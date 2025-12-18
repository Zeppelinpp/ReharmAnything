# ReharmAnything 项目结构文档

> 为爵士乐手设计的 iOS 和弦重配和声应用

## 📁 项目目录结构

```
ReharmAnything/
├── ReharmAnything.xcodeproj/          # Xcode 项目配置
│   └── project.pbxproj
│
├── ReharmAnything/                     # 主应用代码
│   ├── ReharmAnythingApp.swift        # 应用入口
│   ├── ContentView.swift              # 根视图 (Tab 导航)
│   │
│   ├── Models/                        # 数据模型层
│   │   └── Chord.swift                # 和弦、Voicing、音符相关模型
│   │
│   ├── Services/                      # 业务逻辑层
│   │   ├── VoicingGenerator.swift     # Voicing 生成器
│   │   ├── VoiceLeading.swift         # Voice Leading 优化器
│   │   ├── ReharmStrategy.swift       # 重配和声策略
│   │   └── IrealParser.swift          # iReal Pro 解析器
│   │
│   ├── ViewModels/                    # 视图模型层
│   │   └── ChordViewModel.swift       # 主 ViewModel
│   │
│   ├── Views/                         # 视图层
│   │   ├── ChordInputView.swift       # 和弦输入界面
│   │   └── ReharmView.swift           # 重配和声主界面
│   │
│   ├── Audio/                         # 音频引擎层
│   │   ├── SoundFont.swift            # SoundFont 管理
│   │   ├── AudioEngine.swift          # 基础音频引擎
│   │   ├── HumanizedPlaybackEngine.swift  # 人性化播放引擎
│   │   ├── MusicHumanizer.swift       # 音乐人性化处理
│   │   └── RhythmPatternLibrary.swift # 节奏型库
│   │
│   ├── Theme/                         # 主题样式
│   │   └── NordicTheme.swift          # 北欧风格主题
│   │
│   ├── Resources/                     # 资源文件
│   │   ├── UprightPianoKW-20220221.sf2  # Grand Piano 音源
│   │   └── jRhodes3.sf2               # Rhodes 音源
│   │
│   └── Assets.xcassets/               # 图片资源
│
└── README.md                          # 项目说明
```

---

## 🏗️ 架构概览

采用 **MVVM** (Model-View-ViewModel) 架构模式：

```
┌─────────────────────────────────────────────────────────────────┐
│                           Views                                  │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │ ChordInputView  │  │   ReharmView    │  │   ContentView   │ │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘ │
│           │                    │                    │           │
│           └────────────────────┼────────────────────┘           │
│                                │                                 │
│                                ▼                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    ChordViewModel                         │  │
│  │  - originalProgression    - selectedVoicingType          │  │
│  │  - reharmedProgression    - selectedStrategy             │  │
│  │  - currentVoicings        - voiceLeadingAnalysis         │  │
│  └──────────────────────────────┬───────────────────────────┘  │
│                                 │                               │
├─────────────────────────────────┼───────────────────────────────┤
│                           Services                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │VoicingGenerator│  │VoiceLeading │  │   ReharmManager      │  │
│  │              │  │  Optimizer   │  │                      │  │
│  └──────────────┘  └──────────────┘  └──────────────────────┘  │
│                                                                 │
│  ┌──────────────┐  ┌──────────────────────────────────────┐    │
│  │ IrealParser  │  │         Audio System                 │    │
│  └──────────────┘  │  ┌────────────────────────────────┐ │    │
│                    │  │ HumanizedPlaybackEngine        │ │    │
│                    │  │   ├─ MusicHumanizer            │ │    │
│                    │  │   ├─ RhythmPatternLibrary      │ │    │
│                    │  │   └─ SoundFontManager          │ │    │
│                    │  └────────────────────────────────┘ │    │
│                    └──────────────────────────────────────┘    │
├─────────────────────────────────────────────────────────────────┤
│                            Models                               │
│  ┌────────────────────────────────────────────────────────────┐│
│  │ Chord, Voicing, ChordEvent, ChordProgression, VoicingType  ││
│  │ NoteName, ChordQuality, MIDINote                           ││
│  └────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

---

## 📦 核心模块详解

### 1. Models (`Models/Chord.swift`)

#### 基础类型

```swift
typealias MIDINote = Int  // MIDI 音符编号 (0-127)
```

#### VoicingType (Voicing 风格)

```swift
enum VoicingType: String, CaseIterable {
    case rootlessA = "Rootless A"   // Bill Evans A型: 3-5-7-9
    case rootlessB = "Rootless B"   // Bill Evans B型: 7-9-3-5
    case quartal = "Quartal"        // McCoy Tyner: 四度叠置
    case drop2 = "Drop 2"           // 第二声部下移八度
    case drop3 = "Drop 3"           // 第三声部下移八度
    case shell = "Shell"            // 根音-三音-七音
}
```

#### NoteName (音名)

```swift
enum NoteName: String, CaseIterable {
    case C, Db, D, Eb, E, F, Gb, G, Ab, A, Bb, B
    
