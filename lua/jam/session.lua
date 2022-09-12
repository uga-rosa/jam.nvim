local api = vim.api

local CompleteNodes = require("jam.node.complete_nodes")
local InputStatus = require("jam.input.status")
local keymap = require("jam.keymap")
local Convert = require("jam.convert")
local cgi = require("jam.cgi")
local pum = require("jam.utils.pum")
local utils = require("jam.utils")
local sa = require("jam.utils.safe_array")

local aug_name = "jam"

---@alias ime_mode
--- | '""'
--- | '"PreInput"'
--- | '"Input"'
--- | '"Complete"'
--- | '"Convert"'

---@type ime_mode
vim.b.ime_mode = ""

---@class Session
---@field ime_mode ime_mode
---@field start_pos integer[] #(1,1) index
---@field completeNodes CompleteNodes
---@field input_status InputStatus
local Session = {}

function Session:start()
    self:reset()
    self:_mode_set("PreInput")

    api.nvim_create_augroup(aug_name, { clear = true })
    api.nvim_create_autocmd("InsertCharPre", {
        group = aug_name,
        buffer = 0,
        callback = function()
            if self.ime_mode == "Complete" and not self:current_node():_skip() then
                self:confirm()
                self:_mode_set("PreInput")
            end
            self.input_status:input(vim.v.char)
        end,
    })
    api.nvim_create_autocmd("TextChangedI", {
        group = aug_name,
        buffer = 0,
        callback = function()
            self.input_status:update_buffer()
        end,
    })
    api.nvim_create_autocmd("InsertLeavePre", {
        group = aug_name,
        buffer = 0,
        callback = function()
            self:exit()
        end,
    })

    keymap:store()
    keymap:set()
end

function Session:reset()
    self.ime_mode = ""
    self.start_pos = utils.get_pos()
    self.completeNodes = nil
    self.input_status = InputStatus.new(self)
end

---@param mode ime_mode
function Session:_mode_set(mode)
    self.ime_mode = mode
    vim.b.ime_mode = mode
end

---@param modes ime_mode | ime_mode[]
function Session:_mode_validate(modes)
    modes = utils.cast2tbl(modes)
    local set = sa.new(modes):to_set()
    assert(set[self.ime_mode], "Called in invalid IME mode: " .. self.ime_mode)
end

function Session:backspace()
    self:_mode_validate("Input")
    self.input_status:backspace()
end

---@return CompleteNode
function Session:current_node()
    return self.completeNodes:current()
end

function Session:_complete()
    self:current_node():complete()
end

function Session:complete()
    self:_mode_validate({ "Input", "Complete", "Convert" })
    if self.ime_mode == "Complete" then
        local request = sa.new(self.completeNodes.nodes)
            :map(function(node)
                return node.origin
            end)
            :concat(",")
        local response = cgi.get_responce(request)
        self.completeNodes:new_response(response)
    else
        local request = self.input_status.display
        local response = cgi.get_responce(request)
        self.completeNodes = CompleteNodes.new(request, response, self.start_pos, self)
    end
    self:_complete()
    self:_mode_set("Complete")
end

---@param get_responce fun(raw: string, hiragana: string): response
function Session:_convert(get_responce)
    self:_mode_validate({ "Input", "Complete", "Convert" })
    if self.ime_mode ~= "Input" then
        self:cancel()
    end
    local request = self.input_status.display
    local response = get_responce(self.input_status.raw, request)
    self.completeNodes = CompleteNodes.new(request, response, self.start_pos, self)
    self:current_node():move()
    self:_mode_set("Convert")
end

function Session:convert_hira()
    self:_convert(Convert.hira)
end

function Session:convert_zen_kata()
    self:_convert(Convert.zen_kata)
end

function Session:convert_zen_eisuu()
    self:_convert(Convert.zen_eisuu)
end

function Session:convert_han_kata()
    self:_convert(Convert.han_kata)
end

function Session:convert_han_eisuu()
    self:_convert(Convert.han_eisuu)
end

function Session:cancel()
    self:_mode_validate({ "Complete", "Convert" })
    self.completeNodes:tail():move()
    pum.close()
    self.input_status.end_col = self.completeNodes.end_
    self:_mode_set("Input")
    self.input_status:update_buffer()
    self.completeNodes = nil
end

---@param delta integer
function Session:insert_item(delta)
    self:_mode_validate("Complete")
    self:current_node():insert_relative(delta)
end

function Session:goto_next()
    self:_mode_validate("Complete")
    if self.completeNodes:goto_next() then
        self:_complete()
    end
end

function Session:goto_prev()
    self:_mode_validate("Complete")
    if self.completeNodes:goto_prev() then
        self:_complete()
    end
end

function Session:goto_head()
    self:_mode_validate("Complete")
    if self.completeNodes:goto_head() then
        self:_complete()
    end
end

function Session:goto_tail()
    self:_mode_validate("Complete")
    if self.completeNodes:goto_tail() then
        self:_complete()
    end
end

function Session:extend()
    self:_mode_validate("Complete")
    self:current_node():extend()
end

function Session:shorten()
    self:_mode_validate("Complete")
    self:current_node():shorten()
end

function Session:confirm()
    self:_mode_validate({ "Input", "Complete" })
    if self.ime_mode == "Complete" then
        self.completeNodes:tail():move()
        pum.close()
    end
    self:reset()
    self:_mode_set("PreInput")
end

function Session:exit()
    if self.ime_mode == "Input" or self.ime_mode == "Complete" then
        self:confirm()
    end
    self:_mode_set("")
    api.nvim_create_augroup(aug_name, { clear = true })
    keymap:del()
    keymap:restore()
end

return Session
