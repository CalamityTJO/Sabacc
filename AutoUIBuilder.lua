-- AutoUIBuilder.lua (WORKING VERSION)
-- Location: StarterGui > AutoUIBuilder (LocalScript)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("?? Building Sabacc UI...")

local CardData = require(ReplicatedStorage.Modules.CardData)
local DrawCardEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("DrawCard")
local StandActionEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("StandAction")
local UpdateGameStateEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("UpdateGameState")

-- Card Asset IDs
local CARD_ASSETS = {
	Sand = {
		[1] = "rbxassetid://102611808939661",
		[2] = "rbxassetid://89429393168464",
		[3] = "rbxassetid://71399034051488",
		[4] = "rbxassetid://97982201542875",
		[5] = "rbxassetid://121591668416482",
		[6] = "rbxassetid://124232684294156",
	},
	Blood = {}
}

local currentGameState = nil
local myPlayerData = nil
local isSittingAtTable = false

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SabaccUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local function createFrame(name, parent, props)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Parent = parent

	local cornerRadius = props.CornerRadius or 15

	for prop, value in pairs(props) do
		if prop ~= "CornerRadius" then
			frame[prop] = value
		end
	end

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, cornerRadius)
	corner.Parent = frame

	return frame
end

local function createButton(name, parent, props)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Parent = parent
	button.Font = Enum.Font.GothamBold
	button.TextSize = props.TextSize or 20
	button.TextColor3 = Color3.new(1, 1, 1)
	button.BorderSizePixel = 4
	button.AutoButtonColor = false

	local cornerRadius = props.CornerRadius or 15
	local originalSize = props.Size

	for prop, value in pairs(props) do
		if prop ~= "TextSize" and prop ~= "CornerRadius" then
			button[prop] = value
		end
	end

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, cornerRadius)
	corner.Parent = button

	return button
end

local function createLabel(name, parent, props)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Parent = parent
	label.Font = Enum.Font.GothamBold
	label.TextSize = props.TextSize or 20
	label.TextColor3 = Color3.new(1, 1, 1)
	label.BackgroundTransparency = props.BackgroundTransparency or 0
	label.BorderSizePixel = 0

	local cornerRadius = props.CornerRadius or 10
	local noCorner = props.NoCorner

	for prop, value in pairs(props) do
		if prop ~= "TextSize" and prop ~= "CornerRadius" and prop ~= "NoCorner" then
			label[prop] = value
		end
	end

	if not noCorner then
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, cornerRadius)
		corner.Parent = label
	end

	return label
end

-- Main Frame
local mainFrame = createFrame("MainFrame", screenGui, {
	Size = UDim2.new(0.95, 0, 0.95, 0),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = Color3.fromRGB(20, 40, 30),
	BorderSizePixel = 4,
	BorderColor3 = Color3.fromRGB(240, 165, 0),
	Visible = false,
	CornerRadius = 30
})

-- Header
local header = createFrame("Header", mainFrame, {
	Size = UDim2.new(1, 0, 0.1, 0),
	Position = UDim2.new(0, 0, 0, 0),
	BackgroundColor3 = Color3.fromRGB(44, 24, 16),
	BorderSizePixel = 0,
	CornerRadius = 0
})

local title = createLabel("Title", header, {
	Size = UDim2.new(0.5, 0, 1, 0),
	Position = UDim2.new(0, 20, 0, 0),
	Text = "? SABACC ?",
	TextSize = 36,
	TextColor3 = Color3.fromRGB(240, 165, 0),
	BackgroundTransparency = 1,
	NoCorner = true
})

local chipDisplay = createFrame("ChipDisplay", header, {
	Size = UDim2.new(0, 200, 0, 50),
	Position = UDim2.new(1, -220, 0.5, -25),
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 0.5,
	BorderSizePixel = 3,
	BorderColor3 = Color3.fromRGB(255, 215, 0),
	CornerRadius = 25
})

