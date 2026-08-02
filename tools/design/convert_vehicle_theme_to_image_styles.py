#!/usr/bin/env python3
"""Deterministically replace production flat theme chrome with 9-slice assets."""

from __future__ import annotations

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
THEME_PATH = ROOT / "art/visuals/production/ui/vehicle_stage_theme.tres"
MANIFEST_PATH = (
    ROOT / "art/visuals/production/ui/ui-asset-manifest.json"
)

STYLE_MAP = {
    "Modal": ("modal_master", "normal"),
    "Plate": ("content_plate", "normal"),
    "Hud": ("hud_plate", "health_resource"),
    "ChoiceNormal": ("button_secondary", "normal"),
    "ChoiceHover": ("button_secondary", "hover"),
    "ChoicePressed": ("button_secondary", "pressed"),
    "ChoiceFocus": ("button_secondary", "focus"),
    "ChoiceSelected": ("tab_option", "selected"),
    "Disabled": ("button_secondary", "disabled"),
    "UpgradeCardNormal": ("upgrade_card", "normal"),
    "UpgradeCardHover": ("upgrade_card", "hover"),
    "UpgradeCardPressed": ("upgrade_card", "pressed"),
    "UpgradeCardFocus": ("upgrade_card", "focus"),
    "UpgradeCardSelected": ("upgrade_card", "selected"),
    "PrimaryNormal": ("button_primary", "normal"),
    "PrimaryHover": ("button_primary", "hover"),
    "PrimaryPressed": ("button_primary", "pressed"),
    "PrimaryFocus": ("button_primary", "focus"),
    "DangerNormal": ("button_danger", "normal"),
    "DangerHover": ("button_danger", "hover"),
    "DangerPressed": ("button_danger", "pressed"),
    "DangerFocus": ("button_danger", "focus"),
    "MeterBackground": ("meter", "background"),
    "MeterHealth": ("meter", "health"),
    "MeterBoss": ("meter", "boss"),
    "MeterResource": ("meter", "resource"),
    "Slider": ("slider", "lane"),
    "SliderActive": ("slider", "fill"),
    "TabPanel": ("content_plate", "inset"),
    "TabUnselected": ("tab_option", "normal"),
    "TabHovered": ("tab_option", "hover"),
    "TabSelected": ("tab_option", "selected"),
    "FamilyBadge": ("content_plate", "summary"),
    "SummaryBand": ("content_plate", "summary"),
}

EXTRA_STYLE_MAP = {
    "PrimaryDisabled": ("button_primary", "disabled"),
    "DangerDisabled": ("button_danger", "disabled"),
    "UpgradeCardDisabled": ("upgrade_card", "disabled"),
    "TabFocus": ("tab_option", "focus"),
    "ContentInset": ("content_plate", "inset"),
    "ContentSummary": ("content_plate", "summary"),
    "HudHealthResource": ("hud_plate", "health_resource"),
    "HudObjectiveBoss": ("hud_plate", "objective_boss"),
    "HudMinimapTarget": ("hud_plate", "minimap_target"),
    "HudActionRail": ("hud_plate", "action_rail"),
    "HudToast": ("hud_plate", "toast"),
    "PreviewNormal": ("preview", "normal"),
    "PreviewLocked": ("preview", "locked"),
    "PreviewFocused": ("preview", "focused"),
    "MeterCooldown": ("meter", "cooldown"),
    "MeterSupport": ("meter", "support"),
}

EXTRA_TEXTURES = {
    "ui_slider_grabber": ("slider", "grabber"),
    "ui_toggle_off": ("toggle", "off"),
    "ui_toggle_on": ("toggle", "on"),
}


def _resource_id(component_id: str, state_id: str) -> str:
    return f"ui_{component_id}_{state_id}"


def _style_block(
    style_id: str,
    component_id: str,
    state_id: str,
    component: dict,
    previous_body: str,
) -> str:
    patch_margin = float(component["patch_margin"])
    content_lines = [
        line
        for line in previous_body.splitlines()
        if line.startswith("content_margin_")
    ]
    lines = [
        f'[sub_resource type="StyleBoxTexture" id="{style_id}"]',
        f'texture = ExtResource("{_resource_id(component_id, state_id)}")',
        f"texture_margin_left = {patch_margin:.1f}",
        f"texture_margin_top = {patch_margin:.1f}",
        f"texture_margin_right = {patch_margin:.1f}",
        f"texture_margin_bottom = {patch_margin:.1f}",
    ]
    lines.extend(content_lines)
    return "\n".join(lines)


