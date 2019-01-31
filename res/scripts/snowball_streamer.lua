local vec2 = require "snowball_streamer_vec2"
local vec3 = require "snowball_streamer_vec3"
local polygon = require "snowball_streamer_polygon"
local plan = require "snowball_streamer_planner"
local vec4 = require "vec4"
local transf = require "transf"

local EXTEND_NONE = 0
local EXTEND_START = 1
local EXTEND_END = 2
local EXTEND_BOTH = 3

local sprays = {
    "asset/snowball_streamer_cascade_spray_small.mdl",
    "asset/snowball_streamer_cascade_spray_medium.mdl",
    "asset/snowball_streamer_cascade_spray_large.mdl"
}

local streamer = {}

streamer.markerStore = {}
streamer.finisherStore = {}
streamer.connectorStore = {}
streamer.markerStore = {}
streamer.markerId = "asset/snowball_streamer_marker.mdl"
streamer.finisherId = "asset/snowball_streamer_finisher.mdl"
streamer.cascadeId = "asset/snowball_streamer_cascade_marker.mdl"
streamer.leftConnectorId = "asset/snowball_streamer_connector_left.mdl"

local function compareByCount(a, b)
    return a.count < b.count
end

function streamer.getClosestObject(point, model, max)
    local entities = game.interface.getEntities({pos = point, radius = max}, {type = "ASSET_GROUP", includeData = true})
    local object = nil

    if entities then
        local dist = nil
        local mindist = nil

        for id, data in pairs(entities) do
            local objectcount = data.models[model] or 0
            if objectcount > 0 then
                local dist = vec2.length(vec2.sub(data.position, point))

                if (not mindist) or (dist < mindist) then
                    mindist = dist
                    object = data                   
                end
            end
        end
    end
   
    return object
end

function streamer.makeConnectors(lefts)

    local result = {}
    if not lefts then
        return result
    end

    for i = 1, #lefts do
        local left = lefts[i]
        local right = streamer.getClosestObject(left.position, "asset/snowball_streamer_connector_right.mdl", 150)
        if right then

            local normal = vec3.mul(0.5, vec3.sub(right.position, left.position))

            result[#result + 1] = {
                position = vec3.add(left.position, normal),
                normal = normal
            }
        end
    end

    return result
    
end

function streamer.updateEntityLists()
    
    if not streamer.markerStore then
        streamer.markerStore = {}
    end
    if not streamer.finisherStore then
        streamer.finisherStore = {}
    end
    if not streamer.connectorStore then
        streamer.connectorStore = {}
    end

    local built = plan.updateEntityLists({
        [streamer.markerId] = streamer.markerStore,
        [streamer.finisherId] = streamer.finisherStore,
        [streamer.leftConnectorId] = streamer.connectorStore
    })

    for k, data in pairs(streamer.markerStore) do
        data.cascade = (data.models["asset/snowball_streamer_cascade_marker.mdl"] or 0) > 0
    end
      
    return built

end

function streamer.createSnapPoint(point, normal, width)
    
    local np_left = vec3.add(point, vec3.mul(0.5 * width, {-normal[1], -normal[2], 0.0}))
    local np_right = vec3.add(point, vec3.mul(0.5 * width, {normal[1], normal[2], 0.0}))

    game.interface.buildConstruction(
        "asset/snowball_streamer_connector.con",
        {type = "left"},
        transf.transl({x = np_left[1], y = np_left[2], z = np_left[3]})
    )
    game.interface.buildConstruction(
        "asset/snowball_streamer_connector.con",
        {type = "right"},
        transf.transl({x = np_right[1], y = np_right[2], z = np_right[3]})
    )
end

local function normalizeAngle(angle)
    local result = angle
    while result > math.pi do
        result = result - math.pi
    end

    while result < -math.pi do
        result = result + math.pi
    end
    return result
end

