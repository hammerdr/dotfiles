local M = {}

-- Configuration
M.config = {
  -- Default model to use
  model = "claude-3-5-sonnet-20241022",
  -- Buffer name for Claude responses
  buffer_name = "*Claude*",
  -- Window split direction: 'vertical' or 'horizontal'
  split_direction = "vertical",
  -- Window size (percentage for vertical, lines for horizontal)
  window_size = 50,
}

-- State
local claude_bufnr = nil
local claude_winnr = nil

-- Helper function to create or get Claude buffer
local function get_or_create_buffer()
  -- Check if buffer exists and is valid
  if claude_bufnr and vim.api.nvim_buf_is_valid(claude_bufnr) then
    return claude_bufnr
  end
  
  -- Create new buffer
  claude_bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(claude_bufnr, M.config.buffer_name)
  vim.api.nvim_buf_set_option(claude_bufnr, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(claude_bufnr, 'filetype', 'markdown')
  
  return claude_bufnr
end

-- Helper function to show Claude buffer in window
local function show_claude_window()
  local bufnr = get_or_create_buffer()
  
  -- Check if window exists
  if claude_winnr and vim.api.nvim_win_is_valid(claude_winnr) then
    vim.api.nvim_set_current_win(claude_winnr)
    return
  end
  
  -- Create new window
  local cmd = M.config.split_direction == "vertical" 
    and string.format("%dvnew", M.config.window_size)
    or string.format("%dnew", M.config.window_size)
  
  vim.cmd(cmd)
  claude_winnr = vim.api.nvim_get_current_win()
  
  -- Set buffer in window
  vim.api.nvim_win_set_buf(claude_winnr, bufnr)
  
  -- Make buffer modifiable for interactive use
  vim.api.nvim_buf_set_option(bufnr, 'buftype', 'acwrite')
  vim.api.nvim_buf_set_option(bufnr, 'modifiable', true)
  
  -- Set up buffer-local keymaps for Claude window
  local opts = { buffer = bufnr, silent = true }
  
  -- Submit on Ctrl+Enter
  vim.keymap.set({'n', 'i'}, '<C-CR>', function()
    M.submit_chat()
  end, vim.tbl_extend('force', opts, { desc = 'Submit to Claude' }))
  
  -- Submit on <leader>s
  vim.keymap.set({'n', 'i'}, '<leader>s', function()
    M.submit_chat()
  end, vim.tbl_extend('force', opts, { desc = 'Submit to Claude' }))
  
  -- Clear buffer on <leader>x
  vim.keymap.set('n', '<leader>x', function()
    M.clear_claude_buffer()
  end, vim.tbl_extend('force', opts, { desc = 'Clear Claude buffer' }))
end

-- Function to escape special characters for shell
local function shell_escape(str)
  return vim.fn.shellescape(str)
end

-- Function to send text to Claude
function M.send_to_claude(opts)
  opts = opts or {}
  local mode = opts.mode or "n"
  local prompt = opts.prompt
  
  -- Get selected text based on mode
  local text
  if mode == "v" or mode == "V" then
    -- Visual mode: get selected text
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    local lines = vim.api.nvim_buf_get_lines(
      0,
      start_pos[2] - 1,
      end_pos[2],
      false
    )
    
    if mode == "v" then
      -- Character-wise visual mode
      lines[1] = string.sub(lines[1], start_pos[3])
      if #lines > 1 then
        lines[#lines] = string.sub(lines[#lines], 1, end_pos[3])
      else
        lines[1] = string.sub(lines[1], 1, end_pos[3] - start_pos[3] + 1)
      end
    end
    
    text = table.concat(lines, "\n")
  else
    -- Normal mode: get current line or motion
    local line = vim.api.nvim_get_current_line()
    text = line
  end
  
  -- Get additional prompt from user if not provided
  if not prompt then
    prompt = vim.fn.input("Claude prompt: ")
    if prompt == "" then
      return
    end
  end
  
  -- Prepare the full prompt
  local full_prompt = string.format("%s\n\n%s", prompt, text)
  
  -- Show Claude window
  show_claude_window()
  
  -- Add loading message
  local bufnr = get_or_create_buffer()
  vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, {
    "",
    "---",
    "",
    "**Prompt:** " .. prompt,
    "",
    "**Processing...**",
    ""
  })
  
  -- Construct Claude command using table format for better argument handling
  local claude_args = {
    "claude",
    "--print",
    "--model",
    M.config.model,
    full_prompt
  }
  
  -- Execute command asynchronously
  vim.fn.jobstart(claude_args, {
    stdout_buffered = true,
    on_stdout = function(_, data, _)
      if data and #data > 1 then
        -- Remove the processing message
        local line_count = vim.api.nvim_buf_line_count(bufnr)
        vim.api.nvim_buf_set_lines(bufnr, line_count - 2, line_count, false, {})
        
        -- Add Claude's response
        vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, {"**Claude:**", ""})
        vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, data)
      end
    end,
    on_stderr = function(_, data, _)
      if data and #data > 1 then
        -- Remove the processing message
        local line_count = vim.api.nvim_buf_line_count(bufnr)
        vim.api.nvim_buf_set_lines(bufnr, line_count - 2, line_count, false, {})
        
        -- Add error message
        vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, {"**Error:**", ""})
        vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, data)
      end
    end,
    on_exit = function(_, exit_code, _)
      if exit_code ~= 0 then
        vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, {
          "",
          "**Process exited with code: " .. exit_code .. "**"
        })
      end
    end
  })
