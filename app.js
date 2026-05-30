const WIDTH = 12;
const HEIGHT = 9;

const weapons = {
  pistol: { name: "Pistola", damage: 3, range: 4 },
  shotgun: { name: "Escopeta", damage: 5, range: 2 },
  rifle: { name: "Rifle", damage: 4, range: 6 }
};

const bioWeapons = {
  pistol: { name: "Mordida", damage: 3, range: 1 },
  shotgun: { name: "Garra brutal", damage: 5, range: 1 },
  rifle: { name: "Ataque acido", damage: 4, range: 4 }
};

const coverTiles = new Set(["4,1", "7,1", "2,3", "5,4", "8,4", "9,6", "3,7"]);

const upgrades = [
  { id: "weaponDrill", name: "Entrenamiento de armas", cost: 220000, research: 2, text: "+1 dano con armas y ataques B.O.W." },
  { id: "fieldMedic", name: "Botiquines de campo", cost: 180000, research: 2, text: "+2 vida inicial para unidades humanas" },
  { id: "bowGrowth", name: "Cultivo acelerado", cost: 260000, research: 3, text: "+2 vida inicial para B.O.W.s" },
  { id: "mobility", name: "Rutas tacticas", cost: 240000, research: 3, text: "+1 movimiento al escuadron inicial" },
  { id: "squadSlot", name: "Ranura extra", cost: 360000, research: 5, text: "Permite desplegar una unidad extra" }
];

const audioFiles = {
  music: "assets/audio/music-ambient.wav",
  ui: "assets/audio/ui.wav",
  step: "assets/audio/step.wav",
  shot: "assets/audio/shot.wav",
  bite: "assets/audio/bite.wav",
  special: "assets/audio/special.wav",
  turn: "assets/audio/turn.wav",
  victory: "assets/audio/victory.wav",
  defeat: "assets/audio/defeat.wav",
  death: "assets/audio/defeat.wav",
  upgrade: "assets/audio/ui.wav"
};

const factions = {
  bsaa: {
    name: "BSAA",
    mission: "Incidente en las afueras de Raccoon City",
    special: "Granada de contencion",
    specialDamage: 4,
    specialRange: 3,
    units: [
      ["h1", "Chris", 1, 1, 12, 4],
      ["h2", "Jill", 1, 3, 10, 5],
      ["h3", "Piers", 1, 5, 10, 4],
      ["h4", "Sheva", 2, 7, 10, 4],
      ["h5", "Soldado", 3, 2, 9, 4]
    ]
  },
  dso: {
    name: "DSO",
    mission: "Extraccion en Penamstan",
    special: "Disparo perforante",
    specialDamage: 6,
    specialRange: 6,
    units: [
      ["h1", "Leon", 1, 1, 10, 4],
      ["h2", "Helena", 1, 3, 9, 4],
      ["h3", "Agente", 1, 5, 9, 4],
      ["h4", "Tirador", 2, 7, 8, 4],
      ["h5", "Soporte", 3, 2, 9, 4]
    ]
  },
  houndwolf: {
    name: "Hound Wolf",
    mission: "Operacion nocturna en Europa del Este",
    special: "Carga explosiva",
    specialDamage: 5,
    specialRange: 4,
    units: [
      ["h1", "Lobo 1", 1, 1, 11, 5],
      ["h2", "Canine", 1, 3, 10, 5],
      ["h3", "Tundra", 1, 5, 9, 5],
      ["h4", "Umber", 2, 7, 10, 5],
      ["h5", "Night Howl", 3, 2, 9, 5]
    ]
  },
  umbrella: {
    name: "Umbrella",
    mission: "Prueba de campo: brote controlado",
    special: "Liberar mutageno",
    specialDamage: 5,
    specialRange: 4,
    economy: true,
    budget: 1000000,
    units: []
  }
};

const enemyRoster = [
  ["e1", "Zombie", 10, 1, 7, 3],
  ["e2", "Zombie", 9, 3, 7, 3],
  ["e3", "Ganado", 10, 5, 8, 3],
  ["e4", "Perro infectado", 8, 7, 6, 4],
  ["e5", "Licker", 11, 7, 12, 3]
];

const responseRoster = [
  ["e1", "Chris", 10, 1, 12, 4],
  ["e2", "Jill", 9, 3, 10, 5],
  ["e3", "Leon", 10, 5, 10, 4],
  ["e4", "Claire", 8, 7, 9, 4],
  ["e5", "Agente BSAA", 11, 7, 9, 4]
];

const bowShop = [
  { id: "zombie", name: "Zombie", cost: 90000, hp: 7, move: 3, count: 3 },
  { id: "cerberus", name: "Cerberus", cost: 160000, hp: 6, move: 5, count: 1 },
  { id: "licker", name: "Licker", cost: 260000, hp: 12, move: 4, count: 1 },
  { id: "tyrant", name: "Tyrant T-Proto", cost: 420000, hp: 18, move: 2, count: 1 }
];

const playerSpawn = [
  [1, 1],
  [1, 3],
  [1, 5],
  [2, 7],
  [3, 2],
  [2, 4],
  [3, 6]
];

