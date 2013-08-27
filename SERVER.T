%   SERVER PROGRAM

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

const port : int := 3252 % DO NOT CHANGE THIS NUMBER OR PROGRAM WILL NOT WORK
put "Server IP: ", Net.LocalAddress, "\n"

var player : array 1 .. 4 of
    record
	X, Y : int
	spawnX, spawnY : int
	angle : real
	kills, deaths : int
	hit : boolean % whether player has been hit this round
	clr : int

	netPath : int     % Net. object ID
	ip : string
	checkIn : boolean
    end record
player (1).clr := brightblue
player (2).clr := brightred
player (3).clr := brightgreen
player (4).clr := brightcyan
player (1).checkIn := false
player (2).checkIn := false
player (3).checkIn := false
player (4).checkIn := false

process check (client : int) % checks for client's input
    loop     % waits until there is data available
	exit when Net.LineAvailable (player (client).netPath)
    end loop
    var temp : string % format: X+Y+angle
    get : player (client).netPath, temp % stores input from client in temp string
    var separator : array 1 .. 2 of int := init (0, 0) % where the separators ("+") are in temp
    % disects temp to find players location and angle
    var num : int := 1
    for i : 1 .. length (temp)
	if temp (i) = "+" then
	    num += 1
	    separator (num) := i
	end if
    end for
    player (client).X := strint (temp (1 .. separator (1) - 1))
    player (client).Y := strint (temp (separator (1) + 1 .. separator (2) - 1))
    player (client).angle := strreal (temp (separator (2) - 1 .. *))
    % sets checkIn to true
    player (client).checkIn := true
end check

var grid : array 1 .. 40, 1 .. 30 of int
var Dist : int := 5 % #squares players can move each turn

var file : int
var numMaps : int := 0
loop
    exit when ~File.Exists (intstr (numMaps + 1) + ".map")
    numMaps += 1
end loop
var mapNum : int := Rand.Int (1, numMaps)
% load the map
open : file, intstr (mapNum) + ".map", read
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

var numPlayers : int         % how many players

put "How many human players (1-4)?"
loop
    var ans : string
    get ans
    if strintok (ans) and strint (ans) >= 1 and strint (ans) <= 4 then
	numPlayers := strint (ans)
	exit
    end if
    put "Invalid input. Must be an integer from 1 to 4"
end loop

put "Server is now online. Waiting for players..."
for i : 1 .. numPlayers         % opens a connection to each of the clients
    player (i).netPath := Net.WaitForConnection (port + i, player (i).ip)
    var temp : string := intstr (i) + "+" + intstr (Dist)
    put : player (i).netPath, temp    % tells client which player number they are
end for

put "Players found. Uploading map data"
for y : 1 .. 30
    var temp : string := "+"
    for x : 1 .. 40
	temp := temp + intstr (grid (x, y)) + "+"
    end for

    for i : 1 .. numPlayers
	put : player (i), temp
    end for
end for

put "Upload complete. Starting game"
/***************************************************************
 * start of main loop  *****************************************
 ***************************************************************/
loop

    if numPlayers < 4 then % if game is not full of players, use AI
	for i : numPlayers + 1 .. 4 % move CPUs
	    var lastMove : int := Rand.Int (1, 4)
	    for moveNum : 1 .. Dist
		loop
		    var direction : int := Rand.Int (1, 6)
		    if direction > 4 then
			direction := lastMove
		    end if
		    case direction of
			label 1 :
			    if grid (player (i).X, player (i).Y + 1) >= 0 then
				player (i).Y += 1
				lastMove := 1
				exit
			    end if
			label 2 :
			    if grid (player (i).X - 1, player (i).Y) >= 0 then
				player (i).X -= 1
				lastMove := 2
				exit
			    end if
			label 3 :
			    if grid (player (i).X + 1, player (i).Y) >= 0 then
				player (i).X += 1
				lastMove := 3
				exit
			    end if
			label 4 :
			    if grid (player (i).X, player (i).Y - 1) >= 0 then
				player (i).Y -= 1
				lastMove := 4
				exit
			    end if
		    end case
		end loop
	    end for

	    var target : int % which player to target this turn
	    loop % don't allow CPU to target itself
		target := Rand.Int (1, 4)
		exit when target ~= i
	    end loop

	    player (i).angle := realAngle (player (i).X, player (i).Y, player (target).X, player (target).Y)
	    player (i).angle += (Rand.Real - 0.5) * 20 % puts the shot up to 20 degrees off of the targeted player's previous position
	end for
    end if

    for i : 1 .. numPlayers % begins checkin proccesses
	player (i).checkIn := false % sets checkIn variable to false
	fork check (i) % uses processes to check each connection separately
    end for

    loop % waits until all clients have checked in
	var done : boolean := true
	for i : 1 .. numPlayers
	    if ~player (i).checkIn then
		done := false
		exit
	    end if
	end for
	exit when done
    end loop

    for i : 1 .. 4 % resets player's hit variables
	player (i).hit := false
    end for

    for i : 1 .. 4
	% check for any kills
	var x, y : real
	x := player (i).nowX * 20 - 10                 % initial positions of the bullet
	y := player (i).nowY * 20 - 10
	loop
	    exit when x < 0 or x > 800 or y < 0 or y > 600 or grid (x div 20 + 1, y div 20 + 1) = -2                 % exit when shot goes out of the grid or if it hits a wall
	    x += 2 * cosd (player (i).angle)                 % move the shot
	    y += 2 * sind (player (i).angle)
	end loop

	for j : 1 .. 4             % check if the shot hit a player (don't allow player to shoot itself)
	    if j ~= i and Math.DistancePointLine (player (j).nowX * 20 - 10, player (j).nowY * 20 - 10, x, y, player (i).nowX * 20 - 10, player (i).nowY * 20 - 10) < 8 then
		player (i).kills += 1
		player (j).deaths += 1
		player (j).lastX := player (j).spawnX
		player (j).lastY := player (j).spawnY
		player (j).nowX := player (j).spawnX
		player (j).nowY := player (j).spawnY
	    end if
	end for
    end for

    % create the
    var temp : string := ""
    for i : 1 .. 4
	temp := temp + intstr (player (i).X) + "+" + intstr (player (i).Y) + "+" + realstr (player (i).angle, 1) + "+" + intstr (player (i).kills) + "+" + intstr (player (i).deaths) + "+"
	if player (i).hit then % binary indicating if hit this round % X+Y+angle+kills+deaths+hit
	    temp := temp + "1"
	else
	    temp := temp + "0"
	end if
	if i ~= 4 then
	    temp := temp + "+"
	end if
    end for
    put temp

    for i : 1 .. numPlayers
	put : player (i).netPath, temp % sends round results to each client
    end for

    /***************************************************************
     * end of main loop  *******************************************
     ***************************************************************/
end loop
