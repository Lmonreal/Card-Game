# Card Game (working title)

A roguelike deckbuilder built on the climbing card game *President* (a.k.a. Daifugō / Scum).
You don't play against other people — you play against **the House**, and you're trying to
hit a score target before you run out of ladders. Think Balatro's structure with President's
rules.

## The core loop: ladders

Every round is a **ladder**. The House opens with a set — one to three cards of the same rank.
You must answer with the **same number of cards, of a higher rank**. The House answers back,
one or two ranks above you. You answer again. The ladder climbs.

Eventually the House can't go higher and **passes**. When it passes, you **cap** the ladder
and it scores.

## Scoring

A capped ladder scores

    (chips) × (cards you played)

- **Chips** = the face value of every card in the ladder — **yours and the House's**.
  Capping means you *claim* the House's cards too, so long ladders are worth a lot.
- **Cards played** = every card you put down during the ladder. Pairs and triples climb the
  multiplier fast.
- Numbers are worth their rank; Jack/Queen/King are 10; Ace is 11 and the highest rank.

Push a ladder long and both numbers grow. But if you can't answer, you don't cap — and the
ladder is gone.

## Folding: steal or collapse

If you can't (or don't want to) answer, you fold. Two ways:

- **Steal** — take the cards currently on the table into your hand, and score what you've
  played so far (without the House's chips). You only have a few steals per stage.
- **Collapse** — walk away. Nothing scored, nothing gained. The ladder is spent.

Steals are how you build a hand: stolen cards stay with you, and your hand can grow past its
normal size. Steal twice, then play one monster ladder.

## Going Out

If a ladder ends with your hand empty, that ladder scores **×2**. Emptying your hand is the
big finish.

## A stage

- You get a fixed number of **ladders** and **steals**.
- After each ladder your hand refills to 8 (cards you kept stay with you).
- Reach the **target score** before your ladders run out → you win the stage.
  Run out of ladders first → you lose.

## What's next (not in v0)

Multiple stages with rising targets, a House with a real deck instead of a formula, card
modifiers, jokers, and a shop between stages.
