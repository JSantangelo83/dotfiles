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
}


 return plugins
