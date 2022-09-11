local api = vim.api

local CompleteNodes = require("japanese_ime.node.complete_nodes")
local InputStatus = require("japanese_ime.input.status")
local cgi = require("japanese_ime.cgi")
local pum = require("japanese_ime.utils.pum")
local utils = require("japanese_ime.utils")
local sa = require("japanese_ime.utils.safe_array")

local aug_name = "japanese_ime"

---@alias ime_mode
--- | '""'
--- | '"PreInput"'
--- | '"Input"'
--- | '"Convert"'

---@type ime_mode
vim.b.ime_mode = ""

---@class Session
---@field start_pos integer[] #(1,1) index
---@field completeNodes CompleteNodes
---@field input_status InputStatus
local Session = {}

function Session:start()
    vim.b.ime_mode = "PreInput"
    self.start_pos = utils.get_pos()
    self.completeNodes = nil
    self.input_status = InputStatus.new(self)
    api.nvim_create_augroup(aug_name, { clear = true })
    api.nvim_create_autocmd("InsertCharPre", {
        group = aug_name,
        buffer = 0,
        callback = function()
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
end

function Session:backspace()
    self.input_status:backspace()
end

function Session:complete()
    vim.b.ime_mode = "Convert"
    if self.completeNodes == nil then
        ---@type string
        local request = self.input_status.display
        local response = cgi.get_responce(request)
        self.completeNodes = CompleteNodes.new(request, response, self.start_pos, self)
    else
        local request = sa.new(self.completeNodes.nodes)
            :map(function(node)
                return node.origin
            end)
            :concat(",")
        local response = cgi.get_responce(request)
        self.completeNodes:new_response(response)
    end
    self.completeNodes:current():complete()
end

---@param delta integer
function Session:insert_item(delta)
    self.completeNodes:current():insert_relative(delta)
end

---@param dir 1 | -1
function Session:move(dir)
    if vim.b.ime_mode ~= "Convert" then
        return
    end
    if
        (dir == 1 and self.completeNodes:goto_next())
        or (dir == -1 and self.completeNodes:goto_prev())
    then
        self.completeNodes:current():complete()
    end
end

function Session:confirm()
    if self.completeNodes then
        self.completeNodes:tail():move()
    end
    if pum.visible() then
        pum.close()
    end
    self.start_pos = utils.get_pos()
    self.completeNodes = nil
    self.input_status = InputStatus.new(self)
    vim.b.ime_mode = "PreInput"
end

function Session:exit()
    self:confirm()
    vim.b.ime_mode = ""
    api.nvim_create_augroup(aug_name, { clear = true })
end

return Session
