
local mat3 = { }

function mat3.rotX(angle)
    local sx = math.sin(angle)
    local cx = math.cos(angle)

    return {
        {1.0, .0, .0},
        {.0, cx, -sx},
        {.0, sx, cx}
    }
end

function mat3.rotY(angle)
    local sy = math.sin(angle)
    local cy = math.cos(angle)

    return {
        {cy, 0, sy},
        {.0, 1.0, .0},
        {-sy, .0, cy}
    }
end

function mat3.rotZ(angle)
    local sz = math.sin(angle)
    local cz = math.cos(angle)

    return {
        {cz, -sz, .0},
        {sz, cz, .0},
        {.0, .0, 1.0}
    }
end

function mat3.shear(anglex, angley)
    return {
        {1, math.tan(angley), .0},
        {.0, 1, .0},
        {.0, .0, 1}
    }
end

function mat3.scale(x, y, z)
    return {
        {x, 0, .0},
        {0, y, .0},
        {.0, .0, z}
    }
end

function mat3.mul(a, b)
    return {
        {
            a[1][1] * b[1][1] + a[1][2] * b[2][1] + a[1][3] * b[3][1],
            a[1][1] * b[1][2] + a[1][2] * b[2][2] + a[1][3] * b[3][2],
            a[1][1] * b[1][3] + a[1][2] * b[2][3] + a[1][3] * b[3][3]
        },
        {
            a[2][1] * b[1][1] + a[2][2] * b[2][1] + a[2][3] * b[3][1],
            a[2][1] * b[1][2] + a[2][2] * b[2][2] + a[2][3] * b[3][2],
            a[2][1] * b[1][3] + a[2][2] * b[2][3] + a[2][3] * b[3][3]
        },
        {
            a[3][1] * b[1][1] + a[3][2] * b[2][1] + a[3][3] * b[3][1],
            a[3][1] * b[1][2] + a[3][2] * b[2][2] + a[3][3] * b[3][2],
            a[3][1] * b[1][3] + a[3][2] * b[2][3] + a[3][3] * b[3][3]
        }
    }
end

function mat3.transform(a, vector)
    return {
        a[1][1] * vector[1] + a[1][2] * vector[2] + a[1][3] * vector[3],
        a[2][1] * vector[1] + a[2][2] * vector[2] + a[2][3] * vector[3],
        a[3][1] * vector[1] + a[3][2] * vector[2] + a[3][3] * vector[3]
    }
end

function mat3.det(m)
    return 
        m[1][1] * m[2][2] * m[3][3] + 
        m[1][2] * m[2][3] * m[3][1] +
        m[1][3] * m[2][1] * m[3][2] -
        m[1][3] * m[2][2] * m[3][1] -
        m[1][2] * m[2][1] * m[3][3] -
        m[1][1] * m[2][3] * m[3][2]
end

function mat3.solve(A, b)
    local denominator = mat3.det(A)
    local x1 =
        mat3.det(
        {
            {b[1], A[1][2], A[1][3]},
            {b[2], A[2][2], A[2][3]},
            {b[3], A[3][2], A[3][3]}
        }
    ) / denominator

    local x2 =
        mat3.det(
        {
            {A[1][1], b[1], A[1][3]},
            {A[2][1], b[2], A[2][3]},
            {A[3][1], b[3], A[3][3]}
        }
    ) / denominator
    local x3 =
        mat3.det(
        {
            {A[1][1], A[1][2], b[1]},
            {A[2][1], A[2][2], b[2]},
            {A[3][1], A[3][2], b[3]}
        }
    ) / denominator

    return {x1, x2, x3}
end

function mat3.inverse(A)
    local c1 = mat3.solve(A, {1.0, 0.0, 0.0})
    local c2 = mat3.solve(A, {0.0, 1.0, 0.0})
    local c3 = mat3.solve(A, {0.0, 0.0, 1.0})

    return {{c1[1], c2[1], c3[1]}, {c1[2], c2[2], c3[2]}, {c1[3], c2[3], c3[3]}}
end

function mat3.affine(b2, b3)

    local r1 = mat3.solve({b2, b3, {0,0,1}}, {1.0, 0.0, 0.0})
    local r2 = mat3.solve({b2, b3, {0,0,1}}, {0.0, 1.0, 0.0})
    local r3 = mat3.solve({b2, b3, {0,0,1}}, {0.0, 0.0, 1.0})

    return mat3.inverse({r1, r2, r3})

end

return mat3
