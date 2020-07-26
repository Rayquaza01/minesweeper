-- sampler

function make_sampler(n)
	-- create sampler obj
	local sampler = {}
	sampler.length = n
	sampler.items = {}
	-- fill sampler data
	for i = 1, n, 1 do
		sampler.items[i] = i - 1
	end

	-- remove number from sampler
	sampler.remove_number = function(n)
		-- remove item in n + 1th position
		-- at start of game, each tile, n, is stored in index n + 1
		-- will likely fail after get_sample is called!
		sampler.items[n + 1] = sampler.items[sampler.length]
		sampler.length -= 1
	end

	-- get a random item w/o replacement
	sampler.get_sample = function()
		-- choose a random index
		r = 1+flr(rnd(sampler.length-1))
		-- get item from index
		tmp = sampler.items[r]
		-- move item from last position to index
		sampler.items[r] = sampler.items[sampler.length]
		-- remove last item from array
		sampler.length -= 1

		return tmp
	end

	return sampler
end
