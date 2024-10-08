credits = {}

function credits:load()
	self.credits = {}
	self.credits_shadow = {}
	self:processTexts()
end

function credits:draw()
	love.graphics.setColor(1, 1, 1, 1)
	
	local xx, yy = 4, 4
	love.graphics.printf({colors[3], "CREDITS"}, xx, yy + 1, game_width, "center")
	love.graphics.printf({colors[1], "CREDITS"}, xx, yy, game_width, "center")
	
	local hh = 14
	local gap = 4
	xx = game_width/2 - 25
	yy = yy + 1.25*hh
	for i = 1, #self.credits/2 do
		local i1 = (i-1)*2+1
		local i2 = i1+1
		
		if (i == 1) then
			love.graphics.printf(self.credits_shadow[i1], 0, yy + 1, game_width, "center")
			love.graphics.printf(self.credits[i1], 0, yy, game_width, "center")
			yy = yy + hh*1.5
			love.graphics.printf(self.credits_shadow[i2], 0, yy + 1, game_width, "center")
			love.graphics.printf(self.credits[i2], 0, yy, game_width, "center")
			yy = yy + hh
		else
			love.graphics.printf(self.credits_shadow[i1], 0, yy + 1, xx - gap/2, "right")
			love.graphics.printf(self.credits[i1], 0, yy, xx - gap/2, "right")
			love.graphics.printf(self.credits_shadow[i2], xx + gap/2, yy + 1, game_width-xx, "left")
			love.graphics.printf(self.credits[i2], xx + gap/2, yy, game_width-xx, "left")
		end
		yy = yy + hh
	end
	
	drawBackward()
end

function credits:processTexts()
	self.credits = {}
	self.credits_shadow = {}
	for idx, tab in ipairs{"credits", "credits_shadow"} do
		local primary = (idx == 1 and colors[1] or colors[4])
		local secondary = (idx == 1 and colors[2] or colors[3])
		self[tab] = {
			{primary, "GAME DESIGN, ART, MUSIC, PIXEL FONT:"}, {secondary, "HUGOBDESIGNER"},
			{primary, "   SFX:"}, {secondary, "PUZZLESCRIPT"},
			{primary, " USING:"}, {secondary, "LOVE2D"},
		}
		
		if (love.system.getOS() == "Web") then
			table.insert(self[tab], {primary, "       "})
			table.insert(self[tab], {secondary, "LOVE.JS"})
			table.insert(self[tab], {primary, "       "})
			table.insert(self[tab], {secondary, "LOVE WEB BUILDER"})
		end
	end
end

function credits:button_pressed(button)
	if (button == "b") then
		sounds.back:play()
		hold(.25, function() loadState("menu", 4) end)
	end
end

function credits:updatePalette()
	self:processTexts()
end

return credits
