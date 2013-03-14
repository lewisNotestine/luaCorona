module(..., package.seeall)

-- ==========================================================================================
--
-- BeebeGames Class
-- 
-- Designed and created by Jonathan Beebe of Beebe Games.
--
-- http://jonbeebe.tumblr.com/
-- http://beebegamesonline.appspot.com/
--
-- (Should work on all iOS and Android devices, optimized for retina display)
-- 
-- Version: 1.8
-- 
-- Class is MIT Licensed, see http://jonbeebe.tumblr.com/license
-- Copyright (C) 2010-2011 Beebe Games - All Rights Reserved.
--
-- ===============
-- IMPORTANT NOTE:
-- ===============
--
-- The cancelAllTimers() function should only be used as a cleanup! Please run :cancel() and nil out
-- timers individually before calling cancelAllTimers(), so keep track of them all! Same goes for the
-- removeAllObjects() function. Call destroy(), removeSelf(), and nil out your objects and THEN call
-- removeAllObjects().
--
--
-- ========
-- CHANGES:
-- ========
--
-- 1.8 - Fixed major memory leak issues in regards to the destroy() function for objects and cancel() for timers.
--		 Also, randomTable functions have been deprecated because after extensive testing, localizing math.random
--       actually works A LOT faster than using pregenerated random tables.
--
-- 1.7 - Fixed some bugs. Added listAllTimers() as a debug function. Added newRandomTable() and pullFromRandomTable() functions.
--
-- 1.6 - Added event.name and event.count parameters to listeners passed to performAfterDelay().
--
-- 1.5 - Fixed major bug that conflicted with physics. Added objects table and a destroyAllObjects function. Better compatibility with director class scene changes.
--
-- 1.4 - Added an onStart parameter to the doTransition method.
--
-- 1.3 - Added table to hold all active timers (created with performAfterDelay) and functions to pause, resume and cancel all timers.
--
-- 1.2 - Added new functions: resetTimeCounter(), getCountedTime(), performAfterDelay() --> pauseable timers: replaces timer.performWithDelay()
--       The game.isActive variable now defaults to 'true' instead of 'false'.
--
-- 1.1 - Fixed Bug Where newRetinaText would not display proper text size.
--
-- ======
-- Usage:
-- ======
--
-- game = require( "beebegames" )
--
-- From there, everything is accessed via "game". If you define in main.lua and make it a
-- global object, you can use game.whatEver and pass variables (sucha as score, etc.) between
-- modules. Works great with Ricardo Rauber's Director Class.
--
--		.isActive = true	--> example: game.isActive = false;	--pause transitions, animations, movement, etc.
--		.gameScore = 0		--> example: game.gameScore = 0;	--can be used to easily pass score between modules
--
--
-- ========
-- METHODS:
-- ========
--
--
-- newObject( { imageTable }, width, height [, x, y, secondsBetweenFrames, fps60, alpha, parentGroup ] )
--		
--		object:startAnimation()
--		object:stopAnimation()
--		object:showFrame( frameNumber )
--		object:nextFrame()
--		object:doTransition( isFps60 [, { time (in seconds), x, y, xScale, yScale, onComplete } ] )
--		object:move( x, y )		--> move object relative to current location
--		object:moveTowards( x, y [, increment ])	--> move towards specific point; default increment is 1 (pixel)
--		object:getAngleTo( x, y )	--> Get angle from object to specified location
--		object:getDistanceTo( x, y )	--> returns distance (in pixels) from object to specified location
--		object:destroy()	--> removes event listener, calls removeSelf, and then garbage collects
--
--
-- newRetinaText( textString, x, y, fontName, fontSize, r, g, b, alignment, parentGroup )
--
--		textobject:updateText( textString )
--
--
-- commaThousands( amount )				--> example: local score = game.commaThousands( 2185 )	-- returns 2,185
--
-- saveValue( strFilename, strValue )	--> example: game.saveValue( "score.data", game.gameScore )
--
-- loadValue( strFilename )				--> example: local bestScore = game.loadValue( "score.data" )
--
-- resetTimeCounter()					--> starts a time counter.
--
-- getTimeCounted( timeCounter )		--> returns currently counted time (in milliseconds) -- must use resetTimeCounter() first.
--
-- performAfterDelay( secondsToWait, functionToCall, howManyTimes, isFps60 )	--> replaces timer.performWithDelay()
--
-- 		timerObject:pause()			--> timerObject created with performAfterDelay()
--
-- 		timerObject:resume()			--> timerObject created with performAfterDelay()
--	
-- 		timerObject:cancel()			--> timerObject created with performAfterDelay()
--
-- pauseAllTimers()
--
-- resumeAllTimers()			
--
-- cancelAllTimers()
--
-- listAllTimers()
--
-- destroyAllObjects()
--
-- newRandomTable( min, max, howMany )
--
-- pullFromRandomTable( randTable )
--
-- =========================================================================================

