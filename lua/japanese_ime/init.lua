local config = require("japanese_ime.config")
local session = require("japanese_ime.session")
local keymap = require("japanese_ime.keymap")

local M = {}

function M.setup(opt)
    config.setup(opt)
end

local function map_set()
    vim.keymap.set("i", "<Space>", M.complete, { buffer = true })
    vim.keymap.set("i", "<C-n>", M.select_next_item, { buffer = true })
    vim.keymap.set("i", "<C-p>", M.select_prev_item, { buffer = true })
    vim.keymap.set("i", "<C-j>", M.next, { buffer = true })
    vim.keymap.set("i", "<C-k>", M.prev, { buffer = true })
    vim.keymap.set("i", "<CR>", M.confirm, { buffer = true })
    vim.keymap.set("i", "<C-l>", M.extend, { buffer = true })
    vim.keymap.set("i", "<C-h>", M.shorten, { buffer = true })
    vim.keymap.set("i", "<C-e>", M.exit, { buffer = true })
end

local function map_del()
    vim.keymap.del("i", "<Space>", { buffer = true })
    vim.keymap.del("i", "<C-n>", { buffer = true })
    vim.keymap.del("i", "<C-p>", { buffer = true })
    vim.keymap.del("i", "<C-j>", { buffer = true })
    vim.keymap.del("i", "<C-k>", { buffer = true })
    vim.keymap.del("i", "<CR>", { buffer = true })
    vim.keymap.del("i", "<C-l>", { buffer = true })
    vim.keymap.del("i", "<C-h>", { buffer = true })
    vim.keymap.del("i", "<C-e>", { buffer = true })
end

function M.start()
    session:start()
    keymap.store()
    map_set()
end

function M.complete()
    session:complete()
end

function M.select_next_item()
    session.nodes:current():insert_relative(1)
end

function M.select_prev_item()
    session.nodes:current():insert_relative(-1)
end

function M.next()
    session:move(1)
end

function M.prev()
    session:move(-1)
end

function M.extend()
    if vim.b.ime_mode == "convert" then
        session.nodes:current():extend()
    end
end

function M.shorten()
    if vim.b.ime_mode == "convert" then
        session.nodes:current():shorten()
    end
end

function M.confirm()
    session:confirm()
end

function M.exit()
    session:exit()
    map_del()
    keymap.restore()
end

return M
