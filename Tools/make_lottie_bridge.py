#!/usr/bin/env python3
"""Build temporary embedded-image Lottie files for Rive sequence import."""

from __future__ import annotations

import base64
import json
import re
import struct
from dataclasses import dataclass
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
ANIMATIONS_ROOT = PROJECT_ROOT / "Resources" / "Animations"
OUTPUT_ROOT = PROJECT_ROOT / ".build" / "RiveLottieUpload"
FRAME_RATE = 24


@dataclass(frozen=True)
class Sequence:
    prefix: str
    directory: str
    animation_name: str
    expected_frames: int


SEQUENCES = (
    Sequence("01", "idle", "Idle", 90),
    Sequence("02", "point-right", "PointRight", 90),
    Sequence("03", "sad-shrug", "SadShrug", 90),
    Sequence("04", "wave", "Wave", 60),
    Sequence("05", "foam-finger", "FoamFinger", 90),
)


def frame_number(path: Path) -> int:
    match = re.search(r"_(\d+)\.png$", path.name)
    if not match:
        raise ValueError(f"Frame filename has no numeric suffix: {path.name}")
    return int(match.group(1))


def png_dimensions(path: Path) -> tuple[int, int]:
    with path.open("rb") as handle:
        header = handle.read(24)
    if header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        raise ValueError(f"Not a valid PNG: {path}")
    return struct.unpack(">II", header[16:24])


def transform(width: int, height: int) -> dict[str, object]:
    return {
        "o": {"a": 0, "k": 100},
        "r": {"a": 0, "k": 0},
        "p": {"a": 0, "k": [width / 2, height / 2, 0]},
        "a": {"a": 0, "k": [width / 2, height / 2, 0]},
        "s": {"a": 0, "k": [100, 100, 100]},
    }


def build_lottie(sequence: Sequence) -> tuple[dict[str, object], Path]:
    source = ANIMATIONS_ROOT / sequence.directory
    frames = sorted(source.glob("*.png"), key=frame_number)
    if len(frames) != sequence.expected_frames:
        raise ValueError(
            f"{sequence.animation_name}: expected {sequence.expected_frames} frames, "
            f"found {len(frames)}"
        )
    numbers = [frame_number(frame) for frame in frames]
    if numbers != list(range(sequence.expected_frames)):
        raise ValueError(f"{sequence.animation_name}: non-contiguous frame numbers")

    dimensions = {png_dimensions(frame) for frame in frames}
    if dimensions != {(512, 512)}:
        raise ValueError(f"{sequence.animation_name}: unexpected dimensions {dimensions}")

    assets: list[dict[str, object]] = []
    layers: list[dict[str, object]] = []
    for index, frame in enumerate(frames):
        asset_id = f"image_{index:03d}"
        encoded = base64.b64encode(frame.read_bytes()).decode("ascii")
        assets.append(
            {
                "id": asset_id,
                "w": 512,
                "h": 512,
                "u": "",
                "p": f"data:image/png;base64,{encoded}",
                "e": 1,
            }
        )
        layers.append(
            {
                "ddd": 0,
                "ind": index + 1,
                "ty": 2,
                "nm": f"{sequence.animation_name} Frame {index:03d}",
                "refId": asset_id,
                "sr": 1,
                "ks": transform(512, 512),
                "ao": 0,
                "ip": index,
                "op": index + 1,
                "st": 0,
                "bm": 0,
            }
        )

    document: dict[str, object] = {
        "v": "5.12.2",
        "fr": FRAME_RATE,
        "ip": 0,
        "op": sequence.expected_frames,
        "w": 512,
        "h": 512,
        "nm": sequence.animation_name,
        "ddd": 0,
        "assets": assets,
        "layers": layers,
        "markers": [],
    }
    output = OUTPUT_ROOT / f"{sequence.prefix}_{sequence.animation_name}.json"
    return document, output


def main() -> None:
    OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)
    for sequence in SEQUENCES:
        document, output = build_lottie(sequence)
        output.write_text(json.dumps(document, separators=(",", ":")), encoding="utf-8")
        print(
            f"{output.name}: {sequence.expected_frames} frames, "
            f"{sequence.expected_frames / FRAME_RATE:.2f}s, {output.stat().st_size} bytes"
        )


if __name__ == "__main__":
    main()
