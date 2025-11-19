import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/bike_provider.dart';
import 'package:pbak/utils/validators.dart';
import 'package:pbak/utils/constants.dart';
import 'package:pbak/widgets/custom_text_field.dart';
import 'package:pbak/widgets/custom_button.dart';
import 'package:pbak/widgets/loading_widget.dart';

class EditBikeScreen extends ConsumerStatefulWidget {
  final String bikeId;

  const EditBikeScreen({
    super.key,
    required this.bikeId,
  });

  @override
  ConsumerState<EditBikeScreen> createState() => _EditBikeScreenState();
}

class _EditBikeScreenState extends ConsumerState<EditBikeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _registrationController = TextEditingController();
  final _engineController = TextEditingController();
  final _yearController = TextEditingController();
  final _colorController = TextEditingController();

  String _selectedType = AppConstants.motorcycleTypes.first;
  bool _isLoading = false;
  bool _dataLoaded = false;

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

  void _loadBikeData(bike) {
    if (_dataLoaded) return;
    
    _makeController.text = bike.make;
    _modelController.text = bike.model;
    _registrationController.text = bike.registrationNumber;
    _engineController.text = bike.engineNumber;
    _yearController.text = bike.year.toString();
    _colorController.text = bike.color ?? '';
    _selectedType = bike.type;
    _dataLoaded = true;
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

      final success = await ref.read(bikeNotifierProvider.notifier).updateBike(
            int.parse(widget.bikeId),
            bikeData,
          );

      setState(() => _isLoading = false);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bike updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update bike. Please try again.'),
            backgroundColor: AppTheme.brightRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bikeAsync = ref.watch(bikeByIdProvider(int.parse(widget.bikeId)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Bike'),
      ),
      body: bikeAsync.when(
        data: (bike) {
          if (bike == null) {
            return const Center(child: Text('Bike not found'));
          }

          _loadBikeData(bike);

          return SingleChildScrollView(
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
                    label: 'Color',
                    hint: 'e.g., Blue, Red',
                    controller: _colorController,
                    textCapitalization: TextCapitalization.words,
                    prefixIcon: const Icon(Icons.palette_rounded),
                  ),
                  const SizedBox(height: AppTheme.paddingXL),

                  CustomButton(
                    text: 'Update Bike',
                    onPressed: _handleSubmit,
                    isLoading: _isLoading,
                    icon: Icons.save_rounded,
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const LoadingWidget(message: 'Loading bike details...'),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Failed to load bike details'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
