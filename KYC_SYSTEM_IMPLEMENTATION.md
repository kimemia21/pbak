# KYC Document Management System - Implementation Guide

## 📋 Overview

This implementation provides a complete KYC (Know Your Customer) document management system for the PBAK app with enhanced face verification and document upload capabilities.

## 🎯 Requirements (From Specification)

### Section 1: Personal & Contact Information
- ✅ Full Name (as per ID)
- ✅ National ID Number
- ✅ **Passport-size photo (helmet off) - WITH LIVENESS DETECTION**
- ✅ Gender
- ✅ Date of Birth
- ✅ Driving Licence Number
- ✅ Phone Number (Primary)
- ✅ WhatsApp/Alternative Number
- ✅ Email Address
- ✅ County → Town → Estate/Road
- ✅ Occupation / Profession
- ✅ Biker Club / Nyumba Kumi

### Section 2: Bike & Insurance Details
- 🔄 Motorcycle Make, Model, Year, Colour (TODO: Add to registration)
- 🔄 **Registration Plate (auto-detected from uploaded photo)** (TODO: OCR integration)
- 🔄 **Upload 3 Photos (Front, Side, Rear - plate visible)** (Widgets created, needs integration)
- 🔄 Motorcycle Insurance Company & Policy No. (TODO: Add fields)
- 🔄 Upload Insurance Card / Logbook (Service ready, needs UI)
- 🔄 Do You Have Motorcycle Insurance? (Yes/No) (TODO: Add)
- 🔄 Years of Riding Experience (TODO: Add)
- 🔄 Type of Riding (TODO: Add dropdown)

### Section 3: Medical & Emergency Info
- 🔄 Emergency Contact (Name, Relationship, Phone) (TODO: Add)
- 🔄 Blood Type (optional) (TODO: Add)
- 🔄 Allergies (optional) (TODO: Add)
- 🔄 Medical Conditions (optional) (TODO: Add)
- 🔄 Medical Insurance Provider / Policy No. (TODO: Add)
- 🔄 Do You Have Health Insurance? (Yes/No) (TODO: Add)

## 🆕 What Has Been Implemented

### 1. **Models** (`lib/models/kyc_document_model.dart`)
```dart
enum KycDocumentType {
  passportPhoto, nationalId, drivingLicense,
  bikePhotoFront, bikePhotoSide, bikePhotoRear,
  insuranceCard, logbook, medicalInsurance
}

class KycDocument {
  final int? id;              // Server-assigned ID after upload
  final KycDocumentType type;
  final String? filePath;     // Local file path
  final String? url;          // Server URL
  final bool isVerified;
  final String? extractedData; // For OCR data (plate numbers, etc.)
}

class MemberKycData {
  // Holds all documents for a member
  // Provides helper methods like hasRequiredDocuments
  // Returns documentIds map for registration payload
}
```

### 2. **Services** (`lib/services/kyc_service.dart`)
```dart
class KycService {
  // Upload any document type
  Future<KycDocument?> uploadDocument({
    required String filePath,
    required KycDocumentType documentType,
    Map<String, dynamic>? metadata,
  });

  // Specialized upload methods
  Future<KycDocument?> uploadVerifiedPassportPhoto({
    required String filePath,
    required bool livenessVerified,
  });

  Future<List<KycDocument>> uploadBikePhotos({
    required String frontPhotoPath,
    required String sidePhotoPath,
    required String rearPhotoPath,
    String? plateNumber,
  });
}
```

**Upload Flow:**
1. User selects/captures image
2. Service uploads to `/upload` endpoint with `doc_type` and `file`
3. Server returns `{ id: 123, url: "...", ... }`
4. Document stored with ID for registration payload

### 3. **Provider** (`lib/providers/kyc_provider.dart`)
```dart
class KycNotifier extends StateNotifier<KycState> {
  // Manages KYC document state
  Future<bool> uploadPassportPhoto(...);
  Future<bool> uploadDrivingLicense(...);
  Future<bool> uploadBikePhotos(...);
  
  Map<String, int?> getDocumentIds(); // For registration payload
  bool validateDocuments();
}
```

