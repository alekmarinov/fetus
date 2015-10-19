loader = require "los.lospec.loader"
require "los.requires"

for _, name in ipairs(los.lospec.loader.list()) do
	local mod = assert(los.requires(name))
	print(string.format("install %s...", name))
	io.stdout:flush()
	if mod.package.name == "gettext" then
		mod.lfs.delete(mod.path.src.dir)
	end
	local instdir = mod.path.install.dir
	lfs.mkdir(instdir)
	local prefix = mod.api.makepath(instdir, name)
	local cmd = "los -Ddir.install="..prefix.." install "..name.." > "..mod.api.makepath(instdir, name..".log").." 2>&1"
	if os.execute(cmd) == 0 then
		print("OK")
	else
		print("FAILED")
	end
	io.stdout:flush()
end
