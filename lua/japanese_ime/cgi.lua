local Job = require("plenary.job")

local URL = "http://www.google.com/transliterate"
local LANGPAIR = "ja-Hira|ja"

local CGI = {}

---@param s string
---@return string
function CGI.percent_encode(s)
    local bytes = { string.byte(s, 1, -1) }
    local encoded = {}
    for i, v in ipairs(bytes) do
        encoded[i] = string.format("%X", v)
    end
    return "%" .. table.concat(encoded, "%")
end

---@param text string
---@return string
function CGI.create_request(text)
    vim.validate({
        text = { text, "s" },
    })
    local encoded = CGI.percent_encode(text)
    return URL .. "?langpair=" .. LANGPAIR .. "&text=" .. encoded
end

---@param t table
---@param key unknown
---@return any
local function safe_get(t, key)
    if type(t) == "table" and t[key] then
        return t[key]
    end
end

---@alias response { origin: string, candidates: string[] }[]

---@param text string
---@return response
function CGI.get_responce(text)
    local request = CGI.create_request(text)
    local result = {}
    Job:new({
        command = "curl",
        args = { request },
        on_exit = function(j)
            local r = safe_get(j:result(), 1)
            if r then
                r = vim.json.decode(r)
                for i, v in ipairs(r) do
                    result[i] = { origin = v[1], candidates = v[2] }
                end
            end
        end,
    }):sync()
    return result
end

return CGI
