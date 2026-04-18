const { describe, it } = require('node:test')
const assert = require('node:assert/strict')
const { n, monthlyTotal, income, diff, reconciliation, sectionTotal, fmt, monthName } = require('../renderer/budget.js')

// ─── Helpers ──────────────────────────────────────────────────────────────────

function month(...fields) {
  return { fields }
}

function field(behavior, value) {
  return { behavior, value, key: behavior, label: behavior, section: 'test' }
}

// ─── n() ─────────────────────────────────────────────────────────────────────

describe('n()', () => {
  it('parses valid numbers', () => {
    assert.equal(n(100), 100)
    assert.equal(n('42.5'), 42.5)
  })

  it('returns 0 for falsy and non-numeric values', () => {
    assert.equal(n(undefined), 0)
    assert.equal(n(null), 0)
    assert.equal(n(''), 0)
    assert.equal(n('abc'), 0)
  })
})

// ─── monthlyTotal() ───────────────────────────────────────────────────────────

describe('monthlyTotal()', () => {
  it('counts shared fields at 50%', () => {
    assert.equal(monthlyTotal(month(field('shared', 200))), 100)
  })

  it('counts mine fields at 100%', () => {
    assert.equal(monthlyTotal(month(field('mine', 500))), 500)
  })

  it('counts partner-pays fields at 100% (accounted for reconciliation)', () => {
    assert.equal(monthlyTotal(month(field('partner-pays', 1000))), 1000)
  })

  it('counts joint-card fields at 100% (already the user\'s half)', () => {
    assert.equal(monthlyTotal(month(field('joint-card', 150))), 150)
  })

  it('counts partner-expense fields at 100%', () => {
    assert.equal(monthlyTotal(month(field('partner-expense', 350))), 350)
  })

  it('excludes income fields', () => {
    assert.equal(monthlyTotal(month(field('income', 5000))), 0)
  })

  it('returns 0 for empty fields', () => {
    assert.equal(monthlyTotal(month()), 0)
  })

  it('sums mixed behaviors correctly', () => {
    const m = month(
      field('shared', 800),    // 400
      field('mine', 200),      // 200
      field('partner-pays', 100), // 100
      field('income', 5000),   // 0
    )
    assert.equal(monthlyTotal(m), 700)
  })
})

// ─── income() ────────────────────────────────────────────────────────────────

describe('income()', () => {
  it('sums all income-behavior fields', () => {
    const m = month(field('income', 5000), field('income', 500))
    assert.equal(income(m), 5500)
  })

  it('ignores non-income fields', () => {
    const m = month(field('mine', 1000), field('shared', 500))
    assert.equal(income(m), 0)
  })

  it('returns 0 when no income fields', () => {
    assert.equal(income(month()), 0)
  })
})

// ─── diff() ──────────────────────────────────────────────────────────────────

describe('diff()', () => {
  it('returns income minus monthly total', () => {
    const m = month(field('income', 5000), field('mine', 2000))
    assert.equal(diff(m), 3000)
  })

  it('is negative when spending exceeds income', () => {
    const m = month(field('income', 1000), field('mine', 1500))
    assert.equal(diff(m), -500)
  })

  it('is zero when balanced', () => {
    const m = month(field('income', 1000), field('shared', 2000))
    assert.equal(diff(m), 0)
  })
})

// ─── reconciliation() ─────────────────────────────────────────────────────────

describe('reconciliation()', () => {
  it('shared: partner owes you 50%', () => {
    assert.equal(reconciliation(month(field('shared', 600))), 300)
  })

  it('joint-card: partner owes you the full entered amount (already your half)', () => {
    assert.equal(reconciliation(month(field('joint-card', 150))), 150)
  })

  it('partner-pays: you owe partner 50%', () => {
    assert.equal(reconciliation(month(field('partner-pays', 1000))), -500)
  })

  it('partner-expense: reduces partner\'s debt by the full amount', () => {
    assert.equal(reconciliation(month(field('partner-expense', 350))), -350)
  })

  it('mine: no reconciliation effect', () => {
    assert.equal(reconciliation(month(field('mine', 999))), 0)
  })

  it('income: no reconciliation effect', () => {
    assert.equal(reconciliation(month(field('income', 5000))), 0)
  })

  it('returns 0 for empty fields', () => {
    assert.equal(reconciliation(month()), 0)
  })

  it('positive result means partner owes you', () => {
    // shared(800) → partner owes 400; partner-pays(200) → you owe 100 → net +300
    const m = month(field('shared', 800), field('partner-pays', 200))
    assert.equal(reconciliation(m), 300)
  })

  it('negative result means you owe partner', () => {
    // partner-pays(2000) → you owe 1000; shared(400) → partner owes 200 → net -800
    const m = month(field('partner-pays', 2000), field('shared', 400))
    assert.equal(reconciliation(m), -800)
  })

  it('complex scenario: multiple behaviors combined', () => {
    // shared(800)       → partner owes 400
    // joint-card(150)   → partner owes 150
    // partner-pays(1000)   → you owe 500
    // partner-expense(350) → partner owes -350
    // mine(500)         → 0
    // income(5000)      → 0
    // net: 400 + 150 - 500 - 350 = -300
    const m = month(
      field('shared', 800),
      field('joint-card', 150),
      field('partner-pays', 1000),
      field('partner-expense', 350),
      field('mine', 500),
      field('income', 5000),
    )
    assert.equal(reconciliation(m), -300)
  })

  it('handles zero values', () => {
    const m = month(
      field('shared', 0),
      field('joint-card', 0),
      field('partner-pays', 0),
    )
    assert.equal(reconciliation(m), 0)
  })
})

// ─── sectionTotal() ──────────────────────────────────────────────────────────

describe('sectionTotal()', () => {
  it('sums all fields in the given section', () => {
    const m = {
      fields: [
        { behavior: 'mine', value: 100, section: 'housing' },
        { behavior: 'shared', value: 200, section: 'housing' },
        { behavior: 'mine', value: 50, section: 'lifestyle' },
      ]
    }
    assert.equal(sectionTotal(m, 'housing'), 300)
    assert.equal(sectionTotal(m, 'lifestyle'), 50)
  })

  it('returns 0 for unknown section', () => {
    const m = { fields: [{ behavior: 'mine', value: 100, section: 'housing' }] }
    assert.equal(sectionTotal(m, 'nonexistent'), 0)
  })
})

// ─── fmt() ───────────────────────────────────────────────────────────────────

describe('fmt()', () => {
  it('formats positive amounts in GBP', () => {
    assert.equal(fmt(1234), '£1,234')
  })

  it('formats zero', () => {
    assert.equal(fmt(0), '£0')
  })

  it('formats negative amounts', () => {
    assert.equal(fmt(-500), '-£500')
  })
})

// ─── monthName() ─────────────────────────────────────────────────────────────

describe('monthName()', () => {
  it('returns formatted month and year', () => {
    assert.equal(monthName({ year: 2026, month: 1 }), 'January 2026')
    assert.equal(monthName({ year: 2026, month: 12 }), 'December 2026')
  })
})