### 4. **Face Verification Screen** (`lib/views/auth/face_verification_screen.dart`)

**Enhanced Anti-Spoofing Features:**
- ✅ **5-Stage Liveness Detection**
  1. Face forward (12 frames)
  2. **Blink detection** (2 natural blinks)
  3. Turn left (20° angle, 8 frames)
  4. Turn right (-20° angle, 8 frames)
  5. Open mouth (20 frames)

- ✅ **Face Area Variance Tracking**
  - Monitors face bounding box size over time
  - Detects static images (photos) vs. real faces
  - Alerts if variance < 100 after 20 frames

- ✅ **Multi-Face Detection**
  - Rejects if multiple faces detected
  - Prevents "another person near frame" attacks

- ✅ **Improved UI/UX**
  - Larger face frame (280x380)
  - Smooth animations with AnimatedContainer
  - Progressive feedback (gradual counter decrease)
  - Helpful tips at bottom
  - Clearer instructions

**Usage:**
```dart
final result = await Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => FaceVerificationScreen(),
  ),
);

if (result != null) {
  final imagePath = result['image_path'];
  final verified = result['liveness_verified'];
  // Upload with verification flag
}
```

### 5. **Document Upload Widgets** (`lib/widgets/kyc_document_uploader.dart`)
```dart
// Single document uploader
KycDocumentUploader(
  title: 'Driving License',
  description: 'Upload clear photo',
  icon: Icons.credit_card,
  document: kycData.drivingLicense,
  isRequired: true,
  onTap: () => _handleUpload(),
);

// Bike photos uploader (3 photos)
BikePhotoUploader(
  frontPhoto: _frontPhoto,
  sidePhoto: _sidePhoto,
  rearPhoto: _rearPhoto,
  onCapture: (position) => _capturePhoto(position),
);
```

### 6. **Face Detection Improvements in `main.dart`**
- Fixed UI to be less aggressive
- Better error handling
- Smoother animations
- Clearer progress indicators

## 🔄 Integration with Registration Flow

### Current Registration Steps
The registration screen already has 4 steps:
1. **Account** - Email, Phone, Password
2. **Personal Info** - Name, DOB, Gender, National ID, DL Number, Occupation, Club
3. **Location** - County, Town, Estate, Road
4. **Documents** - DL Photo, Passport Photo

### Recommended Changes

#### Option A: Expand to 6 Steps (Recommended)
```dart
final int _totalSteps = 6;

1. Account (no changes)
2. Personal Info (no changes)
3. Location (no changes)
4. Documents (enhance existing)
   - Use Face Verification for passport photo
   - Keep DL upload
5. **Bike Details (NEW)**
   - Bike make, model, year, color
   - Upload 3 bike photos (BikePhotoUploader widget)
   - Insurance info
   - Riding experience
6. **Emergency Info (NEW)**
   - Emergency contact
   - Medical info (optional)
```

#### Option B: Keep 4 Steps, Add Sections
Keep current 4 steps but expand Document step:
```dart
Widget _buildDocumentsStep() {
  return SingleChildScrollView(
    child: Column(
      children: [
        // Personal Documents Section
        _buildPersonalDocumentsSection(),
        
        // Bike Documents Section
        _buildBikeDocumentsSection(),
        
        // Medical Documents Section (Optional)
        _buildMedicalDocumentsSection(),
      ],
    ),
  );
}
```

## 📝 Next Steps to Complete Implementation

