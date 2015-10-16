-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2015, Intelibo Ltd                             --
--                                                                   --
-- Project:       LOS                                                --
-- Filename:      rollback.lua                                       --
-- Description:   Provides method for rollback on error              --
--                                                                   --
-----------------------------------------------------------------------

local _G, assert, type, table, unpack, tostring, print =
	  _G, assert, type, table, unpack, tostring, print

module "los.rollback"

local rollbacks = {}

function push(description, fn, ...)
	assert(type(description) == "string")
	assert(type(fn) == "function")

	local item = { description = description, fn = fn, args = {...} }
	table.insert(rollbacks, item)
	return item
end

function pop()
	return table.remove(rollbacks)
end

function execute()
   for i = #rollbacks, 1, -1 do
      local item = rollbacks[i]
      local ok = item.fn(unpack(item.args))
      local result = ok and "ok" or "failed"
      _G._log:debug(item.description.." "..result)
   end
end
