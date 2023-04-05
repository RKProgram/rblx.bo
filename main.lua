local rblx = {}

local RBXScriptConnection = {}; do
	RBXScriptConnection.__index = RBXScriptConnection

	function RBXScriptConnection.new(func)
		return setmetatable({
			func = func,
			Connected = true
		}, RBXScriptConnection)
	end

	function RBXScriptConnection:Disconnect()
		self.func = function() end
		self.Connected = false
	end
	
end

local RBXScriptSignal = {}; do
	RBXScriptSignal.__index = RBXScriptSignal
	local runService = game:GetService("RunService")

	function RBXScriptSignal.new()
		return setmetatable({
			func = function() end,
			eventIns = Instance.new("IntValue"),
			connections = {},
			once = {}
		}, RBXScriptSignal)
	end

	function RBXScriptSignal:Fire(...)
		for index, connection in pairs(self.connections) do
			if connection.Connected then
				task.spawn(connection.func, ...)
			else
				self.connections[index] = nil
			end
		end
		for index, connection in pairs(self.once) do
			if connection.Connected then
				task.spawn(connection.func, ...)
			end
		end
		self.once = {}
		self.eventIns.Value += 1
	end

	function RBXScriptSignal:Connect(func)
		self.connections[func] = RBXScriptConnection.new(func)
		return self.connections[func]
	end

	function RBXScriptSignal:Wait()
		self.eventIns.Changed:Wait()
	end

	function RBXScriptSignal:Once(func)
		self.once[func] = RBXScriptConnection.new(func)
		return self.once[func]
	end
		
end

local message = {}; do
	message.__index = message
	function message.new(content: string, author: Player)
		local self = setmetatable({}, message)
		self.content = content
		self.author = author
		return self
	end
end

local ctx = {}; do
	function ctx.new(message, author)
		return {
			message = message,
			author = author
		}
	end
end

local client = {}; do
	client.services = {
		players = game:GetService("Players");
		replicatedstorage = game:GetService("ReplicatedStorage")
	};
	client.events = {
		PlayerAdded = client.services.players.PlayerAdded,
		PlayerRemoving = client.services.players.PlayerRemoving,
		OnMessage = RBXScriptSignal.new()
	};
	client.commands = {}
	client.__index = client
	function client:Init()
		if self.services.replicatedstorage:FindFirstChild("DefaultChatSystemChatEvents") then
			print("Old Chat")
			self.services.replicatedstorage.DefaultChatSystemChatEvents.OnMessageDoneFiltering.OnClientEvent:Connect(function(messageData)
				print(typeof(messageData.FromSpeaker))
				self.events.OnMessage:Fire(message.new(messageData.Message, game.Players[messageData.FromSpeaker]))
			end)
		else
			print("New Chat")
			local function onChat(author, msg)
				self.events.OnMessage:Fire(message.new(msg, author))
			end
			for index, player in pairs(self.services.players:GetPlayers()) do
				player.Chatted:Connect(function(msg)
					onChat(player, msg)
				end)
			end
			self.events.PlayerAdded:Connect(function(player)
				player.Chatted:Connect(function(msg)
					onChat(player, msg)
				end)
			end)
		end
		self.events.OnMessage:Connect(function(msg)
			self:HandleMessage(msg)
		end)
	end
	function client:HandleMessage(msg)
		local player = msg.author
		local message = msg.content
		if string.sub(message, 1, #self.Prefix) == self.Prefix then
			local spaceSplits = string.split(message, " ")
			local commandName = string.sub(spaceSplits[1], #self.Prefix + 1, #spaceSplits[1])
			local callback = self.Commands[commandName]
			if callback then
				local args = {}
				if #spaceSplits > 1 then
					for i = 2,#spaceSplits,1 do
						local argument = spaceSplits[i]
						args[#args + 1] = argument
					end
				end
				local ctx = ctx.new(msg, player)
				callback(ctx, unpack(args))
			end
		end
	end
	function client:OnEvent(eventName: string, callback)
		if self.events[eventName] then
			self.events[eventName]:Connect(callback)
		else
			error("No event named "..eventName)
		end
	end
	function client:Send(message: string)
		if not game.ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents") then
			game:GetService("TextChatService").TextChannels.RBXGeneral:SendAsync(message)
		else
			game.ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(message, "All")	
		end
	end
	function client:CreateCommand(commandName: string, callback)
		self.Commands[commandName] = callback
	end
	function client.new(command_prefix: string)
		local self = setmetatable({}, client)
		self.Prefix = command_prefix
		self.Commands = {}
		self:Init()
		return self
	end
end

function rblx:CreateClient(command_prefix: string)
	return client.new(command_prefix)
end

print("rblx.bo init..")

return rblx
