# LinkedIn post

I’ve been building **Rover Link**, an offline-first robotics stack designed to connect embedded control, mobile robotics software, telemetry, and machine learning without turning the AI layer into the safety authority.

The system is built around a simple boundary:

**the phone can decide what it wants the rover to do; the STM32 decides what the hardware is allowed to do.**

The current architecture has four main pieces.

**1. STM32 firmware**

The embedded side handles:

- motor control;
- HC-SR04 ultrasonic sensing;
- servo-based radar scanning;
- Bluetooth communication;
- TFT and LED-matrix feedback;
- buzzer state feedback;
- scheduled control and sensor tasks;
- local obstacle/forward-motion safety;
- a phone-autonomy command watchdog.

**2. Flutter mobile control**

The Android app provides:

- Manual control;
- Assisted control;
- Autonomous control;
- Follow Me control;
- live telemetry;
- radar visualization;
- command-source tracing;
- Bluetooth status;
- local JSONL data collection.

I also made mode transitions explicit. Returning to Manual is not just a screen navigation: the app stops the phone controller, sends a physical STOP, switches the STM32 back to Manual, and only then exposes the manual driver.

**3. Offline ML pipeline**

The phone can record rover state/action data without a backend.

The Python pipeline supports:

- telemetry normalization;
- session-aware datasets;
- perception experiments;
- behavior cloning;
- held-out evaluation and confusion matrices.

The important part is leakage control: physical sessions are grouped so adjacent samples from the same run do not silently appear in both training and test data.

**4. Reinforcement learning**

I built a separate compact PPO environment for the person-approach problem.

The policy observes:

person presence + bearing + target size + facing state + obstacle distance

and selects:

forward / left / right / stop

The model is a small 5 → 32 → 32 → 4 actor network with a value head.

One recorded simulation experiment reached:

**73.5% success, 1.5% collision, 25% timeout**

on 200 deterministic held-out episodes.

But the more interesting result was the failure analysis.

The first policy reached only 53.5% success and repeatedly produced a close-range L → R → L → R oscillation. The simulated turn step was 15°. Reducing it to 8° and retraining raised the reported held-out success to 73.5% and reduced timeouts.

That exposed a robotics issue, not just an ML issue: command granularity can create a control limit cycle when the rover is already close to the target.

I’m also keeping the project honest about what it does not prove yet:

- HC-SR04 range is not material classification.
- Bluetooth RSSI is not precise localization.
- A successful Bluetooth write is not proof that the STM32 executed the command.
- The RL result is simulation-only.
- The PPO model exists, but it is not yet the controller used by the Flutter app.
- The repository contains a framed CRC protocol design, but the current runtime still uses the simpler single-byte command path.
- The backend is currently a documented service boundary, not a required real-time component.
- The current repository does not contain the camera/vision service referenced by the Follow Me/RL design.

The next step is therefore not simply “add a bigger model.”

It is to make the whole control stack internally consistent:

**one safety policy → versioned communication → real target perception → physical replay/evaluation → learned control behind the same safety gate.**

That is the direction I’m taking with Rover Link: build the robotics system so that every layer has a defined responsibility, measurable failure modes, and a clear path from prototype to a defensible system.

Repository: https://github.com/D-engahmed/rover_link

#Robotics #EmbeddedSystems #STM32 #Flutter #MachineLearning #ReinforcementLearning #EdgeAI #AIEngineering #RoboticsEngineering
