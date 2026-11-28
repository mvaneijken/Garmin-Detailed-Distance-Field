"""Tests for compare_lap_probe.py. Standard library only: python -m unittest in tools/probe."""

import unittest

import compare_lap_probe as probe


def line(kind, name, clock, timer, distance, current, previous, number):
    return f"{kind},{name},{clock},{timer},{distance},{current},{previous},{number}"


def lap(index, distance):
    return {"index": index, "distance": distance, "timer_time": 100.0}


class ParseProbeLogTest(unittest.TestCase):
    def test_reads_probe_lines_and_ignores_other_output(self):
        text = "\n".join(
            [
                "Lap Distance build: phase2-second-line",
                line("P", "lap", 100000, 95000, "500.0", "500.0", "0", 2),
                "some other log line",
                line("C", "after", 101000, 96000, "510.0", "10.0", "500.0", 2),
            ]
        )
        events = probe.parse_probe_log(text)
        self.assertEqual([e.kind for e in events], ["P", "C"])
        self.assertEqual(events[0].name, "lap")
        self.assertEqual(events[0].clock_ms, 100000)
        self.assertEqual(events[0].distance, 500.0)
        self.assertEqual(events[1].previous, 500.0)
        self.assertEqual(events[1].lap_number, 2)

    def test_null_values_become_none(self):
        events = probe.parse_probe_log(line("P", "start", 1, "null", "null", "0", "0", 1))
        self.assertIsNone(events[0].timer_ms)
        self.assertIsNone(events[0].distance)

    def test_a_truncated_first_line_of_a_rolled_over_log_is_skipped(self):
        text = "25.0,10.0,500.0,2\n" + line("P", "lap", 5, 5, "1.0", "1.0", "0", 2)
        events = probe.parse_probe_log(text)
        self.assertEqual(len(events), 1)

    def test_the_background_line_of_the_map_page_probe_is_read_and_is_not_a_boundary(self):
        # roadmap 6.1: P,bg,<clock>,<background color>,<obscurity flags>,0,0,0
        events = probe.parse_probe_log("P,bg,5000,16777215,7,0,0,0")
        self.assertEqual(events[0].name, "bg")
        self.assertEqual(events[0].timer_ms, 16777215)
        rows, _ = probe.compare(events, None)
        self.assertEqual(rows, [])

    def test_windows_line_endings(self):
        text = line("P", "lap", 5, 5, "1.0", "1.0", "0", 2) + "\r\n"
        self.assertEqual(len(probe.parse_probe_log(text)), 1)


def events_for(*lines):
    return probe.parse_probe_log("\n".join(lines))