end

-- Function to send current file to Claude
function M.send_file_to_claude(prompt)
  local filename = vim.fn.expand("%:p")
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local content = table.concat(lines, "\n")
  
  -- Default prompt if not provided
  if not prompt or prompt == "" then
    prompt = "Please analyze this " .. vim.bo.filetype .. " file:"
  end
  
  -- Prepare the full prompt with file info
  local full_prompt = string.format(
    "%s\n\nFile: %s\n\n```%s\n%s\n```",
    prompt,
    filename,
    vim.bo.filetype,
    content
  )
  
  -- Show Claude window
  show_claude_window()
  
  -- Add loading message
  local bufnr = get_or_create_buffer()
  vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, {
    "",
    "---",
    "",
    "**File:** " .. filename,
    "**Prompt:** " .. prompt,
    "",
    "**Processing...**",
    ""
  })
  
  -- Construct Claude command using table format for better argument handling
  local claude_args = {
    "claude",
    "--print",
    "--model",
    M.config.model,
    full_prompt
  }
  
  -- Execute command asynchronously
  vim.fn.jobstart(claude_args, {
    stdout_buffered = true,
    on_stdout = function(_, data, _)
      if data and #data > 1 then
        -- Remove the processing message
        local line_count = vim.api.nvim_buf_line_count(bufnr)
        vim.api.nvim_buf_set_lines(bufnr, line_count - 2, line_count, false, {})
        
        -- Add Claude's response
        vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, {"**Claude:**", ""})
        vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, data)
      end
    end,
    on_stderr = function(_, data, _)
      if data and #data > 1 then
        -- Remove the processing message
        local line_count = vim.api.nvim_buf_line_count(bufnr)
        vim.api.nvim_buf_set_lines(bufnr, line_count - 2, line_count, false, {})
        
        -- Add error message
        vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, {"**Error:**", ""})
        vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, data)
      end
    end
  })
end

-- Function to submit interactive chat
function M.submit_chat()
  local bufnr = get_or_create_buffer()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  
  -- Find the last user input (text after the last "---" separator or at the end)
  local user_input_start = 1
  local separator_line = nil
  
  for i = #lines, 1, -1 do
    if lines[i]:match("^%-%-%-+$") then
      separator_line = i
      user_input_start = i + 1
      break
    end
  end
  
  -- If no separator found, look for the last "**You:**" marker
  if not separator_line then
    for i = #lines, 1, -1 do
      if lines[i]:match("^%*%*You:%*%*") then
        user_input_start = i + 1
        break
      end
    end
  end
  
  -- Extract user input from the buffer
  local user_lines = {}
  for i = user_input_start, #lines do
    if lines[i] and lines[i] ~= "" then
      table.insert(user_lines, lines[i])
    end
  end
  
  local user_input = table.concat(user_lines, "\n"):gsub("^%s+", ""):gsub("%s+$", "")
  
  if user_input == "" then
    print("No input to submit")
    return
  end
  
  -- Add separator and processing message
  vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, {
    "",
    "---",
    "",
    "**Processing...**",
    ""
  })
  
  -- Scroll to bottom
  if claude_winnr and vim.api.nvim_win_is_valid(claude_winnr) then
    local line_count = vim.api.nvim_buf_line_count(bufnr)
    vim.api.nvim_win_set_cursor(claude_winnr, {line_count, 0})
  end
  
  -- Construct Claude command using table format for better argument handling
  local claude_args = {
    "claude",
    "--print",
    "--model",
    M.config.model,
    user_input
  }
  
  -- Execute command asynchronously
  vim.fn.jobstart(claude_args, {
    stdout_buffered = true,
    on_stdout = function(_, data, _)
      if data and #data > 1 then
        -- Remove the processing message
        local line_count = vim.api.nvim_buf_line_count(bufnr)
        vim.api.nvim_buf_set_lines(bufnr, line_count - 2, line_count, false, {})
        
        -- Add Claude's response
        vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, {"**Claude:**", ""})
        vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, data)
        vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, {"", "**You:**", ""})
        
        -- Scroll to bottom and enter insert mode
        if claude_winnr and vim.api.nvim_win_is_valid(claude_winnr) then
          local new_line_count = vim.api.nvim_buf_line_count(bufnr)
          vim.api.nvim_win_set_cursor(claude_winnr, {new_line_count, 0})
          -- Switch to insert mode for continued chat
          vim.cmd("startinsert")
        end
      end
    end,
    on_stderr = function(_, data, _)
      if data and #data > 1 then
        -- Remove the processing message
        local line_count = vim.api.nvim_buf_line_count(bufnr)
        vim.api.nvim_buf_set_lines(bufnr, line_count - 2, line_count, false, {})
        
        -- Add error message
        vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, {"**Error:**", ""})
        vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, data)
      end
    end
  })
