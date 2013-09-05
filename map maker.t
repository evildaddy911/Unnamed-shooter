View.Set ("offscreenonly; graphics:800,616")
Mouse.ButtonChoose ("multibutton")
var mx, my, mb : int
var keys : array char of boolean
var map : array 1 .. 40, 1 .. 30 of int
for i : 1 .. 40
    for j : 1 .. 30
	map (i, j) := 0
    end for
end for

loop
    loop
	mousewhere (mx, my, mb)
	Input.KeyDown (keys)
	exit when keys (KEY_ENTER)
	put mx div 20 + 1, " ", my div 20 + 1

	Font.Draw ("left button: clear; middle button: water; right button: wall; enter: next", 400 - Font.Width ("left button: clear; middle button: water; right button: wall; enter: next",
	    defFontID)
	    div 2, 603, defFontID, black)
	for i : 1 .. 40
	    drawline (i * 20, 0, i * 20, 600, black)
	end for
	for i : 1 .. 30
	    drawline (0, i * 20, 800, i * 20, black)
	end for
	for i : 1 .. 40
	    for j : 1 .. 30
		case map (i, j) of
		    label - 1 :
			drawfillbox ((i - 1) * 20, (j - 1) * 20, i * 20, j * 20, blue) % water
		    label - 2 :
			drawfillbox ((i - 1) * 20, (j - 1) * 20, i * 20, j * 20, black) % wall
		    label 1 :
			drawfillstar ((i - 1) * 20, (j - 1) * 20, i * 20, j * 20, brightblue)
		    label 2 :
			drawfillstar ((i - 1) * 20, (j - 1) * 20, i * 20, j * 20, brightred)
		    label 3 :
			drawfillstar ((i - 1) * 20, (j - 1) * 20, i * 20, j * 20, brightgreen)
		    label 4 :
			drawfillstar ((i - 1) * 20, (j - 1) * 20, i * 20, j * 20, brightcyan)
		    label :
		end case
	    end for
	end for

	if mx > 0 and my > 0 and mx < 800 and my < 600 then
	    if keys ('1') then
		for i : 1 .. 40
		    for j : 1 .. 30
			if map (i, j) = 1 then
			    map (i, j) := 0
			end if
		    end for
		end for
		map (mx div 20 + 1, my div 20 + 1) := 1
	    elsif keys ('2') then
		for i : 1 .. 40
		    for j : 1 .. 30
			if map (i, j) = 2 then
			    map (i, j) := 0
			end if
		    end for
		end for
		map (mx div 20 + 1, my div 20 + 1) := 2
	    elsif keys ('3') then
		for i : 1 .. 40
		    for j : 1 .. 30
			if map (i, j) = 3 then
			    map (i, j) := 0
			end if
		    end for
		end for
		map (mx div 20 + 1, my div 20 + 1) := 3
	    elsif keys ('4') then
		for i : 1 .. 40
		    for j : 1 .. 30
			if map (i, j) = 4 then
			    map (i, j) := 0
			end if
		    end for
		end for
		map (mx div 20 + 1, my div 20 + 1) := 4
	    elsif mb >= 100 then
		map (mx div 20 + 1, my div 20 + 1) := -2
	    elsif mb >= 10 then
		map (mx div 20 + 1, my div 20 + 1) := -1
	    elsif mb = 1 then
		map (mx div 20 + 1, my div 20 + 1) := 0
	    end if
	end if
	View.Update
	cls
    end loop
    loop
	Input.KeyDown (keys)
	exit when ~keys (KEY_ENTER)
    end loop
    cls
    for i : 1 .. 40
	for j : 1 .. 30
	    case map (i, j) of
		label - 1 :
		    drawfillbox ((i - 1) * 20, (j - 1) * 20, i * 20, j * 20, blue)     % water
		label - 2 :
		    drawfillbox ((i - 1) * 20, (j - 1) * 20, i * 20, j * 20, black)     % wall
		label 1 :
		    drawfillstar ((i - 1) * 20, (j - 1) * 20, i * 20, j * 20, brightblue)
		label 2 :
		    drawfillstar ((i - 1) * 20, (j - 1) * 20, i * 20, j * 20, brightred)
		label 3 :
		    drawfillstar ((i - 1) * 20, (j - 1) * 20, i * 20, j * 20, brightgreen)
		label 4 :
		    drawfillstar ((i - 1) * 20, (j - 1) * 20, i * 20, j * 20, brightcyan)
		label :
	    end case
	end for
    end for
    Font.Draw ("Press \"Q\" to save or press \"P\" to continue editing", 400 - Font.Width ("Press \"Q\" to save or press \"P\" to continue editing", defFontID) div 2, 603, defFontID, black)
    View.Update
    loop
	Input.KeyDown (keys)
	exit when keys ('p')
	if keys ('q') then
	    var numMaps : int := 1
	    loop
		exit when ~File.Exists (intstr (numMaps) + ".map")
		numMaps += 1
	    end loop
	    var file : int
	    open : file, intstr (numMaps) + ".map", write
	    for x : 1 .. 40
		for y : 1 .. 30
		    write : file, map (x, y)
		end for
	    end for
	    close : file
	    Pic.Save (Pic.New (0, 0, 800, 600), intstr (numMaps + 1) + ".bmp")
	    exit
	end if
    end loop
    exit when keys ('q')
end loop