class CompareTest(unittest.TestCase):
    def test_a_normal_boundary_has_no_flags(self):
        events = events_for(
            line("P", "lap", 100000, 95000, "500.0", "500.0", "0", 2),
            line("C", "after", 101000, 96000, "510.0", "10.0", "500.0", 2),
        )
        rows, notes = probe.compare(events, [lap(1, 500.0), lap(2, 300.0)])
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0].native, 500.0)
        self.assertEqual(rows[0].shown_previous, 500.0)
        self.assertEqual(rows[0].flags, [])
        self.assertEqual(notes, [])

    def test_two_lap_events_at_one_boundary_are_a_double_event(self):
        events = events_for(
            line("P", "step", 200000, 190000, "400.0", "400.0", "0", 2),
            line("P", "lap", 200050, 190050, "400.0", "0.0", "0.0", 3),
            line("C", "after", 201000, 191000, "410.0", "10.0", "0.0", 3),
        )
        rows, _ = probe.compare(events, [lap(1, 400.0), lap(2, 200.0)])
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0].events, ["step", "lap"])
        self.assertIn("DOUBLE EVENT", rows[0].flags)
        self.assertIn("PREVIOUS = 0", rows[0].flags)
        self.assertIn("DIFF > 5 m", rows[0].flags)

    def test_events_far_apart_are_two_boundaries(self):
        events = events_for(
            line("P", "lap", 100000, 95000, "500.0", "500.0", "0", 2),
            line("C", "after", 101000, 96000, "510.0", "10.0", "500.0", 2),
            line("P", "lap", 110000, 105000, "1000.0", "490.0", "490.0", 3),
            line("C", "after", 111000, 106000, "1010.0", "10.0", "490.0", 3),
        )
        rows, _ = probe.compare(events, [lap(1, 500.0), lap(2, 490.0), lap(3, 20.0)])
        self.assertEqual(len(rows), 2)
        self.assertEqual([r.flags for r in rows], [[], []])

    def test_a_difference_above_the_tolerance_is_flagged(self):
        events = events_for(
            line("P", "lap", 100000, 95000, "500.0", "498.0", "0", 2),
            line("C", "after", 101000, 96000, "510.0", "10.0", "498.0", 2),
        )
        rows, _ = probe.compare(events, [lap(1, 500.0), lap(2, 300.0)])
        self.assertEqual(rows[0].flags, [])
        rows, _ = probe.compare(events, [lap(1, 520.0), lap(2, 300.0)], tolerance_m=5.0)
        self.assertEqual(rows[0].flags, ["DIFF > 5 m"])

    def test_a_negative_lap_value_is_flagged(self):
        events = events_for(
            line("P", "leg", 100000, 95000, "500.0", "-3.0", "500.0", 2),
            line("C", "after", 101000, 96000, "510.0", "10.0", "500.0", 2),
        )
        rows, _ = probe.compare(events, [lap(1, 500.0), lap(2, 300.0)])
        self.assertIn("NEGATIVE", rows[0].flags)

    def test_without_a_fit_file_the_native_column_is_empty(self):
        events = events_for(
            line("P", "lap", 100000, 95000, "500.0", "500.0", "0", 2),
            line("C", "after", 101000, 96000, "510.0", "10.0", "500.0", 2),
        )
        rows, notes = probe.compare(events, None)
        self.assertEqual(len(rows), 1)
        self.assertIsNone(rows[0].native)
        self.assertEqual(rows[0].flags, [])
        self.assertEqual(notes, [])

    def test_a_boundary_count_that_differs_from_the_fit_laps_is_noted(self):
        events = events_for(
            line("P", "lap", 100000, 95000, "500.0", "500.0", "0", 2),
            line("C", "after", 101000, 96000, "510.0", "10.0", "500.0", 2),
        )
        rows, notes = probe.compare(events, [lap(1, 500.0), lap(2, 300.0), lap(3, 200.0)])
        self.assertEqual(len(rows), 1)
        self.assertEqual(len(notes), 1)
        self.assertIn("1 lap boundary", notes[0])
        self.assertIn("3 laps", notes[0])

    def test_a_boundary_without_an_after_line_has_no_shown_value(self):
        events = events_for(line("P", "lap", 100000, 95000, "500.0", "500.0", "0", 2))
        rows, _ = probe.compare(events, [lap(1, 500.0), lap(2, 300.0)])
        self.assertIsNone(rows[0].shown_previous)

    def test_a_lap_with_its_trigger_counts_and_a_step_before_it_is_a_double_event(self):
        # lap2_<trigger> is the onTimerLap2 callback of API 5.2.2; 21 = LAP_TRIGGER_WORKOUT_STEP_PREVIOUS
        events = events_for(
            line("P", "step", 200000, 190000, "400.0", "400.0", "0", 2),
            line("P", "lap2_21", 200040, 190040, "400.0", "0.0", "0.0", 3),
            line("C", "after", 201000, 191000, "410.0", "10.0", "0.0", 3),
        )
        rows, _ = probe.compare(events, [lap(1, 400.0), lap(2, 200.0)])
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0].events, ["step", "lap2_21"])
        self.assertIn("DOUBLE EVENT", rows[0].flags)

    def test_timer_events_are_not_lap_boundaries(self):
        events = events_for(
            line("P", "start", 1000, 0, "0.0", "0.0", "0", 1),
            line("P", "stop", 9000, 8000, "20.0", "20.0", "0", 1),
            line("P", "reset", 9500, 8000, "20.0", "20.0", "0", 1),
        )
        rows, _ = probe.compare(events, None)
        self.assertEqual(rows, [])


class GroupingAcrossAComputeTest(unittest.TestCase):
    def test_two_lap_events_one_and_a_half_seconds_apart_are_one_boundary_even_with_a_compute_between(self):
        events = events_for(
            line("P", "step", 200000, 190000, "400.0", "400.0", "0", 2),
            line("C", "after", 200400, 190400, "403.0", "3.0", "400.0", 2),
            line("P", "lap", 201500, 191500, "405.0", "0.0", "0.0", 3),
            line("C", "after", 202400, 192400, "408.0", "3.0", "0.0", 3),
        )
        rows, _ = probe.compare(events, [lap(1, 400.0), lap(2, 200.0)])
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0].events, ["step", "lap"])
        self.assertIn("DOUBLE EVENT", rows[0].flags)
        self.assertEqual(rows[0].shown_previous, 0.0)


class ActivitiesTest(unittest.TestCase):
    def two_activities(self):
        return events_for(
            line("P", "start", 1000, 0, "0.0", "0.0", "0", 1),
            line("P", "lap", 100000, 95000, "500.0", "500.0", "0", 2),
            line("C", "after", 101000, 96000, "510.0", "10.0", "500.0", 2),
            line("P", "reset", 200000, 190000, "900.0", "400.0", "500.0", 2),
            line("C", "after", 201000, 191000, "0.0", "0.0", "0.0", 1),
            line("P", "start", 210000, 0, "0.0", "0.0", "0", 1),
            line("P", "lap", 300000, 90000, "300.0", "300.0", "0", 2),
            line("C", "after", 301000, 91000, "310.0", "10.0", "300.0", 2),
        )

    def test_the_log_is_split_after_every_reset(self):
        activities = probe.split_activities(self.two_activities())
        self.assertEqual(len(activities), 2)
        self.assertEqual([e.name for e in activities[0]][-1], "after")
        self.assertEqual(activities[1][0].name, "start")

    def test_a_reset_followed_by_zero_values_is_ok(self):
        checks = probe.check_resets(self.two_activities())
        self.assertEqual(len(checks), 1)
        self.assertTrue(checks[0]["ok"])

    def test_old_values_after_a_reset_are_flagged(self):
        events = events_for(
            line("P", "reset", 200000, 190000, "900.0", "400.0", "500.0", 2),
            line("C", "after", 201000, 191000, "900.0", "400.0", "500.0", 2),
        )
        checks = probe.check_resets(events)
        self.assertFalse(checks[0]["ok"])
        self.assertEqual(checks[0]["previous"], 500.0)

    def test_a_reset_without_an_after_line_is_unknown(self):
        events = events_for(line("P", "reset", 200000, 190000, "900.0", "400.0", "500.0", 2))
        self.assertIsNone(probe.check_resets(events)[0]["ok"])


