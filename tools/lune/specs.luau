-- Runs the specs in tests/ headless with Lune, without Studio:
--
--   lune run tools/lune/specs.luau             every *Spec module
--   lune run tools/lune/specs.luau Save Shop   only specs whose name contains one of the words
--
-- (tools/test.cmd and tools/test.sh wrap it.) Specs and the code they load are required exactly
-- as in Studio: this builds a read-only instance tree from default.project.json and the files
-- under its $path folders (Rojo's naming: Foo.luau ModuleScript, init.luau turns the folder into
-- one, .server/.client scripts, .csv LocalizationTable; scripts carry their `Source`), and gives
-- every module `game`, `script` and an instance-style `require`.
--
-- What Lune's roblox library lacks is stubbed: `Random` (xoshiro128**, so seeded sequences differ
-- from Roblox's), `task`, and small parts of RunService, HttpService and Players. Instance.new and
-- anything else engine- or client-only errors: keep that code out of specs, and test pure logic
-- (economy, data, rules) here. Add stubs to `services` below when shared code needs more.
--
-- A spec is a ModuleScript in tests/ whose name ends in "Spec". It returns a function that
-- returns (passed, failed, messages); tests/Expect.luau builds that for you.
-- Exit code 1 when a spec fails or errors.

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local stdio = require("@lune/stdio")
local task = require("@lune/task")

local PROJECT = "default.project.json"
if not fs.isFile(PROJECT) then
	stdio.ewrite("run from the repository root (no " .. PROJECT .. " here)\n")
	process.exit(2)
end

-- Random ----------------------------------------------------------------------------------------

local MASK = 0xFFFFFFFF
local band, bxor, lshift, rshift, lrotate = bit32.band, bit32.bxor, bit32.lshift, bit32.rshift, bit32.lrotate

local function mul32(a: number, b: number): number
	-- Low 32 bits of a * b without losing precision past 2^53.
	local aHi, aLo = rshift(a, 16), band(a, 0xFFFF)
	return band(band(aHi * b, 0xFFFF) * 0x10000 + aLo * b, MASK)
end

local Random = {}
Random.__index = Random
Random.__type = "Random"

local seedCounter = 0
function Random.new(seed: number?)
	if seed == nil then
		seedCounter += 1
		seed = os.clock() * 1e6 + seedCounter
	end
	local s = math.floor(seed :: number)
	local lo, hi = band(s % 2 ^ 32, MASK), band(math.floor(s / 2 ^ 32), MASK)
	-- splitmix32 to fill the four state words
	local x = bxor(lo, mul32(hi, 0x9E3779B9))
	local state = {}
	for i = 1, 4 do
		x = band(x + 0x9E3779B9, MASK)
		local z = x
		z = mul32(bxor(z, rshift(z, 16)), 0x85EBCA6B)
		z = mul32(bxor(z, rshift(z, 13)), 0xC2B2AE35)
		state[i] = bxor(z, rshift(z, 16))
	end
	if state[1] == 0 and state[2] == 0 and state[3] == 0 and state[4] == 0 then
		state[1] = 1
	end
	return setmetatable({ s = state }, Random)
end

function Random._next(self): number
	local s = self.s
	local result = mul32(lrotate(mul32(s[2], 5), 7), 9)
	local t = lshift(s[2], 9)
	s[3] = bxor(s[3], s[1])
	s[4] = bxor(s[4], s[2])
	s[2] = bxor(s[2], s[3])
	s[1] = bxor(s[1], s[4])
	s[3] = bxor(s[3], t)
	s[4] = lrotate(s[4], 11)
	return result
end

function Random._unit(self): number
	local a, b = rshift(self:_next(), 5), rshift(self:_next(), 6)
	return (a * 67108864 + b) / 9007199254740992 -- [0, 1) with 53 bits
end

function Random.NextNumber(self, min: number?, max: number?): number
	local lo, hi = min or 0, max or 1
	return lo + self:_unit() * (hi - lo)
end

function Random.NextInteger(self, min: number, max: number): number
	if max < min then
		min, max = max, min
	end
	return min + math.floor(self:_unit() * (max - min + 1))
end

function Random.NextUnitVector(self)
	local z = self:NextNumber(-1, 1)
	local a = self:NextNumber(0, 2 * math.pi)
	local r = math.sqrt(1 - z * z)
	return roblox.Vector3.new(r * math.cos(a), r * math.sin(a), z)
