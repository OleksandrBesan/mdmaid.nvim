local config = require("mdmaid.config")
local server = require("mdmaid.server")
local preview = require("mdmaid.preview")

local M = {}

-- Re-export submodules
M.server = server
M.preview = preview
M.config = config

---Setup mdmaid.nvim
---@param opts? MdmaidConfig
function M.setup(opts)
  config.setup(opts)

  local cfg = config.get()

  -- Setup keymaps for markdown files
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    callback = function(ev)
      local buf = ev.buf

      if cfg.keymaps.preview then
        vim.keymap.set("n", cfg.keymaps.preview, function()
          preview.toggle()
        end, { buffer = buf, desc = "Toggle mdmaid preview" })
      end

      if cfg.keymaps.stop then
        vim.keymap.set("n", cfg.keymaps.stop, function()
          preview.stop()
        end, { buffer = buf, desc = "Stop mdmaid server" })
      end
    end,
  })

  -- Auto-start on markdown open
  if cfg.server.auto_start then
    vim.api.nvim_create_autocmd("BufEnter", {
      pattern = "*.md",
      callback = function(ev)
        -- Only auto-start if no server is running
        if not server.is_running() then
          local file = vim.api.nvim_buf_get_name(ev.buf)
          if file ~= "" then
            preview.start(file)
          end
        end
      end,
    })
  end

  -- Auto-stop on nvim exit
  if cfg.server.auto_stop then
    vim.api.nvim_create_autocmd("VimLeavePre", {
      callback = function()
        if server.is_running() then
          server.stop()
        end
      end,
    })
  end

  -- Create user commands
  vim.api.nvim_create_user_command("MdmaidPreview", function()
    preview.start()
  end, { desc = "Start mdmaid preview" })

  vim.api.nvim_create_user_command("MdmaidStop", function()
    preview.stop()
  end, { desc = "Stop mdmaid server" })

  vim.api.nvim_create_user_command("MdmaidRestart", function()
    server.restart()
  end, { desc = "Restart mdmaid server" })

  vim.api.nvim_create_user_command("MdmaidOpen", function()
    if server.is_running() then
      preview.open_browser()
    else
      vim.notify("Server not running. Use :MdmaidPreview first", vim.log.levels.WARN)
    end
  end, { desc = "Open browser to preview" })

  vim.api.nvim_create_user_command("MdmaidStatus", function()
    local status = preview.status()
    local lines = {
      "mdmaid status:",
      "  Server: " .. (status.server_running and "running" or "stopped"),
      "  URL: " .. status.url,
      "  File: " .. (status.file or "none"),
      "  Port: " .. status.port,
    }
    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
  end, { desc = "Show mdmaid status" })
end

return M
