VERSION = "1.0.2"

json = require("json")
sprite = require("sprite")
-- require("js")

sprites = {}

function love.load()
	IS_WEB = (love.system.getOS() == "Web")
	
	-- These exist for mobile mainly (desktop MAY benefit though)
	display_x = 0
	display_y = 0
	
	game_width = 160
	game_height = 144
	scale = 4
	base_scale = 4
	love.graphics.setDefaultFilter("nearest", "nearest")
	screen_canvas = love.graphics.newCanvas(game_width, game_height)
	
	-- SAVE DATA
	save_data = {
		latest_level = 1,
		grid_opacity = 10,
		volume = 50,
		game_palette = 1,
		casing_palette = 3,
		music_enabled = true,
		sfx_enabled = true,
		b_toggle = true,
		current_language = "EN_US",
		is_fullscreen = (IS_WEB),
	}
	-- INFO: is_fullscreen being IS_WEB is purely to assist with resolution. When running web, it is *never* set to fullscreen in-game. Only externally.
	
	SAVE_PATH = "quantum_save.json"
	for i, v in pairs(save_data) do
		_G[i] = v
	end
	
	oscilator = 0
	hold_timer = {
		timer = 0,
		callback = nil
	}
	mouse_bheld = false
	
	languages = {"EN_US", "PT_BR"}
	
	sounds = {
		title_song = {source = love.audio.newSource("audio/title_song.ogg", "static"), is_music = true, volume = 0.5},
		game_song = {source = love.audio.newSource("audio/game_song.ogg", "static"), is_music = true, volume = 0.25},
		pause = {source = love.audio.newSource("audio/pause.ogg", "static")},
		flash = {source = love.audio.newSource("audio/flash.ogg", "static")},
		select = {source = love.audio.newSource("audio/select.ogg", "static")},
		enter = {source = love.audio.newSource("audio/enter.ogg", "static")},
		back = {source = love.audio.newSource("audio/back.ogg", "static")},
		start = {source = love.audio.newSource("audio/start.ogg", "static")},
		step = {source = love.audio.newSource("audio/step.ogg", "static")},
		restart = {source = love.audio.newSource("audio/restart.ogg", "static")},
	}
	
	for i, v in pairs(sounds) do
		if (v.volume) then
			v.source:setVolume(v.volume)
		else
			v.volume = 1
		end
		if (v.is_music) then
			v.source:setLooping(true)
		end
		v.stop = function(self)
			love.audio.stop(self.source)
		end
		v.play = function(self)
			if ( (not self.is_music and not sfx_enabled) ) then
				self:stop()
				return
			end
			if (volume > 0 or self.is_music) then
				love.audio.play(self.source)
			end
		end
	end
	
	palettes = {
		{ 0xE5E9E8, 0x6ED18A, 0x5D5FC6, 0x110311 },
		{ 0xE0FFF9, 0xF4D38B, 0xF763A3, 0x160E1E },
		{ 0xFFFFFF, 0xC4B0B7, 0x70618C, 0x000000 },
		{ 0xFFFFFF, 0xB0EA72, 0xD34758, 0x1E2813 },
		{ 0xFFFFFF, 0xD1EA9F, 0x71AE8C, 0x545E7F },
		{ 0xE4F4F4, 0xA7C9F7, 0x857BF7, 0x302959 },
		{ 0xE5EADC, 0x56D399, 0x477791, 0x25204C },
		{ 0xFFFFFF, 0x7CD9F8, 0xDB51CD, 0x000000 },
		{ 0xD7F7E2, 0xF2DA43, 0xFF7566, 0x172A49 },
	}
	
	-- Sadly, Love2D doesn't work with hex/dec colors. So I convert them here
	for i, v in ipairs(palettes) do
		for j, w in ipairs(v) do
			palettes[i][j] = dec_to_rgb(w)
		end
	end
	
	colors = {
		{1, 1, 1, 1},
		{2/3, 2/3, 2/3, 1},
		{1/3, 1/3, 1/3, 1},
		{0, 0, 0, 1}
	}
	
	pixel_font = love.graphics.newImageFont( "sprites/font_px.png", "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ.:;/,'\"-_<>* !?{}%&ÃÁÀÂÄÇÉÈÊËÍÌÎÏÑÕÓÒÔÖÚÙÛÜÝ", 1 )
	version_font = love.graphics.newImageFont( "sprites/font_ver.png", "v.0123456789", 1 )
	
	love.graphics.setFont(pixel_font)
	
	window_width = 320
	window_height = 180
	
	menu_right = {
		hover_timer = {0, .5, 1, active = false},
		state = "closed",
		progress = {0, 1},
	}
	menu_left = {
		hover_timer = {0, .5, 1, active = false},
		state = "closed",
		progress = {0, 1},
	}
	
	love.graphics.setDefaultFilter("linear", "linear")
	casing = {
		casing = love.graphics.newImage("casing/casing.png"),
		casing_left = love.graphics.newImage("casing/casing_left.png"),
		casing_left_backdrop = love.graphics.newImage("casing/casing_left_backdrop.png"),
		casing_right = love.graphics.newImage("casing/casing_right.png"),
		casing_right_backdrop = love.graphics.newImage("casing/casing_right_backdrop.png"),
		
		glare_left = love.graphics.newImage("casing/glare_left.png"),
		glare_right = love.graphics.newImage("casing/glare_right.png"),
		arrow_left = love.graphics.newImage("casing/arrow_left.png"),
		arrow_right = love.graphics.newImage("casing/arrow_right.png"),
		
		knob_main = love.graphics.newImage("casing/knob_main.png"),
		knob_side = love.graphics.newImage("casing/knob_side.png"),
		knob_center = love.graphics.newImage("casing/knob_center.png"),
		knob_bit = love.graphics.newImage("casing/knob_bit.png"),
		
		backdrop = love.graphics.newImage("casing/backdrop.png"),
		dpad = {
			unpressed = love.graphics.newImage("casing/dpad.png"),
			pressed_up = love.graphics.newImage("casing/dpad_pressed_up.png"),
			pressed_down = love.graphics.newImage("casing/dpad_pressed_down.png"),
			pressed_left = love.graphics.newImage("casing/dpad_pressed_left.png"),
			pressed_right = love.graphics.newImage("casing/dpad_pressed_right.png"),
		},
		buttons = {
			a_unpressed = love.graphics.newImage("casing/button_a.png"),
			a_pressed = love.graphics.newImage("casing/button_a_pressed.png"),
			b_unpressed = love.graphics.newImage("casing/button_b.png"),
			b_pressed = love.graphics.newImage("casing/button_b_pressed.png"),
			small_unpressed = love.graphics.newImage("casing/button_small.png"),
			small_pressed = love.graphics.newImage("casing/button_small_pressed.png"),
		},
		side_menu = {
			up_unpressed = love.graphics.newImage("casing/button_side_up.png"),
			up_pressed = love.graphics.newImage("casing/button_side_up_pressed.png"),
			down_unpressed = love.graphics.newImage("casing/button_side_down.png"),
			down_pressed = love.graphics.newImage("casing/button_side_down_pressed.png"),
		}
	}
	
	love.graphics.setDefaultFilter("nearest", "nearest")
	sprites.title = sprite.new("sprites/title.png")
	sprites.title_menu = sprite.new("sprites/title_menu.png")
	
	mouse_dpadpressed = nil
	mouse_buttonpressed = nil
	mouse_button_side_pressed = nil
	dpad_lastpressed = nil
	button_mapping = {
		dpad = {
			up = {125, 265, 70, 60, shape = "rectangle", pressed = false},
			down = {125, 395, 70, 60, shape = "rectangle", pressed = false},
			left = {65, 325, 60, 70, shape = "rectangle", pressed = false},
			right = {195, 325, 60, 70, shape = "rectangle", pressed = false},
		},
		buttons = {
			b = {1005, 335, 90, 90, shape = "circle", pressed = false},
			a = {1145, 295, 90, 90, shape = "circle", pressed = false},
			select = {45, 605, 40, 40, shape = "circle", pressed = false},
			start = {1005, 75, 40, 40, shape = "circle", pressed = false},
		},
		left_menu = {
			up = {52, 463, 45, 15, shape = "tri_up", pressed = false},
			down = {52, 622, 45, 15, shape = "tri_down", pressed = false},
			wheel = {35, 200, 92, 145, shape = "semicircle_left", pressed = false, y_pressed = nil, y_value = nil},
		},
		right_menu = {
			up = {53, 83, 45, 15, shape = "tri_up", pressed = false},
			down = {53, 242, 45, 15, shape = "tri_down", pressed = false},
			wheel = {24, 374, 92, 145, shape = "semicircle_right", pressed = false, y_pressed = nil, y_value = nil},
		},
	}
	
	knob_canvas = love.graphics.newCanvas(casing.knob_main:getWidth()+40, casing.knob_main:getHeight()+40)
	
	splash = require("gamestates/splash")
	menu = require("gamestates/menu")
	credits = require("gamestates/credits")
	options = require("gamestates/options")
	game = require("gamestates/game")
	
	loadData()
	setScale()
	loadState(splash)
	updatePalette()
	updateVolume()
	updateFullscreen()
	updateLanguage()
	
	testaabb = love.image.newImageData(window_width*scale, window_height*scale)
	testaabb_img = nil
