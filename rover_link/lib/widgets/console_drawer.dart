import 'package:flutter/material.dart';
import '../state/rover_state.dart';

const _amber = Color(0xFFFFB400);
const _termBg = Color(0xFF080B06);
const _termPanel = Color(0xFF0D1309);
const _termLine = Color(0xFF233016);
const _termMuted = Color(0xFF5C6B4C);
const _grn = Color(0xFF7CFF6B);

class ConsoleDrawer extends StatefulWidget {
  final RoverState state;
  final bool open;
  final VoidCallback onToggle;
  const ConsoleDrawer(
      {super.key, required this.state, required this.open, required this.onToggle});

  @override
  State<ConsoleDrawer> createState() => _ConsoleDrawerState();
}

class _ConsoleDrawerState extends State<ConsoleDrawer> {
  final _inputCtrl = TextEditingController();

  void _send() {
    widget.state.sendCustom(_inputCtrl.text.trim());
    _inputCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      height: widget.open ? 300 : 38,
      decoration:
          const BoxDecoration(color: _termBg, border: Border(top: BorderSide(color: _termLine))),
      child: Column(children: [
        InkWell(
          onTap: widget.onToggle,
          child: SizedBox(
            height: 38,
            child: Row(children: [
              const SizedBox(width: 14),
              Icon(widget.open ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                  color: _amber, size: 16),
              const SizedBox(width: 6),
              const Text('SERIAL CONSOLE',
                  style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: _amber,
                      fontFamily: 'monospace')),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.consolePreview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10.5, color: _termMuted, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(width: 14),
            ]),
          ),
        ),
        if (widget.open)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Column(children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color: _termPanel,
                        border: Border.all(color: _termLine),
                        borderRadius: BorderRadius.circular(4)),
                    padding: const EdgeInsets.all(8),
                    child: s.terminalLog.isEmpty
                        ? const Text('Idle. Tap Connect to pair with HC-05.',
                            style: TextStyle(color: _termMuted, fontFamily: 'monospace', fontSize: 11))
                        : ListView.builder(
                            itemCount: s.terminalLog.length,
                            itemBuilder: (context, i) {
                              final e = s.terminalLog[i];
                              final isRx = e.text.startsWith('RX');
                              final isTx = e.text.startsWith('TX');
                              final color = isRx ? _grn : isTx ? _amber : _termMuted;
                              return Text(e.text,
                                  style: TextStyle(fontSize: 11, color: color, fontFamily: 'monospace'));
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      style: const TextStyle(color: _amber, fontFamily: 'monospace', fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'AT+STATE or raw command…',
                        hintStyle: const TextStyle(color: _termMuted, fontSize: 12),
                        filled: true,
                        fillColor: _termPanel,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(3),
                            borderSide: const BorderSide(color: _termLine)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    onPressed: _send,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _amber, foregroundColor: const Color(0xFF231800)),
                    child: const Text('SEND', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ]),
              ]),
            ),
          ),
      ]),
    );
  }
}
