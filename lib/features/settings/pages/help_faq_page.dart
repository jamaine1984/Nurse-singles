import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nightingale_heart/core/config/app_constants.dart';
import 'package:nightingale_heart/core/config/app_theme.dart';
import 'package:nightingale_heart/core/widgets/glass_card.dart';

class HelpFaqPage extends StatefulWidget {
  const HelpFaqPage({super.key});

  @override
  State<HelpFaqPage> createState() => _HelpFaqPageState();
}

class _HelpFaqPageState extends State<HelpFaqPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // ── FAQ Data ────────────────────────────────────────────────────────────────

  static const List<Map<String, String>> _faqItems = [
    // ── Account ──────────────────────────────────────────────────────────────
    {
      'category': 'Account',
      'question': 'How do I create an account?',
      'answer':
          'Download Nurse Singles from the App Store or Google Play and tap "Sign Up". '
          'You can register with your email address or sign in with Google. '
          'Follow the onboarding steps to add your name, photos, healthcare '
          'specialty, and shift schedule to complete your profile.',
    },
    {
      'category': 'Account',
      'question': 'How do I verify my account?',
      'answer':
          'Go to Settings > Verification Status and follow the prompts. '
          'Verification helps build trust in the community by confirming you '
          'are a real healthcare professional. You may be asked to upload a '
          'selfie and a photo of your healthcare badge or license.',
    },
    {
      'category': 'Account',
      'question': 'How do I delete my account?',
      'answer':
          'Navigate to Settings > Danger Zone > Delete Account. You will be '
          'asked to confirm twice before deletion proceeds. Please note that '
          'account deletion is permanent -- all your matches, messages, photos, '
          'and profile data will be erased and cannot be recovered.',
    },
    {
      'category': 'Account',
      'question': 'How do I reset my password?',
      'answer':
          'On the login screen, tap "Forgot Password?" and enter the email '
          'address associated with your account. You will receive a password '
          'reset link via email. Follow the link to create a new password. '
          'If you do not see the email, check your spam folder.',
    },
    {
      'category': 'Account',
      'question': 'Can I change my email address?',
      'answer':
          'Currently you can update your display name and profile details from '
          'Settings > Edit Profile. To change the email address linked to your '
          'account, please contact our support team at '
          'support@nursesingles.com and we will assist you.',
    },

    // ── Matching & Discovery ─────────────────────────────────────────────────
    {
      'category': 'Privacy & Safety',
      'question': 'Can I discuss patients or clinical cases?',
      'answer':
          'No. Do not share patient names, photos, medical record numbers, case '
          'details, protected health information, or employer-confidential '
          'information. Nurse Singles is for dating and social networking, not '
          'clinical care, charting, emergencies, or workplace case discussion.',
    },
    {
      'category': 'Matching & Discovery',
      'question': 'How does matching work?',
      'answer':
          'When you like someone and they like you back, it is a match! Both of '
          'you will be notified, and a conversation will be created so you can '
          'start chatting. You can also send a Superlike to let someone know '
          'you are especially interested -- they will see your Superlike before '
          'regular likes.',
    },
    {
      'category': 'Matching & Discovery',
      'question': 'How do discovery filters work?',
      'answer':
          'Use the filter icon on the Discover page to narrow your search. You '
          'can filter by age range, distance, healthcare specialty, shift type, '
          'and what people are looking for. Filters help you find compatible '
          'matches who share your schedule and interests.',
    },
    {
      'category': 'Matching & Discovery',
      'question': 'What is a Superlike?',
      'answer':
          'A Superlike is a special way to show someone you are particularly '
          'interested. When you Superlike someone, your profile appears with a '
          'highlighted badge so they know you stood out. Free users receive a '
          'limited number of Superlikes; premium subscribers get more each month.',
    },
    {
      'category': 'Matching & Discovery',
      'question': 'What does boosting my profile do?',
      'answer':
          'Boosting puts your profile at the top of the discovery feed for 30 '
          'minutes, dramatically increasing your visibility. During a boost, '
          'you can receive up to 10x more profile views. Nurse and Doctor plan '
          'subscribers receive a free monthly boost.',
    },
    {
      'category': 'Matching & Discovery',
      'question': 'Why am I not getting any matches?',
      'answer':
          'Try these tips: add more photos (profiles with 3+ photos get more '
          'likes), write a detailed bio mentioning your specialty and hobbies, '
          'expand your distance and age filters, and check the app regularly '
          'since new users join every day. Using a boost can also help increase '
          'your visibility.',
    },

    // ── Messaging ────────────────────────────────────────────────────────────
    {
      'category': 'Messaging',
      'question': 'How do I message someone?',
      'answer':
          'You can message someone after you have matched. Go to the Messages '
          'tab to see all your conversations, or tap the message button on a '
          'match card. Free users have a daily message limit; upgrading your '
          'subscription gives you more or unlimited messages.',
    },
    {
      'category': 'Messaging',
      'question': 'Can I send gifts in chat?',
      'answer':
          'Yes! Tap the gift icon in the chat input area to browse and send '
          'virtual gifts. Gifts cost gift points, which you earn through daily '
          'activity and can purchase. There are over 60 gifts across categories '
          'like medical, romantic, luxury, and fun.',
    },
    {
      'category': 'Messaging',
      'question': 'How do I block or report someone in chat?',
      'answer':
          'Tap the three-dot menu (or the user\'s avatar) at the top of any '
          'conversation to access options for blocking and reporting. Blocking '
          'a user immediately prevents them from messaging you or seeing your '
          'profile. Reports are reviewed by our trust and safety team.',
    },
    {
      'category': 'Messaging',
      'question': 'Are voice notes supported?',
      'answer':
          'Yes, voice notes are supported in chat. Press and hold the microphone '
          'icon in the chat input to record a voice message. Release to send, '
          'or slide left to cancel. Voice notes are a great way to add a '
          'personal touch to your conversations.',
    },

    // ── Video Dating ─────────────────────────────────────────────────────────
    {
      'category': 'Video Dating',
      'question': 'How do video calls work?',
      'answer':
          'You can start a video call from any conversation by tapping the video '
          'camera icon. Video calls use your available video minutes. Both '
          'users must have minutes remaining and grant camera/microphone '
          'permissions. You can toggle your camera and microphone during the '
          'call.',
    },
    {
      'category': 'Video Dating',
      'question': 'How do I earn free video minutes?',
      'answer':
          'Watch a short rewarded ad from the Dashboard > Free Video Minutes '
          'section to earn bonus minutes. You can also earn minutes by '
          'completing daily missions, upgrading your subscription plan, or '
          'purchasing video minute packs directly from the subscription page.',
    },
    {
      'category': 'Video Dating',
      'question': 'What are speed dating rooms?',
      'answer':
          'Speed dating rooms are timed 1-on-1 video sessions with other '
          'healthcare professionals. Browse available rooms with durations of '
          '5, 10, or 30 minutes, join one, and get paired automatically. After '
          'each session you can rate your experience and choose to match with '
          'your partner.',
    },

    // ── Subscription ─────────────────────────────────────────────────────────
    {
      'category': 'Subscription',
      'question': 'What are the different plans?',
      'answer':
          'Nurse Singles offers five tiers: Free (basic access with daily limits), '
          'Tech (\$1.99/mo - 10 daily likes and messages, 120 video minutes), '
          'College (\$4.99/mo - 25 daily likes and messages, 300 video minutes), '
          'Nurse (\$14.99/mo - unlimited likes and messages, 1000 video minutes, '
          'see who liked you), and Doctor (\$39.99/mo - everything unlimited '
          'plus 3500 video minutes).',
    },
    {
      'category': 'Subscription',
      'question': 'How do I cancel my subscription?',
      'answer':
          'Go to Settings > Subscription > Manage Subscription. On Android, '
          'you will be directed to Google Play subscriptions; on iOS, to your '
          'Apple ID subscriptions. You can cancel at any time and will retain '
          'access to premium features until the end of your billing period.',
    },
    {
      'category': 'Subscription',
      'question': 'Can I get a refund?',
      'answer':
          'Refunds are handled by the App Store or Google Play, depending on '
          'your device. You can request a refund through their respective '
          'support pages. If you have billing issues, contact us at '
          'support@nursesingles.com and we will do our best to help.',
    },
    {
      'category': 'Subscription',
      'question': 'What can I do on the free plan?',
      'answer':
          'Free users get 3 daily likes, 3 daily messages, and access to the '
          'discovery feed and speed dating rooms. You can watch ads to earn '
          'extra likes, messages, and video minutes. Upgrade anytime for more '
          'features like Superlikes, unlimited messaging, and seeing who liked '
          'your profile.',
    },

    // ── Safety & Privacy ─────────────────────────────────────────────────────
    {
      'category': 'Safety & Privacy',
      'question': 'How do I report a user?',
      'answer':
          'Tap the three-dot menu on any user\'s profile or conversation and '
          'select "Report". Choose a reason such as inappropriate content, '
          'harassment, fake profile, or spam. Our moderation team reviews all '
          'reports and takes action within 24 hours.',
    },
    {
      'category': 'Safety & Privacy',
      'question': 'How do I block someone?',
      'answer':
          'Open the user\'s profile or conversation, tap the menu icon, and '
          'select "Block". Blocked users cannot see your profile, send you '
          'messages, or appear in your discovery feed. You can manage your '
          'blocked list from Settings > Blocked Users.',
    },
    {
      'category': 'Safety & Privacy',
      'question': 'Who can see my profile?',
      'answer':
          'By default, all Nurse Singles users within your discovery filters can '
          'see your profile. You can control visibility in Settings > Privacy. '
          'Nurse and Doctor plan subscribers can enable Incognito Mode, which '
          'hides your profile from everyone unless you like them first.',
    },
    {
      'category': 'Safety & Privacy',
      'question': 'How is my data protected?',
      'answer':
          'We use industry-standard encryption for all data in transit and at '
          'rest. Your personal information is stored securely on Firebase with '
          'strict security rules. We never sell your data to third parties. '
          'Read our full Privacy Policy for complete details on data handling.',
    },
    {
      'category': 'Safety & Privacy',
      'question': 'Is the app safe to use?',
      'answer':
          'Nurse Singles is designed with safety as a priority. We offer profile '
          'verification, blocking and reporting tools, incognito browsing for '
          'premium users, and a dedicated trust and safety team. We recommend '
          'meeting in public places and telling a friend when meeting someone '
          'for the first time.',
    },
  ];

  // ── Helpers ─────────────────────────────────────────────────────────────────

  List<Map<String, String>> get _filteredFaqs {
    if (_searchQuery.isEmpty) return _faqItems;
    final query = _searchQuery.toLowerCase();
    return _faqItems.where((faq) {
      return faq['question']!.toLowerCase().contains(query) ||
          faq['answer']!.toLowerCase().contains(query);
    }).toList();
  }

  /// Returns the unique categories present in the filtered list, preserving
  /// the original ordering.
  List<String> get _categories {
    final seen = <String>{};
    final result = <String>[];
    for (final faq in _filteredFaqs) {
      final cat = faq['category']!;
      if (seen.add(cat)) result.add(cat);
    }
    return result;
  }

  List<Map<String, String>> _faqsForCategory(String category) {
    return _filteredFaqs.where((f) => f['category'] == category).toList();
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'Account':
        return Icons.person_outline;
      case 'Matching & Discovery':
        return Icons.favorite_outline;
      case 'Messaging':
        return Icons.chat_bubble_outline;
      case 'Video Dating':
        return Icons.videocam_outlined;
      case 'Subscription':
        return Icons.workspace_premium_outlined;
      case 'Safety & Privacy':
        return Icons.shield_outlined;
      default:
        return Icons.help_outline;
    }
  }

  Future<void> _launchSupportEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: AppConstants.supportEmail,
      queryParameters: {'subject': 'Nurse Singles App Support Request'},
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = _categories;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Help & FAQ',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // ── Search Bar ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: GoogleFonts.plusJakartaSans(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Search questions...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: theme.scaffoldBackgroundColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppTheme.deepPlum,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(duration: 300.ms),

          // ── FAQ List ────────────────────────────────────────────────────
          Expanded(
            child: _filteredFaqs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 56,
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No results found',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Try a different search term',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: categories.length + 1, // +1 for the contact card
                    itemBuilder: (context, index) {
                      // ── Contact support card at the bottom ──────────────
                      if (index == categories.length) {
                        return _buildContactSupportCard(theme);
                      }

                      final category = categories[index];
                      final faqs = _faqsForCategory(category);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (index > 0) const SizedBox(height: 20),
                          _buildCategoryHeader(category, theme),
                          const SizedBox(height: 8),
                          GlassCard(
                            padding: EdgeInsets.zero,
                            child: Column(
                              children: [
                                for (int i = 0; i < faqs.length; i++) ...[
                                  if (i > 0)
                                    Divider(
                                      height: 1,
                                      indent: 16,
                                      endIndent: 16,
                                      color: theme.colorScheme.outline
                                          .withValues(alpha: 0.15),
                                    ),
                                  _FaqTile(
                                    question: faqs[i]['question']!,
                                    answer: faqs[i]['answer']!,
                                  ),
                                ],
                              ],
                            ),
                          ).animate().fadeIn(
                            duration: 300.ms,
                            delay: Duration(milliseconds: index * 60),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String category, ThemeData theme) {
    return Row(
      children: [
        Icon(_iconForCategory(category), size: 20, color: AppTheme.deepPlum),
        const SizedBox(width: 8),
        Text(
          category,
          style: GoogleFonts.playfairDisplay(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildContactSupportCard(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 40),
      child: GlassCard(
        showGradientOverlay: true,
        child: Column(
          children: [
            Icon(Icons.support_agent, size: 40, color: AppTheme.deepPlum),
            const SizedBox(height: 12),
            Text(
              'Still need help?',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Our support team is here for you. We typically respond within 24 hours.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                height: 1.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _launchSupportEmail,
                icon: const Icon(Icons.email_outlined, size: 18),
                label: Text(
                  'Contact Support',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.deepPlum,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }
}

// ── Expandable FAQ Tile ───────────────────────────────────────────────────────

class _FaqTile extends StatefulWidget {
  const _FaqTile({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.question,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _isExpanded
                          ? AppTheme.deepPlum
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more,
                    size: 22,
                    color: _isExpanded
                        ? AppTheme.deepPlum
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  widget.answer,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    height: 1.6,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
              sizeCurve: Curves.easeInOut,
            ),
          ],
        ),
      ),
    );
  }
}
