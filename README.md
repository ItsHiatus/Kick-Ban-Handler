# Kick-Ban-Note-Handler
Handles player banning/kicking/noting (server only)

How to use:
	
Moderators must be added to to Moderator list (Name or UserId)

Must use Resolver.VerifyGameAccess() when a player joins to check if they're banned or not
	
	Resolver.VerifyGameAccess(user : number|Player): boolean --> Checks if user has access to the game (false = banned)
		Note: 'user' must be a UserId or Player object
		
	Resolver.Note(user : number|Player, note : string, moderator : string|Player)
		Note: 'user' must be a UserId or Player object
		      'moderator' must be a string or Player object
		
	Resolver.Kick(player : Player, moderator : string|Player, reason : string?, format : string?)
		Note:  Must pass a Player object
		      'moderator' must be a UserId or Player object
		      'reason' will default to "None" when nil (can be changed)
		      'format' defines the source of the kick (error/suspicious)
		       Each format creates a new message with the reason:

			=> [error]  reason .. "If this problem persists, please contact support."
			=> [sus]    "Suspicious activity detected:" .. reason
			=> [nil]    reason (no extra message)
	
	Resolver.Ban(user : number|Player, moderator : string|Player, reason : string?)
		Note: 'user' must be a UserId or Player object
		      'moderator' must be a string or Player object
		      'reason' will default to "None" when nil (can be changed)
			
	Resolver.Unban(id : number, moderator : string|Player, reason : string?)
		Note: 'id' must be a UserId
		      'moderator' must be a string or Player object
		      'reason' will default to "No reason given" when nil
