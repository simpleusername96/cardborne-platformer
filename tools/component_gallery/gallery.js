"use strict";

const WORLD_BOUNDS = { x: 0, y: -200, width: 8960, height: 1440 };
const BACKGROUND_BOUNDS = { x: -256, y: -456, width: 9472, height: 1952 };
const VIEWPORTS = {
  "960x540": { width: 960, height: 540 },
  "1280x720": { width: 1280, height: 720 },
  "1920x1080": { width: 1920, height: 1080 },
};

const ventSvg = `
<svg viewBox="0 0 400 260" xmlns="http://www.w3.org/2000/svg" aria-hidden="true" focusable="false">
  <defs>
    <linearGradient id="vent-metal" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#52636a"/>
      <stop offset="0.52" stop-color="#2c393e"/>
      <stop offset="1" stop-color="#1a2327"/>
    </linearGradient>
    <linearGradient id="vent-brass" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#e0b24d"/>
      <stop offset="1" stop-color="#7f5a22"/>
    </linearGradient>
    <radialGradient id="vent-core" cx="50%" cy="42%" r="58%">
      <stop offset="0" stop-color="#17272b"/>
      <stop offset="1" stop-color="#080d0f"/>
    </radialGradient>
    <filter id="vent-soft-glow" x="-80%" y="-80%" width="260%" height="260%">
      <feGaussianBlur stdDeviation="5"/>
    </filter>
  </defs>

  <g data-layer="base" class="vent-base" data-base-id="timed-poison-vent/base-v1">
    <ellipse cx="200" cy="199" rx="111" ry="18" fill="#05090b" opacity=".62"/>
    <path d="M104 172 121 143h158l17 29-11 25H115Z" fill="#202b2f" stroke="#526068" stroke-width="2"/>
    <path d="M119 173h162l8 18H111Z" fill="#141c20" stroke="#38474d" stroke-width="2"/>
    <path d="M130 163h140l8 16H122Z" fill="url(#vent-metal)" stroke="#68777d" stroke-width="2"/>
    <path d="M148 150V98c0-25 17-42 52-42s52 17 52 42v52Z" fill="url(#vent-metal)" stroke="#66767d" stroke-width="3"/>
    <path d="M159 142v-40c0-18 12-31 41-31s41 13 41 31v40Z" fill="#192226" stroke="#39494f" stroke-width="2"/>
    <ellipse cx="200" cy="91" rx="42" ry="20" fill="#28363b" stroke="#718188" stroke-width="3"/>
    <ellipse cx="200" cy="88" rx="31" ry="13" fill="url(#vent-core)" stroke="#0b1113" stroke-width="3"/>
    <path d="M177 87c12-5 34-5 46 0" fill="none" stroke="#526068" stroke-width="2" opacity=".7"/>
    <path d="M165 130h70M162 143h76" fill="none" stroke="#101719" stroke-width="4"/>
    <path d="M165 128h70M162 141h76" fill="none" stroke="#526068" stroke-width="1" opacity=".7"/>
    <rect x="181" y="149" width="38" height="22" rx="2" fill="#171e21" stroke="#776032"/>
    <path d="M188 155h24v3h-24zm0 7h16v3h-16z" fill="#d4a33f" opacity=".82"/>
    <path d="M128 169h18v12h-18zm126 0h18v12h-18z" fill="url(#vent-brass)" stroke="#392b18"/>
    <circle cx="122" cy="184" r="4" fill="#0b1012" stroke="#68777d"/>
    <circle cx="278" cy="184" r="4" fill="#0b1012" stroke="#68777d"/>
    <path d="M138 189h124" stroke="#0a0e10" stroke-width="3" opacity=".8"/>
  </g>

  <g data-overlay="warning">
    <ellipse class="vent-warning-ring" cx="200" cy="87" rx="49" ry="27" fill="none" stroke="#d4a33f" stroke-width="3" stroke-dasharray="8 6"/>
    <ellipse cx="200" cy="87" rx="58" ry="34" fill="none" stroke="#d4a33f" stroke-width="9" opacity=".12" filter="url(#vent-soft-glow)"/>
    <path d="M200 23v19M167 32l9 16m57-16-9 16" stroke="#f0c55d" stroke-width="4" stroke-linecap="round"/>
    <path d="M190 42h20l-3 24h-14Z" fill="#d4a33f" opacity=".16"/>
    <text x="200" y="58" fill="#f3d276" font-family="Cascadia Mono, monospace" font-size="18" font-weight="700" text-anchor="middle">!</text>
  </g>

  <g data-overlay="active">
    <ellipse cx="200" cy="91" rx="50" ry="25" fill="#75b96c" opacity=".26" filter="url(#vent-soft-glow)"/>
    <g class="vent-plume">
      <path d="M170 88c-8-19 13-23 4-40 17 5 18-13 14-27 24 12 10 31 25 38 7-14 20-13 20 1 0 10-8 17-5 28Z" fill="#75b96c" opacity=".74"/>
      <path d="M181 85c-4-13 10-20 5-33 13 8 6 21 17 26 8-9 15-5 14 7Z" fill="#b4db77" opacity=".56"/>
    </g>
    <circle class="vent-particle" cx="159" cy="63" r="5" fill="#89c878" opacity=".8"/>
    <circle class="vent-particle delay-one" cx="236" cy="52" r="4" fill="#b1d978" opacity=".75"/>
    <circle class="vent-particle delay-two" cx="217" cy="30" r="3" fill="#6fbb70" opacity=".8"/>
    <rect x="109" y="75" width="182" height="98" rx="3" fill="none" stroke="#d9654f" stroke-width="2" stroke-dasharray="5 5" opacity=".9"/>
    <path d="m112 86 8-8m-8 0 8 8m160 0 8-8m-8 0 8 8" stroke="#f07a60" stroke-width="2"/>
  </g>

  <g data-overlay="cooldown">
    <ellipse cx="200" cy="89" rx="38" ry="17" fill="#62a9b5" opacity=".11"/>
    <path class="cooling-wisp" d="M179 84c-8-13 8-19 1-31m21 32c-8-16 9-21 2-39m20 39c-6-11 7-16 2-25" fill="none" stroke="#8fc5cc" stroke-width="3" stroke-linecap="round" opacity=".68"/>
    <path d="M161 105c21 8 57 8 78 0" fill="none" stroke="#62a9b5" stroke-width="2" stroke-dasharray="4 7" opacity=".7"/>
  </g>

  <g data-layer="debug">
    <rect data-damage-box x="110" y="76" width="180" height="96" fill="#d9654f" fill-opacity=".07" stroke="#d9654f" stroke-width="2" stroke-dasharray="6 4"/>
    <path d="M190 124h20M200 114v20" stroke="#f0f1e8" stroke-width="1.5"/>
    <circle cx="200" cy="124" r="3" fill="#f0f1e8"/>
    <text data-debug-label class="debug-label" x="112" y="70" fill="#f3d276" font-family="Cascadia Mono, monospace" font-size="9">AREA · DAMAGE OFF</text>
  </g>
</svg>`;

