menu = {}

function menu:load(_selection)
	self.selection = 2
	self.options = {
		{text = "Continue game", disabled = true},
		{text = "New game"},
		{text = "Options_MENU"},
		{text = "Credits_MENU"},
		{text = "Quit"},
	}
	
	if (latest_level > 1) then
		self.selection = 1
		self.options[1].disabled = false
	end
	
	if (_selection) then
		self.selection = _selection
	end
end

function menu:draw()
	-- Title image
	sprites.title_menu:draw(math.floor(game_width/2 - sprites.title_menu.img_width/2), 6 + math.sin(oscilator/2)/2+.5, nil, nil, true)
	
	local margin = 8
	local line_yy = 60
	love.graphics.setColor(colors[3])
	
	-- Version number
	love.graphics.setFont(version_font)
	-- Here we use the original love.graphics.print because the version string should NOT be changed
	_lg_printf("v" .. VERSION, margin + 1, line_yy - 6, game_width - 2*margin, "right" )
	
	-- Divider line
	love.graphics.rectangle("fill", margin, line_yy, game_width - 2*margin, 1)
	
	love.graphics.setFont(pixel_font)
	
	local hh = 14
	local margin_left = 20
	local margin_bottom = -10
	
	for i, v in ipairs(self.options) do
		if (v.disabled) then
			love.graphics.setColor(colors[3])
			love.graphics.print(v.text, 1 + margin_left, game_height - margin_bottom - hh - #self.options * hh + (i-1)*hh + 1)
			love.graphics.print(v.text, 1 + margin_left + 1, game_height - margin_bottom - hh - #self.options * hh + (i-1)*hh)
			love.graphics.print(v.text, 1 + margin_left, game_height - margin_bottom - hh - #self.options * hh + (i-1)*hh - 1)
			love.graphics.print(v.text, 1 + margin_left - 1, game_height - margin_bottom - hh - #self.options * hh + (i-1)*hh)
			love.graphics.setColor(colors[4])
			love.graphics.print(v.text, 1 + margin_left, game_height - margin_bottom - hh - #self.options * hh + (i-1)*hh)
		else
			local txt = getText(v.text)
			if (self.selection == i) then
				txt = "> " .. txt
			end
			love.graphics.setColor(colors[3])
			love.graphics.print(txt, margin_left, game_height - margin_bottom - hh - #self.options * hh + (i-1)*hh + 1)
			love.graphics.setColor(colors[1])
			love.graphics.print(txt, margin_left, game_height - margin_bottom - hh - #self.options * hh + (i-1)*hh)
		end
	end
	
	drawForward()
end

function menu:button_pressed(button)
	if (button == "start" or button == "select" or button == "a") then
		if (self.selection == 1) then -- Continue game
			sounds.enter:play()
			hold(.25, function() loadState("game", latest_level) end)
		elseif (self.selection == 2) then -- New game
			sounds.enter:play()
			hold(.25, function()
				latest_level = 1
				saveData()
				loadState("game")
			end)
		elseif (self.selection == 3) then -- Options (Frums ♥)
			sounds.enter:play()
			hold(.25, function() loadState("options") end)
		elseif (self.selection == 4) then -- Credits (Frums ♥)
			sounds.enter:play()
			hold(.25, function() loadState("credits") end)
		elseif (self.selection == 5) then -- Quit
			sounds.enter:play()
			hold(0.75, function() loadState("splash") end)
		end
	end
end

function menu:dpad_pressed(dir)
	if (dir == "up") then
		self.selection = self.selection - 1
		if (self.selection == 0 or (self.selection == 1 and self.options[1].disabled) ) then
			self.selection = #self.options
		end
		sounds.select:play()
	elseif (dir == "down") then
		self.selection = self.selection + 1
		if (self.selection > #self.options) then
			self.selection = 1
			if (self.options[1].disabled) then
				self.selection = 2
			end
		end
		sounds.select:play()
	end
end

return menu
