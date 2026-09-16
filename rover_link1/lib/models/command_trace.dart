enum CommandSource { human, ai, safety, system }
enum CommandStage { proposed, approved, blocked, queued, sent, failed }

class CommandTrace {
  final DateTime timestamp;
  final CommandSource source;
  final CommandStage stage;
  final String action;
  final String wireCommand;
  final String? reason;
  final int? latencyMs;

  const CommandTrace({
    required this.timestamp,
    required this.source,
    required this.stage,
    required this.action,
    required this.wireCommand,
    this.reason,
    this.latencyMs,
  });

  String get sourceLabel => switch (source) {
        CommandSource.human => 'HUMAN',
        CommandSource.ai => 'AI',
        CommandSource.safety => 'SAFETY',
        CommandSource.system => 'SYSTEM',
      };

  String get stageLabel => switch (stage) {
        CommandStage.proposed => 'PROPOSED',
        CommandStage.approved => 'APPROVED',
        CommandStage.blocked => 'BLOCKED',
        CommandStage.queued => 'QUEUED',
        CommandStage.sent => 'SENT',
        CommandStage.failed => 'FAILED',
      };
}
