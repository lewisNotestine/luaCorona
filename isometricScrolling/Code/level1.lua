--[[ 
Abstract: Project for walking character around isometric floor image
~Character animations to change with direction.  
~Character remains centrally located, background scrolls.  
~perspective (i.e., sprites are behind certain objects, in front of others
~Character can't pass through walls
~Has basic menu functionality. 

Version: 1.0  
]]--


--[[
NOTES:

TODO: replace floorGroup objects with "zOrderGroup" and "moveGroup" or something... there are 
	  two separate functions that require address.
	         1. zOrderGroup has as members all groups/objects that require re-sorting to specify z-order.
			 2. moveGroup has as members all groups/objects that move (including everything in zOrderGroup)
	  
merge the three different functions that create the walls into one big function.
]]--

module(..., package.seeall)

--***********************************************************************************************--
--***********************************************************************************************--

-- LEVEL MODULE

-- To create a new level, change "MODULE-SPECIFIC VARIABLES" (below) and also the
-- createLevel() function. Everything else should be identical between level modules.

--***********************************************************************************************--
--***********************************************************************************************--


-- Main function - MUST return a display.newGroup()
function new()
	local hudGroup = display.newGroup()
	 
	local gameGroup = display.newGroup()
	gameGroup.x = 0
	
	local floorGroup = display.newGroup() -- all items that are scrolling
	local tblFloorGroup = {} -- list of items, as table.
	local walls = {}
	local wallsGroups = {}
	local lastTime = system.getTimer()
	local sortInterval = 10
	local sortCounter = 0
	local lines = {}
	
	-- MODULE-SPECIFIC VARIABLES
	local backgroundFilename1 = "Test_Floor2-02.png"
	local wallsFilename1 = "Test_Walls-03.png"
	local tblNPCObjects = {}
	
	-- EXTERNAL MODULES / LIBRARIES
	
	local movieclip = require( "movieclip" )
	local physics = require "physics"
	local ui = require( "ui" )
	local game = require( "beebegames" )
	local joystick = require( "joystick" )
	
	--local facebook = require "facebook"
	
	local mCeil = math.ceil
	local mAtan2 = math.atan2
	local mPi = math.pi
	local mSqrt = math.sqrt
	
	-- OBJECTS
	
	local tblCharAnim = {}
	local tblNpcAnim = {}
	local objChar
	local backgroundImage1
	-- make some buttons
	local pauseMenuBtn; local pauseBtn; local pauseShade

	
	-- VARIABLES
	
	local blnGameIsActive = false
	local blnCharCanMove = true
	local waitingForNewRound
	local restartTimer
	local ghostTween
	local screenPosition = "left"	--> "left" or "right"
	local canSwipe = true
	local swipeTween
	local gameLives = 4
	local gameScore = 0
	local bestScore
	local monsterCount
	local jstkSpeed = 4
	local lineBody = {density=10, friction=0, bounce=0}  --, isSensor=true}
	local charColBodyShape = {-21,0, 21,0, 21,35, -21,35 }
	local charColBody = {density=10, friction=0, bounce=0, shape=charColBodyShape}
	local CharOccBodyShape = {}
	local charOccBody = {}
	local xInput, yInput
	local wallOffset
	
	local topX, topY, bottomX, bottomY
	
	-- LEVEL SETTINGS
	
	local restartModule
	local nextModule
	
	-- AUDIO
	
	--***************************************************

	-- saveValue() --> used for saving high score, etc.
	
	--***************************************************
	local saveValue = function( strFilename, strValue )
		-- will save specified value to specified file
		local theFile = strFilename
		local theValue = strValue
		
		local path = system.pathForFile( theFile, system.DocumentsDirectory )
		
		-- io.open opens a file at path. returns nil if no file found
		local file = io.open( path, "w+" )
		if file then
		   -- write game score to the text file
		   file:write( theValue )
		   io.close( file )
		end
	end
	
	--***************************************************

	-- loadValue() --> load saved value from file (returns loaded value as string)
	
	--***************************************************
	local loadValue = function( strFilename )
		-- will load specified file, or create new file if it doesn't exist
		
		local theFile = strFilename
		
		local path = system.pathForFile( theFile, system.DocumentsDirectory )
		
		-- io.open opens a file at path. returns nil if no file found
		local file = io.open( path, "r" )
		if file then
		   -- read all contents of file into a string
		   local contents = file:read( "*a" )
		   io.close( file )
		   return contents
		else
		   -- create file b/c it doesn't exist yet
		   file = io.open( path, "w" )
		   file:write( "0" )
		   io.close( file )
		   return "0"
		end
	end
	
	local function npcDialogStrt( npcName )
		
	end
	
	local drawBackground = function()
		
		local grpBackGrd = display.newGroup()
		-- Background gets drawn in this order: backdrop, clouds, trees, red glow
		
		-- BACKDROP
		backgroundImage1 = display.newImageRect( backgroundFilename1, 1090, 979 )
		--backgroundImage1:setReferencePoint( display.CenterLeftReferencePoint )
		backgroundImage1.x = 0; backgroundImage1.y = 160
		backgroundImage1.surfcType = "floor"
		grpBackGrd:insert( backgroundImage1 )
		floorGroup:insert( grpBackGrd )

	end
	

	
	--TODO: merge drawWalls and createLineBoundary and createWallOccluder into one big function that handles walls...
	--TODO: include functionality to handle z-ordering of wall images. Use "Carousel"
	--TODO: consider indexing table walls by the filename of the incoming wall?
	
	local drawWalls = function( wallFileName, inX, inY, inWidth, inHeight, inRealHeight, inDirection )
		--[[
		local wallID = #walls + 1
		local iWall = display.newImageRect( wallFileName, inWidth, inHeight)
		
		iWall.x = inX; iWall.y = inY -- -5; wallsImage1.y = 165
		iWall.surfcType = "wallImg"
		iWall.realHeight = inRealHeight
		iWall.wallSlope = ( iWall.contentHeight - iWall.realHeight ) / iWall.contentWidth	--wallSlope is scalar	
		iWall.direction = inDirection
		
		walls[wallID] = iWall
		
		--wallsGroups[wallID]  = display.newGroup()
		
		local iWallObj = walls[wallID]
		
		--wallsGroups[wallID]:insert( iWallObj ) --wallsGroups[wallID][wallID] = walls[wallID]
		tblFloorGroup[#tblFloorGroup + 1] = iWallObj
		 
		--local iWallGrp = wallsGroups[wallID] 
		 
		floorGroup:insert( iWallObj )--(tblFloorGroup[#tblFloorGroup])
		]]--
	end
	
	
	
	
	local function createLineBoundary( prms )
		
		--[[
		prms:
		westX , westY 
		eastX , eastY
		northX, northY
		southX, southY
		]]--
		
		local lineID = #lines + 1

		local wallShape

		if prms.westX and prms.westY then 		-- northwest wall
			if prms.northX and prms.northY then 
				lines[lineID] = display.newLine( prms.westX, prms.westY, prms.northX, prms.northY )
				lines[lineID].direction = "northwest"
				wallShape = {0, - wallOffset, lines[lineID].contentWidth, - wallOffset - lines[lineID].contentHeight}
				lines[lineID].west = {prms.westX, prms.westY}
				lines[lineID].north = {prms.northX, prms.northY}
				
			elseif prms.southX and prms.southY then -- southwest wall
				lines[lineID] = display.newLine( prms.southX, prms.southY, prms.westX, prms.westY )
				lines[lineID].direction = "southwest" 
				wallShape = {0, 0, -lines[lineID].contentWidth, - lines[lineID].contentHeight}
				lines[lineID].west = {prms.westX, prms.westY}
				lines[lineID].south = {prms.southX, prms.southY}
			end
			
		elseif prms.eastX and prms.eastY then	
			
			if prms.northX and prms.northY then	--northeast wall
				lines[lineID] = display.newLine( prms.northX, prms.northY,prms.eastX, prms.eastY )
				lines[lineID].direction = "northeast"
				wallShape = {0, - wallOffset, lines[lineID].contentWidth, - wallOffset + lines[lineID].contentHeight}
				lines[lineID].east = {prms.eastX, prms.EastY}
				lines[lineID].north = {prms.northX, prms.NorthY}
				
			elseif prms.southX and prms.southY then	--southeast wall
				lines[lineID] = display.newLine( prms.eastX, prms.eastY, prms.southX, prms.southY )
				lines[lineID].direction = "southeast"
				wallShape = {0, 0, - lines[lineID].contentWidth, lines[lineID].contentHeight}
				lines[lineID].east = {prms.eastX, prms.eastY}
				lines[lineID].south = {prms.southX, prms.southY}
				
			end
			
		elseif prms.northX and prms.northY and prms.southX and prms.southY then	-- north-south (vertical) wall 
			lines[lineID] = display.newLine( prms.northX, prms.northY, prms.southX, prms.southY )
			lines[lineID].direction = "northsouth"
			wallShape = {0, 0, 0, lines[lineID].contentHeight}
			lines[lineID].north = {prms.northX, prms.northY}
			lines[lineID].south = {prms.southX, prms.southY}
			
		elseif prms.eastX and prms.eastY and prms.westX and prms.westY then	
			lines[lineID] = display.newLine( prms.eastX, prms.eastY, prms.westX, prms.westY )-- east-west (horiz.) wall
			lines[lineID].direction = "eastwest"
			wallShape = {0, 0, lines[lineID].contentWidth, 0}
			lines[lineID].east = {prms.eastX, prms.eastY}
			lines[lineID].west = {prms.westX, prms.westY}
		end
		
		lines[lineID].surfcType = "wall"
		physics.addBody( lines[lineID], "static", {density=10, friction=0, bounce=0, shape=wallShape})
		lines[lineID].isSensor = true


	end

	-- Create Game Character
	
	local createCharacter = function()
		
		grpChar = display.newGroup()
		-- handlers for collisions, controls, etc
		
			table.insert( tblCharAnim, "BlackMage2M-N.gif" ) --1
			table.insert( tblCharAnim, "BlackMage2M-NW.gif" ) --2
			table.insert( tblCharAnim, "BlackMage2M-W.gif" ) --3
			table.insert( tblCharAnim, "BlackMage2M-SW.gif" ) --4
			table.insert( tblCharAnim, "BlackMage2M-S.gif" ) -- 5
			table.insert( tblCharAnim, "BlackMage2M-SE.gif" ) -- 6 
			table.insert( tblCharAnim, "BlackMage2M-E.gif" ) -- 7 
			table.insert( tblCharAnim, "BlackMage2M-NE.gif" ) -- 8
		
		objChar = movieclip.newAnim ( tblCharAnim, 42, 70 )
		--objChar = game.newObject( tblCharAnim, 42, 70, 240, 160, .2, false, 1, gameGroup )
		objChar.x = 240; objChar.y = 160
		
		--Character Properties
		--objChar.blnIsMoving = false
		objChar.surfcType = "char"
		
		physics.addBody( objChar, "dynamic", charColBody )
		objChar.isSensor = true
		objChar.bottom = objChar.y + (objChar.contentHeight/2)
		
		objCharOcc = display.newRect(objChar.x - (objChar.contentWidth/2), objChar.y - (objChar.contentHeight/2), 42, 35)-- rect for occlusion body
		physics.addBody( objCharOcc, "dynamic", charOccBody )
		objCharOcc.isVisible = false
		objCharOcc.isSensor = true
		objCharOcc.surfcType = "charOcc"
		
		objCharJnt = physics.newJoint( "weld", objChar, objCharOcc, objChar.x, objChar.y )

		--gameGroup:insert( objChar )
		--floorGroup:insert( grpChar )
		--grpChar:insert( objChar )
		tblFloorGroup[#tblFloorGroup + 1] = objChar
		wallOffset = 0 * objChar.contentHeight
		
	end
	
	-- User interface
	local drawHUD = function()
		-- TWO BLACK RECTANGLES AT TOP AND BOTTOM (for those viewing from iPad)
		local topRect = display.newRect( 0, -160, 480, 160 )
		topRect:setFillColor( 0, 0, 0, 255 )
		
		local bottomRect = display.newRect( 0, 320, 480, 160 )
		bottomRect:setFillColor( 0, 0, 0, 255 )
		
		hudGroup:insert( topRect )
		hudGroup:insert( bottomRect )
		
		-- WHEEL FOR CONTROLLING CHARACTER MOVEMENT
	
		jstkChar = joystick.newJoystick{}
		
		-- PAUSE BUTTON

		-- MENU BUTTON (on Pause Display)

	end
	
	
	local onScreenTouch = function( event )
	-- HANDLE TOUCHING OF Screen: Including NPC TARGET- INITIATE DIALOG, take actions, etc
		if event.phase == "began" then 	
			print( event.x - backgroundImage1.x )
			print( event.y - backgroundImage1.y )
		end
	end
	
	-- Listener function to handle z-ordering
	-- TODO:  create dispatcher for sort function, so that z-ordering occurs when event fires.
	
	-- local onZOrder = function( event )
		-- sort the ordering table.
	-- end 

		
	local function sort()
		
	-- *********TODO:  sort function args a, b are treated as if "by ref". but they're probably "by val". Need to create string tag identifier to l
	--			to look up the elements being compared and assign them properties based on lookup instead of directly.
	
        table.sort(tblFloorGroup,  
                function(a, b)
						--if a.surfcType == "char" then a.zy = a.y + (a.contentHeight/2)
						
						if (a.surfcType == "wallImg" and (b.surfcType == "char" or b.surfcType == "NPC")) or (b.surfcType == "wallImg" and (a.surfcType == "char" or a.surfcType == "NPC")) then 
						b.zy = b.y + (b.contentHeight/2)
							if a.direction == "northeast" then 
								a.zy = a.y - (a.contentHeight/2) -- top of object
								+ a.realHeight  -- "real" height of wall
								+ (a.wallSlope * (b.x - (a.x - (a.contentWidth/2)) )) -- calculate y for sloped wall.

							elseif a.direction == "southeast" then
								a.zy = a.y - (a.contentHeight/2) -- top of object
								+ a.realHeight  -- "real" height of wall
								+ (-a.wallSlope * (b.x - (a.x - -(a.contentWidth/2)) )) -- calculate y for sloped wall.
						
							elseif a.direction == "northwest" then
								a.zy = a.y - (a.contentHeight/2) -- top of object
								+ a.realHeight  -- "real" height of wall
								+ (-a.wallSlope * (b.x - (a.x - (a.contentWidth/2)) )) -- calculate y for sloped wall.
						
							elseif a.direction == "southwest" then
								a.zy = a.y - (a.contentHeight/2)
								+ a.realHeight
								+ (a.wallSlope * (b.x - (a.x - (a.contentWidth/2)) ))
								
							elseif a.direction == "northsouth" then
								a.zy = a.y
								
							elseif a.direction == "eastwest" then 
								a.zy = a.y
																 
							end
						
						elseif (a.surfcType == "wallImg" and b.surfcType == "wallImg") then
							a.zy = a.y
							b.zy = b.y
							
						elseif (a.surfcType == "char" and b.surfcType == "NPC") or (a.surfcType == "NPC" and b.surfcType == "char") then
							a.zy = a.y + (a.contentHeight/2)
							b.zy = b.y + (b.contentHeight/2)
						
						elseif (a.surfcType == nil or b.surfcType == nil ) then 
							print("nil parameter")
						
						else 
							print( "some other combination of table elements" )
							a.zy = a.y
							b.zy = b.y 
							print( a.surfcType )
							print( b.surfcType )
						end 
						
						print( a.zy )
						print( b.zy )
						print( "--------------" )
						
						if (a.surfcType == nil or b.surfcType == nil) then
							return a.y < b.y
						else
						
                        return a.zy < b.zy
						end
						
                end
        )
        
        for i = 1, #tblFloorGroup do
                floorGroup:insert(tblFloorGroup[i])
        end
	end

	
	--listener function for collision and occlusion: TODO:  Move this into a modularized production version 
	local function onCollision( event )
		if ( event.phase == "began" ) then
			print( event.object1.surfcType )
			print( event.object2.surfcType )
			
			if (( event.object1.surfcType == "char" and event.object2.surfcType == "wall") )
				then

				blnCharCanMove = false

				local intWallRecoil = 7
				local i 
			
				print( event.object1.direction )
				print( event.object2.direction )
				
				for i = 1,floorGroup.numChildren do
					if floorGroup[i].surfcType ~= "char" then 
						if event.object2.direction == "northeast" then
							transition.to( floorGroup[i], {time=200, x=floorGroup[i].x + intWallRecoil, y=floorGroup[i].y - intWallRecoil} )
						elseif event.object2.direction == "southeast" then
							transition.to( floorGroup[i], {time=200, x=floorGroup[i].x + intWallRecoil, y=floorGroup[i].y + intWallRecoil} )
						elseif event.object2.direction == "southwest" then
							transition.to( floorGroup[i], {time=200, x=floorGroup[i].x - intWallRecoil, y=floorGroup[i].y + intWallRecoil} )
						elseif event.object2.direction == "northwest" then
							transition.to( floorGroup[i], {time=200, x=floorGroup[i].x - intWallRecoil, y=floorGroup[i].y - intWallRecoil} )
						end
					end
				end
			
				print( "Char collided" )
			
			elseif  
				((event.object1.surfcType == "charOcc" and event.object2.surfcType == "NPC")
				or (event.object1.surfcType == "NPC" and event.object2.surfcType == "charOcc"))
	
			then
				print( "occluded" )
				--objChar:toFront()
			elseif ((event.object1.surfcType == "npcOcc" and event.object2.surfcType == "char")
				or (event.object1.surfcType == "char" and event.object2.surfcType == "npcOcc"))
			then
				print( "occluded" )
				--objNPC:toFront()
			elseif --event.phase == "began" and
				event.object1.surfcType == "char" 
				and event.object2.surfcType == "NPC" 
			then
				blnCharCanMove = false
				local intNPCRecoil = 5
				for i = 1,floorGroup.numChildren do
					if floorGroup[i].surfcType ~= "char" then
						transition.to( floorGroup[i], {time=200, x=floorGroup[i].x + (intNPCRecoil * xInput) , y=floorGroup[i].y + (intNPCRecoil * yInput)} )
					end
				end
			elseif 
				event.object1.surfcType == "char"
				and event.object2.surfcType == "wallOcc" 
			then
				--wallsImage1:toFront()
			end

		elseif event.phase == "ended" then
				print( "ended" )
				blnCharCanMove = true
		end

		return true
	end

	-- TODO: Create additional collision listener for NPCs colliding with non-Char objects

	-- TODO:  merge createWallOccluder and drawWalls and createLineBoundaries
	

	--function to trigger sorting
	local function sortTrigger()
	
		if sortCounter % sortInterval == 0 then
                sort()
				sortCounter = 0
        end
                
        sortCounter = sortCounter + 1
		print( sortCounter )
		
	end
	
		-- Main enterFrame Listener
	local gameLoop = function( event )
		
		sortTrigger()
		
		
		-- moving character
		--local xInput, yInput
		if jstkChar.joyX == false then 
			xInput = 0
		else
			xInput = jstkChar.joyX * jstkSpeed
		end
			
		if jstkChar.joyY == false then
			yInput = 0 
		else
			yInput = jstkChar.joyY * jstkSpeed
		end
			
		--print( jstkChar.joyAngle )
		
		local i
		
		-- move the character
		if blnCharCanMove == true then 
			for i = 1,floorGroup.numChildren do
				if floorGroup[i].surfcType ~= "char" then
					floorGroup[i].x = floorGroup[i].x - xInput
					floorGroup[i].y = floorGroup[i].y - yInput
				end
			end
		end

		-- Character Animation Start
		if (jstkChar.joyX ~= false or jstkChar.joyY ~= false) then
			if (jstkChar.joyAngle >= 337.5 or jstkChar.joyAngle < 22.5) then 
				objChar:play{ startFrame=1, endFrame=1, loop=0, remove=false}
			elseif (jstkChar.joyAngle >= 22.5 and jstkChar.joyAngle < 67.5) then
				objChar:play{ startFrame=8, endFrame=8, loop=0, remove=false}
			elseif (jstkChar.joyAngle >= 67.5 and jstkChar.joyAngle < 112.5) then
				objChar:play{ startFrame=7, endFrame=7, loop=0, remove=false}
			elseif (jstkChar.joyAngle >= 112.5 and jstkChar.joyAngle < 157.5) then
				objChar:play{ startFrame=6, endFrame=6, loop=0, remove=false}			
			elseif (jstkChar.joyAngle >= 157.5 and jstkChar.joyAngle < 202.5) then
				objChar:play{ startFrame=5, endFrame=5, loop=0, remove=false}			
			elseif (jstkChar.joyAngle >= 202.5 and jstkChar.joyAngle < 247.5) then
				objChar:play{ startFrame=4, endFrame=4, loop=0, remove=false}			
			elseif (jstkChar.joyAngle >= 247.5 and jstkChar.joyAngle < 292.5) then
				objChar:play{ startFrame=3, endFrame=3, loop=0, remove=false}			
			elseif (jstkChar.joyAngle >= 292.5 and jstkChar.joyAngle < 337.5) then
				objChar:play{ startFrame=2, endFrame=2, loop=0, remove=false}
			end
		end



	return true
	end
	
	-- *********************************************************************************************
	
	-- createLevel() function (should be the only function that's different in each level module
	
	-- *********************************************************************************************
	
	local createLevel = function()
		
		-- Array for eventually storing all NPC/enemy information
		--local tblNPCs = {}
		
	-- CREATE NPCs
		local createNPC = function()
			
			table.insert( tblNpcAnim, "Pig-SW.gif" )
			
			local s = {-21,0, 21,0, 21,35, -21,35}
			
			objNPC = movieclip.newAnim ( tblNpcAnim, 42, 70 )
			
			physics.addBody( objNPC, "dynamic", {density=10, friction=0, bounce=0, shape=s} )
			objNPC.isSensor = true
			objNPC.surfcType = "NPC"
			objNPC.charName = "pig1"
			
			floorGroup:insert( objNPC ) 
			objNPC.x = backgroundImage1.x 
			objNPC.y = backgroundImage1.y
						
			objNPCOcc = display.newRect(objNPC.x - (objNPC.contentWidth/2), objNPC.y - (objNPC.contentHeight/2), 42, 35)-- rect for occlusion body
			physics.addBody( objNPCOcc, "dynamic", charOccBody )
			objNPCOcc.isVisible = false
			objNPCOcc.isSensor = true
			objNPCOcc.surfcType = "npcOcc"
			tblFloorGroup[#tblFloorGroup + 1] = objNPC
			floorGroup:insert( objNPCOcc )
		
			objNPCJnt = physics.newJoint( "weld", objNPC, objNPCOcc, objNPC.x, objNPC.y )

			
		end 
		
		local createTree = function()
			tree1 = display.newImageRect( "Tree_1.png", 100, 200)
			tree1.x = backgroundImage1.x - 100
			tree1.y = backgroundImage1.y
			tree1.surfcType = "tree"
			
			floorGroup:insert( tree1 )
			
			local treeShape = {-50,50, 50,50, 50,100, -50,100}
			
			physics.addBody( tree1, "static", {density=10, friction=0, bounce=0, shape=treeShape} )
			treeOcc = display.newRect(tree1.x - (tree1.contentWidth/2), tree1.y - (tree1.contentHeight/2), 100, 200)
			treeOcc.isVisible = false
			treeOcc.isSensor = true
			treeOcc.surfctype = "treeOcc"
			physics.addBody( treeOcc, "static", charOccBody )
			floorGroup:insert( treeOcc )
			--objTreeJnt = physics.newJoint( "weld", tree1, tree1Occ, tree1.x, tree1.y)
		end
		
		createTree()
		

		function npcDialogStrt( argObject )
			-- disable dialog unless player char is closer to NPC.
			local distNPC 
			distNPC = math.sqrt((argObject.x - objChar.x)^2 + (argObject.y - objChar.y)^2)
			if distNPC < 150 then
				--bring up character dialog window
				print( "dialog start" )
				
			end
		end
		
		function onNPCTouch( event )
			if event.phase == "began" then
				print(	event.name.." occurred")
				print( event.target.charName )
				if event.target.charName == "pig1" then 
					npcDialogStrt( objNPC ) -- TODO: update this to look up from a table instead of relying on conditionals?
				end
			end
		return true
		end
		
		
		createNPC()
		
		
	createLineBoundary( {
		westX=backgroundImage1.x - 516, 
		westY=backgroundImage1.y + 287,
		northX=backgroundImage1.x + 121,
		northY=backgroundImage1.y - 1.6
		}
		)

	createLineBoundary( {	
		eastX=backgroundImage1.x + 517,
		eastY=backgroundImage1.y + 0,
		northX=backgroundImage1.x + -97,
		northY=backgroundImage1.y + -279
		}
		)
	
	createLineBoundary( {	
		eastX=backgroundImage1.x + 321,
		eastY=backgroundImage1.y +283,
		northX=backgroundImage1.x + 101,
		northY=backgroundImage1.y + 180
		}
		)
	
	createLineBoundary( {	
		eastX=backgroundImage1.x + 516,
		eastY=backgroundImage1.y + 0,
		southX=backgroundImage1.x + 101,
		southY=backgroundImage1.y + 180
		}
		)
	
	createLineBoundary( {	
		westX=backgroundImage1.x - 296,
		westY=backgroundImage1.y - 191,
		southX=backgroundImage1.x + 121,
		southY=backgroundImage1.y - 3
		}
		)
	
	createLineBoundary( {	
		westX=backgroundImage1.x - 516,
		westY=backgroundImage1.y + 287,
		southX=backgroundImage1.x -97,
		southY=backgroundImage1.y + 468
		}
		)
	
	createLineBoundary( {	
		eastX=backgroundImage1.x + 321,
		eastY=backgroundImage1.y + 283,
		southX=backgroundImage1.x - 97 ,
		southY=backgroundImage1.y + 468
		}
		)

	--createWallOccluder()
	
		local z
		for z = 1, #lines do
			floorGroup:insert( lines[z] )
		end 
	end
	
	
	
	-- *********************************************************************************************
	
	-- END createLevel() function
	
	-- *********************************************************************************************
	
	local onSystem = function( event )
		if event.type == "applicationSuspend" then
			if gameIsActive and pauseBtn.isVisible then
				gameIsActive = false
				physics.pause()
				
				-- SHADE
				if not shadeRect then
					shadeRect = display.newRect( 0, 0, 480, 320 )
					shadeRect:setFillColor( 0, 0, 0, 255 )
					hudGroup:insert( shadeRect )
				end
				shadeRect.alpha = 0.5
				
				-- SHOW MENU BUTTON
				if pauseMenuBtn then
					pauseMenuBtn.isVisible = true
					pauseMenuBtn.isActive = true
					pauseMenuBtn:toFront()
				end
				
				pauseBtn:toFront()
				
				-- STOP GHOST ANIMATION
				if ghostTween then
					transition.cancel( ghostTween )
				end
			end
			
		elseif event.type == "applicationExit" then
			if system.getInfo( "environment" ) == "device" then
				-- prevents iOS 4+ multi-tasking crashes
				os.exit()
			end
		end
	end
	
	local gameInit = function()
		
		--blnGameIsActive = true
		-- PHYSICS
		physics.start( true )
		physics.setDrawMode( "hybrid" )	-- set to "debug" or "hybrid" to see collision boundaries
		physics.setGravity( 0, 0 )	--> 0, 9.8 = Earth-like gravity
		
		-- DRAW GAME OBJECTS
		createCharacter()
		drawBackground()
		--drawWalls( wallsFilename1, -5, 165, 1090, 1091)
		drawWalls( "test_walls-05.png", -310, 460, 420, 335, 155, "southwest" )
		drawWalls( "test_walls-06.png", 110, 460, 419, 335, 155, "southeast" )
		drawWalls( "test_walls-07.png", 210, 318, 222, 253, 155, "northeast" )
		--create NPCs function
		
		-- CREATE LEVEL
		createLevel()
		
		-- DRAW HEADS-UP DISPLAY (score, lives, etc)
		drawHUD()
		
		-- LOAD BEST SCORE FOR THIS LEVEL
			
		-- START EVENT LISTENERS
		
		objChar.collision = onCollision
		Runtime:addEventListener( "touch", onScreenTouch )
		Runtime:addEventListener( "collision", onCollision )
		Runtime:addEventListener( "enterFrame", gameLoop )
		Runtime:addEventListener( "system", onSystem )
		--objChar:addEventListener( "collision", objChar )
		objNPC:addEventListener( "touch", onNPCTouch )
		
		--local startTimer = timer.performWithDelay( 2000, function() startNewRound(); end, 1 )
		
		floorGroup:toBack()
	
	end
	
	unloadMe = function()
		-- STOP PHYSICS ENGINE
		--physics.stop()
		
		-- REMOVE EVENT LISTENERS
		Runtime:removeEventListener( "touch", onScreenTouch )
		Runtime:removeEventListener( "enterFrame", gameLoop )
		Runtime:removeEventListener( "system", onSystem )
		
		-- REMOVE everything in other groups
		for i = hudGroup.numChildren,1,-1 do
			local child = hudGroup[i]
			child.parent:remove( child )
			child = nil
		end
		
		-- Stop any transitions

		
		-- Stop any timers

	end
	
	gameInit()

	
	-- MUST return a display.newGroup()
	return gameGroup
end