local configs = require("plugins.configs.lspconfig")
local on_attach = configs.on_attach
local capabilities = configs.capabilities

local lspconfig = require "lspconfig"
local servers = { "html", "cssls", "astro", "svelte", "tailwindcss", "tsserver" }

for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
    capabilities = capabilities,
  }
end

-- css, html, json
local capabilitiesWithSnippetSupport = vim.lsp.protocol.make_client_capabilities()
capabilitiesWithSnippetSupport.textDocument.completion.completionItem.snippetSupport = true

local servers2 = { "cssls", "html", "jsonls" }
for _, lsp in ipairs(servers2) do
  lspconfig[lsp].setup {
    capabilities = capabilitiesWithSnippetSupport,
  }
end


-- eslint
lspconfig.eslint.setup({
  --- ...
  on_attach = function(client, bufnr)
    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = bufnr,
      command = "EslintFixAll",
    })
  end,
})

