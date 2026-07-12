class_name SlimeKing
extends BossBase

const BOSS_ID := &"slime_king"
const MAX_HEALTH := 80
const PHASE_TWO_HEALTH := 40
const CONTACT_DAMAGE := 1
const STAGGER_DURATION := 1.4


# Stagger capacity stays injected until reviewed tuning supplies an authored value.
func _init(p_stagger_capacity: int) -> void:
	configure(
		BOSS_ID,
		MAX_HEALTH,
		PHASE_TWO_HEALTH,
		p_stagger_capacity,
		STAGGER_DURATION
	)


func validate_slime_king_contract() -> PackedStringArray:
	var errors := validate_contract()
	if id != BOSS_ID or max_health != MAX_HEALTH or phase_two_health != PHASE_TWO_HEALTH:
		errors.append("Giant Slime King health and phase values must remain exact.")
	if not is_equal_approx(stagger_duration, STAGGER_DURATION):
		errors.append("Giant Slime King stagger window must remain 1.4 seconds.")
	return errors
