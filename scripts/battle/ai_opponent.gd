extends Node
## AI 상대
## 3~7초 간격으로 가장 비싼 낼 수 있는 카드를 랜덤 레인에 배치합니다.

signal ai_play_card(card_data: CardData, lane_index: int)

var mana_manager: Node  # ManaManager 인스턴스 (AI 전용)
var card_deck: Node     # CardDeck 인스턴스 (AI 전용)
var lane_picker: Callable

var _ai_timer: float = 0.0
var _next_play_time: float = 4.0
var _is_active: bool = false
var _last_lane: int = -1

# AI 전용 마나
var _ai_mana: float = 5.0
const AI_MAX_MANA: float = 10.0
const AI_BASE_REGEN: float = 0.33
const AI_MAX_REGEN: float = 1.0
var _elapsed_time: float = 0.0


func start() -> void:
	_is_active = true
	_ai_mana = 5.0
	_elapsed_time = 0.0
	_next_play_time = randf_range(0.3, 0.5)
	_last_lane = -1

	# AI 전용 카드 덱 설정
	if card_deck:
		card_deck.setup_enemy_deck()


func stop() -> void:
	_is_active = false


func _process(delta: float) -> void:
	if not _is_active:
		return

	# AI 마나 리젠
	_elapsed_time += delta
	var regen_rate: float = lerpf(AI_BASE_REGEN, AI_MAX_REGEN, minf(_elapsed_time / 120.0, 1.0))
	_ai_mana = minf(_ai_mana + regen_rate * delta, AI_MAX_MANA)

	# 타이머
	_ai_timer += delta
	if _ai_timer >= _next_play_time:
		_ai_timer = 0.0
		_next_play_time = randf_range(0.3, 0.7)
		_try_play_card()


func _try_play_card() -> void:
	if not card_deck:
		return

	var card_index: int = card_deck.get_affordable_card_index(_ai_mana)
	if card_index < 0:
		return

	var card: CardData = card_deck.play_card(card_index)
	if card:
		_ai_mana -= card.mana_cost
		var lane: int = _pick_lane(card)
		ai_play_card.emit(card, lane)
		print("[AI] Playing %s on lane %d (Mana: %.1f)" % [card.card_name, lane, _ai_mana])


func _pick_lane(card: CardData) -> int:
	var lane: int = -1
	if lane_picker and lane_picker.is_valid():
		var picked: Variant = lane_picker.call(card)
		if typeof(picked) == TYPE_INT and int(picked) >= 0 and int(picked) <= 1:
			lane = int(picked)

	if lane < 0:
		lane = randi() % 2

	# 같은 레인 연속 사용 확률을 줄여 단조로움 완화
	if lane == _last_lane and randf() < 0.45:
		lane = 1 - lane

	_last_lane = lane
	return lane
