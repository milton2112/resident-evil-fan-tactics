const WIDTH = 12;
const HEIGHT = 9;

const weapons = {
  pistol: { name: "Pistola", damage: 3, range: 4 },
  shotgun: { name: "Escopeta", damage: 5, range: 2 },
  rifle: { name: "Rifle", damage: 4, range: 6 }
};

const coverTiles = new Set(["4,1", "7,1", "2,3", "5,4", "8,4", "9,6", "3,7"]);

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
  }
};

const enemyRoster = [
  ["e1", "Zombie", 10, 1, 7, 3],
  ["e2", "Zombie", 9, 3, 7, 3],
  ["e3", "Ganado", 10, 5, 8, 3],
  ["e4", "Perro infectado", 8, 7, 6, 4],
  ["e5", "Licker", 11, 7, 12, 3]
];

let state;

const battlefield = document.querySelector("#battlefield");
const roundLabel = document.querySelector("#roundLabel");
const turnLabel = document.querySelector("#turnLabel");
const missionLabel = document.querySelector("#missionLabel");
const squadTitle = document.querySelector("#squadTitle");
const selectedUnitStats = document.querySelector("#selectedUnitStats");
const unitPanel = document.querySelector("#unitPanel");
const logEl = document.querySelector("#log");
const resultModal = document.querySelector("#resultModal");
const resultTitle = document.querySelector("#resultTitle");
const resultText = document.querySelector("#resultText");
const startScreen = document.querySelector("#startScreen");
const startBtn = document.querySelector("#startBtn");

const actionButtons = {
  move: document.querySelector("#moveBtn"),
  attack: document.querySelector("#attackBtn"),
  special: document.querySelector("#specialBtn"),
  wait: document.querySelector("#waitBtn"),
  end: document.querySelector("#endTurnBtn")
};

let selectedFaction = "bsaa";

function newGame(factionId = selectedFaction) {
  selectedFaction = factions[factionId] ? factionId : "bsaa";
  const faction = factions[selectedFaction];

  state = {
    round: 1,
    side: "hero",
    mode: "move",
    selectedId: "h1",
    selectedWeapon: "pistol",
    factionId: selectedFaction,
    specialUsed: false,
    log: [],
    units: [
      ...faction.units.map(([id, name, x, y, hp, move]) => unit(id, name, "hero", x, y, hp, move)),
      ...enemyRoster.map(([id, name, x, y, hp, move]) => unit(id, name, "enemy", x, y, hp, move))
    ]
  };

  addLog(`${faction.name} desplegado. Objetivo: contener el brote.`);
  resultModal.classList.add("is-hidden");
  startScreen.classList.add("is-hidden");
  render();
}

function unit(id, name, side, x, y, hp, move) {
  return { id, name, side, x, y, hp, maxHp: hp, move, acted: false };
}

function render() {
  const faction = factions[state.factionId];
  roundLabel.textContent = `Ronda ${state.round}`;
  turnLabel.textContent = state.side === "hero" ? "Turno de heroes" : "Turno de infectados";
  missionLabel.textContent = faction.mission;
  squadTitle.textContent = `Escuadron ${faction.name}`;
  renderBoard();
  renderPanel();
  renderLog();
  updateButtons();
}

