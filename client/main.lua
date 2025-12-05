local Config = lib.load('config')
local OnCooldown = false

lib.locale()

local function KeybindCooldown()
    OnCooldown = true
    SetTimeout(Config.KeybindCooldown * 1000, function()
        OnCooldown = false
    end)
end

local function ToggleNearestVeh()
    local PlayerPed = cache.ped

    local Vehicle = lib.getClosestVehicle(GetEntityCoords(PlayerPed), Config.MaxDistance, true)
    if not Vehicle then return end

    local success, vehLocked = lib.callback.await('mani-keys:server:ToggleNearestVeh', false, NetworkGetNetworkIdFromEntity(Vehicle))
    if not success then return exports['mani-bridge']:Notify(vehLocked, nil, 'error') end

    lib.playAnim(PlayerPed, Config.Animation['Dict'], Config.Animation['Clip'], 15.0, -10.0, 1500, 49, 0, false, false, false)

    if Config.Animation['Sound'] then PlaySoundFromEntity(-1, "Remote_Control_Close", Vehicle, "PI_Menu_Sounds", 1, 0) end

    exports['mani-bridge']:Notify(vehLocked and locale('Notify.Locked') or locale('Notify.Unlocked'), nil, vehLocked and 'success' or 'inform')
end

exports('GiveKey', function(Vehicle, owner)
    local Success = lib.callback.await('mani-keys:server:giveKey', false, NetworkGetNetworkIdFromEntity(Vehicle), owner)
    if not Success then return end

    local Plate = GetVehicleNumberPlateText(Vehicle)

    exports['mani-bridge']:Notify((locale('Notify.KeysRecieved'):format(Plate)), nil, 'success')
end)

exports('GiveKeyServerId', function(Vehicle, serverid)
    local success, msg = lib.callback.await('mani-keys:server:GiveKeyServerId', false, NetworkGetNetworkIdFromEntity(Vehicle), serverid)
    if not success then return exports['mani-bridge']:Notify(msg, nil, 'error') end

    exports['mani-bridge']:Notify((locale('Notify.KeysGiven'):format(GetVehicleNumberPlateText(Vehicle))), nil, 'success')
end)

exports('RemoveKey', function(Vehicle)
    local success, msg = lib.callback.await('mani-keys:server:RemoveKey', false, NetworkGetNetworkIdFromEntity(Vehicle))
    if not success then return end

    exports['mani-bridge']:Notify((locale('Notify.KeysRemoved'):format(GetVehicleNumberPlateText(Vehicle))), nil, 'error')
end)

exports('RemoveKeyServerId', function(Vehicle, serverid)
    local success, msg = lib.callback.await('mani-keys:server:RemoveKeyServerId', false, NetworkGetNetworkIdFromEntity(Vehicle), serverid)
    if not success then return exports['mani-bridge']:Notify(msg, nil, 'error') end

    exports['mani-bridge']:Notify((locale('Notify.KeysTaken'):format(serverid)), nil, 'success')
end)

exports('SetJobKey', function(Vehicle, job)
    local success, msg = lib.callback.await('mani-keys:server:SetJobKey', false, NetworkGetNetworkIdFromEntity(Vehicle), job)
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
    local Vehicle = lib.getClosestVehicle(GetEntityCoords(cache.ped), Config.MaxDistance, true)
    if not Vehicle then return end
    exports['mani-keys']:GiveKeyServerId(Vehicle, serverId)
end, false)

RegisterCommand('removekeys', function(source, args, raw)
    if not args[1] then return end
    local serverId = args[1]
    local Vehicle = lib.getClosestVehicle(GetEntityCoords(cache.ped), Config.MaxDistance, true)
    if not Vehicle then return end
    exports['mani-keys']:RemoveKeyServerId(Vehicle, serverId)
end, false)

local function toggleEngine()
    local Vehicle = cache.vehicle
    if not Vehicle then return end
    local seat = cache.seat
    if seat ~= -1 then return end

	SetVehicleEngineOn(Vehicle, not GetIsVehicleEngineRunning(Vehicle), true, true)
end

CreateThread(function()
    lib.addKeybind({
        name = locale('Keybinds.KeyName'),
        description = locale('Keybinds.KeyDesc'),
        defaultKey = Config.Keybinds['LockUnlock'],
        onPressed = function(self)
            if OnCooldown then return end
            KeybindCooldown()
            ToggleNearestVeh()
        end
    })

    lib.addKeybind({
        name = locale('Keybinds.EngineName'),
        description = locale('Keybinds.EngineDesc'),
        defaultKey = Config.Keybinds['ToggleEngine'],
        onPressed = function(self)
            if OnCooldown then return end
            KeybindCooldown()
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
            local Vehicle = lib.getClosestVehicle(GetEntityCoords(cache.ped), Config.MaxDistance, true)
            if not Vehicle then return end
            exports['mani-keys']:GiveKeyServerId(Vehicle, serverId)
		end
	})
end)

