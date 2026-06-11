extends RefCounted
## Stars and score for a puzzle attempt.
##
## Stars: 3 = at or under par with no hint, 2 = within 25% of par with no
## hint, 1 = completed (or completed with a hint), 0 = not complete.
## Score = base + efficiency bonus - hint penalty.

const BASE_POINTS := 1000
const EFFICIENCY_SCALE := 500.0
const HINT_PENALTY := 250
const TWO_STAR_FACTOR := 1.25

static func stars(level: Variant, state: Variant) -> int:
	if not state.is_complete():
		return 0
	if state.hint_used:
		return 1
	var length: int = state.total_length()
	if length <= level.par_length:
		return 3
	if length <= ceili(level.par_length * TWO_STAR_FACTOR):
		return 2
	return 1

static func score(level: Variant, state: Variant) -> int:
	if not state.is_complete():
		return 0
	var points := BASE_POINTS + int(EFFICIENCY_SCALE * level.par_length / maxi(state.total_length(), 1))
	if state.hint_used:
		points -= HINT_PENALTY
	return maxi(points, 0)
