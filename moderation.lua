--!strict
-- Credits to Hiatus/ApprenticeOfMadara
-- Settings
local DefaultModerators : {string} = {
	[-1] = "Server", -- id -1 is reserved for game
	[12545525] = "Im_Hiatus",
}

local KickMessageFormats = {
	error = "\n%s. \n(If this problem persists, please contact support)",
	sus = "Suspicious activity detected: %s."
}

local DEFAULT_KICK_REASON = "None"
local DEFAULT_BAN_REASON = "None"
local DEFAULT_UNBAN_REASON = "No reason given"

local MAX_PCALL_ATTEMPTS = 10
type Subscription = "UpdateMods" | "KickPlayer" -- for MessagingService

local MODS_DS_KEY = "Mods_1_"
local BANS_DS_KEY = "Bans_1_"
local KICKS_DS_KEY = "Kicks_1_"
local NOTES_DS_KEY = "Notes_1_"
--

type Data = {[any] : any}
type List = {string}
type Message = {Data : any, Sent : number}

type User = Player | number
type LogCategory = "Notes"|"Bans"|"Kicks"

local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local ServerId = (game:GetService("RunService"):IsStudio()) and "Studio" or game.JobId

local ModerationStore : DataStore = game:GetService("DataStoreService"):GetDataStore("Moderation_1")
local Moderators : List

local function FetchData(key : string) : (Data, boolean)
	if not key then warn("Must send a valid key! (Sent nil)") return {}, false end

	local success, result

	for attempt = 1, MAX_PCALL_ATTEMPTS do
		success, result = pcall(function()
			return ModerationStore:GetAsync(key)
		end)

		if success then return result or {}, success end
	end

	warn("Failed to retrieve data from Roblox servers. Please try again later. Problem:", result)
	return {}, false
end

local function WriteToData(key : string, data : Data) : boolean
	if not key then warn("Must send a valid key! (Sent nil)") return false end

	local success, msg

	for attempt = 1, MAX_PCALL_ATTEMPTS do
		success, msg = pcall(function()
			return ModerationStore:UpdateAsync(key, function(old)
				return data
			end)
		end)

		if success then return success end
	end

	warn("Failed to update data on Roblox servers. Please try again later. Problem:", msg)
	return false
end

local function SubscribeToMessage(topic : Subscription, callback : (any) -> ()) : (RBXScriptConnection?, boolean)
	if not topic or type(topic) ~= "string" then
		warn("Please send a valid topic to subscribe to! Sent:", topic) return nil, false
	end

	local success, result

	for attempt = 1, MAX_PCALL_ATTEMPTS do
		success, result = pcall(function()
			return MessagingService:SubscribeAsync(topic, callback)
		end)

		if success then return result, success end
	end

	warn(string.format("Failed to subscribe to %s. Please try again later. Error: %s", topic, result))
	return nil, false
end

local function PublishMessage(topic : Subscription, message : any) : boolean
	if not topic or type(topic) ~= "string" then
		warn("Please send a valid topic to publish to! Sent:", topic) return false
	end

	local success, result

	for attempt = 1, MAX_PCALL_ATTEMPTS do
		success, result = pcall(function()
			return MessagingService:PublishAsync(topic, message)
		end)

		if success then return true end
	end

	warn(string.format("Failed to publish to %s. Please try again later. Error: %s", topic, result))
	return false
end

local function GetId(user : User) : number?
	local id : number = if typeof(user) == "Instance" and user:IsA("Player") then user.UserId else user

	if type(id) == "number" then
		return id
	else
		warn("Must send a Player or UserId! Sent:", user) return nil
	end
end

local function IsModerator(moderator : User) : string|boolean
	if not Moderators then warn("Mod list has not been fetched yet (Call UpdateModerators())") return false end
	if not moderator then warn("Must send a player! (Sent nil)") return false end

	local id = GetId(moderator) :: number
	if not id or not Moderators[id] then
		warn(string.format("%s does not have permission to kick/ban users!", tostring(id))) return false
	end

	return Moderators[id]
end

local Moderation = {}

