// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:the_salon_app/features/ai_salon/presentation/pages/ai_smart_mirror_workspace.dart';
import 'package:the_salon_app/features/premium/data/premium_access_controller.dart';
import 'package:the_salon_app/features/premium/domain/premium_models.dart';
import 'package:the_salon_app/main.dart';

void main() {
  final verticalScroll = find.byWidgetPredicate(
    (widget) =>
        widget is Scrollable && widget.axisDirection == AxisDirection.down,
  );

  testWidgets('app starts on the explore screen', (tester) async {
    await tester.pumpWidget(const TheSalonApp());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Explore'), findsWidgets);
  });

  testWidgets('AR Mirror shows direct edit controls without prompt bar', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AiSmartMirrorWorkspace(enableThreeDViewer: false),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Edit overlay'),
      300,
      scrollable: verticalScroll,
    );

    expect(find.text('Ask or adjust your try-on'), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Edit overlay'), findsOneWidget);
    expect(find.text('Size'), findsNothing);

    await tester.tap(find.text('Edit overlay'));
    await tester.pump();

    expect(find.text('Size'), findsOneWidget);
    expect(find.text('Rotate'), findsOneWidget);
    expect(find.text('Opacity'), findsOneWidget);
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
  });

  testWidgets('AR Mirror switches to tattoo category', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AiSmartMirrorWorkspace()));

    await tester.scrollUntilVisible(
      find.text('Tattoo'),
      300,
      scrollable: verticalScroll,
    );
    await tester.tap(find.text('Tattoo'));
    await tester.pump();

    expect(find.text('Minimal rose'), findsOneWidget);
    expect(find.text('Fine-line butterfly'), findsOneWidget);
  });

  testWidgets('AR Mirror filters hairstyle models by look group', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AiSmartMirrorWorkspace()));

    await tester.scrollUntilVisible(
      find.text('Men'),
      300,
      scrollable: verticalScroll,
    );

    expect(find.text('Textured black'), findsOneWidget);
    expect(find.text('Long butterfly'), findsNothing);

    await tester.tap(find.text('Women'));
    await tester.pumpAndSettle();

    expect(find.text('Long butterfly'), findsOneWidget);
    expect(find.text('Textured black'), findsNothing);
  });

  testWidgets('AR Mirror shows premium AI try-on mode', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AiSmartMirrorWorkspace(enableThreeDViewer: false),
      ),
    );

    await tester.tap(find.text('AI Premium'));
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Choose AI style'),
      300,
      scrollable: verticalScroll,
    );

    expect(find.text('Choose AI style'), findsOneWidget);
    expect(find.text('AI Hair'), findsWidgets);
    expect(find.text('AI Beard'), findsWidgets);
    expect(find.text('AI Nails'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('AI style prompt'),
      300,
      scrollable: verticalScroll,
    );
    expect(find.text('AI style prompt'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'brown hair');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(find.textContaining('Prompt color noted'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Premium AI Try-On'),
      300,
      scrollable: verticalScroll,
    );
    expect(find.text('Premium AI Try-On'), findsOneWidget);
  });

  testWidgets('premium preview opens plans and development payment', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AiSmartMirrorWorkspace(enableThreeDViewer: false),
      ),
    );

    await tester.tap(find.text('AI Premium'));
    await tester.pumpAndSettle();

    expect(find.text('Premium studio previews'), findsOneWidget);
    await tester.tap(find.byTooltip('Hide premium banner'));
    await tester.pump();
    expect(find.text('Premium studio previews'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Textured crop motion'),
      300,
      scrollable: verticalScroll,
    );
    await tester.drag(verticalScroll, const Offset(0, -260));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Textured crop motion'));
    await tester.pumpAndSettle();

    expect(find.text('Unlock premium preview'), findsOneWidget);
    await tester.tap(find.text('Unlock premium'));
    await tester.pumpAndSettle();

    expect(find.text('Salon Premium'), findsOneWidget);
    expect(find.text('AI Hair Studio'), findsOneWidget);
    await tester.tap(find.byKey(const Key('premium-features-info')));
    await tester.pump();
    expect(
      find.textContaining('AI Hair Studio creates realistic'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Continue to payment'),
      300,
      scrollable: verticalScroll,
    );
    await tester.tap(find.text('Continue to payment'));
    await tester.pumpAndSettle();

    expect(find.text('Payment'), findsOneWidget);
    expect(find.text('Google Play Billing'), findsOneWidget);
    expect(find.text('UPI'), findsOneWidget);
    expect(find.text('Credit / Debit Card'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Complete development payment'),
      300,
      scrollable: verticalScroll,
    );
    expect(find.text('Wallet'), findsOneWidget);

    await tester.tap(find.text('Complete development payment'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Premium unlocked'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(
      PremiumAccessController.instance.isUnlocked(PremiumFeature.aiHair),
      isTrue,
    );
  });
}
