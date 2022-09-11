local config = require("jam.config")

local M = {}

---@param opt table?
function M.setup(opt)
    config.setup(opt or {})
end

return M
