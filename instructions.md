# LEON --- Product, UX/UI & Development Instructions

**Purpose:** A practical, research-informed product and implementation
guide for building LEON, a strength-training and gym companion app.

**Product principle:** Make workout tracking fast enough to use between
sets, make progress understandable, and help users make better training
decisions without adding distraction or unsupported fitness claims.

------------------------------------------------------------------------

## 1. Product vision and design principles

LEON should help users:

1.  Plan or select a workout.
2.  Log exercises, sets, reps, weight and relevant notes with minimal
    friction.
3.  Use previous performance as a reference during training.
4.  Understand progress over time.
5.  Maintain consistency without shame-based engagement mechanics.
6.  Review recovery and training balance as useful context, not as a
    medical diagnosis.
7.  Control their own goals, reminders and data.

### Core product principles

-   **Workout-first:** During an active session, workout controls take
    priority over charts, feeds, social features and decorative content.
-   **Low-friction logging:** The common action should be possible in as
    few clear interactions as practical. Do not optimize for a
    theoretical minimum tap count at the expense of errors or clarity.
-   **Useful feedback:** Show what a recorded result means and what the
    user can do next. Avoid dashboards that only display numbers.
-   **Progressive disclosure:** Show essential information first and
    advanced detail on demand.
-   **Consistency over punishment:** Encourage sustainable habits. Do
    not shame users for missed sessions or make a single missed day feel
    like failure.
-   **Transparent recommendations:** Explain the basis of suggestions.
    Distinguish logged facts, calculations, estimates and AI-generated
    suggestions.
-   **Accessible by default:** Readable type, sufficient contrast, large
    touch targets and clear states are functional requirements.
-   **User control:** Users should be able to edit records, change
    goals, manage reminders and understand how data is used.
-   **Evidence-informed, not evidence-overstated:** General
    physical-activity and health-app research provides hypotheses. Test
    decisions with strength-training users before treating them as
    proven for LEON.

------------------------------------------------------------------------

## 2. Target users and jobs to be done

Design around real user tasks rather than a list of features.

### Primary jobs

-   "Help me start today's workout quickly."
-   "Remind me what I lifted last time."
-   "Let me log a set without interrupting my training."
-   "Help me see whether my performance is improving."
-   "Help me organize a routine and replace an exercise if equipment is
    unavailable."
-   "Show me my training consistency without making me feel bad when
    life gets in the way."
-   "Help me understand trends without pretending the app can diagnose
    my recovery or health."

### User contexts to consider

-   The user may have one hand available, be holding a phone near gym
    equipment, or be tired between sets.
-   The gym may have poor connectivity. Critical logging flows should
    not depend on a live network connection.
-   Users have different levels of training experience, exercise
    knowledge, goals and preferred units.
-   Users may enter a set incorrectly and need a quick, safe way to
    correct it.
-   Users may skip, reorder or substitute exercises during a real
    workout.
-   Some users want detailed analytics; others only want to log and
    leave. Do not force everyone through the same depth of information.

### Research questions to validate with users

-   Which workout information do users need to see without leaving the
    active session?
-   How do they currently remember weights and reps?
-   Which actions cause the most interruptions?
-   What information makes a progress chart understandable?
-   Which notifications are useful, and which feel intrusive?
-   How do users handle missed sessions, substitutions and incomplete
    workouts?

------------------------------------------------------------------------

## 3. Information architecture and navigation

Keep the main navigation small and based on stable user goals. A
possible structure is:

1.  **Home / Dashboard** --- next workout, resume action, weekly
    activity and one useful insight.
2.  **Workouts** --- routines, workout builder, exercise library and
    workout history.
3.  **Analytics / Progress** --- exercise trends, volume, consistency
    and personal records.
4.  **Recovery** --- optional self-reported readiness and recovery
    context, with transparent limitations.
5.  **Profile / Settings** --- goals, units, preferences, reminders,
    privacy and account controls.

Adapt this to the existing application rather than introducing duplicate
navigation or parallel architectures. Active workout mode should have a
clear, focused experience and a dependable way to return to the session.

### Navigation rules

-   Use familiar labels. Avoid ambiguous icon-only navigation unless the
    icon is widely understood and an accessible label is provided.
-   Keep the user's active workout state available when navigating to a
    needed reference screen.
-   Warn before destructive actions, such as deleting a routine or
    discarding an unfinished session.
