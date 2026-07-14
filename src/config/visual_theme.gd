extends Resource
class_name VisualTheme

@export_file("*.png") var battle_background_path: String
@export_file("*.png") var boss_hp_bar_frame_path: String
@export_file("*.png") var vertical_queue_frame_path: String
@export_file("*.png") var player_portrait_path: String
@export_file("*.png") var boss_portrait_path: String
@export_file("*.png") var astrolabe_base_path: String
@export_file("*.png") var heartlight_core_path: String
@export_file("*.png") var shield_ring_path: String
@export_file("*.png") var collapse_boundary_path: String
@export_file("*.png") var color_orb_red_path: String
@export_file("*.png") var color_orb_blue_path: String
@export_file("*.png") var color_orb_gold_path: String
@export_file("*.png") var color_orb_green_path: String
@export_file("*.png") var color_orb_red_glow_path: String
@export_file("*.png") var color_orb_blue_glow_path: String
@export_file("*.png") var color_orb_gold_glow_path: String
@export_file("*.png") var color_orb_green_glow_path: String
@export_file("*.png") var combat_orb_attack_path: String
@export_file("*.png") var combat_orb_shield_path: String
@export_file("*.png") var combat_orb_recover_path: String
@export_file("*.png") var combat_orb_attack_glow_path: String
@export_file("*.png") var combat_orb_shield_glow_path: String
@export_file("*.png") var combat_orb_recover_glow_path: String
@export_file("*.png") var eclipse_orb_warning_path: String
@export_file("*.png") var eclipse_orb_danger_path: String
@export_file("*.png") var eclipse_orb_warning_glow_path: String
@export_file("*.png") var eclipse_orb_danger_glow_path: String
@export var board_art_radius: float = 260.0
@export var core_art_radius: float = 80.0
@export_range(0.0, 1.0, 0.01) var astrolabe_base_alpha: float = 1.0
@export_range(0.0, 1.0, 0.01) var collapse_boundary_alpha: float = 1.0
@export_range(0.0, 1.0, 0.01) var core_art_alpha: float = 1.0
@export_range(0.0, 1.0, 0.01) var board_guide_alpha: float = 1.0
@export var orb_sprite_radius: float = 24.0
@export var orb_glow_radius_scale: float = 1.25
@export var orb_glow_alpha: float = 0.75
@export var preview_icon_size: Vector2 = Vector2(34.0, 34.0)

var _texture_cache: Dictionary = {}

func battle_background() -> Texture2D:
	return _texture_from_path(battle_background_path)

func boss_hp_bar_frame() -> Texture2D:
	return _texture_from_path(boss_hp_bar_frame_path)

func vertical_queue_frame() -> Texture2D:
	return _texture_from_path(vertical_queue_frame_path)

func player_portrait() -> Texture2D:
	return _texture_from_path(player_portrait_path)

func boss_portrait() -> Texture2D:
	return _texture_from_path(boss_portrait_path)

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

func get_orb_glow_texture(ball: BallState) -> Texture2D:
	if ball == null:
		return null
	if ball.kind == BallState.Kind.COLOR:
		return _color_orb_glow_texture(ball.color_id)
	if ball.kind == BallState.Kind.COMBAT:
		return _combat_orb_glow_texture(ball.combat_kind)
	if ball.kind == BallState.Kind.HAZARD:
		return _texture_from_path(eclipse_orb_danger_glow_path if ball.hazard_phase == BallState.HazardPhase.DANGER else eclipse_orb_warning_glow_path)
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

func _color_orb_glow_texture(color_id: int) -> Texture2D:
	match max(color_id, 0) % 4:
		0:
			return _texture_from_path(color_orb_red_glow_path)
		1:
			return _texture_from_path(color_orb_blue_glow_path)
		2:
			return _texture_from_path(color_orb_gold_glow_path)
		3:
			return _texture_from_path(color_orb_green_glow_path)
	return _texture_from_path(color_orb_red_glow_path)

func _combat_orb_glow_texture(combat_kind: int) -> Texture2D:
	match combat_kind:
		BallState.CombatKind.ATTACK:
			return _texture_from_path(combat_orb_attack_glow_path)
		BallState.CombatKind.SHIELD:
			return _texture_from_path(combat_orb_shield_glow_path)
		BallState.CombatKind.HEAL:
			return _texture_from_path(combat_orb_recover_glow_path)
	return _texture_from_path(combat_orb_attack_glow_path)

func _texture_from_path(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if _texture_cache.has(path):
		return _texture_cache[path] as Texture2D
	if ResourceLoader.exists(path):
		var loaded := ResourceLoader.load(path)
		if loaded is Texture2D:
			_texture_cache[path] = loaded
			return loaded
	var image := Image.new()
	var error := image.load(path)
	if error != OK:
		push_warning("VisualTheme failed to load texture path: %s" % path)
		return null
	var texture := ImageTexture.create_from_image(image)
	_texture_cache[path] = texture
	return texture
