local home = os.getenv("HOME")
local jdtls = require("jdtls")

-- File types that signify a Java project's root directory. This will be
-- used by eclipse to determine what constitutes a workspace
local root_markers = { "gradlew", "mvnw", ".git" }
local root_dir = require("jdtls.setup").find_root(root_markers)

-- eclipse.jdt.ls stores project specific data within a folder. If you are working
-- with multiple different projects, each project must use a dedicated data directory.
-- This variable is used to configure eclipse to use the directory name of the
-- current project found using the root_marker as the folder for project specific data.
local workspace_folder = home .. "/.local/share/eclipse/" .. vim.fn.fnamemodify(root_dir, ":p:h:t")

-- Helper function for creating keymaps
function nnoremap(rhs, lhs, bufopts, desc)
	bufopts.desc = desc
	vim.keymap.set("n", rhs, lhs, bufopts)
end

-- The on_attach function is used to set key maps after the language server
-- attaches to the current buffer
local on_attach = function(client, bufnr)
	-- Regular Neovim LSP client keymappings
	local bufopts = { noremap = true, silent = true, buffer = bufnr }
	nnoremap("gD", vim.lsp.buf.declaration, bufopts, "Go to declaration")
	nnoremap("gd", vim.lsp.buf.definition, bufopts, "Go to definition")
	nnoremap("gi", vim.lsp.buf.implementation, bufopts, "Go to implementation")
	nnoremap("K", vim.lsp.buf.hover, bufopts, "Hover text")
	nnoremap("<C-k>", vim.lsp.buf.signature_help, bufopts, "Show signature")
	nnoremap("<space>wa", vim.lsp.buf.add_workspace_folder, bufopts, "Add workspace folder")
	nnoremap("<space>wr", vim.lsp.buf.remove_workspace_folder, bufopts, "Remove workspace folder")
	nnoremap("<space>wl", function()
		print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
	end, bufopts, "List workspace folders")
	nnoremap("<space>D", vim.lsp.buf.type_definition, bufopts, "Go to type definition")
	nnoremap("<space>rn", vim.lsp.buf.rename, bufopts, "Rename")
	nnoremap("<space>ca", vim.lsp.buf.code_action, bufopts, "Code actions")
	vim.keymap.set(
		"v",
		"<space>ca",
		"<ESC><CMD>lua vim.lsp.buf.range_code_action()<CR>",
		{ noremap = true, silent = true, buffer = bufnr, desc = "Code actions" }
	)
	nnoremap("<space>f", function()
		vim.lsp.buf.format({ async = true })
	end, bufopts, "Format file")

	-- Java extensions provided by jdtls
	nnoremap("<C-o>", jdtls.organize_imports, bufopts, "Organize imports")
	nnoremap("<space>ev", jdtls.extract_variable, bufopts, "Extract variable")
	nnoremap("<space>ec", jdtls.extract_constant, bufopts, "Extract constant")
	vim.keymap.set(
		"v",
		"<space>em",
		[[<ESC><CMD>lua require('jdtls').extract_method(true)<CR>]],
		{ noremap = true, silent = true, buffer = bufnr, desc = "Extract method" }
	)
end

