
-- LUA Memory Game
--
-- by DSI
--


version = "1.1"
num_images = 50
num_cards = 18  -- multiple of 2
num_rows = 3    -- can divide num_cards
num_columns = num_cards / num_rows
card_gap = 7
selected_row = 1
selected_column = 1

myfont = Font.createProportional()
myfont:setPixelSizes(0,11)
y_fix = 9

matches = 0
turns = 0
first_card_turned = 0
second_card_turned = 0
quit_early = false

best = 100

black = Color.new(0,0,0)
white = Color.new(255,255,255)
red = Color.new(255,0,0)
green = Color.new(0,255,0)
blue = Color.new(0,0,255)

score_file  = "score.dat"
scroll_snd  = "sounds/scroll.wav"
turn_snd    = "sounds/turn.wav"
match_snd   = "sounds/match.wav"
background  = "misc/background.png"
cardback    = "misc/cardback.png"

card_image = {}
card_width = "?"
card_height = "?"

card = {}


-- END of global variables



function loadFiles()

  showLoading()
  loadSounds()
  loadImages()
  loadHighScore()

  -- Generate a random number seed based on the time
  -- Note: sometimes the first number is not random, so call it twice
  math.randomseed(os.time())
  math.randomseed(os.time())

end -- loadFiles



function showLoading()

  loadfont = Font.createProportional()
  loadfont:setPixelSizes(0,18)
  load_str = "Loading ..."
  x = (480 - 10*string.len(load_str)) / 2 + 1 
  y = (272 - 18) / 2 + 1
  screen:fontPrint(loadfont,x,y,load_str,green)
  screen.waitVblankStart() 
  screen:flip()

end -- showLoading




function loadImages()

  for i = 1, num_images do
    card_image[i] = Image.load("cards/card" .. i .. ".png")
  end	

  background = Image.load(background)
  cardback = Image.load(cardback)
  card_width = cardback:width()
  card_height = cardback:height()

end -- loadImages



function loadSounds()

  scroll_snd = Sound.load(scroll_snd)
  turn_snd = Sound.load(turn_snd)
  match_snd = Sound.load(match_snd)

end -- loadSounds


function getSelectedCardNum() 

	return (selected_row-1)*num_columns + selected_column
	
end -- getSelectedCardNum



function readInput()
	
	pad = Controls.read()

  -- Turn over card
	if pad:cross() or pad:circle() then
		current_card = getSelectedCardNum()

		-- If card not already matched and it's not already turned over, turn it over 
		if not card[current_card].matched and not card[current_card].turned_over then

			card[current_card].turned_over = true

			if first_card_turned == 0 then
				first_card_turned = current_card
				turn_snd:play()
        System.sleep(200)
			else 
				second_card_turned = current_card
				turns = turns + 1
        -- Don't play sound yet, determine if it is matched
        -- in drawEverything() first
			end	
		end

		waitForPadUp()

	end

	-- Quit game
	if pad:start() then
		waitForPadUp()
		quit_early = true
		return "quit"
	end

	-- Screenshot
	if pad:select() then
		screen:save("screenshot.png")
		waitForPadUp()
	end	

	if pad:up() then
		scroll_snd:play()
		setSelectedAbove()
		waitForPadUp()
	end

	if pad:down() then
		scroll_snd:play()
		setSelectedBelow()
		waitForPadUp()
	end	

	if pad:left() then
		scroll_snd:play()
		setSelectedLeft()
		waitForPadUp()
	end


	if pad:right() then
		scroll_snd:play()
		setSelectedRight()
		waitForPadUp()
	end
	
end -- readInput



-- Go to the next card above which is still unmatched
function setSelectedAbove()

	original_row = selected_row
	original_column = selected_column

	while true do
		
		-- If already at the topmost row
		if selected_row == 1 then
			selected_row = num_rows
		else
			selected_row = selected_row - 1
		end
		
		-- Keep moving if this card is matched / off the board
		if not card[getSelectedCardNum()].matched then
			break
		end

	end

	if selected_row == original_row and selected_column == original_column then
		setSelectedRight()
	end	

end -- setSelectedAbove


-- Go to the next card below which is still unmatched
function setSelectedBelow()

	original_row = selected_row
	original_column = selected_column

	while true do

		-- If already at the bottom row
		if selected_row == num_rows then
			selected_row = 1
		else 
			selected_row = selected_row + 1
		end

		-- Keep moving if this card is matched / off the board
		if not card[getSelectedCardNum()].matched then
			break
		end	

	end

	if selected_row == original_row and selected_column == original_column then
		setSelectedLeft()
	end	