const missions = [
  {
    id: "raccoon-outskirts",
    name: "Afueras de Raccoon City",
    briefing: "Contener el brote inicial y recuperar el punto de extraccion.",
    rewardCredits: 180000,
    rewardResearch: 2,
    map: {
      theme: "city",
      cover: ["4,1", "7,1", "2,3", "5,4", "8,4", "9,6", "3,7"]
    },
    enemyRoster,
    responseRoster
  },
  {
    id: "penamstan-port",
    name: "Puerto de Penamstan",
    briefing: "Entrar al puerto, cortar la ruta de infeccion y eliminar hostiles rapidos.",
    rewardCredits: 260000,
    rewardResearch: 3,
    map: {
      theme: "port",
      cover: ["3,1", "4,2", "5,2", "7,3", "2,5", "8,6", "9,7", "6,7"]
    },
    enemyRoster: [
      ["e1", "Zombie", 10, 1, 8, 3],
      ["e2", "Ganado", 8, 2, 9, 3],
      ["e3", "Perro infectado", 10, 5, 7, 5],
      ["e4", "Licker", 8, 7, 12, 4],
      ["e5", "Brute", 11, 6, 14, 2]
    ],
    responseRoster: [
      ["e1", "Leon", 10, 1, 11, 4],
      ["e2", "Claire", 9, 3, 9, 4],
      ["e3", "Agente DSO", 10, 5, 9, 4],
      ["e4", "Tirador", 8, 7, 8, 4],
      ["e5", "Capitan", 11, 7, 12, 3]
    ]
  },
  {
    id: "valdelobos-night",
    name: "Valdelobos de noche",
    briefing: "Sobrevivir a una zona hostil y neutralizar al enemigo pesado.",
    rewardCredits: 380000,
    rewardResearch: 5,
    map: {
      theme: "village",
      cover: ["5,1", "6,1", "2,2", "8,3", "4,4", "5,5", "3,6", "9,6", "7,7"]
    },
    enemyRoster: [
      ["e1", "Ganado", 10, 1, 10, 3],
      ["e2", "Ganado", 9, 3, 10, 3],
      ["e3", "Colmillo", 10, 5, 8, 5],
      ["e4", "Licker", 8, 7, 13, 4],
      ["e5", "Tyrant fallido", 11, 7, 20, 2]
    ],
    responseRoster: [
      ["e1", "Chris", 10, 1, 13, 4],
      ["e2", "Jill", 9, 3, 11, 5],
      ["e3", "Leon", 10, 5, 11, 4],
      ["e4", "Hound Wolf", 8, 7, 10, 5],
      ["e5", "Especialista", 11, 7, 12, 4]
    ]
  }
];

let state;

const battlefield = document.querySelector("#battlefield");
const gameStage = document.querySelector(".game-stage");
const titleScreen = document.querySelector("#titleScreen");
const continueBtn = document.querySelector("#continueBtn");
const tutorialBtn = document.querySelector("#tutorialBtn");
const tutorialModal = document.querySelector("#tutorialModal");
const closeTutorialBtn = document.querySelector("#closeTutorialBtn");
const roundLabel = document.querySelector("#roundLabel");
const turnLabel = document.querySelector("#turnLabel");
const missionLabel = document.querySelector("#missionLabel");
const squadTitle = document.querySelector("#squadTitle");
const selectedUnitStats = document.querySelector("#selectedUnitStats");
const unitPanel = document.querySelector("#unitPanel");
const objectiveText = document.querySelector("#objectiveText");
const objectiveStats = document.querySelector("#objectiveStats");
const logEl = document.querySelector("#log");
const resultModal = document.querySelector("#resultModal");
const resultTitle = document.querySelector("#resultTitle");
const resultText = document.querySelector("#resultText");
const startScreen = document.querySelector("#startScreen");
const startBtn = document.querySelector("#startBtn");
const bowBuilder = document.querySelector("#bowBuilder");
const bowShopEl = document.querySelector("#bowShop");
const bowRosterEl = document.querySelector("#bowRoster");
const budgetLabel = document.querySelector("#budgetLabel");
const campaignLabel = document.querySelector("#campaignLabel");
const campaignSummary = document.querySelector("#campaignSummary");
const missionBrief = document.querySelector("#missionBrief");
const missionList = document.querySelector("#missionList");
const upgradeList = document.querySelector("#upgradeList");
const campaignMap = document.querySelector("#campaignMap");
const editorGrid = document.querySelector("#editorGrid");
const saveMapBtn = document.querySelector("#saveMapBtn");
const loadMapBtn = document.querySelector("#loadMapBtn");
const muteBtn = document.querySelector("#muteBtn");
const volumeSlider = document.querySelector("#volumeSlider");
const resetProgressBtn = document.querySelector("#resetProgressBtn");
const menuBtn = document.querySelector("#menuBtn");
const nextMissionBtn = document.querySelector("#nextMissionBtn");

const actionButtons = {
  move: document.querySelector("#moveBtn"),
  attack: document.querySelector("#attackBtn"),
  special: document.querySelector("#specialBtn"),
  wait: document.querySelector("#waitBtn"),
  end: document.querySelector("#endTurnBtn")
};

let selectedFaction = "bsaa";
let selectedMissionIndex = 0;
let selectedBows = defaultBowRoster();
let bowBudget = getRemainingBudget(selectedBows);
let campaign = loadCampaign();
let audioContext;
let visualEffects = { movedId: null, attackerId: null, hitIds: [], specialKey: null };
let audioMuted = localStorage.getItem("reFanTacticsMuted") === "true";
let audioVolume = Number(localStorage.getItem("reFanTacticsVolume") || 55) / 100;
let musicAudio;
let editorTool = "cover";
let editorMap = loadEditorMap();