local config = {
	flags = {
		debounce_text_changes = 80,
	},
	on_attach = on_attach, -- We pass our on_attach keybindings to the configuration map
	root_dir = root_dir, -- Set the root directory to our found root_marker
	-- Here you can configure eclipse.jdt.ls specific settings
	-- These are defined by the eclipse.jdt.ls project and will be passed to eclipse when starting.
	-- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
	-- for a list of options
	settings = {
		java = {
			format = {
				settings = {
					-- Use Google Java style guidelines for formatting
					-- To use, make sure to download the file from https://github.com/google/styleguide/blob/gh-pages/eclipse-java-google-style.xml
					-- and place it in the ~/.local/share/eclipse directory
					url = "/.local/share/eclipse/eclipse-java-google-style.xml",
					profile = "GoogleStyle",
				},
			},
			signatureHelp = { enabled = true },
			contentProvider = { preferred = "fernflower" }, -- Use fernflower to decompile library code
			-- Specify any completion options
			completion = {
				favoriteStaticMembers = {
					"org.hamcrest.MatcherAssert.assertThat",
					"org.hamcrest.Matchers.*",
					"org.hamcrest.CoreMatchers.*",
					"org.junit.jupiter.api.Assertions.*",
					"java.util.Objects.requireNonNull",
					"java.util.Objects.requireNonNullElse",
					"org.mockito.Mockito.*",
				},
				filteredTypes = {
					"com.sun.*",
					"io.micrometer.shaded.*",
					"java.awt.*",
					"jdk.*",
					"sun.*",
				},
			},
			-- Specify any options for organizing imports
			sources = {
				organizeImports = {
					starThreshold = 9999,
					staticStarThreshold = 9999,
				},
			},
			-- How code generation should act
			codeGeneration = {
				toString = {
					template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
				},
				hashCodeEquals = {
					useJava7Objects = true,
				},
				useBlocks = true,
			},
			-- If you are developing in projects with different Java versions, you need
			-- to tell eclipse.jdt.ls to use the location of the JDK for your Java version
			-- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
			-- And search for `interface RuntimeOption`
			-- The `name` is NOT arbitrary, but must match one of the elements from `enum ExecutionEnvironment` in the link above
			configuration = {
				runtimes = {
					{
						name = "JavaSE-17",
						path = "/usr/lib/jvm/jdk-17-oracle-x64",
					},
				},
			},
		},
	},
	-- cmd is the command that starts the language server. Whatever is placed
	-- here is what is passed to the command line to execute jdtls.
	-- Note that eclipse.jdt.ls must be started with a Java version of 17 or higher
	-- See: https://github.com/eclipse/eclipse.jdt.ls#running-from-the-command-line
	-- for the full list of options
	cmd = {
		"/opt/java-17-openjdk-17.0.9.0.9-1.portable.jdk.el.x86_64",
		"-Declipse.application=org.eclipse.jdt.ls.core.id1",
		"-Dosgi.bundles.defaultStartLevel=4",
		"-Declipse.product=org.eclipse.jdt.ls.core.product",
		"-Dlog.protocol=true",
		"-Dlog.level=ALL",
		"-Xmx4g",
		"--add-modules=ALL-SYSTEM",
		"--add-opens",
		"java.base/java.util=ALL-UNNAMED",
		"--add-opens",
		"java.base/java.lang=ALL-UNNAMED",
		-- If you use lombok, download the lombok jar and place it in ~/.local/share/eclipse
		"-javaagent:"
			.. home
			.. "/home/doffy/eclipse/jee-2023-09/eclipse/plugins/lombok.jar",
		-- The jar file is located where jdtls was installed. This will need to be updated
		-- to the location where you installed jdtls
		"-jar",
		vim.fn.glob(
			"/home/linuxbrew/.linuxbrew/Cellar/jdtls/1.29.0/libexec/plugins/org.eclipse.equinox.launcher_*.jar"
		),

		-- The configuration for jdtls is also placed where jdtls was installed. This will
		-- need to be updated depending on your environment
		"-configuration",
		"/home/linuxbrew/.linuxbrew/Cellar/jdtls/1.29.0/libexec/config_linux",

		-- Use the workspace_folder defined above to store data for this project
		"-data",
		workspace_folder,
	},
}

-- Finally, start jdtls. This will run the language server using the configuration we specified,
-- setup the keymappings, and attach the LSP client to the current buffer
jdtls.start_or_attach(config)

local fn = vim.fn

-- Automatically install packer
local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
if fn.empty(fn.glob(install_path)) > 0 then
	PACKER_BOOTSTRAP =
		fn.system({ "git", "clone", "--depth", "1", "https://github.com/wbthomason/packer.nvim", install_path })
	print("Installing packer close and reopen Neovim...")
end

-- Autocommand that reloads neovim whenever you save the plugins.lua file
vim.cmd([[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerSync
  augroup end
]])

-- Use a protected call so we don't error out on first use
local status_ok, packer = pcall(require, "packer")
if not status_ok then
	return
end

-- Have packer use a popup window
packer.init({
	display = {
		open_fn = function()
			return require("packer.util").float({ border = "single" })
		end,
	},
})

local null_ls = require("null-ls")

