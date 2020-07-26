--mines
--by joe jarvis
--v1.0 (2020.07.26)

function _init()
	printh("--start mines --")

	cartdata("r01-minesweeper")
	high_score = dget(0)

	-- if high score is 0 (unset), set it to 500 seconds
	if (high_score == 0) then
		high_score = 500 * 30
		dset(0, high_score)
	end

	-- board mask consts
	is_mine = 0x80
	is_flagged = 0x40
	is_maybe_flagged = 0x20
	is_clear = 0x10
	value_mask = 0x0f -- number of adjacent mines

	-- direction maps
	-- up, up right, right, down right, down, down left, left, up left
	dc = {0, 1, 1, 1, 0, -1, -1, -1}
	dr = {-1, -1, 0, 1, 1, 1, 0, -1}


	reset_board()
end

function _update()
	timer += 1

	local adj = false

	if (btnp(⬅️)) move_cur(7)
	if (btnp(➡️)) move_cur(3)
	if (btnp(⬆️)) move_cur(1)
	if (btnp(⬇️)) move_cur(5)

	-- if game is not started, ❎ and 🅾️ start the game
	if (not game.started and (btnp(❎) or btnp(🅾️))) then
		game.started = true
		timer = 0
	end

	-- if game ended, ❎ and 🅾️ reset board
	if (game.over and (btnp(❎) or btnp(🅾️))) then
		game.over = false
		game.started = false
		game.win = false
		reset_board()
		return
	end

	-- if 🅾️, clear tile
	if (btnp(🅾️)) then
		clear(cur.row, cur.col)
	-- if ❎, flag tile
	elseif (btnp(❎)) then
		flag(cur.row, cur.col)
	end
end

function _draw()
	cls()

	-- load main map
	map(0, 0)
	-- high score stored as frames, displayed as seconds
	-- row 0
	print_center("★high score: " .. flr(high_score / 30), 0, -2)

	-- if game is currently in progress
	if (game.started and (not game.over)) then
		-- col 2, row 1 (row offset by 2)
		print(flr(timer / 30), 16, 10)
		print_center("mines", 3, 0)
	else
		-- if game ended in loss, print loss msg
		if (game.over and (not game.win)) then
			print_center("you lose! press 🅾️ to try again", 3, 1)
		-- if game ended in win, print win msg
		elseif (game.win) then
			print_center("you win! press 🅾️ to play again", 3, 1)
		end
		print(flr(frozen_timer / 30), 16, 10)
	end

	-- if game hasn't started yet
	if (not game.started) then
		-- print start message
		print_center("press 🅾️ to start playing", 3, -1)
	end

	-- col 14, row 1 (row offset by 2)
	print(board.active_mines, 112, 10)


	-- row 15
	print_center("🅾️ to clear ◆ ❎ to flag", 15, -3)

	draw_board()
	draw_cur()
end

-- center text
function print_center(s, r, extra)
	print(s, 64 - (#s * 2) + extra, r * 8 + 2)
end
