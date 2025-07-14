local Config = lib.load('config')
local onCooldown = false

lib.locale()

local function keybindCooldown()
    onCooldown = true
    SetTimeout(Config.KeybindCooldown * 1000, function()
        onCooldown = false
    end)
end

local function toggleNearestVeh()
    local ped = cache.ped

    local vehicle = lib.getClosestVehicle(GetEntityCoords(ped), Config.MaxDistance, true)
    if not vehicle then return end

    local success, vehLocked = lib.callback.await('mani-keys:server:toggleNearestVeh', false, NetworkGetNetworkIdFromEntity(vehicle))
    if not success then return exports['mani-bridge']:Notify(vehLocked, nil, 'error') end

    lib.requestAnimDict(Config.Animation['Dict'])

    TaskPlayAnim(ped, Config.Animation['Dict'], Config.Animation['Clip'], 15.0, -10.0, 1500, 49, 0, false, false, false)

    if Config.Animation['Sound'] then PlaySoundFromEntity(-1, "Remote_Control_Close", vehicle, "PI_Menu_Sounds", 1, 0) end

    exports['mani-bridge']:Notify(vehLocked and locale('Notify.Locked') or locale('Notify.Unlocked'), nil, vehLocked and 'success' or 'inform')

    RemoveAnimDict(Config.Animation['Dict'])
end

exports('GiveKey', function(vehicle, owner)
    local success, msg = lib.callback.await('mani-keys:server:giveKey', false, NetworkGetNetworkIdFromEntity(vehicle), owner)
    if not success then return end

    local plate = GetVehicleNumberPlateText(vehicle)

    exports['mani-bridge']:Notify((locale('Notify.KeysRecieved'):format(plate)), nil, 'success')
end)

exports('GiveKeyServerId', function(vehicle, serverid)
    local success, msg = lib.callback.await('mani-keys:server:GiveKeyServerId', false, NetworkGetNetworkIdFromEntity(vehicle), serverid)
    if not success then return exports['mani-bridge']:Notify(msg, nil, 'error') end

    exports['mani-bridge']:Notify((locale('Notify.KeysGiven'):format(GetVehicleNumberPlateText(vehicle))), nil, 'success')
end)

exports('RemoveKey', function(vehicle)
    local success, msg = lib.callback.await('mani-keys:server:RemoveKey', false, NetworkGetNetworkIdFromEntity(vehicle))
    if not success then return end

    exports['mani-bridge']:Notify((locale('Notify.KeysRemoved'):format(GetVehicleNumberPlateText(vehicle))), nil, 'error')
end)

exports('RemoveKeyServerId', function(vehicle, serverid)
    local success, msg = lib.callback.await('mani-keys:server:RemoveKeyServerId', false, NetworkGetNetworkIdFromEntity(vehicle), serverid)
    if not success then return exports['mani-bridge']:Notify(msg, nil, 'error') end

    exports['mani-bridge']:Notify((locale('Notify.KeysTaken'):format(serverid)), nil, 'success')
end)

exports('SetJobKey', function(vehicle, job)
    local success, msg = lib.callback.await('mani-keys:server:SetJobKey', false, NetworkGetNetworkIdFromEntity(vehicle), job)
    if not success then return exports['mani-bridge']:Notify(msg, nil, 'error') end
end)

AddStateBagChangeHandler('vehLocked' , nil, function(bagName, key, value)
	local entity = GetEntityFromStateBagName(bagName)
	if not entity then return end

    local state = Config.States[value and 'Locked' or 'Unlocked']

    SetVehicleDoorsLocked(entity, state)
end)

RegisterCommand('givekeys', function(source, args, raw)
    if not args[1] then return end
    local serverId = args[1]
    local vehicle = lib.getClosestVehicle(GetEntityCoords(cache.ped), Config.MaxDistance, true)
    if not vehicle then return end
    exports['mani-keys']:GiveKeyServerId(vehicle, serverId)
end)

RegisterCommand('removekeys', function(source, args, raw)
    if not args[1] then return end
    local serverId = args[1]
    local vehicle = lib.getClosestVehicle(GetEntityCoords(cache.ped), Config.MaxDistance, true)
    if not vehicle then return end
    exports['mani-keys']:RemoveKeyServerId(vehicle, serverId)
end)

local function toggleEngine()
    local vehicle = cache.vehicle
    if not vehicle then return end
    local seat = cache.seat
    if seat ~= -1 then return end

	SetVehicleEngineOn(vehicle, not GetIsVehicleEngineRunning(vehicle), true, true)
end

CreateThread(function()
    lib.addKeybind({
        name = locale('Keybinds.KeyName'),
        description = locale('Keybinds.KeyDesc'),
        defaultKey = Config.Keybinds['LockUnlock'],
        onPressed = function(self)
            if onCooldown then return end
            keybindCooldown()
            toggleNearestVeh()
        end
    })

    lib.addKeybind({
        name = locale('Keybinds.EngineName'),
        description = locale('Keybinds.EngineDesc'),
        defaultKey = Config.Keybinds['ToggleEngine'],
        onPressed = function(self)
            if onCooldown then return end
            keybindCooldown()
            toggleEngine()
        end
    })

    TriggerEvent('chat:addSuggestion', '/givekeys', locale('Commands.GiveKeys'), {
        { name="id", help="Player ID" }
    })

    TriggerEvent('chat:addSuggestion', '/removekeys', locale('Commands.RemoveKeys'), {
        { name="id", help="Player ID" }
    })

    exports['ox_target']:addGlobalPlayer({
		label = locale('Target.GiveKeys'),
		name = 'mani-keys:target',
		icon = 'fa-solid fa-key',
		distance = 2,
		onSelect = function(data)
            local serverId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))
            local vehicle = lib.getClosestVehicle(GetEntityCoords(cache.ped), Config.MaxDistance, true)
            if not vehicle then return end
            exports['mani-keys']:GiveKeyServerId(vehicle, serverId)
		end
	})
