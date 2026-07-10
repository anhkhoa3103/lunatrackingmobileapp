class ApiConfig {
  static const _env = String.fromEnvironment(
      'ENV', defaultValue: 'web');

  static String get baseUrl {
    switch (_env) {
      case 'emulator':
        return 'http://10.0.2.2:8080/api';  
      case 'device':
        return 'http://192.168.1.181:8080/api';
      case 'web':
      default:
        return 'http://localhost:8080/api';
    }
  }
}