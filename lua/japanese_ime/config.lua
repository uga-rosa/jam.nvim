local M = {}

M.config = {
    keyLayout = "japanese_ime.keylayout.azik",
}

---@param opt table
function M.setup(opt)
    vim.validate({
        opt = { opt, "t" },
    })

    M.config = vim.tbl_deep_extend("force", M.config, opt)

    vim.validate({
        ["config.keyLayout"] = { M.config.keyLayout, "s" },
    })
end

---@param name string
---@return unknown
function M.get(name)
    return M.config[name] or error("Invalid option name: " .. name)
end

return M
