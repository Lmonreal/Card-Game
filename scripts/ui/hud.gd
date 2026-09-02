extends Control
class_name Hud
## Hud — the stat readouts. Draws whatever the coordinator hands it.
## It never reads game state itself: refresh() receives plain values.

@onready var stage_target: Label = %StageTarget
@onready var last_score: Label = %LastScore
@onready var steals_left: Label = %StealsLeft
@onready var ladders_left: Label = %LaddersLeft
@onready var last_reason: Label = %LastReason
@onready var message_label: Label = %MessageLabel

## The score the PLAYER sees. Lags the brain's truth until sync_score() —
## the count-up finale calls it, so the total lands after the drama.
var displayed_score : int = 0


## snapshot keys: target_score, steals_left, ladders_left, last_ladder_score,
## playing (bool), state_text, table_empty (bool), rejected (bool), reason_text
func refresh(s : Dictionary) -> void:
	stage_target.text = "%d / %d" % [displayed_score, s.target_score]
	steals_left.text = str(s.steals_left) + " steals left"
	ladders_left.text = str(s.ladders_left) + " ladders left"
	last_score.text = "+" + str(s.last_ladder_score)
	last_reason.text = s.reason_text if s.rejected else ""
	if not s.playing:
		message_label.text = s.state_text
	elif s.table_empty:
		message_label.text = "YOU OPEN - play anything"
	else:
		message_label.text = ""
	steals_left.visible = s.playing
	ladders_left.visible = s.playing
	last_reason.visible = s.playing
	message_label.visible = true   # empty string shows nothing while playing


## Running tally during the count-up ("38 × 4", then the equation).
func set_tally(text : String) -> void:
	last_score.text = text


## Catch the displayed score up to the truth (finale) or reset it (new game).
func sync_score(value : int) -> void:
	displayed_score = value
