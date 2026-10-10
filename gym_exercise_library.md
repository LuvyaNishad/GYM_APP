# Gym Exercise Library

A structured starter library for a gym app. Each exercise has a short
description, target and secondary muscles, equipment, execution steps,
tags, difficulty, and practical notes.

> **Important:** Muscle involvement is approximate and varies with
> anatomy, technique, grip, range of motion, and equipment. This is an
> exercise reference, not individualized medical advice. Stop if an
> exercise causes sharp or unusual pain; seek a qualified coach or
> clinician when appropriate.

## Suggested app data fields

-   `name`: display name; consider a stable slug/ID in your database.
-   `primary_muscles` and `secondary_muscles`: searchable muscle tags.
-   `equipment`: equipment required; `bodyweight` means no external
    load.
-   `movement_pattern`: e.g. horizontal push, vertical pull, squat,
    hinge, carry, rotation.
-   `exercise_type`: compound, isolation, isometric, mobility,
    conditioning, or power.
-   `difficulty`: broad starting estimate, not a guarantee of safety.
-   `instructions`: concise step-by-step form guidance.
-   `coaching_cues` / `safety`: setup, common pitfalls, or scaling
    ideas.

## Tag conventions

Tags are lowercase, hyphenated where useful, and suitable for filtering.
Primary/secondary muscles are listed separately from general tags.
Difficulty labels: beginner, intermediate, advanced, or skill-based.
Equipment names can be normalized into IDs in your app.

## Exercises

### Chest

#### Barbell Bench Press

-   **ID:** `barbell-bench-press`
-   **Description:** Barbell Bench Press is a compound; horizontal push;
    strength movement used to train the listed muscles.
-   **Primary muscles:** pectoralis major
-   **Secondary muscles / stabilizers:** triceps; anterior deltoids
-   **Equipment:** barbell, bench
-   **Movement / type:** Compound; horizontal push; strength
-   **Difficulty:** beginner to intermediate
-   **Tags:** `chest`, `compound`, `horizontal-push`, `strength`, `gym`,
    `exercise-library`
-   **How to perform:** Lie on a flat bench, grip slightly wider than
    shoulder width, lower the bar under control to mid-chest, then press
    up without bouncing.
-   **Coaching / safety notes:** Keep shoulder blades retracted, feet
    planted, and wrists stacked over elbows. Use a spotter or safety
    arms.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Dumbbell Bench Press

-   **ID:** `dumbbell-bench-press`
-   **Description:** Dumbbell Bench Press is a compound; horizontal push
    movement used to train the listed muscles.
-   **Primary muscles:** pectoralis major
-   **Secondary muscles / stabilizers:** triceps; anterior deltoids
-   **Equipment:** dumbbells, flat bench
-   **Movement / type:** Compound; horizontal push
-   **Difficulty:** beginner to intermediate
-   **Tags:** `chest`, `compound`, `horizontal-push`, `gym`,
    `exercise-library`
-   **How to perform:** Lower dumbbells beside the chest with forearms
    vertical, then press upward while keeping the weights controlled.
-   **Coaching / safety notes:** Use a range of motion that feels
    comfortable for your shoulders.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Incline Barbell Bench Press

-   **ID:** `incline-barbell-bench-press`
-   **Description:** Incline Barbell Bench Press is a compound; upper
    chest movement used to train the listed muscles.
-   **Primary muscles:** upper pectoralis major
-   **Secondary muscles / stabilizers:** anterior deltoids; triceps
-   **Equipment:** barbell, incline bench
-   **Movement / type:** Compound; upper chest
-   **Difficulty:** beginner to intermediate
-   **Tags:** `chest`, `compound`, `upper-chest`, `gym`,
    `exercise-library`
-   **How to perform:** Set bench to a modest incline, lower bar to
    upper chest, and press vertically over the shoulders.
-   **Coaching / safety notes:** A very steep angle shifts more work to
    the shoulders.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Incline Dumbbell Press

-   **ID:** `incline-dumbbell-press`
-   **Description:** Incline Dumbbell Press is a compound; upper chest
    movement used to train the listed muscles.
-   **Primary muscles:** upper pectoralis major
-   **Secondary muscles / stabilizers:** anterior deltoids; triceps
-   **Equipment:** dumbbells, incline bench
-   **Movement / type:** Compound; upper chest
-   **Difficulty:** beginner to intermediate
-   **Tags:** `chest`, `compound`, `upper-chest`, `gym`,
    `exercise-library`
-   **How to perform:** Lower dumbbells to either side of the upper
    chest, then press up and slightly inward.
-   **Coaching / safety notes:** Avoid clanking the dumbbells together.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Decline Bench Press

-   **ID:** `decline-bench-press`
-   **Description:** Decline Bench Press is a compound; lower chest
    movement used to train the listed muscles.
-   **Primary muscles:** lower/sternal pectoralis major
-   **Secondary muscles / stabilizers:** triceps; anterior deltoids
-   **Equipment:** barbell, decline bench
-   **Movement / type:** Compound; lower chest
-   **Difficulty:** beginner to intermediate
-   **Tags:** `chest`, `compound`, `lower-chest`, `gym`,
    `exercise-library`
-   **How to perform:** Secure legs, lower bar to lower chest, and press
    up in a controlled path.
-   **Coaching / safety notes:** Use a spotter and exit the bench
    carefully.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Dumbbell Fly

-   **ID:** `dumbbell-fly`
-   **Description:** Dumbbell Fly is a isolation; chest adduction
    movement used to train the listed muscles.
-   **Primary muscles:** pectoralis major
-   **Secondary muscles / stabilizers:** anterior deltoids
-   **Equipment:** dumbbells, flat bench
-   **Movement / type:** Isolation; chest adduction
-   **Difficulty:** beginner to intermediate
-   **Tags:** `chest`, `isolation`, `chest-adduction`, `gym`,
    `exercise-library`
-   **How to perform:** With a slight elbow bend, open arms in an arc
    until a comfortable chest stretch, then bring the weights together.
-   **Coaching / safety notes:** Use light loads; do not force a deep
    stretch.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Incline Dumbbell Fly

-   **ID:** `incline-dumbbell-fly`
-   **Description:** Incline Dumbbell Fly is a isolation; upper chest
    movement used to train the listed muscles.
-   **Primary muscles:** upper pectoralis major
-   **Secondary muscles / stabilizers:** anterior deltoids
-   **Equipment:** dumbbells, incline bench
-   **Movement / type:** Isolation; upper chest
-   **Difficulty:** beginner to intermediate
-   **Tags:** `chest`, `isolation`, `upper-chest`, `gym`,
    `exercise-library`
-   **How to perform:** Open the arms in a controlled arc on an incline
    bench, then bring them back above the chest.
-   **Coaching / safety notes:** Keep elbow angle nearly fixed.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Cable Crossover

-   **ID:** `cable-crossover`
-   **Description:** Cable Crossover is a isolation; chest adduction
    movement used to train the listed muscles.
-   **Primary muscles:** pectoralis major
-   **Secondary muscles / stabilizers:** anterior deltoids; biceps
    stabilizers
-   **Equipment:** dual cable machine
-   **Movement / type:** Isolation; chest adduction
-   **Difficulty:** beginner to intermediate
-   **Tags:** `chest`, `isolation`, `chest-adduction`, `gym`,
    `exercise-library`
-   **How to perform:** Stand between pulleys, bring handles together in
    front of the torso, and return slowly.
-   **Coaching / safety notes:** Adjust pulley height to change the line
    of pull.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### High-to-Low Cable Fly

-   **ID:** `high-to-low-cable-fly`
-   **Description:** High-to-Low Cable Fly is a isolation; lower chest
    bias movement used to train the listed muscles.
-   **Primary muscles:** lower/sternal pectoralis major
-   **Secondary muscles / stabilizers:** anterior deltoids
-   **Equipment:** dual cable machine, high pulleys
-   **Movement / type:** Isolation; lower chest bias
-   **Difficulty:** beginner to intermediate
-   **Tags:** `chest`, `isolation`, `lower-chest-bias`, `gym`,
    `exercise-library`
-   **How to perform:** Starting with handles high, sweep hands down and
    inward toward the hips.
-   **Coaching / safety notes:** Avoid turning it into a torso swing.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Low-to-High Cable Fly

-   **ID:** `low-to-high-cable-fly`
-   **Description:** Low-to-High Cable Fly is a isolation; upper chest
    bias movement used to train the listed muscles.
-   **Primary muscles:** upper pectoralis major
-   **Secondary muscles / stabilizers:** anterior deltoids
-   **Equipment:** dual cable machine, low pulleys
-   **Movement / type:** Isolation; upper chest bias
-   **Difficulty:** beginner to intermediate
-   **Tags:** `chest`, `isolation`, `upper-chest-bias`, `gym`,
    `exercise-library`
-   **How to perform:** Starting with handles low, sweep arms upward and
    inward to chest height.
-   **Coaching / safety notes:** Keep ribs down and shoulders
    controlled.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Pec Deck Fly

-   **ID:** `pec-deck-fly`
-   **Description:** Pec Deck Fly is a isolation; chest movement used to
    train the listed muscles.
-   **Primary muscles:** pectoralis major
-   **Secondary muscles / stabilizers:** anterior deltoids
-   **Equipment:** pec deck machine
-   **Movement / type:** Isolation; chest
-   **Difficulty:** beginner to intermediate
-   **Tags:** `chest`, `isolation`, `gym`, `exercise-library`
-   **How to perform:** Bring pads or handles together in front of the
    chest, pause, then return slowly.
-   **Coaching / safety notes:** Set seat so handles align around
    mid-chest.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Push-Up

-   **ID:** `push-up`
-   **Description:** Push-Up is a compound; bodyweight push movement
    used to train the listed muscles.
-   **Primary muscles:** pectoralis major
-   **Secondary muscles / stabilizers:** triceps; anterior deltoids;
    core
-   **Equipment:** bodyweight, optional handles
-   **Movement / type:** Compound; bodyweight push
-   **Difficulty:** beginner / scalable
-   **Tags:** `chest`, `compound`, `bodyweight-push`, `gym`,
    `exercise-library`
-   **How to perform:** Keep body in a straight line, lower chest toward
    floor, and push back up.
-   **Coaching / safety notes:** Elevate hands to scale down or elevate
    feet to increase difficulty.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Wide-Grip Push-Up

-   **ID:** `wide-grip-push-up`
-   **Description:** Wide-Grip Push-Up is a compound; chest emphasis
    movement used to train the listed muscles.
-   **Primary muscles:** pectoralis major
-   **Secondary muscles / stabilizers:** anterior deltoids; triceps;
    core
-   **Equipment:** bodyweight
-   **Movement / type:** Compound; chest emphasis
-   **Difficulty:** beginner to intermediate
-   **Tags:** `chest`, `compound`, `chest-emphasis`, `gym`,
    `exercise-library`
-   **How to perform:** Perform a push-up with hands somewhat wider than
    shoulders and elbows at a comfortable angle.
-   **Coaching / safety notes:** Do not flare elbows excessively.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Close-Grip Push-Up

-   **ID:** `close-grip-push-up`
-   **Description:** Close-Grip Push-Up is a compound; triceps emphasis
    movement used to train the listed muscles.
-   **Primary muscles:** triceps; inner chest contribution
-   **Secondary muscles / stabilizers:** pectoralis major; anterior
    deltoids; core
-   **Equipment:** bodyweight
-   **Movement / type:** Compound; triceps emphasis
-   **Difficulty:** beginner to intermediate
-   **Tags:** `chest`, `compound`, `triceps-emphasis`, `gym`,
    `exercise-library`
-   **How to perform:** Keep hands closer than shoulder width and lower
    the chest under control.
-   **Coaching / safety notes:** Hand placement should remain
    comfortable for wrists.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Chest Dip

-   **ID:** `chest-dip`
-   **Description:** Chest Dip is a compound; chest/triceps movement
    used to train the listed muscles.
-   **Primary muscles:** lower pectoralis major
-   **Secondary muscles / stabilizers:** triceps; anterior deltoids
-   **Equipment:** dip bars, assisted dip machine optional
-   **Movement / type:** Compound; chest/triceps
-   **Difficulty:** beginner to intermediate
-   **Tags:** `chest`, `compound`, `chest-triceps`, `gym`,
    `exercise-library`
-   **How to perform:** Lean slightly forward, lower only as far as
    shoulders tolerate, then press up.
-   **Coaching / safety notes:** Use assistance if needed; deep dips can
    irritate some shoulders.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Machine Chest Press

-   **ID:** `machine-chest-press`
-   **Description:** Machine Chest Press is a compound; machine push
    movement used to train the listed muscles.
-   **Primary muscles:** pectoralis major
-   **Secondary muscles / stabilizers:** triceps; anterior deltoids
-   **Equipment:** chest press machine
-   **Movement / type:** Compound; machine push
-   **Difficulty:** beginner to intermediate
-   **Tags:** `chest`, `compound`, `machine-push`, `gym`,
    `exercise-library`
-   **How to perform:** Set handles near mid-chest, press forward, then
    return without letting the stack slam.
-   **Coaching / safety notes:** Adjust seat and use a controlled range.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Smith Machine Bench Press

-   **ID:** `smith-machine-bench-press`
-   **Description:** Smith Machine Bench Press is a compound; guided bar
    press movement used to train the listed muscles.
-   **Primary muscles:** pectoralis major
-   **Secondary muscles / stabilizers:** triceps; anterior deltoids
-   **Equipment:** Smith machine, bench
-   **Movement / type:** Compound; guided bar press
-   **Difficulty:** beginner to intermediate
-   **Tags:** `chest`, `compound`, `guided-bar-press`, `gym`,
    `exercise-library`
-   **How to perform:** Position bench so the bar descends to mid-chest,
    lower under control, and press upward.
-   **Coaching / safety notes:** Set safety stops and use a comfortable
    bar path.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Landmine Chest Press

-   **ID:** `landmine-chest-press`
-   **Description:** Landmine Chest Press is a compound; angled press
    movement used to train the listed muscles.
-   **Primary muscles:** pectoralis major
-   **Secondary muscles / stabilizers:** anterior deltoids; triceps;
    core
-   **Equipment:** barbell, landmine attachment
-   **Movement / type:** Compound; angled press
-   **Difficulty:** beginner to intermediate
-   **Tags:** `chest`, `compound`, `angled-press`, `gym`,
    `exercise-library`
-   **How to perform:** Press the landmine end forward and upward from
    chest level while resisting torso rotation.
-   **Coaching / safety notes:** Can be done half-kneeling or standing.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

### Back

