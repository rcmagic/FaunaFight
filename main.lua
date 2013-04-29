lick = require "lick"
lick.reset = true
lick.debug = true
totalTicks = 0
gameTicks = 0
FRAME_RATE = 60
Camera = { x = 640, y = 0}
DEBUG = false
ROUNDSTOWIN = 5
playerStats = 
{
	{wins = 0, rounds = 0},
	{wins = 0, rounds = 0}
}
-- Stores references to all objects
EntityRefs = {}
Entity = {}
function Entity:New(entity)
    entity = entity or {}
    setmetatable(entity, self)
    self.__index = self
    table.insert(EntityRefs, object)
    entity.index = # EntityRefs
    self.name = "Entity"
    return entity
end

Player = Entity:New()
function Player:New()
	object = Entity:New(
	 {
	 	AnimEnd = false,
	 	YCrossed = false,
	    character = nil,
	    enemy = nil,
		pos = {x = 0, y = 0},
		vel = {x = 0, y = 0},
		acc = {x = 0, y = 0},
		config = {a = nil, b = nil},
		inputs = {a = false, b = false},
		inputsDown = {},

		isHit = false,
		hitType = "",
		move = nil,
		frame = 0,
		ticks = 0,
		inputEnabled = true,
		number = 1
	})
	return object
end

Mallard = {
	name = "Mallard",
	imageAssets = {"idle", "throw", "thrown", "throw_react", "ko", "walk01", "walk02", "icon", "name"},
	cachedImages = {},
	moves = { 
		idle = {
			name = "idle",
			loop = true,
			flip = false,
			length = 8,
			images = {
				{ "idle", 0, 8, -208, 360 },
			},
			active = {},
			passive = {{-100, 200, 100, 0, 0, 8}},
			enter = function(player) end,
			leave = function(player)
				player.vel.x = 0
				if player.flip then
					if player.inputs.a then player.vel.x = 10
					elseif player.inputs.b then player.vel.x = -8 end
				else 
					if player.inputs.a then player.vel.x = -8
					elseif player.inputs.b then player.vel.x = 10 end
				end
				-- We only adjust the side the player facing during idle state
				if (player.pos.x > player.enemy.pos.x) ~= player.flip then
					player.flip = not player.flip
					-- When characters cross, flip the relative x velocity
					player.vel.x = -player.vel.x
				end
				if player.isHit then
					player.vel.x = 0
					if player.hitType == "throw" then 
						return "thrown" 
					end
					--return "hit"
				end
				-- Activate the throw when the c button is pressed
				if player.inputsDown["c"] then
					player.vel.x = 0

					return "throw"
				end
				if player.vel.x ~= 0 then return "walk" end
			end
		},
		walk = {
			name = "walk",
			loop = true,
			flip = false,
			length = 30,
			images = {
				{ "walk01", 0, 15, -208, 360 },
				{ "walk02", 15, 30, -208, 322 },
			},
			active = {},
			passive = {{-100, 200, 100, 0, 0, 8}},
			enter = function(player) end,
			leave = function(player)
				player.vel.x = 0
				if player.flip then
					if player.inputs.a then player.vel.x = 10
					elseif player.inputs.b then player.vel.x = -8 end
				else 
					if player.inputs.a then player.vel.x = -8
					elseif player.inputs.b then player.vel.x = 10 end
				end
				-- We only adjust the side the player facing during idle state
				if (player.pos.x > player.enemy.pos.x) ~= player.flip then
					player.flip = not player.flip
					-- When characters cross, flip the relative x velocity
					player.vel.x = -player.vel.x
				end
				if player.isHit then
					player.vel.x = 0
					if player.hitType == "throw" then 
						return "thrown" 
					end
					--return "hit"
				end
				-- Activate the throw when the c button is pressed
				if player.inputsDown["c"] then
					player.vel.x = 0

					return "throw"
				end
				if player.vel.x == 0 then return "idle" end


			end
		},
		hit = {
			name = "hit",
			length = 30,
			images = {
				{ "hit", 0, 30, -256, 512}
			},
			active = {},
			passive = {},
			enter = function(player) end,
			leave = function(player)
				if player.AnimEnd then
					return "idle"
				end
			end
		},
		thrown = {
			name = "thrown",
			length = 8,
			loop = true,
			images = {
				{ "thrown", 0, 8, -256, 512}
			},
			active = {},
			passive = {},
			enter = function(player) end,
			leave = function(player) end
		},
		ko = {
			name = "ko",
			length = 8,
			loop = true,
			images = {
				{ "ko", 0, 8, -256, 300}
			},
			active = {},
			passive = {},
			enter = function(player) 
				player.vel.y = 20
				player.acc.y = -2
				player.vel.x = -10
			end,
			leave = function(player) 
				if player.enemy.stats.rounds == 5 then
					ShowWin = true
				else 
					ShowKO = true
				end
				PlayerWhoWon = player.enemy.number
				if player.ticks > 200 then
					reset()
				end
				if player.YCrossed then
					player.vel.x = 0
				end
			end
		},
		throw = {
			type = "throw",
			name = "throw",
			loop = false,
			length = 30,
			images = {
				{ "throw", 0, 30, -182, 332 },
			},
			active = {{150, 300, 200, 100, 4, 8}},
			passive = {{-150, 200, 160, 0, 0, 30}},
			enter = function(player) end,
			leave = function(player)
				if player.isHit then
					return "thrown"
				end
				if player.hitEnemy then
					return "throw_react"
				end
				if player.AnimEnd then return "idle" end
			end
		},
		throw_react = {
			name = "throw_react",
			loop = false,
			length = 3000,
			images = {
				{ "throw_react", 0, 3000, -256, 512 },
			},
			passive = {},
			active = {},
			enter = function(player) 
				player.vel.y = 60
				player.acc.y = -2
				player.inputEnabled = false
				player.enemy.inputEnabled = false
			end,

			leave = function(player)
				player.enemy.pos.y = player.pos.y+20
				if player.flip then
					player.enemy.pos.x = player.pos.x-60
				else 
					player.enemy.pos.x = player.pos.x+60
				end
				if player.YCrossed then
					player.stats.rounds = player.stats.rounds+1
					player.vel.y = 0
					player.acc.y = 0
					SetMove(player.enemy, "ko")
					return "idle"
				end
			end
		},

	}
}

