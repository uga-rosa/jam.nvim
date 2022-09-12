if vim.g.loaded_japanese_ime then
    return
end
vim.g.loaded_japanese_ime = true

require("jam").setup()

local bg = vim.api.nvim_get_hl_by_name("Normal", "").background
local bg_1, bg_2
local diff = tonumber("101010", 16)
if bg < tonumber("FFFFFF", 16) - 2 * diff then
    bg_1 = bg + diff
    bg_2 = bg_1 + diff
else
    bg_1 = bg - diff
    bg_2 = bg_1 - diff
end

local set_hl = vim.api.nvim_set_hl

set_hl(0, "JamInput", { underdotted = true })
set_hl(0, "JamCompleteSelected", { underline = true })
set_hl(0, "JamCompleteNotSelected1", { underdotted = true, bg = bg_1 })
set_hl(0, "JamCompleteNotSelected2", { underdotted = true, bg = bg_2 })
set_hl(0, "JamConvert", { underline = true })
