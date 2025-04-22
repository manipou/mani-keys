lib.callback.register('mani-keys:server:sendNotify', function(source, serverId, msg)
    TriggerClientEvent('ox_lib:notify', serverId, { title = msg, type = 'info' })
end)