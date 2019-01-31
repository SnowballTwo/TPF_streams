local vec3 = { }

function vec3.add(a, b)
	return { a[1] + b[1], a[2] + b[2], a[3] + b[3] }
end

function vec3.sub(a, b)
	return { a[1] - b[1], a[2] - b[2], a[3] - b[3] }
end

function vec3.mul(f, v)
	return { f * v[1], f * v[2], f * v[3] }
end

function vec3.dot(a, b)
	return a[1] * b[1] + a[2] * b[2] + a[3] * b[3];
end

function vec3.cross(a, b)
	return {
		a[2] * b[3] - a[3] * b[2],
		a[3] * b[1] - a[1] * b[3],
		a[1] * b[2] - a[2] * b[1] }
end

function vec3.length(v)
	return math.sqrt(vec3.dot(v, v))
end

function vec3.distance(a, b)
	return vec3.length(vec3.sub(a, b))
end

function vec3.normalize(v)
	return vec3.mul(1.0 / vec3.length(v), v)
end

function vec3.angle(a,b)
	local unit = math.min( 1, math.max( -1, vec3.dot(a,b) / (vec3.length(a) * vec3.length(b)) ))
	return math.acos(unit)
end

return vec3