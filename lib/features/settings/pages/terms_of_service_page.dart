import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:nightingale_heart/core/config/app_constants.dart';
import 'package:nightingale_heart/core/widgets/glass_card.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Terms of Service',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Last updated notice
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

            // 1. Acceptance of Terms
            _buildSection(
              context: context,
              theme: theme,
              number: '1',
              title: 'Acceptance of Terms',
              body:
                  'By downloading, installing, accessing, or using the ${AppConstants.appName} mobile application '
                  '("App," "Service," or "Platform"), you acknowledge that you have read, understood, and agree to '
                  'be bound by these Terms of Service ("Terms"). These Terms constitute a legally binding agreement '
                  'between you ("User," "you," or "your") and ${AppConstants.appName} ("Company," "we," "us," or "our").\n\n'
                  'If you do not agree to all of these Terms, you must immediately cease using the App and delete it '
                  'from your device. Your continued use of the App after any modification to these Terms constitutes '
                  'your acceptance of the modified Terms. We reserve the right to update or modify these Terms at any '
                  'time, and it is your responsibility to review them periodically. Material changes will be communicated '
                  'through in-app notifications or email to the address associated with your account.',
            ),

            // 2. Eligibility
            _buildSection(
              context: context,
              theme: theme,
              number: '2',
              title: 'Eligibility',
              body:
                  'To create an account and use ${AppConstants.appName}, you must meet all of the following requirements:\n\n'
                  'a) Age Requirement: You must be at least eighteen (18) years of age. By creating an account, you '
                  'represent and warrant that you are at least 18 years old. We reserve the right to request proof of '
                  'age at any time and to terminate accounts where the user is found to be underage.\n\n'
                  'b) Healthcare Professional Status: ${AppConstants.appName} is designed exclusively for healthcare '
                  'professionals, including but not limited to registered nurses, licensed practical nurses, nurse '
                  'practitioners, certified nursing assistants, physicians, surgeons, pharmacists, therapists, medical '
                  'technicians, paramedics, and other allied health professionals. By registering, you represent that '
                  'you are currently employed in, studying toward, or retired from a healthcare profession. We may '
                  'request verification of your professional credentials at any time.\n\n'
                  'c) Legal Capacity: You must have the legal capacity to enter into a binding contract in your '
                  'jurisdiction of residence. You must not be prohibited from using the App under any applicable law.\n\n'
                  'd) Account Restrictions: You may not create an account if you have been previously banned or '
                  'removed from the Platform for violating these Terms. You may only maintain one active account at '
                  'any time.',
            ),

            // 3. Account Registration & Security
            _buildSection(
              context: context,
              theme: theme,
              number: '3',
              title: 'Account Registration & Security',
              body:
                  'When you register for ${AppConstants.appName}, you agree to provide accurate, current, and complete '
                  'information as prompted by the registration process. You are responsible for maintaining the accuracy '
                  'of your profile information and updating it promptly if any changes occur.\n\n'
                  'a) Account Credentials: You are solely responsible for maintaining the confidentiality and security '
                  'of your account credentials, including your password and any authentication tokens. You agree to '
                  'immediately notify us at ${AppConstants.supportEmail} if you suspect any unauthorized access to or '
                  'use of your account.\n\n'
                  'b) Account Responsibility: You are fully responsible for all activities that occur under your account, '
                  'whether or not authorized by you. The Company shall not be liable for any loss or damage arising '
                  'from your failure to maintain the security of your account credentials.\n\n'
                  'c) Accurate Information: You agree not to create an account using false or misleading information, '
                  'impersonate another person, or use another person\'s identity without their explicit permission. '
                  'Providing fraudulent credentials, including fabricated healthcare professional status, is grounds '
                  'for immediate termination and may be reported to relevant authorities.\n\n'
                  'd) Third-Party Authentication: If you choose to register or log in using third-party authentication '
                  'providers (such as Google Sign-In), you authorize us to access and use certain information from '
                  'those services in accordance with our Privacy Policy.',
            ),

            // 4. User Conduct
            _buildSection(
              context: context,
              theme: theme,
              number: '4',
              title: 'User Conduct',
              body:
                  'You agree to use ${AppConstants.appName} in a manner consistent with all applicable laws, '
                  'regulations, and these Terms. The following conduct is strictly prohibited and may result in '
                  'immediate suspension or permanent termination of your account:\n\n'
                  'a) Harassment and Abuse: Engaging in any form of harassment, bullying, intimidation, stalking, '
                  'or threatening behavior toward other users. This includes, but is not limited to, sending '
                  'unsolicited explicit content, making derogatory remarks based on race, ethnicity, gender, sexual '
                  'orientation, religion, disability, or any other protected characteristic.\n\n'
                  'b) Fake Profiles and Misrepresentation: Creating fraudulent, misleading, or deceptive profiles. '
                  'This includes using photographs of another person without their consent, fabricating personal '
                  'information, or misrepresenting your healthcare professional status.\n\n'
                  'c) Solicitation and Commercial Activity: Using the Platform to solicit money, promote commercial '
                  'products or services, recruit for employment, engage in multi-level marketing, or conduct any '
                  'form of advertising without prior written consent from the Company.\n\n'
                  'd) Illegal Activity: Using the App to facilitate, promote, or engage in any illegal activity, '
                  'including but not limited to fraud, identity theft, distribution of controlled substances, money '
                  'laundering, or trafficking.\n\n'
                  'e) Contact with Minors: Any attempt to use the Platform to contact, solicit, or engage with '
                  'individuals under the age of 18 for any purpose is strictly prohibited and will be reported to '
                  'law enforcement authorities.\n\n'
                  'f) Unauthorized Commercial Use: Using any automated systems, bots, scrapers, or similar technology '
                  'to access, collect data from, or interact with the App. Reverse engineering, decompiling, or '
                  'disassembling any part of the App is prohibited.\n\n'
                  'g) Harmful Content: Uploading, sharing, or transmitting any content that is defamatory, obscene, '
                  'pornographic, violent, or that promotes hatred, discrimination, or harm against any individual or '
                  'group. Sharing content that contains viruses, malware, or any code designed to disrupt or damage '
                  'the App or its infrastructure is also prohibited.\n\n'
                  'h) Patient and Employer Confidentiality: You may not post, upload, transmit, or request patient '
                  'names, photos, medical record numbers, case details, protected health information, private clinical '
                  'information, or employer-confidential information. ${AppConstants.appName} is not a medical, '
                  'clinical, emergency, charting, or employer workforce tool, and you are responsible for following '
                  'all professional, workplace, privacy, and confidentiality obligations that apply to you.',
            ),

            // 5. Content & Intellectual Property
            _buildSection(
              context: context,
              theme: theme,
              number: '5',
              title: 'Content & Intellectual Property',
              body:
                  'a) User Content Ownership: You retain all ownership rights to the photographs, text, and other '
                  'content that you upload, post, or transmit through the App ("User Content"). You are solely '
                  'responsible for ensuring that your User Content does not infringe upon the intellectual property '
                  'rights, privacy rights, or any other rights of third parties.\n\n'
                  'b) License Grant to the Company: By uploading or sharing User Content on the Platform, you grant '
                  '${AppConstants.appName} a non-exclusive, worldwide, royalty-free, sublicensable, and transferable '
                  'license to use, reproduce, modify, adapt, publish, display, and distribute your User Content '
                  'solely for the purposes of operating, developing, providing, promoting, and improving the App '
                  'and our services. This license continues for a commercially reasonable period after you remove '
                  'your User Content or delete your account, to allow for backup and archival purposes.\n\n'
                  'c) Platform Intellectual Property: The App, including its design, logos, trademarks, service marks, '
                  'trade names, software, source code, algorithms, visual interfaces, graphics, text, images, '
                  'audio, video, and all other elements of the Service (collectively, "Platform IP"), are the '
                  'exclusive property of ${AppConstants.appName} and are protected by copyright, trademark, patent, '
                  'trade secret, and other intellectual property laws. You may not copy, reproduce, modify, '
                  'distribute, create derivative works from, or publicly display any Platform IP without our prior '
                  'written consent.\n\n'
                  'd) Feedback: Any suggestions, ideas, enhancement requests, feedback, or recommendations you '
                  'provide to us regarding the App are entirely voluntary and non-confidential, and we shall be '
                  'free to use such feedback without any obligation or compensation to you.',
            ),

            // 6. Subscriptions & Payments
            _buildSection(
              context: context,
              theme: theme,
              number: '6',
              title: 'Subscriptions & Payments',
              body:
                  '${AppConstants.appName} offers various subscription tiers that provide enhanced features and '
                  'functionality. By purchasing a subscription, you agree to the following terms:\n\n'
                  'a) Auto-Renewal: All subscriptions automatically renew at the end of each billing cycle (monthly '
                  'or as otherwise specified) at the then-current subscription price unless you cancel before the '
                  'renewal date. You authorize us to charge the payment method on file for recurring subscription '
                  'fees.\n\n'
                  'b) Cancellation: You may cancel your subscription at any time through your device\'s app store '
                  '(Apple App Store or Google Play Store) account settings. Cancellation will take effect at the end '
                  'of the current billing period, and you will continue to have access to premium features until that '
                  'date. Cancellation does not entitle you to a refund for the current billing period.\n\n'
                  'c) Refund Policy: Subscription payments are processed through the Apple App Store or Google Play '
                  'Store, and refund requests must be submitted directly through the respective app store in '
                  'accordance with their refund policies. ${AppConstants.appName} does not process refunds directly '
                  'for subscription purchases. We encourage you to review the refund policies of the applicable app '
                  'store before making a purchase.\n\n'
                  'd) In-App Purchases: Certain features, virtual items, and content may be available for purchase '
                  'within the App. All in-app purchases are final and non-refundable, except as required by applicable '
                  'law. In-app purchases are licensed to you on a limited, personal, non-transferable, non-sublicensable, '
                  'and revocable basis.\n\n'
                  'e) Price Changes: We reserve the right to change subscription prices at any time. Price changes for '
                  'existing subscribers will take effect at the start of the next billing cycle following reasonable '
                  'notice of the price change.',
            ),

            // 7. Virtual Gifts & In-App Currency
            _buildSection(
              context: context,
              theme: theme,
              number: '7',
              title: 'Virtual Gifts & In-App Currency',
              body:
                  '${AppConstants.appName} may offer virtual gifts, gift points, tokens, or other forms of in-app '
                  'currency ("Virtual Items") that can be purchased or earned through App usage.\n\n'
                  'a) No Real-World Value: Virtual Items have no real-world monetary value and cannot be exchanged '
                  'for cash, legal tender, or any form of real currency. Virtual Items do not constitute property '
                  'and are not transferable between users or accounts, except as explicitly permitted within the '
                  'App\'s gift-sending functionality.\n\n'
                  'b) Non-Transferable: You may not sell, trade, barter, or otherwise transfer Virtual Items to '
                  'other users or third parties outside of the App\'s intended functionality. Any attempt to do so '
                  'is a violation of these Terms and may result in account termination.\n\n'
                  'c) Non-Refundable: All purchases of Virtual Items are final and non-refundable, except as required '
                  'by applicable law. Unused Virtual Items will not be refunded upon account deletion or termination.\n\n'
                  'd) Modifications: We reserve the right to modify, manage, regulate, control, or eliminate Virtual '
                  'Items at our sole discretion, including changing the pricing, availability, or functionality of '
                  'Virtual Items. We shall have no liability to you or any third party for the exercise of such rights.\n\n'
                  'e) Earned Rewards: Virtual Items earned through watching advertisements, completing missions, or '
                  'other promotional activities are subject to the same restrictions and may be revoked if obtained '
                  'through fraudulent or abusive means.',
            ),

            // 8. Video Dating & Communication
            _buildSection(
              context: context,
              theme: theme,
              number: '8',
              title: 'Video Dating & Communication',
              body:
                  '${AppConstants.appName} provides video dating features, including speed dating sessions and '
                  'one-on-one video calls, to facilitate real-time connections between users.\n\n'
                  'a) Appropriate Behavior: All participants in video dating sessions must conduct themselves in a '
                  'respectful and appropriate manner. Nudity, sexual conduct, display of explicit or offensive '
                  'material, use of illegal substances, and any form of harassment during video calls are strictly '
                  'prohibited and will result in immediate account suspension or termination.\n\n'
                  'b) Recording Prohibited: You may not record, capture, screenshot, or otherwise reproduce any video '
                  'or audio content from video dating sessions or private calls without the explicit, prior written '
                  'consent of all participants. Unauthorized recording may violate applicable privacy laws and will '
                  'result in permanent account termination.\n\n'
                  'c) Report Mechanism: If you experience inappropriate behavior, harassment, or any violation of '
                  'these Terms during a video session, you may report the incident using the in-app reporting tools. '
                  'We take all reports seriously and will investigate them promptly. Users who are found to have '
                  'violated these Terms during video sessions will face appropriate consequences, up to and including '
                  'permanent account termination and referral to law enforcement.\n\n'
                  'd) Technical Requirements: Video features require a stable internet connection, camera, and '
                  'microphone access. The Company is not responsible for poor video quality, dropped calls, or '
                  'technical issues arising from your device, network, or third-party service providers.\n\n'
                  'e) Video Minutes: Video calling features may be subject to usage limits based on your subscription '
                  'tier. Additional video minutes may be purchased as in-app purchases or earned through promotional '
                  'activities.',
            ),

            // 9. Matching & Interactions
            _buildSection(
              context: context,
              theme: theme,
              number: '9',
              title: 'Matching & Interactions',
              body:
                  'a) No Guarantee of Matches: ${AppConstants.appName} does not guarantee that you will receive any '
                  'particular number of matches, likes, or interactions. The availability and frequency of matches '
                  'depend on various factors, including but not limited to your profile completeness, activity level, '
                  'geographic location, and the preferences of other users.\n\n'
                  'b) Algorithm Discretion: Our matching algorithms use various signals and criteria to suggest '
                  'potential matches. We reserve the right to modify, improve, or change our matching algorithms at '
                  'any time at our sole discretion without prior notice. We do not disclose the specific details of '
                  'our proprietary matching algorithms.\n\n'
                  'c) User Interactions: You are solely responsible for your interactions with other users. '
                  '${AppConstants.appName} does not conduct criminal background checks, identity verification beyond '
                  'basic profile review, or screening of users. We strongly recommend exercising caution and good '
                  'judgment when communicating with or meeting other users.\n\n'
                  'd) Offline Meetings: If you choose to meet another user in person, you do so entirely at your '
                  'own risk. We recommend meeting in public places, informing a friend or family member of your plans, '
                  'and taking appropriate safety precautions. The Company is not responsible for the conduct of any '
                  'user, whether online or offline.',
            ),

            // 10. Safety & Reporting
            _buildSection(
              context: context,
              theme: theme,
              number: '10',
              title: 'Safety & Reporting',
              body:
                  '${AppConstants.appName} is committed to providing a safe and respectful environment for all users '
                  'in the healthcare community.\n\n'
                  'a) Report Abuse: We encourage all users to report any behavior that violates these Terms, '
                  'including harassment, threats, fraud, fake profiles, or any other inappropriate conduct. Reports '
                  'can be submitted through the in-app reporting feature available on user profiles and within '
                  'conversations. You may also contact us directly at ${AppConstants.supportEmail}.\n\n'
                  'b) Zero Tolerance for Harassment: We maintain a strict zero-tolerance policy for harassment, '
                  'hate speech, discrimination, threats of violence, and sexual misconduct. Users found engaging in '
                  'such behavior will face immediate account suspension or permanent termination, without refund of '
                  'any subscription fees or Virtual Items.\n\n'
                  'c) Cooperation with Law Enforcement: We cooperate fully with law enforcement agencies and '
                  'regulatory authorities in investigating criminal activity, threats to public safety, or violations '
                  'of applicable laws. We may disclose user information, communications, and usage data to law '
                  'enforcement without prior notice to the user when required by law, subpoena, court order, or when '
                  'we believe in good faith that disclosure is necessary to protect the safety of any person or to '
                  'prevent imminent harm.\n\n'
                  'd) Safety Resources: If you are in immediate danger or experiencing a medical emergency, please '
                  'contact your local emergency services immediately. ${AppConstants.appName} is not an emergency '
                  'service and cannot provide real-time assistance for emergencies.',
            ),

            // 11. Termination
            _buildSection(
              context: context,
              theme: theme,
              number: '11',
              title: 'Termination',
              body:
                  'a) Termination by the Company: We reserve the right to suspend, restrict, or permanently terminate '
                  'your account and access to the App at any time, with or without cause, and with or without prior '
                  'notice, if we reasonably believe that you have violated these Terms, engaged in fraudulent or '
                  'illegal activity, or posed a risk to the safety or well-being of other users. In the event of '
                  'termination for cause, you will not be entitled to any refund of subscription fees, in-app '
                  'purchases, or Virtual Items.\n\n'
                  'b) Termination by the User: You may delete your account at any time through the App\'s settings '
                  'menu. Upon account deletion, your profile will be removed from the Platform, and your personal '
                  'data will be handled in accordance with our Privacy Policy. Please note that some information may '
                  'be retained for a reasonable period for legal, regulatory, fraud prevention, or legitimate '
                  'business purposes.\n\n'
                  'c) Effects of Termination: Upon termination or deletion of your account, your right to use the '
                  'App and access its features will immediately cease. Any unused subscription time, Virtual Items, '
                  'gift points, or other in-app benefits will be forfeited and will not be refunded. Content you have '
                  'shared with other users (such as messages) may continue to be visible to those users even after '
                  'your account is deleted.\n\n'
                  'd) Survival: The provisions of these Terms that by their nature should survive termination shall '
                  'survive, including but not limited to intellectual property provisions, disclaimers, limitations '
                  'of liability, indemnification obligations, and dispute resolution provisions.',
            ),

            // 12. Disclaimers
            _buildSection(
              context: context,
              theme: theme,
              number: '12',
              title: 'Disclaimers',
              body:
                  'a) "As Is" Basis: THE APP AND ALL SERVICES ARE PROVIDED ON AN "AS IS" AND "AS AVAILABLE" BASIS '
                  'WITHOUT WARRANTIES OF ANY KIND, WHETHER EXPRESS, IMPLIED, STATUTORY, OR OTHERWISE. TO THE FULLEST '
                  'EXTENT PERMITTED BY APPLICABLE LAW, THE COMPANY DISCLAIMS ALL WARRANTIES, INCLUDING BUT NOT '
                  'LIMITED TO IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, TITLE, AND '
                  'NON-INFRINGEMENT.\n\n'
                  'b) No Guarantee of Matches: ${AppConstants.appName} does not guarantee that you will find a '
                  'romantic partner, match, friend, or any specific outcome through the use of the App. The success '
                  'of your interactions depends on numerous factors beyond our control, including your own efforts '
                  'and the actions of other users.\n\n'
                  'c) No Background Checks: ${AppConstants.appName} does not conduct criminal background checks, '
                  'sex offender registry checks, or comprehensive identity verification of its users. While we may '
                  'offer optional profile verification features, these do not constitute a guarantee of a user\'s '
                  'identity, character, intentions, or suitability. You acknowledge the inherent risks of interacting '
                  'with strangers and agree to exercise caution.\n\n'
                  'd) Service Availability: We do not warrant that the App will be uninterrupted, error-free, secure, '
                  'or free of viruses or other harmful components. We may modify, suspend, or discontinue any aspect '
                  'of the App at any time without prior notice or liability.\n\n'
                  'e) Third-Party Services: The App may integrate with or contain links to third-party services, '
                  'including payment processors, video conferencing providers, and cloud services. We are not '
                  'responsible for the availability, accuracy, content, or practices of third-party services and do '
                  'not endorse them.',
            ),

            // 13. Limitation of Liability
            _buildSection(
              context: context,
              theme: theme,
              number: '13',
              title: 'Limitation of Liability',
              body:
                  'a) User Interactions: TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, ${AppConstants.appName.toUpperCase()} '
                  'SHALL NOT BE LIABLE FOR ANY DAMAGES, CLAIMS, OR LOSSES ARISING FROM THE CONDUCT OF ANY USER, WHETHER '
                  'ONLINE OR OFFLINE, INCLUDING BUT NOT LIMITED TO PERSONAL INJURY, EMOTIONAL DISTRESS, PROPERTY DAMAGE, '
                  'OR FINANCIAL LOSS RESULTING FROM INTERACTIONS WITH OTHER USERS OF THE APP.\n\n'
                  'b) Damages Cap: IN NO EVENT SHALL THE COMPANY, ITS DIRECTORS, OFFICERS, EMPLOYEES, AFFILIATES, AGENTS, '
                  'CONTRACTORS, OR LICENSORS BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, PUNITIVE, OR '
                  'EXEMPLARY DAMAGES, INCLUDING BUT NOT LIMITED TO DAMAGES FOR LOSS OF PROFITS, GOODWILL, USE, DATA, OR '
                  'OTHER INTANGIBLE LOSSES, REGARDLESS OF WHETHER SUCH DAMAGES WERE FORESEEABLE AND WHETHER OR NOT THE '
                  'COMPANY WAS ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.\n\n'
                  'THE COMPANY\'S TOTAL AGGREGATE LIABILITY TO YOU FOR ALL CLAIMS ARISING OUT OF OR RELATING TO THESE '
                  'TERMS OR YOUR USE OF THE APP SHALL NOT EXCEED THE TOTAL AMOUNT OF SUBSCRIPTION FEES ACTUALLY PAID BY '
                  'YOU TO THE COMPANY DURING THE TWELVE (12) MONTHS IMMEDIATELY PRECEDING THE EVENT GIVING RISE TO THE '
                  'CLAIM, OR ONE HUNDRED DOLLARS (\$100.00), WHICHEVER IS GREATER.\n\n'
                  'c) Jurisdictional Limitations: Some jurisdictions do not allow the exclusion or limitation of certain '
                  'damages. In such jurisdictions, the limitations set forth above shall apply to the fullest extent '
                  'permitted by applicable law.',
            ),

            // 14. Indemnification
            _buildSection(
              context: context,
              theme: theme,
              number: '14',
              title: 'Indemnification',
              body:
                  'You agree to indemnify, defend, and hold harmless ${AppConstants.appName}, its parent company, '
                  'subsidiaries, affiliates, officers, directors, employees, agents, contractors, licensors, service '
                  'providers, and successors and assigns from and against any and all claims, demands, actions, damages, '
                  'losses, liabilities, costs, and expenses (including reasonable attorneys\' fees and court costs) arising '
                  'out of or relating to:\n\n'
                  'a) Your use or misuse of the App or its services;\n\n'
                  'b) Your User Content, including any claims that your User Content infringes upon the intellectual '
                  'property rights, privacy rights, or other rights of any third party;\n\n'
                  'c) Your violation of these Terms or any applicable law, regulation, or third-party right;\n\n'
                  'd) Your interactions with other users of the App, whether online or offline;\n\n'
                  'e) Any misrepresentation made by you, including misrepresentation of your healthcare professional '
                  'status, identity, or personal information.\n\n'
                  'This indemnification obligation shall survive the termination or expiration of these Terms and your '
                  'use of the App.',
            ),

            // 15. Governing Law
            _buildSection(
              context: context,
              theme: theme,
              number: '15',
              title: 'Governing Law',
              body:
                  'These Terms shall be governed by and construed in accordance with the laws of the State of California, '
                  'United States of America, without regard to its conflict of law principles. Any legal action or '
                  'proceeding arising out of or relating to these Terms or your use of the App shall be brought '
                  'exclusively in the federal or state courts located in Los Angeles County, California, and you hereby '
                  'consent to the personal jurisdiction and venue of such courts.\n\n'
                  'Any claim or cause of action arising out of or related to your use of the App or these Terms must be '
                  'filed within one (1) year after such claim or cause of action arose, or it shall be forever barred, '
                  'regardless of any statute of limitations or other law to the contrary.\n\n'
                  'To the extent permitted by applicable law, you agree to waive any right to participate in a class '
                  'action lawsuit or class-wide arbitration against ${AppConstants.appName}. You agree that any dispute '
                  'resolution proceedings will be conducted on an individual basis and not in a class, consolidated, or '
                  'representative action.',
            ),

            // 16. Changes to Terms
            _buildSection(
              context: context,
              theme: theme,
              number: '16',
              title: 'Changes to Terms',
              body:
                  '${AppConstants.appName} reserves the right to modify, amend, or replace these Terms at any time at '
                  'our sole discretion. When we make material changes to these Terms, we will provide notice through '
                  'one or more of the following methods: posting a prominent notice within the App, sending a push '
                  'notification, or emailing the address associated with your account.\n\n'
                  'The updated Terms will be effective upon posting unless a later effective date is specified. Your '
                  'continued use of the App after the effective date of any modified Terms constitutes your acceptance '
                  'of those changes. If you do not agree to the revised Terms, you must stop using the App and delete '
                  'your account.\n\n'
                  'We encourage you to periodically review these Terms to stay informed about our requirements and any '
                  'changes. The "Last updated" date at the top of these Terms indicates when they were most recently '
                  'revised.',
            ),

            // 17. Contact Information
            _buildSection(
              context: context,
              theme: theme,
              number: '17',
              title: 'Contact Information',
              body:
                  'If you have any questions, concerns, or feedback about these Terms of Service, or if you need to '
                  'report a violation of these Terms, please contact us using the following information:\n\n'
                  'Email: ${AppConstants.supportEmail}\n\n'
                  'When contacting us, please include your account email address and a detailed description of your '
                  'inquiry or concern so that we can assist you as promptly and effectively as possible.\n\n'
                  'For urgent safety concerns, including threats of violence or imminent harm, please contact your '
                  'local emergency services immediately before reaching out to us.\n\n'
                  'We aim to respond to all inquiries within a reasonable timeframe, typically within five (5) business '
                  'days. For complex matters that require additional investigation, response times may be longer, and '
                  'we will keep you informed of our progress.',
            ),

            const SizedBox(height: 40),
          ],
        ).animate().fadeIn(duration: 400.ms),
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required ThemeData theme,
    required String number,
    required String title,
    required String body,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$number. $title',
              style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              body,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.6,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
