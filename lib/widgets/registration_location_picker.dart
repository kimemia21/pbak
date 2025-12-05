// import 'package:flutter/material.dart';
// import 'package:pbak/theme/app_theme.dart';
// import 'package:pbak/widgets/google_places_location_picker.dart';

// /// Enhanced location picker for registration with Google Places integration
// /// Handles both home location (region/town/estate) and workplace location (Google Places)
// class RegistrationLocationPicker extends StatefulWidget {
//   final String googleApiKey;
//   final List<Map<String, dynamic>> regions;
//   final List<Map<String, dynamic>> towns;
//   final List<Map<String, dynamic>> estates;
//   final int? selectedRegionId;
//   final int? selectedTownId;
//   final int? selectedEstateId;
//   final TextEditingController roadNameController;
//   final Function(int?) onRegionChanged;
//   final Function(int?) onTownChanged;
//   final Function(int?) onEstateChanged;
//   final Function(LocationData) onWorkplaceSelected;

//   const RegistrationLocationPicker({
//     super.key,
//     required this.googleApiKey,
//     required this.regions,
//     required this.towns,
//     required this.estates,
//     required this.selectedRegionId,
//     required this.selectedTownId,
//     required this.selectedEstateId,
//     required this.roadNameController,
//     required this.onRegionChanged,
//     required this.onTownChanged,
//     required this.onEstateChanged,
//     required this.onWorkplaceSelected,
//   });

//   @override
//   State<RegistrationLocationPicker> createState() => _RegistrationLocationPickerState();
// }

// class _RegistrationLocationPickerState extends State<RegistrationLocationPicker> {
//   LocationData? _workplaceLocation;
//   bool _hasWorkplace = false;

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
    
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Section 1: Home Location
//         _buildSectionHeader(
//           icon: Icons.home_outlined,
//           title: 'Home Location',
//           subtitle: 'Where do you live?',
//         ),
//         const SizedBox(height: 20),
        
//         // County/Region Dropdown
//         _buildDropdown<int>(
//           label: 'County/Region',
//           hint: 'Select your county',
//           value: widget.selectedRegionId,
//           items: widget.regions.map((region) {
//             return DropdownMenuItem<int>(
//               value: region['id'] as int,
//               child: Text(region['name'] ?? 'Unknown'),
//             );
//           }).toList(),
//           onChanged: (value) {
//             widget.onRegionChanged(value);
//           },
//           icon: Icons.location_city_outlined,
//         ),
//         const SizedBox(height: 20),

//         // Town Dropdown
//         _buildDropdown<int>(
//           label: 'Town/City',
//           hint: widget.selectedRegionId == null 
//               ? 'Select region first' 
//               : 'Select your town',
//           value: widget.selectedTownId,
//           items: widget.towns.map((town) {
//             return DropdownMenuItem<int>(
//               value: town['id'] as int,
//               child: Text(town['name'] ?? 'Unknown'),
//             );
//           }).toList(),
//           onChanged: widget.selectedRegionId != null ? widget.onTownChanged : null,
//           icon: Icons.apartment_outlined,
//           enabled: widget.selectedRegionId != null,
//         ),
//         const SizedBox(height: 20),

//         // Estate Dropdown
//         _buildDropdown<int>(
//           label: 'Estate/Area',
//           hint: widget.selectedTownId == null 
//               ? 'Select town first' 
//               : 'Select your estate',
//           value: widget.selectedEstateId,
//           items: widget.estates.map((estate) {
//             return DropdownMenuItem<int>(
//               value: estate['id'] as int,
//               child: Text(estate['name'] ?? 'Unknown'),
//             );
//           }).toList(),
//           onChanged: widget.selectedTownId != null ? widget.onEstateChanged : null,
//           icon: Icons.holiday_village_outlined,
//           enabled: widget.selectedTownId != null,
//         ),
//         const SizedBox(height: 20),

//         // Road Name
//         _buildTextField(
//           label: 'Road/Street Name',
//           hint: 'Enter your road or street name',
//           controller: widget.roadNameController,
//           icon: Icons.signpost_outlined,
//         ),

//         const SizedBox(height: 32),
//         const Divider(),
//         const SizedBox(height: 24),

//         // Section 2: Workplace Location
//         _buildSectionHeader(
//           icon: Icons.work_outline,
//           title: 'Workplace Location',
//           subtitle: 'Where do you work?',
//         ),
//         const SizedBox(height: 16),

//         // Checkbox for having a workplace
//         CheckboxListTile(
//           value: _hasWorkplace,
//           onChanged: (value) {
//             setState(() {
//               _hasWorkplace = value ?? false;
//               if (!_hasWorkplace) {
//                 _workplaceLocation = null;
//               }
//             });
//           },
//           title: Text(
//             'I have a workplace location',
//             style: theme.textTheme.bodyLarge?.copyWith(
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           contentPadding: EdgeInsets.zero,
//           controlAffinity: ListTileControlAffinity.leading,
//           activeColor: AppTheme.brightRed,
//         ),
        
//         if (_hasWorkplace) ...[
//           const SizedBox(height: 16),
          
