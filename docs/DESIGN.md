# Space Roadster X: Design Doc

Status: describes v1.0 as built (free on the App Store). Last updated 2026-11-01.

## Concept

**Space Roadster X is a one-thumb endless runner where you hold to fire the air thrusters on a silver electric roadster and hop over rural Texas traffic at sundown, landing on roofs and flipping for points, in runs of about 90 seconds.**

The pitch was picked from three concepts. All three came out of the browser prototype (`prototypes/aerogt-arcade.html` in the project files), which tried each one as a mode.

| | Pitch | Player fantasy | Why it was or wasn't picked |
| --- | --- | --- | --- |
| **A. Thrust Hop (picked)** | An endless highway run. Hold to lift off, release to drop, swipe up to flip. Traffic, haulers, and barriers get denser as the road speeds up. Air is a meter that refills on the ground. | "My car can fly, and I'm showing off on the way home." | One input, instant retry, and a score that keeps climbing. It was the most replayable prototype mode and fits a phone held in one hand. This is what v1.0 ships. |
| B. Sky Commute | A daily route. Hold and drag up or down to steer through the air, let go to glide, and finish a fixed route faster than yesterday. | "The morning commute, but above the traffic jam." | Calm and good for a daily habit, but drag-to-steer is fussier than hold-to-lift, and a fixed route wears thin without a lot of content. |
| C. Stunt Trials | Hand-made levels built on two well-timed taps: launch on the green light, fire the thrusters at the ramp lip, switch on suction in a loop and stick to the ceiling. Graded PERFECT, GREAT, or NO BOOST. | "A stunt driver nailing a one-take jump." | Big payoff moments, but each level has to be built by hand, and once a level is solved there's little reason to replay it. Its timing ideas live on in the spool-up thrust and the Window Test. |

## Design pillars (3 max)

1. **One thumb, full control.** Hold, release, and swipe up are the whole vocabulary. Depth comes from timing, not more buttons. If a feature needs a second finger or a menu mid-run, it doesn't go in.
2. **Weight you can feel.** The thrusters spool up over 0.55 s and bleed off over 0.18 s, so lift has to be planned. Every action has a matching sound, haptic, and particle effect: the takeoff blast, the cutoff puff, the roof clunk, the landing ring.
3. **Fair, fast, and one more try.** Every crash names its cause ("You rear-ended a…", "Landed mid-flip. Flip earlier or higher."). Retry is one tap after 0.6 s. A run is short enough that losing doesn't sting.

## Core loop

Every few seconds the player reads the next obstacle and decides how to clear it:

1. **Read** what's coming: a car, a three-car lineup, a Hauler, a barrier, or a Wedge Truck with someone about to throw a steel ball at it.
2. **Commit early.** Hold before the obstacle, because thrust takes about half a second to beat gravity. A quick tap barely leaves the road, and a long hold launches.
3. **Choose risk.** Clear it safely, skim it for a near miss (+25), land on its roof (+100, and air refills twice as fast there), or swipe up for a backflip (+250, multiplied up to x5 when chained without touching down).
4. **Manage air.** A full tank is 2 s of thrust. Ground time refills it in about 5.5 s from empty, and blue canisters add 35% (+50).
5. **Land clean** and repeat. Landing before 85% of a flip is a crash.

The Window Test is the set piece: when a Wedge Truck rolls in, a steel ball is thrown at it. Dodge the ball, or flip through it to bat it away for +300 ("Armor Glass").

Speed ramps from 260 to 620 (about 109 to 260 mph on the HUD) and hits top speed around 75 s. Lineups appear after 12 s, Haulers after 6 s, and the Window Test after 18 s, so a run escalates on its own.

## Meta loop / progression

What's in v1.0:

- **Top 20 on the device.** Each run is ranked against your best 20 (score, flips, and date), and the crash screen shows "New best! Rank #1" or "Rank #N of top 20". This is the whole meta loop today.
- **Mastery as progression.** No unlocks. Getting better means reaching the late-game density, chaining flips, and landing Armor Glass.

Not built yet, in rough order of value:

- Game Center leaderboards, so scores compete with friends and not just yourself.
- Daily challenge: a fixed-seed road everyone drives that day (the core of pitch B in a lighter form).
- Paint jobs and cosmetic unlocks for score or flip milestones. The car art already takes a `paint` index.
- Short goals ("flip 3 times in one jump", "land on 5 roofs") to give each session a target.

## Target feel

- **Session length:** about 90 s per run, retry in under a second, so a sitting is a few minutes of back-to-back runs.
- **Difficulty:** easy to start, hard to master. The first 6 s is gentle traffic and barriers, then it ramps. Crashes should feel like your own mistake, never the game's.
- **Tone:** playful and a little cocky. Original look-alike cars, deadpan crash lines, and the Window Test as a wink. No real brands or logos.
- **Art direction:** rural Texas at sundown. A big orange-to-night sky, mesas, cowboys and longhorns on the skyline, barbed-wire fence, windmills, prickly pear, tumbleweeds, and a two-lane blacktop. The RoadsterX is silver. Everything is drawn in code at full Retina resolution.
- **Audio:** an original driving rock loop in E minor at 140 BPM that ducks when not playing, and synthesized rocket thrust that rises with spool-up. Core Haptics follow the thrust level.

## Current metrics / playtest notes

**Known (from the build and its tuning):**

- v1.0 is free on the App Store, built in SwiftUI and SpriteKit for iOS 17+.
- Designed run length is about 90 s, with top speed reached around 75 s. These are tuning targets in `Tuning.swift`, not measured averages.
- The top 20 scores are stored on the device only. There's no analytics or crash reporting, so nothing from real players reaches us yet.

**Playtest notes so far (developer testing on device):**

- Instant thrust felt weightless, so thrust now spools up over 0.55 s and bleeds off over 0.18 s. Holding early became the core skill.
- The speed ramp was slowed from the prototype so top speed lands near 75 s instead of early in the run.
- The first build's sunset highway was swapped for the rural Texas backdrop, the car was made silver, and the rock loop and rocket sound were added for more attitude.
- A single best score wasn't enough of a reason to retry, so it became a top 20 list. Old best scores carry over.

**Not yet measured:**

- Actual average run length and runs per session
- Day 1 and day 7 retention
- Where players crash (which obstacle, and how far into the run)
- How many players ever land a flip, a chain, or Armor Glass
- First-run drop-off (players who quit before the first Window Test)
- App Store ratings and reviews

The cheapest next step is local, privacy-friendly counters (crash cause, run length, flips per run), or a TestFlight group with a short survey.
