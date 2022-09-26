# Moderation Handler
Handles player banning/kicking/noting (server only)

API:
```lua
Resolver.VerifyGameAccess(user : number|Player): boolean --> Checks if user has access to the game (false = banned)
--Note: 'user' must be a UserId or Player object
```

```lua
Resolver.Note(user : number|Player, note : string, moderator : string|Player)
--Note: 'user' must be a UserId or Player object
--	'moderator' must be a string or Player object
```

	Resolver.Kick(player : Player, moderator : string|Player, reason : string?, format : string?)
		Note:  Must pass a Player object
		      'moderator' must be a UserId or Player object
		      'reason' will default to "None" when nil (can be changed)
		      'format' defines the source of the kick (error/suspicious)
		       Each format creates a new message with the reason:

			=> [error]  reason .. "If this problem persists, please contact support."
			=> [sus]    "Suspicious activity detected:" .. reason
			=> [nil]    reason (no extra message)
	
	Resolver.Ban(user : number|Player, moderator : string|Player, duration : number, reason : string?)
		Note: 'user' must be a UserId or Player object
		      'moderator' must be a string or Player object
		      'duration' is in seconds (set to -1 for indefinite)
		      'reason' will default to "None" when nil (can be changed)
			
	Resolver.Unban(id : number, moderator : string|Player, reason : string?)
		Note: 'id' must be a UserId
		      'moderator' must be a string or Player object
		      'reason' will default to "No reason given" when nil
		      
	Resolver.GetLogs(user : number|Player, category : string?)
		Note: 'user' must be a UserId or Player object
		      'category' lets you choose which category of logs you want to see ("Notes" | "Bans" | "Kicks")
		       leaving 'category' as nil will return logs all categories
		       
	Resolver.AddModerator(moderator : string|number|Player)
		Note: 'moderator' must be a Name, UserId or Player object
	
	Resolver.RemoveModerator(moderator : string|number|Player)
		Note: 'moderator' must be a Name, UserId or Player object

Notes:

- Moderators must be added to to Moderator list (Name or UserId)
- You must use Resolver.VerifyGameAccess() when a player joins to check if they're banned or not
- Ban duration is in seconds. For indefinite bans, set the duration to -1.
