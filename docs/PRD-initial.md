# Product Requirements Document (PRD)

## Project Name

Cross Over Strings

## Overview

Cross Over Strings is a relaxing yet challenging puzzle game built with Godot. Players connect colored nodes using strings that can cross over one another. The objective is to create valid string patterns while minimizing tangles, managing limited crossings, and satisfying level-specific constraints.

The game combines elements of line-drawing puzzles, knot theory, network optimization, and spatial reasoning.

---

# Vision

Create a visually satisfying puzzle experience that is easy to learn but difficult to master. Players should feel clever when discovering efficient routing solutions and enjoy the tactile feeling of weaving strings across the board.

---

# Target Audience

### Primary Audience

* Puzzle game enthusiasts
* Casual mobile gamers
* Players who enjoy games such as:

  * Flow Free
  * Mini Metro
  * Railbound
  * Hook
  * The Witness (light puzzle aspects)

### Secondary Audience

* Educational users interested in graph theory concepts
* Children aged 10+
* Steam puzzle game community

---

# Platform

### Initial Release

* Windows
* macOS
* Linux

### Future Releases

* Android
* iOS
* Nintendo Switch

---

# Game Loop

1. Start level
2. Analyze node layout
3. Connect matching nodes using strings
4. Manage crossing points
5. Satisfy level objectives
6. Submit solution
7. Receive score
8. Unlock next level

---

# Core Gameplay

## Board

The board contains:

* Colored endpoints
* Obstacles
* Crossing zones
* Switch nodes
* Goal nodes

Players draw strings between matching endpoints.

Example:

Red ● ----------- ● Red

Blue ● ----X------ ● Blue

The X represents a crossing point.

---

## String Rules

### Basic Rules

* Every color pair must be connected.
* Strings cannot pass through obstacles.
* Strings may only cross at valid crossing locations.
* Strings cannot overlap.
* Strings cannot self-intersect.

### Advanced Rules

Some levels introduce:

* One-way crossings
* Locked crossings
* Rotating crossing nodes
* Dynamic obstacles
* Timed switches

---

# Game Modes

## Campaign

### Beginner World

Introduces:

* Basic connections
* Single crossings
* Limited board size

### Intermediate World

Introduces:

* Multiple crossings
* Obstacles
* Scoring mechanics

### Advanced World

Introduces:

* Dynamic board elements
* Crossing limits
* Puzzle chains

### Expert World

Introduces:

* Complex weaving patterns
* Multi-layer routing
* Special node behaviors

---

## Daily Puzzle

* One new puzzle every day
* Global leaderboard
* Unique puzzle seed

---

## Challenge Mode

Players must solve puzzles under constraints:

Examples:

* Maximum 3 crossings
* Solve within 60 seconds
* No string longer than 10 segments

---

# Progression

## Stars

Players earn:

### 3 Stars

Perfect solution

### 2 Stars

Completed with minor inefficiencies

### 1 Star

Puzzle completed

---

## Unlock System

Each world unlocks after:

* Completing previous world
* Earning minimum star count

---

# Scoring

Score factors:

Positive:

* Fewer crossings
* Shorter string lengths
* Faster completion
* Puzzle bonuses

Negative:

* Excess crossings
* Hint usage
* Undo abuse (optional)

Formula:

Score =
Base Points

* Efficiency Bonus
* Time Bonus

- Penalties

---

# Special Mechanics

## String Tension

Long strings generate tension.

High tension:

* Reduces score
* May trigger level failure in advanced modes

---

## String Types

### Standard

Normal string

### Elastic

Can stretch around obstacles

### Metallic

Cannot cross other strings

### Magical

Can pass through designated barriers

---

## Layer System

Advanced puzzles may contain:

Layer 1
Layer 2

Players switch between layers to route strings.

This creates highly strategic puzzles.

---

# Visual Design

## Art Style

* Clean minimalist aesthetic
* Soft gradients
* Modern puzzle-game appearance

Inspirations:

* Monument Valley
* Mini Metro
* Hook

---

## Color Palette

* High contrast
* Colorblind-friendly options
* Dark mode support

---

# Audio

## Music

* Relaxing ambient soundtrack
* Procedurally mixed loops

## Sound Effects

* String drawing
* Crossing placement
* Puzzle completion
* Star rewards

All sounds should feel soft and tactile.

---

# Technical Requirements

## Engine

Godot 4.x

## Architecture

### Core Systems

* Level Manager
* Puzzle Validator
* Path Routing System
* Save System
* Achievement System

---

## Data Format

Levels stored as JSON:

```json
{
  "nodes": [],
  "obstacles": [],
  "crossings": [],
  "goals": []
}
```

---

# Controls

## Mouse

* Click node
* Drag string
* Release to connect

## Touch

* Tap node
* Drag path
* Release to confirm

## Keyboard

* Undo
* Restart
* Hint

---

# Accessibility

* Colorblind mode
* High contrast mode
* UI scaling
* Reduced animation option
* Full controller support

---

# Monetization

## Premium Version

One-time purchase.

Includes:

* Full campaign
* Daily puzzles
* Achievements

### Optional DLC

* New puzzle worlds
* Seasonal puzzle packs

No pay-to-win mechanics.

---

# MVP Scope

## Must Have

* 50 handcrafted levels
* Basic node connections
* Crossing mechanics
* Star scoring
* Save/load
* Hint system

## Nice to Have

* Daily puzzles
* Leaderboards
* Steam achievements

## Future

* Community level editor
* Workshop integration
* Puzzle sharing
* Procedural generation

---

# Success Metrics

Launch Goals:

* 80%+ level completion rate for World 1
* 4.5+ user rating
* Average session length > 15 minutes
* 30% Day-7 retention
* 100+ community-created puzzles within 6 months

---

# Elevator Pitch

Cross Over Strings is a relaxing puzzle game where players weave colored strings across increasingly complex boards, balancing crossings, efficiency, and spatial logic to create elegant solutions.

