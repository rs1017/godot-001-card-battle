extends Control
## 메타 시스템 수동 검증용 로비

@onready var user_id_input: LineEdit = $Margin/Root/TopRow/UserIdInput
@onready var password_input: LineEdit = $Margin/Root/TopRow/PasswordInput
@onready var output_log: RichTextLabel = $Margin/Root/OutputPanel/OutputLog


func _ready() -> void:
	$Margin/Root/TopRow/LoginButton.pressed.connect(_on_login_pressed)
	$Margin/Root/TopRow/SaveDataButton.pressed.connect(_on_save_pressed)
	$Margin/Root/TopRow/LoadDataButton.pressed.connect(_on_load_pressed)
	$Margin/Root/TopRow/BackButton.pressed.connect(_on_back_pressed)
	$Margin/Root/Tabs/EconomyTab/EconomyRow/BuyStarterButton.pressed.connect(_on_buy_starter_pressed)
	$Margin/Root/Tabs/EconomyTab/EconomyRow/RefreshSnapshotButton.pressed.connect(_on_refresh_snapshot_pressed)
	$Margin/Root/Tabs/SocialTab/SocialRow1/SendGlobalChatButton.pressed.connect(_on_send_chat_pressed)
	$Margin/Root/Tabs/SocialTab/SocialRow1/AddFriendButton.pressed.connect(_on_add_friend_pressed)
	$Margin/Root/Tabs/SocialTab/SocialRow2/CreatePartyButton.pressed.connect(_on_create_party_pressed)
	$Margin/Root/Tabs/SocialTab/SocialRow2/CreateGuildButton.pressed.connect(_on_create_guild_pressed)
	$Margin/Root/Tabs/LiveOpsTab/LiveOpsRow/SendMailButton.pressed.connect(_on_send_mail_pressed)
	$Margin/Root/Tabs/LiveOpsTab/LiveOpsRow/ClaimMailButton.pressed.connect(_on_claim_mail_pressed)
	$Margin/Root/Tabs/CombatTab/CombatRow/CastSkillButton.pressed.connect(_on_cast_skill_pressed)
	_append_log("Meta lobby ready. save_path=%s" % MetaPersistenceService.get_save_path())


func _on_login_pressed() -> void:
	var ok: bool = AuthService.login(user_id_input.text.strip_edges(), password_input.text.strip_edges())
	_append_log("login=%s user=%s" % [ok, AuthService.get_active_user_id()])
	_on_refresh_snapshot_pressed()


func _on_save_pressed() -> void:
	var ok: bool = MetaPersistenceService.save_all()
	_append_log("save_all=%s" % ok)


func _on_load_pressed() -> void:
	var ok: bool = MetaPersistenceService.load_all()
	_append_log("load_all=%s" % ok)
	_on_refresh_snapshot_pressed()


func _on_buy_starter_pressed() -> void:
	var ok: bool = ShopService.purchase("pack_starter", 1)
	_append_log("purchase pack_starter=%s" % ok)
	_on_refresh_snapshot_pressed()


func _on_send_chat_pressed() -> void:
	var ok: bool = ChatService.send_message("global", "hello from meta lobby")
	_append_log("chat global send=%s" % ok)


func _on_add_friend_pressed() -> void:
	var ok: bool = SocialService.send_friend_request("friend_bot")
	_append_log("friend request to friend_bot=%s" % ok)


func _on_create_party_pressed() -> void:
	var party_id: String = SocialService.create_party()
	var joined: bool = SocialService.add_party_member("party_bot")
	_append_log("party id=%s joined_party_bot=%s" % [party_id, joined])


func _on_create_guild_pressed() -> void:
	var guild_id: String = "guild_alpha"
	var created: bool = SocialService.create_guild(guild_id)
	var joined: bool = SocialService.add_guild_member("guild_bot")
	_append_log("guild id=%s created=%s joined_guild_bot=%s" % [guild_id, created, joined])


func _on_cast_skill_pressed() -> void:
	var caster_id: String = AuthService.get_active_user_id()
	if caster_id.is_empty():
		_append_log("skill cast blocked: login required")
		return
	SkillService.set_caster_mana(caster_id, 10.0)
	var ok: bool = SkillService.request_cast(caster_id, "fireball", "enemy_dummy")
	_append_log("cast fireball=%s mana_after=%.2f" % [ok, SkillService.get_caster_mana(caster_id)])


func _on_send_mail_pressed() -> void:
	var user_id: String = AuthService.get_active_user_id()
	if user_id.is_empty():
		_append_log("mail send blocked: login required")
		return
	var mail_id: String = MailService.send_mail(user_id, "Daily Gift", "claim your gift", {"boost_ticket": 1})
	_append_log("mail sent id=%s" % mail_id)


func _on_claim_mail_pressed() -> void:
	var mails: Array = MailService.get_mailbox()
	if mails.is_empty():
		_append_log("no mail to claim")
		return
	var mail_id: String = String(mails[0].get("mail_id", ""))
	var ok: bool = MailService.claim_mail(mail_id)
	_append_log("mail claim id=%s result=%s" % [mail_id, ok])
	_on_refresh_snapshot_pressed()


func _on_refresh_snapshot_pressed() -> void:
	var user_id: String = AuthService.get_active_user_id()
	var gold: int = AuthService.get_wallet("gold")
	var gem: int = AuthService.get_wallet("gem")
	var cards: Dictionary = InventoryService.get_card_snapshot()
	var items: Dictionary = InventoryService.get_item_snapshot()
	_append_log("snapshot user=%s gold=%d gem=%d cards=%s items=%s" % [user_id, gold, gem, cards, items])


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _append_log(line: String) -> void:
	output_log.append_text("%s\n" % line)
