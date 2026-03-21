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

  @override
  String get authWelcomeBack => 'Welcome back, scholar';

  @override
  String get authSignIn => 'Sign In';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authForgotPassword => 'Forgot Password?';

  @override
  String get authContinueWithApple => 'Continue with Apple';

  @override
  String get authOr => 'or';

  @override
  String get authNoAccount => 'Don\'t have an account? ';

  @override
  String get authCreateAccount => 'Create Account';

  @override
  String get authHaveAccount => 'Already have an account? ';

  @override
  String get authTermsOfService => 'Terms of Service';

  @override
  String get authPrivacyPolicy => 'Privacy Policy';

  @override
  String get authBeginJourney => 'Begin your journey to academic excellence';

  @override
  String get authFullName => 'Full Name';

  @override
  String get authConfirmPassword => 'Confirm Password';

  @override
  String get authAgreeToTerms => 'I agree to the ';

  @override
  String get authAnd => ' and ';

  @override
  String get authEmailRequired => 'Email is required';

  @override
  String get authValidEmail => 'Enter a valid email';

  @override
  String get authPasswordRequired => 'Password is required';

  @override
  String get authPasswordMinLength => 'Password must be at least 6 characters';

  @override
  String get authNameRequired => 'Name is required';

  @override
  String get authNameMinLength => 'Name must be at least 2 characters';

  @override
  String get authConfirmRequired => 'Please confirm your password';

  @override
  String get authPasswordMismatch => 'Passwords do not match';

  @override
  String get authAcceptTerms =>
      'Please accept the Terms of Service and Privacy Policy';

  @override
  String get authEnterEmailFirst => 'Enter your email first';

  @override
  String get authResetSent => 'Password reset email sent!';

  @override
  String get authAlreadyRegistered => 'This email is already registered';

  @override
  String get authWeakPassword => 'Password must be at least 6 characters';

  @override
  String get authNoInternet => 'No internet connection';

  @override
  String get authSomethingWrong => 'Something went wrong. Please try again.';

  @override
  String get practiceExamTitle => 'Practice Exam';

  @override
  String get practiceExamSelectCourse => 'SELECT COURSE';

  @override
  String get practiceExamQuestionCount => 'NUMBER OF QUESTIONS';

  @override
  String get practiceExamQuestions => 'questions';

  @override
  String get practiceExamTimeLimit => 'TIME LIMIT';

  @override
  String get practiceExamTime15 => '15 min';

  @override
  String get practiceExamTime30 => '30 min';

  @override
  String get practiceExamTime60 => '60 min';

  @override
  String get practiceExamNoLimit => 'No Limit';

  @override
  String get practiceExamStartExam => 'Start Exam';

  @override
  String get practiceExamSelectCourseFirst => 'Please select a course';

  @override
  String get practiceExamNoCourses =>
      'Create a course first to take a practice exam.';

  @override
  String get practiceExamSelectToStart => 'Select a course to start';

  @override
  String get practiceExamLoadingHistory => 'Loading history...';

  @override
  String get practiceExamFirstAttempt => 'First attempt — Good luck! 🍀';

  @override
  String get practiceExamKeepItUp => 'Keep it up!';

  @override
  String get practiceExamCanDoBetter => 'You can do better!';

  @override
  String get practiceExamPracticeMakesPerfect => 'Practice makes perfect!';

  @override
  String practiceExamLastScore(int pct, String encouragement) {
    return 'Last score: $pct% — $encouragement';
  }

  @override
  String get practiceExamEstimatedDifficulty => 'Estimated difficulty';

  @override
  String get practiceExamMedium => 'Medium';

  @override
  String quizQuestion(String current) {
    return 'Question $current';
  }

  @override
  String get quizTypeAnswer => 'Type your answer here...';

  @override
  String get quizAnswerHint =>
      'Answer in your own words. The AI will evaluate your understanding.';

  @override
  String get quizPrevious => 'Previous';

  @override
  String get quizNext => 'Next';

  @override
  String get quizSubmitExam => 'Submit Exam';

  @override
  String get quizSubmitQuiz => 'Submit Quiz';

  @override
  String get quizPerfectScore => 'Perfect Score! 🎉';

  @override
  String get quizPerfectSub => 'You nailed every question!';

  @override
  String get quizComplete => 'Quiz Complete';

  @override
  String get quizPerfect => '🏆 Perfect!';

  @override
  String get quizLeaveTitle => 'Leave quiz?';

  @override
  String get quizLeaveExamTitle => 'Leave Exam?';

  @override
  String get quizLeaveSaved =>
      'Your progress is saved! You can continue this quiz later from the home screen.';

  @override
  String get quizStay => 'Stay';

  @override
  String get quizContinueQuiz => 'Continue Quiz';

  @override
  String get quizLeaveForNow => 'Leave for now';

  @override
  String get quizCouldNotLoad => 'Could not load quiz';

  @override
  String get quizGoBack => 'Go Back';

  @override
  String get quizNoQuestions => 'No questions found';

  @override
  String quizAnswerQuestion(String number) {
    return 'Please answer question $number';
  }

  @override
  String quizAnswerQuestions(String numbers) {
    return 'Please answer questions $numbers';
  }

  @override
  String get quizDailyStreak => 'Daily Streak';

  @override
  String get chatSuggestStudyToday => 'What should I study today?';

  @override
  String get chatSuggestProgress => 'How am I doing overall?';

  @override
  String get chatSuggestWeakest => 'Explain my weakest topic';

  @override
  String get chatSuggestQuiz => 'Quiz me on this';

  @override
  String get chatSuggestSummarize => 'Summarize the material';

  @override
  String get chatFollowUpExample => 'Can you give an example?';

  @override
  String get chatFollowUpSimpler => 'Explain it more simply';

  @override
  String get chatFollowUpRelated => 'How does this relate to other topics?';

  @override
  String get homeFlashcards => 'FLASHCARDS';

  @override
  String homeDue(int count) {
    return '$count due';
  }

  @override
  String get homeSomethingWrong => 'Something went wrong';

  @override
  String get homeCheckConnection => 'Check your connection and try again';

  @override
  String get homeRetry => 'Retry';

  @override
  String get homeYourDecks => 'Your Decks';

  @override
  String get flashcardCreateNew => 'Create New';

  @override
  String get flashcardCreateDeck => 'Create Flashcard Deck';

  @override
  String get flashcardSelectCourse => 'Select a course';

  @override
  String get flashcardCardCount => 'Number of cards';

  @override
  String get flashcardCards => 'cards';

  @override
  String get flashcardGenerate => 'Generate Flashcards';

  @override
  String get flashcardUploadDoc => 'Upload notes (optional)';

  @override
  String get flashcardUploadHint => 'PDF or photo of your notes';

  @override
  String get flashcardUploadPdf => 'Upload PDF';

  @override
  String get flashcardUploadPhoto => 'Scan photo';

  @override
  String get flashcardUploadChange => 'Change';

  @override
  String get flashcardUploadProcessing => 'Processing document...';

  @override
  String get flashcardBookmarked => 'Card bookmarked';

  @override
  String get flashcardReshuffled => 'Cards reshuffled';

  @override
  String get quickActionSnapSolve => 'Snap Solve';

  @override
  String get quickActionOracle => 'Oracle';

  @override
  String get quickActionGroups => 'Groups';

  @override
  String get quickActionExam => 'Exam';

  @override
  String get greetingMorning => 'Good Morning';

  @override
  String get greetingAfternoon => 'Good Afternoon';

  @override
  String get greetingEvening => 'Good Evening';

  @override
  String streakDaysStreak(int count) {
    return '$count Days Streak';
  }

  @override
  String get streakOneDayStreak => '1 Day Streak';

  @override
  String streakLongest(int days) {
    return 'Longest streak: $days days';
  }

  @override
  String get streakStartToday => 'Start studying today to begin your streak!';

  @override
  String streakKeepGoing(int remaining, String dayWord, String milestone) {
    return 'Keep going! $remaining more $dayWord to your $milestone badge!';
  }

  @override
  String get streakCheckHeatmap =>
      'Check your Study Heatmap on the home screen';

  @override
  String get streakGotIt => 'Got it';

  @override
  String get streakDay => 'day';

  @override
  String get streakDays => 'days';

  @override
  String get journeyLearningJourney => 'Learning Journey';

  @override
  String journeyProgress(int percent) {
    return '$percent% JOURNEY';
  }

  @override
  String journeyLevel(int level) {
    return 'LEVEL $level';
  }

  @override
  String get journeyTodaysChallenge => 'TODAY\'S CHALLENGE';

  @override
  String journeyCompleteAll(int xp) {
    return 'Complete all for +$xp XP bonus';
  }

  @override
  String get journeyUpNext => 'UP NEXT';

  @override
  String get journeyStart => 'START';

  @override
  String get journeyStartExam => 'START EXAM';

  @override
  String get journeyOpen => 'OPEN';

  @override
  String get journeyFinalExam => 'Final Exam';

  @override
  String get journeyComprehensiveTest => 'Comprehensive test';

  @override
  String get journeyRewardChest => 'Reward Chest';

  @override
  String get journeyNoContent => 'No content yet';

  @override
  String get journeyUploadMaterials =>
      'Upload materials to generate your learning journey';

  @override
  String get journeyUploadMaterial => 'Upload Material';

  @override
  String get journeyCouldNotLoad => 'Could not load journey';

  @override
  String get journeyGenerating => 'Generating your learning journey...';

  @override
  String get journeyComplete => 'Journey Complete!';

  @override
  String get journeyReviewJourney => 'Review Journey';

  @override
  String get journeyContinue => 'Continue Journey';

  @override
  String get journeyReviewFlashcards => 'Review Flashcards';

  @override
  String get journeyTakeQuiz => 'Take Quiz';

  @override
  String get journeyReviewMaterial => 'Review Material';

  @override
  String get journeyReadSummary => 'Read Summary';

  @override
  String get journeyAskOracle => 'Ask the Oracle';

  @override
  String get journeyTakeCheckpoint => 'Take Checkpoint';

  @override
  String get journeyClaimReward => 'Claim Reward';

  @override
  String get journeyStartFinalExam => 'Start Final Exam';

  @override
  String get journeyCompletePrevious => 'Complete the previous step first';

  @override
  String get journeyExamToday => 'Exam is today!';

  @override
  String journeyDaysToExam(int days, String suffix) {
    return '$days day$suffix to exam';
  }

  @override
  String get journeyQuickQuestions => '5 quick questions';

  @override
  String get journeyCheckpoint => 'Checkpoint';

  @override
  String journeyReview(String title) {
    return 'Review: $title';
  }

  @override
  String journeyFlashcards(String title) {
    return 'Flashcards: $title';
  }

  @override
  String journeyCards(int count) {
    return '$count cards';
  }

  @override
  String get journeyPracticeQuiz => 'Practice Quiz';

  @override
  String get journeyTestKnowledge => 'Test your knowledge';

  @override
  String get journeyAiQA => 'AI-powered Q&A';

  @override
  String get journeyPdfDocument => 'PDF Document';

  @override
  String get journeyAudio => 'Audio';

  @override
  String get journeyNotes => 'Notes';

  @override
  String get journeyPastedText => 'Pasted Text';

  @override
  String get journeyMaterial => 'Material';

  @override
  String get journeyFillGaps => 'Fill the Gaps';

  @override
  String get journeyFillGapsSub => 'Complete the missing terms';

  @override
  String get journeySpeedRound => 'Speed Round';

  @override
  String get journeySpeedRoundSub => '10 true/false in 50 seconds';

  @override
  String get journeyMistakeSpotter => 'Mistake Spotter';

  @override
  String get journeyMistakeSpotterSub => 'Find the errors';

  @override
  String get journeyTeachBot => 'Teach the Bot';

  @override
  String get journeyTeachBotSub => 'Explain it in your words';

  @override
  String get journeyCompareContrast => 'Compare & Contrast';

  @override
  String get journeyCompareContrastSub => 'Sort the differences';

  @override
  String get journeyTimelineBuilder => 'Timeline Builder';

  @override
  String get journeyTimelineBuilderSub => 'Put steps in order';

  @override
  String get journeyCaseStudy => 'Case Study';

  @override
  String get journeyCaseStudySub => 'Apply your knowledge';

  @override
  String get journeyMatchBlitz => 'Match Blitz';

  @override
  String get journeyMatchBlitzSub => 'Pair concepts fast';

  @override
  String get journeyConceptMapper => 'Concept Map';

  @override
  String get journeyConceptMapperSub => 'Connect the ideas';

  @override
  String get journeyDailyChallenge => 'Daily Challenge';

  @override
  String get journeyDailyChallengeSub => 'Today\'s personalized exercise';

  @override
  String get journeyStartFillGaps => 'Start Fill the Gaps';

  @override
  String get journeyStartSpeedRound => 'Start Speed Round';

  @override
  String get journeyStartMistakeSpotter => 'Start Mistake Spotter';

  @override
  String get journeyStartTeachBot => 'Start Teaching';

  @override
  String get journeyStartCompareContrast => 'Start Comparing';

  @override
  String get journeyStartTimelineBuilder => 'Start Timeline';

  @override
  String get journeyStartCaseStudy => 'Start Case Study';

  @override
  String get journeyStartMatchBlitz => 'Start Match Blitz';

  @override
  String get journeyStartConceptMapper => 'Start Concept Map';

  @override
  String get journeyStartDailyChallenge => 'Start Challenge';

  @override
  String get journeyDifficultyEasy => 'Easy';

  @override
  String get journeyDifficultyMedium => 'Medium';

  @override
  String get journeyDifficultyHard => 'Hard';

  @override
  String journeyStreakMultiplier(int multiplier) {
    return 'x$multiplier XP';
  }

  @override
  String get journeyStreakBonus => 'Streak Bonus!';

  @override
  String get journeyInsights => 'Progress Insights';

  @override
  String get journeyMastered => 'Mastered';

  @override
  String get journeyNeedsWork => 'Needs Work';

  @override
  String get journeyTimeStudied => 'Time studied';

  @override
  String get journeyThisWeek => 'this week';

  @override
  String get journeyPredictedScore => 'Predicted exam score';

  @override
  String get journeyWeeklyGoal => 'Weekly goal';

  @override
  String get journeyBossPreview => 'Exam Topics';

  @override
  String get journeyConfidence => 'Confidence';

  @override
  String get journeyReviewWeak => 'Review Weak Topics';

  @override
  String get journeyRecapTitle => 'Weekly Recap';

  @override
  String journeyRecapNodesCompleted(int count) {
    return '$count nodes completed';
  }

  @override
  String journeyRecapXpEarned(int xp) {
    return '$xp XP earned';
  }

  @override
  String get journeyRecapNewTopics => 'New topics';

  @override
  String get journeyRecapReviewed => 'Reviewed';

  @override
  String get journeyMicroReviewTitle => 'Review';

  @override
  String journeyMicroReviewCompleted(String date) {
    return 'Completed $date';
  }

  @override
  String journeyMicroReviewScore(int score) {
    return 'Score: $score%';
  }

  @override
  String get journeyMicroReviewRedo => 'Redo Exercise';

  @override
  String get journeyMicroReviewNoScore => 'No score recorded';

  @override
  String get journeyFabContinue => 'Continue';

  @override
  String get journeyFabReview => 'Review';

  @override
  String get journeyFabQuickChallenge => 'Quick Challenge';

  @override
  String get exerciseCorrect => 'Correct!';

  @override
  String get exerciseIncorrect => 'Incorrect';

  @override
  String exerciseScore(int score) {
    return 'Score: $score%';
  }

  @override
  String get exerciseComplete => 'Exercise Complete!';

  @override
  String exerciseImproved(int percent) {
    return 'You improved $percent% vs last time!';
  }

  @override
  String exerciseMastered(int count, int total) {
    return 'Mastered $count/$total concepts';
  }

  @override
  String get exerciseTimeUp => 'Time\'s up!';

  @override
  String get exerciseSubmit => 'Submit';

  @override
  String get exerciseNext => 'Next';

  @override
  String get exerciseFinish => 'Finish';

  @override
  String get exerciseTryAgain => 'Try Again';

  @override
  String get exerciseCheckAnswer => 'Check Answer';

  @override
  String get exerciseTrue => 'True';

  @override
  String get exerciseFalse => 'False';

  @override
  String get exerciseGoodJob => 'Good job!';

  @override
  String get exerciseKeepPracticing => 'Keep practicing!';

  @override
  String get exerciseExcellent => 'Excellent!';

  @override
  String get exerciseNeedsImprovement => 'Needs improvement';

  @override
  String get exerciseLoading => 'Generating exercise...';

  @override
  String get exerciseCouldNotLoad => 'Could not load exercise';

  @override
  String get fillGapsInstruction => 'Fill in the blanks with the correct terms';

  @override
  String get fillGapsHint => 'Type the missing word';

  @override
  String fillGapsOf(int current, int total) {
    return '$current of $total';
  }

  @override
  String get speedRoundInstruction =>
      'True or False? You have 5 seconds per question!';

  @override
  String get speedRoundReady => 'Ready?';

  @override
  String get speedRoundGo => 'GO!';

  @override
  String speedRoundResult(int correct, int total) {
    return '$correct/$total correct';
  }

  @override
  String speedRoundAvgTime(String seconds) {
    return 'Avg. ${seconds}s per question';
  }

  @override
  String mistakeSpotterInstruction(int count) {
    return 'Find $count mistakes in the text below';
  }

  @override
  String mistakeSpotterFound(int found, int total) {
    return '$found/$total mistakes found';
  }

  @override
  String get mistakeSpotterTapToMark => 'Tap on sentences to mark mistakes';

  @override
  String get mistakeSpotterCorrection => 'Correction';

  @override
  String get mistakeSpotterWrongSelection =>
      'This sentence is actually correct';

  @override
  String get teachBotInstruction =>
      'Explain this concept to the bot as if teaching a confused student';

  @override
  String get teachBotBotMessage =>
      'I\'m confused about this topic. Can you explain it to me?';

  @override
  String get teachBotSendExplanation => 'Send explanation';

  @override
  String get teachBotFeedback => 'The bot analyzed your explanation';

  @override
  String teachBotCoveredPoints(int count, int total) {
    return '$count/$total key points covered';
  }

  @override
  String teachBotMissedPoint(String point) {
    return 'You didn\'t mention: $point';
  }

  @override
  String get compareContrastInstruction =>
      'Sort these traits into the correct category';

  @override
  String get compareContrastDragHint => 'Drag items to the correct column';

  @override
  String get timelineInstruction => 'Arrange these steps in the correct order';

  @override
  String get timelineDragHint => 'Drag to reorder';

  @override
  String get timelineCheckOrder => 'Check Order';

  @override
  String get timelineCorrectOrder => 'Correct order!';

  @override
  String get timelineWrongOrder => 'Not quite right. Try again!';

  @override
  String get caseStudyScenario => 'Scenario';

  @override
  String caseStudyQuestion(int num) {
    return 'Question $num';
  }

  @override
  String get caseStudyAnswer => 'Your answer';

  @override
  String get matchBlitzInstruction => 'Match concepts with their definitions';

  @override
  String matchBlitzPairsLeft(int count) {
    return '$count pairs left';
  }

  @override
  String matchBlitzTimeBonus(int xp) {
    return 'Time bonus: +$xp XP';
  }

  @override
  String get conceptMapInstruction =>
      'Connect the missing links in the concept map';

  @override
  String get conceptMapDragToConnect => 'Drag to connect nodes';

  @override
  String get chatAiOracle => 'AI Oracle';

  @override
  String get chatTheOracle => 'The Oracle';

  @override
  String get chatSettingsComingSoon => 'Chat settings coming soon';

  @override
  String get chatToday => 'Today';

  @override
  String get chatStudyCompanion => 'Your AI study companion';

  @override
  String get chatStudyCompanionSub =>
      'Ask questions, get explanations, and ace your exams.';

  @override
  String get chatOracleKnows => 'The Oracle knows everything';

  @override
  String get chatOracleKnowsSub =>
      'Ask about your courses, scores, weak areas, and upcoming exams.';

  @override
  String get flashcardLoadError => 'Could not load flashcards';

  @override
  String get flashcardNoCards => 'No flashcards yet';

  @override
  String get flashcardNoCardsHint =>
      'Generate flashcards from your course materials first.';

  @override
  String get flashcardLeaveTitle => 'Leave session?';

  @override
  String get flashcardLeaveMessage =>
      'Your progress in this session will be lost.';

  @override
  String get flashcardStay => 'Stay';

  @override
  String get flashcardLeave => 'Leave';

  @override
  String get flashcardEditComingSoon => 'Edit cards coming soon';

  @override
  String get flashcardSessionComplete => 'Session Complete!';

  @override
  String flashcardCardsReviewed(int count) {
    return '$count cards reviewed';
  }

  @override
  String get flashcardMastered => 'Mastered';

  @override
  String get flashcardAgain => 'Again';

  @override
  String get flashcardMasteryLabel => 'Mastery';

  @override
  String get flashcardShareResults => 'Share Results';

  @override
  String get flashcardContinueReviewing => 'Continue Reviewing';

  @override
  String get flashcardDone => 'Done';

  @override
  String get homeDefaultName => 'Student';

  @override
  String get exerciseDifficultyTitle => 'Choose Difficulty';

  @override
  String get exerciseDifficultyEasy => 'Easy';

  @override
  String get exerciseDifficultyEasyDesc => 'More time, hints available';

  @override
  String get exerciseDifficultyMedium => 'Medium';

  @override
  String get exerciseDifficultyMediumDesc => 'Standard challenge';

  @override
  String get exerciseDifficultyHard => 'Hard';

  @override
  String get exerciseDifficultyHardDesc => 'Less time, no hints';

  @override
  String get exerciseDifficultyStart => 'Start Exercise';

  @override
  String exerciseComboStreak(int count) {
    return '$count in a row!';
  }

  @override
  String exerciseComboBonusXp(int xp) {
    return '+$xp bonus XP';
  }

  @override
  String get exerciseRelatedTitle => 'Want to learn more?';

  @override
  String get exerciseRelatedSummary => 'View Summary';

  @override
  String get exerciseRelatedFlashcards => 'Practice Flashcards';

  @override
  String get exerciseRelatedGlossary => 'Read Glossary';

  @override
  String get chatPreferencesTitle => 'Chat Preferences';

  @override
  String get chatResponseStyle => 'Response Style';

  @override
  String get chatStyleBrief => 'Brief';

  @override
  String get chatStyleBriefDesc => 'Short, concise answers';

  @override
  String get chatStyleDetailed => 'Detailed';

  @override
  String get chatStyleDetailedDesc => 'In-depth explanations';

  @override
  String get chatStyleEli5 => 'ELI5';

  @override
  String get chatStyleEli5Desc => 'Explain like I\'m 5';

  @override
  String get chatIncludeExamples => 'Include Examples';

  @override
  String get chatIncludeExamplesDesc => 'Add practical examples to responses';

  @override
  String get chatPreferencesSaved => 'Preferences saved';

  @override
  String get chatLongPressToClear => 'Long-press to clear';

  @override
  String chatCharCount(String count, String max) {
    return '$count/$max';
  }

  @override
  String get postUploadMaterialUploaded => 'Material uploaded';

  @override
  String get postUploadWhatToCreate => 'What do you want to create?';

  @override
  String get postUploadFlashcards => 'Flashcards';

  @override
  String get postUploadQuiz => 'Quiz';

  @override
  String get postUploadSummary => 'Summary';

  @override
  String get postUploadGlossary => 'Glossary';

  @override
  String get postUploadCreateCards => 'Create study cards';

  @override
  String get postUploadTestKnowledge => 'Test your knowledge';

  @override
  String get postUploadKeyPoints => 'Key points overview';

  @override
  String get postUploadKeyTerms => 'Key terms defined';

  @override
  String get postUploadMoreTools => 'More tools';

  @override
  String get postUploadSrsReview => 'SRS Review';

  @override
  String get postUploadPracticeExam => 'Practice Exam';

  @override
  String get postUploadAudioSummary => 'Audio Summary';

  @override
  String get postUploadSnapSolve => 'Snap & Solve';

  @override
  String get postUploadChat => 'Chat';

  @override
  String get postUploadSkip => 'Skip';

  @override
  String postUploadGeneratingInBackground(String tool) {
    return 'Generating $tool in background...';
  }

  @override
  String get postUploadHowManyFlashcards => 'How many flashcards?';

  @override
  String get postUploadChooseCount => 'Choose the number of cards to generate';

  @override
  String get postUploadPro => 'PRO';

  @override
  String postUploadGenerateFlashcards(int count) {
    return 'Generate $count Flashcards';
  }

  @override
  String homeDueCardsBanner(int count) {
    return '$count cards due for review';
  }

  @override
  String get homeDueCardsReviewNow => 'Review now';

  @override
  String get homeMyCourses => 'My Courses';

  @override
  String get trialNotifDay0Title => 'Your study plan is ready!';

  @override
  String get trialNotifDay0Body => 'Generate your first flashcards now';

  @override
  String get trialNotifDay1Title => 'Did you know?';

  @override
  String get trialNotifDay1Body =>
      'Students who use flashcards score 23% higher. Try generating a quiz!';

  @override
  String get trialNotifDay2Title => 'Have you tried Snap & Solve?';

  @override
  String get trialNotifDay2Body =>
      'Take a photo of any problem and get a step-by-step solution';

  @override
  String get trialNotifLastDayTitle => 'Last day of your trial!';

  @override
  String get trialNotifLastDayBody =>
      'Make the most of it — generate flashcards, quizzes, and summaries';

  @override
  String get trialNotif2DaysLeftTitle => '2 days left on your trial';

  @override
  String get trialNotif2DaysLeftBody =>
      'Don\'t miss out — explore all the AI tools before it ends';
}
