local Config = lib.load('config')
local Util = lib.load(('framework.%s-util'):format(Config.Framework))

lib.locale()

lib.callback.register('mani-keys:server:toggleNearestVeh', function(src, netId)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    while not vehicle do Wait(50) end

    local playerData = Util.GetPlayerData(src)
    local playerJob = playerData.Job
    local state = Entity(vehicle).state
    local keyHolders = json.decode(state.keyHolders) or {}

    if (not keyHolders or not keyHolders[playerData.Identifier]) and not (state.JobKey and state.JobKey == playerJob) then return false, locale('Notify.NoKey') end

    local vehLocked = state.vehLocked or false

    state:set('vehLocked', not vehLocked, true)

    return true, not vehLocked
end)

lib.callback.register('mani-keys:server:giveKey', function(src, netId, owner)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    while not vehicle do Wait(50) end
    local state = Entity(vehicle).state
    local keyHolders = json.decode(state.keyHolders) or {}

    local playerData = Util.GetPlayerData(src)

    keyHolders[playerData.Identifier] = { ['Owner'] = owner }

    state:set('keyHolders', json.encode(keyHolders), true)

    return true
end)

lib.callback.register('mani-keys:server:GiveKeyServerId', function(src, netId, target)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    while not vehicle do Wait(50) end

    local playerData = Util.GetPlayerData(src)
    local targetData = Util.GetPlayerData(target)

    local targetIdentifier = targetData.Identifier
    local identifier = playerData.Identifier

    local state = Entity(vehicle).state
    local keyHolders = json.decode(state.keyHolders) or {}

    if not keyHolders[identifier] or not keyHolders[identifier]['Owner'] then return false, locale('Notify.NotOwner') end

    keyHolders[targetIdentifier] = { ['Owner'] = false }

    state:set('keyHolders', json.encode(keyHolders), true)

    TriggerClientEvent('mani-bridge:notify', target, (locale('Notify.KeysRecieved'):format(GetVehicleNumberPlateText(vehicle))), nil, 'success')

    return true
end)

lib.callback.register('mani-keys:server:RemoveKey', function(src, netId)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    while not vehicle do Wait(50) end

    local state = Entity(vehicle).state
    local keyHolders = json.decode(state.keyHolders) or {}

    local playerData = Util.GetPlayerData(src)

    keyHolders[playerData.Identifier] = nil

    state:set('keyHolders', json.encode(keyHolders), true)

    return true
end)

lib.callback.register('mani-keys:server:RemoveKeyServerId', function(src, netId, target)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    while not vehicle do Wait(50) end

    local playerData = Util.GetPlayerData(src)
    local targetData = Util.GetPlayerData(target)

    local targetIdentifier = targetData.Identifier
    local identifier = playerData.Identifier

    local state = Entity(vehicle).state
    local keyHolders = json.decode(state.keyHolders) or {}

    if not keyHolders[identifier] or not keyHolders[identifier]['Owner'] then return false, locale('Notify.NotOwner') end

    keyHolders[targetIdentifier] = nil

    state:set('keyHolders', json.encode(keyHolders), true)

    TriggerClientEvent('mani-bridge:notify', target, (locale('Notify.KeysRemoved'):format(GetVehicleNumberPlateText(vehicle))), nil, 'error')
    return true
end)

lib.callback.register('mani-keys:server:SetJobKey', function(src, netId, job)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    while not vehicle do Wait(50) end

    if not job then job = Util.GetPlayerData(src).Job end

    local state = Entity(vehicle).state
    state:set('JobKey', job, true)
    return true
end)

RegisterNetEvent('mani-keys:server:breakLockpick', function()
    local src = source

    exports['mani-bridge']:RemoveItem(src, Config.NPCVehicles['Lockpick']['Item'], 1)
end)