-   Do not ask for confirmation for every harmless action. Use undo
    where it is more efficient.
-   Make the current location and selected state visible.
-   Preserve draft work when the user navigates away or the app is
    interrupted.

------------------------------------------------------------------------

## 4. Key user flows

### A. First launch and onboarding

1.  Explain LEON's main value in a concise, skippable introduction.
2.  Collect only information necessary to personalize the experience:
    for example, training goal, experience level, preferred units and
    optional schedule.
3.  Ask for notification permission only when the user is setting up a
    reminder or when the benefit is clear.
4.  Let users start with a template or create a routine.
5.  Make it clear which details are optional and allow changes later.
6.  Avoid a long onboarding questionnaire before the user has
    experienced the core value.

**Success criteria:** A new user can reach a useful workout or routine
without unnecessary setup, and understands how to begin logging.

### B. Start or resume a workout

1.  Dashboard shows a clear primary action: start the planned workout or
    resume an active session.
2.  Show the routine name and a short preview of its exercises.
3.  Allow the user to start without making them inspect every exercise
    first.
4.  Restore an unfinished session after app closure or interruption.
5.  Clearly distinguish a planned workout from a session already in
    progress.

### C. Active workout and set logging

1.  Show the current exercise and a concise exercise description.
2.  Display the previous session's relevant performance when available.
3.  Present set number, weight, reps and completion status clearly.
4.  Make the primary action obvious, such as "Complete set".
5.  After completion, update the set state and offer the rest timer if
    enabled.
6.  Make editing or undoing a mistaken entry easy.
7.  Support skipping, reordering or substituting exercises without
    losing completed data.
8.  Save changes locally immediately; synchronize when possible.
9.  Make session completion explicit and summarize what was logged.

**Critical rule:** Never silently discard a completed set. Protect data
when the app backgrounds, crashes or loses connectivity.

### D. Rest timer

-   Offer a visible countdown, pause/resume and skip controls.
-   Allow the user to adjust the duration without navigating through a
    deep settings flow.
-   Do not make sound or vibration mandatory.
-   Respect device notification and sound preferences.
-   Avoid obstructing set logging or other controls while the timer
    runs.
-   Test timer behavior when the app is backgrounded or the device is
    locked.

### E. Workout builder

-   Let users add, remove and reorder exercises.
-   Make exercise search tolerant of common terms.
-   Provide filters such as muscle group and equipment where useful.
-   Show enough information to distinguish similarly named exercises.
-   Support substitutions and preserve the history of the original
    exercise.
-   Validate incomplete or nonsensical entries without making the form
    frustrating.
-   Offer sensible templates, but never trap users in them.

### F. Finish workout

1.  Show a concise summary: completed exercises and sets, duration if
    reliably tracked, and relevant performance highlights.
2.  Distinguish completed work from skipped or unfinished exercises.
3.  Offer an optional note or perceived-effort entry if it adds value.
4.  Avoid exaggerated claims such as "you gained muscle today."
5.  Save the session before showing success.
6.  Let users edit the session afterward.

### G. Review progress

1.  Start with a plain-language summary of a meaningful trend.
2.  Let users inspect the supporting exercise or metric history.
3.  Label chart units, time ranges and calculation methods.
4.  Explain missing data or changes in measurement.
5.  Avoid suggesting that one unusually good or bad session defines a
    trend.
6.  Do not imply causation from simple correlations.

### H. Recovery and reminders

-   Treat recovery data as optional context, especially if based on
    self-report.
-   Explain what a recovery indicator is based on and what it cannot
    tell the user.
-   Avoid presenting readiness scores as medical facts.
-   Let users choose reminder timing, frequency and categories.
-   Make pausing or disabling reminders easy.
-   Use supportive language. Never shame or threaten users over missed
    sessions.

------------------------------------------------------------------------

## 5. UI design guidelines

### Visual hierarchy

For every screen, define one primary user task and make its main action
visually obvious.

-   Use size, spacing, weight and contrast to establish hierarchy.
-   Keep important workout values more prominent than decorative labels.
-   Use consistent alignment and spacing.
-   Group related data together.
-   Do not make every card, badge or statistic equally prominent.
-   Keep decoration subordinate to information and actions.

### Active workout screen

Prioritize this screen above most other visual work because it is used
repeatedly during exercise.

**Suggested order of importance:**