ImageAssets = { "idle", "throw"}
SCREEN_WIDTH = 1280
SCREEN_HEIGHT = 720
test_box = {600, 400, 680, 0}
love.graphics.setMode(SCREEN_WIDTH, SCREEN_HEIGHT)
GROUND_HEIGHT = 50
function love.load()
	-- Load Character Image Assets
	for i,v in ipairs(Mallard.imageAssets) do 
		Mallard.cachedImages[v] = love.graphics.newImage("characters/" .. Mallard.name .. "/" .. v .. ".png")
	end
	stage = love.graphics.newImage("stage.png")
	player1WinImage = love.graphics.newImage("p1win.png")
	player2WinImage = love.graphics.newImage("p2win.png")
	winsImage = love.graphics.newImage("wins.png")
	koImage = love.graphics.newImage("ko.png")


	reset()
	love.graphics.setNewFont(30)
end
ShowKO = false
function reset()
	ShowWin = false
	ShowKO = false
	if players and players[1].stats.rounds == 5 then
		players[1].stats.wins = players[1].stats.wins + 1
		players[1].stats.rounds = 0
		players[2].stats.rounds = 0
	end
	if players and players[2].stats.rounds == 5 then
		players[2].stats.wins = players[1].stats.wins + 1
		players[1].stats.rounds = 0
		players[2].stats.rounds = 0
	end
	players = {Player:New(), Player:New()}

	players[1].character = Mallard
	players[2].character = Mallard
	players[1].pos.x = -400
	players[2].pos.x = 400
	players[1].enemy = players[2]
	players[2].enemy = players[1]

	-- Assign player input configuration
	players[1].config = { a = "a", b = "s", c = "d"}
	players[2].config = { a = "o", b = "p", c = "["}
	for i,player in ipairs(players) do
		player.move = player.character.moves.idle
		player.stats = playerStats[i]
		player.number = i
	end
end
pressed = false
function love.draw()

	love.graphics.push()
	love.graphics.translate(SCREEN_WIDTH/2-Camera.x, Camera.y)

	-- Draw Players
	love.graphics.push()
	love.graphics.draw(stage, -1300, -340)
	love.graphics.translate(0, -GROUND_HEIGHT)

	for i,player in ipairs(players) do
		DrawPlayer(player)
		if DEBUG then
			DrawBoxes(player)
		end
	end
	love.graphics.pop()
	-- End Draw Players

	if DEBUG then
		-- Draw Center line for testing
		love.graphics.rectangle("line", -10, 0, 20, SCREEN_HEIGHT)

		-- DRAW GROUND
		love.graphics.rectangle("line", -1500, SCREEN_HEIGHT-GROUND_HEIGHT, 3000, GROUND_HEIGHT)

	end
	love.graphics.pop()
	DrawHud()
