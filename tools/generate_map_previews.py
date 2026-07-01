from __future__ import annotations

import html
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "data" / "design" / "first_slice" / "stage_layouts.json"
OUT_DIR = ROOT / "docs" / "maps" / "generated"


TILE_COLORS = {
    "S": "#2f80ed",
    "E": "#27ae60",
    "B": "#8e44ad",
    "#": "#4a4f55",
    "=": "#7f8c8d",
    "P": "#16a085",
    "^": "#e74c3c",
    "~": "#8eec9d",
    "!": "#f1c40f",
    "W": "#d35400",
    "C": "#c0392b",
    "R": "#9b59b6",
    "m": "#7bed9f",
    "$": "#f39c12",
    "M": "#00a8a8",
    "T": "#b9770e",
    "K": "#f7dc6f",
    "G": "#2c3e50",
    ".": "#f7f8fa",
    " ": "#ffffff",
}

LABELS = {
    "S": "S",
    "E": "E",
    "B": "B",
    "W": "W",
    "C": "C",
    "R": "R",
    "m": "m",
    "$": "$",
    "M": "M",
    "T": "T",
    "K": "K",
    "G": "G",
    "!": "!",
}


def load_data() -> dict:
    with SOURCE.open("r", encoding="utf-8") as f:
        return json.load(f)


def validate_layout(stage: dict, legend: dict) -> tuple[int, int]:
    rows = stage["layout"]
    if not rows:
        raise ValueError(f"{stage['id']} has no layout rows")

    width = len(rows[0])
    for index, row in enumerate(rows):
        if len(row) != width:
            raise ValueError(
                f"{stage['id']} row {index} width {len(row)} does not match {width}"
            )

    allowed_symbols = set(legend)
    used_symbols = {symbol for row in rows for symbol in row}
    unknown_symbols = sorted(used_symbols - allowed_symbols)
    if unknown_symbols:
        joined = ", ".join(repr(symbol) for symbol in unknown_symbols)
        raise ValueError(f"{stage['id']} uses symbols not declared in legend: {joined}")

    stage_type = stage.get("stage_type")
    missing_symbols = []
    if "S" not in used_symbols:
        missing_symbols.append("S player spawn")
    if stage_type == "normal" and "E" not in used_symbols:
        missing_symbols.append("E exit portal")
    if stage_type == "boss" and "B" not in used_symbols:
        missing_symbols.append("B boss spawn")
    if missing_symbols:
        raise ValueError(f"{stage['id']} is missing required symbols: {', '.join(missing_symbols)}")

    if stage_type == "boss" and "E" in used_symbols:
        raise ValueError(
            f"{stage['id']} should not pre-place an exit portal; boss clear flow spawns or shows it after defeat"
        )

    return width, len(rows)


def render_stage_svg(stage: dict, tile_size: int, legend: dict) -> str:
    width, height = validate_layout(stage, legend)
    canvas_width = width * tile_size
    canvas_height = height * tile_size
    title = html.escape(stage["display_name"])
    purpose = html.escape(stage.get("purpose", ""))

    parts = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        (
            f'<svg xmlns="http://www.w3.org/2000/svg" width="{canvas_width}" '
            f'height="{canvas_height + 96}" viewBox="0 0 {canvas_width} {canvas_height + 96}">'
        ),
        '<rect width="100%" height="100%" fill="#f8f9fb"/>',
        f'<text x="12" y="24" font-family="Arial, sans-serif" font-size="18" font-weight="700" fill="#1f2933">{title}</text>',
        f'<text x="12" y="46" font-family="Arial, sans-serif" font-size="12" fill="#52606d">{purpose}</text>',
        f'<g transform="translate(0, 64)">',
    ]

    for y, row in enumerate(stage["layout"]):
        for x, symbol in enumerate(row):
            color = TILE_COLORS.get(symbol, "#ff00ff")
            label = LABELS.get(symbol)
            tile_x = x * tile_size
            tile_y = y * tile_size
            if symbol == " ":
                continue

            title_text = html.escape(legend.get(symbol, "unknown"))
            parts.append(
                f'<rect x="{tile_x}" y="{tile_y}" width="{tile_size}" height="{tile_size}" '
                f'fill="{color}" stroke="#d0d7de" stroke-width="0.5"><title>{title_text}</title></rect>'
            )
            if label:
                parts.append(
                    f'<text x="{tile_x + tile_size / 2}" y="{tile_y + tile_size * 0.68}" '
                    f'text-anchor="middle" font-family="Arial, sans-serif" font-size="{max(10, tile_size * 0.55)}" '
                    f'font-weight="700" fill="#111827">{html.escape(label)}</text>'
                )

    parts.extend(["</g>", "</svg>"])
    return "\n".join(parts)


def write_index(stages: list[dict]) -> None:
    lines = [
        "# Generated Map Previews",
        "",
        "Generated from `data/design/first_slice/stage_layouts.json`.",
        "",
    ]
    for stage in stages:
        filename = f"{stage['id']}.svg"
        lines.append(f"- [{stage['display_name']}]({filename})")
    lines.append("")
    (OUT_DIR / "map_index.md").write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    data = load_data()
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    tile_size = int(data.get("tile_size", 24))
    legend = data.get("legend", {})
    stages = data.get("stages", [])
    if not legend:
        raise ValueError("No legend found")
    if not stages:
        raise ValueError("No stages found")

    for stage in stages:
        svg = render_stage_svg(stage, tile_size, legend)
        (OUT_DIR / f"{stage['id']}.svg").write_text(svg, encoding="utf-8")

    write_index(stages)
    print(f"Generated {len(stages)} map previews in {OUT_DIR}")


if __name__ == "__main__":
    main()
