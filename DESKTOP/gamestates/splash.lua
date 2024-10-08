splash = {}

function splash:load()
	toggle_releasedb()
	
	self.flashing = {false, 0, .5, 2} -- {Is flashing, flashing timer, flashing total time, number of flashes}
	hold(0.5, function()
		sounds.title_song:play()
	end)
end

function splash:update(dt)
	if (self.flashing[1]) then
		self.flashing[2] = self.flashing[2] + dt
		
		if (self.flashing[2] >= self.flashing[3]) then
			cancel_hold()
			loadState("menu")
		end
	end
end

function splash:draw()
	sprites.title:draw(0, math.sin(oscilator), nil, nil, true)
	-- love.graphics.draw(sprites.title, 0, math.sin(love.timer.getTime()))
	
	local font = love.graphics.getFont()
	local text = "PRESS START"
	
	if (math.sin(oscilator) < .8 or self.flashing[1]) then
		love.graphics.setColor(colors[3])
		love.graphics.print(text, game_width/2 - font:getWidth(text)/2, game_height - 16 + 1)
	
		love.graphics.setColor(colors[1])
		if (self.flashing[1]) then
			local flash = math.floor(self.flashing[2]/self.flashing[3] * self.flashing[4] * 2)
			
			if (flash % 2 == 0) then
				love.graphics.setColor(colors[2])
				love.graphics.rectangle("fill", 0, 0, game_width, game_height)
				love.graphics.setColor(colors[4])
			end
		end
		love.graphics.print(text, game_width/2 - font:getWidth(text)/2, game_height - 16)
	end
end

function splash:button_pressed(button)
	if (button == "select" or button == "start" or button == "a") then
		if (not self.flashing[1]) then
			cancel_hold()
			self.flashing[1] = true
			sounds.title_song:stop()
			sounds.start:play()
		end
	end
end

return splash
