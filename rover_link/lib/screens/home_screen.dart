import 'package:flutter/material.dart';
import '../constants.dart';
import '../state/rover_state.dart';
import '../widgets/controls.dart';
import '../widgets/follow_me_panel.dart';
import '../widgets/console_drawer.dart';
import '../widgets/connect_sheet.dart';

class HomeScreen extends StatefulWidget {
  final RoverState state;
  const HomeScreen({super.key, required this.state});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _drawerOpen = false;

  void _openConnectSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A1420),
      isScrollControlled: true,
      builder: (_) => ConnectSheet(state: widget.state),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _AppBar(state: s, onTapConnection: _openConnectSheet),
            SafetyStrip(state: s),
            ModeSwitch(state: s),
            QuickMacros(state: s),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: s.mode == DriveMode.manual
                    ? ManualDrivePanel(state: s)
                    : FollowMePanel(state: s),
              ),
            ),
            ConsoleDrawer(
              state: s,
              open: _drawerOpen,
              onToggle: () => setState(() => _drawerOpen = !_drawerOpen),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  final RoverState state;
  final VoidCallback onTapConnection;
  const _AppBar({required this.state, required this.onTapConnection});

  @override
  Widget build(BuildContext context) {
    final connected = state.connected;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Rover Link',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              const Text('HC-05 · UART 9600 · STM32F401',
                  style: TextStyle(fontSize: 11, color: Color(0xFF5F8296))),
              if (useDemoBluetooth)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFFFB100)),
                      borderRadius: BorderRadius.circular(3)),
                  child: const Text('DEMO DATA — no BLE link',
                      style: TextStyle(
                          fontSize: 9, color: Color(0xFFFFB100), fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          GestureDetector(
            onTap: onTapConnection,
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: connected ? const Color(0xFF5EE08A) : const Color(0xFF5F8296)),
                ),
                const SizedBox(width: 6),
                Text(connected ? 'HC-05 LINKED' : 'CONNECT',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
