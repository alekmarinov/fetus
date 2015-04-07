-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2015,  Intelibo Ltd                            --
--                                                                   --
-- Project:       LRun                                               --
-- Filename:      start.lua                                          --
-- Description:   Lua programs starter                               --
--                                                                   --
----------------------------------------------------------------------- 

local args = {...}
local program = require (args[1])
os.exit(program.main(select(2, ...)))
