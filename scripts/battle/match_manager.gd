extends Node3D
## 매치 매니저 (BattleArena 루트)
## 모든 배틀 시스템을 연결하고 스폰/승패를 관리합니다.

const MinionScene: PackedScene = preload("res://scenes/battle/minion.tscn")
enum MatchPhase { NORMAL, OVERTIME, TIEBREAKER }

const NORMAL_DURATION: float = 180.0
const OVERTIME_DURATION: float = 120.0
const TIEBREAKER_DURATION: float = 30.0
const TIEBREAKER_TICK_INTERVAL: float = 1.0
const TIEBREAKER_DAMAGE_PER_TICK: int = 20
const SUDDEN_DEATH_MAX_DURATION: float = 60.0
const SUDDEN_DEATH_DAMAGE_BASE: int = 24
const SUDDEN_DEATH_DAMAGE_STEP: int = 8
const SUDDEN_DEATH_STEP_INTERVAL: float = 10.0

@onready var lane_manager: Node3D = $Lanes
@onready var mana_manager: Node = $ManaManager
@onready var card_deck: Node = $CardDeck
@onready var ai_opponent: Node = $AIOpponent
@onready var battle_hud: CanvasLayer = $BattleHUD
@onready var player_tower: StaticBody3D = $Entities/PlayerTower
@onready var enemy_tower: StaticBody3D = $Entities/EnemyTower
@onready var player_minions: Node3D = $Entities/PlayerMinions
@onready var enemy_minions: Node3D = $Entities/EnemyMinions

var _selected_card_index: int = -1
var _match_timer: float = 0.0
var _match_active: bool = false
var _current_phase: MatchPhase = MatchPhase.NORMAL
var _phase_time_left: float = NORMAL_DURATION
var _tiebreaker_tick_accum: float = 0.0
var _is_sudden_death: bool = false
var _sudden_death_elapsed: float = 0.0


func _ready() -> void:
	if not _validate_dependencies():
		push_error("[MatchManager] Missing required battle nodes. Match start aborted.")
		return
	_start_match()


func _process(delta: float) -> void:
	if _match_active:
		_match_timer += delta
		_update_phase(delta)
		_update_hud_phase_timer()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("card_cancel"):
		_cancel_deploy()


func _start_match() -> void:
	_match_active = true
	_match_timer = 0.0
	_current_phase = MatchPhase.NORMAL
	_phase_time_left = NORMAL_DURATION
	_tiebreaker_tick_accum = 0.0
	_is_sudden_death = false
	_sudden_death_elapsed = 0.0
	GameManager.change_state(GameManager.GameState.BATTLE_PLAYING)

	# 플레이어 덱 설정
	if card_deck and card_deck.has_method("setup_player_deck"):
		card_deck.setup_player_deck()
	else:
		push_error("[MatchManager] CardDeck is missing setup_player_deck().")
		return

	# AI 전용 카드 덱 생성
	var ai_deck_script: Script = load("res://scripts/battle/card_deck.gd")
	if not ai_deck_script:
		push_error("[MatchManager] Failed to load AI deck script.")
		return
	var ai_deck_node: Node = Node.new()
	ai_deck_node.set_script(ai_deck_script)
	ai_opponent.add_child(ai_deck_node)
	ai_opponent.card_deck = ai_deck_node

	# AI 시작
	if ai_opponent and ai_opponent.has_signal("ai_play_card"):
		if not ai_opponent.ai_play_card.is_connected(_on_ai_play_card):
			ai_opponent.ai_play_card.connect(_on_ai_play_card)
	if ai_opponent:
		ai_opponent.lane_picker = Callable(self, "_pick_ai_lane")
	if ai_opponent and ai_opponent.has_method("start"):
		ai_opponent.start()

	# 타워 시그널 연결
	if player_tower and player_tower.has_signal("tower_destroyed"):
		if not player_tower.tower_destroyed.is_connected(_on_player_tower_destroyed):
			player_tower.tower_destroyed.connect(_on_player_tower_destroyed)
	if enemy_tower and enemy_tower.has_signal("tower_destroyed"):
		if not enemy_tower.tower_destroyed.is_connected(_on_enemy_tower_destroyed):
			enemy_tower.tower_destroyed.connect(_on_enemy_tower_destroyed)

	# HUD 연결
	if mana_manager and mana_manager.has_signal("mana_changed"):
		if not mana_manager.mana_changed.is_connected(battle_hud._on_mana_changed):
			mana_manager.mana_changed.connect(battle_hud._on_mana_changed)
	if card_deck and card_deck.has_signal("hand_changed"):
		if not card_deck.hand_changed.is_connected(battle_hud._on_hand_changed):
			card_deck.hand_changed.connect(battle_hud._on_hand_changed)
	if battle_hud and battle_hud.has_signal("card_selected"):
		if not battle_hud.card_selected.is_connected(_on_card_selected):
			battle_hud.card_selected.connect(_on_card_selected)
	if battle_hud and battle_hud.has_signal("lane_selected"):
		if not battle_hud.lane_selected.is_connected(_on_lane_selected):
			battle_hud.lane_selected.connect(_on_lane_selected)

	# 초기 HUD 업데이트
	if battle_hud and battle_hud.has_method("setup"):
		battle_hud.setup(player_tower, enemy_tower, card_deck)
	_update_hud_phase_timer()

	EventBus.match_started.emit()
	print("[MatchManager] Match started!")


