# v0.2 Refactor Plan — from one big scene to components

Status: APPROVED 2026-08-31 (Lorenzo). Execution starts after the Discrete midterm (2026-09-09); step 0 first.

## 0. Why now

`main.gd` is ~300 lines wearing five hats: refresh core, button handlers, drag system,
pile drawing, score animation. Every v0.2 feature (a House with a body, the rank-column
ladder, stages, a shop, a menu) would pile onto that one file. The refactor is not
cleanup — it makes v0.2 *possible* at evening-session granularity: each feature touches
one small file instead of one big one.

Non-goals: no rule changes, no visual changes, no new features. The game must play
pixel-identically after every step. Rule changes (Going Out deletion, fold → redraw,
steal scoring) happen in the brain BEFORE the refactor, so we never relocate dead code.

## 1. Principles (the argument for the shape)

1. **A scene is a component.** A self-contained subtree with its own script and a
   behavior boundary. You can open it alone, lay it out alone, run it alone (F6). Not
   "everything that can be a scene" — the brain has no nodes and stays a class.
2. **Split by what changes together.** The hand's drag math changes for different
   reasons than the HUD's label text. Files that change for one reason stay small.
3. **Signals up, calls down.** Parents call children's methods; children never call
   parents — they emit. A component reaching for `get_parent()` is a bug.
4. **Views take data as arguments.** `hand_view.show_hand(cards)` — a view never holds
   a `StageState`. Only the coordinator touches the brain's doors. This extends the
   existing brain ⟂ UI wall one ring outward: brain ⟂ coordinator ⟂ views.
5. **Screen = scene, run = state.** Menu, table, shop, stage-clear are each a scene that
   says "I'm done, here's the result". What persists *between* screens (stage number,
   target, money, deck config) lives in state owned by the autoload, never in a screen.
6. **`%UniqueName` over `$Path`.** Survives moving nodes around the tree — which the art
   pass will do constantly.

## 2. Target layout (mapped to the UI mockup)

```
  HouseView   cat portrait + vial                    (top-left)
  Hud         stat column: score, blue×red, counters (left)
  TableView   the ladder as a rank-column            (center)
  HandView    the player's cards                     (right, middle)
  ActionBar   PLAY / FOLD / STEAL buttons            (bottom-right)
```

Mockup note: the stat column (left) and the action buttons (bottom-right) are far apart,
so buttons get their own component (ActionBar) instead of living inside the Hud — they
will move independently during the art pass.

### File tree after the refactor

```
scenes/
  app/app.tscn                 NEW root: owns the ScreenContainer (see section 5)
  screens/
    table_screen.tscn          today's main.tscn, renamed — the game screen
    (later) main_menu.tscn, shop_screen.tscn, stage_clear_screen.tscn
  ui/
    card_visual.tscn           unchanged
    hand_view.tscn             HandArea becomes its own scene
    table_view.tscn
    house_view.tscn            NEW — built by Lorenzo after the refactor
    hud.tscn
    action_bar.tscn
scripts/
  game/      stage_state.gd, play.gd, score_step.gd   unchanged
             run_state.gd                              NEW, tiny: stage #, target, deck config
  ui/        table_screen.gd (was main.gd), hand_view.gd, table_view.gd, house_view.gd,
             hud.gd, action_bar.gd, score_animator.gd, card_visual.gd
  autoloads/ game_manager.gd                           finally has a job: owns RunState, switches screens
```

## 3. Components — owns / exposes / emits

### HandView  (hand_view.tscn, root Control, hand_view.gd)
- **Owns:** CardVisual children; **the selection set** (moves here from main); drag,
  drop, live-shift, slot math, hover_slot.
