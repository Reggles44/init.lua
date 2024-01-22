return  {

  {
    "folke/tokyonight.nvim",
    config = function()
      require("tokyonight").setup({
        style = "storm",
        terminal_colors = true,
        styles = {
          comments = { italic = false },
          keywords = { italic = false },

          sidebars = "dark",
          floats = "dark",
        }

      })
    end
  },

  {

    'rose-pine/neovim',
    name = 'rose-pine',
    config = function() 
      vim.cmd("colorscheme rose-pine"); 
    end
  }
} 
