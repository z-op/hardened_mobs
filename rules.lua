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

-- Пример: Усиление по глубине
hardened_mobs.register_rule("depth_rule", {
    condition = function(pos, mob_def, rule)
        return pos.y < -50  -- Условие: ниже -50
    end,
    apply = function(self, pos, mob_def, rule)
        local depth = math.abs(math.min(pos.y, 0))
        local multiplier = 1 + depth / 100  -- +1% за каждый блок глубины

        self.health = self.health * multiplier
        self.damage = self.damage * multiplier
    end
})

-- Пример: Усиление по биому
hardened_mobs.register_rule("biome_rule", {
    condition = function(pos, mob_def, rule)
        local biome = minetest.get_biome_name(minetest.get_biome_data(pos).biome)
        return biome == "desert" or biome == "icesheet"
    end,
    apply = function(self, pos, mob_def, rule)
        self.health = self.health * 1.5
        self.walk_velocity = self.walk_velocity * 1.2
    end
})
