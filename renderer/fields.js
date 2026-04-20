const SECTIONS = [
  { id: "joint-account", title: "Joint Account" },
  { id: "my-account", title: "My Account" },
  { id: "cards", title: "Credit Cards" },
  { id: "partner-account", title: "Partner Account" },
  { id: "savings", title: "Savings" },
  { id: "income", title: "Income" },
];

// All fields store the full total cost. For shared fields the app displays
// your 50% share alongside the input.
//
// behavior drives how each field contributes to monthly total, joint transfer, and reconciliation:
//   shared          — counts 50% in monthly total; transfer 100% to joint; partner owes you 50%
//   mine            — counts 100% in monthly total; no transfer; no reconciliation effect
//   partner-pays    — counts 100% in monthly total; no transfer; you owe partner 100%
//   partner-expense — counts 100% in monthly total; no transfer; reduces partner's debt by 100%
//   income          — excluded from monthly total; used only for diff calculation
