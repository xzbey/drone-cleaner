---------------------------- CONST ----------------------------

local DRONE_SIZE = 0.3      -- м
local FLY_AREA = {2.0, 2.0} -- м, м
local HEIGHT = 0.5          -- м
local SPEED = 0.2           -- м / с

-- Декартова система координат

local function round(value, decimal)
    return math.floor(value * 10000 + 0.5) / 10000
end

---------------------------- POINTS ----------------------------

local function generate_points(fly_area, step_x)
    local width, length = fly_area[1], fly_area[2] -- width = X, length = Y

    if width <= 0 or length <= 0 then
        error("Fly area size must be more zero")
    end

    intervals = math.ceil(width / step_x)
    actual_step = width / intervals
    
    points = {}
    moving_up = true

    local time_x, time_y = math.max(round(actual_step / SPEED, 4), 2), round(length / SPEED, 4)
    for i = 0, intervals, 1 do
        local x = round(i * actual_step, 4)
        if moving_up then
            table.insert(points, {x, 0.0, HEIGHT, time_x})
            table.insert(points, {x, length, HEIGHT, time_y})
        else
            table.insert(points, {x, length, HEIGHT, time_x})
            table.insert(points, {x, 0.0, HEIGHT, time_y})
        end

        moving_up = not moving_up
    end

    table.remove(points, 1)
    return points
end


local function print_points(waypoints)
    print("Count points: " .. #waypoints)
    for i, wp in ipairs(waypoints) do
        print(i .. ": x = " .. wp[1] .. ", y = " .. wp[2] .. ", z = " .. wp[3] .. ", t = " .. wp[4])
    end
end


---------------------------- FLY ----------------------------

local points = generate_points(FLY_AREA, DRONE_SIZE)
local id = 1
local landing = false

local function start_fly()
    ap.push(Ev.MCE_PREFLIGHT)
    sleep(5)
    ap.push(Ev.MCE_TAKEOFF)
end

local function stop_fly()
    landing = true
    ap.push(Ev.MCE_LANDING)
end


local function next_point()
    if id > #points then
        stop_fly()
        return
    end
    
    local point = points[id]
    id = id + 1
    ap.goToLocalPoint(point[1], point[2], point[3], point[4]) -- x y z t
end


function callback(event)
    if (event == Ev.TAKEOFF_COMPLETE or event == Ev.POINT_REACHED) and not landing then
        next_point()
    elseif event == Ev.LOW_VOLTAGE1 or event == Ev.LOW_VOLTAGE2 or event == Ev.LOW_CHARGE
            or event == Ev.CONTROL_FAIL or event == Ev.ENGINE_FAIL then
        stop_fly()
    elseif event == Ev.COPTER_LANDED then
        ap.push(Ev.ENGINES_DISARM)
    end
end


-- print_points(points)
start_fly()