--[[ 
Abstract: Project for walking character around isometric floor image
~Character animations to change with direction.  
~Character remains centrally located, background scrolls.  
~Has basic menu functionality. 

Version: 1.0  
]]--





module(..., package.seeall)

--***********************************************************************************************--
--***********************************************************************************************--

-- mainmenu

--***********************************************************************************************--
--***********************************************************************************************--

-- Main function - MUST return a display.newGroup()
function new()
	local menuGroup = display.newGroup()
	
	local ui = require("ui")

	
	-- AUDIO
		--local backgroundSound = audio.loadStream( "rainsound.mp3" )	--> This is how you'd load music
	
	local drawScreen = function()
		-- BACKGROUND IMAGE
		local backgroundImage = display.newImageRect( "GameMenu.png", 480, 320 )
		backgroundImage.x = 240; backgroundImage.y = 160
		
		menuGroup:insert( backgroundImage )
		
		
		-- MENU TITLE
		local menuTitle = display.newImageRect( "MenuTitle.png", 240, 160 )
		menuTitle.x = 240; menuTitle.y = 160
		
		menuGroup:insert( menuTitle )
									
														
		-- PLAY BUTTON
		local playBtn
		
		local onPlayTouch = function( event )
			
			if event.phase == "release" then
			director:changeScene( "level1" )
			end

		end
		
		playBtn = ui.newButton{
			default = "buttonRed.png",
			over = "buttonRedOver.png",
			onEvent = onPlayTouch,
			x = 0,
			y = 75,
			text = "it is your birthday",
			emboss = true
		}
		
		--playBtn:setReferencePoint( display.BottomCenterReferencePoint )
		playBtn.x = 250 playBtn.y = 250
		
		menuGroup:insert( playBtn )
		
		
	end
	
	drawScreen()
	--audio.play( backgroundSound, { channel=1, loops=-1, fadein=5000 }  )
	
	unloadMe = function()
		-- do some stuff to unload.
		--if tapSound then audio.dispose( tapSound ); end
	end
	
	-- MUST return a display.newGroup()
	return menuGroup
end
