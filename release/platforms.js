define(['phaser', 'underscore', 'app/defines', 'app/helpers'], function(Phaser, _, defines, Helpers) {
  'use strict';
  var DebugMixin, Ledge, Platforms, Point, Tile, autoSetTiles;
  Point = Phaser.Point;
  autoSetTiles = Helpers.autoSetTiles, DebugMixin = Helpers.DebugMixin;
  Tile = {
    Empty: 0,
    Solid: 1,
    Meta: 2
  };
  Platforms = (function() {
    function Platforms(config, game, gui) {
      this.config = config;
      this.minLedgeSize = 3;
      this.maxLedgeSize = 5;
      this.minLedgeSpacing = new Point(4, 2);
      this.maxLedgeSpacing = new Point(8, 4);
      this.ledgeThickness = 2;
      this.tileWidth = this.tileHeight = 32;
      this.ledges = [];
      this.tiles = [];
      this._initialize(game, gui);
    }

    Platforms.prototype._initialize = function(game, gui) {
      this.game = game;
      this._initDebugging(gui);
      return this.makeMap(game);
    };

    Platforms.prototype._initDebugging = function(gui) {
      var completedInit;
      this.debugNamespace = 'platforms';
      this.debugging = defines.debugging;
      completedInit = this._initDebugMixin(gui);
      if (!completedInit) {

      }
    };

    Platforms.prototype.destroy = function() {};

    Platforms.prototype.makeMap = function(game) {
      var row, rowCSV, tilesCSV;
      if (!this.tiles.length) {
        this._generateTiles();
      }
      tilesCSV = ((function() {
        var i, len, ref, results;
        ref = this.tiles;
        results = [];
        for (i = 0, len = ref.length; i < len; i++) {
          row = ref[i];
          results.push(rowCSV = row.join(','));
        }
        return results;
      }).call(this)).join("\n");
      game.load.tilemap('platforms', null, tilesCSV);
      this.tilemap = game.add.tilemap('platforms', this.tileWidth, this.tileHeight);
      this.tilemap.addTilesetImage(this.config.tileImageKey);
      this.tilemap.setCollisionBetween(1, 16);
      this.layer = this.tilemap.createLayer(0);
      return this.layer.resizeWorld();
    };

    Platforms.prototype._createTileGeneratorState = function() {
      var mapSize, numRowsLedge, vars;
      mapSize = this.game.world.getBounds();
      vars = {
        facing: 'right',
        prevFacing: null,
        iCol: -1,
        iColStart: -1,
        iColEnd: -1,
        iRow: -1,
        iRowStart: -1,
        iRowEnd: 0,
        iLedgeRow: -1,
        iLedgeLayer: -1,
        numCols: Math.floor(mapSize.width / this.tileWidth),
        numRows: Math.floor(this.config.mapH / this.tileHeight),
        numRowsClearance: this.minLedgeSpacing.y + this.ledgeThickness,
        numLedgeRows: -1,
        rangeLedgeSize: this.maxLedgeSize - this.minLedgeSize,
        rangeRowSpacing: this.maxLedgeSpacing.y - this.minLedgeSpacing.y,
        rowSize: -1,
        rowSpacing: -1,
        rowTiles: null,
        rowType: null
      };
      numRowsLedge = (this.maxLedgeSpacing.y + this.minLedgeSpacing.y) / 2 + (this.ledgeThickness - 1);
      vars.numLedgeRows = Math.round(vars.numRows / numRowsLedge);
      return vars;
    };

    Platforms.prototype._generateTiles = function() {
      var vars;
      vars = this._createTileGeneratorState();
      this.tiles = [];
      vars.iLedgeLayer = 0;
      vars.iLedgeRow = 0;
      vars.rowSpacing = this.minLedgeSpacing.y;
      vars.iRow = vars.iRowStart = vars.numRows - 1;
      while (!(vars.iRow < vars.iRowEnd)) {
        this._setupEachRow(vars);
        if ((vars.iRow - vars.numRowsClearance) <= vars.iRowEnd) {
          this._setupEmptyRow(vars);
          if (vars.iLedgeLayer > 0) {
            vars.iLedgeLayer--;
            _.last(this.ledges).rowIndex = vars.iRowStart - vars.iRow;
          } else {
            vars.rowTiles = [];
          }
        } else {
          if (vars.rowSpacing === 0) {
            this._setupLedgeRow(vars);
            vars.iLedgeLayer = this.ledgeThickness - 1;
          } else if (vars.iLedgeLayer > 0) {
            vars.iLedgeLayer--;
          } else {
            this._setupEmptyRow(vars);
            vars.rowSpacing--;
            vars.iLedgeLayer = 0;
          }
        }
        this._addRow(vars);
        vars.iRow--;
      }
      this.tiles.reverse();
      this.tiles = autoSetTiles(this.tiles);
      return this.debug('tiles', this.tiles);
    };

    Platforms.prototype._addLedgeDifficulty = function(ledge, vars) {
      var easiness;
      easiness = Math.pow(vars.numLedgeRows / ledge.index, 0.3);
      ledge.spacing = Math.round(ledge.spacing / easiness);
      ledge.size = Math.round(ledge.size * easiness);
      ledge.spacing = Phaser.Math.clamp(ledge.spacing, this.minLedgeSpacing.y, this.maxLedgeSpacing.y);
      ledge.size = Phaser.Math.clamp(ledge.size, this.minLedgeSize, this.maxLedgeSize);
      switch (ledge.facing) {
        case 'left':
          return ledge.end = ledge.size - 1;
        case 'right':
          return ledge.start = ledge.end + 1 - ledge.size;
      }
    };

    Platforms.prototype._addRow = function(vars) {
      var i, index, ledge, ref;
      if (vars.rowType === 'ledge') {
        ledge = new Ledge();
        ledge.index = vars.iLedgeRow;
        ledge.rowIndex = vars.iRowStart - vars.iRow;
        ledge.size = vars.rowSize;
        ledge.spacing = vars.rowSpacing;
        ledge.start = vars.iColStart;
        ledge.end = vars.iColEnd;
        ledge.facing = vars.prevFacing;
        this._addLedgeDifficulty(ledge, vars);
        this.ledges.push(ledge);
        vars.iColStart = ledge.start;
        vars.iColEnd = ledge.end;
      }
      if (!vars.rowTiles.length) {
        for (index = i = 0, ref = vars.numCols; 0 <= ref ? i < ref : i > ref; index = 0 <= ref ? ++i : --i) {
          if (((0 <= index && index < vars.iColStart)) || ((vars.iColEnd < index && index < vars.numCols)) || (vars.iColStart === vars.iColEnd)) {
            vars.rowTiles.push(Tile.Empty);
          }
          if (((vars.iColStart <= index && index <= vars.iColEnd)) && (vars.iColStart !== vars.iColEnd)) {
            vars.rowTiles.push(Tile.Solid);
          }
        }
      }
      return this.tiles.push(vars.rowTiles);
    };

    Platforms.prototype._setupEmptyRow = function(vars) {
      vars.iColStart = 0;
      vars.iColEnd = 0;
      return vars.rowType = 'empty';
    };

    Platforms.prototype._setupLedgeRow = function(vars) {
      vars.iLedgeRow++;
      vars.rowSize = this.minLedgeSize + parseInt(Math.random() * vars.rangeLedgeSize);
      vars.rowSpacing = this.minLedgeSpacing.y + parseInt(Math.random() * vars.rangeRowSpacing);
      vars.rowType = 'ledge';
      vars.prevFacing = vars.facing;
      switch (vars.facing) {
        case 'left':
          vars.iColStart = 0;
          vars.iColEnd = vars.rowSize - 1;
          return vars.facing = 'right';
        case 'right':
          vars.iColStart = vars.numCols - vars.rowSize;
          vars.iColEnd = vars.numCols - 1;
          return vars.facing = 'left';
      }
    };

    Platforms.prototype._setupEachRow = function(vars) {
      if (vars.iLedgeLayer === 0) {
        return vars.rowTiles = [];
      }
    };

    return Platforms;

  })();
  Ledge = (function() {
    function Ledge() {
      this.index = -1;
      this.rowIndex = -1;
      this.size = -1;
      this.spacing = -1;
      this.start = -1;
      this.end = -1;
      this.facing = 'left';
    }

    Ledge.prototype.createMidpoint = function(platforms) {
      var point;
      point = new Point();
      point.x = (this.size / 2) * platforms.tileWidth;
      if (this.facing === 'right') {
        point.x = platforms.tilemap.widthInPixels - point.x;
      }
      point.y = ((platforms.tiles.length - 1) - this.rowIndex) * platforms.tileHeight;
      return point;
    };

    return Ledge;

  })();
  _.extend(Platforms.prototype, DebugMixin);
  return _.extend(Platforms, {
    Ledge: Ledge,
    Tile: Tile
  });
});

//# sourceMappingURL=platforms.js.map