end
PlayerWhoWon = 1
ShowWin = false
function DrawWin()
	if PlayerWhoWon == 1 then
		love.graphics.draw(player1WinImage, 240, 100)
	else
		love.graphics.draw(player2WinImage, 240, 100)
	end
		love.graphics.draw(winsImage, 340, 320)
end

function DrawHud()
	love.graphics.print("WINS: " .. players[1].stats.wins, 150, 5)
	love.graphics.print("WINS: " .. players[2].stats.wins, 1000, 5)

	love.graphics.push()
	love.graphics.translate(0, 40)
	love.graphics.draw(players[1].character.cachedImages.name)
	love.graphics.draw(players[2].character.cachedImages.name, 850)

	for i = 0, players[1].stats.rounds-1 do
		love.graphics.draw(players[1].character.cachedImages.icon, i*80, 60)
	end
	for i = 0, players[2].stats.rounds-1 do
		love.graphics.draw(players[1].character.cachedImages.icon, 1150-i*80, 60)
	end
	love.graphics.pop()
	if DEBUG then
		love.graphics.print("Ticks:" .. gameTicks, 0, 0)
		for i,player in ipairs(players) do
			local hit = "No"
			if player.isHit then hit = "Yes" end
			love.graphics.print("Pos(" .. i .. "): [" .. player.pos.x .. ", " .. player.pos.y .."]   Hit: " .. hit .. " Move: " .. player.move.name .. "[" .. player.frame .. "]  Wins: " .. playerStats[i].wins, 0, i*40)
		end
	end

	if ShowKO then
		love.graphics.draw(koImage,480, 240)
	end
	if ShowWin then
		DrawWin()
	end
end

function love.update(dt)
	-- Fixed time step updates.  We detect collisions and update physics at FRAME_RATE frames per second
	totalTicks = dt*FRAME_RATE + totalTicks
	if totalTicks >= 1  then
		pressed = false
		totalTicks = totalTicks - 1
		gameTicks = gameTicks + 1
		UpdatePhysics()
		CheckCollisions()

		for i, player in ipairs(players) do
			-- Reset events that only last one frame
			player.AnimEnd = false
			player.YCrossed = false
			-- if player.inputs.a then player.pos.x = player.pos.x - 20 end
			-- if player.inputs.b then player.pos.x = player.pos.x + 20 end
			player.frame = player.frame + 1
			player.ticks = player.ticks + 1

			if player.frame == player.move.length then
				if player.move.loop then
					player.frame = 0
				else 
					player.AnimEnd = true
				end
			end

			-- Trigger YCrossed when the player crossed the y axis
			if player.vel.y < 0 and player.pos.y <= 0 then
				player.vel.y = 0
				player.pos.y = 0
				player.YCrossed = true
			end

			-- Check transition function
			local next = player.move.leave(player)
			if next then
				player.move = player.character.moves[next]
				player.frame = 0
				player.ticks = 0
				-- Run state entry function
				player.move.enter(player)
			end

			for key, value in pairs(player.inputs) do
				player.inputsDown[key] = false

			end
	
		end

		-- Center the Camera
		Camera.x = (players[1].pos.x + players[2].pos.x) / 2
		Camera.y = (players[1].pos.y + players[2].pos.y) / 6
		if Camera.x < -WALL+SCREEN_WIDTH/2 then
			Camera.x = -WALL+SCREEN_WIDTH/2
		end
		if Camera.x > WALL-SCREEN_WIDTH/2 then
			Camera.x = WALL-SCREEN_WIDTH/2
		end

	end
end

function SetMove(player, move)
	player.frame = 0
	player.ticks = 0
	player.move = player.character.moves[move]
	player.move.enter(player)
end


function love.keypressed(key)
	if key == "w" then pressed = true end
	for i, player in ipairs(players) do
		if player.inputEnabled then
			for input, value in pairs(player.config) do
				if value == key then 
					player.inputs[input] = true 
					player.inputsDown[input] = true 
				end
			end
		end
	end
	if key == "2" then FRAME_RATE = 30 
	elseif key == "1" then FRAME_RATE = 60 
	elseif key == "3" then DEBUG = not DEBUG
	elseif key == "escape" then love.event.quit() end

