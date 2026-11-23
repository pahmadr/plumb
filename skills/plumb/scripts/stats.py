#!/usr/bin/env python3
"""Token usage of the current Claude Code session, read from its transcript.

Usage: stats.py [transcript.jsonl]
With no argument, picks the most recently written transcript of the project
in the current directory. Prints plain text; changes nothing.
"""
import json
import os
import sys
from collections import Counter
from pathlib import Path


def find_transcript():
    root = Path(os.environ.get("CLAUDE_CONFIG_DIR", Path.home() / ".claude")) / "projects"
    slug = "".join(c if c.isalnum() else "-" for c in os.getcwd())
    files = list((root / slug).glob("*.jsonl"))
    if not files:
        sys.exit(f"No transcript found for this directory under {root}")
    return max(files, key=lambda f: f.stat().st_mtime)


def main():
    path = Path(sys.argv[1]) if len(sys.argv) > 1 else find_transcript()
    usage = {}          # message id -> usage (a message spans several lines)
    tool_names = {}     # tool_use id -> tool name
    result_chars = Counter()
    result_calls = Counter()
    turns = 0

    for line in path.open(encoding="utf-8", errors="replace"):
        try:
            row = json.loads(line)
        except ValueError:
            continue
        msg = row.get("message")
        if not isinstance(msg, dict) or row.get("isSidechain"):
            continue
        content = msg.get("content")
        if row.get("type") == "assistant":
            if msg.get("usage") and msg.get("id"):
                usage[msg["id"]] = msg["usage"]
            for block in content if isinstance(content, list) else []:
                if block.get("type") == "tool_use":
                    tool_names[block.get("id")] = block.get("name", "?")
        elif row.get("type") == "user":
            # Real prompts only: slash-command echoes, task notifications and
            # agent messages arrive as user rows too, flagged meta or tagged.
            if row.get("isMeta"):
                continue
            if isinstance(content, str):
                turns += not content.lstrip().startswith("<")
                continue
            is_prompt = False
            for block in content if isinstance(content, list) else []:
                if block.get("type") == "tool_result":
                    name = tool_names.get(block.get("tool_use_id"), "?")
                    body = block.get("content")
                    size = len(body) if isinstance(body, str) else len(json.dumps(body))
                    result_chars[name] += size
                    result_calls[name] += 1
                elif block.get("type") == "text":
                    is_prompt = True
            turns += is_prompt

    def total(key):
        return sum(u.get(key) or 0 for u in usage.values())

    fresh, written, cached, out = (
        total("input_tokens"),
        total("cache_creation_input_tokens"),
        total("cache_read_input_tokens"),
        total("output_tokens"),
    )
    print(f"Session: {path.stem}")
    print(f"User turns: {turns}   Model requests: {len(usage)}")
    print(f"Input, new:           {fresh + written:>12,}")
    print(f"Input, re-read cache: {cached:>12,}")
    print(f"Output:               {out:>12,}")
    if usage:
        print(f"Largest single request context: {max((u.get('input_tokens') or 0) + (u.get('cache_creation_input_tokens') or 0) + (u.get('cache_read_input_tokens') or 0) for u in usage.values()):,}")
    if result_chars:
        print("\nTool output that entered the context (characters, about 4 per token):")
        for name, size in result_chars.most_common(8):
            print(f"  {name:<28} {size:>10,}  in {result_calls[name]} calls")


if __name__ == "__main__":
    main()
