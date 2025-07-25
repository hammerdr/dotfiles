local M = {}

local watchers = {}
local timer = nil
local check_interval = 1000 -- Check every 1 second

local function get_file_mtime(filepath)
  local stat = vim.loop.fs_stat(filepath)
  return stat and stat.mtime.sec or 0
end

local function reload_buffer(bufnr, filepath)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end
  
  -- Check if buffer has unsaved changes
  if vim.api.nvim_buf_get_option(bufnr, 'modified') then
    vim.notify("Buffer has unsaved changes, skipping reload: " .. filepath, vim.log.levels.WARN)
    return true
  end
  
  -- Read file content
  local file = io.open(filepath, 'r')
  if not file then
    vim.notify("Could not read file: " .. filepath, vim.log.levels.ERROR)
    return true
  end
  
  local content = file:read('*all')
  file:close()
  
  -- Split content into lines
  local lines = {}
  for line in content:gmatch('[^\r\n]*') do
    table.insert(lines, line)
  end
  
  -- Update buffer content
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  
  -- Reset modified flag
  vim.api.nvim_buf_set_option(bufnr, 'modified', false)
  
  vim.notify("Reloaded: " .. vim.fn.fnamemodify(filepath, ':t'), vim.log.levels.INFO)
  return true
end

local function check_files()
  for bufnr, watcher_data in pairs(watchers) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      local current_mtime = get_file_mtime(watcher_data.filepath)
      if current_mtime > watcher_data.last_mtime then
        watcher_data.last_mtime = current_mtime
        reload_buffer(bufnr, watcher_data.filepath)
      end
    else
      -- Buffer no longer valid, remove from watchers
      watchers[bufnr] = nil
    end
  end
  
  -- Stop timer if no watchers left
  if next(watchers) == nil and timer then
    timer:stop()
    timer:close()
    timer = nil
  end
end

function M.start_watching()
  local bufnr = vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(bufnr)
  
  if filepath == '' then
    vim.notify("Current buffer has no associated file", vim.log.levels.WARN)
    return
  end
  
  if not vim.loop.fs_stat(filepath) then
    vim.notify("File does not exist: " .. filepath, vim.log.levels.ERROR)
    return
  end
  
  if watchers[bufnr] then
    vim.notify("Already watching: " .. vim.fn.fnamemodify(filepath, ':t'), vim.log.levels.INFO)
    return
  end
  
  local mtime = get_file_mtime(filepath)
  watchers[bufnr] = {
    filepath = filepath,
    last_mtime = mtime
  }
  
  -- Start timer if not already running
  if not timer then
    timer = vim.loop.new_timer()
    timer:start(check_interval, check_interval, vim.schedule_wrap(check_files))
  end
  
  vim.notify("Started watching: " .. vim.fn.fnamemodify(filepath, ':t'), vim.log.levels.INFO)
end

function M.stop_watching()
  local bufnr = vim.api.nvim_get_current_buf()
  
  if watchers[bufnr] then
    local filepath = watchers[bufnr].filepath
    watchers[bufnr] = nil
    vim.notify("Stopped watching: " .. vim.fn.fnamemodify(filepath, ':t'), vim.log.levels.INFO)
  else
    vim.notify("Current buffer is not being watched", vim.log.levels.WARN)
  end
end

function M.stop_all_watching()
  local count = 0
  for _ in pairs(watchers) do
    count = count + 1
  end
  
  watchers = {}
  
  if timer then
    timer:stop()
    timer:close()
    timer = nil
  end
  
  vim.notify("Stopped watching " .. count .. " file(s)", vim.log.levels.INFO)
end

function M.list_watched_files()
  local watched_files = {}
  for bufnr, watcher_data in pairs(watchers) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      table.insert(watched_files, vim.fn.fnamemodify(watcher_data.filepath, ':t'))
    end
  end
  
  if #watched_files == 0 then
    vim.notify("No files are currently being watched", vim.log.levels.INFO)
  else
    vim.notify("Watching files: " .. table.concat(watched_files, ', '), vim.log.levels.INFO)
  end
end

function M.setup()
  -- Create user commands
  vim.api.nvim_create_user_command('FileWatchStart', M.start_watching, {})
  vim.api.nvim_create_user_command('FileWatchStop', M.stop_watching, {})
  vim.api.nvim_create_user_command('FileWatchStopAll', M.stop_all_watching, {})
  vim.api.nvim_create_user_command('FileWatchList', M.list_watched_files, {})
  
  -- Set up keybindings
  vim.keymap.set('n', '<leader>fw', M.start_watching, { desc = 'Start watching current file' })
  vim.keymap.set('n', '<leader>fW', M.stop_watching, { desc = 'Stop watching current file' })
  vim.keymap.set('n', '<leader>fwa', M.stop_all_watching, { desc = 'Stop watching all files' })
  vim.keymap.set('n', '<leader>fwl', M.list_watched_files, { desc = 'List watched files' })
end

return M