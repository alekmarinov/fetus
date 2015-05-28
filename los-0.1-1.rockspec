package = "los"
version = "0.1-1"
source = {
   url = "git+https://git.intelibo.com/intelibo/los.git"
}
description = {
   summary = "los is lua powered development and runtime environment",
   detailed = [[
      los is a packaging tool providing development and runtime environment for luarocks
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
      ["los.env"] = "lua/los/env.lua",
      ["los.init"] = "lua/los/init.lua"
   }
}
