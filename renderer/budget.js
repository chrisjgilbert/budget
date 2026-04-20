function n(v) {
  return parseFloat(v) || 0;
}

function monthContribution(field) {
  const v = n(field.value);
  if (field.behavior === "shared") return v * 0.5;
  if (field.behavior === "income") return 0;
  return v;
}

function reconciliationContribution(field) {
  const v = n(field.value);
  switch (field.behavior) {
    case "shared":
      return v * 0.5;
    case "partner-pays":
    case "partner-expense":
      return -v;
    default:
      return 0;
  }
}

function monthlyTotal(m) {
  return m.fields.reduce((sum, f) => sum + monthContribution(f), 0);
}

function income(m) {
  return m.fields
    .filter((f) => f.behavior === "income")
    .reduce((sum, f) => sum + n(f.value), 0);
}

function diff(m) {
  return income(m) - monthlyTotal(m);
}

function reconciliation(m) {
  return m.fields.reduce((sum, f) => sum + reconciliationContribution(f), 0);
}

function jointAccountTransfer(m) {
  return m.fields.reduce((sum, f) => {
    const v = n(f.value);
    if (f.behavior === "shared") return sum + v;
    return sum;
  }, 0);
}

function fmt(amount) {
  return new Intl.NumberFormat("en-GB", {
    style: "currency",
    currency: "GBP",
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount);
}

function monthName(m) {
  return new Date(m.year, m.month - 1, 1).toLocaleDateString("en-GB", {
    month: "long",
    year: "numeric",
  });
}

function sectionTotal(m, sectionId) {
  return m.fields
    .filter((f) => f.section === sectionId)
    .reduce((sum, f) => sum + n(f.value), 0);
}

if (typeof module !== "undefined") {
  module.exports = {
    n,
    monthlyTotal,
    income,
    diff,
    reconciliation,
    jointAccountTransfer,
    sectionTotal,
    fmt,
    monthName,
  };
}
