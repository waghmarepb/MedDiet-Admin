# Delete All Meals Feature

## Overview
Added functionality to delete all meals for a patient on a specific date (default: today) with a single click.

## Features Added

### 1. Backend Service Method
**File:** `lib/services/plan_service.dart`

#### New Method: `deleteAllMeals()`
```dart
static Future<ApiResponse<int>> deleteAllMeals(String patientId, {String? date})
```

**Functionality:**
- Fetches all meals for the specified patient and date
- Deletes each meal individually using the existing `deleteMeal()` API
- Returns count of successfully deleted meals
- Provides detailed logging for debugging

**Parameters:**
- `patientId`: The patient's ID
- `date`: Optional date filter (defaults to today if not provided)

**Returns:**
- `ApiResponse<int>` with:
  - `success`: true if operation completed
  - `message`: Summary of operation
  - `data`: Number of meals deleted

**Example Usage:**
```dart
final response = await PlanService.deleteAllMeals(
  'PAT_F5856A2B',
  date: '2026-01-06',
);

if (response.success) {
  print('Deleted ${response.data} meals');
}
```

### 2. UI Components
**File:** `lib/screens/pages/patients_page.dart`

#### A. Delete All Button
Added a red "Delete All" button in the meals section header that:
- Only appears when meals exist (`if (meals.isNotEmpty)`)
- Uses a red gradient to indicate destructive action
- Shows delete sweep icon
- Positioned between meal count and "Add Meal" button

**Visual Design:**
```
Meals Today    [2 meals] [🗑️ Delete All] [+ Add Meal]
```

#### B. Confirmation Dialog
**Method:** `_confirmDeleteAllMeals()`

Shows a warning dialog before deletion:
- ⚠️ Warning icon in title
- Clear message about irreversible action
- Cancel and Delete All buttons
- Red Delete All button for visual warning

**Dialog Preview:**
```
⚠️  Delete All Meals

Are you sure you want to delete ALL meals for today?
This action cannot be undone.

[Cancel]  [Delete All]
```

#### C. Delete Handler
**Method:** `_handleDeleteAllMeals()`

Handles the deletion process:
1. Validates patient selection
2. Shows loading indicator
3. Calls `PlanService.deleteAllMeals()`
4. Hides loading indicator
5. Shows success/error message
6. Refreshes patient data

**Features:**
- ✅ Loading indicator during deletion
- ✅ Success message with count
- ✅ Error handling with user-friendly messages
- ✅ Automatic data refresh
- ✅ Comprehensive debug logging

## User Flow

### Step-by-Step Process

1. **User Views Meals**
   ```
   Today's Meals    [2 meals] [🗑️ Delete All] [+ Add Meal]
   
   🍽️ Milk
      ⏰ 08:00                      150 cal
   
   🍽️ Oatmeal
      ⏰ 09:30                      450 cal
   ```

2. **User Clicks "Delete All"**
   - Confirmation dialog appears

3. **User Confirms Deletion**
   - Loading indicator shows: "Deleting all meals..."
   - Backend deletes each meal
   - Loading indicator hides

4. **Success Feedback**
   ```
   ✅ Successfully deleted 2 meals
   ```

5. **UI Updates**
   ```
   Today's Meals    [+ Add Meal]
   
   No meal data available yet
   ```

## Debug Logging

### Service Layer Logs
```
[2026-01-06T17:30:00.000] 🗑️ Fetching all meals to delete for patient PAT_F5856A2B
[2026-01-06T17:30:00.123] 🗑️ Deleting 2 meals...
[2026-01-06T17:30:00.234] 🗑️ Deleting meal 13 for patient PAT_F5856A2B
[2026-01-06T17:30:00.345] ✅ Meal deleted successfully
[2026-01-06T17:30:00.456] 🗑️ Deleting meal 14 for patient PAT_F5856A2B
[2026-01-06T17:30:00.567] ✅ Meal deleted successfully
[2026-01-06T17:30:00.678] ✅ Deleted 2 meals, 0 failed
```

### UI Layer Logs
```
🗑️ Starting delete all meals for patient: PAT_F5856A2B
✅ Successfully deleted 2 meals
🔄 Refreshing patient data...
📡 Fetching meals for 1 patients...
✅ Loaded 0 meals for patient PAT_F5856A2B
```

## Error Handling

### Scenario 1: No Meals to Delete
```dart
if (meals.isEmpty) {
  return ApiResponse(
    success: true, 
    message: 'No meals to delete', 
    data: 0
  );
}
```
**User sees:** "No meals to delete" (success message)

### Scenario 2: Partial Deletion Failure
```dart
// If some meals fail to delete
return ApiResponse(
  success: true,
  message: 'Deleted 2 meals, 1 failed',
  data: 2
);
```
**User sees:** "Deleted 2 meals, 1 failed" (warning)

### Scenario 3: Network Error
```dart
catch (e) {
  return ApiResponse(
    success: false,
    message: 'Error: $e',
    data: 0
  );
}
```
**User sees:** "Error: [error details]" (error message)