end

-- Function to start interactive chat
function M.start_chat()
  show_claude_window()
  local bufnr = get_or_create_buffer()
  
  -- If buffer is empty, add initial prompt
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  if line_count == 1 then
    local first_line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
    if first_line == "" then
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
        "# Claude Chat",
        "",
        "Type your message below and press <C-CR> or <leader>s to submit.",
        "Use <leader>x to clear the buffer.",
        "",
        "**You:**",
        ""
      })
    end
  else
    -- Add new user prompt at the end
    vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, {"", "**You:**", ""})
  end
  
  -- Move cursor to the end and enter insert mode
  local new_line_count = vim.api.nvim_buf_line_count(bufnr)
  vim.api.nvim_win_set_cursor(claude_winnr, {new_line_count, 0})
  vim.cmd("startinsert")
end

-- Function to clear Claude buffer
function M.clear_claude_buffer()
  local bufnr = get_or_create_buffer()
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
    "# Claude Chat",
    "",
    "Type your message below and press <C-CR> or <leader>s to submit.",
    "Use <leader>x to clear the buffer.",
    "",
    "**You:**",
    ""
  })
  
  -- Move cursor to the end and enter insert mode
  if claude_winnr and vim.api.nvim_win_is_valid(claude_winnr) then
    local line_count = vim.api.nvim_buf_line_count(bufnr)
    vim.api.nvim_win_set_cursor(claude_winnr, {line_count, 0})
    vim.cmd("startinsert")
  end
end

-- Setup function
function M.setup(opts)
  M.config = vim.tbl_extend("force", M.config, opts or {})
  
  -- Create commands
  vim.api.nvim_create_user_command("Claude", function(args)
    M.send_to_claude({ prompt = args.args })
  end, { nargs = "?", range = true })
  
  vim.api.nvim_create_user_command("ClaudeFile", function(args)
    M.send_file_to_claude(args.args)
  end, { nargs = "?" })
  
  vim.api.nvim_create_user_command("ClaudeChat", function()
    M.start_chat()
  end, {})
  
  vim.api.nvim_create_user_command("ClaudeSync", function(args)
    require('claude_sync').send_to_claude(args.args)
  end, { nargs = "?" })
  
  vim.api.nvim_create_user_command("ClaudeSyncFile", function(args)
    require('claude_sync').send_file_to_claude(args.args)
  end, { nargs = "?" })
  
  vim.api.nvim_create_user_command("ClaudeTelescope", function()
    require('claude_telescope').claude_picker()
  end, {})
  
  vim.api.nvim_create_user_command("ClaudeTest", function()
    require('claude_telescope').test_claude_command()
  end, {})
  
  vim.api.nvim_create_user_command("ClaudeClear", function()
    M.clear_claude_buffer()
  end, {})
  
  -- Create keymaps (using working synchronous version)
  vim.keymap.set("n", "<leader>cc", ":ClaudeSync<CR>", { desc = "Claude (sync)" })
  vim.keymap.set("v", "<leader>cc", ":ClaudeSync<CR>", { desc = "Claude (sync)" })
  vim.keymap.set("n", "<leader>cf", ":ClaudeSyncFile<CR>", { desc = "Send file to Claude (sync)" })
  vim.keymap.set("n", "<leader>ch", ":ClaudeChat<CR>", { desc = "Start Claude chat" })
  vim.keymap.set("n", "<leader>ct", ":ClaudeTelescope<CR>", { desc = "Claude with Telescope (broken)" })
  vim.keymap.set("v", "<leader>ct", ":ClaudeTelescope<CR>", { desc = "Claude with Telescope (broken)" })
  vim.keymap.set("n", "<leader>cx", ":ClaudeClear<CR>", { desc = "Clear Claude buffer" })
end

return M