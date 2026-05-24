import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() {
  runApp(const BlockPuzzleConnectApp());
}

/// Describes a playable board size.
class BoardConfig {
  const BoardConfig({
    required this.rows,
    required this.columns,
    required this.label,
  });

  final int rows;
  final int columns;
  final String label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoardConfig &&
          rows == other.rows &&
          columns == other.columns &&
          label == other.label;

  @override
  int get hashCode => Object.hash(rows, columns, label);
}

const List<BoardConfig> kBoardConfigs = [
  BoardConfig(rows: 4, columns: 4, label: '4×4'),
  BoardConfig(rows: 4, columns: 5, label: '4×5'),
  BoardConfig(rows: 5, columns: 5, label: '5×5'),
  BoardConfig(rows: 5, columns: 6, label: '5×6'),
  BoardConfig(rows: 6, columns: 6, label: '6×6'),
  BoardConfig(rows: 6, columns: 7, label: '6×7'),
  BoardConfig(rows: 7, columns: 7, label: '7×7'),
  BoardConfig(rows: 7, columns: 8, label: '7×8'),
  BoardConfig(rows: 8, columns: 8, label: '8×8'),
  BoardConfig(rows: 8, columns: 9, label: '8×9'),
  BoardConfig(rows: 9, columns: 9, label: '9×9'),
];

const BoardConfig kDefaultBoardConfig = BoardConfig(
  rows: 8,
  columns: 8,
  label: '8×8',
);

const int kLineClearScore = 10;
const int kTraySize = 3;
const double kBoardGridPadding = 4;
const double kBoardGridSpacing = 2;

/// Cell dimensions derived from the rendered board grid.
class BoardLayoutMetrics {
  const BoardLayoutMetrics({
    required this.cellWidth,
    required this.cellHeight,
    this.crossAxisSpacing = kBoardGridSpacing,
    this.mainAxisSpacing = kBoardGridSpacing,
  });

  final double cellWidth;
  final double cellHeight;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  static ({double boardWidth, double boardHeight}) boardDimensions({
    required BoardConfig config,
    required double maxWidth,
    required double maxHeight,
  }) {
    final maxSide = math.min(maxWidth, maxHeight);
    final aspectRatio = config.columns / config.rows;

    if (aspectRatio >= 1) {
      return (boardWidth: maxSide, boardHeight: maxSide / aspectRatio);
    }
    return (boardWidth: maxSide * aspectRatio, boardHeight: maxSide);
  }

  factory BoardLayoutMetrics.fromBoardSize({
    required BoardConfig config,
    required double boardWidth,
    required double boardHeight,
  }) {
    final innerWidth = boardWidth - kBoardGridPadding * 2;
    final innerHeight = boardHeight - kBoardGridPadding * 2;
    final cellWidth =
        (innerWidth - kBoardGridSpacing * (config.columns - 1)) / config.columns;
    final cellHeight =
        (innerHeight - kBoardGridSpacing * (config.rows - 1)) / config.rows;

    return BoardLayoutMetrics(
      cellWidth: cellWidth,
      cellHeight: cellHeight,
    );
  }

  double pieceWidth(int columnSpan) =>
      columnSpan * cellWidth + math.max(0, columnSpan - 1) * crossAxisSpacing;

  double pieceHeight(int rowSpan) =>
      rowSpan * cellHeight + math.max(0, rowSpan - 1) * mainAxisSpacing;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoardLayoutMetrics &&
          cellWidth == other.cellWidth &&
          cellHeight == other.cellHeight &&
          crossAxisSpacing == other.crossAxisSpacing &&
          mainAxisSpacing == other.mainAxisSpacing;

  @override
  int get hashCode => Object.hash(
        cellWidth,
        cellHeight,
        crossAxisSpacing,
        mainAxisSpacing,
      );
}

Offset _pieceAnchorDragAnchorStrategy(
  Draggable<Object> draggable,
  BuildContext context,
  Offset position,
) {
  return position;
}

/// A cell offset relative to a piece anchor (top-left).
class CellOffset {
  const CellOffset(this.row, this.col);

