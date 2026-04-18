const SECTIONS = [
  { id: 'housing',       title: 'Housing & Utilities' },
  { id: 'subscriptions', title: 'Subscriptions & Services' },
  { id: 'savings',       title: 'Savings & Investments' },
  { id: 'cards',         title: 'Credit Cards' },
  { id: 'lifestyle',     title: 'Family & Lifestyle' },
  { id: 'income',        title: 'Income' },
]

// behavior drives how each field contributes to monthly total and reconciliation:
//   shared          — you fund 100%, counts 50% in total; partner owes you 50%
//   mine            — you pay 100%, counts 100% in total; no reconciliation effect
//   partner-pays    — partner pays, counts 100% in total (account for it); you owe partner 50%
//   joint-card      — you enter your 50% share; counts 100% in total; partner owes you the full entered amount
//   partner-expense — you pay, counts 100% in total; reduces partner's reconciliation debt by 100%
//   income       — excluded from monthly total; used only for diff calculation
