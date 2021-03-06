var empty_, water, wall : array 1 .. 10, 1 .. 10 of int
var player : array 1 .. 10, 1 .. 10, 1 .. 10 of int

if File.Exists ("Texture.txr") then
    var file : int
    open : file, "Texture.txr", read
    for x : 1 .. 10
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
else
    for x : 1 .. 10
	for y : 1 .. 10
	    empty_ (x, y) := 0
	    water (x, y) := 0
	    wall (x, y) := 0
	    for i : 1 .. 10
		player (i, x, y) := 0
	    end for
	end for
    end for
end if

var mx, my, mb : int
var editing : int := 1 % which tile to be edited
var editCoords : array 1 .. 2 of int := init (1, 1) % which square to be edited
View.Set ("graphics:800,600; offscreenonly")
var key : string (1) := ""
var msg : string

loop
    mousewhere (mx, my, mb)
    key := ""
    if hasch then
	getch (key)
    end if

    Font.Draw ("Press Q when done. Press P to edit the next tile", 400 - Font.Width ("Press Q when done. Press P to edit the next tile", defFontID) div 2, 60, defFontID, black)
    exit when key = "q"

    for x : 1 .. 10 % draws each square of the selected tile
	for y : 1 .. 10
	    case editing of
		label 1 :
		    msg := "Empty tile"
		    drawfillbox (x * 50 + 100, y * 50 + 25, x * 50 + 150, y * 50 + 75, empty_ (x, y))
		label 2 :
		    msg := "Water"
		    drawfillbox (x * 50 + 100, y * 50 + 25, x * 50 + 150, y * 50 + 75, water (x, y))
		label 3 :
		    msg := "Wall"
		    drawfillbox (x * 50 + 100, y * 50 + 25, x * 50 + 150, y * 50 + 75, wall (x, y))
		label 4 :
		    msg := "Player 1"
		    drawfillbox (x * 50 + 100, y * 50 + 25, x * 50 + 150, y * 50 + 75, player (1, x, y))
		label 5 :
		    msg := "Player 2"
		    drawfillbox (x * 50 + 100, y * 50 + 25, x * 50 + 150, y * 50 + 75, player (2, x, y))
		label 6 :
		    msg := "Player 3"
		    drawfillbox (x * 50 + 100, y * 50 + 25, x * 50 + 150, y * 50 + 75, player (3, x, y))
		label 7 :
		    msg := "Player 4"
		    drawfillbox (x * 50 + 100, y * 50 + 25, x * 50 + 150, y * 50 + 75, player (4, x, y))
		label 8 :
		    msg := "Player 5"
		    drawfillbox (x * 50 + 100, y * 50 + 25, x * 50 + 150, y * 50 + 75, player (5, x, y))
		label 9 :
		    msg := "Player 6"
		    drawfillbox (x * 50 + 100, y * 50 + 25, x * 50 + 150, y * 50 + 75, player (6, x, y))
		label 10 :
		    msg := "Player 7"
		    drawfillbox (x * 50 + 100, y * 50 + 25, x * 50 + 150, y * 50 + 75, player (7, x, y))
		label 11 :
		    msg := "Player 8"
		    drawfillbox (x * 50 + 100, y * 50 + 25, x * 50 + 150, y * 50 + 75, player (8, x, y))
		label 12 :
		    msg := "Player 9"
		    drawfillbox (x * 50 + 100, y * 50 + 25, x * 50 + 150, y * 50 + 75, player (9, x, y))
		label :
		    msg := "Player 10"
		    drawfillbox (x * 50 + 100, y * 50 + 25, x * 50 + 150, y * 50 + 75, player (10, x, y))
	    end case
	    drawbox (x * 50 + 100, y * 50 + 25, x * 50 + 150, y * 50 + 75, black) % draws outline around box
	end for
    end for
    Font.Draw ("Editing: " + msg, 400 - Font.Width ("Editing: " + msg, defFontID) div 2, 580, defFontID, black)
    drawoval (editCoords (1) * 50 + 125, editCoords (2) * 50 + 50, 24, 24, black) % shows which square you are editing
    drawoval (editCoords (1) * 50 + 125, editCoords (2) * 50 + 50, 23, 23, black)
    drawoval (editCoords (1) * 50 + 125, editCoords (2) * 50 + 50, 22, 22, white)
    drawoval (editCoords (1) * 50 + 125, editCoords (2) * 50 + 50, 21, 21, white)

    for i : 0 .. 255 % draws the colors
	drawfillbox (i * 3 + 5, 0, i * 3 + 8, 15, i)
    end for

    if mb = 1 then
	if mx >= 5 and mx <= 255 * 3 + 7 and my >= 0 and my <= 25 then % switches color to the one chosen
	    case editing of
		label 1 :
		    empty_ (editCoords (1), editCoords (2)) := (mx - 5) div 3
		label 2 :
		    water (editCoords (1), editCoords (2)) := (mx - 5) div 3
		label 3 :
		    wall (editCoords (1), editCoords (2)) := (mx - 5) div 3
		label 4 :
		    player (1, editCoords (1), editCoords (2)) := (mx - 5) div 3
		label 5 :
		    player (2, editCoords (1), editCoords (2)) := (mx - 5) div 3
		label 6 :
		    player (3, editCoords (1), editCoords (2)) := (mx - 5) div 3
		label 7 :
		    player (4, editCoords (1), editCoords (2)) := (mx - 5) div 3
		label 8 :
		    player (5, editCoords (1), editCoords (2)) := (mx - 5) div 3
		label 9 :
		    player (6, editCoords (1), editCoords (2)) := (mx - 5) div 3
		label 10 :
		    player (7, editCoords (1), editCoords (2)) := (mx - 5) div 3
		label 11 :
		    player (8, editCoords (1), editCoords (2)) := (mx - 5) div 3
		label 12 :
		    player (9, editCoords (1), editCoords (2)) := (mx - 5) div 3
		label :
		    player (10, editCoords (1), editCoords (2)) := (mx - 5) div 3
	    end case
	end if
	if mx >= 150 and mx <= 650 and my >= 75 and my <= 575 then % switches editing square
	    editCoords (1) := (mx - 100) div 50
	    editCoords (2) := (my - 25) div 50
	end if
    end if
    if key = KEY_UP_ARROW and editCoords (2) < 10 then
	editCoords (2) += 1
    elsif key = KEY_DOWN_ARROW and editCoords (2) > 1 then
	editCoords (2) -= 1
    elsif key = KEY_RIGHT_ARROW and editCoords (1) < 10 then
	editCoords (1) += 1
    elsif key = KEY_LEFT_ARROW and editCoords (1) > 1 then
	editCoords (1) -= 1
    end if

    if key = "p" then % switch tiles
	editing += 1
	if editing > 13 then
	    editing := 1
	end if
    end if


    View.Update
    cls
end loop

cls
View.Set ("nooffscreenonly")
var file : int
open : file, "Texture.txr", write
for x : 1 .. 10
    for y : 1 .. 10
	write : file, empty_ (x, y)
	write : file, water (x, y)
	write : file, wall (x, y)
	for i : 1 .. 10
	    write : file, player (i, x, y)
	end for
    end for
end for
put "Texture saved as Texture.txr"
