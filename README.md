# Kick-Ban-Handler
Handles player banning/kicking (server only)

How to use:

	Resolver.VerifyAccess(player): boolean --> Checks if player has access to the game (false = banned)

	Resolver.Kick(player, reason, format?) --> Kicks a player, saving the reason and date in newest slot
			
		Note: 'format' defines the reason for the kick (error/suspicious).
		       Each format has a different message, coupled with the reason:

			=> [error]  reason .. "If this problem persists, please contact support."
			=> [sus]    "Suspicious activity detected:" .. reason
			=> [nil]    reason (no extra message)
	
	Resolver.Ban(user: Player|number, reason) --> Bans a user, saving the reason and date.
			
		Note: Accepts a Player instance or UserId for first arg. 
		      Must use Resolver.Verify() when the player joins to check if they're banned or not
			
	Resolver.Unban(user: Player|number, reason) --> Unbans a user, saving the reason and date.
			
		Note: Accepts a Player instance or UserId for first arg.
