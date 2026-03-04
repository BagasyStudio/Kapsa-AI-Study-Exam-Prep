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
}
