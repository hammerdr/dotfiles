local M = {}

-- Extract code blocks from Claude's response
local function extract_code_blocks(text)
  local blocks = {}
  local pattern = "```(%w*)\n(.-)\n```"
  
  for lang, code in text:gmatch(pattern) do
    table.insert(blocks, {
      language = lang ~= "" and lang or nil,
      code = code
    })
  end
  
  return blocks
end

-- Function to insert code block at cursor
function M.insert_code_block()
  local bufnr = vim.fn.bufnr("*Claude*")
  if bufnr == -1 then
    print("No Claude buffer found")
    return
  end
  
  -- Get all lines from Claude buffer
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local full_text = table.concat(lines, "\n")
  
  -- Extract code blocks
  local blocks = extract_code_blocks(full_text)
  
  if #blocks == 0 then
    print("No code blocks found in Claude's response")
    return
  end
  
  -- If multiple blocks, let user choose
  local code_to_insert
  if #blocks == 1 then
    code_to_insert = blocks[1].code
  else
    -- Create selection menu
    local choices = {}
    for i, block in ipairs(blocks) do
      local preview = block.code:match("^(.-)\n") or block.code
      local lang = block.language or "unknown"
      table.insert(choices, string.format("%d. [%s] %s", i, lang, preview))
    end
    
    -- Use vim.ui.select to choose
    vim.ui.select(choices, {
      prompt = "Select code block to insert:",
    }, function(choice, idx)
      if idx then
        code_to_insert = blocks[idx].code
      end
    end)
  end
  
  if code_to_insert then
    -- Split code into lines
    local code_lines = {}
    for line in code_to_insert:gmatch("([^\n]*)\n?") do
      if line ~= "" or #code_lines > 0 then
        table.insert(code_lines, line)
      end
    end
    
    -- Insert at current cursor position
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, code_lines)
  end
end

-- Function to replace selection with code from Claude
function M.replace_with_code()
  local bufnr = vim.fn.bufnr("*Claude*")
  if bufnr == -1 then
    print("No Claude buffer found")
    return
  end
  
  -- Get all lines from Claude buffer
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local full_text = table.concat(lines, "\n")
  
  -- Extract code blocks
  local blocks = extract_code_blocks(full_text)
  
  if #blocks == 0 then
    print("No code blocks found in Claude's response")
    return
  end
  
  -- Get visual selection range
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  
  -- If multiple blocks, let user choose
  local code_to_insert
  if #blocks == 1 then
    code_to_insert = blocks[1].code
  else
    -- Create selection menu
    local choices = {}
    for i, block in ipairs(blocks) do
      local preview = block.code:match("^(.-)\n") or block.code
      local lang = block.language or "unknown"
      table.insert(choices, string.format("%d. [%s] %s", i, lang, preview))
    end
    
    -- Use vim.ui.select to choose
    vim.ui.select(choices, {
      prompt = "Select code block to use:",
    }, function(choice, idx)
      if idx then
        code_to_insert = blocks[idx].code
      end
    end)
  end
  
  if code_to_insert then
    -- Split code into lines
    local code_lines = {}
    for line in code_to_insert:gmatch("([^\n]*)\n?") do
      table.insert(code_lines, line)
    end
    
    -- Remove empty line at end if present
    if code_lines[#code_lines] == "" then
      table.remove(code_lines)
    end
    
    -- Replace selected lines
    vim.api.nvim_buf_set_lines(0, start_pos[2] - 1, end_pos[2], false, code_lines)
  end
end

-- Add keymaps for advanced features
function M.setup()
  vim.keymap.set("n", "<leader>ci", function()
    require("claude_advanced").insert_code_block()
  end, { desc = "Insert code from Claude response" })
  
  vim.keymap.set("v", "<leader>cr", function()
    require("claude_advanced").replace_with_code()
  end, { desc = "Replace selection with Claude code" })
end

return M