1.  Exercise name and current position in the workout.
2.  Previous performance reference, if available.
3.  Current set inputs: weight and reps.
4.  Set list and completion state.
5.  Primary set-completion action.
6.  Rest timer and its controls.
7.  Secondary actions: notes, substitution, reorder, skip or exercise
    details.

Use large, readable numbers for weight, reps and timer values. Inputs
should be easy to focus, edit and clear. Avoid tiny steppers as the only
input method; provide a practical way to type values. Prevent accidental
duplicate set completion and show clear confirmation of the resulting
state.

### Dashboard

-   Make "Start workout" or "Resume workout" the primary action when
    appropriate.
-   Show the next planned workout if the user has a plan.
-   Show a compact weekly consistency summary.
-   Include one useful, explainable insight rather than a wall of
    metrics.
-   Keep recent activity accessible without letting history overwhelm
    the next action.
-   Personalize content based on user goals and activity, but avoid
    empty personalized sections when data is unavailable.
-   Provide a useful first-run or empty state with a clear next step.

### Progress charts

-   Choose a chart because it answers a question, not because it looks
    sophisticated.
-   Use line charts for trends over time and bars for discrete
    comparisons when appropriate.
-   Label axes, units and selected periods.
-   Avoid truncated axes that exaggerate small changes without making
    the scale clear.
-   Distinguish weight, reps, estimated strength and volume; do not
    combine incompatible units.
-   Explain calculations. For example, if volume is calculated as sets ×
    reps × load, state that definition.
-   Allow users to inspect the underlying sessions.
-   Provide a textual summary or accessible alternative to color-only
    interpretation.
-   Handle sparse history honestly. Do not invent trends when there is
    insufficient data.

### Exercise library

Each exercise entry should provide, where available:

-   Exercise name and any useful alternate name.
-   Targeted muscle group(s).
-   Equipment.
-   Instructions and a demonstration or illustration.
-   Relevant technique or safety notes.
-   A way to add the exercise to a routine or current session.

Do not imply that a simple muscle-group label fully describes an
exercise's biomechanics. Use consistent terminology and review exercise
content for accuracy.

### Components and consistency

Create reusable components for repeated patterns such as:

-   Cards and section headers.
-   Buttons and icon buttons.
-   Set rows and input fields.
-   Exercise list items.
-   Timer controls.
-   Progress indicators and charts.
-   Empty, loading, error and offline states.
-   Dialogs, snackbars and confirmation/undo patterns.

Use design tokens for color, typography, spacing, radius, elevation and
motion. Avoid one-off styling that causes the same component to behave
or look differently across features.

### Dark theme and visual style

LEON has an existing Material 3 dark-theme direction and reusable visual
components. Preserve that direction unless research or user testing
identifies a concrete problem.

-   Use dark surfaces with clearly differentiated elevation levels.
-   Reserve bright accent colors for primary actions, important state
    and selected data.
-   Maintain readable contrast for text, disabled controls and chart
    labels.
-   Do not use color alone to communicate completed, failed, selected or
    warning states.
-   Use glass effects, blur, glow and shadows sparingly. They should
    never reduce text clarity or action discoverability.
-   Use animation to communicate state changes, not as decoration that
    delays a workout.
-   Test the actual interface in bright gym lighting and at different
    screen sizes.

### Typography and spacing

-   Establish a small, consistent type scale for page titles, section
    headings, body text, labels and metrics.
-   Use tabular numerals for changing numeric values where practical.
-   Avoid tiny secondary labels for information needed during a workout.
-   Respect system text scaling.
-   Give controls enough spacing to reduce accidental taps.
-   Keep touch targets comfortably usable; aim for at least
    approximately 48 dp for common interactive targets where feasible.

### Interaction feedback

Every important action should have a clear result.

-   Show a visible state change when a set is logged.
-   Provide progress or loading feedback for longer operations.
-   Explain why an action cannot proceed and how to fix the issue.
-   Use undo for reversible mistakes when possible.
-   Avoid success animations that block the next action.
-   Do not use vague errors such as "Something went wrong" when a
    specific explanation is possible.

------------------------------------------------------------------------

## 6. Accessibility and inclusive design

Treat accessibility as part of core functionality, not a later polish
task.

-   Maintain sufficient contrast for text, icons, chart labels and
    interactive states.
-   Support text scaling without clipping essential controls.
-   Add semantic labels to icon-only buttons and meaningful labels to
    inputs.
