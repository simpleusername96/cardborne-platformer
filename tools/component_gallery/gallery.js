"use strict";

const REPORT = window.CARDBORNE_VISUAL_COVERAGE;
if (!REPORT || !REPORT.flooded) {
  throw new Error("Generated Flooded Works coverage data is required. Run build_gallery.ps1.");
}

const FLOODED = REPORT.flooded;
const WORLD_BOUNDS = FLOODED.world_bounds;
const COMPOSITE = FLOODED.composite_size;
const PANEL = FLOODED.panel_size;
const OVERLAP = Number(FLOODED.panel_overlap);
const OVERSCAN = FLOODED.overscan;
const SCROLL_SCALE = FLOODED.scroll_scale;
const VIEWPORTS = {
  "960x540": { width: 960, height: 540 },
  "1280x720": { width: 1280, height: 720 },
  "1920x1080": { width: 1920, height: 1080 },
};

const COMPONENTS = {
  vent: {
    mount: "vent-raster",
    initial: "warning",
    loop: true,
    sequence: ["warning", "active", "cooldown"],
    states: {
      warning: { duration: 0.70, copy: "사전 경고 · 피해 없음", caption: "+ WARNING_OVERLAY.PNG", tone: "warning" },
      active: { duration: 1.20, copy: "독성 분출 · 피해 판정 켜짐", caption: "+ ACTIVE_OVERLAY.PNG", tone: "danger" },
      cooldown: { duration: 1.50, copy: "잔류 증기 · 피해 없음", caption: "+ COOLDOWN_OVERLAY.PNG", tone: "cool" },
    },
  },
  platform: {
    mount: "platform-raster",
    initial: "stable",
    loop: false,
    sequence: ["warning", "disabled", "respawning", "stable"],
    states: {
      stable: { duration: null, copy: "고정 상태 · 충돌 켜짐", caption: "+ NO OVERLAY", tone: "stable" },
      warning: { duration: 0.45, copy: "균열 경고 · 충돌 켜짐", caption: "+ WARNING_OVERLAY.PNG", tone: "warning" },
      disabled: { duration: 1.80, copy: "발판 붕괴 · 충돌 꺼짐", caption: "+ DISABLED_OVERLAY.PNG", tone: "danger" },
      respawning: { duration: 0.25, copy: "베이스 복원 · 충돌 꺼짐", caption: "+ RESPAWNING_OVERLAY.PNG", tone: "cool" },
    },
  },
};

function formatSize(value, decimals = 0) {
  const width = Number(value.x).toFixed(decimals);
  const height = Number(value.y).toFixed(decimals);
  return `${width} × ${height}`;
}

function setupMetrics() {
  document.querySelector("#stage-bounds").textContent = `${WORLD_BOUNDS.width} × ${WORLD_BOUNDS.height}`;
  document.querySelector("#required-composite").textContent = formatSize(FLOODED.required_composite_size, 1);
  document.querySelector("#produced-composite").textContent = formatSize(COMPOSITE);
  document.querySelector("#memory-value").textContent = `${FLOODED.estimated_rgba_mib.toFixed(0)} MiB`;
}