### Scenario 4: API Error
```dart
if (!mealsResponse.success) {
  return ApiResponse(
    success: false,
    message: 'Failed to fetch meals'
  );
}
```
**User sees:** "Failed to fetch meals" (error message)

## Technical Details

### API Calls Made
1. **GET** `/doctor/patient/{id}/meals?date={today}`
   - Fetches all meals for the date
   
2. **DELETE** `/doctor/patient/{id}/meals/{mealId}` (for each meal)
   - Deletes individual meal
   - Called in sequence for each meal

### Performance Considerations
- **Sequential Deletion**: Meals are deleted one by one (not in parallel)
  - Reason: Ensures proper error tracking per meal
  - Alternative: Could be optimized with `Future.wait()` for parallel deletion

- **Loading Indicator**: Shows for entire operation
  - Duration: Depends on number of meals
  - Typical: 2-5 seconds for 5 meals

### State Management
- Uses existing `_fetchPatients()` to refresh data
- Automatically updates `_patientsMealsData` cache
- Triggers UI rebuild with updated meal count

## Testing Checklist

### ✅ Test Case 1: Delete Multiple Meals
1. Add 3 meals for today
2. Click "Delete All"
3. Confirm deletion
4. **Expected:** All 3 meals deleted, success message shown

### ✅ Test Case 2: Delete Single Meal
1. Add 1 meal for today
2. Click "Delete All"
3. Confirm deletion
4. **Expected:** Meal deleted, "Successfully deleted 1 meals" shown

### ✅ Test Case 3: Cancel Deletion
1. Have meals for today
2. Click "Delete All"
3. Click "Cancel" in dialog
4. **Expected:** Dialog closes, no meals deleted

### ✅ Test Case 4: No Meals
1. Ensure no meals for today
2. **Expected:** "Delete All" button not visible

### ✅ Test Case 5: Network Error
1. Disconnect network
2. Click "Delete All" and confirm
3. **Expected:** Error message shown, meals remain

### ✅ Test Case 6: Multiple Patients
1. Add meals for Patient A
2. Switch to Patient B
3. Add meals for Patient B
4. Delete all meals for Patient B
5. Switch back to Patient A
6. **Expected:** Patient A's meals still exist

## UI/UX Improvements

### Visual Feedback
- ✅ Loading spinner during deletion
- ✅ Color-coded messages (green=success, red=error)
- ✅ Count of deleted meals in success message
- ✅ Warning icon in confirmation dialog

### Safety Measures
- ✅ Confirmation dialog prevents accidental deletion
- ✅ Clear warning about irreversible action
- ✅ Red button color indicates danger
- ✅ Button only shows when meals exist

### User Experience
- ✅ Single click to delete all (after confirmation)
- ✅ Automatic data refresh
- ✅ Clear feedback messages
- ✅ Responsive UI updates

## Future Enhancements

### Potential Improvements
1. **Undo Functionality**
   - Store deleted meals temporarily
   - Allow undo within 5 seconds
   - Restore meals if undo clicked

2. **Bulk Delete Options**
   - Delete meals by type (e.g., all breakfast meals)
   - Delete meals by date range
   - Select specific meals to delete

3. **Confirmation Options**
   - "Don't ask again" checkbox
   - Settings to disable confirmation

4. **Performance Optimization**
   - Parallel deletion with `Future.wait()`
   - Backend endpoint for bulk delete
   - Optimistic UI updates

5. **Analytics**
   - Track deletion patterns
   - Show deletion history
   - Restore from history

## Code Structure

### Service Layer
```
lib/services/plan_service.dart
├── deleteMeal()           // Delete single meal
└── deleteAllMeals()       // Delete all meals (NEW)
    ├── getMeals()         // Fetch meals
    └── deleteMeal()       // Delete each meal
```

### UI Layer
```
lib/screens/pages/patients_page.dart
├── _buildMealsSection()
│   └── [Delete All Button]       // UI button (NEW)
├── _confirmDeleteAllMeals()       // Confirmation dialog (NEW)
└── _handleDeleteAllMeals()        // Delete handler (NEW)
    ├── PlanService.deleteAllMeals()
    └── _fetchPatients()           // Refresh data
```

## Summary

✅ **Added:** Delete all meals functionality
✅ **Added:** Confirmation dialog with warning
✅ **Added:** Loading indicator during deletion
✅ **Added:** Success/error feedback messages
✅ **Added:** Comprehensive debug logging
✅ **Added:** Proper error handling
✅ **Improved:** User safety with confirmation
✅ **Improved:** User experience with clear feedback

## Result

Users can now quickly delete all meals for a patient with:
- 🔴 One click on "Delete All" button
- ⚠️ Confirmation to prevent accidents
- ⏳ Loading feedback during operation
- ✅ Clear success/error messages
- 🔄 Automatic UI refresh

Perfect for:
- Correcting mistakes (wrong patient selected)
- Starting fresh meal plan
- Removing test data
- Quick cleanup operations


