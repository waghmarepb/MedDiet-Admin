# Debug Logging Guide - MedDiet Admin

## Problem Fixed
Previously, when adding a meal, error logs were not showing properly in the debug console. This has been fixed by adding comprehensive logging throughout the meal addition flow.

## Changes Made

### 1. Enhanced `plan_service.dart` - API Service Layer
**Location:** `lib/services/plan_service.dart`

Added detailed logging for the `addMeal()` method:
- ✅ Logs when meal addition starts with timestamp
- ✅ Logs the patient ID and meal data being sent
- ✅ Logs the API URL and headers
- ✅ Logs the HTTP response status and body
- ✅ Logs success/failure with clear indicators (✅/❌)
- ✅ Logs full stack trace on exceptions
- ✅ Clear visual separators (========== ADD MEAL START/END ==========)

### 2. Enhanced `patients_page.dart` - UI Layer
**Location:** `lib/screens/pages/patients_page.dart`

Added logging in the `_handleAddMeal()` method:
- ✅ Logs validation failures
- ✅ Logs meal preparation details (patient ID, meal type, meal name)
- ✅ Logs API call initiation
- ✅ Logs success/failure responses
- ✅ Logs exceptions with full stack trace
- ✅ Uses emoji indicators for easy scanning (🍽️, 📝, 📡, ✅, ❌, 🔄)

### 3. Enhanced `user_details_page.dart` - User Details UI
**Location:** `lib/screens/user_details_page.dart`

Added logging in the meal dialog:
- ✅ Logs validation failures
- ✅ Logs meal data being sent
- ✅ Logs success/failure responses
- ✅ Logs exceptions with full stack trace
- ✅ Wrapped API calls in try-catch blocks

## How to View Debug Logs

### In VS Code / Cursor
1. Run your Flutter app in debug mode: `flutter run` or press F5
2. Open the **Debug Console** panel (View → Debug Console or Ctrl+Shift+Y)
3. All logs will appear with timestamps and emoji indicators

### In Android Studio
1. Run your app in debug mode
2. Open the **Run** tab at the bottom
3. Filter by "flutter" to see your debug logs

### In Terminal
```bash
flutter run --verbose
```

## Log Format Examples

### Successful Meal Addition
```
🍽️ Preparing to add meal for patient: 123
📝 Meal Type: breakfast
📝 Meal Name: Oatmeal with fruits
📡 Calling PlanService.addMeal...
[2025-01-06T10:30:45.123] ========== ADD MEAL START ==========
[2025-01-06T10:30:45.123] Adding meal for patient: 123
[2025-01-06T10:30:45.123] Meal data: {"meal_type":"breakfast","meal_name":"Oatmeal with fruits",...}
[2025-01-06T10:30:45.123] API URL: http://your-api.com/api/patients/123/meals
[2025-01-06T10:30:45.456] Response status: 201
[2025-01-06T10:30:45.456] Response body: {"success":true,"data":{...}}
[2025-01-06T10:30:45.456] ✅ Meal added successfully
[2025-01-06T10:30:45.456] ========== ADD MEAL END ==========
✅ Meal added successfully via API
🔄 Refreshing patient data...
```

### Failed Meal Addition (API Error)
```
🍽️ Preparing to add meal for patient: 123
📝 Meal Type: breakfast
📝 Meal Name: Oatmeal
📡 Calling PlanService.addMeal...
[2025-01-06T10:30:45.123] ========== ADD MEAL START ==========
[2025-01-06T10:30:45.123] Adding meal for patient: 123
[2025-01-06T10:30:45.456] Response status: 400
[2025-01-06T10:30:45.456] Response body: {"success":false,"message":"Invalid meal data"}
[2025-01-06T10:30:45.456] ❌ Failed to add meal: Invalid meal data
[2025-01-06T10:30:45.456] Full response: {success: false, message: Invalid meal data}
[2025-01-06T10:30:45.456] ========== ADD MEAL END ==========
❌ Failed to add meal: Invalid meal data
```

### Exception/Network Error
```
🍽️ Preparing to add meal for patient: 123
📡 Calling PlanService.addMeal...
[2025-01-06T10:30:45.123] ========== ADD MEAL START ==========
[2025-01-06T10:30:45.123] Adding meal for patient: 123
[2025-01-06T10:30:45.456] ❌ ERROR adding meal: SocketException: Failed host lookup
[2025-01-06T10:30:45.456] Stack trace: #0 PlanService.addMeal (package:meddiet/services/plan_service.dart:59)
[2025-01-06T10:30:45.456] ========== ADD MEAL END ==========
❌ EXCEPTION in _handleAddMeal: Error: SocketException: Failed host lookup
Stack trace: ...
```

### Validation Errors
```
❌ Validation failed: No meal type selected
```
or
```
❌ Validation failed: No meal name entered
```

## Common Issues and Solutions

### 1. No Logs Appearing
**Problem:** Debug console is empty when adding meals

**Solutions:**
- Make sure you're running in debug mode, not release mode
- Check that the Debug Console is open (not the Terminal)
- Try `flutter clean` and `flutter pub get`, then run again
- Ensure `debugPrint` is not disabled in your Flutter configuration

### 2. Logs Cut Off
**Problem:** Logs are truncated

**Solution:**
```bash
# Run with verbose output
flutter run --verbose

# Or increase log buffer
flutter run -v
```

### 3. Can't Find Specific Logs
**Problem:** Too many logs to find meal-related ones

**Solution:**
- Look for emoji indicators: 🍽️, 📝, 📡, ✅, ❌
- Search for "ADD MEAL" in the console
- Filter by timestamp if you know when you added the meal

## Testing the Logging

1. **Test Successful Addition:**
   - Add a meal with all required fields
   - Check for ✅ success indicators in logs

2. **Test Validation Errors:**
   - Try adding a meal without selecting type
   - Try adding a meal without entering name
   - Check for ❌ validation error logs

3. **Test API Errors:**
   - Try adding a meal with invalid data
   - Check for ❌ API error logs with response details

4. **Test Network Errors:**
   - Turn off backend server
   - Try adding a meal
   - Check for ❌ exception logs with stack trace

## Additional Debugging Tips

### Enable HTTP Logging
To see all HTTP requests/responses, you can add this to `plan_service.dart`:

```dart
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// Add this before making requests
debugPrint('Request URL: $url');
debugPrint('Request Headers: $headers');
debugPrint('Request Body: $body');
```

### Check Backend Logs
Don't forget to also check your backend logs at:
- `C:\Users\PRADIP\Documents\MedDiet\MedDiet_Backend\`

### Use Flutter DevTools
For advanced debugging:
```bash
flutter pub global activate devtools
flutter pub global run devtools
```

## Summary
All meal addition operations now have comprehensive logging that will help you:
- Track the flow of data from UI to API
- Identify where errors occur
- See exact error messages and stack traces
- Debug API communication issues
- Validate data being sent to the backend

The logs use clear visual indicators (emojis and symbols) to make it easy to scan and find issues quickly.