#### Conventional Deadlift

-   **ID:** `conventional-deadlift`
-   **Description:** Conventional Deadlift is a compound; hip hinge;
    pull movement used to train the listed muscles.
-   **Primary muscles:** gluteus maximus; hamstrings; spinal erectors
-   **Secondary muscles / stabilizers:** lats; traps; forearms;
    quadriceps
-   **Equipment:** barbell, plates
-   **Movement / type:** Compound; hip hinge; pull
-   **Difficulty:** intermediate
-   **Tags:** `back`, `compound`, `hip-hinge`, `pull`, `gym`,
    `exercise-library`
-   **How to perform:** Brace, hinge to grip the bar, push the floor
    away, and stand tall with the bar close to the legs.
-   **Coaching / safety notes:** Keep spine braced; do not lean back at
    lockout.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Romanian Deadlift

-   **ID:** `romanian-deadlift`
-   **Description:** Romanian Deadlift is a compound; hip hinge movement
    used to train the listed muscles.
-   **Primary muscles:** hamstrings; gluteus maximus
-   **Secondary muscles / stabilizers:** spinal erectors; lats; forearms
-   **Equipment:** barbell or dumbbells
-   **Movement / type:** Compound; hip hinge
-   **Difficulty:** intermediate
-   **Tags:** `back`, `compound`, `hip-hinge`, `gym`, `exercise-library`
-   **How to perform:** With soft knees, push hips back and lower the
    weight along the legs until hamstrings stretch, then stand.
-   **Coaching / safety notes:** Move from the hips; keep the load
    close.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Barbell Bent-Over Row

-   **ID:** `barbell-bent-over-row`
-   **Description:** Barbell Bent-Over Row is a compound; horizontal
    pull movement used to train the listed muscles.
-   **Primary muscles:** latissimus dorsi; middle trapezius; rhomboids
-   **Secondary muscles / stabilizers:** rear deltoids; biceps; spinal
    erectors
-   **Equipment:** barbell
-   **Movement / type:** Compound; horizontal pull
-   **Difficulty:** beginner to intermediate
-   **Tags:** `back`, `compound`, `horizontal-pull`, `gym`,
    `exercise-library`
-   **How to perform:** Hinge with a braced torso, pull bar toward lower
    ribs, and lower slowly.
-   **Coaching / safety notes:** Avoid jerking the torso to move the
    bar.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### One-Arm Dumbbell Row

-   **ID:** `one-arm-dumbbell-row`
-   **Description:** One-Arm Dumbbell Row is a compound; unilateral row
    movement used to train the listed muscles.
-   **Primary muscles:** latissimus dorsi; rhomboids; middle trapezius
-   **Secondary muscles / stabilizers:** rear deltoids; biceps
-   **Equipment:** dumbbell, bench
-   **Movement / type:** Compound; unilateral row
-   **Difficulty:** beginner to intermediate
-   **Tags:** `back`, `compound`, `unilateral-row`, `gym`,
    `exercise-library`
-   **How to perform:** Support one hand on a bench, pull dumbbell
    toward hip, and lower with control.
-   **Coaching / safety notes:** Keep hips square and avoid twisting.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Seated Cable Row

-   **ID:** `seated-cable-row`
-   **Description:** Seated Cable Row is a compound; horizontal pull
    movement used to train the listed muscles.
-   **Primary muscles:** middle trapezius; rhomboids; latissimus dorsi
-   **Secondary muscles / stabilizers:** biceps; rear deltoids
-   **Equipment:** cable row station, handle
-   **Movement / type:** Compound; horizontal pull
-   **Difficulty:** beginner to intermediate
-   **Tags:** `back`, `compound`, `horizontal-pull`, `gym`,
    `exercise-library`
-   **How to perform:** Sit tall, pull handle toward lower ribs, squeeze
    shoulder blades, and extend arms slowly.
-   **Coaching / safety notes:** Avoid excessive backward rocking.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Chest-Supported Row

-   **ID:** `chest-supported-row`
-   **Description:** Chest-Supported Row is a compound; supported row
    movement used to train the listed muscles.
-   **Primary muscles:** middle back; latissimus dorsi
-   **Secondary muscles / stabilizers:** rear deltoids; biceps
-   **Equipment:** incline bench, dumbbells or machine
-   **Movement / type:** Compound; supported row
-   **Difficulty:** beginner to intermediate
-   **Tags:** `back`, `compound`, `supported-row`, `gym`,
    `exercise-library`
-   **How to perform:** Lie chest-down on support and row weights toward
    the torso.
-   **Coaching / safety notes:** Support reduces lower-back demand.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### T-Bar Row

-   **ID:** `t-bar-row`
-   **Description:** T-Bar Row is a compound; horizontal pull movement
    used to train the listed muscles.
-   **Primary muscles:** middle back; latissimus dorsi
-   **Secondary muscles / stabilizers:** biceps; rear deltoids; spinal
    erectors
-   **Equipment:** T-bar row machine or landmine, handle
-   **Movement / type:** Compound; horizontal pull
-   **Difficulty:** beginner to intermediate
-   **Tags:** `back`, `compound`, `horizontal-pull`, `gym`,
    `exercise-library`
-   **How to perform:** Brace, pull handle toward torso, and lower under
    control.
-   **Coaching / safety notes:** Keep torso stable.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Pendlay Row

-   **ID:** `pendlay-row`
-   **Description:** Pendlay Row is a compound; strict barbell row
    movement used to train the listed muscles.
-   **Primary muscles:** middle back; latissimus dorsi
-   **Secondary muscles / stabilizers:** rear deltoids; biceps; spinal
    erectors
-   **Equipment:** barbell, plates
-   **Movement / type:** Compound; strict barbell row
-   **Difficulty:** advanced / skill-based
-   **Tags:** `back`, `compound`, `strict-barbell-row`, `gym`,
    `exercise-library`
-   **How to perform:** From a hinged torso, row the bar from the floor
    to the lower chest, resetting each rep.
-   **Coaching / safety notes:** Requires sound hinge and bracing
    technique.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Inverted Row

-   **ID:** `inverted-row`
-   **Description:** Inverted Row is a compound; bodyweight pull
    movement used to train the listed muscles.
-   **Primary muscles:** rhomboids; middle trapezius; latissimus dorsi
-   **Secondary muscles / stabilizers:** biceps; rear deltoids; core
-   **Equipment:** bar in rack or suspension trainer
-   **Movement / type:** Compound; bodyweight pull
-   **Difficulty:** beginner to intermediate
-   **Tags:** `back`, `compound`, `bodyweight-pull`, `gym`,
    `exercise-library`
-   **How to perform:** Keep body straight under a secure bar, pull
    chest to bar, then lower.
-   **Coaching / safety notes:** Bend knees or raise bar to make it
    easier.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Pull-Up

-   **ID:** `pull-up`
-   **Description:** Pull-Up is a compound; vertical pull movement used
    to train the listed muscles.
-   **Primary muscles:** latissimus dorsi
-   **Secondary muscles / stabilizers:** biceps; brachialis; lower
    trapezius; core
-   **Equipment:** pull-up bar
-   **Movement / type:** Compound; vertical pull
-   **Difficulty:** intermediate
-   **Tags:** `back`, `compound`, `vertical-pull`, `gym`,
    `exercise-library`
-   **How to perform:** Hang from the bar, pull elbows down until chin
    reaches bar height, then lower steadily.
-   **Coaching / safety notes:** Use band or machine assistance if
    needed.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Chin-Up

-   **ID:** `chin-up`
-   **Description:** Chin-Up is a compound; underhand vertical pull
    movement used to train the listed muscles.
-   **Primary muscles:** latissimus dorsi
-   **Secondary muscles / stabilizers:** biceps; brachialis; forearms
-   **Equipment:** pull-up bar
-   **Movement / type:** Compound; underhand vertical pull
-   **Difficulty:** beginner to intermediate
-   **Tags:** `back`, `compound`, `underhand-vertical-pull`, `gym`,
    `exercise-library`
-   **How to perform:** Use an underhand grip and pull chest upward,
    then lower under control.
-   **Coaching / safety notes:** Avoid swinging or kicking.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Lat Pulldown

-   **ID:** `lat-pulldown`
-   **Description:** Lat Pulldown is a compound; vertical pull movement
    used to train the listed muscles.
-   **Primary muscles:** latissimus dorsi
-   **Secondary muscles / stabilizers:** biceps; teres major; middle
    back
-   **Equipment:** lat pulldown machine
-   **Movement / type:** Compound; vertical pull
-   **Difficulty:** beginner to intermediate
-   **Tags:** `back`, `compound`, `vertical-pull`, `gym`,
    `exercise-library`
-   **How to perform:** Pull bar toward upper chest while keeping torso
    slightly leaned back, then allow arms to extend.
-   **Coaching / safety notes:** Do not pull behind the neck.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Neutral-Grip Lat Pulldown

-   **ID:** `neutral-grip-lat-pulldown`
-   **Description:** Neutral-Grip Lat Pulldown is a compound; vertical
    pull movement used to train the listed muscles.
-   **Primary muscles:** latissimus dorsi
-   **Secondary muscles / stabilizers:** biceps; brachialis; teres major
-   **Equipment:** pulldown machine, neutral handle
-   **Movement / type:** Compound; vertical pull
-   **Difficulty:** beginner to intermediate
-   **Tags:** `back`, `compound`, `vertical-pull`, `gym`,
    `exercise-library`
-   **How to perform:** Pull neutral handles toward upper chest and
    return slowly.
-   **Coaching / safety notes:** Keep shoulders away from ears.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Straight-Arm Cable Pulldown

-   **ID:** `straight-arm-cable-pulldown`
-   **Description:** Straight-Arm Cable Pulldown is a isolation;
    shoulder extension movement used to train the listed muscles.
-   **Primary muscles:** latissimus dorsi
-   **Secondary muscles / stabilizers:** teres major; long head of
    triceps contribution
-   **Equipment:** cable machine, straight bar or rope
-   **Movement / type:** Isolation; shoulder extension
-   **Difficulty:** beginner to intermediate
-   **Tags:** `back`, `isolation`, `shoulder-extension`, `gym`,
    `exercise-library`
-   **How to perform:** With elbows softly bent, sweep the bar from
    shoulder height to thighs without swinging.
-   **Coaching / safety notes:** Keep ribs down and arms mostly
    straight.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Machine High Row

-   **ID:** `machine-high-row`
-   **Description:** Machine High Row is a compound; angled pull
    movement used to train the listed muscles.
-   **Primary muscles:** latissimus dorsi; upper/middle back
-   **Secondary muscles / stabilizers:** biceps; rear deltoids
-   **Equipment:** high-row machine
-   **Movement / type:** Compound; angled pull
-   **Difficulty:** beginner to intermediate
-   **Tags:** `back`, `compound`, `angled-pull`, `gym`,
    `exercise-library`
-   **How to perform:** Set chest against pad and pull handles down and
    back.
-   **Coaching / safety notes:** Follow the machine's natural path.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Dumbbell Pullover

-   **ID:** `dumbbell-pullover`
-   **Description:** Dumbbell Pullover is a compound/accessory; shoulder
    extension movement used to train the listed muscles.
-   **Primary muscles:** latissimus dorsi; pectoralis major
-   **Secondary muscles / stabilizers:** serratus anterior; triceps long
    head
-   **Equipment:** dumbbell, bench
-   **Movement / type:** Compound/accessory; shoulder extension
-   **Difficulty:** beginner to intermediate
-   **Tags:** `back`, `compound-accessory`, `shoulder-extension`, `gym`,
    `exercise-library`
-   **How to perform:** Lower one dumbbell behind the head with slightly
    bent elbows, then bring it over the chest.
-   **Coaching / safety notes:** Use a comfortable shoulder range and
    modest load.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Back Extension

-   **ID:** `back-extension`
-   **Description:** Back Extension is a accessory; trunk/hip extension
    movement used to train the listed muscles.
-   **Primary muscles:** spinal erectors
-   **Secondary muscles / stabilizers:** gluteus maximus; hamstrings
-   **Equipment:** back extension bench
-   **Movement / type:** Accessory; trunk/hip extension
-   **Difficulty:** beginner to intermediate
-   **Tags:** `back`, `accessory`, `trunk-hip-extension`, `gym`,
    `exercise-library`
-   **How to perform:** Hinge at hips to lower torso, then raise until
    body is straight.
-   **Coaching / safety notes:** Avoid hyperextending the lower back.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Reverse Hyperextension

-   **ID:** `reverse-hyperextension`
-   **Description:** Reverse Hyperextension is a accessory; hip
    extension movement used to train the listed muscles.
-   **Primary muscles:** gluteus maximus; spinal erectors
-   **Secondary muscles / stabilizers:** hamstrings
-   **Equipment:** reverse hyper machine or sturdy supported setup
-   **Movement / type:** Accessory; hip extension
-   **Difficulty:** beginner to intermediate
-   **Tags:** `back`, `accessory`, `hip-extension`, `gym`,
    `exercise-library`
-   **How to perform:** With torso supported, lift legs by extending
    hips, then lower slowly.
-   **Coaching / safety notes:** Use controlled motion and appropriate
    equipment.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Rack Pull

-   **ID:** `rack-pull`
-   **Description:** Rack Pull is a compound; partial deadlift movement
    used to train the listed muscles.
-   **Primary muscles:** spinal erectors; gluteus maximus; traps
-   **Secondary muscles / stabilizers:** hamstrings; forearms; lats
-   **Equipment:** barbell, rack, safety pins
-   **Movement / type:** Compound; partial deadlift
-   **Difficulty:** beginner to intermediate
-   **Tags:** `back`, `compound`, `partial-deadlift`, `gym`,
    `exercise-library`
-   **How to perform:** Set bar just below or above knees, brace, stand
    tall, and lower to pins.
-   **Coaching / safety notes:** Keep bar close; avoid overleaning at
    lockout.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

### Shoulders

#### Standing Barbell Overhead Press

-   **ID:** `standing-barbell-overhead-press`
-   **Description:** Standing Barbell Overhead Press is a compound;
    vertical push movement used to train the listed muscles.
-   **Primary muscles:** anterior deltoids; medial deltoids
-   **Secondary muscles / stabilizers:** triceps; upper trapezius; core
-   **Equipment:** barbell
-   **Movement / type:** Compound; vertical push
-   **Difficulty:** intermediate
-   **Tags:** `shoulders`, `compound`, `vertical-push`, `gym`,
    `exercise-library`
-   **How to perform:** Brace glutes and abdomen, press bar overhead,
    then lower to upper chest.
