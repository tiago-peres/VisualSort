sorts = {
  bubble: """
for x in [0...VA.length]
  for y in [x + 1...VA.length]
    if VA.gt(x, y)
      VA.swap(x, y)
  """
  select: """
for x in [0...VA.length - 1]
  minIndex = x
  for y in [x + 1...VA.length]
    if VA.lt(y, minIndex)
      minIndex = y
  VA.swap(minIndex, x)
  """
  insert: """
for x in [1...VA.length]
  y = 0
  while VA.gt(x, y)
    y++
    if y == x
      break
  VA.insert(x, y)
  """
  quick: """
bubblesort = (left, right) ->
  #left, right are inclusive
  for x in [left..right]
    for y in [x + 1..right]
      if VA.gt(x, y)
        VA.swap(x, y)

quicksort = (left, right) ->
  if right <= left
    return
  #left, right are inclusive
  #pivot is the left-most value
  if right - left < 5
    bubblesort(left, right)
    return
  pivot = left
  leftMove = left + 1
  rightMove = right
  while leftMove < rightMove
    if VA.lt(leftMove, pivot)
      leftMove++
    else if VA.gt(rightMove, pivot)
      rightMove--
    else
      VA.swap(rightMove, leftMove)
  #now, leftMove == rightMove
  if VA.gt(leftMove, pivot)
    leftMove -= 2
  else
    rightMove++
    leftMove--
  VA.swap(leftMove + 1, pivot)
  quicksort(left, leftMove)
  quicksort(rightMove, right)

quicksort(0, VA.length - 1)
  """
  clear: ""
}

sleep = (ms) ->
  start = new Date()
  while((new Date()) - start < ms)
    0

