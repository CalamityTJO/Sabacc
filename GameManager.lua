-- GameManager.lua (WORKING 2-PLAYER VERSION)
-- Location: ServerScriptService > GameManager

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local CardData = require(ReplicatedStorage.Modules.CardData)
local DeckManager = require(ServerScriptService.DeckManager)
local HandEvaluator = require(ServerScriptService.HandEvaluator)

-- Remote Events
local DrawCardEvent = ReplicatedStorage.RemoteEvents.DrawCard
local StandActionEvent = ReplicatedStorage.RemoteEvents.StandAction
local UpdateGameStateEvent = ReplicatedStorage.RemoteEvents.UpdateGameState

local GameManager = {}
GameManager.ActiveGames = {}

-- Game Instance Class
local GameInstance = {}
GameInstance.__index = GameInstance

function GameInstance.new(tableId)
	local self = setmetatable({}, GameInstance)

	self.tableId = tableId
	self.players = {}
	self.playerList = {}
	self.deckManager = DeckManager.new()
	self.currentTurn = 1
	self.currentPlayerIndex = 1
	self.roundActive = false
	self.gameActive = false

	print("Created new game instance for table: " .. tableId)

	return self
end

function GameInstance:AddPlayer(player)
	if self.players[player] then
		return false, "Already in game"
	end

	if self:GetPlayerCount() >= GameConfig.MAX_PLAYERS then
		return false, "Table is full"
	end

	self.players[player] = {
		chips = GameConfig.STARTING_CHIPS,
		sandCard = nil,
		bloodCard = nil,
		hasStood = false,
		chipsInvested = 0,
		tokens = {},
		usedToken = false
	}

	table.insert(self.playerList, player)

	print(player.Name .. " joined the table (" .. self:GetPlayerCount() .. "/" .. GameConfig.MIN_PLAYERS .. " players)")

	-- Auto-start when enough players join
	if self:GetPlayerCount() >= GameConfig.MIN_PLAYERS and not self.gameActive then
		wait(2)
		self:StartGame()
	end

	return true, "Joined table"
end

function GameInstance:RemovePlayer(player)
	self.players[player] = nil

	for i, p in ipairs(self.playerList) do
		if p == player then
			table.remove(self.playerList, i)
			break
		end
	end

	print(player.Name .. " left the table")

	if self.gameActive and self:GetPlayerCount() < GameConfig.MIN_PLAYERS then
		self:EndGame("Not enough players")
	end
end

function GameInstance:GetPlayerCount()
	return #self.playerList
end

function GameInstance:StartGame()
	if self:GetPlayerCount() < GameConfig.MIN_PLAYERS then
		return false, "Need at least " .. GameConfig.MIN_PLAYERS .. " players"
	end

	self.gameActive = true
	print("?? Starting Sabacc game with " .. self:GetPlayerCount() .. " players!")

	self:StartRound()
	return true, "Game started"
end

function GameInstance:StartRound()
	self.roundActive = true
	self.currentTurn = 1
	self.currentPlayerIndex = 1

	print("?? Starting new round...")

	-- Reset player states
	for player, data in pairs(self.players) do
		data.hasStood = false
		data.chipsInvested = 0
		data.usedToken = false
	end

	-- Deal initial cards
	self:DealCards()

	wait(0.5)
	self:BroadcastGameState()

	print("? Round started")
end

function GameInstance:DealCards()
	for player, data in pairs(self.players) do
		data.sandCard = self.deckManager:DrawCard("Sand")
		data.bloodCard = self.deckManager:DrawCard("Blood")
		print("Dealt cards to " .. player.Name)
	end
end

function GameInstance:GetCurrentPlayer()
	if #self.playerList == 0 then return nil end
	return self.playerList[self.currentPlayerIndex]
end

function GameInstance:NextTurn()
	if not self.roundActive then return end

	-- Check if all players have stood
	local allStood = true
	for player, data in pairs(self.players) do
		if not data.hasStood then
			allStood = false
			break
		end
	end

	if allStood or self.currentTurn > GameConfig.MAX_TURNS then
		self:EndRound()
		return
	end

	-- Move to next player
	local playerList = self:GetPlayerList()
	local attempts = 0
	repeat
		self.currentPlayerIndex = self.currentPlayerIndex + 1
		if self.currentPlayerIndex > #playerList then
			self.currentPlayerIndex = 1
			self.currentTurn = self.currentTurn + 1
		end

		attempts = attempts + 1
		if attempts > #playerList * 2 then
			self:EndRound()
			return
		end

		if self.currentTurn > GameConfig.MAX_TURNS then
			self:EndRound()
			return
		end
	until not self.players[playerList[self.currentPlayerIndex]].hasStood

	print("Turn " .. self.currentTurn .. " - " .. self:GetCurrentPlayer().Name .. "'s turn")

	self:BroadcastGameState()
end

function GameInstance:GetPlayerList()
	return self.playerList
end

function GameInstance:PlayerDrawCard(player, deckType, fromDiscard)
	local data = self.players[player]
	if not data or data.hasStood then 
		return false 
	end

	if self:GetCurrentPlayer() ~= player then
		return false, "Not your turn"
	end

	if data.chips < GameConfig.DRAW_COST then
		return false, "Not enough chips"
	end

	local newCard = fromDiscard and self.deckManager:DrawFromDiscard(deckType) or self.deckManager:DrawCard(deckType)

	if not newCard then
		return false, "No cards available"
	end

	-- Deduct chips
	data.chips = data.chips - GameConfig.DRAW_COST
	data.chipsInvested = data.chipsInvested + GameConfig.DRAW_COST

	-- Discard and replace
	if deckType == "Sand" then
		if data.sandCard then
			self.deckManager:DiscardCard(data.sandCard)
		end
		data.sandCard = newCard
	else
		if data.bloodCard then
			self.deckManager:DiscardCard(data.bloodCard)
		end
		data.bloodCard = newCard
	end

	print(player.Name .. " drew a " .. deckType .. " card")

	self:NextTurn()
	return true, "Card drawn"
