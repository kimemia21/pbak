// import 'package:flutter/material.dart';
// import 'package:pbak/services/comms/comms.dart';

// /// Test screen for CommsService
// /// This screen demonstrates the CommsService functionality
// /// Can be used for testing API integration
// class CommsTestScreen extends StatefulWidget {
//   const CommsTestScreen({super.key});

//   @override
//   State<CommsTestScreen> createState() => _CommsTestScreenState();
// }

// class _CommsTestScreenState extends State<CommsTestScreen> {
//   final _comms = CommsService.instance;
//   String _result = 'No request made yet';
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _initializeComms();
//   }

//   void _initializeComms() {
//     // Display current configuration
//     setState(() {
//       _result = '''
// CommsService Initialized
// ━━━━━━━━━━━━━━━━━━━━━━
// Environment: ${CommsConfig.currentEnvironment}
// Base URL: ${CommsConfig.baseUrl}
// Connect Timeout: ${CommsConfig.connectTimeout}s
// Receive Timeout: ${CommsConfig.receiveTimeout}s
// Send Timeout: ${CommsConfig.sendTimeout}s
// Mock API: ${CommsConfig.useMockApi}
// ━━━━━━━━━━━━━━━━━━━━━━
// Ready to make requests!
//       ''';
//     });
//   }

//   Future<void> _testGetRequest() async {
//     setState(() {
//       _isLoading = true;
//       _result = 'Making GET request...';
//     });

//     final response = await _comms.get<Map<String, dynamic>>(
//       ApiEndpoints.allClubs,
//       queryParameters: {'limit': 10},
//     );

//     setState(() {
//       _isLoading = false;
//       if (response.success) {
//         _result = '''
// ✅ GET Request Successful
// ━━━━━━━━━━━━━━━━━━━━━━
// Status Code: ${response.statusCode}
// Message: ${response.message}
// ━━━━━━━━━━━━━━━━━━━━━━
// Response Data:
// ${_formatJson(response.rawData)}
//         ''';
//       } else {
//         _result = '''
// ❌ GET Request Failed
// ━━━━━━━━━━━━━━━━━━━━━━
// Status Code: ${response.statusCode ?? 'N/A'}
// Error Type: ${response.errorType}
// Message: ${response.message}
//         ''';
//       }
//     });
//   }

//   Future<void> _testPostRequest() async {
//     setState(() {
//       _isLoading = true;
//       _result = 'Making POST request...';
//     });

//     final response = await _comms.post<Map<String, dynamic>>(
//       ApiEndpoints.login,
//       data: {
//         'email': 'test@example.com',
//         'password': 'password123',
//       },
//     );

//     setState(() {
//       _isLoading = false;
//       if (response.success) {
//         _result = '''
// ✅ POST Request Successful
// ━━━━━━━━━━━━━━━━━━━━━━
// Status Code: ${response.statusCode}
// Message: ${response.message}
// ━━━━━━━━━━━━━━━━━━━━━━
// Response Data:
// ${_formatJson(response.rawData)}
//         ''';
//       } else {
//         _result = '''
// ❌ POST Request Failed
// ━━━━━━━━━━━━━━━━━━━━━━
// Status Code: ${response.statusCode ?? 'N/A'}
// Error Type: ${response.errorType}
// Message: ${response.message}
//         ''';
//       }
//     });
//   }

//   Future<void> _testErrorHandling() async {
//     setState(() {
//       _isLoading = true;
//       _result = 'Testing error handling...';
//     });

//     // Test with non-existent endpoint
//     final response = await _comms.get('/non-existent-endpoint');

//     setState(() {
//       _isLoading = false;
//       _result = '''
// 🔍 Error Handling Test
// ━━━━━━━━━━━━━━━━━━━━━━
// Status Code: ${response.statusCode ?? 'N/A'}
// Success: ${response.success}
// Error Type: ${response.errorType}
// Message: ${response.message}
// ━━━━━━━━━━━━━━━━━━━━━━
// Error types are properly detected and can be handled accordingly.
//       ''';
//     });
//   }

//   Future<void> _testAuthToken() async {
//     setState(() {
//       _result = 'Setting auth token...';
//     });

//     // Set a mock token
//     _comms.setAuthToken('mock_jwt_token_12345');

//     setState(() {
//       _result = '''
// 🔐 Authentication Token Test
// ━━━━━━━━━━━━━━━━━━━━━━
// Token set successfully!
// ━━━━━━━━━━━━━━━━━━━━━━
// All subsequent requests will include:
// Authorization: Bearer mock_jwt_token_12345
// ━━━━━━━━━━━━━━━━━━━━━━
// Try making a GET or POST request now to see the token in action.
//       ''';
//     });
//   }

//   Future<void> _testRemoveToken() async {
//     setState(() {
//       _result = 'Removing auth token...';
//     });

//     _comms.removeAuthToken();

//     setState(() {
//       _result = '''
// 🔓 Authentication Token Removed
// ━━━━━━━━━━━━━━━━━━━━━━
// Token removed successfully!
// ━━━━━━━━━━━━━━━━━━━━━━
// Subsequent requests will no longer include the Authorization header.
//       ''';
//     });
//   }

//   String _formatJson(dynamic data) {
//     if (data == null) return 'null';
//     try {
//       return data.toString().length > 500 
//           ? '${data.toString().substring(0, 500)}...' 
//           : data.toString();
//     } catch (e) {
//       return 'Error formatting data';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('CommsService Test'),
//         elevation: 0,
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(16),
//               child: Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.grey[900],
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Text(
//                   _result,
//                   style: const TextStyle(
//                     fontFamily: 'monospace',
//                     fontSize: 12,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           if (_isLoading)
//             const LinearProgressIndicator()
//           else
//             Container(height: 4, color: Colors.transparent),
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.1),
//                   blurRadius: 8,
//                   offset: const Offset(0, -2),
//                 ),
//               ],
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 const Text(
//                   'Test Operations',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 Wrap(
//                   spacing: 8,
//                   runSpacing: 8,
//                   children: [
//                     _TestButton(
//                       label: 'GET Request',
//                       icon: Icons.download,
//                       onPressed: _isLoading ? null : _testGetRequest,
//                     ),
//                     _TestButton(
//                       label: 'POST Request',
//                       icon: Icons.upload,
//                       onPressed: _isLoading ? null : _testPostRequest,
//                     ),
//                     _TestButton(
//                       label: 'Error Test',
//                       icon: Icons.error_outline,
//                       onPressed: _isLoading ? null : _testErrorHandling,
//                     ),
//                     _TestButton(
//                       label: 'Set Token',
//                       icon: Icons.lock,
//                       onPressed: _isLoading ? null : _testAuthToken,
//                     ),
//                     _TestButton(
//                       label: 'Remove Token',
//                       icon: Icons.lock_open,
//                       onPressed: _isLoading ? null : _testRemoveToken,
//                     ),
//                     _TestButton(
//                       label: 'Reset',
//                       icon: Icons.refresh,
//                       onPressed: _isLoading ? null : _initializeComms,
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _TestButton extends StatelessWidget {
//   final String label;
//   final IconData icon;
//   final VoidCallback? onPressed;

//   const _TestButton({
//     required this.label,
//     required this.icon,
//     this.onPressed,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return ElevatedButton.icon(
//       onPressed: onPressed,
//       icon: Icon(icon, size: 18),
//       label: Text(label),
//       style: ElevatedButton.styleFrom(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       ),
//     );
//   }
// }
