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
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
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

  /// No description provided for @authWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, scholar'**
  String get authWelcomeBack;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get authSignIn;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get authForgotPassword;

  /// No description provided for @authContinueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get authContinueWithApple;

  /// No description provided for @authOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get authOr;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get authNoAccount;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get authCreateAccount;

  /// No description provided for @authHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get authHaveAccount;

  /// No description provided for @authTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get authTermsOfService;

  /// No description provided for @authPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get authPrivacyPolicy;

  /// No description provided for @authBeginJourney.
  ///
  /// In en, this message translates to:
  /// **'Begin your journey to academic excellence'**
  String get authBeginJourney;

  /// No description provided for @authFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get authFullName;

  /// No description provided for @authConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get authConfirmPassword;

  /// No description provided for @authAgreeToTerms.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get authAgreeToTerms;

  /// No description provided for @authAnd.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get authAnd;

  /// No description provided for @authEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get authEmailRequired;

  /// No description provided for @authValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get authValidEmail;

  /// No description provided for @authPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get authPasswordRequired;

  /// No description provided for @authPasswordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get authPasswordMinLength;

  /// No description provided for @authNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get authNameRequired;

  /// No description provided for @authNameMinLength.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get authNameMinLength;

  /// No description provided for @authConfirmRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get authConfirmRequired;

  /// No description provided for @authPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get authPasswordMismatch;

  /// No description provided for @authAcceptTerms.
  ///
  /// In en, this message translates to:
  /// **'Please accept the Terms of Service and Privacy Policy'**
  String get authAcceptTerms;

  /// No description provided for @authEnterEmailFirst.
  ///
  /// In en, this message translates to:
  /// **'Enter your email first'**
  String get authEnterEmailFirst;

  /// No description provided for @authResetSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent!'**
  String get authResetSent;

  /// No description provided for @authAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered'**
  String get authAlreadyRegistered;

  /// No description provided for @authWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get authWeakPassword;

  /// No description provided for @authNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get authNoInternet;

  /// No description provided for @authSomethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get authSomethingWrong;

  /// No description provided for @practiceExamTitle.
  ///
  /// In en, this message translates to:
  /// **'Practice Exam'**
  String get practiceExamTitle;

  /// No description provided for @practiceExamSelectCourse.
  ///
  /// In en, this message translates to:
  /// **'SELECT COURSE'**
  String get practiceExamSelectCourse;

  /// No description provided for @practiceExamQuestionCount.
  ///
  /// In en, this message translates to:
  /// **'NUMBER OF QUESTIONS'**
  String get practiceExamQuestionCount;

  /// No description provided for @practiceExamQuestions.
  ///
  /// In en, this message translates to:
  /// **'questions'**
  String get practiceExamQuestions;

  /// No description provided for @practiceExamTimeLimit.
  ///
  /// In en, this message translates to:
  /// **'TIME LIMIT'**
  String get practiceExamTimeLimit;

  /// No description provided for @practiceExamTime15.
  ///
  /// In en, this message translates to:
  /// **'15 min'**
  String get practiceExamTime15;

  /// No description provided for @practiceExamTime30.
  ///
  /// In en, this message translates to:
  /// **'30 min'**
  String get practiceExamTime30;

  /// No description provided for @practiceExamTime60.
  ///
  /// In en, this message translates to:
  /// **'60 min'**
  String get practiceExamTime60;

  /// No description provided for @practiceExamNoLimit.
  ///
  /// In en, this message translates to:
  /// **'No Limit'**
  String get practiceExamNoLimit;

  /// No description provided for @practiceExamStartExam.
  ///
  /// In en, this message translates to:
  /// **'Start Exam'**
  String get practiceExamStartExam;

  /// No description provided for @practiceExamSelectCourseFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select a course'**
  String get practiceExamSelectCourseFirst;

  /// No description provided for @practiceExamNoCourses.
  ///
  /// In en, this message translates to:
  /// **'Create a course first to take a practice exam.'**
  String get practiceExamNoCourses;

  /// No description provided for @practiceExamSelectToStart.
  ///
  /// In en, this message translates to:
  /// **'Select a course to start'**
  String get practiceExamSelectToStart;

  /// No description provided for @practiceExamLoadingHistory.
  ///
  /// In en, this message translates to:
  /// **'Loading history...'**
  String get practiceExamLoadingHistory;

  /// No description provided for @practiceExamFirstAttempt.
  ///
  /// In en, this message translates to:
  /// **'First attempt — Good luck! 🍀'**
  String get practiceExamFirstAttempt;

  /// No description provided for @practiceExamKeepItUp.
  ///
  /// In en, this message translates to:
  /// **'Keep it up!'**
  String get practiceExamKeepItUp;

  /// No description provided for @practiceExamCanDoBetter.
  ///
  /// In en, this message translates to:
  /// **'You can do better!'**
  String get practiceExamCanDoBetter;

  /// No description provided for @practiceExamPracticeMakesPerfect.
  ///
  /// In en, this message translates to:
  /// **'Practice makes perfect!'**
  String get practiceExamPracticeMakesPerfect;

  /// No description provided for @practiceExamLastScore.
  ///
  /// In en, this message translates to:
  /// **'Last score: {pct}% — {encouragement}'**
  String practiceExamLastScore(int pct, String encouragement);

  /// No description provided for @practiceExamEstimatedDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Estimated difficulty'**
  String get practiceExamEstimatedDifficulty;

  /// No description provided for @practiceExamMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get practiceExamMedium;

  /// No description provided for @quizQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question {current}'**
  String quizQuestion(String current);

  /// No description provided for @quizTypeAnswer.
  ///
  /// In en, this message translates to:
  /// **'Type your answer here...'**
  String get quizTypeAnswer;

  /// No description provided for @quizAnswerHint.
  ///
  /// In en, this message translates to:
  /// **'Answer in your own words. The AI will evaluate your understanding.'**
  String get quizAnswerHint;

  /// No description provided for @quizPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get quizPrevious;

  /// No description provided for @quizNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get quizNext;

  /// No description provided for @quizSubmitExam.
  ///
  /// In en, this message translates to:
  /// **'Submit Exam'**
  String get quizSubmitExam;

  /// No description provided for @quizSubmitQuiz.
  ///
  /// In en, this message translates to:
  /// **'Submit Quiz'**
  String get quizSubmitQuiz;

  /// No description provided for @quizPerfectScore.
  ///
  /// In en, this message translates to:
  /// **'Perfect Score! 🎉'**
  String get quizPerfectScore;

  /// No description provided for @quizPerfectSub.
  ///
  /// In en, this message translates to:
  /// **'You nailed every question!'**
  String get quizPerfectSub;

  /// No description provided for @quizComplete.
  ///
  /// In en, this message translates to:
  /// **'Quiz Complete'**
  String get quizComplete;

  /// No description provided for @quizPerfect.
  ///
  /// In en, this message translates to:
  /// **'🏆 Perfect!'**
  String get quizPerfect;

  /// No description provided for @quizLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave quiz?'**
  String get quizLeaveTitle;

  /// No description provided for @quizLeaveExamTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave Exam?'**
  String get quizLeaveExamTitle;

  /// No description provided for @quizLeaveSaved.
  ///
  /// In en, this message translates to:
  /// **'Your progress is saved! You can continue this quiz later from the home screen.'**
  String get quizLeaveSaved;

  /// No description provided for @quizStay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get quizStay;

  /// No description provided for @quizContinueQuiz.
  ///
  /// In en, this message translates to:
  /// **'Continue Quiz'**
  String get quizContinueQuiz;

  /// No description provided for @quizLeaveForNow.
  ///
  /// In en, this message translates to:
  /// **'Leave for now'**
  String get quizLeaveForNow;

  /// No description provided for @quizCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load quiz'**
  String get quizCouldNotLoad;

  /// No description provided for @quizGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get quizGoBack;

  /// No description provided for @quizNoQuestions.
  ///
  /// In en, this message translates to:
  /// **'No questions found'**
  String get quizNoQuestions;

  /// No description provided for @quizAnswerQuestion.
  ///
  /// In en, this message translates to:
  /// **'Please answer question {number}'**
  String quizAnswerQuestion(String number);

  /// No description provided for @quizAnswerQuestions.
  ///
  /// In en, this message translates to:
  /// **'Please answer questions {numbers}'**
  String quizAnswerQuestions(String numbers);

  /// No description provided for @quizDailyStreak.
  ///
  /// In en, this message translates to:
  /// **'Daily Streak'**
  String get quizDailyStreak;

  /// No description provided for @chatSuggestStudyToday.
  ///
  /// In en, this message translates to:
  /// **'What should I study today?'**
  String get chatSuggestStudyToday;

  /// No description provided for @chatSuggestProgress.
  ///
  /// In en, this message translates to:
  /// **'How am I doing overall?'**
  String get chatSuggestProgress;

  /// No description provided for @chatSuggestWeakest.
  ///
  /// In en, this message translates to:
  /// **'Explain my weakest topic'**
  String get chatSuggestWeakest;

  /// No description provided for @chatSuggestQuiz.
  ///
  /// In en, this message translates to:
  /// **'Quiz me on this'**
  String get chatSuggestQuiz;

  /// No description provided for @chatSuggestSummarize.
  ///
  /// In en, this message translates to:
  /// **'Summarize the material'**
  String get chatSuggestSummarize;

  /// No description provided for @chatFollowUpExample.
  ///
  /// In en, this message translates to:
  /// **'Can you give an example?'**
  String get chatFollowUpExample;

  /// No description provided for @chatFollowUpSimpler.
  ///
  /// In en, this message translates to:
  /// **'Explain it more simply'**
  String get chatFollowUpSimpler;

  /// No description provided for @chatFollowUpRelated.
  ///
  /// In en, this message translates to:
  /// **'How does this relate to other topics?'**
  String get chatFollowUpRelated;

  /// No description provided for @homeFlashcards.
  ///
  /// In en, this message translates to:
  /// **'FLASHCARDS'**
  String get homeFlashcards;

  /// No description provided for @homeDue.
  ///
  /// In en, this message translates to:
  /// **'{count} due'**
  String homeDue(int count);

  /// No description provided for @homeSomethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get homeSomethingWrong;

  /// No description provided for @homeCheckConnection.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again'**
  String get homeCheckConnection;

  /// No description provided for @homeRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get homeRetry;

  /// No description provided for @homeYourDecks.
  ///
  /// In en, this message translates to:
  /// **'Your Decks'**
  String get homeYourDecks;

  /// No description provided for @flashcardCreateNew.
  ///
  /// In en, this message translates to:
  /// **'Create New'**
  String get flashcardCreateNew;

  /// No description provided for @flashcardCreateDeck.
  ///
  /// In en, this message translates to:
  /// **'Create Flashcard Deck'**
  String get flashcardCreateDeck;

  /// No description provided for @flashcardSelectCourse.
  ///
  /// In en, this message translates to:
  /// **'Select a course'**
  String get flashcardSelectCourse;

  /// No description provided for @flashcardCardCount.
  ///
  /// In en, this message translates to:
  /// **'Number of cards'**
  String get flashcardCardCount;

  /// No description provided for @flashcardCards.
  ///
  /// In en, this message translates to:
  /// **'cards'**
  String get flashcardCards;

  /// No description provided for @flashcardGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate Flashcards'**
  String get flashcardGenerate;

  /// No description provided for @flashcardUploadDoc.
  ///
  /// In en, this message translates to:
  /// **'Upload notes (optional)'**
  String get flashcardUploadDoc;

  /// No description provided for @flashcardUploadHint.
  ///
  /// In en, this message translates to:
  /// **'PDF or photo of your notes'**
  String get flashcardUploadHint;

  /// No description provided for @flashcardUploadPdf.
  ///
  /// In en, this message translates to:
  /// **'Upload PDF'**
  String get flashcardUploadPdf;

  /// No description provided for @flashcardUploadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Scan photo'**
  String get flashcardUploadPhoto;

  /// No description provided for @flashcardUploadChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get flashcardUploadChange;

  /// No description provided for @flashcardUploadProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing document...'**
  String get flashcardUploadProcessing;

  /// No description provided for @flashcardBookmarked.
  ///
  /// In en, this message translates to:
  /// **'Card bookmarked'**
  String get flashcardBookmarked;

  /// No description provided for @flashcardReshuffled.
  ///
  /// In en, this message translates to:
  /// **'Cards reshuffled'**
  String get flashcardReshuffled;

  /// No description provided for @quickActionSnapSolve.
  ///
  /// In en, this message translates to:
  /// **'Snap Solve'**
  String get quickActionSnapSolve;

  /// No description provided for @quickActionOracle.
  ///
  /// In en, this message translates to:
  /// **'Oracle'**
  String get quickActionOracle;

  /// No description provided for @quickActionGroups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get quickActionGroups;

  /// No description provided for @quickActionExam.
  ///
  /// In en, this message translates to:
  /// **'Exam'**
  String get quickActionExam;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get greetingEvening;

  /// No description provided for @streakDaysStreak.
  ///
  /// In en, this message translates to:
  /// **'{count} Days Streak'**
  String streakDaysStreak(int count);

  /// No description provided for @streakOneDayStreak.
  ///
  /// In en, this message translates to:
  /// **'1 Day Streak'**
  String get streakOneDayStreak;

  /// No description provided for @streakLongest.
  ///
  /// In en, this message translates to:
  /// **'Longest streak: {days} days'**
  String streakLongest(int days);

  /// No description provided for @streakStartToday.
  ///
  /// In en, this message translates to:
  /// **'Start studying today to begin your streak!'**
  String get streakStartToday;

  /// No description provided for @streakKeepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep going! {remaining} more {dayWord} to your {milestone} badge!'**
  String streakKeepGoing(int remaining, String dayWord, String milestone);

  /// No description provided for @streakCheckHeatmap.
  ///
  /// In en, this message translates to:
  /// **'Check your Study Heatmap on the home screen'**
  String get streakCheckHeatmap;

  /// No description provided for @streakGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get streakGotIt;

  /// No description provided for @streakDay.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get streakDay;

  /// No description provided for @streakDays.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get streakDays;

  /// No description provided for @journeyLearningJourney.
  ///
  /// In en, this message translates to:
  /// **'Learning Journey'**
  String get journeyLearningJourney;

  /// No description provided for @journeyProgress.
  ///
  /// In en, this message translates to:
  /// **'{percent}% JOURNEY'**
  String journeyProgress(int percent);

  /// No description provided for @journeyLevel.
  ///
  /// In en, this message translates to:
  /// **'LEVEL {level}'**
  String journeyLevel(int level);

  /// No description provided for @journeyTodaysChallenge.
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S CHALLENGE'**
  String get journeyTodaysChallenge;

  /// No description provided for @journeyCompleteAll.
  ///
  /// In en, this message translates to:
  /// **'Complete all for +{xp} XP bonus'**
  String journeyCompleteAll(int xp);

  /// No description provided for @journeyUpNext.
  ///
  /// In en, this message translates to:
  /// **'UP NEXT'**
  String get journeyUpNext;

  /// No description provided for @journeyStart.
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get journeyStart;

  /// No description provided for @journeyStartExam.
  ///
  /// In en, this message translates to:
  /// **'START EXAM'**
  String get journeyStartExam;

  /// No description provided for @journeyOpen.
  ///
  /// In en, this message translates to:
  /// **'OPEN'**
  String get journeyOpen;

  /// No description provided for @journeyFinalExam.
  ///
  /// In en, this message translates to:
  /// **'Final Exam'**
  String get journeyFinalExam;

  /// No description provided for @journeyComprehensiveTest.
  ///
  /// In en, this message translates to:
  /// **'Comprehensive test'**
  String get journeyComprehensiveTest;

  /// No description provided for @journeyRewardChest.
  ///
  /// In en, this message translates to:
  /// **'Reward Chest'**
  String get journeyRewardChest;

  /// No description provided for @journeyNoContent.
  ///
  /// In en, this message translates to:
  /// **'No content yet'**
  String get journeyNoContent;

  /// No description provided for @journeyUploadMaterials.
  ///
  /// In en, this message translates to:
  /// **'Upload materials to generate your learning journey'**
  String get journeyUploadMaterials;

  /// No description provided for @journeyUploadMaterial.
  ///
  /// In en, this message translates to:
  /// **'Upload Material'**
  String get journeyUploadMaterial;

  /// No description provided for @journeyCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load journey'**
  String get journeyCouldNotLoad;

  /// No description provided for @journeyGenerating.
  ///
  /// In en, this message translates to:
  /// **'Generating your learning journey...'**
  String get journeyGenerating;

  /// No description provided for @journeyComplete.
  ///
  /// In en, this message translates to:
  /// **'Journey Complete!'**
  String get journeyComplete;

  /// No description provided for @journeyReviewJourney.
  ///
  /// In en, this message translates to:
  /// **'Review Journey'**
  String get journeyReviewJourney;

  /// No description provided for @journeyContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue Journey'**
  String get journeyContinue;

  /// No description provided for @journeyReviewFlashcards.
  ///
  /// In en, this message translates to:
  /// **'Review Flashcards'**
  String get journeyReviewFlashcards;

  /// No description provided for @journeyTakeQuiz.
  ///
  /// In en, this message translates to:
  /// **'Take Quiz'**
  String get journeyTakeQuiz;

  /// No description provided for @journeyReviewMaterial.
  ///
  /// In en, this message translates to:
  /// **'Review Material'**
  String get journeyReviewMaterial;

  /// No description provided for @journeyReadSummary.
  ///
  /// In en, this message translates to:
  /// **'Read Summary'**
  String get journeyReadSummary;

  /// No description provided for @journeyAskOracle.
  ///
  /// In en, this message translates to:
  /// **'Ask the Oracle'**
  String get journeyAskOracle;

  /// No description provided for @journeyTakeCheckpoint.
  ///
  /// In en, this message translates to:
  /// **'Take Checkpoint'**
  String get journeyTakeCheckpoint;

  /// No description provided for @journeyClaimReward.
  ///
  /// In en, this message translates to:
  /// **'Claim Reward'**
  String get journeyClaimReward;

  /// No description provided for @journeyStartFinalExam.
  ///
  /// In en, this message translates to:
  /// **'Start Final Exam'**
  String get journeyStartFinalExam;

  /// No description provided for @journeyCompletePrevious.
  ///
  /// In en, this message translates to:
  /// **'Complete the previous step first'**
  String get journeyCompletePrevious;

  /// No description provided for @journeyExamToday.
  ///
  /// In en, this message translates to:
  /// **'Exam is today!'**
  String get journeyExamToday;

  /// No description provided for @journeyDaysToExam.
  ///
  /// In en, this message translates to:
  /// **'{days} day{suffix} to exam'**
  String journeyDaysToExam(int days, String suffix);

  /// No description provided for @journeyQuickQuestions.
  ///
  /// In en, this message translates to:
  /// **'5 quick questions'**
  String get journeyQuickQuestions;

  /// No description provided for @journeyCheckpoint.
  ///
  /// In en, this message translates to:
  /// **'Checkpoint'**
  String get journeyCheckpoint;

  /// No description provided for @journeyReview.
  ///
  /// In en, this message translates to:
  /// **'Review: {title}'**
  String journeyReview(String title);

  /// No description provided for @journeyFlashcards.
  ///
  /// In en, this message translates to:
  /// **'Flashcards: {title}'**
  String journeyFlashcards(String title);

  /// No description provided for @journeyCards.
  ///
  /// In en, this message translates to:
  /// **'{count} cards'**
  String journeyCards(int count);

  /// No description provided for @journeyPracticeQuiz.
  ///
  /// In en, this message translates to:
  /// **'Practice Quiz'**
  String get journeyPracticeQuiz;

  /// No description provided for @journeyTestKnowledge.
  ///
  /// In en, this message translates to:
  /// **'Test your knowledge'**
  String get journeyTestKnowledge;

  /// No description provided for @journeyAiQA.
  ///
  /// In en, this message translates to:
  /// **'AI-powered Q&A'**
  String get journeyAiQA;

  /// No description provided for @journeyPdfDocument.
  ///
  /// In en, this message translates to:
  /// **'PDF Document'**
  String get journeyPdfDocument;

  /// No description provided for @journeyAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get journeyAudio;

  /// No description provided for @journeyNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get journeyNotes;

  /// No description provided for @journeyPastedText.
  ///
  /// In en, this message translates to:
  /// **'Pasted Text'**
  String get journeyPastedText;

  /// No description provided for @journeyMaterial.
  ///
  /// In en, this message translates to:
  /// **'Material'**
  String get journeyMaterial;

  /// No description provided for @journeyFillGaps.
  ///
  /// In en, this message translates to:
  /// **'Fill the Gaps'**
  String get journeyFillGaps;

  /// No description provided for @journeyFillGapsSub.
  ///
  /// In en, this message translates to:
  /// **'Complete the missing terms'**
  String get journeyFillGapsSub;

  /// No description provided for @journeySpeedRound.
  ///
  /// In en, this message translates to:
  /// **'Speed Round'**
  String get journeySpeedRound;

  /// No description provided for @journeySpeedRoundSub.
  ///
  /// In en, this message translates to:
  /// **'10 true/false in 50 seconds'**
  String get journeySpeedRoundSub;

  /// No description provided for @journeyMistakeSpotter.
  ///
  /// In en, this message translates to:
  /// **'Mistake Spotter'**
  String get journeyMistakeSpotter;

  /// No description provided for @journeyMistakeSpotterSub.
  ///
  /// In en, this message translates to:
  /// **'Find the errors'**
  String get journeyMistakeSpotterSub;

  /// No description provided for @journeyTeachBot.
  ///
  /// In en, this message translates to:
  /// **'Teach the Bot'**
  String get journeyTeachBot;

  /// No description provided for @journeyTeachBotSub.
  ///
  /// In en, this message translates to:
  /// **'Explain it in your words'**
  String get journeyTeachBotSub;

  /// No description provided for @journeyCompareContrast.
  ///
  /// In en, this message translates to:
  /// **'Compare & Contrast'**
  String get journeyCompareContrast;

  /// No description provided for @journeyCompareContrastSub.
  ///
  /// In en, this message translates to:
  /// **'Sort the differences'**
  String get journeyCompareContrastSub;

  /// No description provided for @journeyTimelineBuilder.
  ///
  /// In en, this message translates to:
  /// **'Timeline Builder'**
  String get journeyTimelineBuilder;

  /// No description provided for @journeyTimelineBuilderSub.
  ///
  /// In en, this message translates to:
  /// **'Put steps in order'**
  String get journeyTimelineBuilderSub;

  /// No description provided for @journeyCaseStudy.
  ///
  /// In en, this message translates to:
  /// **'Case Study'**
  String get journeyCaseStudy;

  /// No description provided for @journeyCaseStudySub.
  ///
  /// In en, this message translates to:
  /// **'Apply your knowledge'**
  String get journeyCaseStudySub;

  /// No description provided for @journeyMatchBlitz.
  ///
  /// In en, this message translates to:
  /// **'Match Blitz'**
  String get journeyMatchBlitz;

  /// No description provided for @journeyMatchBlitzSub.
  ///
  /// In en, this message translates to:
  /// **'Pair concepts fast'**
  String get journeyMatchBlitzSub;

  /// No description provided for @journeyConceptMapper.
  ///
  /// In en, this message translates to:
  /// **'Concept Map'**
  String get journeyConceptMapper;

  /// No description provided for @journeyConceptMapperSub.
  ///
  /// In en, this message translates to:
  /// **'Connect the ideas'**
  String get journeyConceptMapperSub;

  /// No description provided for @journeyDailyChallenge.
  ///
  /// In en, this message translates to:
  /// **'Daily Challenge'**
  String get journeyDailyChallenge;

  /// No description provided for @journeyDailyChallengeSub.
  ///
  /// In en, this message translates to:
  /// **'Today\'s personalized exercise'**
  String get journeyDailyChallengeSub;

  /// No description provided for @journeyStartFillGaps.
  ///
  /// In en, this message translates to:
  /// **'Start Fill the Gaps'**
  String get journeyStartFillGaps;

  /// No description provided for @journeyStartSpeedRound.
  ///
  /// In en, this message translates to:
  /// **'Start Speed Round'**
  String get journeyStartSpeedRound;

  /// No description provided for @journeyStartMistakeSpotter.
  ///
  /// In en, this message translates to:
  /// **'Start Mistake Spotter'**
  String get journeyStartMistakeSpotter;

  /// No description provided for @journeyStartTeachBot.
  ///
  /// In en, this message translates to:
  /// **'Start Teaching'**
  String get journeyStartTeachBot;

  /// No description provided for @journeyStartCompareContrast.
  ///
  /// In en, this message translates to:
  /// **'Start Comparing'**
  String get journeyStartCompareContrast;

  /// No description provided for @journeyStartTimelineBuilder.
  ///
  /// In en, this message translates to:
  /// **'Start Timeline'**
  String get journeyStartTimelineBuilder;

  /// No description provided for @journeyStartCaseStudy.
  ///
  /// In en, this message translates to:
  /// **'Start Case Study'**
  String get journeyStartCaseStudy;

  /// No description provided for @journeyStartMatchBlitz.
  ///
  /// In en, this message translates to:
  /// **'Start Match Blitz'**
  String get journeyStartMatchBlitz;

  /// No description provided for @journeyStartConceptMapper.
  ///
  /// In en, this message translates to:
  /// **'Start Concept Map'**
  String get journeyStartConceptMapper;

  /// No description provided for @journeyStartDailyChallenge.
  ///
  /// In en, this message translates to:
  /// **'Start Challenge'**
  String get journeyStartDailyChallenge;

  /// No description provided for @journeyDifficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get journeyDifficultyEasy;

  /// No description provided for @journeyDifficultyMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get journeyDifficultyMedium;

  /// No description provided for @journeyDifficultyHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get journeyDifficultyHard;

  /// No description provided for @journeyStreakMultiplier.
  ///
  /// In en, this message translates to:
  /// **'x{multiplier} XP'**
  String journeyStreakMultiplier(int multiplier);

  /// No description provided for @journeyStreakBonus.
  ///
  /// In en, this message translates to:
  /// **'Streak Bonus!'**
  String get journeyStreakBonus;

  /// No description provided for @journeyInsights.
  ///
  /// In en, this message translates to:
  /// **'Progress Insights'**
  String get journeyInsights;

  /// No description provided for @journeyMastered.
  ///
  /// In en, this message translates to:
  /// **'Mastered'**
  String get journeyMastered;

  /// No description provided for @journeyNeedsWork.
  ///
  /// In en, this message translates to:
  /// **'Needs Work'**
  String get journeyNeedsWork;

  /// No description provided for @journeyTimeStudied.
  ///
  /// In en, this message translates to:
  /// **'Time studied'**
  String get journeyTimeStudied;

  /// No description provided for @journeyThisWeek.
  ///
  /// In en, this message translates to:
  /// **'this week'**
  String get journeyThisWeek;

  /// No description provided for @journeyPredictedScore.
  ///
  /// In en, this message translates to:
  /// **'Predicted exam score'**
  String get journeyPredictedScore;

  /// No description provided for @journeyWeeklyGoal.
  ///
  /// In en, this message translates to:
  /// **'Weekly goal'**
  String get journeyWeeklyGoal;

  /// No description provided for @journeyBossPreview.
  ///
  /// In en, this message translates to:
  /// **'Exam Topics'**
  String get journeyBossPreview;

  /// No description provided for @journeyConfidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get journeyConfidence;

  /// No description provided for @journeyReviewWeak.
  ///
  /// In en, this message translates to:
  /// **'Review Weak Topics'**
  String get journeyReviewWeak;

  /// No description provided for @journeyRecapTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly Recap'**
  String get journeyRecapTitle;

  /// No description provided for @journeyRecapNodesCompleted.
  ///
  /// In en, this message translates to:
  /// **'{count} nodes completed'**
  String journeyRecapNodesCompleted(int count);

  /// No description provided for @journeyRecapXpEarned.
  ///
  /// In en, this message translates to:
  /// **'{xp} XP earned'**
  String journeyRecapXpEarned(int xp);

  /// No description provided for @journeyRecapNewTopics.
  ///
  /// In en, this message translates to:
  /// **'New topics'**
  String get journeyRecapNewTopics;

  /// No description provided for @journeyRecapReviewed.
  ///
  /// In en, this message translates to:
  /// **'Reviewed'**
  String get journeyRecapReviewed;

  /// No description provided for @journeyMicroReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get journeyMicroReviewTitle;

  /// No description provided for @journeyMicroReviewCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed {date}'**
  String journeyMicroReviewCompleted(String date);

  /// No description provided for @journeyMicroReviewScore.
  ///
  /// In en, this message translates to:
  /// **'Score: {score}%'**
  String journeyMicroReviewScore(int score);

  /// No description provided for @journeyMicroReviewRedo.
  ///
  /// In en, this message translates to:
  /// **'Redo Exercise'**
  String get journeyMicroReviewRedo;

  /// No description provided for @journeyMicroReviewNoScore.
  ///
  /// In en, this message translates to:
  /// **'No score recorded'**
  String get journeyMicroReviewNoScore;

  /// No description provided for @journeyFabContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get journeyFabContinue;

  /// No description provided for @journeyFabReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get journeyFabReview;

  /// No description provided for @journeyFabQuickChallenge.
  ///
  /// In en, this message translates to:
  /// **'Quick Challenge'**
  String get journeyFabQuickChallenge;

  /// No description provided for @exerciseCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get exerciseCorrect;

  /// No description provided for @exerciseIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect'**
  String get exerciseIncorrect;

  /// No description provided for @exerciseScore.
  ///
  /// In en, this message translates to:
  /// **'Score: {score}%'**
  String exerciseScore(int score);

  /// No description provided for @exerciseComplete.
  ///
  /// In en, this message translates to:
  /// **'Exercise Complete!'**
  String get exerciseComplete;

  /// No description provided for @exerciseImproved.
  ///
  /// In en, this message translates to:
  /// **'You improved {percent}% vs last time!'**
  String exerciseImproved(int percent);

  /// No description provided for @exerciseMastered.
  ///
  /// In en, this message translates to:
  /// **'Mastered {count}/{total} concepts'**
  String exerciseMastered(int count, int total);

  /// No description provided for @exerciseTimeUp.
  ///
  /// In en, this message translates to:
  /// **'Time\'s up!'**
  String get exerciseTimeUp;

  /// No description provided for @exerciseSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get exerciseSubmit;

  /// No description provided for @exerciseNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get exerciseNext;

  /// No description provided for @exerciseFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get exerciseFinish;

  /// No description provided for @exerciseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get exerciseTryAgain;

  /// No description provided for @exerciseCheckAnswer.
  ///
  /// In en, this message translates to:
  /// **'Check Answer'**
  String get exerciseCheckAnswer;

  /// No description provided for @exerciseTrue.
  ///
  /// In en, this message translates to:
  /// **'True'**
  String get exerciseTrue;

  /// No description provided for @exerciseFalse.
  ///
  /// In en, this message translates to:
  /// **'False'**
  String get exerciseFalse;

  /// No description provided for @exerciseGoodJob.
  ///
  /// In en, this message translates to:
  /// **'Good job!'**
  String get exerciseGoodJob;

  /// No description provided for @exerciseKeepPracticing.
  ///
  /// In en, this message translates to:
  /// **'Keep practicing!'**
  String get exerciseKeepPracticing;

  /// No description provided for @exerciseExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent!'**
  String get exerciseExcellent;

  /// No description provided for @exerciseNeedsImprovement.
  ///
  /// In en, this message translates to:
  /// **'Needs improvement'**
  String get exerciseNeedsImprovement;

  /// No description provided for @exerciseLoading.
  ///
  /// In en, this message translates to:
  /// **'Generating exercise...'**
  String get exerciseLoading;

  /// No description provided for @exerciseCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load exercise'**
  String get exerciseCouldNotLoad;

  /// No description provided for @fillGapsInstruction.
  ///
  /// In en, this message translates to:
  /// **'Fill in the blanks with the correct terms'**
  String get fillGapsInstruction;

  /// No description provided for @fillGapsHint.
  ///
  /// In en, this message translates to:
  /// **'Type the missing word'**
  String get fillGapsHint;

  /// No description provided for @fillGapsOf.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String fillGapsOf(int current, int total);

  /// No description provided for @speedRoundInstruction.
  ///
  /// In en, this message translates to:
  /// **'True or False? You have 5 seconds per question!'**
  String get speedRoundInstruction;

  /// No description provided for @speedRoundReady.
  ///
  /// In en, this message translates to:
  /// **'Ready?'**
  String get speedRoundReady;

  /// No description provided for @speedRoundGo.
  ///
  /// In en, this message translates to:
  /// **'GO!'**
  String get speedRoundGo;

  /// No description provided for @speedRoundResult.
  ///
  /// In en, this message translates to:
  /// **'{correct}/{total} correct'**
  String speedRoundResult(int correct, int total);

  /// No description provided for @speedRoundAvgTime.
  ///
  /// In en, this message translates to:
  /// **'Avg. {seconds}s per question'**
  String speedRoundAvgTime(String seconds);

  /// No description provided for @mistakeSpotterInstruction.
  ///
  /// In en, this message translates to:
  /// **'Find {count} mistakes in the text below'**
  String mistakeSpotterInstruction(int count);

  /// No description provided for @mistakeSpotterFound.
  ///
  /// In en, this message translates to:
  /// **'{found}/{total} mistakes found'**
  String mistakeSpotterFound(int found, int total);

  /// No description provided for @mistakeSpotterTapToMark.
  ///
  /// In en, this message translates to:
  /// **'Tap on sentences to mark mistakes'**
  String get mistakeSpotterTapToMark;

  /// No description provided for @mistakeSpotterCorrection.
  ///
  /// In en, this message translates to:
  /// **'Correction'**
  String get mistakeSpotterCorrection;

  /// No description provided for @mistakeSpotterWrongSelection.
  ///
  /// In en, this message translates to:
  /// **'This sentence is actually correct'**
  String get mistakeSpotterWrongSelection;

  /// No description provided for @teachBotInstruction.
  ///
  /// In en, this message translates to:
  /// **'Explain this concept to the bot as if teaching a confused student'**
  String get teachBotInstruction;

  /// No description provided for @teachBotBotMessage.
  ///
  /// In en, this message translates to:
  /// **'I\'m confused about this topic. Can you explain it to me?'**
  String get teachBotBotMessage;

  /// No description provided for @teachBotSendExplanation.
  ///
  /// In en, this message translates to:
  /// **'Send explanation'**
  String get teachBotSendExplanation;

  /// No description provided for @teachBotFeedback.
  ///
  /// In en, this message translates to:
  /// **'The bot analyzed your explanation'**
  String get teachBotFeedback;

  /// No description provided for @teachBotCoveredPoints.
  ///
  /// In en, this message translates to:
  /// **'{count}/{total} key points covered'**
  String teachBotCoveredPoints(int count, int total);

  /// No description provided for @teachBotMissedPoint.
  ///
  /// In en, this message translates to:
  /// **'You didn\'t mention: {point}'**
  String teachBotMissedPoint(String point);

  /// No description provided for @compareContrastInstruction.
  ///
  /// In en, this message translates to:
  /// **'Sort these traits into the correct category'**
  String get compareContrastInstruction;

  /// No description provided for @compareContrastDragHint.
  ///
  /// In en, this message translates to:
  /// **'Drag items to the correct column'**
  String get compareContrastDragHint;

  /// No description provided for @timelineInstruction.
  ///
  /// In en, this message translates to:
  /// **'Arrange these steps in the correct order'**
  String get timelineInstruction;

  /// No description provided for @timelineDragHint.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder'**
  String get timelineDragHint;

  /// No description provided for @timelineCheckOrder.
  ///
  /// In en, this message translates to:
  /// **'Check Order'**
  String get timelineCheckOrder;

  /// No description provided for @timelineCorrectOrder.
  ///
  /// In en, this message translates to:
  /// **'Correct order!'**
  String get timelineCorrectOrder;

  /// No description provided for @timelineWrongOrder.
  ///
  /// In en, this message translates to:
  /// **'Not quite right. Try again!'**
  String get timelineWrongOrder;

  /// No description provided for @caseStudyScenario.
  ///
  /// In en, this message translates to:
  /// **'Scenario'**
  String get caseStudyScenario;

  /// No description provided for @caseStudyQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question {num}'**
  String caseStudyQuestion(int num);

  /// No description provided for @caseStudyAnswer.
  ///
  /// In en, this message translates to:
  /// **'Your answer'**
  String get caseStudyAnswer;

  /// No description provided for @matchBlitzInstruction.
  ///
  /// In en, this message translates to:
  /// **'Match concepts with their definitions'**
  String get matchBlitzInstruction;

  /// No description provided for @matchBlitzPairsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} pairs left'**
  String matchBlitzPairsLeft(int count);

  /// No description provided for @matchBlitzTimeBonus.
  ///
  /// In en, this message translates to:
  /// **'Time bonus: +{xp} XP'**
  String matchBlitzTimeBonus(int xp);

  /// No description provided for @conceptMapInstruction.
  ///
  /// In en, this message translates to:
  /// **'Connect the missing links in the concept map'**
  String get conceptMapInstruction;

  /// No description provided for @conceptMapDragToConnect.
  ///
  /// In en, this message translates to:
  /// **'Drag to connect nodes'**
  String get conceptMapDragToConnect;

  /// No description provided for @chatAiOracle.
  ///
  /// In en, this message translates to:
  /// **'AI Oracle'**
  String get chatAiOracle;

  /// No description provided for @chatTheOracle.
  ///
  /// In en, this message translates to:
  /// **'The Oracle'**
  String get chatTheOracle;

  /// No description provided for @chatSettingsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Chat settings coming soon'**
  String get chatSettingsComingSoon;

  /// No description provided for @chatToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get chatToday;

  /// No description provided for @chatStudyCompanion.
  ///
  /// In en, this message translates to:
  /// **'Your AI study companion'**
  String get chatStudyCompanion;

  /// No description provided for @chatStudyCompanionSub.
  ///
  /// In en, this message translates to:
  /// **'Ask questions, get explanations, and ace your exams.'**
  String get chatStudyCompanionSub;

  /// No description provided for @chatOracleKnows.
  ///
  /// In en, this message translates to:
  /// **'The Oracle knows everything'**
  String get chatOracleKnows;

  /// No description provided for @chatOracleKnowsSub.
  ///
  /// In en, this message translates to:
  /// **'Ask about your courses, scores, weak areas, and upcoming exams.'**
  String get chatOracleKnowsSub;

  /// No description provided for @flashcardLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load flashcards'**
  String get flashcardLoadError;

  /// No description provided for @flashcardNoCards.
  ///
  /// In en, this message translates to:
  /// **'No flashcards yet'**
  String get flashcardNoCards;

  /// No description provided for @flashcardNoCardsHint.
  ///
  /// In en, this message translates to:
  /// **'Generate flashcards from your course materials first.'**
  String get flashcardNoCardsHint;

  /// No description provided for @flashcardLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave session?'**
  String get flashcardLeaveTitle;

  /// No description provided for @flashcardLeaveMessage.
  ///
  /// In en, this message translates to:
  /// **'Your progress in this session will be lost.'**
  String get flashcardLeaveMessage;

  /// No description provided for @flashcardStay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get flashcardStay;

  /// No description provided for @flashcardLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get flashcardLeave;

  /// No description provided for @flashcardEditComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Edit cards coming soon'**
  String get flashcardEditComingSoon;

  /// No description provided for @flashcardSessionComplete.
  ///
  /// In en, this message translates to:
  /// **'Session Complete!'**
  String get flashcardSessionComplete;

  /// No description provided for @flashcardCardsReviewed.
  ///
  /// In en, this message translates to:
  /// **'{count} cards reviewed'**
  String flashcardCardsReviewed(int count);

  /// No description provided for @flashcardMastered.
  ///
  /// In en, this message translates to:
  /// **'Mastered'**
  String get flashcardMastered;

  /// No description provided for @flashcardAgain.
  ///
  /// In en, this message translates to:
  /// **'Again'**
  String get flashcardAgain;

  /// No description provided for @flashcardMasteryLabel.
  ///
  /// In en, this message translates to:
  /// **'Mastery'**
  String get flashcardMasteryLabel;

  /// No description provided for @flashcardShareResults.
  ///
  /// In en, this message translates to:
  /// **'Share Results'**
  String get flashcardShareResults;

  /// No description provided for @flashcardContinueReviewing.
  ///
  /// In en, this message translates to:
  /// **'Continue Reviewing'**
  String get flashcardContinueReviewing;

  /// No description provided for @flashcardDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get flashcardDone;

  /// No description provided for @homeDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get homeDefaultName;

  /// No description provided for @exerciseDifficultyTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Difficulty'**
  String get exerciseDifficultyTitle;

  /// No description provided for @exerciseDifficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get exerciseDifficultyEasy;

  /// No description provided for @exerciseDifficultyEasyDesc.
  ///
  /// In en, this message translates to:
  /// **'More time, hints available'**
  String get exerciseDifficultyEasyDesc;

  /// No description provided for @exerciseDifficultyMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get exerciseDifficultyMedium;

  /// No description provided for @exerciseDifficultyMediumDesc.
  ///
  /// In en, this message translates to:
  /// **'Standard challenge'**
  String get exerciseDifficultyMediumDesc;

  /// No description provided for @exerciseDifficultyHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get exerciseDifficultyHard;

  /// No description provided for @exerciseDifficultyHardDesc.
  ///
  /// In en, this message translates to:
  /// **'Less time, no hints'**
  String get exerciseDifficultyHardDesc;

  /// No description provided for @exerciseDifficultyStart.
  ///
  /// In en, this message translates to:
  /// **'Start Exercise'**
  String get exerciseDifficultyStart;

  /// No description provided for @exerciseComboStreak.
  ///
  /// In en, this message translates to:
  /// **'{count} in a row!'**
  String exerciseComboStreak(int count);

  /// No description provided for @exerciseComboBonusXp.
  ///
  /// In en, this message translates to:
  /// **'+{xp} bonus XP'**
  String exerciseComboBonusXp(int xp);

  /// No description provided for @exerciseRelatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Want to learn more?'**
  String get exerciseRelatedTitle;

  /// No description provided for @exerciseRelatedSummary.
  ///
  /// In en, this message translates to:
  /// **'View Summary'**
  String get exerciseRelatedSummary;

  /// No description provided for @exerciseRelatedFlashcards.
  ///
  /// In en, this message translates to:
  /// **'Practice Flashcards'**
  String get exerciseRelatedFlashcards;

  /// No description provided for @exerciseRelatedGlossary.
  ///
  /// In en, this message translates to:
  /// **'Read Glossary'**
  String get exerciseRelatedGlossary;

  /// No description provided for @chatPreferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat Preferences'**
  String get chatPreferencesTitle;

  /// No description provided for @chatResponseStyle.
  ///
  /// In en, this message translates to:
  /// **'Response Style'**
  String get chatResponseStyle;

  /// No description provided for @chatStyleBrief.
  ///
  /// In en, this message translates to:
  /// **'Brief'**
  String get chatStyleBrief;

  /// No description provided for @chatStyleBriefDesc.
  ///
  /// In en, this message translates to:
  /// **'Short, concise answers'**
  String get chatStyleBriefDesc;

  /// No description provided for @chatStyleDetailed.
  ///
  /// In en, this message translates to:
  /// **'Detailed'**
  String get chatStyleDetailed;

  /// No description provided for @chatStyleDetailedDesc.
  ///
  /// In en, this message translates to:
  /// **'In-depth explanations'**
  String get chatStyleDetailedDesc;

  /// No description provided for @chatStyleEli5.
  ///
  /// In en, this message translates to:
  /// **'ELI5'**
  String get chatStyleEli5;

  /// No description provided for @chatStyleEli5Desc.
  ///
  /// In en, this message translates to:
  /// **'Explain like I\'m 5'**
  String get chatStyleEli5Desc;

  /// No description provided for @chatIncludeExamples.
  ///
  /// In en, this message translates to:
  /// **'Include Examples'**
  String get chatIncludeExamples;

  /// No description provided for @chatIncludeExamplesDesc.
  ///
  /// In en, this message translates to:
  /// **'Add practical examples to responses'**
  String get chatIncludeExamplesDesc;

  /// No description provided for @chatPreferencesSaved.
  ///
  /// In en, this message translates to:
  /// **'Preferences saved'**
  String get chatPreferencesSaved;

  /// No description provided for @chatLongPressToClear.
  ///
  /// In en, this message translates to:
  /// **'Long-press to clear'**
  String get chatLongPressToClear;

  /// No description provided for @chatCharCount.
  ///
  /// In en, this message translates to:
  /// **'{count}/{max}'**
  String chatCharCount(String count, String max);

  /// No description provided for @postUploadMaterialUploaded.
  ///
  /// In en, this message translates to:
  /// **'Material uploaded'**
  String get postUploadMaterialUploaded;

  /// No description provided for @postUploadWhatToCreate.
  ///
  /// In en, this message translates to:
  /// **'What do you want to create?'**
  String get postUploadWhatToCreate;

  /// No description provided for @postUploadFlashcards.
  ///
  /// In en, this message translates to:
  /// **'Flashcards'**
  String get postUploadFlashcards;

  /// No description provided for @postUploadQuiz.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get postUploadQuiz;

  /// No description provided for @postUploadSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get postUploadSummary;

  /// No description provided for @postUploadGlossary.
  ///
  /// In en, this message translates to:
  /// **'Glossary'**
  String get postUploadGlossary;

  /// No description provided for @postUploadCreateCards.
  ///
  /// In en, this message translates to:
  /// **'Create study cards'**
  String get postUploadCreateCards;

  /// No description provided for @postUploadTestKnowledge.
  ///
  /// In en, this message translates to:
  /// **'Test your knowledge'**
  String get postUploadTestKnowledge;

  /// No description provided for @postUploadKeyPoints.
  ///
  /// In en, this message translates to:
  /// **'Key points overview'**
  String get postUploadKeyPoints;

  /// No description provided for @postUploadKeyTerms.
  ///
  /// In en, this message translates to:
  /// **'Key terms defined'**
  String get postUploadKeyTerms;

  /// No description provided for @postUploadMoreTools.
  ///
  /// In en, this message translates to:
  /// **'More tools'**
  String get postUploadMoreTools;

  /// No description provided for @postUploadSrsReview.
  ///
  /// In en, this message translates to:
  /// **'SRS Review'**
  String get postUploadSrsReview;

  /// No description provided for @postUploadPracticeExam.
  ///
  /// In en, this message translates to:
  /// **'Practice Exam'**
  String get postUploadPracticeExam;

  /// No description provided for @postUploadAudioSummary.
  ///
  /// In en, this message translates to:
  /// **'Audio Summary'**
  String get postUploadAudioSummary;

  /// No description provided for @postUploadSnapSolve.
  ///
  /// In en, this message translates to:
  /// **'Snap & Solve'**
  String get postUploadSnapSolve;

  /// No description provided for @postUploadChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get postUploadChat;

  /// No description provided for @postUploadSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get postUploadSkip;

  /// No description provided for @postUploadGeneratingInBackground.
  ///
  /// In en, this message translates to:
  /// **'Generating {tool} in background...'**
  String postUploadGeneratingInBackground(String tool);

  /// No description provided for @postUploadHowManyFlashcards.
  ///
  /// In en, this message translates to:
  /// **'How many flashcards?'**
  String get postUploadHowManyFlashcards;

  /// No description provided for @postUploadChooseCount.
  ///
  /// In en, this message translates to:
  /// **'Choose the number of cards to generate'**
  String get postUploadChooseCount;

  /// No description provided for @postUploadPro.
  ///
  /// In en, this message translates to:
  /// **'PRO'**
  String get postUploadPro;

  /// No description provided for @postUploadGenerateFlashcards.
  ///
  /// In en, this message translates to:
  /// **'Generate {count} Flashcards'**
  String postUploadGenerateFlashcards(int count);

  /// No description provided for @homeDueCardsBanner.
  ///
  /// In en, this message translates to:
  /// **'{count} cards due for review'**
  String homeDueCardsBanner(int count);

  /// No description provided for @homeDueCardsReviewNow.
  ///
  /// In en, this message translates to:
  /// **'Review now'**
  String get homeDueCardsReviewNow;

  /// No description provided for @homeMyCourses.
  ///
  /// In en, this message translates to:
  /// **'My Courses'**
  String get homeMyCourses;

  /// No description provided for @trialNotifDay0Title.
  ///
  /// In en, this message translates to:
  /// **'Your study plan is ready!'**
  String get trialNotifDay0Title;

  /// No description provided for @trialNotifDay0Body.
  ///
  /// In en, this message translates to:
  /// **'Generate your first flashcards now'**
  String get trialNotifDay0Body;

  /// No description provided for @trialNotifDay1Title.
  ///
  /// In en, this message translates to:
  /// **'Did you know?'**
  String get trialNotifDay1Title;

  /// No description provided for @trialNotifDay1Body.
  ///
  /// In en, this message translates to:
  /// **'Students who use flashcards score 23% higher. Try generating a quiz!'**
  String get trialNotifDay1Body;

  /// No description provided for @trialNotifDay2Title.
  ///
  /// In en, this message translates to:
  /// **'Have you tried Snap & Solve?'**
  String get trialNotifDay2Title;

  /// No description provided for @trialNotifDay2Body.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of any problem and get a step-by-step solution'**
  String get trialNotifDay2Body;

  /// No description provided for @trialNotifLastDayTitle.
  ///
  /// In en, this message translates to:
  /// **'Last day of your trial!'**
  String get trialNotifLastDayTitle;

  /// No description provided for @trialNotifLastDayBody.
  ///
  /// In en, this message translates to:
  /// **'Make the most of it — generate flashcards, quizzes, and summaries'**
  String get trialNotifLastDayBody;

  /// No description provided for @trialNotif2DaysLeftTitle.
  ///
  /// In en, this message translates to:
  /// **'2 days left on your trial'**
  String get trialNotif2DaysLeftTitle;

  /// No description provided for @trialNotif2DaysLeftBody.
  ///
  /// In en, this message translates to:
  /// **'Don\'t miss out — explore all the AI tools before it ends'**
  String get trialNotif2DaysLeftBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
