"""
Minimal PPO in plain numpy — no torch. This wasn't the original plan
(stable-baselines3 + torch would have matched your AMMA toolchain more
directly), but installing torch here hit this sandbox's disk quota before
it finished, and there's no way around that from inside the sandbox.

Given the observation space is 5 floats and the action space is 4 discrete
choices, a hand-rolled 2-layer MLP is not actually a compromise — a network
this small doesn't benefit from a heavy autodiff framework, and it has a
real upside: the trained weights export as plain numbers, so the on-device
Flutter inference is just matrix multiplies, no TFLite/ONNX conversion
pipeline and no new native Flutter dependency (a third one, after
bluetooth_classic and camera/ML Kit, felt like it was pushing the "will
this actually build" risk further than it needed to go).

If you specifically want this to be a torch/SB3 PPO model matching AMMA's
architecture more literally, that's a straightforward swap once you're on
a machine without this sandbox's disk limit — the environment (env.py) is
already gymnasium-Env-shaped (reset/step/observation_dim/n_actions) and
would need only a thin wrapper.
"""
from __future__ import annotations
import numpy as np


def softmax(x):
    x = x - x.max(axis=-1, keepdims=True)
    e = np.exp(x)
    return e / e.sum(axis=-1, keepdims=True)


class Adam:
    def __init__(self, params: dict, lr=3e-4, b1=0.9, b2=0.999, eps=1e-8):
        self.lr, self.b1, self.b2, self.eps = lr, b1, b2, eps
        self.m = {k: np.zeros_like(v) for k, v in params.items()}
        self.v = {k: np.zeros_like(v) for k, v in params.items()}
        self.t = 0

    def step(self, params: dict, grads: dict):
        self.t += 1
        for k in params:
            g = grads[k]
            self.m[k] = self.b1 * self.m[k] + (1 - self.b1) * g
            self.v[k] = self.b2 * self.v[k] + (1 - self.b2) * (g * g)
            mhat = self.m[k] / (1 - self.b1 ** self.t)
            vhat = self.v[k] / (1 - self.b2 ** self.t)
            params[k] -= self.lr * mhat / (np.sqrt(vhat) + self.eps)


class MLPActorCritic:
    """obs(5) -> tanh(32) -> tanh(32) -> {policy logits(4), value(1)}"""

    def __init__(self, obs_dim, n_actions, hidden=32, seed=0):
        rng = np.random.default_rng(seed)

        def he(fan_in, fan_out):
            return rng.normal(0, np.sqrt(2 / fan_in), size=(fan_in, fan_out)).astype(np.float32)

        self.p = {
            "W1": he(obs_dim, hidden), "b1": np.zeros(hidden, dtype=np.float32),
            "W2": he(hidden, hidden), "b2": np.zeros(hidden, dtype=np.float32),
            "Wp": he(hidden, n_actions) * 0.1, "bp": np.zeros(n_actions, dtype=np.float32),
            "Wv": he(hidden, 1) * 0.1, "bv": np.zeros(1, dtype=np.float32),
        }
        self.obs_dim, self.n_actions, self.hidden = obs_dim, n_actions, hidden

    def forward(self, X):
        p = self.p
        z1 = X @ p["W1"] + p["b1"]; h1 = np.tanh(z1)
        z2 = h1 @ p["W2"] + p["b2"]; h2 = np.tanh(z2)
        logits = h2 @ p["Wp"] + p["bp"]
        value = (h2 @ p["Wv"] + p["bv"]).squeeze(-1)
        probs = softmax(logits)
        cache = dict(X=X, z1=z1, h1=h1, z2=z2, h2=h2, logits=logits, probs=probs)
        return probs, value, cache

    def act(self, obs, rng: np.random.Generator):
        probs, value, _ = self.forward(obs[None, :])
        probs = probs[0]
        action = rng.choice(self.n_actions, p=probs)
        log_prob = np.log(probs[action] + 1e-8)
        return int(action), float(log_prob), float(value[0])

    def backward(self, cache, dlogits, dvalue, l2=0.0):
        """dlogits: [N, n_actions] gradient of loss wrt policy logits.
        dvalue: [N] gradient of loss wrt value output."""
        p = self.p
        h2, h1, z2, z1, X = cache["h2"], cache["h1"], cache["z2"], cache["z1"], cache["X"]

        grads = {}
        grads["Wp"] = h2.T @ dlogits + l2 * p["Wp"]
        grads["bp"] = dlogits.sum(axis=0)
        grads["Wv"] = h2.T @ dvalue[:, None] + l2 * p["Wv"]
        grads["bv"] = dvalue.sum(axis=0, keepdims=True)

        dh2 = dlogits @ p["Wp"].T + dvalue[:, None] @ p["Wv"].T
        dz2 = dh2 * (1 - h2 ** 2)
        grads["W2"] = h1.T @ dz2 + l2 * p["W2"]
        grads["b2"] = dz2.sum(axis=0)

        dh1 = dz2 @ p["W2"].T
        dz1 = dh1 * (1 - h1 ** 2)
        grads["W1"] = X.T @ dz1 + l2 * p["W1"]
        grads["b1"] = dz1.sum(axis=0)

        return grads