func _on_card_selected(card_index: int) -> void:
	if not _match_active:
		return

	if not card_deck or not card_deck.has_method("get_hand"):
		return

	var hand: Array = card_deck.get_hand()
	if card_index < 0 or card_index >= hand.size():
		return

	var card: CardData = hand[card_index]
	if not mana_manager or not mana_manager.has_method("can_afford"):
		return
	if not mana_manager.can_afford(card.mana_cost):
		return

	_selected_card_index = card_index
	GameManager.change_state(GameManager.GameState.BATTLE_DEPLOYING)
	EventBus.deploy_mode_entered.emit(card_index)
	if battle_hud and battle_hud.has_method("show_lane_select"):
		battle_hud.show_lane_select()


func _on_lane_selected(lane_index: int) -> void:
	if _selected_card_index < 0:
		return

	if not card_deck or not card_deck.has_method("play_card"):
		return

	var card: CardData = card_deck.play_card(_selected_card_index)
	if card:
		if _resolve_player_card(card, lane_index):
			if mana_manager and mana_manager.has_method("spend"):
				mana_manager.spend(card.mana_cost)
			EventBus.card_played.emit(card, 0, lane_index)

	_selected_card_index = -1
	GameManager.change_state(GameManager.GameState.BATTLE_PLAYING)
	EventBus.deploy_mode_exited.emit()
	if battle_hud and battle_hud.has_method("hide_lane_select"):
		battle_hud.hide_lane_select()


func _cancel_deploy() -> void:
	if GameManager.current_state == GameManager.GameState.BATTLE_DEPLOYING:
		_selected_card_index = -1
		GameManager.change_state(GameManager.GameState.BATTLE_PLAYING)
		EventBus.deploy_mode_exited.emit()
		if battle_hud and battle_hud.has_method("hide_lane_select"):
			battle_hud.hide_lane_select()


func spawn_player_minion(card: CardData, lane_index: int) -> void:
	if not lane_manager or not lane_manager.has_method("get_waypoints") or not lane_manager.has_method("get_spawn_position"):
		push_warning("[MatchManager] LaneManager does not provide spawn helpers.")
		return
	var minion: CharacterBody3D = MinionScene.instantiate()
	player_minions.add_child(minion)

	var waypoints: Array[Vector3] = lane_manager.get_waypoints(lane_index)
	var spawn_pos: Vector3 = lane_manager.get_spawn_position(lane_index, true)
	# 바닥 위에 스폰 + 약간의 x 랜덤 오프셋 (겹침 방지)
	spawn_pos.y = 0.5
	spawn_pos.x += randf_range(-0.5, 0.5)
	minion.global_position = spawn_pos
	minion.setup(card, minion.Team.PLAYER, waypoints)

	EventBus.minion_spawned.emit(minion, 0)
	print("[MatchManager] Player spawned %s on lane %d" % [card.card_name, lane_index])


