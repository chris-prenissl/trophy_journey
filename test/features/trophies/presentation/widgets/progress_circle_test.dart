import 'package:trophy_journey/features/trophies/presentation/widgets/progress_circle.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpCircle(
  WidgetTester tester, {
  required int achieved,
  required int total,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: ProgressCircle(achieved: achieved, total: total),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the achieved over total ratio', (tester) async {
    await pumpCircle(tester, achieved: 3, total: 4);

    expect(find.text('3 / 4'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
  });

  testWidgets('animates the indicator to the final value', (tester) async {
    await pumpCircle(tester, achieved: 1, total: 4);

    final indicator = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    expect(indicator.value, closeTo(0.25, 0.0001));
  });

  testWidgets('handles an empty trophy list without dividing by zero', (
    tester,
  ) async {
    await pumpCircle(tester, achieved: 0, total: 0);

    expect(find.text('0 / 0'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
  });

  testWidgets('reports full completion', (tester) async {
    await pumpCircle(tester, achieved: 4, total: 4);

    expect(find.text('100%'), findsOneWidget);
  });
}