end

function GameInstance:PlayerStand(player)
	local data = self.players[player]
	if not data then return false end

	if self:GetCurrentPlayer() ~= player then
		return false, "Not your turn"
	end

	data.hasStood = true
	print(player.Name .. " is standing")

	self:NextTurn()
	return true, "Standing"
end

function GameInstance:EndRound()
	self.roundActive = false
	print("?? Round ending, evaluating hands...")

	-- Evaluate all hands
	local playerHands = {}
	for player, data in pairs(self.players) do
		playerHands[player] = {
			sandCard = data.sandCard,
			bloodCard = data.bloodCard
		}
	end

	local results = HandEvaluator.DetermineWinner(playerHands)

	-- Award chips to winner
	if results.winner then
		local winnerData = self.players[results.winner]
		winnerData.chips = winnerData.chips + winnerData.chipsInvested

		print("?? " .. results.winner.Name .. " wins the round!")

		-- Tax losers
		for player, data in pairs(self.players) do
			if player ~= results.winner then
				data.chips = math.max(0, data.chips - GameConfig.BASE_TAX)
			end
		end
	end

	-- Eliminate players with no chips
	local playersToRemove = {}
	for player, data in pairs(self.players) do
		if data.chips <= 0 then
			table.insert(playersToRemove, player)
		end
	end

	for _, player in ipairs(playersToRemove) do
		self:RemovePlayer(player)
	end

	-- Broadcast results
	self:BroadcastResults(results)

	wait(GameConfig.ROUND_END_DELAY)

	if self:GetPlayerCount() >= GameConfig.MIN_PLAYERS then
		self.deckManager:Reset()
		self:StartRound()
	else
		local winnerName = results.winner and results.winner.Name or "No one"
		self:EndGame(winnerName .. " wins!")
	end
end

function GameInstance:EndGame(reason)
	self.gameActive = false
	self.roundActive = false
	print("?? Game ended: " .. reason)
end

function GameInstance:BroadcastGameState()
	local playersData = {}
	for p, data in pairs(self.players) do
		playersData[p] = {
			chips = data.chips,
			hasStood = data.hasStood,
			chipsInvested = data.chipsInvested
		}
	end

	for player, playerData in pairs(self.players) do
		local state = {
			currentTurn = self.currentTurn,
			currentPlayer = self:GetCurrentPlayer(),
			myData = {
				chips = playerData.chips,
				sandCard = playerData.sandCard and playerData.sandCard:Serialize() or nil,
				bloodCard = playerData.bloodCard and playerData.bloodCard:Serialize() or nil,
				hasStood = playerData.hasStood,
				chipsInvested = playerData.chipsInvested
			},
			players = playersData,
			sandDiscardTop = self.deckManager:GetTopDiscard("Sand") and self.deckManager:GetTopDiscard("Sand"):Serialize() or nil,
			bloodDiscardTop = self.deckManager:GetTopDiscard("Blood") and self.deckManager:GetTopDiscard("Blood"):Serialize() or nil
		}

		UpdateGameStateEvent:FireClient(player, state)
	end
end

function GameInstance:BroadcastResults(results)
	local serializedResults = {
		winner = results.winner,
		isTie = results.isTie,
		evaluations = {}
	}

	for player, evaluation in pairs(results.evaluations) do
		serializedResults.evaluations[player] = evaluation
	end

	for player in pairs(self.players) do
		UpdateGameStateEvent:FireClient(player, {
			type = "roundEnd",
			results = serializedResults
		})
	end
end

-- Monitor seats
local function setupTableMonitoring()
	local sabaccTable = Workspace:WaitForChild("SabaccTable", 10)

	if not sabaccTable then
		warn("?? No SabaccTable found in Workspace!")
		return
	end

	print("? Found SabaccTable")

	local seats = {}
	for _, child in ipairs(sabaccTable:GetChildren()) do
		if child:IsA("Seat") and child.Name:match("PlayerSeat") then
			table.insert(seats, child)
		end
	end

	print("Found " .. #seats .. " seats")

	local tableId = sabaccTable.Name

	for _, seat in ipairs(seats) do
		seat:GetPropertyChangedSignal("Occupant"):Connect(function()
			if seat.Occupant then
				local character = seat.Occupant.Parent
				local player = Players:GetPlayerFromCharacter(character)

				if player then
					print("?? " .. player.Name .. " sat at table")

					if not GameManager.ActiveGames[tableId] then
						GameManager.ActiveGames[tableId] = GameInstance.new(tableId)
					end

					local game = GameManager.ActiveGames[tableId]
					game:AddPlayer(player)
				end
			end
		end)
	end

	print("? Seat monitoring active!")
end

-- Event Connections
DrawCardEvent.OnServerEvent:Connect(function(player, deckType, fromDiscard)
	for _, game in pairs(GameManager.ActiveGames) do
		if game.players[player] then
			game:PlayerDrawCard(player, deckType, fromDiscard)
			break
		end
	end
end)

StandActionEvent.OnServerEvent:Connect(function(player)
	for _, game in pairs(GameManager.ActiveGames) do
		if game.players[player] then
			game:PlayerStand(player)
			break
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	for _, game in pairs(GameManager.ActiveGames) do
		if game.players[player] then
			game:RemovePlayer(player)
		end
	end
end)

wait(2)
setupTableMonitoring()

print("?? GameManager loaded and ready!")

return GameManager