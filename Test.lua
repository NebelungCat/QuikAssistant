enum = require("enum")
sizes = { "SMALL", "MEDIUM", "BIG" }
operations = { "Buy", "Sell" }
Size = enum.new("Size", sizes)
Operation = enum.new("Operation", operations)
print(Size) -- "<enum 'Size'>"
print(Size.SMALL) -- "<Size.SMALL: 1>"
print(Size.SMALL.name) -- "SMALL"
print(Size.SMALL.value) -- 1
assert(Size.SMALL ~= Size.BIG) -- true
assert(Size.SMALL < Size.BIG) -- error "Unsupported operation"
assert(Size[1] == Size.SMALL) -- true
print("Operation.S.value") -- 1

local ddd = Operation.Sell

print(ddd) -- 1

-- Size[5] -- error "Invalid enum member: 5"
-- -- Enums cannot be modified
-- Size.MINI -- error "Invalid enum: MINI"
-- assert(Size.BIG.something == nil) -- true
-- Size.MEDIUM.other = 1 -- error "Cannot set fields in enum value"
-- -- Keys cannot be reused
-- Color = enum.new("Color", {"RED", "RED"}) -- error "Attempted to reuse key: 'RED'"
