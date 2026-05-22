module.exports = {
  presets: ['module:@react-native/babel-preset'],
  plugins: [
    [
      './scripts/babel-inline-env',
      {
        variables: ['HOT_UPDATER_BASE_URL'],
      },
    ],
  ],
};
