local polygon = {}

function polygon.intersects(line1, line2)
    local v1x1 = line1[1][1]
    local v1y1 = line1[1][2]
    local v1x2 = line1[2][1]
    local v1y2 = line1[2][2]

    local v2x1 = line2[1][1]
    local v2y1 = line2[1][2]
    local v2x2 = line2[2][1]
    local v2y2 = line2[2][2]

    local d1, d2
    local a1, a2, b1, b2, c1, c2

    a1 = v1y2 - v1y1
    b1 = v1x1 - v1x2
    c1 = (v1x2 * v1y1) - (v1x1 * v1y2)

    d1 = (a1 * v2x1) + (b1 * v2y1) + c1
    d2 = (a1 * v2x2) + (b1 * v2y2) + c1

    if d1 > 0 and d2 > 0 then
        return false
    end

    if d1 < 0 and d2 < 0 then
        return false
    end

    a2 = v2y2 - v2y1
    b2 = v2x1 - v2x2
    c2 = (v2x2 * v2y1) - (v2x1 * v2y2)

    d1 = (a2 * v1x1) + (b2 * v1y1) + c2
    d2 = (a2 * v1x2) + (b2 * v1y2) + c2

    if d1 > 0 and d2 > 0 then
        return false
    end

    if d1 < 0 and d2 < 0 then
        return false
    end

    --colinear
    if (a1 * b2) - (a2 * b1) == 0.0 then
        print("colinear")
        return false
    end

    return true
end

function polygon.getBounds(points)
    local xmin, xmax, ymin, ymax

    for i = 1, #points do
        local point = points[i]

        if (not xmin or point[1] < xmin) then
            xmin = point[1]
        end

        if (not xmax or point[1] > xmax) then
            xmax = point[1]
        end

        if (not ymin or point[2] < ymin) then
            ymin = point[2]
        end

        if (not ymax or point[2] > ymax) then
            ymax = point[2]
        end
    end

    return {
        x = xmin,
        y = ymin,
        width = xmax - xmin,
        height = ymax - ymin
    }
end

local function isLeft(p0, p1, p2)
    return ((p1[1] - p0[1]) * (p2[2] - p0[2]) - (p2[1] - p0[1]) * (p1[2] - p0[2]))
end

local function windings(p, v)
    local wn = 0

    for i = 1, #v - 1 do
        if v[i][2] <= p[2] then
            if (v[i + 1][2] > p[2]) then
                if isLeft(v[i], v[i + 1], p) > 0 then
                    wn = wn + 1
                end
            end
        else
            if (v[i + 1][2] <= p[2]) then
                if (isLeft(v[i], v[i + 1], p) < 0) then
                    wn = wn - 1
                end
            end
        end
    end
    return wn
end

function polygon.contains(points, point, bounds)   
    
    if (point[1] < bounds.x or point[1] > bounds.x + bounds.width or point[2] < bounds.y or point[2] > bounds.y + bounds.height) then
        return false
    end

    local horizontal = {{bounds.x, point[2]}, {point[1], point[2]}}
	local windingNumber = windings(point, points)
    
    return windingNumber % 2 == 1
end

function polygon.isSelfIntersecting(points)
    local edges = {}
    for i = 1, #points do
        local a = points[(i - 1) % #points + 1]
        local b = points[i % #points + 1]

        edges[#edges + 1] = {a, b}
    end

    if #edges < 4 then
        return false
    end

    for i = 1, #edges do
        for j = i + 1, #edges do
            if math.abs(j - i) > 1 and (i > 1 or j < #edges) then
                local ai = (i - 1 % #edges) + 1
                local aj = (j - 1 % #edges) + 1

                local a = edges[ai]
                local b = edges[aj]

                if polygon.intersects(a, b) then
                    return true
                end
            end
        end
    end

    return false
end

function polygon.getCircle(center, radius)
    local segments = math.max(4, math.floor(radius / 2))
    local da = math.pi * 2 / segments
    local result = {}

    for i = 1, segments do
        result[#result + 1] = {math.cos(da * (i - 1)) * radius + center[1], math.sin(da * (i - 1)) * radius + center[2]}
    end

    return result

end

return polygon