if Config.NPCVehicles['LockedChance'] <= 0 then return end

local function IsNPCVehicle(Vehicle)
    local EntityType = GetEntityPopulationType(Vehicle)
    return (EntityType >= 1 and EntityType <= 5)
end

local function Lockpick(Vehicle)
    local Dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@'
    local Anim = 'machinic_loop_mechandplayer'
    local PlayerPed = cache.ped
    lib.playAnim(PlayerPed, Dict, Anim, 3.0, 1.0, -1, 31, 0, 0, 0)

    if lib.skillCheck({'easy', 'medium'}, {'w', 'a', 's', 'd'}) then
        SetVehicleDoorsLocked(Vehicle, Config.States['Unlocked'])
        Entity(Vehicle).state:set('vehLocked', false, true)
        exports['mani-bridge']:Notify(locale('Notify.LockpickSuccess'), nil, 'success')
    else
        local breakChance = math.random(1, 100)
        if breakChance <= Config.NPCVehicles['Lockpick']['BreakChance'] then
            TriggerServerEvent('mani-keys:server:BreakLockpick')
        end
        SetVehicleAlarm(Vehicle, true)
        SetVehicleAlarmTimeLeft(Vehicle, 5000)
        exports['mani-bridge']:Notify(locale('Notify.LockpickFailed'), nil, 'error')
    end

    ClearPedTasks(PlayerPed)
end

RegisterNetEvent('baseevents:enteringVehicle', function(Vehicle)
    local chance = math.random(1, 100)

    if not IsNPCVehicle(Vehicle) then return end

    local state = Entity(Vehicle).state
    if state.vehLocked ~= nil then return end

    if chance <= Config.NPCVehicles['LockedChance'] then
        SetVehicleDoorsLocked(Vehicle, Config.States['Locked'])
        state:set('vehLocked', true, true)
    else
        SetVehicleDoorsLocked(Vehicle, Config.States['Unlocked'])
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

    local Vehicle = lib.getClosestVehicle(GetEntityCoords(PlayerPed), 2, true)
    if not Vehicle then return end
    if not (IsNPCVehicle(Vehicle) and (Entity(Vehicle).state.vehLocked == nil or true)) then return end

    Lockpick(Vehicle)
end)

if not Config.NPCVehicles['StealArmed'] then return end

CreateThread(function()
    local Dict = 'random@mugging3'
    local Anim = 'handsup_standing_base'

    SetInterval(function()
        local IsAiming, NPCEntity = GetEntityPlayerIsFreeAimingAt(cache.playerId)
        local PlayerPed = cache.ped

        if IsAiming and IsPedInAnyVehicle(NPCEntity, true) and IsPedHuman(NPCEntity) and IsEntityAPed(NPCEntity) and not IsPedAPlayer(NPCEntity) and not IsPedDeadOrDying(NPCEntity, true) and IsPedInAnyVehicle(NPCEntity, false) then
            local Vehicle = GetVehiclePedIsIn(NPCEntity, false)
            if Vehicle and GetEntitySpeed(Vehicle) < 1.5 and (#(GetEntityCoords(PlayerPed) - GetEntityCoords(Vehicle)) < 8.0) then
                lib.playAnim(NPCEntity, Dict, Anim, 3.0, 3.0, -1, 49, 0, false, false, false)
                TaskVehicleTempAction(NPCEntity, Vehicle, 1, 3000)
                Wait(2500)
                ClearPedTasks(NPCEntity)
                TaskLeaveVehicle(NPCEntity, Vehicle, 256)

                lib.waitFor(function()
                    if not IsPedInAnyVehicle(NPCEntity, true) then return true end
                end, nil, 10000)

                TaskSmartFleePed(NPCEntity, PlayerPed, 40.0, 20000, false, false)
                SetBlockingOfNonTemporaryEvents(NPCEntity, true)

                SetVehicleDoorsLocked(Vehicle, Config.States['Unlocked'])
                Entity(Vehicle).state:set('vehLocked', false, true)
                exports['mani-keys']:GiveKey(Vehicle)
            end
        end
    end, 500)
end)