function Moderation.VerifyGameAccess(user : User) : boolean
	local id = GetId(user)
	if not id then return false end

	local key = BANS_DS_KEY .. tostring(id)
	local ban_logs = FetchData(key)
	local latest_log = ban_logs[1]

	if not latest_log or not latest_log.Banned then
		return true
	elseif latest_log.Duration > 0 and os.time() > latest_log.TimeOfBan + latest_log.Duration then
		Moderation.Unban(id :: number, -1, "Ban duration finished")
		return true
	elseif typeof(user) == "Instance" and user:IsA("Player") then
		user:Kick(string.format("You are banned from this experience. Reason: %s", latest_log.Reason))
	end

	return false
end

function Moderation.AddModerator(new_moderator : User, moderator : User)
	if not new_moderator then warn("Must send a valid user! Sent:", new_moderator) return end
	if not IsModerator(moderator) then warn("Must send a valid moderator to grant others mod! Sent:", moderator) return end
	
	local added_mods, fetch_success = FetchData(MODS_DS_KEY)
	if not fetch_success then return end
	
	local id : number
	local name : string

	if typeof(new_moderator) == "number" then
		id = new_moderator
		name = tostring(id)

		added_mods[id] = name
		Moderators[id] = name

	elseif typeof(new_moderator) == "Instance" then
		id = GetId(new_moderator) :: number
		if not id then return end

		name = new_moderator.Name

		added_mods[id] = name
		Moderators[id] = name
	end

	local update_success = WriteToData(MODS_DS_KEY, added_mods)
	if not update_success then warn("Failed to update mod list datastore") return end

	PublishMessage("UpdateMods", {
		Action = "Add",
		Mod = {Id = id, Name = name},
		Server = ServerId
	})
end

function Moderation.RemoveModerator(old_moderator : User, moderator : User)
	if not old_moderator then warn("Must send a valid user! Sent:", old_moderator) return end
	if not IsModerator(moderator) then warn("Must send a valid moderator to grant others mod! Sent:", moderator) return end
	
	local added_mods, fetch_success = FetchData(MODS_DS_KEY)
	if not fetch_success then return end

	local id = GetId(old_moderator) :: number
	if not id then return end
	if not Moderators[id] then warn(id, "is not a moderator!") return end

	added_mods[id] = nil
	Moderators[id] = nil

	local update_success = WriteToData(MODS_DS_KEY, added_mods)
	if not update_success then warn("Failed to update mod list datastore") return end

	PublishMessage("UpdateMods", {
		Action = "Remove",
		Mod = {Id = id},
		Server = ServerId
	})
end

function Moderation.UpdateModerators() : boolean?
	local new_mod_list = {}

	for id, name in pairs(DefaultModerators) do -- fill in the default mods (server setup)
		if new_mod_list[id] then continue end
		new_mod_list[id] = name
	end

	local added_mods, fetch_success = FetchData(MODS_DS_KEY)
	if not fetch_success then warn("Failed to get list of mods added to the datastore") return false end

	for id, name in pairs(added_mods) do
		new_mod_list[id] = name
	end

	Moderators = new_mod_list
	return true
end

function Moderation.GetModerators() : List
	if not Moderators then Moderation.UpdateModerators() end
	return Moderators
end

function Moderation.Note(user : User, moderator : User, note : string)
	if not note or typeof(note) ~= "string" then warn("Must send a valid note! Sent:", note) return end

	local mod = IsModerator(moderator)
	if not mod then return end

	local id = GetId(user) :: number
	if not id then return end

	local key = NOTES_DS_KEY .. tostring(id)

	local notes = FetchData(key)
	table.insert(notes, 1, {
		Date = os.date(),
		Note = note,
		Moderator = mod :: string,
		Traceback = debug.traceback()
	})

	WriteToData(key, notes)
	print(string.format("added note to %d", id))
end

function Moderation.GetLogs(user : User, moderator : User, category : LogCategory?)
	local mod = IsModerator(moderator)
	if not mod then return end

	local id = tostring(GetId(user))
	if not id or id == "nil" then return end

	if category == "Notes" then
		return FetchData(NOTES_DS_KEY .. id)
	elseif category == "Kicks" then
		return FetchData(KICKS_DS_KEY .. id)
	elseif category == "Bans" then
		return FetchData(BANS_DS_KEY .. id)
	else
		return {
			Notes = FetchData(NOTES_DS_KEY .. id),
			Kicks = FetchData(KICKS_DS_KEY .. id),
			Bans = FetchData(BANS_DS_KEY .. id)
		}
	end
