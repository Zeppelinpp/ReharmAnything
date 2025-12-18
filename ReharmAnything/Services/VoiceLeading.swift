import Foundation

// MARK: - Voice Leading Cost Function

/// Voice leading optimizer using cost function approach
/// Based on traditional jazz voice leading principles:
/// - 7th resolves to 3rd (半音下行)
/// - Common tones are held
/// - Minimum motion for other voices
/// - Avoid parallel 5ths and octaves
class VoiceLeadingOptimizer {
    
    private let voicingGenerator = VoicingGenerator()
    
    // MARK: - Cost Function Weights (Tunable)
    
    struct CostWeights {
        // Core voice leading principles
        var seventhToThird: Double = -15.0      // REWARD: 7th resolving to 3rd (negative = good)
        var halfStepMotion: Double = -3.0       // REWARD: Half-step motion
        var wholeStepMotion: Double = -1.0      // REWARD: Whole-step motion
        var commonTone: Double = -5.0           // REWARD: Holding common tones
        
        // Penalties
        var largeLeap: Double = 2.0             // Per semitone beyond minor 3rd
        var parallelFifths: Double = 20.0       // Parallel perfect 5ths
        var parallelOctaves: Double = 20.0      // Parallel octaves
        var voiceCrossing: Double = 15.0        // Voices crossing each other
        var voiceOverlap: Double = 8.0          // Voice moving past previous position of another
        
        // Range and balance
        var outOfRange: Double = 10.0           // Per semitone out of ideal range
        var registerJump: Double = 5.0          // Large register change
        var unevenSpacing: Double = 3.0         // Uneven intervals between voices
        
        // Contrary motion bonus
        var contraryMotion: Double = -2.0       // Outer voices move in opposite directions
        
        // Global voicing constraints
        var spreadPenalty: Double = 3.0         // Penalty for voicing spread > maxSpread
        var globalSpreadPenalty: Double = 8.0   // Penalty for large spread change between chords
        
        // Cluster control - avoid too many minor/major 2nds
        var clusterPenalty: Double = 12.0       // Penalty for excess clusters (>2 semitones intervals)
        var maxAllowedClusters: Int = 1         // Allow max 1-2 cluster intervals
        
        // Inner movement - reward voice motion that shows chord change
        var innerMovementBonus: Double = -4.0   // Reward for meaningful voice movement
        var staticVoicingPenalty: Double = 8.0  // Penalty if too many voices stay static
        var minMovingVoices: Int = 2            // At least 2 voices should move to show change
    }
    
    // Global voicing constraints
    let maxVoicingSpread: Int = 24              // Max spread within a single voicing (2 octaves)
    let maxSpreadChange: Int = 12              // Max spread change between consecutive voicings (1 octave)
    
    var weights = CostWeights()
    
    // Ideal range for piano voicings
    let idealLow: MIDINote = 48    // C3
    let idealHigh: MIDINote = 72   // C5
    let absoluteLow: MIDINote = 36 // C2
    let absoluteHigh: MIDINote = 84 // C6
    
    // MARK: - Main Cost Function
    
