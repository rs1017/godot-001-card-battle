class_name CardData extends Resource
## 카드 데이터 리소스
## 미니언의 스탯과 모델 정보를 정의합니다.

enum MinionType { MELEE, RANGED, TANK }
enum CardCategory { TROOP, SPELL, BUILDING }

@export_group("Basic Info")
@export var card_name: String = ""
@export var mana_cost: int = 3
@export var card_category: CardCategory = CardCategory.TROOP
@export var minion_type: MinionType = MinionType.MELEE

@export_group("Stats")
@export var health: int = 100
@export var damage: int = 20
@export var attack_speed: float = 1.0
@export var move_speed: float = 3.0
@export var attack_range: float = 2.0
@export var aggro_range: float = 6.0

@export_group("Visuals")
@export var kaykit_model_path: String = ""

@export_group("Animation Overrides")
@export var anim_idle: String = "Idle"
@export var anim_walk: String = "Walking_A"
@export var anim_attack: String = "1H_Melee_Attack_Chop"
@export var anim_hit: String = "Hit_A"
@export var anim_death: String = "Death_A"
