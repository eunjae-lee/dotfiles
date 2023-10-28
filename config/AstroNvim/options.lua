return function(local_vim)
  local_vim.opt.relativenumber = true -- sets vim.opt.relativenumber
  local_vim.opt.number = true -- sets vim.opt.number
  local_vim.opt.spell = false -- sets vim.opt.spell
  local_vim.opt.signcolumn = "auto" -- sets vim.opt.signcolumn to auto
  local_vim.opt.wrap = false -- sets vim.opt.wrap

  local_vim.g.mapleader = " " -- sets vim.g.mapleader
  local_vim.g.autoformat_enabled = true -- enable or disable auto formatting at start (lsp.formatting.format_on_save must be enabled)
  local_vim.g.cmp_enabled = true -- enable completion at start
  local_vim.g.autopairs_enabled = true -- enable autopairs at start
  local_vim.g.diagnostics_mode = 3 -- set the visibility of diagnostics in the UI (0=off, 1=only show in status line, 2=virtual text off, 3=all on)
  local_vim.g.icons_enabled = true -- disable icons in the UI (disable if no nerd font is available, requires :PackerSync after changing)
  local_vim.g.ui_notifications_enabled = true -- disable notifications when toggling UI elements
  local_vim.g.resession_enabled = false -- enable experimental resession.nvim session management (will be default in AstroNvim v4)

  return local_vim
end
