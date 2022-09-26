if vim.g.loaded_jam then
    return
end
vim.g.loaded_jam = true

require("jam").setup()

vim.cmd([[
hi def JamInput guifg=#000000 guibg=#ffffff
hi def JamCompleteSelected guifg=#000000 guibg=#ffffff
hi def JamCompleteNotSelected1 guifg=#000000 guibg=#cccccc
hi def JamCompleteNotSelected2 guifg=#000000 guibg=#999999
hi def JamConvert guifg=#000000 guibg=#ffffff
]])

local api = vim.api

local aug_name = "jam-nvim"
api.nvim_create_augroup(aug_name, {})

local cmp_config
api.nvim_create_autocmd("User", {
    pattern = "JamStart",
    callback = function()
        local ok, cmp = pcall(require, "cmp")
        if ok then
            cmp_config = cmp.get_config()
            cmp.setup({ enabled = false })
        end
        vim.b.lexima_disabled = 1
    end,
})

api.nvim_create_autocmd("User", {
    pattern = "JamExit",
    callback = function()
        local ok, cmp = pcall(require, "cmp")
        if ok then
            cmp.setup({ enabled = cmp_config.enabled })
        end
        vim.b.lexima_disabled = 0
    end,
})
