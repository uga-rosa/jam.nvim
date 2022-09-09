local api = vim.api

local utf8 = require("japanese_ime.utf8")

---@class Abbrev
---@field layout table<string, string>[]
--- Key layout with the length of the string to be entered as the top-level key.
--- { { a = "あ", ... }, { ka = "か", ... }, { kya = "きゃ", ... } }
local Abbrev = {}

local aug_name = "japanese_ime_hiragana"

function Abbrev:load()
    if self.layout == nil then
        local keyLayout = require("japanese_ime.config").get("keyLayout")
        local layout = require(keyLayout)
        self.layout = {}
        for k, v in pairs(layout) do
            if self.layout[#k] == nil then
                self.layout[#k] = {}
            end
            self.layout[#k][k] = v
        end
    end
end

---@return string
function Abbrev:current_line_to_cursor()
    local current_line = api.nvim_get_current_line()
    local cursor_col = api.nvim_win_get_cursor(0)[2] + 1
    return current_line:sub(1, cursor_col - 1) .. vim.v.char
end

---@return string? lhs
---@return string? rhs
function Abbrev:match()
    local line = self:current_line_to_cursor()
    for i = table.maxn(self.layout), 1, -1 do
        local layout = self.layout[i] or {}
        local lhs = line:sub(-i)
        if layout[lhs] then
            return lhs, layout[lhs]
        end
    end
end

---@param key string
local function feedkey(key)
    ---@diagnostic disable-next-line
    api.nvim_feedkeys(api.nvim_replace_termcodes(key, true, true, true), "n", false)
end

function Abbrev:replace()
    local lhs, rhs = self:match()
    if lhs == nil or rhs == nil then
        return
    end

    vim.v.char = ""
    for _ = 2, utf8.len(lhs) do
        feedkey("<BS>")
    end
    feedkey(rhs)
end

function Abbrev:start()
    self:load()
    api.nvim_create_augroup(aug_name, { clear = true })
    api.nvim_create_autocmd("InsertCharPre", {
        group = aug_name,
        buffer = 0,
        callback = function()
            self:replace()
        end,
    })
end

function Abbrev:exit()
    api.nvim_create_augroup(aug_name, { clear = true })
end

return Abbrev
