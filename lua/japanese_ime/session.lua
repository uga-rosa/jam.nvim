local api = vim.api

local CandidateNodes = require("japanese_ime.nodes")
local cgi = require("japanese_ime.cgi")
local abbr = require("japanese_ime.abbr")
local pum = require("japanese_ime.pum")
local _utils = require("japanese_ime.utils")
local utils = _utils.utils
local sa = _utils.sa

---@alias ime_mode
--- | '""'
--- | '"input"'
--- | '"convert"'

---@type ime_mode
vim.b.ime_mode = ""

---@class Session
---@field start_pos integer[] #(1,1) index
---@field nodes CandidateNodes
local Session = {}

function Session:start()
    vim.b.ime_mode = "input"
    self.start_pos = utils.get_pos()
    self.nodes = nil
    abbr:start()
end

function Session:complete()
    vim.b.ime_mode = "convert"
    if self.nodes == nil then
        ---@type string
        local request = api.nvim_get_current_line():sub(self.start_pos[2])
        local response = cgi.get_responce(request)
        self.nodes = CandidateNodes.new(request, response, self.start_pos, self)
    else
        local request = sa.new(self.nodes.nodes)
            :map(function(node)
                return node.origin
            end)
            :concat(",")
        local response = cgi.get_responce(request)
        self.nodes:new_response(response)
    end
    self.nodes:current():complete()
end

---@param dir 1 | -1
function Session:move(dir)
    if vim.b.ime_mode ~= "convert" then
        return
    end
    if (dir == 1 and self.nodes:goto_next()) or (dir == -1 and self.nodes:goto_prev()) then
        self.nodes:current():complete()
    end
end

function Session:confirm()
    if self.nodes then
        self.nodes:tail():move()
    end
    if pum.visible() then
        pum.close()
    end
    self.nodes = nil
    self.start_pos = utils.get_pos()
    vim.b.ime_mode = "input"
end

function Session:exit()
    self:confirm()
    vim.b.ime_mode = ""
    abbr:exit()
end

return Session