-   **Coaching / safety notes:** Avoid excessive lower-back arch.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Seated Dumbbell Shoulder Press

-   **ID:** `seated-dumbbell-shoulder-press`
-   **Description:** Seated Dumbbell Shoulder Press is a compound;
    vertical push movement used to train the listed muscles.
-   **Primary muscles:** anterior deltoids; medial deltoids
-   **Secondary muscles / stabilizers:** triceps; upper trapezius
-   **Equipment:** dumbbells, bench with back support
-   **Movement / type:** Compound; vertical push
-   **Difficulty:** beginner to intermediate
-   **Tags:** `shoulders`, `compound`, `vertical-push`, `gym`,
    `exercise-library`
-   **How to perform:** Press dumbbells from shoulder height overhead
    and lower slowly.
-   **Coaching / safety notes:** Use a pain-free range.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Arnold Press

-   **ID:** `arnold-press`
-   **Description:** Arnold Press is a compound; rotational shoulder
    press movement used to train the listed muscles.
-   **Primary muscles:** anterior deltoids; medial deltoids
-   **Secondary muscles / stabilizers:** triceps; upper trapezius
-   **Equipment:** dumbbells, bench
-   **Movement / type:** Compound; rotational shoulder press
-   **Difficulty:** beginner to intermediate
-   **Tags:** `shoulders`, `compound`, `rotational-shoulder-press`,
    `gym`, `exercise-library`
-   **How to perform:** Start palms facing you, rotate palms forward as
    you press overhead, then reverse.
-   **Coaching / safety notes:** Use lighter weights while learning the
    rotation.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Dumbbell Lateral Raise

-   **ID:** `dumbbell-lateral-raise`
-   **Description:** Dumbbell Lateral Raise is a isolation; shoulder
    abduction movement used to train the listed muscles.
-   **Primary muscles:** medial deltoids
-   **Secondary muscles / stabilizers:** supraspinatus; upper trapezius
-   **Equipment:** dumbbells
-   **Movement / type:** Isolation; shoulder abduction
-   **Difficulty:** beginner to intermediate
-   **Tags:** `shoulders`, `isolation`, `shoulder-abduction`, `gym`,
    `exercise-library`
-   **How to perform:** Raise dumbbells out to the sides to around
    shoulder height, then lower slowly.
-   **Coaching / safety notes:** Use a slight elbow bend and avoid
    swinging.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Cable Lateral Raise

-   **ID:** `cable-lateral-raise`
-   **Description:** Cable Lateral Raise is a isolation; shoulder
    abduction movement used to train the listed muscles.
-   **Primary muscles:** medial deltoids
-   **Secondary muscles / stabilizers:** supraspinatus; upper trapezius
-   **Equipment:** low cable, single handle
-   **Movement / type:** Isolation; shoulder abduction
-   **Difficulty:** beginner to intermediate
-   **Tags:** `shoulders`, `isolation`, `shoulder-abduction`, `gym`,
    `exercise-library`
-   **How to perform:** Raise the handle out to the side against cable
    tension and lower with control.
-   **Coaching / safety notes:** Stand so the cable pulls across the
    body.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Machine Lateral Raise

-   **ID:** `machine-lateral-raise`
-   **Description:** Machine Lateral Raise is a isolation; shoulder
    abduction movement used to train the listed muscles.
-   **Primary muscles:** medial deltoids
-   **Secondary muscles / stabilizers:** upper trapezius
-   **Equipment:** lateral raise machine
-   **Movement / type:** Isolation; shoulder abduction
-   **Difficulty:** beginner to intermediate
-   **Tags:** `shoulders`, `isolation`, `shoulder-abduction`, `gym`,
    `exercise-library`
-   **How to perform:** Press upper arms into pads and raise to a
    comfortable height.
-   **Coaching / safety notes:** Adjust seat so pads align with upper
    arms.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Front Dumbbell Raise

-   **ID:** `front-dumbbell-raise`
-   **Description:** Front Dumbbell Raise is a isolation; shoulder
    flexion movement used to train the listed muscles.
-   **Primary muscles:** anterior deltoids
-   **Secondary muscles / stabilizers:** upper pectoralis major;
    serratus anterior
-   **Equipment:** dumbbells
-   **Movement / type:** Isolation; shoulder flexion
-   **Difficulty:** beginner to intermediate
-   **Tags:** `shoulders`, `isolation`, `shoulder-flexion`, `gym`,
    `exercise-library`
-   **How to perform:** Raise dumbbells in front to shoulder height and
    lower slowly.
-   **Coaching / safety notes:** Avoid leaning back; front delts already
    work in many presses.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Plate Front Raise

-   **ID:** `plate-front-raise`
-   **Description:** Plate Front Raise is a isolation; shoulder flexion
    movement used to train the listed muscles.
-   **Primary muscles:** anterior deltoids
-   **Secondary muscles / stabilizers:** upper pectoralis major
-   **Equipment:** weight plate
-   **Movement / type:** Isolation; shoulder flexion
-   **Difficulty:** beginner to intermediate
-   **Tags:** `shoulders`, `isolation`, `shoulder-flexion`, `gym`,
    `exercise-library`
-   **How to perform:** Hold plate with both hands, raise to shoulder
    height, and lower steadily.
-   **Coaching / safety notes:** Use a load that does not require
    momentum.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Reverse Pec Deck

-   **ID:** `reverse-pec-deck`
-   **Description:** Reverse Pec Deck is a isolation; horizontal
    abduction movement used to train the listed muscles.
-   **Primary muscles:** rear deltoids
-   **Secondary muscles / stabilizers:** rhomboids; middle trapezius
-   **Equipment:** reverse pec deck machine
-   **Movement / type:** Isolation; horizontal abduction
-   **Difficulty:** beginner to intermediate
-   **Tags:** `shoulders`, `isolation`, `horizontal-abduction`, `gym`,
    `exercise-library`
-   **How to perform:** Face the machine, open arms outward, pause, and
    return slowly.
-   **Coaching / safety notes:** Keep shoulders down and torso against
    pad.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Bent-Over Rear Delt Fly

-   **ID:** `bent-over-rear-delt-fly`
-   **Description:** Bent-Over Rear Delt Fly is a isolation; rear
    shoulder movement used to train the listed muscles.
-   **Primary muscles:** rear deltoids
-   **Secondary muscles / stabilizers:** rhomboids; middle trapezius
-   **Equipment:** dumbbells
-   **Movement / type:** Isolation; rear shoulder
-   **Difficulty:** beginner to intermediate
-   **Tags:** `shoulders`, `isolation`, `rear-shoulder`, `gym`,
    `exercise-library`
-   **How to perform:** Hinge forward and raise arms outward with soft
    elbows.
-   **Coaching / safety notes:** Avoid shrugging or swinging.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Face Pull

-   **ID:** `face-pull`
-   **Description:** Face Pull is a accessory; upper-back/shoulder
    health movement used to train the listed muscles.
-   **Primary muscles:** rear deltoids; middle/lower trapezius
-   **Secondary muscles / stabilizers:** rotator cuff; rhomboids
-   **Equipment:** cable machine, rope
-   **Movement / type:** Accessory; upper-back/shoulder health
-   **Difficulty:** beginner to intermediate
-   **Tags:** `shoulders`, `accessory`, `upper-back-shoulder-health`,
    `gym`, `exercise-library`
-   **How to perform:** Pull rope toward face with elbows high and
    rotate hands apart near the end.
-   **Coaching / safety notes:** Use light-to-moderate load and
    controlled motion.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Upright Row

-   **ID:** `upright-row`
-   **Description:** Upright Row is a compound/accessory; shoulder pull
    movement used to train the listed muscles.
-   **Primary muscles:** medial deltoids; upper trapezius
-   **Secondary muscles / stabilizers:** biceps; forearms
-   **Equipment:** barbell, EZ bar, or cable
-   **Movement / type:** Compound/accessory; shoulder pull
-   **Difficulty:** beginner to intermediate
-   **Tags:** `shoulders`, `compound-accessory`, `shoulder-pull`, `gym`,
    `exercise-library`
-   **How to perform:** Pull the bar upward close to body to a
    comfortable height, then lower.
-   **Coaching / safety notes:** Use a grip and range that do not cause
    shoulder pinching.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Barbell Shrug

-   **ID:** `barbell-shrug`
-   **Description:** Barbell Shrug is a isolation; scapular elevation
    movement used to train the listed muscles.
-   **Primary muscles:** upper trapezius
-   **Secondary muscles / stabilizers:** forearms; levator scapulae
-   **Equipment:** barbell
-   **Movement / type:** Isolation; scapular elevation
-   **Difficulty:** beginner to intermediate
-   **Tags:** `shoulders`, `isolation`, `scapular-elevation`, `gym`,
    `exercise-library`
-   **How to perform:** Stand tall and lift shoulders straight up,
    pause, then lower.
-   **Coaching / safety notes:** Do not roll shoulders in circles.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Dumbbell Shrug

-   **ID:** `dumbbell-shrug`
-   **Description:** Dumbbell Shrug is a isolation; scapular elevation
    movement used to train the listed muscles.
-   **Primary muscles:** upper trapezius
-   **Secondary muscles / stabilizers:** forearms; levator scapulae
-   **Equipment:** dumbbells
-   **Movement / type:** Isolation; scapular elevation
-   **Difficulty:** beginner to intermediate
-   **Tags:** `shoulders`, `isolation`, `scapular-elevation`, `gym`,
    `exercise-library`
-   **How to perform:** Hold weights at sides, shrug vertically, and
    lower slowly.
-   **Coaching / safety notes:** Keep neck neutral.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Cable Y-Raise

-   **ID:** `cable-y-raise`
-   **Description:** Cable Y-Raise is a accessory; scapular control
    movement used to train the listed muscles.
-   **Primary muscles:** lower trapezius; medial/rear deltoids
-   **Secondary muscles / stabilizers:** rotator cuff; serratus anterior
-   **Equipment:** cables or light dumbbells
-   **Movement / type:** Accessory; scapular control
-   **Difficulty:** beginner to intermediate
-   **Tags:** `shoulders`, `accessory`, `scapular-control`, `gym`,
    `exercise-library`
-   **How to perform:** Raise arms diagonally into a Y while keeping
    ribs down.
-   **Coaching / safety notes:** Choose light resistance and prioritize
    control.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

### Arms - Biceps and Forearms

#### Barbell Biceps Curl

-   **ID:** `barbell-biceps-curl`
-   **Description:** Barbell Biceps Curl is a isolation; elbow flexion
    movement used to train the listed muscles.
-   **Primary muscles:** biceps brachii
-   **Secondary muscles / stabilizers:** brachialis; brachioradialis
-   **Equipment:** barbell
-   **Movement / type:** Isolation; elbow flexion
-   **Difficulty:** beginner to intermediate
-   **Tags:** `arms-biceps-and-forearms`, `isolation`, `elbow-flexion`,
    `gym`, `exercise-library`
-   **How to perform:** Curl bar toward shoulders without moving upper
    arms, then lower slowly.
-   **Coaching / safety notes:** Avoid swinging hips.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### EZ-Bar Curl

-   **ID:** `ez-bar-curl`
-   **Description:** EZ-Bar Curl is a isolation; elbow flexion movement
    used to train the listed muscles.
-   **Primary muscles:** biceps brachii
-   **Secondary muscles / stabilizers:** brachialis; brachioradialis
-   **Equipment:** EZ curl bar
-   **Movement / type:** Isolation; elbow flexion
-   **Difficulty:** beginner to intermediate
-   **Tags:** `arms-biceps-and-forearms`, `isolation`, `elbow-flexion`,
    `gym`, `exercise-library`
-   **How to perform:** Curl the angled bar while keeping elbows close
    to sides.
-   **Coaching / safety notes:** Angled grip may feel more comfortable
    on wrists.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Alternating Dumbbell Curl

-   **ID:** `alternating-dumbbell-curl`
-   **Description:** Alternating Dumbbell Curl is a isolation;
    unilateral curl movement used to train the listed muscles.
-   **Primary muscles:** biceps brachii
-   **Secondary muscles / stabilizers:** brachialis; brachioradialis
-   **Equipment:** dumbbells
-   **Movement / type:** Isolation; unilateral curl
-   **Difficulty:** beginner to intermediate
-   **Tags:** `arms-biceps-and-forearms`, `isolation`,
    `unilateral-curl`, `gym`, `exercise-library`
-   **How to perform:** Curl one dumbbell at a time, rotating palm
    upward as comfortable.
-   **Coaching / safety notes:** Keep upper arm still.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Hammer Curl

-   **ID:** `hammer-curl`
-   **Description:** Hammer Curl is a isolation; neutral-grip curl
    movement used to train the listed muscles.
-   **Primary muscles:** brachialis; brachioradialis
-   **Secondary muscles / stabilizers:** biceps brachii
-   **Equipment:** dumbbells
-   **Movement / type:** Isolation; neutral-grip curl
-   **Difficulty:** beginner to intermediate
-   **Tags:** `arms-biceps-and-forearms`, `isolation`,
    `neutral-grip-curl`, `gym`, `exercise-library`
-   **How to perform:** Keep palms facing inward and curl dumbbells
    toward shoulders.
-   **Coaching / safety notes:** Avoid swinging or bending wrists.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Incline Dumbbell Curl

-   **ID:** `incline-dumbbell-curl`
-   **Description:** Incline Dumbbell Curl is a isolation;
    lengthened-position curl movement used to train the listed muscles.
-   **Primary muscles:** biceps brachii, especially long head emphasis
-   **Secondary muscles / stabilizers:** brachialis; brachioradialis
-   **Equipment:** dumbbells, incline bench
-   **Movement / type:** Isolation; lengthened-position curl
-   **Difficulty:** beginner to intermediate
-   **Tags:** `arms-biceps-and-forearms`, `isolation`,
    `lengthened-position-curl`, `gym`, `exercise-library`
-   **How to perform:** Sit back on incline bench with arms hanging,
    curl without moving elbows forward.
-   **Coaching / safety notes:** Use lighter weights and avoid
    overstretching.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Preacher Curl

-   **ID:** `preacher-curl`
-   **Description:** Preacher Curl is a isolation; supported curl
    movement used to train the listed muscles.
-   **Primary muscles:** biceps brachii
-   **Secondary muscles / stabilizers:** brachialis
-   **Equipment:** preacher bench, EZ bar or dumbbells
-   **Movement / type:** Isolation; supported curl
-   **Difficulty:** beginner to intermediate
-   **Tags:** `arms-biceps-and-forearms`, `isolation`, `supported-curl`,
    `gym`, `exercise-library`
