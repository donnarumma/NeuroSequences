#!/usr/bin/env python3
"""Join the eight existing scientific clips without re-encoding their frames."""

import argparse
import hashlib
import json
import shutil
import subprocess
import tempfile
from dataclasses import dataclass
from datetime import datetime, timezone
from fractions import Fraction
from pathlib import Path


ROOT = Path(__file__).resolve().parent
FPS = 20
TITLE = "Inferential planning in the frontal cortex"


@dataclass(frozen=True)
class Segment:
    key: str
    title: str
    seconds: int = 0
    kicker: str = ""
    heading: str = ""
    body: str = ""
    footer: str = ""

    @property
    def is_card(self):
        return self.seconds > 0


STORYBOARD = (
    Segment("opening", TITLE, 10, "NEUROSEQUENCES | SIMULATION MOVIE",
            "Inferential planning\nin the frontal cortex",
            "How can an entire plan be represented at once?\nA visual companion to the computational model",
            "MODEL-GENERATED ACTIVITY | SELECTED RESULTS FROM FIGURES 2, 4 AND 5"),
    Segment("chapter_1", "Chapter 1 | Goal-directed sequence planning", 6,
            "CHAPTER 01 / 03 | FIGURE 2",
            "Goal-directed\nsequence planning",
            "Two goals. One start. Three planned movements.\nTask based on Mushiake et al. (2006).",
            "THE NEURAL PLANNING INTERVAL IS FOLLOWED BY A SEPARATE SCHEMATIC REPLAY"),
    Segment("Mushiake_Fig02_ULL", "Figure 2 | ULL: up, left, left"),
    Segment("Mushiake_Fig02_URR", "Figure 2 | URR: up, right, right"),
    Segment("chapter_2", "Chapter 2 | Remembering and reversing sequences", 6,
            "CHAPTER 02 / 03 | FIGURE 4",
            "Remembering and reversing\nthree-target sequences",
            "A, B, C: forward memory, backward memory and sensory encoding.\nTask based on Chen et al. (2024).",
            "THE RULE IS KNOWN BEFORE THE TARGETS; SEQUENCE LENGTH IS INITIALLY UNKNOWN"),
    Segment("Chen01_Fig04_ABC_Forward", "Figure 4 | ABC forward memory"),
    Segment("Chen01_Fig04_ABC_Backward", "Figure 4 | ABC backward memory"),
    Segment("Chen01_Fig04_ABC_Sensory", "Figure 4 | ABC sensory responses"),
    Segment("chapter_3", "Chapter 3 | Reordering memory after a late cue", 6,
            "CHAPTER 03 / 03 | FIGURE 5",
            "Reordering memory\nafter a late cue",
            "Two remembered targets. A rule revealed later.\nTask based on Chen et al. (2024).",
            "AB + FORWARD -> AB | AB + BACKWARD -> BA | BA + BACKWARD -> AB"),
    Segment("Chen02_Fig05_AB_Forward", "Figure 5 | AB with a forward cue"),
    Segment("Chen02_Fig05_AB_Backward", "Figure 5 | AB with a backward cue"),
    Segment("Chen02_Fig05_BA_Backward", "Figure 5 | BA with a backward cue"),
    Segment("closing", "Closing | Paper and code", 12,
            "INFERENTIAL PLANNING | PAPER AND CODE",
            "One computational framework.\nDifferent sequence tasks.",
            "Francesco Donnarumma, Thomas Parr, Karl Friston,\nJames Whittington and Giovanni Pezzulo\nCode and movie: CONAN Lab, ISTC-CNR",
            "Code: github.com/donnarumma/NeuroSequences\nConcept DOI: 10.5281/zenodo.21628748"),
)


def run(command):
    return subprocess.run(command, check=True, capture_output=True, text=True).stdout


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def probe(path):
    return json.loads(run(["ffprobe", "-v", "error", "-show_streams", "-show_format",
                           "-show_chapters", "-of", "json", str(path)]))


def video_info(path):
    data = probe(path)
    videos = [stream for stream in data["streams"] if stream["codec_type"] == "video"]
    if len(videos) != 1 or any(s["codec_type"] == "audio" for s in data["streams"]):
        raise ValueError(f"Expected one silent video stream: {path}")
    stream = videos[0]
    signature = (stream["codec_name"], stream["width"], stream["height"],
                 stream["pix_fmt"], Fraction(stream["r_frame_rate"]),
                 stream.get("sample_aspect_ratio", "1:1"))
    if signature != ("h264", 1920, 1080, "yuv420p", Fraction(FPS), "1:1"):
        raise ValueError(f"Expected H.264, 1920x1080, yuv420p, {FPS} fps, square pixels: {path}")
    return {"frames": int(stream["nb_frames"]), "sha256": sha256(path),
            "path": str(path.resolve()), "time_base": stream["time_base"]}


