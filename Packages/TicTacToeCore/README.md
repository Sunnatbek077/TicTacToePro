# TicTacToeCore

Platform-agnostic game logic shared by the iOS, visionOS and watchOS targets.

## Why this package exists

The three app targets each carried their own hand-copied version of the same
source files — roughly 4,150 lines were byte-identical duplicates, and the rest
had quietly drifted apart. The drift was not cosmetic:

- `winLength` on watchOS was `boardSize`, so a 5x5 game needed **five** in a row
  on the watch but **four** on iOS. The same match scored differently per device.
- The watchOS combination generator only produced full-length rows and columns,
  missing every offset line and offset diagonal.
- The watchOS minimax had no `maxDepth == 0` cutoff — `advancedHeuristic` was
  defined but never called — so the weakest device searched the deepest.

Every one of those came from a fix landing in one copy and not the others. This
package is the single source of truth so that cannot recur.

## Rules

1. **No UI frameworks.** Nothing here may `import SwiftUI`, `UIKit` or `WatchKit`.
   Being UI-free is what lets all three targets share it. If a type needs
   `@Published`, it belongs in the app layer, not here.
2. **Public API is deliberate.** Only what the apps actually call is `public`.
3. **Changes come with tests.** See `Tests/TicTacToeCoreTests`.

## Building and testing

```bash
swift build --package-path Packages/TicTacToeCore
swift test  --package-path Packages/TicTacToeCore
```

The package builds under the **Swift 6 language mode**, which is stricter than
the apps' current `SWIFT_VERSION = 5.0`. That strictness already caught one real
latent defect: `Board.zobristTable` was a `static var` — nonisolated global
mutable state, a data race waiting to happen once AI search moved off the main
thread. It is now a `static let`, which is what it always meant to be.

> **Note:** `swift test` needs full Xcode. With only Command Line Tools installed
> the test target compiles but cannot run, because `Testing.framework`'s runtime
> library ships with Xcode.

## Wiring it into the Xcode project

This has to be done in Xcode — editing `project.pbxproj` by hand to add a package
reference is error-prone and cannot be build-verified from the command line.

1. **File → Add Package Dependencies… → Add Local…** and select
   `Packages/TicTacToeCore`.
2. For **each** of the three app targets, open *General → Frameworks, Libraries,
   and Embedded Content* and add the `TicTacToeCore` library.
3. Add `import TicTacToeCore` to the files that use `Board`, `SquareStatus` or
   `AIDifficulty`.
4. **Only once the project builds**, delete the now-redundant per-target copies:
   - `TicTacToePro/ViewModels/GameLogicModel.swift`
   - `TicTacToePro-VisionOS/ViewModels/GameLogicModel.swift`
   - `TicTacToePro-WatchOS Watch App/ViewModels/GameLogicModel.swift`

   The project uses Xcode 16 synchronized groups (`objectVersion = 77`), so
   deleting the file on disk removes it from the build — no `.pbxproj` edit needed.

Do not delete the copies before step 3 succeeds, or all three targets stop compiling.

## What still needs migrating

This package currently holds the pure-logic layer only. Still duplicated across
the three targets, in rough order of value:

| Candidate | Notes |
|---|---|
| `Square` | Currently declared *inside* `SquareCellView.swift` — a model type living in a view file. Extract before moving. |
| `GameViewModel`, `AppState` | Identical in all three targets. Need SwiftUI/Combine, so they belong in a separate `TicTacToeUI` package, not this one. |
| `MotionManager` | Identical, but already `#if os(iOS)`-gated; decide whether watch/vision need it at all. |
| `Localizable.xcstrings` | Three copies (232KB / 234KB / 236KB) that have already diverged. Consolidating these is high-value and independent of this package. |
| Settings views | `NeonLightView` and `CustomBackgroundView` are identical across all three. |
