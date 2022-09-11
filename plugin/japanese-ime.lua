if vim.g.loaded_japanese_ime then
    return
end
vim.g.loaded_japanese_ime = true

require("jam").setup()
