local map = vim.keymap.set

map("i", "jk", "<Esc>", { desc = "Salir a modo normal" })
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Guardar" })
map("n", "<leader>q", "<cmd>q<cr>", { desc = "Cerrar ventana" })
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Quitar resaltado de búsqueda" })

map("n", "<C-h>", "<C-w>h", { desc = "Ventana izquierda" })
map("n", "<C-j>", "<C-w>j", { desc = "Ventana abajo" })
map("n", "<C-k>", "<C-w>k", { desc = "Ventana arriba" })
map("n", "<C-l>", "<C-w>l", { desc = "Ventana derecha" })

map("v", "<", "<gv", { desc = "Indentar izquierda (mantiene selección)" })
map("v", ">", ">gv", { desc = "Indentar derecha (mantiene selección)" })

map("n", "<leader>e", "<cmd>Ex<cr>", { desc = "Explorador de archivos (netrw)" })
