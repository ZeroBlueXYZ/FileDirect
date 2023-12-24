# FileDirect

[Homepage](https://filedirect.zeroblue.xyz/)

FileDirect is a free and open-source app that helps you share and receives files with nearby and remote devices.

## Contribution

We welcome anyone interested in helping to improve FileDirect. If you are interested, considered the following options to get you started.

### Translation

Help add more languages to make FileDirect avaiable to a wider audience.

1. Clone the repository.
2. Add new locale in `lib/l10n` by copying the English locale file `app_en.arb` and renaming it to the target locale. Check [locale codes](https://saimana.com/list-of-country-locale-code/) for a full list of locales.
3. Translate the English content to the target language.
4. Create a [pull request](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests) to propose your changes.

More, help translate the [website](https://github.com/ZeroBlueXYZ/FileDirect-Website) as well.

### Bug Fixes

If you find a bug and create a fix, please create a [pull request](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests) to propose your changes.

### Bug Reports and Feature Requests

If you want to report bugs or request features, please create an [issue](https://github.com/ZeroBlueXYZ/FileDirect/issues) with clear description of the issue or feature.

## Development

### Getting Started

```
flutter run
```

### Useful Commands
- Generate localizations
```
flutter gen-l10n
```
- Sort imports
```
dart run import_sorter:main
```
- Generate JSON serializable code
```
dart run build_runner build --delete-conflicting-outputs
```

### References
- [Material Theme Builder](https://m3.material.io/theme-builder)
- [Internationalization in Flutter](https://docs.flutter.dev/ui/accessibility-and-localization/internationalization)
- [Continuous Deployment to Miscrosoft Store](https://docs.flutter.dev/deployment/windows#github-actions-cicd)
