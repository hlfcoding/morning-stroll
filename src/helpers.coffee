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
        details = if details? then @_prettyHash(details) else ''
        @debugTextItems[label] = "#{label}: #{value} #{details}"

    _prettyPoint: (point) ->
      _.chain point
        .pick 'x', 'y'
        .mapObject (n) -> parseFloat n.toFixed(2)
        .value()

    _prettyHash: (hash) ->
      JSON.stringify hash
        .replace RegExps.PrettyHashRemove,''
        .replace RegExps.PrettyHashPad, '$& '

  { DebugMixin, RegExps }