function newGame(factionId = selectedFaction) {
  unlockAudio();
  selectedFaction = factions[factionId] ? factionId : "bsaa";
  const faction = factions[selectedFaction];
  const mission = missions[selectedMissionIndex] || missions[0];
  const baseFactionUnits = hasUpgrade("squadSlot", selectedFaction)
    ? [...faction.units, ["h6", "Refuerzo", 2, 4, 9, 4]]
    : faction.units;
  const playerUnits = faction.economy ? buildUmbrellaUnits() : baseFactionUnits.map(([id, name, x, y, hp, move]) => {
    return unit(id, name, "hero", x, y, hp, move, getRoleForName(name, "hero"));
  });
  const opponents = faction.economy ? mission.responseRoster.map(([id, name, x, y, hp, move]) => {
    return unit(id, name, "enemy", x, y, hp, move, getRoleForName(name, "hero"));
  }) : mission.enemyRoster.map(([id, name, x, y, hp, move]) => {
    return unit(id, name, "enemy", x, y, hp, move, getRoleForName(name, "infected"));
  });

  state = {
    round: 1,
    side: "hero",
    mode: "move",
    selectedId: "h1",
    selectedWeapon: "pistol",
    factionId: selectedFaction,
    missionIndex: selectedMissionIndex,
    specialUsed: false,
    completed: false,
    mapTheme: mission.map.theme,
    log: [],
    units: [...playerUnits, ...opponents]
  };

  visualEffects = { movedId: null, attackerId: null, hitIds: [], specialKey: null };
  addLog(`${faction.name} desplegado en ${mission.name}.`);
  addLog(mission.briefing);
  playSound("ui");
  resultModal.classList.add("is-hidden");
  startScreen.classList.add("is-hidden");
  render();
}

function buildUmbrellaUnits() {
  const maxUnits = hasUpgrade("squadSlot") ? playerSpawn.length : 5;
  const roster = selectedBows.length > 0 ? selectedBows : defaultBowRoster();
  return roster.slice(0, maxUnits).map((bowId, index) => {
    const bow = bowShop.find((item) => item.id === bowId);
    const [x, y] = playerSpawn[index];
    return unit(`h${index + 1}`, bow.name, "hero", x, y, bow.hp, bow.move, getRoleForName(bow.name, "bio"));
  });
}

function defaultBowRoster() {
  return ["zombie", "zombie", "zombie", "cerberus", "licker"];
}

function unit(id, name, side, x, y, hp, move, role = "hero") {
  const isHuman = role === "hero" || role === "scout" || role === "brute";
  const isBio = role.startsWith("bio") || role === "infected" || role === "beast";
  const bonusHp = (isHuman && hasUpgrade("fieldMedic") ? 2 : 0) + (isBio && hasUpgrade("bowGrowth") ? 2 : 0);
  const bonusMove = hasUpgrade("mobility") ? 1 : 0;
  return { id, name, side, x, y, hp: hp + bonusHp, maxHp: hp + bonusHp, move: move + bonusMove, role, acted: false };
}

function getRoleForName(name, fallback) {
  const lowered = name.toLowerCase();
  if (lowered.includes("tyrant") || lowered.includes("brute") || lowered.includes("capitan")) return fallback === "bio" ? "bio-brute" : "brute";
  if (lowered.includes("perro") || lowered.includes("cerberus") || lowered.includes("colmillo")) return fallback === "bio" ? "bio-beast" : "beast";
  if (lowered.includes("licker")) return fallback === "bio" ? "bio-beast" : "beast";
  if (lowered.includes("tirador") || lowered.includes("jill") || lowered.includes("leon")) return "scout";
  return fallback;
}

function render() {
  const faction = factions[state.factionId];
  const mission = missions[state.missionIndex];
  roundLabel.textContent = `Ronda ${state.round}`;
  turnLabel.textContent = state.side === "hero" ? "Turno de heroes" : "Turno de infectados";
  missionLabel.textContent = mission.name;
  campaignLabel.textContent = `${faction.name}: ${getFactionProgress(state.factionId).wins} victoria(s)`;
  squadTitle.textContent = `Escuadron ${faction.name}`;
  renderBoard();
  renderPanel();
  renderLog();
  renderObjective();
  updateButtons();
}

function renderBoard() {
  battlefield.innerHTML = "";
  const selected = getSelectedUnit();
  const highlights = selected ? getHighlights(selected) : new Set();
  const coverSet = getCurrentCover();
  battlefield.dataset.theme = state.mapTheme;

  for (let y = 0; y < HEIGHT; y += 1) {
    for (let x = 0; x < WIDTH; x += 1) {
      const tile = document.createElement("button");
      tile.className = "tile";
      tile.type = "button";
      tile.dataset.x = String(x);
      tile.dataset.y = String(y);
      tile.style.left = `${(x - y) * 38}px`;
      tile.style.top = `${(x + y) * 20}px`;
      tile.style.zIndex = String((x + y) * 2);

      const key = `${x},${y}`;
      if ((x + y) % 2 === 1) tile.classList.add("tile-alt");
      if (coverSet.has(key)) tile.classList.add("cover");
      if (highlights.has(key)) tile.classList.add(state.mode === "attack" || state.mode === "special" ? "attackable" : "reachable");
      if (selected && selected.x === x && selected.y === y) tile.classList.add("selected");
      if (visualEffects.movedId && unitAt(x, y)?.id === visualEffects.movedId) tile.classList.add("moved");
      if (visualEffects.specialKey === key) tile.classList.add("special-burst");

      const occupying = unitAt(x, y);
      if (coverSet.has(key)) tile.appendChild(renderCoverProp());
      if (occupying) tile.appendChild(renderUnitToken(occupying));

      tile.addEventListener("click", () => handleTileClick(x, y));
      battlefield.appendChild(tile);
    }
  }
}

function renderCoverProp() {
  const prop = document.createElement("span");
  prop.className = "cover-prop";
  return prop;
}