    /// Calculate total voice leading cost from one voicing to another
    /// Lower cost = better voice leading
    func calculateCost(from v1: Voicing, to v2: Voicing) -> Double {
        var cost: Double = 0
        
        let notes1 = v1.notes.sorted()
        let notes2 = v2.notes.sorted()
        
        // Ensure same number of voices for comparison
        guard notes1.count == notes2.count else {
            return handleVoiceCountMismatch(from: notes1, to: notes2)
        }
        
        // 1. Calculate individual voice motions
        cost += calculateVoiceMotionCost(from: notes1, to: notes2)
        
        // 2. Check for 7th to 3rd resolution (THE KEY PRINCIPLE)
        cost += calculateSeventhToThirdResolution(from: v1, to: v2)
        
        // 3. Common tone bonus
        cost += calculateCommonToneBonus(from: notes1, to: notes2)
        
        // 4. Parallel motion penalties
        cost += calculateParallelMotionPenalty(from: notes1, to: notes2)
        
        // 5. Voice crossing and overlap
        cost += calculateVoiceCrossingPenalty(from: notes1, to: notes2)
        
        // 6. Contrary motion bonus (outer voices)
        cost += calculateContraryMotionBonus(from: notes1, to: notes2)
        
        // 7. Range penalties
        cost += calculateRangePenalty(notes2)
        
        // 8. Register continuity
        cost += calculateRegisterContinuity(from: v1, to: v2)
        
        // 9. Voicing spread constraints
        cost += calculateSpreadPenalty(v2)
        
        // 10. Global spread change penalty
        cost += calculateSpreadChangePenalty(from: v1, to: v2)
        
        // 11. Cluster penalty - avoid too many minor/major 2nds
        cost += calculateClusterPenalty(v2)
        
        // 12. Inner movement - reward voice motion showing chord change
        cost += calculateInnerMovementScore(from: v1, to: v2)
        
        return cost
    }
    
    // MARK: - Cluster Control
    
    /// Count cluster intervals (minor 2nd = 1 semitone, major 2nd = 2 semitones)
    private func countClusterIntervals(_ notes: [MIDINote]) -> Int {
        let sorted = notes.sorted()
        var clusterCount = 0
        
        for i in 0..<(sorted.count - 1) {
            let interval = sorted[i + 1] - sorted[i]
            if interval <= 2 {  // Minor 2nd or Major 2nd
                clusterCount += 1
            }
        }
        
        return clusterCount
    }
    
    /// Penalty for having too many cluster intervals
    private func calculateClusterPenalty(_ voicing: Voicing) -> Double {
        let clusterCount = countClusterIntervals(voicing.notes)
        
        if clusterCount > weights.maxAllowedClusters {
            // Exponential penalty for excessive clusters
            let excess = clusterCount - weights.maxAllowedClusters
            return Double(excess * excess) * weights.clusterPenalty
        }
        
        return 0
    }
    
    // MARK: - Inner Movement
    
    /// Reward meaningful voice movement that shows chord change
    private func calculateInnerMovementScore(from v1: Voicing, to v2: Voicing) -> Double {
        let notes1 = v1.notes.sorted()
        let notes2 = v2.notes.sorted()
        
        guard notes1.count == notes2.count else { return 0 }
        
        var score: Double = 0
        var movingVoices = 0
        var meaningfulMovements = 0
        
        for i in 0..<notes1.count {
            let motion = abs(notes2[i] - notes1[i])
            
            if motion > 0 {
                movingVoices += 1
                
                // Reward stepwise motion (1-2 semitones) as meaningful movement
                if motion >= 1 && motion <= 3 {
                    meaningfulMovements += 1
                    score += weights.innerMovementBonus
                }
            }
        }
        
        // Penalty if chord change doesn't show enough movement
        if movingVoices < weights.minMovingVoices {
            // Too static - doesn't feel like a chord change
            score += weights.staticVoicingPenalty * Double(weights.minMovingVoices - movingVoices)
        }
        
        // Bonus for having good balance of movement and stability
        // Ideal: 2-3 voices move, 1-2 voices hold common tones
        let commonTones = notes1.count - movingVoices
        if commonTones >= 1 && commonTones <= 2 && meaningfulMovements >= 2 {
            score += weights.innerMovementBonus * 2  // Extra bonus for ideal balance
        }
        
        return score
    }
    
    // MARK: - Spread Constraints
    
    /// Penalty for voicing spread exceeding max
    private func calculateSpreadPenalty(_ voicing: Voicing) -> Double {
        let spread = voicing.spread
        if spread > maxVoicingSpread {
            return Double(spread - maxVoicingSpread) * weights.spreadPenalty
        }
        return 0
    }
    
