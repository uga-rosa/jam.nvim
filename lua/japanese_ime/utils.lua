local api = vim.api

local utils = {}

---@param origin string
---@param word string
---@param start integer
---@param end_ integer
---@return string
function utils.insert(origin, word, start, end_)
    return origin:sub(1, start - 1) .. word .. origin:sub(end_ + 1)
end

---Get current cursor position ((1,1)-index)
---@return integer[]
function utils.get_pos()
    local pos = api.nvim_win_get_cursor(0)
    pos[2] = pos[2] + 1
    return pos
end

---@class safe_array
---@field raw unknown[]
---@field len integer
local safe_array = {}
safe_array.__index = safe_array

---@param t any[]
---@return safe_array
function safe_array.new(t)
    vim.validate({ t = { t, "t" } })
    return setmetatable({
        raw = t,
        len = #t,
    }, safe_array)
end

---@param func fun(x: any): any
---@return safe_array
function safe_array:map(func)
    vim.validate({ func = { func, "f" } })
    local new = {}
    for i, v in ipairs(self.raw) do
        new[i] = func(v)
    end
    return safe_array.new(new)
end

---@param func fun(x: any): boolean
---@return safe_array
function safe_array:filter(func)
    vim.validate({ func = { func, "f" } })
    local new = {}
    for _, v in ipairs(self.raw) do
        if func(v) then
            table.insert(new, v)
        end
    end
    return safe_array.new(new)
end

---@param sep? string
---@param i? integer
---@param j? integer
---@return string
function safe_array:concat(sep, i, j)
    vim.validate({
        sep = { sep, "s", true },
        i = { i, "n", true },
        j = { j, "n", true },
    })
    sep = vim.F.if_nil(sep, "")
    i = vim.F.if_nil(i, 1)
    j = vim.F.if_nil(j, #self.raw)
    return table.concat(self.raw, sep, i, j)
end

return {
    utils = utils,
    sa = safe_array,
}
