local CompleteNode = require("jam.node.complete_node")
local Nodes = require("jam.node.nodes")
local utils = require("jam.utils")
local sa = require("jam.utils.safe_array")

---@class CompleteNodes: Nodes
---@field nodes CompleteNode[]
---@field selected_node CompleteNode
---@field _dummy_head CompleteNode
---@field _dummy_tail CompleteNode
---@field origin string
---@field session Session
---@field _response response
---@field current fun(): CompleteNode
---@field head fun(): CompleteNode
---@field tail fun(): CompleteNode
local CompleteNodes = setmetatable({}, { __index = Nodes })

---@param origin string
---@param res response
---@param start_pos integer[]
---@return CompleteNodes
function CompleteNodes.new(origin, res, start_pos, session)
    vim.validate({
        res = { res, "t" },
        start_pos = { start_pos, "t" },
        start_row = { start_pos[1], "n" },
        start_col = { start_pos[2], "n" },
    })
    assert(#res > 0)
    local start_row, start_col = unpack(start_pos)

    local result = setmetatable({
        origin = origin,
        nodes = {},
        row = start_row,
        start = start_col,
        end_ = start_col + #origin - 1,
        _response = res,
        session = session,
    }, { __index = CompleteNodes })

    local dummy_head = CompleteNode.new()
    local dummy_tail = CompleteNode.new()
    result._dummy_head = dummy_head
    result._dummy_tail = dummy_tail

    local prev = dummy_head
    local node
    for _, v in ipairs(res) do
        node = CompleteNode.new(v.origin, v.candidates, start_col, start_pos[1], result, session)
        node.prev = prev
        prev.next = node
        start_col = node.end_ + 1
        prev = node
    end
    node.next = dummy_tail
    dummy_tail.prev = node

    result.selected_node = node

    result:fix_nodes()
    result:update_buffer()

    return result
end

function CompleteNodes:update_buffer()
    local text = sa.new(self.nodes)
        :map(function(node)
            return node.selected_candidate
        end)
        :concat()
    utils.set_text(self.row, self.start, self.end_, text)
    self.start = self:head().start
    self.end_ = self:tail().end_
end

---@param response response
function CompleteNodes:new_response(response)
    local start = self:head().start
    for i, v in ipairs(response) do
        start = self.nodes[i]:new_candidates(v.candidates, start)
    end
    self:update_buffer()
end

return CompleteNodes
