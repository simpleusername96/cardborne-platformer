from __future__ import annotations

import argparse
import html
import json
import random
from collections import deque
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RULES_PATH = ROOT / "data" / "design" / "first_slice" / "procedural_region_rules.json"
OUT_DATA_DIR = ROOT / "data" / "design" / "first_slice" / "generated"
OUT_MAP_DIR = ROOT / "docs" / "maps" / "generated" / "procedural"


ROLE_COLORS = {
    "entrance": "#2f80ed",
    "combat_intro": "#d77a35",
    "combat": "#b95f45",
    "vertical_traversal": "#7f8c8d",
    "key_room": "#f2c94c",
    "locked_gate": "#273746",
    "safe_shop": "#27ae60",
    "shortcut": "#16a085",
    "reward_room": "#d68f18",
    "material_cache": "#00a8a8",
    "hazard_challenge": "#d05b4f",
    "lore_or_map_room": "#8e7cc3",
    "boss_approach": "#9b59b6",
    "boss": "#8e44ad",
}


ROLE_LABELS = {
    "entrance": "START",
    "combat_intro": "FIGHT",
    "combat": "FIGHT",
    "vertical_traversal": "SHAFT",
    "key_room": "KEY",
    "locked_gate": "GATE",
    "safe_shop": "SHOP",
    "shortcut": "SHORT",
    "reward_room": "CHEST",
    "material_cache": "MATERIAL",
    "hazard_challenge": "HAZARD",
    "lore_or_map_room": "MAP",
    "boss_approach": "APPROACH",
    "boss": "BOSS",
}


def load_rules() -> dict:
    with RULES_PATH.open("r", encoding="utf-8") as f:
        return json.load(f)


def get_profile(rules: dict, profile_id: str) -> dict:
    for profile in rules["profiles"]:
        if profile["id"] == profile_id:
            return profile
    raise ValueError(f"Unknown profile: {profile_id}")


def contract_by_role(rules: dict) -> dict:
    return {entry["role"]: entry for entry in rules["room_role_contracts"]}


def randint_range(rng: random.Random, value: dict | list[int] | int, default: int = 0) -> int:
    if isinstance(value, int):
        return value
    if isinstance(value, list):
        return rng.randint(int(value[0]), int(value[1]))
    if isinstance(value, dict):
        return rng.randint(int(value["min"]), int(value["max"]))
    return default


def contract_budget(rng: random.Random, contract: dict, key: str) -> int:
    fixed = contract.get(key)
    if fixed is not None:
        return int(fixed)
    return randint_range(rng, contract.get(f"{key}_range", [0, 0]))


def add_room(rooms: list[dict], rng: random.Random, contracts: dict, role: str, x: int, y: int, critical: bool = False) -> str:
    index = len(rooms)
    room_id = f"r{index:02d}_{role}"
    contract = contracts[role]
    rooms.append(
        {
            "id": room_id,
            "role": role,
            "label": ROLE_LABELS.get(role, role.upper()),
            "x": x,
            "y": y,
            "critical_path": critical,
            "danger": contract_budget(rng, contract, "danger"),
            "reward": contract_budget(rng, contract, "reward"),
            "requires": contract.get("requires", []),
            "grants": contract.get("grants", []),
            "safe": bool(contract.get("safe", False)),
        }
    )
    return room_id


def connect(connections: list[dict], a: str, b: str, kind: str = "normal", requirement: str | None = None, opens_from_far_side: bool = False) -> None:
    edge = {"from": a, "to": b, "kind": kind}
    if requirement:
        edge["requires"] = [requirement]
    if opens_from_far_side:
        edge["opens_from_far_side"] = True
    connections.append(edge)


def choose_optional_role(rng: random.Random, weights: dict) -> str:
    roles = list(weights)
    total = sum(int(weights[role]) for role in roles)
    pick = rng.randint(1, total)
    running = 0
    for role in roles:
        running += int(weights[role])
        if pick <= running:
            return role
    return roles[-1]