    /// Penalty for large spread changes between consecutive voicings
    private func calculateSpreadChangePenalty(from v1: Voicing, to v2: Voicing) -> Double {
        let spreadChange = abs(v1.spread - v2.spread)
        if spreadChange > maxSpreadChange {
            return Double(spreadChange - maxSpreadChange) * weights.globalSpreadPenalty
        }
        return 0
    }
    
    // MARK: - Cost Components
    
    /// Voice motion cost - rewards stepwise, penalizes leaps
    private func calculateVoiceMotionCost(from: [MIDINote], to: [MIDINote]) -> Double {
        var cost: Double = 0
        
        for i in 0..<from.count {
            let motion = abs(to[i] - from[i])
            
            switch motion {
            case 0:
                // Common tone - handled separately
                break
            case 1:
                // Half step - excellent
                cost += weights.halfStepMotion
            case 2:
                // Whole step - good
                cost += weights.wholeStepMotion
            case 3:
                // Minor 3rd - acceptable
                cost += 0
            default:
                // Larger leap - penalty increases with size
                cost += Double(motion - 3) * weights.largeLeap
            }
        }
        
        return cost
    }
    
    /// THE CORE JAZZ PRINCIPLE: 7th resolves down to 3rd
    private func calculateSeventhToThirdResolution(from v1: Voicing, to v2: Voicing) -> Double {
        var cost: Double = 0
        
        // Get 7th from first chord
        guard let seventh = v1.seventhNote() else { return 0 }
        
        // Get 3rd from second chord
        guard let third = v2.thirdNote() else { return 0 }
        
        // Check if 7th resolves to 3rd by half step or whole step
        let resolution = seventh - third
        
        if resolution == 1 || resolution == 2 {
            // Perfect resolution: 7th steps down to 3rd
            cost += weights.seventhToThird
        } else if resolution == -1 || resolution == -2 {
            // Acceptable: 7th steps up to 3rd (less common but valid)
            cost += weights.seventhToThird * 0.5
        }
        
        return cost
    }
    
    /// Common tone bonus - holding notes that exist in both chords
    private func calculateCommonToneBonus(from: [MIDINote], to: [MIDINote]) -> Double {
        var bonus: Double = 0
        
        // Check for exact common tones (same pitch)
        let fromSet = Set(from)
        let toSet = Set(to)
        let exactCommon = fromSet.intersection(toSet).count
        bonus += Double(exactCommon) * weights.commonTone
        
        // Check for enharmonic common tones (same pitch class, different octave)
        let fromPitchClasses = Set(from.map { $0 % 12 })
        let toPitchClasses = Set(to.map { $0 % 12 })
        let pitchClassCommon = fromPitchClasses.intersection(toPitchClasses).count
        bonus += Double(pitchClassCommon - exactCommon) * weights.commonTone * 0.3
        
        return bonus
    }
    
    /// Parallel 5ths and octaves penalty
    private func calculateParallelMotionPenalty(from: [MIDINote], to: [MIDINote]) -> Double {
        var penalty: Double = 0
        
        for i in 0..<from.count {
            for j in (i + 1)..<from.count {
                let interval1 = abs(from[j] - from[i]) % 12
                let interval2 = abs(to[j] - to[i]) % 12
                
                let motion1 = to[i] - from[i]
                let motion2 = to[j] - from[j]
                
                // Both voices moving in same direction by same amount
                let isParallel = motion1 == motion2 && motion1 != 0
                
                if isParallel {
                    // Parallel perfect 5ths
                    if interval1 == 7 && interval2 == 7 {
                        penalty += weights.parallelFifths
                    }
                    // Parallel octaves
                    if interval1 == 0 && interval2 == 0 {
                        penalty += weights.parallelOctaves
                    }
                }
            }
        }
        
        return penalty
    }
    
