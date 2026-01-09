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

  // Address
  final _roadName = TextEditingController();
  final _address1 = TextEditingController();
  final _address2 = TextEditingController();
  final _city = TextEditingController();
  final _stateProvince = TextEditingController();
  final _postalCode = TextEditingController();
  final _country = TextEditingController();

  // Work
  final _employer = TextEditingController();
  final _industry = TextEditingController();
  final _workLatLong = TextEditingController();
  final _workPlaceId = TextEditingController();

  // Medical
  final _bloodGroup = TextEditingController();
  final _allergies = TextEditingController();
  final _medicalPolicyNo = TextEditingController();

  DateTime? _dateOfBirth;
  String? _gender;

  // Interests
  bool _interestSafetyTraining = false;
  bool _interestAssociation = false;
  bool _interestBikerAdvocacy = false;
  bool _interestCertTrain = false;
  bool _interestSafetyWorkshops = false;
  bool _interestMemberWelfare = false;
  bool _interestLegalSupport = false;
  bool _interestMedical = false;

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
    _workLatLong.dispose();
    _workPlaceId.dispose();
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
    _workLatLong.text = user.workLatLong ?? '';
    _workPlaceId.text = user.workPlaceId ?? '';

    _bloodGroup.text = user.bloodGroup ?? '';
    _allergies.text = user.allergies ?? '';
    _medicalPolicyNo.text = user.medicalPolicyNo ?? '';

    _interestSafetyTraining = user.interestSafetyTraining == true;
    _interestAssociation = user.interestAssociation == true;
    _interestBikerAdvocacy = user.interestBikerAdvocacy == true;
    _interestCertTrain = user.interestCertTrain == true;
    _interestSafetyWorkshops = user.interestSafetyWorkshops == true;
    _interestMemberWelfare = user.interestMemberWelfare == true;
    _interestLegalSupport = user.interestLegalSupport == true;
    _interestMedical = user.interestMedical == true;

    _initialized = true;
  }

  Map<String, dynamic> _buildParamsPayload() {
    String? norm(String v) {
      final t = v.trim();
      return t.isEmpty ? null : t;
    }

    bool changedString(String? initial, String? current) {
      final a = (initial ?? '').trim();
      final b = (current ?? '').trim();
      return a != b;
    }

    bool changedDate(DateTime? a, DateTime? b) {
      if (a == null && b == null) return false;
      if (a == null || b == null) return true;
      return a.year != b.year || a.month != b.month || a.day != b.day;
    }

    final params = <String, dynamic>{};

    // Core identity/contact
    if (changedString(_initial.firstName, _firstName.text)) {
      params['first_name'] = norm(_firstName.text);
    }
    if (changedString(_initial.lastName, _lastName.text)) {
      params['last_name'] = norm(_lastName.text);
    }
    if (changedString(_initial.nickname, _nickName.text)) {
      params['nick_name'] = norm(_nickName.text);
    }
    if (changedString(_initial.phone, _phone.text)) {
      params['phone'] = norm(_phone.text);
    }
    if (changedString(_initial.alternativePhone, _altPhone.text)) {
      params['alternative_phone'] = norm(_altPhone.text);
    }

    if (changedString(_initial.nationalId, _nationalId.text)) {
      params['national_id'] = norm(_nationalId.text);
    }
    if (changedString(_initial.drivingLicenseNumber, _dlNumber.text)) {
      params['driving_license_number'] = norm(_dlNumber.text);
    }

    if (changedDate(_initial.dateOfBirth, _dateOfBirth)) {
      params['date_of_birth'] = _dateOfBirth == null
          ? null
          : DateFormat('yyyy-MM-dd').format(_dateOfBirth!);
    }
    if ((_initial.gender ?? '').trim() != (_gender ?? '').trim()) {
      params['gender'] = (_gender ?? '').trim().isEmpty ? null : _gender;
    }

    if (changedString(_initial.emergencyContact, _emergencyContact.text)) {
      params['emergency_contact'] = norm(_emergencyContact.text);
    }

    // Address
    if (changedString(_initial.roadName, _roadName.text)) {
      params['road_name'] = norm(_roadName.text);
    }
    if (changedString(_initial.addressLine1, _address1.text)) {
      params['address_line1'] = norm(_address1.text);
    }
    if (changedString(_initial.addressLine2, _address2.text)) {
      params['address_line2'] = norm(_address2.text);
    }
    if (changedString(_initial.city, _city.text)) {
      params['city'] = norm(_city.text);
    }
    if (changedString(_initial.stateProvince, _stateProvince.text)) {
      params['state_province'] = norm(_stateProvince.text);
    }
    if (changedString(_initial.postalCode, _postalCode.text)) {
      params['postal_code'] = norm(_postalCode.text);
    }
    if (changedString(_initial.country, _country.text)) {
      params['country'] = norm(_country.text);
    }

    // Work
    if (changedString(_initial.employer, _employer.text)) {
      params['employer'] = norm(_employer.text);
    }
    if (changedString(_initial.industry, _industry.text)) {
      params['industry'] = norm(_industry.text);
    }
    if (changedString(_initial.workLatLong, _workLatLong.text)) {
      params['work_lat_long'] = norm(_workLatLong.text);
    }
    if (changedString(_initial.workPlaceId, _workPlaceId.text)) {
      params['work_place_id'] = norm(_workPlaceId.text);
    }

    // Medical
    if (changedString(_initial.bloodGroup, _bloodGroup.text)) {
      final v = norm(_bloodGroup.text);
      // Some APIs use blood_type, others blood_group. Send both for compatibility.
      params['blood_group'] = v;
      params['blood_type'] = v;
    }
    if (changedString(_initial.allergies, _allergies.text)) {
      params['allergies'] = norm(_allergies.text);
    }
    if (changedString(_initial.medicalPolicyNo, _medicalPolicyNo.text)) {
      params['medical_policy_no'] = norm(_medicalPolicyNo.text);
    }

    // Interests (booleans as 1/0)
    void setInterest(String key, bool initial, bool current) {
      if (initial != current) params[key] = current ? 1 : 0;
    }

    setInterest('interest_safety_training', _initial.interestSafetyTraining == true, _interestSafetyTraining);
    setInterest('interest_association', _initial.interestAssociation == true, _interestAssociation);
    setInterest('interest_biker_advocacy', _initial.interestBikerAdvocacy == true, _interestBikerAdvocacy);
    setInterest('interest_cert_train', _initial.interestCertTrain == true, _interestCertTrain);
    setInterest('interest_safety_workshops', _initial.interestSafetyWorkshops == true, _interestSafetyWorkshops);
    setInterest('interest_member_welfare', _initial.interestMemberWelfare == true, _interestMemberWelfare);
    setInterest('interest_legal_support', _initial.interestLegalSupport == true, _interestLegalSupport);
    setInterest('interest_medical', _initial.interestMedical == true, _interestMedical);

    return params;
  }

  Future<void> _save(UserModel currentUser) async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    final params = _buildParamsPayload();
    if (params.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No changes to save'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final ok = await ref.read(memberServiceProvider).updateMemberParams(
        memberId: currentUser.memberId,
        params: params,
      );
      if (!ok) throw Exception('Update failed');

      // Refresh from backend
      ref.invalidate(memberByIdProvider(currentUser.memberId));

      // Update local auth cache (best-effort)
      final updatedLocal = currentUser.copyWith(
        firstName: params['first_name'] ?? currentUser.firstName,
        lastName: params['last_name'] ?? currentUser.lastName,
        nickname: params['nick_name'] ?? currentUser.nickname,
        phone: params['phone'] ?? currentUser.phone,
        alternativePhone: params['alternative_phone'] ?? currentUser.alternativePhone,
        nationalId: params['national_id'] ?? currentUser.nationalId,
        drivingLicenseNumber: params['driving_license_number'] ?? currentUser.drivingLicenseNumber,
        gender: params['gender'] ?? currentUser.gender,
        emergencyContact: params['emergency_contact'] ?? currentUser.emergencyContact,
        roadName: params['road_name'] ?? currentUser.roadName,
        addressLine1: params['address_line1'] ?? currentUser.addressLine1,
        addressLine2: params['address_line2'] ?? currentUser.addressLine2,
        city: params['city'] ?? currentUser.city,
        stateProvince: params['state_province'] ?? currentUser.stateProvince,
        postalCode: params['postal_code'] ?? currentUser.postalCode,
        country: params['country'] ?? currentUser.country,
        employer: params['employer'] ?? currentUser.employer,
        industry: params['industry'] ?? currentUser.industry,
        workLatLong: params['work_lat_long'] ?? currentUser.workLatLong,
        workPlaceId: params['work_place_id'] ?? currentUser.workPlaceId,
        bloodGroup: params['blood_group'] ?? params['blood_type'] ?? currentUser.bloodGroup,
        allergies: params['allergies'] ?? currentUser.allergies,
        medicalPolicyNo: params['medical_policy_no'] ?? currentUser.medicalPolicyNo,
        interestSafetyTraining: params.containsKey('interest_safety_training')
            ? (params['interest_safety_training'] == 1)
            : currentUser.interestSafetyTraining,
        interestAssociation: params.containsKey('interest_association')
            ? (params['interest_association'] == 1)
            : currentUser.interestAssociation,
        interestBikerAdvocacy: params.containsKey('interest_biker_advocacy')
            ? (params['interest_biker_advocacy'] == 1)
            : currentUser.interestBikerAdvocacy,
        interestCertTrain: params.containsKey('interest_cert_train')
            ? (params['interest_cert_train'] == 1)
            : currentUser.interestCertTrain,
        interestSafetyWorkshops: params.containsKey('interest_safety_workshops')
            ? (params['interest_safety_workshops'] == 1)
            : currentUser.interestSafetyWorkshops,
        interestMemberWelfare: params.containsKey('interest_member_welfare')
            ? (params['interest_member_welfare'] == 1)
            : currentUser.interestMemberWelfare,
        interestLegalSupport: params.containsKey('interest_legal_support')
            ? (params['interest_legal_support'] == 1)
            : currentUser.interestLegalSupport,
        interestMedical: params.containsKey('interest_medical')
            ? (params['interest_medical'] == 1)
            : currentUser.interestMedical,
        dateOfBirth: params.containsKey('date_of_birth')
            ? (params['date_of_birth'] == null
                ? null
                : DateTime.tryParse(params['date_of_birth'].toString()))
            : currentUser.dateOfBirth,
      );
      await ref.read(authProvider.notifier).updateProfile(updatedLocal);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated'),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: AppTheme.brightRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _sectionTitle(BuildContext context, String title, {String? subtitle}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final authUser = ref.watch(authProvider).value;
    if (authUser == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    final profileAsync = ref.watch(memberByIdProvider(authUser.memberId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => context.pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _saving
                      ? null
                      : () {
                          final authUserNow = ref.read(authProvider).value;
                          if (authUserNow == null) return;
                          final current = ref.read(memberByIdProvider(authUserNow.memberId)).valueOrNull;
                          _save(current ?? authUserNow);
                        },
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(_saving ? 'Saving…' : 'Save changes'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load profile: $e')),
        data: (profile) {
          final user = profile ?? authUser;
          if (!_initialized) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() => _initFromUser(user));
            });
          }

          return SafeArea(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Update your profile details.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),

                    _sectionTitle(context, 'Basic info'),
                    TextFormField(
                      controller: _firstName,
                      decoration: const InputDecoration(
                        labelText: 'First name',
                        prefixIcon: Icon(Icons.person_rounded),
                      ),
                      validator: (v) => Validators.validateRequired(v, 'First name'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _lastName,
                      decoration: const InputDecoration(
                        labelText: 'Last name',
                        prefixIcon: Icon(Icons.person_rounded),
                      ),
                      validator: (v) => Validators.validateRequired(v, 'Last name'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nickName,
                      decoration: const InputDecoration(
                        labelText: 'Nickname',
                        hintText: 'e.g. Mesh',
                        prefixIcon: Icon(Icons.alternate_email_rounded),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        if (v.trim().length < 2) return 'Nickname is too short';
                        if (v.trim().length > 30) return 'Nickname is too long';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _saving
                                ? null
                                : () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _dateOfBirth ?? DateTime(2000, 1, 1),
                                      firstDate: DateTime(1900, 1, 1),
                                      lastDate: DateTime.now(),
                                    );
                                    if (picked != null) {
                                      setState(() => _dateOfBirth = picked);
                                    }
                                  },
                            borderRadius: BorderRadius.circular(AppTheme.radiusM),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Date of birth',
                                prefixIcon: Icon(Icons.cake_rounded),
                              ),
                              child: Text(
                                _dateOfBirth == null
                                    ? 'Select date'
                                    : DateFormat('yyyy-MM-dd').format(_dateOfBirth!),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: (_gender ?? '').isEmpty ? null : _gender,
                            decoration: const InputDecoration(
                              labelText: 'Gender',
                              prefixIcon: Icon(Icons.wc_rounded),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'male', child: Text('Male')),
                              DropdownMenuItem(value: 'female', child: Text('Female')),
                              DropdownMenuItem(value: 'other', child: Text('Other')),
                            ],
                            onChanged: (v) => setState(() => _gender = v),
                          ),
                        ),
                      ],
                    ),

                    _sectionTitle(context, 'Contact'),
                    TextFormField(
                      controller: _phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        prefixIcon: Icon(Icons.phone_rounded),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) => Validators.validatePhone(v),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _altPhone,
                      decoration: const InputDecoration(
                        labelText: 'Alternative phone',
                        prefixIcon: Icon(Icons.phone_android_rounded),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emergencyContact,
                      decoration: const InputDecoration(
                        labelText: 'Emergency contact',
                        prefixIcon: Icon(Icons.crisis_alert_rounded),
                      ),
                    ),

                    _sectionTitle(context, 'Identity'),
                    TextFormField(
                      controller: _nationalId,
                      decoration: const InputDecoration(
                        labelText: 'National ID',
                        prefixIcon: Icon(Icons.credit_card_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _dlNumber,
                      decoration: const InputDecoration(
                        labelText: 'Driving license number',
                        prefixIcon: Icon(Icons.card_membership_rounded),
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),

                    _sectionTitle(context, 'Address'),
                    TextFormField(
                      controller: _roadName,
                      decoration: const InputDecoration(
                        labelText: 'Road name',
                        prefixIcon: Icon(Icons.route_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _address1,
                      decoration: const InputDecoration(
                        labelText: 'Address line 1',
                        prefixIcon: Icon(Icons.home_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _address2,
                      decoration: const InputDecoration(
                        labelText: 'Address line 2',
                        prefixIcon: Icon(Icons.home_work_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _city,
                            decoration: const InputDecoration(
                              labelText: 'City',
                              prefixIcon: Icon(Icons.location_city_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _stateProvince,
                            decoration: const InputDecoration(
                              labelText: 'State/Province',
                              prefixIcon: Icon(Icons.map_rounded),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _postalCode,
                            decoration: const InputDecoration(
                              labelText: 'Postal code',
                              prefixIcon: Icon(Icons.markunread_mailbox_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _country,
                            decoration: const InputDecoration(
                              labelText: 'Country',
                              prefixIcon: Icon(Icons.flag_rounded),
                            ),
                          ),
                        ),
                      ],
                    ),

                    _sectionTitle(context, 'Work'),
                    TextFormField(
                      controller: _employer,
                      decoration: const InputDecoration(
                        labelText: 'Employer',
                        prefixIcon: Icon(Icons.apartment_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _industry,
                      decoration: const InputDecoration(
                        labelText: 'Industry',
                        prefixIcon: Icon(Icons.business_center_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _workLatLong,
                      decoration: const InputDecoration(
                        labelText: 'Work lat/long',
                        hintText: '-1.2921, 36.8219',
                        prefixIcon: Icon(Icons.my_location_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _workPlaceId,
                      decoration: const InputDecoration(
                        labelText: 'Work place id',
                        prefixIcon: Icon(Icons.pin_drop_rounded),
                      ),
                    ),

                    _sectionTitle(context, 'Medical'),
                    TextFormField(
                      controller: _bloodGroup,
                      decoration: const InputDecoration(
                        labelText: 'Blood group',
                        prefixIcon: Icon(Icons.bloodtype_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _allergies,
                      decoration: const InputDecoration(
                        labelText: 'Allergies',
                        prefixIcon: Icon(Icons.healing_rounded),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _medicalPolicyNo,
                      decoration: const InputDecoration(
                        labelText: 'Medical policy number',
                        prefixIcon: Icon(Icons.policy_rounded),
                      ),
                    ),

                    _sectionTitle(context, 'Interests'),
                    _InterestSwitch(
                      title: 'Safety training',
                      value: _interestSafetyTraining,
                      onChanged: (v) => setState(() => _interestSafetyTraining = v),
                    ),
                    _InterestSwitch(
                      title: 'Association',
                      value: _interestAssociation,
                      onChanged: (v) => setState(() => _interestAssociation = v),
                    ),
                    _InterestSwitch(
                      title: 'Biker advocacy',
                      value: _interestBikerAdvocacy,
                      onChanged: (v) => setState(() => _interestBikerAdvocacy = v),
                    ),
                    _InterestSwitch(
                      title: 'Certification training',
                      value: _interestCertTrain,
                      onChanged: (v) => setState(() => _interestCertTrain = v),
                    ),
                    _InterestSwitch(
                      title: 'Safety workshops',
                      value: _interestSafetyWorkshops,
                      onChanged: (v) => setState(() => _interestSafetyWorkshops = v),
                    ),
                    _InterestSwitch(
                      title: 'Member welfare',
                      value: _interestMemberWelfare,
                      onChanged: (v) => setState(() => _interestMemberWelfare = v),
                    ),
                    _InterestSwitch(
                      title: 'Legal support',
                      value: _interestLegalSupport,
                      onChanged: (v) => setState(() => _interestLegalSupport = v),
                    ),
                    _InterestSwitch(
                      title: 'Medical',
                      value: _interestMedical,
                      onChanged: (v) => setState(() => _interestMedical = v),
                    ),

                    const SizedBox(height: 22),
                    // Actions are in the sticky bottom bar
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InterestSwitch extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _InterestSwitch({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}