function renderUnitToken(unitData) {
  const token = document.createElement("div");
  token.className = `unit ${unitData.side} ${unitData.role} ${unitData.name.length > 8 ? "unit-small-label" : ""}`;
  if (visualEffects.attackerId === unitData.id) token.classList.add("attack-flash");
  if (visualEffects.hitIds.includes(unitData.id)) token.classList.add("hit");
  token.textContent = unitData.side === "hero" || unitData.role === "hero" ? unitData.name[0] : "!";

  const hp = document.createElement("span");
  hp.className = "hp";
  hp.textContent = unitData.hp;
  token.appendChild(hp);

  return token;
}

function renderPanel() {
  const heroes = state.units.filter((unitData) => unitData.side === "hero" && unitData.hp > 0);
  const selected = getSelectedUnit();
  const faction = factions[state.factionId];
  const currentWeapons = getWeaponSet();
  unitPanel.innerHTML = "";
  selectedUnitStats.innerHTML = selected
    ? `
      <strong>${selected.name}</strong>
      <span>${selected.acted ? "Ya actuo este turno" : "Lista para actuar"} - ${currentWeapons[state.selectedWeapon].name}</span>
      <div class="stat-row">
        <span class="stat-pill">Vida ${selected.hp}/${selected.maxHp}</span>
        <span class="stat-pill">Mov ${selected.move}</span>
        <span class="stat-pill">${state.specialUsed ? "Especial usado" : faction.special}</span>
      </div>
    `
    : "<span>Sin unidad seleccionada</span>";

  heroes.forEach((hero) => {
    const card = document.createElement("button");
    card.type = "button";
    card.className = "unit-card";
    if (hero.id === state.selectedId) card.classList.add("is-selected");
    card.innerHTML = `
      <strong>${hero.name}</strong>
      <span>${hero.acted ? "Sin accion" : "Listo"}</span>
      <span>Vida ${hero.hp}/${hero.maxHp}</span>
      <span>${currentWeapons[state.selectedWeapon].name}</span>
    `;
    card.addEventListener("click", () => {
      if (state.side !== "hero") return;
      state.selectedId = hero.id;
      render();
    });
    unitPanel.appendChild(card);
  });
}

function renderLog() {
  logEl.innerHTML = "";
  state.log.slice(-8).reverse().forEach((entry) => {
    const p = document.createElement("p");
    p.textContent = entry;
    logEl.appendChild(p);
  });
}

function renderObjective() {
  const mission = missions[state.missionIndex];
  const enemiesLeft = state.units.filter((unitData) => unitData.side === "enemy" && unitData.hp > 0).length;
  const alliesLeft = state.units.filter((unitData) => unitData.side === "hero" && unitData.hp > 0).length;
  objectiveText.textContent = mission.briefing;
  objectiveStats.innerHTML = `
    <span class="objective-chip"><strong>${enemiesLeft}</strong>hostiles</span>
    <span class="objective-chip"><strong>${alliesLeft}</strong>aliados</span>
    <span class="objective-chip"><strong>${formatMoney(mission.rewardCredits)}</strong>recompensa</span>
  `;
}

function updateButtons() {
  actionButtons.move.classList.toggle("is-active", state.mode === "move");
  actionButtons.attack.classList.toggle("is-active", state.mode === "attack");
  actionButtons.special.classList.toggle("is-active", state.mode === "special");
  actionButtons.move.disabled = state.side !== "hero";
  actionButtons.attack.disabled = state.side !== "hero";
  actionButtons.special.disabled = state.side !== "hero" || state.specialUsed;
  actionButtons.wait.disabled = state.side !== "hero";
  actionButtons.end.disabled = state.side !== "hero";
  actionButtons.special.textContent = state.specialUsed ? "Especial usado" : "Especial";
}

function handleTileClick(x, y) {
  const clickedUnit = unitAt(x, y);

  if (clickedUnit && clickedUnit.side === "hero" && state.side === "hero") {
    state.selectedId = clickedUnit.id;
    render();
    return;
  }

  if (state.side !== "hero") return;

  const selected = getSelectedUnit();
  if (!selected || selected.acted) return;

  if (state.mode === "move") {
    moveSelectedUnit(selected, x, y);
  } else if (state.mode === "attack") {
    attackTarget(selected, clickedUnit);
  } else if (state.mode === "special") {
    useSpecial(selected, clickedUnit);
  }
}

function moveSelectedUnit(selected, x, y) {
  const key = `${x},${y}`;
  if (!getHighlights(selected).has(key) || unitAt(x, y) || getCurrentCover().has(key)) return;

  selected.x = x;
  selected.y = y;
  selected.acted = true;
  visualEffects = { movedId: selected.id, attackerId: null, hitIds: [], specialKey: null };
  playSound("step");
  addLog(`${selected.name} avanza a posicion tactica.`);
  afterHeroAction();
}

function attackTarget(attacker, target) {
  if (!target || target.side !== "enemy") return;

  const weapon = getWeaponSet()[state.selectedWeapon];
  if (distance(attacker, target) > weapon.range) return;

  const damage = weapon.damage + (hasUpgrade("weaponDrill") ? 1 : 0);
  target.hp -= damage;
  attacker.acted = true;
  visualEffects = { movedId: null, attackerId: attacker.id, hitIds: [target.id], specialKey: null };
  playSound(attacker.role.startsWith("bio") ? "bite" : "shot");
  addLog(`${attacker.name} usa ${weapon.name}: ${damage} dano.`);

  if (target.hp <= 0) {
    addLog(`${target.name} neutralizado.`);
    playSound("death");
    state.units = state.units.filter((unitData) => unitData.hp > 0);
  }

  afterHeroAction();
}

