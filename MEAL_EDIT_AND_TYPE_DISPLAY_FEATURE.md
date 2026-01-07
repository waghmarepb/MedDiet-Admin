# Meal Edit and Type Display Feature

## Overview
Enhanced the meal management system with:
1. **Edit Meal Functionality** - Edit existing meals with a single click
2. **Meal Type Display** - Show meal type badges (Breakfast, Lunch, etc.) in the meal list
3. **Smart Dropdown** - Grey out already-added meal types to prevent duplicates

## Features Added

### 1. Meal Type Display in List

#### Visual Enhancements
Each meal item now displays:
- **Color-coded left border** - Different color for each meal type
- **Meal type icon** - Visual indicator (sun for breakfast, moon for dinner, etc.)
- **Meal type badge** - Labeled badge showing the meal type
- **Edit button** - Pencil icon to edit the meal

#### Meal Type Colors & Icons
| Meal Type | Color | Icon |
|-----------|-------|------|
| Breakfast | 🟠 Orange | ☀️ Sunny |
| Morning Snack | 🟢 Green | ☕ Coffee |
| Lunch | 🔵 Blue | 🍽️ Restaurant |
| Evening Snack | 🟣 Purple | ☕ Cafe |
| Dinner | 🔷 Indigo | 🌙 Dinner Dining |

#### Before vs After

**Before:**
```
🍽️ Milk
   ⏰ 08:00                      150 kcal
```

**After:**
```
🟠 ☀️ Milk
      [Breakfast] ⏰ 08:00       150 kcal  ✏️
```

### 2. Edit Meal Functionality

#### How It Works
1. Click the **edit icon (✏️)** on any meal
2. Dialog opens with pre-filled data
3. Modify any fields
4. Click "Update Meal"
5. Meal updates in real-time

#### Edit Dialog Features
- ✅ Pre-populated with existing meal data
- ✅ All fields editable (type, name, calories, time, macros, description)
- ✅ Validation before saving
- ✅ Loading indicator during update
- ✅ Success/error feedback
- ✅ Auto-refresh after update

### 3. Smart Meal Type Dropdown

#### Intelligent Selection
The dropdown now shows:
- **Available meal types** - Normal appearance
- **Already added types** - Greyed out with "Added" badge
- **Currently editing type** - Always available (not greyed out)

#### Visual Indicators

**Available Type:**
```
☀️ Breakfast
```

**Already Added Type:**
```
☀️ Breakfast [Added]  (greyed out)
```

**Benefits:**
- ✅ Prevents duplicate meal types
- ✅ Visual feedback on what's already added
- ✅ Can still edit existing meals of that type
- ✅ Better user experience

## Implementation Details

### New Helper Methods

#### 1. `_convertMealTypeToDisplay(String apiType)`
Converts API format to display format:
```dart
'breakfast' → 'Breakfast'
'mid_morning' → 'Morning Snack'
'lunch' → 'Lunch'
'evening_snack' → 'Evening Snack'
'dinner' → 'Dinner'
```

#### 2. `_getMealTypeColor(String apiType)`
Returns color for each meal type:
```dart
'breakfast' → Colors.orange
'lunch' → Colors.blue
'dinner' → Colors.indigo
```

#### 3. `_getMealTypeIcon(String apiType)`
Returns icon for each meal type:
```dart
'breakfast' → Icons.wb_sunny
'lunch' → Icons.restaurant
'dinner' → Icons.dinner_dining
```

#### 4. `_getUsedMealTypes()`
Returns set of already-added meal types:
```dart
Set<String> {'breakfast', 'lunch'}  // If these are already added
```

#### 5. `_showEditMealDialog(Map<String, dynamic> meal)`
Opens edit dialog with pre-filled meal data

#### 6. `_handleUpdateMeal(Map<String, dynamic> oldMeal)`
Handles the meal update process:
- Validates input
- Finds meal ID
- Calls update API
- Refreshes data

### Updated UI Components

#### Meal Item Layout
```
┌─────────────────────────────────────────────────┐
│ │ 🟠  Milk                     150 kcal  ✏️     │
│ │ ☀️  [Breakfast] ⏰ 08:00                       │
└─────────────────────────────────────────────────┘
```

Components:
1. **Color bar** (left) - Meal type color
2. **Icon** - Meal type icon with colored background
3. **Meal name** - Bold text
4. **Meal type badge** - Small colored badge
5. **Time** - With clock icon
6. **Calories** - Orange badge
7. **Edit button** - Pencil icon

#### Dropdown with Used Types
```
┌─────────────────────────────────┐
│ ☀️ Breakfast [Added]  (grey)    │
│ ☕ Morning Snack                 │
│ 🍽️ Lunch [Added]  (grey)        │
│ ☕ Evening Snack                 │
│ 🌙 Dinner                        │
└─────────────────────────────────┘
```

## User Flow

### Adding a Meal
1. Click "Add Meal"
2. Select meal type (already-added types shown in grey)
3. Fill in details
4. Submit
5. **New:** Meal appears with type badge and color

### Editing a Meal
1. **Click edit icon (✏️)** on any meal
2. Dialog opens with current data
3. Modify fields (can change type, name, calories, etc.)
4. Click "Update Meal"
5. Meal updates immediately
6. Success message shows

### Preventing Duplicates
1. Add "Breakfast" meal
2. Click "Add Meal" again
3. **"Breakfast" is now greyed out** in dropdown
4. Can still select other types
5. **Can edit existing breakfast** meal

