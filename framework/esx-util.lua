local Util = {}

function Util.GetPlayerData(src) -- Serverside
    local state = Player(src).state

    return {
        Job = state.job.name,
        Identifier = state.identifier
    }
end

return Util