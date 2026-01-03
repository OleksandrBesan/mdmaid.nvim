local config = require("mdmaid.config")
local server = require("mdmaid.server")

local M = {}

---@type boolean
M.browser_opened = false

---Get the command to open a URL in the browser
---@param url string
---@return string[]
local function get_open_command(url)
  local opts = config.get()

  -- User specified browser
  if opts.preview.browser then
    return { opts.preview.browser, url }
  end

  -- System default
  local sysname = vim.loop.os_uname().sysname
  if sysname == "Darwin" then
    return { "open", url }
  elseif sysname == "Linux" then
    return { "xdg-open", url }
  elseif sysname == "Windows_NT" then
    return { "cmd", "/c", "start", url }
  end

  return { "open", url }
end

---Open browser to the preview URL
---@param url? string
function M.open_browser(url)
  url = url or server.get_url()
  local cmd = get_open_command(url)

  vim.fn.jobstart(cmd, {
    detach = true,
    on_exit = function(_, code, _)
      if code ~= 0 then
        vim.schedule(function()
          vim.notify("Failed to open browser", vim.log.levels.WARN)
        end)
      end
    end,
  })

  M.browser_opened = true
end

---Start preview (server + browser)
---@param file? string
function M.start(file)
  local opts = config.get()

  -- Start server if not running
  if not server.is_running() then
    local ok = server.start(file)
    if not ok then
      return
    end

    -- Wait a bit for server to start, then open browser
    if opts.preview.open_browser then
      vim.defer_fn(function()
        M.open_browser()
      end, 500)
    end
  else
    -- Server already running, just open browser
    if opts.preview.open_browser then
      M.open_browser()
    end
  end
end

---Stop preview
function M.stop()
  server.stop()
  M.browser_opened = false
end

---Toggle preview
---@param file? string
function M.toggle(file)
  if server.is_running() then
    M.stop()
  else
    M.start(file)
  end
end

---Get preview status
---@return table
function M.status()
  return {
    server_running = server.is_running(),
    browser_opened = M.browser_opened,
    url = server.get_url(),
    file = server.current_file,
    port = server.port,
  }
end

return M
