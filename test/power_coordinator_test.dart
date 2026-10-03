// test/power_coordinator_test.dart
// Regression tests for PowerCoordinator and Flutter Desktop Power Optimization.
// Verifies TickerMode gating, window lifecycle states, idle policies, and background task isolation.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_translate/modules/power_coordinator.dart';

void main() {
  setUp(() {
    PowerCoordinator.resetInstance();
  });

  tearDown(() {
    PowerCoordinator.instance.cancelIdleTimer();
    PowerCoordinator.resetInstance();
  });

  group('PowerCoordinator Core Lifecycle and Logic', () {
    test('Initial state defaults to visible, focused, not minimized, not idle',
        () {
      final power = PowerCoordinator.instance;
      expect(power.isVisible, isTrue);
      expect(power.isFocused, isTrue);
      expect(power.isMinimized, isFalse);
      expect(power.isIdle, isFalse);
      expect(power.isUiActive, isTrue);
      expect(power.isDecorActive, isTrue);
      power.cancelIdleTimer();
    });

    test('isUiActive becomes false when window is blurred (unfocused)', () {
      final power = PowerCoordinator.instance;
      var notifyCount = 0;
      power.addListener(() => notifyCount++);

      power.setWindowFocus(false);
      expect(power.isFocused, isFalse);
      expect(power.isUiActive, isFalse);
      expect(power.isDecorActive, isFalse);
      expect(notifyCount, 1);

      power.setWindowFocus(true);
      expect(power.isFocused, isTrue);
      expect(power.isUiActive, isTrue);
      expect(power.isDecorActive, isTrue);
      expect(notifyCount, 2);

      power.cancelIdleTimer();
    });

    test('isUiActive becomes false when window is minimized', () {
      final power = PowerCoordinator.instance;

      power.setWindowMinimized(true);
      expect(power.isMinimized, isTrue);
      expect(power.isUiActive, isFalse);
      expect(power.isDecorActive, isFalse);

      power.setWindowMinimized(false);
      expect(power.isMinimized, isFalse);
      expect(power.isUiActive, isTrue);
      expect(power.isDecorActive, isTrue);

      power.cancelIdleTimer();
    });

    test('isUiActive becomes false when window is hidden to tray', () {
      final power = PowerCoordinator.instance;

      power.setWindowVisibility(false);
      expect(power.isVisible, isFalse);
      expect(power.isUiActive, isFalse);
      expect(power.isDecorActive, isFalse);

      // Showing window establishes visibility, but does not claim focus alone
      power.setWindowVisibility(true);
      expect(power.isVisible, isTrue);
      expect(power.isUiActive, isTrue);

      power.cancelIdleTimer();
    });

    test('Show without focus keeps isUiActive false', () {
      final power = PowerCoordinator.instance;

      // App is hidden and loses focus
      power.setWindowVisibility(false);
      power.setWindowFocus(false);
      expect(power.isUiActive, isFalse);

      // Restored or shown without gaining focus yet
      power.setWindowVisibility(true);
      expect(power.isVisible, isTrue);
      expect(power.isFocused, isFalse);
      expect(power.isUiActive, isFalse); // Still muted!

      // Window explicitly gains focus
      power.setWindowFocus(true);
      expect(power.isFocused, isTrue);
      expect(power.isUiActive, isTrue); // Now active!

      power.cancelIdleTimer();
    });

    test('Idle timeout policy pauses heavy decoration while keeping UI active',
        () async {
      final power = PowerCoordinator.instance;
      // Configure short timeout for test
      power.idleTimeout = const Duration(milliseconds: 50);

      expect(power.isIdle, isFalse);
      expect(power.isDecorActive, isTrue);

      await Future.delayed(const Duration(milliseconds: 90));

      expect(power.isIdle, isTrue);
      expect(power.isUiActive, isTrue); // UI remains active for instant clicks
      expect(power.isDecorActive, isFalse); // Heavy MeshOrb is paused!

      // User interaction awakens decoration
      power.recordUserActivity();
      expect(power.isIdle, isFalse);
      expect(power.isDecorActive, isTrue);

      power.cancelIdleTimer();
    });

    test('syncNativeState reconciles visibility, focus, and minimized', () {
      final power = PowerCoordinator.instance;

      power.syncNativeState(
          isVisible: false, isFocused: false, isMinimized: true);
      expect(power.isVisible, isFalse);
      expect(power.isFocused, isFalse);
      expect(power.isMinimized, isTrue);
      expect(power.isUiActive, isFalse);

      power.syncNativeState(
          isVisible: true, isFocused: true, isMinimized: false);
      expect(power.isVisible, isTrue);
      expect(power.isFocused, isTrue);
      expect(power.isMinimized, isFalse);
      expect(power.isUiActive, isTrue);

      power.cancelIdleTimer();
    });
  });

  group('Widget TickerMode Gating and Background Isolation', () {
    testWidgets('TickerMode gate mutes standard repeating AnimationController',
        (tester) async {
      final power = PowerCoordinator.instance;
      late AnimationController controller;

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) {
            return AnimatedBuilder(
              animation: power,
              builder: (context, _) {
                return TickerMode(
                  enabled: power.isUiActive,
                  child: child!,
                );
              },
            );
          },
          home: _TestTickerWidget(
            onControllerCreated: (c) => controller = c,
          ),
        ),
      );

      // Active state: controller ticks and advances
      expect(power.isUiActive, isTrue);
      expect(controller.isAnimating, isTrue);
      final initialValue = controller.value;

      await tester.pump(const Duration(milliseconds: 100));
      expect(controller.value, greaterThan(initialValue));
      final activeValue = controller.value;

      // Blur or hide window: TickerMode disabled
      power.setWindowFocus(false);
      await tester.pump();
      expect(power.isUiActive, isFalse);

      // Pumping frames should NOT advance controller value when muted
      await tester.pump(const Duration(milliseconds: 200));
      expect(controller.value, equals(activeValue));

      // Restore focus: TickerMode enabled
      power.setWindowFocus(true);
      await tester.pump();
      expect(power.isUiActive, isTrue);

      await tester.pump(const Duration(milliseconds: 100));
      expect(controller.value, greaterThan(activeValue));

      // Clean up controller and timers before test finish
      controller.stop();
      power.cancelIdleTimer();
    });

    testWidgets(
        'Background business timers continue running uninhibited when UI is muted',
        (tester) async {
      final power = PowerCoordinator.instance;
      int backgroundTicks = 0;
      Timer? backgroundTimer;

      backgroundTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
        backgroundTicks++;
      });

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) {
            return AnimatedBuilder(
              animation: power,
              builder: (context, _) {
                return TickerMode(
                  enabled: power.isUiActive,
                  child: child!,
                );
              },
            );
          },
          home: const Scaffold(body: Text('Background Isolation Test')),
        ),
      );

      // Mute UI by hiding to tray
      power.setWindowVisibility(false);
      await tester.pump();
      expect(power.isUiActive, isFalse);

      // Advance fake async clock by 160ms (should tick 3 times in background)
      await tester.pump(const Duration(milliseconds: 160));

      expect(backgroundTicks, greaterThanOrEqualTo(2));

      // Clean up timer and coordinator
      backgroundTimer.cancel();
      power.cancelIdleTimer();
    });

    testWidgets('User pointer interaction resets idle state via Listener',
        (tester) async {
      final power = PowerCoordinator.instance;
      power.idleTimeout = const Duration(milliseconds: 40);

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) {
            return AnimatedBuilder(
              animation: power,
              builder: (context, _) {
                return Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (_) => power.recordUserActivity(),
                  child: TickerMode(
                    enabled: power.isUiActive,
                    child: child!,
                  ),
                );
              },
            );
          },
          home: const Scaffold(
            body: Center(child: Text('Tap Me')),
          ),
        ),
      );

      // Advance clock past idle timeout
      await tester.pump(const Duration(milliseconds: 70));
      expect(power.isIdle, isTrue);
      expect(power.isDecorActive, isFalse);

      // Tap on the widget
      await tester.tap(find.text('Tap Me'));
      await tester.pump();

      expect(power.isIdle, isFalse);
      expect(power.isDecorActive, isTrue);

      power.cancelIdleTimer();
    });
  });
}

class _TestTickerWidget extends StatefulWidget {
  final ValueChanged<AnimationController> onControllerCreated;

  const _TestTickerWidget({required this.onControllerCreated});

  @override
  State<_TestTickerWidget> createState() => _TestTickerWidgetState();
}

class _TestTickerWidgetState extends State<_TestTickerWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    widget.onControllerCreated(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Text('Progress: ${_controller.value}');
      },
    );
  }
}