end)

if Config.NPCVehicles['LockedChance'] <= 0 then return end

local function IsNPCVehicle(vehicle)
    local EntityType = GetEntityPopulationType(vehicle)
    return (EntityType >= 1 and EntityType <= 5)
end

local function Lockpick(vehicle)
    local Dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@'
    local Anim = 'machinic_loop_mechandplayer'
    local PlayerPed = cache.ped
    lib.requestAnimDict(Dict)
    TaskPlayAnim(PlayerPed, Dict, Anim, 3.0, 1.0, -1, 31, 0, 0, 0)

    if lib.skillCheck({'easy', 'medium'}, {'w', 'a', 's', 'd'}) then
        SetVehicleDoorsLocked(vehicle, Config.States['Unlocked'])
        Entity(vehicle).state:set('vehLocked', false, true)
        exports['mani-bridge']:Notify(locale('Notify.LockpickSuccess'), nil, 'success')
    else
        local breakChance = math.random(1, 100)
        if breakChance <= Config.NPCVehicles['Lockpick']['BreakChance'] then
            TriggerServerEvent('mani-keys:server:breakLockpick')
        end
        SetVehicleAlarm(vehicle, true)
        SetVehicleAlarmTimeLeft(vehicle, 5000)
        exports['mani-bridge']:Notify(locale('Notify.LockpickFailed'), nil, 'error')
    end

    ClearPedTasks(PlayerPed)
    RemoveAnimDict(Dict)
end

RegisterNetEvent('baseevents:enteringVehicle', function(vehicle)
    local chance = math.random(1, 100)

    if not IsNPCVehicle(vehicle) then return end

    local state = Entity(vehicle).state
    if state.vehLocked ~= nil then return end

    if chance <= Config.NPCVehicles['LockedChance'] then
        SetVehicleDoorsLocked(vehicle, Config.States['Locked'])
        state:set('vehLocked', true, true)
    else
        SetVehicleDoorsLocked(vehicle, Config.States['Unlocked'])
        state:set('vehLocked', false, true)
    end
end)

CreateThread(function()
    exports['mani-bridge']:AddGlobalVehicleTarget({
        label = locale('Target.Lockpick'),
        name = 'mani-keys:lockpick',
        icon = 'fa-solid fa-key',
        items = Config.NPCVehicles['Lockpick']['Item'],
        distance = 2,
        canInteract = function(entity)
            return IsNPCVehicle(entity) and (Entity(entity).state.vehLocked == nil or true)
        end,
        onSelect = function(data)
            Lockpick(data.entity)
        end
    })
end)

exports('lockpick', function()
    local PlayerPed = cache.ped

    local vehicle = lib.getClosestVehicle(GetEntityCoords(PlayerPed), 2, true)
    if not vehicle then return end
    if not (IsNPCVehicle(vehicle) and (Entity(vehicle).state.vehLocked == nil or true)) then return end

    Lockpick(vehicle)
end)

if not Config.NPCVehicles['StealArmed'] then return end

CreateThread(function()
    local Dict = 'random@mugging3'
    local Anim = 'handsup_standing_base'

    SetInterval(function()
        local aiming, entity = GetEntityPlayerIsFreeAimingAt(cache.playerId)
        local PlayerPed = cache.ped

        if aiming and IsPedInAnyVehicle(entity, true) and IsPedHuman(entity) and IsEntityAPed(entity) and not IsPedAPlayer(entity) and not IsPedDeadOrDying(entity, true) and IsPedInAnyVehicle(entity, false) then
            local vehicle = GetVehiclePedIsIn(entity)
            if vehicle and GetEntitySpeed(vehicle) < 1.5 and (#(GetEntityCoords(PlayerPed) - GetEntityCoords(vehicle)) < 8.0) then
                lib.requestAnimDict(Dict)
                TaskPlayAnim(entity, Dict, Anim, 3.0, 3.0, -1, 49, 0, false, false, false)
                TaskVehicleTempAction(entity, vehicle, 1, 3000)
                Wait(2500)
                ClearPedTasks(entity)
                RemoveAnimDict(Dict)
                TaskLeaveVehicle(entity, vehicle, 256)

                lib.waitFor(function()
                    if not IsPedInAnyVehicle(entity, true) then return true end
                end, nil, 10000)

                TaskSmartFleePed(entity, PlayerPed, 40.0, 20000)
                SetBlockingOfNonTemporaryEvents(entity, true)

                SetVehicleDoorsLocked(vehicle, Config.States['Unlocked'])
                Entity(vehicle).state:set('vehLocked', false, true)
                exports['mani-keys']:GiveKey(vehicle)
            end
        end
    end, 500)
end)