-   Ensure screen-reader order follows the visual and task order.
-   Do not communicate status using color alone; combine color with
    text, icons or shape.
-   Respect reduced-motion preferences where supported.
-   Ensure focus and selected states are visible.
-   Provide alternatives to gestures that require precision.
-   Test with TalkBack on Android and VoiceOver on iOS as the project
    expands.
-   Check keyboard navigation where applicable.
-   Use plain language and avoid unexplained training jargon.

------------------------------------------------------------------------

## 7. Research evidence and what can reasonably be concluded

The following research themes informed this guide. Evidence from general
physical-activity and mobile-health apps is useful, but it should not
automatically be treated as proof for every strength-training
interaction.

### Self-monitoring and behavior-change techniques

A 2022 systematic review of smartphone interventions targeting physical
activity and sedentary behavior reported frequent use of
self-monitoring, feedback and goal-setting techniques. In the reviewed
interventions, self-monitoring appeared in all 19, feedback in 16 and
goal-setting in 12.

**Design implications:** Make logging dependable, let users set
meaningful goals, and connect records to useful feedback. These findings
show how commonly techniques were used, not that every technique
independently caused better outcomes.

Reference: *Behaviour change techniques in cardiovascular disease
smartphone apps to improve physical activity and sedentary behaviour*
(2022).\
https://pmc.ncbi.nlm.nih.gov/articles/PMC9261070/

### Feedback and presentation

A 2024 systematic review examined how feedback generation and
presentation related to self-monitoring behaviors and health-related
behaviors across 19 studies involving 3,261 participants.

**Design implications:** Test the timing, relevance and presentation of
feedback. A personalized explanation may be more useful than a raw
metric, but LEON should validate this with its own users.

Reference: *Impact of feedback generation and presentation on
self-monitoring behaviors, dietary intake, physical activity, and
weight* (2024).\
https://link.springer.com/article/10.1186/s12966-023-01555-6

### Mobile health usability

A systematic literature review of usability heuristics for mobile health
applications provides a foundation for evaluating consistency, feedback,
error prevention and other usability concerns.

**Design implications:** Use structured usability reviews and task-based
testing. For LEON, directly test the time and error rate involved in
logging a set, correcting a mistake and finding previous performance.

Reference: *Heuristics used for evaluating the usability of mobile
health applications: A systematic literature review* (2024).\
https://journals.sagepub.com/doi/10.1177/20552076241253539

### Gamification

A 2024 meta-analysis of digital health apps with or without gamification
included 36 trials, 49 comparisons and 10,079 participants. It reported
an average increase of 489 steps per day for gamified interventions
compared with non-gamified interventions, alongside small improvements
in some weight-related outcomes.

**Design implications:** Experiment with milestones, consistency
feedback and meaningful personal records. Do not assume the same effect
size or outcome will occur in strength training. Avoid shame-based
streaks and rewards that encourage unsafe training.

Reference: *Effect of digital health applications with or without
gamification on physical activity and cardiometabolic risk factors*
(2024).\
https://pmc.ncbi.nlm.nih.gov/articles/PMC11701442/

### Engagement and behavior-change techniques

A 2023 systematic review of 28 studies examined associations between
behavior-change techniques and mobile-health app engagement.
Goal-setting, self-monitoring, feedback, prompts or cues, rewards and
social support were among the techniques repeatedly associated with
engagement; the evidence did not establish precise relationships with
every engagement measure.

**Design implications:** Use opt-in reminders and relevant feedback, and
evaluate actual repeat use. Do not assume that adding a badge, streak or
notification will automatically improve retention.

Reference: *Potential associations between behavior change techniques
and engagement with mobile health apps: a systematic review* (2023).\
https://www.frontiersin.org/journals/psychology/articles/10.3389/fpsyg.2023.1227443/full

### Exercise prescription and progression

Research evaluating exercise-prescription apps against established
exercise-programming frameworks highlights dimensions such as frequency,
intensity, time, type, volume and progression (FITT-VP).

**Design implications:** Keep exercise instructions, routine structure,
history and progression connected. Treat the research as a guide to
content completeness and program structure, not as validation of any
particular LEON recommendation.

Reference: *Clinical Usability of Exercise Prescription Apps for
Professional Use: Systematic Review and Multidimensional Evaluation*
(2026).\
https://pmc.ncbi.nlm.nih.gov/articles/PMC13015917/

