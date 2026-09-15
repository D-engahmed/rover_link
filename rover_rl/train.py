import numpy as np
from env import RoverApproachEnv
from policy import MLPActorCritic, Adam, compute_gae, ppo_update


def collect_rollout(env, net, rng, n_steps):
    obs_buf, act_buf, logp_buf, val_buf, rew_buf, done_buf = [], [], [], [], [], []
    results = []

    obs = env.reset()
    for _ in range(n_steps):
        action, log_prob, value = net.act(obs, rng)
        next_obs, reward, terminated, truncated, info = env.step(action)

        obs_buf.append(obs)
        act_buf.append(action)
        logp_buf.append(log_prob)
        val_buf.append(value)
        rew_buf.append(reward)
        done_buf.append(float(terminated or truncated))

        if terminated or truncated:
            results.append(info["result"])
            obs = env.reset()
        else:
            obs = next_obs

    _, last_value, _ = net.forward(obs[None, :])
    return (
        np.array(obs_buf, dtype=np.float32),
        np.array(act_buf),
        np.array(logp_buf, dtype=np.float32),
        np.array(val_buf, dtype=np.float32),
        np.array(rew_buf, dtype=np.float32),
        np.array(done_buf, dtype=np.float32),
        float(last_value[0]),
        results,
    )


def train(iterations=150, steps_per_iter=2048, seed=0, log_every=10):
    env = RoverApproachEnv(seed=seed)
    net = MLPActorCritic(env.observation_dim, env.n_actions, hidden=32, seed=seed)
    opt = Adam(net.p, lr=3e-4)
    rng = np.random.default_rng(seed)

    history = []
    for it in range(1, iterations + 1):
        obs, act, logp, val, rew, done, last_val, results = collect_rollout(
            env, net, rng, steps_per_iter
        )
        adv, ret = compute_gae(rew, val, done, last_val)
        stats = ppo_update(net, opt, obs, act, logp, adv, ret)

        n_ep = len(results)
        success = results.count("success") / n_ep if n_ep else 0.0
        collision = results.count("collision") / n_ep if n_ep else 0.0
        timeout = results.count("timeout") / n_ep if n_ep else 0.0
        mean_reward = rew.sum() / max(n_ep, 1)

        history.append(dict(iter=it, episodes=n_ep, success=float(success), collision=float(collision),
                             timeout=float(timeout), mean_reward=float(mean_reward),
                             **{k: float(v) for k, v in stats.items()}))

        if it % log_every == 0 or it == 1:
            print(f"iter {it:4d} | episodes {n_ep:3d} | success {success:.2f} | "
                  f"collision {collision:.2f} | timeout {timeout:.2f} | "
                  f"mean_reward {mean_reward:7.3f} | entropy {stats['entropy']:.3f}")

    return net, history


if __name__ == "__main__":
    net, history = train()

    np.savez("trained_policy.npz", **net.p)
    print("\nSaved weights to trained_policy.npz")

    import json
    with open("training_history.json", "w") as f:
        json.dump(history, f, indent=2)
    print("Saved training_history.json")
