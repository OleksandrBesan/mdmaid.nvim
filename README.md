# mdmaid.nvim

Markdown + Mermaid preview for Neovim.

Live preview of markdown files with first-class Mermaid diagram support, powered by [mdmaid](https://github.com/olesbesan/mdmaid).

## Features

- Live preview with auto-reload on save
- Mermaid diagram rendering
- Table of Contents sidebar
- Image magnifier (hold `Z` to zoom)
- Custom fonts and themes
- Auto-start/stop server

## Requirements

- Neovim >= 0.9.0
- Node.js >= 18
- [mdmaid](https://github.com/olesbesan/mdmaid) CLI

## Installation

### Install mdmaid CLI first

```bash
npm install -g mdmaid
```

### lazy.nvim

```lua
{
  "olesbesan/mdmaid.nvim",
  ft = "markdown",
  config = function()
    require("mdmaid").setup()
  end,
}
```

### packer.nvim

```lua
use {
  "olesbesan/mdmaid.nvim",
  ft = "markdown",
  config = function()
    require("mdmaid").setup()
  end,
}
```

## Configuration

```lua
require("mdmaid").setup({
  -- Server options
  server = {
    port = 3333,
    host = "localhost",
    auto_start = true,   -- Start server when opening .md files
    auto_stop = true,    -- Stop server when exiting Neovim
  },

  -- Preview options
  preview = {
    open_browser = true, -- Auto-open browser
    browser = nil,       -- nil = system default, or "firefox", "google-chrome", etc.
  },

  -- Rendering options (passed to mdmaid)
  render = {
    fonts = {
      -- Custom fonts for diagrams
      -- { family = "Departure Mono", path = "~/fonts/DepartureMono.woff2" },
    },
    mermaid = {
      theme = "default", -- "default", "dark", "forest", "neutral"
      -- themeVariables = { primaryColor = "#0366d6" },
    },
    custom_css = nil,    -- Custom CSS string to inject
  },

  -- Keymaps (set to false to disable)
  keymaps = {
    preview = "<leader>mp", -- Toggle preview
    stop = "<leader>ms",    -- Stop server
  },

  -- Path to mdmaid CLI (if not in PATH)
  mdmaid_path = "mdmaid",
})
```

## Commands

| Command | Description |
|---------|-------------|
| `:MdmaidPreview` | Start server and open browser |
| `:MdmaidStop` | Stop the server |
| `:MdmaidRestart` | Restart the server |
| `:MdmaidOpen` | Open browser (if server running) |
| `:MdmaidStatus` | Show server status |

## Keymaps

Default keymaps (only active in markdown buffers):

| Keymap | Action |
|--------|--------|
| `<leader>mp` | Toggle preview |
| `<leader>ms` | Stop server |

## Health Check

Run `:checkhealth mdmaid` to verify your setup.

## How It Works

```
┌─────────────┐      spawn       ┌─────────────────┐
│   Neovim    │ ───────────────► │ mdmaid serve    │
│             │                  │ file.md --watch │
└─────────────┘                  └─────────────────┘
       │                                  │
       │  file changes                    │ websocket
       │  trigger reload                  ▼
       │                         ┌─────────────────┐
       └────────────────────────►│ Browser preview │
                                 │ localhost:3333  │
                                 └─────────────────┘
```

1. When you open a markdown file, mdmaid.nvim spawns a `mdmaid serve` process
2. The server watches the file for changes
3. Browser connects via WebSocket for live updates
4. Saving the file triggers automatic browser refresh

## License

MIT