function setupWorldViewer() {
  const camera = document.querySelector("#world-camera");
  const plane = document.querySelector("#background-plane");
  const xInput = document.querySelector("#camera-x");
  const yInput = document.querySelector("#camera-y");
  const xOutput = document.querySelector("#camera-x-output");
  const yOutput = document.querySelector("#camera-y-output");
  const positionOutput = document.querySelector("#camera-position");
  const seamInput = document.querySelector("#show-seams");
  let viewport = VIEWPORTS["1280x720"];

  plane.style.setProperty("--panel-width", `${(PANEL.x / COMPOSITE.x) * 100}%`);
  plane.style.setProperty("--panel-two-left", `${((PANEL.x - OVERLAP) / COMPOSITE.x) * 100}%`);
  plane.style.setProperty("--overlap-width", `${(OVERLAP / COMPOSITE.x) * 100}%`);

  function renderCamera() {
    const rect = camera.getBoundingClientRect();
    if (!rect.width) return;
    const scale = rect.width / viewport.width;
    const panX = Number(xInput.value) / 100;
    const panY = Number(yInput.value) / 100;
    const worldTravelX = Math.max(WORLD_BOUNDS.width - viewport.width, 0);
    const worldTravelY = Math.max(WORLD_BOUNDS.height - viewport.height, 0);
    const sampleX = Number(OVERSCAN.x) + worldTravelX * Number(SCROLL_SCALE.x) * panX;
    const sampleY = Number(OVERSCAN.y) + worldTravelY * Number(SCROLL_SCALE.y) * panY;
    const cameraX = Math.round(Number(WORLD_BOUNDS.x) + worldTravelX * panX);
    const cameraY = Math.round(Number(WORLD_BOUNDS.y) + worldTravelY * panY);

    plane.style.width = `${Number(COMPOSITE.x) * scale}px`;
    plane.style.height = `${Number(COMPOSITE.y) * scale}px`;
    plane.style.transform = `translate(${-sampleX * scale}px, ${-sampleY * scale}px)`;
    xOutput.value = `${xInput.value}%`;
    yOutput.value = `${yInput.value}%`;
    positionOutput.textContent = `CAM X ${cameraX} · Y ${cameraY}`;
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
  if ("ResizeObserver" in window) new ResizeObserver(renderCamera).observe(camera);
  else window.addEventListener("resize", renderCamera);
  requestAnimationFrame(renderCamera);
}

class ComponentController {
  constructor(card, config) {
    this.card = card;
    this.config = config;
    this.mount = card.querySelector(`#${config.mount}`);
    this.pill = card.querySelector("[data-state-pill]");
    this.copy = card.querySelector("[data-state-copy]");
    this.duration = card.querySelector("[data-duration]");
    this.progress = card.querySelector("[data-progress]");
    this.layerCaption = card.querySelector("[data-layer-caption]");
    this.baseCaption = card.querySelector(".stage-caption span:first-child");
    this.autoButton = card.querySelector("[data-autoplay]");
    this.state = config.initial;
    this.isPlaying = false;
    this.frame = null;
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
    this.autoButton.addEventListener("click", () => this.isPlaying ? this.stop() : this.start());
    this.card.querySelectorAll("[data-layer-toggle]").forEach((input) => {
      input.addEventListener("change", () => this.updateLayerVisibility());
    });
  }

  setState(nextState, fromTimeline) {
    const state = this.config.states[nextState];
    if (!state) return;
    this.state = nextState;
    this.card.dataset.state = nextState;
    this.pill.textContent = nextState.toUpperCase();
    this.pill.dataset.tone = state.tone;
    this.copy.textContent = state.copy;
    this.duration.textContent = state.duration === null ? "∞" : `${state.duration.toFixed(2)} s`;
    this.layerCaption.textContent = state.caption;
    this.baseCaption.textContent = nextState === "disabled" ? "BASE.PNG · SAME NODE · HIDDEN" : "BASE.PNG · SAME NODE";
    this.card.querySelectorAll("[data-state-choice]").forEach((button) => {
      button.setAttribute("aria-pressed", String(button.dataset.stateChoice === nextState));
    });
    this.mount.querySelectorAll("[data-overlay]").forEach((layer) => {
      layer.style.display = layer.dataset.overlay === nextState ? "block" : "none";
    });
    const debugLabel = this.mount.querySelector(".debug-box span");
    if (debugLabel) {
      const active = this.card.dataset.component === "vent" ? nextState === "active" : !["disabled", "respawning"].includes(nextState);
      debugLabel.textContent = `${this.card.dataset.component === "vent" ? "180×96" : "220×28"} · COLLISION ${active ? "ON" : "OFF"} · PIVOT 0,0`;
    }
    this.updateLayerVisibility();
    this.progress.style.width = state.duration === null ? "100%" : "0%";
    if (!fromTimeline) this.stateStartedAt = performance.now();
  }

  updateLayerVisibility() {
    const values = {};
    this.card.querySelectorAll("[data-layer-toggle]").forEach((input) => { values[input.dataset.layerToggle] = input.checked; });
    this.card.classList.toggle("hide-base", !values.base);
    this.card.classList.toggle("hide-overlay", !values.overlay);
    this.mount.querySelectorAll('[data-layer="debug"]').forEach((layer) => { layer.style.display = values.debug ? "block" : "none"; });
  }

  start() {
    this.stop(false);
    this.isPlaying = true;
    this.autoButton.setAttribute("aria-pressed", "true");
    this.autoButton.innerHTML = '<span aria-hidden="true">■</span> Stop';
    this.setState(this.config.sequence[0], false);
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
    const state = this.config.states[this.state];
    if (state.duration === null) {
      this.finishSequence();
      return;
    }
    const ratio = Math.min((now - this.stateStartedAt) / 1000 / state.duration, 1);
    this.progress.style.width = `${ratio * 100}%`;
    if (ratio >= 1) {
      let nextIndex = this.config.sequence.indexOf(this.state) + 1;
      if (nextIndex >= this.config.sequence.length) {
        if (!this.config.loop) {
          this.finishSequence();
          return;
        }
        nextIndex = 0;
      }
      this.setState(this.config.sequence[nextIndex], true);
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

setupMetrics();
setupWorldViewer();
setupComponents();
