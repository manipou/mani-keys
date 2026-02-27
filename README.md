## Common Issues

> I don't get the keys each time?
This is because the vehicle entity is not networked properly. Try to spawn a vehicle this way:
```lua
local Vehicle, Netid = Jet.Create.Vehicle(vec4(0, 0, 0, 0), 'Panto', { color = 1 ... })
```

## Usage

> Lock / Unlock vehicle [locked is a true/false boolean value] - Shared
```lua
local State = Entity(EntityId).state
local Locked = true
State:set('VehLocked', Locked, true)
```

> Give keys to a player - Shared
```lua
exports['mani-keys']:GiveKey(Source, {
    Plate = 'QB321E', -- Vehicle Plate
    IsOwner = true, -- Owner Perms
    Persistent = true -- Should safe after server restart
})
```

> Removes a key from the player - Shared
```lua
exports['mani-keys']:RemoveKey({
    Plate = 'QB321E', -- Vehicle Plate
    Identifier = 'char1:123456789' -- Target Identifier
})
```

> Sets a job key [if job is nil, it will just use the players current job]
```lua
exports['mani-keys']:SetJobKey({
    Plate = 'QB321E', -- Vehicle Plate
    Job = 'police' -- Job Name
})
```