const platformSvg = `
<svg viewBox="0 0 440 220" xmlns="http://www.w3.org/2000/svg" aria-hidden="true" focusable="false">
  <defs>
    <linearGradient id="platform-stone" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#709096"/>
      <stop offset="0.42" stop-color="#4a656b"/>
      <stop offset="1" stop-color="#29383d"/>
    </linearGradient>
    <linearGradient id="platform-edge" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#ac7e36"/>
      <stop offset="0.48" stop-color="#d4a33f"/>
      <stop offset="1" stop-color="#795725"/>
    </linearGradient>
    <filter id="platform-glow" x="-50%" y="-100%" width="200%" height="300%">
      <feGaussianBlur stdDeviation="4"/>
    </filter>
  </defs>

  <g data-layer="base" class="platform-base" data-base-id="crumbling-platform/base-v1">
    <ellipse cx="220" cy="149" rx="128" ry="17" fill="#05090b" opacity=".55"/>
    <path d="M105 102 117 91h206l12 11-7 29-19 8H128l-16-8Z" fill="#182226" stroke="#526068" stroke-width="2"/>
    <path d="M110 101h220v28H110Z" fill="url(#platform-stone)" stroke="#71888e" stroke-width="2"/>
    <path d="M113 104h214v6H113Z" fill="#9db1af" opacity=".36"/>
    <path d="M110 125h220v6H110Z" fill="#172125"/>
    <path d="M121 101v28m36-28v28m47-28v28m39-28v28m49-28v28" stroke="#26383d" stroke-width="3"/>
    <path d="M122 105h34m4 0h42m5 0h34m5 0h44m5 0h31" stroke="#b5c4bf" stroke-width="1" opacity=".28"/>
    <path d="M119 117h202" stroke="url(#platform-edge)" stroke-width="3" opacity=".86"/>
    <path d="m129 131 8 14h23l8-14m104 0 8 14h23l8-14" fill="#202c30" stroke="#48595f" stroke-width="2"/>
    <circle cx="128" cy="116" r="3" fill="#d4a33f" opacity=".75"/>
    <circle cx="312" cy="116" r="3" fill="#d4a33f" opacity=".75"/>
  </g>

  <g data-overlay="warning">
    <path d="m154 100 11 10-7 8 13 11m51-29-8 8 8 8-10 13m58-29-8 7 11 8-8 14" fill="none" stroke="#f0c55d" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
    <path d="M113 94h214" stroke="#d4a33f" stroke-width="8" opacity=".15" filter="url(#platform-glow)"/>
    <g class="platform-warning-mark">
      <path d="M211 61h18l-3 23h-12Z" fill="#d4a33f" opacity=".18"/>
      <text x="220" y="78" fill="#f3d276" font-family="Cascadia Mono, monospace" font-size="18" font-weight="700" text-anchor="middle">!</text>
    </g>
    <circle cx="153" cy="142" r="3" fill="#b88a59"/>
    <circle cx="229" cy="146" r="2" fill="#d4a33f"/>
    <circle cx="280" cy="141" r="3" fill="#b88a59"/>
  </g>

  <g data-overlay="disabled">
    <path d="M119 104h38l-7 21-31 9Z" fill="#4a656b" stroke="#71888e" opacity=".82" class="falling-fragment"/>
    <path d="M190 106h43l6 22-41 11Z" fill="#3d565b" stroke="#71888e" opacity=".78" class="falling-fragment delay-one"/>
    <path d="M275 102h48l-5 25-37 8Z" fill="#4b676c" stroke="#71888e" opacity=".8" class="falling-fragment delay-two"/>
    <path d="M126 98c49-13 139-12 189 0" fill="none" stroke="#d9654f" stroke-width="2" stroke-dasharray="4 7" opacity=".7"/>
  </g>

  <g data-overlay="respawning">
    <path d="M110 101h220v28H110Z" fill="#62a9b5" fill-opacity=".08" stroke="#8ecbd3" stroke-width="2" stroke-dasharray="6 5"/>
    <path d="M118 96h204" stroke="#62a9b5" stroke-width="9" opacity=".18" filter="url(#platform-glow)"/>
    <circle class="rebuild-particle" cx="149" cy="116" r="3" fill="#8dd1d8"/>
    <circle class="rebuild-particle delay-one" cx="220" cy="108" r="4" fill="#62a9b5"/>
    <circle class="rebuild-particle delay-two" cx="296" cy="119" r="3" fill="#a9d9dd"/>
    <path d="m122 113 8-8m-8 20 20-20m146 20 20-20m-8 20 8-8" stroke="#b6e1e5" stroke-width="2" opacity=".72"/>
  </g>

  <g data-layer="debug">
    <rect data-collision-box x="110" y="101" width="220" height="28" fill="#62a9b5" fill-opacity=".07" stroke="#62a9b5" stroke-width="2" stroke-dasharray="6 4"/>
    <rect data-sensor-box x="110" y="84" width="220" height="18" fill="#d4a33f" fill-opacity=".06" stroke="#d4a33f" stroke-width="1.5" stroke-dasharray="3 4"/>
    <path d="M210 115h20M220 105v20" stroke="#f0f1e8" stroke-width="1.5"/>
    <circle cx="220" cy="115" r="3" fill="#f0f1e8"/>
    <text data-debug-label class="debug-label" x="112" y="79" fill="#9bd4da" font-family="Cascadia Mono, monospace" font-size="9">SENSOR ON · COLLISION ON</text>
  </g>
</svg>`;