### Evidence limitations

-   Study populations and interventions vary.
-   General physical-activity research may not represent experienced
    lifters or gym-floor conditions.
-   Associations do not necessarily demonstrate causation.
-   A usability heuristic is not a substitute for testing with real
    users.
-   Recheck the original papers before using exact statistics in public
    claims, academic writing or a formal product report.

------------------------------------------------------------------------

## 8. User research and usability testing plan

Research should resolve product decisions, not merely validate choices
already made.

### Discovery interviews

Recruit approximately 5--8 people with varied gym experience for an
initial qualitative round. This is a practical exploratory sample, not a
statistically representative sample.

Ask about recent real behavior:

-   "Walk me through your last workout."
-   "How did you decide which weight and reps to use?"
-   "How do you remember your previous performance?"
-   "Tell me about the last time you forgot to log a set."
-   "What makes you stop using a fitness app?"
-   "When do workout reminders help, and when are they annoying?"
-   "What do you wish you could find more quickly during a workout?"

Avoid leading questions such as "Wouldn't a progress chart be useful?"
Ask about concrete past experiences rather than relying only on
hypothetical preferences.

### Prototype usability test

Test the same tasks with approximately 5--8 participants in an initial
round:

1.  Find and start a planned workout.
2.  Log a set with a specified weight and rep count.
3.  Complete several sets and use the rest timer.
4.  Correct a deliberately entered mistake.
5.  Substitute an unavailable exercise.
6.  Find the previous performance for an exercise.
7.  Interpret a progress chart.
8.  Finish a workout and find its summary.

Ask participants to think aloud where appropriate, but do not coach them
through the interface. Record where they hesitate, misunderstand labels,
make errors or try to tap something that is not interactive.

### Metrics

Track:

-   Task completion rate.
-   Time to complete key tasks.
-   Taps or actions required for common tasks.
-   Incorrect entries and correction success.
-   Abandonment and points of hesitation.
-   Whether users correctly interpret progress and status.
-   Perceived ease and confidence.
-   System Usability Scale (SUS) score, if administered and scored
    consistently.

Do not rely on a single score. Pair quantitative observations with notes
about why a task was difficult.

### Iteration loop

1.  State a specific hypothesis.
2.  Build the smallest prototype that tests it.
3.  Test with users performing realistic tasks.
4.  Record observations and metrics.
5.  Fix high-severity issues first.
6.  Retest the changed flow.
7.  Keep a short decision log explaining what changed and why.

Example hypothesis: "Showing the last logged weight and reps beside the
current set will reduce the time required to enter a set without
increasing errors."

------------------------------------------------------------------------

## 9. Product analytics and success metrics

Instrument only events that help answer product questions. Respect user
consent and privacy requirements.

Potential events:

-   `onboarding_completed`
-   `workout_started`
-   `workout_resumed`
-   `set_logged`
-   `set_edited`
-   `set_undone`
-   `exercise_skipped`
-   `exercise_substituted`
-   `rest_timer_started`
-   `workout_completed`
-   `progress_viewed`
-   `reminder_changed`

Avoid logging unnecessary sensitive free text or more personal data than
needed.

### Useful product measures

-   **Activation:** proportion of new users who complete their first
    meaningful workout logging task.
-   **Logging reliability:** proportion of set entries saved correctly.
-   **Workflow efficiency:** median time and action count to log a set.
-   **Recovery from errors:** proportion of mistakes corrected
    successfully.
-   **Repeat use:** users returning to log another workout over a
    defined period.
-   **Feature usefulness:** whether users who view an insight understand
    it and find it actionable.
-   **Notification quality:** opt-outs, dismissals and user-reported
    usefulness, not just notification opens.

Define each metric precisely before comparing versions. Do not optimize
solely for session length or notification clicks; a good workout tracker
may help users finish the task and put their phone away.

------------------------------------------------------------------------

## 10. Data integrity, offline-first behavior and states

Workout data is important to users. Losing it undermines trust.

### Offline-first requirements

-   Save set entries locally before depending on network
    synchronization.
-   Show a clear saved, syncing, offline or failed state when relevant.
-   Queue changes for synchronization when connectivity returns.
-   Avoid creating duplicate workouts or sets after retries.
-   Define conflict behavior for edits made on multiple devices.
-   Keep timestamps and ordering consistent.
-   Preserve unfinished sessions after app restarts.
-   Make sync failures recoverable and understandable.
-   Do not report a remote sync as successful until it actually
    succeeds.

