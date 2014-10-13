-- Planet

displayMode(OVERLAY)

-- Use this function to perform your initial setup
function setup()
    print("Hello World!")
    
    uri = "https://khms1.google.com/kh/v=159&x=%s&y=%s&z=%s"
    z = 5
    w,h = 2^z,2^z
    l,r = 12,17
    t,b = 8,12
    tiles = {}
    pt = nil
    
    shift = {x=WIDTH/2-(r-l+1)/2*256, y=HEIGHT/2-(b-t+1)/2*256}
    drag = {x=0, y=0}
    
    parameter.watch("shift.x")
    parameter.watch("shift.y")
    parameter.watch("drag.x")
    parameter.watch("drag.y")
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
            tiles[key] = data
        end)
        tiles[key],tile = pt,pt     
    end
    local sx = (x-l)*256
    local sy = HEIGHT-(y-t+1)*256
    sprite(tile, sx, sy)
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


function touched(touch)
    if touch.state ~= BEGAN then
        drag.x = drag.x + touch.deltaX
        drag.y = drag.y + touch.deltaY  
    end
end

