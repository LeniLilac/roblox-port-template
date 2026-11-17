--!strict
-- Tiny assertion helper for specs (tools/lune/specs.luau runs them headless; they also run in
-- Studio). A spec returns `Expect.run(function(t) ... end)`:
--
--   return Expect.run(function(t)
--       t.eq("adds", 3, Sum(1, 2))
--       t.ok("is positive", Sum(1, 2) > 0)
--   end)

export type T = {
	ok: (name: string, condition: boolean, detail: string?) -> (),
	eq: (name: string, expected: any, actual: any) -> (),
	near: (name: string, expected: number, actual: number, tolerance: number?) -> (),
	errors: (name: string, fn: () -> ()) -> (),
}

local Expect = {}

function Expect.run(body: (t: T) -> ()): () -> (number, number, { string })
	return function()
		local passed, failed = 0, 0
		local messages: { string } = {}

		local function ok(name: string, condition: boolean, detail: string?)
			if condition then
				passed += 1
			else
				failed += 1
				table.insert(messages, "FAIL " .. name .. (if detail then ": " .. detail else ""))
			end
		end

		local t: T = {
			ok = ok,
			eq = function(name: string, expected: any, actual: any)
				ok(name, expected == actual, "expected " .. tostring(expected) .. ", got " .. tostring(actual))
			end,
			near = function(name: string, expected: number, actual: number, tolerance: number?)
				local tol = tolerance or 1e-9
				ok(
					name,
					math.abs(expected - actual) <= tol,
					"expected " .. expected .. " ± " .. tol .. ", got " .. actual
				)
			end,
			errors = function(name: string, fn: () -> ())
				ok(name, not pcall(fn), "expected an error")
			end,
		}

		body(t)
		return passed, failed, messages
	end
end

return Expect
