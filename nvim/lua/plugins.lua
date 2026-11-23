-- bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- setup lazy.nvim plugins
require("lazy").setup({
	spec = {
		-- theme
		{
			"navarasu/onedark.nvim",
			priority = 1000,
			config = function()
				require("onedark").setup { style = "cool" }
				require("onedark").load()
			end,
		},

		-- utilities
		{
			"keaising/im-select.nvim",
			cond = vim.fn.has("mac") == 1,
			main = "im_select",
			opts = {
				default_command = "macism",
				default_im_select = "com.apple.keylayout.ABC",
				set_default_events = { "VimEnter", "InsertLeave", "CmdlineLeave" },
			},
		},
		{
			"nmac427/guess-indent.nvim",
			config = function()
				require("guess-indent").setup {}
			end,
		},
		{
			"nvim-treesitter/nvim-treesitter",
			build = ":TSUpdate",
			opts = {
				ensure_installed = { "c", "lua", "vim", "vimdoc", "markdown" },
				sync_install = false,
				auto_install = true,
				highlight = { enable = true },
			},
		},
		{
			"nvim-treesitter/nvim-treesitter-context",
			dependencies = { "nvim-treesitter/nvim-treesitter" },
			config = function()
				require("treesitter-context").setup {}
			end,
		},
		{
			"crispgm/nvim-tabline",
			config = function()
				require("tabline").setup {}
			end,
		},

		-- LSP
		{ "neovim/nvim-lspconfig" },
		{ "williamboman/mason.nvim" },
		{ "williamboman/mason-lspconfig.nvim" },

		-- telescope
		{
			"nvim-telescope/telescope.nvim",
			dependencies = { "nvim-lua/plenary.nvim" },
			config = function()
				local builtin = require("telescope.builtin")
				vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
				vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
				vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
				vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})
			end,
		},

		-- git
		{
			"lewis6991/gitsigns.nvim",
			config = function()
				require("gitsigns").setup {}
			end,
		},
	},

	-- Automatically check for plugin updates
	checker = { enabled = true },
})

-- telescope preview line numbers
vim.api.nvim_create_autocmd("User", {
	pattern = "TelescopePreviewerLoaded",
	callback = function()
		vim.wo.number = true
	end,
})

-- global diagnostic keymaps
local opts = { noremap = true, silent = true }
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, opts)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, opts)

-- LSP keymaps through LspAttach
local lsp_group = vim.api.nvim_create_augroup('MyLspConfig', { clear = true })

vim.api.nvim_create_autocmd('LspAttach', {
	group = lsp_group,
	callback = function(args)
		local bufnr = args.buf
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if not client then return end

		local cbopts = { buffer = bufnr, noremap = true, silent = true }

		-- Navigation
		vim.keymap.set('n', 'gd', vim.lsp.buf.definition, cbopts)
		vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, cbopts)
		vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, cbopts)
		vim.keymap.set('n', 'gr', vim.lsp.buf.references, cbopts)

		-- Info
		vim.keymap.set('n', 'K', vim.lsp.buf.hover, cbopts)
		vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, cbopts)
		vim.keymap.set('n', '<leader>D', vim.lsp.buf.type_definition, cbopts)

		-- Workspace
		vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, cbopts)
		vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, cbopts)
		vim.keymap.set('n', '<leader>wl', function()
			print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
		end, cbopts)

		-- Refactoring
		vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, cbopts)
		vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, cbopts)

		-- Formatting
		vim.keymap.set('n', '<leader>f', function() vim.lsp.buf.format { async = true } end, cbopts)
	end,
})

-- mason setup, configured lsp have to be installed later manually or using headless mode
require('mason').setup()
require('mason-lspconfig').setup {
	ensure_installed = { },
	-- ensure_installed = { 'gopls', 'lua_ls', 'clangd', 'pylsp', 'ts_ls' },
	automatic_installation = false,
}

-- LSP servers config
local servers = {
	gopls = { cmd = { 'gopls' }, settings = { gopls = { analyses = { unusedparams = true, shadow = true }, staticcheck = true } }, },
	lua_ls = { settings = { Lua = { runtime = { version = 'LuaJIT' }, diagnostics = { globals = { 'vim' } }, workspace = { checkThirdParty = false }, telemetry = { enable = false }, }, }, },
	clangd = { cmd = { 'clangd', '--background-index', '--clang-tidy' }, },
	pylsp = { settings = { pylsp = { plugins = { pycodestyle = { maxLineLength = 100 }, pylint = { enabled = true }, mccabe = { enabled = true }, }, }, }, },
	ts_ls = { cmd = { 'typescript-language-server', '--stdio' }, },
}

for name, config in pairs(servers) do
	vim.lsp.config(name, config)
end

local lsp_by_filetype = {
	lua = { "lua_ls" },
	go = { "gopls" },
	c = { "clangd" },
	cpp = { "clangd" },
	python = { "pylsp" },
	javascript = { "ts_ls" },
	typescript = { "ts_ls" },
}

vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("AutoLspByFiletype", { clear = true }),
	callback = function(args)
		local ft = vim.bo[args.buf].filetype
		local lspservers = lsp_by_filetype[ft]
		if not lspservers then
			return
		end

		for _, name in ipairs(lspservers) do
			vim.lsp.enable(name, { bufnr = args.buf })
		end
	end,
})
