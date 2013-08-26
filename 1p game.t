View.Set ("graphics:1000,600")

var now, last :
    record
	x, y, b : int
    end record
var grid : array 1 .. 40, 1 .. 30 of int % 0=walkable; -1=bullets can pass; -2=wall; >0=player spawn
var player : array 1 .. 4 of
    record
	deaths, kills : int % #times been shot; #shots hit
	hit : boolean % if player has been hit this round
	lastX, lastY : int % where player was last turn
	nowX, nowY : int % where player is now
	spawnX, spawnY : int % where player spawns
	clr : int % which color to draw player in
	angle : real % angle to shoot at
	lastMove : int % which direction player moved last (used for AI)
    end record

var file : int
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
    player (i).lastX := player (i).spawnX
    player (i).lastY := player (i).spawnY
    player (i).nowX := player (i).spawnX
    player (i).nowY := player (i).spawnY
    player (i).angle := 0
    player (i).lastMove := Rand.Int (1, 4)
end for

const dist : int := 8     % #squares player can move in one turn
const accuracy : real := 1     % #degrees [not used]
var turn : int := 1     % whose turn it is
var stage : int := 1     % which part of the turn it is (move / aim)
var moves : int := dist     % how many moves left
var numPlayers : int % how many human players
var ans : string % used for text-based questions
put "how many human players (1-4)?"
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
		    drawfillbox ((i - 1) * 20, (j - 1) * 20, i * 20, j * 20, black)     % wall
		label - 1 :
		    drawfillbox ((i - 1) * 20, (j - 1) * 20, i * 20, j * 20, blue)     % water
		label :
		    drawbox ((i - 1) * 20, (j - 1) * 20, i * 20, j * 20, black)     % walkable
	    end case
	    for k : 1 .. 4     % draws the player's positions from last turn
		if k = turn then
		    if i = player (k).nowX and j = player (k).nowY then
			drawfillstar ((i - 1) * 20 + 1, (j - 1) * 20 + 1, i * 20 - 1, j * 20 - 1, player (k).clr)
		    end if
		else
		    if i = player (k).lastX and j = player (k).lastY then
			drawfillstar ((i - 1) * 20 + 1, (j - 1) * 20 + 1, i * 20 - 1, j * 20 - 1, player (k).clr)
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

    player (pNum).angle := realAngle (player (pNum).nowX, player (pNum).nowY, player (target).lastX, player (target).lastY)
    player (pNum).angle += (Rand.Real - 0.5) * 40         % puts the shot up to 20 degrees off of the targeted player's previous position
    stage += 1
    moves := dist
end AI

var window : int