local chipIcon = createLabel("ChipIcon", chipDisplay, {
	Size = UDim2.new(0, 50, 1, 0),
	Position = UDim2.new(0, 5, 0, 0),
	Text = "??",
	TextSize = 28,
	BackgroundTransparency = 1,
	NoCorner = true
})

local chipCount = createLabel("ChipCount", chipDisplay, {
	Size = UDim2.new(1, -60, 1, 0),
	Position = UDim2.new(0, 55, 0, 0),
	Text = "20",
	TextSize = 28,
	TextColor3 = Color3.fromRGB(255, 215, 0),
	BackgroundTransparency = 1,
	NoCorner = true
})

-- Play Area
local playArea = createFrame("PlayArea", mainFrame, {
	Size = UDim2.new(1, -40, 0.9, -40),
	Position = UDim2.new(0, 20, 0.1, 20),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	CornerRadius = 0
})

-- Left Section
local leftSection = createFrame("LeftSection", playArea, {
	Size = UDim2.new(0.7, -20, 1, 0),
	Position = UDim2.new(0, 0, 0, 0),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	CornerRadius = 0
})

local turnIndicator = createFrame("TurnIndicator", leftSection, {
	Size = UDim2.new(1, 0, 0.12, 0),
	Position = UDim2.new(0, 0, 0.35, 0),
	BackgroundColor3 = Color3.fromRGB(149, 165, 166),
	BorderSizePixel = 3,
	BorderColor3 = Color3.fromRGB(90, 98, 104),
	CornerRadius = 15
})

local turnLabel = createLabel("TurnLabel", turnIndicator, {
	Size = UDim2.new(1, 0, 1, 0),
	Text = "? Waiting for game...",
	TextSize = 24,
	BackgroundTransparency = 1,
	NoCorner = true
})

local playerHand = createFrame("PlayerHand", leftSection, {
	Size = UDim2.new(1, 0, 0.5, 0),
	Position = UDim2.new(0, 0, 0.5, 0),
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 0.6,
	BorderSizePixel = 3,
	BorderColor3 = Color3.fromRGB(240, 165, 0),
	CornerRadius = 20
})

local handLabel = createLabel("HandLabel", playerHand, {
	Size = UDim2.new(1, 0, 0.15, 0),
	Position = UDim2.new(0, 0, 0.05, 0),
	Text = "YOUR HAND",
	TextSize = 20,
	TextColor3 = Color3.fromRGB(240, 165, 0),
	BackgroundTransparency = 1,
	NoCorner = true
})

local cardsFrame = createFrame("CardsFrame", playerHand, {
	Size = UDim2.new(0.8, 0, 0.7, 0),
	Position = UDim2.new(0.1, 0, 0.25, 0),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	CornerRadius = 0
})

-- Sand Card (with image support)
local sandCard = Instance.new("ImageButton")
sandCard.Name = "SandCard"
sandCard.Size = UDim2.new(0.45, 0, 1, 0)
sandCard.Position = UDim2.new(0.05, 0, 0, 0)
sandCard.BackgroundColor3 = Color3.fromRGB(255, 200, 80)
sandCard.BorderSizePixel = 4
sandCard.BorderColor3 = Color3.fromRGB(212, 175, 55)
sandCard.ScaleType = Enum.ScaleType.Fit
sandCard.Image = ""
sandCard.Parent = cardsFrame

local sandCorner = Instance.new("UICorner")
sandCorner.CornerRadius = UDim.new(0, 12)
sandCorner.Parent = sandCard

local sandValue = createLabel("Value", sandCard, {
	Size = UDim2.new(1, 0, 0.5, 0),
	Position = UDim2.new(0, 0, 0.25, 0),
	Text = "?",
	TextSize = 56,
	TextColor3 = Color3.fromRGB(26, 26, 46),
	BackgroundTransparency = 1,
	NoCorner = true
})

