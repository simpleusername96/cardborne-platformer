class_name RunPhase
extends RefCounted

const NORMAL_STAGE_COUNT := 3

enum Value {
	BOOT,
	MAIN_MENU,
	CHARACTER_SELECT,
	LOADOUT,
	STAGE_LOADING,
	STAGE_ACTIVE,
	LEVEL_REWARD,
	STAGE_CARD_REWARD,
	REST_FORGE,
	BOSS_LOADING,
	BOSS_ACTIVE,
	RUN_DEATH,
	RUN_CLEAR,
}

const LEGAL_TRANSITIONS: Dictionary = {
	Value.BOOT: [Value.MAIN_MENU],
	Value.MAIN_MENU: [Value.CHARACTER_SELECT],
	Value.CHARACTER_SELECT: [Value.MAIN_MENU, Value.LOADOUT],
	Value.LOADOUT: [Value.CHARACTER_SELECT, Value.STAGE_LOADING],
	Value.STAGE_LOADING: [Value.STAGE_ACTIVE, Value.MAIN_MENU, Value.RUN_DEATH],
	Value.STAGE_ACTIVE: [
		Value.LEVEL_REWARD, Value.STAGE_CARD_REWARD, Value.RUN_DEATH,
	],
	Value.LEVEL_REWARD: [
		Value.LEVEL_REWARD, Value.STAGE_ACTIVE, Value.STAGE_CARD_REWARD,
		Value.RUN_DEATH,
	],
	Value.STAGE_CARD_REWARD: [
		Value.STAGE_LOADING, Value.REST_FORGE, Value.BOSS_LOADING, Value.RUN_DEATH,
	],
	Value.REST_FORGE: [Value.STAGE_LOADING, Value.RUN_DEATH],
	Value.BOSS_LOADING: [Value.BOSS_ACTIVE, Value.RUN_DEATH],
	Value.BOSS_ACTIVE: [Value.RUN_DEATH, Value.RUN_CLEAR],
	Value.RUN_DEATH: [Value.MAIN_MENU, Value.CHARACTER_SELECT],
	Value.RUN_CLEAR: [Value.MAIN_MENU, Value.CHARACTER_SELECT],
}


static func can_transition(from_phase: Value, to_phase: Value) -> bool:
	return to_phase in LEGAL_TRANSITIONS.get(from_phase, [])


static func name_of(phase: Value) -> String:
	return Value.keys()[phase].to_lower()
