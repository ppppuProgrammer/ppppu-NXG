extends Resource

export var _game_phases:Dictionary

func get_game_phase(phase_name:String)->GamePhase:
	return _game_phases.get(phase_name)