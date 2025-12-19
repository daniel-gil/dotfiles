return {
  {
    "mason-org/mason.nvim",
    opts = {},
    config = function() 
      require("mason").setup()
    end
  },
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {},
    dependencies = {
      { 
          "mason-org/mason.nvim", 
          opts = {}
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
--      require("mason-lspconfig").setup {
 --       ensure_installed = { "lua_ls", "csharp_ls" },
 --     }

      -- Load nvim-lspconfig configs
--      require('lspconfig').lua_ls.setup({})
  
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, {})
    end
  },
}
