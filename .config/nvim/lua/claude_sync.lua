local M = {}

-- Configuration
M.config = {
  model = "sonnet",
  claude_path = "/opt/homebrew/bin/claude",
}

-- Function to get selected text or current context
local function get_context_info()
  local mode = vim.fn.mode()
  local context = ""
  local context_type = ""
  local filename = vim.fn.expand("%:p")
  
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
      if #lines == 1 then
        lines[1] = string.sub(lines[1], start_pos[3], end_pos[3])
      else
        lines[1] = string.sub(lines[1], start_pos[3])
        lines[#lines] = string.sub(lines[#lines], 1, end_pos[3])
      end
    end
    
    context = table.concat(lines, "\n")
    context_type = "Selected Text"
  else
    -- Normal mode: get entire file
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    context = table.concat(lines, "\n")
    context_type = "Entire File"
  end
  
  return {
    content = context,
    type = context_type,
    filename = filename,
    filetype = vim.bo.filetype
  }
end

-- Function to execute Claude command synchronously
local function execute_claude(prompt, context_info)
  local full_prompt
  
  if context_info.type == "Selected Text" then
    full_prompt = string.format("%s\n\n%s", prompt, context_info.content)
  else
    full_prompt = string.format(
      "%s\n\nFile: %s\n\n```%s\n%s\n```",
      prompt,
      context_info.filename,
      context_info.filetype or "",
      context_info.content
    )
  end
  
  -- Use vim.fn.system for synchronous execution
  local cmd = string.format(
    "%s --print --model %s %s",
    M.config.claude_path,
    M.config.model,
    vim.fn.shellescape(full_prompt)
  )
  
  local result = vim.fn.system(cmd)
  local exit_code = vim.v.shell_error
  
  return {
    output = result,
    exit_code = exit_code,
    success = exit_code == 0
  }
end

-- Function to create and show result in a split window
local function show_result(prompt, context_info, result)
  -- Create a new split window
  vim.cmd("vsplit")
  local win = vim.api.nvim_get_current_win()
  
  -- Create a new buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(win, buf)
  
  -- Set buffer properties
  vim.api.nvim_buf_set_name(buf, "*Claude Result*")
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  
  -- Prepare content
  local lines = {}
  
  -- Context section
  table.insert(lines, "# Context: " .. context_info.type)
  if context_info.filename ~= "" then
    table.insert(lines, "**File:** " .. context_info.filename)
  end
  table.insert(lines, "")
  
  -- Show context (truncated for readability)
  table.insert(lines, "```" .. (context_info.filetype or ""))
  local context_lines = vim.split(context_info.content, '\n', { plain = true })
  for i, line in ipairs(context_lines) do
    if i > 15 then
      table.insert(lines, "... (truncated)")
      break
    end
    table.insert(lines, line)
  end
  table.insert(lines, "```")
  table.insert(lines, "")
  
  -- Prompt section
  table.insert(lines, "# Prompt")
  table.insert(lines, prompt)
  table.insert(lines, "")
  
  -- Response section
  table.insert(lines, "# Claude Response")
  if result.success then
    local response_lines = vim.split(result.output, '\n', { plain = true })
    for _, line in ipairs(response_lines) do
      table.insert(lines, line)
    end
  else
    table.insert(lines, "**Error (exit code " .. result.exit_code .. "):**")
    table.insert(lines, result.output)
  end
  
  -- Set content
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  
  -- Set up key mappings for the result buffer
  local opts = { buffer = buf, silent = true }
  vim.keymap.set('n', 'q', '<cmd>close<cr>', opts)
  vim.keymap.set('n', '<leader>ci', function()
    M.insert_code_from_buffer(buf)
  end, opts)
  vim.keymap.set('n', '<leader>y', function()
    M.copy_response_from_buffer(buf)
  end, opts)
end

-- Function to extract and insert code blocks
function M.insert_code_from_buffer(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local content = table.concat(lines, '\n')
  
  -- Extract code blocks
  local blocks = {}
  for lang, code in content:gmatch("```(%w*)\n(.-)\n```") do
    if lang ~= "" and lang ~= "javascript" and lang ~= "typescript" and lang ~= "python" then
      -- Skip context blocks and focus on actual code responses
      goto continue
    end
    table.insert(blocks, {
      language = lang ~= "" and lang or nil,
      code = code
    })
    ::continue::
  end
  
  if #blocks == 0 then
    print("No code blocks found")
    return
  end
  
  local code_to_insert
  if #blocks == 1 then
    code_to_insert = blocks[1].code
  else
    -- Let user choose
    local choices = {}
    for i, block in ipairs(blocks) do
      local preview = block.code:match("^(.-)\n") or block.code
      local lang = block.language or "unknown"
      table.insert(choices, string.format("%d. [%s] %s", i, lang, preview:sub(1, 50)))
    end
    
    vim.ui.select(choices, {
      prompt = "Select code block:",
    }, function(choice, idx)
      if idx then
        code_to_insert = blocks[idx].code
      end
    end)
  end
  
  if code_to_insert then
    -- Close the result window first
    vim.cmd("close")
    
    -- Insert at cursor
    local code_lines = vim.split(code_to_insert, '\n', { plain = true })
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, code_lines)
  end
end

-- Function to copy response to clipboard
function M.copy_response_from_buffer(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local content = table.concat(lines, '\n')
  
  -- Extract just the response part
  local response_start = content:find("# Claude Response\n")
  if response_start then
    local response = content:sub(response_start + 18) -- 18 = length of "# Claude Response\n"
    vim.fn.setreg('+', response)
    print("Response copied to clipboard")
  else
    print("No response found")
  end
end

-- Main function to send to Claude
function M.send_to_claude(prompt)
  if not prompt or prompt == "" then
    prompt = vim.fn.input("Claude prompt: ")
    if prompt == "" then
      return
    end
  end
  
  local context_info = get_context_info()
  
  print("Sending to Claude...")
  local result = execute_claude(prompt, context_info)
  
  show_result(prompt, context_info, result)
end

-- Function to send file to Claude
function M.send_file_to_claude(prompt)
  if not prompt or prompt == "" then
    prompt = vim.fn.input("Claude prompt: ")
    if prompt == "" then
      return
    end
  end
  
  local context_info = get_context_info()
  -- Force it to be entire file
  context_info.type = "Entire File"
  
  print("Sending file to Claude...")
  local result = execute_claude(prompt, context_info)
  
  show_result(prompt, context_info, result)
end

-- Setup function
function M.setup(opts)
  M.config = vim.tbl_extend("force", M.config, opts or {})
  
  -- Create commands
  vim.api.nvim_create_user_command("ClaudeSync", function(args)
    M.send_to_claude(args.args)
  end, { nargs = "?" })
  
  vim.api.nvim_create_user_command("ClaudeSyncFile", function(args)
    M.send_file_to_claude(args.args)
  end, { nargs = "?" })
  
  vim.api.nvim_create_user_command("ClaudeTestCompletion", function()
    require('claude_completion').test_completion()
  end, {})
  
  -- Create keymaps
  vim.keymap.set("n", "<leader>cc", ":ClaudeSync<CR>", { desc = "Claude (sync)" })
  vim.keymap.set("v", "<leader>cc", ":ClaudeSync<CR>", { desc = "Claude (sync)" })
  vim.keymap.set("n", "<leader>cf", ":ClaudeSyncFile<CR>", { desc = "Send file to Claude (sync)" })
  vim.keymap.set("n", "<leader>cT", ":ClaudeTestCompletion<CR>", { desc = "Test Claude completion" })
end

return M