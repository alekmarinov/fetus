-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2015, Intelibo Ltd                             --
--                                                                   --
-- Project:       LOS                                                --
-- Filename:      rollback.lua                                       --
-- Description:   Provides method for rollback on error              --
--                                                                   --
-----------------------------------------------------------------------

local assert, type, table, unpack =
	  assert, type, table, unpack

module "los.rollback"

local rollbacks = {}

function push(fn, ...)
	assert(type(fn) == "function")

	local item = { fn = fn, args = {...} }
	table.insert(rollbacks, item)
	return item
end

function pop()
	return table.remove(rollbacks)
end

function execute()
   for i = #rollbacks, 1, -1 do
      local item = rollbacks[i]
      item.fn(unpack(item.args))
   end
end
