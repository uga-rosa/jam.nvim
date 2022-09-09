local action = require("japanese_ime.action")
local keymap = require("japanese_ime.keymap")

local M = {}

M.config = {
    keyLayout = "japanese_ime.keylayout.azik",
    start_key = "<C-q>",
    mappings = {
        { "<Space>", action.complete, "input" },
        { "<C-n>", action.insert_next_item, "convert" },
        { "<C-p>", action.insert_prev_item, "convert" },
        { "<C-j>", action.next, "convert" },
        { "<C-k>", action.prev, "convert" },
        { "<CR>", action.confirm, "convert" },
        { "<C-m>", action.confirm, "convert" },
        { "<M-j>", action.extend, "convert" },
        { "<M-k>", action.shorten, "convert" },
        { "<C-e>", action.exit, { "input", "convert" } },
    },
}

---@param opt table
function M.setup(opt)
    vim.validate({
        opt = { opt, "t" },
    })

    M.config = vim.tbl_deep_extend("force", M.config, opt)

    vim.validate({
        ["config.keyLayout"] = { M.config.keyLayout, "s" },
        ["config.start_key"] = { M.config.start_key, "s" },
        ["config.mappings"] = { M.config.mappings, "t" },
    })

    keymap.mappings = M.config.mappings
    vim.keymap.set("i", M.config.start_key, action.start, {})
end

---@param name string
---@return unknown
function M.get(name)
    return M.config[name] or error("Invalid option name: " .. name)
end

return M