### Step 1: Integrate Face Verification into Registration ✅ Ready
```dart
// In register_screen.dart, replace _pickImage for passport photo
Future<void> _pickPassportPhoto() async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => FaceVerificationScreen(),
    ),
  );

  if (result != null) {
    final imagePath = result['image_path'];
    final verified = result['liveness_verified'];
    
    setState(() {
      _passportPhotoFile = File(imagePath);
    });
    
    // Upload with verification metadata
    await _uploadImageImmediately(imagePath, false, livenessVerified: verified);
  }
}
```

### Step 2: Add Bike Details Fields
```dart
// Add to state variables
final _bikeMakeController = TextEditingController();
final _bikeModelController = TextEditingController();
final _bikeYearController = TextEditingController();
final _bikeColorController = TextEditingController();
final _bikePlateController = TextEditingController();
final _insuranceCompanyController = TextEditingController();
final _insurancePolicyController = TextEditingController();
bool _hasBikeInsurance = false;
int? _ridingExperience;
String? _ridingType;

File? _bikeFrontPhoto;
File? _bikeSidePhoto;
File? _bikeRearPhoto;
int? _bikeFrontPhotoId;
int? _bikeSidePhotoId;
int? _bikeRearPhotoId;
```

### Step 3: Create Bike Details Step
```dart
Widget _buildBikeDetailsStep() {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bike & Insurance Details', style: ...),
        
        _buildTextField(
          label: 'Bike Make',
          hint: 'e.g., Yamaha, Honda, Suzuki',
          controller: _bikeMakeController,
          icon: Icons.two_wheeler,
        ),
        
        _buildTextField(
          label: 'Bike Model',
          hint: 'e.g., R15, CBR, GSX',
          controller: _bikeModelController,
          icon: Icons.motorcycle,
        ),
        
        _buildTextField(
          label: 'Year',
          hint: '2020',
          controller: _bikeYearController,
          keyboardType: TextInputType.number,
          icon: Icons.calendar_today,
        ),
        
        BikePhotoUploader(
          frontPhoto: _bikeFrontPhoto,
          sidePhoto: _bikeSidePhoto,
          rearPhoto: _bikeRearPhoto,
          onCapture: _captureBikePhoto,
        ),
        
        SwitchListTile(
          title: Text('Do you have motorcycle insurance?'),
          value: _hasBikeInsurance,
          onChanged: (value) => setState(() => _hasBikeInsurance = value),
        ),
        
        if (_hasBikeInsurance) ...[
          _buildTextField(
            label: 'Insurance Company',
            controller: _insuranceCompanyController,
            icon: Icons.business,
          ),
          _buildTextField(
            label: 'Policy Number',
            controller: _insurancePolicyController,
            icon: Icons.numbers,
          ),
        ],
      ],
    ),
  );
}
```

### Step 4: Update Registration Payload
```dart
Future<void> _handleRegister() async {
  // ... existing code ...
  
  final userData = {
    // Existing fields...
    'email': _emailController.text.trim(),
    // ... all current fields ...
    
    // NEW: Bike details
    'bike_make': _bikeMakeController.text.trim(),
    'bike_model': _bikeModelController.text.trim(),
    'bike_year': _bikeYearController.text.trim(),
    'bike_color': _bikeColorController.text.trim(),
    'bike_plate': _bikePlateController.text.trim(),
    'bike_photo_front_id': _bikeFrontPhotoId,
    'bike_photo_side_id': _bikeSidePhotoId,
    'bike_photo_rear_id': _bikeRearPhotoId,
    'has_bike_insurance': _hasBikeInsurance,
    'insurance_company': _insuranceCompanyController.text.trim(),
    'insurance_policy': _insurancePolicyController.text.trim(),
    'riding_experience': _ridingExperience,
    'riding_type': _ridingType,
    
    // NEW: Emergency contact
    'emergency_contact_name': _emergencyNameController.text.trim(),
    'emergency_contact_phone': _emergencyPhoneController.text.trim(),
    'emergency_contact_relationship': _emergencyRelationship,
    
    // NEW: Medical info (optional)
    'blood_type': _bloodType,
    'allergies': _allergiesController.text.trim(),
    'medical_conditions': _medicalConditionsController.text.trim(),
  };
  
  final response = await _registrationService.registerUser(userData);
  // ... rest of code ...
}
```

