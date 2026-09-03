extends Node
class_name ScoreAnimator
## ScoreAnimator — the count-up, the burn, the fade. Behavior with no visuals of
## its own, so it's a plain Node (it needs the tree for tweens and timers).
## It receives everything as arguments; it never reads game state.

var score_beat : float = 0.50    # pause between count-up steps
var score_hold : float = 0.4     # pause before/after the final total reveal

var _table : TableView  # TableView: find_visual() + parent for float labels
var _hud : Hud          # Hud: set_tally() / sync_score()


## Called once by the coordinator in _ready.
func setup(table_view : TableView, hud : Hud) -> void:
	_table = table_view
	_hud = hud


## Cap: walk the receipt last-played-first, one beat per contribution,
## then reveal the equation and catch the displayed score up to `new_total`.
func animate_cap(receipt : Array[ScoreStep], ladder_score : int, new_total : int) -> void:
	var reverse_receipt := receipt.duplicate()
	reverse_receipt.reverse()
	var chips_total : int = 0
	var mult_total : int = 0
	for step in reverse_receipt:
		var visual : Control = _table.find_visual(step.card)
		if visual:
			visual.pivot_offset = visual.size / 2
			# Beat 1: chips. Every card has these.
			_pop(visual)
			_spawn_float("+%d" % step.chips, visual.position, Color(0.5, 0.8, 1.0))
			chips_total += step.chips
			_hud.set_tally("%d x %d" % [chips_total, mult_total])
			await get_tree().create_timer(score_beat).timeout
			# Beat 2: mult, only if this card gives any. Future add-ons = more beats here.
			# HOUSE RULE: a check doesn't survive an await. Everything below the
			# first await re-verifies `visual` before touching it; the math and
			# tally run regardless — the score is the brain's truth, not the visual's.
			if is_instance_valid(visual):
				_pop(visual)
				_spawn_float("+%d" % step.mult, visual.position, Color(1.0, 0.35, 0.3))
			mult_total += step.mult
			_hud.set_tally("%d x %d" % [chips_total, mult_total])
			await get_tree().create_timer(score_beat).timeout
			if is_instance_valid(visual):
				visual.queue_free()
	# Finale: hold, reveal the equation, land the total.
	await get_tree().create_timer(score_hold).timeout
	_hud.set_tally("%d x %d = +%d" % [chips_total, mult_total, ladder_score])
	_hud.sync_score(new_total)
	await get_tree().create_timer(score_hold).timeout


## Steal: steals don't score. The stolen set (ladder.back()) simply leaves —
## it's in the player's hand now — and everything else on the table burns.
func animate_steal(ladder : Array[Play]) -> void:
	var loot : Play = ladder.back()
	for play in ladder:
		if play == loot:
			for card in play.cards:
				var visual : Control = _table.find_visual(card)
				if visual:
					visual.queue_free()
		else:
			for card in play.cards:
				var visual : Control = _table.find_visual(card)
				if visual:
					create_tween().tween_property(visual, "modulate", Color(0, 0, 0, 0), 0.3).set_trans(Tween.TRANS_CUBIC)
	await get_tree().create_timer(0.5).timeout


## Collapse: the whole pile fades. Nothing counts.
func animate_collapse(ladder : Array[Play]) -> void:
	for play in ladder:
		for card in play.cards:
			var visual : Control = _table.find_visual(card)
			if visual:
				create_tween().tween_property(visual, "modulate", Color(0, 0, 0, 0), 0.3)
	await get_tree().create_timer(0.2).timeout


# ---- internals ----

func _pop(visual : Control) -> void:
	var t := create_tween().parallel()
	t.parallel().tween_property(visual, "scale", Vector2(1.60, 1.60), 0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(visual, "rotation_degrees", 10, 0.12).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(visual, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(visual, "rotation_degrees", 0, 0.06).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _spawn_float(label_text : String, at : Vector2, text_color : Color = Color.WHITE) -> void:
	var fl := Label.new()
	fl.text = label_text
	fl.add_theme_font_override("font", load("res://assets/fonts/Logic_Loop.ttf"))
	fl.add_theme_font_size_override("font_size", 36)
	fl.add_theme_color_override("font_color", text_color)
	fl.add_theme_color_override("font_outline_color", Color.BLACK)
	fl.add_theme_constant_override("outline_size", 16)
	fl.position = at + Vector2(20, -10)
	_table.add_child(fl)
	var t := create_tween().set_parallel(true)
	t.tween_property(fl, "position:y", fl.position.y - 40, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(fl, "modulate:a", 0.0, 0.8)
	t.chain().tween_callback(fl.queue_free)