//           // Google Places Location Picker for Workplace
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Search Your Workplace',
//                 style: theme.textTheme.titleMedium?.copyWith(
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               GooglePlacesLocationPicker(
//                 apiKey: widget.googleApiKey,
//                 hintText: 'Search for your workplace address...',
//                 decoration: InputDecoration(
//                   hintText: 'Search for your workplace address...',
//                   hintStyle: theme.inputDecorationTheme.hintStyle,
//                   prefixIcon: Icon(
//                     Icons.search,
//                     color: AppTheme.mediumGrey,
//                     size: 22,
//                   ),
//                   filled: true,
//                   fillColor: theme.inputDecorationTheme.fillColor,
//                   contentPadding: const EdgeInsets.symmetric(
//                     horizontal: 16,
//                     vertical: 16,
//                   ),
//                   border: theme.inputDecorationTheme.border,
//                   enabledBorder: theme.inputDecorationTheme.enabledBorder,
//                   focusedBorder: theme.inputDecorationTheme.focusedBorder,
//                 ),
//                 onLocationSelected: (locationData) {
//                   setState(() {
//                     _workplaceLocation = locationData;
//                   });
//                   widget.onWorkplaceSelected(locationData);
//                 },
//               ),
//             ],
//           ),
          
//           if (_workplaceLocation != null) ...[
//             const SizedBox(height: 16),
//             _buildWorkplaceInfo(),
//           ],
//         ],
//       ],
//     );
//   }

//   Widget _buildSectionHeader({
//     required IconData icon,
//     required String title,
//     required String subtitle,
//   }) {
//     final theme = Theme.of(context);
    
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: AppTheme.brightRed.withOpacity(0.05),
//         borderRadius: BorderRadius.circular(AppTheme.radiusM),
//         border: Border.all(
//           color: AppTheme.brightRed.withOpacity(0.2),
//           width: 1,
//         ),
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(10),
//             decoration: BoxDecoration(
//               color: AppTheme.brightRed.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(AppTheme.radiusS),
//             ),
//             child: Icon(
//               icon,
//               color: AppTheme.brightRed,
//               size: 24,
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: theme.textTheme.titleMedium?.copyWith(
//                     fontWeight: FontWeight.bold,
//                     color: AppTheme.brightRed,
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   subtitle,
//                   style: theme.textTheme.bodySmall?.copyWith(
//                     color: AppTheme.darkGrey,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDropdown<T>({
//     required String label,
//     required String hint,
//     required T? value,
//     required List<DropdownMenuItem<T>> items,
//     required void Function(T?)? onChanged,
//     required IconData icon,
//     bool enabled = true,
//   }) {
//     final theme = Theme.of(context);
    
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: theme.textTheme.titleMedium?.copyWith(
//             fontWeight: FontWeight.w600,
//             color: enabled ? theme.colorScheme.onSurface : AppTheme.mediumGrey,
//           ),
//         ),
//         const SizedBox(height: 8),
//         DropdownButtonFormField<T>(
//           value: value,
//           decoration: InputDecoration(
//             hintText: hint,
//             hintStyle: theme.inputDecorationTheme.hintStyle,
//             prefixIcon: Icon(icon, color: AppTheme.mediumGrey, size: 22),
//             filled: true,
//             fillColor: enabled 
//                 ? theme.inputDecorationTheme.fillColor 
//                 : AppTheme.lightSilver,
//             contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//             border: theme.inputDecorationTheme.border,
//             enabledBorder: theme.inputDecorationTheme.enabledBorder,
//             focusedBorder: theme.inputDecorationTheme.focusedBorder,
//             disabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(AppTheme.radiusM),
//               borderSide: BorderSide(color: AppTheme.silverGrey),
//             ),
//           ),
//           items: items,
//           onChanged: enabled ? onChanged : null,
//         ),
//       ],
//     );
//   }

//   Widget _buildTextField({
//     required String label,
//     required String hint,
//     required TextEditingController controller,
//     required IconData icon,
//   }) {
//     final theme = Theme.of(context);
    
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: theme.textTheme.titleMedium?.copyWith(
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         const SizedBox(height: 8),
//         TextFormField(
//           controller: controller,
//           textCapitalization: TextCapitalization.words,
//           style: theme.textTheme.bodyLarge,
//           decoration: InputDecoration(
//             hintText: hint,
//             hintStyle: theme.inputDecorationTheme.hintStyle,
//             prefixIcon: Icon(
//               icon,
//               color: AppTheme.mediumGrey,
//               size: 22,
//             ),
//             filled: true,
//             fillColor: theme.inputDecorationTheme.fillColor,
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 16,
//               vertical: 16,
//             ),
//             border: theme.inputDecorationTheme.border,
//             enabledBorder: theme.inputDecorationTheme.enabledBorder,
//             focusedBorder: theme.inputDecorationTheme.focusedBorder,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildWorkplaceInfo() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: AppTheme.successGreen.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(AppTheme.radiusM),
//         border: Border.all(
//           color: AppTheme.successGreen.withOpacity(0.3),
//           width: 1.5,
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(
//                 Icons.check_circle,
//                 color: AppTheme.successGreen,
//                 size: 20,
//               ),
//               const SizedBox(width: 8),
//               Text(
//                 'Workplace Selected',
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.bold,
//                   color: AppTheme.successGreen,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           _buildInfoRow(
//             icon: Icons.location_on,
//             label: 'Address',
//             value: _workplaceLocation!.address,
//           ),
//           const SizedBox(height: 8),
//           if (_workplaceLocation!.estateName != null) ...[
//             _buildInfoRow(
//               icon: Icons.business,
//               label: 'Area',
//               value: _workplaceLocation!.estateName!,
//             ),
//             const SizedBox(height: 8),
//           ],
//           _buildInfoRow(
//             icon: Icons.my_location,
//             label: 'Coordinates',
//             value: _workplaceLocation!.latLongString,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildInfoRow({
//     required IconData icon,
//     required String label,
//     required String value,
//   }) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Icon(
//           icon,
//           size: 16,
//           color: AppTheme.darkGrey,
//         ),
//         const SizedBox(width: 8),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 label,
//                 style: TextStyle(
//                   fontSize: 12,
//                   color: AppTheme.mediumGrey,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//               const SizedBox(height: 2),
//               Text(
//                 value,
//                 style: TextStyle(
//                   fontSize: 13,
//                   color: AppTheme.darkGrey,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }
