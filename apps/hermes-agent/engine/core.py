"""
Hermes Agent — Autonomous ReAct-style tool-calling loop.

This turns the one-shot `hermes chat/ask` CLI into a genuine agent that can
plan and execute *complex, multi-step tasks* on its own: reading/writing files,
running shell commands, executing Python, and fetching URLs — iterating until
the goal is met, exactly in the spirit of NousResearch/hermes-agent.

Providers supported (OpenAI-compatible function calling):
  - groq        (default, fast + free)
  - openrouter  (200+ models)
  - gateway     (Hermes Cloudflare gateway)
  - cloudrun    (GCP Cloud Run app)
  - openai      (or any OpenAI-compatible base URL via HERMES_BASE_URL)
"""

from __future__ import annotations

import json
import os
import sys
import time
import urllib.request
import urllib.error

from . import tools

# ─── ANSI colours (match the bash CLI palette) ───────────────────────────────
R = "\033[0;31m"; G = "\033[0;32m"; Y = "\033[1;33m"; B = "\033[0;34m"
P = "\033[0;35m"; C = "\033[0;36m"; W = "\033[1;37m"; D = "\033[0;90m"
N = "\033[0m"; BOLD = "\033[1m"


def _c(text: str, color: str) -> str:
    if os.environ.get("NO_COLOR"):
        return text
    return f"{color}{text}{N}"


# ─────────────────────────────────────────────────────────────────────────────
#  Provider configuration
# ─────────────────────────────────────────────────────────────────────────────
PROVIDERS = {
    "groq": {
        "url": "https://api.groq.com/openai/v1/chat/completions",
        "key_env": "GROQ_KEY",
        "model": "llama-3.3-70b-versatile",
    },
    "openrouter": {
        "url": "https://openrouter.ai/api/v1/chat/completions",
        "key_env": "OR_KEY",
        "model": "google/gemini-2.5-flash",
    },
    "or": {
        "url": "https://openrouter.ai/api/v1/chat/completions",
        "key_env": "OR_KEY",
        "model": "google/gemini-2.5-flash",
    },
    "gateway": {
        "url": os.environ.get("GATEWAY", "https://hermes-cloudflare.certveis.workers.dev")
        + "/v1/chat/completions",
        "key_env": "TOKEN",
        "model": "llama-3.3-70b-versatile",
    },
    "cloudrun": {
        "url": os.environ.get("CLOUDRUN", "https://ai-vitality-819208434965.us-west1.run.app")
        + "/v1/chat/completions",
        "key_env": "TOKEN",
        "model": "llama-3.3-70b-versatile",
    },
    "openai": {
        "url": os.environ.get("HERMES_BASE_URL", "https://api.openai.com/v1")
        + "/chat/completions",
        "key_env": "OPENAI_API_KEY",
        "model": "gpt-4o-mini",
    },
}


SYSTEM_PROMPT = """You are Hermes, an autonomous AI agent running on the user's machine.

You handle COMPLEX, MULTI-STEP tasks by yourself. You have real tools and a
sandboxed workspace. Work like a careful senior engineer:

  1. THINK: Briefly restate the goal and outline a plan.
  2. ACT: Use tools to make progress — run shell commands, read/write/edit
     files, execute Python, fetch URLs. Prefer small verifiable steps.
  3. OBSERVE: Read each tool result and adapt. If something fails, diagnose
     and try a different approach instead of repeating the same call.
  4. VERIFY: Before finishing, check your work actually runs / passes.
  5. FINISH: Call the `finish` tool with a concise summary of what you did
     and where the artifacts live.

Rules:
- Always operate inside the workspace unless told otherwise.
- Never ask the user for permission mid-task; make reasonable decisions.
- Keep reasoning short in visible text; do the real work through tool calls.
- Only call `finish` when the whole task is genuinely done and verified.
"""


class ProviderError(RuntimeError):
    pass


