extends RefCounted
class_name RunState
## Everything that survives between screens. A stage builds itself FROM this;
## it never writes back except through GameManager.

var stage_index : int = 1
var target_score : int = 300


## Target curve for later stages. One place to tune; v0.2 starts flat.
func target_for(stage : int) -> int:
	return 300 + (stage - 1) * 150


func next_stage() -> void:
	stage_index += 1
	target_score = target_for(stage_index)