## API Integration

### Update Meal Endpoint
```
PUT /doctor/patient/{patientId}/meals/{mealId}
```

**Request Body:**
```json
{
  "meal_type": "breakfast",
  "meal_name": "Oatmeal with fruits",
  "calories": 450,
  "protein": 15,
  "carbs": 60,
  "fats": 10,
  "time": "08:00",
  "date": "2026-01-06",
  "description": "Healthy breakfast"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Meal updated successfully",
  "data": { ... }
}
```

## Debug Logging

### Edit Meal Logs
```
🍽️ Preparing to update meal 13 for patient: PAT_F5856A2B
📝 Meal Type: breakfast
📝 Meal Name: Oatmeal with berries
📡 Calling PlanService.updateMeal...
[2026-01-06T17:45:00.000] Response status: 200
[2026-01-06T17:45:00.123] Response body: {"success":true,...}
✅ Meal updated successfully via API
🔄 Refreshing patient data...
```

### Used Meal Types Detection
```
📊 Used meal types: {breakfast, lunch}
```

## Error Handling

### Scenario 1: No Meal Type Selected
```
❌ Validation failed: No meal type selected
User sees: "Please select a meal type"
```

### Scenario 2: Empty Meal Name
```
❌ Validation failed: No meal name entered
User sees: "Please enter meal name"
```

### Scenario 3: Meal ID Not Found
```
❌ Could not find meal ID
User sees: "Error: Could not find meal to update"
```

### Scenario 4: API Error
```
❌ Failed to update meal: [error message]
User sees: Error message from API
```

## Testing Checklist

### ✅ Test Case 1: Display Meal Types
1. Add meals of different types
2. **Expected:** Each meal shows correct type badge and color

### ✅ Test Case 2: Edit Meal
1. Add a meal
2. Click edit icon
3. Modify name and calories
4. Save
5. **Expected:** Meal updates with new data

### ✅ Test Case 3: Change Meal Type
1. Add breakfast meal
2. Edit it and change type to lunch
3. **Expected:** Meal updates, breakfast slot becomes available

### ✅ Test Case 4: Grey Out Used Types
1. Add breakfast meal
2. Click "Add Meal"
3. **Expected:** Breakfast shown in grey with "Added" badge

### ✅ Test Case 5: Edit Used Type
1. Add breakfast meal
2. Click edit on breakfast meal
3. **Expected:** Breakfast still selectable in dropdown (not greyed)

### ✅ Test Case 6: Multiple Meals
1. Add breakfast, lunch, dinner
2. **Expected:** All three greyed out in add dialog
3. Edit lunch
4. **Expected:** Lunch available in edit dialog

## UI/UX Improvements

### Visual Hierarchy
- ✅ Color-coded meal types for quick identification
- ✅ Icons provide visual cues
- ✅ Badges clearly label meal types
- ✅ Edit button easily accessible

### User Guidance
- ✅ Grey out used types to prevent confusion
- ✅ "Added" badge explains why type is greyed
- ✅ Can still edit existing meals of that type
- ✅ Clear visual feedback on actions

### Consistency
- ✅ Same color scheme throughout
- ✅ Consistent icon usage
- ✅ Uniform badge styling
- ✅ Predictable behavior

## Code Structure

### Helper Methods
```
lib/screens/pages/patients_page.dart
├── _convertMealTypeToDisplay()    // API → Display name
├── _getMealTypeColor()            // Type → Color
├── _getMealTypeIcon()             // Type → Icon
├── _getUsedMealTypes()            // Get added types
├── _showEditMealDialog()          // Show edit dialog
└── _handleUpdateMeal()            // Handle update
```

### UI Components
```
_buildMealsSection()
└── meals.map()
    └── Container (Meal Item)
        ├── Color bar (left)
        ├── Icon (colored)
        ├── Meal details
        │   ├── Name
        │   ├── Type badge
        │   └── Time
        ├── Calories badge
        └── Edit button  ← NEW
```

### Dropdown Enhancement
```
_buildMealTypeDropdown()
├── Get used meal types
└── items.map()
    ├── Check if used
    ├── Grey out if used
    └── Add "Added" badge
```

## Summary

### What's New
✅ **Edit Meal Button** - Click pencil icon to edit any meal
✅ **Meal Type Badges** - Visual labels showing meal type
✅ **Color-Coded Meals** - Different colors for each type
✅ **Type Icons** - Visual indicators (sun, moon, etc.)
✅ **Smart Dropdown** - Grey out already-added types
✅ **"Added" Badges** - Show which types are used
✅ **Edit Dialog** - Pre-filled form for easy editing
✅ **Update API Integration** - Save changes to backend
✅ **Real-time Updates** - UI refreshes after edit

### Benefits
- 🎯 **Better Organization** - Easy to see meal types at a glance
- ✏️ **Quick Edits** - Fix mistakes without deleting and re-adding
- 🚫 **Prevent Duplicates** - Visual cues for already-added types
- 🎨 **Visual Appeal** - Color-coded, icon-rich interface
- 📱 **Better UX** - Intuitive and user-friendly

### User Experience
**Before:**
- No way to edit meals (had to delete and re-add)
- No indication of meal type in list
- Could accidentally add duplicate types
- Plain, text-only interface

**After:**
- ✏️ One-click editing
- 🏷️ Clear meal type labels
- 🚫 Visual prevention of duplicates
- 🎨 Beautiful, color-coded interface

Perfect for managing daily meal plans! 🎉

