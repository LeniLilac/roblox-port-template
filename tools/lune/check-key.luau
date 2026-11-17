-- Checks the Open Cloud key in ASPHALT_API_KEY without printing it: asks Roblox who owns the
-- key and what it may do, and prints only that.
--
--   lune run tools/lune/check-key.luau      (tools/check-key.cmd and .sh load .env first)
--
-- Set EXPECTED_KEY_OWNER to a user ID to get a warning when the key belongs to someone else
-- (for example your main account instead of the uploader account).

local net = require("@lune/net")
local process = require("@lune/process")
local serde = require("@lune/serde")
local stdio = require("@lune/stdio")

local key = process.env.ASPHALT_API_KEY
if key == nil or key == "" then
	stdio.ewrite("ASPHALT_API_KEY is not set. Copy .env.example to .env and add your Open Cloud key.\n")
	process.exit(1)
end

local response = net.request({
	url = "https://apis.roblox.com/api-keys/v1/introspect",
	method = "POST",
	headers = { ["Content-Type"] = "application/json" },
	body = serde.encode("json", { apiKey = key }),
})

if not response.ok then
	stdio.ewrite(
		string.format("Introspect failed (HTTP %d). The key is wrong, revoked or expired.\n", response.statusCode)
	)
	process.exit(1)
end

local info = serde.decode("json", response.body)
-- Never print anything that could hold the key itself.
for _, field in { "apiKey", "key", "secret" } do
	info[field] = nil
end
print(serde.encode("json", info, true))

local expected = process.env.EXPECTED_KEY_OWNER
if expected and expected ~= "" and tostring(info.authorizedUserId) ~= expected then
	stdio.ewrite(string.format("warning: the key belongs to user %s, expected %s\n", tostring(info.authorizedUserId), expected))
end
