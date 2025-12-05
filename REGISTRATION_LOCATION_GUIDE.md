# Registration Location Picker - Implementation Guide

## Overview
This implementation adds an enhanced location picker to the registration flow that combines:
1. **Home Location**: Traditional dropdown selection (Region → Town → Estate)
2. **Workplace Location**: Google Places API integration for accurate address search with coordinates

## Features

### ✅ Home Location Section
- County/Region selection
- Town/City selection (dynamically loaded based on region)
- Estate/Area selection (dynamically loaded based on town)
- Road/Street name input

### ✅ Workplace Location Section
- Google Places autocomplete search
- Real-time location suggestions as user types
- Automatic coordinate extraction (latitude, longitude)
- Estate/area name detection
- Visual confirmation with location details
- Optional - users can skip if they don't have a workplace

## Implementation Details

### Files Created/Modified

#### 1. **New Widget**: `lib/widgets/registration_location_picker.dart`
A comprehensive location picker widget that:
- Displays both home and workplace location inputs
- Handles cascading dropdowns for home location
- Integrates Google Places API for workplace search
- Provides beautiful UI with section headers and visual feedback
- Maintains theme consistency

#### 2. **API Keys Config**: `lib/utils/api_keys.dart`
Centralized API key management with:
- Google Places API key storage
- Configuration validation
- Documentation on how to obtain API keys

#### 3. **Updated**: `lib/views/auth/register_screen.dart`
Added:
- Workplace location state variables
- Integration with new location picker widget
- Updated registration payload to include workplace data

### Data Flow

```
User Input → Google Places → LocationData Model → State Variables → Backend
```

**State Variables:**
```dart
String? _workplaceLatLong;      // e.g., "-1.2921,36.8219"
String? _workplacePlaceId;      // Google Place ID
String? _workplaceEstateName;   // e.g., "Westlands"
String? _workplaceAddress;      // Full address
```

**Backend Payload:**
```json
{
  "estate_id": 1,
  "road_name": "Ngong Road",
  "work_lat_long": "-1.2921,36.8219",
  "work_place_id": "ChIJJ...",
  "work_estate_name": "Westlands",
  "work_address": "ABC Place, Waiyaki Way, Westlands, Nairobi"
}
```

## Setup Instructions

### 1. Get Google Places API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the following APIs:
   - **Places API**
   - **Maps SDK for Android** (if using Android)
   - **Maps SDK for iOS** (if using iOS)
4. Create credentials:
   - Go to **APIs & Services → Credentials**
   - Click **Create Credentials → API Key**
5. Restrict your API key (Important for security):
   - Click on the created API key
   - Under **API restrictions**, select "Restrict key"
   - Select the enabled APIs above
   - Under **Application restrictions**, add your app's package name

### 2. Add API Key to Project

Open `lib/utils/api_keys.dart` and replace the placeholder:

```dart
static const String googlePlacesApiKey = 'AIzaSyC...YOUR_ACTUAL_KEY';
```

### 3. Android Configuration (if needed)

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<application>
    ...
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="YOUR_API_KEY"/>
</application>
```

### 4. iOS Configuration (if needed)

Add to `ios/Runner/AppDelegate.swift`:

```swift
import GoogleMaps