func spawn_enemy_minion(card: CardData, lane_index: int) -> void:
	if not lane_manager or not lane_manager.has_method("get_waypoints") or not lane_manager.has_method("get_spawn_position"):
		push_warning("[MatchManager] LaneManager does not provide spawn helpers.")
		return
	var minion: CharacterBody3D = MinionScene.instantiate()
	enemy_minions.add_child(minion)

	var waypoints: Array[Vector3] = lane_manager.get_waypoints(lane_index)
	var spawn_pos: Vector3 = lane_manager.get_spawn_position(lane_index, false)
	spawn_pos.y = 0.5
	spawn_pos.x += randf_range(-0.5, 0.5)
	minion.global_position = spawn_pos
	minion.setup(card, minion.Team.ENEMY, waypoints)

	EventBus.minion_spawned.emit(minion, 1)
	print("[MatchManager] Enemy spawned %s on lane %d" % [card.card_name, lane_index])


func _on_ai_play_card(card: CardData, lane_index: int) -> void:
	if _resolve_enemy_card(card, lane_index):
		EventBus.card_played.emit(card, 1, lane_index)


func _on_player_tower_destroyed(_tower: StaticBody3D) -> void:
	_end_match(false)


func _on_enemy_tower_destroyed(_tower: StaticBody3D) -> void:
	_end_match(true)


func _end_match(player_won: bool) -> void:
	if not _match_active:
		return
	_match_active = false
	if ai_opponent and ai_opponent.has_method("stop"):
		ai_opponent.stop()

	# 모든 미니언 서서히 제거
	_cleanup_minions(player_minions)
	_cleanup_minions(enemy_minions)

	GameManager.change_state(GameManager.GameState.GAME_OVER)
	if battle_hud and battle_hud.has_method("show_game_over"):
		battle_hud.show_game_over(player_won)
	EventBus.match_ended.emit(player_won)
	print("[MatchManager] Match ended! Player won: %s" % str(player_won))


func _cleanup_minions(container: Node3D) -> void:
	for child in container.get_children():
		var sm: StateMachine = child.get_node_or_null("StateMachine")
		if sm:
			if sm.is_in_state("DeathState"):
				continue
			sm.transition_to("DeathState")


func _update_phase(delta: float) -> void:
	if not _match_active:
		return
	_phase_time_left -= delta

	match _current_phase:
		MatchPhase.NORMAL:
			if _phase_time_left <= 0.0:
				_enter_overtime()
		MatchPhase.OVERTIME:
			if _phase_time_left <= 0.0:
				_enter_tiebreaker()
		MatchPhase.TIEBREAKER:
			if _phase_time_left <= 0.0:
				_phase_time_left = 0.0
				_is_sudden_death = true
				_sudden_death_elapsed = 0.0
			_tiebreaker_tick_accum += delta
			while _tiebreaker_tick_accum >= TIEBREAKER_TICK_INTERVAL:
				_tiebreaker_tick_accum -= TIEBREAKER_TICK_INTERVAL
				if _is_sudden_death:
					_apply_sudden_death_tick_damage()
				else:
					_apply_tiebreaker_tick_damage()
				if not _match_active:
					return
			if _is_sudden_death:
				_sudden_death_elapsed += delta
				if _sudden_death_elapsed >= SUDDEN_DEATH_MAX_DURATION:
					_resolve_timeout_winner()
					return


func _enter_overtime() -> void:
	_current_phase = MatchPhase.OVERTIME
	_phase_time_left = OVERTIME_DURATION
	print("[MatchManager] Overtime started.")


func _enter_tiebreaker() -> void:
	_current_phase = MatchPhase.TIEBREAKER
	_phase_time_left = TIEBREAKER_DURATION
	_tiebreaker_tick_accum = 0.0
	_is_sudden_death = false
	print("[MatchManager] Tiebreaker started.")


func _apply_tiebreaker_tick_damage() -> void:
	var player_health: HealthComponent = player_tower.get_node_or_null("HealthComponent")
	if player_health and not player_health.is_dead:
		player_health.take_damage(TIEBREAKER_DAMAGE_PER_TICK, self)

	var enemy_health: HealthComponent = enemy_tower.get_node_or_null("HealthComponent")
	if enemy_health and not enemy_health.is_dead:
		enemy_health.take_damage(TIEBREAKER_DAMAGE_PER_TICK, self)