    var pitchClass: Int { ... }  // 0-11
    static func from(pitchClass: Int) -> NoteName
    static func parse(_ str: String) -> NoteName?
}
```

#### ChordQuality (和弦性质)

```swift
enum ChordQuality: String, Codable {
    case major = ""
    case minor = "-"
    case dominant7 = "7"
    case major7 = "maj7"
    case minor7 = "-7"
    case halfDiminished = "-7b5"
    case diminished7 = "dim7"
    // ... 更多
    
    var intervals: [Int] { ... }  // 音程列表
    var isDominant: Bool { ... }
}
```

#### Chord (和弦)

```swift
struct Chord: Identifiable, Codable, Equatable {
    let id: UUID
    let root: NoteName
    let quality: ChordQuality
    let bass: NoteName?           // 斜杠和弦的低音
    let extensions: [String]      // 扩展音 (b9, #11, dimStack 等)
    
    var displayName: String       // 显示名称
    var isDominant: Bool
    func pitchClasses() -> [Int]  // 获取所有音级
}
```

#### Voicing (配置)

```swift
struct Voicing: Equatable {
    let chord: Chord
    let notes: [MIDINote]         // 所有 MIDI 音符
    var voicingType: VoicingType?
    var leftHandNotes: [MIDINote]  // 左手音符 (低音区)
    var rightHandNotes: [MIDINote] // 右手音符 (高音区)
    
    var bassNote: MIDINote?       // 最低音
    var topNote: MIDINote?        // 最高音
    var center: Double            // 中心音高
    var spread: Int               // 音域跨度
    
    func thirdNote() -> MIDINote?   // 获取三音
    func seventhNote() -> MIDINote? // 获取七音
    func voiceLeadingDistance(to other: Voicing) -> Int
}
```

#### ChordEvent & ChordProgression

```swift
struct ChordEvent: Identifiable, Codable {
    let chord: Chord
    let startBeat: Double
    let duration: Double
}

struct ChordProgression: Identifiable, Codable {
    let title: String
    var events: [ChordEvent]
    var tempo: Double
    var totalBeats: Double
}
```

---

### 2. VoicingGenerator (`Services/VoicingGenerator.swift`)

**职责**: 根据和弦类型和 Voicing 风格生成具体的 MIDI 音符配置

#### 核心结构

```swift
struct TwoHandVoicing {
    let leftHand: [Int]   // 左手音程 (相对于根音)
    let rightHand: [Int]  // 右手音程
    let description: String
}
```

#### 关键方法

```swift
class VoicingGenerator {
    // Voicing 字典: [和弦性质: [Voicing类型: [模板]]]
    private var voicingDictionary: [ChordQuality: [VoicingType: [TwoHandVoicing]]]
    
    // 生成单个 Voicing
    func generateVoicing(
        for chord: Chord,
        type: VoicingType,
        targetRegister: MIDINote = 54
    ) -> Voicing
    
    // 生成 Diminished Stack Polychord Voicing
    // C7 -> C triad + A triad (C-E-G + A-C#-E)
    func generateDiminishedStackVoicing(
        for dominantChord: Chord,
        useMajorTriads: Bool = true
    ) -> Voicing
    
    // 生成所有变体 (不同八度、转位)
    func generateAllVariants(
        for chord: Chord,
        type: VoicingType,
        targetRegister: MIDINote = 54
    ) -> [Voicing]
    
