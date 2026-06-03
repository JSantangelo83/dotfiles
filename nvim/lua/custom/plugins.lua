local plugins={
  {
    'williamboman/mason.nvim',
    opts = {
     ensure_installed = {
       'pyright',
      }
    }
  },
  {
    'max397574/better-escape.nvim',
    lazy = false,
    config = function()
    require("better_escape").setup()
    end,
  },
  {
    'phaazon/hop.nvim',
    lazy=false,
    as = 'hop',
  config = function()
    -- you can configure Hop the way you like here; see :h hop-config
    require'hop'.setup { keys = 'etovxqpdygfblzhckisuran' }
  end
  },
  {
  "neovim/nvim-lspconfig",
   dependencies = {
     "jose-elias-alvarez/null-ls.nvim",
     config = function()
       require "custom.configs.null-ls"
     end,
   },
   config = function()
    require "plugins.configs.lspconfig"
    require "custom.configs.lspconfig"
     end,
  },
  {
    "ThePrimeagen/harpoon",
    dependencies = {"nvim-lua/plenary.nvim"},
    lazy = false,
    config = function ()
      vim.keymap.set("n", "<leader>a", '<cmd>lua require("harpoon.mark").add_file()<CR>', { noremap = true})
      vim.keymap.set("n", "<C-e>", '<cmd>lua require("harpoon.ui").toogle_quick_menu()<CR>', { noremap = true})
      vim.keymap.set("n", "<C-h>", '<cmd>lua require("harpoon.ui").nav_file(1)<CR>', { noremap = true})
      vim.keymap.set("n", "<C-j>", '<cmd>lua require("harpoon.ui").nav_file(2)<CR>', { noremap = true})
      vim.keymap.set("n", "<C-k>", '<cmd>lua require("harpoon.ui").nav_file(3)<CR>', { noremap = true})
      vim.keymap.set("n", "<C-l>", '<cmd>lua require("harpoon.ui").nav_file(4)<CR>', { noremap = true})
    end
  }, {
    "justinmk/vim-sneak",
    lazy = false
  }
}


 return plugins
