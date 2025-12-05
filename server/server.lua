local Config, Util = lib.load('config'), lib.load(('framework.%s-util'):format(Config.Framework))
local NetIds = {}

lib.locale()

---@param Identifier string
---@param NetId number
---@param IsOwner boolean
local function GiveKey(Identifier, NetId, IsOwner)
    NetIds[NetId] = NetIds[NetId] or { KeyHolders = {}, JobKey = '' }

    NetIds[NetId]['KeyHolders'][Identifier] = { ['Owner'] = IsOwner }
end

---@param PlayerData table
---@param NetId number
---@return boolean HasKey
---@return boolean IsOwner
local function HasKey(PlayerData, NetId)
    if not NetIds[NetId] then return false, false end

    return next(NetIds[NetId]['KeyHolders'][PlayerData.Identifier]) or NetIds[NetId]['JobKey'] == PlayerData.Job.Name, NetIds[NetId]['KeyHolders'][PlayerData.Identifier] and NetIds[NetId]['KeyHolders'][PlayerData.Identifier]['Owner'] or false
end

---@param Identifier string
---@param NetId number
local function RemoveKey(Identifier, NetId)
    if not NetIds[NetId] then return false end
    
    NetIds[NetId]['KeyHolders'][Identifier] = nil
end

local function SetJobKey(NetId, JobKey)
    if not NetIds[NetId] then return false end

    NetIds[NetId]['JobKey'] = JobKey
end

lib.callback.register('mani-keys:server:ToggleNearestVeh', function(Source, NetId)
    local Vehicle = NetworkGetEntityFromNetworkId(NetId)
    if not Vehicle then return end

    local PlayerData = exports['mani-bridge']:GetPlayerData(Source)
    if not PlayerData then return end
    local State = Entity(Vehicle).state

    local HasKey = HasKey(PlayerData, NetId)
    if not HasKey then return end

    local vehLocked = State.vehLocked or false

    State:set('vehLocked', not vehLocked, true)

    return true, not vehLocked
end)

lib.callback.register('mani-keys:server:GiveKey', function(Source, NetId, IsOwner)
    local PlayerData = exports['mani-bridge']:GetPlayerData(Source)
    if not PlayerData then return end

    GiveKey(PlayerData.Identifier, NetId, IsOwner)

    return true
end)

lib.callback.register('mani-keys:server:GiveKeyServerId', function(Source, NetId, TargetSource)
    local PlayerData = exports['mani-bridge']:GetPlayerData(Source)
    local TargetData = exports['mani-bridge']:GetPlayerData(TargetSource)
    if not PlayerData or not TargetData then return false, locale('Notify.GenericError') end

    local Identifier = PlayerData.Identifier
    local TargetIdentifier = TargetData.Identifier

    local HasKey, IsOWner = HasKey(PlayerData, NetId)
    if not IsOWner then return false, locale('Notify.NotOwner') end

    GiveKey(TargetIdentifier, NetId, false)

    TriggerClientEvent('mani-bridge:notify', TargetSource, (locale('Notify.KeysRecieved'):format(GetVehicleNumberPlateText(vehicle))), nil, 'success')

    return true
end)

lib.callback.register('mani-keys:server:RemoveKey', function(Source, NetId)
    local PlayerData = exports['mani-bridge']:GetPlayerData(Source)
    if not PlayerData then return false, locale('Notify.GenericError') end

    RemoveKey(PlayerData.Identifier, NetId)

    return true
end)

lib.callback.register('mani-keys:server:RemoveKeyServerId', function(Source, NetId, TargetSource)
    local PlayerData = exports['mani-bridge']:GetPlayerData(Source)
    local TargetData = exports['mani-bridge']:GetPlayerData(TargetSource)
    if not PlayerData or not TargetData then return false, locale('Notify.GenericError') end

    local Identifier = PlayerData.Identifier
    local TargetIdentifier = TargetData.Identifier

    local HasKey, IsOWner = HasKey(PlayerData, NetId)
    if not IsOWner then return false, locale('Notify.NotOwner') end

    RemoveKey(TargetIdentifier, NetId)

    TriggerClientEvent('mani-bridge:notify', target, (locale('Notify.KeysRemoved'):format(GetVehicleNumberPlateText(vehicle))), nil, 'error')

    return true
end)

lib.callback.register('mani-keys:server:SetJobKey', function(Source, NetId, JobKey)
    if not JobKey then
        local PlayerData = exports['mani-bridge']:GetPlayerData(Source)
        if not PlayerData then return end
        JobKey = PlayerData.Job.Name
    end

    SetJobKey(NetId, JobKey)

    return true
end)

RegisterNetEvent('mani-keys:server:BreakLockpick', function() exports['mani-bridge']:RemoveItem(source, Config.NPCVehicles['Lockpick']['Item'], 1) end)

exports('GiveKey', GiveKey)
exports('RemoveKey', RemoveKey)
exports('HasKey', HasKey)
exports('SetJobKey', SetJobKey)