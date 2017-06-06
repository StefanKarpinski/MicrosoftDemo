using JuliaDB, GeometryTypes, IndexedTables, Colors, GLVisualize
dir(paths...) = joinpath(dirname(@__FILE__), paths...)

stars = loadfiles([dir("stars.csv")], indexcols = []);
gstars = gather(stars)

"""
bv color index to color
"""
function bv2rgb(bv)
    bv < -0.4 && (bv = -0.4)
    bv > 2.0 && (bv = 2.0)
    if bv >= -0.40 && bv < 0.00
        t = (bv + 0.40) / (0.00 + 0.40)
        r = 0.61 + 0.11 * t + 0.1 * t * t
        g = 0.70 + 0.07 * t + 0.1 * t * t
        b = 1.0
    elseif bv >= 0.00 && bv < 0.40
        t = (bv - 0.00) / (0.40 - 0.00)
        r = 0.83 + (0.17 * t)
        g = 0.87 + (0.11 * t)
        b = 1.0
    elseif bv >= 0.40 && bv < 1.60
        t = (bv - 0.40) / (1.60 - 0.40)
        r = 1.0
        g = 0.98 - 0.16 * t
    else
        t = (bv - 1.60) / (2.00 - 1.60)
        r = 1.0
        g = 0.82 - 0.5 * t * t
    end
    if bv >= 0.40 && bv < 1.50
        t = (bv - 0.40) / (1.50 - 0.40)
        b = 1.00 - 0.47 * t + 0.1 * t * t
    elseif bv >= 1.50 && bv < 1.951
        t = (bv - 1.50) / (1.94 - 1.50)
        b = 0.63 - 0.6 * t * t
    else
        b = 0.0
    end
    return RGB{Float32}(r, g, b)
end

positions = map(x-> Point3f0(x.x, x.y, x.z), gstars).data
colors = map(x-> RGBA{Float32}(bv2rgb(get(x.ci, 0.0)), 0.4f0), gstars).data
glow_colors = map(gstars) do x
    # shift them a bit in brightness and make it more transparent.
    hsv = HSV(bv2rgb(get(x.ci, 0.0)))
    hsv = HSV(hsv.h, hsv.s, clamp(hsv.v + 0.2, 0, 1))
    RGBA{Float32}(RGBA(hsv, 0.3))
end.data

scales = map(gstars) do nt
    Vec2f0(nt.mag + 27) ./ 10000f0
end.data
positions2 = positions ./ 100f0
w = glscreen(color = RGBA(0f0, 0f0, 0f0, 0f0))
_view(visualize(
    (Circle, positions2),
    color = colors,
    glow_color = glow_colors,
    glow_width = 0.001f0,
    scale = scales
), camera = :perspective)
GLAbstraction.center!(w)
@async renderloop(w)
