extends RefCounted
class_name BattleState

var player_max_hp: int = 30
var player_hp: int = 30
var player_shield: int = 0
var boss_max_hp: int = 200
var boss_hp: int = 200

func apply_player_damage(amount: int) -> void:
	var remaining: int = max(amount, 0)
	var absorbed: int = min(player_shield, remaining)
	player_shield -= absorbed
	remaining -= absorbed
	player_hp = max(player_hp - remaining, 0)

func apply_attack_to_boss(amount: int) -> void:
	var damage: int = max(amount, 0)
	boss_hp = max(boss_hp - damage, 0)

func add_shield(amount: int) -> void:
	player_shield += max(amount, 0)

func heal_player(amount: int) -> void:
	var healed: int = max(amount, 0)
	player_hp = min(player_hp + healed, player_max_hp)

func result() -> String:
	if boss_hp <= 0:
		return "win"
	if player_hp <= 0:
		return "loss"
	return "active"
