# mdmaid.nvim

Markdown + Mermaid preview for Neovim.

Live preview of markdown files with first-class Mermaid diagram support, powered by [mdmaid](https://github.com/olesbesan/mdmaid).

## Features

- Live preview with auto-reload on save
- Mermaid diagram rendering
- **Multi-file support** - track and switch between multiple markdown files
- **File picker** - Telescope integration with fallback to vim.ui.select
- **Session management** - each Neovim instance gets its own server
- **Dynamic port allocation** - no port conflicts between sessions
- Table of Contents sidebar
- Image magnifier (hold `Z` to zoom)
- Custom fonts and themes
- Auto-start/stop server with orphan cleanup

## Requirements

- Neovim >= 0.9.0
- Node.js >= 18
- [mdmaid](https://github.com/olesbesan/mdmaid) CLI
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) (optional, for file picker)

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
  dependencies = {
    "nvim-telescope/telescope.nvim", -- optional
  },
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
  requires = {
    "nvim-telescope/telescope.nvim", -- optional
  },
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
    port = 3333,         -- Base port (actual port assigned dynamically)
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
    files = "<leader>mf",   -- Open file picker
    add = "<leader>ma",     -- Add current file to tracked files
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
| `:MdmaidFiles` | Open file picker to switch files |
| `:MdmaidAdd` | Add current file to tracked files |
| `:MdmaidRemove` | Remove current file from tracked files |
| `:MdmaidStatus` | Show server status and tracked files |

## Keymaps

Default keymaps (only active in markdown buffers):

| Keymap | Action |
|--------|--------|
| `<leader>mp` | Toggle preview |
| `<leader>ms` | Stop server |
| `<leader>mf` | Open file picker |
| `<leader>ma` | Add current file |

### File Picker

The file picker uses Telescope if available, otherwise falls back to `vim.ui.select`.

In Telescope picker:
- `<CR>` - Switch to selected file
- `<C-d>` - Remove file from tracked list

## Multi-Session Support

mdmaid.nvim supports running multiple Neovim instances, each with its own server:

- Each instance gets a dynamically allocated port (no conflicts)
- Sessions are persisted to `/tmp/mdmaid-sessions/`
- Orphaned servers (from crashed Neovim instances) are automatically cleaned up

## Health Check

Run `:checkhealth mdmaid` to verify your setup.

## How It Works

```
┌─────────────┐      spawn       ┌─────────────────┐
│   Neovim    │ ───────────────► │ mdmaid serve    │
│  (session)  │                  │ --watch         │
└─────────────┘                  └─────────────────┘
       │                                  │
       │  HTTP API                        │ websocket
       │  (add/switch files)              ▼
       │                         ┌─────────────────┐
       └────────────────────────►│ Browser preview │
                                 │ localhost:XXXX  │
                                 └─────────────────┘
```

1. When you open a markdown file, mdmaid.nvim spawns a `mdmaid serve` process
2. The server outputs its dynamically assigned port
3. All markdown files you open are tracked in the session
4. Use the file picker (`:MdmaidFiles` or `<leader>mf`) to switch between files
5. Browser connects via WebSocket for live updates
6. The web UI also has a file picker sidebar for switching files

## License

MIT
