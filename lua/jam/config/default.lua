local mapping = require("jam").mapping

return {
    -- "default" and "azik" is available.
    -- You can set the full path of your own key layout file to it.
    keyLayout = "default",
    start_key = "<C-q>",
    mappings = {
        ["<Space>"] = {
            Input = mapping.complete,
            Complete = mapping.insert_next_item,
            Convert = mapping.complete,
        },
        ["<F6>"] = mapping(mapping.convert_hira, { "Input", "Complete", "Convert" }),
        ["<F7>"] = mapping(mapping.convert_zen_kata, { "Input", "Complete", "Convert" }),
        ["<F8>"] = mapping(mapping.convert_han_kata, { "Input", "Complete", "Convert" }),
        ["<F9>"] = mapping(mapping.convert_zen_eisuu, { "Input", "Complete", "Convert" }),
        ["<F10>"] = mapping(mapping.convert_han_eisuu, { "Input", "Complete", "Convert" }),
        ["<CR>"] = mapping(mapping.confirm, { "Input", "Complete", "Convert" }),
        ["<C-m>"] = mapping(mapping.confirm, { "Input", "Complete", "Convert" }),
        ["<C-CR>"] = mapping(mapping.confirm, { "Input", "Complete", "Convert" }),
        ["<BS>"] = {
            PreInput = mapping.exit,
            Input = mapping.backspace,
            Complete = mapping.cancel,
            Convert = mapping.cancel,
        },
        ["<C-h>"] = {
            PreInput = mapping.exit,
            Input = mapping.backspace,
            Complete = mapping.cancel,
            Convert = mapping.cancel,
        },
        ["<Esc>"] = {
            PreInput = mapping.exit,
            Input = mapping.exit,
            Complete = mapping.cancel,
            Convert = mapping.cancel,
        },
        ["<C-n>"] = {
            Input = mapping.complete,
            Complete = mapping.insert_next_item,
        },
        ["<Tab>"] = {
            Input = mapping.complete,
            Complete = mapping.insert_next_item,
        },
        ["<C-p>"] = mapping(mapping.insert_prev_item, "Complete"),
        ["<S-Tab>"] = mapping(mapping.insert_prev_item, "Complete"),
        ["<C-b>"] = mapping(mapping.goto_prev, { "Input", "Complete", "Convert" }),
        ["<Left>"] = mapping(mapping.goto_prev, { "Input", "Complete", "Convert" }),
        ["<C-f>"] = mapping(mapping.goto_next, { "Input", "Complete", "Convert" }),
        ["<Right>"] = mapping(mapping.goto_next, { "Input", "Complete", "Convert" }),
        ["<C-a>"] = mapping(mapping.goto_head, { "Input", "Complete", "Convert" }),
        ["<C-Left>"] = mapping(mapping.goto_head, { "Input", "Complete", "Convert" }),
        ["<Home>"] = mapping(mapping.goto_head, { "Input", "Complete", "Convert" }),
        ["<C-e>"] = mapping(mapping.goto_tail, { "Input", "Complete", "Convert" }),
        ["<C-Right>"] = mapping(mapping.goto_tail, { "Input", "Complete", "Convert" }),
        ["<End>"] = mapping(mapping.goto_tail, { "Input", "Complete", "Convert" }),
        ["<C-j>"] = mapping(mapping.shorten, "Complete"),
        ["<S-Left>"] = mapping(mapping.shorten, "Complete"),
        ["<C-k>"] = mapping(mapping.extend, "Complete"),
        ["<S-Right>"] = mapping(mapping.extend, "Complete"),
        ["<C-Space>"] = mapping(mapping.zenkaku_space, "PreInput"),
    },
}
