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
  BoardConfig _boardConfig = kDefaultBoardConfig;
  int _score = 0;

  void _onBoardConfigChanged(BoardConfig config) {
    setState(() => _boardConfig = config);
  }

  void _onRestart() {
    setState(() => _score = 0);
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
                  child: _BoardPreview(config: _boardConfig),
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
                children: List.generate(
                  3,
                  (index) => _PiecePlaceholder(color: colorScheme.primaryContainer),
                ),
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

class _BoardPreview extends StatelessWidget {
  const _BoardPreview({required this.config});

  final BoardConfig config;

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
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(
                      color: colorScheme.outlineVariant,
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

class _PiecePlaceholder extends StatelessWidget {
  const _PiecePlaceholder({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: Icon(
        Icons.extension_outlined,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }
}
