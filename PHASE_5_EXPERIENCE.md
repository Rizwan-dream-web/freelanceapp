# Phase 5: Experience & Polish - "The Premium Shift"

This phase focuses exclusively on user experience (UX), emotional design, and differentiation. We are moving beyond "features" to "feelings" — creating an app that feels like a calm, intelligent partner.

## 1. 🧘 Experience Modes (Dashboard Transformation)
Transform the Dashboard from a static list into a context-aware workspace.
- **Concept**: User selects their current "Mental State".
- **Modes**:
    - **Focus Mode**: Zero clutter. Shows *only* the active timer, current project, and immediate next task. Hides financials ($) to reduce anxiety during work hours.
    - **Business Mode (Default)**: The current "Command Center". Balanced view of pipeline, active work, and health.
    - **Review Mode**: Retrospective view. Highlights completed tasks, income realized, and weekly progress charts. Best for Friday afternoons.
- **Implementation**:
    - Add `dashboardMode` to Settings/Hive.
    - Create a sleek, pill-shaped mode switcher on the Dashboard AppBar.
    - Animated transitions between layouts (using `AnimatedSwitcher`).

## 2. 📜 Project Story Timeline
A narrative view of a project's lifecycle to show progress and momentum.
- **Concept**: Instead of just lists, show the "Story" of a client relationship.
- **Entities Linked**: `Proposal (Accepted)` -> `Project (Created)` -> `Milestone (Reached)` -> `Invoice (Sent)` -> `Payment (Received)`.
- **UI**: Vertical step-timeline with connecting lines, dates, and status icons.
- **Location**: Inside `Project Details` and `Client Details`.

## 3. 🧠 Guided Weekly Review
A calm, guided flow to close out the week.
- **Concept**: A "Story" style interface (like Instagram stories) that summarizes the week.
- **Slides**:
    1.  **Effort**: "You tracked 32 hours this week." (Chart)
    2.  **Focus**: "Most time spent on [Project Name]."
    3.  **Finance**: "$1,200 invoiced, $800 collected."
    4.  **Closure**: "Ready to archive 3 completed tasks?"
- **Trigger**: Button in "Review Mode" or automatic prompt on Friday evenings.

## 4. 🎛️ Dashboard Personalization
Give users control over their workspace.
- **Capabilities**:
    - **Toggle Visibility**: Hide "Financial Snapshot" or "Time Burn" if not relevant.
    - **Reorder**: (Stretch goal) Drag and drop widgets.
- **Implementation**: A "Customize Dashboard" bottom sheet with simple switches.

## 5. 🛡️ Trust & Transparency Center
Reinforce the "Offline-First" and "Secure" nature of the app.
- **UI**: A dedicated, beautifully designed screen in Settings.
- **Visuals**:
    - "Data Health Status" (Green check).
    - "Encryption Shield" animation.
    - "Last Backup" timestamp with a visual timeline.
    - "Device Storage" usage visualizer.

## 6. ✨ Meaningful Micro-Interactions
Feedback that feels physical and satisfying.
- **Interactions**:
    - **Task Completion**: Not just a check, but a subtle strikethrough animation + haptic 'thud'.
    - **Timer Start**: A "breathing" glow effect around the active timer.
    - **Navigation**: Smooth hero transitions between cards and detail views (already partially planned).

---

## Execution Plan
**Step 1: Experience Modes (High Impact)**
- Create the data model for `DashboardMode`.
- Implement the Mode Switcher UI.
- Refactor `DashboardScreen` to conditionally render widgets based on mode.

**Step 2: Dashboard Customization**
- Implement the "Customize" sheet to toggle widget visibility.
- Persist preferences in Hive.

**Step 3: The "Project Story" View**
- Build the `TimelineWidget`.
- Integrate into Project/Client screens.

**Step 4: Trust & Polish**
- Build the Data Health screen.
- Audit and refine all animations/haptics.
