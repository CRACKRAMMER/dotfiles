vim.g.mapleader = " "

local keymap = vim.keymap

keymap.set("n","<leader>q","<Cmd>q<CR>");
keymap.set("n","<leader>Q","<Cmd>qall<CR>");
keymap.set("n","<leader>w","<Cmd>w<CR>");
keymap.set("n","<leader>W","<Cmd>wall<CR>");
keymap.set("n","<leader>x","<Cmd>x<CR>");
keymap.set("n","<leader>X","<Cmd>xall<CR>");
keymap.set("n","T","<cmd>tabnew<CR>")

keymap.set("n",";","<C-w>w")
keymap.set("n","<C-a>","gg<S-v>G");

keymap.set("n","<left>","<C-w><")
keymap.set("n","<right>","<C-w>>")
keymap.set("n","<up>","<C-w>+")
keymap.set("n","<down>","<C-w>-")

keymap.set("t","<ESC>","<C-\\><C-n>");
keymap.set("n","<leader>tt",":split<Return>:terminal<Return>",{silent = true});

keymap.set("v", "J", ":m '>+1<CR>gv=gv")
keymap.set("v", "K", ":m '<-2<CR>gv=gv")

keymap.set("n", "<leader>sv", "<C-w>v")
keymap.set("n", "<leader>sh", "<C-w>s")
keymap.set("n","<leader>sh","<C-w>h")
keymap.set("n","<leader>sj","<C-w>j")
keymap.set("n","<leader>sk","<C-w>k")
keymap.set("n","<leader>sl","<C-w>l")

keymap.set("n", "<leader>nh", ":nohl<CR>")

keymap.set("n", "<C-L>", ":bnext<CR>")
keymap.set("n", "<C-H>", ":bprevious<CR>")

keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>")
