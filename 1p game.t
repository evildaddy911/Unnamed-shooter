/*
 PlayerHunter game
 by Matt Fraser (2013)
 for ICS 4U 2013 (Mr. Baxter)

 DESCRIPTION
 - uses parallel turn stystem where each player determines their actions parallel to each other before their actions are excuted simultaneously
 - move your character, then select which angle to shoot at -- YOU CANNOT SEE WHERE THE OTHER PLAYERS HAVE MOVED OR WHERE THEY ARE AIMING
 -- multiple players CAN occupy the same location at the same time
 - once all players have completed the above, calculate any hits, award points and respawn any dead players

 POINTS
 - 3 points for killing an enemy
 - -1 point for getting killed
 */

View.Set ("graphics:1000,600; nobuttonbar; title:ICS 4U Culminating")

var mouseNow, mouseLast : % a custom type to hold the state of the mouse
    record
	x, y, b : int
    end record
type COORDS : % a custom type to hold coordinates of a player
    record
	x, y : int
    end record

var grid : array 1 .. 40, 1 .. 30 of int     % 0=walkable; -1=water; -2=wall; >0=player spawn
type PLAYER : % custom type to hold player data
    record
	points : int     % score
	hit : boolean     % if player has been hit this round
	prev : array 1 .. 3 of COORDS     % where player was last 3 turns
	now, spawn : COORDS     % where player is now, where player spawns
	clr : int     % which color to draw player in
	angle : real     % angle to shoot at
	lastMove : int     % which direction player moved last (used for AI)
	name : string     % the player's name
    end record
var player : array 1 .. 10 of PLAYER % stores each of the players' data

var emptyPic, waterPic, wallPic : int % picture ID's of each square
var playerPic : array 1 .. 10 of int % pictures of each player
var file : int % the file object to use for I/O
var dist : int % #squares player can move in one turn
var accuracy : real := 1.0 % --- NOT IMPLEMENTED ---
var turn : int % which player's turn it is
var stage : int % which part of the turn (move, aim, next turn/results)
var moves : int % how many moves are left in that turn
var numHumans : int % how many human players
var ans : string % used for text-based questions
var numPlayers : int % how many total players
var endGame : int := 5 % game ends when the average score is >= endGame

procedure loadTexture (file : int)     % loads the texture
    View.Set ("invisible") % hides the output window
    var empty_, water, wall : array 1 .. 10, 1 .. 10 of int % which color to use for each square in the texture
    var player : array 1 .. 10, 1 .. 10, 1 .. 10 of int % which color to use for each of the players' textures
    for x : 1 .. 10 % load the texture data from the texture file
	for y : 1 .. 10
	    read : file, empty_ (x, y)
	    read : file, water (x, y)
	    read : file, wall (x, y)
	    for i : 1 .. 10
		read : file, player (i, x, y)
	    end for
	end for
    end for
    close : file

    for tile : 1 .. 13
	for x : 1 .. 10     % draws each square of the selected tile
	    for y : 1 .. 10
		case tile of
		    label 1 :
			drawfillbox (x * 2, y * 2, x * 2 + 2, y * 2 + 2, empty_ (x, y))
		    label 2 :
			drawfillbox (x * 2, y * 2, x * 2 + 2, y * 2 + 2, water (x, y))
		    label 3 :
			drawfillbox (x * 2, y * 2, x * 2 + 2, y * 2 + 2, wall (x, y))
		    label :
			drawfillbox (x * 2, y * 2, x * 2 + 2, y * 2 + 2, player (tile - 3, x, y))
		end case
	    end for
	end for
	case tile of % store the drawn texture as a picture and assign it's ID to the different texture variables
	    label 1 :
		emptyPic := Pic.New (2, 2, 22, 22)
	    label 2 :
		waterPic := Pic.New (2, 2, 22, 22)
	    label 3 :
		wallPic := Pic.New (2, 2, 22, 22)
	    label :
		playerPic (tile - 3) := Pic.New (2, 2, 22, 22)
	end case
    end for
    cls % basically resets the output window
    View.Set ("popup")
end loadTexture

function realAngle (x1, y1, x2, y2 : real) : real % returns the angle (in degreees) from (x1,y1) to (x2,y2) from -90 to +270
    if x1 = x2 then
	if y1 > y2 then
	    result 270
	elsif y1 < y2 then
	    result 90
	else
	    result 0
	end if
    else
	var temp : real := arctand ((y2 - y1) / (x2 - x1))
	if x1 > x2 then
	    temp += 180
	end if
	result temp
    end if
end realAngle

