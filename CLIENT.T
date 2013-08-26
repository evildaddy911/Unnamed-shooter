View.Set ("graphics:1000,600")
%   CLIENT PROGRAM

const port : int := 3252 % DO NOT CHANGE THIS NUMBER
var netPath : int % connection ID

var now, last : % mouse buttons etc
    record
	x, y, b : int
    end record

var player : array 1 .. 4 of
    record
	X, Y : int % location
	spawnX, spawnY : int % where player spawns
	angle : real
	kills, deaths : int
	hit : boolean % whether player has been hit this round
	clr : int
    end record
player (1).clr := brightblue
player (2).clr := brightred
player (3).clr := brightgreen
player (4).clr := brightcyan

var playerNumber : int

var grid : array 1 .. 40, 1 .. 30 of int
var Dist : int % #squares players can move each turn

var ans : string % holds responses to text based questions
var key : string (1)   % used for single-key inputs
loop
    put "Press any key once server is online"
    loop
	exit when hasch ()
    end loop
    getch (key)

    var serverIP : string
    put "\nPlease enter server IP in format \"XXX.XXX.XXX.XXX\""
    get serverIP

    for i : 1 .. 4 % attempts to connect to the server
	netPath := Net.OpenConnection (serverIP, port + i)
	exit when netPath > 0
    end for
    exit when netPath > 0
    put "\nError connecting to server. Please try again\n"
end loop

loop
    exit when Net.LineAvailable (netPath)
end loop
get : netPath, ans % gets player# and dist
for i : 1 .. length (ans)
    if ans (i) = "+" then
	playerNumber := strint (ans (1 .. i - 1))
	Dist := strint (ans (i + 1 .. *))
    end if
end for

var mapData : array 1 .. 30 of string % download map data
for i : 1 .. 30
    loop
	exit when Net.LineAvailable (netPath)
    end loop
    get : netPath, mapData (i)
end for

% disect map data
for y : 1 .. 30
    var separator : array 1 .. 41 of int
    var num : int := 1
    for i : 1 .. length (mapData (y))
	if mapData (y) (i) = "+" then
	    separator (num) := i
	    num += 1
	end if
    end for
    for x : 1 .. 40
	grid (x, y) := strint (mapData (y) (separator (x) + 1 .. separator (x + 1) - 1))
    end for
end for

procedure drawMap ()
    for i : 1 .. 40
	for j : 1 .. 30
	    case grid (i, j) of         % draws the different tiles
		label - 2 :         % draws the different tiles || In an update, these will be replaced by pictures
		    drawfillbox ((i - 1) * 20, (j - 1) * 20, i * 20, j * 20, black)         % wall
		label - 1 :
		    drawfillbox ((i - 1) * 20, (j - 1) * 20, i * 20, j * 20, blue)         % water
		label :
		    drawbox ((i - 1) * 20, (j - 1) * 20, i * 20, j * 20, black)         % walkable
	    end case
	    for k : 1 .. 4         % draws the player's positions from last playerNumber
		if i = player (k).X and j = player (k).Y then
		    drawfillstar ((i - 1) * 20 + 1, (j - 1) * 20 + 1, i * 20 - 1, j * 20 - 1, player (k).clr)
		end if
	    end for
	end for
    end for
end drawMap