local group = vim.api.nvim_create_augroup("lsp_format_on_save", { clear = false })
local event = "BufWritePre" -- or "BufWritePost"
local async = event == "BufWritePost"

null_ls.setup({
	on_attach = function(client, bufnr)
		if client.supports_method("textDocument/formatting") then
			vim.keymap.set("n", "<Leader>f", function()
				vim.lsp.buf.format({ bufnr = vim.api.nvim_get_current_buf() })
			end, { buffer = bufnr, desc = "[lsp] format" })

			-- format on save
			vim.api.nvim_clear_autocmds({ buffer = bufnr, group = group })
			vim.api.nvim_create_autocmd(event, {
				buffer = bufnr,
				group = group,
				callback = function()
					vim.lsp.buf.format({ bufnr = bufnr, async = async })
				end,
				desc = "[lsp] format on save",
			})
		end

		if client.supports_method("textDocument/rangeFormatting") then
			vim.keymap.set("x", "<Leader>f", function()
				vim.lsp.buf.format({ bufnr = vim.api.nvim_get_current_buf() })
			end, { buffer = bufnr, desc = "[lsp] format" })
		end
	end,
})

-- Install your plugins here
return packer.startup(function(use)
	-- My plugins here
	use("wbthomason/packer.nvim") -- Have packer manage itself
	use("nvim-lua/popup.nvim") -- An implementation of the Popup API from vim in Neovim
	use("nvim-lua/plenary.nvim") -- Useful lua functions used ny lots of plugins
	use("williamboman/mason.nvim")

	use("mfussenegger/nvim-dap")
	use("mfussenegger/nvim-jdtls")
	use("nvim-lua/plenary.nvim")
	use({
		"numToStr/Comment.nvim",
		config = function()
			require("Comment").setup({
				---Add a space b/w comment and the line
				padding = true,
				---Whether the cursor should stay at its position
				sticky = true,
				---Lines to be ignored while (un)comment
				ignore = nil,
				---LHS of toggle mappings in NORMAL mode
				toggler = {
					---Line-comment toggle keymap
					line = "gcc",
					---Block-comment toggle keymap
					block = "gbc",
				},
				---LHS of operator-pending mappings in NORMAL and VISUAL mode
				opleader = {
					---Line-comment keymap
					line = "gc",
					---Block-comment keymap
					block = "gb",
				},
				---LHS of extra mappings
				extra = {
					---Add comment on the line above
					above = "gcO",
					---Add comment on the line below
					below = "gco",
					---Add comment at the end of line
					eol = "gcA",
				},
				---Enable keybindings
				---NOTE: If given `false` then the plugin won't create any mappings
				mappings = {
					---Operator-pending mapping; `gcc` `gbc` `gc[count]{motion}` `gb[count]{motion}`
					basic = true,
					---Extra mapping; `gco`, `gcO`, `gcA`
					extra = true,
				},
				---Function to call before (un)comment
				pre_hook = nil,
				---Function to call after (un)comment
				post_hook = nil,
			})
		end,
	})

	-- Lua
	use("gbprod/yanky.nvim")
	require("yanky").setup({
		-- your configuration comes here
		-- or leave it empty to use the default settings
		-- refer to the configuration section below
		ring = {
				history_length = 100,
				storage = "shada",
				storage_path = vim.fn.stdpath("data") .. "/databases/yanky.db", -- Only for sqlite storage
				sync_with_numbered_registers = true,
				cancel_event = "update",
				ignore_registers = { "_" },
				update_register_on_cycle = false,
			},
			picker = {
				select = {
					action = nil, -- nil to use default put action
				},
				telescope = {
					use_default_mappings = true, -- if default mappings should be used
					mappings = nil, -- nil to use default mappings or no mappings (see `use_default_mappings`)
				},
			},
			system_clipboard = {
				sync_with_ring = true,
			},
			highlight = {
				on_put = true,
				on_yank = true,
				timer = 500,
			},
			preserve_cursor_position = {
				enabled = true,
			},
			textobj = {
				enabled = true,
			},
	})

	-- Automatically set up your configuration after cloning packer.nvim
	-- Put this at the end after all plugins
	if PACKER_BOOTSTRAP then
		require("packer").sync()
	end
end)
