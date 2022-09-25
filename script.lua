--!strict
-- Credits to Hiatus/ApprenticeOfMadara
local BannedPlayers : DataStore = game:GetService("DataStoreService"):GetDataStore("Banned_1_")
local KickedPlayers : DataStore = game:GetService("DataStoreService"):GetDataStore("Kicked_1_")
local PlayerNotes   : DataStore = game:GetService("DataStoreService"):GetDataStore("Notes_1_")

local KickTypes = {
	error = "\n%s. \n(If this problem persists, please contact support)",
	sus = "Suspicious activity detected: %s."
}

local Moderators = {
	[12545525] = "Im_Hiatus"
}

local MAX_FETCH_ATTEMPTS = 10

local function GetId(user : Player | number) : number?
	local id : number = if typeof(user) == "Instance" and user:IsA("Player") then user.UserId else user
	
	if type(id) == "number" then
		return id
	else
		warn("Must send a Player or UserId! Sent:", user) return
	end
end

local function VerifyModerator(moderator : Player | number) : boolean
	if not moderator then warn("Must send a user! (Sent nil)") return false end
	
	local id = GetId(moderator)
	if not id or not Moderators[id] then
		return false, string.format("%d does not have permission to kick/ban users!", id or 0)
	end
	
	return true
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

	return (success and result) or warn("Failed to retrieve data from Roblox servers. Please try again later. Problem:", result)
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

	return success or false, warn("Failed to update data on Roblox servers. Please try again later. Problem:", msg)
end

local Resolver = {}

function Resolver.Note(user : Player | number, note : string, noter : (Player | number)?)
	if not user then warn("Must send a user! (Sent nil)") return end
	
	local id = GetId(user)
	if not id then return end
	
	local data = FetchData(id :: number, PlayerNotes) or {}
	table.insert(data, 1, {
		Date = os.date(),
		Note = note,
		Noter = noter or debug.traceback()
	})
	
	WriteToData(id :: number, PlayerNotes, data)
end

function Resolver.Kick(player : Player, reason : string, format : string)
	if not player or typeof(player) ~= "Instance" or not player:IsA("Player") then
		warn("Must send a player! Sent:", player) return
	end
	
	local data = FetchData(player.UserId, KickedPlayers) or {}
	table.insert(data, 1, {
		Date = os.date(),
		Reason = string.format("%s (%s)", reason, format),
		Traceback = debug.traceback()
	})

	WriteToData(player.UserId, KickedPlayers, data)
	player:Kick(string.format(KickTypes[format] or "%s", reason))
end

function Resolver.Ban(user : Player | number, moderator : Player, reason : string)
	if not user then warn("Must send a user! (Sent nil)") return end
	if not VerifyModerator(moderator) then return end
	
	local id = GetId(user)
	if not id then return end
	
	WriteToData(id :: number, BannedPlayers, {
		Banned = true,
		Reason = reason or "No reason given",
		Moderator = moderator.Name,
		Date = os.date()
	})
	
	if typeof(user) == "Instance" and user:IsA("Player") then
		user:Kick(reason)
	end
end

function Resolver.Unban(id : number, moderator : Player, reason : string)
	if type(id) ~= "number" then warn("Must send a UserId") return end
	if not VerifyModerator(moderator) then return end
	
	WriteToData(id, BannedPlayers, {
		Banned = false,
		Reason = reason or "No reason given",
		Moderator = moderator.Name,
		Date = os.date()
	})
end

function Resolver.VerifyGameAccess(user : Player | number) : boolean
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
