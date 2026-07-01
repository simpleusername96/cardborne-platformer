from __future__ import annotations

import html
import json
import textwrap
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "data" / "design" / "first_slice" / "ui_screen_skeletons.json"
OUT_DIR = ROOT / "docs" / "uiux" / "generated"


COLORS = {
    "background": "#101419",
    "world": "#1d2730",
    "panel": "#202a33",
    "button": "#2b6c76",
    "card": "#28313a",
    "bar": "#d7a441",
    "slot": "#34414c",
    "avatar": "#4fb6a8",
    "enemy": "#b95f45",
    "warning": "#d05b4f",
    "platform": "#63707a",
    "shop": "#a87943",
    "text": "#f4efe3",
    "muted": "#b7c0c8",
    "stroke": "#d7d0bd",
}

REQUIRED_FIELDS = {"type", "x", "y", "w", "h", "label"}
ELEMENT_TYPES = {
    "world",
    "panel",
    "button",
    "text",
    "bar",
    "card",
    "avatar",
    "slot",
    "platform",
    "enemy",
    "warning",
    "shop",
}


def load_data() -> dict:
    with SOURCE.open("r", encoding="utf-8") as f:
        return json.load(f)


def validate(data: dict) -> tuple[int, int, list[dict]]:
    canvas = data.get("canvas", {})
    width = int(canvas.get("width", 1280))
    height = int(canvas.get("height", 720))
    screens = data.get("screens", [])
    if not screens:
        raise ValueError("No screens found")

    seen_ids = set()
    for screen in screens:
        screen_id = screen.get("id")
        if not screen_id:
            raise ValueError("Screen missing id")
        if screen_id in seen_ids:
            raise ValueError(f"Duplicate screen id: {screen_id}")
        seen_ids.add(screen_id)
        elements = screen.get("elements", [])
        if not elements:
            raise ValueError(f"{screen_id} has no elements")
        for element in elements:
            missing = REQUIRED_FIELDS - set(element)
            if missing:
                raise ValueError(f"{screen_id} element missing fields: {sorted(missing)}")
            element_type = element["type"]
            if element_type not in ELEMENT_TYPES:
                raise ValueError(f"{screen_id} has unknown element type: {element_type}")
            x, y, w, h = (int(element[key]) for key in ("x", "y", "w", "h"))
            if x < 0 or y < 0 or w <= 0 or h <= 0:
                raise ValueError(f"{screen_id} has invalid element bounds: {element}")
            if x + w > width or y + h > height:
                raise ValueError(f"{screen_id} element exceeds canvas: {element}")

    return width, height, screens


def text_lines(label: str, width: int, size: int) -> list[str]:
    max_chars = max(8, int(width / max(size * 0.52, 1)))
    return textwrap.wrap(label, width=max_chars, max_lines=4, placeholder="...")


def draw_text(parts: list[str], label: str, x: float, y: float, width: float, size: int, fill: str, weight: str = "600") -> None:
    for index, line in enumerate(text_lines(label, int(width), size)):
        parts.append(
            f'<text x="{x}" y="{y + index * (size + 4)}" '
            f'font-family="Arial, sans-serif" font-size="{size}" font-weight="{weight}" '
            f'fill="{fill}">{html.escape(line)}</text>'
        )