end -- setSelectedBelow



-- Go to the next card on the left which is still unmatched
function setSelectedLeft()

	while true do

		-- If already at first column
		if selected_column == 1 then
			selected_column = num_columns
	
			-- If already at first row
			if selected_row == 1 then
				selected_row = num_rows
			else
				selected_row = selected_row - 1
			end

		else
			selected_column = selected_column - 1 
		end	
		
		-- Keep moving if this card is matched / off the board
		if not card[getSelectedCardNum()].matched then
			break
		end
		
	end

end -- setSelectedLeft



-- Go to the next card on the right which is still unmatched
function setSelectedRight()

	while true do

		-- If at rightmost
		if selected_column == num_columns then
			selected_column = 1
	
			-- If at last row
			if selected_row == num_rows then
				selected_row = 1
			else 
				selected_row = selected_row + 1
			end			
		else
			selected_column = selected_column + 1
		end

		-- Keep moving if this card is matched / off the board
		if not card[getSelectedCardNum()].matched then
			break
		end	

	end

end -- setSelectedRight






--
-- waitForPadUp:  Pauses execution till all buttons are released;
--								prevents scrolling too fast when pressing d-pad
--
-- This function is credited to Dark Killer at www.ps2dev.org
--
function waitForPadUp()

	pad = Controls.read()

	while pad:up() or pad:down() or pad:left() or pad:right() or pad:cross()
		or pad:circle() do

		pad = Controls.read()
	end

end -- waitForPadUp



function drawEverything()

	current_card = 0
	match_x = 0
	match_y = 0

	-- Draw background
	screen:blit(0, 0, background, 0, 0, background:width(), background:height(), false)

	-- Draw cards
	for row = 1,num_rows do

		x = card_gap
		y = (row-1)*card_height + row*card_gap

		for column = 1, num_columns do

			current_card = current_card + 1	

			if card[current_card].turned_over and (current_card == first_card_turned 
				or current_card == second_card_turned) and second_card_turned > 0 then
				
				-- Second card has been turned over, check for match	
				if card[first_card_turned].id == card[second_card_turned].id then
					card[current_card].matched = true
					
					-- Show cards on a match; they will be taken off the board the  next time 
					-- this function is called though 
					id = card[current_card].id
					screen:blit(x, y, card_image[id])

					if current_card == second_card_turned then
						matches = matches + 1
					end
				end
			end

			if card[current_card].turned_over and not card[current_card].matched then
				-- Show card if we turned it over 
				id = card[current_card].id
				screen:blit(x, y, card_image[id])

			elseif not card[current_card].matched then
				-- Show the back (don't show the cards if they're a match)
				screen:blit(x, y, cardback)
			end

			if row == selected_row and column == selected_column then
				-- Card is currently selected with d-pad
				screen:fillRect(x-4, y-4, card_width+8, 4, black)
				screen:fillRect(x-4, y, 4, card_height, black)
				screen:fillRect(x+card_width, y, 4, card_height, black)
				screen:fillRect(x-4, y+card_height, card_width+8, 4, black)
			end

			x = x + card_width + card_gap

		end -- column
	end -- row


	-- Status messages

	screen:fontPrint(myfont,300, 100+y_fix, "  v" .. version .. " By DSI", black)
	screen:fontPrint(myfont,310, 140+y_fix, "MATCHED: " .. matches .. "/" .. num_cards/2, black)
	screen:fontPrint(myfont,310, 160+y_fix, "TURNS:   " .. turns, black)
	screen:fontPrint(myfont,310, 180+y_fix, "BEST:    " .. best, black)

	screen:fontPrint(myfont,300, 210+y_fix, "CONTROLS:", black)
	screen:fontPrint(myfont,300, 230+y_fix, "- D-pad to move", black)
	screen:fontPrint(myfont,300, 240+y_fix, "- CROSS or CIRCLE to select", black)
	screen:fontPrint(myfont,300, 250+y_fix, "- START to quit", black)

	if first_card_turned == 0 then
		status_string = "Pick first card"
		screen:fontPrint(myfont,10, 250+y_fix, status_string, black)
		screen.waitVblankStart()
		screen:flip()
	elseif second_card_turned == 0 then
		status_string = "Pick second card"
		screen:fontPrint(myfont,10, 250+y_fix, status_string, black)
		screen.waitVblankStart()	
		screen:flip()
	elseif second_card_turned > 0 then

		if not card[second_card_turned].matched then
			status_string = "Sorry, no match"
			turn_snd:play()
      System.sleep(500)
			screen:fontPrint(myfont,10, 250+y_fix, status_string, black)		
			screen.waitVblankStart()	
			screen:flip()
			screen.waitVblankStart(90)
			
			card[first_card_turned].turned_over = false
			card[second_card_turned].turned_over = false
		else
			status_string = "Match found!"
			match_snd:play()
			screen:fontPrint(myfont,10, 250+y_fix, status_string, black)		
			screen.waitVblankStart()	
			screen:flip()
			screen.waitVblankStart(120)

			if not gameEnd() then
				if selected_column == num_columns then
					setSelectedLeft()
				else	
					setSelectedRight()
				end
			end	
		end

		first_card_turned = 0 
		second_card_turned = 0
	end

	
