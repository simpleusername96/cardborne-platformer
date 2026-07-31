#!/usr/bin/env python3
"""Export generated visual-replacement sources into deterministic runtime PNGs.

The generated chroma-key originals stay immutable under ``sources/``. This
script consumes alpha intermediates produced by the imagegen chroma helper,
normalizes every runtime canvas, writes manifests, and builds review sheets.
"""

from __future__ import annotations

from hashlib import sha256
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[2]
GAME_ROOT = ROOT / "art/gameplay/semantic-v2"
UI_ROOT = ROOT / "art/ui/production/semantic-v2"
ALPHA_ROOT = ROOT / "build/visual-production/alpha"
RESAMPLING = Image.Resampling.LANCZOS

EFFECT_SPECS = [
    ("01-reflect-deflection.png", "reflect_deflection", 5, (96, 96), 20),
    ("02-barrier-contact.png", "barrier_contact", 5, (128, 128), 20),
    ("03-hull-hit.png", "hull_hit", 4, (96, 96), 20),
    ("04-seeker-impact.png", "seeker_impact", 4, (96, 96), 20),
    ("05-escort-drone-impact.png", "escort_drone_impact", 4, (96, 96), 20),
    ("06-orbit-blade-impact.png", "orbit_blade_impact", 4, (96, 96), 20),
    ("07-enemy-destroy-light.png", "enemy_destroy_light", 5, (160, 160), 15),
    ("08-enemy-destroy-heavy.png", "enemy_destroy_heavy", 6, (192, 192), 15),
    ("09-crate-destroy.png", "crate_destroy", 5, (128, 128), 15),
    ("10-pickup-intake.png", "pickup_intake", 4, (96, 96), 20),
    ("11-support-heal.png", "support_heal", 4, (128, 128), 15),
    ("12-lifesteal-pulse.png", "lifesteal_pulse", 4, (64, 64), 20),
    ("13-transit-shift.png", "transit_shift", 5, (160, 96), 15),
    ("14-boss-reduced-hit.png", "boss_reduced_hit", 4, (96, 96), 20),
]

CUE_SPECS = [
    (
        "01-target-priority-ranged.png",
        ["target_bracket_corner", "priority_target", "ranged_startup"],
    ),
    (
        "02-collective-gather-lock-execute.png",
        ["collective_gather", "collective_lock", "collective_execute"],
    ),
    (
        "03-collective-break-elite-traits.png",
        ["collective_break", "elite_armored", "elite_overclocked"],
    ),
    (
        "04-elite-heavy-boss-core.png",
        ["elite_heavy", "boss_core_sealed", "boss_core_open"],
    ),
    (
        "05-boss-objective-states.png",
        ["boss_core_stable", "objective_active", "objective_resolved"],
    ),
    (
        "06-commit-guide-ship.png",
        ["commit_locked", "commit_autonomous", "guide_ship"],
    ),
    (
        "07-guide-role-categories.png",
        ["guide_mobile", "guide_stationary", "guide_bosses"],
    ),
    ("08-guide-objects.png", ["guide_objects"]),
]


def _rgba(path: Path) -> Image.Image:
    return Image.open(path).convert("RGBA")


def _alpha_bbox(image: Image.Image, inset: int = 0) -> tuple[int, int, int, int]:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        raise RuntimeError("empty alpha image")
    left, top, right, bottom = bbox
    return (
        min(max(left + inset, 0), right - 1),
        min(max(top + inset, 0), bottom - 1),
        max(min(right - inset, image.width), left + 1),
        max(min(bottom - inset, image.height), top + 1),
    )


