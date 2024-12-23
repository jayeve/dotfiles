local opt = vim.opt -- for conciseness

-- line numbers
opt.relativenumber = true -- show relative line numbers
opt.number = true -- shows absolute line number on cursor line (when relative number is on)

-- tabs & indentation
opt.tabstop = 2 -- 2 spaces for tabs (prettier default)
opt.shiftwidth = 2 -- 2 spaces for indent width
opt.expandtab = true -- expand tab to spaces
opt.autoindent = true -- copy indent from current line when starting new one

expandtab = true

-- line wrapping
opt.wrap = false -- disable line wrapping

-- for obsidian.nvim
opt.conceallevel = 0

-- search settings
opt.ignorecase = true -- ignore case when searching
opt.smartcase = true -- if you include mixed case in your search, assumes you want case-sensitive

-- cursor line
opt.cursorline = true -- highlight the current cursor line

-- appearance

-- turn on termguicolors for nightfly colorscheme to work
-- (have to use iterm2 or any other true color terminal)
opt.termguicolors = true
opt.background = "dark" -- colorschemes that can be light or dark will be made dark
opt.signcolumn = "yes" -- show sign column so that text doesn't shift

-- backspace
opt.backspace = "indent,eol,start" -- allow backspace on indent, end of line or insert mode start position

-- clipboard
opt.clipboard:append("unnamedplus") -- use system clipboard as default register

-- split windows
opt.splitbelow = true -- split horizontal window to the bottom
opt.splitright = true

opt.iskeyword:append("-") -- consider string-string as whole word

vim.cmd([[
  autocmd BufRead * autocmd FileType <buffer> ++once
    \ if &ft !~# 'commit\|rebase' && line("'\"") > 1 && line("'\"") <= line("$") | exe 'normal! g`"' | endif
]])

-- keep vim history after closing
vim.cmd([[
  if has('persistent_undo')
    silent !mkdir ~/.config/nvim/backups > /dev/null 2>&1
    set undodir=~/.config/nvim/backups
    set undofile
  endif
]])

-- no swapfiles
vim.cmd([[set noswapfile]])

-- highlight trailing whitespace
vim.cmd([[highlight ExtraWhitespace ctermbg=red guibg=red]])
vim.cmd([[match ExtraWhitespace /\s\+$/]])
vim.api.nvim_create_augroup("TrailingWhitespace", { clear = true })
vim.api.nvim_create_autocmd({ "BufWinEnter", "InsertLeave" }, {
	group = "TrailingWhitespace",
	pattern = "*",
	command = "match ExtraWhitespace /\\s\\+$/",
})
vim.api.nvim_create_autocmd("InsertEnter", {
	group = "TrailingWhitespace",
	pattern = "*",
	command = "match ExtraWhitespace /\\s\\+\\%#\\@<!$/",
})
