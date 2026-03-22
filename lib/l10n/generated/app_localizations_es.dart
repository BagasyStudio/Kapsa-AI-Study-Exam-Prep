// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonSkip => 'Saltar por ahora';

  @override
  String get onboardingGetStarted => 'Comenzar';

  @override
  String get onboardingAlmostThere => 'Ya casi';

  @override
  String get onboardingStartStudying => 'Empezar a estudiar 🚀';

  @override
  String get welcomeSubtitle =>
      'Tu compañero de estudio inteligente.\nHerramientas de IA para aprobar exámenes\ny mejorar tus notas.';

  @override
  String get welcomeTo => 'Bienvenido ';

  @override
  String get welcomeToWord => 'a ';

  @override
  String get welcomeBrand => 'Kapsa';

  @override
  String get examUrgencyTitle => '¿Tenés un examen\npróximo?';

  @override
  String get examUrgencySubtitle => 'Vamos a priorizar lo más importante.';

  @override
  String get examUrgencyThisWeek => 'Esta semana';

  @override
  String get examUrgencyThisMonth => 'Este mes';

  @override
  String get examUrgencyFewMonths => 'En unos meses';

  @override
  String get examUrgencyNoExams => 'No tengo exámenes';

  @override
  String get studyAreaTitle => '¿Qué\nestudiás?';

  @override
  String get studyAreaSubtitle =>
      'Personalizá tu experiencia eligiendo\ntu área de estudio.';

  @override
  String get studyAreaSciences => 'Ciencias';

  @override
  String get studyAreaEngineering => 'Ingeniería';

  @override
  String get studyAreaLaw => 'Derecho';

  @override
  String get studyAreaMedicine => 'Medicina';

  @override
  String get studyAreaEconomics => 'Economía';

  @override
  String get studyAreaArts => 'Artes';

  @override
  String get studyAreaCS => 'Informática';

  @override
  String get studyAreaOther => 'Otro';

  @override
  String get challengeTitle => '¿Cuál es tu mayor\ndesafío?';

  @override
  String get challengeSubtitle => 'Vamos a encontrar cómo ayudarte mejor.';

  @override
  String get challengeMemorizing => 'Me cuesta memorizar';

  @override
  String get challengeTime => 'No tengo tiempo';

  @override
  String get challengeBored => 'Me aburro estudiando';

  @override
  String get challengeNotes => 'No puedo organizar mis apuntes';

  @override
  String get challengeExams => 'Tengo exámenes pronto';

  @override
  String get challengeStart => 'No sé por dónde empezar';

  @override
  String get studyTimeTitle => '¿Cuánto estudiás\npor día?';

  @override
  String get studyTimeSubtitle => 'Vamos a adaptar tu plan a tu rutina.';

  @override
  String studyTimePerDay(String time) {
    return '$time por día';
  }

  @override
  String get studyTime30min => '30 min';

  @override
  String get studyTime1h => '1 hora';

  @override
  String get studyTime2h => '2 horas';

  @override
  String get studyTime3h => '3 horas';

  @override
  String get studyTime5h => '5 horas';

  @override
  String get studyTime8h => '8 horas';

  @override
  String get studyTimeSub30 => 'Sesiones rápidas';

  @override
  String get studyTimeSub1 => 'Ritmo constante';

  @override
  String get studyTimeSub2 => 'Estudio enfocado';

  @override
  String get studyTimeSub3 => 'Estudiante dedicado';

  @override
  String get studyTimeSub5 => 'Estudiante intensivo';

  @override
  String get studyTimeSub8 => 'Compromiso total';

  @override
  String get uploadTitle => 'Subí tu primer\nmaterial de estudio';

  @override
  String get uploadSubtitle =>
      'Kapsa creará flashcards, quizzes\ny un plan de estudio con él.';

  @override
  String get uploadScanPages => 'Escanear páginas';

  @override
  String get uploadScanSub => 'Tomá una foto de tus apuntes';

  @override
  String get uploadPdf => 'Subir PDF';

  @override
  String get uploadPdfSub => 'Elegí un archivo de tu dispositivo';

  @override
  String get processingTitle => 'Creando tu kit\nde estudio...';

  @override
  String get processingContinue => 'Continuar';

  @override
  String get processingStepReading => 'Leyendo tu material...';

  @override
  String get processingStepReadingDone => 'Material analizado';

  @override
  String get processingStepFlashcards => 'Generando flashcards...';

  @override
  String processingStepFlashcardsDone(int count) {
    return '$count flashcards creadas';
  }

  @override
  String get processingStepQuiz => 'Creando preguntas de quiz...';

  @override
  String processingStepQuizDone(int count) {
    return '$count preguntas de quiz listas';
  }

  @override
  String get processingStepPlan => 'Armando tu plan de estudio...';

  @override
  String get processingStepPlanDone => '¡Plan de estudio listo!';

  @override
  String get socialProofTitle => 'Los estudiantes aman Kapsa';

  @override
  String socialProofFlashcardsReady(int count) {
    return 'estudiantes — ¡tus $count flashcards están listas!';
  }

  @override
  String get socialProofActiveStudents => 'estudiantes activos';

  @override
  String get socialProofIn30Days => 'En 30 días';

  @override
  String get socialProofGradeImprovement => 'Promedio +40% de mejora en notas';

  @override
  String get testimonialSofiaName => 'Sofía M.';

  @override
  String get testimonialSofiaRole => 'Estudiante de Medicina';

  @override
  String get testimonialSofiaQuote =>
      'Kapsa cambió mi forma de estudiar. Mis notas mejoraron muchísimo en solo un mes.';

  @override
  String get testimonialMarcoName => 'Marco L.';

  @override
  String get testimonialMarcoRole => 'Ingeniería';

  @override
  String get testimonialMarcoQuote =>
      'Aprobé mis finales gracias a las flashcards con IA. La mejor app de estudio.';

  @override
  String get testimonialLuciaName => 'Lucía R.';

  @override
  String get testimonialLuciaRole => 'Estudiante de Derecho';

  @override
  String get testimonialLuciaQuote =>
      'El Oráculo es como tener un tutor personal 24/7. Ya no puedo estudiar sin él.';

  @override
  String get planReadyTitle => '¡Tu plan está\nlisto!';

  @override
  String get planReadyPersonalized => 'Personalizado';

  @override
  String planReadyStudyArea(String area) {
    return 'Área de estudio: $area';
  }

  @override
  String planReadyFocus(String challenge) {
    return 'Enfoque: $challenge';
  }

  @override
  String planReadyTime(String time) {
    return 'Tiempo: $time por día';
  }

  @override
  String get planReadyAiTools => 'Herramientas de IA hechas para vos';

  @override
  String planReadyMaterial(int flashcards, int quizzes) {
    return '$flashcards flashcards y $quizzes preguntas de quiz listas';
  }

  @override
  String get planReadyNotSet => 'Sin definir';

  @override
  String get planReadyUrgencyThisWeek =>
      '¡Tu examen es esta semana — vamos a prepararte!';

  @override
  String get planReadyUrgencyThisMonth =>
      '¡Tu examen es este mes — vamos a prepararte!';

  @override
  String get rateTitle => '¿Estás disfrutando\nKapsa?';

  @override
  String get rateSubtitle => 'Ayudanos a crecer';

  @override
  String get rateThankYou => 'Gracias por\ntu sinceridad';

  @override
  String get rateFeedbackHelps =>
      'Tu opinión nos ayuda a crear una mejor\nexperiencia de estudio para todos.';

  @override
  String get rateLoveIt => '¡Me encanta!';

  @override
  String get rateNotYet => 'Todavía no';

  @override
  String get rateAwesome => '¡Genial! 🎉';

  @override
  String get rateAskStars =>
      'Una reseña de 5 estrellas nos ayuda a seguir\ncreando herramientas de IA para estudiar mejor.';

  @override
  String get rate5Stars => 'Dar 5 Estrellas ⭐';

  @override
  String get rateMaybeLater => 'Quizás después';

  @override
  String get rateHonestyAppreciated => 'Valoramos tu sinceridad. 🙏';

  @override
  String get rateAlwaysImproving =>
      'Siempre estamos mejorando Kapsa.\nTu opinión nos ayuda a crear las herramientas\nde estudio que realmente necesitás.';

  @override
  String get rateWeShipUpdates => 'Publicamos actualizaciones cada semana';

  @override
  String get rateGetsBetter =>
      'Kapsa mejora con cada\nopinión de los estudiantes.';

  @override
  String get paywallKapsaPro => 'KAPSA PRO';

  @override
  String get paywallTitle => 'Desbloqueá todo\ntu potencial';

  @override
  String get paywallFeature1 => 'Chat de Oráculo IA ilimitado';

  @override
  String get paywallFeature2 => 'Flashcards y Quizzes ilimitados';

  @override
  String get paywallFeature3 => 'Planes de estudio inteligentes';

  @override
  String get paywallFeature4 => 'Análisis avanzados';

  @override
  String get paywallFeature5 => 'Resúmenes de audio y oclusión';

  @override
  String get paywallFeature6 => 'Grupos de estudio ilimitados';

  @override
  String get paywallStudents => '50K+ estudiantes';

  @override
  String get paywallRating => '4.8';

  @override
  String get paywallStartTrial => 'Empezar prueba gratis de 3 días';

  @override
  String get paywallSkip => 'Continuar sin Pro';

  @override
  String get paywallDisclaimer =>
      'Prueba gratis de 3 días · Cancelá en cualquier momento · Sin cargo hoy';

  @override
  String get captureProcessingPdf => 'Procesando tu PDF...';

  @override
  String get captureProcessingWhisper => 'Transcribiendo audio...';

  @override
  String get captureProcessingOcr => 'Analizando tu escaneo...';

  @override
  String get captureProcessingDone => '¡Listo!';

  @override
  String get captureSavingNote => 'Guardando nota...';

  @override
  String get capturePdfUploading => 'Subiendo PDF...';

  @override
  String get capturePdfUploaded => 'PDF subido';

  @override
  String get capturePdfParsing => 'Analizando páginas...';

  @override
  String get capturePdfParsed => 'Páginas analizadas';

  @override
  String get capturePdfAnalyzing => 'Analizando estructura...';

  @override
  String get capturePdfAnalyzed => 'Estructura analizada';

  @override
  String get capturePdfExtracting => 'IA extrayendo contenido...';

  @override
  String get capturePdfExtracted => 'Contenido extraído';

  @override
  String get capturePdfConcepts => 'Identificando conceptos clave...';

  @override
  String get capturePdfConceptsDone => 'Conceptos clave encontrados';

  @override
  String get capturePdfFormatting => 'Formateando texto...';

  @override
  String get capturePdfFormattingDone => 'Texto formateado';

  @override
  String get capturePdfFinishing => 'Terminando...';

  @override
  String get capturePdfReady => '¡Listo!';

  @override
  String get captureWhisperUploading => 'Subiendo audio...';

  @override
  String get captureWhisperUploaded => 'Audio subido';

  @override
  String get captureWhisperSignal => 'Procesando señal de audio...';

  @override
  String get captureWhisperSignalDone => 'Señal procesada';

  @override
  String get captureWhisperSpeech => 'Detectando patrones de voz...';

  @override
  String get captureWhisperSpeechDone => 'Voz detectada';

  @override
  String get captureWhisperTranscribing => 'IA transcribiendo audio...';

  @override
  String get captureWhisperTranscribed => 'Audio transcrito';

  @override
  String get captureWhisperFormatting => 'Formateando transcripción...';

  @override
  String get captureWhisperFormattingDone => 'Transcripción formateada';

  @override
  String get captureWhisperCleaning => 'Puliendo texto...';

  @override
  String get captureWhisperCleaningDone => 'Texto pulido';

  @override
  String get captureWhisperFinishing => 'Terminando...';

  @override
  String get captureWhisperReady => '¡Listo!';

  @override
  String get captureOcrUploading => 'Subiendo imagen...';

  @override
  String get captureOcrUploaded => 'Imagen subida';

  @override
  String get captureOcrScanning => 'Escaneando documento...';

  @override
  String get captureOcrScanned => 'Documento escaneado';

  @override
  String get captureOcrRecognizing => 'IA reconociendo texto...';

  @override
  String get captureOcrRecognized => 'Texto reconocido';

  @override
  String get captureOcrExtracting => 'Extrayendo contenido clave...';

  @override
  String get captureOcrExtracted => 'Contenido extraído';

  @override
  String get captureOcrFormatting => 'Formateando resultados...';

  @override
  String get captureOcrFormattingDone => 'Resultados formateados';

  @override
  String get captureOcrOrganizing => 'Organizando material...';

  @override
  String get captureOcrOrganized => 'Material organizado';

  @override
  String get captureOcrFinishing => 'Terminando...';

  @override
  String get captureOcrReady => '¡Listo!';

  @override
  String get authWelcomeBack => 'Bienvenido de vuelta, estudiante';

  @override
  String get authSignIn => 'Iniciar Sesión';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Contraseña';

  @override
  String get authForgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get authContinueWithApple => 'Continuar con Apple';

  @override
  String get authOr => 'o';

  @override
  String get authNoAccount => '¿No tenés una cuenta? ';

  @override
  String get authCreateAccount => 'Crear Cuenta';

  @override
  String get authHaveAccount => '¿Ya tenés una cuenta? ';

  @override
  String get authTermsOfService => 'Términos de Servicio';

  @override
  String get authPrivacyPolicy => 'Política de Privacidad';

  @override
  String get authBeginJourney =>
      'Comenzá tu camino hacia la excelencia académica';

  @override
  String get authFullName => 'Nombre Completo';

  @override
  String get authConfirmPassword => 'Confirmar Contraseña';

  @override
  String get authAgreeToTerms => 'Acepto los ';

  @override
  String get authAnd => ' y ';

  @override
  String get authEmailRequired => 'El email es obligatorio';

  @override
  String get authValidEmail => 'Ingresá un email válido';

  @override
  String get authPasswordRequired => 'La contraseña es obligatoria';

  @override
  String get authPasswordMinLength =>
      'La contraseña debe tener al menos 6 caracteres';

  @override
  String get authNameRequired => 'El nombre es obligatorio';

  @override
  String get authNameMinLength => 'El nombre debe tener al menos 2 caracteres';

  @override
  String get authConfirmRequired => 'Confirmá tu contraseña';

  @override
  String get authPasswordMismatch => 'Las contraseñas no coinciden';

  @override
  String get authAcceptTerms =>
      'Aceptá los Términos de Servicio y la Política de Privacidad';

  @override
  String get authEnterEmailFirst => 'Ingresá tu email primero';

  @override
  String get authResetSent => '¡Email de recuperación enviado!';

  @override
  String get authAlreadyRegistered => 'Este email ya está registrado';

  @override
  String get authWeakPassword =>
      'La contraseña debe tener al menos 6 caracteres';

  @override
  String get authNoInternet => 'Sin conexión a internet';

  @override
  String get authSomethingWrong => 'Algo salió mal. Intentá de nuevo.';

  @override
  String get practiceExamTitle => 'Examen de Práctica';

  @override
  String get practiceExamSelectCourse => 'SELECCIONÁ UN CURSO';

  @override
  String get practiceExamQuestionCount => 'CANTIDAD DE PREGUNTAS';

  @override
  String get practiceExamQuestions => 'preguntas';

  @override
  String get practiceExamTimeLimit => 'LÍMITE DE TIEMPO';

  @override
  String get practiceExamTime15 => '15 min';

  @override
  String get practiceExamTime30 => '30 min';

  @override
  String get practiceExamTime60 => '60 min';

  @override
  String get practiceExamNoLimit => 'Sin Límite';

  @override
  String get practiceExamStartExam => 'Comenzar Examen';

  @override
  String get practiceExamSelectCourseFirst => 'Seleccioná un curso';

  @override
  String get practiceExamNoCourses =>
      'Creá un curso primero para hacer un examen de práctica.';

  @override
  String get practiceExamSelectToStart => 'Seleccioná un curso para empezar';

  @override
  String get practiceExamLoadingHistory => 'Cargando historial...';

  @override
  String get practiceExamFirstAttempt => 'Primer intento — ¡Buena suerte! 🍀';

  @override
  String get practiceExamKeepItUp => '¡Seguí así!';

  @override
  String get practiceExamCanDoBetter => '¡Podés mejorar!';

  @override
  String get practiceExamPracticeMakesPerfect =>
      '¡La práctica hace al maestro!';

  @override
  String practiceExamLastScore(int pct, String encouragement) {
    return 'Último puntaje: $pct% — $encouragement';
  }

  @override
  String get practiceExamEstimatedDifficulty => 'Dificultad estimada';

  @override
  String get practiceExamMedium => 'Media';

  @override
  String quizQuestion(String current) {
    return 'Pregunta $current';
  }

  @override
  String get quizTypeAnswer => 'Escribí tu respuesta acá...';

  @override
  String get quizAnswerHint =>
      'Respondé con tus propias palabras. La IA evaluará tu comprensión.';

  @override
  String get quizPrevious => 'Anterior';

  @override
  String get quizNext => 'Siguiente';

  @override
  String get quizSubmitExam => 'Entregar Examen';

  @override
  String get quizSubmitQuiz => 'Entregar Quiz';

  @override
  String get quizPerfectScore => '¡Puntaje Perfecto! 🎉';

  @override
  String get quizPerfectSub => '¡Respondiste todo correctamente!';

  @override
  String get quizComplete => 'Quiz Completado';

  @override
  String get quizPerfect => '🏆 ¡Perfecto!';

  @override
  String get quizLeaveTitle => '¿Salir del quiz?';

  @override
  String get quizLeaveExamTitle => '¿Salir del examen?';

  @override
  String get quizLeaveSaved =>
      '¡Tu progreso está guardado! Podés continuar este quiz después desde la pantalla principal.';

  @override
  String get quizStay => 'Quedarme';

  @override
  String get quizContinueQuiz => 'Continuar Quiz';

  @override
  String get quizLeaveForNow => 'Salir por ahora';

  @override
  String get quizCouldNotLoad => 'No se pudo cargar el quiz';

  @override
  String get quizGoBack => 'Volver';

  @override
  String get quizNoQuestions => 'No se encontraron preguntas';

  @override
  String quizAnswerQuestion(String number) {
    return 'Respondé la pregunta $number';
  }

  @override
  String quizAnswerQuestions(String numbers) {
    return 'Respondé las preguntas $numbers';
  }

  @override
  String get quizDailyStreak => 'Racha Diaria';

  @override
  String get chatSuggestStudyToday => '¿Qué debería estudiar hoy?';

  @override
  String get chatSuggestProgress => '¿Cómo voy en general?';

  @override
  String get chatSuggestWeakest => 'Explicá mi tema más débil';

  @override
  String get chatSuggestQuiz => 'Hazme un quiz sobre esto';

  @override
  String get chatSuggestSummarize => 'Resumí el material';

  @override
  String get chatFollowUpExample => '¿Podés darme un ejemplo?';

  @override
  String get chatFollowUpSimpler => 'Explicalo más simple';

  @override
  String get chatFollowUpRelated => '¿Cómo se relaciona con otros temas?';

  @override
  String get homeFlashcards => 'FLASHCARDS';

  @override
  String homeDue(int count) {
    return '$count pendientes';
  }

  @override
  String get homeSomethingWrong => 'Algo salió mal';

  @override
  String get homeCheckConnection => 'Revisá tu conexión e intentá de nuevo';

  @override
  String get homeRetry => 'Reintentar';

  @override
  String get homeYourDecks => 'Tus Mazos';

  @override
  String get flashcardCreateNew => 'Crear Nuevo';

  @override
  String get flashcardCreateDeck => 'Crear Mazo de Flashcards';

  @override
  String get flashcardSelectCourse => 'Seleccioná un curso';

  @override
  String get flashcardCardCount => 'Cantidad de tarjetas';

  @override
  String get flashcardCards => 'tarjetas';

  @override
  String get flashcardGenerate => 'Generar Flashcards';

  @override
  String get flashcardUploadDoc => 'Subir apuntes (opcional)';

  @override
  String get flashcardUploadHint => 'PDF o foto de tus apuntes';

  @override
  String get flashcardUploadPdf => 'Subir PDF';

  @override
  String get flashcardUploadPhoto => 'Escanear foto';

  @override
  String get flashcardUploadChange => 'Cambiar';

  @override
  String get flashcardUploadProcessing => 'Procesando documento...';

  @override
  String get flashcardBookmarked => 'Tarjeta guardada';

  @override
  String get flashcardReshuffled => 'Tarjetas mezcladas';

  @override
  String get quickActionSnapSolve => 'Resolver';

  @override
  String get quickActionOracle => 'Oráculo';

  @override
  String get quickActionGroups => 'Grupos';

  @override
  String get quickActionExam => 'Examen';

  @override
  String get greetingMorning => 'Buen Día';

  @override
  String get greetingAfternoon => 'Buenas Tardes';

  @override
  String get greetingEvening => 'Buenas Noches';

  @override
  String streakDaysStreak(int count) {
    return 'Racha de $count Días';
  }

  @override
  String get streakOneDayStreak => 'Racha de 1 Día';

  @override
  String streakLongest(int days) {
    return 'Racha más larga: $days días';
  }

  @override
  String get streakStartToday =>
      '¡Empezá a estudiar hoy para comenzar tu racha!';

  @override
  String streakKeepGoing(int remaining, String dayWord, String milestone) {
    return '¡Seguí así! $remaining $dayWord más para tu medalla de $milestone!';
  }

  @override
  String get streakCheckHeatmap =>
      'Mirá tu Mapa de Estudio en la pantalla principal';

  @override
  String get streakGotIt => 'Entendido';

  @override
  String get streakDay => 'día';

  @override
  String get streakDays => 'días';

  @override
  String get journeyLearningJourney => 'Camino de Aprendizaje';

  @override
  String journeyProgress(int percent) {
    return '$percent% PROGRESO';
  }

  @override
  String journeyLevel(int level) {
    return 'NIVEL $level';
  }

  @override
  String get journeyTodaysChallenge => 'DESAFÍO DE HOY';

  @override
  String journeyCompleteAll(int xp) {
    return 'Completá todos por +$xp XP extra';
  }

  @override
  String get journeyUpNext => 'SIGUIENTE';

  @override
  String get journeyStart => 'EMPEZAR';

  @override
  String get journeyStartExam => 'EMPEZAR EXAMEN';

  @override
  String get journeyOpen => 'ABRIR';

  @override
  String get journeyFinalExam => 'Examen Final';

  @override
  String get journeyComprehensiveTest => 'Evaluación integral';

  @override
  String get journeyRewardChest => 'Cofre de Recompensa';

  @override
  String get journeyNoContent => 'Sin contenido aún';

  @override
  String get journeyUploadMaterials =>
      'Subí materiales para generar tu camino de aprendizaje';

  @override
  String get journeyUploadMaterial => 'Subir Material';

  @override
  String get journeyCouldNotLoad => 'No se pudo cargar el camino';

  @override
  String get journeyGenerating => 'Generando tu camino de aprendizaje...';

  @override
  String get journeyComplete => '¡Camino Completado!';

  @override
  String get journeyReviewJourney => 'Revisar Camino';

  @override
  String get journeyContinue => 'Continuar Camino';

  @override
  String get journeyReviewFlashcards => 'Repasar Flashcards';

  @override
  String get journeyTakeQuiz => 'Hacer Quiz';

  @override
  String get journeyReviewMaterial => 'Revisar Material';

  @override
  String get journeyReadSummary => 'Leer Resumen';

  @override
  String get journeyAskOracle => 'Preguntarle al Oráculo';

  @override
  String get journeyTakeCheckpoint => 'Hacer Checkpoint';

  @override
  String get journeyClaimReward => 'Reclamar Recompensa';

  @override
  String get journeyStartFinalExam => 'Empezar Examen Final';

  @override
  String get journeyCompletePrevious => 'Completá el paso anterior primero';

  @override
  String get journeyExamToday => '¡El examen es hoy!';

  @override
  String journeyDaysToExam(int days, String suffix) {
    return '$days día$suffix para el examen';
  }

  @override
  String get journeyQuickQuestions => '5 preguntas rápidas';

  @override
  String get journeyCheckpoint => 'Checkpoint';

  @override
  String journeyReview(String title) {
    return 'Repasar: $title';
  }

  @override
  String journeyFlashcards(String title) {
    return 'Flashcards: $title';
  }

  @override
  String journeyCards(int count) {
    return '$count tarjetas';
  }

  @override
  String get journeyPracticeQuiz => 'Quiz de Práctica';

  @override
  String get journeyTestKnowledge => 'Poné a prueba tu conocimiento';

  @override
  String get journeyAiQA => 'Preguntas y respuestas con IA';

  @override
  String get journeyPdfDocument => 'Documento PDF';

  @override
  String get journeyAudio => 'Audio';

  @override
  String get journeyNotes => 'Apuntes';

  @override
  String get journeyPastedText => 'Texto Pegado';

  @override
  String get journeyMaterial => 'Material';

  @override
  String get journeyFillGaps => 'Completar Espacios';

  @override
  String get journeyFillGapsSub => 'Completá los términos faltantes';

  @override
  String get journeySpeedRound => 'Ronda Relámpago';

  @override
  String get journeySpeedRoundSub => '10 verdadero/falso en 50 seg';

  @override
  String get journeyMistakeSpotter => 'Cazador de Errores';

  @override
  String get journeyMistakeSpotterSub => 'Encontrá los errores';

  @override
  String get journeyTeachBot => 'Enseñale al Bot';

  @override
  String get journeyTeachBotSub => 'Explicalo con tus palabras';

  @override
  String get journeyCompareContrast => 'Comparar y Contrastar';

  @override
  String get journeyCompareContrastSub => 'Ordená las diferencias';

  @override
  String get journeyTimelineBuilder => 'Constructor de Línea Temporal';

  @override
  String get journeyTimelineBuilderSub => 'Ordená los pasos';

  @override
  String get journeyCaseStudy => 'Caso Práctico';

  @override
  String get journeyCaseStudySub => 'Aplicá tu conocimiento';

  @override
  String get journeyMatchBlitz => 'Match Blitz';

  @override
  String get journeyMatchBlitzSub => 'Emparejá conceptos rápido';

  @override
  String get journeyConceptMapper => 'Mapa Conceptual';

  @override
  String get journeyConceptMapperSub => 'Conectá las ideas';

  @override
  String get journeyDailyChallenge => 'Desafío Diario';

  @override
  String get journeyDailyChallengeSub => 'Ejercicio personalizado del día';

  @override
  String get journeyStartFillGaps => 'Empezar a Completar';

  @override
  String get journeyStartSpeedRound => 'Empezar Ronda';

  @override
  String get journeyStartMistakeSpotter => 'Empezar a Buscar';

  @override
  String get journeyStartTeachBot => 'Empezar a Enseñar';

  @override
  String get journeyStartCompareContrast => 'Empezar a Comparar';

  @override
  String get journeyStartTimelineBuilder => 'Empezar Línea Temporal';

  @override
  String get journeyStartCaseStudy => 'Empezar Caso';

  @override
  String get journeyStartMatchBlitz => 'Empezar Match';

  @override
  String get journeyStartConceptMapper => 'Empezar Mapa';

  @override
  String get journeyStartDailyChallenge => 'Empezar Desafío';

  @override
  String get journeyDifficultyEasy => 'Fácil';

  @override
  String get journeyDifficultyMedium => 'Media';

  @override
  String get journeyDifficultyHard => 'Difícil';

  @override
  String journeyStreakMultiplier(int multiplier) {
    return 'x$multiplier XP';
  }

  @override
  String get journeyStreakBonus => '¡Bonus de Racha!';

  @override
  String get journeyInsights => 'Estadísticas de Progreso';

  @override
  String get journeyMastered => 'Dominados';

  @override
  String get journeyNeedsWork => 'Necesitan Trabajo';

  @override
  String get journeyTimeStudied => 'Tiempo estudiado';

  @override
  String get journeyThisWeek => 'esta semana';

  @override
  String get journeyPredictedScore => 'Nota estimada del examen';

  @override
  String get journeyWeeklyGoal => 'Meta semanal';

  @override
  String get journeyBossPreview => 'Temas del Examen';

  @override
  String get journeyConfidence => 'Confianza';

  @override
  String get journeyReviewWeak => 'Repasar Temas Débiles';

  @override
  String get journeyRecapTitle => 'Resumen Semanal';

  @override
  String journeyRecapNodesCompleted(int count) {
    return '$count nodos completados';
  }

  @override
  String journeyRecapXpEarned(int xp) {
    return '$xp XP ganados';
  }

  @override
  String get journeyRecapNewTopics => 'Temas nuevos';

  @override
  String get journeyRecapReviewed => 'Repasados';

  @override
  String get journeyMicroReviewTitle => 'Repaso';

  @override
  String journeyMicroReviewCompleted(String date) {
    return 'Completado el $date';
  }

  @override
  String journeyMicroReviewScore(int score) {
    return 'Puntaje: $score%';
  }

  @override
  String get journeyMicroReviewRedo => 'Rehacer Ejercicio';

  @override
  String get journeyMicroReviewNoScore => 'Sin puntaje registrado';

  @override
  String get journeyFabContinue => 'Continuar';

  @override
  String get journeyFabReview => 'Repasar';

  @override
  String get journeyFabQuickChallenge => 'Desafío Rápido';

  @override
  String get exerciseCorrect => '¡Correcto!';

  @override
  String get exerciseIncorrect => 'Incorrecto';

  @override
  String exerciseScore(int score) {
    return 'Puntaje: $score%';
  }

  @override
  String get exerciseComplete => '¡Ejercicio Completado!';

  @override
  String exerciseImproved(int percent) {
    return '¡Mejoraste $percent% vs la última vez!';
  }

  @override
  String exerciseMastered(int count, int total) {
    return 'Dominaste $count/$total conceptos';
  }

  @override
  String get exerciseTimeUp => '¡Se acabó el tiempo!';

  @override
  String get exerciseSubmit => 'Enviar';

  @override
  String get exerciseNext => 'Siguiente';

  @override
  String get exerciseFinish => 'Finalizar';

  @override
  String get exerciseTryAgain => 'Intentar de Nuevo';

  @override
  String get exerciseCheckAnswer => 'Verificar Respuesta';

  @override
  String get exerciseTrue => 'Verdadero';

  @override
  String get exerciseFalse => 'Falso';

  @override
  String get exerciseGoodJob => '¡Buen trabajo!';

  @override
  String get exerciseKeepPracticing => '¡Seguí practicando!';

  @override
  String get exerciseExcellent => '¡Excelente!';

  @override
  String get exerciseNeedsImprovement => 'Necesita mejora';

  @override
  String get exerciseLoading => 'Generando ejercicio...';

  @override
  String get exerciseCouldNotLoad => 'No se pudo cargar el ejercicio';

  @override
  String get fillGapsInstruction =>
      'Completá los espacios con los términos correctos';

  @override
  String get fillGapsHint => 'Escribí la palabra faltante';

  @override
  String fillGapsOf(int current, int total) {
    return '$current de $total';
  }

  @override
  String get speedRoundInstruction =>
      '¿Verdadero o Falso? ¡Tenés 5 segundos por pregunta!';

  @override
  String get speedRoundReady => '¿Listo?';

  @override
  String get speedRoundGo => '¡YA!';

  @override
  String speedRoundResult(int correct, int total) {
    return '$correct/$total correctas';
  }

  @override
  String speedRoundAvgTime(String seconds) {
    return 'Prom. ${seconds}s por pregunta';
  }

  @override
  String mistakeSpotterInstruction(int count) {
    return 'Encontrá $count errores en el texto';
  }

  @override
  String mistakeSpotterFound(int found, int total) {
    return '$found/$total errores encontrados';
  }

  @override
  String get mistakeSpotterTapToMark =>
      'Tocá las oraciones para marcar errores';

  @override
  String get mistakeSpotterCorrection => 'Corrección';

  @override
  String get mistakeSpotterWrongSelection => 'Esta oración es correcta';

  @override
  String get teachBotInstruction =>
      'Explicale este concepto al bot como si le enseñaras a un alumno confundido';

  @override
  String get teachBotBotMessage =>
      'Estoy confundido con este tema. ¿Me lo podés explicar?';

  @override
  String get teachBotSendExplanation => 'Enviar explicación';

  @override
  String get teachBotFeedback => 'El bot analizó tu explicación';

  @override
  String teachBotCoveredPoints(int count, int total) {
    return '$count/$total puntos clave cubiertos';
  }

  @override
  String teachBotMissedPoint(String point) {
    return 'No mencionaste: $point';
  }

  @override
  String get compareContrastInstruction =>
      'Ordená estos rasgos en la categoría correcta';

  @override
  String get compareContrastDragHint =>
      'Arrastrá los elementos a la columna correcta';

  @override
  String get timelineInstruction => 'Ordená estos pasos en el orden correcto';

  @override
  String get timelineDragHint => 'Arrastrá para reordenar';

  @override
  String get timelineCheckOrder => 'Verificar Orden';

  @override
  String get timelineCorrectOrder => '¡Orden correcto!';

  @override
  String get timelineWrongOrder => 'No del todo. ¡Intentá de nuevo!';

  @override
  String get caseStudyScenario => 'Escenario';

  @override
  String caseStudyQuestion(int num) {
    return 'Pregunta $num';
  }

  @override
  String get caseStudyAnswer => 'Tu respuesta';

  @override
  String get matchBlitzInstruction =>
      'Emparejá los conceptos con sus definiciones';

  @override
  String matchBlitzPairsLeft(int count) {
    return '$count pares restantes';
  }

  @override
  String matchBlitzTimeBonus(int xp) {
    return 'Bonus de tiempo: +$xp XP';
  }

  @override
  String get conceptMapInstruction =>
      'Conectá los enlaces faltantes en el mapa conceptual';

  @override
  String get conceptMapDragToConnect => 'Arrastrá para conectar nodos';

  @override
  String get chatAiOracle => 'Oráculo IA';

  @override
  String get chatTheOracle => 'El Oráculo';

  @override
  String get chatSettingsComingSoon => 'Configuración del chat próximamente';

  @override
  String get chatToday => 'Hoy';

  @override
  String get chatStudyCompanion => 'Tu compañero de estudio IA';

  @override
  String get chatStudyCompanionSub =>
      'Hacé preguntas, obtené explicaciones y aprobá tus exámenes.';

  @override
  String get chatOracleKnows => 'El Oráculo lo sabe todo';

  @override
  String get chatOracleKnowsSub =>
      'Preguntá sobre tus cursos, notas, áreas débiles y próximos exámenes.';

  @override
  String get flashcardLoadError => 'No se pudieron cargar las flashcards';

  @override
  String get flashcardNoCards => 'Todavía no hay flashcards';

  @override
  String get flashcardNoCardsHint =>
      'Generá flashcards desde tus materiales de estudio primero.';

  @override
  String get flashcardLeaveTitle => '¿Salir de la sesión?';

  @override
  String get flashcardLeaveMessage => 'Tu progreso en esta sesión se perderá.';

  @override
  String get flashcardStay => 'Quedarme';

  @override
  String get flashcardLeave => 'Salir';

  @override
  String get flashcardEditComingSoon => 'Editar tarjetas próximamente';

  @override
  String get flashcardSessionComplete => '¡Sesión Completa!';

  @override
  String flashcardCardsReviewed(int count) {
    return '$count tarjetas repasadas';
  }

  @override
  String get flashcardMastered => 'Dominadas';

  @override
  String get flashcardAgain => 'Repetir';

  @override
  String get flashcardMasteryLabel => 'Dominio';

  @override
  String get flashcardShareResults => 'Compartir Resultados';

  @override
  String get flashcardContinueReviewing => 'Seguir Repasando';

  @override
  String get flashcardDone => 'Listo';

  @override
  String get homeDefaultName => 'Estudiante';

  @override
  String get exerciseDifficultyTitle => 'Elegir Dificultad';

  @override
  String get exerciseDifficultyEasy => 'Fácil';

  @override
  String get exerciseDifficultyEasyDesc => 'Más tiempo, pistas disponibles';

  @override
  String get exerciseDifficultyMedium => 'Medio';

  @override
  String get exerciseDifficultyMediumDesc => 'Desafío estándar';

  @override
  String get exerciseDifficultyHard => 'Difícil';

  @override
  String get exerciseDifficultyHardDesc => 'Menos tiempo, sin pistas';

  @override
  String get exerciseDifficultyStart => 'Comenzar Ejercicio';

  @override
  String exerciseComboStreak(int count) {
    return '¡$count seguidas!';
  }

  @override
  String exerciseComboBonusXp(int xp) {
    return '+$xp XP bonus';
  }

  @override
  String get exerciseRelatedTitle => '¿Querés aprender más?';

  @override
  String get exerciseRelatedSummary => 'Ver Resumen';

  @override
  String get exerciseRelatedFlashcards => 'Practicar Flashcards';

  @override
  String get exerciseRelatedGlossary => 'Leer Glosario';

  @override
  String get chatPreferencesTitle => 'Preferencias del Chat';

  @override
  String get chatResponseStyle => 'Estilo de Respuesta';

  @override
  String get chatStyleBrief => 'Breve';

  @override
  String get chatStyleBriefDesc => 'Respuestas cortas y concisas';

  @override
  String get chatStyleDetailed => 'Detallado';

  @override
  String get chatStyleDetailedDesc => 'Explicaciones en profundidad';

  @override
  String get chatStyleEli5 => 'ELI5';

  @override
  String get chatStyleEli5Desc => 'Explicame como si tuviera 5 años';

  @override
  String get chatIncludeExamples => 'Incluir Ejemplos';

  @override
  String get chatIncludeExamplesDesc =>
      'Agregar ejemplos prácticos a las respuestas';

  @override
  String get chatPreferencesSaved => 'Preferencias guardadas';

  @override
  String get chatLongPressToClear => 'Mantené presionado para borrar';

  @override
  String chatCharCount(String count, String max) {
    return '$count/$max';
  }

  @override
  String get postUploadMaterialUploaded => 'Material subido';

  @override
  String get postUploadWhatToCreate => '¿Qué querés crear?';

  @override
  String get postUploadFlashcards => 'Flashcards';

  @override
  String get postUploadQuiz => 'Quiz';

  @override
  String get postUploadSummary => 'Resumen';

  @override
  String get postUploadGlossary => 'Glosario';

  @override
  String get postUploadCreateCards => 'Creá tarjetas de estudio';

  @override
  String get postUploadTestKnowledge => 'Poné a prueba lo que sabés';

  @override
  String get postUploadKeyPoints => 'Resumen de puntos clave';

  @override
  String get postUploadKeyTerms => 'Definiciones de términos';

  @override
  String get postUploadMoreTools => 'Más herramientas';

  @override
  String get postUploadSrsReview => 'Repaso SRS';

  @override
  String get postUploadPracticeExam => 'Examen Práctico';

  @override
  String get postUploadAudioSummary => 'Resumen en Audio';

  @override
  String get postUploadSnapSolve => 'Snap & Solve';

  @override
  String get postUploadChat => 'Chat';

  @override
  String get postUploadSkip => 'Omitir';

  @override
  String postUploadGeneratingInBackground(String tool) {
    return 'Generando $tool en segundo plano...';
  }

  @override
  String get postUploadHowManyFlashcards => '¿Cuántas flashcards?';

  @override
  String get postUploadChooseCount => 'Elegí la cantidad de tarjetas a generar';

  @override
  String get postUploadPro => 'PRO';

  @override
  String postUploadGenerateFlashcards(int count) {
    return 'Generar $count Flashcards';
  }

  @override
  String homeDueCardsBanner(int count) {
    return '$count tarjetas pendientes de repaso';
  }

  @override
  String get homeDueCardsReviewNow => 'Repasar ahora';

  @override
  String get homeMyCourses => 'Mis Cursos';

  @override
  String get homeYourJourney => 'Tu Camino';

  @override
  String get homeContinue => 'Continuar';

  @override
  String get homeFlashcardDecks => 'Mazos de Flashcards';

  @override
  String get homeSeeAll => 'Ver todo';

  @override
  String homeViewAllDecks(int count) {
    return 'Ver los $count mazos';
  }

  @override
  String get homeNoDecksYet => 'Aún no tienes mazos';

  @override
  String get homeStartJourney => 'Comienza tu camino';

  @override
  String get homeComplete => 'completo';

  @override
  String get trialNotifDay0Title => '¡Tu plan de estudio está listo!';

  @override
  String get trialNotifDay0Body => 'Generá tus primeras flashcards ahora';

  @override
  String get trialNotifDay1Title => '¿Sabías que...?';

  @override
  String get trialNotifDay1Body =>
      'Los estudiantes que usan flashcards rinden 23% mejor. ¡Probá generar un quiz!';

  @override
  String get trialNotifDay2Title => '¿Probaste Snap & Solve?';

  @override
  String get trialNotifDay2Body =>
      'Sacale foto a cualquier problema y obtén la solución paso a paso';

  @override
  String get trialNotifLastDayTitle => '¡Último día de tu prueba!';

  @override
  String get trialNotifLastDayBody =>
      'Aprovechá al máximo — generá flashcards, quizzes y resúmenes';

  @override
  String get trialNotif2DaysLeftTitle => 'Te quedan 2 días de prueba';

  @override
  String get trialNotif2DaysLeftBody =>
      'No te lo pierdas — explorá todas las herramientas de IA';
}
