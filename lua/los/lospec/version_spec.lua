local version = require "los.lospec.version"
describe("Version parser", function()
	for n = 1, 5 do
		it("should parse "..n.." version number", function()
			local v = {}
			for k = 1, n do
				table.insert(v, k)
			end
			v.string = table.concat(v, ".")
			local parsed = version.parse(v.string)
			assert.are.same(parsed, v)
		end)
	end

	local testverA = "1.2a"
	it("should parse "..testverA.." version number", function()
		local parsed = version.parse(testverA)
		assert.is_true(parsed[3] < 1)
		parsed[3] = nil
		assert.are.same({[1] = 1, [2] = 2, string = "1.2a"}, parsed)
	end)

	local testverB = "1.2b"
	local parsedA = version.parse(testverA)
	local parsedB = version.parse(testverB)
	it("should parse "..testverA.." as near to "..testverB.." version number", function()
		assert.is_near(parsedA[3], parsedB[3], 0.001)
	end)

	it("should parse "..testverA.." < "..testverB.." version number", function()
		assert.is_true(parsedA[3] < parsedB[3])
	end)

	local testverRC = "1.2rc"
	local parsedRC = version.parse(testverRC)
	it("should parse "..testverRC.." version number", function()
		assert.are.same({[1] = 1, [2] = 2, [3] = -1000, string = "1.2rc"}, parsedRC)
	end)

	local testverRCA = "1.2rca"
	it("should parse "..testverRC.." < "..testverRCA.." version number", function()
		local parsedRCA = version.parse(testverRCA)
		assert.is_true(parsedRC[3] < parsedRCA[3])
	end)
end)

describe("Constraints parser", function()
	local constring = ">= 1.2, <2"
	it("should parse 2 constaints "..constring, function()
		local constraints = version.parseconstraints(constring)
		assert.is.equal(#constraints, 2)
	end)
	it("should parse 2 constaints as expected", function()
		local constraints = version.parseconstraints(constring)
		assert.are.same({
			[1] = {op = ">=", version = {[1] = 1, [2] = 2, string = "1.2"}},
			[2] = {op = "<", version = {[1] = 2, string = "2"}}
		}, constraints)
	end)
end)

describe("Dependency parser", function()
	local depstring = "foo >= 1.2, <2"
	it("should parse dependency description "..depstring.." as expected", function()
		local dep = version.parsedep(depstring)
		assert.are.same({ name = "foo", constraints = {
			[1] = {op = ">=", version = {[1] = 1, [2] = 2, string = "1.2"}},
			[2] = {op = "<", version = {[1] = 2, string = "2"}}
		}}, dep)
	end)
end)

describe("Find best dependency", function()
	local function map(func, array)
		local new_array = {}
		for i,v in ipairs(array) do
		new_array[i] = func(v)
		end
		return new_array
	end
	local vstrings = {"1.0", "1.1", "1.1a", "1.1b", "2.0"}
	local versions = map(version.parse, vstrings)
	local constring = "> 1.0, < 2"

	it("should find best of "..table.concat(vstrings, ", ").." for constraints "..constring, function()
		local constraints = version.parseconstraints(constring)
		local idx = version.bestindexof(versions, constraints)
		assert.is.equal(4, idx)
	end)

	it("should find best of "..table.concat(vstrings, ", ").." for no constraints", function()
		local constraints = version.parsedep("foo").constraints
		local idx = version.bestindexof(versions, constraints)
		assert.is.equal(5, idx)
	end)
end)
