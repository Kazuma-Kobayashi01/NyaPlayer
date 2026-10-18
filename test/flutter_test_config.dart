import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// The flowing light and the Hi-Res badge animate for ever, and
/// `pumpAndSettle` waits until nothing is animating. The system's "reduce
/// motion" switch is what makes them stand still, so it is on for every test;
/// tests of the motion itself turn it off again.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
  });
  await testMain();
}
