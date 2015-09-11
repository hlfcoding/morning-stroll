define [
  'phaser'
  'underscore'
], (Phaser, _) ->

  RegExps =
    PrettyHashRemove: /[{}"]/g
    PrettyHashPad: /[:,]/g

  DebugMixin =

    _initDebugMixin: (gui) ->
      @debugging = on
      @tracing = off
      @debugTextItems = {}

      return no unless gui?

      @gui = gui
      @gui.add(@, 'debugging').onFinishChange => @debugTextItems = {}
      @gui.add @, 'tracing'

      yes

    debug: (label, value, details) ->
      return unless @debugging

      value = parseFloat value.toFixed(2) if _.isNumber(value)
      value = @_prettyHash @_prettyPoint(value) if value instanceof Phaser.Point

      if details?.position and details.position instanceof Phaser.Point
        details.position = @_prettyPoint details.position

      if @tracing
        label = "#{@debugNamespace}:#{label}"
        if details? then console.trace label, value, details
        else console.trace label, value
      else
        if _.isArray(value) and _.isArray(value[0])
          label = "#{@debugNamespace}:#{label}"
          console.trace label
          console.table? value
        else
          details = if details? then @_prettyHash(details) else ''
          @debugTextItems[label] = "#{label}: #{value} #{details}".trim()

    _prettyPoint: (point) ->
      _.chain point
        .pick 'x', 'y'
        .mapObject (n) -> parseFloat n.toFixed(2)
        .value()

    _prettyHash: (hash) ->
      JSON.stringify hash
        .replace RegExps.PrettyHashRemove,''
        .replace RegExps.PrettyHashPad, '$& '

  # Same behavior as Flixel, but a different, more straightforward implementation.
  autoSetTiles = (tiles) ->
    result = (_.clone row for row in tiles)

    for row, r in result
      for col, c in row when col is 1

        left = right = top = bottom = 1
        left    = tiles[r][c - 1] unless c is 0
        right   = tiles[r][c + 1] unless c is row.length - 1
        top     = tiles[r - 1][c] unless r is 0
        bottom  = tiles[r + 1][c] unless r is tiles.length - 1

        switch [top, right, bottom, left].join() # Tainted by CSS.
          when '0,0,0,0' then tile = 1 # all empty
          when '1,0,0,0' then tile = 2 # bottom tip
          when '0,1,0,0' then tile = 3 # left tip
          when '1,1,0,0' then tile = 4 # bottom-left corner
          when '0,0,1,0' then tile = 5 # top tip
          when '1,0,1,0' then tile = 6 # vertical segment
          when '0,1,1,0' then tile = 7 # top-left corner
          when '1,1,1,0' then tile = 8 # left edge
          when '0,0,0,1' then tile = 9 # right tip
          when '1,0,0,1' then tile = 10 # bottom-right corner
          when '0,1,0,1' then tile = 11 # horizontal segment
          when '1,1,0,1' then tile = 12 # bottom edge
          when '0,0,1,1' then tile = 13 # top-right corner
          when '1,0,1,1' then tile = 14 # right edge
          when '0,1,1,1' then tile = 15 # top edge
          when '1,1,1,1' then tile = 16 # body

        row[c] = tile

    result

  { DebugMixin, RegExps, autoSetTiles }
