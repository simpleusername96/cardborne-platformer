"""Normalize generated sprite figures into an exact, baseline-aligned atlas.

The image generator places figures approximately on a grid. Runtime atlases need
exact cells, so this tool extracts the largest alpha-connected figures and
re-centers them without redrawing or interpolating gameplay state.
"""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--columns", type=int, default=4)
    parser.add_argument("--rows", type=int, default=2)
    parser.add_argument("--cell-size", type=int, default=512)
    parser.add_argument("--scale", type=float, default=0.9)
    parser.add_argument("--baseline", type=int, default=482)
    parser.add_argument("--alpha-threshold", type=int, default=16)
    parser.add_argument("--minimum-area", type=int, default=1_000)
    return parser.parse_args()


def find_figure_bounds(
    image: Image.Image,
    expected_count: int,
    columns: int,
    alpha_threshold: int,
    minimum_area: int,
) -> tuple[np.ndarray, list[tuple[int, tuple[int, int, int, int]]]]:
    alpha = np.asarray(image.getchannel("A")) > alpha_threshold
    labels, _ = ndimage.label(alpha, structure=np.ones((3, 3), dtype=np.uint8))
    figures: list[tuple[int, tuple[int, int, int, int], float, float, int]] = []
    for label_index, slices in enumerate(ndimage.find_objects(labels), start=1):
        if slices is None:
            continue
        y_slice, x_slice = slices
        area = int(np.count_nonzero(labels[slices] == label_index))
        if area < minimum_area:
            continue
        bounds = (x_slice.start, y_slice.start, x_slice.stop, y_slice.stop)
        center_x = (x_slice.start + x_slice.stop) * 0.5
        center_y = (y_slice.start + y_slice.stop) * 0.5
        figures.append((area, bounds, center_x, center_y, label_index))

    if len(figures) < expected_count:
        raise ValueError(
            f"Expected {expected_count} figures, found {len(figures)} above area "
            f"{minimum_area}"
        )

    selected = sorted(figures, key=lambda item: item[0], reverse=True)[:expected_count]
    selected.sort(key=lambda item: item[3])
    ordered: list[tuple[int, tuple[int, int, int, int]]] = []
    for row_start in range(0, expected_count, columns):
        row = sorted(selected[row_start : row_start + columns], key=lambda item: item[2])
        ordered.extend((item[4], item[1]) for item in row)
    return labels, ordered


def normalize_sheet(args: argparse.Namespace) -> None:
    source = Image.open(args.input).convert("RGBA")
    expected_count = args.columns * args.rows
    labels, figures = find_figure_bounds(
        source,
        expected_count,
        args.columns,
        args.alpha_threshold,
        args.minimum_area,
    )
    output = Image.new(
        "RGBA",
        (args.columns * args.cell_size, args.rows * args.cell_size),
        (0, 0, 0, 0),
    )

    source_pixels = np.asarray(source).copy()
    for index, (label_index, figure_bounds) in enumerate(figures):
        left, top, right, bottom = figure_bounds
        figure_pixels = source_pixels[top:bottom, left:right].copy()
        figure_labels = labels[top:bottom, left:right]
        figure_pixels[figure_labels != label_index, 3] = 0
        figure = Image.fromarray(figure_pixels, mode="RGBA")
        target_size = (
            max(1, round(figure.width * args.scale)),
            max(1, round(figure.height * args.scale)),
        )
        if target_size[0] >= args.cell_size or target_size[1] > args.baseline:
            raise ValueError(
                f"Figure {index} does not fit: {target_size} in "
                f"{args.cell_size}x{args.cell_size} cell"
            )
        figure = figure.resize(target_size, Image.Resampling.LANCZOS)
        column = index % args.columns
        row = index // args.columns
        x = column * args.cell_size + (args.cell_size - figure.width) // 2
        y = row * args.cell_size + args.baseline - figure.height
        output.alpha_composite(figure, (x, y))

    args.output.parent.mkdir(parents=True, exist_ok=True)
    output.save(args.output)
    print(
        f"Wrote {args.output} ({output.width}x{output.height}, "
        f"{args.columns}x{args.rows}, scale={args.scale})"
    )


if __name__ == "__main__":
    normalize_sheet(parse_args())
