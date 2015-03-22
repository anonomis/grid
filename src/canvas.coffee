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
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  ctx.fillStyle = "rgb(1,1,255)"
  ctx.fillRect 0, 0, canvas.width, canvas.height
  ctx.fillStyle = "rgb(255,1,255)"
  ctx.fillRect canvas.width/4, canvas.height/4, canvas.width/2, canvas.height/2
  last_time = time
  function_end = +new Date
  ctx.fillStyle = 'white';
  ctx.fillText function_end - function_start + ' ms', 10, 10

  window.grid.draw ctx

  return

animate tick

(onresize = (e) ->
  canvas.width = window.innerWidth
  canvas.height = window.innerHeight
  return
)()

console.log "FUCK YEAH!"


class Sq
  constructor: (@x, @y) ->

  # getColor: -> return "rgba"

class Grid
  constructor: (@size) ->
    @sqs = []
    for x in [0..@size]
      for y in [0..@size]
        @sqs[x] = [] unless @sqs[x]
        @sqs[x][y] = new Sq(x,y)

  draw: (ctx, viewport) ->
    ctx.strokeStyle = 'black'
    ctx.lineWidth = "10"
    zoom = 10
    for sq in @sqs
      ctx.beginPath()
      ctx.rect(sq.x*zoom,sq.y*zoom,zoom,zoom)
      ctx.stroke()


window.grid = new Grid(100)