"""Compare the lap probe log of the data field with the lap table of a saved FIT file (roadmap 0.5).

The probe build (see docs/LAP-TEST-PROTOCOL.md) prints one line per timer event:

    <P or C>,<event>,<getTimer ms>,<timerTime ms>,<distance m>,<current lap m>,<previous lap m>,<lap number>

P is printed in the callback, C at the first compute after an event (the values the field shows from then on).
Run one scenario per activity, then:

    python compare_lap_probe.py --log LAPPROBE.TXT [--log LAPPROBE.BAK] [--fit activity.fit]

The log parsing and the comparison are pure functions without dependencies (see the tests). Reading the FIT
file needs the fitdecode package (requirements.txt), imported only when --fit is used.
"""

import argparse
import re
import sys
from dataclasses import dataclass, field
from typing import List, Optional

# Events that start a new lap in the field. start, stop, pause, resume and reset are logged but are not boundaries.
LAP_EVENTS = ("lap", "step", "leg")  # also lap2_<trigger> (onTimerLap2 with the lap trigger)
# Two lap events this close together belong to one boundary.
DOUBLE_EVENT_GAP_MS = 2000

_NUMBER = r"-?[0-9.]+(?:[eE][-+]?[0-9]+)?|null"
_LINE = re.compile(
    r"^(?P<kind>[PC]),(?P<name>[a-z0-9_]+),"
    rf"(?P<clock>-?\d+),(?P<timer>{_NUMBER}),(?P<distance>{_NUMBER}),"
    rf"(?P<current>{_NUMBER}),(?P<previous>{_NUMBER}),(?P<number>\d+|null)$"
)


@dataclass
class Event:
    kind: str
    name: str
    clock_ms: int
    timer_ms: Optional[float]
    distance: Optional[float]
    current: Optional[float]
    previous: Optional[float]
    lap_number: Optional[int]


@dataclass
class Row:
    index: int
    events: List[str]
    clock_ms: int
    distance: Optional[float]
    native: Optional[float]
    shown_previous: Optional[float]
    flags: List[str] = field(default_factory=list)


def _number(text):
    return None if text == "null" else float(text)


def parse_probe_log(text):
    """The probe lines of a log, in order. Other lines (and a line cut by a log rollover) are ignored."""
    events = []
    for raw in text.splitlines():
        match = _LINE.match(raw.strip())
        if not match:
            continue
        number = match["number"]
        events.append(
            Event(
                kind=match["kind"],
                name=match["name"],
                clock_ms=int(match["clock"]),
                timer_ms=_number(match["timer"]),
                distance=_number(match["distance"]),
                current=_number(match["current"]),
                previous=_number(match["previous"]),
                lap_number=None if number == "null" else int(number),
            )
        )
    return events


def read_fit_laps(path):
    """The lap messages of a FIT file as dicts: index (1-based), distance (m), timer_time (s)."""
    import fitdecode  # imported here so the pure functions work without the package

    laps = []
    with fitdecode.FitReader(path) as reader:
        for frame in reader:
            if frame.frame_type != fitdecode.FIT_FRAME_DATA or frame.name != "lap":
                continue
            laps.append(
                {
                    "index": len(laps) + 1,
                    "distance": frame.get_value("total_distance", fallback=None),
                    "timer_time": frame.get_value("total_timer_time", fallback=None),
                }
            )
    return laps


def split_activities(events):
    """The log cut after every reset event (the activity ended). The C line after a reset stays with it."""
    activities = []
    current = []
    index = 0
    while index < len(events):
        event = events[index]
        current.append(event)
        index += 1
        if event.kind == "P" and event.name == "reset":
            if index < len(events) and events[index].kind == "C":
                current.append(events[index])
                index += 1
            activities.append(current)
            current = []
    if current:
        activities.append(current)
    return activities


def check_resets(events):
    """What the field shows right after every reset: both laps should be 0 (finding C2, scenario S7).

    ok is None when the log has no C line after the reset (no compute ran before it ended).
    """
    checks = []
    for index, event in enumerate(events):
        if event.kind != "P" or event.name != "reset":
            continue
        after = events[index + 1] if index + 1 < len(events) and events[index + 1].kind == "C" else None
        ok = None
        if after is not None:
            ok = (after.current or 0) < 1.0 and (after.previous or 0) < 1.0
        checks.append(
            {
                "clock_ms": event.clock_ms,
                "current": None if after is None else after.current,
                "previous": None if after is None else after.previous,
                "ok": ok,
            }
        )
    return checks


def _plural(count, singular, plural):
    return f"{count} {singular if count == 1 else plural}"


