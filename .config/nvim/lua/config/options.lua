vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.mouse = "a"
opt.clipboard = "unnamedplus"
opt.breakindent = true
opt.undofile = true
opt.ignorecase = true
opt.smartcase = true
opt.signcolumn = "yes"
opt.updatetime = 250
opt.timeoutlen = 300
opt.splitright = true
opt.splitbelow = true
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.inccommand = "split"
opt.scrolloff = 8
opt.termguicolors = true
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.wrap = false
opt.cursorline = true

-- Comentarios (gc / gcc) son nativos desde Neovim 0.10, no hace falta plugin.

local state = vim.fn.stdpath("state")
opt.backupdir = state .. "/backup//"
opt.directory = state .. "/swap//"
opt.undodir = state .. "/undo//"
