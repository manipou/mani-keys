local Config = require 'config'
local Util = require(('framework.%s-util'):format(Config.Framework))

Jet.Locale.LoadLocale(Config.Locale)

local Keyholders, JobKeys = {}, {}

local GenericError = { Success = false, Message = Jet.Locale.T('Notify.GenericError') } -- Lazy

CreateThread(function()
    local Success, Keys = pcall(function() return MySQL.query.await('SELECT * FROM `mani_persistentkeys`') end)
    if not Success then
        MySQL.query([[
            CREATE TABLE IF NOT EXISTS `mani_persistentkeys` (
                `id` INT(11) NOT NULL AUTO_INCREMENT,
                `identifier` VARCHAR(50) NOT NULL DEFAULT '' COLLATE 'utf8mb4_uca1400_ai_ci',
                `plate` VARCHAR(50) NOT NULL DEFAULT '' COLLATE 'utf8mb4_uca1400_ai_ci',
                `isowner` INT(11) NOT NULL DEFAULT '0',
                PRIMARY KEY (`id`) USING BTREE
            )
            COLLATE='utf8mb4_uca1400_ai_ci'
            ENGINE=InnoDB;
        ]])

        Keys = {}
    end

    for i = 1, #Keys do
        local Data = Keys[i]
        Keyholders[Data.plate] = Keyholders[Data.plate] or {}
        Keyholders[Data.plate][Data.identifier] = { IsOwner = Data.isowner == 1, Persistent = true }
    end
end)

---@param Source integer
---@param Plate string
local function HasKeys(Source, Plate)
    local PlayerData = Util.GetPlayerData(Source)
    if not PlayerData then return false end

    local Identifier = PlayerData.Identifier
    local JobKey = JobKeys[Plate]
    if JobKey then
        if PlayerData.Job and PlayerData.Job.name == JobKey then return true end
    end

    return Keyholders[Plate] and Keyholders[Plate][Identifier] ~= nil
end

---@param Source integer
---@param Data table
local function GiveKey(Source, Data)
    local Plate = Data.Plate
    local IsOwner = Data.IsOwner or false
    local Persistent = Data.Persistent or false

    if not Plate then return GenericError end

    Keyholders[Plate] = Keyholders[Plate] or {}

    local PlayerData = Util.GetPlayerData(Source)
    if not PlayerData then return GenericError end
    local Identifier = PlayerData.Identifier

    Keyholders[Plate][Identifier] = { IsOwner = IsOwner, Persistent = Persistent }

    if Persistent then
        MySQL.query('INSERT INTO `mani_persistentkeys` (`identifier`, `plate`, `isowner`) VALUES (?, ?, ?)', { Identifier, Plate, IsOwner and 1 or 0 })
    end

    return { Success = true, Message = Jet.Locale.T('Notify.KeyGiven') }
end

Jet.Callback.Register('mani-keys:server:GiveKey', GiveKey)
Jet.Callback.Register('mani-keys:server:GiveKeyId', function(Source, Data)
    local Plate = Data.Plate
    local Target = Data.Target
    if not Plate or not Target then return GenericError end

    local PlayerData = Util.GetPlayerData(Source)
    local TargetData = Util.GetPlayerData(Target)
    if not PlayerData or not TargetData then return GenericError end

    Keyholders[Plate] = Keyholders[Plate] or {}
    local Permissions = Keyholders[Plate][PlayerData.Identifier]
    if not Permissions or not Permissions.IsOwner then return { Success = false, Message = Jet.Locale.T('Notify.NotPermission') } end

    return GiveKey(Target, Data)
end)
exports('GiveKey', GiveKey)

---@param Data table
local function RemoveKey(Data)
    local Plate = Data.Plate
    local Identifier = Data.Identifier
    if not Identifier or not Plate then return GenericError end
    if not Keyholders[Plate] then return GenericError end

    if type(Identifier) == 'number' then
        local TargetData = Util.GetPlayerData(Identifier)
        if not TargetData then return GenericError end
        Identifier = TargetData.Identifier
    end

    if not Keyholders[Plate][Identifier] then return GenericError end

    if Keyholders[Plate][Identifier].Persistent then
        MySQL.query('DELETE FROM `mani_persistentkeys` WHERE `identifier` = ? AND `plate` = ?', { Identifier, Plate })
    end

    Keyholders[Plate][Identifier] = nil

    return { Success = true, Message = Jet.Locale.T('Notify.KeyRemoved') }
end
Jet.Callback.Register('mani-keys:server:RemoveKey', RemoveKey)
Jet.Callback.Register('mani-keys:server:RemoveKeyId', function(Source, Data)
    local Plate = Data.Plate
    if not Plate then return GenericError end

    local PlayerData = Util.GetPlayerData(Source)
    if not PlayerData then return GenericError end

    Keyholders[Plate] = Keyholders[Plate] or {}
    local Permissions = Keyholders[Plate][PlayerData.Identifier]
    if not Permissions or not Permissions.IsOwner then return { Success = false, Message = Jet.Locale.T('Notify.NotPermission') } end

    return RemoveKey(Data)
end)
exports('RemoveKey', RemoveKey)

---@param Plate string
---@param Job string
local function SetJobKey(Plate, Job)
    JobKeys[Plate] = JobKeys[Plate] or {}
    JobKeys[Plate] = Job

    return { Success = true }
end
exports('SetJobKey', SetJobKey)
Jet.Callback.Register('mani-keys:server:SetJobKey', function(Source, Data)
    local Plate = Data.Plate
    local Job = Data.Job
    if not Plate or not Job then return GenericError end

    if not Job then
        local PlayerData = Util.GetPlayerData(Source)
        if not PlayerData then return GenericError end
        Job = PlayerData.Job
    end

    return SetJobKey(Plate, Job)
end)

Jet.Callback.Register('mani-keys:server:ToggleNearestVeh', function(Source, NetId)
    local Vehicle = NetworkGetEntityFromNetworkId(NetId)
    if not Vehicle then return GenericError end

    local Plate = GetVehicleNumberPlateText(Vehicle)
    if not Plate then return GenericError end

    if not HasKeys(Source, Plate) then return { Success = false, Message = Jet.Locale.T('Notify.NoKeys') } end

    local State = Entity(Vehicle).state

    local VehLocked = State.VehLocked

    State:set('VehLocked', not VehLocked, true)

    return { Success = true, Message = not VehLocked and Jet.Locale.T('Notify.VehicleLocked') or Jet.Locale.T('Notify.VehicleUnlocked') }
end)

RegisterNetEvent('mani-keys:server:BreakLockpick', function() Jet.Inventory.RemoveItem(source, Config.NPCVehicles['Lockpick']['Item'], 1) end)

exports('GetKeyholders', function(Plate) return Keyholders[Plate] or {} end)