def compare(events, laps, double_gap_ms=DOUBLE_EVENT_GAP_MS, tolerance_m=5.0):
    """Pair every lap boundary in the log with the native lap of the FIT file.

    Returns (rows, notes). laps is None when there is no FIT file (simulator runs).
    """
    groups = []  # each: {"events": [Event], "after": Event or None}
    waiting_for_after = None
    for event in events:
        if event.kind == "P":
            if event.name in LAP_EVENTS or event.name.startswith("lap2_"):
                last = groups[-1] if groups else None
                if last is not None and event.clock_ms - last["events"][-1].clock_ms <= double_gap_ms:
                    # Same boundary, even when a compute printed a C line in between: the latest C line wins.
                    last["events"].append(event)
                    last["after"] = None
                else:
                    last = {"events": [event], "after": None}
                    groups.append(last)
                waiting_for_after = last
            else:
                waiting_for_after = None
        elif waiting_for_after is not None:
            waiting_for_after["after"] = event
            waiting_for_after = None

    rows = []
    for index, group in enumerate(groups):
        events_here = group["events"]
        after = group["after"]
        shown_previous = after.previous if after is not None else None
        distance = events_here[-1].distance
        native = None
        if laps is not None and index < len(laps):
            native = laps[index]["distance"]
        row = Row(
            index=index + 1,
            events=[e.name for e in events_here],
            clock_ms=events_here[0].clock_ms,
            distance=distance,
            native=native,
            shown_previous=shown_previous,
        )
        if len(events_here) >= 2:
            row.flags.append("DOUBLE EVENT")
        if shown_previous is not None and shown_previous < 1.0 and distance is not None and distance >= 10.0:
            row.flags.append("PREVIOUS = 0")
        if native is not None and shown_previous is not None and abs(shown_previous - native) > tolerance_m:
            row.flags.append(f"DIFF > {tolerance_m:g} m")
        shown = list(events_here) + ([after] if after is not None else [])
        if any((v is not None and v < 0) for e in shown for v in (e.current, e.previous)):
            row.flags.append("NEGATIVE")
        rows.append(row)

    notes = []
    if laps is not None and len(rows) != max(len(laps) - 1, 0):
        notes.append(
            f"The field saw {_plural(len(rows), 'lap boundary', 'lap boundaries')} but the FIT file has "
            f"{_plural(len(laps), 'lap', 'laps')} (expected {max(len(laps) - 1, 0)}). "
            "Rows are paired in order; check the table against the log."
        )
    return rows, notes


def verdict(rows):
    if not rows:
        return "The log has no lap boundary: no lap event arrived."
    doubles = sum(1 for row in rows if "DOUBLE EVENT" in row.flags)
    if doubles:
        return (
            f"C3 confirmed: {doubles} of {len(rows)} boundaries fired more than one lap event "
            f"within {DOUBLE_EVENT_GAP_MS // 1000} s."
        )
    return "C3 not seen: every boundary fired a single lap event."


def _cell(value):
    return "" if value is None else f"{value:.1f}"


def format_markdown(rows, notes):
    lines = [
        "| Lap | Events | Distance at event (m) | Native lap (m) | Field previous lap (m) | Flags |",
        "|---|---|---:|---:|---:|---|",
    ]
    for row in rows:
        lines.append(
            f"| {row.index} | {'+'.join(row.events)} | {_cell(row.distance)} | {_cell(row.native)} | "
            f"{_cell(row.shown_previous)} | {', '.join(row.flags)} |"
        )
    lines.append("")
    for note in notes:
        lines.append(f"Note: {note}")
    lines.append(verdict(rows))
    return "\n".join(lines)


def format_resets(checks):
    lines = []
    for number, check in enumerate(checks, start=1):
        if check["ok"] is None:
            state = "unknown (no compute line after the reset)"
        elif check["ok"]:
            state = f"OK: current {_cell(check['current'])} m, previous {_cell(check['previous'])} m"
        else:
            state = (
                f"OLD VALUES: current {_cell(check['current'])} m, previous {_cell(check['previous'])} m "
                "(finding C2: the laps of the old activity survive)"
            )
        lines.append(f"Reset {number}: {state}")
    return "\n".join(lines)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--log", action="append", required=True, help="probe log; repeat for LAPPROBE.BAK first")
    parser.add_argument("--fit", help="saved activity (.fit) with the native lap table")
    parser.add_argument(
        "--activity",
        type=int,
        help="which activity of the log the FIT file belongs to (1 = the first, default: the last with laps)",
    )
    parser.add_argument("--tolerance", type=float, default=5.0, help="allowed difference in meters")
    args = parser.parse_args(argv)

    text = ""
    for path in args.log:
        with open(path, encoding="utf-8", errors="replace") as handle:
            text += handle.read() + "\n"
    events = parse_probe_log(text)
    activities = split_activities(events)
    laps = read_fit_laps(args.fit) if args.fit else None

    with_laps = [i for i, part in enumerate(activities) if compare(part, None)[0]]
    chosen = (args.activity - 1) if args.activity else (with_laps[-1] if with_laps else None)
    for index, part in enumerate(activities):
        rows, notes = compare(part, laps if index == chosen else None, tolerance_m=args.tolerance)
        if len(activities) > 1:
            print(f"### Activity {index + 1} of {len(activities)}" + (" (paired with the FIT file)" if index == chosen and laps else ""))
        print(format_markdown(rows, notes))
        print()
    checks = check_resets(events)
    if checks:
        print(format_resets(checks))
    return 0


if __name__ == "__main__":
    sys.exit(main())
