if not arg[1] then
    print("missing argument")
    return
end

local fname = arg[1]
local file = io.open(fname, "r")
assert(file, "Cannot open the file to read: " .. fname)

local new_fname = fname:match("(.+)%..+$") .. ".lua"
local new_file = io.open(new_fname, "w")
assert(new_file, "Cannot open the file to write: " .. new_fname)

local function escape(s)
    return string.gsub(s, '"', '\\"')
end

local buffer = { "return {" }
for line in file:lines() do
    local lhs, rhs = string.match(line, "^(%S+)%s+(%S+)$")
    if lhs and rhs then
        lhs = escape(lhs)
        rhs = escape(rhs)
        table.insert(buffer, ('    ["%s"] = "%s",'):format(lhs, rhs))
    end
end
file:close()
table.insert(buffer, "}")

new_file:write(table.concat(buffer, "\n"))
new_file:close()
