# VoiceLeadingOptimizer

A high-level service that optimizes the transitions between voicings in a chord progression using musical heuristics and algorithmic search.

## Key Responsibilities

- **Cost-Based Pathfinding**: Uses a cost function to evaluate the "musicality" of moving from one voicing to another.
- **Global Optimization**: Employs dynamic programming to find the optimal path through all candidate voicings for an entire progression, not just local greedy matches.
- **Voice Leading Analysis**: Provides feedback on the quality of transitions (e.g., 7th to 3rd resolution, common tones, smooth stepwise motion).
- **Loop Optimization**: Ensures that the transition from the end of the progression back to the beginning is smooth for seamless looping.

## Optimization Heuristics (Cost Function)

The optimizer applies rewards (negative cost) and penalties (positive cost) based on traditional jazz principles:
- **Reward**: 7th resolving down to 3rd (the most critical principle).
- **Reward**: Holding common tones between chords.
- **Reward**: Stepwise motion (half or whole steps).
- **Penalty**: Large leaps in any voice.
- **Penalty**: Parallel octaves and perfect fifths.
- **Penalty**: Voice crossing (one voice moving above another).
- **Penalty**: Excessive "clusters" (too many close intervals).
- **Penalty**: Register jumps (moving the whole voicing too far up or down the keyboard).

## Core Algorithm

1. **Candidate Generation**: For each chord, generate all valid variants using `VoicingGenerator`.
2. **DP Table Construction**: Build a table where `dp[chord_index][candidate_index]` stores the minimum cost to reach that voicing from the beginning.
3. **Transition Calculation**: Calculate the cost of moving between every candidate in step `i` and step `i+1`.
4. **Backtracking**: Trace back from the lowest cost voicing at the final chord to find the optimal sequence.
5. **Spread Normalization**: A final pass to ensure the "spread" (distance between lowest and highest notes) remains consistent throughout the progression.