function useSpecial(attacker, target) {
  if (state.specialUsed || !target || target.side !== "enemy") return;

  const faction = factions[state.factionId];
  if (distance(attacker, target) > faction.specialRange) return;

  const affected = state.units.filter((unitData) => {
    return unitData.side === "enemy" && distance(target, unitData) <= 1;
  });

  const damage = faction.specialDamage + (hasUpgrade("weaponDrill") ? 1 : 0);
  affected.forEach((enemy) => {
    enemy.hp -= damage;
  });

  state.specialUsed = true;
  attacker.acted = true;
  visualEffects = { movedId: null, attackerId: attacker.id, hitIds: affected.map((enemy) => enemy.id), specialKey: `${target.x},${target.y}` };
  playSound("special");
  addLog(`${attacker.name} usa ${faction.special}. ${affected.length} objetivo(s) afectados.`);

  const defeated = affected.filter((enemy) => enemy.hp <= 0);
  defeated.forEach((enemy) => addLog(`${enemy.name} neutralizado por la habilidad especial.`));
  state.units = state.units.filter((unitData) => unitData.hp > 0);

  afterHeroAction();
}

function afterHeroAction() {
  if (checkWinLoss()) return;
  selectNextReadyHero();
  render();
}

function selectNextReadyHero() {
  const next = state.units.find((unitData) => unitData.side === "hero" && unitData.hp > 0 && !unitData.acted);
  if (next) {
    state.selectedId = next.id;
  } else {
    setTimeout(startEnemyTurn, 250);
  }
}

function startEnemyTurn() {
  state.side = "enemy";
  visualEffects = { movedId: null, attackerId: null, hitIds: [], specialKey: null };
  pulseTurn();
  playSound("turn");
  render();
  setTimeout(runEnemyTurn, 450);
}

function runEnemyTurn() {
  const enemies = state.units.filter((unitData) => unitData.side === "enemy" && unitData.hp > 0);

  enemies.forEach((enemy) => {
    const heroes = state.units.filter((unitData) => unitData.side === "hero" && unitData.hp > 0);
    if (heroes.length === 0) return;

    const target = chooseEnemyTarget(enemy, heroes);
    const attackRange = enemy.role === "scout" ? 4 : 1;
    if (distance(enemy, target) <= attackRange) {
      const damage = enemy.role === "brute" ? 4 : enemy.role === "scout" ? 3 : 2;
      target.hp -= damage;
      visualEffects = { movedId: null, attackerId: enemy.id, hitIds: [target.id], specialKey: null };
      playSound(enemy.role === "scout" || enemy.role === "hero" ? "shot" : "bite");
      addLog(`${enemy.name} hiere a ${target.name}.`);
      if (target.hp <= 0) addLog(`${target.name} cae en combate.`);
      state.units = state.units.filter((unitData) => unitData.hp > 0);
    } else {
      stepToward(enemy, target);
    }
  });

  if (checkWinLoss()) return;

  state.side = "hero";
  state.round += 1;
  visualEffects = { movedId: null, attackerId: null, hitIds: [], specialKey: null };
  pulseTurn();
  playSound("turn");
  state.units.forEach((unitData) => {
    unitData.acted = false;
  });
  selectNextReadyHero();
  render();
}

function stepToward(unitData, target) {
  const candidates = [
    { x: unitData.x + Math.sign(target.x - unitData.x), y: unitData.y },
    { x: unitData.x, y: unitData.y + Math.sign(target.y - unitData.y) },
    { x: unitData.x + Math.sign(target.x - unitData.x), y: unitData.y + Math.sign(target.y - unitData.y) },
    { x: unitData.x + 1, y: unitData.y },
    { x: unitData.x - 1, y: unitData.y },
    { x: unitData.x, y: unitData.y + 1 },
    { x: unitData.x, y: unitData.y - 1 }
  ];

  const coverSet = getCurrentCover();
  const next = candidates
    .filter((tile) => inBounds(tile.x, tile.y) && !unitAt(tile.x, tile.y) && !coverSet.has(`${tile.x},${tile.y}`))
    .sort((a, b) => {
      const aScore = distance(a, target) - flankBonus(a, target);
      const bScore = distance(b, target) - flankBonus(b, target);
      return aScore - bScore;
    })[0];

  if (next) {
    unitData.x = next.x;
    unitData.y = next.y;
    visualEffects = { movedId: unitData.id, attackerId: null, hitIds: [], specialKey: null };
  }
}

function chooseEnemyTarget(enemy, heroes) {
  return heroes.slice().sort((a, b) => {
    const aScore = a.hp * 1.4 + distance(enemy, a) * 1.8 - (a.acted ? 0 : 1);
    const bScore = b.hp * 1.4 + distance(enemy, b) * 1.8 - (b.acted ? 0 : 1);
    return aScore - bScore;
  })[0];
}

function flankBonus(tile, target) {
  const adjacentAllies = state.units.filter((unitData) => {
    return unitData.side === "enemy" && distance(unitData, target) <= 1;
  }).length;
  return distance(tile, target) <= 1 ? adjacentAllies * 0.5 : 0;
}

function checkWinLoss() {
  const heroesLeft = state.units.some((unitData) => unitData.side === "hero" && unitData.hp > 0);
  const enemiesLeft = state.units.some((unitData) => unitData.side === "enemy" && unitData.hp > 0);

  if (!enemiesLeft) {
    const reward = completeMission();
    playSound("victory");
    showResult("Zona despejada", `Victoria en ${missions[state.missionIndex].name}. Recompensa: ${formatMoney(reward.credits)} y ${reward.research} datos de investigacion.`);
    return true;
  }

  if (!heroesLeft) {
    playSound("defeat");
    showResult("Mision fallida", "La zona queda perdida. Reinicia y prueba otra combinacion de armas.");
    return true;
  }

  return false;
}

