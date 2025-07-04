local M = {}

local telescope = require('telescope')
local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local previewers = require('telescope.previewers')
local utils = require('telescope.utils')

-- Function to get git diff for a file
local function get_file_diff(file)
    local cmd = string.format("git diff HEAD -- %s", vim.fn.shellescape(file))
    local diff = vim.fn.system(cmd)
    if vim.v.shell_error ~= 0 then
        cmd = string.format("git diff --cached -- %s", vim.fn.shellescape(file))
        diff = vim.fn.system(cmd)
    end
    return vim.split(diff, '\n')
end

-- Function to get list of changed files
local function get_changed_files()
    -- Get both staged and unstaged changes
    local staged = vim.fn.system("git diff --cached --name-only")
    local unstaged = vim.fn.system("git diff --name-only")
    
    local files = {}
    local seen = {}
    
    -- Add staged files
    for _, file in ipairs(vim.split(staged, '\n')) do
        if file ~= "" and not seen[file] then
            table.insert(files, {file = file, status = "staged"})
            seen[file] = true
        end
    end
    
    -- Add unstaged files
    for _, file in ipairs(vim.split(unstaged, '\n')) do
        if file ~= "" and not seen[file] then
            table.insert(files, {file = file, status = "modified"})
            seen[file] = true
        end
    end
    
    return files
end

-- Custom previewer for git diffs
local function diff_previewer(opts)
    return previewers.new_buffer_previewer {
        title = "Git Diff",
        get_buffer_by_name = function(_, entry)
            return entry.value
        end,
        define_preview = function(self, entry)
            -- Wrap in pcall to catch any errors
            local ok, diff = pcall(get_file_diff, entry.value)
            if not ok then
                vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, {"Error getting diff: " .. tostring(diff)})
                return
            end
            
            -- Ensure we have valid content
            if type(diff) ~= "table" then
                diff = {"No diff available"}
            end
            
            -- Use schedule to avoid async issues
            vim.schedule(function()
                if vim.api.nvim_buf_is_valid(self.state.bufnr) then
                    vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, diff)
                    vim.api.nvim_buf_set_option(self.state.bufnr, 'filetype', 'diff')
                end
            end)
        end
    }
end

-- Main code review picker
function M.review_changes(opts)
    opts = opts or {}
    
    local changed_files = get_changed_files()
    
    if #changed_files == 0 then
        vim.notify("No changes to review", vim.log.levels.INFO)
        return
    end
    
    pickers.new(opts, {
        prompt_title = "Code Review - Changed Files",
        finder = finders.new_table {
            results = changed_files,
            entry_maker = function(entry)
                local display = string.format("%-10s %s", "[" .. entry.status .. "]", entry.file)
                return {
                    value = entry.file,
                    display = display,
                    ordinal = entry.file,
                    status = entry.status,
                }
            end
        },
        sorter = conf.file_sorter(opts),
        previewer = diff_previewer(opts),
        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                if selection then
                    actions.close(prompt_bufnr)
                    -- Open the file in a split
                    vim.cmd('vsplit ' .. selection.value)
                    -- Open fugitive's Gdiff for side-by-side comparison
                    vim.cmd('Gdiffsplit')
                end
            end)
            
            -- Add mapping to stage/unstage files
            map('i', '<C-s>', function()
                local selection = action_state.get_selected_entry()
                if selection then
                    if selection.status == "staged" then
                        vim.fn.system("git reset HEAD " .. vim.fn.shellescape(selection.value))
                        vim.notify("Unstaged: " .. selection.value)
                    else
                        vim.fn.system("git add " .. vim.fn.shellescape(selection.value))
                        vim.notify("Staged: " .. selection.value)
                    end
                    -- Refresh the picker
                    actions.close(prompt_bufnr)
                    M.review_changes(opts)
                end
            end)
            
            -- Add mapping to checkout file (discard changes)
            map('i', '<C-x>', function()
                local selection = action_state.get_selected_entry()
                if selection then
                    local confirm = vim.fn.confirm("Discard changes to " .. selection.value .. "?", "&Yes\n&No", 2)
                    if confirm == 1 then
                        vim.fn.system("git checkout -- " .. vim.fn.shellescape(selection.value))
                        vim.notify("Discarded changes: " .. selection.value)
                        actions.close(prompt_bufnr)
                        M.review_changes(opts)
                    end
                end
            end)
            
            return true
        end,
    }):find()
