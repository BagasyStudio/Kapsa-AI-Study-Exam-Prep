import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get commonSkip;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingAlmostThere.
  ///
  /// In en, this message translates to:
  /// **'Almost There'**
  String get onboardingAlmostThere;

  /// No description provided for @onboardingStartStudying.
  ///
  /// In en, this message translates to:
  /// **'Start Studying 🚀'**
  String get onboardingStartStudying;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your smart study companion.\nAI-powered tools to ace exams\nand boost your GPA.'**
  String get welcomeSubtitle;

  /// No description provided for @welcomeTo.
  ///
  /// In en, this message translates to:
  /// **'Welcome '**
  String get welcomeTo;

  /// No description provided for @welcomeToWord.
  ///
  /// In en, this message translates to:
  /// **'to '**
  String get welcomeToWord;

  /// No description provided for @welcomeBrand.
  ///
  /// In en, this message translates to:
  /// **'Kapsa'**
  String get welcomeBrand;

  /// No description provided for @examUrgencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Do you have an\nexam coming up?'**
  String get examUrgencyTitle;

  /// No description provided for @examUrgencySubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll prioritize what matters most.'**
  String get examUrgencySubtitle;

  /// No description provided for @examUrgencyThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get examUrgencyThisWeek;

  /// No description provided for @examUrgencyThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get examUrgencyThisMonth;

  /// No description provided for @examUrgencyFewMonths.
  ///
  /// In en, this message translates to:
  /// **'In a few months'**
  String get examUrgencyFewMonths;

  /// No description provided for @examUrgencyNoExams.
  ///
  /// In en, this message translates to:
  /// **'No exams yet'**
  String get examUrgencyNoExams;

  /// No description provided for @studyAreaTitle.
  ///
  /// In en, this message translates to:
  /// **'What do you\nstudy?'**
  String get studyAreaTitle;

  /// No description provided for @studyAreaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customize your experience by choosing\nyour study area.'**
  String get studyAreaSubtitle;

  /// No description provided for @studyAreaSciences.
  ///
  /// In en, this message translates to:
  /// **'Sciences'**
  String get studyAreaSciences;

  /// No description provided for @studyAreaEngineering.
  ///
  /// In en, this message translates to:
  /// **'Engineering'**
  String get studyAreaEngineering;

  /// No description provided for @studyAreaLaw.
  ///
  /// In en, this message translates to:
  /// **'Law'**
  String get studyAreaLaw;

  /// No description provided for @studyAreaMedicine.
  ///
  /// In en, this message translates to:
  /// **'Medicine'**
  String get studyAreaMedicine;

  /// No description provided for @studyAreaEconomics.
  ///
  /// In en, this message translates to:
  /// **'Economics'**
  String get studyAreaEconomics;

  /// No description provided for @studyAreaArts.
  ///
  /// In en, this message translates to:
  /// **'Arts'**
  String get studyAreaArts;

  /// No description provided for @studyAreaCS.
  ///
  /// In en, this message translates to:
  /// **'Computer Science'**
  String get studyAreaCS;

  /// No description provided for @studyAreaOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get studyAreaOther;

  /// No description provided for @challengeTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s your\nbiggest challenge?'**
  String get challengeTitle;

  /// No description provided for @challengeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll figure out how to help you best.'**
  String get challengeSubtitle;

  /// No description provided for @challengeMemorizing.
  ///
  /// In en, this message translates to:
  /// **'I struggle to memorize'**
  String get challengeMemorizing;

  /// No description provided for @challengeTime.
  ///
  /// In en, this message translates to:
  /// **'I don\'t have time'**
  String get challengeTime;

  /// No description provided for @challengeBored.
  ///
  /// In en, this message translates to:
  /// **'I get bored studying'**
  String get challengeBored;

  /// No description provided for @challengeNotes.
  ///
  /// In en, this message translates to:
  /// **'I can\'t organize my notes'**
  String get challengeNotes;

  /// No description provided for @challengeExams.
  ///
  /// In en, this message translates to:
  /// **'Exams are coming soon'**
  String get challengeExams;

  /// No description provided for @challengeStart.
  ///
  /// In en, this message translates to:
  /// **'I don\'t know where to start'**
  String get challengeStart;

  /// No description provided for @studyTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'How much do you\nstudy per day?'**
  String get studyTimeTitle;

  /// No description provided for @studyTimeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll adapt your plan to your routine.'**
  String get studyTimeSubtitle;

  /// No description provided for @studyTimePerDay.
  ///
  /// In en, this message translates to:
  /// **'{time} per day'**
  String studyTimePerDay(String time);

  /// No description provided for @studyTime30min.
  ///
  /// In en, this message translates to:
  /// **'30 min'**
  String get studyTime30min;

  /// No description provided for @studyTime1h.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get studyTime1h;

  /// No description provided for @studyTime2h.
  ///
  /// In en, this message translates to:
  /// **'2 hours'**
  String get studyTime2h;

  /// No description provided for @studyTime3h.
  ///
  /// In en, this message translates to:
  /// **'3 hours'**
  String get studyTime3h;

  /// No description provided for @studyTime5h.
  ///
  /// In en, this message translates to:
  /// **'5 hours'**
  String get studyTime5h;

  /// No description provided for @studyTime8h.
  ///
  /// In en, this message translates to:
  /// **'8 hours'**
  String get studyTime8h;

  /// No description provided for @studyTimeSub30.
  ///
  /// In en, this message translates to:
  /// **'Quick sessions'**
  String get studyTimeSub30;

  /// No description provided for @studyTimeSub1.
  ///
  /// In en, this message translates to:
  /// **'Steady pace'**
  String get studyTimeSub1;

  /// No description provided for @studyTimeSub2.
  ///
  /// In en, this message translates to:
  /// **'Focused study'**
  String get studyTimeSub2;

  /// No description provided for @studyTimeSub3.
  ///
  /// In en, this message translates to:
  /// **'Dedicated learner'**
  String get studyTimeSub3;

  /// No description provided for @studyTimeSub5.
  ///
  /// In en, this message translates to:
  /// **'Power student'**
  String get studyTimeSub5;

  /// No description provided for @studyTimeSub8.
  ///
  /// In en, this message translates to:
  /// **'Full commitment'**
  String get studyTimeSub8;

  /// No description provided for @uploadTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload your first\nstudy material'**
  String get uploadTitle;

  /// No description provided for @uploadSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Kapsa will create flashcards, quizzes\nand a study plan from it.'**
  String get uploadSubtitle;

  /// No description provided for @uploadScanPages.
  ///
  /// In en, this message translates to:
  /// **'Scan pages'**
  String get uploadScanPages;

  /// No description provided for @uploadScanSub.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of your notes'**
  String get uploadScanSub;

  /// No description provided for @uploadPdf.
  ///
  /// In en, this message translates to:
  /// **'Upload PDF'**
  String get uploadPdf;

  /// No description provided for @uploadPdfSub.
  ///
  /// In en, this message translates to:
  /// **'Choose a file from your device'**
  String get uploadPdfSub;

  /// No description provided for @processingTitle.
  ///
  /// In en, this message translates to:
  /// **'Creating your\nstudy toolkit...'**
  String get processingTitle;

  /// No description provided for @processingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get processingContinue;

  /// No description provided for @processingStepReading.
  ///
  /// In en, this message translates to:
  /// **'Reading your material...'**
  String get processingStepReading;

  /// No description provided for @processingStepReadingDone.
  ///
  /// In en, this message translates to:
  /// **'Material analyzed'**
  String get processingStepReadingDone;

  /// No description provided for @processingStepFlashcards.
  ///
  /// In en, this message translates to:
  /// **'Generating flashcards...'**
  String get processingStepFlashcards;

  /// No description provided for @processingStepFlashcardsDone.
  ///
  /// In en, this message translates to:
  /// **'{count} flashcards created'**
  String processingStepFlashcardsDone(int count);

  /// No description provided for @processingStepQuiz.
  ///
  /// In en, this message translates to:
  /// **'Creating quiz questions...'**
  String get processingStepQuiz;

  /// No description provided for @processingStepQuizDone.
  ///
  /// In en, this message translates to:
  /// **'{count} quiz questions ready'**
  String processingStepQuizDone(int count);

  /// No description provided for @processingStepPlan.
  ///
  /// In en, this message translates to:
  /// **'Building your study plan...'**
  String get processingStepPlan;

  /// No description provided for @processingStepPlanDone.
  ///
  /// In en, this message translates to:
  /// **'Study plan ready!'**
  String get processingStepPlanDone;

  /// No description provided for @socialProofTitle.
  ///
  /// In en, this message translates to:
  /// **'Students love Kapsa'**
  String get socialProofTitle;

  /// No description provided for @socialProofFlashcardsReady.
  ///
  /// In en, this message translates to:
  /// **'students — your {count} flashcards are ready!'**
  String socialProofFlashcardsReady(int count);

  /// No description provided for @socialProofActiveStudents.
  ///
  /// In en, this message translates to:
  /// **'active students'**
  String get socialProofActiveStudents;

  /// No description provided for @socialProofIn30Days.
  ///
  /// In en, this message translates to:
  /// **'In 30 days'**
  String get socialProofIn30Days;

  /// No description provided for @socialProofGradeImprovement.
  ///
  /// In en, this message translates to:
  /// **'Average +40% grade improvement'**
  String get socialProofGradeImprovement;

  /// No description provided for @testimonialSofiaName.
  ///
  /// In en, this message translates to:
  /// **'Sofia M.'**
  String get testimonialSofiaName;

  /// No description provided for @testimonialSofiaRole.
  ///
  /// In en, this message translates to:
  /// **'Med Student'**
  String get testimonialSofiaRole;

  /// No description provided for @testimonialSofiaQuote.
  ///
  /// In en, this message translates to:
  /// **'Kapsa changed the way I study. My grades improved so much in just one month.'**
  String get testimonialSofiaQuote;

  /// No description provided for @testimonialMarcoName.
  ///
  /// In en, this message translates to:
  /// **'Marco L.'**
  String get testimonialMarcoName;

  /// No description provided for @testimonialMarcoRole.
  ///
  /// In en, this message translates to:
  /// **'Engineering'**
  String get testimonialMarcoRole;

  /// No description provided for @testimonialMarcoQuote.
  ///
  /// In en, this message translates to:
  /// **'I passed my finals thanks to the AI flashcards. Best study app ever.'**
  String get testimonialMarcoQuote;

  /// No description provided for @testimonialLuciaName.
  ///
  /// In en, this message translates to:
  /// **'Lucia R.'**
  String get testimonialLuciaName;

  /// No description provided for @testimonialLuciaRole.
  ///
  /// In en, this message translates to:
  /// **'Law Student'**
  String get testimonialLuciaRole;

  /// No description provided for @testimonialLuciaQuote.
  ///
  /// In en, this message translates to:
  /// **'The Oracle is like having a personal tutor 24/7. Can\'t study without it now.'**
  String get testimonialLuciaQuote;

  /// No description provided for @planReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your plan is\nready!'**
  String get planReadyTitle;

  /// No description provided for @planReadyPersonalized.
  ///
  /// In en, this message translates to:
  /// **'Personalized'**
  String get planReadyPersonalized;

  /// No description provided for @planReadyStudyArea.
  ///
  /// In en, this message translates to:
  /// **'Study area: {area}'**
  String planReadyStudyArea(String area);

  /// No description provided for @planReadyFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus: {challenge}'**
  String planReadyFocus(String challenge);

  /// No description provided for @planReadyTime.
  ///
  /// In en, this message translates to:
  /// **'Time: {time} per day'**
  String planReadyTime(String time);

  /// No description provided for @planReadyAiTools.
  ///
  /// In en, this message translates to:
  /// **'AI tools tailored just for you'**
  String get planReadyAiTools;

  /// No description provided for @planReadyMaterial.
  ///
  /// In en, this message translates to:
  /// **'{flashcards} flashcards & {quizzes} quiz questions ready'**
  String planReadyMaterial(int flashcards, int quizzes);

  /// No description provided for @planReadyNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get planReadyNotSet;

  /// No description provided for @planReadyUrgencyThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Your exam is this week — let\'s get you prepared!'**
  String get planReadyUrgencyThisWeek;

  /// No description provided for @planReadyUrgencyThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Your exam is this month — let\'s get you prepared!'**
  String get planReadyUrgencyThisMonth;

  /// No description provided for @rateTitle.
  ///
  /// In en, this message translates to:
  /// **'Are you enjoying\nKapsa?'**
  String get rateTitle;

  /// No description provided for @rateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Help us grow'**
  String get rateSubtitle;

  /// No description provided for @rateThankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you for\nyour honesty'**
  String get rateThankYou;

  /// No description provided for @rateFeedbackHelps.
  ///
  /// In en, this message translates to:
  /// **'Your feedback helps us build a better\nstudy experience for everyone.'**
  String get rateFeedbackHelps;

  /// No description provided for @rateLoveIt.
  ///
  /// In en, this message translates to:
  /// **'Love it!'**
  String get rateLoveIt;

  /// No description provided for @rateNotYet.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get rateNotYet;

  /// No description provided for @rateAwesome.
  ///
  /// In en, this message translates to:
  /// **'Awesome! 🎉'**
  String get rateAwesome;

  /// No description provided for @rateAskStars.
  ///
  /// In en, this message translates to:
  /// **'A 5-star rating helps us keep building\nAI tools that make studying easier.'**
  String get rateAskStars;

  /// No description provided for @rate5Stars.
  ///
  /// In en, this message translates to:
  /// **'Rate 5 Stars ⭐'**
  String get rate5Stars;

  /// No description provided for @rateMaybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get rateMaybeLater;

  /// No description provided for @rateHonestyAppreciated.
  ///
  /// In en, this message translates to:
  /// **'We appreciate your honesty. 🙏'**
  String get rateHonestyAppreciated;

  /// No description provided for @rateAlwaysImproving.
  ///
  /// In en, this message translates to:
  /// **'We\'re always improving Kapsa.\nYour feedback helps us build the study\ntools you actually need.'**
  String get rateAlwaysImproving;

  /// No description provided for @rateWeShipUpdates.
  ///
  /// In en, this message translates to:
  /// **'We ship updates every week'**
  String get rateWeShipUpdates;

  /// No description provided for @rateGetsBetter.
  ///
  /// In en, this message translates to:
  /// **'Kapsa gets better with every\nstudent\'s feedback.'**
  String get rateGetsBetter;

  /// No description provided for @paywallKapsaPro.
  ///
  /// In en, this message translates to:
  /// **'KAPSA PRO'**
  String get paywallKapsaPro;

  /// No description provided for @paywallTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock your\nfull potential'**
  String get paywallTitle;

  /// No description provided for @paywallFeature1.
  ///
  /// In en, this message translates to:
  /// **'Unlimited AI Oracle Chat'**
  String get paywallFeature1;

  /// No description provided for @paywallFeature2.
  ///
  /// In en, this message translates to:
  /// **'Unlimited Flashcards & Quizzes'**
  String get paywallFeature2;

  /// No description provided for @paywallFeature3.
  ///
  /// In en, this message translates to:
  /// **'Smart Study Plans'**
  String get paywallFeature3;

  /// No description provided for @paywallFeature4.
  ///
  /// In en, this message translates to:
  /// **'Advanced Analytics & Insights'**
  String get paywallFeature4;

  /// No description provided for @paywallFeature5.
  ///
  /// In en, this message translates to:
  /// **'Audio Summaries & Occlusion'**
  String get paywallFeature5;

  /// No description provided for @paywallFeature6.
  ///
  /// In en, this message translates to:
  /// **'Unlimited Study Groups'**
  String get paywallFeature6;

  /// No description provided for @paywallStudents.
  ///
  /// In en, this message translates to:
  /// **'50K+ students'**
  String get paywallStudents;

  /// No description provided for @paywallRating.
  ///
  /// In en, this message translates to:
  /// **'4.8'**
  String get paywallRating;

  /// No description provided for @paywallStartTrial.
  ///
  /// In en, this message translates to:
  /// **'Start 3-Day Free Trial'**
  String get paywallStartTrial;

  /// No description provided for @paywallSkip.
  ///
  /// In en, this message translates to:
  /// **'Continue without Pro'**
  String get paywallSkip;

  /// No description provided for @paywallDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'3-day free trial · Cancel anytime · No charge today'**
  String get paywallDisclaimer;

  /// No description provided for @captureProcessingPdf.
  ///
  /// In en, this message translates to:
  /// **'Processing your PDF...'**
  String get captureProcessingPdf;

  /// No description provided for @captureProcessingWhisper.
  ///
  /// In en, this message translates to:
  /// **'Transcribing audio...'**
  String get captureProcessingWhisper;

  /// No description provided for @captureProcessingOcr.
  ///
  /// In en, this message translates to:
  /// **'Analyzing your scan...'**
  String get captureProcessingOcr;

  /// No description provided for @captureProcessingDone.
  ///
  /// In en, this message translates to:
  /// **'All done!'**
  String get captureProcessingDone;

  /// No description provided for @captureSavingNote.
  ///
  /// In en, this message translates to:
  /// **'Saving note...'**
  String get captureSavingNote;

  /// No description provided for @capturePdfUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading PDF...'**
  String get capturePdfUploading;

  /// No description provided for @capturePdfUploaded.
  ///
  /// In en, this message translates to:
  /// **'PDF uploaded'**
  String get capturePdfUploaded;

  /// No description provided for @capturePdfParsing.
  ///
  /// In en, this message translates to:
  /// **'Parsing pages...'**
  String get capturePdfParsing;

  /// No description provided for @capturePdfParsed.
  ///
  /// In en, this message translates to:
  /// **'Pages parsed'**
  String get capturePdfParsed;

  /// No description provided for @capturePdfAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing structure...'**
  String get capturePdfAnalyzing;

  /// No description provided for @capturePdfAnalyzed.
  ///
  /// In en, this message translates to:
  /// **'Structure analyzed'**
  String get capturePdfAnalyzed;

  /// No description provided for @capturePdfExtracting.
  ///
  /// In en, this message translates to:
  /// **'AI extracting content...'**
  String get capturePdfExtracting;

  /// No description provided for @capturePdfExtracted.
  ///
  /// In en, this message translates to:
  /// **'Content extracted'**
  String get capturePdfExtracted;

  /// No description provided for @capturePdfConcepts.
  ///
  /// In en, this message translates to:
  /// **'Identifying key concepts...'**
  String get capturePdfConcepts;

  /// No description provided for @capturePdfConceptsDone.
  ///
  /// In en, this message translates to:
  /// **'Key concepts found'**
  String get capturePdfConceptsDone;

  /// No description provided for @capturePdfFormatting.
  ///
  /// In en, this message translates to:
  /// **'Formatting text...'**
  String get capturePdfFormatting;

  /// No description provided for @capturePdfFormattingDone.
  ///
  /// In en, this message translates to:
  /// **'Text formatted'**
  String get capturePdfFormattingDone;

  /// No description provided for @capturePdfFinishing.
  ///
  /// In en, this message translates to:
  /// **'Finishing up...'**
  String get capturePdfFinishing;

  /// No description provided for @capturePdfReady.
  ///
  /// In en, this message translates to:
  /// **'Ready!'**
  String get capturePdfReady;

  /// No description provided for @captureWhisperUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading audio...'**
  String get captureWhisperUploading;

  /// No description provided for @captureWhisperUploaded.
  ///
  /// In en, this message translates to:
  /// **'Audio uploaded'**
  String get captureWhisperUploaded;

  /// No description provided for @captureWhisperSignal.
  ///
  /// In en, this message translates to:
  /// **'Processing audio signal...'**
  String get captureWhisperSignal;

  /// No description provided for @captureWhisperSignalDone.
  ///
  /// In en, this message translates to:
  /// **'Signal processed'**
  String get captureWhisperSignalDone;

  /// No description provided for @captureWhisperSpeech.
  ///
  /// In en, this message translates to:
  /// **'Detecting speech patterns...'**
  String get captureWhisperSpeech;

  /// No description provided for @captureWhisperSpeechDone.
  ///
  /// In en, this message translates to:
  /// **'Speech detected'**
  String get captureWhisperSpeechDone;

  /// No description provided for @captureWhisperTranscribing.
  ///
  /// In en, this message translates to:
  /// **'AI transcribing audio...'**
  String get captureWhisperTranscribing;

  /// No description provided for @captureWhisperTranscribed.
  ///
  /// In en, this message translates to:
  /// **'Audio transcribed'**
  String get captureWhisperTranscribed;

  /// No description provided for @captureWhisperFormatting.
  ///
  /// In en, this message translates to:
  /// **'Formatting transcript...'**
  String get captureWhisperFormatting;

  /// No description provided for @captureWhisperFormattingDone.
  ///
  /// In en, this message translates to:
  /// **'Transcript formatted'**
  String get captureWhisperFormattingDone;

  /// No description provided for @captureWhisperCleaning.
  ///
  /// In en, this message translates to:
  /// **'Cleaning up text...'**
  String get captureWhisperCleaning;

  /// No description provided for @captureWhisperCleaningDone.
  ///
  /// In en, this message translates to:
  /// **'Text polished'**
  String get captureWhisperCleaningDone;

  /// No description provided for @captureWhisperFinishing.
  ///
  /// In en, this message translates to:
  /// **'Finishing up...'**
  String get captureWhisperFinishing;

  /// No description provided for @captureWhisperReady.
  ///
  /// In en, this message translates to:
  /// **'Ready!'**
  String get captureWhisperReady;

  /// No description provided for @captureOcrUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading image...'**
  String get captureOcrUploading;

  /// No description provided for @captureOcrUploaded.
  ///
  /// In en, this message translates to:
  /// **'Image uploaded'**
  String get captureOcrUploaded;

  /// No description provided for @captureOcrScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning document...'**
  String get captureOcrScanning;

  /// No description provided for @captureOcrScanned.
  ///
  /// In en, this message translates to:
  /// **'Document scanned'**
  String get captureOcrScanned;

  /// No description provided for @captureOcrRecognizing.
  ///
  /// In en, this message translates to:
  /// **'AI recognizing text...'**
  String get captureOcrRecognizing;

  /// No description provided for @captureOcrRecognized.
  ///
  /// In en, this message translates to:
  /// **'Text recognized'**
  String get captureOcrRecognized;

  /// No description provided for @captureOcrExtracting.
  ///
  /// In en, this message translates to:
  /// **'Extracting key content...'**
  String get captureOcrExtracting;

  /// No description provided for @captureOcrExtracted.
  ///
  /// In en, this message translates to:
  /// **'Content extracted'**
  String get captureOcrExtracted;

  /// No description provided for @captureOcrFormatting.
  ///
  /// In en, this message translates to:
  /// **'Formatting results...'**
  String get captureOcrFormatting;

  /// No description provided for @captureOcrFormattingDone.
  ///
  /// In en, this message translates to:
  /// **'Results formatted'**
  String get captureOcrFormattingDone;

  /// No description provided for @captureOcrOrganizing.
  ///
  /// In en, this message translates to:
  /// **'Organizing material...'**
  String get captureOcrOrganizing;

  /// No description provided for @captureOcrOrganized.
  ///
  /// In en, this message translates to:
  /// **'Material organized'**
  String get captureOcrOrganized;

  /// No description provided for @captureOcrFinishing.
  ///
  /// In en, this message translates to:
  /// **'Finishing up...'**
  String get captureOcrFinishing;

  /// No description provided for @captureOcrReady.
  ///
  /// In en, this message translates to:
  /// **'Ready!'**
  String get captureOcrReady;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
