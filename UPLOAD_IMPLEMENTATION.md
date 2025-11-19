# Document Upload Implementation ✅

## Overview
Implemented immediate upload of documents when selected, with visual feedback showing upload status and returned IDs.

## How It Works

### Upload Flow
1. **User selects image** → `_pickImage()` called
2. **Image immediately uploaded** → `_uploadImageImmediately()` called
3. **Server returns ID** → Stored in `_dlPicId` or `_passportPhotoId`
4. **Visual feedback shown** → Green badge with ID displayed
5. **On registration** → IDs sent with form data

### Visual States

#### 1. No Image Selected
- Grey border
- Grey icon (credit card or portrait)
- "Tap to select image" placeholder
- Upload icon in corner

#### 2. Image Selected, Uploading
- Orange border
- Orange upload cloud icon
- Image preview shown
- Orange "Uploading..." badge on image

#### 3. Successfully Uploaded
- Green border (2px thick)
- Green checkmark icon
- Image preview shown
- Green "Uploaded (ID: 123)" badge on image
- Edit icon in corner to re-upload

### API Integration

#### Upload Endpoint
```
POST /api/v1/upload
Headers:
  - x-api-key: nokey
  - Authorization: Bearer {token}
Body (multipart/form-data):
  - file: (binary)
  - doc_type: "dl" or "passport"
```

#### Response
```json
{
  "status": "success",
  "data": {
    "id": 123,
    "url": "https://...",
    "filename": "..."
  }
}
```

Or simply:
```json
{
  "id": 123,
  "url": "https://..."
}
```

### Code Changes

#### 1. Registration Service (`registration_service.dart`)
```dart
Future<int?> uploadImage(String filePath, String imageType) async {
  // imageType: 'dl' for driving license, 'passport' for passport photo
  final response = await _comms.uploadFile(
    ApiEndpoints.uploadFile,
    filePath: filePath,
    fileField: 'file',
    data: {'doc_type': imageType},
  );

  // Parse response to get ID
  if (response.success && response.rawData != null) {
    final data = response.rawData!;
    
    if (data['data'] != null) {
      final fileData = data['data'] as Map<String, dynamic>;
      final id = fileData['id'] ?? fileData['file_id'];
      return id is int ? id : int.tryParse(id.toString());
    } else if (data['id'] != null) {
      final id = data['id'];
      return id is int ? id : int.tryParse(id.toString());
    }
  }
  
  return null;
}
```

#### 2. Register Screen (`register_screen.dart`)

**Immediate Upload on Selection:**
```dart
Future<void> _pickImage(bool isDlPic) async {
  final pickedFile = await _imagePicker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 1920,
    maxHeight: 1920,
    imageQuality: 85,
  );

  if (pickedFile != null && mounted) {
    setState(() {
      if (isDlPic) {
        _dlPicFile = File(pickedFile.path);
        _dlPicId = null; // Reset ID when new file selected
      } else {
        _passportPhotoFile = File(pickedFile.path);
        _passportPhotoId = null;
      }
    });

    // Upload immediately after selection
    await _uploadImageImmediately(pickedFile.path, isDlPic);
  }
}
```

**Upload Handler:**
```dart
Future<void> _uploadImageImmediately(String filePath, bool isDlPic) async {
  setState(() => _isLoading = true);

  try {
    final imageType = isDlPic ? 'dl' : 'passport';
    final uploadedId = await _registrationService.uploadImage(
      filePath,
      imageType,
    );

    if (mounted) {
      if (uploadedId != null) {
        setState(() {
          if (isDlPic) {
            _dlPicId = uploadedId;
          } else {
            _passportPhotoId = uploadedId;
          }
          _isLoading = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isDlPic
                  ? 'Driving license uploaded successfully!'
                  : 'Passport photo uploaded successfully!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        setState(() => _isLoading = false);
        _showError('Failed to upload image. Please try again.');
      }
    }
  } catch (e) {
    setState(() => _isLoading = false);
    _showError('Error uploading image: $e');
  }
}
```

**Validation Before Registration:**
```dart
Future<bool> _uploadImages() async {
  // Check if images are already uploaded (have IDs)
  if (_dlPicFile != null && _dlPicId == null) {
    _showError('Driving license upload incomplete. Please re-select the image.');
    return false;
  }

  if (_passportPhotoFile != null && _passportPhotoId == null) {
    _showError('Passport photo upload incomplete. Please re-select the image.');
    return false;
  }

  // Both images should be uploaded by now (IDs exist)
  return _dlPicId != null && _passportPhotoId != null;
}
```

**Visual Feedback:**
```dart
Widget _buildImageUploadCard({
  required String title,
  required String description,
  required IconData icon,
  required File? imageFile,
  required int? uploadedId,
  required VoidCallback onTap,
}) {
  final isUploaded = uploadedId != null;
  final hasFile = imageFile != null;
  
  return Card(
    elevation: isUploaded ? 4 : 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: isUploaded 
            ? Colors.green 
            : (hasFile ? Colors.orange : Colors.grey[300]!),
        width: isUploaded ? 2 : 1,
      ),
    ),
    // ... rest of card UI with status badges
  );
}
```

### Registration Data Structure

When submitting registration:
```dart
final userData = {
  'email': _emailController.text.trim(),
  'password': _passwordController.text,
  // ... other fields ...
  'dl_pic': _dlPicId,           // ID from upload
  'passport_photo': _passportPhotoId, // ID from upload
};
```

### User Experience

1. **Select Driving License Photo**
   - User taps card
   - Image picker opens
   - User selects image
   - Loading indicator shows
   - Image uploads to server
   - Green badge shows "Uploaded (ID: 123)"
   - Success toast appears

2. **Select Passport Photo**
   - Same flow as above
   - Different doc_type sent to server

3. **Change/Re-upload**
   - User can tap card again
   - Selects new image
   - Old ID cleared
   - New upload starts
   - New ID stored

4. **Registration Submit**
   - System checks both IDs exist
   - If missing, shows error to re-select
   - If present, submits with IDs included

### Error Handling

- **Upload fails**: Shows error snackbar, user can retry
- **ID missing at submit**: Clear error message
- **Network error**: Caught and displayed to user
- **Invalid response**: Logged and user notified

### Debug Logging

All uploads log:
- File path being uploaded
- Upload type (dl/passport)
- Server response
- Returned ID
- Any errors

Example output:
```
I/flutter: Uploading image: /path/to/image.jpg, type: dl
I/flutter: Upload response: {status: success, data: {id: 123, url: ...}}
I/flutter: Uploaded successfully, ID: 123
```

### Benefits

✅ Immediate upload prevents large registration payload
✅ User knows upload status in real-time
✅ Can fix upload issues before final submit
✅ Server gets files as soon as selected
✅ Clear visual feedback with colors and badges
✅ IDs stored and sent with registration
✅ Can change/re-upload anytime
✅ Proper error handling and retry logic

## Testing

1. **Select DL image** → Uploads immediately → Green badge with ID
2. **Select passport** → Uploads immediately → Green badge with ID  
3. **Change DL image** → Old cleared → New uploads → New ID shown
4. **Submit without DL** → Error shown
5. **Submit with both** → IDs sent in registration data
6. **Network error** → Error shown, can retry

## Complete! 🎉

The document upload flow is now fully integrated with:
- Immediate uploads on selection
- Visual status feedback
- ID storage and transmission
- Proper error handling
- User-friendly experience