def timeline(input_root):
    rows = []
    cursor = 0
    for segment in STORYBOARD:
        source = None
        if segment.is_card:
            frames = segment.seconds * FPS
        else:
            path = input_root / segment.key / f"{segment.key}.mp4"
            if not path.is_file():
                raise FileNotFoundError(f"Missing movie: {path}. Render the individual movie first.")
            source = video_info(path)
            frames = source["frames"]
        rows.append({"key": segment.key, "title": segment.title,
                     "kind": "title_card" if segment.is_card else "source_clip",
                     "start_frame": cursor, "end_frame": cursor + frames,
                     "frames": frames, "start_seconds": cursor / FPS,
                     "end_seconds": (cursor + frames) / FPS, "source": source})
        cursor += frames
    return rows


def timestamp(frame):
    milliseconds = frame * 1000 // FPS
    minutes, milliseconds = divmod(milliseconds, 60000)
    seconds, milliseconds = divmod(milliseconds, 1000)
    return f"{minutes:02d}:{seconds:02d}.{milliseconds:03d}"


def metadata_escape(value):
    return value.replace("\\", "\\\\").replace("=", "\\=").replace(";", "\\;").replace("#", "\\#")


def chapter_metadata(rows):
    lines = [";FFMETADATA1", f"title={TITLE} | Simulation movie",
             "artist=NeuroSequences | CONAN Lab, ISTC-CNR",
             "comment=Selected model simulations from Figures 2, 4 and 5. Silent; narration script supplied separately."]
    for row in rows:
        lines.extend(["[CHAPTER]", "TIMEBASE=1/1000",
                      f"START={row['start_frame'] * 1000 // FPS}",
                      f"END={row['end_frame'] * 1000 // FPS}",
                      f"title={metadata_escape(row['title'])}"])
    return "\n".join(lines) + "\n"


def filter_path(path):
    value = str(path).replace("\\", "/").replace(":", "\\:").replace("'", "'\\''")
    return f"'{value}'"


def render_card(segment, directory, font_dir):
    filters = ["drawgrid=width=96:height=96:thickness=1:color=white@0.035"]
    for index, colour in enumerate(["0xdf5221", "0xedb11f", "0x7e2f8e"]):
        filters.append(f"drawbox=x={140 + index * 552}:y=882:w=510:h=6:color={colour}:t=fill")
    fields = [("kicker", segment.kicker, 140, 215, 24, "0xc6d5e5", False),
              ("heading", segment.heading, 132, 304, 76, "white", True),
              ("body", segment.body, 140, 570, 30, "0xc6d5e5", False),
              ("footer", segment.footer, 140, 945, 21, "0x9aaec4", False)]
    for name, value, x, y, size, colour, bold in fields:
        font = font_dir / ("DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf")
        # Separate lines avoid drawtext rendering line-break control glyphs.
        for index, line in enumerate(value.splitlines()):
            text_file = directory / f"{segment.key}_{name}_{index}.txt"
            text_file.write_text(line, encoding="utf-8")
            filters.append(f"drawtext=fontfile={filter_path(font)}:textfile={filter_path(text_file)}:"
                           f"expansion=none:fontsize={size}:fontcolor={colour}:x={x}:y={y + index * (size + 18)}")
    filters.extend(["fade=t=in:st=0:d=0.4",
                    f"fade=t=out:st={segment.seconds - 0.4}:d=0.4", "format=yuv420p"])
    output = directory / f"{segment.key}.mp4"
    run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-f", "lavfi", "-i",
         f"gradients=s=1920x1080:r={FPS}:c0=0x1b2b40:c1=0x0b1522:"
         f"x0=0:y0=0:x1=1920:y1=1080:n=2:seed=0:speed=0:d={segment.seconds}",
         "-vf", ",".join(filters), "-frames:v", str(segment.seconds * FPS),
         "-an", "-c:v", "libx264", "-preset", "medium", "-crf", "18", "-pix_fmt", "yuv420p",
         "-video_track_timescale", "10240", "-movflags", "+faststart", str(output)])
    return output


def frame_hashes(path):
    result = run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-i", str(path),
                  "-map", "0:v:0", "-an", "-f", "framemd5", "-"])
    return [line.rsplit(",", 1)[1].strip() for line in result.splitlines()
            if line and not line.startswith("#")]


