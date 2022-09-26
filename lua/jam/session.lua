local api = vim.api

local CompleteNodes = require("jam.node.complete_nodes")
local InputNodes = require("jam.node.input_nodes")
local keymap = require("jam.keymap")
local Convert = require("jam.convert")
local cgi = require("jam.cgi")
local utils = require("jam.utils")
local sa = require("jam.utils.safe_array")
local config = require("jam.config")

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
---@field complete_nodes CompleteNodes
---@field input_nodes InputNodes
---@field ns_id integer
local Session = {}

function Session:start()
    self:reset()
    self:_mode_set("PreInput")

    api.nvim_create_augroup(aug_name, { clear = true })
    api.nvim_create_autocmd("InsertCharPre", {
        group = aug_name,
        buffer = 0,
        callback = function()
            if
                (self.ime_mode == "Complete" and not self:current_c():_skip())
                or self.ime_mode == "Convert"
            then
                self:confirm()
                self:_mode_set("PreInput")
            end
            self.input_nodes:input(vim.v.char)
        end,
    })
    api.nvim_create_autocmd("TextChangedI", {
        group = aug_name,
        buffer = 0,
        callback = function()
            self.input_nodes:update_buffer()
            self:_update_highlight()
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
    vim.cmd("do User JamStart")
end

function Session:reset()
    self.ime_mode = ""
    self.start_pos = utils.get_pos()
    self.complete_nodes = nil
    self.input_nodes = InputNodes.new(self)
    self.ns_id = api.nvim_create_namespace("jam-nvim")
    self.marker = config.get("marker")
    vim.opt_local.completeopt = "noinsert"
end

function Session:_update_highlight()
    api.nvim_buf_clear_namespace(0, self.ns_id, self.start_pos[1] - 1, self.start_pos[1])
    if self.ime_mode == "Input" then
        api.nvim_buf_add_highlight(
            0,
            self.ns_id,
            "JamInput",
            self.input_nodes.row - 1,
            self.input_nodes:head().start - 1,
            self.input_nodes:tail().end_
        )
    elseif self.ime_mode == "Complete" then
        local c = 1
        for _, node in ipairs(self.complete_nodes.nodes) do
            if node:is_selected() then
                api.nvim_buf_add_highlight(
                    0,
                    self.ns_id,
                    "JamCompleteSelected",
                    node.row - 1,
                    node.start - 1,
                    node.end_
                )
            elseif c == 1 then
                api.nvim_buf_add_highlight(
                    0,
                    self.ns_id,
                    "JamCompleteNotSelected1",
                    node.row - 1,
                    node.start - 1,
                    node.end_
                )
                c = 2
            else
                api.nvim_buf_add_highlight(
                    0,
                    self.ns_id,
                    "JamCompleteNotSelected2",
                    node.row - 1,
                    node.start - 1,
                    node.end_
                )
                c = 1
            end
        end
    elseif self.ime_mode == "Convert" then
        local node = self:current_c()
        api.nvim_buf_add_highlight(
            0,
            self.ns_id,
            "JamConvert",
            node.row - 1,
            node.start - 1,
            node.end_
        )
    end
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
    self.input_nodes:backspace()
end

---@return CompleteNode
function Session:current_c()
    return self.complete_nodes:current()
end

---@return InputNode
function Session:current_i()
    return self.input_nodes:current()
end

function Session:_complete()
    self:current_c():complete()
    self:_update_highlight()
end

function Session:complete()
    self:_mode_validate({ "Input", "Complete", "Convert" })
    if self.ime_mode == "Complete" then
        local request = sa.new(self.complete_nodes.nodes)
            :map(function(node)
                return node.origin
            end)
            :concat(",")
        local response = cgi.get_responce(request)
        self.complete_nodes:new_response(response)
        self.complete_nodes._response = response
    else
        if self.ime_mode == "Convert" then
            self:cancel()
        end
        local request = self.input_nodes.display
        local response = cgi.get_responce(request)
        self.complete_nodes = CompleteNodes.new(request, response, self.start_pos, self)
    end
    self:_mode_set("Complete")
    self:_complete()
end

---@return string?
function Session:_search_raw()
    local i_nodes = self.input_nodes.nodes
    local c_nodes = self.complete_nodes.nodes
    local idx = self:current_c():get_idx()
    local skip_count = 0
    for i = 1, idx - 1 do
        skip_count = skip_count + #c_nodes[i].origin
    end

    local i = 1
    while skip_count > 0 do
        skip_count = skip_count - #i_nodes[i].display
        i = i + 1
    end
    if skip_count ~= 0 then
        return
    end

    local raw_str = ""
    local display = ""
    local display_len = #c_nodes[idx].origin
    while #display < display_len do
        raw_str = raw_str .. i_nodes[i].raw_str
        display = display .. i_nodes[i].display
        i = i + 1
    end
    if #display == display_len then
        return raw_str
    end
end

---@param get_responce fun(hiragana: string, raw_str?: string): response
---@param need_raw? boolean
function Session:_convert(get_responce, need_raw)
    self:_mode_validate({ "Input", "Complete", "Convert" })
    if self.ime_mode == "Complete" then
        local hiragana = self:current_c().origin
        local raw_str = need_raw and (self:_search_raw() or hiragana) or nil
        local response = self.complete_nodes._response
        response[self:current_c():get_idx()] = get_responce(hiragana, raw_str)[1]
        self.complete_nodes:new_response(response)
        self:current_c():close()
    else
        if self.ime_mode == "Convert" then
            self:cancel()
        end
        local hiragana = self.input_nodes.display
        local raw_str = need_raw and self.input_nodes:raw_str() or nil
        local response = get_responce(hiragana, raw_str)
        self.complete_nodes = CompleteNodes.new(hiragana, response, self.start_pos, self)
    end
    self:_mode_set("Convert")
    self:current_c():move()
end

function Session:convert_hira()
    self:_convert(Convert.hira)
end

function Session:convert_zen_kata()
    self:_convert(Convert.zen_kata)
end

function Session:convert_zen_eisuu()
    self:_convert(Convert.zen_eisuu, true)
end

function Session:convert_han_kata()
    self:_convert(Convert.han_kata)
end

function Session:convert_han_eisuu()
    self:_convert(Convert.han_eisuu, true)
end

function Session:cancel()
    self:_mode_validate({ "Complete", "Convert" })
    self:current_c():close()
    self.complete_nodes:tail():move()
    self.input_nodes.end_ = self.complete_nodes.end_
    self:_mode_set("Input")
    self.input_nodes:update_buffer()
    self.complete_nodes = nil
end

---@param delta 1 | -1
function Session:insert_item(delta)
    self:_mode_validate("Complete")
    self:current_c():insert_relative(delta)
end

function Session:goto_prev()
    self:_mode_validate({ "Input", "Complete", "Convert" })
    if self.ime_mode == "Input" then
        self.input_nodes:goto_prev()
    elseif self.complete_nodes:goto_prev() then
        self:_complete()
    end
end

function Session:goto_next()
    self:_mode_validate({ "Input", "Complete", "Convert" })
    if self.ime_mode == "Input" then
        self.input_nodes:goto_next()
    elseif self.complete_nodes:goto_next() then
        self:_complete()
    end
end

function Session:goto_head()
    self:_mode_validate({ "Input", "Complete", "Convert" })
    if self.ime_mode == "Input" then
        self.input_nodes:goto_head()
    elseif self.complete_nodes:goto_head() then
        self:_complete()
    end
end

function Session:goto_tail()
    self:_mode_validate({ "Input", "Complete", "Convert" })
    if self.ime_mode == "Input" then
        self.input_nodes:goto_tail()
    elseif self.complete_nodes:goto_tail() then
        self:_complete()
    end
end

function Session:extend()
    self:_mode_validate("Complete")
    self:current_c():extend()
end

function Session:shorten()
    self:_mode_validate("Complete")
    self:current_c():shorten()
end

function Session:confirm()
    self:_mode_validate({ "Input", "Complete", "Convert" })
    if self.ime_mode ~= "Input" then
        self:current_c():close()
        self.complete_nodes:tail():move()
    end
    self:reset()
    self:_mode_set("PreInput")
    self:_update_highlight()
end

function Session:exit()
    if self.ime_mode == "Input" or self.ime_mode == "Complete" then
        self:confirm()
    end
    self:_mode_set("")
    api.nvim_create_augroup(aug_name, { clear = true })
    api.nvim_buf_clear_namespace(0, self.ns_id, 0, -1)
    keymap:del()
    keymap:restore()
    vim.cmd("do User JamExit")
end

return Session
