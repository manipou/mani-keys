local Util = {}

function Util.GetPlayerData(src) -- Serverside
    local Player = exports['qbx_core']:GetPlayer(src)
    if not Player then return end

    return {
        Job = Player.PlayerData.job.name,
        Identifier = Player.PlayerData.citizenid
    }
end

return Util