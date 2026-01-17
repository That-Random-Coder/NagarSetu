import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService extends ChangeNotifier {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  static const String _languageKey = 'selected_language';

  String _currentLanguage = 'English';
  String get currentLanguage => _currentLanguage;

  Locale get currentLocale {
    switch (_currentLanguage) {
      case 'मराठी':
        return const Locale('mr', 'IN');
      case 'हिंदी':
        return const Locale('hi', 'IN');
      case 'தமிழ்':
        return const Locale('ta', 'IN');
      case 'తెలుగు':
        return const Locale('te', 'IN');
      default:
        return const Locale('en', 'US');
    }
  }

  Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString(_languageKey) ?? 'English';
    notifyListeners();
  }

  Future<void> setLanguage(String language) async {
    if (_currentLanguage == language) return;
    _currentLanguage = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language);
    notifyListeners();
  }

  String translate(String key) {
    return _translations[_currentLanguage]?[key] ??
        _translations['English']?[key] ??
        key;
  }

  static final Map<String, Map<String, String>> _translations = {
    'English': {
      // App
      'app_name': 'NagarSetu',

      // Common
      'loading': 'Loading...',
      'error': 'Error',
      'retry': 'Retry',
      'cancel': 'Cancel',
      'ok': 'OK',
      'save': 'Save',
      'submit': 'Submit',
      'done': 'Done',
      'yes': 'Yes',
      'no': 'No',

      // Navigation
      'home': 'Home',
      'map': 'Map',
      'report': 'Report',
      'my_issues': 'My Issues',
      'profile': 'Profile',

      // Home Screen
      'welcome': 'Welcome',
      'report_issue': 'Report Issue',
      'view_issues': 'View Issues',
      'quick_actions': 'Quick Actions',
      'recent_issues': 'Recent Issues',
      'no_issues': 'No issues reported yet',

      // Report Issue Screen
      'report_new_issue': 'Report New Issue',
      'issue_title': 'Issue Title',
      'description': 'Description',
      'add_description': 'Add a description',
      'speak_description': 'Speak to describe the issue',
      'issue_type': 'Issue Type',
      'criticality': 'Criticality',
      'location': 'Location',
      'add_photo': 'Add Photo',
      'take_photo': 'Take Photo',
      'choose_from_gallery': 'Choose from Gallery',
      'submit_issue': 'Submit Issue',
      'issue_reported': 'Issue Reported!',
      'issue_reported_message':
          'Your issue has been reported successfully. You will be notified once it is acknowledged.',
      'please_add_photo': 'Please add a photo of the issue',
      'please_add_description': 'Please add a description',
      'please_add_title': 'Please enter a title for your issue',
      'generate_title': 'Generate Title',
      'auto_generate_title': 'Auto-generate title using AI',

      // Issue Types
      'road': 'Road',
      'water': 'Water',
      'electricity': 'Electricity',
      'garbage': 'Garbage',
      'drainage': 'Drainage',
      'streetlight': 'Streetlight',
      'public_safety': 'Public Safety',
      'other': 'Other',

      // Criticality
      'low': 'Low',
      'medium': 'Medium',
      'high': 'High',
      'critical': 'Critical',

      // Status
      'pending': 'Pending',
      'acknowledged': 'Acknowledged',
      'in_progress': 'In Progress',
      'team_assigned': 'Team Assigned',
      'resolved': 'Resolved',

      // My Issues Screen
      'no_issues_reported': 'No issues reported yet',
      'report_issue_to_see': 'Report an issue to see it here',
      'loading_issues': 'Loading issues...',

      // Issue Detail Screen
      'issue_details': 'Issue Details',
      'issue_id': 'Issue ID',
      'reported_on': 'Reported on',
      'loading_issue_details': 'Loading issue details...',

      // Map Screen
      'issue_map': 'Issue Map',
      'issues_found': 'issues found',

      // Profile Screen
      'edit_profile': 'Edit Profile',
      'settings': 'Settings',
      'notifications': 'Notifications',
      'language': 'Language',
      'dark_mode': 'Dark Mode',
      'support_info': 'Support & Info',
      'help_center': 'Help Center',
      'about': 'About',
      'privacy_policy': 'Privacy Policy',
      'terms_of_service': 'Terms of Service',
      'logout': 'Logout',
      'logout_confirm': 'Are you sure you want to logout?',
      'loading_profile': 'Loading profile...',
      'issues_reported': 'Issues Reported',
      'issues_resolved': 'Issues Resolved',
      'member_since': 'Member Since',

      // Auth
      'login': 'Login',
      'signup': 'Sign Up',
      'email': 'Email',
      'password': 'Password',
      'forgot_password': 'Forgot Password?',
      'dont_have_account': "Don't have an account?",
      'already_have_account': 'Already have an account?',
    },

    'मराठी': {
      // App
      'app_name': 'नगरसेतू',

      // Common
      'loading': 'लोड होत आहे...',
      'error': 'त्रुटी',
      'retry': 'पुन्हा प्रयत्न करा',
      'cancel': 'रद्द करा',
      'ok': 'ठीक आहे',
      'save': 'जतन करा',
      'submit': 'सबमिट करा',
      'done': 'पूर्ण',
      'yes': 'होय',
      'no': 'नाही',

      // Navigation
      'home': 'मुख्यपृष्ठ',
      'map': 'नकाशा',
      'report': 'तक्रार',
      'my_issues': 'माझ्या तक्रारी',
      'profile': 'प्रोफाइल',

      // Home Screen
      'welcome': 'स्वागत आहे',
      'report_issue': 'तक्रार नोंदवा',
      'view_issues': 'तक्रारी पहा',
      'quick_actions': 'जलद क्रिया',
      'recent_issues': 'अलीकडील तक्रारी',
      'no_issues': 'अद्याप कोणतीही तक्रार नोंदवलेली नाही',

      // Report Issue Screen
      'report_new_issue': 'नवीन तक्रार नोंदवा',
      'issue_title': 'तक्रारीचे शीर्षक',
      'description': 'वर्णन',
      'add_description': 'वर्णन जोडा',
      'speak_description': 'तक्रारीचे वर्णन बोला',
      'issue_type': 'तक्रारीचा प्रकार',
      'criticality': 'गंभीरता',
      'location': 'स्थान',
      'add_photo': 'फोटो जोडा',
      'take_photo': 'फोटो काढा',
      'choose_from_gallery': 'गॅलरीतून निवडा',
      'submit_issue': 'तक्रार सबमिट करा',
      'issue_reported': 'तक्रार नोंदवली!',
      'issue_reported_message':
          'तुमची तक्रार यशस्वीरित्या नोंदवली गेली आहे. स्वीकारल्यानंतर तुम्हाला सूचित केले जाईल.',
      'please_add_photo': 'कृपया तक्रारीचा फोटो जोडा',
      'please_add_description': 'कृपया वर्णन जोडा',
      'please_add_title': 'कृपया तक्रारीचे शीर्षक लिहा',
      'generate_title': 'शीर्षक तयार करा',
      'auto_generate_title': 'AI वापरून शीर्षक स्वयंचलितपणे तयार करा',

      // Issue Types
      'road': 'रस्ता',
      'water': 'पाणी',
      'electricity': 'वीज',
      'garbage': 'कचरा',
      'drainage': 'नाले',
      'streetlight': 'पथदिवे',
      'public_safety': 'सार्वजनिक सुरक्षा',
      'other': 'इतर',

      // Criticality
      'low': 'कमी',
      'medium': 'मध्यम',
      'high': 'उच्च',
      'critical': 'अत्यंत गंभीर',

      // Status
      'pending': 'प्रलंबित',
      'acknowledged': 'स्वीकारले',
      'in_progress': 'प्रगतीपथावर',
      'team_assigned': 'टीम नियुक्त',
      'resolved': 'निराकरण झाले',

      // My Issues Screen
      'no_issues_reported': 'अद्याप कोणतीही तक्रार नोंदवलेली नाही',
      'report_issue_to_see': 'येथे पाहण्यासाठी तक्रार नोंदवा',
      'loading_issues': 'तक्रारी लोड होत आहेत...',

      // Issue Detail Screen
      'issue_details': 'तक्रारीचे तपशील',
      'issue_id': 'तक्रार क्रमांक',
      'reported_on': 'नोंदवल्याची तारीख',
      'loading_issue_details': 'तक्रारीचे तपशील लोड होत आहेत...',

      // Map Screen
      'issue_map': 'तक्रार नकाशा',
      'issues_found': 'तक्रारी सापडल्या',

      // Profile Screen
      'edit_profile': 'प्रोफाइल संपादित करा',
      'settings': 'सेटिंग्ज',
      'notifications': 'सूचना',
      'language': 'भाषा',
      'dark_mode': 'डार्क मोड',
      'support_info': 'मदत आणि माहिती',
      'help_center': 'मदत केंद्र',
      'about': 'आमच्याबद्दल',
      'privacy_policy': 'गोपनीयता धोरण',
      'terms_of_service': 'सेवा अटी',
      'logout': 'लॉगआउट',
      'logout_confirm': 'तुम्हाला खात्री आहे की तुम्ही लॉगआउट करू इच्छिता?',
      'loading_profile': 'प्रोफाइल लोड होत आहे...',
      'issues_reported': 'नोंदवलेल्या तक्रारी',
      'issues_resolved': 'निराकरण झालेल्या तक्रारी',
      'member_since': 'सदस्य झाल्यापासून',

      // Auth
      'login': 'लॉगिन',
      'signup': 'साइन अप',
      'email': 'ईमेल',
      'password': 'पासवर्ड',
      'forgot_password': 'पासवर्ड विसरलात?',
      'dont_have_account': 'खाते नाही?',
      'already_have_account': 'आधीच खाते आहे?',
    },

    'हिंदी': {
      // App
      'app_name': 'नगरसेतु',

      // Common
      'loading': 'लोड हो रहा है...',
      'error': 'त्रुटि',
      'retry': 'पुनः प्रयास करें',
      'cancel': 'रद्द करें',
      'ok': 'ठीक है',
      'save': 'सहेजें',
      'submit': 'जमा करें',
      'done': 'पूर्ण',
      'yes': 'हाँ',
      'no': 'नहीं',

      // Navigation
      'home': 'होम',
      'map': 'नक्शा',
      'report': 'रिपोर्ट',
      'my_issues': 'मेरी शिकायतें',
      'profile': 'प्रोफाइल',

      // Home Screen
      'welcome': 'स्वागत है',
      'report_issue': 'शिकायत दर्ज करें',
      'view_issues': 'शिकायतें देखें',
      'quick_actions': 'त्वरित कार्य',
      'recent_issues': 'हाल की शिकायतें',
      'no_issues': 'अभी तक कोई शिकायत दर्ज नहीं',

      // Report Issue Screen
      'report_new_issue': 'नई शिकायत दर्ज करें',
      'issue_title': 'शिकायत का शीर्षक',
      'description': 'विवरण',
      'add_description': 'विवरण जोड़ें',
      'speak_description': 'शिकायत का विवरण बोलें',
      'issue_type': 'शिकायत का प्रकार',
      'criticality': 'गंभीरता',
      'location': 'स्थान',
      'add_photo': 'फोटो जोड़ें',
      'take_photo': 'फोटो लें',
      'choose_from_gallery': 'गैलरी से चुनें',
      'submit_issue': 'शिकायत जमा करें',
      'issue_reported': 'शिकायत दर्ज हो गई!',
      'issue_reported_message':
          'आपकी शिकायत सफलतापूर्वक दर्ज हो गई है। स्वीकार होने पर आपको सूचित किया जाएगा।',
      'please_add_photo': 'कृपया शिकायत का फोटो जोड़ें',
      'please_add_description': 'कृपया विवरण जोड़ें',
      'please_add_title': 'कृपया शिकायत का शीर्षक दर्ज करें',
      'generate_title': 'शीर्षक बनाएं',
      'auto_generate_title': 'AI का उपयोग करके शीर्षक स्वचालित रूप से बनाएं',

      // Issue Types
      'road': 'सड़क',
      'water': 'पानी',
      'electricity': 'बिजली',
      'garbage': 'कचरा',
      'drainage': 'नाली',
      'streetlight': 'स्ट्रीटलाइट',
      'public_safety': 'सार्वजनिक सुरक्षा',
      'other': 'अन्य',

      // Criticality
      'low': 'कम',
      'medium': 'मध्यम',
      'high': 'उच्च',
      'critical': 'अत्यधिक गंभीर',

      // Status
      'pending': 'लंबित',
      'acknowledged': 'स्वीकृत',
      'in_progress': 'प्रगति में',
      'team_assigned': 'टीम नियुक्त',
      'resolved': 'समाधान हो गया',

      // My Issues Screen
      'no_issues_reported': 'अभी तक कोई शिकायत दर्ज नहीं',
      'report_issue_to_see': 'यहाँ देखने के लिए शिकायत दर्ज करें',
      'loading_issues': 'शिकायतें लोड हो रही हैं...',

      // Issue Detail Screen
      'issue_details': 'शिकायत विवरण',
      'issue_id': 'शिकायत क्रमांक',
      'reported_on': 'दर्ज करने की तारीख',
      'loading_issue_details': 'शिकायत विवरण लोड हो रहा है...',

      // Map Screen
      'issue_map': 'शिकायत नक्शा',
      'issues_found': 'शिकायतें मिलीं',

      // Profile Screen
      'edit_profile': 'प्रोफाइल संपादित करें',
      'settings': 'सेटिंग्स',
      'notifications': 'सूचनाएं',
      'language': 'भाषा',
      'dark_mode': 'डार्क मोड',
      'support_info': 'सहायता और जानकारी',
      'help_center': 'सहायता केंद्र',
      'about': 'हमारे बारे में',
      'privacy_policy': 'गोपनीयता नीति',
      'terms_of_service': 'सेवा की शर्तें',
      'logout': 'लॉगआउट',
      'logout_confirm': 'क्या आप वाकई लॉगआउट करना चाहते हैं?',
      'loading_profile': 'प्रोफाइल लोड हो रहा है...',
      'issues_reported': 'दर्ज की गई शिकायतें',
      'issues_resolved': 'समाधान हुई शिकायतें',
      'member_since': 'सदस्य बने',

      // Auth
      'login': 'लॉगिन',
      'signup': 'साइन अप',
      'email': 'ईमेल',
      'password': 'पासवर्ड',
      'forgot_password': 'पासवर्ड भूल गए?',
      'dont_have_account': 'खाता नहीं है?',
      'already_have_account': 'पहले से खाता है?',
    },

    'தமிழ்': {
      // App
      'app_name': 'நகர்சேது',

      // Common
      'loading': 'ஏற்றுகிறது...',
      'error': 'பிழை',
      'retry': 'மீண்டும் முயற்சிக்க',
      'cancel': 'ரத்து செய்',
      'ok': 'சரி',
      'save': 'சேமி',
      'submit': 'சமர்ப்பி',
      'done': 'முடிந்தது',
      'yes': 'ஆம்',
      'no': 'இல்லை',

      // Navigation
      'home': 'முகப்பு',
      'map': 'வரைபடம்',
      'report': 'புகார்',
      'my_issues': 'என் புகார்கள்',
      'profile': 'சுயவிவரம்',

      // Home Screen
      'welcome': 'வரவேற்கிறோம்',
      'report_issue': 'புகார் பதிவு செய்',
      'view_issues': 'புகார்களை காண்க',
      'quick_actions': 'விரைவு செயல்கள்',
      'recent_issues': 'சமீபத்திய புகார்கள்',
      'no_issues': 'இன்னும் புகார் எதுவும் பதிவாகவில்லை',

      // Profile Screen
      'settings': 'அமைப்புகள்',
      'notifications': 'அறிவிப்புகள்',
      'language': 'மொழி',
      'logout': 'வெளியேறு',
    },

    'తెలుగు': {
      // App
      'app_name': 'నగర్‌సేతు',

      // Common
      'loading': 'లోడ్ అవుతోంది...',
      'error': 'లోపం',
      'retry': 'మళ్ళీ ప్రయత్నించు',
      'cancel': 'రద్దు',
      'ok': 'సరే',
      'save': 'సేవ్ చేయి',
      'submit': 'సబ్మిట్',
      'done': 'పూర్తయింది',
      'yes': 'అవును',
      'no': 'కాదు',

      // Navigation
      'home': 'హోమ్',
      'map': 'మ్యాప్',
      'report': 'రిపోర్ట్',
      'my_issues': 'నా సమస్యలు',
      'profile': 'ప్రొఫైల్',

      // Home Screen
      'welcome': 'స్వాగతం',
      'report_issue': 'సమస్య నమోదు చేయి',
      'view_issues': 'సమస్యలు చూడు',

      // Profile Screen
      'settings': 'సెట్టింగ్స్',
      'notifications': 'నోటిఫికేషన్లు',
      'language': 'భాష',
      'logout': 'లాగ్ అవుట్',
    },
  };
}

// Extension for easy access
extension LocalizationExtension on BuildContext {
  String tr(String key) => LocalizationService().translate(key);
}