func _apply_sudden_death_tick_damage() -> void:
	var step_level: int = int(_sudden_death_elapsed / SUDDEN_DEATH_STEP_INTERVAL)
	var damage: int = SUDDEN_DEATH_DAMAGE_BASE + (SUDDEN_DEATH_DAMAGE_STEP * step_level)

	var player_health: HealthComponent = player_tower.get_node_or_null("HealthComponent")
	if player_health and not player_health.is_dead:
		player_health.take_damage(damage, self)

	var enemy_health: HealthComponent = enemy_tower.get_node_or_null("HealthComponent")
	if enemy_health and not enemy_health.is_dead:
		enemy_health.take_damage(damage, self)


func _resolve_timeout_winner() -> void:
	if not _match_active:
		return

	var player_hp: int = _get_tower_hp(player_tower)
	var enemy_hp: int = _get_tower_hp(enemy_tower)

	if player_hp != enemy_hp:
		_end_match(player_hp > enemy_hp)
		return

	var board_score: float = _calculate_board_pressure_advantage()
	if board_score != 0.0:
		_end_match(board_score > 0.0)
		return

	_end_match(randf() >= 0.5)


func _get_tower_hp(tower: StaticBody3D) -> int:
	if not tower:
		return 0
	var hp: HealthComponent = tower.get_node_or_null("HealthComponent")
	if not hp:
		return 0
	return hp.current_health


func _calculate_board_pressure_advantage() -> float:
	var score: float = 0.0

	for minion in player_minions.get_children():
		if not (minion is CharacterBody3D):
			continue
		if not minion.has_method("is_dead") or minion.is_dead():
			continue
		var hp: HealthComponent = minion.get_node_or_null("HealthComponent")
		var hp_factor: float = float(hp.current_health) / maxf(float(hp.max_health), 1.0) if hp else 0.5
		var dist_to_enemy: float = minion.global_position.distance_to(enemy_tower.global_position)
		score += hp_factor * (1.5 if dist_to_enemy < 16.0 else 1.0)

	for minion in enemy_minions.get_children():
		if not (minion is CharacterBody3D):
			continue
		if not minion.has_method("is_dead") or minion.is_dead():
			continue
		var hp: HealthComponent = minion.get_node_or_null("HealthComponent")
		var hp_factor: float = float(hp.current_health) / maxf(float(hp.max_health), 1.0) if hp else 0.5
		var dist_to_player: float = minion.global_position.distance_to(player_tower.global_position)
		score -= hp_factor * (1.5 if dist_to_player < 16.0 else 1.0)

	return score


func _update_hud_phase_timer() -> void:
	if battle_hud and battle_hud.has_method("update_match_phase"):
		battle_hud.update_match_phase(_get_phase_label(), _phase_time_left)


func _get_phase_label() -> String:
	match _current_phase:
		MatchPhase.NORMAL:
			return "NORMAL"
		MatchPhase.OVERTIME:
			return "OVERTIME"
		MatchPhase.TIEBREAKER:
			if _is_sudden_death:
				return "SUDDEN DEATH"
			return "TIEBREAKER"
		_:
			return "NORMAL"


func _resolve_player_card(card: CardData, lane_index: int) -> bool:
	if not card:
		return false
	var category: int = int(card.card_category)
	match category:
		CardData.CardCategory.TROOP:
			spawn_player_minion(card, lane_index)
			return true
		CardData.CardCategory.SPELL:
			return _cast_spell(card, lane_index, true)
		CardData.CardCategory.BUILDING:
			return _deploy_building(card, lane_index, true)
		_:
			push_warning("[MatchManager] Unknown player card category: %d" % category)
			return false


func _resolve_enemy_card(card: CardData, lane_index: int) -> bool:
	if not card:
		return false
	var category: int = int(card.card_category)
	match category:
		CardData.CardCategory.TROOP:
			spawn_enemy_minion(card, lane_index)
			return true
		CardData.CardCategory.SPELL:
			return _cast_spell(card, lane_index, false)
		CardData.CardCategory.BUILDING:
			return _deploy_building(card, lane_index, false)
		_:
			push_warning("[MatchManager] Unknown enemy card category: %d" % category)
			return false


