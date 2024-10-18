game = {}

shapes = enum{
	"round",
	"square",
	"triangle"
}
objects = enum{
	"WALL",
	"GLASS",
	"DECOR",
	"MIRROR_LEFT_DOWN",
	"MIRROR_LEFT_UP",
	"MIRROR_RIGHT_DOWN",
	"MIRROR_RIGHT_UP",
}
objects["AIR"] = 0

sprites.floor = sprite.new("sprites/floor.png")
sprites.wall = sprite.new("sprites/wall.png")
sprites.glass = sprite.new("sprites/glass.png", 11, 0)
sprites.vase = sprite.new("sprites/vase.png")

sprites.mirror_left_down = sprite.new("sprites/mirror_left_down.png")
sprites.mirror_left_up = sprite.new("sprites/mirror_left_up.png")
sprites.mirror_right_down = sprite.new("sprites/mirror_right_down.png")
sprites.mirror_right_up = sprite.new("sprites/mirror_right_up.png")

sprites.ghost_round = sprite.new("sprites/ghost_round.png", 8, 0.25)
sprites.ghost_round_off = sprite.new("sprites/ghost_round_off.png")

sprites.ghost_square = sprite.new("sprites/ghost_square.png", 8, 0.25)
sprites.ghost_square_off = sprite.new("sprites/ghost_square_off.png")

sprites.ghost_triangle = sprite.new("sprites/ghost_triangle.png", 8, 0.25)
sprites.ghost_triangle_off = sprite.new("sprites/ghost_triangle_off.png")

sprites.player_up = sprite.new("sprites/player_up.png", 4, 0.625)
sprites.player_down = sprite.new("sprites/player_down.png", 4, 0.625)
sprites.player_left = sprite.new("sprites/player_left.png", 4, 0.625)
sprites.player_right = sprite.new("sprites/player_right.png", 4, 0.625)

sprites.player_up_photo = sprite.new("sprites/player_up_photo.png")
sprites.player_down_photo = sprite.new("sprites/player_down_photo.png")
sprites.player_left_photo = sprite.new("sprites/player_left_photo.png")
sprites.player_right_photo = sprite.new("sprites/player_right_photo.png")

-- CUTSCENE STUFF
sprites.cutscene_stars = sprite.new("sprites/cutscene_00a.png")
sprites.cutscene_blocker = sprite.new("sprites/cutscene_00b.png")
sprites.cutscene_back = sprite.new("sprites/cutscene_00c.png")
sprites.cutscene_clouds = sprite.new("sprites/cutscene_00d.png")
sprites.cutscene_ghost_happy = sprite.new("sprites/cutscene_01.png")
sprites.cutscene_ghost_angry = sprite.new("sprites/cutscene_02.png")
sprites.cutscene_ghost_scared = sprite.new("sprites/cutscene_03.png")
sprites.cutscene_camera = sprite.new("sprites/cutscene_04.png")
sprites.cutscene_camera_pressing = sprite.new("sprites/cutscene_05.png")

-- ANIMATION OFFSETS
sprites.ghost_square.frame = 3
sprites.ghost_triangle.frame = 6

function game:load(_level)
	toggle_releasedb()
	
	self.level = 1
	self.game_over = false
	self.current_text = nil
	self.level_texts = {}
	self.level_texts_shadows = {}
	
	self.level_special_texts = {
		["LVL_01_FRAME"] = false,
		["LVL_02_QUANTUM"] = false,
		["LVL_03_TURN"] = false,
		["LVL_05_TOGETHER"] = false,
		["LVL_10_END"] = false,
	}
	
	if (_level) then
		self.level = _level
	end
	self.turnTutorial = 0
	self.blink_id = {}
	self.select_holding = {0, 1.5}
	self.game_over_anim = {0, 0}
	self.photo_time = .75
	self.last_flash = false
	self.last_text = nil
	
	for i, v in pairs(shapes) do
		self.blink_id[i] = 0
	end
	
	self.tile_size = 12
	
	self.grid = {}
	self.grid_width = math.floor(game_width / self.tile_size)
	self.grid_height = math.floor(game_height / self.tile_size)
	
	self.light_map = {}
	
	for x = 0, self.grid_width-1 do
		self.grid[x] = {}
		self.light_map[x] = {}
		for y = 0, self.grid_height-1 do
			self.grid[x][y] = objects.AIR
			self.light_map[x][y] = {shape = {left = "none", right = "none", up = "none", down = "none", center = "none"}, level = 0}
		end
	end
	
	self.ghosts = {}
	self.player = {
		dir = "down",
		x = 8,
		y = 8,
		post_photo_callback = nil,
		taking_photo = false,
		takePhoto = function(self)
			self.taking_photo = game.photo_time
			sounds.flash:play()
			game:checkGhosts()
		end,
		
		update = function(self, dt)
			if (self.taking_photo) then
				self.taking_photo = self.taking_photo - dt
				if (self.taking_photo <= 0) then
					self.taking_photo = false
					if (self.post_photo_callback) then
						self.post_photo_callback()
						self.post_photo_callback = nil
					end
				end
			end
		end,
		
		turn = function(self, dir)
			if (self.taking_photo) then return end
			self.dir = dir
		end,
		
		move = function(self, dir)
			if (self.taking_photo) then return end
			local oldx, oldy = self.x, self.y
			if (dir == "up") then
				if (self.y > 0 and game.grid[self.x][self.y-1] == objects.AIR) then
					self.y = self.y - 1
					sounds.step:play()
				end
			elseif (dir == "down") then
				if (self.y < game.grid_height-1 and game.grid[self.x][self.y+1] == objects.AIR) then
					self.y = self.y + 1
					sounds.step:play()
				end
			elseif (dir == "left") then
				if (self.x > 0 and game.grid[self.x-1][self.y] == objects.AIR) then
					self.x = self.x - 1
					sounds.step:play()
				end
			elseif (dir == "right") then
				if (self.x < game.grid_width-1 and game.grid[self.x+1][self.y] == objects.AIR) then
					self.x = self.x + 1
					sounds.step:play()
				end
			end
			if (self.x ~= oldx or self.y ~= oldy) then
				-- Player did, in fact, move
				game:playerMoved()
			end
			
			self:turn(dir)
		end,
		
		draw = function(self)
			local spr = "player_" .. self.dir
			if (self.taking_photo) then
				spr = spr .. "_photo"
			end
			game:drawObject( spr, self.x, self.y )
		end
	}
	
	self.off_x = math.floor((game_width - (self.grid_width * self.tile_size)) / 2)
	self.off_y = math.floor((game_height - (self.grid_height * self.tile_size)) / 2)
	
	self:loadLevel(self.level)