-   **How to perform:** Rest upper arms on pad, curl upward, then lower
    without bouncing at the bottom.
-   **Coaching / safety notes:** Do not forcefully lock elbows.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Concentration Curl

-   **ID:** `concentration-curl`
-   **Description:** Concentration Curl is a isolation; unilateral curl
    movement used to train the listed muscles.
-   **Primary muscles:** biceps brachii
-   **Secondary muscles / stabilizers:** brachialis
-   **Equipment:** dumbbell, bench
-   **Movement / type:** Isolation; unilateral curl
-   **Difficulty:** beginner to intermediate
-   **Tags:** `arms-biceps-and-forearms`, `isolation`,
    `unilateral-curl`, `gym`, `exercise-library`
-   **How to perform:** Brace upper arm against inner thigh and curl
    dumbbell toward shoulder.
-   **Coaching / safety notes:** Keep movement smooth.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Cable Biceps Curl

-   **ID:** `cable-biceps-curl`
-   **Description:** Cable Biceps Curl is a isolation; constant-tension
    curl movement used to train the listed muscles.
-   **Primary muscles:** biceps brachii
-   **Secondary muscles / stabilizers:** brachialis; brachioradialis
-   **Equipment:** cable machine, straight or EZ handle
-   **Movement / type:** Isolation; constant-tension curl
-   **Difficulty:** beginner to intermediate
-   **Tags:** `arms-biceps-and-forearms`, `isolation`,
    `constant-tension-curl`, `gym`, `exercise-library`
-   **How to perform:** Curl handle toward shoulders and lower against
    cable tension.
-   **Coaching / safety notes:** Keep elbows near the torso.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Bayesian Cable Curl

-   **ID:** `bayesian-cable-curl`
-   **Description:** Bayesian Cable Curl is a isolation;
    shoulder-extended curl movement used to train the listed muscles.
-   **Primary muscles:** biceps brachii
-   **Secondary muscles / stabilizers:** brachialis
-   **Equipment:** low cable, single handle
-   **Movement / type:** Isolation; shoulder-extended curl
-   **Difficulty:** beginner to intermediate
-   **Tags:** `arms-biceps-and-forearms`, `isolation`,
    `shoulder-extended-curl`, `gym`, `exercise-library`
-   **How to perform:** Stand facing away from low pulley with arm
    slightly behind body, curl handle upward.
-   **Coaching / safety notes:** Use a comfortable shoulder position.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Spider Curl

-   **ID:** `spider-curl`
-   **Description:** Spider Curl is a isolation; strict curl movement
    used to train the listed muscles.
-   **Primary muscles:** biceps brachii
-   **Secondary muscles / stabilizers:** brachialis
-   **Equipment:** incline bench, dumbbells or EZ bar
-   **Movement / type:** Isolation; strict curl
-   **Difficulty:** beginner to intermediate
-   **Tags:** `arms-biceps-and-forearms`, `isolation`, `strict-curl`,
    `gym`, `exercise-library`
-   **How to perform:** Lie chest-down on incline bench with arms
    hanging and curl without swinging.
-   **Coaching / safety notes:** Keep shoulders supported.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Reverse Curl

-   **ID:** `reverse-curl`
-   **Description:** Reverse Curl is a isolation; pronated curl movement
    used to train the listed muscles.
-   **Primary muscles:** brachioradialis; brachialis
-   **Secondary muscles / stabilizers:** biceps brachii; wrist extensors
-   **Equipment:** EZ bar or barbell
-   **Movement / type:** Isolation; pronated curl
-   **Difficulty:** beginner to intermediate
-   **Tags:** `arms-biceps-and-forearms`, `isolation`, `pronated-curl`,
    `gym`, `exercise-library`
-   **How to perform:** Curl with palms facing down and wrists straight.
-   **Coaching / safety notes:** Start lighter than with a standard
    curl.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Wrist Curl

-   **ID:** `wrist-curl`
-   **Description:** Wrist Curl is a isolation; wrist flexion movement
    used to train the listed muscles.
-   **Primary muscles:** wrist flexors
-   **Secondary muscles / stabilizers:** finger flexors
-   **Equipment:** dumbbells or barbell, bench
-   **Movement / type:** Isolation; wrist flexion
-   **Difficulty:** beginner to intermediate
-   **Tags:** `arms-biceps-and-forearms`, `isolation`, `wrist-flexion`,
    `gym`, `exercise-library`
-   **How to perform:** Rest forearms on thighs or bench, curl wrists
    upward, and lower slowly.
-   **Coaching / safety notes:** Move at the wrists rather than elbows.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Reverse Wrist Curl

-   **ID:** `reverse-wrist-curl`
-   **Description:** Reverse Wrist Curl is a isolation; wrist extension
    movement used to train the listed muscles.
-   **Primary muscles:** wrist extensors
-   **Secondary muscles / stabilizers:** brachioradialis
-   **Equipment:** dumbbells or barbell, bench
-   **Movement / type:** Isolation; wrist extension
-   **Difficulty:** beginner to intermediate
-   **Tags:** `arms-biceps-and-forearms`, `isolation`,
    `wrist-extension`, `gym`, `exercise-library`
-   **How to perform:** With forearms supported and palms down, lift the
    backs of hands upward.
-   **Coaching / safety notes:** Use light loads and controlled reps.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Farmer's Carry

-   **ID:** `farmer-s-carry`
-   **Description:** Farmer's Carry is a loaded carry; grip and bracing
    movement used to train the listed muscles.
-   **Primary muscles:** forearms; grip muscles
-   **Secondary muscles / stabilizers:** traps; core; glutes
-   **Equipment:** heavy dumbbells or farmer handles
-   **Movement / type:** Loaded carry; grip and bracing
-   **Difficulty:** beginner to intermediate
-   **Tags:** `arms-biceps-and-forearms`, `loaded-carry`,
    `grip-and-bracing`, `gym`, `exercise-library`
-   **How to perform:** Walk upright while holding heavy weights at your
    sides.
-   **Coaching / safety notes:** Take controlled steps and keep
    shoulders level.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Dead Hang

-   **ID:** `dead-hang`
-   **Description:** Dead Hang is a isometric; grip movement used to
    train the listed muscles.
-   **Primary muscles:** forearm/grip muscles
-   **Secondary muscles / stabilizers:** lats; shoulder stabilizers
-   **Equipment:** pull-up bar
-   **Movement / type:** Isometric; grip
-   **Difficulty:** beginner to intermediate
-   **Tags:** `arms-biceps-and-forearms`, `isometric`, `grip`, `gym`,
    `exercise-library`
-   **How to perform:** Hang from a secure bar for a chosen time,
    maintaining comfortable shoulder control.
-   **Coaching / safety notes:** Use feet support if grip or shoulders
    need scaling.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

### Arms - Triceps

#### Cable Triceps Pushdown

-   **ID:** `cable-triceps-pushdown`
-   **Description:** Cable Triceps Pushdown is a isolation; elbow
    extension movement used to train the listed muscles.
-   **Primary muscles:** triceps brachii
-   **Secondary muscles / stabilizers:** anconeus
-   **Equipment:** cable machine, rope or bar
-   **Movement / type:** Isolation; elbow extension
-   **Difficulty:** beginner to intermediate
-   **Tags:** `arms-triceps`, `isolation`, `elbow-extension`, `gym`,
    `exercise-library`
-   **How to perform:** Keep elbows by sides and straighten arms
    downward, then return slowly.
-   **Coaching / safety notes:** Do not let shoulders swing the weight.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Rope Triceps Pushdown

-   **ID:** `rope-triceps-pushdown`
-   **Description:** Rope Triceps Pushdown is a isolation; elbow
    extension movement used to train the listed muscles.
-   **Primary muscles:** triceps brachii
-   **Secondary muscles / stabilizers:** anconeus
-   **Equipment:** cable machine, rope
-   **Movement / type:** Isolation; elbow extension
-   **Difficulty:** beginner to intermediate
-   **Tags:** `arms-triceps`, `isolation`, `elbow-extension`, `gym`,
    `exercise-library`
-   **How to perform:** Push rope down and separate ends slightly at the
    bottom.
-   **Coaching / safety notes:** Keep wrists neutral.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Overhead Cable Triceps Extension

-   **ID:** `overhead-cable-triceps-extension`
-   **Description:** Overhead Cable Triceps Extension is a isolation;
    overhead elbow extension movement used to train the listed muscles.
-   **Primary muscles:** triceps brachii long head
-   **Secondary muscles / stabilizers:** other triceps heads; core
    stabilizers
-   **Equipment:** cable machine, rope
-   **Movement / type:** Isolation; overhead elbow extension
-   **Difficulty:** beginner to intermediate
-   **Tags:** `arms-triceps`, `isolation`, `overhead-elbow-extension`,
    `gym`, `exercise-library`
-   **How to perform:** Face away from pulley, elbows bent overhead,
    extend arms without flaring excessively.
-   **Coaching / safety notes:** Use a stable stance and comfortable
    shoulder range.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Dumbbell Overhead Triceps Extension

-   **ID:** `dumbbell-overhead-triceps-extension`
-   **Description:** Dumbbell Overhead Triceps Extension is a isolation;
    overhead elbow extension movement used to train the listed muscles.
-   **Primary muscles:** triceps brachii, long head emphasis
-   **Secondary muscles / stabilizers:** other triceps heads
-   **Equipment:** one dumbbell
-   **Movement / type:** Isolation; overhead elbow extension
-   **Difficulty:** beginner to intermediate
-   **Tags:** `arms-triceps`, `isolation`, `overhead-elbow-extension`,
    `gym`, `exercise-library`
-   **How to perform:** Hold dumbbell overhead, bend elbows to lower
    behind head, then extend.
-   **Coaching / safety notes:** Keep ribs down and elbows in a
    comfortable position.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Lying Triceps Extension / Skull Crusher

-   **ID:** `lying-triceps-extension-skull-crusher`
-   **Description:** Lying Triceps Extension / Skull Crusher is a
    isolation; elbow extension movement used to train the listed
    muscles.
-   **Primary muscles:** triceps brachii
-   **Secondary muscles / stabilizers:** anconeus
-   **Equipment:** EZ bar or dumbbells, bench
-   **Movement / type:** Isolation; elbow extension
-   **Difficulty:** beginner to intermediate
-   **Tags:** `arms-triceps`, `isolation`, `elbow-extension`, `gym`,
    `exercise-library`
-   **How to perform:** Lower weight toward forehead or just behind head
    by bending elbows, then extend.
-   **Coaching / safety notes:** Use controlled loads; keep upper arms
    stable.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Close-Grip Bench Press

-   **ID:** `close-grip-bench-press`
-   **Description:** Close-Grip Bench Press is a compound;
    triceps-focused press movement used to train the listed muscles.
-   **Primary muscles:** triceps brachii
-   **Secondary muscles / stabilizers:** pectoralis major; anterior
    deltoids
-   **Equipment:** barbell, flat bench
-   **Movement / type:** Compound; triceps-focused press
-   **Difficulty:** beginner to intermediate
-   **Tags:** `arms-triceps`, `compound`, `triceps-focused-press`,
    `gym`, `exercise-library`
-   **How to perform:** Use a moderately narrow grip, lower to lower
    chest, and press up.
-   **Coaching / safety notes:** Do not force hands extremely close
    together.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Dumbbell Triceps Kickback

-   **ID:** `dumbbell-triceps-kickback`
-   **Description:** Dumbbell Triceps Kickback is a isolation; elbow
    extension movement used to train the listed muscles.
-   **Primary muscles:** triceps brachii
-   **Secondary muscles / stabilizers:** anconeus
-   **Equipment:** dumbbells, bench optional
-   **Movement / type:** Isolation; elbow extension
-   **Difficulty:** beginner to intermediate
-   **Tags:** `arms-triceps`, `isolation`, `elbow-extension`, `gym`,
    `exercise-library`
-   **How to perform:** Hinge forward, keep upper arm beside torso, and
    straighten elbow behind you.
-   **Coaching / safety notes:** Use light weights and avoid shoulder
    movement.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Bench Dip

-   **ID:** `bench-dip`
-   **Description:** Bench Dip is a compound; bodyweight push movement
    used to train the listed muscles.
-   **Primary muscles:** triceps brachii
-   **Secondary muscles / stabilizers:** anterior deltoids; pectoralis
    major
-   **Equipment:** bench or sturdy parallel surfaces
-   **Movement / type:** Compound; bodyweight push
-   **Difficulty:** beginner to intermediate
-   **Tags:** `arms-triceps`, `compound`, `bodyweight-push`, `gym`,
    `exercise-library`
-   **How to perform:** Place hands on a stable bench, bend elbows to
    lower a small comfortable distance, then press up.
-   **Coaching / safety notes:** Can stress the front of the shoulder;
    use an alternative if uncomfortable.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Assisted Dip

-   **ID:** `assisted-dip`
-   **Description:** Assisted Dip is a compound; vertical push movement
    used to train the listed muscles.
-   **Primary muscles:** triceps brachii
-   **Secondary muscles / stabilizers:** pectoralis major; anterior
    deltoids
-   **Equipment:** assisted dip machine
-   **Movement / type:** Compound; vertical push
-   **Difficulty:** beginner to intermediate
-   **Tags:** `arms-triceps`, `compound`, `vertical-push`, `gym`,
    `exercise-library`
-   **How to perform:** Use assistance to lower and press between
    handles with control.
-   **Coaching / safety notes:** Choose assistance that permits smooth
    reps.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### JM Press

-   **ID:** `jm-press`
-   **Description:** JM Press is a compound/accessory; triceps press
    movement used to train the listed muscles.
-   **Primary muscles:** triceps brachii
-   **Secondary muscles / stabilizers:** pectoralis major; anterior
    deltoids
-   **Equipment:** barbell or Smith machine, bench
-   **Movement / type:** Compound/accessory; triceps press
-   **Difficulty:** advanced / skill-based
-   **Tags:** `arms-triceps`, `compound-accessory`, `triceps-press`,
    `gym`, `exercise-library`
-   **How to perform:** Lower bar toward the area between upper chest
    and chin by bending elbows, then press.
-   **Coaching / safety notes:** Technique-sensitive; start light.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Single-Arm Cable Pushdown

-   **ID:** `single-arm-cable-pushdown`
-   **Description:** Single-Arm Cable Pushdown is a isolation;
    unilateral extension movement used to train the listed muscles.