local mCeil = math.ceil
local mAtan2 = math.atan2
local mPi = math.pi
local mSqrt = math.sqrt
math.randomseed(os.time())	--> make random more random
local mRand = math.random
local tInsert = table.insert
local tRemove = table.remove
local tForEach = table.foreach

--=========================================================================================
--
-- Public Class Attributes
--
--=========================================================================================

isActive = true		--> when set to false, all animation stops (great for game pausing)
gameScore = 0		--> variable to store a game score value

activeTimers = {}	--> table that will hold active timers created with performAfterDelay()
objectsTable = {}	--> table that will hold all objects created with newObject()


--=========================================================================================
--
-- Public Method: commaThousands()	--> returns string with commas in the thousands digits
--
--=========================================================================================

function commaThousands(amount)
	amount = tonumber(amount)
	
	local formatted = amount
		while true do  
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if (k==0) then
			break
		end
	end
	
	return formatted
end


--===================================================================================
--
-- Public Method: saveValue()	--> save single-line file (replace contents)
--
--===================================================================================

function saveValue( strFilename, strValue )
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

--===================================================================================
--
-- Public Method: loadValue()	--> load single-line file and store it into variable
--
--===================================================================================

function loadValue( strFilename )
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



--===================================================================================
--
-- Retina Display Text (compatible with retina displays as well as older displays)
--
--===================================================================================

function newRetinaText( textString, x, y, fontName, fontSize, r, g, b, alignment, parentGroup )
	
	local doubleSize
	
	if not textString then textString = "Text"; end
	if not x then x = display.contentWidth * 0.5; end
	if not y then y = display.contentHeight * 0.5; end
	if not fontName then fontName = "Helvetica"; end
	if not fontSize then fontSize = 40; doubleSize = fontSize; else doubleSize = fontSize * 2; end
	if not r then r = 255; end
	if not g then g = 255; end
	if not b then b = 255; end
	if not alignment then alignment = "center"; end
	
	local textObject = display.newText( textString, x, y, fontName, doubleSize )
	textObject:setTextColor( r, g, b, 255 )
	textObject.text = textString
	textObject.xScale = 0.5; textObject.yScale = 0.5
	
	textObject.defaultX = x
	textObject.defaultY = y
	
	if alignment == "left" then
		textObject.x = x + ( textObject.contentWidth * 0.5 )
	elseif alignment == "center" then
		textObject.x = x
	elseif alignment == "right" then
		textObject.x = x - ( textObject.contentWidth * 0.5 )
	end
	
	textObject.y = y
	
	if parentGroup and type(parentGroup) == "table" then
		parentGroup:insert( textObject )
	end
	
	function textObject:updateText( textString )
		if not textString then textString = self.text; end
		
		self.text = textString
		self.xScale = 0.5; self.yScale = 0.5
		
		if alignment == "left" then
			textObject.x = self.defaultX + ( textObject.contentWidth * 0.5 )
		elseif alignment == "center" then
			textObject.x = self.defaultX
		elseif alignment == "right" then
			textObject.x = self.defaultX - ( textObject.contentWidth * 0.5 )
		end
		
		textObject.y = self.defaultY
	end
	
	return textObject
end

--===================================================================================
--
-- Time Counting
--
--===================================================================================

function resetTimeCounter()
	-- USAGE: local markTime = restTimeCounter()
	-- NEXT FUNCTION USAGE: local timeCounted = getTimeCounted() --in milliseconds
	
	local markTime = system.getTimer()
	
	return markTime
end

--

function getTimeCounted( timeCounter )
	
	local countedTime = system.getTimer() - timeCounter
	
	return countedTime
end

--===================================================================================
--
-- Pauseable Timer Library
--
--===================================================================================

