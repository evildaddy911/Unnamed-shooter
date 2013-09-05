View.Set ("graphics:1000,600")

var mouseNow, mouseLast :
    record
	x, y, b : int
    end record
var grid : array 1 .. 40, 1 .. 30 of int % 0=walkable; -1=water; -2=wall; >0=player spawn
var player : array 1 .. 4 of
    record
	deaths, kills : int % #times been shot; #shots hit
	hit : boolean % if player has been hit this round
	prevX, prevY : array 1 .. 3 of int % where player was last 3 turns
	nowX, nowY : int % where player is now
	spawnX, spawnY : int % where player spawns
	clr : int % which color to draw player in
	angle : real % angle to shoot at
	lastMove : int % which direction player moved last (used for AI)
    end record

var emptyPic, waterPic, wallPic : int
var playerPic : array 1 .. 4 of int

procedure loadTexture (file : int) % loads the texture
    View.Set ("invisible")
    var empty_, water, wall : array 1 .. 10, 1 .. 10 of int
    var player : array 1 .. 4, 1 .. 10, 1 .. 10 of int
    for x : 1 .. 10
	for y : 1 .. 10
	    read : file, empty_ (x, y)
	    read : file, water (x, y)
	    read : file, wall (x, y)
	    for i : 1 .. 4
		read : file, player (i, x, y)
	    end for
	end for
    end for
    close : file

    for tile : 1 .. 7
	for x : 1 .. 10     % draws each square of the selected tile
	    for y : 1 .. 10
		case tile of
		    label 1 :
			drawfillbox (x * 2, y * 2, x * 2 + 2, y * 2 + 2, empty_ (x, y))
		    label 2 :
			drawfillbox (x * 2, y * 2, x * 2 + 2, y * 2 + 2, water (x, y))
		    label 3 :
			drawfillbox (x * 2, y * 2, x * 2 + 2, y * 2 + 2, wall (x, y))
		    label 4 :
			drawfillbox (x * 2, y * 2, x * 2 + 2, y * 2 + 2, player (1, x, y))
		    label 5 :
			drawfillbox (x * 2, y * 2, x * 2 + 2, y * 2 + 2, player (2, x, y))
		    label 6 :
			drawfillbox (x * 2, y * 2, x * 2 + 2, y * 2 + 2, player (3, x, y))
		    label :
			drawfillbox (x * 2, y * 2, x * 2 + 2, y * 2 + 2, player (4, x, y))
		end case
	    end for
	end for
	case tile of
	    label 1 :
		emptyPic := Pic.New (2, 2, 22, 22)
	    label 2 :
		waterPic := Pic.New (2, 2, 22, 22)
	    label 3 :
		wallPic := Pic.New (2, 2, 22, 22)
	    label 4 :
		playerPic (1) := Pic.New (2, 2, 22, 22)
	    label 5 :
		playerPic (2) := Pic.New (2, 2, 22, 22)
	    label 6 :
		playerPic (3) := Pic.New (2, 2, 22, 22)
	    label :
		playerPic (4) := Pic.New (2, 2, 22, 22)
	end case
    end for
    cls
    View.Set ("popup")
end loadTexture


var file : int
open : file, "Texture.txr", read
loadTexture (file)

var numMaps : int := 0
loop
    exit when ~File.Exists (intstr (numMaps + 1) + ".map")
    numMaps += 1
end loop
var map : int := Rand.Int (1, numMaps)
% load the map
open : file, intstr (map) + ".map", read
for i : 1 .. 40
    for j : 1 .. 30
	read : file, grid (i, j)
	for k : 1 .. 4
	    if grid (i, j) = k then
		player (k).spawnX := i
		player (k).spawnY := j
	    end if
	end for
    end for
end for
% initialize player's variables
player (1).clr := brightblue
player (2).clr := brightred
player (3).clr := brightgreen
player (4).clr := brightcyan
for i : 1 .. 4
    player (i).deaths := 0
    player (i).kills := 0
    player (i).hit := false
    for j : 1 .. 3
	player (i).prevX (j) := player (i).spawnX
	player (i).prevY (j) := player (i).spawnY
    end for
    player (i).nowX := player (i).spawnX
    player (i).nowY := player (i).spawnY
    player (i).angle := 0
    player (i).lastMove := Rand.Int (1, 4)
