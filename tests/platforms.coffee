define ['platforms', 'test/fakes'], (Platforms, fakes) ->

  describe 'Platforms', ->
    game = null
    platforms = null

    beforeEach ->
      spyOn Platforms::, '_initialize'
      platforms = new Platforms {}
      _.extend platforms, fakes.createPlatformsProps(platforms)
      fakes.configurePlatformsWithDefaults platforms
      return

    describe 'when constructed', ->
      it 'should have set ledge constraints', ->
        expect(platforms.minLedgeSize).toBeDefined()
        expect(platforms.maxLedgeSize).toBeDefined()
        expect(platforms.minLedgeSpacing).toBeDefined()
        expect(platforms.maxLedgeSpacing).toBeDefined()
        return

      it 'should have configured sizes', ->
        expect(platforms.tileWidth).toBeDefined()
        expect(platforms.tileHeight).toBeDefined()
        return

      it 'should have empty ledges array', ->
        expect(platforms.ledges).toEqual []
        return
      return

    describe '#_createTileGeneratorState', ->
      state = null

      beforeEach ->
        state = platforms._createTileGeneratorState()
        return

      it 'returns expected number of columns and rows', ->
        expect(state.numCols).toBe 13
        expect(state.numRows).toBe 98
        return

      it 'returns expected ledge size and row spacing ranges', ->
        expect(state.rangeLedgeSize).toBe 2
        expect(state.rangeRowSpacing).toBe 2
        return

      it 'returns expected base number of ledges', ->
        expect(state.numLedgeRows).toBe 25
        return
      return

    describe '#_addLedgeDifficulty', ->
      ledge = null
      vars = { numLedgeRows: 23 }

      beforeEach ->
        ledge = new Platforms.Ledge()
        ledge.index = 1
        ledge.rowIndex = 4
        ledge.size = 4
        ledge.spacing = 3
        ledge.start = 0
        ledge.end = 3
        ledge.facing = 'left'
        return

      it 'makes initial ledges longer and closer together', ->
        platforms._addLedgeDifficulty ledge, vars

        expect(ledge.spacing).toBe 2
        expect(ledge.size).toBe 5
        expect(ledge.end).toBe 4
        return

      it 'makes final ledges shorter and farther apart', ->
        ledge.index = vars.numLedgeRows - 1
        platforms._addLedgeDifficulty ledge, vars

        expect(ledge.spacing).toBe 3
        expect(ledge.size).toBe 4
        expect(ledge.end).toBe 3
        return

      it 'correctly updates start and end values for ledges facing right', ->
        ledge.facing = 'right'
        ledge.start = 8
        ledge.end = 12
        platforms._addLedgeDifficulty ledge, vars

        expect(ledge.start).toBe 8
        return

    describe '#_addRow', ->
      vars = null

      beforeEach ->
        vars =
          iColStart: 0
          iColEnd: 3
          numCols: 13
          numLedgeRows: 23
          rowTiles: []
          rowType: 'empty'
        return

      it 'generates and adds a row of tiles', ->
        prevLength = platforms.tiles.length
        platforms._addRow vars

        expect(vars.rowTiles.length).toBeGreaterThan 0
        expect(platforms.tiles[0]).toEqual vars.rowTiles
        return

      it 'adds the same row of tiles if called again', ->
        platforms._addRow vars
        prevRowTiles = vars.rowTiles
        platforms._addRow vars

        expect(vars.rowTiles).toBe prevRowTiles
        expect(platforms.tiles[1]).toEqual platforms.tiles[0]
        return

      it 'adds a ledge if provided correct row type', ->
        vars.rowType = 'ledge'
        platforms._addRow vars

        expect(platforms.ledges[0] instanceof Platforms.Ledge).toBe yes
        return

      it 'sets row tiles so only those within start and end indexes are solid'
      , ->
        vars.rowType = 'ledge'
        platforms._addRow vars

        expect platforms.tiles[0][..vars.iColEnd]
          .not.toContain Platforms.Tile.Empty
        expect platforms.tiles[0][vars.iColEnd + 1...]
          .not.toContain Platforms.Tile.Solid
        return
      return

    describe '#_setupEmptyRow', ->
      vars = null

      beforeEach ->
        vars = {}
        platforms._setupEmptyRow vars
        return

      it 'resets column indexes for upcoming row', ->
        expect(vars.iColStart).toBe 0
        expect(vars.iColEnd).toBe 0
        return

      it 'resets row type for upcoming row', ->
        expect(vars.rowType).toBe 'empty'
        return
      return

    describe '#_setupLedgeRow', ->
      vars = null

      beforeEach ->
        vars =
          facing: 'left'
          iLedgeRow: 0
          numCols: 13
          rangeLedgeSize: 2
          rangeRowSpacing: 2
        return

      it 'resets column indexes for upcoming ledge facing left,
      with variance', ->
        platforms._setupLedgeRow vars

        expect(vars.iColStart).toBe 0
        expect(vars.iColEnd >= platforms.minLedgeSize - 1).toBe yes
        return

      it 'resets column indexes for upcoming ledge facing right,
      with variance', ->
        vars.facing = 'right'
        platforms._setupLedgeRow vars

        expect(vars.iColStart <= 13 - platforms.minLedgeSize).toBe yes
        expect(vars.iColEnd).toBe 12
        return

      it 'resets row data for upcoming row, with variance', ->
        platforms._setupLedgeRow vars

        expect(vars.rowSize >= platforms.minLedgeSize).toBe yes
        expect(vars.rowSpacing >= platforms.minLedgeSpacing.y).toBe yes
        expect(vars.rowType).toBe 'ledge'
        return

      it 'updates other related state', ->
        platforms._setupLedgeRow vars

        expect(vars.iLedgeRow).toBe 1
        expect(vars.prevFacing).toBe 'left'
        return

    describe '#_setupEachRow', ->
      vars = null

      beforeEach ->
        vars = { iLedgeLayer: 0 }
        return

      it 'resets row tiles for upcoming row only on first ledge layer', ->
        platforms._setupEachRow vars
        expect(vars.rowTiles).toEqual []

        vars.iLedgeLayer++
        vars.rowTiles.push Platforms.Tile.Solid for c in [0...13]
        platforms._setupEachRow vars
        expect(vars.rowTiles).not.toEqual []
        return

    describe '#_generateTiles', ->
      it 'calls #_addRow for each row', ->
        spyOn(platforms, '_addRow').and.callThrough()
        platforms._generateTiles()

        expect(platforms._addRow.calls.count()).toBe platforms.tiles.length
        return

      it 'calls #_setupEachRow for the each row', ->
        spyOn(platforms, '_setupEachRow').and.callThrough()
        platforms._generateTiles()

        expect platforms._setupEachRow.calls.count()
          .toBe platforms.tiles.length
        return

      it 'calls #_setupLedgeRow for each ledge and #_setupEmptyRow for the
      rest', ->
        spyOn(platforms, '_setupLedgeRow').and.callThrough()
        spyOn(platforms, '_setupEmptyRow').and.callThrough()
        platforms._generateTiles()

        # FIXME: Not sure why rounding is needed.
        expect platforms._setupLedgeRow.calls.count()
          .toBe Math.round(platforms.ledges.length / platforms.ledgeThickness)
        expect platforms._setupEmptyRow.calls.count()
          .toBe platforms.tiles.length - platforms.ledges.length
        return
      return
    return
  return
