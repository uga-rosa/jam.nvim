local action = require("jam.action")

return {
    -- "default" and "azik" is available.
    -- You can set the full path of your own key layout file to it.
    keyLayout = "default",
    start_key = "<C-q>",
    mappings = {
        { "<Space>", action.complete, "input" },
        { "<C-h>", action.backspace, "input" },
        { "<BS>", action.backspace, "input" },
        { "<C-n>", action.insert_next_item, "convert" },
        { "<C-p>", action.insert_prev_item, "convert" },
        { "<C-j>", action.next, "convert" },
        { "<C-k>", action.prev, "convert" },
        { "<CR>", action.confirm, "convert" },
        { "<C-m>", action.confirm, "convert" },
        { "<M-j>", action.extend, "convert" },
        { "<M-k>", action.shorten, "convert" },
        { "<C-e>", action.exit, { "preinput", "input", "convert" } },
    },
    _action = action,
}
