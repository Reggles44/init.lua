return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      "jose-elias-alvarez/nvim-lsp-ts-utils",
      "b0o/schemastore.nvim",
      { "j-hui/fidget.nvim", opts = {} },
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
          Lua = {
            workspace = {
              checkThirdParty = false,
            },
          },
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

      local custom_init = function(client)
        client.config.flags = client.config.flags or {}
        client.config.flags.allow_incremental_sync = true
      end
      local custom_attach = function(client, bufnr)
        if client.name == "copilot" then
          return
        end

        local filetype = vim.api.nvim_buf_get_option(0, "filetype")

        vim.keymap.set("i", "<c-s>", vim.lsp.buf.signature_help )

        vim.keymap.set("n", "<space>cr", vim.lsp.buf.rename )
        vim.keymap.set("n", "<space>ca", vim.lsp.buf.code_action )

        vim.keymap.set("n", "gd", vim.lsp.buf.definition )
        vim.keymap.set("n", "gD", vim.lsp.buf.declaration )
        vim.keymap.set("n", "gT", vim.lsp.buf.type_definition )
        vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "lsp:hover" } )

        vim.keymap.set("n", "<space>lr", "<cmd>lua R('tj.lsp.codelens').run()<CR>" )
        vim.keymap.set("n", "<space>rr", "LspRestart" )

        vim.bo.omnifunc = "v:lua.vim.lsp.omnifunc"

        if filetype == "typescript" or filetype == "lua" or filetype == "clojure" then
          client.server_capabilities.semanticTokensProvider = nil
        end

        -- Attach any filetype specific options to the client
        filetype_attach[filetype]()
      end
      require("mason-lspconfig").setup {
        handlers = {
          function(server_name)
            local server = servers[server_name] or {}
            if type(server) ~= "table" then server = {} end
            server = vim.tbl_deep_extend("force", {
              on_init = custom_init,
              on_attach = custom_attach,
              capabilities = server.capabilities or {}
            }, server)
            require("lspconfig")[server_name].setup(server)
          end,
        },
      }
    end,
  },
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      {
        "L3MON4D3/LuaSnip",
        build = (function()
          return "make install_jsregexp"
        end)(),
      },
      "saadparwaiz1/cmp_luasnip",

      -- Adds other completion capabilities.
      --  nvim-cmp does not ship with all sources by default. They are split
      --  into multiple repos for maintenance purposes.
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-path",

      -- If you want to add a bunch of pre-configured snippets,
      --    you can use this plugin to help you. It even has snippets
      --    for various frameworks/libraries/etc. but you will have to
      --    set up the ones that are useful for you.
      -- "rafamadriz/friendly-snippets",
    },
    config = function()
      local cmp = require "cmp"
      local luasnip = require "luasnip"
      luasnip.config.setup {}

      cmp.setup {
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        completion = { completeopt = "menu,menuone,noinsert" },

        -- For an understanding of why these mappings were
        -- chosen, you will need to read `:help ins-completion`
        --
        -- No, but seriously. Please read `:help ins-completion`, it is really good!
        mapping = cmp.mapping.preset.insert {
          -- Select the [n]ext item
          ["<C-n>"] = cmp.mapping.select_next_item(),
          -- Select the [p]revious item
          ["<C-p>"] = cmp.mapping.select_prev_item(),

          -- Accept ([y]es) the completion.
          --  This will auto-import if your LSP supports it.
          --  This will expand snippets if the LSP sent a snippet.
          ["<C-y>"] = cmp.mapping.confirm { select = true },

          -- Manually trigger a completion from nvim-cmp.
          --  Generally you don"t need this, because nvim-cmp will display
          --  completions whenever it has completion options available.
          ["<C-Space>"] = cmp.mapping.complete {},

          -- Think of <c-l> as moving to the right of your snippet expansion.
          --  So if you have a snippet that"s like:
          --  function $name($args)
          --    $body
          --  end
          --
          -- <c-l> will move you to the right of each of the expansion locations.
          -- <c-h> is similar, except moving you backwards.
          ["<C-l>"] = cmp.mapping(function()
            if luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            end
          end, { "i", "s" }),
          ["<C-h>"] = cmp.mapping(function()
            if luasnip.locally_jumpable(-1) then
              luasnip.jump(-1)
            end
          end, { "i", "s" }),
        },
        sources = {
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "path" },
        },
      }
    end,
  },
}
