# hardened_mobs

Hardened Mobs Mod
English
Overview

Hardened Mobs is a Minetest mod that dynamically increases mob difficulty based on various factors like depth, distance from world origin, time of day, and biome. It's designed to work with Mobs Redo API to provide a more challenging gameplay experience.
Features

    Dynamic Difficulty Scaling: Mobs become stronger based on location and environmental factors

    Depth-Based Scaling: Mobs become tougher the deeper you go underground

    Configurable Multipliers: Adjust health, damage, and other stats through config files

    Visual Effects: Option to show particles and visual indicators on strengthened mobs

    Mob-Specific Rules: Define custom rules for specific mob types or locations

    Whitelist/Blacklist Support: Control exactly which mobs are affected

Installation

    Download the mod

    Place it in your Minetest mods directory

    Enable it in your world settings

Configuration

All configuration is done in config.lua. Key settings include:
lua

hardened_mobs.config = {
    enabled = true,
    global_multiplier = 2.0,
    depth_enabled = true,
    depth_start = 0,
    depth_multiplier = 0.005,
    show_particles = true,
    -- ... other settings
}

Custom Rules

Create custom rules in rules.lua:
lua

hardened_mobs.register_rule("danger_zone", {
    description = "Mobs in danger zone are stronger",
    condition = function(pos, mobname)
        return vector.distance(pos, {x=0, y=0, z=0}) < 50
    end,
    apply = function(entity, multiplier, pos, mobname)
        return multiplier * 2.0
    end
})

Dependencies

    Mobs Redo (or any mob system using _cmi_is_mob flag)

License

GPLv3 License
Русский
Обзор

Hardened Mobs — это мод для Minetest, который динамически увеличивает сложность мобов в зависимости от различных факторов: глубины, расстояния от центра мира, времени суток и биома. Мод разработан для работы с Mobs Redo API и предоставляет более сложный игровой опыт.
Возможности

    Динамическое масштабирование сложности: Мобы становятся сильнее в зависимости от местоположения и окружающих условий

    Зависимость от глубины: Чем глубже под землёй, тем сильнее мобы

    Настраиваемые множители: Настройка здоровья, урона и других характеристик через конфигурационные файлы

    Визуальные эффекты: Опция показа частиц и визуальных индикаторов на усиленных мобах

    Правила для конкретных мобов: Определение пользовательских правил для определённых типов мобов или мест

    Поддержка белого/чёрного списков: Точный контроль над тем, какие мобы подвергаются усилению

Установка

    Скачайте мод

    Поместите его в директорию mods Minetest

    Включите его в настройках мира

Конфигурация

Вся конфигурация находится в файле config.lua. Основные настройки:
lua

hardened_mobs.config = {
    enabled = true,
    global_multiplier = 2.0,
    depth_enabled = true,
    depth_start = 0,
    depth_multiplier = 0.005,
    show_particles = true,
    -- ... другие настройки
}

Пользовательские правила

Создавайте пользовательские правила в файле rules.lua:
lua

hardened_mobs.register_rule("danger_zone", {
    description = "Мобы в опасной зоне сильнее",
    condition = function(pos, mobname)
        return vector.distance(pos, {x=0, y=0, z=0}) < 50
    end,
    apply = function(entity, multiplier, pos, mobname)
        return multiplier * 2.0
    end
})

Зависимости

    Mobs Redo (или любая система мобов, использующая флаг _cmi_is_mob)

Лицензия

GPLv3
Примечание по совместимости

Мод автоматически определяет мобов системы Mobs Redo и корректно масштабирует их здоровье, урон и другие характеристики. Для работы с другими системами мобов может потребоваться дополнительная настройка.