func _cast_spell(card: CardData, lane_index: int, from_player: bool) -> bool:
	var target_container: Node3D = enemy_minions if from_player else player_minions
	var fallback_tower: StaticBody3D = enemy_tower if from_player else player_tower
	var preferred_x: float = lane_manager.get_spawn_position(lane_index, from_player).x if lane_manager and lane_manager.has_method("get_spawn_position") else 0.0

	var best_target: Node = null
	var best_lane_dist: float = INF
	for minion in target_container.get_children():
		if not (minion is CharacterBody3D):
			continue
		if not minion.has_node("HealthComponent"):
			continue
		var hp: HealthComponent = minion.get_node_or_null("HealthComponent")
		if not hp or hp.is_dead:
			continue
		var lane_dist: float = absf(minion.global_position.x - preferred_x)
		if lane_dist < best_lane_dist:
			best_lane_dist = lane_dist
			best_target = minion

	var damage: int = maxi(card.damage * 2, 1)
	if best_target:
		var minion_hp: HealthComponent = best_target.get_node_or_null("HealthComponent")
		if minion_hp:
			minion_hp.take_damage(damage, self)
			return true

	if fallback_tower:
		var tower_hp: HealthComponent = fallback_tower.get_node_or_null("HealthComponent")
		if tower_hp and not tower_hp.is_dead:
			tower_hp.take_damage(damage, self)
			return true

	return false


func _deploy_building(card: CardData, _lane_index: int, for_player: bool) -> bool:
	var tower: StaticBody3D = player_tower if for_player else enemy_tower
	if not tower:
		return false

	var tower_hp: HealthComponent = tower.get_node_or_null("HealthComponent")
	if not tower_hp or tower_hp.is_dead:
		return false

	var heal_amount: int = maxi(int(card.health / 2), 1)
	tower_hp.heal(heal_amount)
	return true


func _validate_dependencies() -> bool:
	if not lane_manager:
		return false
	if not mana_manager:
		return false
	if not card_deck:
		return false
	if not ai_opponent:
		return false
	if not battle_hud:
		return false
	if not player_tower:
		return false
	if not enemy_tower:
		return false
	if not player_minions:
		return false
	if not enemy_minions:
		return false
	return true


func _pick_ai_lane(_card: CardData) -> int:
	if not lane_manager or not lane_manager.has_method("get_spawn_position"):
		return randi() % 2

	var lane_scores: Array[float] = [0.0, 0.0]

	# 플레이어 미니언 압박이 높은 레인을 우선 방어
	for minion in player_minions.get_children():
		if not (minion is CharacterBody3D):
			continue
		if not minion.has_method("is_dead") or minion.is_dead():
			continue
		var lane_index: int = _get_lane_from_position(minion.global_position)
		var distance_to_enemy_tower: float = minion.global_position.distance_to(enemy_tower.global_position)
		var threat: float = 1.0
		if distance_to_enemy_tower < 16.0:
			threat = 2.0
		if distance_to_enemy_tower < 10.0:
			threat = 3.0
		lane_scores[lane_index] += threat

	# 이미 아군(적 AI 기준) 미니언이 많은 레인은 우선순위 감소
	for minion in enemy_minions.get_children():
		if not (minion is CharacterBody3D):
			continue
		if not minion.has_method("is_dead") or minion.is_dead():
			continue
		var lane_index: int = _get_lane_from_position(minion.global_position)
		lane_scores[lane_index] -= 0.6

	# 동률이면 랜덤
	if is_equal_approx(lane_scores[0], lane_scores[1]):
		return randi() % 2

	return 0 if lane_scores[0] > lane_scores[1] else 1


func _get_lane_from_position(world_pos: Vector3) -> int:
	var left_spawn: Vector3 = lane_manager.get_spawn_position(0, true)
	var right_spawn: Vector3 = lane_manager.get_spawn_position(1, true)
	var left_dist: float = absf(world_pos.x - left_spawn.x)
	var right_dist: float = absf(world_pos.x - right_spawn.x)
	return 0 if left_dist <= right_dist else 1
