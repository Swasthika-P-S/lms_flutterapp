import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for managing app language (English / Hindi)
class LocaleProvider extends ChangeNotifier {
  String _locale = 'en';

  String get locale => _locale;
  bool get isHindi => _locale == 'hi';
  bool get isEnglish => _locale == 'en';

  LocaleProvider() {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    _locale = prefs.getString('app_locale') ?? 'en';
    notifyListeners();
  }

  Future<void> switchLocale(String newLocale) async {
    if (_locale == newLocale) return;
    _locale = newLocale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_locale', newLocale);
    notifyListeners();
  }

  Future<void> toggleLocale() async {
    await switchLocale(_locale == 'en' ? 'hi' : 'en');
  }

  /// Get translated string by key
  String t(String key) {
    final map = _locale == 'hi' ? _hiTranslations : _enTranslations;
    return map[key] ?? _enTranslations[key] ?? key;
  }

  // ─────────────────────────────────────────────
  // English Translations
  // ─────────────────────────────────────────────
  static const Map<String, String> _enTranslations = {
    // General
    'app_name': 'LMS',
    'admin_panel': 'Admin Panel',
    'learning_management_system': 'Learning Management System',

    // Nav Bar
    'nav_home': 'Home',
    'nav_courses': 'Courses',
    'nav_quizzes': 'Quizzes',
    'nav_tasks': 'Tasks',
    'nav_profile': 'Profile',
    'nav_settings': 'Settings',
    'nav_dashboard': 'Dashboard',

    // Home Screen
    'hello': 'Hello,',
    'keep_learning': 'Keep Learning!',
    'complete_daily_goals': 'Complete your daily goals and earn achievements',
    'goal_achieved': 'Goal Achieved',
    'quick_actions': 'Quick Actions',
    'browse_courses': 'Browse Courses',
    'new_course_available': 'New Course Available!',
    'categories': 'Categories',
    'new_course': 'New Course',
    'courses_label': 'Courses',
    'hours_label': 'Hours',
    'progress_label': 'Progress',

    // Login Screen
    'welcome_back': 'Welcome Back',
    'sign_in_to_continue': 'Sign in to continue your learning journey',
    'email_label': 'Email',
    'password_label': 'Password',
    'login': 'Login',
    'sign_in': 'Sign In',
    'sign_up': 'Sign Up',
    'or': 'OR',
    'continue_with_google': 'Continue with Google',
    'dont_have_account': "Don't have an account?",
    'already_have_account': 'Already have an account?',
    'register': 'Register',
    'forgot_password': 'Forgot Password?',
    'please_enter_email': 'Please enter your email',
    'please_enter_valid_email': 'Please enter a valid email',
    'please_enter_password': 'Please enter your password',
    'password_min_length': 'Password must be at least 6 characters',
    'login_failed': 'Login failed',
    'google_sign_in_failed': 'Google Sign-In failed',

    // Register Screen
    'create_account': 'Create Account',
    'join_learning_journey': 'Join our learning journey today',
    'full_name': 'Full Name',
    'confirm_password': 'Confirm Password',
    'please_enter_name': 'Please enter your name',
    'passwords_dont_match': "Passwords don't match",

    // Settings Screen
    'settings': 'Settings',
    'app_preferences': 'App Preferences',
    'dark_mode': 'Dark Mode',
    'switch_to_light': 'Switch to light mode',
    'switch_to_dark': 'Switch to dark mode',
    'notifications': 'Notifications',
    'enabled': 'Enabled',
    'disabled': 'Disabled',
    'account': 'Account',
    'edit_profile': 'Edit Profile',
    'update_personal_info': 'Update your personal information',
    'change_password': 'Change Password',
    'update_password': 'Update your password',
    'learning': 'Learning',
    'study_goals': 'Study Goals',
    'set_daily_targets': 'Set daily learning targets',
    'progress_tracking': 'Progress Tracking',
    'view_analytics': 'View your learning analytics',
    'about': 'About',
    'learnhub_lms': 'LearnHub LMS',
    'privacy_policy': 'Privacy Policy',
    'terms_of_service': 'Terms of Service',
    'logout': 'Logout',
    'logout_confirm': 'Are you sure you want to logout?',
    'cancel': 'Cancel',
    'feature_coming_soon': 'feature coming soon!',
    'language': 'Language',
    'language_english': 'English',
    'language_hindi': 'Hindi',
    'select_language': 'Select Language',
    'login_with_email': 'Login with Email',
    'email_address': 'Email Address',
    'enter_valid_email': 'Enter a valid email',
    'min_6_chars': 'Minimum 6 characters',
    'signing_in': 'Signing in...',
    'incorrect_login': 'Incorrect Login Credentials',
    'learn_practice_excel': 'Learn, Practice, and Excel',
    'good_morning': 'Good morning,',
    'good_afternoon': 'Good afternoon,',
    'good_evening': 'Good evening,',
    'overall_progress': 'Your overall progress',
    'complete_semester': 'complete this semester',
    'quick_access': 'Quick Access',
    'todays_tip': 'Today\'s Tip',
    'practice_dsa_daily': 'Practice DSA problems daily. Consistency beats intense cramming every time.',

    // Profile Screen
    'profile': 'Profile',
    'student': 'Student',
    'courses_completed': 'Courses Completed',
    'total_hours': 'Total Hours',
    'achievements': 'Achievements',
    'skills': 'Skills',

    // Course Listing Screen
    'courses': 'Courses',
    'all': 'All',
    'enrolled': 'Enrolled',
    'new_filter': 'New',
    'popular': 'Popular',
    'no_courses_found': 'No courses found',
    'try_changing_filter': 'Try changing your filter',
    'search_coming_soon': 'Search feature coming soon!',
    'filter_coming_soon': 'Filter feature coming soon!',

    'lessons': 'Lessons',
    'about_course': 'About this course',
    'enroll_now': 'Enroll Now',
    'continue_learning': 'Continue Learning',
    'instructor': 'Instructor',
    'duration': 'Duration',
    'total_lessons': 'Total Lessons',

    // Quiz Screens
    'quizzes': 'Quizzes',
    'start_quiz': 'Start Quiz',
    'question': 'Question',
    'next': 'Next',
    'previous': 'Previous',
    'submit': 'Submit',
    'score': 'Score',
    'correct': 'Correct',
    'incorrect': 'Incorrect',
    'quiz_results': 'Quiz Results',
    'try_again': 'Try Again',
    'back_to_courses': 'Back to Courses',
    'select_answer': 'Select an answer',
    'explanation': 'Explanation',

    // Assignment/Tasks Screen
    'assignments': 'Assignments',
    'dashboard': 'Dashboard',
    'upcoming_deadlines': 'Upcoming Deadlines',
    'no_assignments': 'No assignments yet',
    'due_date': 'Due Date',
    'submitted': 'Submitted',
    'pending': 'Pending',
    'overdue': 'Overdue',
    'view_assignments': 'View Assignments',
    'scan_qr': 'Scan QR',
    'generate_qr': 'Generate QR',
    'notifications_title': 'Notifications',

    // Admin Dashboard
    'admin_dashboard': 'Admin Dashboard',
    'total_students': 'Total Students',
    'active_courses': 'Active Courses',
    'total_assignments': 'Total Assignments',

    // Chatbot
    'ai_assistant': 'AI Placement Assistant',
    'powered_by_groq': 'Powered by Groq',
    'ask_me_anything': 'Ask me anything...',
    'start_conversation': 'Start a conversation!',
    'chatbot_not_initialized': 'Chatbot not initialized',
    'configure_api_key': 'Please configure API key',
    'clear_chat': 'Clear chat',

    // Common
    'loading': 'Loading...',
    'error': 'Error',
    'retry': 'Retry',
    'save': 'Save',
    'delete': 'Delete',
    'edit': 'Edit',
    'close': 'Close',
    'ok': 'OK',
    'yes': 'Yes',
    'no': 'No',
    'days': 'Days',
    'search': 'Search',
  };