const COMPONENTS = {
  vent: {
    mount: "vent-svg",
    svg: ventSvg,
    initial: "warning",
    loop: true,
    sequence: ["warning", "active", "cooldown"],
    states: {
      warning: { duration: 0.70, copy: "사전 경고 · 피해 없음", caption: "+ WARNING_OVERLAY", tone: "warning" },
      active: { duration: 1.20, copy: "독성 분출 · 피해 판정 켜짐", caption: "+ ACTIVE_OVERLAY", tone: "danger" },
      cooldown: { duration: 1.50, copy: "잔류 증기 · 피해 없음", caption: "+ COOLDOWN_OVERLAY", tone: "cool" },
    },
  },
  platform: {
    mount: "platform-svg",
    svg: platformSvg,
    initial: "stable",
    loop: false,
    sequence: ["warning", "disabled", "respawning", "stable"],
    states: {
      stable: { duration: null, copy: "고정 상태 · 충돌 켜짐", caption: "+ NO OVERLAY", tone: "stable" },
      warning: { duration: 0.45, copy: "균열 경고 · 충돌 켜짐", caption: "+ CRACK_OVERLAY", tone: "warning" },
      disabled: { duration: 1.80, copy: "발판 붕괴 · 충돌 꺼짐", caption: "+ FALLING_DEBRIS", tone: "danger" },
      respawning: { duration: 0.25, copy: "베이스 복원 · 충돌 꺼짐", caption: "+ RESPAWN_OVERLAY", tone: "cool" },
    },
  },
};

