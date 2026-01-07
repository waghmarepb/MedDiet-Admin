class ApiEndpoints {
  // Auth & Profile
  static const String login = "/doctor/login";
  static const String profile = "/doctor/profile";
  
  // Patients
  static const String patients = "/doctor/patients";
  static const String patientDetails = "/doctor/patient"; // + /{id}
  static const String patientsStepsToday = "/doctor/patients/steps/today";
  static const String patientSteps = "/doctor/patient"; // + /{id}/steps
  
  // Plan Management - Meals
  // POST/GET: /doctor/patient/{id}/meals
  // PUT/DELETE: /doctor/patient/{id}/meals/{mealId}
  static String patientMeals(String patientId) => "/doctor/patient/$patientId/meals";
  static String patientMeal(String patientId, String mealId) => "/doctor/patient/$patientId/meals/$mealId";
  
  // Plan Management - Exercises
  // POST/GET: /doctor/patient/{id}/exercises
  // PUT/DELETE: /doctor/patient/{id}/exercises/{exerciseId}
  static String patientExercises(String patientId) => "/doctor/patient/$patientId/exercises";
  static String patientExercise(String patientId, String exerciseId) => "/doctor/patient/$patientId/exercises/$exerciseId";
  
  // Plan Management - Supplements
  // POST/GET: /doctor/patient/{id}/supplements
  // PUT/DELETE: /doctor/patient/{id}/supplements/{supplementId}
  static String patientSupplements(String patientId) => "/doctor/patient/$patientId/supplements";
  static String patientSupplement(String patientId, String supplementId) => "/doctor/patient/$patientId/supplements/$supplementId";
  
  // Plan Management - Weight Target
  // POST/GET: /doctor/patient/{id}/weight-target
  // PUT: /doctor/patient/{id}/weight-target/{targetId}
  static String patientWeightTarget(String patientId) => "/doctor/patient/$patientId/weight-target";
  static String patientWeightTargetUpdate(String patientId, String targetId) => "/doctor/patient/$patientId/weight-target/$targetId";
}

