local fn = vim.fn

local pum = {}

---Close current popup menu.
function pum.close()
    fn["pum#close"]()
end

---Returns `Dictionary` like `complete_info()`.
---If {what} is supplied, then only the items listed in {what}
---are returned.
---@param what? table
---@return table
function pum.complete_info(what)
    return fn["pum#complete_info"](what)
end

---Returns like `pum_getpos()` result.
---     height		window height
---     width		window width
---     row		screen position row (0 origin)
---     col		screen position col (0 origin)
---     size		total number of items
---     scrollbar	v:false
function pum.get_pos()
    fn["pum#get_pos"]()
end

---Open popup menu like `complete()`.
---{startcol} is the byte offset in the line where the completed
---text start.
---Note: {startcol} is 1 origin like `col()`.
---{items} must be a `List`.  See `complete-items` for the kind
---of items.  You can use following special key.
---
---  	highlights:  Custom highlights.
---  		type	 "abbr" or "kind" or "menu"
---  		name	highlight name.  It is used for
---  			`prop_type_add()` in Vim.
---  			Note: It must be unique.
---  		hl_group	highlight group
---  		(`highlight-groups`)
---  		col	highlight start column (0 origin)
---  		width	highlight end column width
---  	Note: It is experimental feature.
---
---Note: If 'completeopt' contains "noinsert", the first item is
---selected automatically, but it increases screen flicker.
---@param startcol integer #1-index
---@param items table #`:h complete-items`
function pum.open(startcol, items)
    fn["pum#open"](startcol, items)
end

---Set {option-name} option to {value}.
---If {dict} is available, the key is {option-name} and the value
---is {value}. See `pum-options` for available {option-name}.
---@param option_name string
---@param value unknown
---@overload fun(dict: table)
function pum.set_option(option_name, value)
    fn["pum#set_option"](option_name, value)
end

---If it is `v:true`, auto completion plugin must be skipped auto
---completion.
---@return boolean
function pum.skip_complete()
    return fn["pum#skip_complete"]()
end

---Returns `v:true` if the popup menu is visible like pumvisible()`.
---@return boolean
function pum.visible()
    return fn["pum#visible"]()
end

local map = {}

---Cancel the select and close the popup.
---Note: It must not be called in `:map-<expr>`.
function map.cancel()
    fn["pum#map#cancel"]()
end

---Insert the select and close the popup.
---Note: It must not be called in `:map-<expr>`.
function map.confirm()
    fn["pum#map#confirm"]()
end

---Move forward or backward {delta} number and insert the
---candidate.
---Note: It must not be called in `:map-<expr>`.
function map.insert_relative(delta)
    fn["pum#map#insert_relative"](delta)
end

---Move forward or backward "{delta} * page height" number and
---insert the candidate.
---Note: It must not be called in `:map-<expr>`.
function map.insert_relative_page(delta)
    fn["pum#map#insert_relative_page"](delta)
end

---Move forward or backward {delta} number and select the
---candidate.
---Note: It must not be called in `:map-<expr>`.
function map.select_relative(delta)
    fn["pum#map#select_relative"](delta)
end

---Move forward or backward "{delta} * page height" number and
---select the candidate.
---Note: It must not be called in `:map-<expr>`.
function map.select_relative_page(delta)
    fn["pum#map#select_relative_page"](delta)
end

pum.map = map

---==========================================================
---             Original Utilities
---==========================================================

function pum.selected_word()
    local p = fn["pum#_get"]()
    return p.cursor > 0 and p.items[p.cursor].word or p.orig_input
end

return pum
