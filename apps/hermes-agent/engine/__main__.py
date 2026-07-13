"""
Hermes Agent CLI entrypoint.

Usage:
    python -m agent                     # interactive agent REPL
    python -m agent "build me a ..."    # one-shot task, then exit
    python -m agent --provider openrouter --model x/y "task"
    python -m agent --step              # confirm each tool call (safe mode)

This is what the bash `hermes agent` command shells into.
"""

from __future__ import annotations

import argparse
import os
import sys

from .core import Agent, ProviderError, print_banner, _c, D, G, Y, C, R, N, BOLD


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="hermes agent",
        description="Autonomous, tool-using AI agent for complex multi-step tasks.",
    )
    p.add_argument("task", nargs="*", help="Task to run once (omit for interactive mode).")
    p.add_argument("--provider", default=None, help="groq | openrouter | gateway | cloudrun | openai")
    p.add_argument("--model", default=None, help="Override the model id.")
    p.add_argument("--max-steps", type=int, default=25, help="Max tool-call iterations (default 25).")
    p.add_argument("--step", action="store_true", help="Confirm each tool call before it runs.")
    p.add_argument("--quiet", action="store_true", help="Suppress step-by-step trace.")
    return p


REPL_HELP = f"""
  {_c('Interactive Agent — commands', BOLD)}
    {_c('/provider <name>', C)}   switch provider (groq, openrouter, gateway, ...)
    {_c('/model <id>', C)}        switch model
    {_c('/steps <n>', C)}         set max tool iterations
    {_c('/auto', C)}              toggle auto-run vs confirm-each-tool
    {_c('/reset', C)}             clear conversation memory
    {_c('/help', C)}              show this help
    {_c('/exit', C)}              quit
  Otherwise, just type a task and the agent will work on it autonomously.
"""


def repl(args) -> int:
    try:
        agent = Agent(
            provider=args.provider,
            model=args.model,
            max_steps=args.max_steps,
            auto=not args.step,
            verbose=not args.quiet,
        )
    except ProviderError as exc:
        print(_c(f"  ✗ {exc}", R))
        return 1

    print_banner(agent)
    if not agent.api_key:
        print(_c("  ⚠️  No API key found for this provider. Run `hermes setup` first,", Y))
        print(_c("      or export the key (e.g. GROQ_KEY / OR_KEY / TOKEN).", Y))
        print()
    print(_c("  Type a complex task, or /help for commands. /exit to quit.", D))

    while True:
        try:
            line = input(_c("\n  ⌁ agent> ", G + BOLD))
        except (EOFError, KeyboardInterrupt):
            print()
            break
        line = line.strip()
        if not line:
            continue

        if line in ("/exit", "/quit", "exit", "quit"):
            break
        if line in ("/help", "help", "?"):
            print(REPL_HELP)
            continue
        if line == "/reset":
            agent.messages = agent.messages[:1]
            print(_c("  ✓ conversation memory cleared", G))
            continue
        if line == "/auto":
            agent.auto = not agent.auto
            print(_c(f"  ✓ auto-run = {agent.auto}", G))
            continue
        if line.startswith("/provider"):
            name = line.split(maxsplit=1)[1].strip() if len(line.split()) > 1 else ""
            try:
                new = Agent(provider=name, max_steps=agent.max_steps,
                            auto=agent.auto, verbose=agent.verbose)
                new.messages = agent.messages
                agent = new
                print(_c(f"  ✓ provider → {agent.provider} ({agent.model})", G))
            except ProviderError as exc:
                print(_c(f"  ✗ {exc}", R))
            continue
        if line.startswith("/model"):
            parts = line.split(maxsplit=1)
            if len(parts) > 1:
                agent.model = parts[1].strip()
                print(_c(f"  ✓ model → {agent.model}", G))
            continue
        if line.startswith("/steps"):
            parts = line.split(maxsplit=1)
            if len(parts) > 1 and parts[1].strip().isdigit():
                agent.max_steps = int(parts[1].strip())
                print(_c(f"  ✓ max-steps → {agent.max_steps}", G))
            continue

        # Regular task → run the autonomous loop.
        try:
            result = agent.run(line)
        except KeyboardInterrupt:
            print(_c("\n  ⚠ interrupted", Y))
            continue
        print()
        print(_c("  ══ RESULT ══", BOLD))
        print("  " + result.replace("\n", "\n  "))

    print(_c("\n  ☤ goodbye", D))
    return 0


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)

    if args.task:
        task = " ".join(args.task)
        try:
            agent = Agent(
                provider=args.provider,
                model=args.model,
                max_steps=args.max_steps,
                auto=not args.step,
                verbose=not args.quiet,
            )
        except ProviderError as exc:
            print(_c(f"  ✗ {exc}", R))
            return 1
        print_banner(agent)
        result = agent.run(task)
        print()
        print(_c("  ══ RESULT ══", BOLD))
        print("  " + result.replace("\n", "\n  "))
        return 0

    return repl(args)


if __name__ == "__main__":
    sys.exit(main())
