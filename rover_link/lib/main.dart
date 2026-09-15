import 'package:flutter/material.dart';
import 'constants.dart';
import 'services/bt_service.dart';
import 'services/real_bt_service.dart';
import 'services/vision_service.dart';
import 'state/rover_state.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final BtService bt = useDemoBluetooth ? DemoBtService() : RealBtService();
  final state = RoverState(bt);
  final vision = VisionService();
  state.attachVision(vision);

  runApp(RoverLinkApp(state: state));
}

class RoverLinkApp extends StatelessWidget {
  final RoverState state;
  const RoverLinkApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rover Link',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050B13),
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF57D6FF),
          brightness: Brightness.dark,
        ),
        sliderTheme: const SliderThemeData(trackHeight: 3),
      ),
      home: AnimatedBuilder(
        animation: state,
        builder: (context, _) => HomeScreen(state: state),
      ),
    );
  }
}
