local action = require("jam.action")

return {
    -- "default" and "azik" is available.
    -- You can set the full path of your own key layout file to it.
    keyLayout = "default",
    start_key = "<C-q>",
    mappings = {
        { "<Space>", action.complete, "Input" },
        { "<C-h>", action.backspace, "Input" },
        { "<BS>", action.backspace, "Input" },
        { "<C-n>", action.insert_next_item, "Convert" },
        { "<C-p>", action.insert_prev_item, "Convert" },
        { "h", action.goto_prev, "Convert" },
        { "l", action.goto_next, "Convert" },
        { "H", action.goto_head, "Convert" },
        { "L", action.goto_tail, "Convert" },
        { "<CR>", action.confirm, "Convert" },
        { "<C-m>", action.confirm, "Convert" },
        { "<C-j>", action.extend, "Convert" },
        { "<C-k>", action.shorten, "Convert" },
        { "<C-e>", action.exit, { "PreInput", "Input", "Convert" } },
    },
    _action = action,
}
