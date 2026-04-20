let months = [];
let activeId = null;
let saveTimer = null;

// ─── Init ─────────────────────────────────────────────────────────────────────

async function init() {
  document.addEventListener("input", handleInput);
  document.getElementById("add-month-btn").addEventListener("click", addMonth);
  document.getElementById("empty-add-btn").addEventListener("click", addMonth);
  document
    .getElementById("form-sections")
    .addEventListener("click", handleSectionClick);

  months = ((await window.store.get("months")) || []).map(migrateMonth);
  renderSidebar();
  if (months.length > 0) selectMonth(months[months.length - 1].id);
}

// ─── Migration (old flat format → fields array) ───────────────────────────────

function migrateMonth(m) {
  if (Array.isArray(m.fields)) return m;
  return { id: m.id, year: m.year, month: m.month, fields: [] };
}

// ─── Key generation ───────────────────────────────────────────────────────────

function toKey(label, existingKeys) {
  const base = label
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, "")
    .replace(/\s+(.)/g, (_, c) => c.toUpperCase());
  let candidate = base;
  let i = 2;
  while (existingKeys.has(candidate)) candidate = base + i++;
  return candidate;
}

// ─── Form builder (rebuilt on each month selection) ───────────────────────────

function buildForm(m) {
  const container = document.getElementById("form-sections");
  container.innerHTML = "";

  SECTIONS.forEach((section) => {
    const sectionFields = m.fields.filter((f) => f.section === section.id);

    const el = document.createElement("div");
    el.className = "section open";
    el.id = `section-${section.id}`;

    el.innerHTML = `
      <div class="section-header">
        <span class="section-title">${section.title}</span>
        <span class="section-subtotal" id="subtotal-${section.id}"></span>
        <button class="add-field-btn" data-section="${section.id}" title="Add field">+</button>
        <span class="section-chevron">&#9654;</span>
      </div>
      <div class="section-body">
        ${sectionFields.map((f) => fieldRowHtml(f)).join("")}
        <div class="add-field-form hidden" id="add-form-${section.id}">
          <input type="text" class="add-field-label" placeholder="Field name">
          <select class="add-field-behavior">
            <option value="mine">My cost</option>
            <option value="shared">Shared 50/50 (enter total)</option>
            <option value="partner-pays">Owe partner</option>
            <option value="income">Income</option>
          </select>
          <label class="reset-label">
            <input type="checkbox" class="add-field-reset"> Reset monthly
          </label>
          <button class="add-field-submit">Add</button>
          <button class="add-field-cancel">Cancel</button>
        </div>
      </div>
    `;

    el.querySelector(".section-header").addEventListener("click", (e) => {
      if (!e.target.closest(".add-field-btn")) el.classList.toggle("open");
    });

    el.querySelector(".add-field-btn").addEventListener("click", (e) => {
      e.stopPropagation();
      const form = document.getElementById(`add-form-${section.id}`);
      form.classList.toggle("hidden");
      if (!form.classList.contains("hidden")) {
        el.classList.add("open");
        form.querySelector(".add-field-label").focus();
      }
    });

    el.querySelector(".add-field-submit").addEventListener("click", () => {
      submitAddField(section.id, el);
    });

    el.querySelector(".add-field-label").addEventListener("keydown", (e) => {
      if (e.key === "Enter") submitAddField(section.id, el);
    });

    el.querySelector(".add-field-cancel").addEventListener("click", () => {
      resetAddForm(section.id, el);
    });

    container.appendChild(el);
  });
}