procedure drawMap () % simply draws the map and all the players
    for i : 1 .. 40
	for j : 1 .. 30
	    case grid (i, j) of     % draws the different tiles
		label - 2 :     % draws the different tiles
		    Pic.Draw (wallPic, (i - 1) * 20, (j - 1) * 20, picCopy)     % wall
		label - 1 :
		    Pic.Draw (waterPic, (i - 1) * 20, (j - 1) * 20, picCopy)     % water
		label :
		    Pic.Draw (emptyPic, (i - 1) * 20, (j - 1) * 20, picCopy)     % walkable
	    end case
	    for k : 1 .. numPlayers     % draws the player's positions from last turn
		if k = turn then
		    if i = player (k).now.x and j = player (k).now.y then
			Pic.Draw (playerPic (k), (i - 1) * 20, (j - 1) * 20, picCopy)
		    end if
		else
		    if i = player (k).prev (3).x and j = player (k).prev (3).y then
			Pic.Draw (playerPic (k), (i - 1) * 20, (j - 1) * 20, picCopy)
		    end if
		end if
	    end for
	end for
    end for
end drawMap

procedure listMoves (x, y, movesLeft : int, var checked_ : array 1 .. 40, 1 .. 30 of boolean) % outputs all possible moves starting at (x,y) in the varable 'checked_'
    checked_ (x, y) := true     % current square is accessible

    if movesLeft <= 0 then
	return     % exit when there are no moves remaining
    end if

    if x > 1 and grid (x - 1, y) >= 0 then  % if it is possible to move left, check those tiles
	listMoves (x - 1, y, movesLeft - 1, checked_) % recursive calls
    end if
    if x < 39 and grid (x + 1, y) >= 0 then
	listMoves (x + 1, y, movesLeft - 1, checked_)
    end if
    if y > 1 and grid (x, y - 1) >= 0 then
	listMoves (x, y - 1, movesLeft - 1, checked_)
    end if
    if y < 29 and grid (x, y + 1) >= 0 then
	listMoves (x, y + 1, movesLeft - 1, checked_)
    end if

end listMoves

