local Config = require 'config'
local Cooldown = false

Jet.Locale.LoadLocale(Config.Locale)

local function SetCooldown()
    Cooldown = true
    SetTimeout(Config.CooldownTime * 1000, function() Cooldown = false end)
end

local function GiveKey(Data)
    local Response = Jet.Callback.Await('mani-keys:server:GiveKey', false, Data)
    if not Response.Success then Jet.Notify({ title = Jet.Locale.T('Notify.Error'), description = Response.Message, type = 'error' }) return end

    Jet.Notify({ title = Jet.Locale.T('Notify.Success'), description = Response.Message, type = 'success' })
end
exports('GiveKey', GiveKey)

RegisterCommand('givekeys', function(_, Args)
    if not Args[1] then return end
    local ServerId = Args[1]
    local Vehicle = Jet.Nearest.Vehicle(GetEntityCoords(cache.ped), Config.MaxDistance, true)
    if not Vehicle then return end

    local Response = Jet.Callback.Await('mani-keys:server:GiveKeyId', false, { Plate = GetVehicleNumberPlateText(Vehicle), Target = ServerId })
    if not Response.Success then Jet.Notify({ title = Jet.Locale.T('Notify.Error'), description = Response.Message, type = 'error' }) return end

    Jet.Notify({ title = Jet.Locale.T('Notify.Success'), description = Response.Message, type = 'success' })
end, false)

local function RemoveKey(Data)
    local Response = Jet.Callback.Await('mani-keys:server:RemoveKey', false, Data)
    if not Response.Success then Jet.Notify({ title = Jet.Locale.T('Notify.Error'), description = Response.Message, type = 'error' }) return end

    Jet.Notify({ title = Jet.Locale.T('Notify.Success'), description = Response.Message, type = 'success' })
end
exports('RemoveKey', RemoveKey)

RegisterCommand('removekeys', function(_, Args)
    if not Args[1] then return end
    local ServerId = Args[1]
    local Vehicle = Jet.Nearest.Vehicle(GetEntityCoords(cache.ped), Config.MaxDistance, true)
    if not Vehicle then return end

    local Response = Jet.Callback.Await('mani-keys:server:RemoveKeyId', false, { Plate = GetVehicleNumberPlateText(Vehicle), Target = ServerId })
    if not Response.Success then Jet.Notify({ title = Jet.Locale.T('Notify.Error'), description = Response.Message, type = 'error' }) return end

    Jet.Notify({ title = Jet.Locale.T('Notify.Success'), description = Response.Message, type = 'success' })
end, false)

exports('SetJobKey', function(Data)
    local Response = Jet.Callback.Await('mani-keys:server:SetJobKey', false, Data)
    if not Response.Success then Jet.Notify({ title = Jet.Locale.T('Notify.Error'), description = Response.Message, type = 'error' }) return end
end)

local function ToggleNearestVeh()
    local PlayerPed = cache.ped
    local Vehicle = Jet.Nearest.Vehicle(GetEntityCoords(PlayerPed), Config.MaxDistance, true)
    if not Vehicle then return end

    local Response = Jet.Callback.Await('mani-keys:server:ToggleNearestVeh', false, NetworkGetNetworkIdFromEntity(Vehicle))
    if not Response.Success then Jet.Notify({ title = Jet.Locale.T('Notify.Error'), description = Response.Message, type = 'error' }) return end

    Jet.PlayAnim(PlayerPed, Config.Animation['Dict'], Config.Animation['Clip'], 15.0, -10.0, 1500, 49, 0, false, false, false)

    if Config.Animation['Sound'] then PlaySoundFromEntity(-1, "Remote_Control_Close", Vehicle, "PI_Menu_Sounds", 1, 0) end

    Jet.Notify({ title = Jet.Locale.T('Notify.Success'), description = Response.Message, type = 'success' })
end

local function ToggleEngine()
    local Vehicle = cache.vehicle
    if not Vehicle then return end
    local seat = cache.seat
    if seat ~= -1 then return end

	SetVehicleEngineOn(Vehicle, not GetIsVehicleEngineRunning(Vehicle), true, true)
end

