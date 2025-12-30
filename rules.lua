-- Hardened Mobs Rules Configuration
-- Add custom rules here

-- Example rule: Harder mobs in specific areas
hardened_mobs.register_rule("danger_zone", {
	description = "Mobs in danger zone are stronger",

	condition = function(pos, mobname)
		-- Define a dangerous area (e.g., around spawn)
		local danger_pos = {x=0, y=0, z=0}
		local radius = 50
		return vector.distance(pos, danger_pos) < radius
	end,

	apply = function(entity, multiplier, pos, mobname)
		-- Double the multiplier in danger zone
		return multiplier * 2.0
	end
})

-- Example rule: Specific mob types get special treatment
hardened_mobs.register_rule("boss_mobs", {
	description = "Boss mobs are always strong",

	condition = function(pos, mobname)
		-- Check if mobname contains "boss"
		return mobname and string.find(mobname:lower(), "boss")
	end,

	apply = function(entity, multiplier, pos, mobname)
		-- Boss mobs minimum multiplier
		return math.max(multiplier, 3.0)
	end
})
