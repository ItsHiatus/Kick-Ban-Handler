--!strict
-- Credits to Hiatus/ApprenticeOfMadara
type Note = {
	Date : string,
	Note : string,
	Moderator : string,
	Traceback : string
}
type LogCategory = "Notes"|"Bans"|"Kicks"

local BannedPlayers : DataStore = game:GetService("DataStoreService"):GetDataStore("Banned_1_")
local KickedPlayers : DataStore = game:GetService("DataStoreService"):GetDataStore("Kicked_1_")
local PlayerNotes   : DataStore = game:GetService("DataStoreService"):GetDataStore("Notes_1_")

local KickTypes = {
	error = "\n%s. \n(If this problem persists, please contact support)",
	sus = "Suspicious activity detected: %s."
}

local Moderators : {[string|number] : string} = {
	Server = "Server",
	[12545525] = "Im_Hiatus"
}

local DEFAULT_KICK_REASON = "None"
local DEFAULT_BAN_REASON = "None"
local DEFAULT_UNBAN_REASON = "No reason given"
local MAX_FETCH_ATTEMPTS = 10

local function GetId(user : Player|number) : number?
	local id : number = if typeof(user) == "Instance" and user:IsA("Player") then user.UserId else user

	if type(id) == "number" then
		return id
	else
		warn("Must send a Player or UserId! Sent:", user) return
	end
end

local function IsModerator(moderator : string|Player) : string|boolean
	if not moderator then warn("Must send a player! (Sent nil)") return false end

	local mod
	if typeof(moderator) == "Instance" and moderator:IsA("Player") then
		mod = moderator.Name
	elseif typeof(moderator) == "string" then
		mod = moderator
	end

	if not mod or not Moderators[mod] then
		print("not mod")
		return false, warn(string.format("%s does not have permission to kick/ban users!", mod or "__nil"))
	end

	return mod
end

local function FetchData(userId : number, datastore : DataStore) : {[any] : any}?
	if not userId then warn("Must send a UserId! (Sent nil)") return end

	local success, result
	local attempt = 0

	while not success and attempt < MAX_FETCH_ATTEMPTS do
		attempt += 1

		success, result = pcall(function()
			return datastore:GetAsync(tostring(userId))
		end)
	end

	if not success then warn("Failed to retrieve data from Roblox servers. Please try again later. Problem:", result) end
	return success and result or nil
end

local function WriteToData(userId: number, datastore : DataStore, data : {any}) : boolean
	if not userId then warn("Must send a UserId! (Sent nil)") return false end

	local success, msg
	local attempt = 0

	while not success and attempt < MAX_FETCH_ATTEMPTS do
		attempt += 1

		success, msg = pcall(function()
			return datastore:UpdateAsync(tostring(userId), function(old)
				return data
			end)
		end)
	end

	if not success then warn("Failed to update data on Roblox servers. Please try again later. Problem:", msg) end
	return success
end

local Resolver = {}

function Resolver.Note(user : number|Player, note : string, moderator : string|Player)
	if not note or typeof(note) ~= "string" then warn("Must send a valid note! Sent:", note) return end

	local mod = IsModerator(moderator)
	if not mod then return end

	local id = GetId(user)
	if not id then return end

	local notes = FetchData(id :: number, PlayerNotes) or {}
	table.insert(notes, 1, {
		Date = os.date(),
		Note = note,
		Moderator = mod :: string,
		Traceback = debug.traceback()
	})

	WriteToData(id :: number, PlayerNotes, notes)
end

function Resolver.GetLogs(user : number|Player, category : LogCategory?)
	local id = GetId(user)
	if not id then return end
	
	if category == "Notes" then
		return FetchData(id :: number, PlayerNotes) or {}
	elseif category == "Kicks" then
		return FetchData(id :: number, KickedPlayers) or {}
	elseif category == "Bans" then
		return FetchData(id :: number, BannedPlayers) or {}
	else
		return {
			Notes = FetchData(id :: number, PlayerNotes) or {},
			Kicks = FetchData(id :: number, KickedPlayers) or {},
			Bans = FetchData(id :: number, BannedPlayers) or {}
		}
	end
end

function Resolver.Kick(player : Player, moderator : string|Player, reason : string?, format : string?)
	if not player or typeof(player) ~= "Instance" or not player:IsA("Player") then
		warn("Must send a player! Sent:", player) return
	end

	local mod = IsModerator(moderator)
	if not mod then return end

	reason = reason or DEFAULT_KICK_REASON

	local kick_logs = FetchData(player.UserId, KickedPlayers) or {}
	table.insert(kick_logs, 1, {
		Date = os.date(),
		Reason = string.format("%s (%s)", reason :: string, format or "General"),
		Moderator = mod,
		Traceback = debug.traceback()
	})

	WriteToData(player.UserId, KickedPlayers, kick_logs)
	player:Kick(string.format(KickTypes[format] or "%s", reason :: string))
end

function Resolver.Ban(user : number|Player, moderator : string|Player, duration : number, reason : string?)
	-- duration : seconds
	if not user then warn("Must send a user! (Sent nil)") return end
	if not duration or type(duration) ~= "number" then warn("Duration must be a number! Sent:", duration) return end
	
	local mod = IsModerator(moderator)
	if not mod then return end

	local id = GetId(user)
	if not id then return end
	
	reason = reason or DEFAULT_BAN_REASON
	
	local ban_logs : {any} = FetchData(id :: number, BannedPlayers) or {}
	if ban_logs[1] and ban_logs[1].Banned then warn(user, "already banned!") return end
	
	table.insert(ban_logs, 1, {
		Banned = true,
		Date = os.date(),
		Reason = reason,
		Moderator = mod,
		Traceback = debug.traceback(),
		TimeOfBan = os.time(),
		Duration = math.round(duration),
	})
	
	WriteToData(id :: number, BannedPlayers, ban_logs)

	if typeof(user) == "Instance" and user:IsA("Player") then
		user:Kick(reason)
	end
end

function Resolver.Unban(id : number, moderator : string|Player, reason : string?)
	if type(id) ~= "number" then warn("Must send a UserId") return end

	local mod = IsModerator(moderator)
	if not mod then return end
	
	reason = reason or DEFAULT_UNBAN_REASON
	
	local ban_logs = FetchData(id :: number, BannedPlayers) or {}
	table.insert(ban_logs, 1, {
		Banned = false,
		Date = os.date(),
		Reason = reason,
		Moderator = mod,
		Traceback = debug.traceback()
	})
	
	WriteToData(id :: number, BannedPlayers, ban_logs)
end

function Resolver.VerifyGameAccess(user : number|Player) : boolean
	if not user then warn("Must send a user! (Sent nil)") return false end

	local id = GetId(user)
	if not id then return false end

	local ban_logs = FetchData(id :: number, BannedPlayers)
	local latest_log = ban_logs and ban_logs[1]
	
	if not latest_log or not latest_log.Banned then
		return true
	elseif latest_log.Duration > 0 and os.time() > latest_log.TimeOfBan + latest_log.Duration then
		Resolver.Unban(id :: number, "Server", "Ban duration finished")
		return true
	elseif typeof(user) == "Instance" and user:IsA("Player") then
		user:Kick(string.format("You are banned from this experience. Reason: %s", latest_log.Reason))
	end

	return false
end

return Resolver
