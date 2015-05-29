package = "los"
version = "0.1-1"
source = {
   url = "git+https://git.intelibo.com/intelibo/los.git"
}
description = {
   summary = "los is lua powered development and runtime environment",
   detailed = [[
los is a package management system operating in dependency clean
development and runtime environment emphasized on Lua development.
   ]],
   license = "MIT/X11",
   homepage = "https://git.intelibo.com/intelibo/los"
}
dependencies = {
   "lrun-utils >= 0.1",
   "lrun-net-www-download >= 0.1",
   "luasocket ~> 3"
}
build = {
   type = "builtin",
   install = {
      conf = { "conf/los.conf" },
      bin = { "bin/los" }
   },
   copy_directories = { "lospec", "usable" },
   modules = {
      ["los.requires"] = "lua/los/requires.lua",
      ["los.init"] = "lua/los/init.lua"
   }
}