GMSServices.provideAPIKey("YOUR_API_KEY")
```

## Usage

### For Users

1. **Home Location** (Required):
   - Select County/Region
   - Select Town/City (appears after region selection)
   - Select Estate/Area (appears after town selection)
   - Enter Road/Street name

2. **Workplace Location** (Optional):
   - Check "I have a workplace location" checkbox
   - Search for your workplace address
   - Select from the suggestions
   - Review and confirm the selected location

### For Developers

The location picker is integrated into Step 3 (Location) of the registration flow:

```dart
Widget _buildLocationStep() {
  return SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    child: RegistrationLocationPicker(
      googleApiKey: ApiKeys.googlePlacesApiKey,
      regions: _regions,
      towns: _towns,
      estates: _estates,
      selectedRegionId: _selectedRegionId,
      selectedTownId: _selectedTownId,
      selectedEstateId: _selectedEstateId,
      roadNameController: _roadNameController,
      onRegionChanged: (value) async {
        setState(() => _selectedRegionId = value);
        if (value != null) await _loadTowns(value);
      },
      onTownChanged: (value) async {
        setState(() => _selectedTownId = value);
        if (value != null && _selectedRegionId != null) {
          await _loadEstates(_selectedRegionId!, value);
        }
      },
      onEstateChanged: (value) {
        setState(() => _selectedEstateId = value);
      },
      onWorkplaceSelected: (locationData) {
        setState(() {
          _workplaceLatLong = locationData.latLongString;
          _workplacePlaceId = locationData.address.hashCode.toString();
          _workplaceEstateName = locationData.estateName;
          _workplaceAddress = locationData.address;
        });
      },
    ),
  );
}
```

## Backend Integration

### Expected Request Format

```json
{
  "email": "user@example.com",
  "password": "Password123!",
  "phone": "+254712345678",
  "alternative_phone": "+254722334455",
  "first_name": "John",
  "last_name": "Doe",
  "date_of_birth": "1990-01-01",
  "gender": "male",
  "national_id": "12345678",
  "driving_license_number": "DL123456",
  "occupation": 1,
  "club_id": 1,
  "estate_id": 1,
  "road_name": "Ngong Road",
  "work_lat_long": "-1.2921,36.8219",
  "work_place_id": "ChIJJ...",
  "work_estate_name": "Westlands",
  "work_address": "ABC Place, Waiyaki Way, Westlands, Nairobi",
  "dl_pic": 1,
  "passport_photo": 1,
  ...
}
```

### Backend Field Mapping

| Frontend Field | Backend Field | Type | Required | Description |
|---------------|---------------|------|----------|-------------|
| `_selectedEstateId` | `estate_id` | int | Yes | Home estate ID |
| `_roadNameController.text` | `road_name` | string | No | Home road/street name |
| `_workplaceLatLong` | `work_lat_long` | string | No | Format: "lat,lng" |
| `_workplacePlaceId` | `work_place_id` | string | No | Google Place ID |
| `_workplaceEstateName` | `work_estate_name` | string | No | Workplace area/estate |
| `_workplaceAddress` | `work_address` | string | No | Full workplace address |

## UI/UX Features

### Visual Design
- **Section Headers**: Clear distinction between home and workplace sections
- **Progressive Disclosure**: Workplace section only appears when checkbox is checked
- **Visual Feedback**: 
  - Loading indicators during search
  - Success indicators when location is selected
  - Location details card showing selected workplace
- **Theme Consistency**: Uses app theme colors and styles

### User Experience
- **Smart Cascading**: Town dropdown enables after region selection
- **Clear Instructions**: Helper text and placeholders guide users
- **Optional Workplace**: Users can skip workplace if not applicable
- **Validation**: Ensures required fields are completed before proceeding

## Testing

### Test Scenarios

1. **Home Location Only**:
   - Select region, town, estate
   - Leave workplace unchecked
   - Verify registration succeeds with null workplace fields

2. **Full Location Data**:
   - Complete home location
   - Check workplace checkbox
   - Search and select workplace
   - Verify all fields populated correctly

3. **API Key Validation**:
   - Test with invalid API key
   - Verify graceful error handling

4. **Network Issues**:
   - Test with slow/no internet
   - Verify appropriate error messages

## Security Considerations

⚠️ **Important Security Notes:**

1. **API Key Protection**:
   - Never commit API keys to version control
   - Use environment variables in production
   - Consider using backend proxy for API calls
   - Add package name restrictions to your API key

2. **Data Privacy**:
   - Workplace location is optional
   - Users control what information they share
   - Comply with local data protection regulations

3. **Production Best Practices**:
   ```dart
   // Use environment variables
   static const String googlePlacesApiKey = 
       String.fromEnvironment('GOOGLE_PLACES_API_KEY');
   
   // Or use flutter_dotenv
   final apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'];
   ```

## Troubleshooting

### Issue: Google Places not working
**Solution**: Check API key is valid and Places API is enabled in Google Cloud Console

### Issue: No suggestions appearing
**Solution**: Check internet connection and API quota limits

### Issue: Wrong location selected
**Solution**: Verify country code in GooglePlaceAutoCompleteTextField (currently set to "ke" for Kenya)

### Issue: Coordinates not captured
**Solution**: Ensure `isLatLngRequired: true` in GooglePlaceAutoCompleteTextField

## Dependencies

This implementation uses:
- `google_places_flutter: ^2.0.9` (already in pubspec.yaml)

No additional dependencies needed!

## Future Enhancements

Potential improvements:
1. Add map preview of selected location
2. Current location detection
3. Distance calculation between home and workplace
4. Offline caching of recent searches
5. Multiple workplace support

## Support

For issues or questions:
1. Check the Google Places API documentation
2. Review error logs for API-related issues
3. Verify API key restrictions and quotas

---

**Last Updated**: 2024
**Version**: 1.0.0
