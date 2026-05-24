import 'package:flutter_test/flutter_test.dart';

import 'package:block_puzzle_connect/main.dart';

void main() {
  testWidgets('Game shell loads with default 8x8 board', (WidgetTester tester) async {
    await tester.pumpWidget(const BlockPuzzleConnectApp());

    expect(find.text('Block Puzzle Connect'), findsOneWidget);
    expect(find.text('Score: 0'), findsOneWidget);
    expect(find.text('8×8'), findsOneWidget);
    expect(find.text('Restart'), findsOneWidget);
  });
}
