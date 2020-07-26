-- board

-- bitwise func
-- used to check if a given bit is set
function is_set(r, c, bitw)
	return ((board.tiles[r][c] & bitw) == bitw)
end

-- encode a position to a single number
function encode_pos(r, c)
	return c - 1 + board.columns * (r + board.rows - 1) - board.area
end

-- decode a number into a row and column
function decode_pos(pos)
	res = {}

	pos += board.area
	res.col = pos % board.columns + 1
	pos = flr(pos / board.columns)
	res.row = pos % board.rows + 1

	return res
end

-- find pos of tile in adjacent direction
function find_adjacent(r, c, d, wrap)
	res = {}

	-- dr and dc represent the change in value for row and columns in a given direction
	-- see dr and dc's def in make_board
	res.row = r + dr[d]
	res.col = c + dc[d]

	if (wrap) then
		-- index underflows to last row
		if (res.row < 1) then
			res.row = board.rows
		-- index overflows to first row
		elseif (res.row > board.rows) then
			res.row = 1
		end

		-- same with columns
		if (res.col < 1) then
			res.col = board.columns
		elseif (res.col > board.columns) then
			res.col = 1
		end
	-- if row or column are out of bounds,
	-- return false to show adjacent tile does not exist
	elseif (res.row < 1 or res.row > board.rows or res.col < 1 or res.col > board.columns) then
		return false
	end
	return res
end

-- generate mines, excluding a position
function generate_mines(r, c)
	-- create sampler with all positions on board
	local smp = make_sampler(board.area)
	-- remove tile the player cleared from sampler
	smp.remove_number(encode_pos(r, c))
	for d = 1, 8, 1 do
		-- remove all adjacent tiles from sampler
		local adj = find_adjacent(r, c, d, false)
		if (adj) then
			smp.remove_number(encode_pos(adj.row, adj.col))
		end
	end

	-- generate mines for game
	for i = 1, board.mines, 1 do
		-- get random position on board
		local r = smp.get_sample()
		local pos = decode_pos(r)
		-- mark as mine
		board.tiles[pos.row][pos.col] |= is_mine
		-- increase adjacent values for nearby mines
		for d = 1, 8, 1 do
			local adj = find_adjacent(pos.row, pos.col, d, false)
			if (adj) then
				board.tiles[adj.row][adj.col] += 1
			end
		end
	end
end

-- flag a given tile
function flag(r, c)
	-- return if clear (can't flag cleared tile)
	if (is_set(r, c, is_clear)) return

	-- if flagged, maybe flag
	if (is_set(r, c, is_flagged)) then
		board.active_mines += 1
		board.tiles[r][c] ^^= is_flagged
		board.tiles[r][c] |= is_maybe_flagged
	-- if maybe flag, remove flag
	elseif (is_set(r, c, is_maybe_flagged)) then
		board.tiles[r][c] ^^= is_maybe_flagged
	-- if unflagged, add flag
	else
		board.active_mines -= 1
		board.tiles[r][c] |= is_flagged
	end
	-- flag noise
	sfx(3)
end

-- clear a given tile
function clear(r, c)
	-- return if clear (exit condition for recursive clear)
	if (is_set(r, c, is_clear)) return
	-- return if flagged (can't clear flagged tile)
	if (is_set(r, c, is_flagged)) return

	-- remove maybe flag
	if (is_set(r, c, is_maybe_flagged)) then
		board.tiles[r][c] ^^= is_maybe_flagged
	end
	board.tiles[r][c] |= is_clear

	if (board.generated == false) then
		generate_mines(r, c)
		board.generated = true
	end

	-- if cleared tile is mine (lose condition)
	if (is_set(r, c, is_mine)) then
		-- end game on failure
		game.over = true
		frozen_timer = timer
		sfx(2)
		return
	end

	-- making it here means game didn't end this turn
	-- increase total cleared tiles
	board.cleared_tiles += 1

	-- clear nearby tiles if current tile is 0
	if ((board.tiles[r][c] & value_mask) == 0) then
		-- cascade sound
		sfx(0)
		for d = 1, 8, 1 do
			adj = find_adjacent(r, c, d, false)
			if (adj) then
				-- if cascading to a flagged tile, unflag the tile before clearing
				if (is_set(adj.row, adj.col, is_flagged)) then
					-- run flag twice b/c flag toggles between 3 states
					flag(adj.row, adj.col) -- maybe flagged
					flag(adj.row, adj.col) -- no flag
				elseif (is_set(adj.row, adj.col, is_maybe_flagged)) then
					flag(adj.row, adj.col) -- no flag
				end
				clear(adj.row, adj.col)
			end
		end
	end

	-- if all non mine tiles are cleared
	-- win condition
	if (board.cleared_tiles == (board.area - board.mines)) then
		-- game ends with win
		game.over = true
		game.win = true
		-- freeze timer
		frozen_timer = timer
		-- save new high (low) score! if applicable
		if (frozen_timer < high_score) then
			high_score = frozen_timer
			dset(0, frozen_timer)
		end
	end

	-- clear sound
	sfx(1)
end

function make_board()
	board = {}
	board.columns = 10
	board.rows = 7
	board.mines = 10
	board.area = board.columns * board.rows
	-- are the mines generated yet
	board.generated = false

	-- represents how many flags are left
	board.active_mines = board.mines
	-- represents how many tiles are cleared
	board.cleared_tiles = 0

	board.tiles = {}

	-- create 2d array representing tiles
	for i = 1, board.rows, 1 do
		board.tiles[i] = {}
		for j = 1, board.columns, 1 do
			board.tiles[i][j] = 0
		end
	end
end

-- display sprites on the board given relative position
function board_sprite(s, r, c)
	spr(s, (c + 2) * 8, (r + 5) * 8)
end

-- display text on the board given relative position
function board_text(t, r, c)
	print(t, (c + 2) * 8 + 2, (r + 5) * 8 + 2)
end

-- draw the board to the screen
function draw_board()
	-- loop through all tiles
	for i = 1, board.rows, 1 do
		for j = 1, board.columns, 1 do
			-- if game hasn't ended
			if (not game.over) then
				-- if current tile is clear
				if (is_set(i, j, is_clear)) then
					board_sprite(2, i, j)
					-- display text on non 0 clear tiles
					if ((board.tiles[i][j] & value_mask) > 0) then
						board_text(board.tiles[i][j] & value_mask, i, j)
					end
				-- if current tile is flagged
				elseif(is_set(i, j, is_flagged)) then
					board_sprite(3, i, j)
				elseif (is_set(i, j, is_maybe_flagged)) then
					board_sprite(3, i, j)
					board_text("?", i, j)
				end
			-- if game has ended
			else
				-- display clear tiles (same as above)
				if (is_set(i, j, is_clear)) then
					board_sprite(2, i, j)
					if ((board.tiles[i][j] & value_mask) > 0) then
						board_text(board.tiles[i][j] & value_mask, i, j)
					end
				end
				-- if tile is a mine
				if (is_set(i, j, is_mine)) then
					-- if tile is also flagged
					-- display flagged mine sprite
					if (is_set(i, j, is_flagged) or is_set(i, j, is_maybe_flagged)) then
						board_sprite(5, i, j)
					-- if mine but not flagged
					-- display mine sprite
					else
						board_sprite(4, i, j)
					end
				-- if flagged but not mine
				-- display flag sprite
				elseif (is_set(i, j, is_flagged)) then
					board_sprite(3, i, j)
				elseif (is_set(i, j, is_maybe_flagged)) then
					board_sprite(3, i, j)
					board_text("?", i, j)
				end
			end
		end -- j loop
	end -- i loop
end