function showResult(title, text) {
  resultTitle.textContent = title;
  resultText.textContent = text;
  nextMissionBtn.disabled = state.missionIndex >= missions.length - 1;
  resultModal.classList.remove("is-hidden");
  render();
}

function completeMission() {
  if (state.completed) return { credits: 0, research: 0 };
  const mission = missions[state.missionIndex];
  const progress = getFactionProgress(state.factionId);
  progress.wins += 1;
  progress.credits += mission.rewardCredits;
  progress.research += mission.rewardResearch;
  progress.unlockedMission = Math.max(progress.unlockedMission, Math.min(state.missionIndex + 1, missions.length - 1));
  progress.bestRounds[mission.id] = Math.min(progress.bestRounds[mission.id] || 99, state.round);
  state.completed = true;
  saveCampaign();
  return { credits: mission.rewardCredits, research: mission.rewardResearch };
}

function getHighlights(selected) {
  const highlights = new Set();
  const faction = factions[state.factionId];
  const range = state.mode === "attack"
    ? getWeaponSet()[state.selectedWeapon].range
    : state.mode === "special"
      ? faction.specialRange
      : selected.move;

  for (let y = 0; y < HEIGHT; y += 1) {
    for (let x = 0; x < WIDTH; x += 1) {
      if (distance(selected, { x, y }) <= range) highlights.add(`${x},${y}`);
    }
  }

  return highlights;
}

function getCurrentCover() {
  const saved = localStorage.getItem("reFanTacticsUseEditorMap") === "true" ? loadEditorMap() : null;
  if (saved && saved.cover.length > 0) return new Set(saved.cover);
  return new Set((missions[state?.missionIndex || selectedMissionIndex]?.map?.cover || Array.from(coverTiles)));
}

function getWeaponSet() {
  return state && factions[state.factionId]?.economy ? bioWeapons : weapons;
}

function updateWeaponCards() {
  const currentWeapons = selectedFaction === "umbrella" ? bioWeapons : weapons;
  document.querySelectorAll(".weapon-card").forEach((button) => {
    const weapon = currentWeapons[button.dataset.weapon];
    button.querySelector("span").textContent = weapon.name;
    button.querySelector("strong").textContent = `${weapon.damage} dano / ${weapon.range} casillas`;
  });
}

function renderBowBuilder() {
  const isUmbrella = selectedFaction === "umbrella";
  const maxUnits = hasUpgrade("squadSlot", "umbrella") ? playerSpawn.length : 5;
  bowBuilder.classList.toggle("is-hidden", !isUmbrella);
  updateWeaponCards();
  if (!isUmbrella) return;

  budgetLabel.textContent = formatMoney(bowBudget);
  bowShopEl.innerHTML = "";
  bowShop.forEach((item) => {
    const button = document.createElement("button");
    button.type = "button";
    button.className = "shop-card";
    button.disabled = bowBudget < item.cost || selectedBows.length >= maxUnits;
    button.innerHTML = `
      <strong>${item.name}</strong>
      <span>${formatMoney(item.cost)} - Vida ${item.hp} - Mov ${item.move}</span>
    `;
    button.addEventListener("click", () => buyBow(item.id));
    bowShopEl.appendChild(button);
  });

  bowRosterEl.innerHTML = "";
  const roster = selectedBows.length > 0 ? selectedBows : defaultBowRoster();
  roster.forEach((bowId, index) => {
    const item = bowShop.find((bow) => bow.id === bowId);
    const chip = document.createElement("button");
    chip.type = "button";
    chip.className = "roster-chip";
    chip.innerHTML = `<strong>${index + 1}. ${item.name}</strong><span>Click para quitar</span>`;
    chip.addEventListener("click", () => removeBow(index));
    bowRosterEl.appendChild(chip);
  });
}

function buyBow(bowId) {
  const item = bowShop.find((bow) => bow.id === bowId);
  if (!item || bowBudget < item.cost || selectedBows.length >= playerSpawn.length) return;
  selectedBows.push(bowId);
  bowBudget -= item.cost;
  playSound("upgrade");
  renderBowBuilder();
}

function removeBow(index) {
  const [removed] = selectedBows.splice(index, 1);
  if (!removed) return;
  const item = bowShop.find((bow) => bow.id === removed);
  bowBudget += item.cost;
  playSound("ui");
  renderBowBuilder();
}

function getRemainingBudget(roster) {
  return factions.umbrella.budget - roster.reduce((sum, id) => {
    return sum + bowShop.find((bow) => bow.id === id).cost;
  }, 0);
}

function formatMoney(value) {
  return `$${value.toLocaleString("es-AR")}`;
}

function getFactionProgress(factionId = selectedFaction) {
  if (!campaign[factionId]) {
    campaign[factionId] = { wins: 0, credits: 0, research: 0, unlockedMission: 0, bestRounds: {}, upgrades: [] };
  }
  if (!campaign[factionId].upgrades) campaign[factionId].upgrades = [];
  return campaign[factionId];
}

function loadCampaign() {
  try {
    const saved = JSON.parse(localStorage.getItem("reFanTacticsCampaign") || "{}");
    return saved && typeof saved === "object" ? saved : {};
  } catch {
    return {};
  }
}

function saveCampaign() {
  localStorage.setItem("reFanTacticsCampaign", JSON.stringify(campaign));
}

