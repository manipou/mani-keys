local Util = {}

local QBCore = exports['qb-core']:GetCoreObject()

function Util.GetPlayerData(src) -- Serverside
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    return {
        Job = Player.PlayerData.job.name,
        Identifier = Player.PlayerData.citizenid
    }
end

return Util