end

-- Review commits picker
function M.review_commits(opts)
    opts = opts or {}
    
    pickers.new(opts, {
        prompt_title = "Code Review - Recent Commits",
        finder = finders.new_oneshot_job({
            "git", "log", "--pretty=format:%h %s (%cr) <%an>", "--abbrev-commit", "-30"
        }, opts),
        sorter = conf.generic_sorter(opts),
        previewer = previewers.new_buffer_previewer {
            title = "Commit Details",
            get_buffer_by_name = function(_, entry)
                return entry.value
            end,
            define_preview = function(self, entry)
                vim.schedule(function()
                    if not vim.api.nvim_buf_is_valid(self.state.bufnr) then
                        return
                    end
                    
                    local commit_hash = entry.value:match("^(%w+)")
                    if not commit_hash then
                        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, {"Invalid commit format"})
                        return
                    end
                    
                    local cmd = string.format("git show --color=never %s", commit_hash)
                    local result = vim.fn.system(cmd)
                    local lines = vim.split(result, '\n')
                    
                    if vim.api.nvim_buf_is_valid(self.state.bufnr) then
                        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
                        vim.api.nvim_buf_set_option(self.state.bufnr, 'filetype', 'diff')
                    end
                end)
            end
        },
        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                if selection then
                    local commit_hash = selection.value:match("^(%w+)")
                    actions.close(prompt_bufnr)
                    -- Show commit in fugitive
                    vim.cmd('Git show ' .. commit_hash)
                end
            end)
            
            -- Add mapping to compare with current branch
            map('i', '<C-d>', function()
                local selection = action_state.get_selected_entry()
                if selection then
                    local commit_hash = selection.value:match("^(%w+)")
                    actions.close(prompt_bufnr)
                    vim.cmd('Git difftool ' .. commit_hash .. ' HEAD')
                end
            end)
            
            return true
        end,
    }):find()
end

-- Review branch differences
function M.review_branch_diff(opts)
    opts = opts or {}
    local base_branch = opts.base or "main"
    
    -- Get files changed between current branch and base
    local cmd = string.format("git diff --name-only %s...HEAD", base_branch)
    local changed_files_raw = vim.fn.system(cmd)
    
    if vim.v.shell_error ~= 0 then
        vim.notify("Error getting branch differences. Is '" .. base_branch .. "' a valid branch?", vim.log.levels.ERROR)
        return
    end
    
    local changed_files = vim.split(changed_files_raw, '\n')
    changed_files = vim.tbl_filter(function(file) return file ~= "" end, changed_files)
    
    if #changed_files == 0 then
        vim.notify("No differences with " .. base_branch, vim.log.levels.INFO)
        return
    end
    
    pickers.new(opts, {
        prompt_title = string.format("Branch Diff: %s...HEAD", base_branch),
        finder = finders.new_table {
            results = changed_files,
        },
        sorter = conf.file_sorter(opts),
        previewer = previewers.new_buffer_previewer {
            title = "Branch Diff",
            get_buffer_by_name = function(_, entry)
                return entry.value
            end,
            define_preview = function(self, entry)
                vim.schedule(function()
                    if not vim.api.nvim_buf_is_valid(self.state.bufnr) then
                        return
                    end
                    
                    local cmd = string.format("git diff %s...HEAD -- %s", base_branch, vim.fn.shellescape(entry.value))
                    local diff = vim.fn.system(cmd)
                    local lines = vim.split(diff, '\n')
                    
                    if vim.api.nvim_buf_is_valid(self.state.bufnr) then
                        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
                        vim.api.nvim_buf_set_option(self.state.bufnr, 'filetype', 'diff')
                    end
                end)
            end
        },
        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                if selection then
                    actions.close(prompt_bufnr)
                    vim.cmd('edit ' .. selection.value)
                    vim.cmd('Gdiffsplit ' .. base_branch .. ':' .. selection.value)
                end
            end)
            return true
        end,
    }):find()
end

return M