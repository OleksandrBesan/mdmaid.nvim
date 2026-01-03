local config = require("mdmaid.config")
local session = require("mdmaid.session")

local M = {}

---@type number|nil
M.job_id = nil

---@type number|nil
M.port = nil

---@type number|nil
M.pid = nil

---Check if server is running
---@return boolean
function M.is_running()
  return M.job_id ~= nil and M.port ~= nil
end

---Get the server URL
---@return string
function M.get_url()
  local opts = config.get()
  return string.format("http://%s:%d", opts.server.host, M.port or 0)
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
    "--watch",
  }
  -- Don't specify port - let server pick dynamically
  return cmd
end

---Parse port from server output
---@param line string
---@return number|nil
local function parse_port(line)
  local port = line:match("^PORT:(%d+)")
  if port then
    return tonumber(port)
  end
  return nil
end

---Send command to server via HTTP API
---@param action string
---@param file string|nil
local function send_api_command(action, file)
  if not M.port then
    return
  end

  local url = string.format("http://localhost:%d/api/%s", M.port, action)

  if action == "add" and file then
    -- Use curl for POST
    vim.fn.jobstart({
      "curl",
      "-s",
      "-X",
      "POST",
      "-H",
      "Content-Type: application/json",
      "-d",
      vim.json.encode({ file = file }),
      url,
    }, { detach = true })
  end
end

---Start the mdmaid server
---@param file? string Markdown file to serve (default: current buffer)
---@return boolean success
function M.start(file)
  if M.is_running() then
    vim.notify("mdmaid server already running on port " .. M.port, vim.log.levels.WARN)
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

  local cmd = build_command(file)

  M.job_id = vim.fn.jobstart(cmd, {
    on_stdout = function(_, data, _)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            -- Parse port from output
            local port = parse_port(line)
            if port then
              M.port = port
              -- Get the job PID (approximate - jobpid gives the shell PID)
              M.pid = vim.fn.jobpid(M.job_id)

              -- Update session
              session.set_server(M.port, M.pid)
              session.add_file(file)

              vim.schedule(function()
                vim.notify(string.format("mdmaid server started on port %d", M.port), vim.log.levels.INFO)
              end)
            end
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
        M.port = nil
        M.pid = nil
        session.clear_server()

        if code ~= 0 and code ~= 143 and code ~= 15 then -- 143/15 = SIGTERM
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

  return true
end

---Stop the mdmaid server
function M.stop()
  if not M.job_id then
    return
  end

  vim.fn.jobstop(M.job_id)
  M.job_id = nil
  M.port = nil
  M.pid = nil
  session.clear_server()
  vim.notify("mdmaid server stopped", vim.log.levels.INFO)
end

---Restart the server
function M.restart()
  local files = session.get_files()
  local current = session.current and session.current.current_file

  M.stop()

  -- Small delay to ensure port is released
  vim.defer_fn(function()
    if current then
      M.start(current)
      -- Re-add other files
      vim.defer_fn(function()
        for _, f in ipairs(files) do
          if f ~= current then
            M.add_file(f)
          end
        end
      end, 500)
    end
  end, 200)
end

---Add a file to the server
---@param file string
function M.add_file(file)
  local abs_path = vim.fn.fnamemodify(file, ":p")
  session.add_file(abs_path)

  if M.is_running() then
    send_api_command("add", abs_path)
  end
end

---Switch to a different file
---@param file string
function M.switch_file(file)
  local abs_path = vim.fn.fnamemodify(file, ":p")
  session.set_current_file(abs_path)

  if M.is_running() then
    -- For switch, we use the add endpoint (server will switch if file exists)
    send_api_command("add", abs_path)
  end
end

---Get current file
---@return string|nil
function M.get_current_file()
  if session.current then
    return session.current.current_file
  end
  return nil
end

---Get all tracked files
---@return string[]
function M.get_files()
  return session.get_files()
end

return M