function fieldRowHtml(f) {
  const note = f.note ? `<span class="field-note">${f.note}</span>` : "";
  const val = f.value && f.value !== 0 ? ` value="${f.value}"` : "";
  const isShared = f.behavior === "shared";
  const shareVal = isShared && f.value ? fmt(n(f.value) * 0.5) : "";
  const shareHtml = isShared
    ? `<span class="share-amount" id="share-${f.key}">${shareVal}</span>`
    : "";
  const resetChecked = f.resetOnNew ? " checked" : "";
  return `
    <div class="field-row" data-key="${f.key}">
      <label>${f.label}${note}</label>
      <div class="input-wrap">
        <span class="prefix">£</span>
        <input type="number" min="0" step="0.01" data-field="${f.key}" placeholder="0"${val}>
      </div>
      ${shareHtml}
      <button class="edit-field-btn" data-key="${f.key}" title="Edit field">✎</button>
      <button class="delete-field-btn" data-key="${f.key}" title="Remove field">&times;</button>
    </div>
    <div class="edit-field-form hidden" id="edit-form-${f.key}">
      <input type="text" class="edit-field-label" value="${f.label}">
      <select class="edit-field-behavior">
        <option value="mine"${f.behavior === "mine" ? " selected" : ""}>My cost</option>
        <option value="shared"${f.behavior === "shared" ? " selected" : ""}>Shared 50/50 (enter total)</option>
        <option value="partner-pays"${f.behavior === "partner-pays" ? " selected" : ""}>Owe partner</option>
        <option value="income"${f.behavior === "income" ? " selected" : ""}>Income</option>
      </select>
      <label class="reset-label">
        <input type="checkbox" class="edit-field-reset"${resetChecked}> Reset monthly
      </label>
      <button class="edit-field-save" data-key="${f.key}">Save</button>
      <button class="edit-field-cancel" data-key="${f.key}">Cancel</button>
    </div>
  `;
}

function submitAddField(sectionId, sectionEl) {
  const label = sectionEl.querySelector(".add-field-label").value.trim();
  if (!label) return;
  const behavior = sectionEl.querySelector(".add-field-behavior").value;
  const resetOnNew =
    sectionEl.querySelector(".add-field-reset").checked || undefined;

  const m = months.find((m) => m.id === activeId);
  const key = toKey(label, new Set(m.fields.map((f) => f.key)));
  m.fields.push({
    key,
    label,
    section: sectionId,
    behavior,
    resetOnNew,
    value: 0,
  });

  saveAll();
  buildForm(m);
  updateSummary(m);
}

function resetAddForm(sectionId, sectionEl) {
  document.getElementById(`add-form-${sectionId}`).classList.add("hidden");
  sectionEl.querySelector(".add-field-label").value = "";
  sectionEl.querySelector(".add-field-reset").checked = false;
}

// ─── Event delegation for delete buttons ──────────────────────────────────────

function handleSectionClick(e) {
  if (!activeId) return;
  const m = months.find((m) => m.id === activeId);

  const deleteBtn = e.target.closest(".delete-field-btn");
  if (deleteBtn) {
    m.fields = m.fields.filter((f) => f.key !== deleteBtn.dataset.key);
    saveAll();
    buildForm(m);
    updateSummary(m);
    return;
  }

  const editBtn = e.target.closest(".edit-field-btn");
  if (editBtn) {
    const form = document.getElementById(`edit-form-${editBtn.dataset.key}`);
    form.classList.toggle("hidden");
    return;
  }

  const saveBtn = e.target.closest(".edit-field-save");
  if (saveBtn) {
    const key = saveBtn.dataset.key;
    const form = document.getElementById(`edit-form-${key}`);
    const field = m.fields.find((f) => f.key === key);
    if (field) {
      field.label = form.querySelector(".edit-field-label").value.trim() || field.label;
      field.behavior = form.querySelector(".edit-field-behavior").value;
      field.resetOnNew = form.querySelector(".edit-field-reset").checked || undefined;
    }
    saveAll();
    buildForm(m);
    updateSummary(m);
    return;
  }

  const cancelBtn = e.target.closest(".edit-field-cancel");
  if (cancelBtn) {
    const form = document.getElementById(`edit-form-${cancelBtn.dataset.key}`);
    form.classList.add("hidden");
    return;
  }
}

// ─── Sidebar ──────────────────────────────────────────────────────────────────