end

function love.update(dt)
	dt = math.min(1/20, dt)
	oscilator = love.timer.getTime()*math.pi
	
	if (menu_right.hover_timer.active) then
		menu_right.hover_timer[1] = math.min(menu_right.hover_timer[1] + dt, menu_right.hover_timer[3])
	else
		menu_right.hover_timer[1] = 0
	end
	
	if (menu_left.hover_timer.active) then
		menu_left.hover_timer[1] = math.min(menu_left.hover_timer[1] + dt, menu_left.hover_timer[3])
	else
		menu_left.hover_timer[1] = 0
	end
	
	if (menu_right.state == "opening") then
		menu_right.progress[1] = menu_right.progress[1] + dt
		if (menu_right.progress[1] >= menu_right.progress[2]) then
			menu_right.progress[1] = menu_right.progress[2]
			menu_right.state = "open"
		end
	elseif (menu_right.state == "closing") then
		menu_right.progress[1] = menu_right.progress[1] - dt
		if (menu_right.progress[1] <= 0) then
			menu_right.progress[1] = 0
			menu_right.state = "closed"
		end
	elseif (menu_left.state == "opening") then
		menu_left.progress[1] = menu_left.progress[1] + dt
		if (menu_left.progress[1] >= menu_left.progress[2]) then
			menu_left.progress[1] = menu_left.progress[2]
			menu_left.state = "open"
		end
	elseif (menu_left.state == "closing") then
		menu_left.progress[1] = menu_left.progress[1] - dt
		if (menu_left.progress[1] <= 0) then
			menu_left.progress[1] = 0
			menu_left.state = "closed"
		end
	end
	
	if (hold_timer.timer > 0) then
		hold_timer.timer = hold_timer.timer - dt
		if (hold_timer.timer <= 0) then
			hold_timer.timer = 0
			if (hold_timer.callback) then
				hold_timer.callback()
				
				-- Check timer. The callback might have started ANOTHER hold
				if (hold_timer.timer == 0) then
					hold_timer.callback = nil
				end
			end
		end
		return
	end
	
	if (state.update) then state:update(dt) end
end

