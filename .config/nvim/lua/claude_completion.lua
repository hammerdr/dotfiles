local M = {}

-- Configuration
M.config = {
  model = "sonnet",
  claude_path = "/opt/homebrew/bin/claude",
  max_context_lines = 20,
  completion_timeout = 5000, -- 5 seconds
  min_trigger_length = 3,
}

-- Cache to avoid repeated requests
local completion_cache = {}
local cache_timeout = 30000 -- 30 seconds

-- Function to get context around cursor
local function get_completion_context()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1 -- 0-indexed
  local col = cursor[2]
  
  -- Get current line
  local current_line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
  local before_cursor = string.sub(current_line, 1, col)
  local after_cursor = string.sub(current_line, col + 1)
  
  -- Get surrounding lines for context
  local start_row = math.max(0, row - M.config.max_context_lines)
  local end_row = math.min(vim.api.nvim_buf_line_count(bufnr), row + M.config.max_context_lines + 1)
  local context_lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row, false)
  
  return {
    filetype = vim.bo[bufnr].filetype,
    filename = vim.api.nvim_buf_get_name(bufnr),
    before_cursor = before_cursor,
    after_cursor = after_cursor,
    current_line = current_line,
    context_lines = context_lines,
    cursor_row = row,
    relative_cursor_row = row - start_row,
  }
end

-- Function to generate completion prompt
local function create_completion_prompt(context)
  local prompt = string.format([[
You are a code completion assistant. Given the context below, provide ONLY the completion for the current line where the cursor is positioned.

Rules:
1. Complete only what should come after the cursor position
2. Provide a single, most likely completion
3. Do not include explanations or multiple options
4. Respect the existing code style and patterns
5. If you cannot provide a meaningful completion, respond with exactly: "NO_COMPLETION"

File: %s
Language: %s

Context:
```%s
%s
```

Current line before cursor: %s
Current line after cursor: %s

Provide completion for after the cursor:]], 
    context.filename,
    context.filetype,
    context.filetype,
    table.concat(context.context_lines, "\n"),
    context.before_cursor,
    context.after_cursor
  )
  
  return prompt
end

-- Function to execute Claude completion
local function get_claude_completion(context)
  local prompt = create_completion_prompt(context)
  
  -- Create cache key
  local cache_key = vim.fn.sha256(prompt)
  local now = vim.fn.localtime() * 1000
  
  -- Check cache
  if completion_cache[cache_key] and 
     (now - completion_cache[cache_key].timestamp) < cache_timeout then
    return completion_cache[cache_key].result
  end
  
  -- Execute Claude command
  local cmd = string.format(
    "%s --print --model %s %s",
    M.config.claude_path,
    M.config.model,
    vim.fn.shellescape(prompt)
  )
  
  local result = vim.fn.system(cmd)
  local exit_code = vim.v.shell_error
  
  if exit_code ~= 0 then
    return nil
  end
  
  -- Clean up the result
  result = vim.trim(result)
  
  -- Check for no completion indicator
  if result == "NO_COMPLETION" or result == "" then
    return nil
  end
  
  -- Cache the result
  completion_cache[cache_key] = {
    result = result,
    timestamp = now
  }
  
  return result
end

-- nvim-cmp source
local cmp_source = {}

function cmp_source:is_available()
  -- Only provide completions for code files
  local ft = vim.bo.filetype
  return ft ~= "" and ft ~= "text" and ft ~= "markdown"
end

function cmp_source:get_debug_name()
  return "claude"
end

function cmp_source:get_keyword_pattern()
  return [[\k\+]]
end

function cmp_source:get_trigger_characters()
  return { ".", ":", "(", "[", " " }
end

function cmp_source:complete(params, callback)
  local context = get_completion_context()
  
  -- Don't trigger for very short input
  if string.len(context.before_cursor) < M.config.min_trigger_length then
    callback({ items = {}, isIncomplete = false })
    return
  end
  
  -- Get Claude completion asynchronously using vim.defer_fn
  vim.defer_fn(function()
    local completion = get_claude_completion(context)
    
    if completion then
      -- Create completion item
      local items = {
        {
          label = completion,
          kind = require('cmp').lsp.CompletionItemKind.Text,
          detail = "Claude AI",
          documentation = {
            kind = "markdown",
            value = "AI-generated completion from Claude"
          },
          insertText = completion,
        }
      }
      
      callback({ items = items, isIncomplete = false })
    else
      callback({ items = {}, isIncomplete = false })
    end
  end, 0)
end

-- Setup function
function M.setup(opts)
  M.config = vim.tbl_extend("force", M.config, opts or {})
  
  -- Register with nvim-cmp
  local ok, cmp = pcall(require, 'cmp')
  if ok then
    cmp.register_source('claude', cmp_source)
  end
end

-- Manual completion function for testing
function M.test_completion()
  local context = get_completion_context()
  print("Context:", vim.inspect(context))
  
  local completion = get_claude_completion(context)
  if completion then
    print("Completion:", completion)
    
    -- Insert the completion
    local cursor = vim.api.nvim_win_get_cursor(0)
    local row = cursor[1] - 1
    local col = cursor[2]
    
    vim.api.nvim_buf_set_text(0, row, col, row, col, {completion})
  else
    print("No completion available")
  end
end

return M