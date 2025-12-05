# Image Upload ID Extraction Fix

## Problem
When uploading images, the API response format doesn't always include an explicit `id` field. Instead, the response looks like:

```json
{
  "fieldname": "file",
  "originalname": "CAP6728164250140725349.jpg",
  "encoding": "7bit",
  "mimetype": "image/jpeg",
  "destination": "uploads/",
  "filename": "1764924068428.jpg",
  "path": "uploads/1764924068428.jpg",
  "size": 384905,
  "rsp": true,
  "message": "File uploaded successfully",
  "newpath": "uploads/1764924068428.jpg"
}
```

The ID needs to be extracted from the filename (e.g., `1764924068428` from `1764924068428.jpg`).

## Solution
Updated the following files to automatically extract the ID from the filename when not explicitly provided:

### 1. `lib/services/comms/registration_service.dart`
Updated the `uploadImage()` method to:
- Check for explicit `id` or `file_id` in response
- Extract ID from `filename` field if not present
- Fallback to extracting from `newpath` field
- Additional fallback to `path` field

### 2. `lib/services/upload_service.dart`
Updated the `UploadResult` model to:
- Add an `id` field to store the extracted ID
- Updated `fromJson()` constructor with the same extraction logic
- Also handle multiple field names: `originalname`, `mimetype`, etc.

## ID Extraction Priority
The logic follows this priority order:

1. **Explicit ID**: Check `json['id']` first
2. **File ID**: Check `json['file_id']` 
3. **Filename**: Extract from `json['filename']` (e.g., "1764924068428.jpg" → 1764924068428)
4. **Newpath**: Extract from `json['newpath']` (e.g., "uploads/1764924068428.jpg" → 1764924068428)
5. **Path**: Extract from `json['path']` (e.g., "uploads/1764924068428.jpg" → 1764924068428)

## Testing
All test cases passed:
- ✅ Extract ID from filename in typical upload response
- ✅ Extract ID from newpath when filename has different format
- ✅ Extract ID from path field
- ✅ Use explicit ID when provided
- ✅ Use file_id when provided

## Usage
No changes required in calling code. The services will automatically extract the ID:

```dart
// Registration service
final uploadedId = await _registrationService.uploadImage(filePath, 'dl');
print('Uploaded ID: $uploadedId'); // Will be extracted from filename

// Upload service
final result = await uploadService.uploadFile(
  filePath: filePath,
  fileField: 'file',
);
print('Uploaded ID: ${result?.id}'); // Will be extracted from filename
```

## Benefits
- Handles multiple API response formats
- Backwards compatible with explicit ID responses
- Robust fallback mechanisms
- No breaking changes to existing code
