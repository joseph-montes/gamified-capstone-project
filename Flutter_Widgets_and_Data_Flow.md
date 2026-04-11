# Flutter Widgets and Data Flow Documentation
**Project Name:** CodeQuest: Gamified Learning App

## 1. Key Flutter Widgets Used

### Structural & Layout Widgets
* **`Scaffold` & custom `GlassScaffold`:** Provides the main structure for all screens. `GlassScaffold` applies a modern, gradient-based background consistent throughout the app.
* **`Stack` & `Positioned`:** Used heavily in screens like `MainScreen` (for the bottom navigation bar hovering over content) and `ChallengeScreen` (for question cards stacked visually).
* **`ListView` & `SingleChildScrollView`:** Utilized to make content scrollable on devices of different sizes, preventing overflow errors. `LeaderboardPage` uses `ListView.builder` for efficient rendering of list items.
* **`GridView`:** Used in the `ProfilePage` to display the user's achievements and statistics in a neat, responsive grid format.
* **`Row`, `Column`, `Expanded`, `Flexible`:** Basic structural widgets used extensively for organizing components linearly.

### Interactive & UI Components
* **`GestureDetector` & `InkWell`:** Used to make custom UI components (like the Quick Action cards or achievement badges) tappable and interactive.
* **`TextFormField`:** Used in `LoginPage`, `RegisterPage`, and the Profile Edit dialog to collect user input securely.
* **`LinearPercentIndicator`:** (from the `percent_indicator` package) A visual widget used prominently in the `HomePage` and `ProfilePage` to display the user's XP progress toward the next level.
* **`BottomNavigationBar`:** Implemented within `MainScreen` to switch between core tabs (Home, Challenges, Leaderboard, Profile).
* **`AlertDialog` & `BottomSheet`:** Used for interactive prompts, such as the Logout confirmation dialog and the "Edit Profile" bottom sheet.

### Animation Widgets
* **`flutter_animate` package (`.animate()`, `.slide()`, `.fadeIn()`):** Used across the application to provide smooth entrance animations for cards, headers, and notification panels.

---

## 2. System Data Flow & State Management

The application utilizes **Provider** (`ChangeNotifier`) combined with **Firebase Firestore** for state management and data persistence.

### Architectural Layers
1. **Presentation Layer (UI/Widgets):** The screens the user interacts with (e.g., `HomePage`, `ProfilePage`).
2. **Business Logic Layer (Models):** Handled primarily by `UserModel` and `ChallengeModel`. These define the rules of the app (e.g., leveling up when XP reaches a threshold).
3. **Data/Service Layer (Services):** `DatabaseService` handles direct communication with Firebase (Authentication and Firestore operations).

### The Data Flow Cycle
The general data flow follows a **unidirectional pattern**:

1. **User Input (UI Action)** 
   ↓
2. **State/Model Update (Business Logic)** 
   ↓
3. **Backend Sync (Database Service)** 
   ↓
4. **Listeners Notified** 
   ↓
5. **UI Rebuilds**

**Example 1: Completing a Challenge (Awarding XP)**
1. **User Action:** The user selects the final correct answer inside `ChallengeScreen`.
2. **Logic Execution:** The UI calls `context.read<DatabaseService>().awardXP(...)`.
3. **Model Update:** `DatabaseService` calls `UserModel.addXP()`, which calculates if a level-up occurred.
4. **Backend Sync:** `DatabaseService` updates the user's Firestore document with the new XP and Level.
5. **UI Notification:** `UserModel` calls `notifyListeners()`.
6. **UI Rebuild:** The `HomePage` and `ProfilePage`, which are listening via `context.watch<UserModel>()`, rebuild to instantly show the newly animated progress bar and updated rank.

**Example 2: Theme Switching**
1. **User Action:** The user flips the switch on the `ProfilePage`.
2. **Logic Execution:** `ThemeService.toggleDarkMode()` is triggered.
3. **State Persistence:** The service saves the boolean value locally using `SharedPreferences`.
4. **UI Notification:** `ThemeService` (which extends `ChangeNotifier`) calls `notifyListeners()`.
5. **UI Rebuild:** The root `MaterialApp` inside `main.dart`, which is wrapped in a `Consumer<ThemeService>`, rebuilds the entire app with the new `ThemeData`.

**Example 3: Leaderboard Updates (Real-time Stream)**
Unlike standard localized data flow, the `LeaderboardPage` directly subscribes to a backend data stream.
1. `StreamBuilder` connects to `FirebaseFirestore.instance.collection('users').orderBy('level').snapshots()`.
2. Whenever any user levels up, Firestore emits a new snapshot.
3. The `StreamBuilder` triggers a localized UI rebuild of the leaderboard list, ensuring rankings are always live and accurate without manual refreshing.
