import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:nightingale_heart/core/config/app_constants.dart';
import 'package:nightingale_heart/core/widgets/glass_card.dart';

/// In-app privacy notice for Nurse Singles.
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Last Updated ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Last updated: April 29, 2026',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),

            // ── 1. Introduction ───────────────────────────────────────────
            _buildSection(
              theme: theme,
              title: '1. Introduction',
              children: [
                _bodyText(
                  theme,
                  'Welcome to ${AppConstants.appName} ("we," "us," or "our"). '
                  '${AppConstants.appName} is a dating and social networking '
                  'application designed specifically for healthcare professionals, '
                  'including nurses, doctors, medical technicians, and other '
                  'individuals working in the healthcare industry. We are committed '
                  'to protecting your privacy and ensuring the security of your '
                  'personal information.',
                ),
                const SizedBox(height: 12),
                _bodyText(
                  theme,
                  'This Privacy Policy explains how we collect, use, disclose, '
                  'and safeguard your information when you use our mobile '
                  'application and related services (collectively, the "Service"). '
                  'This policy applies to all users of ${AppConstants.appName}, '
                  'regardless of how you access or use the Service. By using '
                  '${AppConstants.appName}, you agree to the collection and use of '
                  'information in accordance with this Privacy Policy. If you do not '
                  'agree with the terms of this Privacy Policy, please do not access '
                  'or use the Service.',
                ),
                const SizedBox(height: 12),
                _bodyText(
                  theme,
                  'We encourage you to read this Privacy Policy carefully and in '
                  'its entirety. If you have any questions or concerns about our '
                  'privacy practices, please contact us at '
                  '${AppConstants.supportEmail}.',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── 2. Information We Collect ──────────────────────────────────
            _buildSection(
              theme: theme,
              title: 'Healthcare Privacy and HIPAA-Aware Use',
              children: [
                _bodyText(
                  theme,
                  '${AppConstants.appName} is a social, dating, and networking '
                  'service for healthcare workers. It is not a medical care, '
                  'diagnosis, treatment, emergency, patient charting, or employer '
                  'workforce management tool.',
                ),
                const SizedBox(height: 12),
                _bodyText(
                  theme,
                  'Do not post, upload, or send patient names, patient photos, '
                  'medical record numbers, case details, protected health '
                  'information, employer-confidential information, or anything '
                  'that could identify a patient or private workplace matter.',
                ),
                const SizedBox(height: 12),
                _bodyText(
                  theme,
                  'Healthcare credential reviews are handled privately. We do not '
                  'publicly display license numbers or credential evidence. If a '
                  'future partner program involves a covered entity or protected '
                  'health information, separate legal review and appropriate '
                  'agreements are required. This policy does not promise HIPAA '
                  'compliance for uses outside the Service described here.',
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildSection(
              theme: theme,
              title: '2. Information We Collect',
              children: [
                _bodyText(
                  theme,
                  'We collect several types of information to provide and improve '
                  'the Service. The categories of information we collect include:',
                ),
                const SizedBox(height: 16),
                _subSectionTitle(theme, '2.1 Personal Information'),
                const SizedBox(height: 8),
                _bodyText(
                  theme,
                  'When you create an account and use ${AppConstants.appName}, we '
                  'collect personal information that you voluntarily provide to us. '
                  'This includes your full name, email address, date of birth, '
                  'gender, profile photographs, healthcare profession or job title, '
                  'workplace or hospital name, and geographic location (city, state, '
                  'or country). We require your date of birth to verify that you '
                  'meet the minimum age requirement for using our Service.',
                ),
                const SizedBox(height: 16),
                _subSectionTitle(theme, '2.2 Profile Information'),
                const SizedBox(height: 8),
                _bodyText(
                  theme,
                  'To help you connect with compatible matches, we collect '
                  'additional profile information that you choose to provide. This '
                  'may include your biography or personal description, interests and '
                  'hobbies, shift schedule and work patterns (such as day shift, '
                  'night shift, or rotating shifts), languages spoken, relationship '
                  'preferences, education background, and any other information you '
                  'choose to include in your profile. Providing this information is '
                  'optional, but it helps improve your experience and matching '
                  'accuracy.',
                ),
                const SizedBox(height: 16),
                _subSectionTitle(theme, '2.3 Usage Data'),
                const SizedBox(height: 8),
                _bodyText(
                  theme,
                  'We automatically collect data about how you interact with the '
                  'Service. This includes your swipe activity (likes, dislikes, and '
                  'superlikes), match history and match interactions, messaging '
                  'activity and conversation metadata (we do not read your messages '
                  'for advertising purposes), video call session logs including '
                  'duration and connection quality, features you use and pages you '
                  'visit within the app, gift transactions and virtual item '
                  'purchases, speed dating participation records, and the dates and '
                  'times of your interactions with the Service.',
                ),
                const SizedBox(height: 16),
                _subSectionTitle(theme, '2.4 Device Information'),
                const SizedBox(height: 8),
                _bodyText(
                  theme,
                  'When you access ${AppConstants.appName}, we automatically '
                  'collect certain device and technical information. This includes '
                  'your device type, model, and manufacturer, operating system type '
                  'and version, unique device identifiers (such as device ID, '
                  'advertising ID, or IDFA/GAID), IP address, mobile network '
                  'information, app version and build number, browser type (if '
                  'accessing web-based features), and push notification tokens for '
                  'delivering notifications to your device.',
                ),
                const SizedBox(height: 16),
                _subSectionTitle(theme, '2.5 Location Data'),
                const SizedBox(height: 8),
                _bodyText(
                  theme,
                  'With your permission, we collect approximate location data to '
                  'provide location-based matching and to show you users who are '
                  'nearby. We use your device\'s location services to determine your '
                  'approximate geographic position. You can control location access '
                  'through your device settings at any time. If you disable location '
                  'services, certain features of the app, such as distance-based '
                  'matching and discovery, may not function properly. We do not '
                  'continuously track your precise, real-time location.',
                ),
                const SizedBox(height: 16),
                _subSectionTitle(theme, '2.6 Payment Information'),
                const SizedBox(height: 8),
                _bodyText(
                  theme,
                  'If you purchase a subscription or make in-app purchases, payment '
                  'processing is handled entirely by Apple (App Store), Google '
                  '(Google Play Store), or our payment processor RevenueCat. We do '
                  'not collect, store, or have access to your full credit card '
                  'numbers, debit card numbers, or banking information. We receive '
                  'only a transaction confirmation, the type of subscription or '
                  'purchase made, and transaction identifiers necessary to manage '
                  'your subscription and provide customer support.',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── 3. How We Use Your Information ────────────────────────────
            _buildSection(
              theme: theme,
              title: '3. How We Use Your Information',
              children: [
                _bodyText(
                  theme,
                  'We use the information we collect for the following purposes:',
                ),
                const SizedBox(height: 12),
                _bulletPoint(
                  theme,
                  'Providing and Maintaining the Service: To create and manage your '
                  'account, display your profile to other users, facilitate matches '
                  'and connections, enable messaging and video calling, and deliver '
                  'the core features of ${AppConstants.appName}.',
                ),
                _bulletPoint(
                  theme,
                  'Matching and Discovery: To recommend compatible users based on '
                  'your profile information, preferences, location, profession, '
                  'shift schedule, and interaction history.',
                ),
                _bulletPoint(
                  theme,
                  'Improving the Service: To analyze usage patterns, diagnose '
                  'technical issues, conduct research and analytics, and develop '
                  'new features and improvements to enhance your experience.',
                ),
                _bulletPoint(
                  theme,
                  'Communications and Notifications: To send you push '
                  'notifications about new matches, messages, and activity; to '
                  'provide important service updates, security alerts, and account '
                  'notifications; and to respond to your support requests and '
                  'inquiries.',
                ),
                _bulletPoint(
                  theme,
                  'Safety and Fraud Prevention: To detect, investigate, and prevent '
                  'fraudulent transactions, abuse, harassment, spam, and other '
                  'harmful or unauthorized activities; to enforce our Terms of '
                  'Service and community guidelines; and to protect the safety and '
                  'security of our users.',
                ),
                _bulletPoint(
                  theme,
                  'Advertising: To display relevant advertisements within the app '
                  'through our advertising partner (Google AdMob). Free-tier users '
                  'may see personalized ads based on general interests, while '
                  'premium subscribers enjoy an ad-reduced or ad-free experience.',
                ),
                _bulletPoint(
                  theme,
                  'Legal Compliance: To comply with applicable laws, regulations, '
                  'legal processes, or enforceable governmental requests; to '
                  'establish, exercise, or defend legal claims; and to protect our '
                  'rights, privacy, safety, or property.',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── 4. Legal Basis for Processing ─────────────────────────────
            _buildSection(
              theme: theme,
              title: '4. Legal Basis for Processing (GDPR)',
              children: [
                _bodyText(
                  theme,
                  'If you are located in the European Economic Area (EEA), the '
                  'United Kingdom, or Switzerland, we process your personal data '
                  'based on the following legal grounds under the General Data '
                  'Protection Regulation (GDPR):',
                ),
                const SizedBox(height: 12),
                _bulletPoint(
                  theme,
                  'Consent: Where you have given us explicit consent to process '
                  'your personal data for specific purposes, such as enabling '
                  'location services, receiving marketing communications, or '
                  'processing special categories of data (e.g., information about '
                  'your profession). You may withdraw your consent at any time by '
                  'contacting us or adjusting your app settings.',
                ),
                _bulletPoint(
                  theme,
                  'Contract Performance: Processing that is necessary to perform '
                  'our contract with you, including providing the Service, managing '
                  'your account, facilitating matches and messaging, processing '
                  'subscription transactions, and delivering the features you have '
                  'requested.',
                ),
                _bulletPoint(
                  theme,
                  'Legitimate Interests: Processing that is necessary for our '
                  'legitimate interests or the legitimate interests of a third '
                  'party, provided that such interests are not overridden by your '
                  'rights and freedoms. Our legitimate interests include improving '
                  'and optimizing the Service, ensuring platform safety and '
                  'security, preventing fraud and abuse, conducting analytics, and '
                  'marketing our Service.',
                ),
                _bulletPoint(
                  theme,
                  'Legal Obligation: Processing that is necessary for compliance '
                  'with a legal obligation to which we are subject, such as '
                  'responding to lawful requests from public authorities, '
                  'maintaining records as required by applicable law, or reporting '
                  'illegal activity.',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── 5. Sharing Your Information ───────────────────────────────
            _buildSection(
              theme: theme,
              title: '5. Sharing Your Information',
              children: [
                _bodyText(
                  theme,
                  'We may share your information in the following circumstances:',
                ),
                const SizedBox(height: 12),
                _subSectionTitle(theme, '5.1 With Other Users'),
                const SizedBox(height: 8),
                _bodyText(
                  theme,
                  'Your profile information, including your name, photographs, bio, '
                  'profession, and other details you choose to share, will be '
                  'visible to other ${AppConstants.appName} users as part of the '
                  'matching and discovery features. When you match with another '
                  'user, both parties may see additional profile details. Messages '
                  'you send are delivered to the intended recipient. Information '
                  'shared during video calls is transmitted directly between '
                  'participants.',
                ),
                const SizedBox(height: 16),
                _subSectionTitle(theme, '5.2 With Service Providers'),
                const SizedBox(height: 8),
                _bodyText(
                  theme,
                  'We engage trusted third-party service providers to perform '
                  'functions and provide services on our behalf. These providers '
                  'have access to your personal information only to the extent '
                  'necessary to perform their services and are contractually '
                  'obligated to protect your data. Our key service providers '
                  'include:',
                ),
                const SizedBox(height: 8),
                _bulletPoint(
                  theme,
                  'Firebase / Google Cloud: For authentication, database storage '
                  '(Cloud Firestore), file storage (Cloud Storage), cloud '
                  'functions, crash reporting (Crashlytics), and analytics.',
                ),
                _bulletPoint(
                  theme,
                  'RevenueCat: For subscription and in-app purchase management '
                  'across Apple and Google platforms.',
                ),
                _bulletPoint(
                  theme,
                  'ZegoCloud: For real-time video calling and speed dating '
                  'functionality, including video and audio stream processing.',
                ),
                _bulletPoint(
                  theme,
                  'Google AdMob: For serving advertisements to free-tier users, '
                  'which may involve the collection of advertising identifiers and '
                  'general interest data.',
                ),
                const SizedBox(height: 16),
                _subSectionTitle(theme, '5.3 For Legal Requirements'),
                const SizedBox(height: 8),
                _bodyText(
                  theme,
                  'We may disclose your information if required to do so by law or '
                  'in the good-faith belief that such action is necessary to comply '
                  'with a legal obligation, court order, subpoena, or other '
                  'governmental request; protect and defend our rights or property; '
                  'prevent or investigate possible wrongdoing in connection with the '
                  'Service; protect the personal safety of users of the Service or '
                  'the public; or protect against legal liability.',
                ),
                const SizedBox(height: 16),
                _subSectionTitle(theme, '5.4 No Sale of Personal Data'),
                const SizedBox(height: 8),
                _bodyText(
                  theme,
                  'We do not sell, rent, or trade your personal information to '
                  'third parties for their marketing purposes. We have not sold '
                  'personal information in the preceding twelve (12) months and do '
                  'not intend to do so in the future. This commitment applies to '
                  'all users, including California residents under the CCPA/CPRA.',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── 6. Data Retention ─────────────────────────────────────────
            _buildSection(
              theme: theme,
              title: '6. Data Retention',
              children: [
                _bodyText(
                  theme,
                  'We retain your personal information for as long as your account '
                  'is active and as needed to provide you with the Service. If you '
                  'choose to delete your account, we will initiate the deletion of '
                  'your personal data from our active systems within thirty (30) '
                  'days of your request. This includes your profile information, '
                  'photographs, match history, messages, and other user-generated '
                  'content.',
                ),
                const SizedBox(height: 12),
                _bodyText(
                  theme,
                  'Please note that some information may be retained for a limited '
                  'period beyond the 30-day window in backup systems, or as '
                  'necessary to comply with our legal obligations, resolve disputes, '
                  'enforce our agreements, or protect our legitimate business '
                  'interests. We may also retain anonymized or aggregated data that '
                  'can no longer be used to identify you for analytical and service '
                  'improvement purposes indefinitely.',
                ),
                const SizedBox(height: 12),
                _bodyText(
                  theme,
                  'If your account is suspended or banned due to a violation of our '
                  'Terms of Service, we may retain certain information as necessary '
                  'to prevent the creation of a new account and to protect the '
                  'safety of our community.',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── 7. Data Security ──────────────────────────────────────────
            _buildSection(
              theme: theme,
              title: '7. Data Security',
              children: [
                _bodyText(
                  theme,
                  'We take the security of your personal information seriously and '
                  'implement appropriate technical and organizational measures to '
                  'protect it against unauthorized access, alteration, disclosure, '
                  'or destruction. Our security measures include:',
                ),
                const SizedBox(height: 12),
                _bulletPoint(
                  theme,
                  'Encryption in Transit: All data transmitted between your device '
                  'and our servers is encrypted using industry-standard TLS/SSL '
                  'protocols.',
                ),
                _bulletPoint(
                  theme,
                  'Encryption at Rest: Your personal data stored in our database '
                  'systems (Firebase/Google Cloud) is encrypted at rest using '
                  'AES-256 encryption.',
                ),
                _bulletPoint(
                  theme,
                  'Firebase Security Rules: We implement granular Firestore '
                  'security rules that restrict data access to authorized users '
                  'only, ensuring that users can only read and modify their own '
                  'data and data they are authorized to access.',
                ),
                _bulletPoint(
                  theme,
                  'Access Controls: Access to user data within our organization is '
                  'restricted on a need-to-know basis. Administrative access is '
                  'protected by multi-factor authentication.',
                ),
                _bulletPoint(
                  theme,
                  'Regular Security Reviews: We periodically review and update our '
                  'security practices to address emerging threats and '
                  'vulnerabilities.',
                ),
                const SizedBox(height: 12),
                _bodyText(
                  theme,
                  'While we strive to use commercially acceptable means to protect '
                  'your personal data, no method of transmission over the internet '
                  'or method of electronic storage is 100% secure. We cannot '
                  'guarantee absolute security, but we are committed to promptly '
                  'addressing any security incidents and notifying affected users as '
                  'required by applicable law.',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── 8. Children's Privacy ─────────────────────────────────────
            _buildSection(
              theme: theme,
              title: '8. Children\'s Privacy',
              children: [
                _bodyText(
                  theme,
                  '${AppConstants.appName} is not intended for use by anyone under '
                  'the age of eighteen (18) years. We do not knowingly collect '
                  'personal information from children under 18. When you create an '
                  'account, you represent and warrant that you are at least 18 years '
                  'of age.',
                ),
                const SizedBox(height: 12),
                _bodyText(
                  theme,
                  'If we become aware that we have inadvertently collected personal '
                  'information from a child under 18, we will take immediate steps '
                  'to delete such information from our systems. If you are a parent '
                  'or guardian and you believe that your child has provided us with '
                  'personal information without your consent, please contact us '
                  'immediately at ${AppConstants.supportEmail} so that we can take '
                  'appropriate action.',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── 9. Your Rights ────────────────────────────────────────────
            _buildSection(
              theme: theme,
              title: '9. Your Rights',
              children: [
                _bodyText(
                  theme,
                  'Depending on your location, you may have certain rights '
                  'regarding your personal information. We are committed to '
                  'honoring these rights and providing you with meaningful control '
                  'over your data.',
                ),
                const SizedBox(height: 16),
                _subSectionTitle(theme, '9.1 Rights Under the GDPR (EEA/UK)'),
                const SizedBox(height: 8),
                _bodyText(
                  theme,
                  'If you are located in the European Economic Area or the United '
                  'Kingdom, you have the following rights under the General Data '
                  'Protection Regulation:',
                ),
                const SizedBox(height: 8),
                _bulletPoint(
                  theme,
                  'Right of Access: You have the right to request a copy of the '
                  'personal data we hold about you, along with information about '
                  'how we process it.',
                ),
                _bulletPoint(
                  theme,
                  'Right to Rectification: You have the right to request that we '
                  'correct any inaccurate or incomplete personal data we hold about '
                  'you. You can also update most of your profile information '
                  'directly within the app.',
                ),
                _bulletPoint(
                  theme,
                  'Right to Erasure ("Right to be Forgotten"): You have the right '
                  'to request the deletion of your personal data. You can delete '
                  'your account directly within the app through Settings, or by '
                  'contacting us.',
                ),
                _bulletPoint(
                  theme,
                  'Right to Data Portability: You have the right to receive your '
                  'personal data in a structured, commonly used, and '
                  'machine-readable format, and to request the transfer of such '
                  'data to another controller where technically feasible.',
                ),
                _bulletPoint(
                  theme,
                  'Right to Restriction of Processing: You have the right to '
                  'request that we restrict the processing of your personal data '
                  'under certain circumstances, such as when you contest the '
                  'accuracy of the data or when processing is unlawful.',
                ),
                _bulletPoint(
                  theme,
                  'Right to Object: You have the right to object to the processing '
                  'of your personal data based on legitimate interests or for '
                  'direct marketing purposes.',
                ),
                _bulletPoint(
                  theme,
                  'Right to Withdraw Consent: Where processing is based on your '
                  'consent, you have the right to withdraw that consent at any '
                  'time, without affecting the lawfulness of processing based on '
                  'consent before its withdrawal.',
                ),
                _bulletPoint(
                  theme,
                  'Right to Lodge a Complaint: You have the right to lodge a '
                  'complaint with your local data protection supervisory authority '
                  'if you believe that we have not complied with applicable data '
                  'protection laws.',
                ),
                const SizedBox(height: 16),
                _subSectionTitle(
                  theme,
                  '9.2 Rights Under the CCPA/CPRA (California)',
                ),
                const SizedBox(height: 8),
                _bodyText(
                  theme,
                  'If you are a California resident, you have the following rights '
                  'under the California Consumer Privacy Act (CCPA) as amended by '
                  'the California Privacy Rights Act (CPRA):',
                ),
                const SizedBox(height: 8),
                _bulletPoint(
                  theme,
                  'Right to Know: You have the right to request that we disclose '
                  'the categories and specific pieces of personal information we '
                  'have collected about you, the categories of sources from which '
                  'we collected it, the business or commercial purpose for '
                  'collecting it, and the categories of third parties with whom '
                  'we share it.',
                ),
                _bulletPoint(
                  theme,
                  'Right to Delete: You have the right to request the deletion of '
                  'personal information we have collected from you, subject to '
                  'certain exceptions permitted by law.',
                ),
                _bulletPoint(
                  theme,
                  'Right to Correct: You have the right to request the correction '
                  'of inaccurate personal information that we maintain about you.',
                ),
                _bulletPoint(
                  theme,
                  'Right to Opt-Out of Sale or Sharing: You have the right to '
                  'opt-out of the sale or sharing of your personal information. As '
                  'stated above, we do not sell your personal information.',
                ),
                _bulletPoint(
                  theme,
                  'Right to Non-Discrimination: You have the right not to receive '
                  'discriminatory treatment for exercising any of your privacy '
                  'rights. We will not deny you access to the Service, charge you '
                  'different prices, or provide a different quality of service '
                  'because you exercised your privacy rights.',
                ),
                const SizedBox(height: 16),
                _subSectionTitle(theme, '9.3 How to Exercise Your Rights'),
                const SizedBox(height: 8),
                _bodyText(
                  theme,
                  'To exercise any of the rights described above, you may: (a) '
                  'email us at ${AppConstants.supportEmail} with your request, '
                  'including sufficient information to verify your identity; (b) '
                  'use the in-app account deletion feature available in Settings to '
                  'delete your account and associated data; or (c) adjust your '
                  'privacy settings within the app to control certain data '
                  'collection and sharing preferences. We will respond to verifiable '
                  'requests within thirty (30) days, or within the timeframe '
                  'required by applicable law. We may request additional information '
                  'to verify your identity before fulfilling your request.',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── 10. Cookies & Tracking Technologies ───────────────────────
            _buildSection(
              theme: theme,
              title: '10. Cookies & Tracking Technologies',
              children: [
                _bodyText(
                  theme,
                  '${AppConstants.appName} and our third-party partners use '
                  'certain tracking technologies within the mobile application to '
                  'provide, analyze, and improve the Service. These include:',
                ),
                const SizedBox(height: 12),
                _bulletPoint(
                  theme,
                  'Firebase Analytics: We use Google Firebase Analytics to collect '
                  'usage data and understand how users interact with our app. This '
                  'includes information about app opens, screen views, user '
                  'engagement, and feature usage. Firebase Analytics may use device '
                  'identifiers and instance IDs to aggregate data.',
                ),
                _bulletPoint(
                  theme,
                  'Google AdMob: For free-tier users, AdMob may use advertising '
                  'identifiers (IDFA on iOS, GAID on Android) and device '
                  'information to deliver personalized advertisements. You can opt '
                  'out of personalized ads through your device\'s advertising '
                  'settings.',
                ),
                _bulletPoint(
                  theme,
                  'Firebase Crashlytics: We use Crashlytics to collect crash '
                  'reports and diagnostic data, including device state information, '
                  'unique device identifiers, and crash stack traces. This helps us '
                  'identify and fix bugs to improve app stability.',
                ),
                _bulletPoint(
                  theme,
                  'Firebase Cloud Messaging: We use push notification tokens to '
                  'deliver notifications to your device. These tokens are unique to '
                  'your device and app installation.',
                ),
                const SizedBox(height: 12),
                _bodyText(
                  theme,
                  'You can manage your tracking preferences through your device '
                  'settings. On iOS, you can use App Tracking Transparency to '
                  'control app tracking. On Android, you can reset your advertising '
                  'ID or opt out of ads personalization in your device settings.',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── 11. Third-Party Services ──────────────────────────────────
            _buildSection(
              theme: theme,
              title: '11. Third-Party Services',
              children: [
                _bodyText(
                  theme,
                  '${AppConstants.appName} integrates with several third-party '
                  'services to provide our features. Each of these services has its '
                  'own privacy policy governing how they collect and use data. We '
                  'encourage you to review their privacy policies:',
                ),
                const SizedBox(height: 12),
                _bulletPoint(
                  theme,
                  'Google / Firebase: Provides authentication, database, storage, '
                  'analytics, and cloud functions. Privacy policy available at '
                  'https://policies.google.com/privacy',
                ),
                _bulletPoint(
                  theme,
                  'RevenueCat: Manages subscriptions and in-app purchases across '
                  'platforms. Privacy policy available at '
                  'https://www.revenuecat.com/privacy',
                ),
                _bulletPoint(
                  theme,
                  'ZegoCloud: Provides real-time video and audio communication '
                  'for video calls and speed dating features. Privacy policy '
                  'available at https://www.zegocloud.com/privacy',
                ),
                _bulletPoint(
                  theme,
                  'Google AdMob: Serves advertisements to free-tier users within '
                  'the app. Privacy policy available at '
                  'https://policies.google.com/privacy',
                ),
                _bulletPoint(
                  theme,
                  'Apple App Store / Google Play Store: Handles app distribution '
                  'and payment processing for in-app purchases and subscriptions.',
                ),
                const SizedBox(height: 12),
                _bodyText(
                  theme,
                  'We are not responsible for the privacy practices of these '
                  'third-party services. We recommend that you review their '
                  'respective privacy policies to understand how they handle your '
                  'information.',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── 12. International Data Transfers ──────────────────────────
            _buildSection(
              theme: theme,
              title: '12. International Data Transfers',
              children: [
                _bodyText(
                  theme,
                  '${AppConstants.appName} operates globally, and your personal '
                  'information may be transferred to, stored, and processed in '
                  'countries other than your country of residence, including the '
                  'United States and other countries where our service providers '
                  'maintain facilities. These countries may have data protection '
                  'laws that are different from the laws of your country.',
                ),
                const SizedBox(height: 12),
                _bodyText(
                  theme,
                  'When we transfer personal data from the European Economic Area, '
                  'the United Kingdom, or Switzerland to countries that have not '
                  'been recognized as providing an adequate level of data '
                  'protection, we ensure that appropriate safeguards are in place. '
                  'These safeguards may include Standard Contractual Clauses '
                  'approved by the European Commission, data processing agreements '
                  'with our service providers, or other legally recognized transfer '
                  'mechanisms. By using the Service, you acknowledge and consent to '
                  'the transfer of your information to these countries, subject to '
                  'the protections described in this Privacy Policy.',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── 13. Changes to This Policy ────────────────────────────────
            _buildSection(
              theme: theme,
              title: '13. Changes to This Policy',
              children: [
                _bodyText(
                  theme,
                  'We may update this Privacy Policy from time to time to reflect '
                  'changes in our practices, technologies, legal requirements, or '
                  'other factors. When we make material changes to this Privacy '
                  'Policy, we will notify you through the app via an in-app '
                  'notification or a prominent notice on our Service, and we will '
                  'update the "Last updated" date at the top of this page.',
                ),
                const SizedBox(height: 12),
                _bodyText(
                  theme,
                  'We encourage you to review this Privacy Policy periodically to '
                  'stay informed about how we are protecting your information. Your '
                  'continued use of ${AppConstants.appName} after the posting of '
                  'changes constitutes your acceptance of those changes. If you do '
                  'not agree with any changes to this Privacy Policy, you should '
                  'stop using the Service and delete your account.',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── 14. Contact Us ────────────────────────────────────────────
            _buildSection(
              theme: theme,
              title: '14. Contact Us',
              children: [
                _bodyText(
                  theme,
                  'If you have any questions, concerns, or requests regarding this '
                  'Privacy Policy or our data practices, please contact us at:',
                ),
                const SizedBox(height: 12),
                _bodyText(theme, 'Email: ${AppConstants.supportEmail}'),
                const SizedBox(height: 8),
                _bodyText(
                  theme,
                  'When contacting us, please include sufficient information to '
                  'identify yourself (such as the email address associated with '
                  'your ${AppConstants.appName} account) and a clear description of '
                  'your request. We will endeavor to respond to all legitimate '
                  'requests within thirty (30) days. In some cases, we may need '
                  'additional time, in which case we will inform you of the reason '
                  'for the delay and the expected timeframe for our response.',
                ),
                const SizedBox(height: 12),
                _bodyText(
                  theme,
                  'If you are a resident of the European Economic Area and you '
                  'believe that we have not adequately addressed your data '
                  'protection concerns, you have the right to lodge a complaint '
                  'with your local data protection supervisory authority.',
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ).animate().fadeIn(duration: 400.ms),
      ),
    );
  }

  // ── Section builder ───────────────────────────────────────────────────────

  Widget _buildSection({
    required ThemeData theme,
    required String title,
    required List<Widget> children,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  // ── Sub-section title ─────────────────────────────────────────────────────

  Widget _subSectionTitle(ThemeData theme, String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  // ── Body text ─────────────────────────────────────────────────────────────

  Widget _bodyText(ThemeData theme, String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  // ── Bullet point ──────────────────────────────────────────────────────────

  Widget _bulletPoint(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 10),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.6,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