def compute_gae(rewards, values, dones, last_value, gamma=0.99, lam=0.95):
    """Standard GAE-lambda advantage estimation."""
    T = len(rewards)
    adv = np.zeros(T, dtype=np.float32)
    last_gae = 0.0
    for t in reversed(range(T)):
        next_value = last_value if t == T - 1 else values[t + 1]
        next_nonterminal = 1.0 - dones[t]
        delta = rewards[t] + gamma * next_value * next_nonterminal - values[t]
        last_gae = delta + gamma * lam * next_nonterminal * last_gae
        adv[t] = last_gae
    returns = adv + values
    return adv, returns


def ppo_update(net: MLPActorCritic, opt: Adam, obs, actions, old_log_probs, advantages, returns,
                clip_eps=0.2, value_coef=0.5, entropy_coef=0.01, epochs=4, batch_size=256):
    N = len(obs)
    advantages = (advantages - advantages.mean()) / (advantages.std() + 1e-8)
    idx_all = np.arange(N)

    last_stats = {}
    for _ in range(epochs):
        np.random.shuffle(idx_all)
        for start in range(0, N, batch_size):
            idx = idx_all[start:start + batch_size]
            X = obs[idx]
            a = actions[idx]
            old_lp = old_log_probs[idx]
            adv = advantages[idx]
            ret = returns[idx]

            probs, value, cache = net.forward(X)
            n = len(idx)
            new_lp = np.log(probs[np.arange(n), a] + 1e-8)
            ratio = np.exp(new_lp - old_lp)

            unclipped = ratio * adv
            clipped = np.clip(ratio, 1 - clip_eps, 1 + clip_eps) * adv
            use_unclipped = unclipped <= clipped  # min() picks this branch

            # d(loss_policy)/d(new_log_prob), loss = -mean(min(...))
            d_surrogate_d_ratio = np.where(use_unclipped, adv, 0.0)
            d_loss_d_newlp = -(d_surrogate_d_ratio * ratio) / n

            onehot = np.zeros_like(probs)
            onehot[np.arange(n), a] = 1.0
            dlogits_pg = d_loss_d_newlp[:, None] * (onehot - probs)

            # Entropy bonus (maximize entropy => subtract from loss):
            # dH/dz_j = -p_j * (H + log p_j); loss contribution = -entropy_coef * H
            logp_all = np.log(probs + 1e-8)
            H = -(probs * logp_all).sum(axis=1)
            dH_dz = -probs * (H[:, None] + logp_all)
            dlogits_entropy = -entropy_coef * dH_dz / n

            dlogits = dlogits_pg + dlogits_entropy

            dvalue = value_coef * 2 * (value - ret) / n

            grads = net.backward(cache, dlogits, dvalue)
            opt.step(net.p, grads)

            last_stats = {
                "policy_loss": float(-np.minimum(unclipped, clipped).mean()),
                "value_loss": float(((value - ret) ** 2).mean()),
                "entropy": float(H.mean()),
            }
    return last_stats