function performAfterDelay( secondsToWait, functionToCall, howManyTimes, isFps60, timerNameString )
	
	-- USAGE: performAfterDelay( secondsToWait, functionToCall, howManyTimes, isFps60 )
	--
	-- This function differs from timer.performWithDelay in that you pass seconds (instead of milliseconds)
	-- and must specifiy if your app is set to run at 60 fps in your config.lua, if not, it defaults to 30
	
	local newTimer = {}
	local theFPS
	local iterations
	local isInfinite = false
	
	local frameCounter = 1
	local timerIsActive = true
	
	local maxFrameCount
	
	local theEvent = {}
	theEvent.name = "timer"
	theEvent.count = 0
	
	--newTimer.myPosition = #activeTimers + 1
	
	if timerNameString then
		newTimer.myName = timerNameString
	else
		newTimer.myName = "unnamed timer"
	end
	
	if not secondsToWait then
		secondsToWait = 1.0
	end
	
	if not howManyTimes then
		iterations = 1
	else
		iterations = howManyTimes
		
		if iterations == 0 then
			iterations = -1
			isInfinite = true
		end
	end
	
	if isFps60 then
		theFPS = 60
		maxFrameCount = mCeil(secondsToWait * 60)
	else
		theFPS = 30
		maxFrameCount = mCeil(secondsToWait * 30)
	end
	
	local timerListener = function( event )
		if timerIsActive then
			
			if not isInfinite then
				-- FINITE Amount of Timer Fires:
				
				if frameCounter >= maxFrameCount and iterations > 0 then
					frameCounter = 1				--> reset frame counter
					iterations = iterations - 1		--> decrement iterations
					
					theEvent.count = theEvent.count + 1	--> increment event count
					
					-- execute function passed as 'functionToCall'
					if functionToCall and type(functionToCall) == "function" then
						functionToCall( theEvent )
					end
					
				elseif frameCounter < maxFrameCount and iterations > 0 then
					-- increment frame count
					frameCounter = frameCounter + 1
				elseif iterations == 0 then
					
					-- stop counter
					newTimer:cancel()
				end
				
			else
				-- INFINITE Amount of Timer Fires:
				
				if frameCounter >= maxFrameCount then
					frameCounter = 1		--> reset frame counter
					theEvent.count = theEvent.count + 1	--> increment event count
					
					-- execute function passed as 'functionToCall'
					if functionToCall and type(functionToCall) == "function" then
						functionToCall( theEvent )
					end
				else
					frameCounter = frameCounter + 1
				end
				
			end
		end
	end
	
	function newTimer:enterFrame( event )
		self:repeatFunction( event )
	end
	
	function newTimer:cancel()
		frameCounter = 1
		timerIsActive = false
		Runtime:removeEventListener( "enterFrame", self )
		
		local removeEntry = function( _index )
			if activeTimers[_index] == self then
				tRemove( activeTimers, _index )
			end
		end
		
		--tRemove( activeTimers, self.myPosition )
		tForEach( activeTimers, removeEntry )
		
		--self.myPosition = nil
		self = nil
	end
	
	function newTimer:pause()
		-- These timers will be paused/resumed outside of normal game.isActive pausing features.
		-- They must be started, stoped, paused, and resumed individually.
		
		timerIsActive = false
	end
	
	function newTimer:resume()
		timerIsActive = true
	end
	
	newTimer.repeatFunction = timerListener
	Runtime:addEventListener( "enterFrame", newTimer )
	
	--activeTimers[ newTimer.myPosition ] = newTimer
	tInsert( activeTimers, newTimer )
	
	return newTimer
end

--===================================================================================
--
-- Pause, Resume, and Cancel All Timers
--
--===================================================================================

function pauseAllTimers()
	
	local i
	local activeTimerCount = #activeTimers
	
	if activeTimerCount > 0 then
		for i = activeTimerCount,1,-1 do
			local child = activeTimers[i]
			child:pause()
		end
	end
end

function resumeAllTimers()
	
	local i
	local activeTimerCount = #activeTimers
	
	if activeTimerCount > 0 then
		for i = activeTimerCount,1,-1 do
			local child = activeTimers[i]
			child:resume()
		end
	end
end

function cancelAllTimers()
	
	local i
	local activeTimerCount = #activeTimers
	
	if activeTimerCount > 0 then
		
		for i = activeTimerCount,1,-1 do
			local child = activeTimers[i]
			child:cancel()
			child = nil
		end
		
	end