function resetCampaignProgress() {
  campaign[selectedFaction] = { wins: 0, credits: 0, research: 0, unlockedMission: 0, bestRounds: {}, upgrades: [] };
  saveCampaign();
  selectedMissionIndex = 0;
  renderStartScreen();
}

function hasUpgrade(upgradeId, factionId = selectedFaction) {
  return getFactionProgress(factionId).upgrades.includes(upgradeId);
}

function buyUpgrade(upgradeId) {
  const upgrade = upgrades.find((item) => item.id === upgradeId);
  const progress = getFactionProgress(selectedFaction);
  if (!upgrade || progress.upgrades.includes(upgradeId)) return;
  if (progress.credits < upgrade.cost || progress.research < upgrade.research) return;
  progress.credits -= upgrade.cost;
  progress.research -= upgrade.research;
  progress.upgrades.push(upgradeId);
  saveCampaign();
  playSound("upgrade");
  renderStartScreen();
}

function renderStartScreen() {
  const progress = getFactionProgress(selectedFaction);
  campaignSummary.innerHTML = `
    <span class="campaign-chip"><strong>${progress.wins}</strong>victorias</span>
    <span class="campaign-chip"><strong>${formatMoney(progress.credits)}</strong>creditos</span>
    <span class="campaign-chip"><strong>${progress.research}</strong>investigacion</span>
  `;

  if (selectedMissionIndex > progress.unlockedMission) selectedMissionIndex = progress.unlockedMission;
  missionList.innerHTML = "";
  missions.forEach((mission, index) => {
    const button = document.createElement("button");
    button.type = "button";
    button.className = "mission-card";
    button.disabled = index > progress.unlockedMission;
    button.classList.toggle("is-selected", index === selectedMissionIndex);
    const best = progress.bestRounds[mission.id] ? `Mejor: ${progress.bestRounds[mission.id]} ronda(s)` : "Sin completar";
    button.innerHTML = `
      <strong>${mission.name}</strong>
      <span>${index > progress.unlockedMission ? "Bloqueada" : best} - ${formatMoney(mission.rewardCredits)} - ${mission.rewardResearch} investigacion</span>
    `;
    button.addEventListener("click", () => {
      if (button.disabled) return;
      selectedMissionIndex = index;
      renderStartScreen();
    });
    missionList.appendChild(button);
  });
  missionBrief.textContent = missions[selectedMissionIndex].briefing;
  renderCampaignMap(progress);
  renderUpgradeShop(progress);
  renderEditorGrid();
  renderBowBuilder();
}

function renderCampaignMap(progress) {
  campaignMap.innerHTML = "";
  missions.forEach((mission, index) => {
    const node = document.createElement("button");
    node.type = "button";
    node.className = "campaign-node";
    node.classList.toggle("is-unlocked", index <= progress.unlockedMission);
    node.classList.toggle("is-cleared", Boolean(progress.bestRounds[mission.id]));
    node.disabled = index > progress.unlockedMission;
    node.innerHTML = `<strong>${index + 1}. ${mission.name}</strong><br><span>${progress.bestRounds[mission.id] ? "Completada" : index <= progress.unlockedMission ? "Disponible" : "Bloqueada"}</span>`;
    node.addEventListener("click", () => {
      if (node.disabled) return;
      selectedMissionIndex = index;
      renderStartScreen();
    });
    campaignMap.appendChild(node);
  });
}

function renderUpgradeShop(progress) {
  upgradeList.innerHTML = "";
  upgrades.forEach((upgrade) => {
    const owned = progress.upgrades.includes(upgrade.id);
    const canBuy = progress.credits >= upgrade.cost && progress.research >= upgrade.research && !owned;
    const button = document.createElement("button");
    button.type = "button";
    button.className = "upgrade-card";
    button.classList.toggle("is-owned", owned);
    button.disabled = !canBuy;
    button.innerHTML = `
      <strong>${owned ? "Comprado: " : ""}${upgrade.name}</strong>
      <span>${upgrade.text}</span>
      <span>${formatMoney(upgrade.cost)} - ${upgrade.research} investigacion</span>
    `;
    button.addEventListener("click", () => buyUpgrade(upgrade.id));
    upgradeList.appendChild(button);
  });
}

function showStartScreen() {
  resultModal.classList.add("is-hidden");
  startScreen.classList.remove("is-hidden");
  renderStartScreen();
}

function loadEditorMap() {
  try {
    const saved = JSON.parse(localStorage.getItem("reFanTacticsEditorMap") || "null");
    return saved || { cover: [], hero: [], enemy: [] };
  } catch {
    return { cover: [], hero: [], enemy: [] };
  }
}

function saveEditorMap() {
  localStorage.setItem("reFanTacticsEditorMap", JSON.stringify(editorMap));
  localStorage.setItem("reFanTacticsUseEditorMap", "true");
  playSound("upgrade");
  renderStartScreen();
}

function renderEditorGrid() {
  editorGrid.innerHTML = "";
  for (let y = 0; y < HEIGHT; y += 1) {
    for (let x = 0; x < WIDTH; x += 1) {
      const key = `${x},${y}`;
      const cell = document.createElement("button");
      cell.type = "button";
      cell.className = "editor-cell";
      if (editorMap.cover.includes(key)) cell.classList.add("cover");
      if (editorMap.hero.includes(key)) cell.classList.add("hero");
      if (editorMap.enemy.includes(key)) cell.classList.add("enemy");
      cell.addEventListener("click", () => editCell(key));
      editorGrid.appendChild(cell);
    }
  }
}