function renderSidebar() {
  const list = document.getElementById("month-list");
  list.innerHTML = "";
  months.forEach((m) => {
    const li = document.createElement("li");
    li.dataset.id = m.id;
    if (m.id === activeId) li.classList.add("active");

    const d = diff(m);
    const badgeClass = d > 0 ? "pos" : d < 0 ? "neg" : "zero";
    const sign = d > 0 ? "+" : "";

    li.innerHTML = `
      <span class="month-name">${monthName(m)}</span>
      <span class="diff-badge ${badgeClass}">${sign}${fmt(d)}</span>
    `;
    li.addEventListener("click", () => selectMonth(m.id));
    list.appendChild(li);
  });
}

// ─── Select a month ───────────────────────────────────────────────────────────

function selectMonth(id) {
  activeId = id;
  const m = months.find((m) => m.id === id);
  document.getElementById("empty-state").classList.add("hidden");
  document.getElementById("month-detail").classList.remove("hidden");
  buildForm(m);
  updateSummary(m);
  renderSidebar();
}

// ─── Summary card ─────────────────────────────────────────────────────────────

function updateSummary(m) {
  const transfer = jointAccountTransfer(m);
  const settlement = reconciliation(m);
  const balance = diff(m);

  document.getElementById("s-transfer").textContent = fmt(transfer);

  const settlementEl = document.getElementById("s-settlement");
  if (settlement === 0) {
    settlementEl.textContent = "All square";
    settlementEl.className = "summary-val";
  } else if (settlement > 0) {
    settlementEl.textContent = `Partner owes ${fmt(settlement)}`;
    settlementEl.className = "summary-val pos";
  } else {
    settlementEl.textContent = `You owe ${fmt(Math.abs(settlement))}`;
    settlementEl.className = "summary-val neg";
  }

  const balanceEl = document.getElementById("s-balance");
  balanceEl.textContent = (balance >= 0 ? "+" : "") + fmt(balance);
  balanceEl.className = "summary-val " + (balance > 0 ? "pos" : balance < 0 ? "neg" : "");

  document.getElementById("s-total").textContent = fmt(monthlyTotal(m));
  document.getElementById("s-income").textContent = fmt(income(m));

  SECTIONS.forEach((section) => {
    const el = document.getElementById(`subtotal-${section.id}`);
    if (el) {
      const raw = sectionTotal(m, section.id);
      el.textContent = raw > 0 ? fmt(raw) : "";
    }
  });
}

// ─── Input handling ───────────────────────────────────────────────────────────

function handleInput(e) {
  const fieldKey = e.target.dataset.field;
  if (!fieldKey || !activeId) return;

  const m = months.find((m) => m.id === activeId);
  const field = m.fields.find((f) => f.key === fieldKey);
  if (!field) return;
  field.value = parseFloat(e.target.value) || 0;

  if (field.behavior === "shared") {
    const shareEl = document.getElementById(`share-${fieldKey}`);
    if (shareEl)
      shareEl.textContent = field.value ? fmt(field.value * 0.5) : "";
  }

  updateSummary(m);

  clearTimeout(saveTimer);
  saveTimer = setTimeout(saveAll, 300);
}

async function saveAll() {
  await window.store.set("months", months);
  renderSidebar();
}

// ─── Add month ────────────────────────────────────────────────────────────────

function addMonth() {
  const latest = months[months.length - 1];
  let year, month;

  if (latest) {
    month = latest.month === 12 ? 1 : latest.month + 1;
    year = latest.month === 12 ? latest.year + 1 : latest.year;
  } else {
    const now = new Date();
    year = now.getFullYear();
    month = now.getMonth() + 1;
  }

  const id = `${year}-${String(month).padStart(2, "0")}`;
  if (months.find((m) => m.id === id)) return;

  const fields = latest
    ? latest.fields.map((f) => ({
        ...f,
        value: f.resetOnNew ? 0 : f.value || 0,
      }))
    : [];

  months.push({ id, year, month, fields });
  saveAll();
  selectMonth(id);
}

init();