    /// Voice crossing and overlap penalties
    private func calculateVoiceCrossingPenalty(from: [MIDINote], to: [MIDINote]) -> Double {
        var penalty: Double = 0
        
        for i in 0..<(from.count - 1) {
            // Voice crossing: voice i ends up higher than voice i+1
            if to[i] > to[i + 1] {
                penalty += weights.voiceCrossing
            }
            
            // Voice overlap: voice i moves past where voice i+1 was
            if to[i] > from[i + 1] || to[i + 1] < from[i] {
                penalty += weights.voiceOverlap
            }
        }
        
        return penalty
    }
    
    /// Contrary motion bonus - outer voices moving in opposite directions
    private func calculateContraryMotionBonus(from: [MIDINote], to: [MIDINote]) -> Double {
        guard from.count >= 2 else { return 0 }
        
        let bassMotion = to[0] - from[0]
        let sopranoMotion = to.last! - from.last!
        
        // Contrary motion: one goes up, other goes down
        if (bassMotion > 0 && sopranoMotion < 0) || (bassMotion < 0 && sopranoMotion > 0) {
            return weights.contraryMotion
        }
        
        return 0
    }
    
    /// Range penalty for notes outside ideal range
    private func calculateRangePenalty(_ notes: [MIDINote]) -> Double {
        var penalty: Double = 0
        
        for note in notes {
            if note < idealLow {
                penalty += Double(idealLow - note) * weights.outOfRange * 0.5
            } else if note > idealHigh {
                penalty += Double(note - idealHigh) * weights.outOfRange * 0.5
            }
            
            // Severe penalty for absolute range violations
            if note < absoluteLow {
                penalty += Double(absoluteLow - note) * weights.outOfRange * 2
            } else if note > absoluteHigh {
                penalty += Double(note - absoluteHigh) * weights.outOfRange * 2
            }
        }
        
        return penalty
    }
    
    /// Register continuity - penalize large jumps in overall voicing position
    private func calculateRegisterContinuity(from v1: Voicing, to v2: Voicing) -> Double {
        let centerDiff = abs(v1.center - v2.center)
        
        if centerDiff > 6 {
            return (centerDiff - 6) * weights.registerJump
        }
        
        return 0
    }
    
    /// Handle different voice counts
    private func handleVoiceCountMismatch(from: [MIDINote], to: [MIDINote]) -> Double {
        // Heavy penalty for voice count changes, but still calculate what we can
        let penalty = Double(abs(from.count - to.count)) * 20.0
        
        let minCount = min(from.count, to.count)
        var cost = penalty
        
        for i in 0..<minCount {
            let motion = abs(to[i] - from[i])
            if motion > 3 {
                cost += Double(motion - 3) * weights.largeLeap
            }
        }
        
        return cost
    }
    
    // MARK: - Find Best Voicing
    
    /// Find the best voicing for the next chord given the current voicing
    func findBestVoicing(
        for chord: Chord,
        after previousVoicing: Voicing?,
        voicingType: VoicingType = .rootlessA
    ) -> Voicing {
        // Check if this chord should use diminished stack (polychord) voicing
        let useDimStack = chord.extensions.contains("dimStack")
        
        // If no previous voicing, start with a sensible default
        guard let previous = previousVoicing else {
            if useDimStack && chord.isDominant {
                return voicingGenerator.generateDiminishedStackVoicing(for: chord, useMajorTriads: true)
            }
            return voicingGenerator.generateVoicing(for: chord, type: voicingType, targetRegister: 54)
        }
        
        // For diminished stack, use the special polychord voicing
        if useDimStack && chord.isDominant {
            return voicingGenerator.generateDiminishedStackVoicing(for: chord, useMajorTriads: true)
        }
        
        // Generate all candidate voicings
        let candidates = voicingGenerator.generateAllVariants(
            for: chord,
            type: voicingType,
            targetRegister: MIDINote(Int(previous.center))
        )
        
        // Find the one with lowest cost
        var bestVoicing = candidates.first ?? voicingGenerator.generateVoicing(for: chord, type: voicingType)
        var bestCost = Double.infinity
        
        for candidate in candidates {
            let cost = calculateCost(from: previous, to: candidate)
            if cost < bestCost {
                bestCost = cost
                bestVoicing = candidate
            }
        }
        
        return bestVoicing
    }
    
