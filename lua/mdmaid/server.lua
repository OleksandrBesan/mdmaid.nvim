local config = require("mdmaid.config")

local M = {}

---@type number|nil
M.job_id = nil

---@type string|nil
M.current_file = nil

---@type number
M.port = 3333

---Check if server is running
---@return boolean
function M.is_running()
  return M.job_id ~= nil
end

---Get the server URL
---@return string
function M.get_url()
  local opts = config.get()
  return string.format("http://%s:%d", opts.server.host, M.port)
end

---Build the mdmaid command
---@param file string
---@return string[]
local function build_command(file)
  local opts = config.get()
  local cmd = {
    opts.mdmaid_path,
    "serve",
    file,
    "--port",
    tostring(opts.server.port),
    "--watch",
  }
  return cmd
end

---Start the mdmaid server
---@param file? string Markdown file to serve (default: current buffer)
---@return boolean success
function M.start(file)
  if M.is_running() then
    vim.notify("mdmaid server already running", vim.log.levels.WARN)
    return false
  end

  file = file or vim.api.nvim_buf_get_name(0)
  if file == "" then
    vim.notify("No file to serve", vim.log.levels.ERROR)
    return false
  end

  -- Check if file is markdown
  if not file:match("%.md$") then
    vim.notify("Not a markdown file", vim.log.levels.ERROR)
    return false
  end

  local opts = config.get()
  M.port = opts.server.port
  M.current_file = file

  local cmd = build_command(file)

  M.job_id = vim.fn.jobstart(cmd, {
    on_stdout = function(_, data, _)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            vim.schedule(function()
              -- Only show important messages
              if line:match("URL:") or line:match("Error") then
                vim.notify(line, vim.log.levels.INFO)
              end
            end)
          end
        end
      end
    end,
    on_stderr = function(_, data, _)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" and not line:match("^%s*$") then
            vim.schedule(function()
              vim.notify("mdmaid: " .. line, vim.log.levels.WARN)
            end)
          end
        end
      end
    end,
    on_exit = function(_, code, _)
      vim.schedule(function()
        M.job_id = nil
        M.current_file = nil
        if code ~= 0 and code ~= 143 then -- 143 = SIGTERM
          vim.notify("mdmaid server exited with code " .. code, vim.log.levels.WARN)
        end
      end)
    end,
  })

  if M.job_id <= 0 then
    vim.notify("Failed to start mdmaid server", vim.log.levels.ERROR)
    M.job_id = nil
    return false
  end

  vim.notify(string.format("mdmaid server started on port %d", M.port), vim.log.levels.INFO)
  return true
end

---Stop the mdmaid server
function M.stop()
  if not M.is_running() then
    return
  end

  vim.fn.jobstop(M.job_id)
  M.job_id = nil
  M.current_file = nil
  vim.notify("mdmaid server stopped", vim.log.levels.INFO)
end

---Restart the server with the same file
function M.restart()
  local file = M.current_file
  M.stop()
  -- Small delay to ensure port is released
  vim.defer_fn(function()
    if file then
      M.start(file)
    else
      M.start()
    end
  end, 100)
end

---Switch to a different file
---@param file string
function M.switch_file(file)
  if M.is_running() then
    M.stop()
  end
  M.start(file)
end

return M