procedure AI (pNum : int) % the main procedure for the AI players

    moves := Rand.Int (0, dist)
    var startTime : int := Time.Elapsed
    loop
	var direction : int := Rand.Int (1, 12)     % choose a random direction
	if direction > 4 then     % 75% chance to repeat last move
	    direction := player (pNum).lastMove
	end if
	case direction of     % move AI if valid move
	    label 1 : % move upwards
		if player (pNum).now.y + 1 <= 30 and grid (player (pNum).now.x, player (pNum).now.y + 1) >= 0 then
		    player (pNum).now.y += 1
		    player (pNum).lastMove := 1
		    moves -= 1
		end if
	    label 2 : % left
		if player (pNum).now.x - 1 > 0 and grid (player (pNum).now.x - 1, player (pNum).now.y) >= 0 then
		    player (pNum).now.x -= 1
		    player (pNum).lastMove := 2
		    moves -= 1
		end if
	    label 3 : % right
		if player (pNum).now.x + 1 <= 40 and grid (player (pNum).now.x + 1, player (pNum).now.y) >= 0 then
		    player (pNum).now.x += 1
		    player (pNum).lastMove := 3
		    moves -= 1
		end if
	    label 4 : % downwards
		if player (pNum).now.y - 1 > 0 and grid (player (pNum).now.x, player (pNum).now.y - 1) >= 0 then
		    player (pNum).now.y -= 1
		    player (pNum).lastMove := 4
		    moves -= 1
		end if
	end case
	exit when moves <= 0 or Time.Elapsed - startTime >= 125
    end loop

    /*
     CURRENT AI AIMING DETAILS

     1- chooses a random target
     2- uses the 2 previous turns to determine the target's direction of travel
     3- creates a list of all possible locations the target could be in
     4- cross-references that array with the direction of travel to make a list of most likely locations for the target
     5- if the likelyMoves array is empty, fill it with any possible moves
     6- creates an array with locations that are hittable from pNum's location and are also in the likelyMoves array
     7- if the hittable array is empty, repeat steps 1 through 7 for a maximum of 0.75 seconds
     */

    var aim : COORDS % which square to aim at
    startTime := Time.Elapsed   % used to set a time limit on the AI
    var lastTarget : int := 0 % which player the person targeted last attempt (initialized as zero so that each player has a fair chance to be targeted)
    loop
	var target : int % which player to target this turn
	loop     % don't allow AI to target itself
	    target := Rand.Int (1, numPlayers)
	    exit when target ~= pNum and target ~= lastTarget % exit when the target is neither itself or the person it had targeted the previous attempt
	end loop
	var move : array 1 .. 40, 1 .. 30 of boolean     % stores which squares are accessible to the target
	for x : 1 .. 40
	    for y : 1 .. 30
		move (x, y) := false     % set all to false for now
	    end for
	end for

	listMoves (player (target).prev (3).x, player (target).prev (3).y, dist, move)
	var moveList : flexible array 1 .. 0 of COORDS
	for x : 1 .. 40
	    for y : 1 .. 30
		if move (x, y) then     % uses the move array to create a list of possible moves
		    new moveList, upper (moveList) + 1
		    moveList (upper (moveList)).x := x
		    moveList (upper (moveList)).y := y
		end if
	    end for
	end for
	var moveAngle : real     % which direction the target has been travelling the past 2 turns

	if player (target).prev (1).x = player (target).prev (3).x and player (target).prev (1).y = player (target).prev (3).y then
	    moveAngle := Rand.Real * 360     % if the player is in the same location it was 2 turns ago (or if it has just respawned)
	else     % extrapolates target's previous locations to determine where it might be this turn
	    moveAngle := realAngle (player (target).prev (1).x, player (target).prev (1).y, player (target).prev (3).x, player (target).prev (3).y)
	end if

	var likelyMoves : flexible array 1 .. 0 of COORDS     % cross-reference the moveList with the direction the target has traveled the previous 2 turns
	for d : 0 .. 2 * dist     % makes sure it gets every square
	    for m : 1 .. upper (moveList)
		if moveList (m).x = round (d / 2 * cosd (moveAngle)) + player (target).prev (3).x and moveList (m).y = round (d / 2 * cosd (moveAngle)) + player (target).prev (3).y then
		    new likelyMoves, upper (likelyMoves) + 1
		    likelyMoves (upper (likelyMoves)) := moveList (m)
		end if
	    end for
	end for

	if upper (likelyMoves) = 0 then
	    % if the target cannot continue travelling the same direction, target a moveable location that is also hittable
	    new likelyMoves, upper (moveList)
	    for i : 1 .. upper (moveList)
		likelyMoves (i) := moveList (i)
	    end for
	end if

	% create a create a list of hittable locations also in the likelyMoves list
	var hittable : flexible array 1 .. 0 of COORDS % a list of arrays containing each location that is hittable from the AI's current location
	var blt :  % stores where the bullet is currently located
	    record
		x, y : real
	    end record
	for l : 1 .. upper (likelyMoves) % checks if each location in 'likelyMoves' is hittable from the AI's location
	    var angle : real := realAngle (player (pNum).now.x, player (pNum).now.y, likelyMoves (l).x, likelyMoves (l).y)
	    blt.x := player (pNum).now.x % bullet starts at AI's current location
	    blt.y := player (pNum).now.y

	    loop
		blt.x += .5 * cosd (angle) % advance the bullet 0.5 squares
		blt.y += .5 * sind (angle)
		exit when blt.x < 1 or blt.x > 40 or blt.y < 0 or blt.y > 30 or grid (round (blt.x), round (blt.y)) = -2     % exit when a bullet hits a wall or exits the grid
		if round (blt.x) = likelyMoves (l).x and round (blt.y) = likelyMoves (l).y then
		    % if the bullet hits the target square before hitting a wall, add the location to the hittable array
		    new hittable, upper (hittable) + 1
		    hittable (upper (hittable)) := likelyMoves (l)
		    exit
		end if
	    end loop
	end for

	if upper (hittable) ~= 0 then
	    % exit when there is a hittable location
	    aim := hittable (Rand.Int (1, upper (hittable))) % choose a random location from the hittable array
	    player (pNum).angle := realAngle (player (pNum).now.x, player (pNum).now.y, aim.x, aim.y) % set the angle
	    exit
	end if

	exit when Time.Elapsed - startTime >= 750     % maximum of 0.75 seconds per CPU player

	lastTarget := target
    end loop
end AI

procedure centerText (text : string, x, y, font, clr : int)
    Font.Draw (text, x - Font.Width (text, font) div 2, y, font, clr)
end centerText

