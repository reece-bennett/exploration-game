function print_r ( t )
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        print(indent.."["..pos..'] => "'..val..'"')
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        print(tostring(t).." {")
        sub_print_r(t,"  ")
        print("}")
    else
        sub_print_r(t,"  ")
    end
    print()
end

table.print = print_r

-- KeyPressed and released detection
love.keyboard.keysPressed = {}
love.keyboard.keysReleased = {}

function love.keyboard.wasPressed(key)
  if love.keyboard.keysPressed[key] then
    return true
  end
  return false
end

function love.keyboard.wasReleased(key)
  if love.keyboard.keysReleased[key] then
    return true
  end
  return false
end

function love.keypressed(key, scancode, isrepeat)
  love.keyboard.keysPressed[key] = true
end

function love.keyreleased(key)
  love.keyboard.keysReleased[key] = false
end

function love.keyboard.updateKeys()
  love.keyboard.keysPressed = {}
  love.keyboard.keysReleased = {}
end



-- Class stuff
Sprite = { sheet = nil, quad = nil }
function Sprite:new(offX, offY, sheet)
  o = { sheet = sheet, quad = getQuad(offX, offY, sheet) }
  setmetatable(o, self)
  self.__index = self
  return o
end

Tile = { x = nil, y = nil, background = nil, object = nil, items = {} }
function Tile:new(x, y, background)
  o = { x = x, y = y, background = background, items = {} }
  setmetatable(o, self)
  self.__index = self
  return o
end

Object = { sprite = nil, onBreak = nil, blocking = false }
function Object:new(sprite, onBreak, blocking)
  o = { sprite = sprite, onBreak = onBreak, blocking = blocking }
  setmetatable(o, self)
  self.__index = self
  return o
end

Item = { sprite = nil, name = "unNamed" }
function Item:new(sprite, name)
  o = { sprite = sprite, name = name }
  setmetatable(o, self)
  self.__index = self
  return o
end



