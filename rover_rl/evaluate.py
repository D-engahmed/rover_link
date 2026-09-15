import json
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

from env import RoverApproachEnv, ARENA_SIZE, ACTION_NAMES
from policy import MLPActorCritic


def load_policy(path="trained_policy.npz", obs_dim=5, n_actions=4):
    data = np.load(path)
    net = MLPActorCritic(obs_dim, n_actions)
    for k in net.p:
        net.p[k] = data[k]
    return net


def run_episode(env, net, deterministic=True, rng=None):
    obs = env.reset()
    traj = [env.rover_pos.copy()]
    for _ in range(300):
        probs, value, _ = net.forward(obs[None, :])
        probs = probs[0]
        action = int(np.argmax(probs)) if deterministic else rng.choice(4, p=probs)
        obs, reward, terminated, truncated, info = env.step(action)
        traj.append(env.rover_pos.copy())
        if terminated or truncated:
            return info["result"], np.array(traj), env.person_pos.copy(), env.obstacles.copy()
    return "timeout", np.array(traj), env.person_pos.copy(), env.obstacles.copy()


def evaluate(n_episodes=200):
    net = load_policy()
    results = []
    example = None
    for i in range(n_episodes):
        env = RoverApproachEnv(seed=1000 + i)
        result, traj, person_pos, obstacles = run_episode(env, net, deterministic=True)
        results.append(result)
        if example is None and result == "success":
            example = (traj, person_pos, obstacles)

    n = len(results)
    print(f"Evaluated {n} episodes (deterministic policy, held-out seeds):")
    for r in ("success", "collision", "timeout"):
        pct = 100 * results.count(r) / n
        print(f"  {r:10s}: {pct:5.1f}%  ({results.count(r)}/{n})")

    # Training curve
    with open("training_history.json") as f:
        history = json.load(f)
    iters = [h["iter"] for h in history]
    success = [h["success"] for h in history]
    reward = [h["mean_reward"] for h in history]

    fig, axes = plt.subplots(1, 2, figsize=(11, 4))
    axes[0].plot(iters, success)
    axes[0].set_title("Success rate over training")
    axes[0].set_xlabel("PPO iteration")
    axes[0].set_ylabel("Success rate (this iteration's rollout)")
    axes[0].set_ylim(0, 1)

    axes[1].plot(iters, reward)
    axes[1].set_title("Mean episode reward over training")
    axes[1].set_xlabel("PPO iteration")
    axes[1].set_ylabel("Mean reward")

    plt.tight_layout()
    plt.savefig("training_curves.png", dpi=130)
    print("Saved training_curves.png")

    if example:
        traj, person_pos, obstacles = example
        fig2, ax = plt.subplots(figsize=(5.5, 5.5))
        ax.plot(traj[:, 0], traj[:, 1], "-o", ms=2, lw=1, color="#2563eb", label="rover path")
        ax.plot(traj[0, 0], traj[0, 1], "s", ms=10, color="#16a34a", label="start")
        ax.plot(person_pos[0], person_pos[1], "*", ms=18, color="#dc2626", label="person")
        for obs in obstacles:
            ax.add_patch(plt.Circle(obs, 0.25, color="#94a3b8", alpha=0.6))
        ax.set_xlim(0, ARENA_SIZE)
        ax.set_ylim(0, ARENA_SIZE)
        ax.set_aspect("equal")
        ax.set_title("Example successful approach (held-out seed)")
        ax.legend(loc="upper right", fontsize=8)
        plt.tight_layout()
        plt.savefig("example_trajectory.png", dpi=130)
        print("Saved example_trajectory.png")
    else:
        print("No successful episode found in this eval batch to plot — see success rate above.")

    return results


if __name__ == "__main__":
    evaluate()
