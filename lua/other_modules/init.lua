require('other_modules.plugins') -- loads other_modules/init.lua
require('other_modules.plugins1')
-- require('other_modules.cplusplus_lsp_config')

require("mason").setup({
    ui = {
        icons = {
           package_installed = "",
           package_pending = "->",
           package_uninstaled = "x"
        }
    }
})
