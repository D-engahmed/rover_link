السلام عليكم، إزيكم؟

خلينا نفترض إنك AI Engineer واتحطيت في موقف:

**"معاك عربية صغيرة متحكم فيها بالـ Bluetooth، وعاوزين نحولها لـ Self-Driving / Autonomous Rover في أقل من يومين."**

هتبدأ بإيه؟

تفتح Python وتعمل Neural Network؟

**لا.**

أول حاجة هعملها هي إني أنسى الـ AI مؤقتًا وأسأل:

**إيه اللي عندي أصلًا؟**

لأن أصعب غلطة ممكن تعملها في Robotics إنك تبدأ من الـ model قبل ما تفهم الـ system اللي الموديل المفروض يتحكم فيه.

---

### 1. إيه الـ Non-Functional Requirements؟

المطلوب مش مجرد إن العربية تتحرك.

لازم يكون عندي:

* Human control
* Assisted control
* Autonomous control
* Follow Me
* Live telemetry
* Radar visualization
* Command-source tracing
* Command-source editing
* Bluetooth status
* Local data collection

يعني أنا محتاج **control system + observability + data pipeline**، مش مجرد remote control.

---

### 2. طيب الهاردوير اللي معايا إيه؟

هنا بدأت أعمل inventory للـ system.

عندي STM32 كـ embedded controller.

وعندي:

**Motor Driver**
مسؤولة عن الـ wheel actuation.

**HC-SR04**
عندي sensor للـ distance والـ obstacle detection.

**Servo Motor**
يعمل sweep للـ ultrasonic sensor عشان أقدر أبني radar-like spatial view.

**Bluetooth module**
الـ communication layer بين الـ phone والـ rover.

**ST7735 TFT**
للعرض المحلي والـ radar visualization.

**LED Matrix + STP**
للـ local status feedback.

**Buzzer**
للـ alerts وحالات التشغيل.

وفوق كل ده فيه embedded software stack بالفعل:

GPIO
USART
SPI
Timers
SysTick
Interrupts
Scheduler
Application modules

فبالتالي أنا مش ببني عربية من الصفر.

أنا عندي **embedded platform جاهزة نسبيًا**، والمشكلة الحقيقية هي:

**إزاي أضيف autonomy فوقها بدون ما أفسد التحكم والسلامة؟**

---

### 3. وإيه اللي الـ existing drivers دي بتديني إياه؟

دي النقطة اللي بدأت منها فعلًا.

الـ Motor Driver معناها إن عندي abstraction للتحكم في الحركة.

الـ HC-SR04 معناها إن عندي قياس للمسافة.

الـ Servo معناها إني أقدر أعمل scanning بدل sensor ثابت فقط.

الـ Bluetooth معناها إن الـ phone يقدر يكون high-level command source.

الـ TFT والـ LED Matrix والـ Buzzer معناهم إن الـ rover نفسه عنده local feedback.

والـ scheduler معناه إننا مش بنشغل كل حاجة في `while(1)` وخلاص؛ عندنا tasks منفصلة للـ control، telemetry، radar، ultrasonic، display وغيرها.

فالسؤال لم يعد:

**"إزاي أعمل AI؟"**

السؤال أصبح:

**"إزاي أركب autonomy فوق نظام embedded موجود بطريقة آمنة وقابلة للقياس؟"**

---

### 4. وهنا عملت الـ architecture

قسمت النظام إلى طبقات:

**STM32**

يمتلك:

* sensors
* motors
* actuator control
* local safety
* command handling

**Flutter Mobile App**

يمتلك:

* Manual
* Assisted
* Autonomous
* Follow Me
* telemetry
* radar visualization
* command tracing
* local JSONL collection

**Offline ML**

يأخذ الـ recorded sessions ويعمل:

**telemetry → normalization → dataset → training → evaluation**

وبعدين عندي مسار منفصل للـ RL experiments.

الفكرة إن الـ learning stack يفضل خارج الـ hard safety loop، والسياسة المتعلمة في النهاية مجرد **proposal** للحركة، وليست صاحبة القرار النهائي.

---

