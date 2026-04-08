// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'WorklogsJira';

  @override
  String get settings => 'Configuraciones';

  @override
  String get user => 'Usuario';

  @override
  String get email => 'Correo electrónico';

  @override
  String get emailHelperText =>
      '(Opcional) Sería necesario para visualizar el Dashboard.';

  @override
  String get password => 'Contraseña';

  @override
  String get authoritationSaved => 'Autorización guardada';

  @override
  String get systemTheme => 'Tema del sistema';

  @override
  String get lightTheme => 'Tema claro';

  @override
  String get darkTheme => 'Tema oscuro';

  @override
  String get issue => 'Tarea';

  @override
  String get hours => 'Horas';

  @override
  String get repetitions => '# Repeticiones de la tarea';

  @override
  String get startDate => 'Fecha de inicio';

  @override
  String get load => 'Cargar tarea';

  @override
  String get log => 'Imputar tarea';

  @override
  String get successfulRequest => 'Petición satisfactoria';

  @override
  String get errorRequest => 'Ha ocurrido un error';

  @override
  String get issueRequired => 'La tarea es requerida';

  @override
  String get someFieldsRequired => 'Algunos campos son requeridos';

  @override
  String get issueEmpty => 'Esta tarea no tiene imputaciones';

  @override
  String get listEmpty => 'No hay tareas imputadas en este rango de fechas';

  @override
  String get issuePreffix => 'Prefijo de la tarea';

  @override
  String get showChart => 'Mostrar gráfico';

  @override
  String get barsChart => 'Gráfico de barras';

  @override
  String get pieChart => 'Gráfico de pastel';

  @override
  String get startRange => 'Rango de inicio';

  @override
  String get finishRange => 'Rango final';

  @override
  String get loading => 'Cargando';

  @override
  String get timeSpent => 'Tiempo gastando';

  @override
  String get startedLog => 'Día de imputación';

  @override
  String get comment => 'Comentarios';

  @override
  String get created => 'Creado';

  @override
  String get updated => 'Actualizado';

  @override
  String get assginee => 'Asignada';

  @override
  String get jiraPath => 'Url de Jira';

  @override
  String get useToken => 'Usar token';

  @override
  String get useTokenDescription =>
      'Puede usar el token o contraseña para la autenticación';

  @override
  String get workedHours => 'Horas de trabajo por día';

  @override
  String get workedHoursDescription =>
      'Escriba la máxima cantidad de horas de trabajo por día y seleccione los días activos';

  @override
  String get clearCache => 'Eliminar la cache';

  @override
  String get setSettings => 'Debes primero modificar las Configuraciones';

  @override
  String get passwordDeprecated =>
      'Autenticación básica (usuario y contraseña) ha sido deshabilitada';

  @override
  String get subtasks => 'Subtareas';

  @override
  String lastLoggedDate(String date) {
    return 'Último día imputado: $date';
  }

  @override
  String get loggedTasks => 'Tareas imputadas';

  @override
  String get task => 'Tarea';

  @override
  String get date => 'Fecha';

  @override
  String get reloadProjects => 'Recargar proyectos';

  @override
  String get loadProjectsFromJira => 'Cargar proyectos desde Jira';

  @override
  String get loadProjectsHelper =>
      'Cargar proyectos desde Jira o escribir manualmente';

  @override
  String projectsAvailable(int count) {
    return '$count proyectos disponibles';
  }

  @override
  String get worklogReminder => 'Recordatorio de horas';

  @override
  String get enableReminder => 'Activar recordatorio';

  @override
  String get selectReminderTime => 'Seleccionar hora del recordatorio';

  @override
  String get customReminderMessage => 'Mensaje personalizado';

  @override
  String get applyToAllDays => 'Aplicar a todos los días de trabajo';

  @override
  String get reminderTimeForDay => 'Hora del recordatorio';

  @override
  String get daysReceiveReminder => 'Días que recibirán el recordatorio';

  @override
  String get noWorkingDaysReminder =>
      'Marca al menos un día laborable para activar recordatorios.';

  @override
  String get resetToDefaultTime => 'Restaurar hora predeterminada';

  @override
  String get reminderDaysHint =>
      'Activa o desactiva el recordatorio individualmente por cada día laborable. Toca la hora para establecer una hora personalizada.';

  @override
  String get updateAvailable => 'Actualización disponible';

  @override
  String get newVersion => 'Nueva versión';

  @override
  String get releaseNotes => 'Notas de la versión';

  @override
  String get noReleaseNotes => 'No hay notas de versión disponibles';

  @override
  String get later => 'Más tarde';

  @override
  String get download => 'Descargar';

  @override
  String get multiTaskTitle => 'Imputar varias tareas';

  @override
  String get addTask => 'Añadir tarea';

  @override
  String get logAll => 'Imputar todas';

  @override
  String totalHoursInfo(String total, String max) {
    return 'Total: ${total}h / ${max}h';
  }

  @override
  String hoursExceeded(String total, String max) {
    return 'Has superado las horas del día (${total}h / ${max}h). ¿Continuar igualmente?';
  }

  @override
  String get continueAnyway => 'Continuar';

  @override
  String get reviewTasks => 'Revisar';

  @override
  String get noTasksToLog => 'No hay tareas para imputar';

  @override
  String get allTasksLogged => 'Todas las tareas imputadas correctamente';
}