end for

const dist : int := 4     % #squares player can move in one turn
const accuracy : real := 1     % #degrees [not used]
var turn : int := 1     % whose turn it is
var stage : int := 1     % which part of the turn it is (move / aim)
var moves : int := dist     % how many moves left
var numPlayers : int % how many human players
var ans : string % used for text-based questions
put "How many human players (1-4)?"
loop
    get ans
    exit when strintok (ans) and strint (ans) >= 1 and strint (ans) <= 4
    put "Invalid input. must be an integer from 1 to 4"
end loop
numPlayers := strint (ans)

function realAngle (x1, y1, x2, y2 : real) : real
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

procedure drawMap ()
    for i : 1 .. 40
	for j : 1 .. 30
	    case grid (i, j) of     % draws the different tiles
		label - 2 :     % draws the different tiles
		    Pic.Draw (wallPic, (i - 1) * 20, (j - 1) * 20, picCopy) % wall
		label - 1 :
		    Pic.Draw (waterPic, (i - 1) * 20, (j - 1) * 20, picCopy) % water
		label :
		    Pic.Draw (emptyPic, (i - 1) * 20, (j - 1) * 20, picCopy) % walkable
	    end case
	    for k : 1 .. 4     % draws the player's positions from last turn
		if k = turn then
		    if i = player (k).nowX and j = player (k).nowY then
			Pic.Draw (playerPic (k), (i - 1) * 20, (j - 1) * 20, picCopy)
		    end if
		else
		    if i = player (k).prevX (3) and j = player (k).prevY (3) then
			Pic.Draw (playerPic (k), (i - 1) * 20, (j - 1) * 20, picCopy)
		    end if
		end if
	    end for
	end for
    end for
end drawMap

procedure AI (pNum : int)
    moves := dist
    loop
	var direction : int := Rand.Int (1, 6)     % choose a random direction
	if direction > 4 then     % 50% chance to repeat last move
	    direction := player (pNum).lastMove
	end if
	case direction of     % move AI if valid move
	    label 1 :
		if grid (player (pNum).nowX, player (pNum).nowY + 1) >= 0 then
		    player (pNum).nowY += 1
		    player (pNum).lastMove := 1
		    moves -= 1
		end if
	    label 2 :
		if grid (player (pNum).nowX - 1, player (pNum).nowY) >= 0 then
		    player (pNum).nowX -= 1
		    player (pNum).lastMove := 2
		    moves -= 1
		end if
	    label 3 :
		if grid (player (pNum).nowX + 1, player (pNum).nowY) >= 0 then
		    player (pNum).nowX += 1
		    player (pNum).lastMove := 3
		    moves -= 1
		end if
	    label 4 :
		if grid (player (pNum).nowX, player (pNum).nowY - 1) >= 0 then
		    player (pNum).nowY -= 1
		    player (pNum).lastMove := 4
		    moves -= 1
		end if
	end case
	exit when moves <= 0
    end loop

    var target : int         % which player to target this turn
    loop         % don't allow CPU to target itself
	target := Rand.Int (1, 4)
	exit when target ~= pNum
    end loop

    var moveAngle : real := realAngle (player (target).prevX (1), player (target).prevY (1), player (target).prevX (3), player (target).prevY (3))
    var aimX : int := round (Rand.Real * dist * cosd (moveAngle) + player (target).prevX (3))
    var aimY : int := round (Rand.Real * dist * cosd (moveAngle) + player (target).prevY (3))
    player (pNum).angle := realAngle (player (pNum).nowX, player (pNum).nowY, aimX, aimY)

    % puts the shot up to 'dist' blocks off of the targeted player's previous position
    moves := dist
    stage := 3
end AI

var window : int

