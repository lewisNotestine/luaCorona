-- ScrollJump - main.lua
-- Abstract:  Side scrolling platforming demo.  
-- has a character that can move, jump, and (maybe) fire projectiles.
-- May have enemies, a boss, platforms, and a life meter.
-- May have sound effects
-- May have a score and an ending sequence.
--
-- Lewis Notestine
-- Version 1.0
-- 3/31/2011
--

--**************NOTES******************


--**************End NOTES *************



game = require( "beebegames" )
ui = require( "ui" )
physics = require( "physics" )

tblCharNu = {}

table.insert( tblCharNu, "Nu - Stand (Right).tiff" )
table.insert( tblCharNu, "Nu - Stand (Left).tiff" )

for i = 1,4 do
	table.insert( tblCharNu, "Nu - Walk (Right)-" .. i .. ".tiff" )
end

for i = 1,4 do	
	table.insert( tblCharNu, "Nu - Walk (Left)-" .. i .. ".tiff" )
end

charNu = game.newObject( tblCharNu, 56, 66, 240, 240, .2, false, 1, nil )

local moveback = function()
	charNu:doTransition( false, { time=5, x=240, y=240, xScale=1, yScale=1, onComplete=moveout }  )
end


local moveout = function()
	charNu:doTransition( false, { time=5, x=140, y=140, xScale=1, yScale=1, onComplete=moveback}  )
end

-- Button Handlers

local btnHandlerRight = function( event )
	if (event.phase == "press" or event.phase == "moved_in") then
		charWalkRight()
	elseif event.phase == "release" then 
		charStopRight()
	elseif event.phase == "moved_out" then
		charStopRight()
	end
end

local btnHandlerLeft = function( event )
	if (event.phase == "press" or event.phase == "moved_in") then
		charWalkLeft()
	elseif event.phase == "release" then
		charStopLeft()
	elseif event.phase == "moved_out" then
		charStopLeft()
	end
end


local btnHandlerJump = function( event )
	if event.phase == "press" 
		then 
		charJump()
	end
end




-- button objects

local buttonRight = ui.newButton{
        default = "buttonRed.png",
        over = "buttonRedOver.png",
		onEvent = btnHandlerRight,
		x = 0,
		y = 75,
        text = nil,
        emboss = true
}


print(buttonRight.contentWidth)
print(buttonRight.x)


local buttonLeft = ui.newButton{
        default = "buttonRed.png",
        over = "buttonRedOver.png",
		onEvent = btnHandlerLeft,
		x = 0,
		y = 150,
        text = nil,
        emboss = true
}


local buttonJump = ui.newButton{
		default = "buttonRed.png",
		over = "buttonRedOver.png",
		onEvent = btnHandlerJump,
		x = 0, 
		y = 225,
		text = nil,
		emboss = false
}

