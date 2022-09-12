local action = require("jam.action")

return {
    -- "default" and "azik" is available.
    -- You can set the full path of your own key layout file to it.
    keyLayout = "default",
    start_key = "<C-q>",
    mappings = {
        {
            "<Space>",
            {
                Input = action.complete,
                Convert = action.complete,
                Complete = action.insert_next_item,
            },
        },
        { "<F6>", action.convert_hira, { "Input", "Complete", "Convert" } },
        { "<F7>", action.convert_zen_kata, { "Input", "Complete", "Convert" } },
        { "<F8>", action.convert_han_kata, { "Input", "Complete", "Convert" } },
        { "<F9>", action.convert_zen_eisuu, { "Input", "Complete", "Convert" } },
        { "<F10>", action.convert_han_eisuu, { "Input", "Complete", "Convert" } },
        { { "<C-CR>", "<C-m>", "<CR>" }, action.confirm, { "Input", "Complete" } },
        {
            { "<C-h>", "<BS>" },
            {
                Input = action.backspace,
                Convert = action.cancel,
            },
        },
        {
            "<Esc>",
            {
                PreInput = action.exit,
                Input = action.exit,
                Convert = action.cancel,
            },
        },
        { { "<C-n>", "<Tab>" }, action.insert_next_item, "Complete" },
        { { "<C-p>", "<S-Tab>" }, action.insert_prev_item, "Complete" },
        { { "<C-f>", "<Right>" }, action.goto_next, "Complete" },
        { { "<C-b>", "<Left>" }, action.goto_prev, "Complete" },
        { { "<C-e>", "<C-Right>", "<End>" }, action.goto_tail, "Complete" },
        { { "<C-a>", "<C-Left>", "<Home>" }, action.goto_head, "Complete" },
        { { "<C-k>", "<S-Right>" }, action.extend, "Complete" },
        { { "<C-j>", "<S-Left>" }, action.shorten, "Complete" },
    },
    _action = action,
}