local sandDeckLabel = createLabel("DeckLabel", sandCard, {
	Size = UDim2.new(1, 0, 0.15, 0),
	Position = UDim2.new(0, 0, 0.05, 0),
	Text = "SAND",
	TextSize = 16,
	TextColor3 = Color3.fromRGB(26, 26, 46),
	BackgroundTransparency = 1,
	NoCorner = true
})

-- Blood Card (with image support)
local bloodCard = Instance.new("ImageButton")
bloodCard.Name = "BloodCard"
bloodCard.Size = UDim2.new(0.45, 0, 1, 0)
bloodCard.Position = UDim2.new(0.5, 0, 0, 0)
bloodCard.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
bloodCard.BorderSizePixel = 4
bloodCard.BorderColor3 = Color3.fromRGB(102, 0, 0)
bloodCard.ScaleType = Enum.ScaleType.Fit
bloodCard.Image = ""
bloodCard.Parent = cardsFrame

local bloodCorner = Instance.new("UICorner")
bloodCorner.CornerRadius = UDim.new(0, 12)
bloodCorner.Parent = bloodCard

local bloodValue = createLabel("Value", bloodCard, {
	Size = UDim2.new(1, 0, 0.5, 0),
	Position = UDim2.new(0, 0, 0.25, 0),
	Text = "?",
	TextSize = 56,
	TextColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 1,
	NoCorner = true
})

local bloodDeckLabel = createLabel("DeckLabel", bloodCard, {
	Size = UDim2.new(1, 0, 0.15, 0),
	Position = UDim2.new(0, 0, 0.05, 0),
	Text = "BLOOD",
	TextSize = 16,
	TextColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 1,
	NoCorner = true
})

-- Right Section (continues in next part...)
local rightSection = createFrame("RightSection", playArea, {
	Size = UDim2.new(0.3, 0, 1, 0),
	Position = UDim2.new(0.7, 0, 0, 0),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	CornerRadius = 0
})

local roundInfo = createFrame("RoundInfo", rightSection, {
	Size = UDim2.new(1, 0, 0.12, 0),
	Position = UDim2.new(0, 0, 0, 0),
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 0.5,
	BorderSizePixel = 0,
	CornerRadius = 10
})

local roundText = createLabel("RoundText", roundInfo, {
	Size = UDim2.new(1, 0, 0.4, 0),
	Position = UDim2.new(0, 0, 0.1, 0),
	Text = "Turn",
	TextSize = 14,
	BackgroundTransparency = 1,
	NoCorner = true
})

local roundNumber = createLabel("RoundNumber", roundInfo, {
	Size = UDim2.new(1, 0, 0.5, 0),
	Position = UDim2.new(0, 0, 0.45, 0),
	Text = "1 / 3",
	TextSize = 28,
	TextColor3 = Color3.fromRGB(240, 165, 0),
	BackgroundTransparency = 1,
	NoCorner = true
})

local discardSection = createFrame("DiscardSection", rightSection, {
	Size = UDim2.new(1, 0, 0.25, 0),
	Position = UDim2.new(0, 0, 0.15, 0),
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 0.6,
	BorderSizePixel = 2,
	BorderColor3 = Color3.fromRGB(240, 165, 0),
	CornerRadius = 20
})

local discardTitle = createLabel("Title", discardSection, {
	Size = UDim2.new(1, 0, 0.2, 0),
	Position = UDim2.new(0, 0, 0.05, 0),
	Text = "DISCARD PILES",
	TextSize = 14,
	TextColor3 = Color3.fromRGB(240, 165, 0),
	BackgroundTransparency = 1,
	NoCorner = true
})

local sandDiscard = createButton("SandDiscard", discardSection, {
	Size = UDim2.new(0.45, 0, 0.6, 0),
	Position = UDim2.new(0.05, 0, 0.3, 0),
	BackgroundColor3 = Color3.fromRGB(200, 160, 60),
	BorderColor3 = Color3.fromRGB(212, 175, 55),
	Text = "",
	TextSize = 14,
	CornerRadius = 10
})

