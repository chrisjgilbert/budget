# Budget

A personal budget tracking desktop app built with Electron.

## Requirements

- [Node.js](https://nodejs.org) (v18 or later)
- macOS (tested), Windows and Linux should work

## Installation

```bash
git clone https://github.com/chrisjgilbert/budget.git
cd budget
npm install
```

## Running

```bash
npm start
```

## Data storage

All budget data is stored locally on your machine — nothing is written to this repository. The data file location depends on your OS:

- **macOS**: `~/Library/Application Support/budget/config.json`
- **Windows**: `%APPDATA%\budget\config.json`
- **Linux**: `~/.config/budget/config.json`
