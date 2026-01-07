# Apply Edit & Visual Features to Other Sections

## Overview
This guide shows how to apply the same edit functionality and visual improvements (type/category display with colors, icons, and edit buttons) to:
1. **Exercises Section**
2. **Supplements Section**
3. **Weight Targets Section**

## Already Implemented

### Helper Methods Added ✅
The following helper methods have been added to `patients_page.dart`:

#### Exercise Helpers
```dart
Color _getExerciseTypeColor(String? type)  // Returns color for exercise type
IconData _getExerciseTypeIcon(String? type) // Returns icon for exercise type
```

**Colors:**
- Cardio: 🔴 Red
- Strength: 🔵 Blue
- Flexibility: 🟣 Purple
- Balance: 🔷 Teal
- Walking: 🟢 Green
- Yoga: 🩷 Pink

#### Supplement Helpers
```dart
Color _getSupplementColor(String name)      // Returns color based on supplement name
IconData _getSupplementIcon(String name)    // Returns icon based on supplement name
```

**Colors (by name pattern):**
- Vitamin: 🟠 Orange
- Protein: 🔵 Blue
- Omega/Fish Oil: 🔷 Teal
- Calcium: 🟣 Purple
- Iron: 🔴 Red
- Magnesium: 🟢 Green
- Default: 🔷 Indigo

## Implementation Pattern

### Step 1: Update Section UI to Show Type/Category

For each section, follow the same pattern as meals. Here's the template:

#### Exercises Section Example

**Current** (without types shown):
```dart
Container(
  child: Row(
    children: [
      Icon(Icons.fitness_center),
      Text(exercise['name']),
      Text('${exercise['duration']} min'),
    ],
  ),
)
```

**Updated** (with type badge and colors):
```dart
Container(
  child: Row(
    children: [
      // Color bar (left)
      Container(
        width: 5,
        height: 60,
        decoration: BoxDecoration(
          color: _getExerciseTypeColor(exercise['type']),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      SizedBox(width: 14),
      
      // Icon with colored background
      Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _getExerciseTypeColor(exercise['type']).withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getExerciseTypeColor(exercise['type']).withOpacity(0.3),
          ),
        ),
        child: Icon(
          _getExerciseTypeIcon(exercise['type']),
          color: _getExerciseTypeColor(exercise['type']),
          size: 20,
        ),
      ),
      SizedBox(width: 14),
      
      // Exercise details
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exercise['name'],
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6),
            Row(
              children: [
                // Type badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _getExerciseTypeColor(exercise['type']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _getExerciseTypeColor(exercise['type']).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    Exercise.getExerciseTypeDisplay(exercise['type']),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getExerciseTypeColor(exercise['type']),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.access_time, size: 14),
                Text('${exercise['duration']} min'),
              ],
            ),
          ],
        ),
      ),
      
      // Duration/Calories badge
      Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text('${exercise['caloriesBurn']} cal'),
      ),
      SizedBox(width: 8),
      
      // Edit button
      IconButton(
        onPressed: () => _showEditExerciseDialog(exercise),
        icon: Icon(Icons.edit),
        color: AppColors.accent,
        iconSize: 20,
      ),
    ],
  ),
)
```

### Step 2: Add Edit Dialog

For each section, create an edit dialog method:

```dart
void _showEditExerciseDialog(Map<String, dynamic> exercise) {
  // Populate form with exercise data
  _exerciseNameController.text = exercise['name'] ?? '';
  _exerciseDurationController.text = exercise['duration']?.toString() ?? '';
  _exerciseCaloriesController.text = exercise['caloriesBurn']?.toString() ?? '';
  _exerciseInstructionsController.text = exercise['instructions'] ?? '';
  
  setState(() => selectedExerciseType = exercise['type']);

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        // ... similar structure to meal edit dialog
        child: Column(
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.accent, AppColors.accent.withOpacity(0.8)],
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.white),
                  Text('Edit Exercise', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            
            // Form fields
            _buildExerciseTypeDropdown(),
            _buildDialogTextField('Exercise Name', controller: _exerciseNameController),
            _buildDialogTextField('Duration (mins)', controller: _exerciseDurationController),
            // ... more fields
            
            // Buttons
            Row(
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _handleUpdateExercise(exercise);
                  },
                  child: Text('Update Exercise'),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
```