    // MARK: - Optimize Entire Progression
    
    /// Optimize voice leading for an entire chord progression using global optimization
    func optimizeProgression(
        _ progression: ChordProgression,
        voicingType: VoicingType = .rootlessA,
        forLoop: Bool = true
    ) -> [Voicing] {
        guard !progression.events.isEmpty else { return [] }
        
        // Use global optimization with spread constraints
        var voicings = optimizeGlobal(progression, voicingType: voicingType)
        
        // Refine for loop if needed
        if forLoop && voicings.count > 1 {
            voicings = optimizeForLoop(voicings, progression: progression, voicingType: voicingType)
        }
        
        // Final pass: normalize spread to reduce extreme variations
        voicings = normalizeVoicingSpread(voicings, progression: progression, voicingType: voicingType)
        
        return voicings
    }
    
    /// Global optimization using dynamic programming approach
    private func optimizeGlobal(
        _ progression: ChordProgression,
        voicingType: VoicingType
    ) -> [Voicing] {
        guard !progression.events.isEmpty else { return [] }
        
        let events = progression.events
        
        // Generate all candidate voicings for each chord
        var allCandidates: [[Voicing]] = []
        for event in events {
            let candidates = voicingGenerator.generateAllVariants(
                for: event.chord,
                type: voicingType,
                targetRegister: 54
            )
            // Filter out voicings with excessive spread or too many clusters
            let filtered = candidates.filter { voicing in
                let spreadOk = voicing.spread <= maxVoicingSpread + 6
                let clusterCount = countClusterIntervals(voicing.notes)
                let clusterOk = clusterCount <= weights.maxAllowedClusters + 1
                return spreadOk && clusterOk
            }
            allCandidates.append(filtered.isEmpty ? candidates : filtered)
        }
        
        // Dynamic programming: find optimal path through all voicings
        // dp[i][j] = (minCost, previousIndex) for chord i, voicing j
        var dp: [[(cost: Double, prev: Int)]] = []
        
        // Initialize first chord
        dp.append(allCandidates[0].map { _ in (0.0, -1) })
        
        // Fill DP table
        for i in 1..<events.count {
            var currentRow: [(cost: Double, prev: Int)] = []
            
            for (j, currentVoicing) in allCandidates[i].enumerated() {
                var bestCost = Double.infinity
                var bestPrev = 0
                
                for (k, prevVoicing) in allCandidates[i-1].enumerated() {
                    let transitionCost = calculateCost(from: prevVoicing, to: currentVoicing)
                    let totalCost = dp[i-1][k].cost + transitionCost
                    
                    if totalCost < bestCost {
                        bestCost = totalCost
                        bestPrev = k
                    }
                }
                
                currentRow.append((bestCost, bestPrev))
            }
            
            dp.append(currentRow)
        }
        
        // Backtrack to find optimal voicings
        var result: [Voicing] = []
        
        // Find best final voicing
        guard let lastRow = dp.last else { return [] }
        var bestFinalIdx = 0
        var bestFinalCost = Double.infinity
        for (idx, entry) in lastRow.enumerated() {
            if entry.cost < bestFinalCost {
                bestFinalCost = entry.cost
                bestFinalIdx = idx
            }
        }
        
        // Backtrack
        var currentIdx = bestFinalIdx
        for i in (0..<events.count).reversed() {
            result.insert(allCandidates[i][currentIdx], at: 0)
            if i > 0 {
                currentIdx = dp[i][currentIdx].prev
            }
        }
        
        return result
    }
    
