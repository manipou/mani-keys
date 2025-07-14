local Config = {}

Config.Debug = false

Config.Keybinds = {
    ['LockUnlock'] = 'L',
    ['ToggleEngine'] = 'K',
}

Config.KeybindCooldown = 1 -- Seconds

Config.Animation = {
    ['Dict'] = 'anim@mp_player_intmenu@key_fob@',
    ['Clip'] = 'fob_click',
    ['Sound'] = true
}

Config.MaxDistance = 10.0

Config.States = {
    ['Locked'] = 2,
    ['Unlocked'] = 1
}

Config.NPCVehicles = { -- Requires baseevents
    ['LockedChance'] = 80,
    ['StealArmed'] = true,
    ['Lockpick'] = {
        ['Item'] = 'lockpick',
        ['BreakChance'] = 50
    }
}

Config.Framework = 'esx' -- esx, qb, qbx

return Config