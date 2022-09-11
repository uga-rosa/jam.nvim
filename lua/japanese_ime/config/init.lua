local M = {
    config = {},
}

---@param opt table
function M.setup(opt)
    vim.validate({
        opt = { opt, "t" },
    })

    local default = require("japanese_ime.config.default")
    if opt.disable_default_mappings then
        default.mappings = {}
    end
    M.config = vim.tbl_deep_extend("force", M.config, default, opt)

    vim.validate({
        ["config.keyLayout"] = { M.config.keyLayout, "s" },
        ["config.start_key"] = { M.config.start_key, "s" },
        ["config.mappings"] = { M.config.mappings, "t" },
    })

    vim.keymap.set("i", M.config.start_key, M.config._action.start, {})
end

---@param name string
---@return unknown
function M.get(name)
    return M.config[name] or error("Invalid option name: " .. name)
end

return M
