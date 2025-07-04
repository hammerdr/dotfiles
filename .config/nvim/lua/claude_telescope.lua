local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local previewers = require "telescope.previewers"
local utils = require "telescope.utils"
local Job = require "plenary.job"

local M = {}

-- Configuration
M.config = {
  model = "claude-3-5-sonnet-20241022",
  height = 0.9,
  width = 0.9,
}

-- State to store context and responses
local claude_state = {
  context = "",
  context_type = "",
  filename = "",
  responses = {}
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

-- Custom previewer for showing context, prompt, and response
local function create_claude_previewer()
  return previewers.new_buffer_previewer({
    title = "Claude Context & Response",
    get_buffer_by_name = function(_, entry)
      return entry and entry.value or "default"
    end,
    define_preview = function(self, entry, status)
      local lines = {}
      
      -- Context section
      table.insert(lines, "# Context: " .. (claude_state.context_type or "Unknown"))
      if claude_state.filename and claude_state.filename ~= "" then
        table.insert(lines, "**File:** " .. claude_state.filename)
      end
      table.insert(lines, "")
      
      -- Show context if available
      if claude_state.context and claude_state.context ~= "" then
        table.insert(lines, "```" .. (claude_state.filetype or ""))
        
        -- Split context into lines and add them (limit to first 20 lines for readability)
        local context_lines = vim.split(claude_state.context, '\n', { plain = true })
        for i, line in ipairs(context_lines) do
          if i > 20 then
            table.insert(lines, "... (truncated)")
            break
          end
          table.insert(lines, line)
        end
        table.insert(lines, "```")
      end
      table.insert(lines, "")
      
      -- If an entry is selected, show its details
      if entry and entry.value then
        local response = claude_state.responses[entry.value] or {}
        
        -- Prompt section
        table.insert(lines, "# Prompt")
        table.insert(lines, response.prompt or "_No prompt yet_")
        table.insert(lines, "")
        
        -- Response section
        table.insert(lines, "# Claude Response")
        if response.status == "processing" then
          table.insert(lines, "**Processing...**")
        elseif response.status == "error" then
          table.insert(lines, "**Error:**")
          if response.error then
            local error_lines = vim.split(response.error, '\n', { plain = true })
            for _, line in ipairs(error_lines) do
              table.insert(lines, line)
            end
          else
            table.insert(lines, "Unknown error")
          end
        elseif response.response then
          -- Split response into lines and add them
          local response_lines = vim.split(response.response, '\n', { plain = true })
          for _, line in ipairs(response_lines) do
            table.insert(lines, line)
          end
        else
          table.insert(lines, "_No response yet_")
        end
      else
        table.insert(lines, "# Ready")
        table.insert(lines, "Type your prompt below and press <Enter> to send to Claude.")
        table.insert(lines, "")
        table.insert(lines, "**Available actions:**")
        table.insert(lines, "- <Enter>: Submit prompt")
        table.insert(lines, "- <C-i>: Insert code from response")
        table.insert(lines, "- <C-y>: Copy response to clipboard")
      end
      
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
      vim.api.nvim_buf_set_option(self.state.bufnr, 'filetype', 'markdown')
    end
  })
end

-- Function to send prompt to Claude
local function send_to_claude(prompt, entry_id)
  local context_info = claude_state
  local full_prompt
  
  if context_info.context_type == "Selected Text" then
    full_prompt = string.format("%s\n\n%s", prompt, context_info.context)
  else
    full_prompt = string.format(
      "%s\n\nFile: %s\n\n```%s\n%s\n```",
      prompt,
      context_info.filename,
      context_info.filetype or "",
      context_info.context
    )
  end
  
  -- Update state to show processing
  claude_state.responses[entry_id] = {
    prompt = prompt,
    status = "processing",
    filetype = context_info.filetype
  }
  
  -- Create Claude command
  local cmd = {"claude", "-m", M.config.model, full_prompt}
  
  -- Execute Claude command using table format for better argument handling
  -- Use full path to ensure claude is found
  local claude_path = "/opt/homebrew/bin/claude"
  local claude_args = {
    claude_path,
    "--print", 
    "--model",
    M.config.model,
    full_prompt
  }
  
  vim.fn.jobstart(claude_args, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data, _)
      if data then
        -- Filter out empty strings
        local filtered_data = {}
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(filtered_data, line)
          end
        end
        
        if #filtered_data > 0 then
          local result = table.concat(filtered_data, "\n")
          claude_state.responses[entry_id] = {
            prompt = prompt,
            status = "complete",
            response = result,
            filetype = context_info.filetype
          }
          -- Trigger preview refresh
          vim.schedule(function()
            vim.cmd("redraw")
          end)
        end
      end
    end,
    on_stderr = function(_, data, _)
      if data then
        -- Filter out empty strings
        local filtered_data = {}
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(filtered_data, line)
          end
        end
        
        if #filtered_data > 0 then
          local error_msg = table.concat(filtered_data, "\n")
          claude_state.responses[entry_id] = {
            prompt = prompt,
            status = "error",
            error = error_msg,
            filetype = context_info.filetype
          }
          -- Trigger preview refresh
          vim.schedule(function()
            vim.cmd("redraw")
          end)
        end
      end
    end,
    on_exit = function(_, exit_code, _)
      -- If job exits without stdout data, it might be an error
      if not claude_state.responses[entry_id] or claude_state.responses[entry_id].status == "processing" then
        claude_state.responses[entry_id] = {
          prompt = prompt,
          status = "error",
          error = "Claude command failed with exit code: " .. exit_code,
          filetype = context_info.filetype
        }
        vim.schedule(function()
          vim.cmd("redraw")
        end)
      end
    end
  })