### Step 3: Add Update Handler

```dart
Future<void> _handleUpdateExercise(Map<String, dynamic> oldExercise) async {
  // Validation
  if (_exerciseNameController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please enter exercise name')),
    );
    return;
  }

  try {
    final patient = patients[selectedPatientIndex];
    final patientId = patient['patient_id'] ?? patient['id'];
    
    // Get exercise ID (you'll need to fetch this from API data)
    final exerciseId = oldExercise['id']?.toString();

    // Create exercise object
    final exercise = Exercise(
      exerciseName: _exerciseNameController.text.trim(),
      exerciseType: selectedExerciseType,
      durationMins: int.tryParse(_exerciseDurationController.text),
      caloriesBurn: int.tryParse(_exerciseCaloriesController.text),
      instructions: _exerciseInstructionsController.text.trim(),
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );

    // Call API
    final response = await PlanService.updateExercise(patientId, exerciseId, exercise);

    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exercise updated'), backgroundColor: Colors.green),
      );
      _fetchPatients(); // Refresh
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
    );
  }
}
```

## Quick Implementation Checklist

### For Exercises ✅
- [x] Helper methods added (_getExerciseTypeColor, _getExerciseTypeIcon)
- [ ] Update _buildExerciseSection to show type badges
- [ ] Add edit button to each exercise item
- [ ] Create _showEditExerciseDialog method
- [ ] Create _handleUpdateExercise method
- [ ] Fetch exercises data in _fetchPatients
- [ ] Update _mapPatientData to include exercises

### For Supplements ✅
- [x] Helper methods added (_getSupplementColor, _getSupplementIcon)
- [ ] Update _buildSupplementsSection to show frequency badges
- [ ] Add edit button to each supplement item
- [ ] Create _showEditSupplementDialog method
- [ ] Create _handleUpdateSupplement method
- [ ] Fetch supplements data in _fetchPatients
- [ ] Update _mapPatientData to include supplements

### For Weight Targets
- [ ] Add helper methods for weight progress visualization
- [ ] Update _buildWeightProgressCard to show current vs target
- [ ] Add edit button for weight target
- [ ] Create _showEditWeightTargetDialog method
- [ ] Create _handleUpdateWeightTarget method
- [ ] Fetch weight targets in _fetchPatients

## Data Fetching Pattern

Similar to meals, you need to fetch data for each section in `_fetchPatients()`:

```dart
Future<void> _fetchPatients() async {
  // ... existing code ...
  
  // After fetching patients
  await _fetchMealsForPatients(patientsData);
  await _fetchExercisesForPatients(patientsData);  // Add this
  await _fetchSupplementsForPatients(patientsData); // Add this
  await _fetchWeightTargetsForPatients(patientsData); // Add this
  
  setState(() {
    _apiPatients = patientsData.map((p) => _mapPatientData(p)).toList();
  });
}
```

### Example: Fetch Exercises

```dart
Map<String, List<dynamic>> _patientsExercisesData = {};

Future<void> _fetchExercisesForPatients(List<dynamic> patientsData) async {
  try {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    final exercisesFutures = patientsData.map((patient) async {
      final patientId = patient['patient_id']?.toString() ?? '';
      if (patientId.isEmpty) return;
      
      try {
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}${ApiEndpoints.patientExercises(patientId)}?date=$today'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${AuthService.token}',
          },
        );
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true && data['data'] != null) {
            _patientsExercisesData[patientId] = data['data'] as List<dynamic>;
          }
        }
      } catch (e) {
        debugPrint('Error fetching exercises for patient $patientId: $e');
      }
    }).toList();
    
    await Future.wait(exercisesFutures);
  } catch (e) {
    debugPrint('Error in _fetchExercisesForPatients: $e');
  }
}
```