function setupWorldViewer() {
  const camera = document.querySelector("#world-camera");
  const plane = document.querySelector("#background-plane");
  const xInput = document.querySelector("#camera-x");
  const yInput = document.querySelector("#camera-y");
  const xOutput = document.querySelector("#camera-x-output");
  const yOutput = document.querySelector("#camera-y-output");
  const positionOutput = document.querySelector("#camera-position");
  const coverageOutput = document.querySelector("#coverage-value");
  const seamInput = document.querySelector("#show-seams");
  const safeArea = plane.querySelector(".world-safe-area");
  let viewport = VIEWPORTS["1280x720"];

  const safeInsets = {
    top: ((WORLD_BOUNDS.y - BACKGROUND_BOUNDS.y) / BACKGROUND_BOUNDS.height) * 100,
    right: (((BACKGROUND_BOUNDS.x + BACKGROUND_BOUNDS.width) - (WORLD_BOUNDS.x + WORLD_BOUNDS.width)) / BACKGROUND_BOUNDS.width) * 100,
    bottom: (((BACKGROUND_BOUNDS.y + BACKGROUND_BOUNDS.height) - (WORLD_BOUNDS.y + WORLD_BOUNDS.height)) / BACKGROUND_BOUNDS.height) * 100,
    left: ((WORLD_BOUNDS.x - BACKGROUND_BOUNDS.x) / BACKGROUND_BOUNDS.width) * 100,
  };
  safeArea.style.inset = `${safeInsets.top}% ${safeInsets.right}% ${safeInsets.bottom}% ${safeInsets.left}%`;

  function renderCamera() {
    const cameraRect = camera.getBoundingClientRect();
    if (!cameraRect.width || !cameraRect.height) return;

    const panX = Number(xInput.value) / 100;
    const panY = Number(yInput.value) / 100;
    const planeWidth = cameraRect.width * (BACKGROUND_BOUNDS.width / viewport.width);
    const planeHeight = cameraRect.height * (BACKGROUND_BOUNDS.height / viewport.height);
    const travelX = Math.max(planeWidth - cameraRect.width, 0);
    const travelY = Math.max(planeHeight - cameraRect.height, 0);
    const logicalTravelX = Math.max(BACKGROUND_BOUNDS.width - viewport.width, 0);
    const logicalTravelY = Math.max(BACKGROUND_BOUNDS.height - viewport.height, 0);
    const cameraX = Math.round(BACKGROUND_BOUNDS.x + logicalTravelX * panX);
    const cameraY = Math.round(BACKGROUND_BOUNDS.y + logicalTravelY * panY);

    plane.style.width = `${planeWidth}px`;
    plane.style.height = `${planeHeight}px`;
    plane.style.transform = `translate(${-travelX * panX}px, ${-travelY * panY}px)`;
    xOutput.value = `${xInput.value}%`;
    yOutput.value = `${yInput.value}%`;
    positionOutput.textContent = `CAM X ${cameraX} · Y ${cameraY}`;
    coverageOutput.textContent = `${(BACKGROUND_BOUNDS.width / viewport.width).toFixed(1)} screens wide`;
  }

  document.querySelectorAll("[data-viewport]").forEach((button) => {
    button.addEventListener("click", () => {
      viewport = VIEWPORTS[button.dataset.viewport];
      document.querySelectorAll("[data-viewport]").forEach((candidate) => {
        candidate.setAttribute("aria-pressed", String(candidate === button));
      });
      renderCamera();
    });
  });

  [xInput, yInput].forEach((input) => input.addEventListener("input", renderCamera));
  seamInput.addEventListener("change", () => camera.classList.toggle("show-seams", seamInput.checked));

  if ("ResizeObserver" in window) {
    new ResizeObserver(renderCamera).observe(camera);
  } else {
    window.addEventListener("resize", renderCamera);
  }
  requestAnimationFrame(renderCamera);
}

