-- Credits to Hiatus/ApprenticeOfMadara
local Resolver = {}
local BannedPlayers = game:GetService("DataStoreService"):GetDataStore("Banned_1_")
local KickedPlayers = game:GetService("DataStoreService"):GetDataStore("Kicked_1_")

local KickTypes = {
	error = "\n%s. \n(If this problem persists, please contact support)",
	sus = "Suspicious activity detected: %s."
}

local Moderators = {
	[12545525] = "Im_Hiatus"
}

local MAX_FETCH_ATTEMPTS = 10
local SHOULD_WARN = false

local function VerifyIsPlayer(player)
	if not player or typeof(player) ~= "Instance" or not player:IsA("Player") then
		return (SHOULD_WARN) and warn(string.format("Must send a player! (Sent: %s)", typeof(player)))
	end

	return true
end

local function VerifyModerator(moderator)
	if VerifyIsPlayer(moderator) then
		if not Moderators[moderator.UserId] then
			return (SHOULD_WARN and warn(string.format("%s does not have permission to kick/ban users!"), moderator.Name))
		end
	elseif not Moderators[moderator] then
		return (SHOULD_WARN and warn(string.format("%d does not have permission to kick/ban users!"), moderator))
	end
	
	return true
end

local function FetchData(user, store)
	if VerifyIsPlayer(user) then
		user = user.UserId
	end

	local success, result
	local attempt = 0

	while not success and attempt < MAX_FETCH_ATTEMPTS do
		attempt += 1

		success, result = pcall(function()
			return store:GetAsync(user)
		end)
	end

	return (success and result) or (SHOULD_WARN and warn("Failed to retrieve data from Roblox servers. Please try again later. Problem:", result))
end

local function WriteToData(user, store, data)
	if VerifyIsPlayer(user) then
		user = user.UserId
	end

	local success, msg
	local attempt = 0

	while not success and attempt < MAX_FETCH_ATTEMPTS do
		attempt += 1

		success, msg = pcall(function()
			return store:UpdateAsync(user, function(old)
				return data
			end)
		end)
	end

	return success or (SHOULD_WARN and warn("Failed to update data on Roblox servers. Please try again later. Problem:", msg))
end

function Resolver.Kick(player, reason, format)
	if not VerifyIsPlayer(player) then return end

	local kickedData = FetchData(player, KickedPlayers) or {}
	table.insert(kickedData, 1, {
		Date = os.date(),
		Reason = string.format("%s (%s)", reason, format),
		Traceback = debug.traceback()
	})

	WriteToData(player.UserId, KickedPlayers, kickedData)
	player:Kick(string.format(KickTypes[format] or "%s", reason))
end

function Resolver.Ban(user, moderator, reason)
	if not VerifyModerator(moderator) then return end
	
	WriteToData(user, BannedPlayers, {
		Banned = true,
		Reason = reason or "No reason given",
		Moderator = moderator.Name,
		Date = os.date()
	})

	if VerifyIsPlayer(user) then
		user:Kick(reason)
	end
end

function Resolver.Unban(user, moderator, reason)
	if not VerifyModerator(moderator) then return end
	
	WriteToData(user, BannedPlayers, {
		Banned = false,
		Reason = reason or "No reason given",
		Moderator = moderator.Name,
		Date = os.date()
	})
end

function Resolver.VerifyAccess(player)
	if not VerifyIsPlayer(player) then return end

	local bannedData = FetchData(player, BannedPlayers)
	if bannedData and bannedData.Banned then
		player:Kick(string.format("You are banned from this experience. Reason: %s", bannedData.Reason))
		return false
	end

	return true
end

return Resolver