def generate_region(seed: int, profile_id: str) -> dict:
    rules = load_rules()
    profile = get_profile(rules, profile_id)
    contracts = contract_by_role(rules)
    rng = random.Random(seed)

    critical_len = randint_range(rng, profile["critical_path_length"])
    target_rooms = randint_range(rng, profile["target_room_count"])
    vertical_span = randint_range(rng, profile["vertical_span"])

    rooms: list[dict] = []
    connections: list[dict] = []

    critical_roles = [
        "entrance",
        "combat_intro",
        "vertical_traversal",
        "locked_gate",
        "combat",
        "boss_approach",
        "boss",
    ]
    while len(critical_roles) < critical_len:
        critical_roles.insert(-2, choose_optional_role(rng, {"combat": 4, "hazard_challenge": 2, "vertical_traversal": 1}))

    critical_ids = []
    x = 0
    y = vertical_span - 1
    for i, role in enumerate(critical_roles):
        if role == "vertical_traversal":
            y = max(1, y - rng.randint(2, 3))
        elif i > 0:
            y = max(0, min(vertical_span, y + rng.choice([-1, 0, 1])))
        room_id = add_room(rooms, rng, contracts, role, x, y, critical=True)
        critical_ids.append(room_id)
        x += rng.randint(1, 2)

    for a, b in zip(critical_ids, critical_ids[1:]):
        requirement = "lower_gate_key" if rooms_by_id(rooms)[b]["role"] in {"combat", "boss_approach", "boss"} and rooms_by_id(rooms)[a]["role"] == "locked_gate" else None
        connect(connections, a, b, kind="critical", requirement=requirement)

    id_by_role = {room["role"]: room["id"] for room in rooms}
    vertical_room = id_by_role["vertical_traversal"]
    gate_room = id_by_role["locked_gate"]

    key_room = add_room(
        rooms,
        rng,
        contracts,
        "key_room",
        rooms_by_id(rooms)[vertical_room]["x"] + rng.choice([-1, 1]),
        max(0, rooms_by_id(rooms)[vertical_room]["y"] - rng.randint(1, 2)),
    )
    connect(connections, vertical_room, key_room, kind="key_branch")
    connect(connections, key_room, vertical_room, kind="return")

    safe_room = add_room(
        rooms,
        rng,
        contracts,
        "safe_shop",
        rooms_by_id(rooms)[vertical_room]["x"] - 1,
        min(vertical_span, rooms_by_id(rooms)[vertical_room]["y"] + 1),
    )
    connect(connections, vertical_room, safe_room, kind="safe_branch")

    shortcut_room = add_room(
        rooms,
        rng,
        contracts,
        "shortcut",
        rooms_by_id(rooms)[gate_room]["x"] + 1,
        min(vertical_span, rooms_by_id(rooms)[vertical_room]["y"] + 2),
    )
    connect(connections, gate_room, shortcut_room, kind="shortcut_locked", opens_from_far_side=True)
    connect(connections, shortcut_room, vertical_room, kind="shortcut_return", opens_from_far_side=True)

    anchors = critical_ids[:-1] + [vertical_room]
    while len(rooms) < target_rooms:
        anchor = rng.choice(anchors)
        anchor_room = rooms_by_id(rooms)[anchor]
        role = choose_optional_role(rng, profile["room_role_weights"])
        if role in {"combat_intro", "vertical_traversal"}:
            role = "combat"
        branch = add_room(
            rooms,
            rng,
            contracts,
            role,
            max(0, anchor_room["x"] + rng.choice([-2, -1, 1, 2])),
            max(0, min(vertical_span, anchor_room["y"] + rng.choice([-2, -1, 1, 2]))),
        )
        connect(connections, anchor, branch, kind="side_branch")
        if rng.random() < 0.45:
            connect(connections, branch, anchor, kind="return")

    output = {
        "schema": "cardborne.generated_region_graph.v0",
        "seed": seed,
        "profile_id": profile_id,
        "display_name": f"{profile['display_name']} Seed {seed}",
        "region_id": profile["id"],
        "rooms": rooms,
        "connections": connections,
        "summary": summarize(rooms, connections),
        "validation": validate_region(rooms, connections, profile),
    }
    return output


