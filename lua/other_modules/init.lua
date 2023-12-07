require('other_modules.plugins') -- loads other_modules/init.lua
require('other_modules.plugins1')
-- require('other_modules.cplusplus_lsp_config')

-- require('neovim-pde.lua.pde.cpp')

require("mason").setup({
    ui = {
        icons = {
           package_installed = "",
           package_pending = "->",
           package_uninstaled = "x"
        }
    }
})

require('pde.java')

local prettier = require("prettier")

prettier.setup({
  bin = 'prettier', -- or `'prettierd'` (v0.23.3+)
  filetypes = {
    "css",
    "graphql",
    "html",
    "javascript",
    "javascriptreact",
    "json",
    "less",
    "markdown",
    "scss",
    "typescript",
    "typescriptreact",
    "yaml",
  },
})



require('mini.files').setup()
