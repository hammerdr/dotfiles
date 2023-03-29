require('neorg').setup {
  load = {
    ["core.defaults"] = {},
    ["core.highlights"] = {},
    ["core.keybinds"] = {},
    ["core.mode"] = {},
    ["core.neorgcmd"] = {},
    ["core.norg.concealer"] = {},
    ["core.norg.dirman"] = {
      config = {
        workspaces = {
          default = "~/notes/default",
          doax = "~/notes/doax",
          vault = "/mnt/raid1/shared/org",
        },
        default_workspace = "vault",
      },
    },
    ["core.norg.esupports.hop"] = {},
    ["core.norg.esupports.metagen"] = {},
    ["core.integrations.telescope"] = {},
    ["core.integrations.treesitter"] = {},
    ["core.norg.completion"] = { config = {engine = "nvim-cmp"} },
  },
}

local neorg_callbacks = require("neorg.callbacks")

neorg_callbacks.on_event("core.keybinds.events.enable_keybinds", function(_, keybinds)
    -- Map all the below keybinds only when the "norg" mode is active
    keybinds.map_event_to_mode("norg", {
        n = { -- Bind keys in normal mode
            { "<C-s>", "core.integrations.telescope.find_linkable" },
        },

        i = { -- Bind in insert mode
            { "<C-l>", "core.integrations.telescope.insert_link" },
        },
    }, {
        silent = true,
        noremap = true,
    })
end)
