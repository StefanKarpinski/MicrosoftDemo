using GeometryTypes, DataFrames, Colors, GLVisualize, Reactive, GLAbstraction

# wget http://www.astronexus.com/files/downloads/hygdata_v3.csv.gz
# mv hygdata_v3.csv.gz stars.csv.gz
# gunzip stars.csv.gz
stars = readtable("stars.csv");

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

scales = Vec2f0.(map(mag->Vec2f0(mag)./13f0, stars[:absmag].data))

positions2 = positions ./ 100f0
window = glscreen(color = RGBA(0f0, 0f0, 0f0, 0f0))

xyz = convert(Matrix, stars[[:x, :y, :z]])
u, s, v = svd(xyz)
u .*= median(map(sign, v), 1)
v .*= median(map(sign, v), 1)
# up: flattest direction
up = normalize(Vec3f0(v[:,3]))
# generate camera path with N steps
N = 1000
r = [5 + 15*cos(2π*(i/2N))^2 for i = 0:N-1]
ϕ = [10*sin(3π*(i/N)) for i = 0:N-1]
θ = [8π*(i/N) for i = 0:N-1]
camera_path = map(r, ϕ, θ) do r, ϕ, θ
    Vec3f0(r*(cos(θ)*v[:,2] + sin(θ)*v[:,1]) + ϕ*v[:,3])
end

# create an camera eyeposition signal, which follows the path
timesignal = Signal(1)
eyeposition = map(timesignal) do index
    len = length(camera_path)
    Vec3f0(camera_path[index])
end
# create the camera lookat and up vector
lookatposition = Signal(Vec3f0(3*v[:,1]))
upvector = Signal(up)
println(lookatposition)
println(eyeposition)
# create a camera from these
cam = PerspectiveCamera(window.area, eyeposition, lookatposition, upvector)

push!(cam.farclip, 10000f0)
_view(visualize(
    (Circle, positions2),
    color = colors,
    scale = scales
), window, camera = cam)

# don't use renderloop
#@async renderloop(window)

# create a stream to which we can add frames
io, buffer = GLVisualize.create_video_stream("stars.mkv", window)
for i = 1:N
    # do something
    # if you call @async renderloop(window) you can replace this part with yield
    GLWindow.render_frame(window)
    GLWindow.swapbuffers(window)
    GLWindow.poll_glfw()
    GLWindow.poll_reactive()
    push!(timesignal, mod1(value(timesignal)+1, N))
    yield()
    #add the frame from the current window
    GLVisualize.add_frame!(io, window, buffer)
end
close(io)
GLWindow.destroy!(window)
