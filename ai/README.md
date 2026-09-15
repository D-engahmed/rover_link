# Rover Link AI

The AI layer is perception-first. It produces structured evidence; it does not directly drive motors.

## First model target
`sensor/camera features -> target type + confidence + bearing + distance`

A standard HC-SR04 alone is insufficient for defensible human/metal/wood classification. The training dataset must therefore record the actual sensing modalities used for each sample.

## Training loop
1. collect synchronized sensor/camera samples;
2. label target class and quality;
3. split by session/environment, not random individual samples only;
4. train a baseline classifier/detector;
5. evaluate false positives/false negatives;
6. export a versioned inference artifact;
7. validate inference against deterministic safety rules.

## Runtime contract
The model may return:
- target class;
- confidence;
- bearing;
- estimated range if the model provides it.

The navigation and safety layers decide whether motion is permitted.