var stage : int := 1         % which part of the playerNumber it is (move / aim)
var moves : int := Dist
cls
View.Set ("offscreenonly")
loop
    mousewhere (now.x, now.y, now.b)

    case stage of
	label 1 :
	    drawMap
	    if moves > 0 then
		Font.Draw ("Movement Stage", 900 - Font.Width ("Movement Stage", defFontID) div 2, 475, defFontID, black)
		Font.Draw ("Moves left: " + intstr (moves), 900 - Font.Width ("Moves left: " + intstr (moves), defFontID) div 2, 417, defFontID, black)
		Font.Draw ("K/D: " + intstr (player (playerNumber).kills) + "/" + intstr (player (playerNumber).deaths), 900 - Font.Width ("K/D: " + intstr (player (playerNumber).kills) + "/"
		    +
		    intstr (player (playerNumber).deaths), defFontID) div 2, 403, defFontID, black)
		% up button
		drawfillbox (855, 255, 945, 345, player (playerNumber).clr)
		Draw.ThickLine (900, 275, 900, 325, 10, black)
		Draw.ThickLine (900, 325, 875, 300, 10, black)
		Draw.ThickLine (900, 325, 925, 300, 10, black)
		% left button
		drawfillbox (805, 155, 895, 245, player (playerNumber).clr)
		Draw.ThickLine (825, 200, 875, 200, 10, black)
		Draw.ThickLine (825, 200, 850, 225, 10, black)
		Draw.ThickLine (825, 200, 850, 175, 10, black)
		% right button
		drawfillbox (905, 155, 995, 245, player (playerNumber).clr)
		Draw.ThickLine (925, 200, 975, 200, 10, black)
		Draw.ThickLine (975, 200, 950, 225, 10, black)
		Draw.ThickLine (975, 200, 950, 175, 10, black)
		% down button
		drawfillbox (855, 55, 945, 145, player (playerNumber).clr)
		Draw.ThickLine (900, 75, 900, 125, 10, black)
		Draw.ThickLine (900, 75, 925, 100, 10, black)
		Draw.ThickLine (900, 75, 875, 100, 10, black)

		% checks for the buttons being clicked, makes sure it is valid move, then moves player
		if now.b ~= 0 and last.b = 0 then
		    if now.x > 855 and now.x < 945 and now.y > 255 and now.y < 345 and player (playerNumber).Y < 30 and grid (player (playerNumber).X, player (playerNumber).Y + 1) >= 0 then
			moves -= 1
			player (playerNumber).Y += 1
		    end if
		    if now.x > 805 and now.x < 895 and now.y > 155 and now.y < 245 and player (playerNumber).X > 1 and grid (player (playerNumber).X - 1, player (playerNumber).Y) >= 0 then
			moves -= 1
			player (playerNumber).X -= 1
		    end if
		    if now.x > 905 and now.x < 995 and now.y > 155 and now.y < 245 and player (playerNumber).X < 40 and grid (player (playerNumber).X + 1, player (playerNumber).Y) >= 0 then
			moves -= 1
			player (playerNumber).X += 1
		    end if
		    if now.x > 855 and now.x < 945 and now.y > 55 and now.y < 145 and player (playerNumber).Y > 1 and grid (player (playerNumber).X, player (playerNumber).Y - 1) >= 0 then
			moves -= 1
			player (playerNumber).Y -= 1
		    end if
		end if
	    else
		loop         % makes sure you don't accidentally click anything in the next stage
		    mousewhere (now.x, now.y, now.b)
		    exit when now.b = 0
		end loop
		moves := Dist
		stage := 2
		player (playerNumber).angle := 0
	    end if
	label 2 :
	    drawMap
	    drawline (round (500 * cosd (player (playerNumber).angle)) + player (playerNumber).X * 20 - 10, round (500 * sind (player (playerNumber).angle)) + player (playerNumber).Y * 20 -
		10,
		player (playerNumber).X * 20 - 10, player (playerNumber).Y * 20 - 10, player (playerNumber).clr)                % aiming line
	    drawfillbox (800, 0, 1000, 600, white)         % clear the side panel
	    Font.Draw ("Aiming Stage", 900 - Font.Width ("Aiming Stage", defFontID) div 2, 475, defFontID, black)
	    Font.Draw ("Angle: " + realstr (player (playerNumber).angle, 1), 825, 410, defFontID, black)
	    % CCW box
	    drawfillbox (805, 255, 995, 345, player (playerNumber).clr)
	    Font.Draw ("CCW", 900 - Font.Width ("CCW", defFontID) div 2, 295, defFontID, black)
	    % CW box
	    drawfillbox (805, 155, 995, 245, player (playerNumber).clr)
	    Font.Draw ("CW", 900 - Font.Width ("CW", defFontID) div 2, 195, defFontID, black)
	    % OK box
	    drawfillbox (805, 55, 995, 145, player (playerNumber).clr)
	    Font.Draw ("DONE", 900 - Font.Width ("DONE", defFontID) div 2, 95, defFontID, black)

	    % checks for buttons being clicked
	    if now.b ~= 0 then
		if now.x > 805 and now.x < 995 and now.y > 255 and now.y < 345 then
		    player (playerNumber).angle := player (playerNumber).angle + 0.5
		    if player (playerNumber).angle > 360 then         % keeps angle under 360
			player (playerNumber).angle -= 360
		    end if
		end if
		if now.x > 805 and now.x < 995 and now.y > 155 and now.y < 245 then
		    player (playerNumber).angle := player (playerNumber).angle - 0.5
		    if player (playerNumber).angle < 0 then
			player (playerNumber).angle += 360         % keeps angle positive
		    end if
		end if
		if now.x > 805 and now.x < 995 and now.y > 55 and now.y < 145 then
		    loop         % makes sure you don't accidentally click anything in the next stage
			mousewhere (now.x, now.y, now.b)
			exit when now.b = 0
		    end loop
		    moves := Dist
		    stage := 3
		end if
	    end if
	label :
	    drawMap
	    Font.Draw ("Waiting for server...", 900 - Font.Width ("Waiting for server...", defFontID) div 2, 475, defFontID, black)

	    var temp : string := intstr (player (playerNumber).X) + "+" + intstr (player (playerNumber).Y) + "+" + realstr (player (playerNumber).angle, 1)
	    put : netPath, temp
	    loop
		exit when Net.LineAvailable (netPath)
	    end loop
	    get : netPath, temp
	    % disect string for round results
	    var separator : array 1 .. 24 of int
	    separator (1) := 0
	    var num : int := 2
	    for i : 1 .. length (temp)
		if temp (i) = "+" then
		    separator (num) := i
		    num += 1
		end if
	    end for

	    % format: X+Y+angle+kills+deaths+hit
	    for i : 1 .. 4
		player (i).X := strint (temp (separator (6 * (i - 1) + 1) + 1 .. separator (6 * (i - 1) + 2) - 1))
		player (i).Y := strint (temp (separator (6 * (i - 1) + 2) + 1 .. separator (6 * (i - 1) + 3) - 1))
		player (i).angle := strreal (temp (separator (6 * (i - 1) + 3) + 1 .. separator (6 * (i - 1) + 4) - 1))
		player (i).kills := strint (temp (separator (6 * (i - 1) + 4) + 1 .. separator (6 * (i - 1) + 5) - 1))
		player (i).deaths := strint (temp (separator (6 * (i - 1) + 5) + 1 .. separator (6 * (i - 1) + 6) - 1))
		player (i).hit := temp (separator (6 * (i - 1) + 6) + 1) = "1"
	    end for

	    drawMap
	    for i : 1 .. 4         % draw the shot lines
		drawline (round (750 * cosd (player (i).angle)) + player (i).X * 20 - 10, round (750 * sind (player (i).angle)) + player (i).Y * 20 - 10, player (i).X * 20 - 10,
		    player (i).Y * 20 - 10, player (i).clr)
	    end for
	    drawfillbox (800, 0, 1000, 600, white)         % clear the right-hand panel

	    % output the results
	    Font.Draw ("RESULTS", 900 - Font.Width ("RESULTS", defFontID) div 2, 475, defFontID, black)

	    if player (playerNumber).hit then
		Font.Draw ("You were shot! Respawning :(", 900 - Font.Width ("You were shot! Respawning :(", defFontID) div 2, 450, defFontID, black)
	    else
		Font.Draw ("You survived this round!", 900 - Font.Width ("You survived this round!", defFontID) div 2, 450, defFontID, black)
	    end if

	    for i : 1 .. 4         % respawns dead characters
		if player (i).hit then                  %
		    player (i).X := player (i).spawnX         % NOTE: this was not done by the server so that the characters would
		    player (i).Y := player (i).spawnY         % be in their previous positions to draw
		end if                                  %
	    end for

	    % outputs the scores
	    Font.Draw ("Player 1 K/D: " + intstr (player (1).kills) + "/" + intstr (player (1).deaths), 810, 400, defFontID, black)
	    Font.Draw ("Player 2 K/D: " + intstr (player (2).kills) + "/" + intstr (player (2).deaths), 810, 375, defFontID, black)
	    Font.Draw ("Player 3 K/D: " + intstr (player (3).kills) + "/" + intstr (player (3).deaths), 810, 350, defFontID, black)
	    Font.Draw ("Player 4 K/D: " + intstr (player (4).kills) + "/" + intstr (player (4).deaths), 810, 325, defFontID, black)

	    drawfillbox (805, 200, 995, 300, black)         % continue button
	    Font.Draw ("Next Round", 900 - Font.Width ("Next Round", defFontID) div 2, 245, defFontID, white)
	    View.Update
	    loop
		mousewhere (now.x, now.y, now.b)
		if now.b ~= 0 and now.x > 805 and now.x < 995 and now.y > 200 and now.y < 300 then
		    stage := 1
		    loop
			mousewhere (now.x, now.y, now.b)
			exit when now.b = 0
		    end loop
		    exit
		end if
	    end loop

    end case

    View.Update
    last := now
    cls
end loop
