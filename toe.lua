-- Author: SentyFunBall
-- GitHub: https://github.com/SentyFunBall
-- Workshop: 

--Code by STCorp. Do not reuse.--
--- Developed using LifeBoatAPI - Stormworks Lua plugin for VSCode - https://code.visualstudio.com/download (search "Stormworks Lua with LifeboatAPI" extension)
--- If you have any issues, please report them here: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension/issues - by Nameous Changey


--[====[ HOTKEYS ]====]
-- Press F6 to simulate this file
-- Press F7 to build the project, copy the output from /_build/out/ into the game to use
-- Remember to set your Author name etc. in the settings: CTRL+COMMA


--[====[ EDITABLE SIMULATOR CONFIG - *automatically removed from the F7 build output ]====]
---@section __LB_SIMULATOR_ONLY__
do
    ---@type Simulator -- Set properties and screen sizes here - will run once when the script is loaded
    simulator = simulator
    simulator:setScreen(1, "2x2")
    simulator:setScreen(2, "2x2")
    simulator:setProperty("ExampleNumberProperty", 123)

    -- Runs every tick just before onTick; allows you to simulate the inputs changing
    ---@param simulator Simulator Use simulator:<function>() to set inputs etc.
    ---@param ticks     number Number of ticks since simulator started
    function onLBSimulatorTick(simulator, ticks)

        -- touchscreen defaults
        local screenConnection = simulator:getTouchScreen(1)
        local screenConnection2 = simulator:getTouchScreen(2)
        simulator:setInputBool(1, screenConnection2.isTouched)
        simulator:setInputBool(2, screenConnection.isTouched)
        simulator:setInputNumber(1, screenConnection.touchX)
        simulator:setInputNumber(2, screenConnection.touchY)
        simulator:setInputNumber(3, screenConnection2.touchX)
        simulator:setInputNumber(4, screenConnection2.touchY)

        -- NEW! button/slider options from the UI
        simulator:setInputBool(31, simulator:getIsClicked(1))       -- if button 1 is clicked, provide an ON pulse for input.getBool(31)
        simulator:setInputNumber(31, simulator:getSlider(1))        -- set input 31 to the value of slider 1

        simulator:setInputBool(32, simulator:getIsToggled(2))       -- make button 2 a toggle, for input.getBool(32)
        simulator:setInputNumber(32, simulator:getSlider(2) * 50)   -- set input 32 to the value from slider 2 * 50
    end;
end
---@endsection


--[====[ IN-GAME CODE ]====]

-- try require("Folder.Filename") to include code from another file in this, so you can store code in libraries
-- the "LifeBoatAPI" is included by default in /_build/libs/ - you can use require("LifeBoatAPI") to get this, and use all the LifeBoatAPI.<functions>!

-- Constants
local COLOR_X = {65, 67, 125}     -- Blue for X
local COLOR_O = {163, 96, 75}     -- Red for O  
local COLOR_WHITE = {200, 200, 200} -- White text
local COLOR_GREEN = {0, 255, 0}   -- Green for sync

local screenNum = 0 -- 0 = L, 1 = R
local s = screen
local turn = { false, false } -- for each board. false = X, true = O
local canMp = false
local down = false
local down2 = false
local isMp = false

local states = { 1, 1 } -- for each board. 0 = reset 1 = playing SP 2 = waiting for MP 3 = is my MP turn 4 = waiting on other player 5 = game over

local mapL = { -- 0 = empty, 1 = X, 2 = O
	{ 0, 0, 0 },
	{ 0, 0, 0 },
	{ 0, 0, 0 }
}

local mapR = {
	{ 0, 0, 0 },
	{ 0, 0, 0 },
	{ 0, 0, 0 }
}

-- Helper functions
local function clearBoard(board)
    for i = 1, 3 do
        for j = 1, 3 do
            board[i][j] = 0
        end
    end
end

local function drawGameResult(winner, x, y, w, h)
    if winner == 1 then
        c(COLOR_X)
        s.drawTextBox(x, y, w, h, "X won!", 0, 0)
    elseif winner == 2 then
        c(COLOR_O)
        s.drawTextBox(x, y, w, h, "O won!", 0, 0)
    else
        c(COLOR_WHITE)
        s.drawTextBox(x, y, w, h, "Draw!", 0, 0)
    end
end

local function drawTurnIndicator(isOTurn, x, y, w, h)
    if isOTurn then
        c(COLOR_O)
    else
        c(COLOR_X)
    end
    s.drawTextBox(x, y, w, h, (isOTurn and "O" or "X") .. "'s turn!", 0, 0)
end