### Update _mapPatientData

```dart
Map<String, dynamic> _mapPatientData(Map<String, dynamic> apiPatient) {
  final patientId = apiPatient['patient_id']?.toString() ?? '';
  
  // Get meals data (existing)
  final mealsToday = _patientsMealsData[patientId] ?? [];
  
  // Get exercises data (add this)
  final exercisesData = _patientsExercisesData[patientId] ?? [];
  final exercisesToday = exercisesData.map((exercise) {
    return {
      'id': exercise['id'],
      'name': exercise['exercise_name'],
      'type': exercise['exercise_type'],
      'duration': exercise['duration_mins'],
      'caloriesBurn': exercise['calories_burn'],
      'instructions': exercise['instructions'],
    };
  }).toList();
  
  // Get supplements data (add this)
  final supplementsData = _patientsSupplementsData[patientId] ?? [];
  final supplementsToday = supplementsData.map((supplement) {
    return {
      'id': supplement['id'],
      'name': supplement['supplement_name'],
      'dosage': supplement['dosage'],
      'frequency': supplement['frequency'],
      'instructions': supplement['instructions'],
    };
  }).toList();
  
  return {
    // ... existing fields ...
    'mealsToday': mealsToday,
    'exercisesToday': exercisesToday,      // Add this
    'supplementsToday': supplementsToday,  // Add this
  };
}
```

## Visual Examples

### Exercise Item (After Implementation)
```
🔴 🏃  Morning Run
       [Cardio] ⏰ 30 min        150 cal  ✏️

🔵 💪  Weight Training
       [Strength] ⏰ 45 min      200 cal  ✏️
```

### Supplement Item (After Implementation)
```
🟠 💧  Vitamin D3
       [Once Daily] 💊 500mg              ✏️

🔵 💪  Whey Protein
       [After Meals] 💊 25g               ✏️
```

### Weight Target (After Implementation)
```
⚖️ Weight Progress
   Current: 75 kg  →  Target: 70 kg
   Progress: -2 kg (40%)                  ✏️
```

## API Methods Needed

Make sure these methods exist in `plan_service.dart`:

```dart
// Exercises
static Future<ApiResponse<Exercise>> updateExercise(String patientId, String exerciseId, Exercise exercise)
static Future<ApiResponse<List<Exercise>>> getExercises(String patientId, {String? date})

// Supplements
static Future<ApiResponse<Supplement>> updateSupplement(String patientId, String supplementId, Supplement supplement)
static Future<ApiResponse<List<Supplement>>> getSupplements(String patientId)

// Weight Targets
static Future<ApiResponse<WeightTarget>> updateWeightTarget(String patientId, String targetId, WeightTarget target)
static Future<ApiResponse<WeightTarget>> getWeightTarget(String patientId)
```

## Summary

The same pattern used for meals can be applied to all other sections:

1. **Helper Methods** ✅ - Already added for colors and icons
2. **UI Updates** - Add type badges, colors, and edit buttons
3. **Edit Dialogs** - Create dialog with pre-filled data
4. **Update Handlers** - Handle API calls and refresh
5. **Data Fetching** - Fetch data in _fetchPatients
6. **Data Mapping** - Transform API data to UI format

### Key Benefits
- 🎨 Consistent visual design across all sections
- ✏️ Easy editing without delete/re-add
- 🏷️ Clear categorization with badges
- 🎯 Color-coded for quick identification
- 📱 Better UX throughout the app

### Files to Modify
1. `lib/screens/pages/patients_page.dart` - Main UI and logic
2. `lib/services/plan_service.dart` - API methods (if missing)
3. `lib/models/*.dart` - Ensure models support all fields

Would you like me to implement these features for a specific section (Exercises, Supplements, or Weight Targets) in detail?