CreateThread(function()
    Jet.AddKeybind({
        name = Jet.Locale.T('Keybinds.LockUnlockName'),
        description = Jet.Locale.T('Keybinds.LockUnlockDesc'),
        defaultKey = Config.Keybinds['LockUnlock'],
        onPressed = function(self)
            if Cooldown then return end
            SetCooldown()
            ToggleNearestVeh()
        end
    })

    Jet.AddKeybind({
        name = Jet.Locale.T('Keybinds.EngineName'),
        description = Jet.Locale.T('Keybinds.EngineDesc'),
        defaultKey = Config.Keybinds['ToggleEngine'],
        onPressed = function(self)
            if Cooldown then return end
            SetCooldown()
            ToggleEngine()
        end
    })

    TriggerEvent('chat:addSuggestion', '/givekeys', Jet.Locale.T('Commands.GiveKeys'), {
        { name="id", help="Player ID" }
    })

    TriggerEvent('chat:addSuggestion', '/removekeys', Jet.Locale.T('Commands.RemoveKeys'), {
        { name="id", help="Player ID" }
    })
end)

AddStateBagChangeHandler('VehLocked' , nil, function(BagName, _, Value)
	local Vehicle = GetEntityFromStateBagName(BagName)
	if not Vehicle then return end

    local State = Config.States[Value and 'Locked' or 'Unlocked']

    SetVehicleDoorsLocked(Vehicle, State)
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
    Jet.PlayAnim(PlayerPed, Dict, Anim, 3.0, 1.0, -1, 31, 0, 0, 0)

    if exports['ox_lib']:skillcheck({'easy', 'medium'}, {'w', 'a', 's', 'd'}) then
        SetVehicleDoorsLocked(Vehicle, Config.States['Unlocked'])
        Entity(Vehicle).state:set('VehLocked', false, true)

        Jet.Notify({ title = Jet.Locale.T('Notify.Success'), description = Jet.Locale.T('Notify.LockpickSuccess'), type = 'success' })
    else
        local BreakChance = math.random(1, 100)
        if BreakChance <= Config.NPCVehicles['Lockpick']['BreakChance'] then
            TriggerServerEvent('mani-keys:server:BreakLockpick')
        end
        SetVehicleAlarm(Vehicle, true)
        SetVehicleAlarmTimeLeft(Vehicle, 5000)

        Jet.Notify({ title = Jet.Locale.T('Notify.Error'), description = Jet.Locale.T('Notify.LockpickFailed'), type = 'error' })
    end

    ClearPedTasks(PlayerPed)
end

RegisterNetEvent('baseevents:enteringVehicle', function(Vehicle)
    local Chance = math.random(1, 100)

    if not IsNPCVehicle(Vehicle) then return end

    local State = Entity(Vehicle).state
    if State.VehLocked ~= nil then return end

    if Chance <= Config.NPCVehicles['LockedChance'] then
        SetVehicleDoorsLocked(Vehicle, Config.States['Locked'])
        State:set('VehLocked', true, true)
    else
        SetVehicleDoorsLocked(Vehicle, Config.States['Unlocked'])
        State:set('VehLocked', false, true)
    end
end)

CreateThread(function()
    Jet.Target.AddGlobalVehicleTarget({
        label = Jet.Locale.T('Target.Lockpick'),
        name = 'mani-keys:lockpick',
        icon = 'fa-solid fa-key',
        items = Config.NPCVehicles['Lockpick']['Item'],
        distance = 2,
        canInteract = function(entity)
            return IsNPCVehicle(entity) and (Entity(entity).state.VehLocked == nil or true)
        end,
        onSelect = function(data)
            Lockpick(data.entity)
        end
    })
end)

exports('lockpick', function()
    local PlayerPed = cache.ped

    local Vehicle = Jet.Nearest.Vehicle(GetEntityCoords(PlayerPed), 2.0, true)
    if not Vehicle then return end
    if not (IsNPCVehicle(Vehicle) and (Entity(Vehicle).state.VehLocked == nil or true)) then return end

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
                Jet.PlayAnim(NPCEntity, Dict, Anim, 3.0, 3.0, -1, 49, 0, false, false, false)
                TaskVehicleTempAction(NPCEntity, Vehicle, 1, 3000)
                Wait(2500)
                ClearPedTasks(NPCEntity)
                TaskLeaveVehicle(NPCEntity, Vehicle, 256)

                Jet.WaitFor(function()
                    if not IsPedInAnyVehicle(NPCEntity, true) then return true end
                end, nil, 10000)

                TaskSmartFleePed(NPCEntity, PlayerPed, 40.0, 20000, false, false)
                SetBlockingOfNonTemporaryEvents(NPCEntity, true)

                SetVehicleDoorsLocked(Vehicle, Config.States['Unlocked'])
                Entity(Vehicle).state:set('VehLocked', false, true)

                GiveKey({ Plate = GetVehicleNumberPlateText(Vehicle) })
            end
        end
    end, 500)
end)