options = {}

function options:load(_in_game)
	self.options = {}
	self.options_shadow = {}
	self.pause_options = {}
	self.selected = 1
	self.in_game = false
	if (_in_game) then
		self.in_game = true
	end
	self:processTexts()
end

function options:draw()
	love.graphics.setColor(1, 1, 1, 1)
	
	local xx, yy = 4, 4
	local str = (self.in_game and "PAUSE" or "OPTIONS")
	love.graphics.printf({colors[3], str}, xx, yy + 1, game_width, "center")
	love.graphics.printf({colors[1], str}, xx, yy, game_width, "center")
	
	local hh = 14
	local gap = 4
	xx = game_width/2 - 25
	yy = yy + 1.5*hh
	for i = 1, #self.options/2 do
		local i1 = (i-1)*2+1
		local i2 = i1+1
		
		love.graphics.printf(self.options_shadow[i1], 0, yy + 1, xx - gap/2, "right")
		love.graphics.printf(self.options_shadow[i2], xx + gap/2, yy + 1, game_width-xx, "left")
		
		love.graphics.printf(self.options[i1], 0, yy, xx - gap/2, "right")
		love.graphics.printf(self.options[i2], xx + gap/2, yy, game_width-xx, "left")
		
		yy = yy + hh
	end
	
	xx = xx - gap/2 - pixel_font:getWidth("MUSIC:")
	for i, v in ipairs(self.pause_options) do
		love.graphics.printf(v, xx, yy, game_width-xx, "left")
		
		yy = yy + hh
	end
	
	drawBackward()
end

function options:processTexts()
	self.options = {}
	self.options_shadow = {}
	self.pause_options = {}
	for idx, tab in ipairs{"options", "options_shadow"} do
		local primary = (idx == 1 and colors[1] or colors[4])
		local secondary = (idx == 1 and colors[2] or colors[3])
		self[tab] = {
			{primary, "MUSIC:"}, {secondary, (self.selected == 1 and "> " or "") .. (music_enabled and "ON" or "OFF")},
			{primary, "  SFX:"}, {secondary, (self.selected == 2 and "> " or "") .. (sfx_enabled and "ON" or "OFF")},
		}
	end
	if (self.in_game) then
		self.pause_options = {
			{colors[1], (self.selected == 3 and "> " or "") .. "RETURN TO GAME"},
			{colors[1], (self.selected == 4 and "> " or "") .. "RETURN TO MENU"},
		}
	end
end

function options:dpad_pressed(dir)
	if (dir == "up") then
		self.selected = self.selected - 1
		if ( self.selected < 1 ) then
			self.selected = (#self.options/2 + #self.pause_options)
		end
		self:processTexts()
		sounds.select:play()
	elseif (dir == "down") then
		self.selected = self.selected + 1
		if ( self.selected > (#self.options/2 + #self.pause_options) ) then
			self.selected = 1
		end
		self:processTexts()
		sounds.select:play()
	elseif (dir == "left" or dir == "right") then
		if (self.selected == 1 or self.selected == 2) then
			if (self.selected == 1) then
				music_enabled = not music_enabled
			elseif (self.selected == 2) then
				sfx_enabled = not sfx_enabled
			end
			updateVolume()
			saveData()
			sounds.enter:play()
			self:processTexts()
		end
	end
end

function options:button_pressed(button)
	if (button == "a" or button == "select") then
		if (self.selected == 1 or self.selected == 2) then
			if (self.selected == 1) then
				music_enabled = not music_enabled
			elseif (self.selected == 2) then
				sfx_enabled = not sfx_enabled
			end
			updateVolume()
			saveData()
			sounds.enter:play()
			self:processTexts()
		elseif (self.selected == 3) then
			self:goToGame()
		elseif (self.selected == 4) then
			self:goToMenu()
		end
	elseif (button == "b" and not self.in_game) then
		self:goToMenu()
	elseif (self.in_game and (button == "b" or button == "start")) then
		self:goToGame()
	end
end

function options:goToMenu()
	sounds.game_song:stop()
	sounds.back:play()
	hold(.25, function() loadState("menu", ((not self.in_game) and 3 or nil)) end)
end

function options:goToGame()
	sounds.pause:play()
	hold(.05, function() state = game end) -- NOT LOADSTATE!! We want to keep the game's data intact, since it's still "running"
end

function options:updatePalette()
	self:processTexts()
end

return options
