import 'package:flutter/material.dart';

/// Shows PBAK Terms & Conditions / Privacy Policy dialog.
///
/// Returns `true` if the user tapped "Agree", otherwise `false`.
Future<bool> showTermsAndConditionsDialog(BuildContext context) async {
  final theme = Theme.of(context);

  TextSpan h(String text) => TextSpan(
        text: '$text\n',
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          height: 1.25,
        ),
      );

  TextSpan sh(String text) => TextSpan(
        text: '$text\n',
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w800,
          height: 1.35,
        ),
      );

  TextSpan p(String text) => TextSpan(
        text: '$text\n\n',
        style: theme.textTheme.bodyMedium?.copyWith(
          height: 1.45,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );

  TextSpan line(String text) => TextSpan(
        text: '$text\n',
        style: theme.textTheme.bodyMedium?.copyWith(
          height: 1.45,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );

  TextSpan bullet(String text) => line('• $text');
  TextSpan dash(String text) => line('- $text');

  final agreed = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.verified_user_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            const Expanded(child: Text('Terms & Conditions')),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 480),
          child: SingleChildScrollView(
            child: SelectableText.rich(
              TextSpan(
                children: [
                  h('PRIVATE BIKERS’ ASSOCIATION OF KENYA (PBAK)'),
                  line('Membership & Events Portal / Mobile Application'),
                  p('Effective Date: January 2026'),

                  sh('1. PRIVACY POLICY'),
                  p(
                    'The Private Bikers Association of Kenya (PBAK) is committed to protecting the privacy, confidentiality, and security of its members’ personal, sensitive, and financial data. This Privacy Policy explains how information is collected, used, stored, processed, and protected when you access or use the PBAK Membership & Events Portal, Mobile Application, or related services.',
                  ),
                  p(
                    'By registering, accessing, or using the platform, you acknowledge that you have read, understood, and consent to this Privacy Policy.',
                  ),

                  sh('1.1 Legal & Regulatory Compliance'),
                  line('PBAK processes personal data in accordance with:'),
                  dash('The Kenya Data Protection Act, 2019'),
                  dash(
                    'Regulations and guidelines issued by the Office of the Data Protection Commissioner (ODPC)',
                  ),
                  line(''),
                  line('Lawful bases for processing include:'),
                  dash('Explicit user consent'),
                  dash(
                    'Contractual necessity (membership, event participation, and payment)',
                  ),
                  dash('Legal obligation'),
                  dash(
                    'Legitimate interest (safety, fraud prevention, operational integrity)',
                  ),
                  line(''),

                  sh('1.2 Information We Collect'),
                  line('a) Personal & Contact Information'),
                  bullet('Full name'),
                  bullet('National ID or Passport number'),
                  bullet('Date of birth'),
                  bullet('Phone number'),
                  bullet('Email address'),
                  bullet('Home / residential address'),
                  bullet('County and town of residence'),
                  p(
                    'Purpose: Identity verification, official records, safety coordination, and regulatory compliance.',
                  ),

                  line('b) User Profile Photograph (Mandatory)'),
                  bullet('Clear, recent front-facing photo'),
                  bullet('No helmets, sunglasses, or face coverings'),
                  p(
                    'Purpose: Identification, event safety, verification during rides and activities.',
                  ),

                  line('c) KYC & Identity Verification'),
                  bullet('Driving License (Mandatory - Front & Back Images)'),
                  line(
                    '  Front image: Full name, driving licence number, photograph, licence class',
                  ),
                  line(
                    '  Back image: Identification number (National ID or Passport), issuing authority, endorsements',
                  ),
                  line(''),

                  line('d) Motorcycle Information'),
                  bullet('Registration number, make, model, and engine capacity'),
                  bullet(
                    'Mandatory images: Front, side, rear (clearly showing number plate)',
                  ),
                  bullet(
                    'Foreign Registered Motorcycles: Chassis number, engine number, supporting ownership/import documentation',
                  ),
                  line(''),

                  line('e) Medical Information (Sensitive Data)'),
                  bullet('Blood group (optional but recommended)'),
                  bullet('Relevant medical conditions'),
                  bullet('Allergies'),
                  bullet('Ongoing medication (optional)'),
                  p('Purpose: Emergency response and rider safety only.'),

                  line('f) Insurance Information'),
                  bullet('Motorcycle insurance provider'),
                  bullet('Policy number'),
                  bullet('Insurance expiry date'),
                  p('Purpose: Legal compliance and event risk management.'),

                  line('g) Emergency Contact Information (Two Contacts - Mandatory)'),
                  bullet('Full name'),
                  bullet('Relationship to member'),
                  bullet('Phone number'),
                  p(
                    'Purpose: Contact next of kin or designated persons in case of accident, medical emergency, or serious incident.',
                  ),

                  line('h) Event, Safety & Participation Information'),
                  bullet('Event registrations and attendance'),
                  bullet('Ride participation declarations'),
                  bullet('Medical emergency consent'),
                  line(''),

                  line('i) Technical & Usage Data'),
                  bullet('IP address'),
                  bullet('Device type and operating system'),
                  bullet('Login timestamps'),
                  bullet('App usage and interaction data (security, analytics, system improvement)'),
                  line(''),

                  line('j) Payment Information'),
                  bullet('Payment method (credit/debit card, mobile money, or approved methods)'),
                  bullet('Transaction amount'),
                  bullet('Transaction ID / payment confirmation'),
                  p(
                    'Purpose: Facilitate event fee payments, confirm membership or event registration, maintain financial records for auditing and compliance. Data Handling: PBAK does not store full card details; payments are processed via trusted third-party providers compliant with PCI DSS and data protection regulations; transaction IDs and minimal necessary data are retained for record-keeping, refunds, and legal compliance.',
                  ),

                  sh('1.3 Purpose of Data Processing'),
                  line(
                    'Personal, sensitive, and financial data is processed strictly for:',
                  ),
                  line('▪ Membership registration and administration'),
                  line('▪ Identity and KYC verification'),
                  line('▪ Rider safety, event planning, and emergency response'),
                  line('▪ Contacting designated emergency contacts when necessary'),
                  line('▪ Payment collection, confirmation, and financial record-keeping'),
                  line('▪ Fraud prevention and legal compliance'),
                  line('▪ Official communication and service improvement'),
                  line(''),

                  sh('1.4 Medical & Emergency Data Protection'),
                  line('▪ Medical and emergency contact information is sensitive personal data'),
                  line('▪ Access restricted to authorized PBAK officials and emergency responders'),
                  line('▪ Emergency contacts are contacted only when necessary to protect life, health, or safety'),
                  line('▪ Data is not used for marketing or unrelated purposes'),
                  line(''),

                  sh('1.5 Data Storage & Security'),
                  line('▪ Stored securely using industry-standard safeguards'),
                  line('▪ Restricted access to authorized personnel'),
                  line('▪ Protection against unauthorized access, loss, misuse, or alteration'),
                  line(''),

                  sh('1.6 Data Sharing & Disclosure'),
                  p(
                    'PBAK does not sell or rent personal data. Information may be shared only: Where required by law; with medical or emergency responders during incidents; to contact designated emergency contacts; with trusted third-party service providers for payment processing under confidentiality agreements; with explicit user consent.',
                  ),

                  sh('1.7 Data Retention'),
                  dash(
                    'Personal, sensitive, and financial data is retained only as long as necessary for operational, legal, and auditing purposes',
                  ),
                  dash(
                    'Medical and emergency contact data may be deleted upon request, subject to safety considerations',
                  ),
                  dash(
                    'Payment transaction data may be retained for compliance, refund processing, and record-keeping',
                  ),
                  line(''),

                  sh('1.8 User Rights'),
                  line('Members may:'),
                  line('▪ Access personal data'),
                  line('▪ Request corrections'),
                  line('▪ Request deletion (subject to legal obligations)'),
                  line('Withdraw consent where applicable'),
                  p('Email: tech@pbak.co.ke & association@pbak.co.ke'),

                  sh('2. TERMS OF SERVICE'),
                  sh('2.1 Eligibility'),
                  p(
                    'Members must provide accurate personal, identification, medical (where applicable), insurance, two emergency contact details, and payment information where required.',
                  ),

                  sh('2.2 Member Responsibilities'),
                  dash(
                    'Keep emergency contact, medical, insurance, and payment information accurate and current',
                  ),
                  dash(
                    'Inform emergency contacts that their details are provided to PBAK',
                  ),
                  dash('Carry valid documents during events'),
                  line(''),

                  sh('2.4 Event Participation & Payment'),
                  dash('Event participation may require payment of fees'),
                  dash(
                    'Payment must be completed through approved methods before registration confirmation',
                  ),
                  dash('Members are responsible for accurate payment information'),
                  dash(
                    'PBAK may deny event access if payment is not confirmed',
                  ),
                  line(''),

                  sh('2.7 Membership Termination & Refunds'),
                  dash('Event fees are non-refundable unless explicitly stated'),
                  dash(
                    'Refund requests must follow PBAK policy and may be partial depending on circumstances',
                  ),
                  dash('Membership may be terminated for violations of Terms'),
                  line(''),

                  sh('2.8 Amendments'),
                  p(
                    'PBAK may amend Terms at any time; continued use constitutes acceptance.',
                  ),

                  sh('3. EVENT LIABILITY WAIVER & ASSUMPTION OF RISK'),
                  bullet('Motorcycle riding carries inherent risks'),
                  bullet('Participants assume all risks voluntarily'),
                  bullet(
                    'Release and indemnify PBAK, officials, partners, and volunteers from liability',
                  ),
                  bullet(
                    'Members responsible for motorcycle roadworthiness, insurance, and compliance',
                  ),
                  line(''),

                  sh('4. MEDICAL EMERGENCY & EMERGENCY CONTACT CONSENT'),
                  line('You authorize PBAK and its officials or emergency partners to:'),
                  dash('Provide emergency or first-aid treatment'),
                  dash(
                    'Access provided medical information strictly for emergency response',
                  ),
                  dash(
                    'Contact either or both emergency contacts in the event of an accident, injury, or serious incident',
                  ),
                  dash(
                    'Share necessary information to protect life, health, and safety',
                  ),
                  line(''),

                  sh('5. CODE OF CONDUCT'),
                  bullet('Obey traffic laws and safety regulations'),
                  bullet('Follow instructions from ride marshals and officials'),
                  bullet('Refrain from alcohol or substance use during events'),
                  bullet('Treat members, officials, and public with respect'),
                  bullet('Disciplinary measures: warnings, suspension, or termination'),
                  line(''),

                  sh('6. IMAGE, MEDIA & PROMOTIONAL CONSENT'),
                  bullet('Consent to photography and videography during PBAK events'),
                  bullet(
                    'Use of images/videos for communication, promotion, or archival purposes',
                  ),
                  bullet('Opt-out where reasonably practicable'),
                  line(''),

                  sh('7. THIRD-PARTY SERVICES'),
                  p(
                    'Services provided by trusted third-party partners (payment processors, hosting providers, communication platforms) under confidentiality and data protection obligations.',
                  ),

                  sh('8. FORCE MAJEURE'),
                  p(
                    'PBAK is not liable for failure or delay due to events beyond reasonable control, including weather, government directives, or emergencies.',
                  ),

                  sh('9. GOVERNING LAW'),
                  p(
                    'These Terms and Policies are governed by the laws of the Republic of Kenya.',
                  ),

                  sh('10. HELP & SUPPORT'),
                  line('Technical Support: tech@pbak.co.ke'),
                  p(
                    'Membership, KYC, Medical, Payment & Event Support: association@pbak.co.ke',
                  ),

                  sh('11. USER DECLARATION & CONSENT'),
                  p(
                    '“I confirm that all information provided, including my home address, profile photograph, medical and insurance details, two emergency contact details, and payment information, is true, accurate, and valid. I give explicit consent to the Private Bikers Association of Kenya (PBAK) to collect, verify, store, and process my personal, sensitive, and payment data for membership administration, KYC verification, safety, medical emergency response, contacting my emergency contacts when necessary, event participation, and payment processing in accordance with the Privacy Policy and Terms of Service.”',
                  ),
                ],
              ),
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Agree'),
          ),
        ],
      );
    },
  );

  return agreed == true;
}





