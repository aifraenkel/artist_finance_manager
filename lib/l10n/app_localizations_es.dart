// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Art Finance Hub';

  @override
  String get income => 'Ingresos';

  @override
  String get expenses => 'Gastos';

  @override
  String get balance => 'Saldo';

  @override
  String get projects => 'Proyectos';

  @override
  String get dashboard => 'Panel';

  @override
  String get profile => 'Perfil';

  @override
  String get settings => 'Configuración';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get email => 'Correo electrónico';

  @override
  String get password => 'Contraseña';

  @override
  String get name => 'Nombre';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get delete => 'Eliminar';

  @override
  String get edit => 'Editar';

  @override
  String get add => 'Agregar';

  @override
  String get loading => 'Cargando';

  @override
  String get preferences => 'Preferencias';

  @override
  String get language => 'Idioma';

  @override
  String get currency => 'Moneda';

  @override
  String get updateCurrency => 'Actualizar moneda';

  @override
  String get changeCurrency => 'Cambiar moneda';

  @override
  String get budgetGoal => 'Objetivo de presupuesto';

  @override
  String get profileAndSettings => 'Perfil y configuración';

  @override
  String get addTransaction => 'Agregar transacción';

  @override
  String get transactionHistory => 'Historial de transacciones';

  @override
  String get noTransactionsYet =>
      'Aún no hay transacciones. ¡Agrega tu primera arriba!';

  @override
  String get viewAnalytics => 'Ver análisis';

  @override
  String get createProject => 'Crear proyecto';

  @override
  String get amount => 'Monto';

  @override
  String get description => 'Descripción';

  @override
  String get category => 'Categoría';

  @override
  String get selectCategory => 'Seleccionar categoría';

  @override
  String get expense => 'Gasto';

  @override
  String get incomeType => 'Ingreso';

  @override
  String get type => 'Tipo';

  @override
  String get venue => 'Lugar';

  @override
  String get musicians => 'Músicos';

  @override
  String get foodAndDrinks => 'Comida y bebidas';

  @override
  String get materialsClothes => 'Materiales/Ropa';

  @override
  String get bookPrinting => 'Impresión de libros';

  @override
  String get podcast => 'Podcast';

  @override
  String get other => 'Otro';

  @override
  String get bookSales => 'Ventas de libros';

  @override
  String get eventTickets => 'Entradas para eventos';

  @override
  String get deleteTransaction => 'Eliminar transacción';

  @override
  String get deleteTransactionConfirm =>
      '¿Estás seguro de que deseas eliminar esta transacción?';

  @override
  String get renameProject => 'Renombrar proyecto';

  @override
  String get rename => 'Renombrar';

  @override
  String get deleteProject => 'Eliminar proyecto';

  @override
  String get deleteProjectConfirm =>
      '¿Estás seguro de que deseas eliminar este proyecto?';

  @override
  String get create => 'Crear';

  @override
  String get createAccount => 'Crear cuenta';

  @override
  String get sendSignInLink => 'Enviar enlace de inicio de sesión';

  @override
  String get backToLogin => 'Volver al inicio de sesión';

  @override
  String get resendEmail => 'Reenviar correo';

  @override
  String get deleteAccount => 'Eliminar cuenta';

  @override
  String get deleteAccountWarning =>
      'Esta acción no se puede deshacer. ¿Estás seguro de que deseas eliminar tu cuenta?';

  @override
  String get deleteAccountDetails => 'Esto hará:';

  @override
  String get deleteAccountRemoveAccess => '• Eliminará el acceso a tu cuenta';

  @override
  String get deleteAccountDeleteData =>
      '• Borrará permanentemente todos tus datos';

  @override
  String get analyticsDashboard => 'Panel de análisis';

  @override
  String get analyzeGoal => 'Analizar objetivo';

  @override
  String get changeCurrencyWarning =>
      'Cambiar la moneda convertirá todos los montos de las transacciones.';

  @override
  String get accept => 'Aceptar';

  @override
  String get essentialOnly => 'Solo esenciales';

  @override
  String get totalIncome => 'Ingresos totales';

  @override
  String get totalExpenses => 'Gastos totales';

  @override
  String get createProjectToStart =>
      'Crea un proyecto para empezar\na gestionar tus finanzas';

  @override
  String get projectName => 'Nombre del proyecto';

  @override
  String get enterProjectName => 'Ingresa el nombre del proyecto';

  @override
  String get projectNameTooLong =>
      'El nombre del proyecto debe tener como máximo 50 caracteres.';

  @override
  String get projectCreatedSuccess => 'Proyecto \"\$name\" creado';

  @override
  String get failedToCreateProject => 'Error al crear proyecto: \$error';

  @override
  String get projectRenamedSuccess => 'Proyecto renombrado a \"\$name\"';

  @override
  String get failedToRenameProject => 'Error al renombrar proyecto: \$error';

  @override
  String get deleteProjectWarning =>
      '¿Estás seguro de que deseas eliminar \"\$name\"?\n\nTodas las transacciones de este proyecto se perderán. Esta acción no se puede deshacer.';

  @override
  String get projectDeletedSuccess => 'Proyecto \"\$name\" eliminado';

  @override
  String get failedToDeleteProject => 'Error al eliminar proyecto: \$error';

  @override
  String get noDataAvailable => 'No hay datos disponibles';

  @override
  String get addTransactionsToSeeAnalytics =>
      'Agrega algunas transacciones para ver el análisis';

  @override
  String get failedToLoadUserPreferences =>
      'Error al cargar las preferencias del usuario';

  @override
  String get profileUpdatedSuccess => 'Perfil actualizado correctamente';

  @override
  String get failedToUpdateProfile => 'Error al actualizar el perfil';

  @override
  String get signOutConfirm => '¿Estás seguro de que deseas cerrar sesión?';

  @override
  String get deleteAccountKeepData =>
      '• Guardaremos tus datos durante 90 días por si cambias de opinión';

  @override
  String get recoverAccountInfo =>
      'Puedes recuperar tu cuenta dentro de los 90 días iniciando sesión nuevamente';

  @override
  String get failedToDeleteAccount => 'Error al eliminar la cuenta';

  @override
  String get projectsExportedSuccess => 'Proyectos exportados correctamente';

  @override
  String get failedToExport => 'Error al exportar';

  @override
  String get budgetGoalCleared => 'Objetivo de presupuesto eliminado';

  @override
  String get budgetGoalSavedSuccess =>
      'Objetivo de presupuesto guardado correctamente';

  @override
  String get openaiApiKeyCleared => 'Clave API de OpenAI eliminada';

  @override
  String get openaiApiKeySavedSuccess =>
      'Clave API de OpenAI guardada correctamente';

  @override
  String get failedToSaveApiKey => 'Error al guardar la clave API';

  @override
  String get languageUpdatedTo => 'Idioma actualizado a';

  @override
  String get failedToUpdateLanguage => 'Error al actualizar el idioma';

  @override
  String get currencyChangeDescription =>
      'actualizará el símbolo de moneda que se muestra en la aplicación.';

  @override
  String get currencyRateInfo =>
      'La tasa de conversión del Banco Central Europeo (a través de la API de Frankfurter) se obtendrá y almacenará para su referencia.';

  @override
  String get noteNoConvertExistingAmounts =>
      'Nota: Esto no convierte los montos de transacciones existentes';

  @override
  String get currencyUpdatedWithRate => 'Moneda actualizada a';

  @override
  String get failedToUpdateCurrency => 'Error al actualizar la moneda';

  @override
  String get pleaseEnterYourName => 'Por favor ingresa tu nombre';

  @override
  String get nameMinimumLength => 'El nombre debe tener al menos 2 caracteres';

  @override
  String get editProfile => 'Editar perfil';

  @override
  String get accountInformation => 'Información de la cuenta';

  @override
  String get memberSince => 'Miembro desde';

  @override
  String get lastLogin => 'Último inicio de sesión';

  @override
  String get loginCount => 'Número de inicios de sesión';

  @override
  String get privacyAndData => 'Privacidad y datos';

  @override
  String get analytics => 'Análisis';

  @override
  String get analyticsHelperText =>
      'Ayuda a mejorar la aplicación compartiendo datos de uso anónimos';

  @override
  String get analyticsEnabledThankYou => 'Análisis activado - ¡gracias!';

  @override
  String get analyticsDisabled => 'Análisis desactivado';

  @override
  String get whatDataDoWeCollect => '¿Qué datos recopilamos?';

  @override
  String get financialGoal => 'Objetivo financiero';

  @override
  String get financialGoalHint =>
      'ej., Quiero tener un saldo positivo de 200€ por mes';

  @override
  String get financialGoalHelper =>
      'Describe tu objetivo financiero en lenguaje natural';

  @override
  String get goalActive => 'Objetivo activo';

  @override
  String get goalActiveHelper =>
      'Activa el objetivo para ver el análisis en el panel';

  @override
  String get saveGoal => 'Guardar objetivo';

  @override
  String get noBudgetGoalSet =>
      'No se ha establecido ningún objetivo de presupuesto';

  @override
  String get active => 'Activo';

  @override
  String get inactive => 'Inactivo';

  @override
  String get setBudgetGoal => 'Establecer objetivo de presupuesto';

  @override
  String get editBudgetGoal => 'Editar objetivo de presupuesto';

  @override
  String get openaiConfiguration => 'Configuración de OpenAI';

  @override
  String get openaiApiKey => 'Clave API de OpenAI';

  @override
  String get openaiApiKeyPlaceholder => 'sk-...';

  @override
  String get openaiApiKeyHelper =>
      'Requerido para el análisis de objetivos de presupuesto. Obtén tu clave en platform.openai.com';

  @override
  String get openaiApiKeySecurityInfo =>
      'Tu clave API se almacena localmente y nunca se comparte. Se utiliza solo para analizar tus objetivos de presupuesto.';

  @override
  String get accountActions => 'Acciones de cuenta';

  @override
  String get exportToCSV => 'Exportar a CSV';

  @override
  String get changingFrom => 'Cambiando de';

  @override
  String get privacyAnalyticsTitle => 'Privacidad y analítica';

  @override
  String get privacyAnalyticsIntro =>
      'Ayúdanos a mejorar la app compartiendo datos de analítica anónimos.';

  @override
  String get privacyAnalyticsCollect => 'Qué recopilamos:';

  @override
  String get privacyCollectTransactions =>
      'Eventos de transacciones (agregar/eliminar/cargar)';

  @override
  String get privacyCollectPerformance =>
      'Métricas de rendimiento (tiempos de carga, Web Vitals)';

  @override
  String get privacyCollectErrors => 'Seguimiento de errores';

  @override
  String get privacyCollectSessions => 'Analítica de sesiones';

  @override
  String get privacyAnalyticsNoCollect => 'Qué NO recopilamos:';

  @override
  String get privacyNoCollectAmounts => 'Montos de transacciones';

  @override
  String get privacyNoCollectDescriptions => 'Descripciones de transacciones';

  @override
  String get privacyNoCollectPersonal => 'Datos financieros personales';

  @override
  String get privacyChangeAnytime =>
      'Puedes cambiar esta preferencia en cualquier momento en Configuración.';

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String get privacyPolicyCallout =>
      'Nuestra Política de Privacidad explica cómo recopilamos, usamos y protegemos tus datos.\n\nPuntos clave:\n• La analítica está desactivada por defecto\n• Nunca rastreamos montos ni descripciones de transacciones\n• Tú controlas tus ajustes de privacidad\n• Puedes eliminar tus datos en cualquier momento\n\nPara ver la política completa, visita nuestro repositorio en GitHub:\ngithub.com/aifraenkel/artist_finance_manager/blob/main/PRIVACY.md';

  @override
  String get close => 'Cerrar';
}
