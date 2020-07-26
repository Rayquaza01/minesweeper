-- sampler

function make_sampler(n)
	-- create sampler obj
	local sampler = {}
	sampler.items = {}
	-- fill sampler data
	for i = 1, n, 1 do
		sampler.items[i] = i - 1
	end

	-- remove number from sampler
	sampler.remove_number = function(n)
		del(sampler.items, n)
	end

	-- get a random item w/o replacement
	sampler.get_sample = function()
		-- choose a random index
		r = 1 + flr(rnd(#sampler.items - 1))
		-- get item from index
		tmp = sampler.items[r]
		-- delete item from sampler
		deli(sampler.items, r)

		return tmp
	end

	return sampler
end
