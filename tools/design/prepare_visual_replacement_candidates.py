#!/usr/bin/env python3
"""Prepare grounded ImageGen output for the visual-replacement workbench.

This tool is intentionally candidate-only. It validates targets against both the
active hand-authored workbench and its generated inventory, then writes normalized
RGBA PNGs below ``to-be/assets`` plus unit comparison sheets. It never updates the
workbench ledger, production assets, runtime code, or approval state.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from hashlib import sha256
from io import BytesIO
import json
import math
from pathlib import Path, PurePosixPath
import re
import sys
from typing import Any

from PIL import Image, ImageDraw, ImageFont, ImageOps, PngImagePlugin


CANONICAL_SPEC = "docs/design/VISUAL_SYSTEM.md"
CANONICAL_REFERENCE = "docs/design/cardborne-universal-art-style-reference.png"
REFERENCE_SHA256 = "96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889"
WORKBENCH_PATH = "docs/design/visual-replacement-workbench/replacement-workbench.json"
INVENTORY_PATH = "docs/design/visual-replacement-workbench/inventory.json"
TO_BE_PREFIX = "docs/design/visual-replacement-workbench/to-be/assets"
PREVIEW_ROOT = "docs/design/visual-replacement-workbench/previews/final-batch"
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
RESAMPLING = Image.Resampling.LANCZOS
SAFE_UNIT_ID = re.compile(r"^[a-z0-9][a-z0-9_-]*$")


class CandidateError(RuntimeError):
    """Raised for an invalid mapping, source, candidate, or workbench contract."""


@dataclass(frozen=True)
class Deliverable:
    unit_id: str
    status: str
    target: str
    output_relative: str
    width: int
    height: int
    pivot: tuple[int, int]


@dataclass(frozen=True)
class Mapping:
    source: Path
    target: str
    chroma: tuple[int, int, int]
    chroma_tolerance: float
    chroma_softness: float
    despill: float
    alpha_threshold: int
    source_pivot: tuple[float, float] | None
    target_footprint: tuple[int, int, int, int] | None
    template_path: Path | None
    fit_fraction: float
    expected_source_sha256: str | None


@dataclass
class PreparedCandidate:
    deliverable: Deliverable
    mapping: Mapping
    image: Image.Image
    footprint: tuple[int, int, int, int]
    alpha_bbox: tuple[int, int, int, int]
    png_bytes: bytes
    source_sha256: str
    candidate_sha256: str
    as_is: Image.Image | None


def _sha256_path(path: Path) -> str:
    digest = sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _read_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise CandidateError(f"cannot read JSON {path}: {exc}") from exc


def _repo_relative(value: str, label: str) -> str:
    path = PurePosixPath(value.replace("\\", "/"))
    if path.is_absolute() or not path.parts or ".." in path.parts:
        raise CandidateError(f"{label} must be a safe repository-relative path: {value!r}")
    return path.as_posix()


def _resolve_source(value: str, manifest_dir: Path) -> Path:
    path = Path(value).expanduser()
    return path.resolve() if path.is_absolute() else (manifest_dir / path).resolve()


def _parse_pair(value: Any, label: str) -> tuple[int, int]:
    if not isinstance(value, list) or len(value) != 2 or not all(isinstance(x, int) for x in value):
        raise CandidateError(f"{label} must be [integer, integer]")
    return value[0], value[1]


def _parse_rect(value: Any, label: str) -> tuple[int, int, int, int]:
    if not isinstance(value, list) or len(value) != 4 or not all(isinstance(x, int) for x in value):
        raise CandidateError(f"{label} must be [left, top, right, bottom] integers")
    left, top, right, bottom = value
    if left < 0 or top < 0 or right <= left or bottom <= top:
        raise CandidateError(f"{label} must be a non-empty, non-negative rectangle")
    return left, top, right, bottom


def _parse_chroma(value: Any) -> tuple[int, int, int]:
    if isinstance(value, str) and re.fullmatch(r"#[0-9a-fA-F]{6}", value):
        return tuple(int(value[index : index + 2], 16) for index in (1, 3, 5))  # type: ignore[return-value]
    if isinstance(value, list) and len(value) == 3 and all(isinstance(x, int) and 0 <= x <= 255 for x in value):
        return value[0], value[1], value[2]
    raise CandidateError("mapping chroma must be #RRGGBB or [r, g, b]")


def _validate_authority(repo_root: Path, evidence: Any) -> str:
    if not isinstance(evidence, dict):
        raise CandidateError("mapping manifest requires visual_authority_evidence")
    required = {
        "style_authority": CANONICAL_SPEC,
        "style_reference_sheet": CANONICAL_REFERENCE,
        "style_reference_sha256": REFERENCE_SHA256,
        "document_read_completely": True,
        "sheet_inspected_original_detail": True,
        "actual_image_reference_used": True,
    }
    for key, expected in required.items():
        if evidence.get(key) != expected:
            raise CandidateError(f"visual_authority_evidence.{key} must equal {expected!r}")
    method = evidence.get("reference_input_method")
    if not isinstance(method, str) or not method.strip() or method == "not_applicable":
        raise CandidateError(
            "visual_authority_evidence.reference_input_method must name the actual image-reference input"
        )
    spec = repo_root / CANONICAL_SPEC
    reference = repo_root / CANONICAL_REFERENCE
    if not spec.is_file() or not reference.is_file():
        raise CandidateError("canonical visual authority pair is missing")
    observed = _sha256_path(reference)
    if observed != REFERENCE_SHA256:
        raise CandidateError(f"visual reference SHA-256 mismatch: {observed}")
    return method.strip()


def _deliverable_index(repo_root: Path) -> dict[str, Deliverable]:
    workbench = _read_json(repo_root / WORKBENCH_PATH)
    inventory = _read_json(repo_root / INVENTORY_PATH)
    if not isinstance(workbench, dict) or not isinstance(inventory, dict):
        raise CandidateError("workbench and inventory roots must be JSON objects")

    def collect(document: dict[str, Any], generated: bool) -> dict[str, Deliverable]:
        result: dict[str, Deliverable] = {}
        units = document.get("units")
        if not isinstance(units, list):
            raise CandidateError("workbench and inventory must each contain units[]")
        for unit in units:
            if not isinstance(unit, dict):
                raise CandidateError("unit entries must be objects")
            unit_id = unit.get("id")
            if not isinstance(unit_id, str) or not SAFE_UNIT_ID.fullmatch(unit_id):
                raise CandidateError(f"unsafe or missing unit id: {unit_id!r}")
            status = unit.get("status")
            if not isinstance(status, str):
                raise CandidateError(f"unit {unit_id} has no status")
            deliverables = unit.get("deliverables")
            if not isinstance(deliverables, list):
                raise CandidateError(f"unit {unit_id} deliverables must be an array")
            for item in deliverables:
                if not isinstance(item, dict):
                    raise CandidateError(f"unit {unit_id} has a non-object deliverable")
                target = _repo_relative(str(item.get("target_path", "")), "target_path")
                if target in result:
                    raise CandidateError(f"duplicate deliverable target: {target}")
                width = item.get("width")
                height = item.get("height")
                if not isinstance(width, int) or width <= 0 or not isinstance(height, int) or height <= 0:
                    raise CandidateError(f"invalid dimensions for {target}")
                pivot = _parse_pair(item.get("pivot"), f"{target} pivot")
                expected_output = f"{TO_BE_PREFIX}/{target}"
                output = item.get("workbench_path", expected_output)
                output = _repo_relative(str(output), f"{target} workbench_path")
                if generated and output != expected_output:
                    raise CandidateError(f"inventory output path drift for {target}: {output}")
                result[target] = Deliverable(unit_id, status, target, expected_output, width, height, pivot)
        return result

    source_index = collect(workbench, generated=False)
    inventory_index = collect(inventory, generated=True)
    if source_index != inventory_index:
        missing = sorted(set(source_index) ^ set(inventory_index))
        changed = sorted(
            key
            for key in set(source_index) & set(inventory_index)
            if source_index[key] != inventory_index[key]
        )
        raise CandidateError(f"workbench/inventory deliverable drift; missing={missing}, changed={changed}")
    return inventory_index


def _load_mappings(path: Path, repo_root: Path) -> tuple[list[Mapping], str, str]:
    data = _read_json(path)
    if not isinstance(data, dict):
        raise CandidateError("mapping manifest root must be an object")
    reference_method = _validate_authority(repo_root, data.get("visual_authority_evidence"))
    records = data.get("mappings")
    if not isinstance(records, list) or not records:
        raise CandidateError("mapping manifest requires one or more mappings")
    result: list[Mapping] = []
    for index, record in enumerate(records):
        label = f"mappings[{index}]"
        if not isinstance(record, dict):
            raise CandidateError(f"{label} must be an object")
        source_value = record.get("source")
        if not isinstance(source_value, str) or not source_value:
            raise CandidateError(f"{label}.source must be a path")
        target = _repo_relative(str(record.get("target", "")), f"{label}.target")
        source_pivot_value = record.get("source_pivot")
        if source_pivot_value == "alpha_center":
            source_pivot = None
        elif isinstance(source_pivot_value, list) and len(source_pivot_value) == 2 and all(
            isinstance(x, (int, float)) and math.isfinite(x) for x in source_pivot_value
        ):
            source_pivot = float(source_pivot_value[0]), float(source_pivot_value[1])
        else:
            raise CandidateError(f"{label}.source_pivot must be [x, y] or 'alpha_center'")
        footprint = record.get("target_footprint")
        target_footprint = None if footprint is None else _parse_rect(footprint, f"{label}.target_footprint")
        template_value = record.get("template_path")
        template_path = None
        if template_value is not None:
            template_relative = _repo_relative(str(template_value), f"{label}.template_path")
            template_path = repo_root / template_relative
        tolerance = float(record.get("chroma_tolerance", 24.0))
        softness = float(record.get("chroma_softness", 48.0))
        despill = float(record.get("despill", 1.0))
        threshold = int(record.get("alpha_threshold", 3))
        fit_fraction = float(record.get("fit_fraction", 1.0))
        if not 0 <= tolerance <= 441.7 or not 0 < softness <= 441.7:
            raise CandidateError(f"{label} chroma tolerance/softness are outside valid RGB distance")
        if not 0 <= despill <= 1 or not 1 <= threshold <= 255 or not 0 < fit_fraction <= 1:
            raise CandidateError(f"{label} despill, alpha_threshold, or fit_fraction is outside its valid range")
        expected_hash = record.get("source_sha256")
        if expected_hash is not None and not re.fullmatch(r"[0-9a-f]{64}", str(expected_hash)):
            raise CandidateError(f"{label}.source_sha256 must be lowercase SHA-256")
        result.append(
            Mapping(
                source=_resolve_source(source_value, path.parent),
                target=target,
                chroma=_parse_chroma(record.get("chroma")),
                chroma_tolerance=tolerance,
                chroma_softness=softness,
                despill=despill,
                alpha_threshold=threshold,
                source_pivot=source_pivot,
                target_footprint=target_footprint,
                template_path=template_path,
                fit_fraction=fit_fraction,
                expected_source_sha256=None if expected_hash is None else str(expected_hash),
            )
        )
    return result, reference_method, _sha256_path(path)


def _alpha_bbox(image: Image.Image, threshold: int = 1) -> tuple[int, int, int, int]:
    bbox = image.getchannel("A").point(lambda value: 255 if value >= threshold else 0).getbbox()
    if bbox is None:
        raise CandidateError("image has no non-empty alpha content")
    return bbox


def _remove_chroma(image: Image.Image, mapping: Mapping) -> Image.Image:
    source = image.convert("RGBA")
    key_r, key_g, key_b = mapping.chroma
    pixels: list[tuple[int, int, int, int]] = []
    for red, green, blue, source_alpha in source.getdata():
        distance = math.sqrt((red - key_r) ** 2 + (green - key_g) ** 2 + (blue - key_b) ** 2)
        if distance <= mapping.chroma_tolerance:
            matte = 0.0
        elif distance >= mapping.chroma_tolerance + mapping.chroma_softness:
            matte = 1.0
        else:
            position = (distance - mapping.chroma_tolerance) / mapping.chroma_softness
            matte = position * position * (3.0 - 2.0 * position)
        output_alpha = round(source_alpha * matte)
        if output_alpha < mapping.alpha_threshold or matte <= 0:
            pixels.append((0, 0, 0, 0))
            continue
        if matte < 1 and mapping.despill > 0:
            unmixed = tuple(
                max(0.0, min(255.0, (channel - key * (1.0 - matte)) / matte))
                for channel, key in ((red, key_r), (green, key_g), (blue, key_b))
            )
            weight = mapping.despill * (1.0 - matte)
            red, green, blue = (
                round(original * (1.0 - weight) + clean * weight)
                for original, clean in zip((red, green, blue), unmixed)
            )
        pixels.append((red, green, blue, output_alpha))
    result = Image.new("RGBA", source.size)
    result.putdata(pixels)
    return result


def _load_rgba(path: Path, label: str) -> Image.Image:
    if not path.is_file():
        raise CandidateError(f"{label} does not exist: {path}")
    try:
        with Image.open(path) as image:
            image.load()
            return image.convert("RGBA")
    except (OSError, ValueError) as exc:
        raise CandidateError(f"cannot read {label} {path}: {exc}") from exc


def _footprint(repo_root: Path, mapping: Mapping, deliverable: Deliverable) -> tuple[int, int, int, int]:
    if mapping.target_footprint is not None:
        footprint = mapping.target_footprint
    else:
        template = mapping.template_path or (repo_root / mapping.target)
        if not template.is_file():
            raise CandidateError(f"{mapping.target} needs target_footprint because no template exists: {template}")
        footprint = _alpha_bbox(_load_rgba(template, "template"))
    left, top, right, bottom = footprint
    if right > deliverable.width or bottom > deliverable.height:
        raise CandidateError(f"target footprint exceeds canvas for {mapping.target}: {footprint}")
    pivot_x, pivot_y = deliverable.pivot
    if not left <= pivot_x <= right or not top <= pivot_y <= bottom:
        raise CandidateError(
            f"target pivot {deliverable.pivot} lies outside footprint {footprint} for {mapping.target}"
        )
    return footprint


def _fit_to_pivot(
    trimmed: Image.Image,
    source_pivot: tuple[float, float],
    deliverable: Deliverable,
    footprint: tuple[int, int, int, int],
    fit_fraction: float,
) -> Image.Image:
    source_x, source_y = source_pivot
    if not 0 <= source_x <= trimmed.width or not 0 <= source_y <= trimmed.height:
        raise CandidateError(f"source pivot {source_pivot} is outside trimmed alpha bounds {trimmed.size}")
    target_x, target_y = deliverable.pivot
    left, top, right, bottom = footprint
    source_extents = (source_x, source_y, trimmed.width - source_x, trimmed.height - source_y)
    available = (target_x - left, target_y - top, right - target_x, bottom - target_y)
    limits = [space / extent for space, extent in zip(available, source_extents) if extent > 0]
    if not limits or min(limits) <= 0:
        raise CandidateError(f"pivot-safe footprint cannot contain {deliverable.target}")
    scale = min(limits) * fit_fraction

    for _ in range(24):
        width = max(1, math.floor(trimmed.width * scale))
        height = max(1, math.floor(trimmed.height * scale))
        resized = trimmed.resize((width, height), RESAMPLING)
        resized_pivot = round(source_x * width / trimmed.width), round(source_y * height / trimmed.height)
        origin = target_x - resized_pivot[0], target_y - resized_pivot[1]
        canvas = Image.new("RGBA", (deliverable.width, deliverable.height), (0, 0, 0, 0))
        canvas.alpha_composite(resized, origin)
        bbox = _alpha_bbox(canvas)
        if bbox[0] >= left and bbox[1] >= top and bbox[2] <= right and bbox[3] <= bottom:
            return canvas
        scale *= 0.98
    raise CandidateError(f"could not fit {deliverable.target} within pivot-safe footprint {footprint}")


def _encode_png(image: Image.Image, metadata: PngImagePlugin.PngInfo | None = None) -> bytes:
    output = BytesIO()
    image.save(output, format="PNG", compress_level=9, pnginfo=metadata)
    return output.getvalue()


def _validate_png_bytes(
    png_bytes: bytes,
    deliverable: Deliverable,
    footprint: tuple[int, int, int, int],
) -> tuple[Image.Image, tuple[int, int, int, int]]:
    if not png_bytes.startswith(PNG_SIGNATURE):
        raise CandidateError(f"candidate lacks PNG signature: {deliverable.target}")
    try:
        with Image.open(BytesIO(png_bytes)) as image:
            image.load()
            if image.format != "PNG" or image.mode != "RGBA":
                raise CandidateError(f"candidate must be an RGBA PNG: {deliverable.target}")
            if image.size != (deliverable.width, deliverable.height):
                raise CandidateError(
                    f"candidate dimensions differ for {deliverable.target}: {image.size} != "
                    f"{(deliverable.width, deliverable.height)}"
                )
            copy = image.copy()
    except (OSError, ValueError) as exc:
        raise CandidateError(f"invalid candidate PNG for {deliverable.target}: {exc}") from exc
    bbox = _alpha_bbox(copy)
    left, top, right, bottom = footprint
    if bbox[0] < left or bbox[1] < top or bbox[2] > right or bbox[3] > bottom:
        raise CandidateError(f"candidate alpha bounds {bbox} escape pivot-safe footprint {footprint}")
    pivot_x, pivot_y = deliverable.pivot
    if not 0 <= pivot_x < deliverable.width or not 0 <= pivot_y < deliverable.height:
        raise CandidateError(f"candidate pivot is outside canvas: {deliverable.pivot}")
    return copy, bbox


def _prepare_one(repo_root: Path, mapping: Mapping, deliverable: Deliverable, validate_only: bool) -> PreparedCandidate:
    source_sha = _sha256_path(mapping.source) if mapping.source.is_file() else ""
    if not source_sha:
        raise CandidateError(f"ImageGen source does not exist: {mapping.source}")
    if mapping.expected_source_sha256 and source_sha != mapping.expected_source_sha256:
        raise CandidateError(f"ImageGen source SHA-256 mismatch for {mapping.source}: {source_sha}")
    footprint = _footprint(repo_root, mapping, deliverable)
    output = repo_root / deliverable.output_relative
    if validate_only:
        if not output.is_file():
            raise CandidateError(f"candidate does not exist for validation: {output}")
        png_bytes = output.read_bytes()
    else:
        source = _load_rgba(mapping.source, "ImageGen source")
        keyed = _remove_chroma(source, mapping)
        bbox = _alpha_bbox(keyed, mapping.alpha_threshold)
        trimmed = keyed.crop(bbox)
        if mapping.source_pivot is None:
            source_pivot = trimmed.width / 2.0, trimmed.height / 2.0
        else:
            source_pivot = mapping.source_pivot[0] - bbox[0], mapping.source_pivot[1] - bbox[1]
        candidate = _fit_to_pivot(trimmed, source_pivot, deliverable, footprint, mapping.fit_fraction)
        png_bytes = _encode_png(candidate)
    validated, alpha_bbox = _validate_png_bytes(png_bytes, deliverable, footprint)
    as_is_path = repo_root / mapping.target
    as_is = _load_rgba(as_is_path, "AS-IS asset") if as_is_path.is_file() else None
    return PreparedCandidate(
        deliverable=deliverable,
        mapping=mapping,
        image=validated,
        footprint=footprint,
        alpha_bbox=alpha_bbox,
        png_bytes=png_bytes,
        source_sha256=source_sha,
        candidate_sha256=sha256(png_bytes).hexdigest(),
        as_is=as_is,
    )


def _checker(size: tuple[int, int], step: int = 8) -> Image.Image:
    image = Image.new("RGBA", size, (15, 24, 33, 255))
    draw = ImageDraw.Draw(image)
    for top in range(0, size[1], step):
        for left in range(0, size[0], step):
            if (left // step + top // step) % 2:
                draw.rectangle((left, top, left + step - 1, top + step - 1), fill=(28, 41, 54, 255))
    return image


def _grayscale(image: Image.Image) -> Image.Image:
    gray = ImageOps.grayscale(image.convert("RGB"))
    return Image.merge("RGBA", (gray, gray, gray, image.getchannel("A")))


def _draw_asset_cell(
    sheet: Image.Image,
    image: Image.Image | None,
    box: tuple[int, int, int, int],
    mode: str,
    pivot: tuple[int, int],
    footprint: tuple[int, int, int, int] | None,
) -> None:
    left, top, right, bottom = box
    draw = ImageDraw.Draw(sheet)
    draw.rectangle(box, fill=(10, 17, 24, 255), outline=(70, 90, 110, 255), width=1)
    if image is None:
        draw.line((left + 12, top + 12, right - 12, bottom - 12), fill=(240, 90, 95, 255), width=2)
        draw.line((right - 12, top + 12, left + 12, bottom - 12), fill=(240, 90, 95, 255), width=2)
        return
    content = _grayscale(image) if mode == "grayscale" else image
    background = _checker(content.size)
    background.alpha_composite(content)
    origin_x = left + (right - left - content.width) // 2
    origin_y = top + (bottom - top - content.height) // 2
    sheet.alpha_composite(background, (origin_x, origin_y))
    if mode == "pivot":
        overlay = ImageDraw.Draw(sheet)
        pivot_x, pivot_y = origin_x + pivot[0], origin_y + pivot[1]
        overlay.line((pivot_x - 8, pivot_y, pivot_x + 8, pivot_y), fill=(88, 191, 234, 255), width=1)
        overlay.line((pivot_x, pivot_y - 8, pivot_x, pivot_y + 8), fill=(88, 191, 234, 255), width=1)
        overlay.ellipse((pivot_x - 2, pivot_y - 2, pivot_x + 2, pivot_y + 2), fill=(238, 243, 247, 255))
        if footprint is not None:
            f_left, f_top, f_right, f_bottom = footprint
            overlay.rectangle(
                (origin_x + f_left, origin_y + f_top, origin_x + f_right - 1, origin_y + f_bottom - 1),
                outline=(242, 183, 53, 255),
                width=1,
            )


def _preview_sheet(unit_id: str, candidates: list[PreparedCandidate], reference_method: str) -> bytes:
    font = ImageFont.load_default()
    max_width = max(
        max(candidate.deliverable.width, candidate.as_is.width if candidate.as_is is not None else 0)
        for candidate in candidates
    )
    max_height = max(
        max(candidate.deliverable.height, candidate.as_is.height if candidate.as_is is not None else 0)
        for candidate in candidates
    )
    cell_width = max(128, max_width + 24)
    cell_height = max_height + 24
    label_width = 300
    header_height = 54
    row_gap = 10
    row_height = cell_height + row_gap
    width = label_width + 6 * cell_width + 20
    height = header_height + len(candidates) * row_height + 14
    sheet = Image.new("RGBA", (width, height), (7, 11, 17, 255))
    draw = ImageDraw.Draw(sheet)
    draw.text((12, 10), f"{unit_id} | AS-IS / TO-BE candidate evidence", fill=(238, 243, 247, 255), font=font)
    headings = ("AS-IS 1x", "TO-BE 1x", "AS-IS gray", "TO-BE gray", "AS-IS pivot", "TO-BE pivot")
    for index, heading in enumerate(headings):
        draw.text((label_width + index * cell_width + 8, 32), heading, fill=(158, 173, 188, 255), font=font)
    for row, candidate in enumerate(candidates):
        top = header_height + row * row_height
        draw.text((12, top + 4), Path(candidate.mapping.target).name, fill=(238, 243, 247, 255), font=font)
        draw.text(
            (12, top + 20),
            f"{candidate.deliverable.width}x{candidate.deliverable.height}",
            fill=(158, 173, 188, 255),
            font=font,
        )
        modes = ("actual", "actual", "grayscale", "grayscale", "pivot", "pivot")
        images = (candidate.as_is, candidate.image, candidate.as_is, candidate.image, candidate.as_is, candidate.image)
        for column, (mode, image) in enumerate(zip(modes, images)):
            left = label_width + column * cell_width
            box = (left, top, left + cell_width - 6, top + cell_height)
            footprint = candidate.footprint if column == 5 else None
            _draw_asset_cell(sheet, image, box, mode, candidate.deliverable.pivot, footprint)
    metadata = PngImagePlugin.PngInfo()
    metadata.add_text("unit_id", unit_id)
    metadata.add_text("style_authority", CANONICAL_SPEC)
    metadata.add_text("style_reference_sheet", CANONICAL_REFERENCE)
    metadata.add_text("style_reference_sha256", REFERENCE_SHA256)
    metadata.add_text("actual_image_reference_used", "true")
    metadata.add_text("reference_input_method", reference_method)
    metadata.add_text(
        "targets",
        json.dumps([candidate.mapping.target for candidate in candidates], separators=(",", ":")),
    )
    metadata.add_text(
        "source_sha256",
        json.dumps({candidate.mapping.target: candidate.source_sha256 for candidate in candidates}, sort_keys=True),
    )
    metadata.add_text(
        "candidate_sha256",
        json.dumps({candidate.mapping.target: candidate.candidate_sha256 for candidate in candidates}, sort_keys=True),
    )
    return _encode_png(sheet, metadata)


def _atomic_write(path: Path, content: bytes, overwrite: bool) -> None:
    if path.exists() and not overwrite:
        raise CandidateError(f"refusing to replace existing candidate without --overwrite: {path}")
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(f".{path.name}.tmp")
    temporary.write_bytes(content)
    temporary.replace(path)


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Normalize grounded ImageGen files into workbench-only candidate PNGs and comparison sheets.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""Mapping manifest shape:
  {
    "visual_authority_evidence": {
      "style_authority": "docs/design/VISUAL_SYSTEM.md",
      "style_reference_sheet": "docs/design/cardborne-universal-art-style-reference.png",
      "style_reference_sha256": "96ccf5d053e66dd3a102ccdf39daefd0b0c54b0e88d20428b7ba1c894f002889",
      "document_read_completely": true,
      "sheet_inspected_original_detail": true,
      "actual_image_reference_used": true,
      "reference_input_method": "image_gen.referenced_image_paths"
    },
    "mappings": [{
      "source": "generated/source.png",
      "source_sha256": "optional exact lowercase hash",
      "target": "art/visuals/production/gameplay/.../asset.png",
      "chroma": "#00ff00",
      "source_pivot": [512, 512],
      "template_path": "optional/repo/template.png",
      "target_footprint": [left, top, right, bottom]
    }]
  }

Relative source paths resolve from the mapping manifest. Targets and templates are
repository-relative. Omit target_footprint to derive it from template_path or the
current production target. New targets require an explicit target_footprint.
""",
    )
    parser.add_argument(
        "mapping_manifest",
        type=Path,
        help="JSON manifest containing one or more explicit source-to-target mappings",
    )
    parser.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parents[2], help=argparse.SUPPRESS)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--dry-run", action="store_true", help="transform and validate entirely in memory; write nothing")
    mode.add_argument(
        "--validate-only",
        action="store_true",
        help="validate mapped existing candidates and preview composition; write nothing",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="replace existing workbench candidates/previews (never production files)",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _build_parser().parse_args(argv)
    try:
        repo_root = args.repo_root.resolve()
        manifest_path = args.mapping_manifest.resolve()
        deliverables = _deliverable_index(repo_root)
        mappings, reference_method, manifest_sha = _load_mappings(manifest_path, repo_root)
        seen: set[str] = set()
        prepared: list[PreparedCandidate] = []
        for mapping in mappings:
            if mapping.target in seen:
                raise CandidateError(f"mapping target appears more than once: {mapping.target}")
            seen.add(mapping.target)
            deliverable = deliverables.get(mapping.target)
            if deliverable is None:
                raise CandidateError(f"mapping target is not an active workbench deliverable: {mapping.target}")
            writable_statuses = {"target_required", "switch_ready"}
            validation_statuses = writable_statuses | {"approved_for_switch"}
            allowed_statuses = validation_statuses if args.validate_only else writable_statuses
            if deliverable.status not in allowed_statuses:
                raise CandidateError(
                    f"unit {deliverable.unit_id} status {deliverable.status!r} does not allow "
                    f"{'validation' if args.validate_only else 'candidate preparation'}"
                )
            prepared.append(_prepare_one(repo_root, mapping, deliverable, args.validate_only))

        by_unit: dict[str, list[PreparedCandidate]] = {}
        for candidate in prepared:
            by_unit.setdefault(candidate.deliverable.unit_id, []).append(candidate)
        previews = {
            unit_id: _preview_sheet(unit_id, sorted(items, key=lambda item: item.mapping.target), reference_method)
            for unit_id, items in sorted(by_unit.items())
        }
        if not args.dry_run and not args.validate_only:
            planned_outputs = [repo_root / item.deliverable.output_relative for item in prepared]
            planned_outputs.extend(repo_root / PREVIEW_ROOT / f"{unit_id}.png" for unit_id in previews)
            conflicts = [str(path) for path in planned_outputs if path.exists()]
            if conflicts and not args.overwrite:
                raise CandidateError(
                    "refusing batch because outputs already exist without --overwrite: " + ", ".join(conflicts)
                )
            for candidate in prepared:
                _atomic_write(repo_root / candidate.deliverable.output_relative, candidate.png_bytes, args.overwrite)
            for unit_id, content in previews.items():
                _atomic_write(repo_root / PREVIEW_ROOT / f"{unit_id}.png", content, args.overwrite)

        summary = {
            "mode": "validate-only" if args.validate_only else "dry-run" if args.dry_run else "write",
            "mapping_manifest_sha256": manifest_sha,
            "visual_authority": {
                "style_authority": CANONICAL_SPEC,
                "style_reference_sheet": CANONICAL_REFERENCE,
                "expected_and_observed_sha256": REFERENCE_SHA256,
                "actual_image_reference_used": True,
                "reference_input_method": reference_method,
            },
            "candidates": [
                {
                    "unit_id": item.deliverable.unit_id,
                    "source": str(item.mapping.source),
                    "source_sha256": item.source_sha256,
                    "target": item.mapping.target,
                    "output": item.deliverable.output_relative,
                    "candidate_sha256": item.candidate_sha256,
                    "dimensions": [item.deliverable.width, item.deliverable.height],
                    "pivot": list(item.deliverable.pivot),
                    "alpha_bbox": list(item.alpha_bbox),
                    "footprint": list(item.footprint),
                }
                for item in prepared
            ],
            "previews": [f"{PREVIEW_ROOT}/{unit_id}.png" for unit_id in previews],
            "writes_performed": not args.dry_run and not args.validate_only,
        }
        print(json.dumps(summary, indent=2, ensure_ascii=False))
        return 0
    except CandidateError as exc:
        print(f"candidate preparation failed: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
