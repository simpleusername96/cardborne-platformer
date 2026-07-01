"use strict";

const screens = [
  { id: "start", label: "Start", step: "01" },
  { id: "settings", label: "Settings", step: "02" },
  { id: "character", label: "Character", step: "03" },
  { id: "stage", label: "Stage", step: "04" },
  { id: "reward", label: "Cards", step: "05" },
  { id: "rest", label: "Rest/Shop", step: "06" },
  { id: "forge", label: "Forge", step: "07" },
  { id: "boss", label: "Boss", step: "08" },
  { id: "clear", label: "Clear", step: "09" },
];

const stageSlots = [
  "Stage 1 Intro",
  "Stage 2 Combat",
  "Stage 3 Vertical Gate",
  "Rest Shop",
  "Boss Approach",
  "Boss",
];

const flowIndexByScreen = {
  start: 0,
  settings: 0,
  character: 0,
  stage: 0,
  reward: 1,
  rest: 3,
  forge: 3,
  boss: 5,
  clear: 5,
};

const classes = [
  {
    id: "warrior",
    name: "Warrior",
    tagline: "Heavy melee, guard window, high health",
    token: "WAR",
    stats: { power: 88, speed: 42, range: 30, survival: 92 },
    start: ["HP 7", "Melee +2", "Guard"],
  },
  {
    id: "archer",
    name: "Archer",
    tagline: "Ranged shots, charge timing, spacing",
    token: "ARC",
    stats: { power: 58, speed: 62, range: 92, survival: 60 },
    start: ["HP 5", "Bow", "Charge shot"],
  },
  {
    id: "assassin",
    name: "Assassin",
    tagline: "Dash chain, crit burst, lower stability",
    token: "ASN",
    stats: { power: 70, speed: 94, range: 36, survival: 44 },
    start: ["HP 4", "Dagger", "Dash crit"],
  },
];

const rewardCards = [
  {
    id: "sharp_edge",
    name: "Sharp Edge",
    branch: "Combat",
    effect: "Attack damage +1",
    detail: "Simple damage card for all classes.",
  },
  {
    id: "light_boots",
    name: "Light Boots",
    branch: "Mobility",
    effect: "Move speed +20",
    detail: "Makes generated platforms more forgiving.",
  },
  {
    id: "coin_sense",
    name: "Coin Sense",
    branch: "Economy",
    effect: "Coin gain +15%",
    detail: "Supports shop and forge spending.",
  },
];

const equipment = [
  {
    id: "training_sword",
    name: "Training Sword",
    slot: "Weapon",
    rarity: "Common",
    profile: "blade_balanced",
    level: 0,
    stats: { attack_damage: 0 },
    cost: "8 coin, 1 scrap",
  },
  {
    id: "heavy_cleaver",
    name: "Heavy Cleaver",
    slot: "Weapon",
    rarity: "Rare",
    profile: "heavy_weapon",
    level: 1,
    stats: { attack_damage: 2, attack_speed: 1.15 },
    cost: "16 coin, 2 scrap",
  },
  {
    id: "swift_dagger",
    name: "Swift Dagger",
    slot: "Weapon",
    rarity: "Rare",
    profile: "agile_gear",
    level: 1,
    stats: { attack_damage: -0.25, attack_speed: 0.8 },
    cost: "14 coin, 1 sky thread",
  },
  {
    id: "patched_mail",
    name: "Patched Mail",
    slot: "Armor",
    rarity: "Common",
    profile: "heavy_weapon",
    level: 0,
    stats: { max_health: 1, move_speed: -8 },
    cost: "12 coin, 2 scrap",
  },
  {
    id: "runner_cloak",
    name: "Runner Cloak",
    slot: "Armor",
    rarity: "Rare",
    profile: "agile_gear",
    level: 0,
    stats: { move_speed: 18 },
    cost: "18 coin, 1 sky thread",
  },
  {
    id: "copper_charm",
    name: "Copper Charm",
    slot: "Charm",
    rarity: "Common",
    profile: "utility_charm",
    level: 0,
    stats: { coin_gain: 1.1 },
    cost: "10 coin, 1 scrap",
  },
];

const statLabels = {
  attack_damage: "Attack Damage",
  attack_speed: "Attack Speed",
  move_speed: "Move Speed",
  max_health: "Max Health",
  dash_cooldown: "Dash Cooldown",
  coin_gain: "Coin Gain",
  material_gain: "Material Gain",
  invulnerability_time: "Invulnerability Time",
  no_change: "No Change",
};