procedure rules % displays the rules and controls etc.
    drawfillbox (0, 0, maxx, maxy, black)
    var f := Font.New ("Arial:13")
    centerText ("Rules and Controls", 500, 580, f, white)
    centerText ("Each player will take turns moving their character to a square of their choice before taking aim in any direction they please", 500, 550, f, white)
    centerText ("Your objective is to shoot the other players without getting hit yourself", 500, 530, f, white)
    centerText ("When moving and aiming, pay attention to the map. Players cannot pass through water or walls, but bullets can pass over water", 500, 510, f, white)
    centerText ("Players who have already moved this round will be displayed in their locations from LAST turn", 500, 490, f, white)
    centerText ("During the Aiming Stage, use the buttons (on the right-hand panel) or the arrow keys to move", 500, 470, f, white)
    centerText ("You have a limited number of moves each round. To undo, press \"Q\"", 500, 450, f, white)
    centerText ("Once you have used all of your moves, or press the \"Done\" button, you will move over to the Aiming Stage", 500, 430, f, white)
    centerText ("During the Aiming Stage, use the buttons (on the right-hand panel) or click on a square to move the target line", 500, 410, f, white)
    centerText ("When usig the mouse to aim, the target line will jump around randomly. This is to help revent sniping from across the map", 500, 390, f, white)
    centerText ("When you are satisfied with your aim, press the \"Done\" button", 500, 370, f, white)
    centerText ("If playing with multiple human players, give control over to the next person", 500, 350, f, white)
    centerText ("Once all players have gone (any extra players are computer-controlled), the Results screen will be dsiplayed", 500, 330, f, white)
    centerText ("All players will be displayed in their new positions, and their target lines will also be displayed", 500, 310, f, white)
    centerText ("If you have sucsessfully hit another player, you will be awarded 3 points for every player you hit", 500, 290, f, white)
    centerText ("If you were hit, you will lose 1 point (for every hit taken that round) and will respawn in your original position", 500, 270, f, white)
    centerText ("Press \"Escape\" to resume your game", 500, 250, f, white)
    View.Update
    delay (1000) % rules are displayed for a minimum of 1 second
    loop % delay execution until escape is pressed
	if hasch then % check if any key is pressed
	    var k : string (1)
	    getch (k) % get the key pressed
	    exit when k = KEY_ESC % if that key was 'ESCAPE', exit the loop
	end if
    end loop
end rules