-   **Primary muscles:** triceps brachii
-   **Secondary muscles / stabilizers:** anconeus
-   **Equipment:** cable machine, single handle
-   **Movement / type:** Isolation; unilateral extension
-   **Difficulty:** beginner to intermediate
-   **Tags:** `arms-triceps`, `isolation`, `unilateral-extension`,
    `gym`, `exercise-library`
-   **How to perform:** Keep elbow close to side and extend one arm
    downward.
-   **Coaching / safety notes:** Resist torso rotation.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

### Legs - Quadriceps

#### Barbell Back Squat

-   **ID:** `barbell-back-squat`
-   **Description:** Barbell Back Squat is a compound; squat movement
    used to train the listed muscles.
-   **Primary muscles:** quadriceps; gluteus maximus
-   **Secondary muscles / stabilizers:** adductors; spinal erectors;
    core
-   **Equipment:** barbell, squat rack
-   **Movement / type:** Compound; squat
-   **Difficulty:** intermediate
-   **Tags:** `legs-quadriceps`, `compound`, `squat`, `gym`,
    `exercise-library`
-   **How to perform:** Brace, sit down between hips with feet planted,
    then drive up through the floor.
-   **Coaching / safety notes:** Use rack safeties; depth depends on
    mobility and comfort.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Barbell Front Squat

-   **ID:** `barbell-front-squat`
-   **Description:** Barbell Front Squat is a compound; upright squat
    movement used to train the listed muscles.
-   **Primary muscles:** quadriceps
-   **Secondary muscles / stabilizers:** gluteus maximus; upper back;
    core
-   **Equipment:** barbell, squat rack
-   **Movement / type:** Compound; upright squat
-   **Difficulty:** intermediate
-   **Tags:** `legs-quadriceps`, `compound`, `upright-squat`, `gym`,
    `exercise-library`
-   **How to perform:** Rest bar on front shoulders, keep torso tall,
    squat, and stand.
-   **Coaching / safety notes:** Use a secure front-rack position or
    straps if needed.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Goblet Squat

-   **ID:** `goblet-squat`
-   **Description:** Goblet Squat is a compound; squat movement used to
    train the listed muscles.
-   **Primary muscles:** quadriceps; gluteus maximus
-   **Secondary muscles / stabilizers:** adductors; core
-   **Equipment:** dumbbell or kettlebell
-   **Movement / type:** Compound; squat
-   **Difficulty:** beginner to intermediate
-   **Tags:** `legs-quadriceps`, `compound`, `squat`, `gym`,
    `exercise-library`
-   **How to perform:** Hold weight at chest, squat between hips, and
    stand while keeping torso controlled.
-   **Coaching / safety notes:** Useful for learning squat mechanics.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Dumbbell Split Squat

-   **ID:** `dumbbell-split-squat`
-   **Description:** Dumbbell Split Squat is a compound; unilateral
    squat movement used to train the listed muscles.
-   **Primary muscles:** quadriceps; gluteus maximus
-   **Secondary muscles / stabilizers:** adductors; core
-   **Equipment:** dumbbells optional
-   **Movement / type:** Compound; unilateral squat
-   **Difficulty:** beginner to intermediate
-   **Tags:** `legs-quadriceps`, `compound`, `unilateral-squat`, `gym`,
    `exercise-library`
-   **How to perform:** Take a staggered stance, lower back knee toward
    floor, and drive through front foot.
-   **Coaching / safety notes:** Keep front foot fully planted.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Bulgarian Split Squat

-   **ID:** `bulgarian-split-squat`
-   **Description:** Bulgarian Split Squat is a compound; unilateral
    squat movement used to train the listed muscles.
-   **Primary muscles:** quadriceps; gluteus maximus
-   **Secondary muscles / stabilizers:** adductors; hamstrings; core
-   **Equipment:** bench, dumbbells optional
-   **Movement / type:** Compound; unilateral squat
-   **Difficulty:** intermediate
-   **Tags:** `legs-quadriceps`, `compound`, `unilateral-squat`, `gym`,
    `exercise-library`
-   **How to perform:** Place rear foot on bench, lower vertically, then
    stand through front leg.
-   **Coaching / safety notes:** Start bodyweight and use support for
    balance.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Leg Press

-   **ID:** `leg-press`
-   **Description:** Leg Press is a compound; machine squat movement
    used to train the listed muscles.
-   **Primary muscles:** quadriceps; gluteus maximus
-   **Secondary muscles / stabilizers:** adductors; hamstrings
-   **Equipment:** leg press machine
-   **Movement / type:** Compound; machine squat
-   **Difficulty:** beginner to intermediate
-   **Tags:** `legs-quadriceps`, `compound`, `machine-squat`, `gym`,
    `exercise-library`
-   **How to perform:** Lower platform until knees bend comfortably,
    then press without locking knees hard.
-   **Coaching / safety notes:** Keep hips and lower back against pad.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Hack Squat

-   **ID:** `hack-squat`
-   **Description:** Hack Squat is a compound; machine squat movement
    used to train the listed muscles.
-   **Primary muscles:** quadriceps
-   **Secondary muscles / stabilizers:** gluteus maximus; adductors
-   **Equipment:** hack squat machine
-   **Movement / type:** Compound; machine squat
-   **Difficulty:** beginner to intermediate
-   **Tags:** `legs-quadriceps`, `compound`, `machine-squat`, `gym`,
    `exercise-library`
-   **How to perform:** Position shoulders under pads, squat to
    comfortable depth, and drive platform up.
-   **Coaching / safety notes:** Avoid bouncing at the bottom.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Smith Machine Squat

-   **ID:** `smith-machine-squat`
-   **Description:** Smith Machine Squat is a compound; guided squat
    movement used to train the listed muscles.
-   **Primary muscles:** quadriceps; gluteus maximus
-   **Secondary muscles / stabilizers:** adductors; core
-   **Equipment:** Smith machine
-   **Movement / type:** Compound; guided squat
-   **Difficulty:** beginner to intermediate
-   **Tags:** `legs-quadriceps`, `compound`, `guided-squat`, `gym`,
    `exercise-library`
-   **How to perform:** Set feet under bar in a comfortable position,
    squat, then stand.
-   **Coaching / safety notes:** Set safety stops before loading.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Leg Extension

-   **ID:** `leg-extension`
-   **Description:** Leg Extension is a isolation; knee extension
    movement used to train the listed muscles.
-   **Primary muscles:** quadriceps
-   **Secondary muscles / stabilizers:** ---
-   **Equipment:** leg extension machine
-   **Movement / type:** Isolation; knee extension
-   **Difficulty:** beginner to intermediate
-   **Tags:** `legs-quadriceps`, `isolation`, `knee-extension`, `gym`,
    `exercise-library`
-   **How to perform:** Extend knees until legs are nearly straight,
    pause, and lower slowly.
-   **Coaching / safety notes:** Align machine pivot with knee joint.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Step-Up

-   **ID:** `step-up`
-   **Description:** Step-Up is a compound; unilateral step movement
    used to train the listed muscles.
-   **Primary muscles:** quadriceps; gluteus maximus
-   **Secondary muscles / stabilizers:** hamstrings; calves; core
-   **Equipment:** box or sturdy step, optional dumbbells
-   **Movement / type:** Compound; unilateral step
-   **Difficulty:** beginner to intermediate
-   **Tags:** `legs-quadriceps`, `compound`, `unilateral-step`, `gym`,
    `exercise-library`
-   **How to perform:** Place whole foot on step, rise through that leg,
    then step down under control.
-   **Coaching / safety notes:** Choose a height that allows pelvic
    control.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Walking Lunge

-   **ID:** `walking-lunge`
-   **Description:** Walking Lunge is a compound; locomotion movement
    used to train the listed muscles.
-   **Primary muscles:** quadriceps; gluteus maximus
-   **Secondary muscles / stabilizers:** hamstrings; adductors; core
-   **Equipment:** bodyweight or dumbbells
-   **Movement / type:** Compound; locomotion
-   **Difficulty:** beginner to intermediate
-   **Tags:** `legs-quadriceps`, `compound`, `locomotion`, `gym`,
    `exercise-library`
-   **How to perform:** Step forward, lower both knees, push through
    front foot, and continue to next step.
-   **Coaching / safety notes:** Keep steps controlled and torso steady.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Reverse Lunge

-   **ID:** `reverse-lunge`
-   **Description:** Reverse Lunge is a compound; unilateral lunge
    movement used to train the listed muscles.
-   **Primary muscles:** quadriceps; gluteus maximus
-   **Secondary muscles / stabilizers:** hamstrings; adductors
-   **Equipment:** bodyweight or dumbbells
-   **Movement / type:** Compound; unilateral lunge
-   **Difficulty:** beginner to intermediate
-   **Tags:** `legs-quadriceps`, `compound`, `unilateral-lunge`, `gym`,
    `exercise-library`
-   **How to perform:** Step backward, lower under control, then push
    through front foot to return.
-   **Coaching / safety notes:** Often easier to control than forward
    lunges.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Sissy Squat

-   **ID:** `sissy-squat`
-   **Description:** Sissy Squat is a isolation-like; knee-dominant
    movement used to train the listed muscles.
-   **Primary muscles:** quadriceps
-   **Secondary muscles / stabilizers:** hip flexors; core
-   **Equipment:** sissy squat bench or bodyweight support
-   **Movement / type:** Isolation-like; knee-dominant
-   **Difficulty:** advanced / skill-based
-   **Tags:** `legs-quadriceps`, `isolation-like`, `knee-dominant`,
    `gym`, `exercise-library`
-   **How to perform:** With support, bend knees while leaning torso
    back as knees travel forward, then extend.
-   **Coaching / safety notes:** Advanced knee-loading movement; use
    only pain-free range.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

### Legs - Hamstrings and Glutes

#### Barbell Hip Thrust

-   **ID:** `barbell-hip-thrust`
-   **Description:** Barbell Hip Thrust is a compound; hip extension
    movement used to train the listed muscles.
-   **Primary muscles:** gluteus maximus
-   **Secondary muscles / stabilizers:** hamstrings; adductors; core
-   **Equipment:** barbell, bench, pad
-   **Movement / type:** Compound; hip extension
-   **Difficulty:** beginner to intermediate
-   **Tags:** `legs-hamstrings-and-glutes`, `compound`, `hip-extension`,
    `gym`, `exercise-library`
-   **How to perform:** Rest upper back on bench, drive hips upward,
    pause at top, and lower slowly.
-   **Coaching / safety notes:** Finish with hips extended, not by
    arching the lower back.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Glute Bridge

-   **ID:** `glute-bridge`
-   **Description:** Glute Bridge is a compound; hip extension movement
    used to train the listed muscles.
-   **Primary muscles:** gluteus maximus
-   **Secondary muscles / stabilizers:** hamstrings; core
-   **Equipment:** bodyweight or barbell
-   **Movement / type:** Compound; hip extension
-   **Difficulty:** beginner to intermediate
-   **Tags:** `legs-hamstrings-and-glutes`, `compound`, `hip-extension`,
    `gym`, `exercise-library`
-   **How to perform:** Lie on back with knees bent, press through feet,
    lift hips, and lower.
-   **Coaching / safety notes:** Keep ribs down and avoid overextending.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Single-Leg Glute Bridge

-   **ID:** `single-leg-glute-bridge`
-   **Description:** Single-Leg Glute Bridge is a unilateral; hip
    extension movement used to train the listed muscles.
-   **Primary muscles:** gluteus maximus
-   **Secondary muscles / stabilizers:** hamstrings; core
-   **Equipment:** bodyweight
-   **Movement / type:** Unilateral; hip extension
-   **Difficulty:** beginner to intermediate
-   **Tags:** `legs-hamstrings-and-glutes`, `unilateral`,
    `hip-extension`, `gym`, `exercise-library`
-   **How to perform:** Lift hips using one leg while keeping pelvis
    level.
-   **Coaching / safety notes:** Regress to two legs if hamstrings cramp
    or hips rotate.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Cable Glute Kickback

-   **ID:** `cable-glute-kickback`
-   **Description:** Cable Glute Kickback is a isolation; hip extension
    movement used to train the listed muscles.
-   **Primary muscles:** gluteus maximus
-   **Secondary muscles / stabilizers:** hamstrings; gluteus medius
-   **Equipment:** cable machine, ankle strap
-   **Movement / type:** Isolation; hip extension
-   **Difficulty:** beginner to intermediate
-   **Tags:** `legs-hamstrings-and-glutes`, `isolation`,
    `hip-extension`, `gym`, `exercise-library`
-   **How to perform:** With torso supported, extend leg backward
    without arching the back.
-   **Coaching / safety notes:** Use a small controlled range.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Glute Kickback Machine

-   **ID:** `glute-kickback-machine`
-   **Description:** Glute Kickback Machine is a isolation; hip
    extension movement used to train the listed muscles.
-   **Primary muscles:** gluteus maximus
-   **Secondary muscles / stabilizers:** hamstrings
-   **Equipment:** glute kickback machine
-   **Movement / type:** Isolation; hip extension
-   **Difficulty:** beginner to intermediate
-   **Tags:** `legs-hamstrings-and-glutes`, `isolation`,
    `hip-extension`, `gym`, `exercise-library`
-   **How to perform:** Press the pad backward by extending hip, then
    return slowly.
-   **Coaching / safety notes:** Adjust pad and avoid twisting.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Seated Leg Curl

-   **ID:** `seated-leg-curl`
-   **Description:** Seated Leg Curl is a isolation; knee flexion
    movement used to train the listed muscles.
-   **Primary muscles:** hamstrings
-   **Secondary muscles / stabilizers:** gastrocnemius
-   **Equipment:** seated leg curl machine
-   **Movement / type:** Isolation; knee flexion
-   **Difficulty:** beginner to intermediate
-   **Tags:** `legs-hamstrings-and-glutes`, `isolation`, `knee-flexion`,
    `gym`, `exercise-library`
-   **How to perform:** Curl heels down/back, pause, then return slowly.
-   **Coaching / safety notes:** Align knee with machine pivot.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Lying Leg Curl

-   **ID:** `lying-leg-curl`
-   **Description:** Lying Leg Curl is a isolation; knee flexion
    movement used to train the listed muscles.
-   **Primary muscles:** hamstrings
-   **Secondary muscles / stabilizers:** gastrocnemius
-   **Equipment:** lying leg curl machine
-   **Movement / type:** Isolation; knee flexion
-   **Difficulty:** beginner to intermediate
-   **Tags:** `legs-hamstrings-and-glutes`, `isolation`, `knee-flexion`,
    `gym`, `exercise-library`
-   **How to perform:** Curl pad toward glutes without lifting hips,
    then lower.
-   **Coaching / safety notes:** Keep pelvis against pad.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Standing Single-Leg Curl