def rooms_by_id(rooms: list[dict]) -> dict[str, dict]:
    return {room["id"]: room for room in rooms}


def summarize(rooms: list[dict], connections: list[dict]) -> dict:
    return {
        "room_count": len(rooms),
        "connection_count": len(connections),
        "danger_total": sum(room["danger"] for room in rooms),
        "reward_total": sum(room["reward"] for room in rooms),
        "critical_path_rooms": sum(1 for room in rooms if room["critical_path"]),
        "roles": sorted({room["role"] for room in rooms}),
    }


def validate_region(rooms: list[dict], connections: list[dict], profile: dict) -> dict:
    room_map = rooms_by_id(rooms)
    by_role = {}
    for room in rooms:
        by_role.setdefault(room["role"], []).append(room["id"])

    errors = []
    for role in profile["required_roles"]:
        if role not in by_role:
            errors.append(f"missing required role: {role}")

    adjacency: dict[str, list[str]] = {room["id"]: [] for room in rooms}
    for edge in connections:
        adjacency[edge["from"]].append(edge["to"])
        if edge["kind"] in {"return", "shortcut_return", "safe_branch", "side_branch"}:
            adjacency[edge["to"]].append(edge["from"])

    start = by_role.get("entrance", [None])[0]
    reachable = set()
    if start:
        queue = deque([start])
        while queue:
            current = queue.popleft()
            if current in reachable:
                continue
            reachable.add(current)
            queue.extend(adjacency.get(current, []))
    if len(reachable) != len(rooms):
        errors.append("not all rooms are reachable")

    role_index = {room["role"]: i for i, room in enumerate(rooms) if room["critical_path"]}
    if role_index.get("key_room", 999) > role_index.get("locked_gate", 999):
        # The key is intentionally on a side branch, so compare reachability instead.
        key_id = by_role.get("key_room", [None])[0]
        gate_id = by_role.get("locked_gate", [None])[0]
        if not key_id or not gate_id or key_id not in reachable:
            errors.append("key room is not reachable before locked gate")

    danger_total = sum(room["danger"] for room in rooms)
    reward_total = sum(room["reward"] for room in rooms)
    if not (profile["difficulty_budget"]["min"] <= danger_total <= profile["difficulty_budget"]["max"]):
        errors.append(f"danger budget {danger_total} outside profile range")
    if not (profile["reward_budget"]["min"] <= reward_total <= profile["reward_budget"]["max"]):
        errors.append(f"reward budget {reward_total} outside profile range")

    return {
        "ok": not errors,
        "errors": errors,
    }