function love.load()
  -- Keeps everything nice and pixely
  love.graphics.setDefaultFilter("nearest")

  -- Set the font
  love.graphics.setNewFont(20)

  -- Load the tilesheets
  tileSheet = love.graphics.newImage("assets/tiles.png")
  itemSheet = love.graphics.newImage("assets/items.png")
  tileSize = 16

  -- Background tiles
  bgTiles = {}
  bgTiles[1] = Sprite:new(0, 0, tileSheet)
  bgTiles[2] = Sprite:new(1, 0, tileSheet)
  bgTiles[3] = Sprite:new(2, 0, tileSheet)
  bgTiles[4] = Sprite:new(3, 0, tileSheet)
  bgTiles[5] = Sprite:new(4, 0, tileSheet)
  bgTiles[6] = Sprite:new(5, 0, tileSheet)

  -- Items
  items = {}
  items[1] = Item:new(Sprite:new(0, 0, itemSheet), "Stick")
  items[2] = Item:new(Sprite:new(1, 0, itemSheet), "Log")

  -- Objects
  objects = {}
  objects[1] = Object:new(Sprite:new(0, 2, tileSheet), items[2], false)
  --objects[2] = getQuad(1, 2, tileSheet)

  -- Initalise the map
  mapWidth = 60
  mapHeight = 40

  tileScale = 4

  visibleTilesWidth = 15
  visibleTilesHeight = 11

  cameraX = 1
  cameraY = 1

  map = {}
  for x = 1, mapWidth do
    map[x] = {}
    for y = 1, mapHeight do
      -- Background tile selection
      map[x][y] = Tile:new(x, y, bgTiles[love.math.random(1, #bgTiles)])

      -- Object selection
      local num = love.math.random(-10, #objects)
      if num > 0 then
        map[x][y].object = objects[num]
      end
    end
  end

  table.insert(map[2][3].items, items[1])

  player = {
    x = 1,
    y = 1,
    moveCooldown = 0.2, -- In seconds
    moveTimer = 0,
    img = love.graphics.newImage("assets/player.png"),
    quad = nil,
    breakMode = false,
    invOpen = false,
    inventory = {}
  }
  player.quad = getQuad(0, 0, player.img)

  for i = 1, 5 do
    player.inventory[i] = { item = nil, count = 0 }
  end
end

function getQuad(x, y, image)
  return love.graphics.newQuad(
    x * tileSize,
    y * tileSize,
    tileSize,
    tileSize,
    image:getWidth(),
    image:getHeight())
end

function checkCollision(xOff, yOff)
  xOff = xOff or 0
  yOff = yOff or 0

  if map[player.x+xOff] then
    local ob = map[player.x+xOff][player.y+yOff]
    if ob and ob.object then
      return true
    end
    return false
  end
  return false
end



function love.update(dt)
  -- Exit on escape
  if love.keyboard.isDown("escape") then
    love.event.push("quit")
  end

  -- Player & camera movement
  playerXOffset = player.x - cameraX
  playerYOffset = player.y - cameraY

  if player.moveTimer >= player.moveCooldown and not player.breakMode then
    if love.keyboard.isDown("up") and not checkCollision(0, -1) then
      player.y = player.y - 1
      if player.y < 1 then player.y = 1 end

      if playerYOffset <= 5 then cameraY = cameraY - 1 end
      if cameraY < 1 then
        cameraY = 1
      end

      player.moveTimer = 0
    end

    if love.keyboard.isDown("right") and not checkCollision(1, 0) then
      player.x = player.x + 1
      if player.x > mapWidth then player.x = mapWidth end

      if playerXOffset >= 7 then cameraX = cameraX + 1 end
      if cameraX > mapWidth+1 - visibleTilesWidth then
        cameraX = mapWidth+1 - visibleTilesWidth
      end

      player.moveTimer = 0
    end

    if love.keyboard.isDown("down") and not checkCollision(0, 1) then
      player.y = player.y + 1
      if player.y > mapHeight then player.y = mapHeight end

      if playerYOffset >= 5 then cameraY = cameraY + 1 end
      if cameraY > mapHeight+1 - visibleTilesHeight then
        cameraY = mapHeight+1 - visibleTilesHeight
      end

      player.moveTimer = 0
    end

    if love.keyboard.isDown("left") and not checkCollision(-1, 0) then
      player.x = player.x - 1
      if player.x < 1 then player.x = 1 end

      if playerXOffset <= 7 then cameraX = cameraX - 1 end
      if cameraX < 1 then
        cameraX = 1
      end

      player.moveTimer = 0
    end
  end

  -- See if there is an item to pick up
  local square = map[player.x][player.y]
  for i = #square.items, 1, -1 do
    local item = square.items[i]
    print(i, item)

    local firstSame, firstEmpty = 0, 0
    -- Loop through the inventory finding the first occurance of this item and first empty slot
    for slot, v in ipairs(player.inventory) do
      if v.item and v.item.name == item.name and firstSame == 0 then
        firstSame = slot
      elseif v.item == nil and firstEmpty == 0 then
        firstEmpty = slot
      end
    end

    if firstSame > 0 then
      -- If the item is somewhere in the inventory then put it there and remove from the floor
      player.inventory[firstSame].count = player.inventory[firstSame].count + 1
      table.remove(square.items, #square.items)
    elseif firstEmpty > 0 then
      -- Else put it in the first empty slot and remove from the floor
      local slot = player.inventory[firstEmpty]
      slot.item = item
      slot.count = 1
      table.remove(square.items, #square.items)
    end
  end

  -- Check if in break mode
  if love.keyboard.isDown("x") then
    player.breakMode = true
  else
    player.breakMode = false
  end

  -- Toggle inventory
  if love.keyboard.wasPressed("z") then
    player.invOpen = not player.invOpen
  end

  if player.breakMode then
    local bx, by = 0

    if love.keyboard.isDown("up") and player.y > 1 then
      bx = player.x
      by = player.y-1
    end

    if love.keyboard.isDown("right") and player.x < mapWidth then
      bx = player.x+1
      by = player.y
    end

    if love.keyboard.isDown("down") and player.y < mapHeight then
      bx = player.x
      by = player.y+1
    end

    if love.keyboard.isDown("left") and player.x > 1 then
      bx = player.x-1
      by = player.y
    end

    if bx > 0 and by > 0 then
      local square = map[bx][by]
      if square.object and square.object.onBreak then
        table.insert(square.items, square.object.onBreak)
        square.object = nil
      end
    end
  end

  -- Update the player move timer
  player.moveTimer = player.moveTimer + dt

  -- Reset the key pressed/released lists
  love.keyboard.updateKeys()
end



function love.draw()
  local tileDisplaySize = tileSize * tileScale

  for x = 1, visibleTilesWidth do
    for y = 1, visibleTilesHeight do
      local tile = map[x+(cameraX-1)][y+(cameraY-1)]
      --[[
      table.print(tile)
      error()]]
      -- Draw background
      local bg = tile.background
      love.graphics.draw(bg.sheet, bg.quad, (x-1) * tileDisplaySize, (y-1) * tileDisplaySize, 0, tileScale, tileScale)

      -- Draw object
      local ob = tile.object
      if ob then
        love.graphics.draw(ob.sprite.sheet, ob.sprite.quad, (x-1) * tileDisplaySize, (y-1) * tileDisplaySize, 0, tileScale, tileScale)
      end

      -- Draw items
      for i, v in ipairs(tile.items) do
        love.graphics.draw(v.sprite.sheet, v.sprite.quad, (x-1) * tileDisplaySize, (y-1) * tileDisplaySize, 0, tileScale, tileScale)
      end
    end
  end

  -- Draw player
  love.graphics.draw(player.img, player.quad, (player.x-1-(cameraX-1)) * tileDisplaySize, (player.y-1-(cameraY-1)) * tileDisplaySize, 0, tileScale, tileScale)

  if player.breakMode then
    -- Draw break halo
    love.graphics.rectangle("line", (player.x-cameraX) * tileDisplaySize, (player.y-cameraY-1) * tileDisplaySize, tileDisplaySize, tileDisplaySize)
    love.graphics.rectangle("line", (player.x-cameraX+1) * tileDisplaySize, (player.y-cameraY) * tileDisplaySize, tileDisplaySize, tileDisplaySize)
    love.graphics.rectangle("line", (player.x-cameraX) * tileDisplaySize, (player.y-cameraY+1) * tileDisplaySize, tileDisplaySize, tileDisplaySize)
    love.graphics.rectangle("line", (player.x-cameraX-1) * tileDisplaySize, (player.y-cameraY) * tileDisplaySize, tileDisplaySize, tileDisplaySize)
  end

  if player.invOpen then
    -- Draw the inventory
    local invXOff = 200
    local invYOff = 200
    local invSize = 72
    local invPadding = (invSize - tileDisplaySize) / 2

    local invMargin = 12
    for i = 1, 5 do
      local sx = invXOff + (i-1) * (invSize + invMargin)
      local sy = invYOff
      love.graphics.setColor(180, 180, 180, 200)
      love.graphics.rectangle("fill", sx, sy, invSize, invSize)
      love.graphics.setColor(255, 255, 255)
      local slot = player.inventory[i]
      local item = slot.item
      if item then
        love.graphics.draw(item.sprite.sheet, item.sprite.quad, sx+invPadding, sy+invPadding, 0, tileScale, tileScale)
        love.graphics.print(slot.count, sx, sy, 0, 1, 1)
      end
    end
  end

  -- Write debug text
  love.graphics.print("PX: " .. player.x .. " PY: " .. player.y .. " SX: " .. cameraX .. " SY: " .. cameraY, 10, 10)

  local inv = "Inventory: "
  for i,v in ipairs(player.inventory) do
    if v.item then
      inv = inv .. i .. "[" .. v.item.name .. " x " .. v.count .. "] "
    else
      inv = inv .. i .. "[" .. "Empty] "
    end
  end
  love.graphics.print(inv, 10, 40)
end
