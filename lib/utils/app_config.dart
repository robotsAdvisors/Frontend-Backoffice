/// Configuración de comportamiento de la app (independiente de la red).
class AppConfig {
  AppConfig._();

  /// Habilita los datos de demostración de [DummyHelper] como bootstrap y como
  /// fallback cuando el backend falla o devuelve vacío.
  ///
  /// Por defecto va en **false**: en un build real, un usuario nunca ve tiendas,
  /// códigos, PINs, clientes ni productos ficticios; las pantallas caen a
  /// estados vacíos o al error real del backend.
  ///
  /// Para demos/offline en desarrollo, actívalo al compilar:
  ///   flutter run --dart-define=LETDEM_USE_DUMMY_DATA=true
  static const bool useDummyData =
      bool.fromEnvironment('LETDEM_USE_DUMMY_DATA', defaultValue: false);
}
