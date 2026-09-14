import 'package:flutter/material.dart';
import '../state/rover_state.dart';
import '../services/bt_service.dart';

const _cyan = Color(0xFF57D6FF);
const _line = Color(0xFF16324A);
const _muted = Color(0xFF5F8296);
const _bg = Color(0xFF050B13);
const _crit = Color(0xFFFF4D4D);

class ConnectSheet extends StatelessWidget {
  final RoverState state;
  const ConnectSheet({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: _content(context),
      ),
    );
  }

  Widget _content(BuildContext context) {
    if (state.connected) return _manage(context);
    switch (state.linkState) {
      case BtLinkState.scanning:
        return _scanning();
      case BtLinkState.connecting:
        return _connecting();
      default:
        if (state.lastConnectError != null) return _failed(context);
        if (state.discoveredDevices.isNotEmpty) return _results(context);
        return _idle(context);
    }
  }

  Widget _title(String t) => Text(t,
      style: const TextStyle(
          fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 13, color: Colors.white));

  Widget _idle(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _title('CONNECT TO ROVER'),
          const SizedBox(height: 10),
          const Text("No active scan. Nearby devices aren't visible until you scan.",
              style: TextStyle(color: _muted, fontFamily: 'monospace', fontSize: 11),
              textAlign: TextAlign.center),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () => state.startScan(),
            style: ElevatedButton.styleFrom(backgroundColor: _cyan, foregroundColor: const Color(0xFF001824)),
            child: const Text('Scan for devices', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ],
      );

  Widget _scanning() => Column(mainAxisSize: MainAxisSize.min, children: [
        _title('CONNECT TO ROVER'),
        const SizedBox(height: 16),
        const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: _cyan)),
          SizedBox(width: 10),
          Text('Scanning for nearby devices…',
              style: TextStyle(color: _muted, fontFamily: 'monospace', fontSize: 11)),
        ]),
        const SizedBox(height: 10),
      ]);

  Widget _results(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _title('NEARBY DEVICES'),
          const SizedBox(height: 8),
          ...state.discoveredDevices.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _deviceRow(d),
              )),
          OutlinedButton(onPressed: () => state.startScan(), child: const Text('Scan again')),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ],
      );

  Widget _deviceRow(BtDevice d) => Opacity(
        opacity: d.connectable ? 1 : 0.4,
        child: Material(
          color: _bg,
          borderRadius: BorderRadius.circular(5),
          child: InkWell(
            borderRadius: BorderRadius.circular(5),
            onTap: d.connectable ? () => state.connectTo(d) : null,
            child: Container(
              decoration: BoxDecoration(border: Border.all(color: _line), borderRadius: BorderRadius.circular(5)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(d.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.white)),
                    Text(d.connectable ? d.address : '${d.address} · not a rover link',
                        style: const TextStyle(fontSize: 10, color: _muted, fontFamily: 'monospace')),
                  ]),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _connecting() => const Column(mainAxisSize: MainAxisSize.min, children: [
        Text('CONNECT TO ROVER',
            style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 13, color: Colors.white)),
        SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: _cyan)),
          SizedBox(width: 10),
          Text('Connecting…', style: TextStyle(color: _muted, fontFamily: 'monospace', fontSize: 11)),
        ]),
      ]);

  Widget _failed(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _title('CONNECTION FAILED'),
          const SizedBox(height: 8),
          Text(state.lastConnectError ?? 'Connection failed.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontFamily: 'monospace', fontSize: 11)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              final d = state.connectedDevice;
              if (d != null) state.connectTo(d);
            },
            style: ElevatedButton.styleFrom(backgroundColor: _cyan, foregroundColor: const Color(0xFF001824)),
            child: const Text('Retry'),
          ),
          TextButton(onPressed: () => state.startScan(), child: const Text('Back to devices')),
        ],
      );

  Widget _manage(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _title('CONNECTED'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(border: Border.all(color: _line), borderRadius: BorderRadius.circular(5)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(state.connectedDevice?.name ?? 'HC-05 · Rover',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.white)),
              Text('${state.connectedDevice?.address ?? ''} · 9600 baud',
                  style: const TextStyle(fontSize: 10, color: _muted, fontFamily: 'monospace')),
            ]),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () {
              state.disconnectRover();
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(foregroundColor: _crit, side: const BorderSide(color: Color(0xFF5C1C1C))),
            child: const Text('Disconnect'),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      );
}
