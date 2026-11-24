"""Fast storyboard tests; the full builder also verifies every decoded frame."""

import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import assemble_inferential_planning_movie as movie


class StoryboardTests(unittest.TestCase):
    def test_timestamps(self):
        self.assertEqual(movie.timestamp(0), "00:00.000")
        self.assertEqual(movie.timestamp(833), "00:41.650")
        self.assertEqual(movie.timestamp(5264), "04:23.200")

    def test_complete_timeline_and_metadata(self):
        frames = [513, 513, 545, 533, 533, 609, 609, 609]
        with tempfile.TemporaryDirectory() as name:
            root = Path(name)
            for segment in movie.STORYBOARD:
                if not segment.is_card:
                    folder = root / segment.key
                    folder.mkdir()
                    (folder / f"{segment.key}.mp4").touch()
            with patch.object(movie, "video_info", side_effect=[{"frames": n} for n in frames]):
                rows = movie.timeline(root)
        self.assertEqual(len(rows), 13)
        self.assertEqual(rows[-1]["end_frame"], 5264)
        self.assertEqual(rows[-1]["end_seconds"], 263.2)
        self.assertEqual(rows[2]["start_seconds"], 16)
        self.assertEqual(rows[9]["start_seconds"], 159.85)
        for left, right in zip(rows, rows[1:]):
            self.assertEqual(left["end_frame"], right["start_frame"])
        metadata = movie.chapter_metadata(rows)
        self.assertEqual(metadata.count("[CHAPTER]"), 13)
        self.assertIn("END=263200", metadata)
        self.assertIn("Figure 5 | BA with a backward cue", metadata)

    def test_missing_source_fails_before_rendering(self):
        with tempfile.TemporaryDirectory() as name:
            with self.assertRaisesRegex(FileNotFoundError, "Missing movie"):
                movie.timeline(Path(name))

    def test_metadata_escaping(self):
        self.assertEqual(movie.metadata_escape("A=B;C#D\\E"), "A\\=B\\;C\\#D\\\\E")

    def test_card_text_has_no_line_break_control_glyphs(self):
        with tempfile.TemporaryDirectory() as name:
            directory = Path(name)
            with patch.object(movie, "run"):
                movie.render_card(movie.STORYBOARD[0], directory, directory)
            headings = sorted(directory.glob("opening_heading_*.txt"))
            self.assertEqual(len(headings), 2)
            self.assertEqual(headings[0].read_text(), "Inferential planning")
            for file in directory.glob("*.txt"):
                text = file.read_text()
                self.assertNotIn("\n", text)
                self.assertNotIn("\r", text)


if __name__ == "__main__":
    unittest.main()
