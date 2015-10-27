loader = require "los.lospec.loader"
require "los.requires"

exitcode = 0
for _, name in ipairs(los.lospec.loader.list()) do
	local mod = assert(los.requires(name))
	print(string.format("install %s...", name))
	io.stdout:flush()
	lrun.util.lfs.delete(lrun.util.lfs.dirname(mod.conf["dir.src"]))
	local instdir = mod.path.install.dir
	lfs.mkdir(instdir)
	local prefix = mod.api.makepath(instdir, name)
	local cmd = "los -Ddir.install="..prefix.." install "..name.." > "..mod.api.makepath(instdir, name..".log").." 2>&1"
	if os.execute(cmd) == 0 then
		print("OK")
	else
		print("FAILED")
		exitcode = 1
	end
	io.stdout:flush()
end
os.exit(exitcode)
