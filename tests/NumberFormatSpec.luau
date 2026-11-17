--!strict
-- Example spec: runs headless with `tools/test.cmd` (or `tools/test.sh`) and in CI.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Expect = require(script.Parent.Expect)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)

return Expect.run(function(t)
	local short = NumberFormat.short
	t.eq("small whole", "7", short(7))
	t.eq("small fraction", "1.5", short(1.5))
	t.eq("hundreds", "999", short(999))
	t.eq("thousands", "1.23K", short(1234))
	t.eq("tens of thousands", "12.3K", short(12345))
	t.eq("hundreds of thousands", "123K", short(123456))
	t.eq("millions", "3.45M", short(3456789))
	t.eq("rounds down, never up", "999K", short(999999))
	t.eq("negative", "-2.5K", short(-2500))
	t.eq("past the suffixes", "1.23e39", short(1.234e39))
	t.eq("infinity", "∞", short(math.huge))
	t.eq("not a number", "NaN", short(0 / 0))
end)
