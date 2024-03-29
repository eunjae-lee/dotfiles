-- Mapping data with "desc" stored directly by vim.keymap.set().
--
-- Please use this mappings table to set keyboard mapping since this is the
-- lower level configuration and more robust one. (which-key will
-- automatically pick-up stored data by this setting.)
return {
  -- first key is the mode
  n = {
    -- second key is the lefthand side of the map

    -- navigate buffer tabs with `H` and `L`
    -- L = {
    --   function() require("astronvim.utils.buffer").nav(vim.v.count > 0 and vim.v.count or 1) end,
    --   desc = "Next buffer",
    -- },
    -- H = {
    --   function() require("astronvim.utils.buffer").nav(-(vim.v.count > 0 and vim.v.count or 1)) end,
    --   desc = "Previous buffer",
    -- },

    -- mappings seen under group name "Buffer"
    ["<leader>bD"] = {
      function()
        require("astronvim.utils.status").heirline.buffer_picker(
          function(bufnr) require("astronvim.utils.buffer").close(bufnr) end
        )
      end,
      desc = "Pick to close",
    },
    -- tables with the `name` key will be registered with which-key if it's installed
    -- this is useful for naming menus
    ["<leader>b"] = { name = "Buffers" },
    -- quick save
    -- ["<C-s>"] = { ":w!<cr>", desc = "Save File" },  -- change description but the same command
    ["<C-9>"] = { "I" },
    ["<C-0>"] = { "A" },
  },
  i = {
    -- save even in insert mode, and enter normal mode
    ["<C-s>"] = { "<Esc>:write<CR>" },
    ["<C-9>"] = { "<Esc>I" },
    ["<C-0>"] = { "<Esc>A" },
  },
  t = {
    -- setting a mapping to false will disable it
    -- ["<esc>"] = false,

    -- fix toggleterm shift+space issue
    -- https://github.com/akinsho/toggleterm.nvim/issues/338#issuecomment-1534546031
    ["<S-BS>"] = { "<BS>" },
    ["<C-BS>"] = { "<BS>" },
    ["<M-S-BS>"] = { "<BS>" },
    ["<M-C-BS>"] = { "<BS>" },
    ["<C-S-BS>"] = { "<BS>" },
    ["<M-C-S-BS>"] = { "<BS>" },
    ["<S-Space>"] = { "<Space>" },
    ["<M-S-Space>"] = { "<Space>" },
    ["<M-C-Space>"] = { "<Space>" },
    ["<C-S-Space>"] = { "<Space>" },
    ["<M-C-S-Space>"] = { "<Space>" },
    ["<S-CR>"] = { "<CR>" },
    ["<C-CR>"] = { "<CR>" },
    ["<M-S-CR>"] = { "<CR>" },
    ["<M-C-CR>"] = { "<CR>" },
    ["<C-S-CR>"] = { "<CR>" },
    ["<M-C-S-CR>"] = { "<CR>" },
  },
}
