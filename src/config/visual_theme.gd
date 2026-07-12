extends Resource
class_name VisualTheme

const BallState = preload("res://src/rules/ball_state.gd")

@export_file("*.png") var battle_background_path: String
@export_file("*.png") var astrolabe_base_path: String
@export_file("*.png") var heartlight_core_path: String
@export_file("*.png") var shield_ring_path: String
@export_file("*.png") var collapse_boundary_path: String
@export_file("*.png") var color_orb_red_path: String
@export_file("*.png") var color_orb_blue_path: String
@export_file("*.png") var color_orb_gold_path: String
@export_file("*.png") var color_orb_green_path: String
@export_file("*.png") var combat_orb_attack_path: String
@export_file("*.png") var combat_orb_shield_path: String
@export_file("*.png") var combat_orb_recover_path: String
@export_file("*.png") var eclipse_orb_warning_path: String
@export_file("*.png") var eclipse_orb_danger_path: String
@export var board_art_radius: float = 260.0
@export var core_art_radius: float = 80.0
@export var orb_sprite_radius: float = 24.0
@export var preview_icon_size: Vector2 = Vector2(34.0, 34.0)

var _texture_cache: Dictionary = {}

func battle_background() -> Texture2D:
	return _texture_from_path(battle_background_path)

func astrolabe_base() -> Texture2D:
	return _texture_from_path(astrolabe_base_path)

func heartlight_core() -> Texture2D:
	return _texture_from_path(heartlight_core_path)

func shield_ring() -> Texture2D:
	return _texture_from_path(shield_ring_path)

func collapse_boundary() -> Texture2D:
	return _texture_from_path(collapse_boundary_path)

func get_orb_texture(ball: BallState) -> Texture2D:
	if ball == null:
		return null
	if ball.kind == BallState.Kind.COLOR:
		return _color_orb_texture(ball.color_id)
	if ball.kind == BallState.Kind.COMBAT:
		return _combat_orb_texture(ball.combat_kind)
	if ball.kind == BallState.Kind.HAZARD:
		return _texture_from_path(eclipse_orb_danger_path if ball.hazard_phase == BallState.HazardPhase.DANGER else eclipse_orb_warning_path)
	return null

func _color_orb_texture(color_id: int) -> Texture2D:
	match max(color_id, 0) % 4:
		0:
			return _texture_from_path(color_orb_red_path)
		1:
			return _texture_from_path(color_orb_blue_path)
		2:
			return _texture_from_path(color_orb_gold_path)
		3:
			return _texture_from_path(color_orb_green_path)
	return _texture_from_path(color_orb_red_path)

func _combat_orb_texture(combat_kind: int) -> Texture2D:
	match combat_kind:
		BallState.CombatKind.ATTACK:
			return _texture_from_path(combat_orb_attack_path)
		BallState.CombatKind.SHIELD:
			return _texture_from_path(combat_orb_shield_path)
		BallState.CombatKind.HEAL:
			return _texture_from_path(combat_orb_recover_path)
	return _texture_from_path(combat_orb_attack_path)

func _texture_from_path(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if _texture_cache.has(path):
		return _texture_cache[path] as Texture2D
	var image := Image.new()
	var error := image.load(path)
	if error != OK:
		push_warning("VisualTheme failed to load texture path: %s" % path)
		return null
	var texture := ImageTexture.create_from_image(image)
	_texture_cache[path] = texture
	return texture