- **Exposes:** `show_hand(cards)`, `get_selected() -> Array[Card]`, `clear_selection()`.
- **Emits:** `reorder_requested(from, to)` — the coordinator forwards to `move_card`.
- **Moves in from main:** the hand half of `_control_refresh_helper`, `_slot_position`,
  `_slot_for_position`, `_is_over_hand`, `_on_card_dragged / dropped / clicked`,
  `_shift_neighbors`, `selected_cards`, `hover_slot`.
- **Why a scene:** children, a layout worth editing, a behavior boundary (drag never
  leaks out). It is also the only component that will grow a *fan* layout later — that
  change touches one file.

### TableView  (table_view.tscn)
- **Owns:** pile drawing; `find_visual(card)` (keeps the queued-for-deletion skip).
- **Exposes:** `show_pile(ladder)`, `find_visual(card)`, `clear()`.
- **Emits:** nothing — pure display.
- **Moves in:** `_draw_table_pile`, `_find_table_visual`.
- **Future:** the rank-column layout from the mockup replaces the body of `show_pile` only.

### HouseView  (house_view.tscn) — NEW BUILD, not an extraction
- **Owns:** the House's face-down hand, the cat, the paw, reactions, the vial.
- **Exposes:** `show_hand(cards)`, `play_cards(cards, to_global_pos)` (awaitable: paw
  travels, sets cards down, withdraws), `react(kind)` (awaitable), `set_vial(ratio)`.
- **Moves in:** the face-down half of `_control_refresh_helper`.
- **Placeholder-first:** a rectangle with two circles for eyes and a rectangle paw.
  Prove the feel before drawing a frame.

### Hud  (hud.tscn)
- **Owns:** score box (blue×red pair), steals/ladders counters, message line, last-score
  tally, **`displayed_score`** (moves here), label visibility rules.
- **Exposes:** `refresh(snapshot: Dictionary)` — the coordinator passes plain values,
  never the state object; `set_message(text)`, `set_tally(text)`, `sync_score(value)`.
- **Moves in:** `_update_labels`, the label half of `_update_visibility`, `displayed_score`.

### ActionBar  (action_bar.tscn)
- **Owns:** PLAY / STEAL / FOLD / SORT / RESET buttons and their enabled/visible state.
- **Exposes:** `set_state(playing: bool, animating: bool)`.
- **Emits:** `play_pressed`, `steal_pressed`, `fold_pressed`, `sort_pressed`,
  `reset_pressed`. The editor-wired connections into main are deleted; the coordinator
  subscribes to these signals instead.
- **Why separate from Hud:** the mockup places them apart; they change for different reasons.

### ScoreAnimator  (score_animator.gd on a plain Node inside table_screen)
- **Owns:** the count-up walk, float labels, burn, fade, `score_beat` / `score_hold`.
- **Exposes:** `await animate_cap(receipt)`, `await animate_steal(ladder, receipt)`,
  `await animate_collapse(ladder)`.
- **Needs:** a TableView reference (for `find_visual` and as the float-label parent) and
  a Hud reference (for the tally) — handed over once by the coordinator: `setup(table, hud)`.
- **Moves in:** `_animate_ladder_score`, `_animate_card_score`, `_spawn_float_label`,
  `_animate_steal`, `_animate_collapse`, the two beat knobs.
- **Why a Node, not a scene:** no visuals of its own; it is behavior that needs a place in
  the tree (for `create_tween` / `get_tree`).

### table_screen.gd  (was main.gd) — the coordinator, ~70 lines
- **Owns:** `stage_state`, `animating`, `last_turn_result`.
- **Does:** subscribes to ActionBar signals → calls brain doors → `_refresh()` → runs
  `_end_ladder_sequence(kind)` (logic unchanged, now calling the animator).
- `_refresh()` becomes five one-liners: `hand_view.show_hand(...)`,
  `table_view.show_pile(...)`, `house_view.show_hand(...)`, `hud.refresh(...)`,
  `action_bar.set_state(...)`.
- **Emits (to GameManager, step 6):** `stage_finished(won: bool, score: int)`.

