j = require "jquery2"
_ = require "lodash"

Object::make = ((f) ->
  (o) ->
    f.prototype = o
    new f
)(->)

Number::clamp = (min, max) ->
  Math.max min, Math.min(max, this)

canvas = document.getElementById('canvas')

canvas.oncontextmenu = ->
  false

canvas.onclick = (event) ->
  event.stopPropagation()
  event.preventDefault()
  false

mouse =
  x: 0
  y: 0

document.onmousemove = (e) ->
  dx = e.x - mouse.x
  dy = e.y - mouse.y
  mouse.x = e.x
  mouse.y = e.y
  return

canvas.onmousedown = (e) ->
  if e.button == 0
    mouse.forward_button = true
  else if e.button == 2
    mouse.backward_button = true
  e.preventDefault()
  e.stopPropagation()
  false

canvas.onmouseup = (e) ->
  if e.button == 0
    mouse.forward_button = false
  else if e.button == 2
    mouse.backward_button = false
  e.preventDefault()
  e.stopPropagation()
  false

ctx = canvas.getContext('2d')
animate = window.requestAnimationFrame or window.webkitRequestAnimationFrame or window.mozRequestAnimationFrame or (f) ->
  setTimeout f, 1000 / 30
  return
get_image = ((cache) ->
  (url) ->
    if !(url in cache)
      cache[url] = new Image
      cache[url].src = url
    cache[url]
)({})
last_time = 0

tick = (time) ->
  return if window.p?
  function_start = +new Date
  animate tick
  time /= 1000
  dt = time - last_time
  ctx.save()
  # ctx.clearRect(0, 0, canvas.width, canvas.height);
  # ctx.fillStyle = "rgb(1,1,255)"
  # ctx.fillRect 0, 0, canvas.width, canvas.height
  # ctx.fillStyle = "rgb(255,1,255)"
  # ctx.fillRect canvas.width/4, canvas.height/4, canvas.width/2, canvas.height/2
  last_time = time
  function_end = +new Date

  if window.grid.dirty
    console.log "grid dirty"
    window.grid.draw()
  if window.viewPort.dirty
    console.log "viewPort dirty"
    window.viewPort.draw(ctx)

  ctx.fillStyle = 'white';
  ctx.fillText function_end - function_start + ' ms', 10, 10
  return

animate tick

(onresize = (e) ->
  canvas.width = window.innerWidth
  canvas.height = window.innerHeight
  return
)()

console.log "FUCK YEAH!"



class ViewPort
  constructor: (@world, @zoom = 1, @offset) ->
    @dirty = true
    @offsetStart = null
    @offset = new Pos()
    @viewSize = new Pos(canvas.width, canvas.height)
    j('body').on 'mousewheel', (e) =>
      zoomDiff = @zoom/10
      if e.originalEvent.wheelDelta / 120 > 0
        zoomDiff = +zoomDiff
      else
        zoomDiff = -zoomDiff
      @zoom += zoomDiff
      @dirty = true
      console.log "oldViewSize", @viewSize
      newViewSize = new Pos(canvas.width * @zoom, canvas.height * @zoom)
      console.log "newViewSize", newViewSize
      diff = newViewSize.sub(new Pos(@viewSize))
      console.log "diff", diff
      diff = diff.div(new Pos(2))
      @offset = @offset.sub(diff)
      console.log @offset
      @viewSize = newViewSize

      return
    j('canvas').on 'mousedown', (event) =>
      console.log event
      switch event.which
        when 1
          console.log 'Left Mouse button pressed.'
        when 2
          console.log 'Middle Mouse button pressed.'
        when 3
          console.log 'Right Mouse button pressed.'
          @panCenter = new Pos event.pageX, event.pageY
          @offsetStart = @offset.dupe()
        else
          alert 'You have a strange Mouse!', event.which
      return
    j('canvas').on 'mouseup', (event) =>
      console.log event
      switch event.which
        when 1
          console.log 'Left Mouse button released.'
        when 2
          console.log 'Middle Mouse button released.'
        when 3
          console.log 'Right Mouse button released.'
          @panCenter = null
        else
          alert 'You have a strange Mouse!', event.which
      return
    j('canvas').on 'mousemove', (event) =>
      if @panCenter?
        diff = @panCenter.sub new Pos event.pageX, event.pageY
        @offset = @offsetStart.add diff
        console.log @offset
        @dirty = true

  draw: (ctx) ->
    width = Math.ceil(canvas.width*@zoom)
    height = Math.ceil(canvas.height*@zoom)
    canvas2 = document.createElement('canvas');
    canvas2.width = width
    canvas2.height = height

    ctx2 = canvas2.getContext('2d');
    imgData = @world.ctx.getImageData(Math.ceil(@offset.x), Math.ceil(@offset.y),width,height)
    ctx2.putImageData(imgData,0,0)
    #ctx2.scale(@zoom, @zoom)
    ctx.clearRect(0, 0, canvas.width, canvas.height)

    # putImageData
    ctx.drawImage(canvas2,0,0,canvas.width*2,canvas.height*2)
    console.log @zoom

    @dirty = false

cast = (thisArg, func) ->
  return (x) ->
    unless x instanceof Pos
      func.call(thisArg, [new Pos(x,x)])
    else
      func.call(thisArg, [x])

class Pos
  constructor: (@x, @y) ->
    if @x instanceof Pos
      @x = @x.x
      @y = @x.y
    unless @x?
      @x = 0
    unless @y?
      @y = @x
  dupe: ->
    return new Pos(@x, @y)
  diff: (pos) ->
    return new Pos(pos.x - @x, pos.y - @y)
  add: (pos) ->
    return new Pos(@x + pos.x, @y + pos.y)
  sub: (pos) ->
    return new Pos(@x - pos.x, @y - pos.y)
  div: (pos) ->
    return new Pos(@x / pos.x, @y / pos.y)
  mul: (pos) ->
    return new Pos(@x * pos.x, @y * pos.y)

class Sq
  constructor: (@x, @y) ->
    @dirty = true

  draw: (ctx) ->
    @dirty = false


  # getColor: -> return "rgba"

class Grid
  constructor: (@size) ->
    all = []
    byPos = []
    for x in [0..@size]
      for y in [0..@size]
        byPos[x] = [] unless byPos[x]
        sq = new Sq(x,y)
        byPos[x][y] = sq
        all.push(sq)
    @sqs =
      byPos: byPos
      all: all

    @lod = 10

    canvas2 = document.createElement('canvas');
    canvas2.width = @size * @lod + canvas.width;
    canvas2.height = @size * @lod + canvas.height;
    @ctx = canvas2.getContext('2d');

    @ctx.clearRect(0, 0, @lod * @size, @lod * @size);
    @ctx.fillStyle = "rgb(1,1,255)"
    @ctx.fillRect 0, 0, canvas.width, canvas.height
    @dirty = true

  draw: ->
    # zoom = viewPort.zoom
    # offset = viewPort.offset
    offset = new Pos()
    for sq in @sqs.all
      unless @dirty
        continue unless sq.dirty
      @ctx.beginPath()
      @ctx.strokeStyle = "rgb(255,1,255)"
      @ctx.lineWidth = "1"
      @ctx.rect(sq.x*@lod+offset.x,sq.y*@lod+offset.y,@lod,@lod)
      sq.dirty = false
      @ctx.stroke()
    @dirty = false

window.grid = new Grid(10)
window.viewPort = new ViewPort(window.grid)