end

function listAllTimers()	--> HELPFUL DEBUG FUNCTION
	
	local i
	local activeTimerCount = #activeTimers
	
	if activeTimerCount > 0 then
		
		print( "\n********** START LIST OF TIMERS **********\n" )
		
		for i = activeTimerCount,1,-1 do
			local child = activeTimers[i]
			print( "- Timer: " .. child.myName )
		end
		
		print( "\nNOTE: When unloading a module, you need to make sure to run cancel()" )
		print( "on all the timers listed above, MANUALLY. Also set them to nil. Afterwards," )
		print( "run cancelAllTimers() to clean everything up." )
		
		print( "\n**********  END LIST OF TIMERS  **********\n" )
	else
		print( "\n**********       NO TIMERS      **********\n" )
	end
end

--===================================================================================
--
-- Destroy all objects
--
--===================================================================================

function destroyAllObjects()
	
	local i
	local objectCount = #objectsTable
	
	if objectCount > 0 then
		for i = objectCount,1,-1 do
			local child = objectsTable[i]
			child:destroy( false )
			child = nil
		end
		
		local garbageCollect = function() collectgarbage("collect"); end
        timer.performWithDelay(1, garbageCollect, 1)  
	end
	
	objectsTable = nil
	objectsTable = {}
end

--===================================================================================
--
-- Random Tables (for preloading random values to boost performance)
--
--===================================================================================

function newRandomTable( min, max, howMany )
	-- ======================
	--
	-- USAGE
	--
	-- local myRandTable = newRandomTable( 10, 320, 25 )
	--
	-- local randValue = pullFromRandomTable( myRandTable )
	--
	-- ======================
	local mRand = mRand
	local randTable = {}
	randTable.indice = 1
	randTable.maxIndice = howMany
	
	local i
	
	for i = 1, howMany, 1 do
		randTable[i] = mRand( min, max )
	end
	
	return randTable
end

--

function pullFromRandomTable( randTable )
	local theIndice = randTable.indice
	local nextIndice = theIndice + 1
	local maxIndice = randTable.maxIndice
	
	local randomNumber = randTable[theIndice]
	
	if nextIndice > maxIndice then
		nextIndice = 1
	end
	
	randTable.indice = nextIndice
	
	return randomNumber
end

--=========================================================================================
--
-- Image Drawing and Frame-Based Animation
--
--=========================================================================================

