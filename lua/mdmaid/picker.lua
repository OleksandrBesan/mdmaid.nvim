local server = require("mdmaid.server")
local session = require("mdmaid.session")

local M = {}

---Open file picker using Telescope if available, otherwise vim.ui.select
function M.pick_file()
  local files = server.get_files()

  if #files == 0 then
    vim.notify("No files tracked. Open a markdown file first.", vim.log.levels.INFO)
    return
  end

  -- Try Telescope first
  local has_telescope, telescope = pcall(require, "telescope")
  if has_telescope then
    M.telescope_picker(files)
  else
    M.native_picker(files)
  end
end

---Telescope-based file picker
---@param files string[]
function M.telescope_picker(files)
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local current_file = server.get_current_file()

  -- Create entries with display formatting
  local entries = {}
  for _, file in ipairs(files) do
    local name = vim.fn.fnamemodify(file, ":t")
    local dir = vim.fn.fnamemodify(file, ":h:t")
    local is_current = file == current_file

    table.insert(entries, {
      value = file,
      display = (is_current and "● " or "  ") .. name .. " (" .. dir .. ")",
      ordinal = name,
      path = file,
    })
  end

  pickers
    .new({}, {
      prompt_title = "mdmaid Files",
      finder = finders.new_table({
        results = entries,
        entry_maker = function(entry)
          return {
            value = entry.value,
            display = entry.display,
            ordinal = entry.ordinal,
            path = entry.path,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      previewer = conf.file_previewer({}),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection then
            server.switch_file(selection.value)
          end
        end)

        -- Remove file with <C-d>
        map("i", "<C-d>", function()
          local selection = action_state.get_selected_entry()
          if selection then
            session.remove_file(selection.value)
            vim.notify("Removed: " .. vim.fn.fnamemodify(selection.value, ":t"), vim.log.levels.INFO)
            -- Refresh picker
            actions.close(prompt_bufnr)
            vim.defer_fn(function()
              M.pick_file()
            end, 100)
          end
        end)

        return true
      end,
    })
    :find()
end

---Native vim.ui.select picker
---@param files string[]
function M.native_picker(files)
  local current_file = server.get_current_file()

  local items = {}
  for _, file in ipairs(files) do
    local name = vim.fn.fnamemodify(file, ":t")
    local is_current = file == current_file
    table.insert(items, {
      file = file,
      display = (is_current and "● " or "  ") .. name,
    })
  end

  vim.ui.select(items, {
    prompt = "Select file to preview:",
    format_item = function(item)
      return item.display
    end,
  }, function(choice)
    if choice then
      server.switch_file(choice.file)
    end
  end)
end

---Add current buffer to tracked files
function M.add_current()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    vim.notify("No file in current buffer", vim.log.levels.WARN)
    return
  end

  if not file:match("%.md$") then
    vim.notify("Not a markdown file", vim.log.levels.WARN)
    return
  end

  server.add_file(file)
  vim.notify("Added: " .. vim.fn.fnamemodify(file, ":t"), vim.log.levels.INFO)
end

---Remove current buffer from tracked files
function M.remove_current()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    return
  end

  session.remove_file(file)
  vim.notify("Removed: " .. vim.fn.fnamemodify(file, ":t"), vim.log.levels.INFO)
end

return M