  final int row;
  final int col;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CellOffset && row == other.row && col == other.col;

  @override
  int get hashCode => Object.hash(row, col);
}

/// A placeable block piece made of one or more cells.
class BlockPiece {
  BlockPiece({
    required this.id,
    required this.cells,
    required this.color,
    required this.shapeId,
  });

  final String id;
  final List<CellOffset> cells;
  final Color color;
  final String shapeId;

  int get minRow {
    var min = cells.first.row;
    for (final cell in cells) {
      min = math.min(min, cell.row);
    }
    return min;
  }

  int get minCol {
    var min = cells.first.col;
    for (final cell in cells) {
      min = math.min(min, cell.col);
    }
    return min;
  }

  int get maxRow {
    var max = cells.first.row;
    for (final cell in cells) {
      max = math.max(max, cell.row);
    }
    return max;
  }

  int get maxCol {
    var max = cells.first.col;
    for (final cell in cells) {
      max = math.max(max, cell.col);
    }
    return max;
  }

  int get width => maxCol - minCol + 1;

  int get height => maxRow - minRow + 1;
}

/// Drag payload linking a tray piece to its slot index.
class TrayPieceDragData {
  const TrayPieceDragData({
    required this.piece,
    required this.trayIndex,
  });

  final BlockPiece piece;
  final int trayIndex;
}

/// Starting shape definitions for piece generation.
class ShapeDefinition {
  const ShapeDefinition(this.id, this.cells);

  final String id;
  final List<CellOffset> cells;
}

const List<ShapeDefinition> kShapeCatalog = [
  ShapeDefinition('single', [CellOffset(0, 0)]),
  ShapeDefinition('h2', [CellOffset(0, 0), CellOffset(0, 1)]),
  ShapeDefinition('v2', [CellOffset(0, 0), CellOffset(1, 0)]),
  ShapeDefinition('h3', [CellOffset(0, 0), CellOffset(0, 1), CellOffset(0, 2)]),
  ShapeDefinition('v3', [CellOffset(0, 0), CellOffset(1, 0), CellOffset(2, 0)]),
  ShapeDefinition('square2', [
    CellOffset(0, 0),
    CellOffset(0, 1),
    CellOffset(1, 0),
    CellOffset(1, 1),
  ]),
  ShapeDefinition('l', [
    CellOffset(0, 0),
    CellOffset(1, 0),
    CellOffset(1, 1),
  ]),
  ShapeDefinition('reverse_l', [
    CellOffset(0, 1),
    CellOffset(1, 0),
    CellOffset(1, 1),
  ]),
  ShapeDefinition('diag_nw_se_2', [CellOffset(0, 0), CellOffset(1, 1)]),
  ShapeDefinition('diag_ne_sw_2', [CellOffset(0, 1), CellOffset(1, 0)]),
  ShapeDefinition('diag_nw_se_3', [
    CellOffset(0, 0),
    CellOffset(1, 1),
    CellOffset(2, 2),
  ]),
  ShapeDefinition('diag_ne_sw_3', [
    CellOffset(0, 2),
    CellOffset(1, 1),
    CellOffset(2, 0),
  ]),
];

const List<Color> kPieceColors = [
  Color(0xFFE57373),
  Color(0xFF64B5F6),
  Color(0xFF81C784),
  Color(0xFFFFB74D),
  Color(0xFFBA68C8),
  Color(0xFF4DD0E1),
  Color(0xFFA1887F),
  Color(0xFF9575CD),
];

