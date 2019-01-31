local tu = require "texutil"

function data()
return {
	detailTex = tu.makeTextureMipmapClampVertical("ground_texture/snowball_streamer_grass_border_01_albedo.dds", true, true),
	detailNrmlTex = tu.makeTextureMipmapClampVertical("ground_texture/snowball_streamer_grass_border_01_normal.dds", true, true, true),
	detailSize = { 8.0, 8.0 },
	priority = 1
}
end