class ComponentController {
  constructor(card, config) {
    this.card = card;
    this.config = config;
    this.mount = card.querySelector(`#${config.mount}`);
    this.mount.innerHTML = config.svg;
    this.pill = card.querySelector("[data-state-pill]");
    this.copy = card.querySelector("[data-state-copy]");
    this.duration = card.querySelector("[data-duration]");
    this.progress = card.querySelector("[data-progress]");
    this.layerCaption = card.querySelector("[data-layer-caption]");
    this.baseCaption = card.querySelector(".stage-caption span:first-child");
    this.autoButton = card.querySelector("[data-autoplay]");
    this.isPlaying = false;
    this.frame = null;
    this.state = config.initial;
    this.stateStartedAt = 0;

    this.pill.setAttribute("aria-live", "polite");
    this.bindControls();
    this.setState(config.initial, false);
  }

  bindControls() {
    this.card.querySelectorAll("[data-state-choice]").forEach((button) => {
      button.addEventListener("click", () => {
        this.stop();
        this.setState(button.dataset.stateChoice, false);
      });
    });

    this.autoButton.addEventListener("click", () => {
      if (this.isPlaying) {
        this.stop();
        return;
      }
      this.start();
    });

    this.card.querySelectorAll("[data-layer-toggle]").forEach((input) => {
      input.addEventListener("change", () => this.updateLayerVisibility());
    });
  }

  setState(nextState, fromTimeline) {
    const stateConfig = this.config.states[nextState];
    if (!stateConfig) return;
    this.state = nextState;
    this.card.dataset.state = nextState;
    this.pill.textContent = nextState.toUpperCase();
    this.pill.dataset.tone = stateConfig.tone;
    this.copy.textContent = stateConfig.copy;
    this.duration.textContent = stateConfig.duration === null ? "∞" : `${stateConfig.duration.toFixed(2)} s`;
    this.layerCaption.textContent = stateConfig.caption;
    this.baseCaption.textContent = nextState === "disabled" ? "BASE_01 · HIDDEN" : "BASE_01 · SAME NODE";

    this.card.querySelectorAll("[data-state-choice]").forEach((button) => {
      button.setAttribute("aria-pressed", String(button.dataset.stateChoice === nextState));
    });

    this.mount.querySelectorAll("[data-overlay]").forEach((layer) => {
      layer.style.display = layer.dataset.overlay === nextState ? "inline" : "none";
    });

    this.updateDebugState();
    this.updateLayerVisibility();
    this.progress.style.width = stateConfig.duration === null ? "100%" : "0%";
    if (!fromTimeline) this.stateStartedAt = performance.now();
  }

