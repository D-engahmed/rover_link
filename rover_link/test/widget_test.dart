import 'package:flutter_test/flutter_test.dart';

import 'package:rover_link/main.dart';
import 'package:rover_link/services/bt_service.dart';
import 'package:rover_link/state/rover_state.dart';

void main() {
  testWidgets('Rover Link renders its main control surface', (tester) async {
    final state = RoverState(DemoBtService());
    addTearDown(state.dispose);

    await tester.pumpWidget(RoverLinkApp(state: state));

    expect(find.text('Rover Link'), findsOneWidget);
    expect(find.text('MANUAL DRIVE'), findsWidgets);
    expect(find.text('FOLLOW ME'), findsOneWidget);
    expect(find.text('NEAREST OBSTACLE'), findsOneWidget);
  });
}
