using GeometryTypes, DataFrames, Colors, GLVisualize

# wget http://www.astronexus.com/files/downloads/hygdata_v3.csv.gz
# mv hygdata_v3.csv.gz stars.csv.gz
# gunzip stars.csv.gz
stars = readtable("stars.csv");

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

positions = map(Point3f0, zip(stars[:x], stars[:y], stars[:z]))

colors = RGBA{Float32}.(map(x-> RGBA{Float32}(bv2rgb(ifelse(isa(x, NAtype), 0.2f0, x)), 0.3f0), stars[:ci]).data)

scales = Vec2f0.(map(stars[:absmag]) do mag
    Vec2f0(mag) ./ 13f0
end.data)

positions2 = positions ./ 100f0
w = glscreen(color = RGBA(0f0, 0f0, 0f0, 0f0))
_view(visualize(
    (Circle, positions2),
    color = colors,
    scale = scales
), camera = :perspective)
scales
GLAbstraction.center!(w)
@async renderloop(w)