function updateCanvases()
	-- GETTING STATE IMAGE
	if (state.draw) then
		love.graphics.setCanvas(screen_canvas)
			love.graphics.clear()
			state:draw()
		love.graphics.setCanvas()
	end
	
	-- KNOBS
	if (menu_left.state ~= "closed" or menu_right.state ~= "closed") then
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.setCanvas(knob_canvas)
			love.graphics.clear()
			local side = (menu_right.state ~= "closed" and 1 or -1)
			local rot = 1-(menu_right.state ~= "closed" and volume or grid_opacity) / 100
			local perspective = (menu_right.state ~= "closed" and menu_right.progress[1]/menu_right.progress[2] or menu_left.progress[1]/menu_left.progress[2])
			perspective = math.floor(perspective^2 * 20)
			
			rot = (math.pi/8 + (rot * math.pi*6/8)) * side
			if (perspective > 0) then
				for x = perspective, 1, -1 do
					love.graphics.draw(casing.knob_side, knob_canvas:getWidth()/2 + x*side, knob_canvas:getHeight()/2, rot, 1, 1, casing.knob_side:getWidth()/2, casing.knob_side:getHeight()/2)
				end
			end
			love.graphics.draw(casing.knob_main, knob_canvas:getWidth()/2, knob_canvas:getHeight()/2, rot, 1, 1, casing.knob_main:getWidth()/2, casing.knob_main:getHeight()/2)
			love.graphics.draw(casing.knob_center, knob_canvas:getWidth()/2, knob_canvas:getHeight()/2, 0, 1, 1, casing.knob_center:getWidth()/2, casing.knob_center:getHeight()/2)
			
			-- It's not wrong! The bit goes from the TOP to the BOTTOM, so at angle 0 it wouldn't be at the right
			local offx = -math.sin(rot)*60*-1
			local offy = math.cos(rot)*60*-1
			love.graphics.draw(casing.knob_bit, knob_canvas:getWidth()/2 + offx, knob_canvas:getHeight()/2 + offy, 0, 1, 1, casing.knob_bit:getWidth()/2, casing.knob_bit:getHeight()/2)
		love.graphics.setCanvas()
	end
	
	-- CASING + GAME
	love.graphics.setCanvas(casing_canvas)
		love.graphics.clear()
		love.graphics.setColor( palettes[casing_palette][2] )
		love.graphics.draw(casing.casing)
		love.graphics.setColor( lighten(palettes[casing_palette][4], .1) )
		love.graphics.draw(casing.backdrop)
		
		-- BUTTONS
		love.graphics.setColor( palettes[casing_palette][3] )
		if (button_mapping.dpad.up.pressed) then
			love.graphics.draw(casing.dpad.pressed_up, button_mapping.dpad.left[1], button_mapping.dpad.up[2])
		elseif (button_mapping.dpad.down.pressed) then
			love.graphics.draw(casing.dpad.pressed_down, button_mapping.dpad.left[1], button_mapping.dpad.up[2])
		elseif (button_mapping.dpad.left.pressed) then
			love.graphics.draw(casing.dpad.pressed_left, button_mapping.dpad.left[1], button_mapping.dpad.up[2])
		elseif (button_mapping.dpad.right.pressed) then
			love.graphics.draw(casing.dpad.pressed_right, button_mapping.dpad.left[1], button_mapping.dpad.up[2])
		else
			love.graphics.draw(casing.dpad.unpressed, button_mapping.dpad.left[1], button_mapping.dpad.up[2])
		end
		
		if (button_mapping.buttons.b.pressed) then
			love.graphics.draw(casing.buttons.b_pressed, button_mapping.buttons.b[1], button_mapping.buttons.b[2])
		else
			love.graphics.draw(casing.buttons.b_unpressed, button_mapping.buttons.b[1], button_mapping.buttons.b[2])
		end
		if (button_mapping.buttons.a.pressed) then
			love.graphics.draw(casing.buttons.a_pressed, button_mapping.buttons.a[1], button_mapping.buttons.a[2])
		else
			love.graphics.draw(casing.buttons.a_unpressed, button_mapping.buttons.a[1], button_mapping.buttons.a[2])
		end
		if (button_mapping.buttons.select.pressed) then
			love.graphics.draw(casing.buttons.small_pressed, button_mapping.buttons.select[1], button_mapping.buttons.select[2])
		else
			love.graphics.draw(casing.buttons.small_unpressed, button_mapping.buttons.select[1], button_mapping.buttons.select[2])
		end
		if (button_mapping.buttons.start.pressed) then
			love.graphics.draw(casing.buttons.small_pressed, button_mapping.buttons.start[1], button_mapping.buttons.start[2])
		else
			love.graphics.draw(casing.buttons.small_unpressed, button_mapping.buttons.start[1], button_mapping.buttons.start[2])
		end
	love.graphics.setCanvas()
	
	-- SIDE MENUS
	local r_prog = 0
	local l_prog = 0
	
	-- RIGHT SIDE MENU (VOLUME, CASING PALETTE)
	if (menu_right.state ~= "closed") then
		r_prog = (menu_right.progress[1] / menu_right.progress[2])^2
		
		love.graphics.setCanvas(side_menu_canvas)
			love.graphics.clear()
			love.graphics.setColor( palettes[casing_palette][2] )
			love.graphics.draw(casing.casing_right)
			love.graphics.setColor( lighten(palettes[casing_palette][4], .1) )
			love.graphics.draw(casing.casing_right_backdrop)
			
			-- BUTTONS
			love.graphics.setColor( palettes[casing_palette][1] )
			if (button_mapping.right_menu.up.pressed) then
				love.graphics.draw(casing.side_menu.up_pressed, button_mapping.right_menu.up[1], button_mapping.right_menu.up[2])
			else
				love.graphics.draw(casing.side_menu.up_unpressed, button_mapping.right_menu.up[1], button_mapping.right_menu.up[2])
			end
			if (button_mapping.right_menu.down.pressed) then
				love.graphics.draw(casing.side_menu.down_pressed, button_mapping.right_menu.down[1], button_mapping.right_menu.down[2])
			else
				love.graphics.draw(casing.side_menu.down_unpressed, button_mapping.right_menu.down[1], button_mapping.right_menu.down[2])
			end
			
			-- PALETTE DISPLAY
			paletteDisplay(casing_palette, 26, 120, 100, 100)
			
			love.graphics.setColor( palettes[casing_palette][1] )
			local knob_x, knob_y = 20, 355
			local knob_x_scale = (1-r_prog)*3
			local knob_x_off = knob_x_scale*(knob_canvas:getWidth() * .5)
			love.graphics.setScissor(knob_x + 50, knob_y, 80, knob_canvas:getHeight())
			love.graphics.draw(knob_canvas, knob_x - knob_x_off, knob_y, 0, 0.5 + knob_x_scale, 1)
			love.graphics.setScissor()
		love.graphics.setCanvas()
	end
	
	-- LEFT SIDE MENU (GRID, GAME PALETTE)
	if (menu_left.state ~= "closed") then
		l_prog = (menu_left.progress[1] / menu_left.progress[2])^2
		
		love.graphics.setCanvas(side_menu_canvas)
			love.graphics.clear()
			love.graphics.setColor( palettes[casing_palette][2] )
			love.graphics.draw(casing.casing_left)
			love.graphics.setColor( lighten(palettes[casing_palette][4], .1) )
			love.graphics.draw(casing.casing_left_backdrop)
			
			-- BUTTONS
			love.graphics.setColor( palettes[casing_palette][1] )
			if (button_mapping.left_menu.up.pressed) then
				love.graphics.draw(casing.side_menu.up_pressed, button_mapping.left_menu.up[1], button_mapping.left_menu.up[2])
			else
				love.graphics.draw(casing.side_menu.up_unpressed, button_mapping.left_menu.up[1], button_mapping.left_menu.up[2])
			end
			if (button_mapping.left_menu.down.pressed) then
				love.graphics.draw(casing.side_menu.down_pressed, button_mapping.left_menu.down[1], button_mapping.left_menu.down[2])
			else
				love.graphics.draw(casing.side_menu.down_unpressed, button_mapping.left_menu.down[1], button_mapping.left_menu.down[2])
			end
			
			-- PALETTE DISPLAY
			paletteDisplay(game_palette, 25, 500, 100, 100)
			
			love.graphics.setColor( palettes[casing_palette][1] )
			local knob_x, knob_y = 35, 180
			local knob_x_scale = (1-l_prog)*3
			local knob_x_off = knob_x_scale*(knob_canvas:getWidth() * .5)
			love.graphics.setScissor(0, knob_y, 80, knob_canvas:getHeight())
			love.graphics.draw(knob_canvas, knob_x - knob_x_off, knob_y, 0, 0.5 + knob_x_scale, 1)
			love.graphics.setScissor()
		love.graphics.setCanvas()
	end
end