def _post(url: str, payload: dict, api_key: str | None, timeout: int = 120) -> dict:
    data = json.dumps(payload).encode()
    headers = {"Content-Type": "application/json"}
    if api_key:
        headers["Authorization"] = f"Bearer {api_key}"
    req = urllib.request.Request(url, data=data, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as exc:
        body = exc.read().decode(errors="replace")[:800]
        raise ProviderError(f"HTTP {exc.code} from provider: {body}") from exc
    except urllib.error.URLError as exc:
        raise ProviderError(f"Connection error: {exc.reason}") from exc


# ─────────────────────────────────────────────────────────────────────────────
#  The agent
# ─────────────────────────────────────────────────────────────────────────────
class Agent:
    def __init__(
        self,
        provider: str | None = None,
        model: str | None = None,
        max_steps: int = 25,
        auto: bool = True,
        verbose: bool = True,
    ):
        provider = (provider or os.environ.get("PROVIDER", "groq")).lower()
        if provider not in PROVIDERS:
            raise ProviderError(
                f"Unknown provider '{provider}'. Choose: {', '.join(sorted(PROVIDERS))}"
            )
        self.provider = provider
        cfg = PROVIDERS[provider]
        self.url = cfg["url"]
        self.model = model or os.environ.get("MODEL") or cfg["model"]
        self.api_key = os.environ.get(cfg["key_env"], "")
        self.max_steps = int(os.environ.get("HERMES_MAX_STEPS", max_steps))
        self.auto = auto
        self.verbose = verbose
        self.messages: list[dict] = [{"role": "system", "content": SYSTEM_PROMPT}]

    # ── low-level completion call ───────────────────────────────────────────
    def _complete(self) -> dict:
        payload = {
            "model": self.model,
            "messages": self.messages,
            "tools": tools.TOOL_SCHEMAS,
            "tool_choice": "auto",
            "temperature": 0.4,
            "max_tokens": 4096,
        }
        resp = _post(self.url, payload, self.api_key)
        try:
            return resp["choices"][0]["message"]
        except (KeyError, IndexError) as exc:
            raise ProviderError(f"Unexpected response shape: {json.dumps(resp)[:600]}") from exc

    # ── run a single task to completion ─────────────────────────────────────
    def run(self, task: str) -> str:
        self.messages.append({"role": "user", "content": task})
        final = ""

        for step in range(1, self.max_steps + 1):
            if self.verbose:
                print(_c(f"\n  ── step {step}/{self.max_steps} ──", D))
            try:
                msg = self._complete()
            except ProviderError as exc:
                err = f"[agent] Provider error: {exc}"
                print(_c(err, R))
                return err

            content = msg.get("content") or ""
            tool_calls = msg.get("tool_calls") or []

            # Record the assistant turn (must include tool_calls for the API).
            assistant_entry = {"role": "assistant", "content": content}
            if tool_calls:
                assistant_entry["tool_calls"] = tool_calls
            self.messages.append(assistant_entry)

            if content.strip() and self.verbose:
                print(_c("  🜲 ", P) + content.strip())

            # No tool calls → the model answered directly; we're done.
            if not tool_calls:
                final = content.strip()
                break

            done = False
            for call in tool_calls:
                fn = call.get("function", {})
                name = fn.get("name", "")
                raw_args = fn.get("arguments") or "{}"
                try:
                    args = json.loads(raw_args) if isinstance(raw_args, str) else raw_args
                except json.JSONDecodeError:
                    args = {}

                if self.verbose:
                    preview = json.dumps(args)
                    if len(preview) > 160:
                        preview = preview[:157] + "..."
                    print(_c(f"  ▸ {name}", C) + _c(f" {preview}", D))

                if name == "finish":
                    final = args.get("summary", "Task complete.")
                    result = final
                    done = True
                else:
                    if not self.auto:
                        ans = input(_c(f"    run {name}? [Y/n] ", Y)).strip().lower()
                        if ans in ("n", "no"):
                            result = "[user] Skipped by user."
                        else:
                            result = tools.dispatch(name, args)
                    else:
                        result = tools.dispatch(name, args)

                if self.verbose and name != "finish":
                    shown = result if len(result) < 1200 else result[:1200] + " …"
                    for line in shown.splitlines():
                        print(_c("    │ ", D) + line)

                self.messages.append(
                    {
                        "role": "tool",
                        "tool_call_id": call.get("id", name),
                        "name": name,
                        "content": result,
                    }
                )

            if done:
                break
        else:
            final = "[agent] Reached max steps without calling finish. Partial progress may exist in the workspace."

        if self.verbose:
            print(_c("\n  ✔ ", G) + _c("DONE", G + BOLD))
            print(_c("  " + "─" * 56, D))
        return final


def print_banner(agent: Agent):
    print(_c("╔══════════════════════════════════════════════════════════╗", B))
    print(_c("║  ", B) + _c("☤ HERMES AGENT", Y + BOLD) + _c("  — autonomous complex-task mode", D) + _c("       ║", B))
    print(_c("╚══════════════════════════════════════════════════════════╝", B))
    print(f"  {_c('provider', D)} {agent.provider}   {_c('model', D)} {agent.model}   {_c('max-steps', D)} {agent.max_steps}")
    key_ok = "✅" if agent.api_key else "⚠️  no key set"
    print(f"  {_c('auth', D)} {key_ok}   {_c('workspace', D)} {tools.WORKSPACE}")
    print()