-   **ID:** `standing-single-leg-curl`
-   **Description:** Standing Single-Leg Curl is a isolation; unilateral
    knee flexion movement used to train the listed muscles.
-   **Primary muscles:** hamstrings
-   **Secondary muscles / stabilizers:** gastrocnemius
-   **Equipment:** standing leg curl machine
-   **Movement / type:** Isolation; unilateral knee flexion
-   **Difficulty:** beginner to intermediate
-   **Tags:** `legs-hamstrings-and-glutes`, `isolation`,
    `unilateral-knee-flexion`, `gym`, `exercise-library`
-   **How to perform:** Curl heel toward glute and lower slowly.
-   **Coaching / safety notes:** Keep hips still.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Nordic Hamstring Curl

-   **ID:** `nordic-hamstring-curl`
-   **Description:** Nordic Hamstring Curl is a advanced; eccentric knee
    flexion movement used to train the listed muscles.
-   **Primary muscles:** hamstrings
-   **Secondary muscles / stabilizers:** gluteus maximus; calves
-   **Equipment:** Nordic bench or partner anchor
-   **Movement / type:** Advanced; eccentric knee flexion
-   **Difficulty:** advanced / skill-based
-   **Tags:** `legs-hamstrings-and-glutes`, `advanced`,
    `eccentric-knee-flexion`, `gym`, `exercise-library`
-   **How to perform:** Kneel with ankles secured, keep body straight,
    and lower forward slowly; use hands to catch and assist return.
-   **Coaching / safety notes:** Scale with band assistance or shorter
    range.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Good Morning

-   **ID:** `good-morning`
-   **Description:** Good Morning is a compound; hip hinge movement used
    to train the listed muscles.
-   **Primary muscles:** hamstrings; gluteus maximus
-   **Secondary muscles / stabilizers:** spinal erectors; adductors
-   **Equipment:** barbell, rack
-   **Movement / type:** Compound; hip hinge
-   **Difficulty:** intermediate
-   **Tags:** `legs-hamstrings-and-glutes`, `compound`, `hip-hinge`,
    `gym`, `exercise-library`
-   **How to perform:** With bar across upper back and knees soft, hinge
    hips back, then stand.
-   **Coaching / safety notes:** Use light loads until hinge mechanics
    are consistent.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Cable Pull-Through

-   **ID:** `cable-pull-through`
-   **Description:** Cable Pull-Through is a compound; hip hinge
    movement used to train the listed muscles.
-   **Primary muscles:** gluteus maximus; hamstrings
-   **Secondary muscles / stabilizers:** spinal erectors; adductors
-   **Equipment:** cable machine, rope
-   **Movement / type:** Compound; hip hinge
-   **Difficulty:** beginner to intermediate
-   **Tags:** `legs-hamstrings-and-glutes`, `compound`, `hip-hinge`,
    `gym`, `exercise-library`
-   **How to perform:** Face away from low pulley, hinge with rope
    between legs, then drive hips forward.
-   **Coaching / safety notes:** Keep arms relaxed; hips create the
    motion.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Kettlebell Swing

-   **ID:** `kettlebell-swing`
-   **Description:** Kettlebell Swing is a ballistic; hip hinge movement
    used to train the listed muscles.
-   **Primary muscles:** gluteus maximus; hamstrings
-   **Secondary muscles / stabilizers:** spinal erectors; core;
    shoulders
-   **Equipment:** kettlebell
-   **Movement / type:** Ballistic; hip hinge
-   **Difficulty:** intermediate
-   **Tags:** `legs-hamstrings-and-glutes`, `ballistic`, `hip-hinge`,
    `gym`, `exercise-library`
-   **How to perform:** Hike kettlebell back, snap hips forward to float
    it to chest height, and let it return.
-   **Coaching / safety notes:** A hip hinge, not a squat or shoulder
    raise; learn technique first.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Cable Romanian Deadlift

-   **ID:** `cable-romanian-deadlift`
-   **Description:** Cable Romanian Deadlift is a compound; hip hinge
    movement used to train the listed muscles.
-   **Primary muscles:** hamstrings; gluteus maximus
-   **Secondary muscles / stabilizers:** spinal erectors; lats
-   **Equipment:** cable machine, low pulley or rope
-   **Movement / type:** Compound; hip hinge
-   **Difficulty:** intermediate
-   **Tags:** `legs-hamstrings-and-glutes`, `compound`, `hip-hinge`,
    `gym`, `exercise-library`
-   **How to perform:** Hinge hips back against cable pull, then stand
    by driving hips forward.
-   **Coaching / safety notes:** Maintain a braced torso.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

### Legs - Calves and Adductors/Abductors

#### Standing Calf Raise

-   **ID:** `standing-calf-raise`
-   **Description:** Standing Calf Raise is a isolation; plantar flexion
    movement used to train the listed muscles.
-   **Primary muscles:** gastrocnemius
-   **Secondary muscles / stabilizers:** soleus
-   **Equipment:** calf raise machine or step
-   **Movement / type:** Isolation; plantar flexion
-   **Difficulty:** beginner to intermediate
-   **Tags:** `legs-calves-and-adductors/abductors`, `isolation`,
    `plantar-flexion`, `gym`, `exercise-library`
-   **How to perform:** Rise onto balls of feet, pause, and lower heels
    through a comfortable stretch.
-   **Coaching / safety notes:** Avoid bouncing; use support for
    balance.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Seated Calf Raise

-   **ID:** `seated-calf-raise`
-   **Description:** Seated Calf Raise is a isolation; plantar flexion
    movement used to train the listed muscles.
-   **Primary muscles:** soleus
-   **Secondary muscles / stabilizers:** gastrocnemius
-   **Equipment:** seated calf raise machine
-   **Movement / type:** Isolation; plantar flexion
-   **Difficulty:** beginner to intermediate
-   **Tags:** `legs-calves-and-adductors/abductors`, `isolation`,
    `plantar-flexion`, `gym`, `exercise-library`
-   **How to perform:** With knees bent, raise heels, pause, and lower
    slowly.
-   **Coaching / safety notes:** Use full controlled range.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Leg Press Calf Raise

-   **ID:** `leg-press-calf-raise`
-   **Description:** Leg Press Calf Raise is a isolation; plantar
    flexion movement used to train the listed muscles.
-   **Primary muscles:** gastrocnemius; soleus
-   **Secondary muscles / stabilizers:** ---
-   **Equipment:** leg press machine
-   **Movement / type:** Isolation; plantar flexion
-   **Difficulty:** beginner to intermediate
-   **Tags:** `legs-calves-and-adductors/abductors`, `isolation`,
    `plantar-flexion`, `gym`, `exercise-library`
-   **How to perform:** Place forefeet on platform, lower heels, then
    press through the balls of feet.
-   **Coaching / safety notes:** Keep knees softly extended and safety
    latch engaged.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Single-Leg Calf Raise

-   **ID:** `single-leg-calf-raise`
-   **Description:** Single-Leg Calf Raise is a unilateral; plantar
    flexion movement used to train the listed muscles.
-   **Primary muscles:** gastrocnemius; soleus
-   **Secondary muscles / stabilizers:** foot stabilizers
-   **Equipment:** step or floor
-   **Movement / type:** Unilateral; plantar flexion
-   **Difficulty:** beginner to intermediate
-   **Tags:** `legs-calves-and-adductors/abductors`, `unilateral`,
    `plantar-flexion`, `gym`, `exercise-library`
-   **How to perform:** Rise on one foot, pause, then lower slowly.
-   **Coaching / safety notes:** Hold a rail for balance if needed.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Tibialis Raise

-   **ID:** `tibialis-raise`
-   **Description:** Tibialis Raise is a isolation; dorsiflexion
    movement used to train the listed muscles.
-   **Primary muscles:** tibialis anterior
-   **Secondary muscles / stabilizers:** toe extensors
-   **Equipment:** wall or tibialis raise machine
-   **Movement / type:** Isolation; dorsiflexion
-   **Difficulty:** beginner to intermediate
-   **Tags:** `legs-calves-and-adductors/abductors`, `isolation`,
    `dorsiflexion`, `gym`, `exercise-library`
-   **How to perform:** Keep heels grounded and lift toes toward shins,
    then lower.
-   **Coaching / safety notes:** Useful complement to calf work.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Hip Adduction Machine

-   **ID:** `hip-adduction-machine`
-   **Description:** Hip Adduction Machine is a isolation; hip adduction
    movement used to train the listed muscles.
-   **Primary muscles:** hip adductors
-   **Secondary muscles / stabilizers:** gracilis; pectineus
-   **Equipment:** hip adduction machine
-   **Movement / type:** Isolation; hip adduction
-   **Difficulty:** beginner to intermediate
-   **Tags:** `legs-calves-and-adductors/abductors`, `isolation`,
    `hip-adduction`, `gym`, `exercise-library`
-   **How to perform:** Bring padded thighs together, pause, and return
    slowly.
-   **Coaching / safety notes:** Use a comfortable range; do not force
    the stretch.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Cable Hip Adduction

-   **ID:** `cable-hip-adduction`
-   **Description:** Cable Hip Adduction is a isolation; unilateral
    adduction movement used to train the listed muscles.
-   **Primary muscles:** hip adductors
-   **Secondary muscles / stabilizers:** gracilis; pectineus
-   **Equipment:** low cable, ankle strap
-   **Movement / type:** Isolation; unilateral adduction
-   **Difficulty:** beginner to intermediate
-   **Tags:** `legs-calves-and-adductors/abductors`, `isolation`,
    `unilateral-adduction`, `gym`, `exercise-library`
-   **How to perform:** Stand side-on to cable and draw working leg
    across the body's midline.
-   **Coaching / safety notes:** Hold support and keep pelvis level.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Hip Abduction Machine

-   **ID:** `hip-abduction-machine`
-   **Description:** Hip Abduction Machine is a isolation; hip abduction
    movement used to train the listed muscles.
-   **Primary muscles:** gluteus medius; gluteus minimus
-   **Secondary muscles / stabilizers:** tensor fasciae latae
-   **Equipment:** hip abduction machine
-   **Movement / type:** Isolation; hip abduction
-   **Difficulty:** beginner to intermediate
-   **Tags:** `legs-calves-and-adductors/abductors`, `isolation`,
    `hip-abduction`, `gym`, `exercise-library`
-   **How to perform:** Push knees outward against pads, pause, and
    return slowly.
-   **Coaching / safety notes:** Avoid rocking the torso.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Cable Hip Abduction

-   **ID:** `cable-hip-abduction`
-   **Description:** Cable Hip Abduction is a isolation; unilateral
    abduction movement used to train the listed muscles.
-   **Primary muscles:** gluteus medius; gluteus minimus
-   **Secondary muscles / stabilizers:** tensor fasciae latae
-   **Equipment:** low cable, ankle strap
-   **Movement / type:** Isolation; unilateral abduction
-   **Difficulty:** beginner to intermediate
-   **Tags:** `legs-calves-and-adductors/abductors`, `isolation`,
    `unilateral-abduction`, `gym`, `exercise-library`
-   **How to perform:** Stand side-on and move working leg outward
    without tilting torso.
-   **Coaching / safety notes:** Use light resistance and stable
    support.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Clamshell

-   **ID:** `clamshell`
-   **Description:** Clamshell is a accessory; hip external rotation
    movement used to train the listed muscles.
-   **Primary muscles:** gluteus medius; gluteus minimus
-   **Secondary muscles / stabilizers:** deep hip external rotators
-   **Equipment:** mini-band optional, mat
-   **Movement / type:** Accessory; hip external rotation
-   **Difficulty:** beginner to intermediate
-   **Tags:** `legs-calves-and-adductors/abductors`, `accessory`,
    `hip-external-rotation`, `gym`, `exercise-library`
-   **How to perform:** Lie on side with knees bent, keep feet together,
    and open top knee without rolling pelvis.
-   **Coaching / safety notes:** Use slow, small movements.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

### Core and Abs

#### Crunch

-   **ID:** `crunch`
-   **Description:** Crunch is a isolation; trunk flexion movement used
    to train the listed muscles.
-   **Primary muscles:** rectus abdominis
-   **Secondary muscles / stabilizers:** obliques
-   **Equipment:** mat
-   **Movement / type:** Isolation; trunk flexion
-   **Difficulty:** beginner to intermediate
-   **Tags:** `core-and-abs`, `isolation`, `trunk-flexion`, `gym`,
    `exercise-library`
-   **How to perform:** Curl shoulders toward pelvis without pulling the
    neck, then lower slowly.
-   **Coaching / safety notes:** Think ribs toward hips; avoid yanking
    the head.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Reverse Crunch

-   **ID:** `reverse-crunch`
-   **Description:** Reverse Crunch is a isolation; posterior pelvic
    tilt movement used to train the listed muscles.
-   **Primary muscles:** rectus abdominis
-   **Secondary muscles / stabilizers:** hip flexors
-   **Equipment:** mat or bench
-   **Movement / type:** Isolation; posterior pelvic tilt
-   **Difficulty:** beginner to intermediate
-   **Tags:** `core-and-abs`, `isolation`, `posterior-pelvic-tilt`,
    `gym`, `exercise-library`
-   **How to perform:** Bring knees toward chest by curling pelvis off
    floor, then lower with control.
-   **Coaching / safety notes:** Avoid swinging legs.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Sit-Up

-   **ID:** `sit-up`
-   **Description:** Sit-Up is a compound; trunk flexion movement used
    to train the listed muscles.
-   **Primary muscles:** rectus abdominis
-   **Secondary muscles / stabilizers:** hip flexors; obliques
-   **Equipment:** mat or decline bench
-   **Movement / type:** Compound; trunk flexion
-   **Difficulty:** beginner to intermediate
-   **Tags:** `core-and-abs`, `compound`, `trunk-flexion`, `gym`,
    `exercise-library`
-   **How to perform:** Raise torso from floor to seated position and
    lower slowly.
-   **Coaching / safety notes:** Use a range that feels comfortable for
    the back.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Cable Crunch

-   **ID:** `cable-crunch`
-   **Description:** Cable Crunch is a isolation; loaded trunk flexion
    movement used to train the listed muscles.
-   **Primary muscles:** rectus abdominis
-   **Secondary muscles / stabilizers:** obliques
-   **Equipment:** cable machine, rope
-   **Movement / type:** Isolation; loaded trunk flexion
-   **Difficulty:** beginner to intermediate
-   **Tags:** `core-and-abs`, `isolation`, `loaded-trunk-flexion`,
    `gym`, `exercise-library`