def verify_movie(output, rows):
    data = probe(output)
    hashes = frame_hashes(output)
    if len(hashes) != rows[-1]["end_frame"]:
        raise ValueError("The assembled frame count differs from the storyboard.")
    if len(data.get("chapters", [])) != len(rows):
        raise ValueError("Missing embedded chapters.")
    for row, chapter in zip(rows, data["chapters"]):
        if abs(float(chapter["start_time"]) - row["start_seconds"]) > 0.001:
            raise ValueError(f"Chapter time mismatch: {row['key']}")
        if chapter["tags"]["title"] != row["title"]:
            raise ValueError(f"Chapter title mismatch: {row['key']}")
        if row["source"]:
            path = Path(row["source"]["path"])
            if sha256(path) != row["source"]["sha256"]:
                raise ValueError(f"Input changed while assembling: {path}")
            if hashes[row["start_frame"]:row["end_frame"]] != frame_hashes(path):
                raise ValueError(f"Decoded scientific frames changed: {row['key']}")
            print(f"Verified every original frame: {row['key']}", flush=True)


def assemble(input_root, output_dir, font_dir, overwrite=False):
    rows = timeline(input_root)
    output = output_dir / "Inferential_Planning.mp4"
    if output.exists() and not overwrite:
        raise FileExistsError(f"Video exists: {output}. Use --overwrite to replace it.")
    for font in ["DejaVuSans.ttf", "DejaVuSans-Bold.ttf"]:
        if not (font_dir / font).is_file():
            raise FileNotFoundError(f"Missing font: {font_dir / font}. Set --font-dir.")
    output_dir.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="inferential_planning_") as scratch:
        directory = Path(scratch)
        parts = []
        for segment, row in zip(STORYBOARD, rows):
            if segment.is_card:
                print(f"Rendering title card: {segment.key}", flush=True)
                path = render_card(segment, directory, font_dir)
            else:
                path = Path(row["source"]["path"])
            parts.append(path)
        concat = directory / "parts.ffconcat"
        concat.write_text("ffconcat version 1.0\n" + "".join(
            "file '" + str(path).replace("'", "'\\''") + "'\n"
            f"duration {row['frames'] / FPS:.6f}\n" for path, row in zip(parts, rows)), encoding="utf-8")
        metadata = directory / "chapters.ffmeta"
        metadata.write_text(chapter_metadata(rows), encoding="utf-8")
        temporary = directory / output.name
        print("Joining complete clips with stream copy; no scientific frames are re-encoded.", flush=True)
        run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-f", "concat", "-safe", "0",
             "-i", str(concat), "-f", "ffmetadata", "-i", str(metadata), "-map", "0:v:0",
             "-map_metadata", "1", "-map_chapters", "1", "-c:v", "copy", "-an",
             "-movflags", "+faststart", str(temporary)])
        verify_movie(temporary, rows)
        shutil.copyfile(metadata, output_dir / "Inferential_Planning_chapters.ffmeta")
        for segment, path in zip(STORYBOARD, parts):
            if segment.is_card:
                run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-ss", "1", "-i", str(path),
                     "-frames:v", "1", str(output_dir / f"card_{segment.key}.png")])
        shutil.copyfile(output_dir / "card_opening.png", output_dir / "Inferential_Planning_poster.png")
        # Publish on the destination filesystem without copying extended attributes.
        with tempfile.TemporaryDirectory(prefix=".assembly_", dir=output_dir) as staging:
            staged = Path(staging) / output.name
            shutil.copyfile(temporary, staged)
            staged.replace(output)
    manifest = {"title": TITLE, "createdUTC": datetime.now(timezone.utc).isoformat(),
                "frameRate": FPS, "durationSeconds": rows[-1]["end_seconds"],
                "totalFrames": rows[-1]["end_frame"], "segments": rows,
                "assemblyCodeSHA256": sha256(Path(__file__)), "outputSHA256": sha256(output),
                "verification": "Every decoded source frame matches its corresponding master frame.",
                "audio": "None; English narration is supplied in Movies/Movie-Readme.md.",
                "paperURL": "https://www.sciencedirect.com/science/article/pii/S2211124726009836"}
    (output_dir / "Inferential_Planning_timeline.json").write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"Saved {output} ({timestamp(rows[-1]['end_frame'])})", flush=True)
    return output


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input-root", type=Path, default=ROOT / "output")
    parser.add_argument("--output-dir", type=Path, default=ROOT / "output" / "Inferential_Planning")
    parser.add_argument("--font-dir", type=Path, default=Path("/usr/share/fonts/truetype/dejavu"))
    parser.add_argument("--overwrite", action="store_true")
    parser.add_argument("--check-only", action="store_true", help="Validate inputs and print the timeline without writing files.")
    args = parser.parse_args()
    for tool in ["ffmpeg", "ffprobe"]:
        if shutil.which(tool) is None:
            parser.error(f"{tool} is required on PATH.")
    if args.check_only:
        for row in timeline(args.input_root.expanduser()):
            print(f"{timestamp(row['start_frame'])} - {timestamp(row['end_frame'])} | {row['title']}")
    else:
        assemble(args.input_root.expanduser(), args.output_dir.expanduser(), args.font_dir.expanduser(), args.overwrite)


if __name__ == "__main__":
    main()