function renderBoard() {
  battlefield.innerHTML = "";
  const selected = getSelectedUnit();
  const highlights = selected ? getHighlights(selected) : new Set();

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
      if (coverTiles.has(key)) tile.classList.add("cover");
      if (highlights.has(key)) tile.classList.add(state.mode === "attack" || state.mode === "special" ? "attackable" : "reachable");
      if (selected && selected.x === x && selected.y === y) tile.classList.add("selected");

      const occupying = unitAt(x, y);
      if (coverTiles.has(key)) tile.appendChild(renderCoverProp());
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
  token.className = `unit ${unitData.side} ${unitData.name.length > 8 ? "unit-small-label" : ""}`;
  token.textContent = unitData.side === "hero" ? unitData.name[0] : "!";

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
  unitPanel.innerHTML = "";
  selectedUnitStats.innerHTML = selected
    ? `
      <strong>${selected.name}</strong>
      <span>${selected.acted ? "Ya actuo este turno" : "Lista para actuar"} · ${weapons[state.selectedWeapon].name}</span>
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
      <span>${weapons[state.selectedWeapon].name}</span>
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
  if (!getHighlights(selected).has(key) || unitAt(x, y) || coverTiles.has(key)) return;

  selected.x = x;
  selected.y = y;
  selected.acted = true;
  addLog(`${selected.name} avanza a posicion tactica.`);
  afterHeroAction();
}

function attackTarget(attacker, target) {
  if (!target || target.side !== "enemy") return;

  const weapon = weapons[state.selectedWeapon];
  if (distance(attacker, target) > weapon.range) return;

  target.hp -= weapon.damage;
  attacker.acted = true;
  addLog(`${attacker.name} usa ${weapon.name}: ${weapon.damage} dano.`);

  if (target.hp <= 0) {
    addLog(`${target.name} neutralizado.`);
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

  affected.forEach((enemy) => {
    enemy.hp -= faction.specialDamage;
  });

  state.specialUsed = true;
  attacker.acted = true;
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
  render();
  setTimeout(runEnemyTurn, 450);
}

function runEnemyTurn() {
  const enemies = state.units.filter((unitData) => unitData.side === "enemy" && unitData.hp > 0);

  enemies.forEach((enemy) => {
    const heroes = state.units.filter((unitData) => unitData.side === "hero" && unitData.hp > 0);
    if (heroes.length === 0) return;

    const target = nearestUnit(enemy, heroes);
    if (distance(enemy, target) <= 1) {
      target.hp -= 2;
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
    { x: unitData.x + Math.sign(target.x - unitData.x), y: unitData.y + Math.sign(target.y - unitData.y) }
  ];

  const next = candidates.find((tile) => {
    return inBounds(tile.x, tile.y) && !unitAt(tile.x, tile.y) && !coverTiles.has(`${tile.x},${tile.y}`);
  });

  if (next) {
    unitData.x = next.x;
    unitData.y = next.y;
  }
}

function checkWinLoss() {
  const heroesLeft = state.units.some((unitData) => unitData.side === "hero" && unitData.hp > 0);
  const enemiesLeft = state.units.some((unitData) => unitData.side === "enemy" && unitData.hp > 0);

  if (!enemiesLeft) {
    showResult("Zona despejada", "El escuadron contuvo el brote. Siguiente paso: agregar recompensas y nuevas misiones.");
    return true;
  }

  if (!heroesLeft) {
    showResult("Mision fallida", "La zona queda perdida. Reinicia y prueba otra combinacion de armas.");
    return true;
  }

  return false;
}

function showResult(title, text) {
  resultTitle.textContent = title;
  resultText.textContent = text;
  resultModal.classList.remove("is-hidden");
  render();
}

function getHighlights(selected) {
  const highlights = new Set();
  const faction = factions[state.factionId];
  const range = state.mode === "attack"
    ? weapons[state.selectedWeapon].range
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
    state.selectedWeapon = button.dataset.weapon;
    document.querySelectorAll(".weapon-card").forEach((weaponButton) => {
      weaponButton.classList.toggle("is-selected", weaponButton === button);
    });
    render();
  });
});

actionButtons.move.addEventListener("click", () => {
  state.mode = "move";
  render();
});

actionButtons.attack.addEventListener("click", () => {
  state.mode = "attack";
  render();
});

actionButtons.special.addEventListener("click", () => {
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

document.querySelectorAll(".faction-card").forEach((button) => {
  button.addEventListener("click", () => {
    if (!factions[button.dataset.faction]) {
      addStartSelection(button);
      return;
    }
    selectedFaction = button.dataset.faction;
    addStartSelection(button);
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
