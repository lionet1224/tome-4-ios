#!/usr/bin/env python3
"""Summarize an autopilot soak run: telemetry JSONL + console log."""
import json, sys, collections

def main():
    tele_path = sys.argv[1] if len(sys.argv) > 1 else None
    log_path = sys.argv[2] if len(sys.argv) > 2 else None

    events = []
    if tele_path:
        try:
            with open(tele_path) as f:
                for line in f:
                    line = line.strip()
                    if line:
                        try: events.append(json.loads(line))
                        except json.JSONDecodeError: pass
        except OSError:
            pass

    counts = collections.Counter(e.get("ev") for e in events)
    zones = [e for e in events if e.get("ev") == "zone_change"]
    hearts = [e for e in events if e.get("ev") == "heartbeat"]
    deaths = [e for e in events if e.get("ev") in ("would_have_died", "death")]
    errors = [e for e in events if e.get("ev") == "autopilot_error"]

    print("== soak summary ==")
    if events:
        t0, t1 = events[0].get("t", 0), events[-1].get("t", 0)
        turn1 = events[-1].get("turn", 0)
        dur = max(1, t1 - t0)
        print(f"wall: {dur}s   game turns: {turn1}   turns/sec: {turn1/dur/10:.1f}")
    print("events:", dict(counts))
    if hearts:
        h = hearts[-1]
        print(f"last heartbeat: plevel={h.get('plevel')} kills={h.get('kills')} mem={h.get('mem_kb',0)//1024}MB")
        mems = [h.get("mem_kb", 0) for h in hearts]
        print(f"lua heap: start {mems[0]//1024}MB -> end {mems[-1]//1024}MB (leak signal if monotonic)")
    if zones:
        print("zones visited:", " -> ".join(e.get("zone", "?") for e in zones))
    for e in deaths:
        print(f"would_have_died: {e.get('source','?')} in {e.get('zone','?')} L{e.get('lvl','?')} turn {e.get('turn')}")
    for e in errors[:10]:
        print(f"AUTOPILOT ERROR: {e.get('err','?')[:200]}")

    if log_path:
        try:
            lua_errors = []
            with open(log_path, errors="replace") as f:
                lines = f.readlines()
            for i, line in enumerate(lines):
                if "Lua Error" in line:
                    lua_errors.append("".join(lines[i:i+6]))
            print(f"console Lua Errors: {len(lua_errors)}")
            seen = set()
            for e in lua_errors:
                head = e.splitlines()[0][:160]
                if head not in seen:
                    seen.add(head)
                    print("  ", head)
                if len(seen) >= 10: break
        except OSError:
            pass

if __name__ == "__main__":
    main()
