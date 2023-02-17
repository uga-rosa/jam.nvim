local utf8 = require("jam.utils.utf8")
local data_table = require("jam.convert.table")

---@class Convert
local Convert = {}

---@param hiragana string
---@return response
function Convert.hira(hiragana)
  return { { origin = hiragana, candidates = { hiragana } } }
end

---@param hiragana string
---@return response
function Convert.zen_kata(hiragana)
  local result = {}
  for _, c in utf8.codes(hiragana) do
    table.insert(result, data_table.zen_kata[c] or c)
  end
  return { { origin = hiragana, candidates = { table.concat(result) } } }
end

---@param hiragana string
---@param raw string
---@return response
function Convert.zen_eisuu(hiragana, raw)
  local result = {}
  for _, c in utf8.codes(raw) do
    table.insert(result, data_table.zen_eisuu[c] or c)
  end
  return { { origin = hiragana, candidates = { table.concat(result) } } }
end

---@param hiragana string
---@return response
function Convert.han_kata(hiragana)
  local result = {}
  for _, c in utf8.codes(hiragana) do
    table.insert(result, data_table.han_kata[c] or c)
  end
  return { { origin = hiragana, candidates = { table.concat(result) } } }
end

---@param hiragana string
---@param raw string
---@return response
function Convert.han_eisuu(hiragana, raw)
  return { { origin = hiragana, candidates = { raw } } }
end

return Convert