    // Voicing 变换
    func invertVoicing(_ voicing: Voicing, times: Int = 1) -> Voicing?
    func transposeVoicing(_ voicing: Voicing, semitones: Int) -> Voicing?
}
```

#### Voicing 字典示例

```swift
// Dominant7 的 Rootless A 模板
voicingDictionary[.dominant7] = [
    .rootlessA: [
        TwoHandVoicing(
            leftHand: [0, 10],           // Root + b7
            rightHand: [4, 9, 14],       // 3-13-9
            description: "Shell + 3-13-9"
        ),
        // ... 更多模板
    ],
    // ... 其他 VoicingType
]
```

---

### 3. VoiceLeadingOptimizer (`Services/VoiceLeading.swift`)

**职责**: 优化和弦进行中的 Voice Leading，找到最平滑的连接

#### Cost Function 权重

```swift
struct CostWeights {
    // 奖励 (负值)
    var seventhToThird: Double = -15.0    // 7音解决到3音
    var halfStepMotion: Double = -3.0     // 半音进行
    var wholeStepMotion: Double = -1.0    // 全音进行
    var commonTone: Double = -5.0         // 共同音保持
    var contraryMotion: Double = -2.0     // 反向进行
    var innerMovementBonus: Double = -4.0 // 声部流动奖励
    
    // 惩罚 (正值)
    var largeLeap: Double = 2.0           // 大跳
    var parallelFifths: Double = 20.0     // 平行五度
    var parallelOctaves: Double = 20.0    // 平行八度
    var voiceCrossing: Double = 15.0      // 声部交叉
    var voiceOverlap: Double = 8.0        // 声部重叠
    var outOfRange: Double = 10.0         // 超出范围
    var clusterPenalty: Double = 12.0     // cluster 过多
    var staticVoicingPenalty: Double = 8.0 // 声部过于静止
}
```

#### 核心方法

```swift
class VoiceLeadingOptimizer {
    // 计算两个 Voicing 之间的 Voice Leading 代价
    func calculateCost(from v1: Voicing, to v2: Voicing) -> Double
    
    // 为下一个和弦找到最佳 Voicing
    func findBestVoicing(
        for chord: Chord,
        after previousVoicing: Voicing?,
        voicingType: VoicingType = .rootlessA
    ) -> Voicing
    
    // 优化整个和弦进行 (动态规划)
    func optimizeProgression(
        _ progression: ChordProgression,
        voicingType: VoicingType = .rootlessA,
        forLoop: Bool = true
    ) -> [Voicing]
    
    // 分析 Voice Leading 质量
    func analyzeVoiceLeading(_ voicings: [Voicing], isLoop: Bool = true) -> VoiceLeadingAnalysis
}
```

#### 优化算法

1. **动态规划全局优化** (`optimizeGlobal`)
   - 为每个和弦生成所有候选 Voicing
   - 过滤掉 spread 过大或 cluster 过多的
   - 使用 DP 找到最优路径

2. **循环优化** (`optimizeForLoop`)
   - 确保最后一个 Voicing 能平滑连接回第一个

3. **Spread 归一化** (`normalizeVoicingSpread`)
   - 减少 Voicing 跨度的剧烈变化

---

### 4. ReharmStrategy (`Services/ReharmStrategy.swift`)

**职责**: 定义和应用重配和声策略

#### 策略协议

```swift
protocol ReharmStrategy {
    var name: String { get }
    var description: String { get }
    func canApply(to chord: Chord) -> Bool
    func apply(to chord: Chord) -> [Chord]
}
```

#### 内置策略

| 策略 | 说明 | 示例 |
|------|------|------|
| `TritoneSubstitution` | 三全音替代 | G7 → Db7 |
| `DiminishedStackStrategy` | Diminished Stack (Polychord) | C7 → C+A (同时发声) |
| `RelatedIIVStrategy` | 相关 ii-V 插入 | G7 → D-7 G7 |
| `BackdoorDominantStrategy` | Backdoor 属和弦 | G7 → F7 |

#### DiminishedStack 特殊处理

```swift
// DiminishedStackStrategy 不拆分和弦，而是添加标记
func apply(to chord: Chord) -> [Chord] {
    return [Chord(
        root: chord.root,
        quality: chord.quality,
        extensions: chord.extensions + ["dimStack"]  // 添加标记
    )]
}

// VoicingGenerator 检测标记并生成 Polychord Voicing
if chord.extensions.contains("dimStack") {
    return generateDiminishedStackVoicing(for: chord)
}
```

#### ReharmManager

```swift
class ReharmManager: ObservableObject {
    static let shared = ReharmManager()
    
