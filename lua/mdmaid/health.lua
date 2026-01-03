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

  -- Check server status
  local server = require("mdmaid.server")
  if server.is_running() then
    vim.health.ok("Server running on port " .. server.port)
  else
    vim.health.info("Server not running")
  end
end

return M
