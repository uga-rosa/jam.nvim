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
                Complete = action.insert_next_item,
                Convert = action.complete,
            },
        },
        { "<F6>", action.convert_hira, { "Input", "Complete", "Convert" } },
        { "<F7>", action.convert_zen_kata, { "Input", "Complete", "Convert" } },
        { "<F8>", action.convert_han_kata, { "Input", "Complete", "Convert" } },
        { "<F9>", action.convert_zen_eisuu, { "Input", "Complete", "Convert" } },
        { "<F10>", action.convert_han_eisuu, { "Input", "Complete", "Convert" } },
        { { "<C-CR>", "<C-m>", "<CR>" }, action.confirm, { "Input", "Complete", "Convert" } },
        {
            { "<C-h>", "<BS>" },
            {
                Input = action.backspace,
                Complete = action.cancel,
                Convert = action.cancel,
            },
        },
        {
            "<Esc>",
            {
                PreInput = action.exit,
                Input = action.exit,
                Complete = action.cancel,
                Convert = action.cancel,
            },
        },
        { { "<C-n>", "<Tab>" }, action.insert_next_item, "Complete" },
        { { "<C-p>", "<S-Tab>" }, action.insert_prev_item, "Complete" },
        { { "<C-b>", "<Left>" }, action.goto_prev, { "Input", "Complete" } },
        { { "<C-f>", "<Right>" }, action.goto_next, { "Input", "Complete" } },
        { { "<C-a>", "<C-Left>", "<Home>" }, action.goto_head, { "Input", "Complete" } },
        { { "<C-e>", "<C-Right>", "<End>" }, action.goto_tail, { "Input", "Complete" } },
        { { "<C-k>", "<S-Right>" }, action.extend, "Complete" },
        { { "<C-j>", "<S-Left>" }, action.shorten, "Complete" },
        { "<C-Space>", action.zenkaku_space, "PreInput" },
    },
    _action = action,
}