    @Published var availableStrategies: [any ReharmStrategy]
    @Published var selectedStrategy: (any ReharmStrategy)?
    
    func registerStrategy(_ strategy: any ReharmStrategy)
    func applyReharm(to progression: ChordProgression, strategy: any ReharmStrategy) -> ChordProgression
    func applyToAllDominants(progression: ChordProgression, strategy: any ReharmStrategy) -> ChordProgression
}
```

---

### 5. IrealParser (`Services/IrealParser.swift`)

**职责**: 解析 iReal Pro URL/HTML 和简单文本格式的和弦谱

#### 主要方法

```swift
class IrealParser {
    // 解析 iReal Pro URL
    func parseIrealURL(_ urlString: String) -> ChordProgression?
    
    // 解析 iReal HTML
    func parseIrealHTML(_ html: String) -> [ChordProgression]
    
    // 解析简单文本格式 (空格/换行分隔)
    func parseSimpleChart(_ text: String) -> ChordProgression?
    
    // 解析单个和弦符号
    func parseChordSymbol(_ symbol: String) -> Chord?
    
    // 识别 Reharm 目标 (属和弦)
    func identifyReharmTargets(in progression: ChordProgression) -> [Int]
}
```

#### 支持的和弦格式

```
Cmaj7, C-7, C7, Cdim7, C-7b5, Caug, Csus4
C7alt, C9, C13, C-9, Cmaj9
C/E (斜杠和弦)
C7(b9), C7(#11) (扩展音)
```

---

### 6. Audio System

#### 6.1 SoundFontManager (`Audio/SoundFont.swift`)

```swift
enum SoundFontType: String, CaseIterable {
    case grandPiano = "Grand Piano"
    case rhodes = "Rhodes"
    
    var sf2FileName: String { ... }
}

class SoundFontManager: ObservableObject {
    static let shared = SoundFontManager()
    
    func initialize() async
    func selectSource(_ type: SoundFontType)
    func playChord(_ voicing: Voicing, velocity: UInt8 = 80)
    func stopChord(_ voicing: Voicing)
    func stopAll()
}
```

#### 6.2 HumanizedPlaybackEngine (`Audio/HumanizedPlaybackEngine.swift`)

```swift
class HumanizedPlaybackEngine: ObservableObject {
    @Published var isPlaying: Bool
    @Published var currentBeat: Double
    @Published var selectedStyle: MusicStyle
    @Published var selectedPattern: RhythmPattern?
    
    func setProgression(_ progression: ChordProgression, voicings: [Voicing])
    func play()
    func pause()
    func stop()
    
    func setStyle(_ style: MusicStyle)
    func setPattern(_ pattern: RhythmPattern?)
    func applyPreset(_ preset: HumanizationPreset)
}
```

#### 6.3 MusicHumanizer (`Audio/MusicHumanizer.swift`)

```swift
struct HumanizerConfig {
    var timingJitter: Double      // 时间随机偏移
    var velocityJitter: Int       // 力度随机偏移
    var durationJitter: Double    // 时值随机偏移
    var legato: Double            // 连音程度
    var accentPattern: [Double]   // 重音模式
    var handSeparation: Double    // 双手时间差
    var rollChords: Bool          // 琶音效果
    
    static let natural, tight, loose, expressive: HumanizerConfig
}

class MusicHumanizer {
    func humanize(note: NoteEvent, beatInBar: Int) -> NoteEvent
    func generateNoteEvents(from: ChordProgression, voicings: [Voicing], pattern: RhythmPattern?) -> [NoteEvent]
}
```

#### 6.4 RhythmPatternLibrary (`Audio/RhythmPatternLibrary.swift`)

```swift
enum MusicStyle: String, CaseIterable {
    case swing, bossa, ballad, latin, funk, gospel, stride
    
    var defaultTempo: Double { ... }
    var humanizer: HumanizerConfig { ... }
}

struct RhythmPattern {
    let name: String
    let style: MusicStyle
    let lengthInBeats: Double
    let hits: [RhythmHit]
    let swingFactor: Double
}

class RhythmPatternLibrary {
    static let shared = RhythmPatternLibrary()
    func getPatterns(for style: MusicStyle) -> [RhythmPattern]
}
```

---

### 7. ChordViewModel (`ViewModels/ChordViewModel.swift`)

**职责**: 连接 Views 和 Services，管理应用状态

#### 主要属性

```swift
@MainActor
class ChordViewModel: ObservableObject {
    // 进行状态
    @Published var originalProgression: ChordProgression?
    @Published var reharmedProgression: ChordProgression?
    @Published var currentVoicings: [Voicing] = []
    @Published var reharmTargets: [Int] = []
    
    // UI 状态
    @Published var isPlaying = false
    @Published var selectedStrategy: Int = 0
    @Published var selectedVoicingType: VoicingType = .rootlessA
    @Published var selectedSoundFont: SoundFontType = .grandPiano
    @Published var tempo: Double = 120
    @Published var isLooping = true
    
    // Humanization
    @Published var selectedStyle: MusicStyle = .swing
    @Published var selectedPattern: RhythmPattern?
    @Published var humanizationEnabled = true
    
    // 分析
    @Published var voiceLeadingAnalysis: VoiceLeadingAnalysis?
}
```

#### 主要方法

```swift
// 初始化
func initializeAudio() async

// 导入
func importChart()
func importFromHTML(_ html: String)

// Reharm
func applyReharm()
func resetToOriginal()

// 播放
func play()
func pause()
func stop()
func togglePlayback()

// 设置
func selectSoundFont(_ type: SoundFontType)
func changeVoicingType(_ type: VoicingType)
func updateTempo(_ newTempo: Double)

// Humanization
func setMusicStyle(_ style: MusicStyle)
func setRhythmPattern(_ pattern: RhythmPattern?)
func setHumanizationPreset(_ preset: HumanizationPreset)

// 预览
func previewChord(at index: Int)
func loadSampleProgression()
func loadAutumnLeaves()
func loadAllTheThings()
```

---

## 🔄 数据流

### 1. 和弦导入流程

```
用户输入 (iReal URL / 文本)
    │
    ▼
IrealParser.parseSimpleChart() / parseIrealURL()
    │
    ▼
ChordProgression
    │
    ▼
VoiceLeadingOptimizer.optimizeProgression()
    │
    ▼
[Voicing] (优化后的 Voicing 序列)
    │
    ▼
ChordViewModel.currentVoicings
    │
    ▼
ReharmView 显示
```

### 2. Reharm 应用流程

```
用户选择策略 → 点击 Apply
    │
    ▼
ReharmManager.applyToAllDominants()
    │
    ├─→ TritoneSubstitution: G7 → Db7
    ├─→ DiminishedStackStrategy: G7 → G7[dimStack]
    ├─→ RelatedIIVStrategy: G7 → D-7 G7
    └─→ BackdoorDominantStrategy: G7 → F7
    │
    ▼
新的 ChordProgression
    │
    ▼
VoiceLeadingOptimizer.optimizeProgression()
    │
    ├─→ 检测 dimStack 标记
    │   └─→ VoicingGenerator.generateDiminishedStackVoicing()
    │
    └─→ 普通和弦
        └─→ VoicingGenerator.generateAllVariants()
    │
    ▼
[Voicing] (新的 Voicing 序列)
```

### 3. 播放流程

```
用户点击 Play
    │
    ▼
HumanizedPlaybackEngine.play()
    │
    ├─→ MusicHumanizer.generateNoteEvents()
    │   ├─→ 应用 RhythmPattern
    │   ├─→ 应用 Humanization (timing, velocity jitter)
    │   └─→ 应用手部分离
    │
    ▼
[NoteEvent] (时间戳 + MIDI 音符)
    │
    ▼
Timer tick (10ms)
    │
    ▼
SoundFontManager.playChord() / stopChord()
    │
    ▼
AVAudioEngine + AVAudioUnitSampler
```

---

## 🎨 UI 组件

### Views 结构

```
ContentView
├── appHeader (标题 + 状态指示)
├── TabView
│   ├── ChordInputView (tab 0)
│   │   ├── 文本输入框
│   │   ├── 示例按钮 (ii-V-I, Autumn Leaves, All The Things)
│   │   └── 导入按钮
│   │
│   └── ReharmView (tab 1)
│       ├── headerSection (标题 + Reharmonized 标记)
│       ├── progressionSection (和弦网格)
│       ├── pianoKeyboardSection (钢琴键盘可视化)
│       ├── reharmControlsSection (策略选择 + Apply)
│       ├── humanizationSection (风格 + 节奏型 + Feel)
│       ├── settingsSection (音色 + Voicing + Tempo + Loop)
│       └── playbackControlsSection (进度条 + 播放控制)
│
└── customTabBar (Charts / Reharm 切换)
```

### 主要 UI 组件

| 组件 | 用途 |
|------|------|
| `ChordCell` | 单个和弦显示 (支持 Polychord 显示) |
| `PianoKeyboardView` | 钢琴键盘 Voicing 可视化 |
| `StrategyButton` | Reharm 策略选择 |
| `VoicingTypeButton` | Voicing 风格选择 |
| `StyleButton` | 音乐风格选择 |
| `PatternButton` | 节奏型选择 |
| `PresetButton` | Humanization 预设选择 |

---

## 🔧 扩展指南

### 添加新的 Reharm 策略

```swift
// 1. 创建新策略类
class MyNewStrategy: ReharmStrategy {
    let name = "My Strategy"
    let description = "Description"
    
    func canApply(to chord: Chord) -> Bool {
        // 判断条件
    }
    
    func apply(to chord: Chord) -> [Chord] {
        // 返回新和弦
    }
}

// 2. 注册到 ReharmManager
ReharmManager.shared.registerStrategy(MyNewStrategy())
```

### 添加新的 Voicing 类型

```swift
// 1. 在 VoicingType 枚举中添加
enum VoicingType {
    // ...
    case myNewVoicing = "My Voicing"
}

// 2. 在 VoicingGenerator.buildVoicingDictionary() 中添加模板
voicingDictionary[.dominant7]?[.myNewVoicing] = [
    TwoHandVoicing(
        leftHand: [0, 10],
        rightHand: [4, 7, 14],
        description: "My custom voicing"
    )
]
```

### 添加新的节奏型

```swift
// 在 RhythmPatternLibrary 中添加
private var myPatterns: [RhythmPattern] {
    [
        RhythmPattern(
            name: "My Pattern",
            style: .swing,
            lengthInBeats: 4,
            hits: [
                RhythmHit(0.0, velocity: 1.0, type: .fullChord),
                RhythmHit(2.0, velocity: 0.8, type: .rightHand)
            ],
            swingFactor: 0.33,
            description: "My custom pattern"
        )
    ]
}
```

### 添加新的音源

```swift
// 1. 在 SoundFontType 中添加
enum SoundFontType {
    // ...
    case wurlitzer = "Wurlitzer"
    
    var sf2FileName: String {
        switch self {
        case .wurlitzer: return "Wurlitzer"
        // ...
        }
    }
}

// 2. 将 SF2 文件添加到 Resources 目录
// 3. 在 Xcode 中将文件添加到 target
```

---

## 📝 关键概念

### Voice Leading 原则

1. **7→3 解决**: 属和弦的 7 音解决到下一个和弦的 3 音
2. **共同音保持**: 相邻和弦的共同音保持不动
3. **最小移动**: 其他声部尽量半音或全音移动
4. **避免平行 5 度/8 度**: 传统和声禁忌
5. **避免声部交叉**: 低声部不应跨越高声部

### Diminished Stack (减音程叠加)

- **原理**: 属和弦 = 根音三和弦 + 下方小三度三和弦
- **示例**: C7 = C大三和弦 + A大三和弦 (C-E-G + A-C#-E)
- **效果**: 创造更丰富的属和弦色彩

### 双手 Voicing

- **左手**: 通常弹 Root + 7th (Shell) 或低音区三和弦
- **右手**: 弹 Extensions (3-5-9, 7-9-3 等)
- **分离**: 左手在 C3 附近，右手在 E4 附近

---

## 🐛 调试技巧

### 打印 Voicing 信息

```swift
let voicing = voicingGenerator.generateVoicing(for: chord, type: .rootlessA)
print("Notes: \(voicing.notesDescription())")
let hands = voicing.handsDescription()
print("LH: \(hands.left), RH: \(hands.right)")
```

### 分析 Voice Leading

```swift
let analysis = voiceLeadingOptimizer.analyzeVoiceLeading(voicings)
print("Quality: \(analysis.quality)")
print("Average Cost: \(analysis.averageCost)")
for transition in analysis.transitions {
    print("\(transition.fromChord) → \(transition.toChord): \(transition.features)")
}
```

---

*最后更新: 2024-12*

