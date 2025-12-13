return { 
  "nvim-treesitter/nvim-treesitter", 
  branch = 'master', 
  lazy = false, 
  build = ":TSUpdate",
  config = function()
    local config = require("nvim-treesitter.configs")
    config.setup({
      ensure_installed = {"lua", "javascript"},
      indent = { enable = true },
      highlight = { enable = true }
    })
  end
}