function editCell(key) {
  ["cover", "hero", "enemy"].forEach((bucket) => {
    editorMap[bucket] = editorMap[bucket].filter((item) => item !== key);
  });
  if (editorTool !== "erase") editorMap[editorTool].push(key);
  playSound("ui");
  renderEditorGrid();
}

function unlockAudio() {
  if (!musicAudio) {
    musicAudio = new Audio(audioFiles.music);
    musicAudio.loop = true;
  }
  updateAudioControls();
  musicAudio.play().catch(() => {});
}

function playSound(type) {
  if (audioMuted || !audioFiles[type]) return;
  const sound = new Audio(audioFiles[type]);
  sound.volume = Math.min(1, audioVolume * 0.75);
  sound.play().catch(() => {});
}

function updateAudioControls() {
  if (musicAudio) {
    musicAudio.volume = audioMuted ? 0 : audioVolume * 0.38;
  }
  muteBtn.textContent = audioMuted ? "Mute" : "Audio";
  volumeSlider.value = String(Math.round(audioVolume * 100));
}

function pulseTurn() {
  gameStage.classList.remove("turn-pulse");
  window.requestAnimationFrame(() => {
    gameStage.classList.add("turn-pulse");
  });
}

function getSelectedUnit() {
  return state.units.find((unitData) => unitData.id === state.selectedId && unitData.hp > 0);
}

function unitAt(x, y) {
  return state.units.find((unitData) => unitData.x === x && unitData.y === y && unitData.hp > 0);
}

function distance(a, b) {
  return Math.abs(a.x - b.x) + Math.abs(a.y - b.y);
}

function nearestUnit(from, units) {
  return units.slice().sort((a, b) => distance(from, a) - distance(from, b))[0];
}

function inBounds(x, y) {
  return x >= 0 && y >= 0 && x < WIDTH && y < HEIGHT;
}

function addLog(message) {
  state.log.push(message);
}

document.querySelectorAll(".weapon-card").forEach((button) => {
  button.addEventListener("click", () => {
    unlockAudio();
    playSound("ui");
    state.selectedWeapon = button.dataset.weapon;
    document.querySelectorAll(".weapon-card").forEach((weaponButton) => {
      weaponButton.classList.toggle("is-selected", weaponButton === button);
    });
    render();
  });
});

actionButtons.move.addEventListener("click", () => {
  unlockAudio();
  playSound("ui");
  state.mode = "move";
  render();
});

actionButtons.attack.addEventListener("click", () => {
  unlockAudio();
  playSound("ui");
  state.mode = "attack";
  render();
});

actionButtons.special.addEventListener("click", () => {
  unlockAudio();
  playSound("ui");
  if (state.specialUsed) return;
  state.mode = "special";
  render();
});

actionButtons.wait.addEventListener("click", () => {
  const selected = getSelectedUnit();
  if (!selected || selected.acted) return;
  selected.acted = true;
  addLog(`${selected.name} mantiene la posicion.`);
  afterHeroAction();
});

actionButtons.end.addEventListener("click", startEnemyTurn);
document.querySelector("#restartBtn").addEventListener("click", () => newGame(state.factionId));
menuBtn.addEventListener("click", () => {
  unlockAudio();
  playSound("ui");
  showStartScreen();
});
nextMissionBtn.addEventListener("click", () => {
  unlockAudio();
  selectedMissionIndex = Math.min(state.missionIndex + 1, missions.length - 1);
  newGame(state.factionId);
});
resetProgressBtn.addEventListener("click", resetCampaignProgress);
continueBtn.addEventListener("click", () => {
  unlockAudio();
  playSound("ui");
  titleScreen.classList.add("is-hidden");
  showStartScreen();
});
tutorialBtn.addEventListener("click", () => {
  unlockAudio();
  playSound("ui");
  tutorialModal.classList.remove("is-hidden");
});
closeTutorialBtn.addEventListener("click", () => {
  playSound("ui");
  tutorialModal.classList.add("is-hidden");
});
muteBtn.addEventListener("click", () => {
  audioMuted = !audioMuted;
  localStorage.setItem("reFanTacticsMuted", String(audioMuted));
  updateAudioControls();
});
volumeSlider.addEventListener("input", () => {
  audioVolume = Number(volumeSlider.value) / 100;
  localStorage.setItem("reFanTacticsVolume", String(Math.round(audioVolume * 100)));
  updateAudioControls();
});
document.querySelectorAll(".tool-btn").forEach((button) => {
  button.addEventListener("click", () => {
    editorTool = button.dataset.tool;
    document.querySelectorAll(".tool-btn").forEach((toolButton) => {
      toolButton.classList.toggle("is-selected", toolButton === button);
    });
    playSound("ui");
  });
});
saveMapBtn.addEventListener("click", saveEditorMap);
loadMapBtn.addEventListener("click", () => {
  localStorage.setItem("reFanTacticsUseEditorMap", "true");
  playSound("ui");
  renderStartScreen();
});

document.querySelectorAll(".faction-card").forEach((button) => {
  button.addEventListener("click", () => {
    unlockAudio();
    playSound("ui");
    selectedFaction = button.dataset.faction;
    selectedMissionIndex = Math.min(selectedMissionIndex, getFactionProgress(selectedFaction).unlockedMission);
    addStartSelection(button);
    renderStartScreen();
  });
});

function addStartSelection(button) {
  document.querySelectorAll(".faction-card").forEach((card) => {
    card.classList.toggle("is-selected", card === button);
  });
}

startBtn.addEventListener("click", () => newGame(selectedFaction));

newGame("bsaa");
startScreen.classList.remove("is-hidden");
titleScreen.classList.remove("is-hidden");
updateAudioControls();
renderStartScreen();