local sandDiscardValue = createLabel("Value", sandDiscard, {
	Size = UDim2.new(1, 0, 0.5, 0),
	Position = UDim2.new(0, 0, 0.15, 0),
	Text = "Empty",
	TextSize = 24,
	TextColor3 = Color3.fromRGB(26, 26, 46),
	BackgroundTransparency = 1,
	NoCorner = true
})

local sandDiscardLabel = createLabel("Label", sandDiscard, {
	Size = UDim2.new(1, 0, 0.25, 0),
	Position = UDim2.new(0, 0, 0.7, 0),
	Text = "SAND",
	TextSize = 12,
	TextColor3 = Color3.fromRGB(26, 26, 46),
	BackgroundTransparency = 1,
	NoCorner = true
})

local bloodDiscard = createButton("BloodDiscard", discardSection, {
	Size = UDim2.new(0.45, 0, 0.6, 0),
	Position = UDim2.new(0.5, 0, 0.3, 0),
	BackgroundColor3 = Color3.fromRGB(150, 40, 40),
	BorderColor3 = Color3.fromRGB(102, 0, 0),
	Text = "",
	TextSize = 14,
	CornerRadius = 10
})

local bloodDiscardValue = createLabel("Value", bloodDiscard, {
	Size = UDim2.new(1, 0, 0.5, 0),
	Position = UDim2.new(0, 0, 0.15, 0),
	Text = "Empty",
	TextSize = 24,
	TextColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 1,
	NoCorner = true
})

local bloodDiscardLabel = createLabel("Label", bloodDiscard, {
	Size = UDim2.new(1, 0, 0.25, 0),
	Position = UDim2.new(0, 0, 0.7, 0),
	Text = "BLOOD",
	TextSize = 12,
	TextColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 1,
	NoCorner = true
})

local actionsFrame = createFrame("Actions", rightSection, {
	Size = UDim2.new(1, 0, 0.55, 0),
	Position = UDim2.new(0, 0, 0.43, 0),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	CornerRadius = 0
})

local drawSandBtn = createButton("DrawSandBtn", actionsFrame, {
	Size = UDim2.new(1, 0, 0.22, 0),
	Position = UDim2.new(0, 0, 0, 0),
	BackgroundColor3 = Color3.fromRGB(255, 180, 50),
	BorderColor3 = Color3.fromRGB(212, 175, 55),
	Text = "?? DRAW SAND",
	TextSize = 18,
	CornerRadius = 15
})

local drawBloodBtn = createButton("DrawBloodBtn", actionsFrame, {
	Size = UDim2.new(1, 0, 0.22, 0),
	Position = UDim2.new(0, 0, 0.26, 0),
	BackgroundColor3 = Color3.fromRGB(180, 40, 40),
	BorderColor3 = Color3.fromRGB(102, 0, 0),
	Text = "?? DRAW BLOOD",
	TextSize = 18,
	CornerRadius = 15
})

local standBtn = createButton("StandBtn", actionsFrame, {
	Size = UDim2.new(1, 0, 0.22, 0),
	Position = UDim2.new(0, 0, 0.52, 0),
	BackgroundColor3 = Color3.fromRGB(149, 165, 166),
	BorderColor3 = Color3.fromRGB(90, 98, 104),
	Text = "? STAND",
	TextSize = 18,
	CornerRadius = 15
})

local tokenBtn = createButton("TokenBtn", actionsFrame, {
	Size = UDim2.new(1, 0, 0.22, 0),
	Position = UDim2.new(0, 0, 0.78, 0),
	BackgroundColor3 = Color3.fromRGB(155, 89, 182),
	BorderColor3 = Color3.fromRGB(108, 52, 131),
	Text = "? TOKEN",
	TextSize = 18,
	BackgroundTransparency = 0.5,
	CornerRadius = 15
})