### 5. طب والـ telemetry؟

هنا الـ telemetry بالنسبة لي مش مجرد شاشة بتعرض أرقام.

هي **the system's runtime state stream**.

الـ STM32 بالفعل بيطلع newline-delimited JSON records عبر Bluetooth، فيها بيانات مثل:

* timestamp
* front distance
* ultrasonic validity
* radar angle
* speed
* direction
* mode
* sequence

والـ Flutter `RoverTelemetryService` يستقبل البيانات ويحولها إلى typed state.

بعد كده نفس الـ telemetry لها أكثر من consumer:

**UI**

عشان أشوف حالة الـ rover live.

**Autonomy**

عشان الـ controller يعرف:

> فين obstacle؟
> إيه الـ clearance ناحية اليمين والشمال؟
> العربية في أي mode؟
> وهل sensor state صالح أصلًا؟

**Dataset collection**

عشان نفس الـ runtime state يتسجل كـ training/evaluation data.

يعني بدل ما يكون عندي:

**sensor → UI**

بقى عندي:

**sensor → telemetry stream → multiple consumers**

وده فرق مهم جدًا في الـ architecture.

---

### 6. والأهم: الـ telemetry بتعمل bridge بين الـ robotics والـ ML

أقدر أسجل session مثلًا:

```text
telemetry
+
action
+
session_id
+
firmware_version
+
hardware_version
+
metadata
```

وبالتالي كل قرار حصل أثناء تشغيل الـ rover ممكن يتحول لاحقًا إلى data point قابل للتحليل.

المسار عندي بقى:

**STM32**

↓ Bluetooth

**Flutter**

↓ local JSONL

**Collector**

↓ normalization

**Session-aware dataset**

↓ labeling / feature preparation

**Training**

↓

**Held-out evaluation**

وده مقصود يكون **offline-first**.

أنا مش محتاج backend عشان العربية تمشي.

والـ data collection مش لازم تستنى cloud infrastructure.

الـ phone نفسه هو أول data-collection node.

---

### 7. ليه JSONL محليًا؟

لأن المشكلة في البداية مش scalability.

المشكلة في البداية هي:

**هل أقدر أجمع data بشكل موثوق وسهل؟**

JSONL بسيط، append-friendly، سهل debugging، وسهل يشتغل من file أو stdin.

لكن أهم من format نفسه هو إن الـ record يكون extensible.

يعني الـ schema يقدر يستقبل fields جديدة مع الوقت بدل ما كل sensor جديد يهدم الـ pipeline.

---

### 8. طيب وإحنا بنفكر في الـ future scaling؟

هنا الموضوع يبدأ يأخذ شكل مختلف.

الـ architecture الحالية هي:

**Rover → Phone → Local JSONL**

لكن أنا مصمم الـ data boundary عشان أقدر بعدين أتحول إلى:

**Rover → Phone → Backend Sync → Storage → Dataset Versions → Experiments → Model Registry**

يعني نفس الـ session اللي كنت بسجله على الموبايل، ممكن مستقبلًا أرفعه إلى backend بدون ما أغير فلسفة الـ data نفسها.

وبالتالي أقدر أوصل من:

**one rover**

إلى:

**many sessions**

ثم:

**many rovers**

ثم:

**fleet-level datasets**

ثم:

**model versioning + experiment lineage**

من غير ما أخلط الـ real-time control path مع الـ cloud path.

---

### 9. وهنا ظهرت مشكلة مهمة: Data Leakage

لو عندي rover بيجري في نفس المكان، ونفس الـ trajectory، ونفس الإضاءة، ونفس hardware state، فالـ samples المتجاورة مش independent.

فلو عملت random row split:

**sample 101 → train**
**sample 102 → test**

ممكن أكون فعليًا بختبر النموذج على نفس التجربة اللي درّبته عليها.

عشان كده الـ split عندي **session-aware**.

يعني:

**Session A → train**

**Session B → train**

**Session C → test**

بدل ما أقسم rows عشوائيًا.

وده أهم بكثير من مجرد زيادة عدد الـ samples.

---

