import 'package:flutter/material.dart';
import 'package:pbak/widgets/premium_ui.dart';

import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/utils/validators.dart';

class PersonalInfoStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final DateTime? dateOfBirth;
  final ValueChanged<DateTime?> onDateOfBirthChanged;

  final String? selectedGender;
  final ValueChanged<String?> onGenderChanged;

  final int? selectedOccupationId;
  final List<Map<String, dynamic>> occupations;
  final ValueChanged<int?> onOccupationChanged;

  final int? ridingExperience;
  final ValueChanged<int?> onRidingExperienceChanged;

  final String? ridingType;
  final ValueChanged<String?> onRidingTypeChanged;

  final Widget Function({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    required IconData icon,
    bool obscureText,
    Widget? suffixIcon,
    TextCapitalization textCapitalization,
  })
  buildTextField;

  final Widget Function<T>({
    required String label,
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?)? onChanged,
    required IconData icon,
    bool enabled,
  })
  buildDropdown;

  const PersonalInfoStep({
    super.key,
    required this.formKey,
    required this.firstNameController,
    required this.lastNameController,
    required this.dateOfBirth,
    required this.onDateOfBirthChanged,
    required this.selectedGender,
    required this.onGenderChanged,
    required this.selectedOccupationId,
    required this.occupations,
    required this.onOccupationChanged,
    required this.ridingExperience,
    required this.onRidingExperienceChanged,
    required this.ridingType,
    required this.onRidingTypeChanged,
    required this.buildTextField,
    required this.buildDropdown,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tell us about yourself',
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.35,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            PremiumCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildTextField(
                    label: 'First Name',
              hint: 'John',
              controller: firstNameController,
              validator: (val) =>
                  Validators.validateRequired(val, 'First name'),
              icon: Icons.person_outlined,
              keyboardType: TextInputType.name,
              obscureText: false,
              suffixIcon: null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 24),
            buildTextField(
              label: 'Last Name',
              hint: 'Doe',
              controller: lastNameController,
              validator: (val) => Validators.validateRequired(val, 'Last name'),
              icon: Icons.person_outlined,
              keyboardType: TextInputType.name,
              obscureText: false,
              suffixIcon: null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 24),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime(1990),
                  firstDate: DateTime(1950),
                  lastDate: DateTime.now().subtract(const Duration(days: 6570)),
                );
                if (picked != null) onDateOfBirthChanged(picked);
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date of Birth',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: theme.inputDecorationTheme.border,
                  enabledBorder: theme.inputDecorationTheme.enabledBorder,
                  focusedBorder: theme.inputDecorationTheme.focusedBorder,
                ),
                child: Text(
                  dateOfBirth != null
                      ? '${dateOfBirth!.day}/${dateOfBirth!.month}/${dateOfBirth!.year}'
                      : 'Select your date of birth',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: dateOfBirth != null
                        ? theme.colorScheme.onSurface
                        : AppTheme.mediumGrey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Gender',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedGender,
              decoration: InputDecoration(
                hintText: 'Select your gender',
                hintStyle: theme.inputDecorationTheme.hintStyle,
                prefixIcon: const Icon(Icons.wc_outlined),
                filled: true,
                fillColor: theme.inputDecorationTheme.fillColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: theme.inputDecorationTheme.border,
                enabledBorder: theme.inputDecorationTheme.enabledBorder,
                focusedBorder: theme.inputDecorationTheme.focusedBorder,
              ),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('Male')),
                DropdownMenuItem(value: 'female', child: Text('Female')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: onGenderChanged,
            ),
            const SizedBox(height: 24),
            buildDropdown<int>(
              label: 'Occupation',
              hint: 'Select your occupation',
              value: selectedOccupationId,
              items: occupations
                  .map(
                    (occupation) => DropdownMenuItem<int>(
                      value: occupation['id'] as int,
                      child: Text(occupation['name'] ?? 'Unknown'),
                    ),
                  )
                  .toList(),
              onChanged: onOccupationChanged,
              icon: Icons.work_outlined,
              enabled: true,
            ),
            const SizedBox(height: 24),
            buildDropdown<int>(
              label: 'Years of Riding Experience',
              hint: 'Select years',
              value: ridingExperience,
              items: List.generate(30, (index) => index + 1)
                  .map(
                    (years) => DropdownMenuItem<int>(
                      value: years,
                      child: Text('$years ${years == 1 ? 'year' : 'years'}'),
                    ),
                  )
                  .toList(),
              onChanged: onRidingExperienceChanged,
              icon: Icons.motorcycle_sharp,
              enabled: true,
            ),
            const SizedBox(height: 24),
                  buildDropdown<String>(
                    label: 'Type of Riding',
                    hint: 'Select riding type',
                    value: ridingType,
                    items: const [
                      DropdownMenuItem(
                        value: 'commuting',
                        child: Text('Commuting'),
                      ),
                      DropdownMenuItem(value: 'touring', child: Text('Touring')),
                      DropdownMenuItem(
                        value: 'sports',
                        child: Text('Sports/Racing'),
                      ),
                      DropdownMenuItem(
                        value: 'delivery',
                        child: Text('Delivery/Business'),
                      ),
                      DropdownMenuItem(
                        value: 'recreational',
                        child: Text('Recreational'),
                      ),
                      DropdownMenuItem(value: 'mixed', child: Text('Mixed Use')),
                    ],
                    onChanged: onRidingTypeChanged,
                    icon: Icons.sports_motorsports,
                    enabled: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
