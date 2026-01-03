local M = {}

function M.check()
  vim.health.start("mdmaid.nvim")

  -- Check for mdmaid CLI
  local config = require("mdmaid.config")
  local opts = config.get()
  local mdmaid_path = opts.mdmaid_path or "mdmaid"

  local handle = io.popen(mdmaid_path .. " --version 2>&1")
  if handle then
    local result = handle:read("*a")
    handle:close()

    if result and result:match("mdmaid v") then
      vim.health.ok("mdmaid CLI found: " .. result:gsub("%s+$", ""))
    else
      vim.health.error("mdmaid CLI not found or not working", {
        "Install mdmaid: npm install -g mdmaid",
        "Or set mdmaid_path in config",
      })
    end
  else
    vim.health.error("Could not check mdmaid CLI", {
      "Install mdmaid: npm install -g mdmaid",
    })
  end

  -- Check for Node.js
  local node_handle = io.popen("node --version 2>&1")
  if node_handle then
    local node_result = node_handle:read("*a")
    node_handle:close()

    if node_result and node_result:match("^v%d+") then
      vim.health.ok("Node.js found: " .. node_result:gsub("%s+$", ""))
    else
      vim.health.warn("Node.js not found", {
        "Node.js is required to run mdmaid",
      })
    end
  end

  -- Check for Telescope (optional)
  local has_telescope = pcall(require, "telescope")
  if has_telescope then
    vim.health.ok("Telescope found (file picker will use Telescope)")
  else
    vim.health.info("Telescope not found (file picker will use vim.ui.select)")
  end

  -- Check server status
  local server = require("mdmaid.server")
  if server.is_running() then
    vim.health.ok("Server running on port " .. server.port)
  else
    vim.health.info("Server not running")
  end

  -- Check session info
  local session = require("mdmaid.session")
  if session.current then
    local files = session.get_files()
    vim.health.ok("Session active with " .. #files .. " tracked file(s)")
    if session.current.current_file then
      vim.health.info("Current file: " .. vim.fn.fnamemodify(session.current.current_file, ":t"))
    end
  else
    vim.health.info("No active session")
  end

  -- Check session directory
  local session_dir = "/tmp/mdmaid-sessions"
  if vim.fn.isdirectory(session_dir) == 1 then
    local sessions = vim.fn.glob(session_dir .. "/*.json", false, true)
    vim.health.info(#sessions .. " session file(s) in " .. session_dir)
  end
end

return M
