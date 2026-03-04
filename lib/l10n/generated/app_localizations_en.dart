// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSkip => 'Skip for now';

  @override
  String get onboardingGetStarted => 'Get Started';

  @override
  String get onboardingAlmostThere => 'Almost There';

  @override
  String get onboardingStartStudying => 'Start Studying 🚀';

  @override
  String get welcomeSubtitle =>
      'Your smart study companion.\nAI-powered tools to ace exams\nand boost your GPA.';

  @override
  String get welcomeTo => 'Welcome ';

  @override
  String get welcomeToWord => 'to ';

  @override
  String get welcomeBrand => 'Kapsa';

  @override
  String get examUrgencyTitle => 'Do you have an\nexam coming up?';

  @override
  String get examUrgencySubtitle => 'We\'ll prioritize what matters most.';

  @override
  String get examUrgencyThisWeek => 'This week';

  @override
  String get examUrgencyThisMonth => 'This month';

  @override
  String get examUrgencyFewMonths => 'In a few months';

  @override
  String get examUrgencyNoExams => 'No exams yet';

  @override
  String get studyAreaTitle => 'What do you\nstudy?';

  @override
  String get studyAreaSubtitle =>
      'Customize your experience by choosing\nyour study area.';

  @override
  String get studyAreaSciences => 'Sciences';

  @override
  String get studyAreaEngineering => 'Engineering';

  @override
  String get studyAreaLaw => 'Law';

  @override
  String get studyAreaMedicine => 'Medicine';

  @override
  String get studyAreaEconomics => 'Economics';

  @override
  String get studyAreaArts => 'Arts';

  @override
  String get studyAreaCS => 'Computer Science';

  @override
  String get studyAreaOther => 'Other';

  @override
  String get challengeTitle => 'What\'s your\nbiggest challenge?';

  @override
  String get challengeSubtitle => 'We\'ll figure out how to help you best.';

  @override
  String get challengeMemorizing => 'I struggle to memorize';

  @override
  String get challengeTime => 'I don\'t have time';

  @override
  String get challengeBored => 'I get bored studying';

  @override
  String get challengeNotes => 'I can\'t organize my notes';

  @override
  String get challengeExams => 'Exams are coming soon';

  @override
  String get challengeStart => 'I don\'t know where to start';

  @override
  String get studyTimeTitle => 'How much do you\nstudy per day?';

  @override
  String get studyTimeSubtitle => 'We\'ll adapt your plan to your routine.';

  @override
  String studyTimePerDay(String time) {
    return '$time per day';
  }

  @override
  String get studyTime30min => '30 min';

  @override
  String get studyTime1h => '1 hour';

  @override
  String get studyTime2h => '2 hours';

  @override
  String get studyTime3h => '3 hours';

  @override
  String get studyTime5h => '5 hours';

  @override
  String get studyTime8h => '8 hours';

  @override
  String get studyTimeSub30 => 'Quick sessions';

  @override
  String get studyTimeSub1 => 'Steady pace';

  @override
  String get studyTimeSub2 => 'Focused study';

  @override
  String get studyTimeSub3 => 'Dedicated learner';

  @override
  String get studyTimeSub5 => 'Power student';

  @override
  String get studyTimeSub8 => 'Full commitment';

  @override
  String get uploadTitle => 'Upload your first\nstudy material';

  @override
  String get uploadSubtitle =>
      'Kapsa will create flashcards, quizzes\nand a study plan from it.';

  @override
  String get uploadScanPages => 'Scan pages';

  @override
  String get uploadScanSub => 'Take a photo of your notes';

  @override
  String get uploadPdf => 'Upload PDF';

  @override
  String get uploadPdfSub => 'Choose a file from your device';

  @override
  String get processingTitle => 'Creating your\nstudy toolkit...';

  @override
  String get processingContinue => 'Continue';

  @override
  String get processingStepReading => 'Reading your material...';

  @override
  String get processingStepReadingDone => 'Material analyzed';

  @override
  String get processingStepFlashcards => 'Generating flashcards...';

  @override
  String processingStepFlashcardsDone(int count) {
    return '$count flashcards created';
  }

  @override
  String get processingStepQuiz => 'Creating quiz questions...';

  @override
  String processingStepQuizDone(int count) {
    return '$count quiz questions ready';
  }

  @override
  String get processingStepPlan => 'Building your study plan...';

  @override
  String get processingStepPlanDone => 'Study plan ready!';

  @override
  String get socialProofTitle => 'Students love Kapsa';

  @override
  String socialProofFlashcardsReady(int count) {
    return 'students — your $count flashcards are ready!';
  }

  @override
  String get socialProofActiveStudents => 'active students';

  @override
  String get socialProofIn30Days => 'In 30 days';

  @override
  String get socialProofGradeImprovement => 'Average +40% grade improvement';

  @override
  String get testimonialSofiaName => 'Sofia M.';

  @override
  String get testimonialSofiaRole => 'Med Student';

  @override
  String get testimonialSofiaQuote =>
      'Kapsa changed the way I study. My grades improved so much in just one month.';

  @override
  String get testimonialMarcoName => 'Marco L.';

  @override
  String get testimonialMarcoRole => 'Engineering';

  @override
  String get testimonialMarcoQuote =>
      'I passed my finals thanks to the AI flashcards. Best study app ever.';

  @override
  String get testimonialLuciaName => 'Lucia R.';

  @override
  String get testimonialLuciaRole => 'Law Student';

  @override
  String get testimonialLuciaQuote =>
      'The Oracle is like having a personal tutor 24/7. Can\'t study without it now.';

  @override
  String get planReadyTitle => 'Your plan is\nready!';

  @override
  String get planReadyPersonalized => 'Personalized';

  @override
  String planReadyStudyArea(String area) {
    return 'Study area: $area';
  }

  @override
  String planReadyFocus(String challenge) {
    return 'Focus: $challenge';
  }

  @override
  String planReadyTime(String time) {
    return 'Time: $time per day';
  }

  @override
  String get planReadyAiTools => 'AI tools tailored just for you';

  @override
  String planReadyMaterial(int flashcards, int quizzes) {
    return '$flashcards flashcards & $quizzes quiz questions ready';
  }

  @override
  String get planReadyNotSet => 'Not set';

  @override
  String get planReadyUrgencyThisWeek =>
      'Your exam is this week — let\'s get you prepared!';

  @override
  String get planReadyUrgencyThisMonth =>
      'Your exam is this month — let\'s get you prepared!';

  @override
  String get rateTitle => 'Are you enjoying\nKapsa?';

  @override
  String get rateSubtitle => 'Help us grow';

  @override
  String get rateThankYou => 'Thank you for\nyour honesty';

  @override
  String get rateFeedbackHelps =>
      'Your feedback helps us build a better\nstudy experience for everyone.';

  @override
  String get rateLoveIt => 'Love it!';

  @override
  String get rateNotYet => 'Not yet';

  @override
  String get rateAwesome => 'Awesome! 🎉';

  @override
  String get rateAskStars =>
      'A 5-star rating helps us keep building\nAI tools that make studying easier.';

  @override
  String get rate5Stars => 'Rate 5 Stars ⭐';

  @override
  String get rateMaybeLater => 'Maybe later';

  @override
  String get rateHonestyAppreciated => 'We appreciate your honesty. 🙏';

  @override
  String get rateAlwaysImproving =>
      'We\'re always improving Kapsa.\nYour feedback helps us build the study\ntools you actually need.';

  @override
  String get rateWeShipUpdates => 'We ship updates every week';

  @override
  String get rateGetsBetter =>
      'Kapsa gets better with every\nstudent\'s feedback.';

  @override
  String get paywallKapsaPro => 'KAPSA PRO';

  @override
  String get paywallTitle => 'Unlock your\nfull potential';

  @override
  String get paywallFeature1 => 'Unlimited AI Oracle Chat';

  @override
  String get paywallFeature2 => 'Unlimited Flashcards & Quizzes';

  @override
  String get paywallFeature3 => 'Smart Study Plans';

  @override
  String get paywallFeature4 => 'Advanced Analytics & Insights';

  @override
  String get paywallFeature5 => 'Audio Summaries & Occlusion';

  @override
  String get paywallFeature6 => 'Unlimited Study Groups';

  @override
  String get paywallStudents => '50K+ students';

  @override
  String get paywallRating => '4.8';

  @override
  String get paywallStartTrial => 'Start 3-Day Free Trial';

  @override
  String get paywallSkip => 'Continue without Pro';

  @override
  String get paywallDisclaimer =>
      '3-day free trial · Cancel anytime · No charge today';

  @override
  String get captureProcessingPdf => 'Processing your PDF...';

  @override
  String get captureProcessingWhisper => 'Transcribing audio...';

  @override
  String get captureProcessingOcr => 'Analyzing your scan...';

  @override
  String get captureProcessingDone => 'All done!';

  @override
  String get captureSavingNote => 'Saving note...';

  @override
  String get capturePdfUploading => 'Uploading PDF...';

  @override
  String get capturePdfUploaded => 'PDF uploaded';

  @override
  String get capturePdfParsing => 'Parsing pages...';

  @override
  String get capturePdfParsed => 'Pages parsed';

  @override
  String get capturePdfAnalyzing => 'Analyzing structure...';

  @override
  String get capturePdfAnalyzed => 'Structure analyzed';

  @override
  String get capturePdfExtracting => 'AI extracting content...';

  @override
  String get capturePdfExtracted => 'Content extracted';

  @override
  String get capturePdfConcepts => 'Identifying key concepts...';

  @override
  String get capturePdfConceptsDone => 'Key concepts found';

  @override
  String get capturePdfFormatting => 'Formatting text...';

  @override
  String get capturePdfFormattingDone => 'Text formatted';

  @override
  String get capturePdfFinishing => 'Finishing up...';

  @override
  String get capturePdfReady => 'Ready!';

  @override
  String get captureWhisperUploading => 'Uploading audio...';

  @override
  String get captureWhisperUploaded => 'Audio uploaded';

  @override
  String get captureWhisperSignal => 'Processing audio signal...';

  @override
  String get captureWhisperSignalDone => 'Signal processed';

  @override
  String get captureWhisperSpeech => 'Detecting speech patterns...';

  @override
  String get captureWhisperSpeechDone => 'Speech detected';

  @override
  String get captureWhisperTranscribing => 'AI transcribing audio...';

  @override
  String get captureWhisperTranscribed => 'Audio transcribed';

  @override
  String get captureWhisperFormatting => 'Formatting transcript...';

  @override
  String get captureWhisperFormattingDone => 'Transcript formatted';

  @override
  String get captureWhisperCleaning => 'Cleaning up text...';

  @override
  String get captureWhisperCleaningDone => 'Text polished';

  @override
  String get captureWhisperFinishing => 'Finishing up...';

  @override
  String get captureWhisperReady => 'Ready!';

  @override
  String get captureOcrUploading => 'Uploading image...';

  @override
  String get captureOcrUploaded => 'Image uploaded';

  @override
  String get captureOcrScanning => 'Scanning document...';

  @override
  String get captureOcrScanned => 'Document scanned';

  @override
  String get captureOcrRecognizing => 'AI recognizing text...';

  @override
  String get captureOcrRecognized => 'Text recognized';

  @override
  String get captureOcrExtracting => 'Extracting key content...';

  @override
  String get captureOcrExtracted => 'Content extracted';

  @override
  String get captureOcrFormatting => 'Formatting results...';

  @override
  String get captureOcrFormattingDone => 'Results formatted';

  @override
  String get captureOcrOrganizing => 'Organizing material...';

  @override
  String get captureOcrOrganized => 'Material organized';

  @override
  String get captureOcrFinishing => 'Finishing up...';

  @override
  String get captureOcrReady => 'Ready!';
}
