# Moderation Handler
Handles player banning/kicking/noting (server only)

Important Notes:

- Moderators must be added to to Moderator list (Name or UserId)
- You must use Resolver.VerifyGameAccess() when a player joins to check if they're banned or not
- Ban duration is in seconds. For indefinite bans, set the duration to -1.

API:
```lua
Resolver.VerifyGameAccess(user : number|Player): boolean --> Checks if user has access to the game (false = banned)
--	'user' must be a UserId or Player object
```

```lua
Resolver.Note(user : number|Player, note : string, moderator : string|Player)
--	'user' must be a UserId or Player object
--	'moderator' must be a string or Player object
```

```lua
Resolver.Kick(player : Player, moderator : string|Player, reason : string?, format : string?)
--[[	 Must pass a Player object
	'moderator' must be a UserId or Player object
	'reason' will default to "None" when nil (can be changed)
	'format' defines the source of the kick (error/suspicious)
	 Each format creates a new message with the reason:

		=> [error]  reason .. "If this problem persists, please contact support."
		=> [sus]    "Suspicious activity detected:" .. reason
		=> [nil]    reason (no extra message)
]]--
```

```lua
Resolver.Ban(user : number|Player, moderator : string|Player, duration : number, reason : string?)
--[[	'user' must be a UserId or Player object
	'moderator' must be a string or Player object
	'duration' is in seconds (set to -1 for indefinite)
	'reason' will default to "None" when nil (can be changed)
]]--
```

```lua
Resolver.Unban(id : number, moderator : string|Player, reason : string?)
--[[	'id' must be a UserId
	'moderator' must be a string or Player object
	'reason' will default to "No reason given" when nil
]]--
```

```lua
Resolver.GetLogs(user : number|Player, category : string?)
--[[	'user' must be a UserId or Player object
	'category' lets you choose which category of logs you want to see ("Notes" | "Bans" | "Kicks")
	 leaving 'category' as nil will return logs all categories
]]--
```

```lua		       
Resolver.AddModerator(moderator : string|number|Player)
--	'moderator' must be a Name, UserId or Player object
```

```lua
Resolver.RemoveModerator(moderator : string|number|Player)
--	'moderator' must be a Name, UserId or Player object
```
