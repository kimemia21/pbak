import 'package:flutter/material.dart';

/// Show Terms and Conditions Dialog
void showTermsAndConditionsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const _ModernLegalDialog(
      type: _LegalDialogType.terms,
    ),
  );
}

/// Show Privacy Policy Dialog
void showPrivacyPolicyDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const _ModernLegalDialog(
      type: _LegalDialogType.privacy,
    ),
  );
}

/// Show Help and Support Dialog
void showHelpAndSupportDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const _ModernLegalDialog(
      type: _LegalDialogType.help,
    ),
  );
}

enum _LegalDialogType { terms, privacy, help }

class _ModernLegalDialog extends StatelessWidget {
  final _LegalDialogType type;

  const _ModernLegalDialog({required this.type});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    // Dialog config based on type
    final config = _getConfig();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: config.color.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [config.color, config.color.withOpacity(0.8)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(config.icon, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  // Title
                  Text(
                    config.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    config.subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildContent(theme, isDark, config),
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252525) : Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  // Version/Date info
                  Expanded(
                    child: Text(
                      config.footerText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Close button
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.check_circle_rounded, size: 20),
                    label: const Text('Got it'),
                    style: FilledButton.styleFrom(
                      backgroundColor: config.color,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _DialogConfig _getConfig() {
    switch (type) {
      case _LegalDialogType.terms:
        return _DialogConfig(
          title: 'Terms & Conditions',
          subtitle: 'Please read carefully',
          icon: Icons.description_rounded,
          color: const Color(0xFF3B82F6), // Blue
          footerText: 'Last updated: Jan 2025',
        );
      case _LegalDialogType.privacy:
        return _DialogConfig(
          title: 'Privacy Policy',
          subtitle: 'Your data, your rights',
          icon: Icons.privacy_tip_rounded,
          color: const Color(0xFF10B981), // Green
          footerText: 'Effective: Jan 2025',
        );
      case _LegalDialogType.help:
        return _DialogConfig(
          title: 'Help & Support',
          subtitle: 'We\'re here for you',
          icon: Icons.support_agent_rounded,
          color: const Color(0xFFF59E0B), // Amber
          footerText: '24/7 Support Available',
        );
    }
  }

  List<Widget> _buildContent(ThemeData theme, bool isDark, _DialogConfig config) {
    switch (type) {
      case _LegalDialogType.terms:
        return _buildTermsContent(theme, isDark);
      case _LegalDialogType.privacy:
        return _buildPrivacyContent(theme, isDark);
      case _LegalDialogType.help:
        return _buildHelpContent(theme, isDark);
    }
  }

  List<Widget> _buildTermsContent(ThemeData theme, bool isDark) {
    return [
      _SectionCard(
        icon: Icons.handshake_rounded,
        title: 'Acceptance of Terms',
        content: 'By accessing or using the PBAK mobile application, you agree to be bound by these Terms and Conditions. If you do not agree, please do not use our services.',
        isDark: isDark,
      ),
      _SectionCard(
        icon: Icons.verified_user_rounded,
        title: 'Membership',
        content: 'To become a member of PBAK, you must:\n• Be at least 18 years of age\n• Provide accurate and complete information\n• Maintain updated profile information\n• Hold a valid motorcycle license',
        isDark: isDark,
      ),
      _SectionCard(
        icon: Icons.rule_rounded,
        title: 'Code of Conduct',
        content: 'Members must:\n• Respect all traffic laws and regulations\n• Treat fellow members with respect\n• Not engage in reckless riding behavior\n• Report any safety concerns promptly',
        isDark: isDark,
      ),
      _SectionCard(
        icon: Icons.shield_rounded,
        title: 'Liability',
        content: 'PBAK is not liable for any accidents, injuries, or damages that may occur during rides or events. Members participate at their own risk and are responsible for their own safety.',
        isDark: isDark,
      ),
      _SectionCard(
        icon: Icons.gavel_rounded,
        title: 'Termination',
        content: 'PBAK reserves the right to terminate or suspend membership for violation of these terms, non-payment of fees, or conduct detrimental to the association.',
        isDark: isDark,
      ),
    ];
  }

  List<Widget> _buildPrivacyContent(ThemeData theme, bool isDark) {
    return [
      _SectionCard(
        icon: Icons.data_usage_rounded,
        title: 'Information We Collect',
        content: 'We collect information you provide directly:\n• Personal details (name, email, phone)\n• Vehicle information\n• Location data (with permission)\n• Payment information',
        isDark: isDark,
      ),
      _SectionCard(
        icon: Icons.storage_rounded,
        title: 'How We Use Your Data',
        content: 'Your data is used to:\n• Provide membership services\n• Process payments and subscriptions\n• Send important notifications\n• Improve our services\n• Ensure safety during events',
        isDark: isDark,
      ),
      _SectionCard(
        icon: Icons.share_rounded,
        title: 'Information Sharing',
        content: 'We do not sell your personal information. We may share data with:\n• Event organizers (limited info)\n• Emergency services (when necessary)\n• Payment processors (secure)',
        isDark: isDark,
      ),
      _SectionCard(
        icon: Icons.security_rounded,
        title: 'Data Security',
        content: 'We implement industry-standard security measures to protect your data, including encryption, secure servers, and regular security audits.',
        isDark: isDark,
      ),
      _SectionCard(
        icon: Icons.manage_accounts_rounded,
        title: 'Your Rights',
        content: 'You have the right to:\n• Access your personal data\n• Request data correction\n• Delete your account\n• Opt-out of marketing communications',
        isDark: isDark,
      ),
    ];
  }

  List<Widget> _buildHelpContent(ThemeData theme, bool isDark) {
    return [
      _ContactCard(
        icon: Icons.phone_rounded,
        title: 'Call Us',
        value: '+254 700 000 000',
        subtitle: 'Available 24/7',
        color: const Color(0xFF10B981),
        isDark: isDark,
      ),
      _ContactCard(
        icon: Icons.email_rounded,
        title: 'Email Support',
        value: 'support@pbak.co.ke',
        subtitle: 'Response within 24hrs',
        color: const Color(0xFF3B82F6),
        isDark: isDark,
      ),
      _ContactCard(
        icon: Icons.location_on_rounded,
        title: 'Visit Us',
        value: 'PBAK Office, Nairobi',
        subtitle: 'Mon-Fri: 9AM - 5PM',
        color: const Color(0xFFF59E0B),
        isDark: isDark,
      ),
      const SizedBox(height: 16),
      _FAQItem(
        question: 'How do I update my profile?',
        answer: 'Go to Profile > Edit Profile to update your personal information, contact details, and emergency contacts.',
        isDark: isDark,
      ),
      _FAQItem(
        question: 'How do I register a new bike?',
        answer: 'Navigate to Bikes > Add Bike and fill in your motorcycle details including registration number and photos.',
        isDark: isDark,
      ),
      _FAQItem(
        question: 'How do I pay for membership?',
        answer: 'Go to Packages, select your preferred membership plan, and pay via M-Pesa. Payment is processed instantly.',
        isDark: isDark,
      ),
      _FAQItem(
        question: 'What is crash detection?',
        answer: 'Our crash detection feature monitors your ride and automatically alerts your emergency contact if an accident is detected.',
        isDark: isDark,
      ),
    ];
  }
}

class _DialogConfig {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String footerText;

  _DialogConfig({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.footerText,
  });
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final bool isDark;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.content,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.grey[400] : Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final bool isDark;

  const _ContactCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            color.withOpacity(isDark ? 0.15 : 0.1),
            isDark ? const Color(0xFF1E1E1E) : Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}

class _FAQItem extends StatefulWidget {
  final String question;
  final String answer;
  final bool isDark;

  const _FAQItem({
    required this.question,
    required this.answer,
    required this.isDark,
  });

  @override
  State<_FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<_FAQItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _expanded
              ? theme.colorScheme.primary.withOpacity(0.3)
              : (widget.isDark ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.15)),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.help_outline_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.question,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.expand_more_rounded,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      widget.answer,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: widget.isDark ? Colors.grey[400] : Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ),
                  crossFadeState: _expanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
