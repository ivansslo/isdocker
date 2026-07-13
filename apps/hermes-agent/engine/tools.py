"""
Hermes Agent — Tool implementations.

These are the "hands" of the agent: real actions it can take on the host
system to accomplish complex, multi-step tasks. Every tool returns a plain
string (the observation) that is fed back into the model on the next turn.

The tool schemas are emitted in OpenAI-compatible "function calling" format,
which works with Groq, OpenRouter, the Hermes Gateway, and any other
OpenAI-style endpoint.
"""

from __future__ import annotations

import json
import os
import shlex
import subprocess
import sys
import textwrap
import urllib.request
import urllib.error
from pathlib import Path


# ─────────────────────────────────────────────────────────────────────────────
#  Sandbox / workspace root
# ─────────────────────────────────────────────────────────────────────────────
WORKSPACE = Path(os.environ.get("HERMES_WORKSPACE", str(Path.home() / ".hermes" / "workspace")))
WORKSPACE.mkdir(parents=True, exist_ok=True)

# Hard limits so a runaway agent can't flood the context window.
MAX_OUTPUT_CHARS = 16000
SHELL_TIMEOUT = int(os.environ.get("HERMES_SHELL_TIMEOUT", "120"))


def _truncate(text: str, limit: int = MAX_OUTPUT_CHARS) -> str:
    if text is None:
        return ""
    if len(text) <= limit:
        return text
    head = text[: limit - 400]
    tail = text[-300:]
    return f"{head}\n\n... [truncated {len(text) - limit + 700} chars] ...\n\n{tail}"


def _resolve(path: str) -> Path:
    """Resolve a user-supplied path against the workspace, blocking escapes."""
    p = Path(path).expanduser()
    if not p.is_absolute():
        p = WORKSPACE / p
    return p


# ─────────────────────────────────────────────────────────────────────────────
#  Individual tools
# ─────────────────────────────────────────────────────────────────────────────
def run_shell(command: str, workdir: str | None = None) -> str:
    """Run a shell command and capture combined stdout/stderr."""
    cwd = _resolve(workdir) if workdir else WORKSPACE
    try:
        proc = subprocess.run(
            command,
            shell=True,
            cwd=str(cwd),
            capture_output=True,
            text=True,
            timeout=SHELL_TIMEOUT,
        )
    except subprocess.TimeoutExpired:
        return f"[shell] TIMEOUT after {SHELL_TIMEOUT}s running: {command}"
    except Exception as exc:  # pragma: no cover
        return f"[shell] ERROR: {exc}"

    out = (proc.stdout or "") + (proc.stderr or "")
    status = f"[exit={proc.returncode}]"
    return _truncate(f"{status}\n{out}".strip() or status)


def read_file(path: str) -> str:
    p = _resolve(path)
    if not p.exists():
        return f"[read_file] Not found: {p}"
    if p.is_dir():
        return f"[read_file] Is a directory: {p}"
    try:
        data = p.read_text(errors="replace")
    except Exception as exc:
        return f"[read_file] ERROR: {exc}"
    return _truncate(f"# {p}\n{data}")


def write_file(path: str, content: str) -> str:
    p = _resolve(path)
    try:
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(content)
    except Exception as exc:
        return f"[write_file] ERROR: {exc}"
    return f"[write_file] Wrote {len(content)} chars to {p}"


def edit_file(path: str, find: str, replace: str) -> str:
    p = _resolve(path)
    if not p.exists():
        return f"[edit_file] Not found: {p}"
    try:
        text = p.read_text(errors="replace")
        if find not in text:
            return f"[edit_file] Search text not found in {p}"
        new_text = text.replace(find, replace, 1)
        p.write_text(new_text)
    except Exception as exc:
        return f"[edit_file] ERROR: {exc}"
    return f"[edit_file] Replaced 1 occurrence in {p}"


def list_dir(path: str = ".") -> str:
    p = _resolve(path)
    if not p.exists():
        return f"[list_dir] Not found: {p}"
    if not p.is_dir():
        return f"[list_dir] Not a directory: {p}"
    entries = []
    for item in sorted(p.iterdir()):
        kind = "d" if item.is_dir() else "f"
        size = item.stat().st_size if item.is_file() else "-"
        entries.append(f"{kind}  {size:>10}  {item.name}")
    return _truncate(f"# {p}\n" + "\n".join(entries) if entries else f"[list_dir] (empty) {p}")


