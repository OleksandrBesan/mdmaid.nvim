---@class MdmaidFontConfig
---@field family string Font family name
---@field path? string Local path to font file
---@field url? string External URL (Google Fonts, CDN)
---@field weight? number Font weight (default: 400)
---@field style? string Font style (default: "normal")

---@class MdmaidMermaidConfig
---@field theme? "default"|"dark"|"forest"|"neutral"|"base"
---@field themeVariables? table<string, string>

---@class MdmaidServerConfig
---@field port? number Server port (default: 3333)
---@field host? string Server host (default: "localhost")
---@field auto_start? boolean Start server on markdown open (default: true)
---@field auto_stop? boolean Stop server on nvim exit (default: true)

---@class MdmaidPreviewConfig
---@field open_browser? boolean Auto-open browser (default: true)
---@field browser? string Browser command (nil = system default)

---@class MdmaidRenderConfig
---@field fonts? MdmaidFontConfig[]
---@field mermaid? MdmaidMermaidConfig
---@field custom_css? string Custom CSS to inject

---@class MdmaidKeymapsConfig
---@field preview? string Toggle preview keymap (default: "<leader>mp")
---@field stop? string Stop server keymap (default: "<leader>ms")
---@field files? string File picker keymap (default: "<leader>mf")
---@field add? string Add file keymap (default: "<leader>ma")

---@class MdmaidConfig
---@field server? MdmaidServerConfig
---@field preview? MdmaidPreviewConfig
---@field render? MdmaidRenderConfig
---@field keymaps? MdmaidKeymapsConfig
---@field mdmaid_path? string Path to mdmaid CLI (default: "mdmaid")

local M = {}

---@type MdmaidConfig
M.defaults = {
  server = {
    port = 3333,
    host = "localhost",
    auto_start = true,
    auto_stop = true,
  },
  preview = {
    open_browser = true,
    browser = nil, -- system default
  },
  render = {
    fonts = {},
    mermaid = {
      theme = "default",
    },
    custom_css = nil,
  },
  keymaps = {
    preview = "<leader>mp",
    stop = "<leader>ms",
    files = "<leader>mf",
    add = "<leader>ma",
  },
  mdmaid_path = "mdmaid",
}

---@type MdmaidConfig
M.options = {}

---@param opts? MdmaidConfig
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, opts or {})
end

---@return MdmaidConfig
function M.get()
  return M.options
end

return M