class VisualArray
  constructor: (@canvas) ->
    @ctx = canvas.getContext('2d')
    @height = 200
    @pxWidth = 800
    @maxLength = @pxWidth / 2
    @stepLength = 50
    @animationQueue = []
    @working = false
    @quickHighlight = true
    @quickCompare = true
    @colors = {
      normal: "rgb(0,0,0)"
      swap: "rgb(255, 0, 0)"
      highlight: "rgb(0,255,0)"
      compare: "rgb(255,255,0)"
      insert: "rgb(0,0,255)"
      slide: "rgb(127,127,255)"
    }

  setLength: (length) =>
    if @working
      return
    @length = Math.max 2, Math.min @maxLength, length
    @values =  ( value * @height / @length for value in [1..@length] )
    @barWidth = 1
    while @pxWidth / @barWidth / 2 > @length
      @barWidth++

  drawIndex: (index) =>
    @ctx.fillRect(2 * index * @barWidth, @height - @animationValues[index], @barWidth, @animationValues[index])

  redraw: =>
    @ctx.clearRect(0, 0, @pxWidth, @height)
    @ctx.fillStyle = @colors.normal
    for index in [0...@length]
      @drawIndex(index)

  shuffle: =>
    order = ( Math.random() for x in [0...@length] )
    for x in [0...@length]
      for y in [x + 1...@length]
        if order[x] > order[y]
          tmp = order[x]
          order[x] = order[y]
          order[y] = tmp
          tmp = @values[x]
          @values[x] = @values[y]
          @values[y] = tmp

  sort: =>
    for x in [0...@length]
      for y in [x + 1...@length]
        if @values[x] > @values[y]
          tmp = @values[x]
          @values[x] = @values[y]
          @values[y] = tmp

  reverse: =>
    for x in [0...@length / 2]
      tmp = @values[x]
      @values[x] = @values[@length - x - 1]
      @values[@length - x - 1] = tmp

  swap: (i, j) =>
    if i == j
      return
    @animationQueue.push(type: "swap", i: i, j: j)
    tmp = @values[i]
    @values[i] = @values[j]
    @values[j] = tmp
    @swaps++

  insert: (i, j) =>
    if i == j
      return
    @animationQueue.push(type: "insert", i: i, j: j)
    tmp = @values[i]
    k = i
    if i < j
      while k < j
        @values[k] = @values[k + 1]
        k++
    else
      while k > j
        @values[k] = @values[k - 1]
        k--
    @values[j] = tmp
    @inserts++
    @shifts += Math.abs(j - i)
  
  lt: (i, j) =>
    @compares++
    @animationQueue.push(type: "compare", i: i, j: j)
    @values[i] < @values[j]

  gt: (i, j) =>
    @compares++
    @animationQueue.push(type: "compare", i: i, j: j)
    @values[i] > @values[j]

  lte: (i, j) =>
    @compares++
    @animationQueue.push(type: "compare", i: i, j: j)
    @values[i] <= @values[j]

  gte: (i, j) =>
    @compares++
    @animationQueue.push(type: "compare", i: i, j: j)
    @values[i] >= @values[j]

  highlight: (indices) =>
    if !$.isArray indices
      indices = [indices]
    @animationQueue.push(type: "highlight", indices: indices)
  
  saveInitialState: =>
    @animationValues = @values.slice()
    @swaps = 0
    @inserts = 0
    @shifts = 0
    @compares = 0

  starting: =>
    @working = true

  get: (index) =>
    @values[index]

  play: =>
    if @stepLength > 0
      @playStep()
    else
      @working = false
      @animationQueue = []
      @animationValues = @values.slice()
      @redraw()
  
  playStep: =>
    step = @animationQueue.shift()
    if !step?
      @working = false
      @redraw()
      return
    else if step.type == "swap"
      @redraw()
      @ctx.fillStyle = @colors.swap
      @drawIndex(step.i)
      @drawIndex(step.j)
      setTimeout =>
        tmp = @animationValues[step.i]
        @animationValues[step.i] = @animationValues[step.j]
        @animationValues[step.j] = tmp
        @redraw()
        @ctx.fillStyle = @colors.swap
        @drawIndex(step.i)
        @drawIndex(step.j)
        setTimeout @play, @stepLength
      , @stepLength
    else if step.type == "highlight"
      @redraw()
      @ctx.fillStyle = @colors.highlight
      for index in step.indices
        @drawIndex(index)
      setTimeout @play, if @quickHighlight then @stepLength / 10 else @stepLength
    else if step.type == "compare"
      @redraw()
      @ctx.fillStyle = @colors.compare
      @drawIndex(step.i)
      @drawIndex(step.j)
      setTimeout @play, if @quickCompare then @stepLength / 10 else @stepLength
    else if step.type == "insert"
      if step.i < step.j
        slideRange = [step.i..step.j]
      else
        slideRange = [step.j..step.i]
      @redraw()
      @ctx.fillStyle = @colors.slide
      for x in slideRange
        @drawIndex(x)
      @ctx.fillStyle = @colors.insert
      @drawIndex(step.i)
      setTimeout =>
        tmp = @animationValues[step.i]
        k = step.i
        if step.i < step.j
          while k < step.j
            @animationValues[k] = @animationValues[k + 1]
            k++
        else
          while k > step.j
            @animationValues[k] = @animationValues[k - 1]
            k--
        @animationValues[step.j] = tmp
        @redraw()
        @ctx.fillStyle = @colors.slide
        for x in slideRange
          @drawIndex(x)
        @ctx.fillStyle = @colors.insert
        @drawIndex(step.j)
        setTimeout @play, @stepLength
      , @stepLength
    else
      setTimeout @play, @stepLength

window.VA = new VisualArray $("#js-canvas")[0]
VA.setLength(100)
VA.shuffle()
VA.saveInitialState()
VA.redraw()

evaluate = (code) ->
  $("#js-error").html("")
  if VA.working
    return
  VA.saveInitialState()
  VA.starting()
  try
    CoffeeScript.eval(code)
  catch error
    $("#js-error").html(error.message + "<br /><br />")
  VA.play()

$("#js-run").click ->
  evaluate $("#js-code").val()
  $("#js-swaps").html(VA.swaps)
  $("#js-inserts").html(VA.inserts)
  $("#js-shifts").html(Math.floor(VA.shifts / VA.inserts))
  $("#js-compares").html(VA.compares)

$("#js-set-values").click ->
  if VA.working
    return
  len = $("#js-length").val()
  if isFinite len
    VA.setLength +len

  state = $("#js-state").val()
  if state == "random"
    VA.shuffle()
  else if state == "sort"
    VA.sort()
  else if state == "reverse"
    VA.sort()
    VA.reverse()

  VA.saveInitialState()
  VA.redraw()

$("#js-set-speed").click ->
  speed = $("#js-speed").val()
  if isFinite speed
    VA.stepLength = +speed
  
  if $("#js-quick-highlight").is(":checked")
    VA.quickHighlight = true
  else
    VA.quickHighlight = false

  if $("#js-quick-compare").is(":checked")
    VA.quickCompare = true
  else
    VA.quickCompare = false

$(".js-show-sort").click (e) ->
  $("#js-code").val(sorts[e.currentTarget.id])