def main() -> None:
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    components = manifest["components"]
    source = THEME_PATH.read_text(encoding="utf-8")

    required_assets = sorted(
        set(STYLE_MAP.values()) | set(EXTRA_STYLE_MAP.values())
    )
    ext_lines = []
    for component_id, state_id in required_assets:
        relative = components[component_id]["states"][state_id]
        path = f"res://art/visuals/production/ui/{relative}"
        ext_lines.append(
            '[ext_resource type="Texture2D" '
            f'path="{path}" id="{_resource_id(component_id, state_id)}"]'
        )
    font_line = (
        '[ext_resource type="FontFile" '
        'path="res://art/visuals/production/ui/fonts/NotoSansKR-Variable.ttf" '
        'id="1_font"]'
    )
    source = re.sub(
        r'^\[ext_resource type="Texture2D"[^\n]+ id="ui_[^"]+"\]\n?',
        "",
        source,
        flags=re.MULTILINE,
    )
    for resource_id, (component_id, state_id) in EXTRA_TEXTURES.items():
        relative = components[component_id]["states"][state_id]
        path = f"res://art/visuals/production/ui/{relative}"
        ext_lines.append(
            '[ext_resource type="Texture2D" '
            f'path="{path}" id="{resource_id}"]'
        )
    source = re.sub(
        r'\[ext_resource type="FontFile"[^\n]+\]',
        font_line + "\n" + "\n".join(ext_lines),
        source,
        count=1,
    )

    block_pattern = re.compile(
        r'\[sub_resource type="StyleBox(?:Flat|Texture)" id="([^"]+)"\]\n'
        r"(.*?)(?=\n\[sub_resource|\n\[resource\])",
        re.DOTALL,
    )

    def replace_block(match: re.Match[str]) -> str:
        style_id = match.group(1)
        if style_id == "HorizontalRule":
            return (
                '[sub_resource type="StyleBoxLine" id="HorizontalRule"]\n'
                "color = Color(0.27451, 0.352941, 0.431373, 1)\n"
                "thickness = 1"
            )
        if style_id == "VerticalRule":
            return (
                '[sub_resource type="StyleBoxLine" id="VerticalRule"]\n'
                "color = Color(0.27451, 0.352941, 0.431373, 1)\n"
                "thickness = 1\n"
                "vertical = true"
            )
        mapping = STYLE_MAP.get(style_id, EXTRA_STYLE_MAP.get(style_id))
        if mapping is None:
            raise ValueError(f"unmapped production StyleBoxFlat: {style_id}")
        component_id, state_id = mapping
        return _style_block(
            style_id,
            component_id,
            state_id,
            components[component_id],
            match.group(2),
        )

    converted = block_pattern.sub(replace_block, source)
    extra_blocks = []
    for style_id, (component_id, state_id) in EXTRA_STYLE_MAP.items():
        converted = re.sub(
            rf'\n?\[sub_resource type="StyleBoxTexture" '
            rf'id="{style_id}"\]\n.*?(?=\n\[sub_resource|\n\[resource\])',
            "",
            converted,
            flags=re.DOTALL,
        )
        extra_blocks.append(
            _style_block(
                style_id,
                component_id,
                state_id,
                components[component_id],
                "",
            )
        )
    converted = converted.replace(
        "\n[resource]",
        "\n" + "\n".join(extra_blocks) + "\n[resource]",
        1,
    )
    converted = converted.replace(
        'PrimaryButton/styles/disabled = SubResource("Disabled")',
        'PrimaryButton/styles/disabled = SubResource("PrimaryDisabled")',
    )
    converted = converted.replace(
        'DangerButton/styles/disabled = SubResource("Disabled")',
        'DangerButton/styles/disabled = SubResource("DangerDisabled")',
    )
    converted = converted.replace(
        'TertiaryDangerButton/styles/disabled = SubResource("Disabled")',
        'TertiaryDangerButton/styles/disabled = SubResource("DangerDisabled")',
    )
    converted = converted.replace(
        'UpgradeChoiceCard/styles/disabled = SubResource("Disabled")',
        'UpgradeChoiceCard/styles/disabled = '
        'SubResource("UpgradeCardDisabled")',
    )
    converted = converted.replace(
        'SelectedUpgradeChoiceCard/styles/disabled = SubResource("Disabled")',
        'SelectedUpgradeChoiceCard/styles/disabled = '
        'SubResource("UpgradeCardDisabled")',
    )
    converted = converted.replace(
        'TabContainer/styles/tab_focus = SubResource("ChoiceFocus")',
        'TabContainer/styles/tab_focus = SubResource("TabFocus")',
    )
    converted = converted.replace(
        'TabBar/styles/tab_focus = SubResource("ChoiceFocus")',
        'TabBar/styles/tab_focus = SubResource("TabFocus")',
    )
    slider_anchor = 'HSlider/styles/grabber_area_highlight = SubResource("SliderActive")'
    slider_icons = (
        slider_anchor
        + '\nHSlider/icons/grabber = ExtResource("ui_slider_grabber")'
        + '\nHSlider/icons/grabber_highlight = ExtResource("ui_slider_grabber")'
    )
    converted = re.sub(
        re.escape(slider_anchor)
        + r'(?:\nHSlider/icons/grabber[^\n]*)'
        + r'(?:\nHSlider/icons/grabber_highlight[^\n]*)?',
        slider_icons,
        converted,
    )
    if 'HSlider/icons/grabber = ExtResource("ui_slider_grabber")' not in converted:
        converted = converted.replace(slider_anchor, slider_icons)
    check_anchor = "CheckButton/font_sizes/font_size = 15"
    check_icons = (
        check_anchor
        + '\nCheckButton/icons/unchecked = ExtResource("ui_toggle_off")'
        + '\nCheckButton/icons/checked = ExtResource("ui_toggle_on")'
    )
    converted = re.sub(
        re.escape(check_anchor)
        + r'(?:\nCheckButton/icons/(?:un)?checked[^\n]*){0,2}',
        check_icons,
        converted,
    )
    variation_lines = [
        'ContentInset/base_type = &"PanelContainer"',
        'ContentInset/styles/panel = SubResource("ContentInset")',
        'ContentSummary/base_type = &"PanelContainer"',
        'ContentSummary/styles/panel = SubResource("ContentSummary")',
        'HudHealthResource/base_type = &"PanelContainer"',
        'HudHealthResource/styles/panel = SubResource("HudHealthResource")',
        'HudObjectiveBoss/base_type = &"PanelContainer"',
        'HudObjectiveBoss/styles/panel = SubResource("HudObjectiveBoss")',
        'HudMinimapTarget/base_type = &"PanelContainer"',
        'HudMinimapTarget/styles/panel = SubResource("HudMinimapTarget")',
        'HudActionRail/base_type = &"PanelContainer"',
        'HudActionRail/styles/panel = SubResource("HudActionRail")',
        'HudToast/base_type = &"PanelContainer"',
        'HudToast/styles/panel = SubResource("HudToast")',
        'PreviewFrame/base_type = &"PanelContainer"',
        'PreviewFrame/styles/panel = SubResource("PreviewNormal")',
        'PreviewLocked/base_type = &"PanelContainer"',
        'PreviewLocked/styles/panel = SubResource("PreviewLocked")',
        'PreviewFocused/base_type = &"PanelContainer"',
        'PreviewFocused/styles/panel = SubResource("PreviewFocused")',
        'CooldownMeter/base_type = &"ProgressBar"',
        'CooldownMeter/styles/background = SubResource("MeterBackground")',
        'CooldownMeter/styles/fill = SubResource("MeterCooldown")',
        'SupportMeter/base_type = &"ProgressBar"',
        'SupportMeter/styles/background = SubResource("MeterBackground")',
        'SupportMeter/styles/fill = SubResource("MeterSupport")',
    ]
    for line in variation_lines:
        converted = converted.replace(line + "\n", "")
    converted = converted.rstrip() + "\n" + "\n".join(variation_lines) + "\n"
    if "StyleBoxFlat" in converted:
        raise ValueError("theme still contains StyleBoxFlat")
    dependency_count = (
        len(re.findall(r"^\[ext_resource ", converted, re.MULTILINE))
        + len(re.findall(r"^\[sub_resource ", converted, re.MULTILINE))
        + 1
    )
    converted = re.sub(
        r"^\[gd_resource type=\"Theme\" load_steps=\d+ format=3\]",
        f'[gd_resource type="Theme" load_steps={dependency_count} format=3]',
        converted,
        count=1,
        flags=re.MULTILINE,
    )
    with THEME_PATH.open("w", encoding="utf-8", newline="\n") as output:
        output.write(converted)


if __name__ == "__main__":
    main()