class VerdictTest(unittest.TestCase):
    def test_confirmed_when_a_boundary_fired_two_lap_events(self):
        events = events_for(
            line("P", "step", 200000, 190000, "400.0", "400.0", "0", 2),
            line("P", "lap", 200050, 190050, "400.0", "0.0", "0.0", 3),
            line("C", "after", 201000, 191000, "410.0", "10.0", "0.0", 3),
        )
        rows, _ = probe.compare(events, None)
        self.assertIn("C3 confirmed", probe.verdict(rows))

    def test_not_seen_when_every_boundary_fired_one_event(self):
        events = events_for(
            line("P", "lap", 100000, 95000, "500.0", "500.0", "0", 2),
            line("C", "after", 101000, 96000, "510.0", "10.0", "500.0", 2),
        )
        rows, _ = probe.compare(events, None)
        self.assertIn("C3 not seen", probe.verdict(rows))

    def test_no_boundaries(self):
        self.assertIn("no lap boundary", probe.verdict([]))


class FormatTest(unittest.TestCase):
    def test_markdown_table_has_a_row_per_boundary_and_the_flags(self):
        events = events_for(
            line("P", "step", 200000, 190000, "400.0", "400.0", "0", 2),
            line("P", "lap", 200050, 190050, "400.0", "0.0", "0.0", 3),
            line("C", "after", 201000, 191000, "410.0", "10.0", "0.0", 3),
        )
        rows, notes = probe.compare(events, [lap(1, 400.0), lap(2, 200.0)])
        text = probe.format_markdown(rows, notes)
        self.assertIn("| 1 |", text)
        self.assertIn("step+lap", text)
        self.assertIn("DOUBLE EVENT", text)
        self.assertIn("C3 confirmed", text)


_CRC_TABLE = [0x0000, 0xCC01, 0xD801, 0x1400, 0xF001, 0x3C00, 0x2800, 0xE401,
              0xA001, 0x6C00, 0x7800, 0xB401, 0x5000, 0x9C01, 0x8801, 0x4400]


def _fit_crc(data):
    crc = 0
    for byte in data:
        for nibble in (byte & 0xF, (byte >> 4) & 0xF):
            temp = _CRC_TABLE[crc & 0xF]
            crc = (crc >> 4) & 0x0FFF
            crc = crc ^ temp ^ _CRC_TABLE[nibble]
    return crc


def make_fit_with_laps(laps):
    """A minimal FIT file with one lap message per (distance m, timer time s) pair."""
    import struct

    definition = struct.pack("<BBBHB", 0x40, 0, 0, 19, 2)  # lap message, 2 fields
    definition += struct.pack("<BBB", 8, 4, 0x86)  # total_timer_time, uint32 (scale 1000)
    definition += struct.pack("<BBB", 9, 4, 0x86)  # total_distance, uint32 (scale 100)
    records = definition
    for distance, timer_time in laps:
        records += struct.pack("<BII", 0x00, round(timer_time * 1000), round(distance * 100))
    header = struct.pack("<BBHI4s", 14, 0x20, 2100, len(records), b".FIT")
    header += struct.pack("<H", 0)
    body = header + records
    return body + struct.pack("<H", _fit_crc(body))


class ReadFitLapsTest(unittest.TestCase):
    def test_reads_the_lap_table_of_a_fit_file(self):
        try:
            import fitdecode  # noqa: F401
        except ImportError:
            self.skipTest("fitdecode is not installed (tools/probe/requirements.txt)")
        import os
        import tempfile

        with tempfile.TemporaryDirectory() as folder:
            path = os.path.join(folder, "activity.fit")
            with open(path, "wb") as handle:
                handle.write(make_fit_with_laps([(500.0, 150.0), (300.25, 90.0)]))
            laps = probe.read_fit_laps(path)
        self.assertEqual([lap_["index"] for lap_ in laps], [1, 2])
        self.assertAlmostEqual(laps[0]["distance"], 500.0)
        self.assertAlmostEqual(laps[1]["distance"], 300.25)
        self.assertAlmostEqual(laps[0]["timer_time"], 150.0)


if __name__ == "__main__":
    unittest.main()
