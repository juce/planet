-- Planet

displayMode(OVERLAY)

-- Use this function to perform your initial setup
function setup()
    print("Hello World!")
    
    uri = "https://khms1.google.com/kh/v=%s&x=%s&y=%s&z=%s"
    kv = 159
    z = 3
    w,h = 6,5
    tiles = {}
    
    v = {x=0, y=0}
end

function draw_tile(z, x, y, sx, sy)
    local t = tiles[y*w+x]
    if t then
        sprite(t, sx, sy)
    else
        print("downloading tile: ",z,x,y)
        http.request(string.format(uri, kv, x, y, z), function(data, status, headers)
            tiles[y*w+x] = data
        end, function(err)
            local t = image(256, 256)
            setContext(t)
            fill(79, 79, 92, 255)
            noStroke()
            rect(0,0,256,256)
            setContext()
            tiles[y*w+x] = t    
        end)
    end
end

-- This function gets called once every frame
function draw()
    -- This sets a dark background color 
    background(40, 40, 50)

    noSmooth()

    -- Do your drawing here
    translate(v.x,v.y)
    
    local sx,sy
    for y=0,h-1 do
        for x=0,w-1 do
            sx = WIDTH/w/2 + x*256
            sy = WIDTH/h/2 + (h-1-y)*256
            draw_tile(z,x,y,sx,sy)
        end
    end
    
end


function touched(touch)
    if touch.state ~= BEGAN then
        v.x = v.x + touch.deltaX
        v.y = v.y + touch.deltaY  
    end
end

