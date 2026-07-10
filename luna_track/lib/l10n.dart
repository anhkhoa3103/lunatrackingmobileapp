import 'l10n/app_localizations.dart';

export 'l10n/app_localizations.dart';

/// Maps canonical option values (as stored in the API / Hive, e.g. 'Medium',
/// 'Back pain') to their localized display labels. Stored values themselves
/// are never translated.
extension OptionLabels on AppLocalizations {
  String optionLabel(String canonical) {
    switch (canonical.toLowerCase()) {
      case 'none':
        return none;
      case 'light':
        return light;
      case 'medium':
        return medium;
      case 'heavy':
        return heavy;
      case 'low':
        return low;
      case 'high':
        return high;
      case 'poor':
        return poor;
      case 'ok':
        return ok;
      case 'good':
        return good;
      case 'happy':
        return happy;
      case 'calm':
        return calm;
      case 'anxious':
        return anxious;
      case 'sad':
        return sad;
      case 'irritable':
        return irritable;
      case 'tired':
        return tired;
      case 'cramps':
        return cramps;
      case 'headache':
        return headache;
      case 'bloating':
        return bloating;
      case 'back pain':
        return backPain;
      case 'nausea':
        return nausea;
      case 'fatigue':
        return fatigue;
      default:
        return canonical;
    }
  }
}