const enchantProfiles = {
  blade_balanced: {
    name: "Balanced Blade",
    rolls: [
      { stat: "attack_damage", chance: 0.45, min: 1, max: 2 },
      { stat: "attack_speed", chance: 0.25, min: -0.05, max: -0.03 },
      { stat: "dash_cooldown", chance: 0.15, min: -0.04, max: -0.02 },
      { stat: "no_change", chance: 0.15, min: 0, max: 0 },
    ],
  },
  heavy_weapon: {
    name: "Heavy Weapon",
    rolls: [
      { stat: "attack_damage", chance: 0.55, min: 1, max: 3 },
      { stat: "max_health", chance: 0.15, min: 1, max: 1 },
      { stat: "attack_speed", chance: 0.15, min: -0.04, max: -0.02 },
      { stat: "no_change", chance: 0.15, min: 0, max: 0 },
    ],
  },
  agile_gear: {
    name: "Agile Gear",
    rolls: [
      { stat: "move_speed", chance: 0.35, min: 4, max: 10 },
      { stat: "dash_cooldown", chance: 0.3, min: -0.05, max: -0.02 },
      { stat: "attack_speed", chance: 0.2, min: -0.05, max: -0.02 },
      { stat: "no_change", chance: 0.15, min: 0, max: 0 },
    ],
  },
  utility_charm: {
    name: "Utility Charm",
    rolls: [
      { stat: "coin_gain", chance: 0.35, min: 0.05, max: 0.12 },
      { stat: "material_gain", chance: 0.25, min: 0.05, max: 0.1 },
      { stat: "invulnerability_time", chance: 0.15, min: 0.05, max: 0.1 },
      { stat: "no_change", chance: 0.25, min: 0, max: 0 },
    ],
  },
};

const inspectorContracts = {
  start: {
    title: "Start Page",
    elements: ["New Run", "Continue disabled state", "Settings modal route", "Last run summary"],
    systems: ["Run seed", "Profile snapshot", "Keyboard focus order"],
  },
  settings: {
    title: "Settings Popup",
    elements: ["Audio sliders", "Display toggles", "Control hints", "Apply action"],
    systems: ["Local config", "Modal focus trap later", "Reduced motion path"],
  },
  character: {
    title: "Character Select",
    elements: ["Warrior", "Archer", "Assassin", "Shared control promise"],
    systems: ["Class base stats", "Starting equipment", "Run state init"],
  },
  stage: {
    title: "Normal Stage",
    elements: ["HUD", "Generated terrain", "Enemy/trap/loot markers", "Validation status"],
    systems: ["Fixed stage slot", "Seeded landscape", "Reachability budget"],
  },
  reward: {
    title: "Card Reward",
    elements: ["3 card choices", "Selected state", "Confirm action"],
    systems: ["Card pool", "Run build effects", "Reroll hook"],
  },
  rest: {
    title: "Rest/Shop Map",
    elements: ["Merchant", "Healer", "Forge", "Next stage action"],
    systems: ["Safe state", "Coins/material spending", "NPC interaction"],
  },
  forge: {
    title: "Forge/Enchant",
    elements: ["Equipment list", "Roll table", "Cost", "Preview result"],
    systems: ["Item-specific probability", "No downgrade V1", "Effective stat delta"],
  },
  boss: {
    title: "Boss Stage",
    elements: ["Boss HP", "Phase", "Warning zones", "Safe platforms"],
    systems: ["Telegraph/startup", "Active damage", "Recovery windows"],
  },
  clear: {
    title: "Run Clear",
    elements: ["Final rewards", "Build summary", "Boss core", "Restart action"],
    systems: ["Run summary", "Profile material hook", "Next run seed"],
  },
};

const state = {
  screen: "start",
  seed: 2001,
  selectedClass: "warrior",
  selectedCard: "sharp_edge",
  selectedItem: "heavy_cleaver",
  forgeMode: "enchant",
  rollCount: 0,
  lastRoll: null,
  shopNotice: "Forge is available. Buy/heal actions are safe-state previews.",
  landscape: null,
};