end

function Random.Shuffle(self, t: { any })
	for i = #t, 2, -1 do
		local j = self:NextInteger(1, i)
		t[i], t[j] = t[j], t[i]
	end
end

function Random.Clone(self)
	return setmetatable({ s = table.clone(self.s) }, Random)
end

-- Instance tree -----------------------------------------------------------------------------------

type State = {
	name: string,
	class: string,
	parent: any,
	source: string?, -- file whose code a script runs, or a .csv
	dir: string?, -- folder whose entries are children
	explicit: { any },
	children: { any }?,
	props: { [string]: any },
}

local states: { [any]: State } = setmetatable({}, { __mode = "k" }) :: any
local nodeMeta = {}

local function newNode(name: string, class: string, parent: any, source: string?, dir: string?): any
	local node = setmetatable({}, nodeMeta)
	states[node] = {
		name = name,
		class = class,
		parent = parent,
		source = source,
		dir = dir,
		explicit = {},
		props = {},
	}
	return node
end

local SCRIPT_CLASSES = { ModuleScript = true, Script = true, LocalScript = true }

-- The node a file or folder becomes (nil for files Rojo would skip or that aren't needed here).
local function fromPath(name: string?, parent: any, path: string): any?
	if fs.isDir(path) then
		local folderName = name or path:match("[^/]+$") :: string
		for _, init in
			{
				{ "init.luau", "ModuleScript" },
				{ "init.lua", "ModuleScript" },
				{ "init.server.luau", "Script" },
				{ "init.client.luau", "LocalScript" },
			}
		do
			if fs.isFile(path .. "/" .. init[1]) then
				return newNode(folderName, init[2], parent, path .. "/" .. init[1], path)
			end
		end
		return newNode(folderName, "Folder", parent, nil, path)
	end
	local file = path:match("[^/]+$") :: string
	if file:match("^init%.") or file:match("%.meta%.json$") then
		return nil
	end
	local base, class
	base = file:match("^(.+)%.server%.luau?$")
	if base then
		class = "Script"
	else
		base = file:match("^(.+)%.client%.luau?$")
		if base then
			class = "LocalScript"
		else
			base = file:match("^(.+)%.luau?$")
			if base then
				class = "ModuleScript"
			else
				base = file:match("^(.+)%.csv$")
				if base then
					class = "LocalizationTable"
				end
			end
		end
	end
	if not base then
		return nil
	end
	return newNode(name or base, class, parent, path, nil)
end

local function childrenOf(node: any): { any }
	local st = states[node]
	if st.children then
		return st.children
	end
	local list = table.clone(st.explicit)
	local dir = st.dir
	if dir then
		local entries = fs.readDir(dir)
		table.sort(entries)
		for _, entry in entries do
			local child = fromPath(nil, node, dir .. "/" .. entry)
			if child then
				table.insert(list, child)
			end
		end
	end
	st.children = list
	return list
end

local function findChild(node: any, name: string): any?
	for _, child in childrenOf(node) do
		if states[child].name == name then
			return child
		end
	end
	return nil
end

local function fullName(node: any): string
	local st = states[node]
	if st.parent == nil or states[st.parent].class == "DataModel" then
		return st.name
	end
	return fullName(st.parent) .. "." .. st.name
end

-- Minimal CSV reader (quoted fields, doubled quotes, newlines inside quotes).
local function parseCsv(text: string): { { string } }
	local rows, row, field = {}, {}, {}
	local i, n, quoted = 1, #text, false
	while i <= n do
		local c = string.sub(text, i, i)
		if quoted then
			if c == '"' then
				if string.sub(text, i + 1, i + 1) == '"' then
					table.insert(field, '"')
					i += 1
				else
					quoted = false
				end
			else
				table.insert(field, c)
			end
		elseif c == '"' then
			quoted = true
		elseif c == "," then
			table.insert(row, table.concat(field))
			field = {}
		elseif c == "\n" or c == "\r" then
			if c == "\r" and string.sub(text, i + 1, i + 1) == "\n" then
				i += 1
			end
			table.insert(row, table.concat(field))
			table.insert(rows, row)
			row, field = {}, {}
		else
			table.insert(field, c)
		end
		i += 1
	end
	if #field > 0 or #row > 0 then
		table.insert(row, table.concat(field))
		table.insert(rows, row)
	end
	return rows
end

local methods = {}

function methods.FindFirstChild(self: any, name: string, recursive: boolean?): any?
	local direct = findChild(self, name)
	if direct or not recursive then
		return direct
	end
	for _, child in childrenOf(self) do
		local found = methods.FindFirstChild(child, name, true)
		if found then
			return found
		end
	end
	return nil
end

function methods.WaitForChild(self: any, name: string): any
	local child = findChild(self, name)
	if not child then
		error(string.format("WaitForChild: %s has no child %q (headless specs can't wait)", fullName(self), name), 2)
	end
	return child
end

function methods.GetChildren(self: any): { any }
	return table.clone(childrenOf(self))
end

function methods.GetDescendants(self: any): { any }
	local out = {}
	local function walk(node: any)
		for _, child in childrenOf(node) do
			table.insert(out, child)
			walk(child)
		end
	end
	walk(self)
	return out
end

function methods.IsA(self: any, class: string): boolean
	local own = states[self].class
	return own == class
		or class == "Instance"
		or (class == "LuaSourceContainer" and SCRIPT_CLASSES[own] == true)
		or (class == "BaseScript" and (own == "Script" or own == "LocalScript"))
end

function methods.GetFullName(self: any): string
	return fullName(self)
end

function methods.IsDescendantOf(self: any, other: any): boolean
	local p = states[self].parent
	while p do
		if p == other then
			return true
		end
		p = states[p].parent
	end
	return false
end

function methods.FindFirstAncestor(self: any, name: string): any?
	local p = states[self].parent
	while p do
		if states[p].name == name then
			return p
		end
		p = states[p].parent
	end
	return nil
end

function methods.GetAttribute(_self: any, _name: string): any
	return nil
end

-- LocalizationTable:GetEntries(), from the .csv (Key, Source, Context, Example, locale columns).
function methods.GetEntries(self: any): { any }
	local st = states[self]
	if st.class ~= "LocalizationTable" or not st.source then
		error("GetEntries is only for LocalizationTables", 2)
	end
	local rows = parseCsv(fs.readFile(st.source :: string))
	local header = rows[1] or {}
	local entries = {}
	for r = 2, #rows do
		local row = rows[r]
		local values = {}
		for c = 5, #header do
			local v = row[c]
			if v and v ~= "" then
				values[header[c]] = v
			end
		end
		table.insert(entries, {
			Key = row[1] or "",
			Source = row[2] or "",
			Context = row[3] or "",
			Example = row[4] or "",
			Values = values,
		})
	end
	return entries
end

nodeMeta.__index = function(self: any, key: string): any
	local st = states[self]
	if key == "Name" then
		return st.name
	elseif key == "ClassName" then
		return st.class
	elseif key == "Parent" then
		return st.parent
	end
	local prop = st.props[key]
	if prop ~= nil then
		return prop
	end
	local method = methods[key]
	if method then
		return method
	end
	local child = findChild(self, key)
	if child then
		return child
	end
	error(string.format("%s is not a valid member of %s %q", tostring(key), st.class, st.name), 2)
end
nodeMeta.__newindex = function(self: any, key: string, _value: any)
	error(string.format("headless specs can't set %s.%s", fullName(self), tostring(key)), 2)
end
nodeMeta.__tostring = function(self: any): string
	return states[self].name
end

-- The DataModel from the project file.
local game = newNode("Game", "DataModel", nil, nil, nil)

local function build(node: any, spec: { [string]: any })
	for key, value in spec do
		if string.sub(key, 1, 1) ~= "$" and type(value) == "table" then
			local path = value["$path"]
			if type(path) == "table" then
				path = path.optional
			end
			local child
			if type(path) == "string" then
				if fs.isDir(path) or fs.isFile(path) then
					child = fromPath(key, node, path)
				end
			else
				child = newNode(key, value["$className"] or key, node, nil, nil)
			end
			if child then
				table.insert(states[node].explicit, child)
				build(child, value)
			end
		end
	end
end
build(game, serde.decode("json", fs.readFile(PROJECT)).tree)

-- Lune's fs calls yield, and a metamethod (`node.Child`) can't: list every folder now, and read
-- every script's `Source` (specs that scan the code read it, as plugin-level Studio code can).
local function prime(node: any)
	local st = states[node]
	if SCRIPT_CLASSES[st.class] and st.source then
		st.props.Source = fs.readFile(st.source :: string)
	end
	for _, child in childrenOf(node) do
		prime(child)
	end
end
prime(game)

-- Services the shared code asks for that the project file doesn't define.
local services: { [string]: any } = {
	RunService = {
		IsServer = function()
			return true
		end,
		IsClient = function()
			return false
		end,
		IsStudio = function()
			return true
		end,
	},
	HttpService = {
		JSONEncode = function(_self: any, value: any): string
			return serde.encode("json", value)
		end,
		JSONDecode = function(_self: any, text: string): any
			return serde.decode("json", text)
		end,
	},
	Players = {
		GetPlayers = function()
			return {}
		end,
	},
}

states[game].props.GetService = function(_self: any, name: string): any
	return findChild(game, name) or services[name] or error("headless specs have no service " .. name, 2)
end
states[game].props.Workspace = findChild(game, "Workspace")

-- Modules ------------------------------------------------------------------------------------------

local loaded: { [any]: { value: any } } = {}
local loading: { [any]: boolean } = {}

local datatypes = {}
for _, name in
	{
		"Vector2",
		"Vector3",
		"CFrame",
		"Color3",
		"UDim",
		"UDim2",
		"Rect",
		"NumberRange",
		"NumberSequence",
		"NumberSequenceKeypoint",
		"ColorSequence",
		"ColorSequenceKeypoint",
		"Enum",
		"BrickColor",
		"Font",
	}
do
	datatypes[name] = (roblox :: any)[name]
end

local requireModule

local function environment(node: any): { [string]: any }
	local env = table.clone(datatypes)
	env.game = game
	env.workspace = states[game].props.Workspace
	env.script = node
	env.require = requireModule
	env.Random = Random
	env.task = task
	env.tick = os.clock
	env.Instance = {
		new = function(class: string)
			error("Instance.new(" .. class .. ") isn't available in headless specs", 2)
		end,
	}
	return env
end

function requireModule(target: any): any
	if type(target) ~= "table" or states[target] == nil then
		error("headless require takes a ModuleScript instance, got " .. typeof(target), 2)
	end
	local st = states[target]
	if st.class ~= "ModuleScript" then
		error(fullName(target) .. " is a " .. st.class .. ", not a ModuleScript", 2)
	end
	local cached = loaded[target]
	if cached then
		return cached.value
	end
	if loading[target] then
		error("require cycle at " .. fullName(target), 2)
	end
	loading[target] = true
	local source = fs.readFile(st.source :: string)
	local chunk = luau.load(source, { debugName = st.source, environment = environment(target) })
	local value = chunk()
	loading[target] = nil
	loaded[target] = { value = value }
	return value
end

-- Run ------------------------------------------------------------------------------------------------

local filters = {}
for _, arg in process.args do
	table.insert(filters, string.lower(arg))
end

local function wanted(name: string): boolean
	if #filters == 0 then
		return true
	end
	local lower = string.lower(name)
	for _, f in filters do
		if string.find(lower, f, 1, true) then
			return true
		end
	end
	return false
end

local tests = methods.FindFirstChild(game, "ServerStorage") and methods.FindFirstChild(game.ServerStorage, "Tests")
if not tests then
	stdio.ewrite("no ServerStorage.Tests in " .. PROJECT .. "\n")
	process.exit(2)
end

local totalPassed, totalFailed, errored, ran = 0, 0, 0, 0
local started = os.clock()
for _, child in methods.GetChildren(tests) do
	local name = states[child].name
	if states[child].class == "ModuleScript" and string.sub(name, -4) == "Spec" and wanted(name) then
		ran += 1
		local ok, passed, failed, messages = pcall(function()
			local run = requireModule(child)
			return run()
		end)
		if ok then
			totalPassed += passed
			totalFailed += failed
			print(string.format("%s: %d passed, %d failed", name, passed, failed))
			for _, message in messages do
				print("  " .. message)
			end
		else
			errored += 1
			print(string.format("%s: ERROR %s", name, tostring(passed)))
		end
	end
end
print(
	string.format(
		"total: %d passed, %d failed%s (%d specs, %.2f s)",
		totalPassed,
		totalFailed,
		if errored > 0 then string.format(", %d errored", errored) else "",
		ran,
		os.clock() - started
	)
)
if ran == 0 then
	stdio.ewrite("no spec matched\n")
	process.exit(2)
end
process.exit(if totalFailed > 0 or errored > 0 then 1 else 0)
