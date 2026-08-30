# v0.1 Playtest Log

Settings at start: steals 3 · ladders 4 · target 300 · hand 8 · House: real deck, hand 8, lowest-beating-set
New since v0: winner-stays-on opens · real House deck · sort/drag · count-up · fold animations · tilt/shadow juice

## Runs (baseline settings — no tuning until all 10 are done)

|#|Result|Ladders used|Opened by me?|Real decision (the moment you actually thought)|Autopilot|
|-|-|-|-|-|-|
|1|409|3|2|played a k instead of an ace. Worked out|scaling +1|
|2|411|3|2|Folded to save my 2 aces and 2 queens and it paid off when he played triple 5s|scaling|
|3|411|4|0|Got a shitty start with a 10 as my highest. Had to scale and steal his cards for leverage|scaling|
|4|408|3|2||scaling|
|5|292|4|1|folded at 2 2s|-|
|6|351|4|1|Played 3 4s just to re roll my hand basically|-|
|7|186|4|1|Bet it all on my 2 ks but he had 2 aces|-|
|8|316|4|2|NA|-|
|9|582|2|1|Won early cause I had a huge ladder|-|
|10|360|3|1|Just got a good ladder going. Was screwed a bit by winning with double 5s|-|

## After 10 runs

1. Winner-stays-on: did earning the open change how you played a ladder? Ever play *worse* cards to avoid capping?
- Honestly I was playing low cards almost always. Unless I had like 3 4s and 3 aces or something crazy like that.
2. Did stealing feel like an attack now (its Kings are GONE)? Did you ever steal to disarm rather than to loot?
- Rn there's no feedback on that end really. Stealing just feels like you're gaining an advantage but it isn't obvious that you're actually STEALING it.
3. House with a real hand: could you read its state from its card count? Did its passes feel earned or random?
Tbh I never really paid attention to his hand size. I did take into consideration "Hey he probably doesn't have an ace" or something
4. Count-up: still fun on run 10, or skipping-worthy? score\_beat verdict:
- Nah, Its fun. Like, probably the best part of the game even without sfx. Maybe players should be able to speed it up like in balatro if they want.
5. Ever open with a big set (3-4 of a kind)? Was it the payoff it should be?
- Depends! If you play 4 cards you're also relying on him also having 4 cards unless you have like 4 kings or something where its kinda worth it cause youre getting 160 free points
6. Collapse: pressed by choice? For hand-refresh like v0, or new reasons?
- Rarely. Seriously considering nerfing by a steal. I almost never ran out. You usually steal on the first or second and go big on your third hand so theres not really a point
7. Going Out (×2): ever triggered? Ever *chased*?
- No and no. I was never even close. Think about it. Its basically impossible. Say we have pairs so we have to have 4 good pairs and the AI too so its kind of impossible rn without modifiers and shit
8. Is 300 right for 4 ladders now that rallies are short? Runs won by turtling vs pushing:
- Yeah. Like im the person whose played this the most and a 80% wr for the first level of a run seems fine.
9. Most fun moment:
- being able to rally 3 card hands. you get 6 mult + chips = high ass score
10. Most boring stretch / most confusing moment (this is what friends will hit):

&#x20;  - After like 7 runs it started getting a bit tedious. Im not extremely concerned cause we've talked about this before. This is basically me playing ante 1 blind 1 of balatro with no juice, no sfx, no nothing on repeat. It should ideally be fun for the first couple and then not easy / hard enough to discourage returning players.

## 

## Ship checklist

* \[ ] README still accurate (player opens, House deck)
* \[ ] Export preset + templates installed
* \[ ] .exe tested OUTSIDE the editor (cards load, full stage playable)
* \[ ] Zipped + sent with 3 questions: best moment? confused when? ever fold by choice — why?
* \[ ] git tag v0.1

## Verdict

* Better game than v0? Because: Juice. Juice. Juice. This version was all about making the game more responsive and I think I did a good job for a rough draft.
* The one thing v0.2 needs first:
* What the vision board should fix that tuning can't: Visual style, preparation, refactoring code to make the jump from small project to actual game viable
