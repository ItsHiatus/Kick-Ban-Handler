# Kick-Ban-Note-Handler
Handles player banning/kicking/noting (server only)

How to use:

	Resolver.VerifyGameAccess(player | userId): boolean --> Checks if player has access to the game (false = banned)
	
		Note: Accepts a Player or UserId.
		
	Resolver.Kick(player, moderator : player | userId | nil, reason, format?) --> Kicks a player, saving the reason and date
			
		Note: 'moderator' can be a Player or UserId
		      'format' defines the reason for the kick (error/suspicious).
		       Each format has a different message, coupled with the reason:

			=> [error]  reason .. "If this problem persists, please contact support."
			=> [sus]    "Suspicious activity detected:" .. reason
			=> [nil]    reason (no extra message)
	
	Resolver.Ban(player | userId, reason) --> Bans a user, saving the reason and date.
	
		Note: Must use Resolver.VerifyGameAccess() when the player joins to check if they're banned or not
			
	Resolver.Unban(player | userId, reason) --> Unbans a user, saving the reason and date.
	
	Resolver.Note(player | userId, reason) --> Writes a note on the user
