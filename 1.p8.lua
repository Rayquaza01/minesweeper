-- cursor

-- initialize vars
function reset_board()
	-- timer stores frames since reset or game starting
	-- frozen timer stores duration of last game
	frozen_timer = 0
	timer = 0

	game = {
		started = false, -- if the game is in progress
		over = false, -- if the game ended
		win = false -- if the game was won
	}

	make_cur()
	make_board()
end

-- cursor has position relative to origin of board
function make_cur()
	cur = {}
	cur.col = 1
	cur.row = 1
end

-- adjust the cursor in a direction
function move_cur(d)
	local adj = find_adjacent(cur.row, cur.col, d, true)
	cur.row = adj.row
	cur.col = adj.col
end

function draw_cur()
	local sprite = 16
	-- change sprite every ~.5 secs to animate
	if (timer % 30 > 15) sprite = 32
	-- print cur
	-- board origin is (3, 6) on tilemap
	-- add 2 and 5 because tilemap is 1 indexed
	spr(sprite, (cur.col + 2) * 8, (cur.row + 5) * 8)
end