    /// Normalize spread across progression to reduce extreme variations
    private func normalizeVoicingSpread(
        _ voicings: [Voicing],
        progression: ChordProgression,
        voicingType: VoicingType
    ) -> [Voicing] {
        guard voicings.count > 2 else { return voicings }
        
        var optimized = voicings
        
        // Calculate average spread
        let spreads = voicings.map { $0.spread }
        let avgSpread = Double(spreads.reduce(0, +)) / Double(spreads.count)
        let targetSpread = min(Int(avgSpread), maxVoicingSpread)
        
        // Find voicings with extreme spread and try to replace them
        for i in 0..<optimized.count {
            let currentSpread = optimized[i].spread
            
            // Skip if spread is acceptable
            if abs(currentSpread - targetSpread) <= 6 {
                continue
            }
            
            // Try to find a better voicing closer to target spread
            let candidates = voicingGenerator.generateAllVariants(
                for: progression.events[i].chord,
                type: voicingType,
                targetRegister: MIDINote(Int(optimized[i].center))
            )
            
            // Filter candidates by spread proximity to target
            let filteredBySpread = candidates.filter {
                abs($0.spread - targetSpread) < abs(currentSpread - targetSpread)
            }
            
            guard !filteredBySpread.isEmpty else { continue }
            
            // Find best replacement considering voice leading cost
            var bestReplacement = optimized[i]
            var bestTotalCost = Double.infinity
            
            for candidate in filteredBySpread {
                var totalCost: Double = 0
                
                // Cost to previous voicing
                if i > 0 {
                    totalCost += calculateCost(from: optimized[i-1], to: candidate)
                }
                
                // Cost to next voicing
                if i < optimized.count - 1 {
                    totalCost += calculateCost(from: candidate, to: optimized[i+1])
                }
                
                // Spread bonus - prefer voicings closer to target spread
                let spreadDiff = abs(candidate.spread - targetSpread)
                totalCost += Double(spreadDiff) * 0.5
                
                if totalCost < bestTotalCost {
                    bestTotalCost = totalCost
                    bestReplacement = candidate
                }
            }
            
            optimized[i] = bestReplacement
        }
        
        return optimized
    }
    
    /// Optimize voicings for seamless looping
    private func optimizeForLoop(
        _ voicings: [Voicing],
        progression: ChordProgression,
        voicingType: VoicingType
    ) -> [Voicing] {
        var optimized = voicings
        
        // Check loop connection cost
        let loopCost = calculateCost(from: optimized.last!, to: optimized.first!)
        
        // If loop connection is poor, try different starting voicings
        if loopCost > 10 {
            // Try to find a better starting voicing that works for loop
            let candidates = voicingGenerator.generateAllVariants(
                for: progression.events[0].chord,
                type: voicingType,
                targetRegister: MIDINote(Int(optimized.last!.center))
            )
            
            var bestStart = optimized[0]
            var bestTotalCost = Double.infinity
            
            for candidate in candidates {
                // Calculate cost of this candidate as loop start
                let loopStartCost = calculateCost(from: optimized.last!, to: candidate)
                
                // Re-optimize with this starting point
                var testVoicings = [candidate]
                var prev = candidate
                
                for event in progression.events.dropFirst() {
                    let next = findBestVoicing(for: event.chord, after: prev, voicingType: voicingType)
                    testVoicings.append(next)
                    prev = next
                }
                
                // Calculate total cost including loop
                var totalCost = loopStartCost
                for i in 0..<(testVoicings.count - 1) {
                    totalCost += calculateCost(from: testVoicings[i], to: testVoicings[i + 1])
                }
                totalCost += calculateCost(from: testVoicings.last!, to: testVoicings.first!)
                
                if totalCost < bestTotalCost {
                    bestTotalCost = totalCost
                    bestStart = candidate
                    optimized = testVoicings
                }
            }
        }
        
        return optimized
    }
    
    // MARK: - Analysis
    
