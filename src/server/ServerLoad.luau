--!strict
-- Measures the server time each player costs, so the experience's Max Players can be set from
-- real numbers (see docs/porting-guide.md, "Players per server"). Wrap per-player work in
-- ServerLoad.time(); every WINDOW_S seconds the average and peak per frame are rolled up per
-- player, per kind of work and for the whole server. Costs two os.clock() reads per timed call.
--
--   ServerLoad.time(player, "sim", function()
--       simulateTable(player, dt)
--   end)
--   print(ServerLoad.report().serverAvgMs)
--
-- Measure at a worst case (every per-player cap reached), then pick Max Players so the server's
-- average stays well under the 16.7 ms a 60 Hz frame has, with room for Roblox's own work.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ServerLoad = {}

ServerLoad.WINDOW_S = 5

type Meter = {
	frame: number, -- this frame's seconds so far
	sum: number, -- this window's seconds
	peak: number, -- this window's busiest frame
	avgMs: number, -- the last complete window: average ms a frame
	peakMs: number, -- the last complete window: busiest frame, ms
}

export type Report = {
	windowS: number,
	frames: number,
	fps: number,
	serverAvgMs: number,
	serverPeakMs: number,
	players: { [Player]: { avgMs: number, peakMs: number } },
	parts: { [string]: { avgMs: number, peakMs: number } },
}

local function newMeter(): Meter
	return { frame = 0, sum = 0, peak = 0, avgMs = 0, peakMs = 0 }
end

local meters: { [Player]: Meter } = {}
local parts: { [string]: Meter } = {}
local server = newMeter()
local frames = 0
local windowAt = os.clock()
local lastFrames = 0
local lastFps = 0

-- Adds `seconds` of work done for `player` (and under `part`, if given) to the frame under way.
function ServerLoad.add(player: Player, seconds: number, part: string?)
	local m = meters[player]
	if not m then
		m = newMeter()
		meters[player] = m
	end
	m.frame += seconds
	server.frame += seconds
	if part then
		local p = parts[part]
		if not p then
			p = newMeter()
			parts[part] = p
		end
		p.frame += seconds
	end
end

-- Runs `fn` and adds the time it took to `player` under `part`.
function ServerLoad.time(player: Player, part: string, fn: () -> ())
	local started = os.clock()
	fn()
	ServerLoad.add(player, os.clock() - started, part)
end

local function close(m: Meter)
	m.sum += m.frame
	if m.frame > m.peak then
		m.peak = m.frame
	end
	m.frame = 0
end

local function roll(m: Meter, n: number)
	m.avgMs = if n > 0 then m.sum / n * 1000 else 0
	m.peakMs = m.peak * 1000
	m.sum = 0
	m.peak = 0
end

local function endFrame(now: number)
	close(server)
	for _, m in meters do
		close(m)
	end
	for _, m in parts do
		close(m)
	end
	frames += 1
	if now - windowAt >= ServerLoad.WINDOW_S then
		roll(server, frames)
		for _, m in meters do
			roll(m, frames)
		end
		for _, m in parts do
			roll(m, frames)
		end
		lastFrames = frames
		lastFps = frames / (now - windowAt)
		frames = 0
		windowAt = now
	end
end

-- The last complete window.
function ServerLoad.report(): Report
	local players = {}
	for player, m in meters do
		players[player] = { avgMs = m.avgMs, peakMs = m.peakMs }
	end
	local byPart = {}
	for name, m in parts do
		byPart[name] = { avgMs = m.avgMs, peakMs = m.peakMs }
	end
	return {
		windowS = ServerLoad.WINDOW_S,
		frames = lastFrames,
		fps = lastFps,
		serverAvgMs = server.avgMs,
		serverPeakMs = server.peakMs,
		players = players,
		parts = byPart,
	}
end

-- Work timed during a Heartbeat counts toward the frame that the next Heartbeat closes.
RunService.Heartbeat:Connect(function()
	endFrame(os.clock())
end)

Players.PlayerRemoving:Connect(function(player: Player)
	meters[player] = nil
end)

return ServerLoad
