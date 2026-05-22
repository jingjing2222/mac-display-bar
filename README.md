# mac-display-bar

Open-source BetterDisplay-style macOS display control app scaffolded with React Native for macOS.

This app is macOS-only. The default React Native `ios/` and `android/` targets are intentionally removed.

## Stack

- React Native `0.81.6`
- React Native macOS `^0.81.0-0` (`0.81.7` resolved)
- Yarn `4.13.0`
- CocoaPods for macOS native dependencies

## Setup

```sh
yarn install
pod install --project-directory=macos
```

## Run

Terminal 1:

```sh
yarn start
```

Terminal 2:

```sh
yarn macos
```

## Build

```sh
yarn build:macos
```

## Notes

React Native for macOS is an out-of-tree platform. The current official setup flow is:

1. Create a React Native app with `@react-native-community/cli init`.
2. Keep `react-native` and `react-native-macos` on the same minor version.
3. Add macOS support with `react-native-macos-init`.

This repo follows that flow, then removes the generated iOS and Android targets. `react-native.config.js` disables those platforms and keeps `macos/` as the only native app target.
