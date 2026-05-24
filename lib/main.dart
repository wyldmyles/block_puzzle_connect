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

  int get width {
    var maxCol = 0;
    for (final cell in cells) {
      maxCol = math.max(maxCol, cell.col);
    }
    return maxCol + 1;
  }

  int get height {
    var maxRow = 0;
    for (final cell in cells) {
      maxRow = math.max(maxRow, cell.row);
    }
    return maxRow + 1;
  }
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

  void _onPieceSelected(int index) {
    if (_activePieces[index] == null) {
      return;
    }
    setState(() => _selectedPieceIndex = index);
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

    if (!_canPlacePiece(piece, row, col)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('That piece does not fit there.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _placePiece(piece, row, col);
      _activePieces[selectedIndex] = null;

      final clearedLines = _clearCompletedLines();
      _score += clearedLines * kLineClearScore;

      _selectedPieceIndex = _firstAvailablePieceIndex();
      _refillTrayIfNeeded();
    });
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
                    selected: selected,
                    emptyColor: colorScheme.surfaceContainerHighest,
                    onTap: piece == null ? null : () => _onPieceSelected(index),
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
  });

  final BoardConfig config;
  final List<List<Color?>> occupied;
  final BlockPiece? selectedPiece;
  final void Function(int row, int col) onCellTapped;

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
        final maxSide = math.min(constraints.maxWidth, constraints.maxHeight);
        final aspectRatio = config.columns / config.rows;
        late double boardWidth;
        late double boardHeight;

        if (aspectRatio >= 1) {
          boardWidth = maxSide;
          boardHeight = maxSide / aspectRatio;
        } else {
          boardHeight = maxSide;
          boardWidth = maxSide * aspectRatio;
        }

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
              padding: const EdgeInsets.all(4),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: config.columns,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              itemCount: config.rows * config.columns,
              itemBuilder: (context, index) {
                final row = index ~/ config.columns;
                final col = index % config.columns;
                final cellColor = occupied[row][col];
                final isOccupied = cellColor != null;
                final canPreview = selectedPiece != null &&
                    _wouldPlacementFit(row, col);

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
    required this.selected,
    required this.emptyColor,
    required this.onTap,
  });

  final BlockPiece? piece;
  final bool selected;
  final Color emptyColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 72,
          height: 72,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: piece == null ? emptyColor.withValues(alpha: 0.45) : null,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.outline,
              width: selected ? 3 : 1,
            ),
          ),
          child: piece == null
              ? null
              : _PiecePreview(piece: piece!),
        ),
      ),
    );
  }
}

class _PiecePreview extends StatelessWidget {
  const _PiecePreview({required this.piece});

  final BlockPiece piece;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize = math.min(
          constraints.maxWidth / piece.width,
          constraints.maxHeight / piece.height,
        );

        return SizedBox(
          width: cellSize * piece.width,
          height: cellSize * piece.height,
          child: Stack(
            children: [
              for (final cell in piece.cells)
                Positioned(
                  left: cell.col * cellSize,
                  top: cell.row * cellSize,
                  width: cellSize,
                  height: cellSize,
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
      },
    );
  }
}