end

function game:update(dt)
	for i, v in pairs(sprites) do
		if (v.update) then
			v:update(dt)
		end
	end
	
	if (self.game_over) then
		self.game_over_anim[1] = math.max(0, self.game_over_anim[1] - dt)
	end
	
	self.player:update(dt)
	
	self:updateLightMap()
	if (not self.player.taking_photo) then
		self:updateGhosts()
	end
	
	if (self.select_holding[1] > 0) then
		self.select_holding[1] = self.select_holding[1] - dt
		if (self.select_holding[1] <= 0) then
			self:restart()
		end
	end
end

function game:draw()
	if (self.current_text) then
		
		local hh = 14
		local yy = math.floor(game_height/2 - #self.level_texts[self.current_text]*hh/2 + 3)
		if (self.game_over) then
			
			-- Background
			sprites.cutscene_stars:draw(0, 0, nil, nil, true)
			sprites.cutscene_blocker:draw(140, 20, nil, nil, true, oscilator/20)
			
			sprites.cutscene_back:draw(0, 0, nil, nil, true)
			local cloud_scroll_time = 120 * 3
			local clouds_x_off = (oscilator % cloud_scroll_time)/cloud_scroll_time * sprites.cutscene_clouds.img_width
			sprites.cutscene_clouds:draw(0 - clouds_x_off, 0, nil, nil, true)
			sprites.cutscene_clouds:draw(sprites.cutscene_clouds.img_width - clouds_x_off, 0, nil, nil, true)
			
			-- Ghost
			if (self.current_text == 5) then
				local progress = math.min(1, self.game_over_anim[1] / self.game_over_anim[2] )
				progress = 1-progress -- game_over_anim decrements
				local palette_step = { {4, 0, 4, 0}, {4}, {3, 4}, {3, 4}, {3, 3, 4}, {2, 3, 4}, {1, 2, 3, 4} }
				palette_step = palette_step[ math.ceil(progress * #palette_step) ]
				
				sprites.cutscene_ghost_happy:draw(0, 1 + math.sin(oscilator), palette_step, nil, true)
			elseif (self.current_text == 6) then
				sprites.cutscene_ghost_angry:draw(0, 1 + math.sin(oscilator), palette_step, nil, true)
			elseif (self.current_text == 7) then
				local progress = math.min(1, self.game_over_anim[1] / self.game_over_anim[2] )
				local y = math.floor(progress ^ 2 * 20)
				
				sprites.cutscene_ghost_scared:draw(0, 1 + math.sin(oscilator), nil, nil, true)
				sprites.cutscene_camera:draw(0, y, nil, nil, true)
			elseif (self.current_text >= 8) then
				local progress = math.min(1, self.game_over_anim[1] / self.game_over_anim[2] )
				progress = 1-progress -- game_over_anim decrements
				local ghost_palette = {1, 2, 3, 4}
				
				if (progress >= 0.85) then
					love.graphics.setColor(colors[4])
					love.graphics.rectangle("fill", 0, 0, game_width, game_height)
					
					if (progress >= 0.99) then
						love.graphics.setColor(1, 1, 1, 1)
						love.graphics.printf({colors[3], "THE END!"}, 0, yy + 1, game_width, "center")
						love.graphics.printf({colors[2], "THE END!"}, 0, yy, game_width, "center")
					end
					return
				elseif (progress >= 0.65) then
					love.graphics.setColor(colors[3])
					love.graphics.rectangle("fill", 0, 0, game_width, game_height)
					return
				elseif (progress >= 0.55) then
					love.graphics.setColor(colors[2])
					love.graphics.rectangle("fill", 0, 0, game_width, game_height)
					return
				elseif (progress >= 0.45) then
					love.graphics.setColor(colors[2])
					love.graphics.rectangle("fill", 0, 0, game_width, game_height)
					ghost_palette = {2}
				elseif (progress >= 0.4) then
					sprites.cutscene_back:draw(0, 0, {1, 1, 1, 2}, nil, true)
					ghost_palette = {1, 1, 2, 2}
				elseif (progress >= 0.35) then -- Start flash
					sprites.cutscene_back:draw(0, 0, {1, 2, 2, 3}, nil, true)
					ghost_palette = {1, 2, 2, 3}
				end
				
				sprites.cutscene_ghost_scared:draw(0, 1 + math.sin(oscilator), ghost_palette, nil, true)
				
				if (progress >= 0.25) then
					sprites.cutscene_camera_pressing:draw(0, 0, nil, nil, true)
					if (not self.last_flash) then
						sounds.flash:play()
						self.last_flash = true
					end
				else
					sprites.cutscene_camera:draw(0, 0, nil, nil, true)
				end
				
				return
			end
			
			yy = 4
			hh = 10
			
			love.graphics.setColor(1, 1, 1, 1)
			if (self.current_text ~= 5 or self.game_over_anim[1] <= 0) then -- Yeah yeah magic numbers. Refer to 10_end.txt
				for idx, text in ipairs(self.level_texts_shadows2[self.current_text]) do
					love.graphics.printf(text, 0-1, yy + (idx-1)*hh, game_width, "center")
					love.graphics.printf(text, 0-2, yy + (idx-1)*hh, game_width, "center")
					love.graphics.printf(text, 0+1, yy + (idx-1)*hh, game_width, "center")
					love.graphics.printf(text, 0+2, yy + (idx-1)*hh, game_width, "center")
					love.graphics.printf(text, 0, yy + (idx-1)*hh -1, game_width, "center")
					love.graphics.printf(text, 0, yy + (idx-1)*hh -2, game_width, "center")
					love.graphics.printf(text, 0, yy + (idx-1)*hh +1, game_width, "center")
					love.graphics.printf(text, 0, yy + (idx-1)*hh +2, game_width, "center")
					love.graphics.printf(text, 0 -1, yy + (idx-1)*hh -1, game_width, "center")
					love.graphics.printf(text, 0 -1, yy + (idx-1)*hh +1, game_width, "center")
					love.graphics.printf(text, 0 +1, yy + (idx-1)*hh -1, game_width, "center")
					love.graphics.printf(text, 0 +1, yy + (idx-1)*hh +1, game_width, "center")
				end
			end
		end
		
		love.graphics.setColor(1, 1, 1, 1)
		if (not self.game_over or self.current_text ~= 5 or self.game_over_anim[1] <= 0) then -- Yeah yeah magic numbers. Refer to 10_end.txt
			for idx, text in ipairs(self.level_texts[self.current_text]) do
				local shadow = self.level_texts_shadows[self.current_text][idx]
				love.graphics.printf(shadow, 0, yy + (idx-1)*hh + 1, game_width, "center")
				
				love.graphics.printf(text, 0, yy + (idx-1)*hh, game_width, "center")
			end
		end
		drawForward()
		return
	end
	
	love.graphics.setColor(colors[1])
	
	for x = 0, self.grid_width-1 do
		for y = 0, self.grid_height-1 do
			local light_map = self.light_map[x][y]
			local lvl = light_map.level
			local palette = ( lvl == 0 and {4} or ( lvl == 0.5 and {3, 3, 4} or {3, 3, 3, 4} ) )
			sprites.floor:draw(x, y, palette)
			
			if (self.grid[x][y] == objects.DECOR) then
				palette = ( lvl == 0 and {3, 4} or ( lvl == 0.5 and {2, 3, 3, 4} or {2, 1, 3, 4} ) )
				
				self:drawObject( self.grid[x][y], x, y, palette )
			elseif (	self.grid[x][y] == objects.MIRROR_LEFT_DOWN
					or	self.grid[x][y] == objects.MIRROR_LEFT_UP
					or	self.grid[x][y] == objects.MIRROR_RIGHT_DOWN
					or	self.grid[x][y] == objects.MIRROR_RIGHT_UP) then
				palette = ( lvl == 0 and {2, 3, 4} or ( lvl == 0.5 and {1, 2, 4} or {1, 2, 3, 4} ) )
				
				self:drawObject( self.grid[x][y], x, y, palette )
			elseif (self.grid[x][y] ~= objects.AIR) then
				if (self.grid[x][y] == objects.GLASS) then
					palette = ( lvl == 0 and {4} or ( lvl == 0.5 and {2, 3, 4} or {2, 2, 3, 4} ) )
					local hasUp = (y > 0 and self.grid[x][y-1] == objects.GLASS)
					local hasDown = (y < self.grid_width-1 and self.grid[x][y+1] == objects.GLASS)
					local hasLeft = (x > 0 and self.grid[x-1][y] == objects.GLASS)
					local hasRight = (x < self.grid_height-1 and self.grid[x+1][y] == objects.GLASS)
					
					--         1 2 3 4 5 6 7 8 9 10 11
					-- frames: o < = > ^ | v F 7  L  J
					local frame = 1
					if (hasUp and hasDown) then
						frame = 6
					elseif (hasLeft and hasRight) then
						frame = 3
					elseif (hasDown and hasRight) then
						frame = 8
					elseif (hasDown and hasLeft) then
						frame = 9
					elseif (hasUp and hasRight) then
						frame = 10
					elseif (hasUp and hasLeft) then
						frame = 11
					elseif (hasUp) then
						frame = 7
					elseif (hasDown) then
						frame = 5
					elseif (hasLeft) then
						frame = 4
					elseif (hasRight) then
						frame = 2
					end
					
					self:drawObject( self.grid[x][y], x, y, palette, frame )
				elseif (self.grid[x][y] == objects.WALL) then
					palette = ( lvl == 0 and {3, 4} or ( lvl == 0.5 and {2, 3, 4} or {2, 2, 3, 4} ) )
					
					self:drawObject( self.grid[x][y], x, y, palette )
					
					local xx, yy, ww, hh = x, y, 1, 1
					
					local thickness = nil
					if (light_map.shape["left"] == "thin" or light_map.shape["left"] == "thick") then
						thickness = (light_map.shape["left"] == "thin" and 2/12 or 3/12)
						xx = xx + thickness
						ww = ww - thickness
					end
					if (light_map.shape["right"] == "thin" or light_map.shape["right"] == "thick") then
						thickness = (light_map.shape["right"] == "thin" and 2/12 or 3/12)
						ww = ww - thickness
					end
					if (light_map.shape["up"] == "thin" or light_map.shape["up"] == "thick") then
						thickness = (light_map.shape["up"] == "thin" and 2/12 or 3/12)
						yy = yy + thickness
						hh = hh - thickness
					end
					if (light_map.shape["down"] == "thin" or light_map.shape["down"] == "thick") then
						thickness = (light_map.shape["down"] == "thin" and 2/12 or 3/12)
						hh = hh - thickness
					end
					
					love.graphics.setColor(colors[4])
					game:drawTransform( function() love.graphics.rectangle("fill", xx, yy, ww, hh) end )
				end
				
				-- DRAWS DASHED LINES
				if (light_map.shape["center"] == "none") then
					local airLeft = (x > 0 and self.grid[x-1][y] ~= self.grid[x][y])
					local airRight = (x < self.grid_width-1 and self.grid[x+1][y] ~= self.grid[x][y])
					local airUp = (y > 0 and self.grid[x][y-1] ~= self.grid[x][y])
					local airDown = (y < self.grid_height-1 and self.grid[x][y+1] ~= self.grid[x][y])
					
					local airUpLeft = (x > 0 and y > 0 and self.grid[x-1][y-1] ~= self.grid[x][y])
					local airUpRight = (x < self.grid_width-1 and y > 0 and self.grid[x+1][y-1] ~= self.grid[x][y])
					local airDownLeft = (x > 0 and y < self.grid_height-1 and self.grid[x-1][y+1] ~= self.grid[x][y])
					local airDownRight = (x < self.grid_width-1 and y < self.grid_height-1 and self.grid[x+1][y+1] ~= self.grid[x][y])
					
					love.graphics.setColor(colors[3])
					local tt = 1/12
					local off = 3/12
					
					-- Outer corners
					if (airLeft and not airUp and not airUpLeft) then -- Top-right of outline, bottom-left of tile
						game:drawTransform( function() love.graphics.rectangle("fill", x, y-tt, tt, tt) end )
					end
					if (airRight and not airUp and not airUpRight) then -- Top-left of outline, bottom-right of tile
						game:drawTransform( function() love.graphics.rectangle("fill", x+1-tt, y-tt, tt, tt) end )
					end
					if (not airUp and not airLeft and airUpLeft) then -- Bottom-right of outline, top-left of tile
						game:drawTransform( function() love.graphics.rectangle("fill", x, y, tt, tt) end )
					end
					if (not airUp and not airRight and airUpRight) then -- Bottom-left of outline, top-right of tile
						game:drawTransform( function() love.graphics.rectangle("fill", x+1-tt, y, tt, tt) end )
					end
					
					-- Orthogonal lines
					if (airLeft and light_map.shape["left"] == "none") then -- Right of outline, left of tile
						game:drawTransform( function() love.graphics.rectangle("fill", x, y+off, tt, 1-2*off) end )
						-- Inner corners
						if (airUp and light_map.shape["up"] == "none") then -- Bottom-right of outline, top-left of tile
							game:drawTransform( function() love.graphics.rectangle("fill", x, y, tt, tt) end )
						end
						if (airDown and light_map.shape["down"] == "none") then -- Top-right of outline, bottom-left of tile
							game:drawTransform( function() love.graphics.rectangle("fill", x, y+1-tt, tt, tt) end )
						end
					end
					if (airRight and light_map.shape["right"] == "none") then -- Left of outline, right of tile
						game:drawTransform( function() love.graphics.rectangle("fill", x+1-tt, y+off, tt, 1-2*off) end )
						-- Inner corners
						if (airUp and light_map.shape["up"] == "none") then -- Bottom-left of outline, top-right of tile
							game:drawTransform( function() love.graphics.rectangle("fill", x+1-tt, y, tt, tt) end )
						end
						if (airDown and light_map.shape["down"] == "none") then -- Top-left of outline, bottom-right of tile
							game:drawTransform( function() love.graphics.rectangle("fill", x+1-tt, y+1-tt, tt, tt) end )
						end
					end
					if (airUp and light_map.shape["up"] == "none") then -- Bottom of outline, top of tile
						game:drawTransform( function() love.graphics.rectangle("fill", x+off, y, 1-2*off, tt) end )
					end
					if (airDown and light_map.shape["down"] == "none") then -- Top of outline, bottom of tile
						game:drawTransform( function() love.graphics.rectangle("fill", x+off, y+1-tt, 1-2*off, tt) end )
					end
				end
			end
		end
	end
	
	for i, v in ipairs(self.ghosts) do
		v:draw()
	end
	for i, v in pairs(self.blink_id) do
		self.blink_id[i] = 0
	end
	
	self.player:draw()
end

function game:updateLightMap()
	local flash = self.player.taking_photo and .5 or 1
	local dir = self.player.dir
	local player_beams = {
		-- startx, stary, endx, endy, light_level, wall_check_table
		-- FULL, PLAYER
		{self.player.x, self.player.y, self.player.x, 0, (dir == "up" and 1 or flash)}, -- UP FROM PLAYER
		{self.player.x, self.player.y, self.player.x, self.grid_height-1, (dir == "down" and 1 or flash)}, -- DOWN FROM PLAYER
		{self.player.x, self.player.y, 0, self.player.y, (dir == "left" and 1 or flash)}, -- LEFT FROM PLAYER
		{self.player.x, self.player.y, self.grid_width-1, self.player.y, (dir == "right" and 1 or flash)}, -- RIGHT FROM PLAYER
		
		-- FULL, ADJACENT
		{self.player.x-1, self.player.y, self.player.x-1, 0, flash, -- UP FROM PLAYER LEFT
			{	self.player.x, self.player.y-1 }
		},
		{self.player.x, self.player.y-1, 0, self.player.y-1, flash, -- LEFT FROM PLAYER TOP
			{	self.player.x-1, self.player.y }
		},
		
		{self.player.x+1, self.player.y, self.player.x+1, 0, flash, -- UP FROM PLAYER RIGHT
			{	self.player.x, self.player.y-1 }
		},
		{self.player.x, self.player.y-1, self.grid_width-1, self.player.y-1, flash, -- RIGHT FROM PLAYER TOP
			{	self.player.x+1, self.player.y }
		},
		
		{self.player.x-1, self.player.y, self.player.x-1, self.grid_height-1, flash, -- DOWN FROM PLAYER LEFT
			{	self.player.x, self.player.y+1 }
		},
		{self.player.x, self.player.y+1, 0, self.player.y+1, flash, -- LEFT FROM PLAYER BOTTOM
			{	self.player.x-1, self.player.y }
		},
		
		{self.player.x+1, self.player.y, self.player.x+1, self.grid_height-1, flash, -- DOWN FROM PLAYER RIGHT
			{	self.player.x, self.player.y+1 }
		},
		{self.player.x, self.player.y+1, self.grid_width-1, self.player.y+1, flash, -- RIGHT FROM PLAYER BOTTOM
			{	self.player.x+1, self.player.y }
		},
		
		-- FAINT (2x)
		{self.player.x-2, self.player.y, self.player.x-2, 0, .5, -- UP FROM PLAYER LEFT-2
			{	self.player.x-1, self.player.y,
				self.player.x, self.player.y-1,
				self.player.x-1, self.player.y-1 }
		},
		{self.player.x, self.player.y-2, 0, self.player.y-2, .5, -- LEFT FROM PLAYER TOP-2
			{	self.player.x, self.player.y-1,
				self.player.x-1, self.player.y,
				self.player.x-1, self.player.y-1 }
		},
		
		{self.player.x+2, self.player.y, self.player.x+2, 0, .5, -- UP FROM PLAYER RIGHT-2
			{	self.player.x+1, self.player.y,
				self.player.x, self.player.y-1,
				self.player.x+1, self.player.y-1 }
		},
		{self.player.x, self.player.y-2, self.grid_width-1, self.player.y-2, .5, -- RIGHT FROM PLAYER TOP-2
			{	self.player.x, self.player.y-1,
				self.player.x+1, self.player.y,
				self.player.x+1, self.player.y-1 }
		},
		
		{self.player.x-2, self.player.y, self.player.x-2, self.grid_height-1, .5, -- DOWN FROM PLAYER LEFT-2
			{	self.player.x-1, self.player.y,
				self.player.x, self.player.y+1,
				self.player.x-1, self.player.y+1 }
		},
		{self.player.x, self.player.y+2, 0, self.player.y+2, .5, -- LEFT FROM PLAYER BOTTOM-2
			{	self.player.x, self.player.y+1,
				self.player.x-1, self.player.y,
				self.player.x-1, self.player.y+1 }
		},
		
		{self.player.x+2, self.player.y, self.player.x+2, self.grid_height-1, .5, -- DOWN FROM PLAYER RIGHT-2
			{	self.player.x+1, self.player.y,
				self.player.x, self.player.y+1,
				self.player.x+1, self.player.y+1 }
		},
		{self.player.x, self.player.y+2, self.grid_width-1, self.player.y+2, .5, -- RIGHT FROM PLAYER BOTTOM-2
			{	self.player.x, self.player.y+1,
				self.player.x+1, self.player.y,
				self.player.x+1, self.player.y+1 }
		},
	}
	
	for x = 0, self.grid_width-1 do
		for y = 0, self.grid_height-1 do
			self.light_map[x][y].level = 0
			self.light_map[x][y].shape = {left = "none", right = "none", up = "none", down = "none", center = "none"}
		end
	end
	
	local function checkHitWall(tt)
		if (tt == nil or #tt == 0) then
			return false
		end
		
		for i = 1, #tt-1, 2 do
			local xx = tt[i]
			local yy = tt[i+1]
			
			if (xx >= 0 and xx <= self.grid_width-1 and yy >= 0 and yy <= self.grid_height-1) then
				if (		self.grid[xx][yy] == objects.WALL
						or 	self.grid[xx][yy] == objects.MIRROR_LEFT_DOWN
						or 	self.grid[xx][yy] == objects.MIRROR_LEFT_UP
						or 	self.grid[xx][yy] == objects.MIRROR_RIGHT_DOWN
						or 	self.grid[xx][yy] == objects.MIRROR_RIGHT_UP) then
					return true
				end
			end
		end
		return false
	end
	
	local lim = #player_beams
	local i = 0
	while (i < #player_beams) do
		i = i + 1 -- for loops are fixed in length
		local v = player_beams[i]
		local xstart, ystart, xend, yend, lightlevel, wallcheck = v[1], v[2], v[3], v[4], v[5], v[6]
		
		local _hitWall = checkHitWall( wallcheck )
		
		if (	xstart >= 0 and xstart <= self.grid_width-1 and ystart >= 0 and ystart <= self.grid_height-1
				and self.grid[ xstart ][ ystart ] ~= objects.WALL
				and (self.grid[ xstart ][ ystart ] ~= objects.MIRROR_LEFT_DOWN or i > lim)
				and (self.grid[ xstart ][ ystart ] ~= objects.MIRROR_LEFT_UP or i > lim)
				and (self.grid[ xstart ][ ystart ] ~= objects.MIRROR_RIGHT_DOWN or i > lim)
				and (self.grid[ xstart ][ ystart ] ~= objects.MIRROR_RIGHT_UP or i > lim)
				and not _hitWall ) then
			local can_break = false
			for x = xstart, xend, (xstart > xend and -1 or 1) do
				for y = ystart, yend, (ystart > yend and -1 or 1) do
					self.light_map[x][y].level = math.max(self.light_map[x][y].level, lightlevel)
					local dir
					if (xstart == xend) then -- VERTICAL
						dir = (ystart < yend and "up" or "down")
					elseif (ystart == yend) then -- HORIZONTAL
						dir = (xstart < xend and "left" or "right")
					end
					
					-- Before anyone screams about the unnecessary code repetition for mirrors: I have less than 6 hours left
					if (self.grid[x][y] == objects.MIRROR_LEFT_DOWN) then
						-- DIRECTIONS ARE INVERTED!
						-- This is because they were made primarily for wall lighting
						if (dir == "left" and self.light_map[x][y].shape["left"] ~= "full") then -- If hit from right, go down
							self.light_map[x][y].shape["left"] = "full"
							if (y < self.grid_height-1) then
								table.insert(player_beams, {
									x, y+1, x, self.grid_height-1, lightlevel
								})
							end
						elseif (dir == "down" and self.light_map[x][y].shape["down"] ~= "full") then -- If hit from below, go left
							self.light_map[x][y].shape["down"] = "full"
							if (x > 0) then
								table.insert(player_beams, {
									x-1, y, 0, y, lightlevel
								})
							end
						end
						can_break = true
					elseif (self.grid[x][y] == objects.MIRROR_RIGHT_DOWN) then
						-- DIRECTIONS ARE INVERTED!
						-- This is because they were made primarily for wall lighting
						if (dir == "right" and self.light_map[x][y].shape["right"] ~= "full") then -- If hit from left, go down
							self.light_map[x][y].shape["right"] = "full"
							if (y < self.grid_height-1) then
								table.insert(player_beams, {
									x, y+1, x, self.grid_height-1, lightlevel
								})
							end
						elseif (dir == "down" and self.light_map[x][y].shape["down"] ~= "full") then -- If hit from below, go right
							self.light_map[x][y].shape["down"] = "full"
							if (x < self.grid_width-1) then
								table.insert(player_beams, {
									x+1, y, self.grid_width-1, y, lightlevel
								})
							end
						end
						can_break = true
					elseif (self.grid[x][y] == objects.MIRROR_LEFT_UP) then
						-- DIRECTIONS ARE INVERTED!
						-- This is because they were made primarily for wall lighting
						if (dir == "left" and self.light_map[x][y].shape["left"] ~= "full") then -- If hit from right, go up
							self.light_map[x][y].shape["left"] = "full"
							if (y > 0) then
								table.insert(player_beams, {
									x, y-1, x, 0, lightlevel
								})
							end
						elseif (dir == "up" and self.light_map[x][y].shape["up"] ~= "full") then -- If hit from above, go left
							self.light_map[x][y].shape["up"] = "full"
							if (x > 0) then
								table.insert(player_beams, {
									x-1, y, 0, y, lightlevel
								})
							end
						end
						can_break = true
					elseif (self.grid[x][y] == objects.MIRROR_RIGHT_UP) then
						-- DIRECTIONS ARE INVERTED!
						-- This is because they were made primarily for wall lighting
						if (dir == "right" and self.light_map[x][y].shape["right"] ~= "full") then -- If hit from left, go up
							self.light_map[x][y].shape["right"] = "full"
							if (y > 0) then
								table.insert(player_beams, {
									x, y-1, x, 0, lightlevel
								})
							end
						elseif (dir == "up" and self.light_map[x][y].shape["up"] ~= "full") then -- If hit from above, go right
							self.light_map[x][y].shape["up"] = "full"
							if (x < self.grid_width-1) then
								table.insert(player_beams, {
									x+1, y, self.grid_width-1, y, lightlevel
								})
							end
						end
						can_break = true
					elseif (self.grid[x][y] == objects.WALL) then
						-- self.light_map[x][y].level = .125
						local thickness = "thin"
						if ( math.abs(self.player.x - x) <= 1 or math.abs(self.player.y - y) <= 1 ) then
							thickness = "thick"
						end
						
						self.light_map[x][y].shape[dir] = thickness
						can_break = true
					else
						self.light_map[x][y].shape["center"] = "full"
					end
					if (can_break) then break end
				end
				if (can_break) then break end
			end
		end
	end
	
	-- Player's own position does NOT count for photo
	-- self.light_map[self.player.x][self.player.y].level = flash
end

function game:dpad_pressed(dir)
	if (self.current_text) then return end
	
	if (button_isDown("b")) then
		self.player:turn(dir)
	else
		self.player:move(dir)
	end
end

function game:button_pressed(button)
	if (self.current_text) then
		if (self.game_over and self.game_over_anim[1] > 0) then
			return
		end
		
		if (button == "a" or button == "start" or button == "select") then
			sounds.enter:play()
			self.current_text = self.current_text + 1
			if (self.game_over) then
				if (self.current_text == 5) then -- Yeah yeah magic numbers. Refer to 10_end.txt
					self.game_over_anim = {2, 2}
				elseif (self.current_text == 7) then
					self.game_over_anim = {1, 1}
				elseif (self.current_text == 8) then
					self.game_over_anim = {2, 2}
				elseif (self.current_text > 8) then
					sounds.game_song:stop()
					hold(.25, function() loadState("splash") end)
				end
			else
				if (self.current_text > #self.level_texts) then
					self.current_text = nil
					sounds.game_song:play()
				end
			end
		end
		return
	end
	if (button == "select") then
		self.select_holding[1] = self.select_holding[2]
	elseif (button == "start") then
		sounds.pause:play()
		loadState("options", true)
	elseif (button == "a") then
		self.player:takePhoto()
	end
end

function game:button_released(button)
	if (button == "select") then
		self.select_holding[1] = 0
	end
end

function game:drawObject(id, x, y, palette, frame)
	if (id == objects.AIR) then
		return
	end
	
	if (id == objects.WALL) then
		sprites.wall:draw(x, y, palette, frame)
	elseif (id == objects.GLASS) then
		sprites.glass:draw(x, y, palette, frame)
	elseif (id == objects.MIRROR_LEFT_DOWN) then
		sprites.mirror_left_down:draw(x, y, palette, frame)
	elseif (id == objects.MIRROR_LEFT_UP) then
		sprites.mirror_left_up:draw(x, y, palette, frame)
	elseif (id == objects.MIRROR_RIGHT_DOWN) then
		sprites.mirror_right_down:draw(x, y, palette, frame)
	elseif (id == objects.MIRROR_RIGHT_UP) then
		sprites.mirror_right_up:draw(x, y, palette, frame)
	elseif (id == objects.DECOR) then
		-- Vase is a little bit higher
		sprites.vase:draw(x, y - 4/12, palette, frame)
	elseif ( type(id) == "string" ) then
		sprites[id]:draw(x, y, palette, frame)
	end
end

function game:drawTransform(f)
	love.graphics.push()
	love.graphics.translate(self.off_x, self.off_y)
	love.graphics.scale(self.tile_size)
	f()
	love.graphics.pop()
end

function game:loadLevel(level)
	self.level = level or self.level
	local lvl_name = addZeros(self.level)
	
	local imgData
	if (love.filesystem.read("levels/" .. lvl_name .. ".png")) then
		imgData = love.image.newImageData("levels/" .. lvl_name .. ".png")
		
		if (self.level > latest_level) then
			latest_level = self.level
			saveData()
		end
	else
		-- GAME OVER
		self.game_over = true
		return
	end
	
	self.turnTutorial = 0
	
	if (love.filesystem.read("levels/" .. lvl_name .. ".txt")) then
		self.current_text = 1
		if (DEBUG) then
			self.current_text = nil
		end
	else
		sounds.game_song:play()
	end
	self:processTexts()
	
	self.ghosts = {}
	self.ghost_shapes = {}
	for i, v in pairs(shapes) do
		self.ghost_shapes[i] = 0
	end
	imgData:mapPixel(function(x, y, r, g, b, a)
		self.grid[x][y] = objects.AIR -- by default
		if (a <= .5 or (r == 1 and g == 1 and b == 1)) then
			-- AIR
		elseif (r == 1 and g == 0 and b == 0) then
			-- PLAYER
			self.player.x = x
			self.player.y = y
		elseif (r == 1 and g == 1 and b == 0) then
			-- ROUND GHOST
			table.insert(self.ghosts, self:makeGhost(x, y, "round"))
		elseif (r == 1 and g >= .4 and g <= .6 and b == 0) then
			-- SQUARE GHOST
			table.insert(self.ghosts, self:makeGhost(x, y, "square"))
		elseif (r >= .4 and r <= .6 and g >= .4 and g <= .6 and b == 0) then
			-- TRIANGLE GHOST
			table.insert(self.ghosts, self:makeGhost(x, y, "triangle"))
		elseif (r == 0 and g == 1 and b == 1) then
			self.grid[x][y] = objects.GLASS
		elseif (r == 0 and g == 1 and b == 0) then
			self.grid[x][y] = objects.DECOR
		elseif (r == 0 and g == 0 and b == 1) then
			self.grid[x][y] = objects.MIRROR_LEFT_DOWN
		elseif (r >= .4 and r <= .6 and g >= .4 and g <= .6 and b == 1) then
			self.grid[x][y] = objects.MIRROR_RIGHT_DOWN
		elseif (r == 1 and g == 0 and b == 1) then
			self.grid[x][y] = objects.MIRROR_LEFT_UP
		elseif (r == 1 and g >= .4 and g <= .6 and b == 1) then
			self.grid[x][y] = objects.MIRROR_RIGHT_UP
		elseif (r <= 0.13 and g <= 0.13 and b <= 0.13) then
			-- WALL
			self.grid[x][y] = objects.WALL
		end
		
		return r, g, b, a
	end)
	
	self:updateLightMap()
	self:updateGhosts()
end

function game:makeGhost(x, y, shape)
	shape = shape or "round"
	self.ghost_shapes[shape] = self.ghost_shapes[shape] + 1
	return {
		x = x,
		y = y,
		shape = shape,
		state = "quantum",
		observed = false,
		id = self.ghost_shapes[shape] - 1,
		draw = function(self)
			local lvl = game.light_map[self.x][self.y].level
			local palette = ( lvl == 0 and {3, 2, 4} or (lvl == 0.5 and {2, 1, 4, 4} or {1, 2, 3, 4}) )
			
			local _off = ""
			if ( self.state == "off" or (self.state == "quantum" and game:ghostBlinking(self)) ) then
				_off = "_off"
			end
			game:drawObject( "ghost_" .. self.shape .. _off, self.x, self.y, palette )
		end,
	}
end

function game:updateGhosts()
	-- Update observance first
	self.observables = {}
	for i, v in pairs(shapes) do
		self.observables[i] = 0
	end
	for i, v in ipairs(self.ghosts) do
		v.observed = (self.light_map[v.x][v.y].level == 1)
		if (v.x == self.player.x and v.y == self.player.y) then
			v.observed = false
			-- You can't observe a ghost INSIDE of you. C'mon...
		end
	end
	
	-- Defines who is quantum
	for i, v in ipairs(self.ghosts) do
		if (v.state == "off" and v.observed) then
			-- Observed being off STAYS being off
		else
			if (self.ghost_shapes[v.shape] == 1) then
				-- Unique ghosts are ALWAYS on
				v.state = "on"
			else
				v.state = "quantum"
				self.observables[v.shape] = self.observables[v.shape] + 1
			end
		end
	end
	
	-- Is a quantum being observed? Be off
	for i, v in ipairs(self.ghosts) do
		if (v.state == "quantum" and self.observables[v.shape] > 1 and v.observed) then
			v.state = "off"
			self.observables[v.shape] = self.observables[v.shape] - 1
		end
	end
	
	-- Is a quantum being observed AND the last remaining one? Be on
	for i, v in ipairs(self.ghosts) do
		if (v.state == "quantum" and self.observables[v.shape] == 1) then
			-- I'm the only non-observed quantum ghost of my shape, so I'm being SEEN (or at least restricted)
			v.state = "on"
		end
	end
end

function game:ghostBlinking(ghost)
	local shape = ghost.shape
	local id = self.blink_id[shape]
	self.blink_id[shape] = self.blink_id[shape] + 1 -- Reset after drawing ghosts, used just for easier calculations
	
	local total = self.observables[shape]
	
	local speed_mult = 2
	local _off = shapes[shape]
	local osc = ((oscilator + _off*1/3) % speed_mult) / speed_mult
	
	return osc < id/total or osc >= (id+1)/total
end

function game:updatePalette()
	self:processTexts(self.last_text)
end

function game:processTexts(_lvl_name)
	local lvl_name = "LVL_" .. addZeros(self.level)
	
	if (_lvl_name) then
		lvl_name = _lvl_name
	end
	
	self.last_text = lvl_name
	
	self.level_texts = {}
	self.level_texts_shadows = {}
	self.level_texts_shadows2 = {} -- For ending cutscene, ain't got time for pretty code anymore
	for idx, texts in ipairs{self.level_texts, self.level_texts_shadows, self.level_texts_shadows2} do
		local txt_arr = getText(lvl_name)
		table.insert(texts, {})
		
		for _, line in ipairs(txt_arr) do
			if (line == "-") then
				table.insert(texts, {})
			else
				local txt = {}
				
				local cur = 1
				if (string.sub(line, 1, 1) == "[") then
					cur = 2
				end
				for str in string.gmatch(line, "([^%[%]]+)") do
					table.insert(txt, colors[ (idx == 1 and cur or (idx == 2 and 5-cur or 4) ) ])
					table.insert(txt, string.upper(str))
					cur = 3-cur
				end
				table.insert(texts[#texts], txt)
			end
		end
	end
end

function game:playerMoved()
	if (self.level == 3 and self.level_special_texts["LVL_03_TURN"] == false) then
		if ((self.player.x == 4 and self.player.y == 2) or (self.player.x == 3 and self.player.y == 3)) then
			self.turnTutorial = self.turnTutorial + 1
			if (self.turnTutorial >= 4) then
				game.level_special_texts["LVL_03_TURN"] = true
				game.current_text = 1
				game:processTexts("LVL_03_TURN")
			end
		end
	end
end

function game:restart()
	sounds.restart:play()
	self:load(self.level)
end

function game:checkGhosts()
	self:updateLightMap()
	-- We DON'T update ghosts when taking photos. PLEASE!!
	-- self:updateGhosts()
	
	local allGhostsLit = true
	for i, v in ipairs(self.ghosts) do
		if (v.state == "quantum" or (v.state == "on" and self.light_map[v.x][v.y].level ~= 1) or (v.x == self.player.x and v.y == self.player.y)) then
			allGhostsLit = false
			break
		end
	end
	
	if (not allGhostsLit) then
		if (self.level == 1 and self.level_special_texts["LVL_01_FRAME"] == false) then
			self.player.post_photo_callback = function()
				game.level_special_texts["LVL_01_FRAME"] = true
				game.current_text = 1
				game:processTexts("LVL_01_FRAME")
			end
		elseif (self.level == 2 and self.level_special_texts["LVL_02_QUANTUM"] == false) then
			for i, v in ipairs(self.ghosts) do
				if (v.state == "off" and self.light_map[v.x][v.y].level == 1 and not (v.x == self.player.x and v.y == self.player.y)) then
					-- Fake ghost was photographed
					self.player.post_photo_callback = function()
						game.level_special_texts["LVL_02_QUANTUM"] = true
						game.current_text = 1
						game:processTexts("LVL_02_QUANTUM")
					end
					break
				end
			end
		elseif (self.level == 5 and self.level_special_texts["LVL_05_TOGETHER"] == false) then
			local _has_yes, _has_no = false, false
			for i, v in ipairs(self.ghosts) do
				if (v.state == "on" and self.light_map[v.x][v.y].level == 1) then
					-- One of the ghosts was photographed
					_has_yes = true
				elseif (v.state == "quantum") then
					_has_no = true
				elseif (v.state == "on" and (self.light_map[v.x][v.y].level ~= 1 or (v.x == self.player.x and v.y == self.player.y) )) then
					_has_no = true
				end
			end
			if (_has_yes and _has_no) then
				self.player.post_photo_callback = function()
					game.level_special_texts["LVL_05_TOGETHER"] = true
					game.current_text = 1
					game:processTexts("LVL_05_TOGETHER")
				end
			end
		end
	else
		-- SUCCESS
		self.player.post_photo_callback = function()
			sounds.game_song:stop()
			sounds.start:play()
			self.ghosts = {}
			hold(1.5, function()
				if (self.level == 10) then
					game.game_over = true
					game.level_special_texts["LVL_10_END"] = true
					game.current_text = 1
					game:processTexts("LVL_10_END")
				else
					loadState("game", self.level + 1)
				end
			end)
		end
	end
end

return game
