function data()
return {
	tracks = {
		{ name = "environment/river_medium.wav", refDist = 50.0 }
	},

	updateFn = function (input)
		return {
			tracks = {
				{ 
					gain = 1.0,
					pitch = 1.0
				}
			}
		}
	end
}
end