end

function love.keyreleased(key)
	for i, player in ipairs(players) do
		for input, value in pairs(player.config) do
			if value == key then player.inputs[input] = false end
		end
	end
end

function BoxesCollide(a, b)
	return not ( a[1] > b[3] or b[1] > a[3] or a[4] > b[2] or b[4] > a[2] )
end

function TranslateBox(x, y, box, flip)
	if flip then
		return {x-box[3], y+box[2], x-box[1], y+box[4]}
	end
	return {x+box[1], y+box[2], x+box[3], y+box[4]}
end

function BoxToScreen(box) 
	return {box[1], SCREEN_HEIGHT-box[2], box[3], SCREEN_HEIGHT-box[4]}
end



function PrintBox(box, x, y )
	love.graphics.print("Box: [" .. box[1] .. "," .. box[2] .. "," .. box[3] .. "," .. box[4] .."]", x, y)		
end

function CheckCollisions()
	for i, player in ipairs(players) do
		-- Reset Events
		player.isHit = false
		player.hitEnemy = false
	end

	for i, player in ipairs(players) do
		for j,box in ipairs(player.move.passive) do
			for k, player2 in ipairs(players) do
				if i ~= k then
					for l, box2 in ipairs(player2.move.active) do
						if box[5] <= player.frame and box[6] > player.frame and box2[5] <= player2.frame and box2[6] > player2.frame and
							BoxesCollide(TranslateBox(player.pos.x, player.pos.y, box, player.flip), TranslateBox(player2.pos.x, player2.pos.y, box2, player2.flip)) then
							player.isHit = true
							player2.hitEnemy = true
							player2.enemy = player
							player.hitType = player2.move.type or ""
						end
					end
				end
			end
		end
	end

	if players[1].isHit and players[2].isHit then
		players[1].isHit = false
		players[1].hitEnemy = false
		players[2].isHit = false
		players[2].hitEnemy = false
	end
end

WALL = 1300
-- Integrates physics properties
function UpdatePhysics()
	for i, player in ipairs(players) do
		player.pos.y = player.vel.y + player.pos.y
		player.vel.y = player.acc.y + player.vel.y

		if player.flip then
			player.pos.x =  player.pos.x - player.vel.x
			player.vel.x = player.vel.x - player.acc.x
		else 
			player.pos.x = player.vel.x + player.pos.x
			player.vel.x = player.acc.x + player.vel.x	
		end	

		if player.pos.x < -WALL then
			player.pos.x = -WALL
		end
		if player.pos.x > WALL then
			player.pos.x = WALL
		end
		local left_wall = player.enemy.pos.x - 1200
		local right_wall = player.enemy.pos.x + 1200
		if player.pos.x < left_wall then
			player.pos.x = left_wall
		end
		if player.pos.x > right_wall then
			player.pos.x = right_wall
		end
	end
end

function DrawBox(box)
	local draw_box = BoxToScreen(box)
	love.graphics.rectangle("line", draw_box[1], draw_box[2], draw_box[3]-draw_box[1], draw_box[4]-draw_box[2])
end

function DrawBoxes(player)
	love.graphics.setColor(0, 0, 255)
	for i,box in ipairs(player.move.passive) do
		if box[5] <= player.frame and box[6] > player.frame then
			DrawBox(TranslateBox(player.pos.x, player.pos.y, box, player.flip))
		end
	end

	love.graphics.setColor(255, 0, 0)
	for i,box in ipairs(player.move.active) do
		if box[5] <= player.frame and box[6] > player.frame then		
			DrawBox(TranslateBox(player.pos.x, player.pos.y, box, player.flip))
		end			
	end
	love.graphics.setColor(255, 255, 255)
end

function DrawPlayer(player)
	local character = player.character
	for i, image in ipairs(player.move.images) do
		-- If the image is set to showup on the current frame
		if image[2] <= player.frame and image[3] > player.frame then
			local sx = 1
			local x_off = image[4]
			if player.flip then
				sx = -1
				x_off = -x_off
			end
 			love.graphics.draw(player.character.cachedImages[image[1]], player.pos.x+x_off, SCREEN_HEIGHT-player.pos.y-image[5], 0, sx, 1)
 		end
 	end
end