## Common Issues

> I don't get the keys each time?
This is because the vehicle entity is not networked properly. Try to spawn a vehicle this way:
```lua
local vehicle, netid = exports['mani-bridge']:CreateVeh(coords, model, props) -- vec4(0, 0, 0, 0), GetHashKey('panto', oxlib vehicleProperties table)
```

> I don't get the keys any time?
This is because you're not using the export correctly, the function expects the entityid, not the vehicle plate.
```lua
exports['mani-keys']:GiveKey(entityId, owner) -- entityId is the returned value, when creating a vehicle.
```

## Usage

> Lock / Unlock vehicle [locked is a true/false boolean value]
```lua
local state = Entity(entityid).state
state:set(vehLocked, locked, true)
```

> Give keys to a player
```lua
exports['mani-keys']:GiveKey(entityId, owner)
```

> Gives a key to a specific player
```lua
exports['mani-keys']:GiveKeyServerId(entityid, serverId)
```

> Removes a key from the player
```lua
exports['mani-keys']:RemoveKey(entityId)
```

> Removes a key from a specific player
```lua
exports['mani-keys']:RemoveKeyServerId(entityid, serverId)
```

> Sets a job key [if job is nil, it will just use the players current job]
```lua
exports['mani-keys']:SetJobKey(entityid, job)
```