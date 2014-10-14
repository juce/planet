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

    z = 2
    w,h = 2^z,2^z
    c = {x=w/2, y=h/2}
    l,r,t,b = getBounds(c)
    
    tiles = {}
    pt = nil
    
    touches = {}
    tscale = 1.0

    parameter.watch("z")
    parameter.watch("c.x")
    parameter.watch("c.y")
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
        tiles[key], tile = pt, pt
    end
    local sx = (x-l)*256
    local sy = HEIGHT/tscale-(y-t+1)*256
    sprite(tile, sx, sy)
    --smooth()
    --fill(232, 226, 226, 255)
    --text(key, sx+128, sy+128)
end

function draw()
    background(40, 40, 50)

    if not pt then
        pt = draw_placeholder()
    end

    scale(tscale)
    translate(
        math.floor(WIDTH/2/tscale-(c.x-l)*256), 
        -math.floor(HEIGHT/2/tscale-(c.y-t)*256))

    noSmooth()
    spriteMode(CORNER)
    local sx,sy
    for y=t,b do
        for x=l,r do
            draw_tile(z,x,y)
        end
    end
    
end

function discard(z,l,r,t,b)
    -- discard specific tile images
    -- to keep memory usage under control
    for x=l,r do
        for y=t,b do
            local key = z.."/"..x.."/"..y
            tiles[key] = nil
        end
    end
    collectgarbage()
end

function touched(touch)
    -- keep track of multiple touches
    if touch.state ~= ENDED then
        touches[touch.id] = touch
    else
        touches[touch.id] = nil
        clean(touches)
    end
    
    -- check for pinch/expand gestures
    local zt = {}
    for k,v in pairs(touches) do
        table.insert(zt, v)
    end
    if #zt == 2 then
        local a,b = zt[1],zt[2]
        if touch.state == BEGAN then
            local v1 = vec2(a.x, a.y)
            local v2 = vec2(b.x, b.y)
            sd = v1:dist(v2) 
        elseif touch.state == MOVING then
            local v1 = vec2(a.x, a.y)
            local v2 = vec2(b.x, b.y)
            tscale = v1:dist(v2)/sd
            tscale = math.max(0.5,math.min(2,tscale))
        end
    end
    
    if tscale >= 2.0 and touch.state == ENDED and z < 19 then
        tscale = 1.0
        discard(z,l,r,t,b)
        -- zoom in
        z = z + 1
        w,h = 2^z,2^z
        c.x = c.x * 2
        c.y = c.y * 2
        l,r,t,b = getBounds(c)
        return
        
    elseif tscale <= 0.5 and touch.state == ENDED and z > 0 then
        tscale = 1.0
        discard(z,l,r,t,b)
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
        nl,nr,nt,nb = getBounds(c)
        if nl>l then
            discard(z,l,l,t,b)
        elseif nl<l then
            discard(z,r,r,t,b)
        end
        l,r = nl,nr
        if nt>t then
            discard(z,l,r,t,t)
        elseif nt<t then
            discard(z,l,r,b,b)
        end
        t,b = nt,nb
    end
    
    if touch.state == ENDED then
        tscale = 1.0
    end
end

