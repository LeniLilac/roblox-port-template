--!strict
-- Short number formatting for HUDs (1.2K, 3.45M, 6.7e21), a common need when porting
-- incremental or economy games. Luau numbers are doubles, so values up to about 1e308 need no
-- big-number library. Also an example of pure shared code that tests/NumberFormatSpec.luau
-- checks headless.

local NumberFormat = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

-- Keeps three significant digits: 1.23K, 12.3K, 123K.
local function significant(value: number): string
	if value >= 100 then
		return string.format("%d", math.floor(value))
	elseif value >= 10 then
		return (string.format("%.1f", math.floor(value * 10) / 10):gsub("%.0$", ""))
	end
	return (string.format("%.2f", math.floor(value * 100) / 100):gsub("%.?0+$", ""))
end

function NumberFormat.short(value: number): string
	if value ~= value then
		return "NaN"
	elseif value == math.huge or value == -math.huge then
		return if value > 0 then "∞" else "-∞"
	elseif value < 0 then
		return "-" .. NumberFormat.short(-value)
	elseif value < 1000 then
		return significant(value)
	end
	local tier = math.floor(math.log10(value) / 3)
	if tier >= #SUFFIXES then
		local exponent = math.floor(math.log10(value))
		return significant(value / 10 ^ exponent) .. "e" .. exponent
	end
	return significant(value / 1000 ^ tier) .. SUFFIXES[tier + 1]
end

return NumberFormat