loop % allows game to reset
    View.Set ("nooffscreenonly")
    open : file, "Texture.txr", read
    loadTexture (file) % load the texture file

    var numMaps : int := 0
    loop % determine how many maps are in the folder
	exit when ~File.Exists (intstr (numMaps + 1) + ".map")
	numMaps += 1
    end loop
    var map : int := Rand.Int (1, numMaps) % choose a random map
    % load the map
    open : file, intstr (map) + ".map", read % read the selected map's data
    for i : 1 .. 40
	for j : 1 .. 30
	    read : file, grid (i, j)
	    for k : 1 .. 10
		if grid (i, j) = k then
		    player (k).spawn.x := i
		    player (k).spawn.y := j
		end if
	    end for
	end for
    end for
    % initialize player's variables
    player (1).clr := brightblue
    player (2).clr := brightred
    player (3).clr := brightgreen
    player (4).clr := brightcyan
    player (5).clr := purple
    player (6).clr := grey
    player (7).clr := brown
    player (8).clr := brightmagenta
    player (9).clr := yellow
    player (10).clr := white
    for i : 1 .. 10
	player (i).points := 0
	player (i).hit := false
	for j : 1 .. 3
	    player (i).prev (j) := player (i).spawn
	end for
	player (i).now := player (i).spawn
	player (i).angle := 0
	player (i).lastMove := Rand.Int (1, 4)
    end for

    dist := 5   % #squares player can move in one turn
    accuracy := 1   % #degrees [not used]
    turn := 1   % whose turn it is
    stage := 1   % which part of the turn it is (move / aim)
    moves := dist  % how many moves left
    put "How many players total (2-10)?"
    loop
	get ans
	exit when strintok (ans) and strint (ans) >= 2 and strint (ans) <= 10 % exit the loop when we have valid input
	put "Invalid input. Must be an integer from 2 to 10"
    end loop
    numPlayers := strint (ans)
    put ""
    put "How many human players (1-", numPlayers, ")?"
    loop
	get ans
	exit when strintok (ans) and strint (ans) >= 0 and strint (ans) <= numPlayers % exit the loop when we have valid input
	put "Invalid input. Must be an integer from 1 to ", numPlayers
    end loop
    numHumans := strint (ans)
    put ""
    for i : 1 .. numPlayers % loop through each of the players and allow players to name them
	loop
	    put "Enter player #", i, "'s name"
	    get player (i).name : *
	    exit when player (i).name ~= ""
	    put "Ya gotta enter something.... How would YOU feel if you didnt have a name?"
	    put ""
	end loop
	put ""
    end for

    rules % start by displaying the rules
    View.Set ("offscreenonly")

    loop

	mousewhere (mouseNow.x, mouseNow.y, mouseNow.b) % get the mouse state
	if turn > numHumans then % once all the human players have gone, its the AIs' turns
	    AI (turn)
	    moves := dist
	    stage := 3
	end if
	centerText (player (turn).name + "'s turn", 900, 575, defFontID, player (turn).clr) % display which player's turn it is
	case stage of
	    label 1 : % if stage = 1 then

		drawMap
		if moves > 0 then
		    centerText ("Movement Stage", 900, 550, defFontID, black)
		    % draws the texture (in case the texture doesnt make it obvious)
		    centerText ("Water", 840, 525, defFontID, black)
		    Pic.Draw (waterPic, 830, 500, picCopy)
		    centerText ("Wall", 880, 525, defFontID, black)
		    Pic.Draw (wallPic, 870, 500, picCopy)
		    centerText ("Air", 920, 525, defFontID, black)
		    Pic.Draw (emptyPic, 910, 500, picCopy)
		    centerText ("P" + intstr (turn), 960, 525, defFontID, player (turn).clr)
		    Pic.Draw (playerPic (turn), 950, 500, picCopy)

		    centerText ("Moves left: " + intstr (moves), 900, 417, defFontID, black) % output # moves left
		    centerText ("Score: " + intstr (player (turn).points), 900, 403, defFontID, black) % output current player's score

		    % up button
		    drawfillbox (855, 305, 945, 395, player (turn).clr) % draw the box in the current player's color
		    Draw.ThickLine (900, 325, 900, 375, 10, black) % arrow
		    Draw.ThickLine (900, 375, 875, 350, 10, black)
		    Draw.ThickLine (900, 375, 925, 350, 10, black)
		    Draw.ThickLine (856, 305, 945, 305, 3, black) % shading
		    Draw.ThickLine (945, 305, 945, 394, 3, black)
		    % left button
		    drawfillbox (805, 205, 895, 295, player (turn).clr)
		    Draw.ThickLine (825, 250, 875, 250, 10, black)
		    Draw.ThickLine (825, 250, 850, 275, 10, black)
		    Draw.ThickLine (825, 250, 850, 225, 10, black)
		    Draw.ThickLine (806, 205, 895, 205, 3, black)
		    Draw.ThickLine (895, 205, 895, 294, 3, black)
		    % right button
		    drawfillbox (905, 205, 995, 295, player (turn).clr)
		    Draw.ThickLine (925, 250, 975, 250, 10, black)
		    Draw.ThickLine (975, 250, 950, 275, 10, black)
		    Draw.ThickLine (975, 250, 950, 225, 10, black)
		    Draw.ThickLine (906, 205, 995, 205, 3, black)
		    Draw.ThickLine (995, 205, 995, 294, 3, black)
		    % down button
		    drawfillbox (855, 105, 945, 195, player (turn).clr)
		    Draw.ThickLine (900, 125, 900, 175, 10, black)
		    Draw.ThickLine (900, 125, 925, 150, 10, black)
		    Draw.ThickLine (900, 125, 875, 150, 10, black)
		    Draw.ThickLine (856, 105, 945, 105, 3, black)
		    Draw.ThickLine (945, 105, 945, 194, 3, black)
		    % end the moving stage
		    drawfillbox (805, 5, 995, 95, player (turn).clr)
		    Draw.ThickLine (806, 5, 995, 5, 3, black)
		    Draw.ThickLine (995, 5, 995, 94, 3, black)
		    centerText ("DONE", 900, 45, defFontID, black)
		    % help button
		    drawbox (985, 580, 995, 595, black)
		    centerText ("?", 990, 583, defFontID, black)

		    % checks the controls, make sure it is valid move, then moves player
		    if hasch then
			var k : string (1)
			getch (k)
			Font.Draw (k, 5, maxy - 15, defFontID, black) % output k [debugging]
			% key controls
			if k = KEY_ENTER then % end movement
			    moves := -1
			elsif k = "q" then % undo moves
			    moves := dist
			    player (turn).now := player (turn).prev (3)
			elsif k = KEY_UP_ARROW and player (turn).now.y < 30 and grid (player (turn).now.x, player (turn).now.y + 1) >= 0 then
			    moves -= 1 % move up
			    player (turn).now.y += 1
			elsif k = KEY_LEFT_ARROW and player (turn).now.x > 1 and grid (player (turn).now.x - 1, player (turn).now.y) >= 0 then
			    moves -= 1 % move left
			    player (turn).now.x -= 1
			elsif k = KEY_RIGHT_ARROW and player (turn).now.x < 40 and grid (player (turn).now.x + 1, player (turn).now.y) >= 0 then
			    moves -= 1 % move right
			    player (turn).now.x += 1
			elsif k = KEY_DOWN_ARROW and player (turn).now.y > 1 and grid (player (turn).now.x, player (turn).now.y - 1) >= 0 then
			    moves -= 1 % move down
			    player (turn).now.y -= 1
			end if
		    end if
		    if mouseNow.b ~= 0 and mouseLast.b = 0 then % mouse controls
			if mouseNow.x > 855 and mouseNow.x < 945 and mouseNow.y > 305 and mouseNow.y < 395 and player (turn).now.y < 30 and grid (player (turn).now.x, player (turn).now.y + 1) >= 0
				then % UP button
			    moves -= 1
			    player (turn).now.y += 1
			elsif mouseNow.x > 805 and mouseNow.x < 895 and mouseNow.y > 205 and mouseNow.y < 295 and player (turn).now.x > 1 and grid (player (turn).now.x - 1, player (turn).now.y) >= 0
				then % LEFT button
			    moves -= 1
			    player (turn).now.x -= 1
			elsif mouseNow.x > 905 and mouseNow.x < 995 and mouseNow.y > 205 and mouseNow.y < 295 and player (turn).now.x < 40 and grid (player (turn).now.x + 1, player (turn).now.y) >= 0
				then % RIGHT button
			    moves -= 1
			    player (turn).now.x += 1
			elsif mouseNow.x > 855 and mouseNow.x < 945 and mouseNow.y > 105 and mouseNow.y < 195 and player (turn).now.y > 1 and grid (player (turn).now.x, player (turn).now.y - 1) >= 0
				then % DOWN button
			    moves -= 1
			    player (turn).now.y -= 1
			elsif mouseNow.x > 805 and mouseNow.x < 995 and mouseNow.y > 5 and mouseNow.y < 95 then
			    moves := -1 % DONE button
			elsif mouseNow.x > 985 and mouseNow.x < 995 and mouseNow.y > 580 and mouseNow.y < 595 then
			    rules % HELP button
			end if
		    end if
		else
		    loop     % makes sure you don't accidentally click anything in the next stage
			mousewhere (mouseNow.x, mouseNow.y, mouseNow.b)
			exit when mouseNow.b = 0
		    end loop
		    moves := dist
		    stage := 2
		    player (turn).angle := 0
		end if
	    label 2 :

		drawMap
		drawline (round (500 * cosd (player (turn).angle)) + player (turn).now.x * 20 - 10, round (500 * sind (player (turn).angle)) + player (turn).now.y * 20 - 10, player (turn).now.x * 20
		    - 10, player (turn).now.y * 20 - 10, player (turn).clr)                               % aiming line
		drawfillbox (801, 0, 1000, 600, white)     % clear the side panel (just in case something went wrong)
		centerText ("Aiming Stage", 900, 550, defFontID, black)
		% draws the texture (in case its something messed up)
		centerText ("Water", 840, 525, defFontID, black)
		Pic.Draw (waterPic, 830, 500, picCopy)
		centerText ("Wall", 880, 525, defFontID, black)
		Pic.Draw (wallPic, 870, 500, picCopy)
		centerText ("Air", 920, 525, defFontID, black)
		Pic.Draw (emptyPic, 910, 500, picCopy)
		centerText ("P" + intstr (turn), 960, 525, defFontID, player (turn).clr)
		Pic.Draw (playerPic (turn), 950, 500, picCopy)

		centerText ("Score: " + intstr (player (turn).points), 900, 403, defFontID, black) % display score and angle you are aiming at
		Font.Draw ("Angle: " + realstr (player (turn).angle, 1), 825, 417, defFontID, black)
		% CCW box
		drawfillbox (805, 255, 995, 345, player (turn).clr) % move angle counter-clockwise
		Draw.ThickLine (806, 255, 995, 255, 3, black) % shading
		Draw.ThickLine (995, 255, 995, 344, 3, black)
		centerText ("CCW", 900, 295, defFontID, black)
		% CW box
		drawfillbox (805, 155, 995, 245, player (turn).clr)
		Draw.ThickLine (806, 155, 995, 155, 3, black)
		Draw.ThickLine (995, 155, 995, 244, 3, black)
		centerText ("CW", 900, 195, defFontID, black)
		% OK box
		drawfillbox (805, 55, 995, 145, player (turn).clr) % angle is good
		Draw.ThickLine (806, 55, 995, 55, 3, black)
		Draw.ThickLine (995, 55, 995, 144, 3, black)
		centerText ("DONE", 900, 95, defFontID, black)

		drawbox (985, 580, 995, 595, black) % help button
		centerText ("?", 990, 583, defFontID, black)

		% check controls
		if mouseNow.b ~= 0 then
		    if mouseNow.x > 805 and mouseNow.x < 995 and mouseNow.y > 255 and mouseNow.y < 345 then
			player (turn).angle := player (turn).angle + 0.5
			if player (turn).angle > 360 then     % keeps angle under 360
			    player (turn).angle -= 360
			end if
		    elsif mouseNow.x > 805 and mouseNow.x < 995 and mouseNow.y > 155 and mouseNow.y < 245 then
			player (turn).angle := player (turn).angle - 0.5
			if player (turn).angle < 0 then
			    player (turn).angle += 360     % keeps angle positive
			end if
		    elsif mouseNow.x > 805 and mouseNow.x < 995 and mouseNow.y > 55 and mouseNow.y < 145 then
			loop     % makes sure you don't accidentally click anything in the next stage
			    mousewhere (mouseNow.x, mouseNow.y, mouseNow.b)
			    exit when mouseNow.b = 0 % exit loop when mouse button is released
			end loop
			moves := dist
			stage := 3
		    elsif mouseNow.x > 0 and mouseNow.x < 800 and mouseNow.y > 0 and mouseNow.y < 600 then
			% aim with mouse (with random offest)
			var noise : real := 1 % this is how much the angle can be off by (helps prevent sniping)
			player (turn).angle := realAngle ((player (turn).now.x) * 20 - 10, (player (turn).now.y) * 20 - 10, mouseNow.x, mouseNow.y) + 2 * noise * Rand.Real - noise
		    elsif mouseLast.b = 0 and mouseNow.x > 985 and mouseNow.x < 995 and mouseNow.y > 580 and mouseNow.y < 595 then
			rules % rules button
		    end if
		end if

	    label :
		if turn = numPlayers then     % checks if its time to output the results

		    for i : 1 .. numPlayers
			% move players to their new positions
			player (i).prev (1) := player (i).prev (2)
			player (i).prev (2) := player (i).prev (3)
			player (i).prev (3) := player (i).now
		    end for
		    drawMap % redraw the map


		    for i : 1 .. numPlayers
			% check for any kills
			var x, y : real
			x := player (i).now.x * 20 - 10 % initial positions of the bullet
			y := player (i).now.y * 20 - 10
			loop
			    exit when x <= 1 or x >= 799 or y <= 0 or y >= 599 or grid (x div 20 + 1, y div 20 + 1) = -2     % exit when shot goes out of the grid or if it hits a wall
			    x += cosd (player (i).angle)      % advance the shot
			    y += sind (player (i).angle)
			end loop
			drawline (player (i).now.x * 20 - 10, player (i).now.y * 20 - 10, round (x), round (y), player (i).clr) % shot line

			for j : 1 .. numPlayers     % check if the shot hit a player
			    if j ~= i and Math.DistancePointLine (player (j).now.x * 20 - 10, player (j).now.y * 20 - 10, x, y, player (i).now.x * 20 - 10, player (i).now.y * 20 - 10) <= 8 then
				player (i).points += 3
				player (j).points -= 1
				player (j).hit := true
			    end if
			end for
		    end for

		    drawfillbox (801, 0, 1000, 600, white)     % clear the right-hand panel

		    for i : 1 .. numPlayers     % respawn players (if needed) after shot calculation is finished
			if player (i).hit then
			    player (i).now := player (i).spawn
			    for j : 1 .. 3
				player (i).prev (j) := player (i).spawn
			    end for
			end if
			player (i).hit := false
		    end for

		    % output the results
		    centerText ("RESULTS", 900, 550, defFontID, black)
		    % draws the texture
		    centerText ("Water", 850, 525, defFontID, black)
		    Pic.Draw (waterPic, 840, 500, picCopy)
		    centerText ("Wall", 900, 525, defFontID, black)
		    Pic.Draw (wallPic, 890, 500, picCopy)
		    centerText ("Air", 950, 525, defFontID, black)
		    Pic.Draw (emptyPic, 940, 500, picCopy)
		    for p : 1 .. numPlayers
			Pic.Draw (playerPic (p), 805, 500 - 25 * p, picCopy)
			Font.Draw (player (p).name + ": " + intstr (player (p).points), 830, 505 - 25 * p, defFontID, black)
		    end for

		    drawfillbox (805, 0, 995, 100, black)     % next button
		    Draw.ThickLine (805, 100, 994, 100, 3, grey) % shading
		    Draw.ThickLine (805, 1, 805, 100, 3, grey)
		    centerText ("Next Round", 900, 45, defFontID, white)

		    /*drawfillbox (805, 105, 995, 205, black)     % end game button
		     Draw.ThickLine (805, 205, 994, 205, 3, grey) % shading
		     Draw.ThickLine (805, 106, 805, 205, 3, grey)
		     centerText ("Quit game", 900, 150, defFontID, white)*/

		    drawbox (985, 580, 995, 595, black) % help button
		    centerText ("?", 990, 583, defFontID, black)

		    View.Update
		    var done : boolean := false
		    loop % pause execution until a button is clicked
			mousewhere (mouseNow.x, mouseNow.y, mouseNow.b)

			/*if mouseNow.b ~= 0 and mouseNow.x > 805 and mouseNow.x < 995 and mouseNow.y > 105 and mouseNow.y < 205 then
			 done := true
			 exit
			 els*/
			if mouseNow.b ~= 0 and mouseLast.b = 0 then
			    if mouseNow.x > 805 and mouseNow.x < 995 and mouseNow.y > 0 and mouseNow.y < 100 then
				turn := 1 % next button
				stage := 1
				loop % wait until the mutton is released
				    mousewhere (mouseNow.x, mouseNow.y, mouseNow.b)
				    exit when mouseNow.b = 0
				end loop
				exit
			    elsif mouseNow.x > 985 and mouseNow.x < 995 and mouseNow.y > 580 and mouseNow.y < 595 then
				rules % display the rules
			    end if
			end if
		    end loop
		    exit when done
		    % exit game loop when the average of the player's points is greater than endgame
		    var total : int := 0
		    for i : 1 .. numPlayers
			total += player (i).points
		    end for
		    exit when total / numPlayers >= endGame

		    turn := 1
		    stage := 1
		else     % if all turns aren't finished, go to the next turn
		    turn += 1
		    stage := 1
		end if
	end case


	if hasch then
	    var k : string (1)
	    getch (k)
	    if k = "`" then         % shows current location of each player and where they are aiming [cheatzes!]
		for i : 1 .. turn - 1
		    drawfilloval (player (i).now.x * 20 - 10, player (i).now.y * 20 - 10, 5, 5, player (i).clr)  % location
		    drawline (round (500 * cosd (player (i).angle)) + player (i).now.x * 20 - 10, round (500 * sind (player (i).angle)) + player (i).now.y * 20 - 10, player (i).now.x * 20 -
			10, player (i).now.y * 20 - 10, player (i).clr) % aiming line
		end for
	    end if
	end if
	View.Update
	mouseLast := mouseNow
	cls
    end loop

    drawfillbox (0, 0, maxx, maxy, white)
    var f : int := Font.New ("Arial:30:Bold")
    centerText ("GAME OVER", 500, 550, f, white) % standard GAME OVER

    % sort players highest score to lowest (using bubble sort because im only sorting a few items... and im too lazy to implement anything more complex)
    loop
	var done : boolean
	done := true
	for i : 1 .. numPlayers - 1
	    if player (i).points < player (i + 1).points then
		var temp : PLAYER
		temp := player (i)
		player (i) := player (i + 1)
		player (i + 1) := temp
		done := false
	    end if
	end for
	exit when done
    end loop

    var str : string
    % output the scores
    str := "In FIRST PLACE with " + intstr (player (1).points) + " point"
    if player (1).points = 1 then
	str := str + ":" % I did it this way so that it wouldnt say "1 points"
    else
	str := str + "s:"
    end if
    centerText (str, 502, 493, f, darkgrey) % shadow
    centerText (player (1).name, 502, 448, f, darkgrey)
    centerText (str, 500, 495, f, player (1).clr) % actually draws the text
    centerText (player (1).name, 500, 450, f, player (1).clr) % displays the player's name
    % ^^ repeated for top 3 players ^^
    str := "In SECOND PLACE with " + intstr (player (2).points) + " point"
    if player (2).points = 1 then
	str := str + ":"
    else
	str := str + "s:"
    end if
    centerText (str, 502, 368, f, darkgrey)
    centerText (player (2).name, 502, 323, f, darkgrey)
    centerText (str, 500, 370, f, player (2).clr)
    centerText (player (2).name, 500, 325, f, player (2).clr)

    if numPlayers > 2 then % error prevention
	str := "In THIRD PLACE with " + intstr (player (3).points) + " point"
	if player (3).points = 1 then
	    str := str + ":"
	else
	    str := str + "s:"
	end if
	centerText (str, 502, 243, f, darkgrey)
	centerText (player (3).name, 502, 198, f, darkgrey)
	centerText (str, 500, 245, f, player (3).clr)
	centerText (player (3).name, 500, 200, f, player (3).clr)
    end if

    centerText ("Press \"ESCAPE\" to quit the game. Press any other key to reset program", 500, 75, Font.New ("Arial:20:Bold"), black)
    View.Update
    var done : boolean := false
    loop % pause execution until a key is pressed
	if hasch then
	    var k : string (1)
	    getch (k)
	    if k = KEY_ESC then % if escape is pressed, end game
		done := true
	    end if
	    exit
	end if
    end loop
    exit when done
end loop

Window.Hide (Window.GetSelect) % hide the window (it just looks better)
