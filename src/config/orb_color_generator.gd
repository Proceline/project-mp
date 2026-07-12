extends Resource
class_name OrbColorGenerator

enum Mode { RANDOM, SEQUENCE }

@export var mode: Mode = Mode.RANDOM
@export var color_count: int = 4
@export var sequence: PackedInt32Array = PackedInt32Array()
@export var seed: int = 0

var _rng := RandomNumberGenerator.new()
var _sequence_index: int = 0
var _seed_applied: bool = false

func next_color_id() -> int:
	var count: int = max(color_count, 1)
	if mode == Mode.SEQUENCE and not sequence.is_empty():
		var color_id := int(sequence[_sequence_index % sequence.size()])
		_sequence_index += 1
		return posmod(color_id, count)
	_ensure_rng_seeded()
	return _rng.randi_range(0, count - 1)

func reset() -> void:
	_sequence_index = 0
	_seed_applied = false

func _ensure_rng_seeded() -> void:
	if _seed_applied:
		return
	if seed == 0:
		_rng.randomize()
	else:
		_rng.seed = seed
	_seed_applied = true
