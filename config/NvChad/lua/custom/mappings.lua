---@type MappingsTable
local M = {}

M.general = {
	n = {
		[";"] = { ":", "enter command mode", opts = { nowait = true } },
		["<leader>e"] = { "<cmd> NvimTreeFocus <CR>", "Show nvimtree" },
		["<leader>o"] = { "<cmd> NvimTreeToggle <CR>", "Toggle nvimtree" },
		["<C-q>"] = { "<cmd>q!<cr>", desc = "Force quit" },
		["<F7>"] = { "<cmd>ToggleTerm<cr>", desc = "Toggle terminal" },

		["<leader>gg"] = {
			function()
				local Terminal = require("toggleterm.terminal").Terminal
				local lazygit = Terminal:new({ cmd = "lazygit", hidden = true })
				lazygit:toggle()
			end,
			desc = "ToggleTerm lazygit",
		},
	},
}

-- more keybinds!

M.lspconfig = {
	n = {
		["<leader>fd"] = {
			function()
				vim.diagnostic.open_float({ border = "rounded" })
			end,
			"Floating diagnostic",
		},
	},
}

return M
