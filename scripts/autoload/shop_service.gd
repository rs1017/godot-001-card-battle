extends Node
## 상점 서비스

var _catalog: Dictionary = {
	"pack_starter": {"currency": "gold", "price": 300, "grant_cards": {"soldier": 2, "archer": 1}},
	"bundle_gem": {"currency": "gem", "price": 20, "grant_items": {"boost_ticket": 2}},
	"mail_coupon": {"currency": "gold", "price": 100, "grant_items": {"mail_ticket": 1}},
}


func list_catalog() -> Dictionary:
	return _catalog.duplicate(true)


func purchase(product_id: String, quantity: int = 1) -> bool:
	if quantity <= 0:
		EventBus.shop_purchase_result.emit(false, product_id, quantity, "E_SHOP_QTY", 0)
		return false
	if not AuthService.is_logged_in():
		EventBus.shop_purchase_result.emit(false, product_id, quantity, "E_AUTH_REQUIRED", 0)
		return false
	if not _catalog.has(product_id):
		LogService.add("WARN", "shop", "purchase rejected: unknown product", {"product_id": product_id})
		EventBus.shop_purchase_result.emit(false, product_id, quantity, "E_SHOP_UNKNOWN", 0)
		return false

	var spec: Dictionary = _catalog[product_id]
	var total_price: int = int(spec["price"]) * quantity
	var currency: String = String(spec["currency"])
	if not AuthService.try_spend(currency, total_price):
		EventBus.shop_purchase_result.emit(false, product_id, quantity, "E_SHOP_NO_CURRENCY", AuthService.get_wallet(currency))
		return false

	if spec.has("grant_cards"):
		for card_id: String in spec["grant_cards"].keys():
			InventoryService.add_card(card_id, int(spec["grant_cards"][card_id]) * quantity)
	if spec.has("grant_items"):
		for item_id: String in spec["grant_items"].keys():
			InventoryService.grant_item(item_id, int(spec["grant_items"][item_id]) * quantity, "shop_purchase")

	LogService.add("INFO", "shop", "purchase success", {"product_id": product_id, "quantity": quantity, "currency": currency, "spent": total_price})
	EventBus.shop_purchase_result.emit(true, product_id, quantity, "OK", AuthService.get_wallet(currency))
	return true