function newObject( imageTable, width, height, x, y, secondsBetweenFrames, fps60, alpha, parentGroup )
	
	-- ====================
	-- 
	-- NOTES
	-- 
	-- x, y, alpha, secondsBetweenFrames, and fps60 params are optional.
	--
	-- If x,y are not set, then object will be created at the center of the screen.
	--
	-- If you want to set alpha, you must also set fps60 (set to false if you didn't modify config.lua)
	-- fps60 should be set to 'true' only if your app's config.lua settings are 60 FPS.
	--
	-- You must set an alpha attribute if you want to set the parentGroup.
	--
	-- ====================
	
	-- set up display group
	local object = display.newGroup()
	--object.myPosition = #objectsTable + 1
	--objectsTable[ object.myPosition ] = object
	tInsert( objectsTable, object )
	
	-- private variables
	local i; local isAnimation; local isAnimating
	local currentFrame; local drawCycle; local mSeconds
	local isFlipping
	
	-- for pauseable transitions
	object.isTransitioning = false
	local transitionCycle, maxTransitionCycle
	local xTransition, xIncrement
	local yTransition, yIncrement
	local xScaleTransition, xScaleIncrement
	local yScaleTransition, yScaleIncrement
	local onTransitionStart, onTransitionComplete
	-- end pauseable transitions
	
	local frame = {}
	local frameCount = #imageTable
	
	-- draw each object
	for i=1,frameCount do
		frame[i] = display.newImageRect( imageTable[i], width, height )
		object:insert( frame[i], true )
		
		frame[i].isVisible = false
	end
	
	-- set position
	if x and y then
		object.x = x; object.y = y
	else
		object.x = display.contentWidth * 0.5;
		object.y = display.contentHeight * 0.5;
	end
	
	-- set opacity (alpha)
	if alpha then
		object.alpha = alpha
	else
		object.alpha = 1.0
	end
	
	-- Initial Settings
	object:setReferencePoint( display.CenterReferencePoint )
	object.width = width; object.height = height
	frame[1].isVisible = true
	currentFrame = 1
	drawCycle = 1
	isFlipping = false
	
	-- Place in parentGroup (if set)
	if parentGroup and type(parentGroup) == "table" then
		parentGroup:insert( object )
	end
	
	-- Check to see if this object has an animation associated with it
	-- (depends on if secondsBetweenFrames paramater was set)
	if frameCount > 1 and secondsBetweenFrames then
		if fps60 then
			mSeconds = mCeil(secondsBetweenFrames * 60)	--> get milliseconds based on paramaters
		else
			mSeconds = mCeil(secondsBetweenFrames * 30)
		end
		isAnimation = true
		isAnimating = false		--> animation is not started by default
	else
		isAnimation = false
	end
	
	--===================================================================================
	--
	-- Private Methods
	--
	--===================================================================================
	
	local enterFrameListener = function( self, event )
		if isActive then
			-- ANIMATION
			if isAnimation and isAnimating and isActive then
				
				if drawCycle >= mSeconds then
					drawCycle = 1
					if isFlipping then
						self:nextFrame( true )	--> go to next animation frame
					else
						self:nextFrame()	--> go to next animation frame
					end
				else
					--> secondsBetweenFrames hasn't been reached, so increment drawCycle counter
					drawCycle = drawCycle + 1
				end
			end
			-- END ANIMATION
			
			----------
			
			-- TRANSITIONS
			
			if object.isTransitioning then
				if not xTransition and not yTransition and not xScaleTransition and not yScaleTransition and not widthTransition and not heightTransition then
					self.isTransitioning = false
				else
					if transitionCycle >= maxTransitionCycle then
						-- END THE TRANSITION
						
						self.isTransitioning = false
						transitionCycle = 1
						maxTransitionCycle = nil
						
						if xTransition then
							self.x = xTransition
							xTransition = nil
						end
						
						if yTransition then
							self.y = yTransition
							yTransition = nil
						end
						
						if xScaleTransition then
							self.xScale = xScaleTransition
							xScaleTransition = nil
						end
						
						if yScaleTransition then
							self.yScale = yScaleTransition
							yScaleTransition = nil
						end
						
						-- execute the onComplete event
						if onTransitionComplete and type(onTransitionComplete) == "function" then
							onTransitionComplete()
							--onTransitionComplete = nil
						end
					else
						-- Increment transition cycle
						transitionCycle = transitionCycle + 1
						
						-- X TRANSITIONS
						if xTransition then
							if self.x < xTransition then
								self:move( xIncrement, 0 )
							else
								self:move( -xIncrement, 0 )
							end
						end
						
						-- Y TRANSITIONS
						if yTransition then
							if self.y < yTransition then
								self:move( 0, yIncrement )
							else
								self:move( 0, -yIncrement )
							end
						end
						
						-- xSCALE TRANSITIONS
						if xScaleTransition then
							if self.xScale < xScaleTransition then
								self.xScale = self.xScale + (xScaleIncrement)
							else
								self.xScale = self.xScale - (xScaleIncrement)
							end
						end
						
						-- ySCALE TRANSITIONS
						if yScaleTransition then
							if self.yScale < yScaleTransition then
								self.yScale = self.yScale + (yScaleIncrement)
							else
								self.yScale = self.yScale - (yScaleIncrement)
							end
						end
						
					end
				end
			end
			-- END TRANSITIONS
		elseif not self then
			Runtime:removeEventListener( "enterFrame", self )
			--self = nil
		end
	end
	
	--===================================================================================
	--
	-- Public methods
	--
	--===================================================================================
	
	function object:enterFrame( event )
		self:repeatFunction( event )
	end
	
	object.repeatFunction = enterFrameListener
	Runtime:addEventListener( "enterFrame", object )
	
	function object:startAnimation( shouldFlip )
		isAnimating = true
		
		if shouldFlip then
			isFlipping = true
		else
			isFlipping = false
		end
	end
	
	--===================================================================================
	--
	--
	--===================================================================================
	
	function object:stopAnimation( seconds )
		isAnimating = false
		drawCycle = 1
	end
	
	--===================================================================================
	--
	--
	--===================================================================================
	
	function object:nextFrame( shouldFlip )
		-- shouldFlip is optional; if set to true, object will "flip" to next frame
		
		local theFrame = currentFrame
		local endFrame = frameCount
		if shouldFlip then
			local fxTime = 300
			local setInvisible = function() frame[currentFrame].isVisible = false; end
			
			local flipTween = transition.to( frame[currentFrame], { time=fxTime, xScale=0.001, onComplete=setInvisible } )
		else
			frame[currentFrame].isVisible = false	--> hide current frame
		end
		
		if theFrame >= endFrame then	--> on last frame, cycle back to the first
			theFrame = 1
			currentFrame = theFrame
		else							--> not on last frame, go to next
			theFrame = theFrame + 1
			currentFrame = theFrame
		end
		
		if shouldFlip then
			local fxTime = 300
			local setVisible = function() frame[currentFrame].isVisible = true; end
			
			local flipTween = transition.to( frame[currentFrame], { time=fxTime, xScale=1.0, onComplete=setVisible } )
		else
			frame[currentFrame].isVisible = true
		end
	end
	
	--===================================================================================
	--
	--
	--===================================================================================
	
	function object:showFrame( frameNumber )
		frameNumber = tonumber(frameNumber)
		
		frame[currentFrame].isVisible = false	--> hide current frame
		currentFrame = frameNumber
		frame[currentFrame].isVisible = true
	end
	
	--===================================================================================
	--
	--
	--===================================================================================
	
	function object:doTransition( isFps60, params )
		
		local resetTransitionValues = function()
			transitionCycle = nil
			maxTransitionCycle = nil
			object.isTransitioning = nil
			xTransition = nil
			xIncrement = nil
			yTransition = nil
			yIncrement = nil
			xScaleTransition = nil
			xScaleIncrement = nil
			yScaleTransition = nil
			yScaleIncrement = nil
			onTransitionStart = nil
			onTransitionComplete = nil
		end
		
		resetTransitionValues()
		
		if params.onStart then
			onTransitionStart = params.onStart
			-- execute the onComplete event
			if onTransitionStart and type(onTransitionStart) == "function" then
				onTransitionStart()
				--onTransitionStart = nil
			end
		end
		
		local seconds, transitionTime, fpsAmount, x, y, xScale, yScale, onComplete, onStart
		
		if params.time then
			seconds = params.time
			transitionTime = params.time			
		end
		
		if isFps60 then
			fpsAmount = 60
			
			if transitionTime then
				transitionTime = transitionTime * fpsAmount
			else
				transitionTime = fpsAmount		--> time = 1 second by default
			end
		else
			fpsAmount = 30
			
			if transitionTime then
				transitionTime = transitionTime * fpsAmount
			else
				transitionTime = fpsAmount		--> time = 1 second by default
			end
		end
		
		transitionCycle = 1
		maxTransitionCycle = transitionTime
		
		-- X
		if params.x then
			x = params.x
			xTransition = x
			
			local travelDistance
			
			if self.x < xTransition then
				travelDistance = xTransition - self.x
			else
				travelDistance = self.x - xTransition
			end
			
			xIncrement = (travelDistance / seconds) / fpsAmount
		end
		
		-- Y
		if params.y then
			y = params.y
			yTransition = y
			
			local travelDistance
			
			if self.y < yTransition then
				travelDistance = yTransition - self.y
			else
				travelDistance = self.y - yTransition
			end
			
			yIncrement = (travelDistance / seconds) / fpsAmount
		end
		
		-- XSCALE
		if params.xScale then
			xScale = params.xScale
			xScaleTransition = xScale
			
			local travelDistance
			
			if self.xScale < xScaleTransition then
				travelDistance = xScaleTransition - self.xScale
			else
				travelDistance = self.xScale - xScaleTransition
			end
			
			xScaleIncrement = (travelDistance / seconds) / fpsAmount
		end
		
		-- YSCALE
		if params.yScale then
			yScale = params.yScale
			yScaleTransition = yScale
			
			local travelDistance
			
			if self.yScale < yScaleTransition then
				travelDistance = yScaleTransition - self.yScale
			else
				travelDistance = self.yScale - yScaleTransition
			end
			
			yScaleIncrement = (travelDistance / seconds) / fpsAmount
		end
		
		if params.onComplete then
			onComplete = params.onComplete
			onTransitionComplete = onComplete
		end
		
		object.isTransitioning = true
	end
	
	--===================================================================================
	--
	--
	--===================================================================================
	
	function object:move( x, y )
		if isActive then
			-- move object relative to current x/y position
			local currentX = self.x
			local currentY = self.y
			
			self.x = self.x + (x)
			self.y = self.y + (y)
		end
	end
	
	--===================================================================================
	--
	--
	--===================================================================================
	
	function object:moveTowards( x, y, increment )
		if isActive then
			-- move object towards specified coordinates relative to current x/y position
			-- if optional increment parameter is NOT set, default is 1 (pixel)
			-- will return true if object is already at set coordinates
			
			local currentX = mCeil(self.x)
			local currentY = mCeil(self.y)
			local theIncrement
			local isThereX, isThereY
			
			if increment then
				theIncrement = increment
			else
				theIncrement = 1
			end
			
			local checkX = function()
				if currentX < x then
					local newIncrement
					
					if (x - currentX) < theIncrement then
						newIncrement = x - currentX
						
						print( newIncrement )
					else
						newIncrement = theIncrement
					end
					
					self.x = self.x + (newIncrement)
				elseif currentX > x then
					local newIncrement
					
					if (currentX - x) < theIncrement then
						newIncrement = currentX - x
						
						print( newIncrement )
					else
						newIncrement = theIncrement
					end
					
					self.x = self.x - (newIncrement)
				elseif currentX == x then
					isThereX = true
				end
			end
			
			local checkY = function()
				if currentY < y then
					local newIncrement
					
					if (y - currentY) < theIncrement then
						newIncrement = y - currentY
						
						print( newIncrement )
					else
						newIncrement = theIncrement
					end
					
					self.y = self.y + (newIncrement)
				elseif currentY > y then
					local newIncrement
					
					if (currentY - y) < theIncrement then
						newIncrement = currentY - y
						
						print( newIncrement )
					else
						newIncrement = theIncrement
					end
					
					self.y = self.y - (newIncrement)
				elseif currentY == y then
					isThereY = true
				end
			end
			
			checkX(); checkY()
			
			if isThereX and isThereY then
				return true
			else
				return false
			end
		end
	end
	
	--===================================================================================
	--
	--
	--===================================================================================
	
	function object:getAngleTo( x, y )
		-- Returns angle from object's location to given coordinates
		
		local currentX = self.x
		local currentY = self.y
		
		local angleTo = mCeil(mAtan2( (y - currentY), (x - currentX) ) * 180 / mPi) + 90
		
		return angleTo
	end
	
	--===================================================================================
	--
	--
	--===================================================================================
	
	function object:getDistanceTo( x, y )
		-- Returns distance (in pixels) from object's location to given coordinates.
		
		local currentX = self.x
		local currentY = self.y
		
		local theDistance = mCeil(mSqrt( ((y - currentY) * (y - currentY)) + ((x - currentX) * (x - currentX)) ))
		
		return theDistance
	end
	
	--===================================================================================
	--
	--
	--===================================================================================
	
	function object:destroy( shouldGarbageCollect )
		-- determine whether garbage collector should trigger after removing object
		if not shouldGarbageCollect then
			shouldGarbageCollect = false
		else
			shouldGarbageCollect = true
		end
		
		-- stop animation, remove event listener, and remove object from memory
		isAnimating = false
		object.isTransitioning = false
		Runtime:removeEventListener( "enterFrame", self )
		
		-- update objectsTable indexes
		--[[
		local i
		local maxObj = #objectsTable
		local thePos = self.myPosition
		
		-- reindex the objects table
		for i=1,maxObj,1 do
			if objectsTable[i].myPosition > thePos then
				objectsTable[i].myPosition = objectsTable[i].myPosition - 1
			end
		end
		
		-- update objectsTable
		tRemove( objectsTable, self.myPosition )
		]]--
		
		local removeEntry = function( _index )
			if objectsTable[_index] == self then
				tRemove( objectsTable, _index )
			end
		end
		
		tForEach( objectsTable, removeEntry )
		
		if shouldGarbageCollect then
			local garbageCollect = function() collectgarbage("collect"); end
        	local gbTimer = timer.performWithDelay(1, garbageCollect, 1) 
        end
	end
	
	-- Return the display group as the request new game object
	return object
end