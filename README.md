# Moderation Handler
*Handles player banning/kicking/noting (server only)*

### Important Notes:
- You must call `Moderation.VerifyGameAccess(player)` on every player that joins. This ensures that banned players are kicked from the game, and players whose ban duration is up, are unbanned.

- Moderators can be added by adding them to the DefaultModerator table or by using `Moderation.AddModerator()`
			
- To remove moderators, either remove them from the DefaultModerator list (if they were added there), or by calling `Moderation.RemoveModerator()`.
				
- `Moderation.UpdateModerators()` must be called at least once when the server starts. This is done for you at the bottom of the module.
	
- Ban duration unit is seconds. For indefinite bans, set the duration to -1.
	
- Make sure commands that write to datastores are not used on a particular User in a real game setting; otherwise, a lot of datastore requests will be made, doing the exact same thing.

- Almost all commands require an existing moderator to authorise the function. The server is a default moderator with an Id of -1.

### API:

```
-- Types --

User : UserId|Player
LogCategory : "Notes" | "Kicks" | "Bans"
Format : "error" | "sus"
```

```lua
Moderation.VerifyGameAccess(user : User): boolean
--	Checks if user has access to the game (false = banned)
```

```lua
Moderation.AddModerator(new_moderator : User, existing_moderator : User)
```

```lua
Moderation.RemoveModerator(old_moderator : User, existing_moderator : User)
```

```lua
Moderation.GetModerators() : {[UserId] : string}
```

```lua
Moderation.UpdateModerators()
--	Resyncs the 'Moderators' table with the 'DefaultModerators' and the moderators added using Moderation.AddModerator()
```

```lua
Moderation.GetLogs(user : User, moderator : User, category : LogCategory?)
--	Returns a list of ordered logs (newest to oldest) for the specified category.
--	If no category is specified, it will return a dictionary containing all ordered logs.
```

```lua		       
Moderation.Note(user : User, moderator : User, note : string)
```

```lua
Moderation.Kick(user : User, moderator : User, reason : string?, format : Format?)
--[[	'reason' will default to "None" when nil (changeable)
	'format' will reformat the reason to display a better kick message to the player.
		This makes it easier to write descriptive kick messages:
			- [error]  reason .. "If this problem persists, please contact support."
			- [sus]    "Suspicious activity detected:" .. reason
			- [nil]    reason (no extra message)
							
			(you can add more formats to the KickMessageFormat table)
]]--
```

```lua
Moderation.Ban(user : User, moderator : User, duration : number, reason : string?)
--	'duration' is in seconds (set to -1 for indefinite)
--	'reason' will default to "None" when nil (changeable)
```

```lua
Moderation.Unban(id : number, moderator : User, reason : string?)
--	'reason' will default to "No reason given" when nil
```
