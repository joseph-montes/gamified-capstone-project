# Documentation (UX Case Study)
**Design and Prototype of “CodeQuest”: An HCI-Based Approach to Gamified Learning**

---

## 1. Problem Definition
**Background**
Learning to code, particularly algorithms and concepts in languages like Python and Java, check can be difficult and overwhelming for many students. Often, the traditional curriculum feels disconnected from practical, engaging experiences. This leads to a loss of motivation and a high dropout rate in introductory programming classes.

**Problem Statement**
Students lack an engaging and motivating platform that encourages consistent practice of programming concepts, resulting in poor retention and frustration when learning to code.

**Why the problem is important**
Programming is an essential skill in modern education. If students disengage due to cognitive overload or lack of motivation, they fall behind in an increasingly digital world. Solving this problem with gamified elements ensures higher engagement and better learning outcomes.

**Target Users**
• First and second-year college students (Computer Science / IT)
• High school students exploring programming
• Educators and professors (Secondary users managing content)

---

## 2. User Research

### Persona 1: Identify your target users
**Name:** Maria Turing
**Age:** 19
**Role:** 1st Year IT Student
**Goals:**
• Understand Python and basic OOP concepts easily
• Keep track of her learning progress over time
**Pain Points:**
• Traditional textbooks make her lose focus instantly
• Forgets syntax frequently because it feels too abstract

### Persona 2:
**Name:** John Lovelace
**Age:** 20
**Role:** 2nd Year CS Student
**Goals:**
• Sharpen his skills in SQL and networking quickly
• Compete with friends to make learning fun
**Pain Points:**
• Finds standard quizzes boring and repetitive
• Struggles to stay consistent without daily motivation or rewards

**User Scenario**
Maria wants to prepare for her Python midterms. Instead of reading her textbook directly, she opens CodeQuest. She logs in to a warm, inviting interface, checks her "Novice Learner" rank, and taps "Start Challenge" on her daily challenge. The app rewards her with XP and coins, encouraging her to maintain her daily streak.

---

## 3. User Stories
1. **As a student**, I want to see my daily learning streak, **so that** I am motivated to return to the app every day.
2. **As a user**, I want to select challenges based on programming topics (Python, Java), **so that** I can focus on the subjects I need most help with.
3. **As a learner**, I want to earn XP and level up after completing quizzes, **so that** I feel a sense of accomplishment.
4. **As a student**, I want to toggle to a lighter, warm-colored theme, **so that** I can read content clearly without straining my eyes in bright environments.
5. **As a user**, I want to view a leaderboard, **so that** I can see how I rank against my classmates.

---

## 4. Design Process

**Low-Fidelity Sketches**
• Initial mockups included basic lists of quizzes and a standard user profile text view.

**Transition to High-Fidelity Design**
• The design evolved into a highly interactive "Glassmorphism" interface.
• Complex data was visualised into easy-to-read elements like the `LinearPercentIndicator` for XP tracking and circular avatars.

**Design Decisions (HCI Principles)**
• **Warm & High Contrast Colors:** Addressed legibility in light mode by using warm cream backgrounds (`#FAF8F5`) and deep charcoal text (`#2C241E`, `Colors.black87`).
• **Chunking:** Broke down the learning material into 5-question bites to prevent cognitive overload.

---

## 5. Figma Prototype Description (Mapped to Live App Flow)
**Overview of System:** A gamified learning platform using Flutter.

**Key Features:**
1. **Home Dashboard:** Daily challenge, quick actions, streak tracking.
2. **Challenges Screen:** Filter quizzes by difficulty or language (Python, Java, SQL).
3. **Interactive Quiz:** Code snippets, terminal-style questions, immediate feedback.
4. **Profile Page:** XP tracking, unlocked badge showcase, theme toggling.

**User Flow:**
Login → Home Dashboard → Select "View Challenges" → Choose "Python Fundamentals" → Complete 5 Questions → Review Correct Answers → Receive XP/Coins → Level Up → Check Leaderboard.

---

## 6. Application of HCI Principles/Evaluations

**Usability Evaluation & Interaction Design Principles:**
• **Visibility of System Status:** The user always sees their current Level and XP progress clearly on the Home and Profile screens.
• **Aesthetic and Minimalist Design:** The "Glassmorphism" UI is visually appealing but avoids cluttering the screen with unnecessary text.
• **Error Prevention & Recovery:** Interactive forms (like the Edit Profile sheet) use dropdowns to prevent spelling errors in "Year Level", and social login gives clear animated feedback (shake effect) when incorrect.

---

## 7. Accessibility Considerations
• **Readable Typography & Contrast:** Light mode was strictly evaluated to ensure high contrast. Pale grey text (`Colors.black38`) was replaced with high-opacity dark brown/black (`Colors.black87`) to ensure readability against warm backgrounds.
• **Color Contrast:** Badges and difficulty chips are colored specifically (Green for Easy, Yellow for Medium, Red for Hard) accompanied by universal icons (signal bars) so colorblind users can still understand the difficulty.
• **Touch Targets:** All buttons (e.g., Quick Actions, Start Challenge) have large bounding boxes optimized for thumb-reachability on mobile.

---

## 8. Ethical Design Considerations
• **Data Privacy:** CodeQuest collects minimal user data (Name, Email, Year Level) which is directly related to university context. 
• **Transparency:** Achievements are earned sequentially without hidden algorithms, and XP formulas are completely transparent (Level * 100).
• **Avoidance of Dark Patterns:** The app does not utilize manipulative countdown timers that force users into purchasing or trick them into staying online unnecessarily. It uses positive reinforcement (Daily Streaks).

---

## 9. Evaluation Plan
**Method:** Moderated Usability Testing with 5-7 college students.
**Tasks:**
1. Update your student ID and Year Level in the profile.
2. Locate a Medium difficulty SQL challenge and complete it.
3. Toggle between Dark Mode and Light Mode.
**Metrics for Success:**
• Task completion rate > 90%
• Average Time on Task (should be under 2 minutes per quiz)
• User satisfaction rating via System Usability Scale (SUS) targeting a score > 80.
