extends Node
## 카드 덱 관리
## 카드풀에서 덱을 구성하고 핸드를 관리합니다.

signal hand_changed(hand: Array)

const HAND_SIZE: int = 4
const COPIES_PER_CARD: int = 3

@export var card_pool: Array[CardData] = []

var deck: Array[CardData] = []
var hand: Array[CardData] = []
var _active_cards: Array[CardData] = []

var _player_cards: Array[CardData] = []
var _enemy_cards: Array[CardData] = []
var _cards_loaded: bool = false


func _ensure_cards_loaded() -> void:
	if _cards_loaded:
		return
	_cards_loaded = true
	_player_cards = _load_cards([
		"res://resources/cards/knight.tres",
		"res://resources/cards/mage.tres",
		"res://resources/cards/barbarian.tres",
		"res://resources/cards/rogue.tres",
	])
	_enemy_cards = _load_cards([
		"res://resources/cards/skeleton_warrior.tres",
		"res://resources/cards/skeleton_bolt.tres",
		"res://resources/cards/bone_barricade.tres",
		"res://resources/cards/skeleton_minion.tres",
	])


func setup_player_deck() -> void:
	_ensure_cards_loaded()
	_build_deck(_player_cards)


func setup_enemy_deck() -> void:
	_ensure_cards_loaded()
	_build_deck(_enemy_cards)


func _build_deck(cards: Array[CardData]) -> void:
	_active_cards = []
	deck.clear()
	hand.clear()

	for card in cards:
		if card:
			_active_cards.append(card)

	if _active_cards.is_empty():
		push_error("[CardDeck] No valid cards found while building deck.")
		hand_changed.emit(hand)
		return

	# 각 카드 3장씩
	for card in _active_cards:
		for i in COPIES_PER_CARD:
			deck.append(card)

	# 셔플
	deck.shuffle()

	# 초기 핸드 드로우
	for i in HAND_SIZE:
		if not deck.is_empty():
			hand.append(deck.pop_back())

	hand_changed.emit(hand)


func play_card(index: int) -> CardData:
	if index < 0 or index >= hand.size():
		return null

	var card: CardData = hand[index]
	hand.remove_at(index)

	# 덱에서 새 카드 드로우
	if deck.is_empty():
		_refill_deck()
	if not deck.is_empty():
		hand.append(deck.pop_back())

	hand_changed.emit(hand)
	return card


func _refill_deck() -> void:
	for card in _active_cards:
		for i in COPIES_PER_CARD:
			deck.append(card)
	deck.shuffle()


func get_hand() -> Array[CardData]:
	var result: Array[CardData] = []
	for card in hand:
		result.append(card)
	return result


func get_affordable_card_index(mana: float) -> int:
	# AI용: 가장 비싼 낼 수 있는 카드 인덱스 반환
	var best_index: int = -1
	var best_cost: int = 0

	for i in hand.size():
		if hand[i] and hand[i].mana_cost <= int(mana) and hand[i].mana_cost > best_cost:
			best_cost = hand[i].mana_cost
			best_index = i

	return best_index


func get_next_card_preview() -> CardData:
	if deck.is_empty():
		return null
	return deck[deck.size() - 1]


func _load_cards(paths: Array[String]) -> Array[CardData]:
	var cards: Array[CardData] = []
	for path in paths:
		var card: CardData = load(path)
		if not card:
			push_error("[CardDeck] Failed to load card resource: %s" % path)
			continue
		cards.append(card)
	return cards