-   **How to perform:** Kneel under cable and curl ribs toward pelvis
    while keeping hips mostly fixed.
-   **Coaching / safety notes:** Do not simply hinge at hips.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Hanging Knee Raise

-   **ID:** `hanging-knee-raise`
-   **Description:** Hanging Knee Raise is a compound; trunk/pelvic
    control movement used to train the listed muscles.
-   **Primary muscles:** rectus abdominis
-   **Secondary muscles / stabilizers:** hip flexors; obliques; grip
-   **Equipment:** pull-up/dip station
-   **Movement / type:** Compound; trunk/pelvic control
-   **Difficulty:** beginner to intermediate
-   **Tags:** `core-and-abs`, `compound`, `trunk-pelvic-control`, `gym`,
    `exercise-library`
-   **How to perform:** Hang securely, lift knees toward torso, and
    lower without swinging.
-   **Coaching / safety notes:** Use captain's chair or supported
    version to scale.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Hanging Leg Raise

-   **ID:** `hanging-leg-raise`
-   **Description:** Hanging Leg Raise is a advanced; trunk/pelvic
    control movement used to train the listed muscles.
-   **Primary muscles:** rectus abdominis
-   **Secondary muscles / stabilizers:** hip flexors; obliques; grip
-   **Equipment:** pull-up bar
-   **Movement / type:** Advanced; trunk/pelvic control
-   **Difficulty:** intermediate
-   **Tags:** `core-and-abs`, `advanced`, `trunk-pelvic-control`, `gym`,
    `exercise-library`
-   **How to perform:** Raise straight or slightly bent legs under
    control, then lower without swinging.
-   **Coaching / safety notes:** Progress from knee raises.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Captain's Chair Knee Raise

-   **ID:** `captain-s-chair-knee-raise`
-   **Description:** Captain's Chair Knee Raise is a compound; knee
    raise movement used to train the listed muscles.
-   **Primary muscles:** rectus abdominis
-   **Secondary muscles / stabilizers:** hip flexors; obliques
-   **Equipment:** captain's chair station
-   **Movement / type:** Compound; knee raise
-   **Difficulty:** beginner to intermediate
-   **Tags:** `core-and-abs`, `compound`, `knee-raise`, `gym`,
    `exercise-library`
-   **How to perform:** Support forearms on pads and lift knees toward
    chest, then lower slowly.
-   **Coaching / safety notes:** Keep lower back controlled against pad
    if possible.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Ab Wheel Rollout

-   **ID:** `ab-wheel-rollout`
-   **Description:** Ab Wheel Rollout is a advanced; anti-extension
    movement used to train the listed muscles.
-   **Primary muscles:** rectus abdominis
-   **Secondary muscles / stabilizers:** obliques; lats; shoulders
-   **Equipment:** ab wheel, mat
-   **Movement / type:** Advanced; anti-extension
-   **Difficulty:** advanced / skill-based
-   **Tags:** `core-and-abs`, `advanced`, `anti-extension`, `gym`,
    `exercise-library`
-   **How to perform:** From knees, roll wheel forward while keeping
    ribs down, then pull back.
-   **Coaching / safety notes:** Shorten range or use wall target to
    prevent back arching.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Plank

-   **ID:** `plank`
-   **Description:** Plank is a isometric; anti-extension movement used
    to train the listed muscles.
-   **Primary muscles:** transverse abdominis; rectus abdominis
-   **Secondary muscles / stabilizers:** obliques; glutes; shoulders
-   **Equipment:** mat
-   **Movement / type:** Isometric; anti-extension
-   **Difficulty:** beginner / scalable
-   **Tags:** `core-and-abs`, `isometric`, `anti-extension`, `gym`,
    `exercise-library`
-   **How to perform:** Keep elbows under shoulders and body in a
    straight line while bracing.
-   **Coaching / safety notes:** Stop when hips sag or lower back
    arches.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Side Plank

-   **ID:** `side-plank`
-   **Description:** Side Plank is a isometric; lateral stability
    movement used to train the listed muscles.
-   **Primary muscles:** obliques; quadratus lumborum
-   **Secondary muscles / stabilizers:** gluteus medius; transverse
    abdominis
-   **Equipment:** mat
-   **Movement / type:** Isometric; lateral stability
-   **Difficulty:** beginner to intermediate
-   **Tags:** `core-and-abs`, `isometric`, `lateral-stability`, `gym`,
    `exercise-library`
-   **How to perform:** Support on forearm and side of foot, lift hips,
    and keep body aligned.
-   **Coaching / safety notes:** Bend knees to make it easier.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Pallof Press

-   **ID:** `pallof-press`
-   **Description:** Pallof Press is a anti-rotation; core stability
    movement used to train the listed muscles.
-   **Primary muscles:** obliques; transverse abdominis
-   **Secondary muscles / stabilizers:** glutes; shoulders
-   **Equipment:** cable or resistance band
-   **Movement / type:** Anti-rotation; core stability
-   **Difficulty:** beginner to intermediate
-   **Tags:** `core-and-abs`, `anti-rotation`, `core-stability`, `gym`,
    `exercise-library`
-   **How to perform:** Stand side-on to anchor, press handle straight
    out, resist rotation, and return.
-   **Coaching / safety notes:** Keep hips and shoulders square.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Dead Bug

-   **ID:** `dead-bug`
-   **Description:** Dead Bug is a core stability; anti-extension
    movement used to train the listed muscles.
-   **Primary muscles:** transverse abdominis; rectus abdominis
-   **Secondary muscles / stabilizers:** hip flexors; obliques
-   **Equipment:** mat
-   **Movement / type:** Core stability; anti-extension
-   **Difficulty:** beginner / scalable
-   **Tags:** `core-and-abs`, `core-stability`, `anti-extension`, `gym`,
    `exercise-library`
-   **How to perform:** On back, lower opposite arm and leg while
    keeping lower back gently controlled, then alternate.
-   **Coaching / safety notes:** Reduce range if back lifts off floor.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Bird Dog

-   **ID:** `bird-dog`
-   **Description:** Bird Dog is a core stability; contralateral control
    movement used to train the listed muscles.
-   **Primary muscles:** multifidus; spinal stabilizers
-   **Secondary muscles / stabilizers:** gluteus maximus; shoulders;
    core
-   **Equipment:** mat
-   **Movement / type:** Core stability; contralateral control
-   **Difficulty:** beginner / scalable
-   **Tags:** `core-and-abs`, `core-stability`, `contralateral-control`,
    `gym`, `exercise-library`
-   **How to perform:** On hands and knees, extend opposite arm and leg
    without rotating pelvis.
-   **Coaching / safety notes:** Move slowly and keep spine neutral.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Russian Twist

-   **ID:** `russian-twist`
-   **Description:** Russian Twist is a rotational core movement used to
    train the listed muscles.
-   **Primary muscles:** obliques
-   **Secondary muscles / stabilizers:** rectus abdominis; hip flexors
-   **Equipment:** bodyweight or medicine ball
-   **Movement / type:** Rotational core
-   **Difficulty:** beginner to intermediate
-   **Tags:** `core-and-abs`, `rotational-core`, `gym`,
    `exercise-library`
-   **How to perform:** Lean back slightly and rotate torso side to side
    with control.
-   **Coaching / safety notes:** Avoid rapid twisting under heavy load.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Wood Chop

-   **ID:** `wood-chop`
-   **Description:** Wood Chop is a rotational core; diagonal pull
    movement used to train the listed muscles.
-   **Primary muscles:** obliques
-   **Secondary muscles / stabilizers:** rectus abdominis; shoulders;
    hips
-   **Equipment:** cable machine or resistance band
-   **Movement / type:** Rotational core; diagonal pull
-   **Difficulty:** beginner to intermediate
-   **Tags:** `core-and-abs`, `rotational-core`, `diagonal-pull`, `gym`,
    `exercise-library`
-   **How to perform:** Pull handle diagonally across body by rotating
    torso and hips together in a controlled way.
-   **Coaching / safety notes:** Keep load light enough to control the
    rotation.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Back Extension Hold

-   **ID:** `back-extension-hold`
-   **Description:** Back Extension Hold is a isometric; posterior chain
    movement used to train the listed muscles.
-   **Primary muscles:** spinal erectors
-   **Secondary muscles / stabilizers:** glutes; hamstrings
-   **Equipment:** back extension bench or mat
-   **Movement / type:** Isometric; posterior chain
-   **Difficulty:** beginner to intermediate
-   **Tags:** `core-and-abs`, `isometric`, `posterior-chain`, `gym`,
    `exercise-library`
-   **How to perform:** Hold a neutral straight-body position without
    overextending the spine.
-   **Coaching / safety notes:** Use short holds and stop if discomfort
    occurs.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Suitcase Carry

-   **ID:** `suitcase-carry`
-   **Description:** Suitcase Carry is a loaded carry; anti-lateral
    flexion movement used to train the listed muscles.
-   **Primary muscles:** obliques; quadratus lumborum
-   **Secondary muscles / stabilizers:** grip; traps; glutes
-   **Equipment:** one dumbbell or kettlebell
-   **Movement / type:** Loaded carry; anti-lateral flexion
-   **Difficulty:** beginner to intermediate
-   **Tags:** `core-and-abs`, `loaded-carry`, `anti-lateral-flexion`,
    `gym`, `exercise-library`
-   **How to perform:** Walk holding one weight at your side without
    leaning.
-   **Coaching / safety notes:** Switch sides and keep steps controlled.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

### Full Body, Olympic and Conditioning

#### Barbell Clean

-   **ID:** `barbell-clean`
-   **Description:** Barbell Clean is a explosive; olympic lift movement
    used to train the listed muscles.
-   **Primary muscles:** quadriceps; gluteus maximus; traps
-   **Secondary muscles / stabilizers:** hamstrings; shoulders; core
-   **Equipment:** barbell, bumper plates
-   **Movement / type:** Explosive; Olympic lift
-   **Difficulty:** advanced / skill-based
-   **Tags:** `full-body,-olympic-and-conditioning`, `explosive`,
    `olympic-lift`, `gym`, `exercise-library`
-   **How to perform:** Accelerate bar from floor or hang and receive it
    on front shoulders.
-   **Coaching / safety notes:** Technical lift; learn with a qualified
    coach and light load.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Power Clean

-   **ID:** `power-clean`
-   **Description:** Power Clean is a explosive; olympic lift movement
    used to train the listed muscles.
-   **Primary muscles:** gluteus maximus; quadriceps; traps
-   **Secondary muscles / stabilizers:** hamstrings; shoulders; core
-   **Equipment:** barbell, bumper plates
-   **Movement / type:** Explosive; Olympic lift
-   **Difficulty:** advanced / skill-based
-   **Tags:** `full-body,-olympic-and-conditioning`, `explosive`,
    `olympic-lift`, `gym`, `exercise-library`
-   **How to perform:** Explosively extend hips and legs, then catch bar
    in a partial squat.
-   **Coaching / safety notes:** Prioritize technique and safe catch
    position.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Push Press

-   **ID:** `push-press`
-   **Description:** Push Press is a compound; explosive vertical push
    movement used to train the listed muscles.
-   **Primary muscles:** deltoids; triceps
-   **Secondary muscles / stabilizers:** quadriceps; glutes; core
-   **Equipment:** barbell or dumbbells
-   **Movement / type:** Compound; explosive vertical push
-   **Difficulty:** intermediate
-   **Tags:** `full-body,-olympic-and-conditioning`, `compound`,
    `explosive-vertical-push`, `gym`, `exercise-library`
-   **How to perform:** Dip slightly through knees, drive upward, and
    press weight overhead.
-   **Coaching / safety notes:** Keep dip vertical and brace torso.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Thruster

-   **ID:** `thruster`
-   **Description:** Thruster is a compound; squat-to-press movement
    used to train the listed muscles.
-   **Primary muscles:** quadriceps; gluteus maximus; deltoids
-   **Secondary muscles / stabilizers:** triceps; core
-   **Equipment:** barbell or dumbbells
-   **Movement / type:** Compound; squat-to-press
-   **Difficulty:** intermediate
-   **Tags:** `full-body,-olympic-and-conditioning`, `compound`,
    `squat-to-press`, `gym`, `exercise-library`
-   **How to perform:** Squat with weights at shoulders and use the
    stand-up drive to press overhead.
-   **Coaching / safety notes:** Use manageable load and maintain
    control.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Kettlebell Goblet Carry

-   **ID:** `kettlebell-goblet-carry`
-   **Description:** Kettlebell Goblet Carry is a loaded carry; bracing
    movement used to train the listed muscles.
-   **Primary muscles:** core; upper back
-   **Secondary muscles / stabilizers:** quadriceps; glutes; grip
-   **Equipment:** kettlebell
-   **Movement / type:** Loaded carry; bracing
-   **Difficulty:** beginner to intermediate
-   **Tags:** `full-body,-olympic-and-conditioning`, `loaded-carry`,
    `bracing`, `gym`, `exercise-library`
-   **How to perform:** Hold kettlebell at chest and walk upright with
    steady breathing.
-   **Coaching / safety notes:** Keep ribs stacked over pelvis.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Battle Rope Waves

-   **ID:** `battle-rope-waves`
-   **Description:** Battle Rope Waves is a conditioning; upper-body
    endurance movement used to train the listed muscles.
-   **Primary muscles:** shoulders; forearms
-   **Secondary muscles / stabilizers:** core; upper back
-   **Equipment:** battle ropes
-   **Movement / type:** Conditioning; upper-body endurance
-   **Difficulty:** beginner to intermediate
-   **Tags:** `full-body,-olympic-and-conditioning`, `conditioning`,
    `upper-body-endurance`, `gym`, `exercise-library`
-   **How to perform:** Create alternating or simultaneous rope waves
    while maintaining athletic stance.
-   **Coaching / safety notes:** Choose intervals appropriate to fitness
    level.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Sled Push

-   **ID:** `sled-push`
-   **Description:** Sled Push is a conditioning; horizontal drive
    movement used to train the listed muscles.
-   **Primary muscles:** quadriceps; gluteus maximus; calves
-   **Secondary muscles / stabilizers:** core; shoulders
-   **Equipment:** weighted sled
-   **Movement / type:** Conditioning; horizontal drive
-   **Difficulty:** beginner to intermediate
-   **Tags:** `full-body,-olympic-and-conditioning`, `conditioning`,
    `horizontal-drive`, `gym`, `exercise-library`
-   **How to perform:** Lean into handles and drive sled forward with
    short powerful steps.
-   **Coaching / safety notes:** Use a clear, non-slip path.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Sled Pull