end

function Moderation.Kick(user : User, moderator : User, reason : string?, format : string?)
	local mod = IsModerator(moderator)
	if not mod then return end

	local id = GetId(user)
	if not id then return end
	
	reason = reason or DEFAULT_KICK_REASON :: string
	
	local key = KICKS_DS_KEY .. tostring(id)
	local kick_logs = FetchData(key)
	table.insert(kick_logs, 1, {
		Date = os.date(),
		Reason = string.format("%s (%s)", reason :: string, format or "Unspecified"),
		Moderator = mod :: string,
		Traceback = debug.traceback()
	})

	WriteToData(key, kick_logs)

	local player = Players:GetPlayerByUserId(id)
	if player then
		player:Kick(string.format(KickMessageFormats[format] or "%s", reason))
		print(id, "has been kicked from the game")
	else
		print("finding player in other servers...")
		PublishMessage("KickPlayer", {
			UserId = id,
			Reason = reason,
			Format = format
		})
	end
end

function Moderation.Ban(user : User, moderator : User, duration : number, reason : string?)
	-- duration : seconds
	if not duration or type(duration) ~= "number" then warn("Duration must be a number! Sent:", duration) return end

	local mod = IsModerator(moderator)
	if not mod then return end

	local id = GetId(user)
	if not id then return end

	reason = reason or DEFAULT_BAN_REASON
	
	local key = BANS_DS_KEY .. tostring(id)
	local ban_logs = FetchData(key)
	if ban_logs[1] and ban_logs[1].Banned then warn(user, "already banned!") return end
	
	table.insert(ban_logs, 1, {
		Banned = true,
		Date = os.date(),
		Reason = reason,
		Moderator = mod :: string,
		Traceback = debug.traceback(),
		TimeOfBan = os.time(),
		Duration = math.round(duration),
	})

	WriteToData(key, ban_logs)
	Moderation.Kick(id :: number, -1, reason)

	print(id, "has been banned from the game")
end

function Moderation.Unban(id : number, moderator : User, reason : string?)
	if type(id) ~= "number" then warn("Must send a valid UserId to unban!", id) return end

	local mod = IsModerator(moderator)
	if not mod then return end

	reason = reason or DEFAULT_UNBAN_REASON
	
	local key = BANS_DS_KEY .. tostring(id)
	local ban_logs = FetchData(key)
	
	if ban_logs[1] and not ban_logs[1].Banned then warn(id, "already unbanned") return end
	
	table.insert(ban_logs, 1, {
		Banned = false,
		Date = os.date(),
		Reason = reason,
		Moderator = mod :: string,
		Traceback = debug.traceback()
	})

	WriteToData(key, ban_logs)
	print(id, "has been unbanned")
end

-- Required
Moderation.UpdateModerators()
SubscribeToMessage("UpdateMods", function(message : Message)
	if not message or type(message.Data) ~= "table" then warn("No valid update has been received:", message) return end
	if message.Data.Server == ServerId then return end
	
	local mod = message.Data.Mod
	
	if message.Data.Action == "Add" then
		Moderators[mod.Id] = mod.Name
	elseif message.Data.Action == "Remove" then
		Moderators[mod.Id] = nil
	end
	
	print("updated mods")
end)

SubscribeToMessage("KickPlayer", function(message : Message)
	if not message or type(message.Data) ~= "table" then warn("Received no valid id to kick") return end
	
	local id = message.Data.UserId
	local reason = message.Data.Reason or DEFAULT_KICK_REASON
	local format = message.Data.Format
	
	if type(id) ~= "number" then warn("Please send a valid UserId. Sent:", id) return end
	if type(reason) ~= "string" then warn("Please send a valid reason! Sent:", reason) return end
	if format and type(format) ~= "string" then warn("Please send a valid format! Sent:", format) return end
	
	local player = Players:GetPlayerByUserId(id)
	if player then
		player:Kick(string.format(KickMessageFormats[format] or "%s", reason))
		print(player.UserId, "has been kicked from the game")
	else
		--print(string.format("could not find %d in this server (%s)", id, ServerId))
	end
end)
--

return Moderation
