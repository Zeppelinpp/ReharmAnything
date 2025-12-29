# ReharmManager

The logic engine for applying jazz reharmonization strategies to existing chord progressions.

## Key Responsibilities

- **Strategy Registry**: Maintains a collection of available `ReharmStrategy` implementations.
- **Transformation Logic**: Provides methods to apply a chosen strategy to either specific chords or all eligible chords in a progression.
- **Duration Management**: When a strategy replaces one chord with multiple (e.g., adding a related ii-V), it automatically subdivides the original duration to maintain the progression's timing.

## Available Strategies

1. **Tritone Substitution**: Replaces a dominant 7th chord with a dominant chord a tritone away (e.g., G7 -> Db7).
2. **Diminished Stack**: Marks a dominant chord to use a polychord voicing (root triad + triad a minor 3rd below).
3. **Related ii-V**: Inserts the related minor ii chord before a dominant (e.g., G7 -> Dm7 G7).
4. **Backdoor Dominant**: Replaces the V7 with a bVII7 (backdoor resolution).

## Implementation Detail

- **Strategy Protocol**: Defines `name`, `description`, `canApply(to:)`, and `apply(to:)`.
- **Global Application**: `applyToAllDominants` iterates through a progression and transforms every chord that matches `isDominant`.
- **Observable**: Publishes changes to its `availableStrategies` list, allowing the UI to dynamically populate selection menus.