  updateLayerVisibility() {
    const values = {};
    this.card.querySelectorAll("[data-layer-toggle]").forEach((input) => {
      values[input.dataset.layerToggle] = input.checked;
    });
    this.card.classList.toggle("hide-base", !values.base);
    this.card.classList.toggle("hide-overlay", !values.overlay);
    this.mount.querySelectorAll('[data-layer="debug"]').forEach((layer) => {
      layer.style.display = values.debug ? "inline" : "none";
    });
  }

  updateDebugState() {
    if (this.card.dataset.component === "vent") {
      const damageActive = this.state === "active";
      const box = this.mount.querySelector("[data-damage-box]");
      const label = this.mount.querySelector("[data-debug-label]");
      if (box) box.setAttribute("stroke", damageActive ? "#d9654f" : "#d4a33f");
      if (label) {
        label.setAttribute("fill", damageActive ? "#f07a60" : "#f3d276");
        label.textContent = `AREA · DAMAGE ${damageActive ? "ON" : "OFF"}`;
      }
      return;
    }

    const collisionEnabled = this.state !== "disabled" && this.state !== "respawning";
    const box = this.mount.querySelector("[data-collision-box]");
    const label = this.mount.querySelector("[data-debug-label]");
    if (box) box.setAttribute("stroke", collisionEnabled ? "#62a9b5" : "#d9654f");
    if (label) {
      label.setAttribute("fill", collisionEnabled ? "#9bd4da" : "#f07a60");
      label.textContent = `SENSOR ON · COLLISION ${collisionEnabled ? "ON" : "OFF"}`;
    }
  }

  start() {
    this.stop(false);
    this.isPlaying = true;
    this.autoButton.setAttribute("aria-pressed", "true");
    this.autoButton.innerHTML = '<span aria-hidden="true">■</span> Stop';
    const firstState = this.config.sequence[0];
    this.setState(firstState, false);
    this.stateStartedAt = performance.now();
    this.frame = requestAnimationFrame((time) => this.tick(time));
  }

  stop(resetButton = true) {
    this.isPlaying = false;
    if (this.frame !== null) cancelAnimationFrame(this.frame);
    this.frame = null;
    if (resetButton) this.resetAutoButton();
  }

  resetAutoButton() {
    this.autoButton.setAttribute("aria-pressed", "false");
    const label = this.card.dataset.component === "vent" ? "Cycle" : "Collapse";
    this.autoButton.innerHTML = `<span aria-hidden="true">▶</span> ${label}`;
  }

  tick(now) {
    if (!this.isPlaying) return;
    const stateConfig = this.config.states[this.state];
    if (stateConfig.duration === null) {
      this.finishSequence();
      return;
    }

    const elapsed = (now - this.stateStartedAt) / 1000;
    const ratio = Math.min(elapsed / stateConfig.duration, 1);
    this.progress.style.width = `${ratio * 100}%`;

    if (ratio >= 1) {
      const index = this.config.sequence.indexOf(this.state);
      let nextIndex = index + 1;
      if (nextIndex >= this.config.sequence.length) {
        if (!this.config.loop) {
          this.finishSequence();
          return;
        }
        nextIndex = 0;
      }
      const nextState = this.config.sequence[nextIndex];
      this.setState(nextState, true);
      this.stateStartedAt = now;
    }

    this.frame = requestAnimationFrame((time) => this.tick(time));
  }

  finishSequence() {
    this.stop();
    this.setState(this.config.initial, false);
  }
}

function setupComponents() {
  Object.entries(COMPONENTS).forEach(([name, config]) => {
    const card = document.querySelector(`[data-component="${name}"]`);
    if (card) new ComponentController(card, config);
  });
}

setupWorldViewer();
setupComponents();
