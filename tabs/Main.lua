-- Planet

displayMode(OVERLAY)

function getBounds(c)
    local l = math.floor(c.x)-3
    local r = l + 5
    local t = math.floor(c.y)-2
    local b = t + 4
    return l,r,t,b
end

-- Use this function to perform your initial setup
function setup()
    print("Hello Planet!")
    
    uri = "https://khms1.google.com/kh/v=159&x=%s&y=%s&z=%s"
    z = 3
    w,h = 2^z,2^z
    c = {x=w/2, y=h/2}
    l,r,t,b = getBounds(c)
    
    tiles = {}
    pt = nil
    
    shift = {x=WIDTH/2-(c.x-l)*256, y=HEIGHT/2-(c.y-t)*256}
    drag = {x=0, y=0}
    
    touches = {}
    tv = 0
    --parameter.watch("str(touches)")
    --parameter.watch("tv")
    parameter.watch("state()")
    parameter.watch("shift.x")
    parameter.watch("shift.y")
    --parameter.watch("num(tiles)")
    --parameter.watch("CurrentTouch.deltaX")
    --parameter.watch("CurrentTouch.deltaY")
end

function str(t)
    local tt = {}
    for k,v in pairs(t) do
        tt[#tt + 1] = v.id..","..v.x..","..v.y
    end
    return table.concat(tt,"\n")
end

function state()
    return string.format("z=%s,c.x=%s,c.y=%s",z,c.x,c.y)
end

function num(t)
    local c = 0
    for k,v in pairs(t) do
        c = c + 1
    end
    return c
end

function clean(t)
    local c = 0
    for k,v in pairs(t) do
        c = c + 1
        if c > 2 then 
            t[k] = nil
        end
    end
end

function draw_placeholder()
    local tile = image(256, 256)
    setContext(tile)
    smooth()
    fill(65, 59, 94, 255)
    stroke(30, 32, 59, 255)
    strokeWidth(1.0)
    rectMode(CORNER)
    rect(0,0,256,256)
    setContext()
    return tile
end

function draw_tile(z, x, y)
    local key = z .. "/" .. x .. "/" .. y
    local tile = tiles[key]
    if not tile then
        if x>=0 and x<w and y>=0 and y<h then
            print("downloading tile: ",z,x,y)
            http.request(string.format(uri, x, y, z), function(data, status, headers)
                if tonumber(status) == 200 then
                    tiles[key] = data
                end
            end)
        end  
        tile = pt   
    end
    local sx = (x-l)*256
    local sy = HEIGHT-(y-t+1)*256
    sprite(tile, sx, sy)
    --smooth()
    --fill(232, 226, 226, 255)
    --text(key, sx+128, sy+128)
end

-- This function gets called once every frame
function draw()
    -- This sets a dark background color 
    background(40, 40, 50)

    noSmooth()
    
    if not pt then
        pt = draw_placeholder()
    end

    -- Do your drawing here
    shift.x, shift.y = math.floor(WIDTH/2-(c.x-l)*256), math.floor(HEIGHT/2-(c.y-t)*256)
    translate(shift.x, -shift.y)
    
    spriteMode(CORNER)
    local sx,sy
    for y=t,b do
        for x=l,r do
            draw_tile(z,x,y)
        end
    end
    
end

function discard(z,l,r,t,b)
    for x=l,r do
        for y=t,b do
            local key = z.."/"..x.."/"..y
            tiles[key] = nil
        end
    end
end

function touched(touch)
    -- keep track of multiple touches
    if touch.state ~= ENDED then
        touches[touch.id] = touch
    else
        touches[touch.id] = nil
        clean(touches)
    end
    
    -- zoom in
    local zt = {}
    for k,v in pairs(touches) do
        table.insert(zt, v)
    end
    if #zt == 2 and touch.state == MOVING then
        local a, b = zt[1], zt[2]
        local v1 = vec2(a.prevX, a.prevY)
        local v2 = vec2(b.prevX, b.prevY)
        local val = v1:distSqr(v2)
        v1 = vec2(a.x, a.y)
        v2 = vec2(b.x, b.y)
        val = v1:distSqr(v2) - val
        tv = tv + val 
    end
    
    if tv > 200000 and touch.state == ENDED and z < 20 then
        tv = 0
        discard(z,l,r,t,b)
        collectgarbage()
        -- zoom in
        z = z + 1
        w,h = 2^z,2^z
        c.x = c.x * 2
        c.y = c.y * 2
        l,r,t,b = getBounds(c)
        return
        
    elseif tv < -200000 and touch.state == ENDED and z > 3 then
        tv = 0
        discard(z,l,r,t,b)
        collectgarbage()
        -- zoom out
        z = z - 1
        w,h = 2^z,2^z
        c.x = c.x / 2
        c.y = c.y / 2  
        l,r,t,b = getBounds(c)
        return
    end
    
    -- drag    
    if touch.state == MOVING then       
        c.x = c.x - touch.deltaX/256
        c.y = c.y + touch.deltaY/256      
        local nl = math.floor(c.x)-3
        if nl>l then
            discard(z,l,l,t,b)
        elseif nl<l then
            discard(z,r,r,t,b)
        end
        l,r = nl,nl + 6
        local nt = math.floor(c.y)-2
        if nt>t then
            discard(z,l,r,t,t)
        elseif nt<t then
            discard(z,l,r,b,b)
        end
        t,b = nt,nt + 4
    end
    
    if touch.state == ENDED then
        --tween(0.5, c, {x = c.x - 2*touch.deltaX/256, y = c.y + 2*touch.deltaY/256})
        tv = 0
    end
end

