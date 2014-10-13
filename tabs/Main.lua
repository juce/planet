-- Planet

displayMode(OVERLAY)

-- Use this function to perform your initial setup
function setup()
    print("Hello World!")
    
    uri = "https://khms1.google.com/kh/v=159&x=%s&y=%s&z=%s"
    z = 3
    w,h = 2^z,2^z
    l,r = 1,6
    t,b = 1,5
    tiles = {}
    pt = nil
    
    l0,r0 = l,r
    
    shift = {x=WIDTH/2-(r-l+1)/2*256, y=HEIGHT/2-(b-t+1)/2*256}
    drag = {x=0, y=0}
    
    --parameter.watch("shift.x")
    --parameter.watch("shift.y")
    --parameter.watch("drag.x")
    --parameter.watch("drag.y")
    touches = {}
    parameter.watch("str(touches)")
end

function str(t)
    local tt = {}
    for k,v in pairs(t) do
        tt[#tt + 1] = v
    end
    return table.concat(tt,"\n")
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
        print("downloading tile: ",z,x,y)
        http.request(string.format(uri, x, y, z), function(data, status, headers)
            if tonumber(status) == 200 then
                tiles[key] = data
            end
        end)
        tiles[key],tile = pt,pt     
    end
    local sx = (x-l)*256
    local sy = HEIGHT-(y-t+1)*256
    sprite(tile, sx, sy)
    smooth()
    fill(232, 226, 226, 255)
    text(key, sx+128, sy+128)
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
    translate(shift.x + drag.x, -shift.y + drag.y)
    
    spriteMode(CORNER)
    local sx,sy
    for y=t,b do
        for x=l,r do
            draw_tile(z,x,y)
        end
    end
    
end

function discard_tiles(z,l,r,t,b)
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
        touches[touch.id] = touch.id..","..touch.x..","..touch.y
    else
        touches[touch.id] = nil
        clean(touches)
    end
    
    -- drag    
    if touch.state ~= BEGAN then
        drag.x = drag.x + touch.deltaX
        drag.y = drag.y + touch.deltaY  
        if drag.x <= -256 and r<w-1 then
            discard_tiles(z,l,l,t,b)
            drag.x,l,r = 0,l+1,r+1
        elseif drag.x >= 256 and l>0 then
            discard_tiles(z,r,r,t,b)
            drag.x,l,r = 0,l-1,r-1
        end
        if drag.y <= -256 and t>0 then
            discard_tiles(z,l,r,b,b)
            drag.y,t,b = 0,t-1,b-1
        elseif drag.y >= 256 and b<h-1 then
            discard_tiles(z,l,r,t,t)
            drag.y,t,b = 0,t+1,b+1
        end
    end
end