View.Set ("offscreenonly")
loop

    mousewhere (now.x, now.y, now.b)
    Font.Draw ("Player " + intstr (turn) + "'s turn", 900 - Font.Width ("Player " + intstr (turn) + "'s turn", defFontID) div 2, 575, defFontID, player (turn).clr)
    case stage of
	label 1 :
	    drawMap
	    if moves > 0 then
		Font.Draw ("Movement Stage", 900 - Font.Width ("Movement Stage", defFontID) div 2, 475, defFontID, black)
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
		if now.b ~= 0 and last.b = 0 then
		    if now.x > 855 and now.x < 945 and now.y > 305 and now.y < 395 and player (turn).nowY < 30 and grid (player (turn).nowX, player (turn).nowY + 1) >= 0 then
			moves -= 1
			player (turn).nowY += 1
		    end if
		    if now.x > 805 and now.x < 895 and now.y > 205 and now.y < 295 and player (turn).nowX > 1 and grid (player (turn).nowX - 1, player (turn).nowY) >= 0 then
			moves -= 1
			player (turn).nowX -= 1
		    end if
		    if now.x > 905 and now.x < 995 and now.y > 205 and now.y < 295 and player (turn).nowX < 40 and grid (player (turn).nowX + 1, player (turn).nowY) >= 0 then
			moves -= 1
			player (turn).nowX += 1
		    end if
		    if now.x > 855 and now.x < 945 and now.y > 105 and now.y < 195 and player (turn).nowY > 1 and grid (player (turn).nowX, player (turn).nowY - 1) >= 0 then
			moves -= 1
			player (turn).nowY -= 1
		    end if
		    if now.x > 805 and now.x < 995 and now.y > 5 and now.y < 95 then
			moves := -1
		    end if
		end if
	    else
		loop     % makes sure you don't accidentally click anything in the next stage
		    mousewhere (now.x, now.y, now.b)
		    exit when now.b = 0
		end loop
		moves := dist
		stage := 2
		player (turn).angle := 0
	    end if
	label 2 :
	    drawMap
	    drawline (round (500 * cosd (player (turn).angle)) + player (turn).nowX * 20 - 10, round (500 * sind (player (turn).angle)) + player (turn).nowY * 20 - 10, player (turn).nowX * 20 -
		10, player (turn).nowY * 20 - 10, player (turn).clr)                    % aiming line
	    drawfillbox (800, 0, 1000, 600, white)     % clear the side panel
	    Font.Draw ("Aiming Stage", 900 - Font.Width ("Aiming Stage", defFontID) div 2, 475, defFontID, black)
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
	    if now.b ~= 0 then
		if now.x > 805 and now.x < 995 and now.y > 255 and now.y < 345 then
		    player (turn).angle := player (turn).angle + 0.5
		    if player (turn).angle > 360 then     % keeps angle under 360
			player (turn).angle -= 360
		    end if
		end if
		if now.x > 805 and now.x < 995 and now.y > 155 and now.y < 245 then
		    player (turn).angle := player (turn).angle - 0.5
		    if player (turn).angle < 0 then
			player (turn).angle += 360     % keeps angle positive
		    end if
		end if
		if now.x > 805 and now.x < 995 and now.y > 55 and now.y < 145 then
		    loop     % makes sure you don't accidentally click anything in the next stage
			mousewhere (now.x, now.y, now.b)
			exit when now.b = 0
		    end loop
		    moves := dist
		    stage := 3
		end if
	    end if

	label :
	    if turn = 4 then     % checks if its time to output the results
		for i : numPlayers .. 4
		    AI (i)
		end for
		for i : 1 .. 4
		    % move players to their new positions
		    player (i).lastX := player (i).nowX
		    player (i).lastY := player (i).nowY
		end for
		drawMap     % redraw the map
		for i : 1 .. 4     % draw the shot lines
		    drawline (round (750 * cosd (player (i).angle)) + player (i).nowX * 20 - 10, round (750 * sind (player (i).angle)) + player (i).nowY * 20 - 10, player (i).nowX * 20 - 10,
			player (i).nowY * 20 - 10, player (i).clr)     % shot line
		end for
		drawfillbox (800, 0, 1000, 600, white)     % clear the right-hand panel

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
			player (i).lastX := player (i).spawnX
			player (i).lastY := player (i).spawnY
		    end if
		    player (i).hit := false
		end for

		% output the results
		Font.Draw ("RESULTS", 900 - Font.Width ("RESULTS", defFontID) div 2, 475, defFontID, black)
		Font.Draw ("Player 1 K/D: " + intstr (player (1).kills) + "/" + intstr (player (1).deaths), 810, 400, defFontID, black)
		Font.Draw ("Player 2 K/D: " + intstr (player (2).kills) + "/" + intstr (player (2).deaths), 810, 375, defFontID, black)
		Font.Draw ("Player 3 K/D: " + intstr (player (3).kills) + "/" + intstr (player (3).deaths), 810, 350, defFontID, black)
		Font.Draw ("Player 4 K/D: " + intstr (player (4).kills) + "/" + intstr (player (4).deaths), 810, 325, defFontID, black)

		drawfillbox (805, 200, 995, 300, black)     % next button
		Font.Draw ("Next Turn", 900 - Font.Width ("Next Turn", defFontID) div 2, 245, defFontID, white)
		View.Update
		loop
		    mousewhere (now.x, now.y, now.b)
		    if now.b ~= 0 and now.x > 805 and now.x < 995 and now.y > 200 and now.y < 300 then
			turn := 1
			stage := 1
			loop
			    mousewhere (now.x, now.y, now.b)
			    exit when now.b = 0
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
		drawfilloval (player (i).nowX * 20 - 10, player (i).nowY * 20 - 10, 5, 5, player (i).clr)
		drawline (round (500 * cosd (player (i).angle)) + player (i).nowX * 20 - 10, round (500 * sind (player (i).angle)) + player (i).nowY * 20 - 10, player (i).nowX * 20 -
		    10, player (i).nowY * 20 - 10, player (i).clr) % aiming line
	    end for
	end if
    end if

    View.Update
    last := now
    cls
end loop

