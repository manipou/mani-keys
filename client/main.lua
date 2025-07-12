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
    if not success then lib.notify({ title = vehLocked, type = 'error' }) return end

    lib.requestAnimDict(Config.Animation['Dict'])

    TaskPlayAnim(ped, Config.Animation['Dict'], Config.Animation['Clip'], 15.0, -10.0, 1500, 49, 0, false, false, false)

    if Config.Animation['Sound'] then PlaySoundFromEntity(-1, "Remote_Control_Close", vehicle, "PI_Menu_Sounds", 1, 0) end

    lib.notify({ title = vehLocked and locale('Notify.Locked') or locale('Notify.Unlocked'), type = vehLocked and 'success' or 'inform' })

    RemoveAnimDict(Config.Animation['Dict'])
end

exports('GiveKey', function(vehicle, owner)
    local success, msg = lib.callback.await('mani-keys:server:giveKey', false, NetworkGetNetworkIdFromEntity(vehicle), owner)
    if not success then return end

    local plate = GetVehicleNumberPlateText(vehicle)

    lib.notify({ title = (Locale('Notify.KeysRecieved'):format(plate)), type = 'success' })
end)

exports('GiveKeyServerId', function(vehicle, serverid)
    local success, msg = lib.callback.await('mani-keys:server:GiveKeyServerId', false, NetworkGetNetworkIdFromEntity(vehicle), serverid)
    if not success then return lib.notify({ title = msg, type = 'error' }) end

    lib.notify({ title = (Locale('Notify.KeysGiven'):format(GetVehicleNumberPlateText(vehicle))), type = 'success' })
end)

exports('RemoveKey', function(vehicle)
    local success, msg = lib.callback.await('mani-keys:server:RemoveKey', false, NetworkGetNetworkIdFromEntity(vehicle))
    if not success then return end

    lib.notify({ title = (Locale('Notify.KeysRemoved'):format(GetVehicleNumberPlateText(vehicle))), type = 'error' })
end)

exports('RemoveKeyServerId', function(vehicle, serverid)
    local success, msg = lib.callback.await('mani-keys:server:RemoveKeyServerId', false, NetworkGetNetworkIdFromEntity(vehicle), serverid)
    if not success then return lib.notify({ title = msg, type = 'error' }) end

    lib.notify({ title = (Locale('Notify.KeysTaken'):format(serverid)), type = 'success' })
end)

exports('SetJobKey', function(vehicle, job)
    local success, msg = lib.callback.await('mani-keys:server:SetJobKey', false, NetworkGetNetworkIdFromEntity(vehicle), job)
    if not success then return lib.notify({ title = msg, type = 'error' }) end
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
        name = Locale('Keybinds.KeyName'),
        description = Locale('Keybinds.KeyDesc'),
        defaultKey = Config.Keybinds['LockUnlock'],
        onPressed = function(self)
            if onCooldown then return end
            keybindCooldown()
            toggleNearestVeh()
        end
    })

    lib.addKeybind({
        name = Locale('Keybinds.EngineName'),
        description = Locale('Keybinds.EngineDesc'),
        defaultKey = Config.Keybinds['ToggleEngine'],
        onPressed = function(self)
            if onCooldown then return end
            keybindCooldown()
            toggleEngine()
        end
    })

    TriggerEvent('chat:addSuggestion', '/givekeys', Locale('Commands.GiveKeys'), {
        { name="id", help="Spiller ID" }
    })

    TriggerEvent('chat:addSuggestion', '/removekeys', Locale('Commands.RemoveKeys'), {
        { name="id", help="Spiller ID" }
    })

    exports['ox_target']:addGlobalPlayer({
		label = Locale('Target.GiveKeys'),
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