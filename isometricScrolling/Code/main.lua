--[[ 
Abstract: Project for walking character around isometric floor image
~Character animations to change with direction.  
~Character remains centrally located, background scrolls.  
~Has basic menu functionality. 

Version: 1.0  
]]--




-- SOME INITIAL SETTINGS
display.setStatusBar( display.HiddenStatusBar ) --Hide status bar from the beginning

-- Import director class
local director = require("director")

-- Create a main group
local mainGroup = display.newGroup()

-- Main function
local function main()
	
	-- Add the group from director class
	mainGroup:insert(director.directorView)
	
	-- Uncomment below code and replace init() arguments with valid ones to enable openfeint
	--[[
	openfeint = require ("openfeint")
	openfeint.init( "App Key Here", "App Secret Here", "Ghosts vs. Monsters", "App ID Here" )
	]]--
	
	director:changeScene( "mainmenu" )
	
	return true
end

-- Begin
main()