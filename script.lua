--!strict
-- Credits to Hiatus/ApprenticeOfMadara
local BannedPlayers : DataStore = game:GetService("DataStoreService"):GetDataStore("Banned_1_")
local KickedPlayers : DataStore = game:GetService("DataStoreService"):GetDataStore("Kicked_1_")
local PlayerNotes   : DataStore = game:GetService("DataStoreService"):GetDataStore("Notes_1_")

local KickTypes = {
	error = "\n%s. \n(If this problem persists, please contact support)",
	sus = "Suspicious activity detected: %s."
}

local Moderators : {[string|number] : string} = {
	Im_Hiatus = "Im_Hiatus",
	[12545525] = "Im_Hiatus"
}

local DEFAULT_KICK_REASON = "None"
local DEFAULT_BAN_REASON = "None"
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
		return false, string.format("%s does not have permission to kick/ban users!", mod or "__nil")
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
	
	local data = FetchData(id :: number, PlayerNotes) or {}
	table.insert(data, 1, {
		Date = os.date(),
		Note = note,
		Moderator = mod :: string,
		Traceback = debug.traceback()
	})
	
	WriteToData(id :: number, PlayerNotes, data)
end

function Resolver.Kick(player : Player, moderator : string|Player, reason : string?, format : string?)
	if not player or typeof(player) ~= "Instance" or not player:IsA("Player") then
		warn("Must send a player! Sent:", player) return
	end
	
	local mod = IsModerator(moderator)
	if not mod then return end
	
	reason = reason or DEFAULT_KICK_REASON
	
	local data = FetchData(player.UserId, KickedPlayers) or {}
	table.insert(data, 1, {
		Date = os.date(),
		Reason = string.format("%s (%s)", reason :: string, format or "General"),
		Moderator = mod,
	})

	WriteToData(player.UserId, KickedPlayers, data)
	player:Kick(string.format(KickTypes[format] or "%s", reason :: string))
end

function Resolver.Ban(user : number|Player, moderator : string|Player, reason : string?)
	if not user then warn("Must send a user! (Sent nil)") return end
	
	local mod = IsModerator(moderator)
	if not mod then return end
	
	local id = GetId(user)
	if not id then return end
	
	reason = DEFAULT_BAN_REASON
	
	WriteToData(id :: number, BannedPlayers, {
		Banned = true,
		Reason = reason,
		Moderator = mod,
		Date = os.date()
	})
	
	if typeof(user) == "Instance" and user:IsA("Player") then
		user:Kick(reason)
	end
end

function Resolver.Unban(id : number, moderator : string|Player, reason : string)
	if type(id) ~= "number" then warn("Must send a UserId") return end
	
	local mod = IsModerator(moderator)
	if not mod then return end
	
	WriteToData(id, BannedPlayers, {
		Banned = false,
		Reason = reason or "No reason given",
		Moderator = mod,
		Date = os.date()
	})
end

function Resolver.VerifyGameAccess(user : number|Player) : boolean
	if not user then warn("Must send a user! (Sent nil)") return false end
	
	local id = GetId(user)
	if not id then return false end

	local ban_data = FetchData(id :: number, BannedPlayers)
	if not ban_data or not ban_data.Banned then
		return true 
	elseif typeof(user) == "Instance" and user:IsA("Player") then
		user:Kick(string.format("You are banned from this experience. Reason: %s", ban_data.Reason))
	end
	
	return false
end

return Resolver
