import sys, json, re

def last_assistant_text(transcript_path):
    text = ""
    try:
        with open(transcript_path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    entry = json.loads(line)
                except json.JSONDecodeError:
                    continue
                if entry.get("type") != "assistant":
                    continue
                msg = entry.get("message", {})
                for block in msg.get("content", []):
                    if isinstance(block, dict) and block.get("type") == "text":
                        text = block.get("text", "")
    except FileNotFoundError:
        pass
    return text

HEADER_RE = re.compile(r"^\s*(#{1,6}\s*|\*\*)?CONTINUATION PROMPT(\*\*)?\s*:?\s*$", re.MULTILINE)

def has_unfenced_continuation_prompt(text):
    match = HEADER_RE.search(text)
    if not match:
        return False
    after = text[match.end():]
    fence = after.find("```")
    if fence == -1:
        return True
    # anything other than blank lines between the header and the fence means it's not immediately fenced
    between = after[:fence].strip()
    return between != ""

def main():
    raw = sys.stdin.read()
    try:
        payload = json.loads(raw) if raw.strip() else {}
    except json.JSONDecodeError:
        payload = {}

    transcript_path = payload.get("transcript_path", "")
    text = last_assistant_text(transcript_path)

    if has_unfenced_continuation_prompt(text):
        print(json.dumps({
            "continue": False,
            "decision": "block",
            "reason": "Your final message has a 'CONTINUATION PROMPT' section that is not wrapped in a fenced code block (```). This is a standing rule (CLAUDE.md, memory) violated twice already. Fix it: put the continuation prompt content inside a fenced code block before ending the turn."
        }))
        sys.exit(0)

    sys.exit(0)

if __name__ == "__main__":
    main()
