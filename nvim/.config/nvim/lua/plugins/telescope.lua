return { 
  'nvim-telescope/telescope.nvim',  
  tag = 'v0.2.0', 
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    local builtin = require("telescope.builtin")
    vim.keymap.set('n', '<C-t>', builtin.find_files, {}) -- fuzzy search to find files in our project
    vim.keymap.set('n', '<leader>fg', builtin.live_grep, {}) -- find  grep through our project
  end
}
