local o = vim.o
local g = vim.g

o.wildignore = '*.pyc,.*,*/node_modules/*,*/__pycache__/*,*/venv/*'
g.ctrlp_max_files = 0
g.ctrlp_prompt_mappings = {
 'PrtClearCache()' = ['<c-t>']
}