  // ─────────────────────────────────────────────
  // Hindi Translations
  // ─────────────────────────────────────────────
  static const Map<String, String> _hiTranslations = {
    // General
    'app_name': 'एलएमएस',
    'admin_panel': 'एडमिन पैनल',
    'learning_management_system': 'शिक्षा प्रबंधन प्रणाली',

    // Nav Bar
    'nav_home': 'होम',
    'nav_courses': 'कोर्स',
    'nav_quizzes': 'क्विज़',
    'nav_tasks': 'कार्य',
    'nav_profile': 'प्रोफ़ाइल',
    'nav_settings': 'सेटिंग्स',
    'nav_dashboard': 'डैशबोर्ड',

    // Home Screen
    'hello': 'नमस्ते,',
    'keep_learning': 'सीखते रहो!',
    'complete_daily_goals': 'अपने दैनिक लक्ष्य पूरे करें और उपलब्धियाँ अर्जित करें',
    'goal_achieved': 'लक्ष्य प्राप्त',
    'quick_actions': 'त्वरित कार्य',
    'browse_courses': 'कोर्स देखें',
    'new_course_available': 'नया कोर्स उपलब्ध!',
    'categories': 'श्रेणियाँ',
    'new_course': 'नया कोर्स',
    'courses_label': 'कोर्स',
    'hours_label': 'घंटे',
    'progress_label': 'प्रगति',

    // Login Screen
    'welcome_back': 'वापसी पर स्वागत है',
    'sign_in_to_continue': 'अपनी शिक्षा यात्रा जारी रखने के लिए साइन इन करें',
    'email_label': 'ईमेल',
    'password_label': 'पासवर्ड',
    'login': 'लॉगिन',
    'sign_in': 'साइन इन',
    'sign_up': 'साइन अप',
    'or': 'या',
    'continue_with_google': 'Google से जारी रखें',
    'dont_have_account': 'खाता नहीं है?',
    'already_have_account': 'पहले से खाता है?',
    'register': 'रजिस्टर',
    'forgot_password': 'पासवर्ड भूल गए?',
    'please_enter_email': 'कृपया अपना ईमेल दर्ज करें',
    'please_enter_valid_email': 'कृपया एक वैध ईमेल दर्ज करें',
    'please_enter_password': 'कृपया अपना पासवर्ड दर्ज करें',
    'password_min_length': 'पासवर्ड कम से कम 6 अक्षर का होना चाहिए',
    'login_failed': 'लॉगिन विफल',
    'google_sign_in_failed': 'Google साइन-इन विफल',

    // Register Screen
    'create_account': 'खाता बनाएं',
    'join_learning_journey': 'आज ही हमारी शिक्षा यात्रा से जुड़ें',
    'full_name': 'पूरा नाम',
    'confirm_password': 'पासवर्ड की पुष्टि करें',
    'please_enter_name': 'कृपया अपना नाम दर्ज करें',
    'passwords_dont_match': 'पासवर्ड मेल नहीं खाते',

    // Settings Screen
    'settings': 'सेटिंग्स',
    'app_preferences': 'ऐप प्राथमिकताएं',
    'dark_mode': 'डार्क मोड',
    'switch_to_light': 'लाइट मोड पर स्विच करें',
    'switch_to_dark': 'डार्क मोड पर स्विच करें',
    'notifications': 'सूचनाएं',
    'enabled': 'चालू',
    'disabled': 'बंद',
    'account': 'खाता',
    'edit_profile': 'प्रोफ़ाइल संपादित करें',
    'update_personal_info': 'अपनी व्यक्तिगत जानकारी अपडेट करें',
    'change_password': 'पासवर्ड बदलें',
    'update_password': 'अपना पासवर्ड अपडेट करें',
    'learning': 'शिक्षा',
    'study_goals': 'अध्ययन लक्ष्य',
    'set_daily_targets': 'दैनिक शिक्षा लक्ष्य निर्धारित करें',
    'progress_tracking': 'प्रगति ट्रैकिंग',
    'view_analytics': 'अपने शिक्षा विश्लेषण देखें',
    'about': 'के बारे में',
    'learnhub_lms': 'लर्नहब एलएमएस',
    'privacy_policy': 'गोपनीयता नीति',
    'terms_of_service': 'सेवा की शर्तें',
    'logout': 'लॉगआउट',
    'logout_confirm': 'क्या आप वाकई लॉगआउट करना चाहते हैं?',
    'cancel': 'रद्द करें',
    'feature_coming_soon': 'सुविधा जल्द आ रही है!',
    'language': 'भाषा',
    'language_english': 'English',
    'language_hindi': 'हिंदी',
    'select_language': 'भाषा चुनें',
    'login_with_email': 'ईमेल के साथ लॉगिन करें',
    'email_address': 'ईमेल पता',
    'enter_valid_email': 'एक वैध ईमेल दर्ज करें',
    'min_6_chars': 'न्यूनतम 6 अक्षर',
    'signing_in': 'साइन इन हो रहा है...',
    'incorrect_login': 'गलत लॉगिन क्रेडेंशियल',
    'learn_practice_excel': 'सीखें, अभ्यास करें और उत्कृष्टता प्राप्त करें',
    'good_morning': 'शुभ प्रभात,',
    'good_afternoon': 'शुभ दोपहर,',
    'good_evening': 'शुभ संध्या,',
    'overall_progress': 'आपकी कुल प्रगति',
    'complete_semester': 'इस सेमेस्टर में पूर्ण',
    'quick_access': 'त्वरित पहुँच',
    'todays_tip': 'आज का सुझाव',
    'practice_dsa_daily': 'प्रतिदिन DSA समस्याओं का अभ्यास करें। निरंतरता हमेशा तीव्र रटने से बेहतर होती है।',

    // Profile Screen
    'profile': 'प्रोफ़ाइल',
    'student': 'छात्र',
    'courses_completed': 'पूर्ण कोर्स',
    'total_hours': 'कुल घंटे',
    'achievements': 'उपलब्धियाँ',
    'skills': 'कौशल',

    // Course Listing Screen
    'courses': 'कोर्स',
    'all': 'सभी',
    'enrolled': 'नामांकित',
    'new_filter': 'नया',
    'popular': 'लोकप्रिय',
    'no_courses_found': 'कोई कोर्स नहीं मिला',
    'try_changing_filter': 'फ़िल्टर बदलकर देखें',
    'search_coming_soon': 'खोज सुविधा जल्द आ रही है!',
    'filter_coming_soon': 'फ़िल्टर सुविधा जल्द आ रही है!',

    'lessons': 'पाठ',
    'about_course': 'इस कोर्स के बारे में',
    'enroll_now': 'अभी नामांकन करें',
    'continue_learning': 'सीखना जारी रखें',
    'instructor': 'प्रशिक्षक',
    'duration': 'अवधि',
    'total_lessons': 'कुल पाठ',

    // Quiz Screens
    'quizzes': 'क्विज़',
    'start_quiz': 'क्विज़ शुरू करें',
    'question': 'प्रश्न',
    'next': 'अगला',
    'previous': 'पिछला',
    'submit': 'जमा करें',
    'score': 'अंक',
    'correct': 'सही',
    'incorrect': 'गलत',
    'quiz_results': 'क्विज़ परिणाम',
    'try_again': 'पुनः प्रयास करें',
    'back_to_courses': 'कोर्स पर वापस जाएं',
    'select_answer': 'एक उत्तर चुनें',
    'explanation': 'व्याख्या',

    // Assignment/Tasks Screen
    'assignments': 'असाइनमेंट',
    'dashboard': 'डैशबोर्ड',
    'upcoming_deadlines': 'आगामी डेडलाइन',
    'no_assignments': 'अभी तक कोई असाइनमेंट नहीं',
    'due_date': 'नियत तारीख',
    'submitted': 'जमा किया',
    'pending': 'लंबित',
    'overdue': 'अतिदेय',
    'view_assignments': 'असाइनमेंट देखें',
    'scan_qr': 'QR स्कैन करें',
    'generate_qr': 'QR बनाएं',
    'notifications_title': 'सूचनाएं',

    // Admin Dashboard
    'admin_dashboard': 'एडमिन डैशबोर्ड',
    'total_students': 'कुल छात्र',
    'active_courses': 'सक्रिय कोर्स',
    'total_assignments': 'कुल असाइनमेंट',

    // Chatbot
    'ai_assistant': 'AI प्लेसमेंट सहायक',
    'powered_by_groq': 'Groq द्वारा संचालित',
    'ask_me_anything': 'कुछ भी पूछें...',
    'start_conversation': 'बातचीत शुरू करें!',
    'chatbot_not_initialized': 'चैटबॉट शुरू नहीं हुआ',
    'configure_api_key': 'कृपया API कुंजी कॉन्फ़िगर करें',
    'clear_chat': 'चैट साफ़ करें',

    // Common
    'loading': 'लोड हो रहा है...',
    'error': 'त्रुटि',
    'retry': 'पुनः प्रयास',
    'save': 'सहेजें',
    'delete': 'हटाएं',
    'edit': 'संपादित करें',
    'close': 'बंद करें',
    'ok': 'ठीक है',
    'yes': 'हाँ',
    'no': 'नहीं',
    'days': 'दिन',
    'search': 'खोजें',
  };
}