Future<void> showPrivacyPolicyDialog(BuildContext context) async {
  final theme = Theme.of(context);

  TextSpan h(String text) => TextSpan(
        text: '$text\n',
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          height: 1.25,
        ),
      );

  TextSpan sh(String text) => TextSpan(
        text: '$text\n',
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w800,
          height: 1.35,
        ),
      );

  TextSpan p(String text) => TextSpan(
        text: '$text\n\n',
        style: theme.textTheme.bodyMedium?.copyWith(
          height: 1.45,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );

  TextSpan line(String text) => TextSpan(
        text: '$text\n',
        style: theme.textTheme.bodyMedium?.copyWith(
          height: 1.45,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );

  TextSpan bullet(String text) => line('• $text');
  TextSpan dash(String text) => line('- $text');

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.privacy_tip_rounded,
                color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            const Expanded(child: Text('Privacy Policy')),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 480),
          child: SingleChildScrollView(
            child: SelectableText.rich(
              TextSpan(
                children: [
                  h('PRIVATE BIKERS’ ASSOCIATION OF KENYA (PBAK)'),
                  p('Effective Date: January 2026'),

                  sh('1. PRIVACY POLICY'),
                  p(
                    'PBAK is committed to protecting the privacy, confidentiality, and security of members’ personal, sensitive, and financial data. This policy explains how information is collected, used, stored, and protected when using the PBAK platform.',
                  ),

                  sh('1.1 Legal Compliance'),
                  dash('Kenya Data Protection Act, 2019'),
                  dash('ODPC regulations and guidelines'),
                  line(''),

                  sh('1.2 Information Collected'),
                  bullet('Personal identification and contact details'),
                  bullet('Profile photograph for verification'),
                  bullet('Driving licence and motorcycle details'),
                  bullet('Medical and emergency contact information'),
                  bullet('Payment and transaction records'),
                  line(''),

                  sh('1.3 Purpose of Processing'),
                  bullet('Membership and identity verification'),
                  bullet('Event participation and rider safety'),
                  bullet('Emergency response'),
                  bullet('Payment processing and compliance'),
                  line(''),

                  sh('1.4 Data Security'),
                  bullet('Secure storage with restricted access'),
                  bullet('No sale or rental of personal data'),
                  bullet('Sharing only when legally required or consented'),
                  line(''),

                  sh('1.5 User Rights'),
                  bullet('Access and correct personal data'),
                  bullet('Request deletion where legally allowed'),
                  bullet('Withdraw consent where applicable'),
                  p('Contact: tech@pbak.co.ke | association@pbak.co.ke'),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}








Future<void> showHelpAndSupportDialog(BuildContext context) async {
  final theme = Theme.of(context);

  TextSpan h(String text) => TextSpan(
        text: '$text\n',
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          height: 1.25,
        ),
      );

  TextSpan p(String text) => TextSpan(
        text: '$text\n\n',
        style: theme.textTheme.bodyMedium?.copyWith(
          height: 1.45,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );

  TextSpan line(String text) => TextSpan(
        text: '$text\n',
        style: theme.textTheme.bodyMedium?.copyWith(
          height: 1.45,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.support_agent_rounded,
              color: theme.colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'HELP & SUPPORT',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        content: SelectableText.rich(
          TextSpan(
            children: [
              h('PRIVATE BIKERS’ ASSOCIATION OF KENYA (PBAK)'),
              p(
                'Our support teams are available to assist with technical issues, membership matters, verification, payments, medical records, and event-related inquiries.',
              ),
              line('Technical Support'),
              p('Email: tech@pbak.co.ke'),
              line('Membership, KYC, Medical, Payment & Event Support'),
              p('Email: association@pbak.co.ke'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}


