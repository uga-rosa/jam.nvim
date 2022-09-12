local utf8 = require("jam.utils.utf8")
local data_table = require("jam.convert.table")

---@class Convert
local Convert = {}

---@param raw string
---@param hiragana string
---@return response
---@diagnostic disable-next-line: unused-local
function Convert.hira(raw, hiragana)
    return { { origin = hiragana, candidates = { hiragana } } }
end

---@param raw string
---@param hiragana string
---@return response
---@diagnostic disable-next-line: unused-local
function Convert.zen_kata(raw, hiragana)
    local result = {}
    for _, c in utf8.codes(hiragana) do
        table.insert(result, data_table.zen_kata[c] or c)
    end
    return { { origin = hiragana, candidates = { table.concat(result) } } }
end

---@param raw string
---@param hiragana string
---@return response
function Convert.zen_eisuu(raw, hiragana)
    local result = {}
    for _, c in utf8.codes(raw) do
        table.insert(result, data_table.zen_eisuu[c] or c)
    end
    return { { origin = hiragana, candidates = { table.concat(result) } } }
end

---@param raw string
---@param hiragana string
---@return response
---@diagnostic disable-next-line: unused-local
function Convert.han_kata(raw, hiragana)
    local result = {}
    for _, c in utf8.codes(hiragana) do
        table.insert(result, data_table.han_kata[c] or c)
    end
    return { { origin = hiragana, candidates = { table.concat(result) } } }
end

---@param raw string
---@param hiragana string
---@return response
function Convert.han_eisuu(raw, hiragana)
    return { { origin = hiragana, candidates = { raw } } }
end

return Convert
