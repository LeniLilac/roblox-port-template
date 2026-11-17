--!strict
-- Per-player token buckets for remotes. A client can fire remotes at the engine's throttle
-- (hundreds a second, shared by all remotes); a bucket drops the excess silently, so a flood
-- costs the server one table lookup per request instead of real work or a reply.
--
--   local RateLimit = require(script.Parent.RateLimit)
--   local buyLimit = RateLimit.new(5, 10) -- 5 a second, bursts of 10
--   Remotes.Buy.OnServerEvent:Connect(function(player, itemId)
--       if not buyLimit:allow(player) then return end
--       ...
--   end)

local Players = game:GetService("Players")

export type Limiter = {
	allow: (self: Limiter, player: Player) -> boolean,
}

type Bucket = { tokens: number, at: number }

local RateLimit = {}

local limiters: { { [Player]: Bucket } } = {}

-- A bucket per player, refilled at `rate` tokens a second up to `burst`; each allowed request
-- takes one.
function RateLimit.new(rate: number, burst: number): Limiter
	local buckets: { [Player]: Bucket } = {}
	table.insert(limiters, buckets)
	local limiter = {}
	function limiter.allow(_self: Limiter, player: Player): boolean
		local now = os.clock()
		local b = buckets[player]
		if not b then
			b = { tokens = burst, at = now }
			buckets[player] = b
		end
		b.tokens = math.min(burst, b.tokens + (now - b.at) * rate)
		b.at = now
		if b.tokens < 1 then
			return false
		end
		b.tokens -= 1
		return true
	end
	return limiter :: Limiter
end

-- A shared default for requests a person makes by tapping (menus, purchases, settings): far
-- above what anyone can tap, far below a flood.
RateLimit.menu = RateLimit.new(20, 40)

Players.PlayerRemoving:Connect(function(player: Player)
	for _, buckets in limiters do
		buckets[player] = nil
	end
end)

return RateLimit
