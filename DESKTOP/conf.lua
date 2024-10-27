if (love._os == "Web") then
	display_width = 1920
	display_height = 1080
	-- display_width = 1280
	-- display_height = 720
	
	love.conf = function(t)
		t.console = false
		t.version = "0.11.0"
		t.identity = "quantum_phantom_photo"
		t.window.title = "Quantum Phantom Photo"
		t.window.icon = "sprites/icon_small.png"
		t.window.width = display_width
		t.window.height = display_height
		t.window.fullscreentype = "exclusive"
	end
else -- DESKTOP
	display_width = 1280
	display_height = 720
	
	love.conf = function(t)
		t.console = false
		t.version = "11.0"
		t.identity = "quantum_phantom_photo"
		t.window.title = "Quantum Phantom Photo"
		t.window.icon = "sprites/icon_small.png"
		t.window.width = display_width
		t.window.height = display_height
		t.window.fullscreentype = "desktop"
	end
end
