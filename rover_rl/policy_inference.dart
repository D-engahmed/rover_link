// Forward pass for the trained RL policy — same math as policy.py's
// MLPActorCritic.forward(), deterministic (argmax) action selection, no
// sampling at inference time. Not yet wired into RoverState — see
// rover_rl/README.md "Integration into the Flutter app" for what that
// requires, including the part that still needs deciding (how the RL
// action and the hard e-stop rule interact — the e-stop must stay a real
// veto, not something the model can be trained around).

import 'dart:math';
import 'rover_policy_weights.dart';

enum RoverAction { forward, left, right, stop }

// Note: weights are stored [in_dim][out_dim] (row = input feature) to match
// how export_dart.py wrote them (numpy W of shape [in, out]) — so this does
// x @ W, not W @ x. Written explicitly rather than reusing _matVecAdd's
// row-major assumption, to avoid a transpose bug.
List<double> _forwardLayer(List<double> x, List<List<double>> w, List<double> b) {
  final outDim = b.length;
  final out = List<double>.filled(outDim, 0);
  for (int j = 0; j < outDim; j++) {
    double s = b[j];
    for (int i = 0; i < x.length; i++) {
      s += x[i] * w[i][j];
    }
    out[j] = s;
  }
  return out;
}

List<double> _tanhVec(List<double> x) => x.map((v) => tanh(v)).toList();

List<double> _softmax(List<double> x) {
  final m = x.reduce(max);
  final exps = x.map((v) => exp(v - m)).toList();
  final sum = exps.reduce((a, b) => a + b);
  return exps.map((v) => v / sum).toList();
}

class PolicyOutput {
  final RoverAction action;
  final List<double> actionProbs;
  final double value;
  const PolicyOutput(this.action, this.actionProbs, this.value);
}

/// obs must be exactly: [personPresent, bearingFrac, sizeFrac, facingCamera,
/// obstacleNorm] — same order as env.py's _observe(). obstacleNorm is
/// nearestObstacleCm clamped to [0, 200] and divided by 200 (matches
/// OBSTACLE_MAX_RANGE=2.0m in env.py); get that normalization wrong and the
/// policy will behave confidently and incorrectly, not obviously-broken.
PolicyOutput runPolicy(List<double> obs) {
  assert(obs.length == 5, 'Expected 5 observation features, got ${obs.length}');
  final h1 = _tanhVec(_forwardLayer(obs, W1, b1));
  final h2 = _tanhVec(_forwardLayer(h1, W2, b2));
  final logits = _forwardLayer(h2, Wp, bp);
  final value = _forwardLayer(h2, Wv, bv)[0];
  final probs = _softmax(logits);

  int bestIdx = 0;
  for (int i = 1; i < probs.length; i++) {
    if (probs[i] > probs[bestIdx]) bestIdx = i;
  }
  const actions = [RoverAction.forward, RoverAction.left, RoverAction.right, RoverAction.stop];
  return PolicyOutput(actions[bestIdx], probs, value);
}