    /// Analyze voice leading quality
    func analyzeVoiceLeading(_ voicings: [Voicing], isLoop: Bool = true) -> VoiceLeadingAnalysis {
        guard voicings.count > 1 else {
            return VoiceLeadingAnalysis(
                transitions: [],
                totalCost: 0,
                averageCost: 0,
                loopCost: nil,
                quality: .excellent
            )
        }
        
        var transitions: [TransitionAnalysis] = []
        var totalCost: Double = 0
        
        for i in 0..<(voicings.count - 1) {
            let cost = calculateCost(from: voicings[i], to: voicings[i + 1])
            let analysis = analyzeTransition(from: voicings[i], to: voicings[i + 1], cost: cost)
            transitions.append(analysis)
            totalCost += cost
        }
        
        // Loop analysis
        var loopCost: Double? = nil
        if isLoop {
            loopCost = calculateCost(from: voicings.last!, to: voicings.first!)
            totalCost += loopCost!
        }
        
        let averageCost = totalCost / Double(isLoop ? voicings.count : voicings.count - 1)
        
        let quality: VoiceLeadingQuality
        switch averageCost {
        case ..<0: quality = .excellent
        case 0..<5: quality = .good
        case 5..<10: quality = .fair
        default: quality = .poor
        }
        
        return VoiceLeadingAnalysis(
            transitions: transitions,
            totalCost: totalCost,
            averageCost: averageCost,
            loopCost: loopCost,
            quality: quality
        )
    }
    
    /// Analyze a single transition
    private func analyzeTransition(from v1: Voicing, to v2: Voicing, cost: Double) -> TransitionAnalysis {
        var features: [String] = []
        
        // Check for 7th to 3rd resolution
        if let seventh = v1.seventhNote(), let third = v2.thirdNote() {
            let resolution = seventh - third
            if resolution == 1 {
                features.append("7→3 (半音下行)")
            } else if resolution == 2 {
                features.append("7→3 (全音下行)")
            }
        }
        
        // Count common tones
        let common = Set(v1.notes).intersection(Set(v2.notes)).count
        if common > 0 {
            features.append("\(common)个共同音")
        }
        
        // Check voice motion
        let notes1 = v1.notes.sorted()
        let notes2 = v2.notes.sorted()
        let motions = zip(notes1, notes2).map { abs($1 - $0) }
        let maxMotion = motions.max() ?? 0
        let avgMotion = Double(motions.reduce(0, +)) / Double(motions.count)
        let movingVoices = motions.filter { $0 > 0 }.count
        
        if avgMotion <= 2 {
            features.append("平滑级进")
        } else if maxMotion > 5 {
            features.append("存在跳进")
        }
        
        // Inner movement analysis
        if movingVoices >= 2 && movingVoices <= 3 {
            features.append("良好声部流动")
        } else if movingVoices < 2 {
            features.append("声部变化不足")
        }
        
        // Cluster analysis
        let clusterCount = countClusterIntervals(v2.notes)
        if clusterCount > 1 {
            features.append("cluster过多(\(clusterCount))")
        }
        
        return TransitionAnalysis(
            fromChord: v1.chord.displayName,
            toChord: v2.chord.displayName,
            cost: cost,
            features: features
        )
    }
}

// MARK: - Analysis Types

enum VoiceLeadingQuality: String {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Needs Work"
}

struct TransitionAnalysis {
    let fromChord: String
    let toChord: String
    let cost: Double
    let features: [String]
}

struct VoiceLeadingAnalysis {
    let transitions: [TransitionAnalysis]
    let totalCost: Double
    let averageCost: Double
    let loopCost: Double?
    let quality: VoiceLeadingQuality
    
    var problemSpots: [(Int, String)] {
        var spots: [(Int, String)] = []
        for (i, transition) in transitions.enumerated() {
            if transition.cost > 10 {
                spots.append((i, "\(transition.fromChord) → \(transition.toChord): 需要改进"))
            }
        }
        if let loop = loopCost, loop > 10 {
            spots.append((transitions.count, "循环连接需要改进"))
        }
        return spots
    }
}