function love.draw()
	updateCanvases()
	
	love.graphics.push()
	love.graphics.translate(display_x, display_y)
	
	-- SIDE MENUS
	local casing_x = 0
	local casing_x_scale = 1
	local r_prog = 0
	local l_prog = 0
	
	if (menu_right.state ~= "closed") then
		r_prog = (menu_right.progress[1] / menu_right.progress[2])^2
		casing_x_scale = (window_width-(150/base_scale)*r_prog)/window_width
		
		local c = 0.5 + (0.5 * r_prog)
		love.graphics.setColor(c, c, c, 1)
		love.graphics.draw(side_menu_canvas, window_width*scale-(150/base_scale)*scale*r_prog, 0, 0, scale/base_scale*r_prog, scale/base_scale)
	end
	
	if (menu_left.state ~= "closed") then
		l_prog = (menu_left.progress[1] / menu_left.progress[2])^2
		casing_x_scale = (window_width-(150/base_scale)*l_prog)/window_width
		casing_x = (150/base_scale)*scale*l_prog
		
		local c = 0.5 + (0.5 * l_prog)
		love.graphics.setColor(c, c, c, 1)
		love.graphics.draw(side_menu_canvas, 0, 0, 0, scale/base_scale*l_prog, scale/base_scale)
	end
	
	-- Draws actual casing, with side menu scaling
	if (r_prog + l_prog > 0) then
		local c = (r_prog + l_prog) * .2
		love.graphics.setColor(1 - c, 1 - c, 1 - c, 1)
	else
		love.graphics.setColor(1, 1, 1, 1)
	end
	love.graphics.draw(casing_canvas, casing_x, 0, 0, casing_x_scale*scale/base_scale, scale/base_scale)
	
	love.graphics.push()
		local screen_x = (window_width-game_width)/2 * casing_x_scale * scale + casing_x
		love.graphics.translate(screen_x, (window_height-game_height)/2 * scale)
		
		-- BACKGROUND
		love.graphics.setColor(colors[4])
		love.graphics.rectangle("fill", 0, 0, screen_canvas:getWidth() * casing_x_scale*scale, screen_canvas:getHeight() * scale)
		
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.draw(screen_canvas, 0, 0, 0, casing_x_scale*scale, scale)
	
		if (grid_opacity > 0) then
			love.graphics.setBlendMode("add", "premultiplied")
			overlayPos(casing_x_scale)
			love.graphics.setBlendMode("multiply", "premultiplied")
			overlayNeg(casing_x_scale)
			love.graphics.setBlendMode("alpha", "alphamultiply")
		end
	love.graphics.pop()
	
	-- HOVER ARROWS
	if (r_prog + l_prog == 0) then
		if (menu_right.hover_timer.active and menu_right.hover_timer[1] >= menu_right.hover_timer[2]) then
			local alpha = (menu_right.hover_timer[1] - menu_right.hover_timer[2]) / (menu_right.hover_timer[3] - menu_right.hover_timer[2])
			love.graphics.setColor(palettes[casing_palette][2][1], palettes[casing_palette][2][2], palettes[casing_palette][2][3], alpha)
			
			love.graphics.draw(casing.arrow_right, window_width*scale - (4+73)/base_scale*scale, window_height*scale - (4+72)/base_scale*scale, 0, scale/base_scale, scale/base_scale)
		end
		if (menu_left.hover_timer.active and menu_left.hover_timer[1] >= menu_left.hover_timer[2]) then
			local alpha = (menu_left.hover_timer[1] - menu_left.hover_timer[2]) / (menu_left.hover_timer[3] - menu_left.hover_timer[2])
			love.graphics.setColor(palettes[casing_palette][2][1], palettes[casing_palette][2][2], palettes[casing_palette][2][3], alpha)
			
			love.graphics.draw(casing.arrow_left, 4/base_scale*scale, 4/base_scale*scale, 0, scale/base_scale, scale/base_scale)
		end
	end
	
	-- Adds glare to side menus
	if (r_prog + l_prog > 0) then
		love.graphics.setColor(1, 1, 1, .2 * (r_prog + l_prog))
		for _ = 0, 1 do
			if (r_prog > 0) then
				love.graphics.draw(casing.glare_right, 0, 0, 0, casing_x_scale*scale/base_scale, scale/base_scale)
			end
			
			if (l_prog > 0) then
				love.graphics.draw(casing.glare_left, casing_x, 0, 0, casing_x_scale*scale/base_scale, scale/base_scale)
			end
			
			love.graphics.setBlendMode("add", "premultiplied")
			love.graphics.setColor(.2 * (r_prog + l_prog), .2 * (r_prog + l_prog), .2 * (r_prog + l_prog), 1)
		end
		love.graphics.setBlendMode("alpha", "alphamultiply")
	end
	
	if (testaabb_img) then
		love.graphics.setColor(1, 0.5, 0.5, 0.8)
		love.graphics.draw(testaabb_img)
	end
	
	if (DEBUG_PRINTER and DEBUG_PRINTER ~= "") then
		local txt = string.upper(DEBUG_PRINTER)
		local margin = 2
		love.graphics.setColor(0, 0, 0, 1)
		love.graphics.rectangle("fill", 0, 0, love.graphics.getFont():getWidth(txt) + 2*margin, love.graphics.getFont():getHeight() + 2*margin)
		
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.print(txt, margin, margin + 3)
	end
	
	love.graphics.pop()
end

function dpad_pressed(dir)
	if (hold_timer.timer > 0) then return end
	
	if (dpad_lastpressed) then
		dpad_released(dpad_lastpressed)
	end
	dpad_lastpressed = dir
	
	if (menu_left.state ~= "closed" or menu_right.state ~= "closed") then
		if (dir == "up") then
			button_side_pressed("up")
		elseif (dir == "down") then
			button_side_pressed("down")
		elseif (dir == "left") then
			button_side_pressed("wheel_down")
		elseif (dir == "right") then
			button_side_pressed("wheel_up")
		end
		
		return
	end
	
	if (button_mapping.dpad[dir].pressed) then return end
	
	button_mapping.dpad[dir].pressed = true
	if (state.dpad_pressed) then state:dpad_pressed(dir) end
end

function dpad_released(dir)
	if (menu_left.state ~= "closed" or menu_right.state ~= "closed") then
		if (dir == "up") then
			button_side_released("up")
		elseif (dir == "down") then
			button_side_released("down")
		elseif (dir == "left") then
			button_side_released("wheel_down")
		elseif (dir == "right") then
			button_side_released("wheel_up")
		end
	end
	
	if (not button_mapping.dpad[dir].pressed) then return end
	
	dpad_lastpressed = nil
	
	button_mapping.dpad[dir].pressed = false
	if (state.dpad_released) then state:dpad_released(dir) end
end

function dpad_isDown(dir)
	return button_mapping.dpad[dir].pressed
end

function button_pressed(button)
	if (menu_left.state ~= "closed" or menu_right.state ~= "closed") then return end
	if (hold_timer.timer > 0) then return end
	if (button_mapping.buttons[button].pressed) then return end
	
	if (button ~= "b") then
		toggle_releasedb()
	end
	
	button_mapping.buttons[button].pressed = true
	if (state.button_pressed) then state:button_pressed(button) end
end

function button_released(button)
	if (not button_mapping.buttons[button].pressed) then return end
	
	if (button == "b") then
		if (mouse_bheld) then -- If player held button for a while, keep it pressed
			return
		end
	end
	
	button_mapping.buttons[button].pressed = false
	if (state.button_released) then state:button_released(button) end
end

function toggle_pressedb()
	if (b_toggle) then
		if (state == game and mouse_bheld == false) then -- Double-pressing should turn it off
			mouse_bheld = true
		else
			toggle_releasedb()
		end
	end
end

function toggle_releasedb()
	if (mouse_bheld) then
		mouse_bheld = false
		button_released("b")
	end
end

function button_isDown(button)
	return button_mapping.buttons[button].pressed
end

function button_side_pressed(button)
	if (menu_left.state ~= "open" and menu_right.state ~= "open") then return end
	
	if (menu_left.state == "open") then
		if (button == "wheel_up") then
			grid_opacity = math.max(0, math.min(100, grid_opacity + 10))
			updateGrid()
			button = "wheel"
		elseif (button == "wheel_down") then
			grid_opacity = math.max(0, math.min(100, grid_opacity - 10))
			updateGrid()
			button = "wheel"
		elseif (button == "wheel") then
			local _, yy = mouseTransform(nil, love.mouse.getY())
			button_mapping.left_menu[button].y_pressed = yy
			button_mapping.left_menu[button].y_value = grid_opacity
		else
			paletteChange("game", (button == "up" and 1 or -1) )
		end
		button_mapping.left_menu[button].pressed = true
	elseif (menu_right.state == "open") then
		if (button == "wheel_up") then
			volume = math.max(0, math.min(100, volume + 10))
			updateVolume()
			button = "wheel"
		elseif (button == "wheel_down") then
			volume = math.max(0, math.min(100, volume - 10))
			updateVolume()
			button = "wheel"
		elseif (button == "wheel") then
			local _, yy = mouseTransform(nil, love.mouse.getY())
			button_mapping.right_menu[button].y_pressed = yy
			button_mapping.right_menu[button].y_value = volume
		else
			paletteChange("casing", (button == "up" and 1 or -1) )
		end
		button_mapping.right_menu[button].pressed = true
	end
