-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2015, Intelibo Ltd                             --
--                                                                   --
-- Project:       LOS                                                --
-- Filename:      events.lua                                         --
-- Description:   events management utility                          --
--                                                                   --
-----------------------------------------------------------------------

local table = require "lrun.util.table"

local assert, type, ipairs, pairs =
	  assert, type, ipairs, pairs

module "los.events"

local handlers = {}

-- registers event listener function
-- @param eventname: string name of the event to listen
-- @param fn: function listener
function register(eventname, fn)
	assert(type(eventname) == "string")
	assert(type(fn) == "function")

	handlers[eventname] = handlers[eventname] or {}
	table.insert(handlers[eventname], fn)
end

-- unregisters event listener function
-- @param eventname: string name of the event to unregister listener from
-- @param fn: function listener
function unregister(eventname, fn)
	assert(not eventname or type(eventname) == "string")
	assert(type(fn) == "function")

	if eventname then
		if handlers[eventname] then
			local idx = table.indexof(handlers[eventname], fn)
			if idx then
				table.remove(handlers[eventname], idx)
			end
		end
	else
		for eventname, eventhandlers in pairs(handlers) do
			local idx = table.indexof(eventhandlers, fn)
			if idx then
				table.remove(eventhandlers, idx)
			end
		end
	end
end

-- trigger named event calling all registered listeners
-- @param eventname: string name of the event to trigger
function trigger(eventname, ...)
	assert(type(eventname) == "string")
		
	if handlers[eventname] then
		for _, fn in ipairs(handlers[eventname]) do
			fn(...)
		end
	end
end