-   **ID:** `sled-pull`
-   **Description:** Sled Pull is a conditioning; pull movement used to
    train the listed muscles.
-   **Primary muscles:** back; biceps; legs depending on setup
-   **Secondary muscles / stabilizers:** grip; core
-   **Equipment:** weighted sled, rope or harness
-   **Movement / type:** Conditioning; pull
-   **Difficulty:** beginner to intermediate
-   **Tags:** `full-body,-olympic-and-conditioning`, `conditioning`,
    `pull`, `gym`, `exercise-library`
-   **How to perform:** Walk backward or hand-over-hand pull sled using
    controlled steps.
-   **Coaching / safety notes:** Secure rope and keep the path clear.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Burpee

-   **ID:** `burpee`
-   **Description:** Burpee is a full-body conditioning movement used to
    train the listed muscles.
-   **Primary muscles:** quadriceps; chest; shoulders
-   **Secondary muscles / stabilizers:** triceps; core; calves
-   **Equipment:** bodyweight, optional mat
-   **Movement / type:** Full-body conditioning
-   **Difficulty:** beginner to intermediate
-   **Tags:** `full-body,-olympic-and-conditioning`,
    `full-body-conditioning`, `gym`, `exercise-library`
-   **How to perform:** Squat down, place hands on floor, step or jump
    to plank, return to squat, and stand or jump.
-   **Coaching / safety notes:** Use step-back variation to reduce
    impact.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Mountain Climber

-   **ID:** `mountain-climber`
-   **Description:** Mountain Climber is a conditioning; anti-extension
    movement used to train the listed muscles.
-   **Primary muscles:** core; hip flexors
-   **Secondary muscles / stabilizers:** shoulders; quadriceps
-   **Equipment:** bodyweight, mat
-   **Movement / type:** Conditioning; anti-extension
-   **Difficulty:** beginner to intermediate
-   **Tags:** `full-body,-olympic-and-conditioning`, `conditioning`,
    `anti-extension`, `gym`, `exercise-library`
-   **How to perform:** From plank, alternate driving knees toward chest
    while keeping hips steady.
-   **Coaching / safety notes:** Slow it down if hips bounce.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Jump Squat

-   **ID:** `jump-squat`
-   **Description:** Jump Squat is a plyometric; lower body movement
    used to train the listed muscles.
-   **Primary muscles:** quadriceps; gluteus maximus; calves
-   **Secondary muscles / stabilizers:** hamstrings; core
-   **Equipment:** bodyweight
-   **Movement / type:** Plyometric; lower body
-   **Difficulty:** advanced / skill-based
-   **Tags:** `full-body,-olympic-and-conditioning`, `plyometric`,
    `lower-body`, `gym`, `exercise-library`
-   **How to perform:** Squat to a comfortable depth, jump explosively,
    and land softly before the next rep.
-   **Coaching / safety notes:** Avoid if impact is unsuitable;
    prioritize quiet landings.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Box Jump

-   **ID:** `box-jump`
-   **Description:** Box Jump is a plyometric; power movement used to
    train the listed muscles.
-   **Primary muscles:** quadriceps; gluteus maximus; calves
-   **Secondary muscles / stabilizers:** hamstrings; core
-   **Equipment:** stable plyometric box
-   **Movement / type:** Plyometric; power
-   **Difficulty:** advanced / skill-based
-   **Tags:** `full-body,-olympic-and-conditioning`, `plyometric`,
    `power`, `gym`, `exercise-library`
-   **How to perform:** Jump onto a stable box, land softly, stand, and
    step down.
-   **Coaching / safety notes:** Choose a height that allows safe
    landing; do not jump down repeatedly.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Medicine Ball Slam

-   **ID:** `medicine-ball-slam`
-   **Description:** Medicine Ball Slam is a power; full body movement
    used to train the listed muscles.
-   **Primary muscles:** core; lats; shoulders
-   **Secondary muscles / stabilizers:** glutes; quadriceps
-   **Equipment:** medicine ball designed for slams
-   **Movement / type:** Power; full body
-   **Difficulty:** beginner to intermediate
-   **Tags:** `full-body,-olympic-and-conditioning`, `power`,
    `full-body`, `gym`, `exercise-library`
-   **How to perform:** Raise ball overhead, brace, slam to floor, and
    retrieve with safe hinge mechanics.
-   **Coaching / safety notes:** Use a slam-safe ball and clear floor
    space.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Turkish Get-Up

-   **ID:** `turkish-get-up`
-   **Description:** Turkish Get-Up is a full-body stability; skill
    movement used to train the listed muscles.
-   **Primary muscles:** shoulders; core; glutes
-   **Secondary muscles / stabilizers:** legs; upper back
-   **Equipment:** kettlebell or dumbbell, mat
-   **Movement / type:** Full-body stability; skill
-   **Difficulty:** advanced / skill-based
-   **Tags:** `full-body,-olympic-and-conditioning`,
    `full-body-stability`, `skill`, `gym`, `exercise-library`
-   **How to perform:** Move from lying to standing while keeping weight
    overhead, reversing each step slowly.
-   **Coaching / safety notes:** Learn unloaded first; highly technical
    movement.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Bear Crawl

-   **ID:** `bear-crawl`
-   **Description:** Bear Crawl is a locomotion; full-body stability
    movement used to train the listed muscles.
-   **Primary muscles:** core; shoulders; quadriceps
-   **Secondary muscles / stabilizers:** glutes; calves
-   **Equipment:** bodyweight, floor
-   **Movement / type:** Locomotion; full-body stability
-   **Difficulty:** beginner to intermediate
-   **Tags:** `full-body,-olympic-and-conditioning`, `locomotion`,
    `full-body-stability`, `gym`, `exercise-library`
-   **How to perform:** Move on hands and feet with knees hovering,
    keeping hips level.
-   **Coaching / safety notes:** Take small controlled steps.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

### Mobility, Warm-Up and Rehabilitation-Oriented

#### Band Pull-Apart

-   **ID:** `band-pull-apart`
-   **Description:** Band Pull-Apart is a accessory; shoulder control
    movement used to train the listed muscles.
-   **Primary muscles:** rear deltoids; rhomboids; middle trapezius
-   **Secondary muscles / stabilizers:** rotator cuff
-   **Equipment:** resistance band
-   **Movement / type:** Accessory; shoulder control
-   **Difficulty:** beginner / scalable
-   **Tags:** `mobility,-warm-up-and-rehabilitation-oriented`,
    `accessory`, `shoulder-control`, `gym`, `exercise-library`
-   **How to perform:** Hold band at chest height and pull hands apart,
    then return slowly.
-   **Coaching / safety notes:** Keep shoulders down and use light
    tension.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Band External Rotation

-   **ID:** `band-external-rotation`
-   **Description:** Band External Rotation is a rotator cuff accessory
    movement used to train the listed muscles.
-   **Primary muscles:** infraspinatus; teres minor
-   **Secondary muscles / stabilizers:** rear deltoids; scapular
    stabilizers
-   **Equipment:** resistance band
-   **Movement / type:** Rotator cuff accessory
-   **Difficulty:** beginner to intermediate
-   **Tags:** `mobility,-warm-up-and-rehabilitation-oriented`,
    `rotator-cuff-accessory`, `gym`, `exercise-library`
-   **How to perform:** With elbow tucked to side, rotate forearm
    outward against band.
-   **Coaching / safety notes:** Use light resistance and avoid pain.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Scapular Push-Up

-   **ID:** `scapular-push-up`
-   **Description:** Scapular Push-Up is a accessory; scapular control
    movement used to train the listed muscles.
-   **Primary muscles:** serratus anterior
-   **Secondary muscles / stabilizers:** pectoralis minor; core
-   **Equipment:** bodyweight
-   **Movement / type:** Accessory; scapular control
-   **Difficulty:** beginner to intermediate
-   **Tags:** `mobility,-warm-up-and-rehabilitation-oriented`,
    `accessory`, `scapular-control`, `gym`, `exercise-library`
-   **How to perform:** In plank, keep elbows straight and let chest
    sink slightly, then push floor away by spreading shoulder blades.
-   **Coaching / safety notes:** Small range; do not bend elbows.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Wall Slide

-   **ID:** `wall-slide`
-   **Description:** Wall Slide is a mobility/control; scapular upward
    rotation movement used to train the listed muscles.
-   **Primary muscles:** serratus anterior; lower trapezius
-   **Secondary muscles / stabilizers:** rotator cuff
-   **Equipment:** wall, optional mini-band
-   **Movement / type:** Mobility/control; scapular upward rotation
-   **Difficulty:** beginner / scalable
-   **Tags:** `mobility,-warm-up-and-rehabilitation-oriented`,
    `mobility-control`, `scapular-upward-rotation`, `gym`,
    `exercise-library`
-   **How to perform:** Place forearms on wall and slide upward while
    keeping ribs down.
-   **Coaching / safety notes:** Stay within comfortable range.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Cat-Cow

-   **ID:** `cat-cow`
-   **Description:** Cat-Cow is a mobility; warm-up movement used to
    train the listed muscles.
-   **Primary muscles:** spinal mobility; trunk stabilizers
-   **Secondary muscles / stabilizers:** ---
-   **Equipment:** mat
-   **Movement / type:** Mobility; warm-up
-   **Difficulty:** beginner / scalable
-   **Tags:** `mobility,-warm-up-and-rehabilitation-oriented`,
    `mobility`, `warm-up`, `gym`, `exercise-library`
-   **How to perform:** On hands and knees, gently alternate rounding
    and extending the spine with breath.
-   **Coaching / safety notes:** Move smoothly, not forcefully.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### World's Greatest Stretch

-   **ID:** `world-s-greatest-stretch`
-   **Description:** World's Greatest Stretch is a mobility; dynamic
    warm-up movement used to train the listed muscles.
-   **Primary muscles:** hip flexors; glutes; thoracic mobility
-   **Secondary muscles / stabilizers:** hamstrings; adductors
-   **Equipment:** mat
-   **Movement / type:** Mobility; dynamic warm-up
-   **Difficulty:** beginner / scalable
-   **Tags:** `mobility,-warm-up-and-rehabilitation-oriented`,
    `mobility`, `dynamic-warm-up`, `gym`, `exercise-library`
-   **How to perform:** From a lunge, place hand down and rotate the
    opposite arm upward, then switch sides.
-   **Coaching / safety notes:** Use a stable stance and comfortable
    range.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Bodyweight Squat

-   **ID:** `bodyweight-squat`
-   **Description:** Bodyweight Squat is a warm-up; squat pattern
    movement used to train the listed muscles.
-   **Primary muscles:** quadriceps; gluteus maximus
-   **Secondary muscles / stabilizers:** adductors; core
-   **Equipment:** bodyweight
-   **Movement / type:** Warm-up; squat pattern
-   **Difficulty:** beginner / scalable
-   **Tags:** `mobility,-warm-up-and-rehabilitation-oriented`,
    `warm-up`, `squat-pattern`, `gym`, `exercise-library`
-   **How to perform:** Squat with feet planted and stand smoothly.
-   **Coaching / safety notes:** Use as a warm-up or movement practice.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Hip Hinge Drill

-   **ID:** `hip-hinge-drill`
-   **Description:** Hip Hinge Drill is a movement skill; warm-up
    movement used to train the listed muscles.
-   **Primary muscles:** gluteus maximus; hamstrings
-   **Secondary muscles / stabilizers:** spinal erectors; core
-   **Equipment:** dowel or bodyweight
-   **Movement / type:** Movement skill; warm-up
-   **Difficulty:** beginner / scalable
-   **Tags:** `mobility,-warm-up-and-rehabilitation-oriented`,
    `movement-skill`, `warm-up`, `gym`, `exercise-library`
-   **How to perform:** Push hips backward while keeping spine neutral,
    then return to standing.
-   **Coaching / safety notes:** A dowel along head, upper back, and
    tailbone can provide feedback.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Ankle Dorsiflexion Rock

-   **ID:** `ankle-dorsiflexion-rock`
-   **Description:** Ankle Dorsiflexion Rock is a mobility; ankle
    movement used to train the listed muscles.
-   **Primary muscles:** ankle mobility; soleus
-   **Secondary muscles / stabilizers:** tibialis anterior
-   **Equipment:** wall or support
-   **Movement / type:** Mobility; ankle
-   **Difficulty:** beginner / scalable
-   **Tags:** `mobility,-warm-up-and-rehabilitation-oriented`,
    `mobility`, `ankle`, `gym`, `exercise-library`
-   **How to perform:** Keep heel down and gently move knee forward over
    toes, then return.
-   **Coaching / safety notes:** Do not force through sharp pain.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

#### Thoracic Open Book

-   **ID:** `thoracic-open-book`
-   **Description:** Thoracic Open Book is a mobility; rotation movement
    used to train the listed muscles.
-   **Primary muscles:** thoracic spine mobility
-   **Secondary muscles / stabilizers:** obliques; rear shoulder
-   **Equipment:** mat
-   **Movement / type:** Mobility; rotation
-   **Difficulty:** beginner / scalable
-   **Tags:** `mobility,-warm-up-and-rehabilitation-oriented`,
    `mobility`, `rotation`, `gym`, `exercise-library`
-   **How to perform:** Lie on side with knees bent and rotate top arm
    open while following it with eyes.
-   **Coaching / safety notes:** Keep knees stacked to limit low-back
    rotation.
-   **Logging suggestions:** record sets, reps, load (if applicable),
    and rest; for timed holds/carries, record duration or distance.

## Useful app features to consider

1.  **Filters:** primary muscle, secondary muscle, equipment, movement
    pattern, difficulty, exercise type, and available equipment.
2.  **Alternatives:** offer equipment substitutions (e.g. dumbbell press
    for barbell press) and easier/harder variations.
3.  **Media:** add your own licensed demonstration video or step-by-step
    images; include camera angle and key form cues.
4.  **Programming fields:** suggested rep range, rest range,
    unilateral/bilateral, load type, and whether to log reps, time,
    distance, or assistance.
5.  **Personalization:** let users mark favorites, hide unavailable
    equipment, and record pain-free range or coach notes.
6.  **Data quality:** muscle emphasis is not exclusive; avoid presenting
    secondary muscles as completely inactive. Have a qualified trainer
    review instructions before publication.

## Scope and limitations

This starter library includes common free-weight, machine, cable,
bodyweight, core, conditioning, and mobility exercises. It is not
literally every exercise variation: grips, stances, attachments, tempos,
unilateral versions, and sport-specific drills create many additional
variants. Keep variants linked to a parent exercise rather than
duplicating all metadata.

**Exercise count: 156.**
