extends HBoxContainer
## 마나바 UI
## ProgressBar + 숫자 표시

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var mana_label: Label = $ManaLabel


func _ready() -> void:
	progress_bar.max_value = 10.0
	progress_bar.value = 5.0


func update_mana(current: float, max_mana: float) -> void:
	progress_bar.max_value = max_mana
	progress_bar.value = current
	mana_label.text = "%d/%d" % [int(current), int(max_mana)]
