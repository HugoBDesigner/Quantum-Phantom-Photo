sprite = {}

function sprite.new(path, total_frames, frame_duration)
	total_frames = total_frames or 1
	frame_duration = frame_duration or 0
	
	local spr = {}
	spr.img_base = love.image.newImageData(path)
	spr.img_width = spr.img_base:getWidth()
	spr.img_height = spr.img_base:getHeight()
	
	spr.img_layers = {}
	
	for i = 1, 4 do
		local img_data = love.image.newImageData(path)
		img_data:mapPixel(function(x, y, r, g, b, a)
			if (a < 0.5) then
				return 1, 1, 1, 0
			end
			
			local avg = math.min(0.9999, math.max(0.0001, (r + g + b) / 3))
			local idx = 3 - math.floor(avg * 4);
			
			if (idx == i-1) then
				return 1, 1, 1, 1
			end
			return 1, 1, 1, 0
		end)
		
		spr.img_layers[i] = love.graphics.newImage(img_data)
	end
	
	spr.frame_timer = 0
	spr.frame = 1
	spr.total_frames = total_frames
	spr.frame_duration = frame_duration
	
	if (total_frames == 1 or frame_duration == 0) then
		spr.update = nil
	else
		spr.update = function(self, dt)
			self.frame_timer = self.frame_timer + dt
			if (self.frame_timer >= self.frame_duration) then
				self.frame_timer = self.frame_timer - self.frame_duration
				self.frame = self.frame + 1
				if (self.frame > self.total_frames) then
					self.frame = 1
				end
			end
		end
	end
	
	spr.quads = {}
	
	local ww = math.floor(spr.img_width / total_frames)
	local hh = spr.img_height
	for i = 1, total_frames do
		spr.quads[i] = love.graphics.newQuad( (i-1)*ww, 0, ww, hh, spr.img_width, spr.img_height)
	end
	
	spr.draw = function(self, x, y, palette, frame, ignoreTransform)
		palette = palette or {1, 2, 3, 4}
		while (#palette < 4) do
			palette[#palette + 1] = palette[#palette]
		end
		
		local tx, ty = x, y
		if (not ignoreTransform) then
			tx, ty = game.off_x + tx * game.tile_size, game.off_y + ty * game.tile_size
		end
		
		local frame = frame or self.frame
		for i = 1, 4 do
			love.graphics.setColor( colors[ palette[i] ] )
			love.graphics.draw(self.img_layers[i], self.quads[frame], tx, ty)
		end
	end
	
	return spr
end

return sprite