end

-- Function to extract code blocks from response
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

-- Main Claude telescope function
function M.claude_picker(opts)
  opts = opts or {}
  
  -- Get context information
  local context_info = get_context_info()
  claude_state.context = context_info.content
  claude_state.context_type = context_info.type
  claude_state.filename = context_info.filename
  claude_state.filetype = context_info.filetype
  
  -- Create initial entries (we'll start with one entry for new prompt)
  local entries = {}
  local conversation_counter = 0
  
  pickers.new(opts, {
    prompt_title = "Claude Code (" .. context_info.type .. ") - Type prompt and press <Enter>",
    finder = finders.new_table {
      results = entries,
      entry_maker = function(entry)
        return {
          value = entry.id,
          display = entry.display,
          ordinal = entry.display,
        }
      end
    },
    previewer = create_claude_previewer(),
    sorter = conf.generic_sorter(opts),
    layout_config = {
      height = M.config.height,
      width = M.config.width,
      preview_width = 0.6,
    },
    attach_mappings = function(prompt_bufnr, map)
      -- Submit prompt
      local function submit_prompt()
        local prompt = action_state.get_current_line()
        if prompt == "" then
          print("Please enter a prompt")
          return
        end
        
        conversation_counter = conversation_counter + 1
        local entry_id = "prompt_" .. conversation_counter
        
        -- Create new entry
        local new_entry = {
          id = entry_id,
          display = "🤖 " .. prompt:sub(1, 50) .. (prompt:len() > 50 and "..." or "")
        }
        
        -- Add to entries table
        table.insert(entries, new_entry)
        
        -- Refresh the picker
        local current_picker = action_state.get_current_picker(prompt_bufnr)
        current_picker:refresh(finders.new_table {
          results = entries,
          entry_maker = function(entry)
            return {
              value = entry.id,
              display = entry.display,
              ordinal = entry.display,
            }
          end
        }, { reset_prompt = false })
        
        -- Send to Claude
        send_to_claude(prompt, entry_id)
        
        -- Clear the prompt
        vim.api.nvim_buf_set_lines(prompt_bufnr, 0, -1, false, {""})
      end
      
      -- Insert code from selected response
      local function insert_code()
        local selection = action_state.get_selected_entry()
        if not selection then
          print("No response selected")
          return
        end
        
        local response = claude_state.responses[selection.value]
        if not response or not response.response then
          print("No response available")
          return
        end
        
        actions.close(prompt_bufnr)
        
        -- Extract code blocks
        local blocks = extract_code_blocks(response.response)
        
        if #blocks == 0 then
          print("No code blocks found in response")
          return
        end
        
        local code_to_insert
        if #blocks == 1 then
          code_to_insert = blocks[1].code
        else
          -- Let user choose which block
          local choices = {}
          for i, block in ipairs(blocks) do
            local preview = block.code:match("^(.-)\n") or block.code
            local lang = block.language or "unknown"
            table.insert(choices, string.format("%d. [%s] %s", i, lang, preview:sub(1, 40)))
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
          -- Insert at cursor
          local lines = {}
          for line in code_to_insert:gmatch("([^\n]*)\n?") do
            table.insert(lines, line)
          end
          
          -- Remove empty line at end if present
          if lines[#lines] == "" then
            table.remove(lines)
          end
          
          local row, col = unpack(vim.api.nvim_win_get_cursor(0))
          vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, lines)
        end
      end
      
      -- Copy response to clipboard
      local function copy_response()
        local selection = action_state.get_selected_entry()
        if not selection then
          print("No response selected")
          return
        end
        
        local response = claude_state.responses[selection.value]
        if not response or not response.response then
          print("No response available")
          return
        end
        
        vim.fn.setreg('+', response.response)
        print("Response copied to clipboard")
      end
      
      -- Key mappings
      map('i', '<CR>', submit_prompt)
      map('n', '<CR>', submit_prompt)
      map('n', '<C-i>', insert_code)
      map('i', '<C-i>', insert_code)
      map('n', '<C-y>', copy_response)
      map('i', '<C-y>', copy_response)
      
      -- Keep default actions
      return true
    end,
  }):find()
end

-- Debug function to test Claude command
function M.test_claude_command()
  print("=== CLAUDE DEBUG TEST ===")
  
  -- Test 1: Synchronous system call
  print("\n1. Testing synchronous system call...")
  local echo_result = vim.fn.system("echo hello")
  print("System echo result:", vim.inspect(echo_result))
  
  -- Test 2: Test systemlist
  print("\n2. Testing systemlist...")
  local echo_list = vim.fn.systemlist("echo hello")
  print("Systemlist echo result:", vim.inspect(echo_list))
  
  -- Test 3: Test Claude with system
  print("\n3. Testing Claude with system call...")
  local claude_result = vim.fn.system("/opt/homebrew/bin/claude --help")
  print("Claude help result length:", string.len(claude_result))
  print("Claude help first 100 chars:", string.sub(claude_result, 1, 100))
  
  -- Test 4: Test simple Claude command
  print("\n4. Testing simple Claude command...")
  local simple_claude = vim.fn.system("/opt/homebrew/bin/claude --print hello")
  print("Simple Claude result:", vim.inspect(simple_claude))
  
  -- Test 5: Test full Claude command
  print("\n5. Testing full Claude command...")
  local full_claude = vim.fn.system("/opt/homebrew/bin/claude --print --model sonnet 'Say test successful'")
  print("Full Claude result:", vim.inspect(full_claude))
  
  -- Test 6: Async job with immediate print
  print("\n6. Testing async job...")
  print("About to start job...")
  local job_id = vim.fn.jobstart({"echo", "async test"}, {
    on_stdout = function(_, data, _)
      print("ASYNC CALLBACK TRIGGERED!")
      print("Data:", vim.inspect(data))
    end,
    on_exit = function(_, exit_code, _)
      print("ASYNC EXIT TRIGGERED!")
      print("Exit code:", exit_code)
    end
  })
  print("Job started with ID:", job_id)
  
  -- Force a redraw to see if that helps
  vim.cmd("redraw")
end

-- Setup function
function M.setup(opts)
  M.config = vim.tbl_extend("force", M.config, opts or {})
end

return M