def python_exec(code: str) -> str:
    """Execute a Python snippet in a fresh subprocess (isolated)."""
    tmp = WORKSPACE / "._hermes_exec.py"
    try:
        tmp.write_text(code)
        proc = subprocess.run(
            [sys.executable, str(tmp)],
            cwd=str(WORKSPACE),
            capture_output=True,
            text=True,
            timeout=SHELL_TIMEOUT,
        )
    except subprocess.TimeoutExpired:
        return f"[python] TIMEOUT after {SHELL_TIMEOUT}s"
    except Exception as exc:
        return f"[python] ERROR: {exc}"
    finally:
        tmp.unlink(missing_ok=True)
    out = (proc.stdout or "") + (proc.stderr or "")
    return _truncate(f"[exit={proc.returncode}]\n{out}".strip())


def http_get(url: str) -> str:
    """Fetch a URL and return its text (for lightweight web lookups)."""
    req = urllib.request.Request(url, headers={"User-Agent": "hermes-agent/1.0"})
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            raw = resp.read(2_000_000)  # cap at ~2MB
            charset = resp.headers.get_content_charset() or "utf-8"
            body = raw.decode(charset, errors="replace")
    except urllib.error.HTTPError as exc:
        return f"[http_get] HTTP {exc.code}: {exc.reason}"
    except Exception as exc:
        return f"[http_get] ERROR: {exc}"
    return _truncate(body)


def finish(summary: str) -> str:
    """Signal task completion. Handled specially by the agent loop."""
    return summary


# ─────────────────────────────────────────────────────────────────────────────
#  Registry + OpenAI-compatible schema
# ─────────────────────────────────────────────────────────────────────────────
REGISTRY = {
    "run_shell": run_shell,
    "read_file": read_file,
    "write_file": write_file,
    "edit_file": edit_file,
    "list_dir": list_dir,
    "python_exec": python_exec,
    "http_get": http_get,
    "finish": finish,
}


TOOL_SCHEMAS = [
    {
        "type": "function",
        "function": {
            "name": "run_shell",
            "description": (
                "Run a shell command in the workspace and return combined "
                "stdout/stderr with the exit code. Use for git, build steps, "
                "installing packages, running programs, grep, etc."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "command": {"type": "string", "description": "The shell command to run."},
                    "workdir": {"type": "string", "description": "Optional working directory (relative to workspace)."},
                },
                "required": ["command"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "read_file",
            "description": "Read the full contents of a text file.",
            "parameters": {
                "type": "object",
                "properties": {"path": {"type": "string"}},
                "required": ["path"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "write_file",
            "description": "Create or overwrite a file with the given content.",
            "parameters": {
                "type": "object",
                "properties": {
                    "path": {"type": "string"},
                    "content": {"type": "string"},
                },
                "required": ["path", "content"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "edit_file",
            "description": "Replace the first occurrence of `find` with `replace` in a file.",
            "parameters": {
                "type": "object",
                "properties": {
                    "path": {"type": "string"},
                    "find": {"type": "string"},
                    "replace": {"type": "string"},
                },
                "required": ["path", "find", "replace"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "list_dir",
            "description": "List files and directories at a path.",
            "parameters": {
                "type": "object",
                "properties": {"path": {"type": "string", "description": "Defaults to workspace root."}},
                "required": [],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "python_exec",
            "description": "Execute a Python 3 snippet in an isolated subprocess and return its output.",
            "parameters": {
                "type": "object",
                "properties": {"code": {"type": "string"}},
                "required": ["code"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "http_get",
            "description": "Fetch the text content of a URL (for quick web lookups / API calls).",
            "parameters": {
                "type": "object",
                "properties": {"url": {"type": "string"}},
                "required": ["url"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "finish",
            "description": (
                "Call this ONLY when the entire task is complete. Provide a "
                "concise summary of what was accomplished and where the results live."
            ),
            "parameters": {
                "type": "object",
                "properties": {"summary": {"type": "string"}},
                "required": ["summary"],
            },
        },
    },
]


def dispatch(name: str, arguments: dict) -> str:
    """Call a tool by name with a dict of arguments."""
    fn = REGISTRY.get(name)
    if fn is None:
        return f"[dispatch] Unknown tool: {name}"
    try:
        return fn(**arguments)
    except TypeError as exc:
        return f"[dispatch] Bad arguments for {name}: {exc}"
    except Exception as exc:  # pragma: no cover
        return f"[dispatch] {name} raised: {exc}"
