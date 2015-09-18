local config  = require "lrun.util.config"
local package = require "los.lospec.package"
describe("Package parser", function()
	_G._conf = assert(config.load("conf/los.conf"))

	local pack1 = {
		name = "$(app.name)",
		version = "1.2",
		source  = "$(repo.opensource)/libfoo-1.2.zip",
		arch = "foo"
	}
	local pack2 = package.parse(pack1)
	it("should return the same package table reference", function()
		assert.is_true(pack1 == pack2)
	end)
	it("should substitute the string variables", function()
		assert.is.equal("los", pack2.name)
	end)
	it("should return the same set of keys", function()
		local keys1 = {}
		for k in pairs(pack1) do
			table.insert(keys1, k)
		end
		local keys2 = {}
		for k in pairs(pack2) do
			table.insert(keys2, k)
		end
		assert.are.same(keys1, keys2)
	end)
end)
