local api = vim.api
local uv = vim.loop

local utf8 = require("jam.utils.utf8")

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

---@param v any
---@param msg string
---@param ... string | number
function utils.assertf(v, msg, ...)
    if select("#", ...) > 0 then
        msg = string.format(msg, ...)
    end
    assert(v, msg)
end

---@param path string
---@return string
function utils.read_file_sync(path)
    local fd = assert(uv.fs_open(path, "r", 438))
    local stat = assert(uv.fs_fstat(fd))
    local data = assert(uv.fs_read(fd, stat.size, 0))
    assert(uv.fs_close(fd))
    return data
end

---@param fname string
---@return fun(): integer, string
function utils.lines(fname)
    local data = utils.read_file_sync(fname)
    data = vim.trim(data)
    local lines = vim.split(data, "\n")
    local i = 0
    return function()
        i = i + 1
        if lines[i] then
            return i, lines[i]
        end
    end
end

---@param array any[]
---@param key string
---@param cb fun(arr: any[], i: integer, key: string)
---@return integer
function utils.binary_search(array, key, cb)
    vim.validate({
        array = { array, "t" },
        key = { key, "s" },
        cb = { cb, "f" },
    })
    local left = 0
    local right = #array

    -- (left, right]
    while right - left > 1 do
        local mid = math.floor((left + right) / 2)
        if cb(array, mid, key) then
            right = mid
        else
            left = mid
        end
    end

    return right
end

---@param s string
---@param n integer
---@return string
function utils.get_char(s, n)
    local start = utf8.offset(s, n)
    if not start then
        error("Out of bounds")
    end
    if n == -1 then
        return s:sub(start)
    end
    local end_ = utf8.offset(s, n + 1)
    if not end_ then
        error("Out of bounds")
    end
    return s:sub(start, end_)
end

---@param key string
function utils.feedkey(key)
    api.nvim_feedkeys(api.nvim_replace_termcodes(key, true, false, true), "n", false)
end

---@param a string | string[]
---@return string[]
function utils.cast2tbl(a)
    if type(a) == "table" then
        return a
    end
    return { a }
end

return utils
