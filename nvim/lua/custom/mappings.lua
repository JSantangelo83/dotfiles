local M = {}

M.disabled = {
    n = {
    ["<C-n>"] = "",
    ["<leader>e"] = "",
    ["<leader>ff"] = "",
    ["<leader>rn"] = "",
    ["<leader>n"] = "",
    ["<leader>x"] = "",
  }
}

M.general = {
  n = {
    ["<leader>n"] = { "<cmd> set rnu! <CR>", "Toggle line number" },
    ["<C-q>"] = { "<cmd> q <CR>", "Close File" },
  }
}

M.hoop = {
  n = {
    ["$"]= {"<cmd>lua require'hop'.hint_words()<cr>", "Hop"},
  },
}

M.nvimtree = {
  plugin = true,
  n = {
    -- toggle
    ["<C-t>"] = { "<cmd> NvimTreeToggle <CR>", "Toggle nvimtree" },
    -- focus
    ["<C-0>"] = { "<cmd> NvimTreeFocus <CR>", "Focus nvimtree" },
  },
}

M.telescope = {
  plugin = true,

  n = {
    -- find
    ["<C-p>"] = { "<cmd> Telescope find_files <CR>", "Find files" },
  },
}

M.tabufline = {
  plugin = true;

  n={
    ["<C-w>"] = {
      function()
        require("nvchad.tabufline").close_buffer()
      end,
      "Close buffer",
    },
  }
}

return M;
