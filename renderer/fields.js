const SECTIONS = [
  { id: 'housing',       title: 'Housing & Utilities' },
  { id: 'subscriptions', title: 'Subscriptions & Services' },
  { id: 'savings',       title: 'Savings & Investments' },
  { id: 'cards',         title: 'Credit Cards' },
  { id: 'lifestyle',     title: 'Family & Lifestyle' },
  { id: 'income',        title: 'Income' },
]

// All fields store the full total cost. For shared fields the app displays
// your 50% share alongside the input.
//
// behavior drives how each field contributes to monthly total and reconciliation:
//   shared          — total entered; counts 50% in monthly total; partner owes you 50%
//   mine            — total entered; counts 100% in monthly total; no reconciliation effect
//   partner-pays    — total entered; counts 100% in monthly total; you owe partner 50%
//   partner-expense — total entered; counts 100% in monthly total; reduces partner's reconciliation debt by 100%
//   income          — excluded from monthly total; used only for diff calculation
