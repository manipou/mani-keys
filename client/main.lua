local Config = lib.load('config')
local Keybind = nil
local onCooldown = false

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

    local playerJob = LocalPlayer.state.job.name
    local state = Entity(vehicle).state
    local keyHolders = json.decode(state.keyHolders) or {}

    if (not keyHolders or not keyHolders[LocalPlayer.state.identifier]) and not (state.JobKey and state.JobKey == playerJob) then lib.notify({ title = 'Du har ingen nøgler til dette køretøj', type = 'error' }) return end

    local vehLocked = state.vehLocked == nil and Config.LockedByDefault or state.vehLocked

    lib.waitFor(function()
        NetworkRequestControlOfEntity(vehicle)
        if NetworkGetEntityOwner(vehicle) == PlayerId() then return true end
    end, 'Kunne ikke modtage ejerskab af køretøj', 60000)

    state:set('vehLocked', not vehLocked, true)

    lib.requestAnimDict(Config.Animation['Dict'])

	TaskPlayAnim(ped, Config.Animation['Dict'], Config.Animation['Clip'], 15.0, -10.0, 1500, 49, 0, false, false, false)

    PlaySoundFromEntity(-1, "Remote_Control_Close", vehicle, "PI_Menu_Sounds", 1, 0)

    lib.notify({ title = vehLocked and 'Du låste dit køretøj op' or 'Du låste dit køretøj', type = vehLocked and 'success' or 'error' })
end

exports('GiveKey', function(entity, owner)
    lib.waitFor(function()
        NetworkRequestControlOfEntity(entity)
        if NetworkGetEntityOwner(entity) == PlayerId() then return true end
    end, 'Kunne ikke modtage ejerskab af køretøj', 60000)

    local state = Entity(entity).state
    local keyHolders = json.decode(state.keyHolders) or {}

    keyHolders[LocalPlayer.state.identifier] = { ['Owner'] = owner }

    state:set('keyHolders', json.encode(keyHolders), true)

    local plate = GetVehicleNumberPlateText(entity)

    lib.notify({ title = ('Du har modtaget nøgler til: %s'):format(plate), type = 'success' })
end)

exports('GiveKeyServerId', function(vehicle, serverid)
    lib.waitFor(function()
        NetworkRequestControlOfEntity(vehicle)
        if NetworkGetEntityOwner(vehicle) == PlayerId() then return true end
    end, 'Kunne ikke modtage ejerskab af køretøj', 60000)

    local targetIdentifier = Player(serverid).state.identifier
    local identifier = LocalPlayer.state.identifier

    local ped = cache.ped

    local state = Entity(vehicle).state
    local keyHolders = json.decode(state.keyHolders) or {}

    if not keyHolders[identifier] or not keyHolders[identifier]['Owner'] then lib.notify({ title = 'Du ejer ikke dette køretøj', type = 'error' }) return end

    keyHolders[targetIdentifier] = { ['Owner'] = false }

    state:set('keyHolders', json.encode(keyHolders), true)

    local plate = GetVehicleNumberPlateText(vehicle)

    lib.notify({ title = ('Du har givet nøgler til: %s'):format(plate), type = 'success' })
    lib.callback.await('mani-keys:server:sendNotify', false, serverid, ('Du har fået givet nøgler til: %s'):format(plate))
end)

exports('RemoveKey', function(entity)
    lib.waitFor(function()
        NetworkRequestControlOfEntity(entity)
        if NetworkGetEntityOwner(entity) == PlayerId() then return true end
    end, 'Kunne ikke modtage ejerskab af køretøj', 60000)

    local state = Entity(entity).state
    local keyHolders = json.decode(state.keyHolders) or {}

    keyHolders[LocalPlayer.state.identifier] = nil

    state:set('keyHolders', json.encode(keyHolders), true)

    local plate = GetVehicleNumberPlateText(entity)

    lib.notify({ title = ('Du har mistet nøgler til: %s'):format(plate), type = 'error' })
end)

exports('RemoveKeyServerId', function(vehicle, serverid)
    lib.waitFor(function()
        NetworkRequestControlOfEntity(vehicle)
        if NetworkGetEntityOwner(vehicle) == PlayerId() then return true end
    end, 'Kunne ikke modtage ejerskab af køretøj', 60000)

    local targetIdentifier = Player(serverid).state.identifier
    local identifier = LocalPlayer.state.identifier

    local ped = cache.ped

    local state = Entity(vehicle).state
    local keyHolders = json.decode(state.keyHolders) or {}

    if not keyHolders[identifier] or not keyHolders[identifier]['Owner'] then lib.notify({ title = 'Du ejer ikke dette køretøj', type = 'error' }) return end

    keyHolders[targetIdentifier] = nil

    state:set('keyHolders', json.encode(keyHolders), true)

    local plate = GetVehicleNumberPlateText(vehicle)

    lib.notify({ title = ('Du har taget nøgler fra: %s'):format(serverid), type = 'success' })
    lib.callback.await('mani-keys:server:sendNotify', false, serverid, ('Du har fået taget nøgler fra: %s'):format(plate))
end)

exports('SetJobKey', function(vehicle, job)
    if not job then job = LocalPlayer.state.job.name end
    lib.waitFor(function()
        NetworkRequestControlOfEntity(vehicle)
        if NetworkGetEntityOwner(vehicle) == PlayerId() then return true end
    end, 'Kunne ikke modtage ejerskab af køretøj', 60000)

    local state = Entity(vehicle).state
    state:set('JobKey', job, true)
end)

AddStateBagChangeHandler('vehLocked' , nil, function(bagName, key, value)
	local entity = GetEntityFromStateBagName(bagName)
	if not entity then return end

    local state = Config.States[value and 'Locked' or 'Unlocked']

    SetVehicleDoorsLocked(entity, state)
end)

CreateThread(function()
    Keybind = lib.addKeybind({
        name = 'LockUnlock',
        description = 'Lås / Lås op for dit køretøj',
        defaultKey = Config.Keybinds['LockUnlock'],
        onPressed = function(self)
            if onCooldown then return end
            keybindCooldown()
            toggleNearestVeh()
        end
    })
end)

CreateThread(function()
	exports['ox_target']:addGlobalPlayer({
		label = 'Giv nøgler',
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