def draw_element(parts: list[str], element: dict, scale: float = 1.0, ox: float = 0.0, oy: float = 0.0) -> None:
    element_type = element["type"]
    x = ox + float(element["x"]) * scale
    y = oy + float(element["y"]) * scale
    w = float(element["w"]) * scale
    h = float(element["h"]) * scale
    label = str(element["label"])
    radius = 6 * scale
    stroke_width = max(0.75, 1.4 * scale)

    if element_type == "world":
        fill = COLORS["world"]
        stroke = "#27323b"
    else:
        fill = COLORS.get(element_type, COLORS["panel"])
        stroke = COLORS["stroke"]

    opacity = "0.92"
    if element_type == "world":
        opacity = "1"
    if element_type == "warning":
        opacity = "0.78"

    parts.append(
        f'<rect x="{x:.2f}" y="{y:.2f}" width="{w:.2f}" height="{h:.2f}" rx="{radius:.2f}" '
        f'fill="{fill}" fill-opacity="{opacity}" stroke="{stroke}" stroke-width="{stroke_width:.2f}"/>'
    )

    if element_type == "bar":
        parts.append(
            f'<rect x="{x + 8 * scale:.2f}" y="{y + h * 0.55:.2f}" width="{w * 0.66:.2f}" '
            f'height="{max(4, h * 0.22):.2f}" rx="{2 * scale:.2f}" fill="#f1c75b"/>'
        )

    if element_type == "avatar":
        parts.append(
            f'<circle cx="{x + w / 2:.2f}" cy="{y + h * 0.27:.2f}" r="{min(w, h) * 0.16:.2f}" fill="#d8f3ec"/>'
        )
        parts.append(
            f'<rect x="{x + w * 0.24:.2f}" y="{y + h * 0.42:.2f}" width="{w * 0.52:.2f}" '
            f'height="{h * 0.42:.2f}" rx="{4 * scale:.2f}" fill="#d8f3ec"/>'
        )

    if element_type == "enemy":
        parts.append(
            f'<ellipse cx="{x + w / 2:.2f}" cy="{y + h * 0.55:.2f}" rx="{w * 0.36:.2f}" '
            f'ry="{h * 0.28:.2f}" fill="#f0c0a8"/>'
        )

    if element_type != "world":
        size = max(8, int(16 * scale))
        fill_text = "#111827" if element_type in {"button", "bar", "warning"} else COLORS["text"]
        draw_text(parts, label, x + 14 * scale, y + 26 * scale, max(40, w - 24 * scale), size, fill_text)


def render_screen(screen: dict, canvas_w: int, canvas_h: int) -> str:
    parts = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{canvas_w}" height="{canvas_h}" viewBox="0 0 {canvas_w} {canvas_h}">',
        f'<rect width="{canvas_w}" height="{canvas_h}" fill="{COLORS["background"]}"/>',
    ]
    for element in screen["elements"]:
        draw_element(parts, element)
    parts.append("</svg>")
    return "\n".join(parts)


def render_overview(screens: list[dict], canvas_w: int, canvas_h: int) -> str:
    scale = 0.23
    thumb_w = canvas_w * scale
    thumb_h = canvas_h * scale
    gap_x = 32
    gap_y = 58
    cols = 2
    rows = (len(screens) + cols - 1) // cols
    out_w = int(cols * thumb_w + (cols + 1) * gap_x)
    out_h = int(rows * thumb_h + (rows + 1) * gap_y)

    parts = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{out_w}" height="{out_h}" viewBox="0 0 {out_w} {out_h}">',
        '<rect width="100%" height="100%" fill="#0f141a"/>',
    ]
    for index, screen in enumerate(screens):
        col = index % cols
        row = index // cols
        ox = gap_x + col * (thumb_w + gap_x)
        oy = gap_y + row * (thumb_h + gap_y)
        parts.append(
            f'<text x="{ox:.2f}" y="{oy - 14:.2f}" font-family="Arial, sans-serif" '
            f'font-size="18" font-weight="700" fill="#f4efe3">{html.escape(screen["display_name"])}</text>'
        )
        parts.append(
            f'<rect x="{ox - 2:.2f}" y="{oy - 2:.2f}" width="{thumb_w + 4:.2f}" height="{thumb_h + 4:.2f}" '
            f'fill="none" stroke="#485561" stroke-width="2"/>'
        )
        for element in screen["elements"]:
            draw_element(parts, element, scale=scale, ox=ox, oy=oy)
    parts.append("</svg>")
    return "\n".join(parts)


def write_index(screens: list[dict]) -> None:
    lines = [
        "# Generated UI/UX Wireframes",
        "",
        "Generated from `data/design/first_slice/ui_screen_skeletons.json`.",
        "",
        "- [Overview](uiux_overview.svg)",
    ]
    for screen in screens:
        lines.append(f"- [{screen['display_name']}]({screen['id']}.svg)")
    lines.append("")
    (OUT_DIR / "uiux_index.md").write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    data = load_data()
    canvas_w, canvas_h, screens = validate(data)
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    for screen in screens:
        (OUT_DIR / f"{screen['id']}.svg").write_text(
            render_screen(screen, canvas_w, canvas_h),
            encoding="utf-8",
        )

    (OUT_DIR / "uiux_overview.svg").write_text(
        render_overview(screens, canvas_w, canvas_h),
        encoding="utf-8",
    )
    write_index(screens)
    print(f"Generated {len(screens)} UI/UX wireframes in {OUT_DIR}")


if __name__ == "__main__":
    main()