### 10. وبنيت الـ dataset بحيث يبقى عنده lineage

أنا مش عايز بعد شهر أطلع model وأقول:

**"ده model اشتغل كويس."**

عاوز أقدر أعرف:

**dataset version**

**session IDs**

**firmware version**

**hardware version**

**feature set**

**model architecture**

**hyperparameters**

**training seed**

**split protocol**

**evaluation metrics**

**model artifact**

يعني:

**data → experiment → model**

كل واحدة مرتبطة باللي قبلها.

وده اللي يخلي المشروع قابل للتوسع بدل ما يبقى مجموعة notebooks وتجارب منفصلة.

---

### 11. بعد كده فقط دخل الـ ML

عملت offline ML paths للـ perception والـ behavior cloning.

وكمان عملت PPO experiment منفصل لمسألة:

**person approach**

الـ policy تشوف:

person presence
bearing
target size
facing state
obstacle distance

وتختار:

**Forward / Left / Right / Stop**

والشبكة نفسها صغيرة جدًا:

**5 → 32 → 32 → 4**

في التجربة المسجلة على simulation، النتيجة على 200 deterministic held-out episodes كانت:

**73.5% success
1.5% collision
25% timeout**

لكن بالنسبة لي الرقم نفسه لم يكن أهم شيء.

---

### 12. الـ interesting part كان في الـ failure

الـ first policy كانت حوالي:

**53.5% success**

وكان عندها failure mode واضح جدًا:

**Left → Right → Left → Right**

خصوصًا وهي قريبة من الـ target.

لما بصيت للمشكلة، ظهر إن الـ simulated turn increment كان:

**15°**

وإن granularity الحركة نفسها كانت بتدفع الـ controller إلى oscillation.

لما قللتها إلى:

**8°**

وأعدت التدريب، وصل الـ recorded held-out simulation إلى:

**73.5% success**

وده علمني حاجة مهمة:

**مش كل failure في Robotics هو Model failure.**

أحيانًا المشكلة في:

control granularity
actuator dynamics
timing
sensor update rate
state estimation
أو interaction بين الـ controller والـ physical system.

---

### 13. والأهم: ما ادعيتش حاجة الـ system مش قادر يثبتها

الـ HC-SR04 مش material classifier.

Bluetooth RSSI مش precise localization.

نجاح Bluetooth write مش معناه إن الـ MCU نفذ الأمر فعلًا.

الـ PPO result simulation result، مش physical autonomy guarantee.

والـ exported RL model لسه مش هو controller المستخدم فعليًا داخل Flutter.

حتى الـ framed CRC protocol موجود كـ migration design، بينما الـ active runtime ما زال يستخدم الـ simpler single-byte command path.

وكمان Follow Me لسه محتاج real camera/vision pipeline بدل ما نسمي target telemetry "computer vision".

---

وده بالنسبة لي هو جوهر المشروع.

أنا لم أبدأ بالسؤال:

**"إيه أكبر model أقدر أشغله؟"**

بدأت بالسؤال:

**"إيه النظام اللي عندي؟
إيه اللي أقدر أقيسه؟
إيه اللي يقدر يفشل؟
وإزاي الـ data اللي بجمعها النهارده تقدر تخدمني لما الـ system يكبر؟"**

ومن هنا بدأ **Rover Link** يتحول من Bluetooth-controlled car إلى محاولة لبناء **coherent robotics stack**:

**Embedded Control
→ Communication
→ Telemetry
→ Mobile Control
→ Data Collection
→ ML
→ RL
→ Safety**

والـ long-term direction بالنسبة لي مش:

**"جيب model أكبر."**

لكن:

**one safety policy
→ versioned communication
→ reliable telemetry
→ scalable data pipeline
→ real target perception
→ physical replay/evaluation
→ learned control behind the same safety gate.**

وده هو الجزء اللي أنا مهتم أشتغل عليه بعد كده.

Repository:
https://github.com/D-engahmed/rover_link

#Robotics #EmbeddedSystems #STM32 #Flutter #MachineLearning #ReinforcementLearning #EdgeAI #AIEngineering #RoboticsEngineering
