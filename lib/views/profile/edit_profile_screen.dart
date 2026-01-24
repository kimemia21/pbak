import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pbak/models/user_model.dart';
import 'package:pbak/providers/auth_provider.dart';
import 'package:pbak/providers/member_provider.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/utils/validators.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _initialized = false;

  // Controllers
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _nickName = TextEditingController();
  final _phone = TextEditingController();
  final _altPhone = TextEditingController();
  final _nationalId = TextEditingController();
  final _dlNumber = TextEditingController();
  final _emergencyContact = TextEditingController();
  final _roadName = TextEditingController();
  final _address1 = TextEditingController();
  final _address2 = TextEditingController();
  final _city = TextEditingController();
  final _stateProvince = TextEditingController();
  final _postalCode = TextEditingController();
  final _country = TextEditingController();
  final _employer = TextEditingController();
  final _industry = TextEditingController();
  final _bloodGroup = TextEditingController();
  final _allergies = TextEditingController();
  final _medicalPolicyNo = TextEditingController();

  DateTime? _dateOfBirth;
  String? _gender;
  late UserModel _initial;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _nickName.dispose();
    _phone.dispose();
    _altPhone.dispose();
    _nationalId.dispose();
    _dlNumber.dispose();
    _emergencyContact.dispose();
    _roadName.dispose();
    _address1.dispose();
    _address2.dispose();
    _city.dispose();
    _stateProvince.dispose();
    _postalCode.dispose();
    _country.dispose();
    _employer.dispose();
    _industry.dispose();
    _bloodGroup.dispose();
    _allergies.dispose();
    _medicalPolicyNo.dispose();
    super.dispose();
  }

  void _initFromUser(UserModel user) {
    _initial = user;
    _firstName.text = user.firstName;
    _lastName.text = user.lastName;
    _nickName.text = user.nickname ?? '';
    _phone.text = user.phone ?? '';
    _altPhone.text = user.alternativePhone ?? '';
    _nationalId.text = user.nationalId ?? '';
    _dlNumber.text = user.drivingLicenseNumber ?? '';
    _dateOfBirth = user.dateOfBirth;
    _gender = user.gender;
    _emergencyContact.text = user.emergencyContact ?? '';
    _roadName.text = user.roadName ?? '';
    _address1.text = user.addressLine1 ?? '';
    _address2.text = user.addressLine2 ?? '';
    _city.text = user.city ?? '';
    _stateProvince.text = user.stateProvince ?? '';
    _postalCode.text = user.postalCode ?? '';
    _country.text = user.country ?? '';
    _employer.text = user.employer ?? '';
    _industry.text = user.industry ?? '';
    _bloodGroup.text = user.bloodGroup ?? '';
    _allergies.text = user.allergies ?? '';
    _medicalPolicyNo.text = user.medicalPolicyNo ?? '';
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authUser = ref.watch(authProvider).value;

    if (authUser == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    final profileAsync = ref.watch(memberByIdProvider(authUser.memberId));

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF8F9FA),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (profile) {
          final user = profile ?? authUser;
          if (!_initialized) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _initFromUser(user));
            });
          }
          return _buildContent(context, theme, isDark, user);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme, bool isDark, UserModel user) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildAppBar(context, theme, isDark, user),
        SliverToBoxAdapter(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(context, 'Personal Information', Icons.person_rounded, isDark, [
                    _buildTextField(_firstName, 'First Name', Icons.person_outline_rounded, validator: (v) => Validators.validateRequired(v, 'First name')),
                    _buildTextField(_lastName, 'Last Name', Icons.person_outline_rounded, validator: (v) => Validators.validateRequired(v, 'Last name')),
                    _buildTextField(_nickName, 'Nickname', Icons.alternate_email_rounded),
                    _buildDateField(context, theme, isDark),
                    _buildGenderField(theme, isDark),
                  ]),
                  const SizedBox(height: 20),
                  _buildSection(context, 'Contact', Icons.contact_phone_rounded, isDark, [
                    _buildTextField(_phone, 'Phone Number', Icons.phone_rounded, keyboardType: TextInputType.phone),
                    _buildTextField(_altPhone, 'Alternative Phone', Icons.phone_android_rounded, keyboardType: TextInputType.phone),
                    _buildTextField(_emergencyContact, 'Emergency Contact', Icons.emergency_rounded, keyboardType: TextInputType.phone, isImportant: true),
                  ]),
                  const SizedBox(height: 20),
                  _buildSection(context, 'Identity Documents', Icons.badge_rounded, isDark, [
                    _buildTextField(_nationalId, 'National ID', Icons.credit_card_rounded),
                    _buildTextField(_dlNumber, 'Driving License No.', Icons.drive_eta_rounded),
                  ]),
                  const SizedBox(height: 20),
                  _buildSection(context, 'Address', Icons.location_on_rounded, isDark, [
                    _buildTextField(_roadName, 'Road Name', Icons.route_rounded),
                    _buildTextField(_address1, 'Address Line 1', Icons.home_rounded),
                    _buildTextField(_address2, 'Address Line 2', Icons.home_work_rounded),
                    _buildTextField(_city, 'City', Icons.location_city_rounded),
                    _buildTextField(_stateProvince, 'State/Province', Icons.map_rounded),
                    _buildTextField(_postalCode, 'Postal Code', Icons.markunread_mailbox_rounded),
                    _buildTextField(_country, 'Country', Icons.flag_rounded),
                  ]),
                  const SizedBox(height: 20),
                  _buildSection(context, 'Medical Information', Icons.medical_information_rounded, isDark, [
                    _buildBloodGroupField(theme, isDark),
                    _buildTextField(_allergies, 'Allergies', Icons.warning_rounded),
                    _buildTextField(_medicalPolicyNo, 'Medical Policy No.', Icons.medical_services_rounded),
                  ]),
                  const SizedBox(height: 20),
                  _buildSection(context, 'Work', Icons.work_rounded, isDark, [
                    _buildTextField(_employer, 'Employer', Icons.apartment_rounded),
                    _buildTextField(_industry, 'Industry', Icons.business_center_rounded),
                  ]),
                  const SizedBox(height: 32),
                  _buildActionButtons(context, user),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context, ThemeData theme, bool isDark, UserModel user) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : theme.colorScheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF2D2D2D), const Color(0xFF1A1A1A)]
                  : [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.85)],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        backgroundImage: user.profilePhotoUrl != null ? NetworkImage(user.profilePhotoUrl!) : null,
                        child: user.profilePhotoUrl == null
                            ? Text(user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                                style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold))
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppTheme.goldAccent, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Edit Profile', style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('Update your information', style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.7))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, IconData icon, bool isDark, List<Widget> children) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.06), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, size: 20, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.1)),
          Padding(padding: const EdgeInsets.all(16), child: Column(children: children)),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      {TextInputType? keyboardType, String? Function(String?)? validator, bool isImportant = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: isImportant ? AppTheme.deepRed : null),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
        ),
      ),
    );
  }

  Widget _buildDateField(BuildContext context, ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _dateOfBirth ?? DateTime(1990),
            firstDate: DateTime(1920),
            lastDate: DateTime.now(),
          );
          if (picked != null) setState(() => _dateOfBirth = picked);
        },
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Date of Birth',
            prefixIcon: const Icon(Icons.cake_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
          ),
          child: Text(_dateOfBirth != null ? DateFormat('MMM d, yyyy').format(_dateOfBirth!) : 'Select date'),
        ),
      ),
    );
  }

  Widget _buildGenderField(ThemeData theme, bool isDark) {
    final genders = ['Male', 'Female', 'Other'];
    // Normalize gender value to match dropdown items (case-insensitive)
    String? normalizedGender;
    if (_gender != null && _gender!.isNotEmpty) {
      final lowerGender = _gender!.toLowerCase();
      for (final g in genders) {
        if (g.toLowerCase() == lowerGender) {
          normalizedGender = g;
          break;
        }
      }
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: normalizedGender,
        decoration: InputDecoration(
          labelText: 'Gender',
          prefixIcon: const Icon(Icons.person_rounded),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
        ),
        items: genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
        onChanged: (v) => setState(() => _gender = v),
      ),
    );
  }

  Widget _buildBloodGroupField(ThemeData theme, bool isDark) {
    final groups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
    // Normalize blood group to match dropdown items (case-insensitive)
    String? normalizedBloodGroup;
    if (_bloodGroup.text.isNotEmpty) {
      final lowerBlood = _bloodGroup.text.toUpperCase();
      for (final g in groups) {
        if (g.toUpperCase() == lowerBlood) {
          normalizedBloodGroup = g;
          break;
        }
      }
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: normalizedBloodGroup,
        decoration: InputDecoration(
          labelText: 'Blood Group',
          prefixIcon: const Icon(Icons.bloodtype_rounded, color: AppTheme.deepRed),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
        ),
        items: groups.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
        onChanged: (v) => setState(() => _bloodGroup.text = v ?? ''),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, UserModel user) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _saving ? null : () => context.pop(),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: _saving ? null : () => _save(user),
            icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_rounded),
            label: Text(_saving ? 'Saving...' : 'Save Changes'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          ),
        ),
      ],
    );
  }

  Future<void> _save(UserModel currentUser) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final params = _buildParams();
    if (params.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('No changes to save'), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
      return;
    }
    setState(() => _saving = true);
    try {
      final ok = await ref.read(memberServiceProvider).updateMemberParams(memberId: currentUser.memberId, params: params);
      if (!ok) throw Exception('Update failed');
      ref.invalidate(memberByIdProvider(currentUser.memberId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Profile updated'), backgroundColor: AppTheme.successGreen, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppTheme.deepRed, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Map<String, dynamic> _buildParams() {
    String? norm(String v) => v.trim().isEmpty ? null : v.trim();
    bool changed(String? a, String? b) => (a ?? '').trim() != (b ?? '').trim();
    final p = <String, dynamic>{};
    if (changed(_initial.firstName, _firstName.text)) p['first_name'] = norm(_firstName.text);
    if (changed(_initial.lastName, _lastName.text)) p['last_name'] = norm(_lastName.text);
    if (changed(_initial.nickname, _nickName.text)) p['nick_name'] = norm(_nickName.text);
    if (changed(_initial.phone, _phone.text)) p['phone'] = norm(_phone.text);
    if (changed(_initial.alternativePhone, _altPhone.text)) p['alternative_phone'] = norm(_altPhone.text);
    if (changed(_initial.nationalId, _nationalId.text)) p['national_id'] = norm(_nationalId.text);
    if (changed(_initial.drivingLicenseNumber, _dlNumber.text)) p['driving_license_number'] = norm(_dlNumber.text);
    if (changed(_initial.emergencyContact, _emergencyContact.text)) p['emergency_contact'] = norm(_emergencyContact.text);
    if (changed(_initial.roadName, _roadName.text)) p['road_name'] = norm(_roadName.text);
    if (changed(_initial.addressLine1, _address1.text)) p['address_line1'] = norm(_address1.text);
    if (changed(_initial.addressLine2, _address2.text)) p['address_line2'] = norm(_address2.text);
    if (changed(_initial.city, _city.text)) p['city'] = norm(_city.text);
    if (changed(_initial.stateProvince, _stateProvince.text)) p['state_province'] = norm(_stateProvince.text);
    if (changed(_initial.postalCode, _postalCode.text)) p['postal_code'] = norm(_postalCode.text);
    if (changed(_initial.country, _country.text)) p['country'] = norm(_country.text);
    if (changed(_initial.employer, _employer.text)) p['employer'] = norm(_employer.text);
    if (changed(_initial.industry, _industry.text)) p['industry'] = norm(_industry.text);
    if (changed(_initial.bloodGroup, _bloodGroup.text)) { p['blood_group'] = norm(_bloodGroup.text); p['blood_type'] = norm(_bloodGroup.text); }
    if (changed(_initial.allergies, _allergies.text)) p['allergies'] = norm(_allergies.text);
    if (changed(_initial.medicalPolicyNo, _medicalPolicyNo.text)) p['medical_policy_no'] = norm(_medicalPolicyNo.text);
    if ((_initial.gender ?? '') != (_gender ?? '')) p['gender'] = _gender;
    if (_initial.dateOfBirth != _dateOfBirth) p['date_of_birth'] = _dateOfBirth != null ? DateFormat('yyyy-MM-dd').format(_dateOfBirth!) : null;
    return p;
  }
}
