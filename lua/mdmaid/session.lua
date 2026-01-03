local config = require("mdmaid.config")

local M = {}

-- Session directory
local SESSION_DIR = "/tmp/mdmaid-sessions"

---@class MdmaidSession
---@field nvim_pid number
---@field server_pid number|nil
---@field port number|nil
---@field files string[]
---@field current_file string|nil
---@field cwd string

---@type MdmaidSession|nil
M.current = nil

---Get session file path for this nvim instance
---@return string
local function get_session_path()
  return SESSION_DIR .. "/nvim-" .. vim.fn.getpid() .. ".json"
end

---Ensure session directory exists
local function ensure_session_dir()
  vim.fn.mkdir(SESSION_DIR, "p")
end

---Check if a process is running
---@param pid number
---@return boolean
local function is_pid_running(pid)
  local result = vim.fn.system("kill -0 " .. pid .. " 2>/dev/null; echo $?")
  return vim.trim(result) == "0"
end

---Load session from disk
---@return MdmaidSession|nil
function M.load()
  local path = get_session_path()
  local file = io.open(path, "r")
  if not file then
    return nil
  end

  local content = file:read("*a")
  file:close()

  local ok, session = pcall(vim.json.decode, content)
  if ok and session then
    M.current = session
    return session
  end

  return nil
end

---Save session to disk
function M.save()
  if not M.current then
    return
  end

  ensure_session_dir()
  local path = get_session_path()
  local file = io.open(path, "w")
  if not file then
    vim.notify("Failed to save session", vim.log.levels.ERROR)
    return
  end

  local content = vim.json.encode(M.current)
  file:write(content)
  file:close()
end

---Delete session file
function M.delete()
  local path = get_session_path()
  os.remove(path)
  M.current = nil
end

---Create a new session
---@return MdmaidSession
function M.create()
  M.current = {
    nvim_pid = vim.fn.getpid(),
    server_pid = nil,
    port = nil,
    files = {},
    current_file = nil,
    cwd = vim.fn.getcwd(),
  }
  M.save()
  return M.current
end

---Get or create session
---@return MdmaidSession
function M.get_or_create()
  if M.current then
    return M.current
  end

  local loaded = M.load()
  if loaded then
    return loaded
  end

  return M.create()
end

---Update server info
---@param port number
---@param pid number
function M.set_server(port, pid)
  local session = M.get_or_create()
  session.port = port
  session.server_pid = pid
  M.save()
end

---Clear server info
function M.clear_server()
  if M.current then
    M.current.port = nil
    M.current.server_pid = nil
    M.save()
  end
end

---Add a file to the session
---@param file string
function M.add_file(file)
  local session = M.get_or_create()
  local abs_path = vim.fn.fnamemodify(file, ":p")

  -- Check if already tracked
  for _, f in ipairs(session.files) do
    if f == abs_path then
      return
    end
  end

  table.insert(session.files, abs_path)
  session.current_file = abs_path
  M.save()
end

---Remove a file from the session
---@param file string
function M.remove_file(file)
  if not M.current then
    return
  end

  local abs_path = vim.fn.fnamemodify(file, ":p")
  local new_files = {}

  for _, f in ipairs(M.current.files) do
    if f ~= abs_path then
      table.insert(new_files, f)
    end
  end

  M.current.files = new_files

  -- Update current file if removed
  if M.current.current_file == abs_path then
    M.current.current_file = new_files[1] or nil
  end

  M.save()
end

---Set current file
---@param file string
function M.set_current_file(file)
  local session = M.get_or_create()
  local abs_path = vim.fn.fnamemodify(file, ":p")
  session.current_file = abs_path

  -- Also add if not tracked
  M.add_file(file)
end

---Get all files
---@return string[]
function M.get_files()
  if not M.current then
    return {}
  end
  return M.current.files
end

---Clean up orphaned sessions (nvim process dead)
function M.cleanup_orphans()
  ensure_session_dir()

  local sessions = vim.fn.glob(SESSION_DIR .. "/nvim-*.json", false, true)

  for _, path in ipairs(sessions) do
    local file = io.open(path, "r")
    if file then
      local content = file:read("*a")
      file:close()

      local ok, session = pcall(vim.json.decode, content)
      if ok and session and session.nvim_pid then
        -- Check if nvim process is still running
        if not is_pid_running(session.nvim_pid) then
          -- Kill orphaned server if running
          if session.server_pid and is_pid_running(session.server_pid) then
            vim.fn.system("kill " .. session.server_pid)
            vim.notify("Killed orphaned mdmaid server (pid: " .. session.server_pid .. ")", vim.log.levels.INFO)
          end

          -- Remove session file
          os.remove(path)
        end
      end
    end
  end
end

---Get all active sessions
---@return MdmaidSession[]
function M.get_all_sessions()
  ensure_session_dir()

  local sessions = {}
  local files = vim.fn.glob(SESSION_DIR .. "/nvim-*.json", false, true)

  for _, path in ipairs(files) do
    local file = io.open(path, "r")
    if file then
      local content = file:read("*a")
      file:close()

      local ok, session = pcall(vim.json.decode, content)
      if ok and session then
        table.insert(sessions, session)
      end
    end
  end

  return sessions
end

return M