class BlockPuzzleConnectApp extends StatelessWidget {
  const BlockPuzzleConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Block Puzzle Connect',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const GamePage(),
    );
  }
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final math.Random _random = math.Random();

  BoardConfig _boardConfig = kDefaultBoardConfig;
  int _score = 0;
  late List<List<Color?>> _occupied;
  late List<BlockPiece?> _activePieces;
  int? _selectedPieceIndex;
  int _pieceCounter = 0;
  BoardLayoutMetrics? _boardLayoutMetrics;

  @override
  void initState() {
    super.initState();
    _resetBoardCells();
    _generateTrayPieces(selectFirst: true);
  }

  void _resetBoardCells() {
    _occupied = List.generate(
      _boardConfig.rows,
      (_) => List<Color?>.filled(_boardConfig.columns, null),
    );
  }

  BlockPiece _createPieceFromShape(ShapeDefinition shape, Color color) {
    _pieceCounter += 1;
    return BlockPiece(
      id: 'piece-$_pieceCounter',
      cells: List<CellOffset>.from(shape.cells),
      color: color,
      shapeId: shape.id,
    );
  }

  void _generateTrayPieces({required bool selectFirst}) {
    _activePieces = List<BlockPiece?>.generate(kTraySize, (index) {
      final shape = kShapeCatalog[_random.nextInt(kShapeCatalog.length)];
      final color = kPieceColors[_random.nextInt(kPieceColors.length)];
      return _createPieceFromShape(shape, color);
    });

    if (selectFirst) {
      _selectedPieceIndex = 0;
    } else {
      _selectedPieceIndex = _firstAvailablePieceIndex();
    }
  }

  int? _firstAvailablePieceIndex() {
    for (var i = 0; i < _activePieces.length; i++) {
      if (_activePieces[i] != null) {
        return i;
      }
    }
    return null;
  }

  void _resetGame({required bool selectFirst}) {
    _score = 0;
    _resetBoardCells();
    _generateTrayPieces(selectFirst: selectFirst);
  }

  void _onBoardConfigChanged(BoardConfig config) {
    if (config == _boardConfig) {
      return;
    }
    setState(() {
      _boardConfig = config;
      _resetGame(selectFirst: true);
    });
  }

  void _onRestart() {
    setState(() => _resetGame(selectFirst: true));
  }

  void _onBoardLayoutMetricsChanged(BoardLayoutMetrics metrics) {
    if (_boardLayoutMetrics == metrics) {
      return;
    }
    setState(() => _boardLayoutMetrics = metrics);
  }

  void _onPieceSelected(int index) {
    if (_activePieces[index] == null) {
      return;
    }
    setState(() => _selectedPieceIndex = index);
  }

  int? _indexForPieceId(String pieceId) {
    for (var i = 0; i < _activePieces.length; i++) {
      if (_activePieces[i]?.id == pieceId) {
        return i;
      }
    }
    return null;
  }

  void _showDoesNotFitMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('That piece does not fit there.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _tryPlacePiece({
    required BlockPiece piece,
    required int anchorRow,
    required int anchorCol,
    int? trayIndex,
  }) {
    final slotIndex = trayIndex ?? _indexForPieceId(piece.id);
    if (slotIndex == null || _activePieces[slotIndex]?.id != piece.id) {
      return;
    }

    if (!_canPlacePiece(piece, anchorRow, anchorCol)) {
      _showDoesNotFitMessage();
      return;
    }

    setState(() {
      _placePiece(piece, anchorRow, anchorCol);
      _activePieces[slotIndex] = null;

      final clearedLines = _clearCompletedLines();
      _score += clearedLines * kLineClearScore;

      _selectedPieceIndex = _firstAvailablePieceIndex();
      _refillTrayIfNeeded();
    });
  }

  bool _canPlacePiece(BlockPiece piece, int anchorRow, int anchorCol) {
    for (final offset in piece.cells) {
      final row = anchorRow + offset.row;
      final col = anchorCol + offset.col;
      if (row < 0 ||
          row >= _boardConfig.rows ||
          col < 0 ||
          col >= _boardConfig.columns) {
        return false;
      }
      if (_occupied[row][col] != null) {
        return false;
      }
    }
    return true;
  }

  void _placePiece(BlockPiece piece, int anchorRow, int anchorCol) {
    for (final offset in piece.cells) {
      final row = anchorRow + offset.row;
      final col = anchorCol + offset.col;
      _occupied[row][col] = piece.color;
    }
    _score += piece.cells.length;
  }

  bool _isRowComplete(int row) {
    for (var col = 0; col < _boardConfig.columns; col++) {
      if (_occupied[row][col] == null) {
        return false;
      }
    }
    return true;
  }

  bool _isColumnComplete(int col) {
    for (var row = 0; row < _boardConfig.rows; row++) {
      if (_occupied[row][col] == null) {
        return false;
      }
    }
    return true;
  }

  List<List<CellOffset>> _fullLengthDiagonals({required bool nwToSe}) {
    final rows = _boardConfig.rows;
    final cols = _boardConfig.columns;
    final minDim = math.min(rows, cols);
    if (minDim < 4) {
      return const [];
    }

    final diagonals = <List<CellOffset>>[];

    if (nwToSe) {
      for (var startCol = 0; startCol < cols; startCol++) {
        final cells = <CellOffset>[];
        var row = 0;
        var col = startCol;
        while (row < rows && col < cols) {
          cells.add(CellOffset(row, col));
          row++;
          col++;
        }
        if (cells.length == minDim) {
          diagonals.add(cells);
        }
      }

      for (var startRow = 1; startRow < rows; startRow++) {
        final cells = <CellOffset>[];
        var row = startRow;
        var col = 0;
        while (row < rows && col < cols) {
          cells.add(CellOffset(row, col));
          row++;
          col++;
        }
        if (cells.length == minDim) {
          diagonals.add(cells);
        }
      }
    } else {
      for (var startCol = 0; startCol < cols; startCol++) {
        final cells = <CellOffset>[];
        var row = 0;
        var col = startCol;
        while (row < rows && col >= 0) {
          cells.add(CellOffset(row, col));
          row++;
          col--;
        }
        if (cells.length == minDim) {
          diagonals.add(cells);
        }
      }

      for (var startRow = 1; startRow < rows; startRow++) {
        final cells = <CellOffset>[];
        var row = startRow;
        var col = cols - 1;
        while (row < rows && col >= 0) {
          cells.add(CellOffset(row, col));
          row++;
          col--;
        }
        if (cells.length == minDim) {
          diagonals.add(cells);
        }
      }
    }

    return diagonals;
  }

  bool _isDiagonalComplete(List<CellOffset> diagonal) {
    for (final cell in diagonal) {
      if (_occupied[cell.row][cell.col] == null) {
        return false;
      }
    }
    return true;
  }

  int _clearCompletedLines() {
    final cellsToClear = <String>{};
    var clearedLineCount = 0;

    for (var row = 0; row < _boardConfig.rows; row++) {
      if (_isRowComplete(row)) {
        clearedLineCount++;
        for (var col = 0; col < _boardConfig.columns; col++) {
          cellsToClear.add('$row,$col');
        }
      }
    }

    for (var col = 0; col < _boardConfig.columns; col++) {
      if (_isColumnComplete(col)) {
        clearedLineCount++;
        for (var row = 0; row < _boardConfig.rows; row++) {
          cellsToClear.add('$row,$col');
        }
      }
    }

    for (final diagonal in _fullLengthDiagonals(nwToSe: true)) {
      if (_isDiagonalComplete(diagonal)) {
        clearedLineCount++;
        for (final cell in diagonal) {
          cellsToClear.add('${cell.row},${cell.col}');
        }
      }
    }

    for (final diagonal in _fullLengthDiagonals(nwToSe: false)) {
      if (_isDiagonalComplete(diagonal)) {
        clearedLineCount++;
        for (final cell in diagonal) {
          cellsToClear.add('${cell.row},${cell.col}');
        }
      }
    }

    for (final key in cellsToClear) {
      final parts = key.split(',');
      final row = int.parse(parts[0]);
      final col = int.parse(parts[1]);
      _occupied[row][col] = null;
    }

    return clearedLineCount;
  }

  void _refillTrayIfNeeded() {
    final allPlaced = _activePieces.every((piece) => piece == null);
    if (!allPlaced) {
      return;
    }
    _generateTrayPieces(selectFirst: true);
  }

  void _onBoardCellTapped(int row, int col) {
    final selectedIndex = _selectedPieceIndex;
    if (selectedIndex == null) {
      return;
    }

    final piece = _activePieces[selectedIndex];
    if (piece == null) {
      return;
    }

    _tryPlacePiece(
      piece: piece,
      anchorRow: row,
      anchorCol: col,
      trayIndex: selectedIndex,
    );
  }

  void _onPieceDropped(TrayPieceDragData data, int row, int col) {
    _tryPlacePiece(
      piece: data.piece,
      anchorRow: row,
      anchorCol: col,
      trayIndex: data.trayIndex,
    );
  }

  BlockPiece? get _selectedPiece {
    final index = _selectedPieceIndex;
    if (index == null) {
      return null;
    }
    return _activePieces[index];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Block Puzzle Connect'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Score: $_score',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Board',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: kBoardConfigs.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final config = kBoardConfigs[index];
                    final selected = config == _boardConfig;
                    return ChoiceChip(
                      label: Text(config.label),
                      selected: selected,
                      onSelected: (_) => _onBoardConfigChanged(config),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: _BoardView(
                    config: _boardConfig,
                    occupied: _occupied,
                    selectedPiece: _selectedPiece,
                    onCellTapped: _onBoardCellTapped,
                    onPieceDropped: _onPieceDropped,
                    onLayoutMetricsChanged: _onBoardLayoutMetricsChanged,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pieces',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(kTraySize, (index) {
                  final piece = _activePieces[index];
                  final selected = _selectedPieceIndex == index;
                  return _PieceTraySlot(
                    piece: piece,
                    trayIndex: index,
                    selected: selected,
                    emptyColor: colorScheme.surfaceContainerHighest,
                    boardLayoutMetrics: _boardLayoutMetrics,
                    onTap: piece == null ? null : () => _onPieceSelected(index),
                    onDragStarted: piece == null
                        ? null
                        : () => _onPieceSelected(index),
                  );
                }),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _onRestart,
                icon: const Icon(Icons.refresh),
                label: const Text('Restart'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoardView extends StatelessWidget {
  const _BoardView({
    required this.config,
    required this.occupied,
    required this.selectedPiece,
    required this.onCellTapped,
    required this.onPieceDropped,
    required this.onLayoutMetricsChanged,
  });

  final BoardConfig config;
  final List<List<Color?>> occupied;
  final BlockPiece? selectedPiece;
  final void Function(int row, int col) onCellTapped;
  final void Function(TrayPieceDragData data, int row, int col) onPieceDropped;
  final ValueChanged<BoardLayoutMetrics> onLayoutMetricsChanged;

  bool _wouldPlacementFit(int anchorRow, int anchorCol) {
    final piece = selectedPiece;
    if (piece == null) {
      return false;
    }

    for (final offset in piece.cells) {
      final row = anchorRow + offset.row;
      final col = anchorCol + offset.col;
      if (row < 0 ||
          row >= config.rows ||
          col < 0 ||
          col >= config.columns) {
        return false;
      }
      if (occupied[row][col] != null) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final dimensions = BoardLayoutMetrics.boardDimensions(
          config: config,
          maxWidth: constraints.maxWidth,
          maxHeight: constraints.maxHeight,
        );
        final boardWidth = dimensions.boardWidth;
        final boardHeight = dimensions.boardHeight;
        final layoutMetrics = BoardLayoutMetrics.fromBoardSize(
          config: config,
          boardWidth: boardWidth,
          boardHeight: boardHeight,
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          onLayoutMetricsChanged(layoutMetrics);
        });

        return SizedBox(
          width: boardWidth,
          height: boardHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.outline),
            ),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(kBoardGridPadding),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: config.columns,
                mainAxisSpacing: kBoardGridSpacing,
                crossAxisSpacing: kBoardGridSpacing,
              ),
              itemCount: config.rows * config.columns,
              itemBuilder: (context, index) {
                final row = index ~/ config.columns;
                final col = index % config.columns;
                final cellColor = occupied[row][col];
                final isOccupied = cellColor != null;
                final canPreview = selectedPiece != null &&
                    _wouldPlacementFit(row, col);

                return DragTarget<TrayPieceDragData>(
                  onWillAcceptWithDetails: (_) => true,
                  onAcceptWithDetails: (details) {
                    onPieceDropped(details.data, row, col);
                  },
                  builder: (context, candidateData, rejectedData) {
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: selectedPiece == null
                            ? null
                            : () => onCellTapped(row, col),
                        borderRadius: BorderRadius.circular(2),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: isOccupied
                                ? cellColor
                                : canPreview
                                    ? colorScheme.primary.withValues(alpha: 0.12)
                                    : colorScheme.surface,
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(
                              color: canPreview
                                  ? colorScheme.primary
                                  : colorScheme.outlineVariant,
                              width: canPreview ? 1.5 : 1,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _PieceTraySlot extends StatelessWidget {
  const _PieceTraySlot({
    required this.piece,
    required this.trayIndex,
    required this.selected,
    required this.emptyColor,
    required this.boardLayoutMetrics,
    required this.onTap,
    required this.onDragStarted,
  });

  final BlockPiece? piece;
  final int trayIndex;
  final bool selected;
  final Color emptyColor;
  final BoardLayoutMetrics? boardLayoutMetrics;
  final VoidCallback? onTap;
  final VoidCallback? onDragStarted;

  Widget _slotContainer(
    BuildContext context, {
    Widget? child,
    double opacity = 1,
    bool emptyAppearance = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final showEmpty = emptyAppearance || piece == null;

    return Opacity(
      opacity: opacity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 72,
        height: 72,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: showEmpty ? emptyColor.withValues(alpha: 0.45) : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? colorScheme.primary : colorScheme.outline,
            width: selected ? 3 : 1,
          ),
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final piece = this.piece;
    if (piece == null) {
      return _slotContainer(context);
    }

    final dragData = TrayPieceDragData(piece: piece, trayIndex: trayIndex);
    final metrics = boardLayoutMetrics;

    return Draggable<TrayPieceDragData>(
      data: dragData,
      onDragStarted: onDragStarted,
      dragAnchorStrategy: metrics == null
          ? childDragAnchorStrategy
          : _pieceAnchorDragAnchorStrategy,
      feedback: Material(
        elevation: 4,
        color: Colors.transparent,
        shadowColor: Colors.black26,
        child: metrics == null
            ? SizedBox(
                width: 72,
                height: 72,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: _PiecePreview(piece: piece),
                ),
              )
            : _PiecePreview(
                piece: piece,
                layoutMetrics: metrics,
              ),
      ),
      childWhenDragging: _slotContainer(
        context,
        opacity: 0.35,
        emptyAppearance: true,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: _slotContainer(
            context,
            child: _PiecePreview(piece: piece),
          ),
        ),
      ),
    );
  }
}

class _PiecePreview extends StatelessWidget {
  const _PiecePreview({
    required this.piece,
    this.layoutMetrics,
  });

  final BlockPiece piece;
  final BoardLayoutMetrics? layoutMetrics;

  @override
  Widget build(BuildContext context) {
    if (layoutMetrics != null) {
      return _buildBoardScaledPreview(layoutMetrics!);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize = math.min(
          constraints.maxWidth / piece.width,
          constraints.maxHeight / piece.height,
        );

        return _buildCellStack(
          cellWidth: cellSize,
          cellHeight: cellSize,
          crossAxisSpacing: 0,
          mainAxisSpacing: 0,
        );
      },
    );
  }

  Widget _buildBoardScaledPreview(BoardLayoutMetrics metrics) {
    return _buildCellStack(
      cellWidth: metrics.cellWidth,
      cellHeight: metrics.cellHeight,
      crossAxisSpacing: metrics.crossAxisSpacing,
      mainAxisSpacing: metrics.mainAxisSpacing,
    );
  }

  Widget _buildCellStack({
    required double cellWidth,
    required double cellHeight,
    required double crossAxisSpacing,
    required double mainAxisSpacing,
  }) {
    final width = piece.width * cellWidth +
        math.max(0, piece.width - 1) * crossAxisSpacing;
    final height = piece.height * cellHeight +
        math.max(0, piece.height - 1) * mainAxisSpacing;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final cell in piece.cells)
            Positioned(
              left: (cell.col - piece.minCol) * (cellWidth + crossAxisSpacing),
              top: (cell.row - piece.minRow) * (cellHeight + mainAxisSpacing),
              width: cellWidth,
              height: cellHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: piece.color,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
