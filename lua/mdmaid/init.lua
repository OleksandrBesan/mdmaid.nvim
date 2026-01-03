local config = require("mdmaid.config")
local server = require("mdmaid.server")
local preview = require("mdmaid.preview")
local session = require("mdmaid.session")
local picker = require("mdmaid.picker")

local M = {}

-- Re-export submodules
M.server = server
M.preview = preview
M.config = config
M.session = session
M.picker = picker

---Setup mdmaid.nvim
---@param opts? MdmaidConfig
function M.setup(opts)
  config.setup(opts)

  local cfg = config.get()

  -- Clean up orphaned sessions on startup
  session.cleanup_orphans()

  -- Initialize session for this nvim instance
  session.get_or_create()

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

      if cfg.keymaps.files then
        vim.keymap.set("n", cfg.keymaps.files, function()
          picker.pick_file()
        end, { buffer = buf, desc = "Pick mdmaid file" })
      end

      if cfg.keymaps.add then
        vim.keymap.set("n", cfg.keymaps.add, function()
          picker.add_current()
        end, { buffer = buf, desc = "Add current file to mdmaid" })
      end
    end,
  })

  -- Track opened markdown files
  vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "*.md",
    callback = function(ev)
      local file = vim.api.nvim_buf_get_name(ev.buf)
      if file ~= "" then
        -- Add file to session tracking (but don't start server)
        session.add_file(file)

        -- If server is running, add to server too
        if server.is_running() then
          server.add_file(file)
        end

        -- Auto-start if configured and no server running
        if cfg.server.auto_start and not server.is_running() then
          preview.start(file)
        end
      end
    end,
  })

  -- Auto-stop on nvim exit
  if cfg.server.auto_stop then
    vim.api.nvim_create_autocmd("VimLeavePre", {
      callback = function()
        if server.is_running() then
          server.stop()
        end
        session.delete()
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

  vim.api.nvim_create_user_command("MdmaidFiles", function()
    picker.pick_file()
  end, { desc = "Pick file to preview" })

  vim.api.nvim_create_user_command("MdmaidAdd", function()
    picker.add_current()
  end, { desc = "Add current file to tracked files" })

  vim.api.nvim_create_user_command("MdmaidRemove", function()
    picker.remove_current()
  end, { desc = "Remove current file from tracked files" })

  vim.api.nvim_create_user_command("MdmaidStatus", function()
    local status = preview.status()
    local files = status.files or {}

    local lines = {
      "mdmaid status:",
      "  Server: " .. (status.server_running and "running" or "stopped"),
      "  Port: " .. (status.port or "none"),
      "  URL: " .. (status.port and status.url or "none"),
      "  Current: " .. (status.file and vim.fn.fnamemodify(status.file, ":t") or "none"),
      "  Files: " .. #files .. " tracked",
    }

    if #files > 0 then
      for _, f in ipairs(files) do
        local marker = f == status.file and " ●" or "  "
        table.insert(lines, "   " .. marker .. " " .. vim.fn.fnamemodify(f, ":t"))
      end
    end

    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
  end, { desc = "Show mdmaid status" })
end

return M
