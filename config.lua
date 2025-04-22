local Config = {}

Config.Debug = true

Config.Keybinds = {
    ['LockUnlock'] = 'L',
}

Config.KeybindCooldown = 1 -- Seconds

Config.LockNPCVehicles = false

Config.Animation = {
    ['Dict'] = 'anim@mp_player_intmenu@key_fob@',
    ['Clip'] = 'fob_click',
    ['Sound'] = true
}

Config.LockedByDefault = true

Config.MaxDistance = 10.0

Config.States = {
    ['Locked'] = 2,
    ['Unlocked'] = 1
}

return Config