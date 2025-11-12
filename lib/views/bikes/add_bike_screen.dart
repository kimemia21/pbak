import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/bike_provider.dart';
import 'package:pbak/utils/validators.dart';
import 'package:pbak/utils/constants.dart';
import 'package:pbak/widgets/custom_text_field.dart';
import 'package:pbak/widgets/custom_button.dart';

class AddBikeScreen extends ConsumerStatefulWidget {
  const AddBikeScreen({super.key});

  @override
  ConsumerState<AddBikeScreen> createState() => _AddBikeScreenState();
}

class _AddBikeScreenState extends ConsumerState<AddBikeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _registrationController = TextEditingController();
  final _engineController = TextEditingController();
  final _yearController = TextEditingController();
  final _colorController = TextEditingController();

  String _selectedType = AppConstants.motorcycleTypes.first;
  bool _isLoading = false;

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _registrationController.dispose();
    _engineController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final bikeData = {
        'make': _makeController.text.trim(),
        'model': _modelController.text.trim(),
        'type': _selectedType,
        'registrationNumber': _registrationController.text.trim().toUpperCase(),
        'engineNumber': _engineController.text.trim().toUpperCase(),
        'year': int.parse(_yearController.text.trim()),
        'color': _colorController.text.trim(),
      };

      final success = await ref.read(bikeNotifierProvider.notifier).addBike(bikeData);

      setState(() => _isLoading = false);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bike added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add bike. Please try again.'),
            backgroundColor: AppTheme.brightRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Bike'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.paddingM),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                label: 'Make',
                hint: 'e.g., Yamaha, Honda, Suzuki',
                controller: _makeController,
                validator: (val) => Validators.validateRequired(val, 'Make'),
                textCapitalization: TextCapitalization.words,
                prefixIcon: const Icon(Icons.business_rounded),
              ),
              const SizedBox(height: AppTheme.paddingM),

              CustomTextField(
                label: 'Model',
                hint: 'e.g., MT-07, CB500X',
                controller: _modelController,
                validator: (val) => Validators.validateRequired(val, 'Model'),
                textCapitalization: TextCapitalization.characters,
                prefixIcon: const Icon(Icons.two_wheeler_rounded),
              ),
              const SizedBox(height: AppTheme.paddingM),

              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  prefixIcon: Icon(Icons.category_rounded),
                ),
                items: AppConstants.motorcycleTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
              ),
              const SizedBox(height: AppTheme.paddingM),

              CustomTextField(
                label: 'Registration Number',
                hint: 'e.g., KBZ 456Y',
                controller: _registrationController,
                validator: Validators.validateRegistrationNumber,
                textCapitalization: TextCapitalization.characters,
                prefixIcon: const Icon(Icons.confirmation_number_rounded),
              ),
              const SizedBox(height: AppTheme.paddingM),

              CustomTextField(
                label: 'Engine Number',
                hint: 'Enter engine number',
                controller: _engineController,
                validator: Validators.validateEngineNumber,
                textCapitalization: TextCapitalization.characters,
                prefixIcon: const Icon(Icons.settings_rounded),
              ),
              const SizedBox(height: AppTheme.paddingM),

              CustomTextField(
                label: 'Year',
                hint: 'e.g., 2022',
                controller: _yearController,
                keyboardType: TextInputType.number,
                validator: Validators.validateYear,
                prefixIcon: const Icon(Icons.calendar_today_rounded),
              ),
              const SizedBox(height: AppTheme.paddingM),

              CustomTextField(
                label: 'Color (Optional)',
                hint: 'e.g., Blue, Red',
                controller: _colorController,
                textCapitalization: TextCapitalization.words,
                prefixIcon: const Icon(Icons.palette_rounded),
              ),
              const SizedBox(height: AppTheme.paddingXL),

              CustomButton(
                text: 'Add Bike',
                onPressed: _handleSubmit,
                isLoading: _isLoading,
                icon: Icons.add_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
