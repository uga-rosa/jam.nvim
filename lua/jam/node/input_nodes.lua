local api = vim.api

local Nodes = require("jam.node.nodes")
local InputNode = require("jam.node.input_node")
local utils = require("jam.utils")
local sa = require("jam.utils.safe_array")

---@class InputNodes: Nodes
---@field display string
---@field nodes InputNode[]
---@field session Session
---@field current fun(): InputNode
local InputNodes = setmetatable({}, { __index = Nodes })

function InputNodes.new(session)
    return setmetatable({
        session = session,
    }, { __index = InputNodes })
end

function InputNodes:init()
    local pos = utils.get_pos()
    self.start = pos[2]
    self.end_ = pos[2] - 1
    self.row = pos[1]
    self.session.start_pos = pos

    local dummy_head = InputNode.new(self)
    local dummy_tail = InputNode.new(self)
    self._dummy_head = dummy_head
    self._dummy_tail = dummy_tail

    local node = InputNode.new(self.start, self.row, self)

    node.prev = dummy_head
    node.next = dummy_tail
    dummy_head.next = node
    dummy_tail.prev = node

    self.selected_node = node
    self.nodes = { node }
end

function InputNodes:input(char)
    if self.session.ime_mode == "PreInput" then
        if utils.is_whitespace(char) then
            return
        else
            self.session:_mode_set("Input")
            self:init()
        end
    elseif self.session.ime_mode ~= "Input" then
        return
    end
    self.end_ = self.end_ + 1
    self:current():input(char)
    self:update_display()
end

function InputNodes:update_display()
    local display = {}
    for i, node in ipairs(self.nodes) do
        display[i] = node.display
    end
    self.display = table.concat(display)
end

function InputNodes:update_buffer()
    if self.session.ime_mode ~= "Input" then
        return
    end
    local current_line = api.nvim_get_current_line()
    current_line = utils.insert(current_line, self.display, self.start, self.end_)
    api.nvim_set_current_line(current_line)
    self.end_ = self.start + #self.display - 1
    self:current():move()
    self.session:_update_highlight()
end

---@return string
function InputNodes:raw_str()
    return sa.new(self.nodes)
        :map(function(node)
            return node.raw_str
        end)
        :concat()
end

function InputNodes:backspace()
    if self.display == "" then
        return
    end
    local node = self:current()
    if node.display == "" then
        if not node.prev:is_valid() then
            return
        end
        node = node.prev
        self.selected_node = node
        node.next:delete()
    end
    node:reset()
    node.gi:reset()
    node:update_end()
    self:update_display()
    self:update_buffer()
end

function InputNodes:goto_prev()
    if Nodes.goto_prev(self) then
        if self:current().next.display == "" then
            self:current().next:delete()
            if not Nodes.goto_prev(self) then
                return
            end
        end
        local new = InputNode.new(self:current().end_ + 1, self.row, self)
        self:current():insert_next(new)
        Nodes.goto_next(self)
        self:current():move()
    end
end

function InputNodes:goto_next()
    if Nodes.goto_next(self) then
        if self:current().prev.display == "" then
            self:current().prev:delete()
        end
        local new = InputNode.new(self:current().end_ + 1, self.row, self)
        self:current():insert_next(new)
        Nodes.goto_next(self)
        self:current():move()
    end
end

function InputNodes:goto_head()
    if self:current().display == "" then
        self:current():delete()
    end
    local new = InputNode.new(self.start, self.row, self)
    self._dummy_head:insert_next(new)
    self.selected_node = new
    new:move()
end

function InputNodes:goto_tail()
    if self:current().display == "" then
        self:current():delete()
    end
    local new = InputNode.new(self.end_ + 1, self.row, self)
    self:tail():insert_next(new)
    self.selected_node = new
    new:move()
end

return InputNodes