View.Set ("offscreenonly")
loop

    mousewhere (mouseNow.x, mouseNow.y, mouseNow.b)
    if turn > numPlayers then
	AI (turn)
    end if
    Font.Draw ("Player " + intstr (turn) + "'s turn", 900 - Font.Width ("Player " + intstr (turn) + "'s turn", defFontID) div 2, 575, defFontID, player (turn).clr)
    case stage of
	label 1 :
	    drawMap
	    if moves > 0 then
		Font.Draw ("Movement Stage", 900 - Font.Width ("Movement Stage", defFontID) div 2, 550, defFontID, black)
		% draws the texture
		Font.Draw ("Wtr", 805, 475, defFontID, black)
		Pic.Draw (waterPic, 805, 450, picCopy)
		Font.Draw ("Wall", 840, 475, defFontID, black)
		Pic.Draw (wallPic, 840, 450, picCopy)
		Font.Draw ("P1", 875, 475, defFontID, black)
		Pic.Draw (playerPic (1), 875, 450, picCopy)
		Font.Draw ("P2", 910, 475, defFontID, black)
		Pic.Draw (playerPic (2), 910, 450, picCopy)
		Font.Draw ("P3", 945, 475, defFontID, black)
		Pic.Draw (playerPic (3), 945, 450, picCopy)
		Font.Draw ("P4", 980, 475, defFontID, black)
		Pic.Draw (playerPic (4), 980, 450, picCopy)

		Font.Draw ("Moves left: " + intstr (moves), 900 - Font.Width ("Moves left: " + intstr (moves), defFontID) div 2, 417, defFontID, black)
		Font.Draw ("K/D: " + intstr (player (turn).kills) + "/" + intstr (player (turn).deaths), 900 - Font.Width ("K/D: " + intstr (player (turn).kills) + "/" +
		    intstr (player (turn).deaths), defFontID) div 2, 403, defFontID, black)
		% up button
		drawfillbox (855, 305, 945, 395, player (turn).clr)
		Draw.ThickLine (900, 325, 900, 375, 10, black)
		Draw.ThickLine (900, 375, 875, 350, 10, black)
		Draw.ThickLine (900, 375, 925, 350, 10, black)
		% left button
		drawfillbox (805, 205, 895, 295, player (turn).clr)
		Draw.ThickLine (825, 250, 875, 250, 10, black)
		Draw.ThickLine (825, 250, 850, 275, 10, black)
		Draw.ThickLine (825, 250, 850, 225, 10, black)
		% right button
		drawfillbox (905, 205, 995, 295, player (turn).clr)
		Draw.ThickLine (925, 250, 975, 250, 10, black)
		Draw.ThickLine (975, 250, 950, 275, 10, black)
		Draw.ThickLine (975, 250, 950, 225, 10, black)
		% down button
		drawfillbox (855, 105, 945, 195, player (turn).clr)
		Draw.ThickLine (900, 125, 900, 175, 10, black)
		Draw.ThickLine (900, 125, 925, 150, 10, black)
		Draw.ThickLine (900, 125, 875, 150, 10, black)

		drawfillbox (805, 5, 995, 95, player (turn).clr) % skips the moving stage
		Font.Draw ("DONE", 900 - Font.Width ("DONE", defFontID) div 2, 45, defFontID, black)

		% checks for the buttons being clicked, makes sure it is valid move, then moves player
		if mouseNow.b ~= 0 and mouseLast.b = 0 then
		    if mouseNow.x > 855 and mouseNow.x < 945 and mouseNow.y > 305 and mouseNow.y < 395 and player (turn).nowY < 30 and grid (player (turn).nowX, player (turn).nowY + 1) >= 0 then
			moves -= 1
			player (turn).nowY += 1
		    end if
		    if mouseNow.x > 805 and mouseNow.x < 895 and mouseNow.y > 205 and mouseNow.y < 295 and player (turn).nowX > 1 and grid (player (turn).nowX - 1, player (turn).nowY) >= 0 then
			moves -= 1
			player (turn).nowX -= 1
		    end if
		    if mouseNow.x > 905 and mouseNow.x < 995 and mouseNow.y > 205 and mouseNow.y < 295 and player (turn).nowX < 40 and grid (player (turn).nowX + 1, player (turn).nowY) >= 0 then
			moves -= 1
			player (turn).nowX += 1
		    end if
		    if mouseNow.x > 855 and mouseNow.x < 945 and mouseNow.y > 105 and mouseNow.y < 195 and player (turn).nowY > 1 and grid (player (turn).nowX, player (turn).nowY - 1) >= 0 then
			moves -= 1
			player (turn).nowY -= 1
		    end if
		    if mouseNow.x > 805 and mouseNow.x < 995 and mouseNow.y > 5 and mouseNow.y < 95 then
			moves := -1
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
	    drawline (round (500 * cosd (player (turn).angle)) + player (turn).nowX * 20 - 10, round (500 * sind (player (turn).angle)) + player (turn).nowY * 20 - 10, player (turn).nowX * 20 -
		10, player (turn).nowY * 20 - 10, player (turn).clr)                    % aiming line
	    drawfillbox (801, 0, 1000, 600, white)     % clear the side panel
	    Font.Draw ("Aiming Stage", 900 - Font.Width ("Aiming Stage", defFontID) div 2, 550, defFontID, black)
	    % draws the texture
	    Font.Draw ("Wtr", 805, 475, defFontID, black)
	    Pic.Draw (waterPic, 805, 450, picCopy)
	    Font.Draw ("Wall", 840, 475, defFontID, black)
	    Pic.Draw (wallPic, 840, 450, picCopy)
	    Font.Draw ("P1", 875, 475, defFontID, black)
	    Pic.Draw (playerPic (1), 875, 450, picCopy)
	    Font.Draw ("P2", 910, 475, defFontID, black)
	    Pic.Draw (playerPic (2), 910, 450, picCopy)
	    Font.Draw ("P3", 945, 475, defFontID, black)
	    Pic.Draw (playerPic (3), 945, 450, picCopy)
	    Font.Draw ("P4", 980, 475, defFontID, black)
	    Pic.Draw (playerPic (4), 980, 450, picCopy)

	    Font.Draw ("K/D: " + intstr (player (turn).kills) + "/" + intstr (player (turn).deaths), 900 - Font.Width ("K/D: " + intstr (player (turn).kills) + "/" +
		intstr (player (turn).deaths), defFontID) div 2, 403, defFontID, black)
	    Font.Draw ("Angle: " + realstr (player (turn).angle, 1), 825, 417, defFontID, black)
	    % CCW box
	    drawfillbox (805, 255, 995, 345, player (turn).clr)
	    Font.Draw ("CCW", 900 - Font.Width ("CCW", defFontID) div 2, 295, defFontID, black)
	    % CW box
	    drawfillbox (805, 155, 995, 245, player (turn).clr)
	    Font.Draw ("CW", 900 - Font.Width ("CW", defFontID) div 2, 195, defFontID, black)
	    % OK box
	    drawfillbox (805, 55, 995, 145, player (turn).clr)
	    Font.Draw ("DONE", 900 - Font.Width ("DONE", defFontID) div 2, 95, defFontID, black)

	    % checks for buttons being clicked
	    if mouseNow.b ~= 0 then
		if mouseNow.x > 805 and mouseNow.x < 995 and mouseNow.y > 255 and mouseNow.y < 345 then
		    player (turn).angle := player (turn).angle + 0.5
		    if player (turn).angle > 360 then     % keeps angle under 360
			player (turn).angle -= 360
		    end if
		end if
		if mouseNow.x > 805 and mouseNow.x < 995 and mouseNow.y > 155 and mouseNow.y < 245 then
		    player (turn).angle := player (turn).angle - 0.5
		    if player (turn).angle < 0 then
			player (turn).angle += 360     % keeps angle positive
		    end if
		end if
		if mouseNow.x > 805 and mouseNow.x < 995 and mouseNow.y > 55 and mouseNow.y < 145 then
		    loop     % makes sure you don't accidentally click anything in the next stage
			mousewhere (mouseNow.x, mouseNow.y, mouseNow.b)
			exit when mouseNow.b = 0
		    end loop
		    moves := dist
		    stage := 3
		end if
	    end if

	label :
	    if turn = 4 then     % checks if its time to output the results
		for i : 1 .. 4
		    % move players to their new positions
		    player (i).prevX (1) := player (i).prevX (2)
		    player (i).prevY (1) := player (i).prevY (2)
		    player (i).prevX (2) := player (i).prevX (3)
		    player (i).prevY (2) := player (i).prevY (3)
		    player (i).prevX (3) := player (i).nowX
		    player (i).prevY (3) := player (i).nowY
		end for
		drawMap     % redraw the map
		for i : 1 .. 4     % draw the shot lines
		    drawline (round (1000 * cosd (player (i).angle)) + player (i).nowX * 20 - 10, round (1000 * sind (player (i).angle)) + player (i).nowY * 20 - 10, player (i).nowX * 20 - 10,
			player (i).nowY * 20 - 10, player (i).clr)     % shot line
		end for
		drawfillbox (801, 0, 1000, 600, white)     % clear the right-hand panel

		for i : 1 .. 4
		    % check for any kills
		    var x, y : real
		    x := player (i).nowX * 20 - 10     % initial positions of the bullet
		    y := player (i).nowY * 20 - 10
		    loop
			exit when x < 0 or x > 800 or y < 0 or y > 600 or grid (x div 20 + 1, y div 20 + 1) = -2     % exit when shot goes out of the grid or if it hits a wall
			x += 2 * cosd (player (i).angle)     % move the shot
			y += 2 * sind (player (i).angle)
		    end loop

		    for j : 1 .. 4 % check if the shot hit a player
			if j ~= i and Math.DistancePointLine (player (j).nowX * 20 - 10, player (j).nowY * 20 - 10, x, y, player (i).nowX * 20 - 10, player (i).nowY * 20 - 10) < 8 then
			    player (i).kills += 1
			    player (j).deaths += 1
			    player (j).hit := true
			end if
		    end for
		end for
		for i : 1 .. 4 % respawn players (if needed) after shot calculation is finished
		    if player (i).hit then
			player (i).nowX := player (i).spawnX
			player (i).nowY := player (i).spawnY
			for j : 1 .. 3
			    player (i).prevX (j) := player (i).spawnX
			    player (i).prevY (j) := player (i).spawnY
			end for
		    end if
		    player (i).hit := false
		end for

		% output the results
		Font.Draw ("RESULTS", 900 - Font.Width ("RESULTS", defFontID) div 2, 550, defFontID, black)
		% draws the texture
		Font.Draw ("Wtr", 805, 475, defFontID, black)
		Pic.Draw (waterPic, 805, 450, picCopy)
		Font.Draw ("Wall", 840, 475, defFontID, black)
		Pic.Draw (wallPic, 840, 450, picCopy)
		Font.Draw ("P1", 875, 475, defFontID, black)
		Pic.Draw (playerPic (1), 875, 450, picCopy)
		Font.Draw ("P2", 910, 475, defFontID, black)
		Pic.Draw (playerPic (2), 910, 450, picCopy)
		Font.Draw ("P3", 945, 475, defFontID, black)
		Pic.Draw (playerPic (3), 945, 450, picCopy)
		Font.Draw ("P4", 980, 475, defFontID, black)
		Pic.Draw (playerPic (4), 980, 450, picCopy)

		Font.Draw ("Player 1 K/D: " + intstr (player (1).kills) + "/" + intstr (player (1).deaths), 810, 400, defFontID, black)
		Font.Draw ("Player 2 K/D: " + intstr (player (2).kills) + "/" + intstr (player (2).deaths), 810, 375, defFontID, black)
		Font.Draw ("Player 3 K/D: " + intstr (player (3).kills) + "/" + intstr (player (3).deaths), 810, 350, defFontID, black)
		Font.Draw ("Player 4 K/D: " + intstr (player (4).kills) + "/" + intstr (player (4).deaths), 810, 325, defFontID, black)

		drawfillbox (805, 200, 995, 300, black)     % next button
		Font.Draw ("Next Turn", 900 - Font.Width ("Next Turn", defFontID) div 2, 245, defFontID, white)
		View.Update
		loop
		    mousewhere (mouseNow.x, mouseNow.y, mouseNow.b)
		    if mouseNow.b ~= 0 and mouseNow.x > 805 and mouseNow.x < 995 and mouseNow.y > 200 and mouseNow.y < 300 then
			turn := 1
			stage := 1
			loop
			    mousewhere (mouseNow.x, mouseNow.y, mouseNow.b)
			    exit when mouseNow.b = 0
			end loop
			exit
		    end if
		end loop

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
	if k = "`" then % cheats!!
	    for i : 1 .. 4
		drawfilloval (player (i).nowX * 20 - 10, player (i).nowY * 20 - 10, 5, 5, player (i).clr) % location
		drawline (round (500 * cosd (player (i).angle)) + player (i).nowX * 20 - 10, round (500 * sind (player (i).angle)) + player (i).nowY * 20 - 10, player (i).nowX * 20 -
		    10, player (i).nowY * 20 - 10, player (i).clr) % aiming line
	    end for
	end if
    end if

    View.Update
    mouseLast := mouseNow
    cls
end loop