### Essential UI states

Every major feature should be designed for:

-   Initial loading.
-   Normal populated state.
-   Empty state.
-   Offline state.
-   Saving or syncing state.
-   Recoverable error.
-   Validation error.
-   Permission denied.
-   Partial or incomplete data.
-   Destructive-action confirmation.
-   Successful completion.

A chart with no history should explain how to create history. An
exercise search with no results should offer ways to adjust the query or
filters. An offline indicator should tell users whether their workout is
safely saved locally.

------------------------------------------------------------------------

## 11. Fitness data and recommendation safety

LEON may present training analytics or AI-assisted suggestions. Make
their limits clear.

-   Do not present general wellness calculations as medical diagnoses.
-   Do not claim to know a user's injury status, exact recovery capacity
    or muscle growth from incomplete data.
-   Label estimates and explain the inputs behind them.
-   Avoid automatically increasing training load based on a single
    session.
-   Let users inspect, dismiss or override suggestions.
-   Provide neutral language when data is insufficient.
-   Encourage users to seek a qualified professional for pain, injury
    concerns or medical questions instead of trying to diagnose them.
-   Treat AI-generated advice as a suggestion that requires validation,
    not an authoritative instruction.
-   Do not let a recommendation silently alter a user's saved plan.

------------------------------------------------------------------------

## 12. Flutter implementation guidance

This section is aligned with LEON's existing project direction.
**Preserve the current architecture and inspect the repository before
moving files or introducing a new state-management or routing
approach.**

### Known stack and project direction

-   Flutter and Dart.
-   Riverpod for state management.
-   GoRouter for navigation.
-   Freezed and JsonSerializable for immutable models and serialization.
-   Hive for local persistence.
-   Supabase/PostgreSQL planned or used for backend and synchronization.
-   Material 3 dark theme.
-   `fl_chart` for analytics where appropriate.
-   Existing reusable UI patterns include `GlassCard`, `LeonButton` and
    loading indicators.

Verify the current repository and package versions before implementing.
Do not assume every planned service is fully integrated.

### Architecture principles

-   Keep features modular and responsibilities clear.
-   Separate presentation, state/business logic, data access and domain
    models.
-   Reuse existing providers, services and widgets where they fit.
-   Keep widgets focused on rendering and user interaction; avoid
    embedding complex business logic in large build methods.
-   Use immutable models and consistent serialization.
-   Keep navigation decisions in the existing router structure.
-   Avoid duplicate sources of truth for active workout state.
-   Define clear interfaces for repositories and persistence.
-   Use dependency injection through the project's established Riverpod
    patterns.
-   Keep platform-specific behavior isolated where practical.

### State management

Represent meaningful states explicitly, such as loading, data, empty and
error. Avoid contradictory booleans such as `isLoading`, `hasError` and
`isComplete` being true simultaneously without a defined state model.

For active workouts:

-   Maintain a single authoritative session state.
-   Update the interface immediately when a set is logged.
-   Persist important mutations locally.
-   Ensure edits, undo and completion update all affected views.
-   Prevent duplicate submissions from repeated taps.
-   Define behavior for app lifecycle interruptions.

### Data model considerations

The exact schema should follow the existing project and migration
strategy, but the domain will likely need concepts equivalent to:

-   Exercise.
-   Routine / workout template.
-   Routine exercise and ordering.
-   Workout session.
-   Session exercise.
-   Set entry.
-   Personal record or derived performance summary.
-   User goals and preferences.
-   Optional recovery entry.
-   Sync metadata.

Keep exercise definitions separate from the user's logged performance. A
session should preserve the exercise name or stable exercise reference
and the actual values recorded at the time. Historical data must not
change unexpectedly when a template is edited later.

Include stable identifiers, timestamps and versioning/sync metadata as
needed. Define units explicitly and avoid mixing kilograms and pounds.
Validate numeric inputs and decide how to handle deleted or renamed
exercises without breaking history.

### Performance

-   Avoid expensive recomputation on every set entry.
-   Keep chart data aggregation out of large widget build methods.
-   Use pagination or bounded queries for long histories.
-   Avoid rebuilding unrelated parts of an active workout when a timer
    ticks.
-   Profile before adding complex caching.
-   Keep animations lightweight and respect reduced-motion preferences.