end

function button_side_released(button)
	if (menu_left.state ~= "open" and menu_right.state ~= "open") then return end
	
	if (button == "wheel_up" or button == "wheel_down") then
		button = "wheel"
	end
	button_mapping.left_menu[button].pressed = false
	button_mapping.right_menu[button].pressed = false
end

function button_side_isDown(button)
	return button_mapping.left_menu[button].pressed or button_mapping.right_menu[button].pressed
end

function close_menus()
	if (menu_left.state ~= "closed") then
		menu_left.state = "closing"
	elseif (menu_right.state ~= "closed") then
		menu_right.state = "closing"
	end
end

function love.keypressed(key, scancode, isrepeat)
	local ctrlpressed = (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl"))
	local shiftpressed = (love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift"))
	local altpressed = (love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt"))
	-- DEBUG
	if (ctrlpressed) then
		if (not altpressed) then
			if (key == "f1") then
				makeTest()
			elseif (key == "f5" and not IS_WEB) then
				-- Hard reset: destroys the save file
				love.graphics.clear() -- Deliberately flash the screen to indicate the reset
				love.graphics.present()
				
				love.audio.stop()
				love.filesystem.remove(SAVE_PATH)
				love.load()
				return
			end
		else
			local kn = string.gsub(key, "kp", "")
			if (string.match(kn, "^%d$")) then
				local num = tonumber(key)
				num = (num == 0 and 10 or num)
				loadState("game", num)
			end
		end
	elseif (key == "f5" and not IS_WEB) then
		-- Soft reset: preserves the save file
		love.graphics.clear() -- Deliberately flash the screen to indicate the reset
		love.graphics.present()
		love.audio.stop()
		love.load()
		return
	elseif (key == "f11" and not IS_WEB) then
		is_fullscreen = not is_fullscreen
		if (state.processTexts) then
			state:processTexts()
		end
		saveData()
		updateFullscreen()
	end
	
	if (key == "w" or key == "up") then
		dpad_pressed("up")
	elseif (key == "s" or key == "down") then
		dpad_pressed("down")
	elseif (key == "a" or key == "left") then
		dpad_pressed("left")
	elseif (key == "d" or key == "right") then
		dpad_pressed("right")
	end
	
	-- "escape" on web is for exiting fullscreen
	if (key == "enter" or key == "return" or key == "kpenter" or (key == "escape" and not IS_WEB) ) then
		button_pressed("start")
		close_menus()
	elseif (key == "c" or key == "l") then
		button_pressed("select")
	elseif (key == "z" or key == "j" or key == "lshift" or key == "rshift" or key == "backspace") then
		button_pressed("b")
		-- toggle_pressedb()
	elseif (key == "x" or key == "k" or key == "space") then
		button_pressed("a")
	end
	
	if (key == "]" or (key == "tab" and not shiftpressed)) then
		if (menu_left.state ~= "closed" or menu_right.state ~= "closed") then
			close_menus()
		else
			menu_right.state = "opening"
		end
	elseif (key == "[" or (key == "tab" and shiftpressed)) then
		if (menu_right.state ~= "closed" or menu_left.state ~= "closed") then
			close_menus()
		else
			menu_left.state = "opening"
		end
	end
end

function love.keyreleased(key, scancode, isrepeat)
	if (key == "w" or key == "up") then
		dpad_released("up")
	elseif (key == "s" or key == "down") then
		dpad_released("down")
	elseif (key == "a" or key == "left") then
		dpad_released("left")
	elseif (key == "d" or key == "right") then
		dpad_released("right")
	end
	
	if (key == "escape" or key == "enter" or key == "return" or key == "kpenter") then
		button_released("start")
	elseif (key == "c" or key == "l") then
		button_released("select")
	elseif (key == "z" or key == "j" or key == "lshift" or key == "rshift" or key == "backspace") then
		button_released("b")
	elseif (key == "x" or key == "k" or key == "space") then
		button_released("a")
	end
end

function love.gamepadpressed(joystick, button)
	if (button == "a" or button == "y") then
		button_pressed("a")
		close_menus()
	elseif (button == "b" or button == "x") then
		button_pressed("b")
		close_menus()
	elseif (button == "start") then
		button_pressed("start")
		close_menus()
	elseif (button == "select" or button == "back") then
		button_pressed("select")
		close_menus()
	elseif (button == "leftshoulder") then
		if (menu_right.state ~= "closed" or menu_left.state ~= "closed") then
			close_menus()
		else
			menu_left.state = "opening"
		end
	elseif (button == "rightshoulder") then
		if (menu_left.state ~= "closed" or menu_right.state ~= "closed") then
			close_menus()
		else
			menu_right.state = "opening"
		end
	elseif (button == "dpleft") then
		dpad_pressed("left")
	elseif (button == "dpright") then
		dpad_pressed("right")
	elseif (button == "dpup") then
		dpad_pressed("up")
	elseif (button == "dpdown") then
		dpad_pressed("down")
	end
end

function love.gamepadreleased(joystick, button)
	if (button == "a" or button == "y") then
		button_released("a")
	elseif (button == "b" or button == "x") then
		button_released("b")
	elseif (button == "start") then
		button_released("start")
	elseif (button == "select" or button == "back") then
		button_released("select")
	elseif (button == "dpleft") then
		dpad_released("left")
	elseif (button == "dpright") then
		dpad_released("right")
	elseif (button == "dpup") then
		dpad_released("up")
	elseif (button == "dpdown") then
		dpad_released("down")
	end
end

gamepad_axis = {deadzone = 0.2}
function love.gamepadaxis(joystick, axis, value)
	local id = joystick:getID()
	
	if (not gamepad_axis[id]) then
		gamepad_axis[id] = {x = 0, y = 0, dir = false}
	end
	
	if (axis == "leftx" or axis == "lefty") then -- Ignore right stick for direction
		if (axis == "leftx") then
			gamepad_axis[id].x = value
		elseif (axis == "lefty") then
			gamepad_axis[id].y = value
		end
		
		local new_dir
		local dist = math.sqrt(gamepad_axis[id].x ^ 2 + gamepad_axis[id].y ^ 2)
		if (dist >= gamepad_axis.deadzone) then
			if (math.abs(gamepad_axis[id].x) >= math.abs(gamepad_axis[id].y)) then -- Horizontal movement
				new_dir = ( (gamepad_axis[id].x >= 0) and "right" or "left" )
			else -- Vertical movement
				new_dir = ( (gamepad_axis[id].y >= 0) and "down" or "up" )
			end
		else
			new_dir = false
		end
		
		if (new_dir ~= gamepad_axis[id].dir) then
			gamepad_axis[id].dir = new_dir
			if (new_dir) then
				-- I *could* do trig to get the angle. But realistically, we only need to check which direction is bigger
				dpad_pressed(new_dir)
			else
				if (dpad_lastpressed) then
					dpad_released(dpad_lastpressed)
				end
			end
		end
	end
end

function love.touchpressed( id, x, y, dx, dy, pressure )
	love.mousepressed(x, y, 1, false)
end

function love.touchreleased( id, x, y, dx, dy, pressure )
	love.mousereleased(x, y, 1, false)
end

function love.mousepressed(x, y, button, isTouch)
	if (isTouch) then return end
	
	if (button ~= 1) then return end
	
	x, y = mouseTransform(x, y)
	
	local mx, my = x*base_scale/scale, y*base_scale/scale
	if (menu_left.state == "closed" and menu_right.state == "closed") then
		local xx, yy = window_width*base_scale - 150, window_height*base_scale - 150
		if ( aabb(mx, my, 0, 0, 150, 150, "tri_left") ) then
			menu_left.state = "opening"
		elseif ( aabb(mx, my, xx, yy, 150, 150, "tri_right") ) then
			menu_right.state = "opening"
		end
	elseif (menu_left.state ~= "closed") then
		if ( aabb(mx, my, 150, 0, window_width*base_scale - 150, window_height*base_scale) ) then
			menu_left.state = "closing"
		elseif (menu_left.state == "open") then
			for i, v in pairs(button_mapping.left_menu) do
				if ( aabb(mx, my, v[1], v[2], v[3], v[4], v.shape) ) then
					mouse_button_side_pressed = i
					button_side_pressed(i)
				end
			end
		end
		return
	elseif (menu_right.state ~= "closed") then
		if ( aabb(mx, my, 0, 0, window_width*base_scale - 150, window_height*base_scale) ) then
			menu_right.state = "closing"
		elseif (menu_right.state == "open") then
			for i, v in pairs(button_mapping.right_menu) do
				if ( aabb(mx - (window_width*base_scale - 150), my, v[1], v[2], v[3], v[4], v.shape) ) then
					mouse_button_side_pressed = i
					button_side_pressed(i)
				end
			end
		end
		return
	end
	
	for i, v in pairs(button_mapping.dpad) do
		if ( aabb(mx, my, v[1], v[2], v[3], v[4], v.shape) ) then
			mouse_dpadpressed = i
			dpad_pressed(i)
			break
		end
	end
	
	for i, v in pairs(button_mapping.buttons) do
		if ( aabb(mx, my, v[1], v[2], v[3], v[4], v.shape) ) then
			mouse_buttonpressed = i
			button_pressed(i)
			
			if (i == "b") then
				toggle_pressedb()
			end
			break
		end
	end
end

function love.mousereleased(x, y, button, isTouch)
	if (isTouch) then return end
	if (button ~= 1) then return end
	
	x, y = mouseTransform(x, y)
	
	if (mouse_dpadpressed) then
		dpad_released(mouse_dpadpressed)
		mouse_dpadpressed = nil
	end
	
	if (mouse_buttonpressed) then
		button_released(mouse_buttonpressed)
		mouse_buttonpressed = nil
	end
	
	if (mouse_button_side_pressed) then
		button_side_released(mouse_button_side_pressed)
		mouse_button_side_pressed = nil
	end
end

function love.mousemoved(x, y, dx, dy, isTouch)
	if (isTouch) then return end
	
	x, y = mouseTransform(x, y)
	
	if (menu_right.state == "closed" and menu_left.state == "closed" and isTouch == false) then
		local margin = 1 -- TO-DO: may need to be changed for mobile
		if (x >= margin and y >= margin and x <= window_width*scale-margin and y <= window_height*scale-margin) then
			local xx, yy = window_width*scale - 150*scale/base_scale, window_height*scale - 150*scale/base_scale
			menu_left.hover_timer.active = aabb(x, y, 0, 0, 150*scale/base_scale, 150*scale/base_scale, "tri_left")
			menu_right.hover_timer.active = aabb(x, y, xx, yy, 150*scale/base_scale, 150*scale/base_scale, "tri_right")
		else
			menu_right.hover_timer.active = false
			menu_left.hover_timer.active = false
		end
	else
		menu_right.hover_timer.active = false
		menu_left.hover_timer.active = false
	end
	
	if (mouse_button_side_pressed == "wheel") then
		local min_dist = 150/base_scale*scale
		if (menu_left.state == "open") then
			local dif = math.floor((button_mapping.left_menu.wheel.y_pressed - y) / min_dist * 100)
			grid_opacity = math.max(0, math.min(100, button_mapping.left_menu.wheel.y_value + dif))
			updateGrid()
		elseif (menu_right.state == "open") then
			local dif = math.floor((button_mapping.right_menu.wheel.y_pressed - y) / min_dist * 100)
			volume = math.max(0, math.min(100, button_mapping.right_menu.wheel.y_value + dif))
			updateVolume()
		end
	end
end

function love.wheelmoved(x, y)
	if (menu_left.state ~= "closed") then
		grid_opacity = grid_opacity + 10 * (y > 0 and 1 or -1)
		if (grid_opacity <= 0) then
			grid_opacity = 0
		elseif (grid_opacity >= 100) then
			grid_opacity = 100
		end
		updateGrid()
	elseif (menu_right.state ~= "closed") then
		volume = volume + 10 * (y > 0 and 1 or -1)
		if (volume <= 0) then
			volume = 0
		elseif (volume >= 100) then
			volume = 100
		end
		updateVolume()
	end
end

function aabb(mx, my, x, y, w, h, shape)
	local bb = mx >= x and mx < x+w and my >= y and my < y+h
	
	if (bb) then
		if (shape == "tri_left") then
			return (mx-x)+(my-y) <= (w+h)/2
		elseif (shape == "tri_right") then
			return (mx-x)+(my-y) >= (w+h)/2
		elseif (shape == "circle") then
			return distance(mx-x, (my-y)/h*w, w/2, w/2) <= w/2
		elseif (shape == "semicircle_left") then
			return distance(mx-x, (my-y)/h*w, w/2, w/2) <= w/2 and (mx-x) <= w/2
		elseif (shape == "semicircle_right") then
			return distance(mx-x, (my-y)/h*w, w/2, w/2) <= w/2 and (mx-x) >= w/2
		elseif (shape == "tri_up") then
			return (mx-x)/(w/2) + (my-y-h)/h >= 0 and (w - (mx-x))/(w/2) + (my-y-h)/h >= 0 -- Thanks, Desmos!
		elseif (shape == "tri_down") then
			return (mx-x)/(w/2) - (my-y)/h >= 0 and (w - (mx-x))/(w/2) - (my-y)/h >= 0 -- Thanks, Desmos!
		else
			return true -- Assume rectangle
		end
	end
	
	return false
end

function distance(x1, y1, x2, y2)
	return math.sqrt( (x1-x2)^2 + (y1-y2)^2 )
end

function dec_to_rgb(n)
	local r = math.floor(n / (256*256));
	local g = math.floor(n / 256) % 256;
	local b = n % 256;
	
	return {r/255, g/255, b/255, 1}
end

function lighten(color, amount)
	local r, g, b = unpack(color)
	amount = amount or .5
	return {r + (1-r)*amount, g + (1-g)*amount, b + (1-b)*amount, 1}
end

function updateGrid()
	saveData()
end

function overlayPos(casing_x_scale)
	local c1 = math.max(0, math.min(.1, .1*(grid_opacity/100)) )
	local c2 = math.max(0, math.min(.2, .2*(grid_opacity/100)) )
	
	love.graphics.setColor(c1, c1, c1, 1)
	for x = 0, (game_width-1)*scale*casing_x_scale, scale*casing_x_scale do
		love.graphics.rectangle("fill", x, 0, 1, game_height*scale)
	end
	love.graphics.setColor(c2, c2, c2, 1)
	for y = 0, (game_height-1)*scale, scale do
		love.graphics.rectangle("fill", 0, y, game_width*scale*casing_x_scale, 1)
	end
end

function overlayNeg(casing_x_scale)
	local c1 = math.max(1 - .1, math.min(1, 1 - (.1*(grid_opacity/100))) )
	local c2 = math.max(1 - .2, math.min(1, 1 - (.2*(grid_opacity/100))) )
	
	love.graphics.setColor(c1, c1, c1, 1)
	for x = (scale*casing_x_scale)-1, (game_width-1)*scale*casing_x_scale, scale*casing_x_scale do
		love.graphics.rectangle("fill", x, 0, 1, game_height*scale)
	end
	love.graphics.setColor(c2, c2, c2, 1)
	for y = scale-1, (game_height-1)*scale, scale do
		love.graphics.rectangle("fill", 0, y, game_width*scale*casing_x_scale, 1)
	end
end

function updateVolume()
	love.audio.setVolume( volume / 100 )
	for i, v in pairs(sounds) do
		if (v.is_music) then
			v.source:setVolume( (music_enabled and v.volume or 0) )
		else
			v.source:setVolume( (sfx_enabled and v.volume or 0) )
		end
	end
	saveData()
end

function paletteChange(var, num)
	if (var == "game") then
		game_palette = game_palette + num
		if (game_palette < 1) then
			game_palette = #palettes
		elseif (game_palette > #palettes) then
			game_palette = 1
		end
		updatePalette()
	elseif (var == "casing") then
		casing_palette = casing_palette + num
		if (casing_palette < 1) then
			casing_palette = #palettes
		elseif (casing_palette > #palettes) then
			casing_palette = 1
		end
	end
	saveData()
end

function updatePalette()
	for i = 1, 4 do
		colors[i] = palettes[game_palette][i]
	end
	
	local img_data = love.image.newImageData("sprites/icon_small.png")
	img_data:mapPixel(function(x, y, r, g, b, a)
		if (a < 0.5) then
			return 1, 1, 1, 0
		end
		
		local avg = math.min(0.9999, math.max(0.0001, (r + g + b) / 3))
		local idx = 3 - math.floor(avg * 4);
		
		return unpack(colors[idx + 1])
	end)
	love.window.setIcon(img_data)
	
	if (state.updatePalette) then
		state:updatePalette()
	end
end

function updateLanguage()
	local lang_file = "languages/" .. string.lower(current_language) .. ".json"
	language_data = json.decodeFile(lang_file)
	
	if (state.processTexts) then
		state:processTexts()
	end
end

function updateFullscreen()
	if (not IS_WEB) then
		love.window.setFullscreen(is_fullscreen)
		display_width, display_height = love.window.getMode()
	end
	
	-- IDEALLY this function should be called ONCE on web
	local _, _, flags = love.window.getMode()
	local _width, _height = love.window.getDesktopDimensions(flags.display)
	-- 880 396
	local _default_aspect = 16/9
	local _cur_aspect = _width/_height
	
	if (_cur_aspect >= _default_aspect) then -- Width is greater
		display_height = display_height / _cur_aspect * _default_aspect
		display_width = display_height / 9 * 16
		
		-- May seem backwards, but mobile dimensions are... weird, in a sense.
		-- We're calculating what the width "should" have been originally, even if in reality it wasn't that,
		-- because we're calculating it based on aspect ratio and not real dimensions
		local _old_width = display_width / _default_aspect * _cur_aspect
		
		display_x = math.floor( (_old_width - display_width)/2 )
	else -- Height is greater
		display_width = display_width / _cur_aspect * _default_aspect
		display_height = display_height / 16 * 9
		
		local _old_height = display_height / _default_aspect * _cur_aspect
		
		display_y = math.floor( (_old_height - display_height)/2 )
	end
	
	if (is_fullscreen) then
		scale = math.min(display_width / window_width, display_height / window_height)
	else
		scale = base_scale
	end
end

function mouseTransform(x, y)
	x = x - display_x
	y = y - display_y
	
	if (is_fullscreen) then
		return (x and (x / display_width * window_width*scale) or nil), (y and (y / display_height * window_height*scale) or nil)
	else
		return x, y
	end
end

function drawForward()
	love.graphics.setColor(colors[3])
	love.graphics.print("A}", game_width-16, game_height-9)
end

function drawBackward()
	love.graphics.setColor(colors[3])
	love.graphics.print("{B", 1, game_height-9)
end

function paletteDisplay(palette, x, y, w, h)
	local rr = math.floor(w/16)
	love.graphics.setColor( palettes[palette][1] )
	love.graphics.setScissor(x, y, w/2, h/2)
	love.graphics.rectangle("line", x + .5, y + .5, w-1, h-1, rr)
	love.graphics.rectangle("fill", x+1, y+1, w-2, h-2, rr-2)
	love.graphics.setScissor()
	
	love.graphics.setColor( palettes[palette][2] )
	love.graphics.setScissor(x+w/2, y, w/2, h/2)
	love.graphics.rectangle("line", x + .5, y + .5, w-1, h-1, rr)
	love.graphics.rectangle("fill", x+1, y+1, w-2, h-2, rr-2)
	love.graphics.setScissor()
	
	love.graphics.setColor( palettes[palette][3] )
	love.graphics.setScissor(x, y+h/2, w/2, h/2)
	love.graphics.rectangle("line", x + .5, y + .5, w-1, h-1, rr)
	love.graphics.rectangle("fill", x+1, y+1, w-2, h-2, rr-2)
	love.graphics.setScissor()
	
	love.graphics.setColor( palettes[palette][4] )
	love.graphics.setScissor(x+w/2, y+h/2, w/2, h/2)
	love.graphics.rectangle("line", x + .5, y + .5, w-1, h-1, rr)
	love.graphics.rectangle("fill", x+1, y+1, w-2, h-2, rr-2)
	love.graphics.setScissor()
end

function setScale(newScale)
	if (newScale and newScale ~= scale) then
		scale = newScale
		saveData()
	end
	
	love.graphics.setDefaultFilter("linear", "linear")
	casing_canvas = love.graphics.newCanvas(window_width * scale, window_height * scale)
	side_menu_canvas = love.graphics.newCanvas(150 * scale, window_height * scale)
	love.graphics.setDefaultFilter("nearest", "nearest")
	
	updateGrid()
end

function loadState(newState, ...)
	if (type(newState) == "string") then
		newState = _G[newState]
	end
	state = newState
	if (state.load) then state:load(...) end
end

function json.decodeFile(filename)
	local txt = love.filesystem.read(filename)
	if (txt and txt ~= "") then
		return json.decode(txt)
	end
	return nil
end

function json.encodeToFile(data, filename)
	local txt = json.encode(data)
	love.filesystem.write(filename, txt)

	return txt
end

function saveData()
	for i, v in pairs(save_data) do
		save_data[i] = _G[i]
	end
	
	-- LOCAL FILE
	json.encodeToFile(save_data, SAVE_PATH)
	
	-- local data_string = json.encode(save_data)
	-- data_string = string.gsub(data_string, "\"", "\\\"")
	-- 
	-- JS.callJS( JS.stringFunc(
	-- 	[[
	-- 		GFS.writeFile("%s", "%s")
	-- 	]], SAVE_PATH, data_string
	-- ))
	-- 
	-- JS.callJS("GFS.syncfs");
end

function loadData()
	-- LOCAL FILE
	local data = json.decodeFile(SAVE_PATH)
	if (data) then
		for i, v in pairs(data) do
			save_data[i] = v
			_G[i] = v
		end
	end
	
	-- JS.newRequest(JS.stringFunc(
	-- 	[[
	-- 		GFS.readFile("%s")
	-- 	]] , SAVE_PATH),
	-- function(data)
	-- 	if (data and data ~= "") then
	-- 		local save_data = json.decode(data)
	-- 		for i, v in pairs(save_data) do
	-- 			_G[i] = v
	-- 		end
	-- 	end
	-- end)
	-- 
	-- JS.callJS("GFS.syncfs");
end

function enum(...)
	local args = {...}
	if #args == 1 and type(args[1]) == "table" then
		args = {unpack(args[1])}
	end
	
	local ret = {}
	for i, v in ipairs(args) do
		ret[v] = i
	end
	
	return ret
end

function addZeros(str, num)
	num = num or 2
	
	for i = 1, num do
		str = "0" .. str
	end
	
	return string.sub(str, -num)
end

function hold(time, callback)
	hold_timer.timer = time
	hold_timer.callback = callback
end

function cancel_hold()
	hold_timer.timer = 0
	hold_timer.callback = nil
end


function makeTest()
	if (testaabb_img) then
		-- Make it toggle
		testaabb_img = nil
		return
	end
	testaabb:mapPixel(function(x, y, r, g, b, a)
		if (menu_right.state == "closed" and menu_left.state == "closed") then
			-- local mx, my = love.mouse.getPosition()
			local mx, my = x, y
			-- local mdown = love.mouse.isDown(1)

			local xx, yy = window_width*scale - 150*scale/base_scale, window_height*scale - 150*scale/base_scale
			if ( aabb(mx, my, 0, 0, 150*scale/base_scale, 150*scale/base_scale, "tri_left") ) then
				-- menu_left.hover_timer[1] = math.min(menu_left.hover_timer[1] + dt, menu_left.hover_timer[3])
				-- if (mdown) then
				-- 	menu_left.state = "opening"
				-- end
				return 1, 1, 1, 1
			elseif ( aabb(mx, my, xx, yy, 150*scale/base_scale, 150*scale/base_scale, "tri_right") ) then
				-- menu_right.hover_timer[1] = math.min(menu_right.hover_timer[1] + dt, menu_left.hover_timer[3])
				-- if (mdown) then
				-- 	menu_right.state = "opening"
				-- end
				return 1, 1, 1, 1
			else
				-- menu_right.hover_timer[1] = 0
				-- menu_left.hover_timer[1] = 0
			end
		else
			-- menu_right.hover_timer[1] = 0
			-- menu_left.hover_timer[1] = 0
		end

		local mx, my = x*base_scale/scale, y*base_scale/scale

		if (menu_left.state ~= "closed") then
			if ( aabb(mx, my, 150, 0, window_width*base_scale - 150, window_height*base_scale) ) then
				-- menu_left.state = "closing"
				return 1, 1, 1, 1
			elseif (menu_left.state == "open") then
				for i, v in pairs(button_mapping.left_menu) do
					if ( aabb(mx, my, v[1], v[2], v[3], v[4], v.shape) ) then
						-- mouse_button_side_pressed = i
						-- button_side_pressed(i)
						return 1, 1, 1, 1
					end
				end
			end
			return 0, 0, 0, 0
		elseif (menu_right.state ~= "closed") then
			if ( aabb(mx, my, 0, 0, window_width*base_scale - 150, window_height*base_scale) ) then
				-- menu_right.state = "closing"
				return 1, 1, 1, 1
			elseif (menu_right.state == "open") then
				for i, v in pairs(button_mapping.right_menu) do
					if ( aabb(mx - (window_width*base_scale - 150), my, v[1], v[2], v[3], v[4], v.shape) ) then
						-- mouse_button_side_pressed = i
						-- button_side_pressed(i)
						return 1, 1, 1, 1
					end
				end
			end
			return 0, 0, 0, 0
		end

		for i, v in pairs(button_mapping.dpad) do
			if ( aabb(mx, my, v[1], v[2], v[3], v[4], v.shape) ) then
				-- mouse_dpadpressed = i
				-- dpad_pressed(i)
				-- break
				return 1, 1, 1, 1
			end
		end

		for i, v in pairs(button_mapping.buttons) do
			if ( aabb(mx, my, v[1], v[2], v[3], v[4], v.shape) ) then
				-- mouse_buttonpressed = i
				-- button_pressed(i)
				-- break
				return 1, 1, 1, 1
			end
		end

		return 0, 0, 0, 0
	end)
	testaabb_img = love.graphics.newImage(testaabb)
end

function table.find(t, entry) -- Am I going crazy? Didn't I already write this??
	for idx, v in ipairs(t) do
		if (v == entry) then
			return idx
		end
	end
	return nil
end

function math.round(n) -- Round to nearest number. I'm not gonna do that whole "round mode" thing just for this
	return (n - math.floor(n)) >= .5 and math.ceil(n) or math.floor(n)
end

acc_lower = {"ã","á","à","â","ä","ç","é","è","ê","ë","í","ì","î","ï","ñ","õ","ó","ò","ô","ö","ú","ù","û","ü","ý"}
acc_upper = {"Ã","Á","À","Â","Ä","Ç","É","È","Ê","Ë","Í","Ì","Î","Ï","Ñ","Õ","Ó","Ò","Ô","Ö","Ú","Ù","Û","Ü","Ý"}

-- Potential future problem: getText (and the json files by proxy) IS case-sensitive.
-- What this means is that if, say, I change menu to request "QUIT" rather than "Quit", it won't work.
-- TODO: the JSON files and the getText calls should be standardized for full uppercase
function getText(str)
	if (language_data[str]) then
		return language_data[str]
	end
	return str -- If no localization, return original string
end

function string.upperAccent(str)
	local ret = string.upper(str)
	
	for i = 1, #acc_lower do -- Probably not the most efficient method, but it'll do
		ret = string.gsub(ret, acc_lower[i], acc_upper[i])
	end
	
	return ret
end

_lg_print = love.graphics.print
_lg_printf = love.graphics.printf

function love.graphics.print(...)
	local args = {...}
	args[3] = args[3] - 3 -- Y offset due to accents
	args[1] = string.upperAccent( getText(args[1]) ) -- Much easier than manually updating the whole project
	_lg_print(unpack(args))
end

function love.graphics.printf(...)
	local args = {...}
	args[3] = args[3] - 3 -- Y offset due to accents
	if (type(args[1]) == "table") then
		for i = 2, #args[1], 2 do -- It alternates between color and text
			args[1][i] = string.upperAccent( getText(args[1][i]) )
		end
	else
		args[1] = string.upperAccent( getText(args[1]) )
	end
	_lg_printf(unpack(args))
end

function love.graphics.rectangleLine(x, y, w, h, thickness)
	thickness = thickness or 1
	love.graphics.rectangle("fill", x, y, w - thickness, thickness)
	love.graphics.rectangle("fill", x + w - thickness, y, thickness, h - thickness)
	love.graphics.rectangle("fill", x + thickness, y + h - thickness, w - thickness, thickness)
	love.graphics.rectangle("fill", x, y + thickness, thickness, h - thickness)
end