function streamer.getPoints(markers, connectors, smoothen, width)
    local result = {}

    for i = 1, #markers do
        result[#result + 1] = markers[i].position

        if (i > 1) then
            result[#result].isCascadeTarget = markers[i].cascade
            result[#result - 1].isCascadeTop = markers[i].cascade
        end
    end

    if #result > 1 then
        streamer.snap(result[1], connectors, width)
        streamer.snap(result[#result], connectors, width)
    end

    if smoothen then
        result = streamer.getBezierCurve(result, 0.1, width)
    end

    streamer.correctHeight(result)
    result = streamer.createCascades(result)
    streamer.correctHeight(result)

    return result
end

function streamer.snap(point, connectors, width)
    local mindist = nil
    local snap = nil

    for i = 1, #connectors do
        local dist = vec2.length(vec2.sub(point, connectors[i].position))

        if (dist <= width) and ((not mindist) or (dist < mindist)) then
            mindist = dist
            snap = connectors[i]
        end
    end

    if snap then
        point[1] = snap.position[1]
        point[2] = snap.position[2]
        point[3] = snap.position[3]
        print("snap: " .. point[3])
        point.snapped = true
        point.connector = snap
    end
end

function streamer.correctHeight(points)
    local currentHeight = nil

    for i = 1, #points do
        if not currentHeight then
            currentHeight = points[i][3]
        end
        currentHeight = math.min(currentHeight, points[i][3])
        points[i][3] = currentHeight
    end
end

function streamer.getNormals(points)
    local result = {}

    for i = 1, #points do
        local normal = nil
        if points[i].snapped then
            normal = vec2.normalize(points[i].connector.normal)
            normal.snapped = true
            normal.length = vec2.length(points[i].connector.normal)
        end

        if not normal then
            normal = {0, 0}

            if i > 1 then
                local ortho =
                    vec2.normalize {
                    points[i][2] - points[i - 1][2],
                    points[i][1] - points[i - 1][1]
                }

                normal[1] = normal[1] + ortho[1]
                normal[2] = normal[2] - ortho[2]
            end
            if i < #points then
                local ortho =
                    vec2.normalize {
                    points[i + 1][2] - points[i][2],
                    points[i + 1][1] - points[i][1]
                }

                normal[1] = normal[1] + ortho[1]
                normal[2] = normal[2] - ortho[2]
            end

            normal = vec2.normalize(normal)

            if i > 1 and i < #points then
                local a = vec2.sub(points[i], points[i - 1])
                local b = vec2.sub(points[i + 1], points[i])
                local cosa = vec2.dot(a, b) / (vec2.length(a) * vec2.length(b))

                if (cosa > -1 and cosa < 1) then
                    local an = math.acos(cosa)
                    local angle = 0.5 * math.abs(normalizeAngle(an))

                    normal[1] = normal[1] / math.cos(angle)
                    normal[2] = normal[2] / math.cos(angle)
                end
            end
        end
        result[#result + 1] = normal
    end

    return result
end

function streamer.getOutline(points, normals, width)
    local polygon = {}
    local right = {}
    local left = {}

    for i = 1, #points do
        local normal = normals[i]

        right[#right + 1] = {
            points[i][1] + 0.5 * width * normal[1],
            points[i][2] + 0.5 * width * normal[2],
            points[i][3]
        }
        left[#left + 1] = {
            points[i][1] - 0.5 * width * normal[1],
            points[i][2] - 0.5 * width * normal[2],
            points[i][3]
        }
    end

    if #left < 2 or #right < 2 then
        return nil
    end

    for i = 1, #right do
        polygon[#polygon + 1] = right[i]
    end

    for i = 1, #left do
        polygon[#polygon + 1] = left[#left - i + 1]
    end

    return polygon
end

function streamer.setZone(points, normals, width)
    if (not points or not normals or not width) then
        game.interface.setZone("streamzone", nil)
        return
    end

    local outline = nil

    if #points == 1 then
        outline = polygon.getCircle(points[1], 0.5 * width)
    else
        outline = streamer.getOutline(points, normals, width)
    end

    if not outline then
        game.interface.setZone("streamzone", nil)
        return
    end

    local valid = (polygon.isSelfIntersecting(outline) == false)
    local color = {1, 0, 0, 1}

    if valid then
        color = {38 / 255, 89 / 255, 173 / 255, 1.0}
    end

    local streamzone = {polygon = outline, draw = true, drawColor = color}
    game.interface.setZone("streamzone", streamzone)
end

local function getCurveSegment(segment, tension, width, result)
    local length = vec2.length(vec2.sub(segment[2], segment[3]))

    local m1x = (1 - tension) * (segment[3][1] - segment[1][1]) / 2
    local m2x = (1 - tension) * (segment[4][1] - segment[2][1]) / 2

    local m1y = (1 - tension) * (segment[3][2] - segment[1][2]) / 2
    local m2y = (1 - tension) * (segment[4][2] - segment[2][2]) / 2

    local parts = math.round(length / width * 1.5)

    for i = 1, parts - 1 do
        local t = 1.0 / parts * i

        local x =
            (2 * t * t * t - 3 * t * t + 1) * segment[2][1] + (t * t * t - 2 * t * t + t) * m1x +
            (-2 * t * t * t + 3 * t * t) * segment[3][1] +
            (t * t * t - t * t) * m2x
        local y =
            (2 * t * t * t - 3 * t * t + 1) * segment[2][2] + (t * t * t - 2 * t * t + t) * m1y +
            (-2 * t * t * t + 3 * t * t) * segment[3][2] +
            (t * t * t - t * t) * m2y

        result[#result + 1] = {x, y}
    end
end
function streamer.getBezierCurve(points, tension, width)
    local result = {}

    if #points < 2 then
        return {points[1]}
    elseif #points == 2 then
        result[#result + 1] = points[1]
        local parts = math.round(length / width * 1.5)
        for i = 1, parts - 1 do
            result[#result + 1] = vec2.add(points[1], vec2.mul(i / parts, vec2.sub(points[2], points[1])))
        end
    else
        local n = #points - 1

        for i = 0, n - 1 do
            result[#result + 1] = points[i + 1]

            if i == 0 then
                getCurveSegment({points[1], points[1], points[2], points[3]}, tension, width, result)
            elseif (i == n - 1) then
                getCurveSegment({points[n - 1], points[n], points[n + 1], points[n + 1]}, tension, width, result)
            else
                getCurveSegment({points[i], points[i + 1], points[i + 2], points[i + 3]}, tension, width, result)
            end
        end
    end

    result[#result + 1] = points[#points]

    for i = 1, #result do
        if (not result[i][3]) or (not result[i].snapped) then
            result[i][3] = game.interface.getHeight({result[i][1], result[i][2]})
        end
    end

    return result
end

function streamer.getTerrain(points, normals, widths, depth, extend, part)
    local polygon = {}
    local right = {}
    local left = {}

    for i = 1, #points do

        local p = points[i]
        local width = widths[i]
        local n = vec2.normalize(normals[i])

        if i == 1 and ((extend == EXTEND_START) or (extend == EXTEND_BOTH)) then
            p = vec3.add(p, vec3.mul(0.5 * width, {n[2], -n[1], 0}))
        end

        if i == #points and ((extend == EXTEND_END) or (extend == EXTEND_BOTH)) then
            p = vec3.add(p, vec3.mul(0.5 * width, {-n[2], n[1], 0}))
        end

        local nl = vec3.normalize({n[1], n[2], -math.sqrt(2) * depth / width})
        local nr = vec3.normalize({-n[1], -n[2], -math.sqrt(2) * depth / width})

        local r = {p[1] + 0.5 * width * n[1], p[2] + 0.5 * width * n[2], p[3]}
        local l = {p[1] - 0.5 * width * n[1], p[2] - 0.5 * width * n[2], p[3]}
        
        if part == "surface" then
            left[#left + 1] = l
            right[#right + 1] = r
        elseif part == "ground" then
            left[#left + 1] = vec3.add(l, vec3.mul(0.25 * width, nl))
            right[#right + 1] = vec3.add(r, vec3.mul(0.25 * width, nr))
        elseif part == "left" then
            left[#left + 1] = l
            right[#right + 1] = vec3.add(l, vec3.mul(0.25 * width, nl))
        elseif part == "right" then
            left[#left + 1] = vec3.add(r, vec3.mul(0.25 * width, nr))
            right[#right + 1] = r
        elseif part == "left_beach" then
            left[#left + 1] = vec3.add(l, vec3.mul(2, {-n[1], -n[2], 0}))
            right[#right + 1] = l
        elseif part == "right_beach" then
            left[#left + 1] = r
            right[#right + 1] = vec3.add(r, vec3.mul(2, {n[1], n[2], 0}))
        elseif part == "left_outline" then
            left[#left + 1] = vec3.add(l, vec3.mul(0.1, {-n[1], -n[2], 0}))
            right[#right + 1] = l
        elseif part == "right_outline" then
            left[#left + 1] = r
            right[#right + 1] = vec3.add(r, vec3.mul(0.1, {n[1], n[2], 0}))
        end
        
    end

    if #left < 2 or #right < 2 then
        return nil
    end

    for i = 1, #right do
        polygon[#polygon + 1] = right[i]
    end

    for i = 1, #left do
        polygon[#polygon + 1] = left[#left - i + 1]
    end

    return polygon
end

function streamer.getLakeHeight(pos)
    local entities = game.interface.getEntities({pos = {pos[1], pos[2]}, radius = 25}, {type = "ASSET_GROUP"})

    if entities then
        for i = 1, #entities do
            local c = entities[i]

            local data = game.interface.getEntity(c)
            local lakeTiles =
                data.models["asset/snowball_laker_water_8.mdl"] or data.models["asset/snowball_laker_water_16.mdl"] or
                data.models["asset/snowball_laker_water_32.mdl"] or
                data.models["asset/snowball_laker_water_64.mdl"] or
                data.models["asset/snowball_laker_water_128.mdl"] or
                0

            if lakeTiles > 0 then
                return data.position[3]
            end
        end
    end

    return nil
end

function streamer.triangulateStrip(strip, triangles)
    for i = 1, (0.5 * #strip - 1) do
        local right1 = strip[#strip - i + 1]
        local left1 = strip[i]
        local right2 = strip[#strip - i]
        local left2 = strip[i + 1]

        triangles[#triangles + 1] = {left1, right1, left2}
        triangles[#triangles + 1] = {left2, right1, right2}
    end
end

function streamer.removeDuplicatePoints(points)
    local result = {}
    for i = 1, #points do
        if i == 1 or vec2.length(vec2.sub(points[i], points[i - 1])) > 1e-9 then
            result[#result + 1] = point[i]
        end
    end

    return result
end

function streamer.createCascades(points)
    local result = {}

    for i = 1, #points do
        result[#result + 1] = points[i]

        if points[i].isCascadeTop and i < #points then
            local height_point_index = i + 1
            local height_point = nil
            local height_point_found = false

            while height_point_found == false and height_point_index <= #points do
                height_point = points[height_point_index]

                if height_point.isCascadeTarget then
                    height_point_found = true
                else
                    height_point_index = height_point_index + 1
                end
            end

            if height_point_index == false or i == #points then
                error("Something went terribly wrong: no cascade target found")
            end

            local bottom = height_point[3]
            local target = points[i + 1]
            local top_point = points[i]
            local top = top_point[3]
            local height = top - bottom

            --cascades smaller than ~2m look just like plain dust
            if (height > 2.0) then
                local segment = vec2.sub(target, top_point)
                local direction = segment

                if i > 1 then
                    direction = vec2.sub(top_point, points[i - 1])
                end

                local length = vec2.length(segment)
                local bottom_point =
                    vec2.add(top_point, vec2.mul(math.min(length * 0.3, 0.3 * height), vec2.normalize(direction)))

                bottom_point.isCascadeBottom = true

                bottom_point[3] = bottom
                result[#result + 1] = bottom_point
            else
                points[i].isCascadeTop = false
                height_point.isCascadeTarget = false
            end
        end
    end

    return result
end

function streamer.createCascade(position, normal, width, height, depth, models)
    local size = 1
    if (height > 6) then
        size = 2
    end
    if (height > 12) then
        size = 3
    end
    local step = 2 + size

    local v = vec2.normalize(normal)

    local left = -math.round(width * 0.1) * step
    local right = math.round(width * 0.1) * step

    for f = left, right, step do
        local p = vec2.add(position, vec2.mul(f, v))
        local z = position[3] - 1

        local model = sprays[size]

        models[#models + 1] = {
            id = model,
            transf = transf.new(
                vec4.new(1, 0, 0, .0),
                vec4.new(0, 1, 0, .0),
                vec4.new(0, 0, 1, .0),
                vec4.new(p[1], p[2], z, 1.0)
            )
        }
    end

    --[[ Sound doesn't work on assets, also, the positioning is a problem
    
    local sound = "asset/snowball_streamer_cascade_sound_small.mdl"
    if (height > 8) then
        sound = "asset/snowball_streamer_cascade_sound_large.mdl"
    end

    models[#models + 1] = {
        id = sound,
        transf = transf.new(
            vec4.new(1, 0, 0, .0),
            vec4.new(0, 1, 0, .0),
            vec4.new(0, 0, 1, .0),
            vec4.new(position[1], position[2], position[3] - depth, 1.0)
        )
    }]]
end

function streamer.lock(interactive)
    local player = nil
    if interactive then
        player = game.interface.getPlayer()
    end

    local streams =
        game.interface.getEntities(
        {pos = {0, 0}, radius = 100000},
        {type = "CONSTRUCTION", fileName = "asset/snowball_streamer_digger.con"}
    )
    for i = 1, #streams do
        game.interface.setPlayer(streams[i], player)
    end
end

return streamer
