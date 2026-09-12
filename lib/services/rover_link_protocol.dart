import 'dart:convert';

/// Wire protocol between the phone and the STM32 over the HC-05 link.
///
/// ASSUMPTION (no firmware spec was provided): newline-delimited JSON, one
/// object per line. This is the easiest format to parse on both a Flutter
/// phone and in STM32 C firmware (a tiny JSON encoder is enough — you don't
/// need a full parser on the MCU side, just fixed-key sprintf output).
/// If your firmware already speaks a different format (raw bytes, CSV,
/// a binary struct), only this file and [RoverConnection] need to change —
/// nothing else in the app depends on the wire format directly.
///
/// Telemetry (STM32 -> phone), one line per tick:
/// {"t":"telemetry","tgt_d":4.72,"tgt_b":27,"us_cm":84,"servo":74,
///  "motor":48,"safety":"clear"}
///
/// Commands (phone -> STM32):
/// {"cmd":"set_mode","mode":"follow_me"}
/// {"cmd":"drive","dir":"forward","speed":62}
/// {"cmd":"estop"}          // must be handled instantly & locally on the MCU
/// {"cmd":"resume"}
class RoverPacket {
  const RoverPacket(this.type, this.fields);

  final String type;
  final Map<String, dynamic> fields;

  static RoverPacket? tryParse(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return null;
    try {
      final decoded = jsonDecode(trimmed) as Map<String, dynamic>;
      final type = (decoded['t'] ?? decoded['cmd'] ?? 'unknown').toString();
      return RoverPacket(type, decoded);
    } catch (_) {
      // Malformed / partial line (common with serial streams that split
      // mid-packet) — caller should just drop it and wait for the next one.
      return null;
    }
  }

  static String encodeCommand(String cmd, [Map<String, dynamic> extra = const {}]) {
    return '${jsonEncode({'cmd': cmd, ...extra})}\n';
  }
}