const root = document.getElementById("screenRoot");
const nav = document.getElementById("screenNav");
const inspector = document.getElementById("inspector");
const seedInput = document.getElementById("seedInput");
const status = document.getElementById("status");

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function hashSeed(...parts) {
  const input = parts.join(":");
  let hash = 2166136261;
  for (let index = 0; index < input.length; index += 1) {
    hash ^= input.charCodeAt(index);
    hash = Math.imul(hash, 16777619);
  }
  return hash >>> 0;
}

function mulberry32(seed) {
  return function next() {
    let t = (seed += 0x6d2b79f5);
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function makeRng(...parts) {
  return mulberry32(hashSeed(...parts));
}

function randInt(rng, min, max) {
  return Math.floor(rng() * (max - min + 1)) + min;
}

function choice(rng, values) {
  return values[Math.floor(rng() * values.length)];
}

function formatAmount(stat, amount) {
  if (stat === "no_change") return "-";
  const sign = amount > 0 ? "+" : "";
  if (["attack_speed", "dash_cooldown", "coin_gain", "material_gain", "invulnerability_time"].includes(stat)) {
    return `${sign}${amount.toFixed(2)}`;
  }
  return `${sign}${Math.round(amount)}`;
}

function rollEnchant(item) {
  const profile = enchantProfiles[item.profile];
  const rollIndex = Math.max(1, state.rollCount);
  const rng = makeRng(state.seed, item.id, state.forgeMode, rollIndex);
  const roll = rng();
  let running = 0;
  let selected = profile.rolls[profile.rolls.length - 1];
  for (const entry of profile.rolls) {
    running += entry.chance;
    if (roll <= running) {
      selected = entry;
      break;
    }
  }

  let amount = 0;
  if (selected.stat !== "no_change") {
    amount = selected.min === selected.max
      ? selected.min
      : selected.min + rng() * (selected.max - selected.min);
  }

  return {
    itemId: item.id,
    profile: profile.name,
    stat: selected.stat,
    amount,
    cost: item.cost,
    mode: state.forgeMode,
    rollIndex,
  };
}

function generateLandscape() {
  const cols = 64;
  const rows = 24;
  const grid = Array.from({ length: rows }, () => Array.from({ length: cols }, () => "."));
  const rng = makeRng(state.seed, "fixed-stage-slot", "landscape");
  const path = [];
  const startY = rows - 4;
  let y = startY;

  for (let x = 0; x < cols; x += 1) {
    grid[rows - 1][x] = "#";
  }

  for (let checkpoint = 0; checkpoint < 8; checkpoint += 1) {
    const x = 3 + checkpoint * 8 + randInt(rng, 0, 2);
    const targetY = Math.max(5, Math.min(rows - 5, y + choice(rng, [-3, -2, -1, 0, 1, 2])));
    const length = randInt(rng, 6, 10);
    for (let px = x; px < Math.min(cols - 2, x + length); px += 1) {
      grid[targetY][px] = checkpoint % 3 === 0 ? "#" : "=";
    }
    path.push({ x, y: targetY, length });
    y = targetY;
  }

  for (let branch = 0; branch < 7; branch += 1) {
    const anchor = choice(rng, path.slice(1, -1));
    const bx = Math.max(2, Math.min(cols - 12, anchor.x + choice(rng, [-7, -5, 5, 7])));
    const by = Math.max(4, Math.min(rows - 6, anchor.y + choice(rng, [-4, -3, 3, 4])));
    const length = randInt(rng, 4, 8);
    for (let px = bx; px < bx + length; px += 1) {
      grid[by][px] = "=";
    }
  }

  for (let pit = 0; pit < 5; pit += 1) {
    const start = randInt(rng, 12, cols - 14);
    const width = randInt(rng, 2, 4);
    for (let px = start; px < start + width; px += 1) {
      grid[rows - 1][px] = ".";
      grid[rows - 2][px] = "^";
    }
  }

  const start = path[0];
  const exit = path[path.length - 1];
  grid[start.y - 1][start.x + 1] = "S";
  grid[exit.y - 1][Math.min(cols - 3, exit.x + exit.length - 2)] = "E";

  const enemySymbols = ["W", "C", "R"];
  for (let index = 1; index < path.length - 1; index += 1) {
    const segment = path[index];
    const symbol = choice(rng, enemySymbols);
    grid[segment.y - 1][segment.x + randInt(rng, 1, Math.max(1, segment.length - 2))] = symbol;
    if (rng() > 0.45) {
      grid[segment.y - 1][segment.x + randInt(rng, 1, Math.max(1, segment.length - 2))] = "$";
    }
  }

  const keySegment = path[3];
  const gateSegment = path[5];
  grid[keySegment.y - 1][keySegment.x + 1] = "K";
  grid[gateSegment.y - 1][gateSegment.x + gateSegment.length - 2] = "G";

  for (let index = 0; index < 5; index += 1) {
    const segment = choice(rng, path);
    grid[segment.y - 1][segment.x + randInt(rng, 1, Math.max(1, segment.length - 2))] = choice(rng, ["M", "T", "$"]);
  }

  return {
    cols,
    rows,
    grid,
    path,
    validation: {
      spawnToExit: true,
      checkpoints: `${path.length}/${path.length}`,
      jumpBudget: "base jump + dash",
      rewardBudget: randInt(rng, 12, 18),
      dangerBudget: randInt(rng, 18, 27),
    },
  };
}

function tileClass(symbol) {
  return {
    ".": "empty",
    "#": "solid",
    "=": "platform",
    S: "spawn",
    E: "exit",
    W: "enemy",
    C: "enemy",
    R: "enemy",
    "^": "trap",
    "~": "trap",
    "$": "loot",
    M: "material",
    T: "loot",
    K: "key",
    G: "gate",
  }[symbol] || "empty";
}

function tileLabel(symbol) {
  return {
    S: "Spawn",
    E: "Exit",
    W: "Walker",
    C: "Charger",
    R: "Shooter",
    "^": "Trap",
    "$": "Coin",
    M: "Material",
    T: "Chest",
    K: "Key",
    G: "Gate",
  }[symbol] || "Open";
}

function renderLandscape() {
  if (!state.landscape) state.landscape = generateLandscape();
  const cells = state.landscape.grid.flatMap((row) => row).map((symbol) => {
    const display = symbol === "." || symbol === "#" || symbol === "=" ? "" : symbol;
    return `<div class="tile ${tileClass(symbol)}" title="${tileLabel(symbol)}">${display}</div>`;
  }).join("");
  return `
    <div class="landscape-wrap" aria-label="Seeded generated landscape preview">
      <p class="sr-only">Generated landscape preview with spawn, exit, enemies, traps, key, gate, coins, materials, and chests.</p>
      <div class="landscape-grid" style="--cols:${state.landscape.cols}" aria-hidden="true">${cells}</div>
    </div>
  `;
}

function screenFrame(title, subtitle, body, actions = "") {
  return `
    <section class="screen-frame" aria-labelledby="screenTitle">
      <header class="screen-header">
        <div>
          <h2 id="screenTitle" class="screen-title">${title}</h2>
          <p class="screen-subtitle">${subtitle}</p>
        </div>
        <div class="action-row">${actions}</div>
      </header>
      <div class="screen-body">${body}</div>
    </section>
  `;
}

function renderStart() {
  return `
    <section class="screen-stage" aria-labelledby="startTitle">
      <div class="mock-backdrop"></div>
      <div class="start-layout">
        <div class="brand-block">
          <p class="eyebrow">Seed ${state.seed}</p>
          <h2 id="startTitle">Cardborne Platformer</h2>
          <p>고정된 런 흐름 안에서 매번 다른 지형, 카드 선택, 장비 강화 결과를 만든다.</p>
        </div>
        <div>
          <div class="menu-panel" aria-label="Main menu">
            <button class="button primary" type="button" data-screen="character">New Run</button>
            <button class="button ghost" type="button" disabled>Continue</button>
            <button class="button ghost" type="button" data-screen="settings">Settings</button>
            <button class="button ghost" type="button" disabled>Quit</button>
          </div>
          <div class="summary-panel">
            <p class="section-label">Last run</p>
            <div class="summary-grid">
              <div class="metric"><span>Class</span><strong>Archer</strong></div>
              <div class="metric"><span>Stage</span><strong>Stage 2</strong></div>
              <div class="metric"><span>Coins</span><strong>312</strong></div>
              <div class="metric"><span>Boss Core</span><strong>0</strong></div>
            </div>
          </div>
        </div>
      </div>
    </section>
  `;
}

function renderSettings() {
  const body = `
    <div class="two-column">
      <section class="item-panel">
        <p class="section-label">Audio</p>
        ${rangeRow("Master", 78)}
        ${rangeRow("Music", 62)}
        ${rangeRow("SFX", 86)}
      </section>
      <section class="item-panel">
        <p class="section-label">Display / Controls</p>
        <div class="resource-row">
          <span class="pill">Screen shake On</span>
          <span class="pill">Damage flash On</span>
          <span class="pill">Reduced motion Auto</span>
        </div>
        <div class="tag-row" style="margin-top:14px">
          <span class="pill">A/D Move</span>
          <span class="pill">Space Jump</span>
          <span class="pill">J Attack</span>
          <span class="pill">K Dash</span>
          <span class="pill">E Interact</span>
        </div>
      </section>
    </div>
  `;
  return screenFrame("Settings", "공통 설정 popup의 코드 목업.", body, `<button class="button primary" type="button" data-screen="start">Apply</button>`);
}

function rangeRow(label, value) {
  return `
    <div class="stat-row" style="grid-template-columns:96px minmax(0,1fr) 42px;margin-bottom:12px">
      <span>${label}</span>
      <span class="bar"><i style="width:${value}%"></i></span>
      <strong>${value}</strong>
    </div>
  `;
}

function renderCharacter() {
  const cards = classes.map((entry) => `
    <button class="class-card selectable" type="button" data-class="${entry.id}" aria-pressed="${entry.id === state.selectedClass}">
      <div class="avatar">${entry.token}</div>
      <h3>${entry.name}</h3>
      <p>${entry.tagline}</p>
      <dl class="stat-list">
        ${statBar("Power", entry.stats.power)}
        ${statBar("Speed", entry.stats.speed)}
        ${statBar("Range", entry.stats.range)}
        ${statBar("Survival", entry.stats.survival)}
      </dl>
      <div class="tag-row" style="margin-top:12px">
        ${entry.start.map((tag) => `<span class="pill">${tag}</span>`).join("")}
      </div>
    </button>
  `).join("");
  return `
    <section class="screen-stage" aria-labelledby="characterTitle">
      <div class="mock-backdrop"></div>
      <div class="character-layout">
        <div>
          <p class="eyebrow">Before run</p>
          <h2 id="characterTitle">Choose Starter Class</h2>
        </div>
        <div class="class-grid">${cards}</div>
        <div class="action-row">
          <button class="button ghost" type="button" data-screen="start">Back</button>
          <button class="button primary" type="button" data-screen="stage">Start Run</button>
        </div>
      </div>
    </section>
  `;
}

function statBar(label, value) {
  return `
    <div class="stat-row">
      <span>${label}</span>
      <span class="bar"><i style="width:${value}%"></i></span>
      <strong>${value}</strong>
    </div>
  `;
}

function renderStage() {
  const validation = state.landscape?.validation || generateLandscape().validation;
  const body = `
    <section class="screen-stage" aria-labelledby="stageTitle">
      <div class="stage-hud">
        <div class="hud-panel">
          <div class="hud-line"><span>HP 5/5</span><span>Lv 2</span></div>
          <div class="bar" aria-label="XP progress"><i style="width:68%"></i></div>
        </div>
        <div class="hud-panel">
          <div class="slot-row" aria-label="Card and skill slots">
            <span class="slot">1</span><span class="slot">2</span><span class="slot">3</span>
            <span class="pill">${selectedClass().name}</span>
          </div>
        </div>
        <div class="hud-panel">
          <div class="resource-row">
            <span class="pill">Coin 64</span>
            <span class="pill">Scrap 3</span>
            <span class="pill">Sky Thread 1</span>
          </div>
        </div>
      </div>
      ${renderLandscape()}
      <footer class="stage-footer">
        <div class="validation-list">
          <span class="status-pill ok">Spawn → Exit</span>
          <span class="status-pill ok">Checkpoints ${validation.checkpoints}</span>
          <span class="status-pill warn">Danger ${validation.dangerBudget}</span>
          <span class="status-pill ok">Reward ${validation.rewardBudget}</span>
        </div>
        <div class="action-row">
          <button class="button ghost" type="button" data-action="regenerate">Regenerate</button>
          <button class="button primary" type="button" data-screen="reward">Clear Stage</button>
        </div>
      </footer>
    </section>
  `;
  return body;
}

function selectedClass() {
  return classes.find((entry) => entry.id === state.selectedClass) || classes[0];
}

function renderReward() {
  const cards = rewardCards.map((card) => `
    <button class="reward-card selectable" type="button" data-card="${card.id}" aria-pressed="${card.id === state.selectedCard}">
      <p class="section-label">${card.branch}</p>
      <h3>${card.name}</h3>
      <p><strong>${card.effect}</strong></p>
      <p>${card.detail}</p>
    </button>
  `).join("");
  const body = `
    <div class="reward-layout">
      <div class="reward-grid">${cards}</div>
    </div>
  `;
  return screenFrame("Choose 1 Card", "스테이지 클리어 후 build 방향을 하나 고른다.", body, `<button class="button primary" type="button" data-screen="rest">Confirm</button>`);
}

function renderRest() {
  return `
    <section class="screen-stage" aria-labelledby="restTitle">
      <div class="mock-backdrop"></div>
      <div class="shop-layout">
        <div>
          <p class="eyebrow">Safe state</p>
          <h2 id="restTitle">Rest and Shop Map</h2>
          <div class="camp-floor">
            <div class="npc-row" aria-label="NPC interaction lane">
              <button class="npc" type="button" data-action="shop-buy">Merchant</button>
              <button class="npc" type="button" data-action="shop-heal">Healer</button>
              <button class="npc" type="button" data-screen="forge">Forge</button>
            </div>
          </div>
        </div>
        <aside class="shop-panel">
          <p class="section-label">Run wallet</p>
          <div class="resource-row">
            <span class="pill">Coin 64</span>
            <span class="pill">Slime 5</span>
            <span class="pill">Scrap 3</span>
            <span class="pill">Core 0</span>
          </div>
          <div class="result-box" style="min-height:auto;margin-top:14px" aria-live="polite">
            <strong>Camp action</strong>
            <p>${escapeHtml(state.shopNotice)}</p>
          </div>
          <div class="shop-actions" style="margin-top:18px">
            <button class="button ghost" type="button" data-action="shop-buy">Buy</button>
            <button class="button ghost" type="button" data-action="shop-heal">Heal</button>
            <button class="button ghost" type="button" data-screen="forge">Forge</button>
            <button class="button primary" type="button" data-screen="boss">Enter Boss Approach</button>
          </div>
        </aside>
      </div>
    </section>
  `;
}

function renderForge() {
  const item = selectedItem();
  const profile = enchantProfiles[item.profile];
  const body = `
    <div class="forge-layout">
      <section class="item-panel">
        <p class="section-label">Equipment</p>
        <div class="item-list">
          ${equipment.map((entry) => `
            <button class="item-button" type="button" data-item="${entry.id}" aria-pressed="${entry.id === state.selectedItem}">
              <strong>${entry.name}</strong>
              <span>${entry.slot} · ${entry.rarity} · Lv ${entry.level}</span>
            </button>
          `).join("")}
        </div>
      </section>
      <section class="item-panel">
        <div class="forge-header">
          <div>
            <p class="section-label">${profile.name}</p>
            <h3>${item.name}</h3>
            <p>${item.slot} · ${item.rarity} · Cost ${item.cost}</p>
          </div>
          <div class="mode-tabs" role="group" aria-label="Upgrade mode">
            <button type="button" data-mode="forge" aria-pressed="${state.forgeMode === "forge"}">Forge</button>
            <button type="button" data-mode="enchant" aria-pressed="${state.forgeMode === "enchant"}">Enchant</button>
          </div>
        </div>
        <div class="upgrade-grid">
          <div>
            <table class="roll-table">
              <thead>
                <tr><th scope="col">Stat</th><th scope="col">Chance</th><th scope="col">Amount</th></tr>
              </thead>
              <tbody>
                ${profile.rolls.map((roll) => `
                  <tr>
                    <td>${statLabels[roll.stat]}</td>
                    <td>${Math.round(roll.chance * 100)}%</td>
                    <td>${formatRollRange(roll)}</td>
                  </tr>
                `).join("")}
              </tbody>
            </table>
          </div>
          <aside class="result-box" aria-live="polite">
            ${renderRollResult()}
          </aside>
        </div>
        <div class="action-row" style="margin-top:16px">
          <button class="button ghost" type="button" data-action="reset-rolls">Reset Preview</button>
          <button class="button primary" type="button" data-action="roll-upgrade">Roll Preview</button>
        </div>
      </section>
    </div>
  `;
  return screenFrame("Forge / Enchant", "장비마다 다른 확률표로 스탯 상승을 preview한다.", body, `<button class="button ghost" type="button" data-screen="rest">Back to Camp</button>`);
}

function selectedItem() {
  return equipment.find((entry) => entry.id === state.selectedItem) || equipment[0];
}

function formatRollRange(roll) {
  if (roll.stat === "no_change") return "No stat gain";
  return `${formatAmount(roll.stat, roll.min)} to ${formatAmount(roll.stat, roll.max)}`;
}

function renderRollResult() {
  if (!state.lastRoll) {
    return `
      <strong>No roll yet</strong>
      <p>Seed ${state.seed} and selected item determine the preview result.</p>
      <ul>
        <li>No downgrade in V1</li>
        <li>Cost is consumed only in runtime implementation</li>
        <li>Each item owns its probability profile</li>
      </ul>
    `;
  }

  const result = state.lastRoll;
  const label = statLabels[result.stat];
  const amount = formatAmount(result.stat, result.amount);
  return `
    <strong>Roll ${result.rollIndex}: ${label}</strong>
    <p>${result.stat === "no_change" ? "No stat changed this time." : `${label} ${amount}`}</p>
    <ul>
      <li>Mode: ${result.mode}</li>
      <li>Profile: ${result.profile}</li>
      <li>Cost: ${result.cost}</li>
    </ul>
  `;
}

function renderBoss() {
  return `
    <section class="screen-stage" aria-labelledby="bossTitle">
      <div class="boss-layout">
        <div class="boss-top">
          <div class="boss-panel">
            <div class="hud-line"><span>Giant Slime King · Phase 2</span><span>38/80</span></div>
            <div class="bar"><i style="width:48%"></i></div>
          </div>
          <div class="boss-panel">
            <div class="resource-row">
              <span class="pill">HP 4/5</span>
              <span class="pill">Dash ready</span>
              <span class="pill">Pattern Poison</span>
            </div>
          </div>
        </div>
        <div class="arena" aria-label="Boss arena mockup">
          <div class="safe-platform left"></div>
          <div class="safe-platform right"></div>
          <div class="arena-floor"></div>
          <div class="warning-zone one">WARN</div>
          <div class="warning-zone two">WARN</div>
          <div class="player-token">P</div>
          <div class="boss-token">BOSS</div>
        </div>
        <div class="action-row">
          <button class="button ghost" type="button" data-screen="rest">Retreat</button>
          <button class="button primary" type="button" data-screen="clear">Defeat Boss</button>
        </div>
      </div>
    </section>
  `;
}

function renderClear() {
  const body = `
    <div class="two-column">
      <section class="item-panel">
        <p class="section-label">Rewards</p>
        <div class="summary-grid">
          <div class="metric"><span>Coin</span><strong>+40</strong></div>
          <div class="metric"><span>Boss Core</span><strong>+1</strong></div>
          <div class="metric"><span>Slime</span><strong>+8</strong></div>
          <div class="metric"><span>Card</span><strong>Boss choice</strong></div>
        </div>
      </section>
      <section class="item-panel">
        <p class="section-label">Build</p>
        <div class="resource-row">
          <span class="pill">${selectedClass().name}</span>
          <span class="pill">${selectedReward().name}</span>
          <span class="pill">${selectedItem().name}</span>
        </div>
      </section>
    </div>
  `;
  return screenFrame("Run Clear", "첫 vertical slice의 종료 화면.", body, `<button class="button primary" type="button" data-screen="start">New Seed</button>`);
}

function selectedReward() {
  return rewardCards.find((entry) => entry.id === state.selectedCard) || rewardCards[0];
}

function renderInspector() {
  const contract = inspectorContracts[state.screen] || inspectorContracts.start;
  const flowIndex = flowIndexByScreen[state.screen] ?? 0;
  inspector.innerHTML = `
    <section class="inspector-card">
      <p class="section-label">Flow</p>
      <div class="flow-list">
        ${stageSlots.map((slot, index) => `
          <div class="flow-step ${index === flowIndex ? "active" : ""}">
            <i>${index + 1}</i>
            <span>${slot}</span>
          </div>
        `).join("")}
      </div>
    </section>
    <section class="inspector-card">
      <h2>${contract.title}</h2>
      <p class="section-label">Elements</p>
      <ul>${contract.elements.map((item) => `<li>${item}</li>`).join("")}</ul>
    </section>
    <section class="inspector-card">
      <p class="section-label">Systems</p>
      <ul>${contract.systems.map((item) => `<li>${item}</li>`).join("")}</ul>
    </section>
  `;
}

function renderNav() {
  nav.innerHTML = screens.map((screen) => `
    <button class="screen-button" type="button" data-screen="${screen.id}" aria-current="${screen.id === state.screen ? "page" : "false"}">
      <span>${screen.label}</span>
      <small>${screen.step}</small>
    </button>
  `).join("");
}

function renderScreen() {
  const renderer = {
    start: renderStart,
    settings: renderSettings,
    character: renderCharacter,
    stage: renderStage,
    reward: renderReward,
    rest: renderRest,
    forge: renderForge,
    boss: renderBoss,
    clear: renderClear,
  }[state.screen] || renderStart;

  seedInput.value = state.seed;
  root.innerHTML = renderer();
  renderNav();
  renderInspector();
}

function setStatus(message) {
  status.textContent = message;
}

function handleClick(event) {
  const screenTarget = event.target.closest("[data-screen]");
  if (screenTarget) {
    state.screen = screenTarget.dataset.screen;
    state.lastRoll = null;
    state.rollCount = 0;
    renderScreen();
    root.focus({ preventScroll: true });
    setStatus(`Opened ${state.screen}`);
    return;
  }

  const classTarget = event.target.closest("[data-class]");
  if (classTarget) {
    state.selectedClass = classTarget.dataset.class;
    renderScreen();
    setStatus(`Selected ${selectedClass().name}`);
    return;
  }

  const cardTarget = event.target.closest("[data-card]");
  if (cardTarget) {
    state.selectedCard = cardTarget.dataset.card;
    renderScreen();
    setStatus(`Selected ${selectedReward().name}`);
    return;
  }

  const itemTarget = event.target.closest("[data-item]");
  if (itemTarget) {
    state.selectedItem = itemTarget.dataset.item;
    state.lastRoll = null;
    state.rollCount = 0;
    renderScreen();
    setStatus(`Selected ${selectedItem().name}`);
    return;
  }

  const modeTarget = event.target.closest("[data-mode]");
  if (modeTarget) {
    state.forgeMode = modeTarget.dataset.mode;
    state.lastRoll = null;
    renderScreen();
    setStatus(`Upgrade mode ${state.forgeMode}`);
    return;
  }

  const actionTarget = event.target.closest("[data-action]");
  if (!actionTarget) return;

  const action = actionTarget.dataset.action;
  if (action === "random-seed") {
    state.seed = Math.floor(1000 + Math.random() * 9000);
    state.landscape = generateLandscape();
    state.lastRoll = null;
    state.rollCount = 0;
    renderScreen();
    setStatus(`Seed ${state.seed}`);
  }
  if (action === "regenerate") {
    const nextSeed = Number(seedInput.value) || state.seed;
    state.seed = Math.max(1, Math.floor(nextSeed));
    state.landscape = generateLandscape();
    state.lastRoll = null;
    state.rollCount = 0;
    renderScreen();
    setStatus(`Generated landscape for seed ${state.seed}`);
  }
  if (action === "roll-upgrade") {
    state.rollCount += 1;
    state.lastRoll = rollEnchant(selectedItem());
    renderScreen();
    setStatus(`Rolled ${statLabels[state.lastRoll.stat]}`);
  }
  if (action === "reset-rolls") {
    state.rollCount = 0;
    state.lastRoll = null;
    renderScreen();
    setStatus("Roll preview reset");
  }
  if (action === "shop-buy") {
    state.shopNotice = "Merchant preview: potion, dagger, armor, and charm offers would open here.";
    renderScreen();
    setStatus("Merchant preview");
  }
  if (action === "shop-heal") {
    state.shopNotice = "Healer preview: spend 8 coins to restore 2 HP before the next stage.";
    renderScreen();
    setStatus("Healer preview");
  }
}

function handleSeedChange() {
  const nextSeed = Number(seedInput.value);
  if (Number.isFinite(nextSeed) && nextSeed > 0) {
    state.seed = Math.floor(nextSeed);
  }
}

document.addEventListener("click", handleClick);
seedInput.addEventListener("change", handleSeedChange);

state.landscape = generateLandscape();
renderScreen();