function onTick()
	if screenNum == 2 then
		canMp = true
	else
		canMp = false
	end
	
	screenNum = 0
	
    if states[1] == 0 then -- reset L
        states[1] = 1
        clearBoard(mapL)
    end
    if states[2] == 0 then --reset R
        states[2] = 1
        clearBoard(mapR)
    end
    
    if not isMp and (states[1] == 3 or states[3] == 4 or states[2] == 3 or states[2] == 4) then
        turn[1] = false
        turn[2] = false

        states[1], states[2] = 0, 0
    end
	
	pressR = input.getBool(1) and not down
	down = input.getBool(1)
	pressL = input.getBool(2) and not down2
	down2 = input.getBool(2)
	
	pxR = input.getNumber(3)
	pyR = input.getNumber(4)
	
	pxL = input.getNumber(1)
	pyL = input.getNumber(2)
	
    if states[1] == 1 and turn[1] then
        aiMakeMove(mapL)
        turn[1] = not turn[1]
        if checkWinner(mapL) > 0 or isFull(mapL) then states[1] = 5 end
    end
    
    if states[2] == 1 and turn[2] then
        aiMakeMove(mapR)
        turn[2] = not turn[2]
        if checkWinner(mapR) > 0 or isFull(mapR) then states[2] = 5 end
    end

    if states[1] == 2 and states[2] == 2 then --start mp
        isMp = true
        clearBoard(mapL) -- mp uses left board for both players
        states[1] = 3
        states[2] = 4
    end
	
    if pressL or (pressR and not canMp) then
        if (pressR and not canMp) then
            -- right screen acting as left screen
            pxL = pxR
            pyL = pyR
        end
		if states[1] == 1 or states[1] == 3 then -- play
			local sq = getTouchedSquare(pxL, pyL)
			if sq ~= -1 then
				local y = math.floor(sq / 3) + 1
				local x = (sq % 3 + 1)
				
                if mapL[x][y] == 0 then
                    if states[1] == 3 then --mp
                        states[1] = 4
                        states[2] = 3
                    end
					mapL[x][y] = turn[1] and 2 or 1
					turn[1] = not turn[1]

                    -- Single winner check after move
                    local winner = checkWinner(mapL)
                    if winner > 0 or isFull(mapL) then
                        states[1] = 5
                        if isMp then states[2] = 5 end -- End game for both players in MP mode
                    end
				end
			end
		end
		
		if isPointInRectangle(pxL, pyL, 4, 4, 6, 7) and (states[1] == 1 or states[1] == 5)then --reset button
			if isMp then
				-- Reset MP game for both players but stay in MP mode
				states[1] = 2
				states[2] = 2
			else
				states[1] = 0
			end
		end 
		
		if isPointInRectangle(pxL, pyL, 55, 4, 6, 7) and canMp then --mp button
            states[1] = isMp and 1 or 2
            if states[1] == 1 then
                isMp = false
            end
		end
	end
	
	if pressR and canMp then --canMp also means the second monitor is on
        if states[2] == 1 or states[2] == 3 then -- playing
            local sq = getTouchedSquare(pxR, pyR)
            local board = isMp and mapL or mapR
            local realTurn = isMp and turn[1] or turn[2]
            if sq ~= -1 then
                local y = math.floor(sq / 3) + 1
                local x = (sq % 3 + 1)

                if board[x][y] == 0 then
                    if states[2] == 3 then --mp
                        states[2] = 4
                        states[1] = 3
                        turn[1] = not turn[1]
                    else
                        turn[2] = not turn[2]
                    end
                    board[x][y] = realTurn and 2 or 1
    
                    -- Single winner check after move
                    local winner = checkWinner(board)
                    if winner > 0 or isFull(board) then
                        states[2] = 5
                        if isMp then states[1] = 5 end -- MP mode
                    end
                end
            end
		end

		if isPointInRectangle(pxR, pyR, 4, 4, 6, 7) and (states[2] == 1 or states[2] == 5)then --reset button
			if isMp then
				-- Reset MP game for both players but stay in MP mode
				states[1] = 2
				states[2] = 2
			else
				states[2] = 0
			end
		end 
		
		if isPointInRectangle(pxR, pyR, 55, 4, 6, 7) then --mp button
			states[2] = isMp and 1 or 2

            if states[2] == 1 then
                isMp = false
            end
		end
    end
end

local function drawBoard(board)
    for x = 1, 3 do
        for y = 1, 3 do
            local sq = board[x][y]
            if sq == 1 then
                c(COLOR_X)
                drawX(x * 16 - 8, y * 16 - 9)
            elseif sq == 2 then
                c(COLOR_O)
                drawO(x * 16 - 8, y * 16 - 9)
            end
        end
    end
end