### Testing

Add tests at several levels:

-   Unit tests for calculations, validation, progression metrics and
    state transitions.
-   Repository tests for local persistence and sync behavior.
-   Widget tests for logging, editing, empty/error states and accessible
    labels.
-   Integration tests for start workout → log sets → background/reopen →
    complete workout.
-   Regression tests for duplicate logging and data loss.
-   Tests for unit conversion, missing previous performance and
    incomplete workouts.

------------------------------------------------------------------------

## 13. Definition of done for a feature

Before marking a feature complete, verify:

-   [ ] The main user task is clear and the primary action is obvious.
-   [ ] The normal flow works with realistic data.
-   [ ] Loading, empty, error and offline states are designed.
-   [ ] Important actions provide visible feedback.
-   [ ] Mistakes can be corrected without losing data.
-   [ ] Data persists across navigation and app restarts where expected.
-   [ ] Layout works at different screen sizes and text scales.
-   [ ] Contrast, semantics and touch targets have been checked.
-   [ ] Calculations and displayed units are correct.
-   [ ] Tests cover important business logic and regressions.
-   [ ] No unsupported health or performance claims are presented.
-   [ ] The feature follows the existing architecture and design tokens.
-   [ ] The behavior has been tested with users or clearly marked as an
    unvalidated hypothesis.

------------------------------------------------------------------------

## 14. Recommended implementation order

### Phase 1: Trustworthy workout logging

1.  Audit existing models, providers, routing and local persistence.
2.  Make start/resume workout reliable.
3.  Build or refine the active workout screen.
4.  Implement set logging, editing, undo and completion.
5.  Persist active sessions locally and test app interruption.
6.  Add the rest timer without blocking other actions.

### Phase 2: Routines and exercise discovery

1.  Build the exercise library and search.
2.  Add routine creation and editing.
3.  Support exercise substitutions and reordering.
4.  Preserve historical session data when templates change.

### Phase 3: Progress and feedback

1.  Build exercise-specific history.
2.  Define and test volume and performance calculations.
3.  Add understandable charts and text summaries.
4.  Surface relevant previous performance in the active session.
5.  Test whether users correctly interpret the insights.

### Phase 4: Consistency and personalization

1.  Add goals and weekly activity summaries.
2.  Add optional, user-controlled reminders.
3.  Add meaningful milestones and personal-record celebrations.
4.  Validate retention and user sentiment before expanding gamification.

### Phase 5: Recovery and advanced intelligence

1.  Define exactly which recovery data is collected and why.
2.  Clearly label self-reported values and estimates.
3.  Introduce explainable, optional suggestions.
4.  Test recommendations for safety, usefulness and user control.
5.  Expand only when the underlying data is reliable.

This order prioritizes dependable core behavior before features that
depend on trustworthy history.

------------------------------------------------------------------------

## 15. Competitive analysis checklist

When reviewing another fitness app, compare the same tasks rather than
judging only its home screen.

For each app, inspect:

-   Time and steps required to log a set.
-   Whether previous performance is visible during logging.
-   How the rest timer behaves.
-   How editing and undo work.
-   How exercise search and substitutions work.
-   How routines are created and changed.
-   Whether workout history is easy to inspect.
-   Whether charts explain their metrics.
-   What happens offline.
-   How unfinished workouts are recovered.
-   How reminders and streaks are presented.
-   Accessibility and readability during real use.
-   Pricing or account restrictions that affect the core flow.

Record screenshots, observations, strengths, friction points and ideas
to test. Do not copy visual patterns without understanding the user
problem they solve.

------------------------------------------------------------------------

## 16. Final product decision rules

When deciding whether to add or change a feature, ask:

1.  Which user problem does it solve?
2.  What evidence supports the problem?
3.  Is the evidence directly about strength training or from a related
    domain?
4.  Does it make the core workout flow faster, clearer or more reliable?
5.  What is the simplest design that could solve it?
6.  How will users recover from mistakes?
7.  What happens offline or with missing data?
8.  Can the user understand why an insight or recommendation appears?
9.  How will we test whether it works?
10. What will we remove or simplify if it adds friction without
    measurable value?

**North star:** LEON should be a dependable training companion, not a
dashboard that happens to contain a workout logger. Make the core
experience fast, preserve the user's data, explain progress honestly,
and validate design decisions with real users.
