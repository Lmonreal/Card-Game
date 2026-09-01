# Card Game (v0.1)

A solo card battler based on President. You're playing against the House.
Beat the target score before you run out of ladders.

## The basics

- You have a hand of 8 cards. The House has its own hand of 8 (face-down, top right).
- The game is played in **ladders** (rounds). You have **4 ladders** to reach **300 points**.
- A play is a **set**: one or more cards of the same rank (a single 9, a pair of Jacks, three 5s).

## How a ladder works

1. Someone opens with a set. The other side must answer with the **same number of cards
   at a higher rank**, or give up.
2. You and the House keep climbing until one side can't (or won't) continue.
3. **If the House gives up, you CAP the ladder and score it:**
   every card played this ladder (yours AND the House's) counts as chips,
   multiplied by the number of cards you played. Watch the count-up.
4. If you can't or don't want to answer, you **fold** — see below.

The House plays its lowest valid answer, always. It has a real hand: what it played,
it no longer has. If it passes, it genuinely couldn't beat you.

## Folding

- **STEAL** (2 per game): take the set on the table into your hand, and score your own
  played cards. The House loses those cards forever. Your hand can grow past 8.
- **FOLD**: walk away. Nothing gained, nothing scored.

Either way the ladder is spent and the House opens the next one.

## Winning the open

Cap a ladder and **you** open the next one — play anything, including sets the House
might not be able to answer at all. An unanswered open scores immediately.

## Scoring cheat sheet

- Number cards = face value in chips. J/Q/K = 10. Ace = 11 (and the highest rank).
- Ladder score = (all chips on the table) × (cards you played).
- Long rallies with pairs/triples score big.

## Controls

- **Click** a card to select, click again to deselect. **Drag** to reorder your hand.
- **PLAY** the selected set · **STEAL** / **FOLD** buttons · **SORT** re-sorts your hand.
- After a win or loss: **RESET** deals a new game.

---
v0.1 — early build. Numbers, art, and everything else subject to change.
Made in Godot. Feedback goes in the form! -> https://forms.gle/riXB5tcmDT52ykMt9
