enum TermKind { rx, tx, sys }

enum AiKind { line, steer }

enum LinkPhase { idle, scanning, results, connecting, failed }

enum SafetyState { ok, caution, crit }

class TermEntry {
  TermEntry(this.time, this.kind, this.text);
  final String time;
  final TermKind kind;
  final String text;
}

class AiEntry {
  AiEntry(this.time, this.kind, this.text);
  final String time;
  final AiKind kind;
  final String text;
}

class NearbyDevice {
  const NearbyDevice(this.id, this.name, this.mac, this.connectable);
  final String id, name, mac;
  final bool connectable;
}