-- Results Popup
local resultsPopup = createFrame("ResultsPopup", screenGui, {
	Size = UDim2.new(0, 500, 0, 400),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 0.2,
	BorderSizePixel = 5,
	BorderColor3 = Color3.fromRGB(255, 200, 50),
	Visible = false,
	ZIndex = 10,
	CornerRadius = 25
})

local resultsIcon = createLabel("Icon", resultsPopup, {
	Size = UDim2.new(1, 0, 0.3, 0),
	Position = UDim2.new(0, 0, 0.05, 0),
	Text = "??",
	TextSize = 80,
	BackgroundTransparency = 1,
	NoCorner = true
})

local resultsTitle = createLabel("Title", resultsPopup, {
	Size = UDim2.new(1, 0, 0.2, 0),
	Position = UDim2.new(0, 0, 0.35, 0),
	Text = "YOU WON!",
	TextSize = 42,
	TextColor3 = Color3.fromRGB(240, 165, 0),
	BackgroundTransparency = 1,
	NoCorner = true
})

local resultsText = createLabel("Text", resultsPopup, {
	Size = UDim2.new(0.9, 0, 0.3, 0),
	Position = UDim2.new(0.05, 0, 0.6, 0),
	Text = "",
	TextSize = 20,
	BackgroundTransparency = 1,
	TextWrapped = true,
	NoCorner = true
})

print("? UI Created!")

-- Update Functions
local function updateCardDisplay(card, cardData, valueLabel, deckType)
	if not cardData then
		card.Image = ""
		valueLabel.Visible = true
		valueLabel.Text = "?"
		sandDeckLabel.Visible = true
		bloodDeckLabel.Visible = true
		return
	end

	local cardObj = CardData.Card.Deserialize(cardData)
	local assetId = nil

	if cardObj:IsSylop() then
		assetId = CARD_ASSETS[deckType].Sylop
		if not assetId then
			card.Image = ""
			valueLabel.Visible = true
			valueLabel.Text = "??"
		end
	elseif cardObj:IsImposter() then
		assetId = CARD_ASSETS[deckType].Imposter
		if not assetId then
			card.Image = ""
			valueLabel.Visible = true
			valueLabel.Text = "??"
		end
	else
		assetId = CARD_ASSETS[deckType][cardObj.value]
		if not assetId then
			card.Image = ""
			valueLabel.Visible = true
			valueLabel.Text = tostring(cardObj.value)
		end
	end

	if assetId then
		card.Image = assetId
		valueLabel.Visible = false
		sandDeckLabel.Visible = false
		bloodDeckLabel.Visible = false
	end
end

local function updateDiscardDisplay(button, valueLabel, cardData)
	if not cardData then
		valueLabel.Text = "Empty"
		return
	end

	local cardObj = CardData.Card.Deserialize(cardData)

	if cardObj:IsSylop() then
		valueLabel.Text = "Sylop"
	elseif cardObj:IsImposter() then
		valueLabel.Text = "Imp."
	else
		valueLabel.Text = tostring(cardObj.value)
	end
end