## 4. What does NOT change
- `stage_state.gd`, `play.gd`, `score_step.gd`, `deck_factory.gd`, `card.gd`,
  `card_visual.gd` — byte-identical.
- Shaders and backdrop untouched BY THE REFACTOR (the art direction will replace them separately — scanlines are being removed, background will change; nothing here depends on either).
- Every rule, every number, every animation timing.

## 5. Future-proofing: screens, shop, menu

**The problem a menu or shop creates:** today `main.tscn` IS the game. A menu means
"something before main"; a shop means "something between stages". If main stays the
root, every new screen becomes a hack inside it.

**The structure:**
```
app.tscn (root)
├── (persistent backdrop layer — whatever the new art direction puts here)
└── ScreenContainer (Control, full rect)
    └── exactly one screen scene at a time
```
`GameManager` (autoload) owns `RunState` — stage index, target curve, money, deck config:
the things that survive screen changes — and a `show_screen(packed_scene)` that frees the
current child and instantiates the next. Each screen emits one `finished(result)` signal.
GameManager reacts:

```
MainMenu.finished("play")          → RunState.new(); show TableScreen (stage 1)
TableScreen.finished(won, score)   → won ? show StageClearScreen : show RunOverScreen
StageClearScreen.finished()        → show ShopScreen   (v0.3; v0.2 goes straight on)
ShopScreen.finished()              → RunState.next_stage(); show TableScreen
```
TableScreen receives its config (target, deck) from RunState on entry and builds its own
`StageState`. No screen knows what comes before or after it — the autoload is the only
thing holding the map. Adding a screen = one scene + one line in GameManager. That is the
whole future-proofing argument: **screens are leaves, GameManager is the tree.**

Why a container instead of `change_scene_to_file`: transitions (a fade, the cat walking
off) need both screens alive for a moment — a container makes that trivial. It also gives
a persistent backdrop layer (whatever the new art direction puts there) a home outside
any single screen.

## 6. Migration order (one step per session; game identical after each; one commit each)

0. **Brain rule changes first** (Lorenzo): delete Going Out (+ its `×2` finale branch),
   fold → redraw, steal-scoring decision. Console-test. Commit.
1. **ActionBar** — smallest; teaches the pattern: new scene, signals up, coordinator subscribes.
2. **Hud** — pure reads + `displayed_score` migration.
3. **TableView** — draw + find.
4. **ScoreAnimator** — moves the walk; wired to TableView/Hud via `setup`.
5. **HandView** — the big one (drag). Last among extractions, once the pattern is routine.
6. **App root + GameManager.show_screen + rename main → TableScreen.** No visible change:
   the table is simply screen #1 inside the container. `RunState` introduced holding just
   `target_score`.
7. **HouseView** (Lorenzo builds): placeholder cat + paw `play_cards` tween; the coordinator
   awaits it in the play handler. Here v0.2 proper begins.

Acceptance test after each of steps 1–6, every time: a full stage to WON and to LOST, one
steal, one collapse, one drag-reorder, one sort, one reset. Identical to before.

## 7. Gotchas to watch during migration
- `@onready` vars in a sub-scene resolve in that scene's `_ready`; the parent's `_ready`
  runs AFTER its children's, so the coordinator can call child methods in its own `_ready`.
- Editor-wired button signals must be *deleted* from the scene when ActionBar takes over,
  or handlers fire twice.
- Drag math is already HandArea-local; moving HandArea into its own scene changes nothing
  as long as the CardVisuals stay its children.
- `find_visual` keeps the `is_queued_for_deletion()` skip — the animator still calls it in
  the same frame as a refresh.
- Materials marked Local-to-Scene keep working through nested instancing.

## 8. Effort
Steps 1–6 ≈ 20–25 v0-units (two to three evenings plus narration). Step 0 ≈ 5.
Step 7 is v0.2's first real feature, ≈ 25.