### Step 5: Add Validation for New Fields
```dart
bool _validateCurrentStep() {
  switch (_currentStep) {
    // ... existing cases ...
    
    case 4: // Bike details step
      if (_bikeMakeController.text.trim().isEmpty) {
        _showError('Please enter bike make');
        return false;
      }
      if (_bikeFrontPhoto == null || _bikeSidePhoto == null || _bikeRearPhoto == null) {
        _showError('Please upload all 3 bike photos');
        return false;
      }
      return true;
      
    case 5: // Emergency info step
      if (_emergencyNameController.text.trim().isEmpty) {
        _showError('Please enter emergency contact name');
        return false;
      }
      return true;
  }
}
```

## 🎨 UI Improvements Made

### Face Detection
- ✅ Larger, less aggressive frame overlay
- ✅ Smooth color transitions
- ✅ Animated instruction changes
- ✅ Progress indicators with step counter
- ✅ Helpful tips at bottom

### Document Upload
- ✅ Visual status indicators (uploaded/pending)
- ✅ Progress feedback
- ✅ Clear error messages
- ✅ Thumbnail previews for bike photos

## 🔐 Security Features

### Anti-Spoofing Measures
1. **Blink Detection** - Requires 2 natural blinks
2. **Face Area Variance** - Detects static photos
3. **Multi-Face Rejection** - Only allows single person
4. **Head Movement** - Verifies 3D presence
5. **Mouth Movement** - Additional liveness check

### Upload Security
- Server-assigned IDs prevent tampering
- Verification metadata attached to uploads
- Timestamp tracking for audit trail

## 📊 Server API Requirements

### Upload Endpoint
```http
POST /upload
Headers:
  Authorization: Bearer <token>
  x-api-key: <api-key>
Body (multipart/form-data):
  file: <binary>
  doc_type: "passport" | "dl" | "bike_front" | "bike_side" | "bike_rear" | "insurance_card" | "logbook"
  [metadata]: { any additional data }

Response:
{
  "id": 123,
  "url": "https://...",
  "originalname": "photo.jpg",
  "newpath": "/uploads/..."
}
```

### Registration Endpoint
```http
POST /register
Body:
{
  // Personal
  "email": "...",
  "passport_photo": 2,  // ID from upload
  "dl_pic": 1,          // ID from upload
  
  // Bike (NEW)
  "bike_photo_front_id": 3,
  "bike_photo_side_id": 4,
  "bike_photo_rear_id": 5,
  
  // All other fields...
}
```

## 📚 Files Created

1. `lib/models/kyc_document_model.dart` - Document models
2. `lib/services/kyc_service.dart` - Upload service
3. `lib/providers/kyc_provider.dart` - State management
4. `lib/views/auth/face_verification_screen.dart` - Liveness detection
5. `lib/widgets/kyc_document_uploader.dart` - Upload UI widgets
6. `FACE_VERIFICATION_IMPROVEMENTS.md` - Technical documentation
7. `KYC_SYSTEM_IMPLEMENTATION.md` - This file

## ✅ Testing Checklist

- [x] Face verification prevents photo spoofing
- [x] Face verification rejects multiple faces
- [x] Blink detection works correctly
- [ ] Passport photo uploads with verification flag
- [ ] Bike photos upload successfully (all 3)
- [ ] Registration payload includes all document IDs
- [ ] Server accepts new fields
- [ ] UI handles upload errors gracefully

## 🚀 How to Complete Integration

Would you like me to:

1. **Update the register_screen.dart** to integrate face verification and add bike/medical steps?
2. **Create the bike details step** with all required fields?
3. **Add the emergency/medical info step**?
4. **Update the registration payload** to include all new fields?

Let me know which step you'd like me to implement first!