def _fit(
    image: Image.Image,
    canvas: tuple[int, int],
    padding_ratio: float = 0.08,
    stretch: bool = False,
) -> Image.Image:
    cropped = image.crop(_alpha_bbox(image))
    pad_x = max(1, round(canvas[0] * padding_ratio))
    pad_y = max(1, round(canvas[1] * padding_ratio))
    target = (max(1, canvas[0] - pad_x * 2), max(1, canvas[1] - pad_y * 2))
    if stretch:
        resized = cropped.resize(target, RESAMPLING)
    else:
        scale = min(target[0] / cropped.width, target[1] / cropped.height)
        resized = cropped.resize(
            (max(1, round(cropped.width * scale)), max(1, round(cropped.height * scale))),
            RESAMPLING,
        )
    result = Image.new("RGBA", canvas, (0, 0, 0, 0))
    result.alpha_composite(
        resized,
        ((canvas[0] - resized.width) // 2, (canvas[1] - resized.height) // 2),
    )
    return result


def _region(image: Image.Image, rect: tuple[float, float, float, float]) -> Image.Image:
    left, top, right, bottom = rect
    return image.crop(
        (
            round(image.width * left),
            round(image.height * top),
            round(image.width * right),
            round(image.height * bottom),
        )
    )


def _split_x(image: Image.Image, count: int, edge_inset: int = 7) -> list[Image.Image]:
    frames: list[Image.Image] = []
    for index in range(count):
        left = round(image.width * index / count) + edge_inset
        right = round(image.width * (index + 1) / count) - edge_inset
        frames.append(image.crop((left, 0, right, image.height)))
    return frames


def _clear_edge_rows(image: Image.Image, pixels: int) -> Image.Image:
    result = image.copy()
    alpha = result.getchannel("A")
    draw = ImageDraw.Draw(alpha)
    draw.rectangle((0, 0, alpha.width, pixels - 1), fill=0)
    draw.rectangle((0, alpha.height - pixels, alpha.width, alpha.height), fill=0)
    result.putalpha(alpha)
    return result


def _inset_rect(
    rect: tuple[float, float, float, float],
    horizontal: float,
    vertical: float = 0.0,
) -> tuple[float, float, float, float]:
    left, top, right, bottom = rect
    return (
        left + horizontal,
        top + vertical,
        right - horizontal,
        bottom - vertical,
    )


def _recolor_amber(image: Image.Image, target: tuple[int, int, int]) -> Image.Image:
    result = image.copy()
    pixels = result.load()
    for y in range(result.height):
        for x in range(result.width):
            red, green, blue, alpha = pixels[x, y]
            if alpha == 0 or red < 135 or green < 75 or blue > green * 0.78:
                continue
            value = max(red, green, blue) / 255.0
            pixels[x, y] = (
                round(target[0] * value),
                round(target[1] * value),
                round(target[2] * value),
                alpha,
            )
    return result


def _save(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, optimize=True)


def _digest(path: Path) -> str:
    return sha256(path.read_bytes()).hexdigest()


def _export_effects() -> dict[str, dict]:
    animations: dict[str, dict] = {}
    for source_name, effect_id, frame_count, frame_size, fps in EFFECT_SPECS:
        source = _rgba(ALPHA_ROOT / "effects" / source_name)
        if effect_id == "orbit_blade_impact":
            source = _clear_edge_rows(source, 10)
        frames = [
            _fit(frame, frame_size)
            for frame in _split_x(source, frame_count)
        ]
        frame_dir = GAME_ROOT / "effects/frames" / f"fx_{effect_id}"
        frame_paths = []
        for index, frame in enumerate(frames):
            path = frame_dir / f"frame_{index:02d}.png"
            _save(frame, path)
            frame_paths.append(path)
        gutter = 2
        atlas = Image.new(
            "RGBA",
            (frame_size[0] * frame_count + gutter * (frame_count - 1), frame_size[1]),
            (0, 0, 0, 0),
        )
        for index, frame in enumerate(frames):
            atlas.alpha_composite(frame, (index * (frame_size[0] + gutter), 0))
        atlas_path = GAME_ROOT / "effects/atlases" / f"fx_{effect_id}.png"
        _save(atlas, atlas_path)
        animations[effect_id] = {
            "atlas": f"effects/atlases/{atlas_path.name}",
            "frames": f"effects/frames/fx_{effect_id}/frame_{{index:02}}.png",
            "frame_count": frame_count,
            "grid": [frame_count, 1],
            "frame_size": list(frame_size),
            "gutter": gutter,
            "pivot": [frame_size[0] // 2, frame_size[1] // 2],
            "fps": fps,
            "loop": False,
            "source": f"sources/effect-expansion/{source_name}",
        }

    damage_atlas = GAME_ROOT / "effects/atlases/fx_impact_damage.png"
    damage_frames = GAME_ROOT / "effects/frames/fx_impact_damage"
    if not damage_atlas.is_file() or len(list(damage_frames.glob("frame_*.png"))) != 5:
        raise RuntimeError("canonical impact_damage runtime frames are missing")
    animations["impact_damage"] = {
        "atlas": "effects/atlases/fx_impact_damage.png",
        "frames": "effects/frames/fx_impact_damage/frame_{index:02}.png",
        "frame_count": 5,
        "grid": [5, 1],
        "frame_size": [64, 64],
        "gutter": 2,
        "pivot": [32, 32],
        "fps": 20,
        "loop": False,
        "source": "sources/effects/02-impact-damage.png",
    }
    return animations


def _export_cues() -> dict[str, dict]:
    files: dict[str, dict] = {}
    output_root = GAME_ROOT / "hud/combat-cues"
    for source_name, cue_ids in CUE_SPECS:
        source = _rgba(ALPHA_ROOT / "cues" / source_name)
        for cue_id, cue_image in zip(cue_ids, _split_x(source, len(cue_ids))):
            runtime = _fit(cue_image, (96, 96), 0.06)
            path = output_root / f"cue_{cue_id}.png"
            _save(runtime, path)
            files[cue_id] = {
                "path": f"combat-cues/{path.name}",
                "canvas": [96, 96],
                "pivot": [48, 48],
                "source": f"sources/combat-cues/{source_name}",
            }
    return files


def _ui_export(
    component: str,
    state: str,
    image: Image.Image,
    canvas: tuple[int, int],
) -> str:
    relative = Path(_ui_folder(component)) / f"{component}_{state}.png"
    _save(_fit(image, canvas, 0.02, stretch=True), UI_ROOT / relative)
    return relative.as_posix()


def _ui_folder(component: str) -> str:
    if component in {"modal_master", "content_plate", "hud_plate", "upgrade_card"}:
        return "surfaces"
    if component in {"preview", "small_state"}:
        return "glyphs"
    return "controls"


def _component(
    canvas: tuple[int, int],
    patch_margin: int,
    safe_inset: tuple[int, int, int, int],
) -> dict:
    return {
        "canvas": list(canvas),
        "patch_margin": patch_margin,
        "safe_inset": list(safe_inset),
        "states": {},
    }


def _grid_regions(
    bounds: tuple[float, float, float, float],
    columns: int,
    rows: int,
) -> list[tuple[float, float, float, float]]:
    left, top, right, bottom = bounds
    result = []
    for row in range(rows):
        for column in range(columns):
            result.append(
                (
                    left + (right - left) * column / columns,
                    top + (bottom - top) * row / rows,
                    left + (right - left) * (column + 1) / columns,
                    top + (bottom - top) * (row + 1) / rows,
                )
            )
    return result


def _export_ui() -> dict:
    components = {
        "modal_master": _component((192, 192), 32, (36, 32, 32, 32)),
        "content_plate": _component((96, 96), 16, (20, 18, 18, 18)),
        "hud_plate": _component((96, 96), 16, (18, 16, 18, 16)),
        "upgrade_card": _component((128, 128), 20, (24, 22, 22, 22)),
        "button_primary": _component((96, 64), 16, (20, 16, 20, 16)),
        "button_secondary": _component((96, 64), 16, (20, 16, 20, 16)),
        "button_danger": _component((96, 64), 16, (20, 16, 20, 16)),
        "tab_option": _component((96, 48), 16, (18, 12, 18, 12)),
        "toggle": _component((64, 64), 12, (12, 12, 12, 12)),
        "slider": _component((96, 32), 12, (12, 8, 12, 8)),
        "meter": _component((64, 24), 8, (8, 6, 8, 6)),
        "preview": _component((96, 96), 16, (18, 18, 18, 18)),
        "small_state": _component((32, 32), 6, (6, 6, 6, 6)),
    }

    surfaces = _rgba(ALPHA_ROOT / "ui/01-ui-surfaces.png")
    surface_regions = {
        "modal_master": _region(surfaces, (0.02, 0.12, 0.41, 0.82)),
        "content_plate": _region(surfaces, (0.42, 0.22, 0.72, 0.72)),
        "hud_plate": _region(surfaces, (0.73, 0.30, 0.98, 0.65)),
    }
    for state in ("normal", "compact_safe"):
        components["modal_master"]["states"][state] = _ui_export(
            "modal_master", state, surface_regions["modal_master"], (192, 192)
        )
    for state in ("normal", "inset", "summary"):
        components["content_plate"]["states"][state] = _ui_export(
            "content_plate", state, surface_regions["content_plate"], (96, 96)
        )
    for state in (
        "health_resource",
        "objective_boss",
        "minimap_target",
        "action_rail",
        "toast",
    ):
        target = {
            "objective_boss": (212, 63, 141),
            "minimap_target": (88, 191, 234),
            "toast": (88, 191, 234),
        }.get(state, (242, 183, 53))
        components["hud_plate"]["states"][state] = _ui_export(
            "hud_plate",
            state,
            _recolor_amber(surface_regions["hud_plate"], target),
            (96, 96),
        )

    card_source = _rgba(ALPHA_ROOT / "ui/02-upgrade-preview-small-state.png")
    card_states = ["normal", "hover", "pressed", "focus", "selected", "disabled"]
    for state, rect in zip(
        card_states, _grid_regions((0.02, 0.02, 0.58, 0.94), 3, 2)
    ):
        components["upgrade_card"]["states"][state] = _ui_export(
            "upgrade_card", state, _region(card_source, rect), (128, 128)
        )
    for state, rect in zip(
        ["normal", "locked", "focused"],
        _grid_regions((0.60, 0.03, 0.79, 0.94), 1, 3),
    ):
        components["preview"]["states"][state] = _ui_export(
            "preview", state, _region(card_source, rect), (96, 96)
        )
    small_state_regions = [
        (0.81, 0.08, 0.99, 0.17),
        (0.81, 0.20, 0.99, 0.30),
        (0.81, 0.32, 0.99, 0.42),
        (0.81, 0.43, 0.99, 0.57),
        (0.81, 0.58, 0.99, 0.70),
        (0.81, 0.72, 0.99, 0.81),
    ]
    for state, rect in zip(
        [
            "pip_empty",
            "pip_available",
            "pip_filled",
            "warning",
            "disabled",
            "selection_rail",
        ],
        small_state_regions,
    ):
        components["small_state"]["states"][state] = _ui_export(
            "small_state", state, _region(card_source, rect), (32, 32)
        )

    button_source = _rgba(ALPHA_ROOT / "ui/03-button-states.png")
    button_states = ["normal", "hover", "pressed", "focus", "disabled"]
    button_components = ["button_primary", "button_secondary", "button_danger"]
    for component, row in zip(button_components, range(3)):
        for state, column in zip(button_states, range(5)):
            rect = _inset_rect(
                _grid_regions((0.03, 0.16, 0.97, 0.79), 5, 3)[
                    row * 5 + column
                ],
                0.012,
                0.006,
            )
            components[component]["states"][state] = _ui_export(
                component, state, _region(button_source, rect), (96, 64)
            )

    input_source = _rgba(ALPHA_ROOT / "ui/04-tabs-toggle-slider.png")
    for state, rect in zip(
        ["normal", "hover", "selected", "focus", "disabled"],
        _grid_regions((0.04, 0.11, 0.38, 0.83), 1, 5),
    ):
        components["tab_option"]["states"][state] = _ui_export(
            "tab_option", state, _region(input_source, rect), (96, 48)
        )
    for state, rect in zip(
        ["off", "on", "focus"],
        _grid_regions((0.39, 0.28, 0.63, 0.66), 1, 3),
    ):
        components["toggle"]["states"][state] = _ui_export(
            "toggle", state, _region(input_source, rect), (64, 64)
        )
    for state, rect in zip(
        ["lane", "fill", "grabber"],
        _grid_regions((0.66, 0.31, 0.95, 0.68), 1, 3),
    ):
        canvas = (64, 64) if state == "grabber" else (96, 32)
        components["slider"]["states"][state] = _ui_export(
            "slider", state, _region(input_source, rect), canvas
        )

    meter_source = _rgba(ALPHA_ROOT / "ui/05-meter-states.png")
    meter_states = ["background", "health", "boss", "resource", "cooldown", "support"]
    for state, rect in zip(
        meter_states, _grid_regions((0.06, 0.05, 0.94, 0.94), 1, 6)
    ):
        components["meter"]["states"][state] = _ui_export(
            "meter", state, _region(meter_source, rect), (64, 24)
        )
    return components


def _font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    path = ROOT / "art/ui/production/fonts/NotoSansKR-Variable.ttf"
    try:
        return ImageFont.truetype(str(path), size)
    except OSError:
        return ImageFont.load_default()


def _review_sheet(
    title: str,
    items: list[tuple[str, Path]],
    output: Path,
    columns: int,
    cell: tuple[int, int],
) -> None:
    rows = (len(items) + columns - 1) // columns
    width = 48 + columns * cell[0]
    height = 96 + rows * cell[1]
    sheet = Image.new("RGBA", (width, height), (8, 14, 21, 255))
    draw = ImageDraw.Draw(sheet)
    draw.text((24, 20), title, font=_font(28), fill=(238, 243, 247, 255))
    for index, (label, path) in enumerate(items):
        column = index % columns
        row = index // columns
        x = 24 + column * cell[0]
        y = 72 + row * cell[1]
        preview = _fit(_rgba(path), (cell[0] - 24, cell[1] - 44), 0.08)
        sheet.alpha_composite(preview, (x + 12, y))
        draw.text(
            (x + 8, y + cell[1] - 34),
            label,
            font=_font(13),
            fill=(158, 173, 188, 255),
        )
    _save(sheet, output)


def _write_manifests(
    animations: dict[str, dict],
    cues: dict[str, dict],
    ui_components: dict,
) -> None:
    fragment = {
        "schema_version": 1,
        "generated_by": "tools/design/export_visual_replacement_assets.py",
        "animations": animations,
        "combat_cues": cues,
    }
    (GAME_ROOT / "visual-replacement-manifest-fragment.json").write_text(
        json.dumps(fragment, indent=2) + "\n", encoding="utf-8"
    )
    gameplay_manifest_path = GAME_ROOT / "asset-manifest.json"
    gameplay_manifest = json.loads(gameplay_manifest_path.read_text(encoding="utf-8"))
    merged_animations = dict(gameplay_manifest.get("animations", {}))
    merged_animations.pop("impact_reflect", None)
    merged_animations.update(animations)
    gameplay_manifest["animations"] = merged_animations
    gameplay_manifest["asset_sets"] = [
        asset_set
        for asset_set in gameplay_manifest.get("asset_sets", [])
        if asset_set.get("id") != "combat_cues"
    ]
    gameplay_manifest["asset_sets"].append(
        {
            "id": "combat_cues",
            "root": "hud",
            "pivot": "center",
            "files": cues,
        }
    )
    review_sheets = list(gameplay_manifest.get("review_sheets", []))
    for sheet in (
        "sheets/08-effect-semantic-expansion.png",
        "sheets/09-combat-cue-glyphs.png",
    ):
        if sheet not in review_sheets:
            review_sheets.append(sheet)
    gameplay_manifest["review_sheets"] = review_sheets
    gameplay_manifest_path.write_text(
        json.dumps(gameplay_manifest, indent=2) + "\n", encoding="utf-8"
    )

    ui_manifest = {
        "schema_version": 1,
        "pack": "cardborne-ui-semantic-v2",
        "generated_by": "tools/design/export_visual_replacement_assets.py",
        "components": ui_components,
    }
    (UI_ROOT / "ui-asset-manifest.json").write_text(
        json.dumps(ui_manifest, indent=2) + "\n", encoding="utf-8"
    )

    source_paths = sorted(
        list((GAME_ROOT / "sources/effect-expansion").glob("*.png"))
        + list((GAME_ROOT / "sources/combat-cues").glob("*.png"))
        + list((UI_ROOT / "sources").glob("*.png"))
    )
    export_paths = sorted(
        list((GAME_ROOT / "effects").glob("**/*.png"))
        + list((GAME_ROOT / "hud/combat-cues").glob("*.png"))
        + list(UI_ROOT.glob("surfaces/*.png"))
        + list(UI_ROOT.glob("controls/*.png"))
        + list(UI_ROOT.glob("glyphs/*.png"))
    )
    provenance = {
        "generation_route": "built-in imagegen with approved local style references",
        "board_id": "526f17ef-20ec-4112-ab63-11b2ee788495",
        "source_policy": "one named effect per source; at most three cue/UI identities per source",
        "sources": {
            path.relative_to(ROOT).as_posix(): _digest(path) for path in source_paths
        },
        "exports": {
            path.relative_to(ROOT).as_posix(): _digest(path) for path in export_paths
        },
    }
    (UI_ROOT / "production-provenance.json").write_text(
        json.dumps(provenance, indent=2) + "\n", encoding="utf-8"
    )


def main() -> None:
    animations = _export_effects()
    cues = _export_cues()
    ui_components = _export_ui()
    _write_manifests(animations, cues, ui_components)

    effect_items = []
    for effect_id, descriptor in animations.items():
        effect_items.append(
            (
                effect_id,
                GAME_ROOT / descriptor["frames"].replace("{index:02}", "01"),
            )
        )
    _review_sheet(
        "CARDborne · EFFECT SEMANTIC EXPANSION",
        effect_items,
        GAME_ROOT / "sheets/08-effect-semantic-expansion.png",
        4,
        (280, 220),
    )
    cue_items = [
        (cue_id, GAME_ROOT / "hud/combat-cues" / f"cue_{cue_id}.png")
        for cue_id in cues
    ]
    _review_sheet(
        "CARDborne · COMBAT CUE GLYPHS",
        cue_items,
        GAME_ROOT / "sheets/09-combat-cue-glyphs.png",
        5,
        (220, 190),
    )
    surface_items = []
    control_items = []
    for component_id, component in ui_components.items():
        for state_id, relative in component["states"].items():
            item = (f"{component_id}/{state_id}", UI_ROOT / relative)
            if _ui_folder(component_id) == "surfaces":
                surface_items.append(item)
            else:
                control_items.append(item)
    _review_sheet(
        "CARDborne · UI SURFACE COMPONENTS",
        surface_items,
        UI_ROOT / "sheets/01-ui-surface-components.png",
        5,
        (240, 210),
    )
    _review_sheet(
        "CARDborne · UI CONTROL STATES",
        control_items,
        UI_ROOT / "sheets/02-ui-control-states.png",
        6,
        (210, 170),
    )
    print(
        "VISUAL_REPLACEMENT_EXPORT_OK "
        f"effects={len(animations)} cues={len(cues)} "
        f"ui_states={sum(len(v['states']) for v in ui_components.values())}"
    )


if __name__ == "__main__":
    main()