local function updateUI()
	if not currentGameState or not myPlayerData then return end

	updateCardDisplay(sandCard, myPlayerData.sandCard, sandValue, "Sand")
	updateCardDisplay(bloodCard, myPlayerData.bloodCard, bloodValue, "Blood")

	if myPlayerData.chips then
		chipCount.Text = tostring(myPlayerData.chips)
	end

	local isMyTurn = currentGameState.currentPlayer == player
	if isMyTurn then
		turnLabel.Text = "?? YOUR TURN!"
		turnIndicator.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
		turnIndicator.BorderColor3 = Color3.fromRGB(30, 132, 73)
	else
		if currentGameState.currentPlayer then
			turnLabel.Text = "? " .. currentGameState.currentPlayer.Name .. "'s Turn"
		else
			turnLabel.Text = "? Waiting..."
		end
		turnIndicator.BackgroundColor3 = Color3.fromRGB(149, 165, 166)
		turnIndicator.BorderColor3 = Color3.fromRGB(90, 98, 104)
	end

	if currentGameState.currentTurn then
		roundNumber.Text = tostring(currentGameState.currentTurn) .. " / 3"
	end

	local canAct = isMyTurn and not myPlayerData.hasStood
	drawSandBtn.Active = canAct
	drawBloodBtn.Active = canAct
	standBtn.Active = canAct

	drawSandBtn.BackgroundTransparency = canAct and 0 or 0.5
	drawBloodBtn.BackgroundTransparency = canAct and 0 or 0.5
	standBtn.BackgroundTransparency = canAct and 0 or 0.5

	updateDiscardDisplay(sandDiscard, sandDiscardValue, currentGameState.sandDiscardTop)
	updateDiscardDisplay(bloodDiscard, bloodDiscardValue, currentGameState.bloodDiscardTop)
end

-- Button Handlers
drawSandBtn.MouseButton1Click:Connect(function()
	if not drawSandBtn.Active then return end
	if not currentGameState or currentGameState.currentPlayer ~= player then return end
	DrawCardEvent:FireServer("Sand", false)
end)

drawBloodBtn.MouseButton1Click:Connect(function()
	if not drawBloodBtn.Active then return end
	if not currentGameState or currentGameState.currentPlayer ~= player then return end
	DrawCardEvent:FireServer("Blood", false)
end)

standBtn.MouseButton1Click:Connect(function()
	if not standBtn.Active then return end
	if not currentGameState or currentGameState.currentPlayer ~= player then return end
	StandActionEvent:FireServer()
end)

sandDiscard.MouseButton1Click:Connect(function()
	if not drawSandBtn.Active then return end
	if not currentGameState or currentGameState.currentPlayer ~= player then return end
	DrawCardEvent:FireServer("Sand", true)
end)

bloodDiscard.MouseButton1Click:Connect(function()
	if not drawBloodBtn.Active then return end
	if not currentGameState or currentGameState.currentPlayer ~= player then return end
	DrawCardEvent:FireServer("Blood", true)
end)

-- Game State Updates
UpdateGameStateEvent.OnClientEvent:Connect(function(gameState)
	if gameState.type == "roundEnd" then
		resultsPopup.Visible = true

		if gameState.results.isTie then
			resultsIcon.Text = "??"
			resultsTitle.Text = "TIE!"
		elseif gameState.results.winner == player then
			resultsIcon.Text = "??"
			resultsTitle.Text = "YOU WON!"
		else
			resultsIcon.Text = "??"
			resultsTitle.Text = "YOU LOST"
		end

		local myEval = gameState.results.evaluations[player]
		if myEval then
			resultsText.Text = myEval.displayText
		end

		wait(5)
		resultsPopup.Visible = false
	else
		currentGameState = gameState
		myPlayerData = gameState.myData
		updateUI()
	end
end)

-- Seat Detection
spawn(function()
	while true do
		wait(0.5)

		local character = player.Character
		if character then
			local humanoid = character:FindFirstChild("Humanoid")
			if humanoid and humanoid.Sit then
				local seat = humanoid.SeatPart
				if seat and seat.Parent and seat.Parent.Name == "SabaccTable" then
					if not isSittingAtTable then
						isSittingAtTable = true
						mainFrame.Visible = true
						print("?? Sat at table - UI shown!")
					end
				else
					if isSittingAtTable then
						isSittingAtTable = false
						mainFrame.Visible = false
						print("?? Left table - UI hidden!")
					end
				end
			else
				if isSittingAtTable then
					isSittingAtTable = false
					mainFrame.Visible = false
				end
			end
		end
	end
end)

print("? Professional Sabacc UI Ready! ???")