def render_svg(region: dict) -> str:
    rooms = region["rooms"]
    connections = region["connections"]
    min_x = min(room["x"] for room in rooms)
    min_y = min(room["y"] for room in rooms)
    max_x = max(room["x"] for room in rooms)
    max_y = max(room["y"] for room in rooms)
    cell_w = 170
    cell_h = 110
    margin = 70
    width = (max_x - min_x + 1) * cell_w + margin * 2
    height = (max_y - min_y + 1) * cell_h + margin * 2 + 60

    def pos(room: dict) -> tuple[int, int]:
        return (
            margin + (room["x"] - min_x) * cell_w,
            margin + 60 + (room["y"] - min_y) * cell_h,
        )

    room_map = rooms_by_id(rooms)
    parts = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
        '<rect width="100%" height="100%" fill="#f8f9fb"/>',
        f'<text x="24" y="34" font-family="Arial, sans-serif" font-size="22" font-weight="700" fill="#111827">{html.escape(region["display_name"])}</text>',
        f'<text x="24" y="58" font-family="Arial, sans-serif" font-size="13" fill="#4b5563">rooms {region["summary"]["room_count"]}, danger {region["summary"]["danger_total"]}, reward {region["summary"]["reward_total"]}</text>',
        '<defs><marker id="arrow" markerWidth="10" markerHeight="10" refX="8" refY="3" orient="auto"><path d="M0,0 L0,6 L9,3 z" fill="#4b5563"/></marker></defs>',
    ]

    for edge in connections:
        a = room_map[edge["from"]]
        b = room_map[edge["to"]]
        ax, ay = pos(a)
        bx, by = pos(b)
        color = "#4b5563"
        dash = ""
        width_attr = "2"
        if "shortcut" in edge["kind"]:
            color = "#16a085"
            dash = ' stroke-dasharray="8 6"'
            width_attr = "3"
        elif edge["kind"] == "key_branch":
            color = "#b7791f"
        elif edge.get("requires"):
            color = "#273746"
            width_attr = "4"
        parts.append(
            f'<line x1="{ax + 62}" y1="{ay + 36}" x2="{bx + 62}" y2="{by + 36}" '
            f'stroke="{color}" stroke-width="{width_attr}"{dash} marker-end="url(#arrow)"/>'
        )

    for room in rooms:
        x, y = pos(room)
        color = ROLE_COLORS.get(room["role"], "#888888")
        stroke = "#111827" if room["critical_path"] else "#6b7280"
        parts.append(
            f'<rect x="{x}" y="{y}" width="124" height="72" rx="8" fill="{color}" stroke="{stroke}" stroke-width="2"/>'
        )
        parts.append(
            f'<text x="{x + 12}" y="{y + 26}" font-family="Arial, sans-serif" font-size="13" font-weight="700" fill="#111827">{html.escape(room["label"])}</text>'
        )
        parts.append(
            f'<text x="{x + 12}" y="{y + 46}" font-family="Arial, sans-serif" font-size="11" fill="#111827">D{room["danger"]} R{room["reward"]}</text>'
        )
        if room["requires"]:
            parts.append(
                f'<text x="{x + 12}" y="{y + 62}" font-family="Arial, sans-serif" font-size="10" fill="#111827">req {",".join(room["requires"])}</text>'
            )

    parts.append("</svg>")
    return "\n".join(parts)


def write_index(generated: list[tuple[int, Path, Path]]) -> None:
    lines = [
        "# Procedural Region Examples",
        "",
        "Generated by `tools/generate_region_graph.py` from `data/design/first_slice/procedural_region_rules.json`.",
        "",
    ]
    for seed, json_path, svg_path in generated:
        lines.append(f"- Seed {seed}: [{json_path.name}]({json_path.name}), [{svg_path.name}]({svg_path.name})")
    lines.append("")
    (OUT_MAP_DIR / "procedural_index.md").write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate deterministic first-slice procedural region graph examples.")
    parser.add_argument("--profile", default="lower_ruins_first_slice")
    parser.add_argument("--seed", type=int, action="append", help="Seed to generate. Can be repeated.")
    args = parser.parse_args()

    seeds = args.seed or [1001, 1002, 1003]
    OUT_DATA_DIR.mkdir(parents=True, exist_ok=True)
    OUT_MAP_DIR.mkdir(parents=True, exist_ok=True)

    generated = []
    for seed in seeds:
        region = generate_region(seed, args.profile)
        if not region["validation"]["ok"]:
            raise ValueError(f"Generated invalid region for seed {seed}: {region['validation']['errors']}")
        json_path = OUT_DATA_DIR / f"{args.profile}_{seed}.json"
        svg_path = OUT_MAP_DIR / f"{args.profile}_{seed}.svg"
        json_path.write_text(json.dumps(region, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        svg_path.write_text(render_svg(region), encoding="utf-8")
        generated.append((seed, json_path, svg_path))

    write_index(generated)
    print(f"Generated {len(generated)} procedural region graph examples")


if __name__ == "__main__":
    main()
