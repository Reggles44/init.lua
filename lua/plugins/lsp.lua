return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    "jose-elias-alvarez/nvim-lsp-ts-utils",
    "b0o/schemastore.nvim",
    "j-hui/fidget.nvim",
  },
  config = function()
    -- LSP Keymap
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
      callback = function(event)
        local map = function(keys, func, desc)
          vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
        end

        map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
        map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
        map("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
        map("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type [D]efinition")
        map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
        map("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")
        map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
        map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
        map("K", vim.lsp.buf.hover, "Hover Documentation")
        map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
      end,
    })

    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

    local ts_util = require "nvim-lsp-ts-utils"
    local servers = {
      bashls = true,
      lua_ls = {
        settings = {
          Lua = {
            diagnostics = {
              globals = { 'vim' }
            },
            workspace = {
              checkThirdParty = false,
            },
          },
        }
      },
      pyright = true,
      ruff_lsp = true,
      gopls = {
        settings = {
          gopls = {
            codelenses = { test = true },
            hints = {
              assignVariableTypes = true,
              compositeLiteralFields = true,
              compositeLiteralTypes = true,
              constantValues = true,
              functionTypeParameters = true,
              parameterNames = true,
              rangeVariableTypes = true,
            } or nil,
          },
        },

        flags = {
          debounce_text_changes = 200,
        },
      },
      rust_analyzer = {
        cmd = {
          "rustup",
          "run",
          "nightly",
          "rust-analyzer"
        }
      },
      tsserver = {
        init_options = ts_util.init_options,
        cmd = { "typescript-language-server", "--stdio" },
        filetypes = {
          "javascript",
          "javascriptreact",
          "javascript.jsx",
          "typescript",
          "typescriptreact",
          "typescript.tsx",
        },

        on_attach = function(client)
          ts_util.setup { auto_inlay_hints = false }
          ts_util.setup_client(client)
        end,
      },
      -- C#
      omnisharp = {
        cmd = {
          vim.fn.expand "~/build/omnisharp/run", "--languageserver", "--hostPID", tostring(vim.fn.getpid())
        },
      },
      html = true,
      cssls = true,
      tailwindcss = true,
      vimls = true,
      yamlls = true,
      jsonls = {
        settings = {
          json = {
            schemas = require("schemastore").json.schemas(),
            validate = { enable = true },
          },
        },
      },
    }

    require("mason").setup()

    local ensure_installed = vim.tbl_keys(servers or {})
    vim.list_extend(ensure_installed, {
      "lua_ls", "jsonls"
    })
    require("mason-tool-installer").setup { ensure_installed = ensure_installed }

    require("mason-lspconfig").setup {
      handlers = {
        function(server_name)
          local server = servers[server_name] or {}
          if type(server) ~= "table" then server = {} end
          server = vim.tbl_deep_extend("force", {
            capabilities = server.capabilities or {}
          }, server)
          require("lspconfig")[server_name].setup(server)
        end,
      },
    }
  end,
}