end -- drawEverything


	

function initDeck() 

	for i = 1,(num_cards/2) do
		card[i] = { turned_over = false, matched = false, id = i }

		-- The next half of cards have the same ID as those in the  first half
		-- (matched cards)
		card[i + num_cards/2] = { turned_over = false, matched = false, id = i }
	end

	matches = 0
	turns = 0
	first_card_turned = 0
	second_card_turned = 0
	quit_early = false

end -- initDeck



function shuffleDeck()

	-- Shuffle all of the card *images*
	-- (There may be more images than those that are to be played)
	for i = 1,num_images do
	
		-- Swap current card with a random card in the set of images
		rand = math.random(1,num_images)

		temp = card_image[i]
		card_image[i] = card_image[rand]
		card_image[rand] = temp

	end


	-- Shuffle the IDs of the cards in the deck to be played
	for i = 1,num_cards do
	
		-- Swap current card with a random card in the deck
		rand = math.random(1,num_cards)

		if card[i].id ~= card[rand].id then
			temp = card[i].id
			card[i].id = card[rand].id
			card[rand].id = temp
		end

	end

end -- shuffleDeck


function gameEnd()

	if matches == num_cards/2 then
		return true
	else
		return false
	end	

end -- gameEnd



function gameOverScreen()

	screen:blit(0, 0, background, 0, 0, background:width(), background:height(), false)
	screen:fontPrint(myfont,300, 100+y_fix, "  v" .. version .. " By DSI", black)

  -- Successfully finished game
	if not quit_early then 
		screen:fontPrint(myfont,310, 140+y_fix, "GAME OVER", black)
		screen:fontPrint(myfont,310, 160+y_fix, "TURNS:   " .. turns, black)

		if turns < best then
			best = turns
			screen:fontPrint(myfont,310, 180+y_fix, "NEW HIGH SCORE!", black)
			saveHighScore()	
		else
			screen:fontPrint(myfont,310, 180+y_fix, "BEST:    " .. best, black)
		end	
	
	else

    -- We quit before finishing game
		screen:fontPrint(myfont,310, 160+y_fix, "GAME OVER", black)

		current_card = 0

		for row = 1,num_rows do

			x = card_gap
			y = (row-1)*card_height + row*card_gap

			for column = 1, num_columns do
				
				current_card = current_card + 1	
							
				if not card[current_card].matched then
					screen:blit(x, y, card_image[card[current_card].id])
				end

				x = x + card_width + card_gap			
			end

		end
	end

	screen:fontPrint(myfont,300, 210+y_fix, "Paypal donations: ", black)
	screen:fontPrint(myfont,300, 220+y_fix, "dislam@rocketmail.com", black)
	screen:fontPrint(myfont,10, 250+y_fix, "Press TRIANGLE to restart; HOME to quit", black)

	screen.waitVblankStart()	
	screen:flip()

	-- Triangle to restart
	while not Controls.read():triangle() do

    -- Screenshot
		if Controls.read():select() then
			screen:save("screenshot_end.png")
			waitForPadUp()
		end
	end
	
end -- gameOverScreen


function loadHighScore() 

	-- open file for reading
	file = io.open(score_file, "r")

	-- file not found
	if file == nil then	
		saveHighScore()

	-- if file found then grab the high score
	else
		best = file:read("*n")
	  file:close()
	end

end -- loadHighScore


function saveHighScore()

	file = io.open(score_file, "w")

	if file then
		file:write(best)
		file:close()
	end

end -- saveHighScore






---------------------
-- Main program 
---------------------

loadFiles()

while true do

	initDeck()
	shuffleDeck()

	while true do
		drawEverything()
	
		if gameEnd() or readInput() == "quit" then
			break
		end

	end

	gameOverScreen()

end

