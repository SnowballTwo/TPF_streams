local vec2 = { }

function vec2.dot(a, b)
    return a[1] * b[1] + a[2] * b[2]
end

function vec2.add(a, b)
    return {a[1] + b[1], a[2] + b[2]}
end

function vec2.mul(f, a)
    return {f*a[1],f* a[2] }
end

function vec2.sub(a, b)
    return {a[1] - b[1], a[2] - b[2]}
end

function vec2.normalize(vector)
    local length = vec2.length(vector)
    return {vector[1] / length, vector[2] / length}
end

function vec2.length(vector)
    return math.sqrt(vector[1] * vector[1] + vector[2] * vector[2])
end

function vec2.angle(a,b)
    return math.acos(vec2.dot(a,b) / (vec2.length(a) * vec2.length(b)))
end

return vec2