function onDraw()
	-- draw board and buttons regardless of display
	
	c(117, 100, 75)
	s.drawClear()
	
	c(94, 94, 94)
	s.drawRect(2, 2, 60, 60)
	
	s.drawLine(22,7,22,57)
	s.drawLine(39,7,39,57)
	s.drawLine(7,23,56,23)
	s.drawLine(7,39,56,39)
		
	s.drawRectF(4, 4, 6, 7)
	
	if canMp then
		s.drawRectF(55, 4, 6, 7)
	end
	
	c(COLOR_WHITE)
	s.drawText(5, 5, "R")

	if screenNum == 1 then -- First screen (always left in dual mode, or single screen in single mode)
		screenNum = screenNum + 1
		
		-- In single screen mode, show left screen content
		-- In dual screen mode, this is the left screen
		drawBoard(mapL)
		
        if states[1] == 5 then
            drawGameResult(checkWinner(mapL), 0, 4, 64, 6)
        elseif states[1] == 2 then
            c(COLOR_WHITE)
            s.drawTextBox(0, 4, 64, 6, "Waiting for other player", 0, 0)
        else
            drawTurnIndicator(turn[1], 0, 57, 64, 6)
        end
        
        if states[1] == 1 and canMp then
            c(COLOR_WHITE)
            s.drawText(56, 5, "M")
        elseif isMp then
            c(COLOR_GREEN)
            s.drawText(56, 5, "S")
        end
	else -- Second screen (only exists in dual mode)
		screenNum = screenNum + 1

        local board = isMp and mapL or mapR
        local realTurn = isMp and turn[1] or turn[2]
        
        drawBoard(board)
        
        if states[2] == 5 then
            drawGameResult(checkWinner(board), 0, 4, 64, 6)
        elseif states[2] == 2 then
            c(COLOR_WHITE)
            s.drawTextBox(0, 4, 64, 6, "Waiting for other player", 0, 0)
        else
            drawTurnIndicator(realTurn, 0, 57, 64, 6)
        end
		
		if states[2] == 1 and canMp then
            c(COLOR_WHITE)
            s.drawText(56, 5, "M")
        elseif isMp then
            c(COLOR_GREEN)
            s.drawText(56, 5, "S")
        end
	end
end

function c(...)
    local args = {...}
    if type(args[1]) == "table" then
        args = {args[1][1], args[1][2], args[1][3]}
    end

    for i, v in pairs(args) do
        args[i] = v^2.2/255^2.2*v
    end

    screen.setColor(table.unpack(args))
end

function isPointInRectangle(x, y, rectX, rectY, rectW, rectH)
	return x > rectX and y > rectY and x < rectX+rectW and y < rectY+rectH
end

local lines = { --cache for tryComplete
    -- rows
    {{1,1},{1,2},{1,3}},
    {{2,1},{2,2},{2,3}},
    {{3,1},{3,2},{3,3}},
    -- cols
    {{1,1},{2,1},{3,1}},
    {{1,2},{2,2},{3,2}},
    {{1,3},{2,3},{3,3}},
    -- diagonals
    {{1,1},{2,2},{3,3}},
    {{1,3},{2,2},{3,1}},
}

function drawX(x, y)
screen.drawLine(3+x,4+y,12+x,13+y)
screen.drawLine(3+x,12+y,12+x,3+y)
end

function drawO(x, y)
screen.drawCircle(7+x,8+y,5)
end

function getTouchedSquare(x, y)
	x = x - 7
	y = y - 7
	
	if x < 0 or y < 0 then return -1 end
	
	local col = math.floor(x / 16) --x / cellw
	local row = math.floor(y / 16) --y / cellh
	
	if col < 0 or col > 2 or row < 0 or row > 2 then return -1 end
	
	return row * 3 + col
end
	
-- game functions

-- returns 1 if X won, 2 if O won
function checkWinner(board)
    -- rows & cols
    for i = 1, 3 do
        if board[i][1] ~= 0 and board[i][1] == board[i][2] and board[i][2] == board[i][3] then
            return board[i][1]
        end
        if board[1][i] ~= 0 and board[1][i] == board[2][i] and board[2][i] == board[3][i] then
            return board[1][i]
        end
    end

    -- diagonals
    if board[2][2] ~= 0 then
        if board[1][1] == board[2][2] and board[2][2] == board[3][3] then
            return board[2][2]
        end
        if board[1][3] == board[2][2] and board[2][2] == board[3][1] then
            return board[2][2]
        end
    end

    return 0 -- no winner
end

function isFull(board)
    for r = 1, 3 do
        for c = 1, 3 do
            if board[r][c] == 0 then return false end
        end
    end
    return true
end

function tryComplete(target, board) -- target = 2 to win, 1 to block
    for _, line in ipairs(lines) do
        local nT, n0 = 0, 0
        local empty = nil

        for i=1,3 do
            local r,c = line[i][1], line[i][2]
            local v = board[r][c]
            if v == target then 
                nT = nT + 1
            elseif v == 0 then 
				n0 = n0 + 1
				empty = {r,c}
            end
        end

        if nT == 2 and n0 == 1 and empty then
            board[empty[1]][empty[2]] = 2
            return true
        end
    end
    return false
end

function aiMakeMove(board)
    -- 1. Try to win
    if tryComplete(2, board) then return end

    -- 2. Block X
    if tryComplete(1, board) then return end

    -- 3. Take center
    if board[2][2] == 0 then board[2][2] = 2 return end

    -- 4. Corners
    local corners = {{1,1},{1,3},{3,1},{3,3}}
    for _,pos in ipairs(corners) do
        local r,c = pos[1],pos[2]
        if board[r][c] == 0 then board[r][c] = 2 return end
    end

    -- 5. Edges
    local edges = {{1,2},{2,1},{2,3},{3,2}}
    for _,pos in ipairs(edges) do
        local r,c = pos[1],pos[2]
        if board[r][c] == 0 then board[r][c] = 2 return end
    end
end
