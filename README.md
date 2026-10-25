# CoAuthor

An iOS app built with SwiftUI and SwiftData.

## Requirements

- Xcode 16 or later
- iOS 18.1 or later

## Getting Started

1. Clone the repository:
   ```sh
   git clone <repo-url>
   cd CoAuthor
   ```
2. Open `CoAuthor.xcodeproj` in Xcode.
3. Select a simulator or device and press **Cmd+R** to build and run.

## Project Structure

- `CoAuthor/` — app source code (SwiftUI views, SwiftData models)
- `CoAuthorTests/` — unit tests
- `CoAuthorUITests/` — UI tests

## Testing

Run tests in Xcode with **Cmd+U**, or from the command line:

```sh
xcodebuild test -project CoAuthor.xcodeproj -scheme CoAuthor -destination 'platform=iOS Simulator,name=iPhone 16'
```

## License

Proprietary — see [LICENSE](LICENSE) for details.
