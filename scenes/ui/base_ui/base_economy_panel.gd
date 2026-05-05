extends Control

const REPAIR_HP_PER_SCRAP := 5
const RESOURCE_TYPES := [
	ResourceData.ResourceType.IRON,
	ResourceData.ResourceType.GOLD,
	ResourceData.ResourceType.CRYSTAL,
	ResourceData.ResourceType.ICE,
	ResourceData.ResourceType.FUEL,
	ResourceData.ResourceType.SCRAP,
]

var _row_labels: Dictionary = {}
var _buy_buttons: Dictionary = {}
var _sell_buttons: Dictionary = {}
var _player: Node = null

@onready var market_cycle_label: Label = $Panel/Margin/Rows/MarketCycleLabel
@onready var payment_option: OptionButton = $Panel/Margin/Rows/PaymentRow/PaymentResourceOption
@onready var resource_rows: VBoxContainer = $Panel/Margin/Rows/ResourceRows
@onready var repair_button: Button = $Panel/Margin/Rows/Actions/RepairButton
@onready var close_button: Button = $Panel/Margin/Rows/Actions/CloseButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_payment_options()
	_create_resource_rows()
	_connect_signals()
	_on_game_state_changed(GameManager.current_state)
	_refresh()


func _create_payment_options() -> void:
	for resource_type in RESOURCE_TYPES:
		payment_option.add_item(ResourceData.get_type_name(resource_type).capitalize(), int(resource_type))
	var scrap_index := RESOURCE_TYPES.find(ResourceData.ResourceType.SCRAP)
	if scrap_index >= 0:
		payment_option.select(scrap_index)


func _create_resource_rows() -> void:
	for resource_type in RESOURCE_TYPES:
		var row := HBoxContainer.new()
		var label := Label.new()
		var buy_button := Button.new()
		var sell_button := Button.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		buy_button.pressed.connect(_on_buy_pressed.bind(resource_type))
		sell_button.pressed.connect(_on_sell_pressed.bind(resource_type))
		row.add_child(label)
		row.add_child(buy_button)
		row.add_child(sell_button)
		resource_rows.add_child(row)
		_row_labels[resource_type] = label
		_buy_buttons[resource_type] = buy_button
		_sell_buttons[resource_type] = sell_button


func _connect_signals() -> void:
	GameManager.game_state_changed.connect(_on_game_state_changed)
	ResourceManager.inventory_changed.connect(_on_inventory_changed)
	MarketManager.market_changed.connect(_on_inventory_changed)
	payment_option.item_selected.connect(_on_payment_resource_selected)
	repair_button.pressed.connect(_on_repair_pressed)
	close_button.pressed.connect(_on_close_pressed)


func _on_game_state_changed(new_state: GameManager.GameState) -> void:
	visible = new_state == GameManager.GameState.IN_BASE
	if visible:
		_find_player()
		_refresh()


func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	_player = players[0] if players.size() > 0 else null


func _refresh() -> void:
	market_cycle_label.text = "Market cycle: %d" % MarketManager.market_cycle
	var payment_type := _get_payment_resource()
	var payment_name := ResourceData.get_type_name(payment_type).capitalize()
	for resource_type in RESOURCE_TYPES:
		var amount := ResourceManager.get_resource_amount(resource_type)
		var unit_price := MarketManager.get_unit_price(resource_type)
		var buy_cost := MarketManager.quote_buy(resource_type, payment_type)
		var sell_gain := MarketManager.quote_sell(resource_type, payment_type)
		(_row_labels[resource_type] as Label).text = "%s: %d  value %d" % [
			ResourceData.get_type_name(resource_type).capitalize(),
			amount,
			unit_price
		]
		(_buy_buttons[resource_type] as Button).text = "Buy 1 (%d %s)" % [buy_cost, payment_name]
		(_buy_buttons[resource_type] as Button).disabled = not MarketManager.can_buy_resource(resource_type, payment_type)
		(_sell_buttons[resource_type] as Button).text = "Sell 1 (+%d %s)" % [sell_gain, payment_name]
		(_sell_buttons[resource_type] as Button).disabled = not MarketManager.can_sell_resource(resource_type, payment_type)
	_update_repair_button()


func _update_repair_button() -> void:
	var cost := _get_repair_scrap_cost()
	repair_button.text = "Repair (%d Scrap)" % cost
	repair_button.disabled = cost <= 0 or ResourceManager.get_resource_amount(ResourceData.ResourceType.SCRAP) < cost


func _get_repair_scrap_cost() -> int:
	var missing := _get_missing_health()
	if missing <= 0:
		return 0
	return int(ceil(float(missing) / float(REPAIR_HP_PER_SCRAP)))


func _get_missing_health() -> int:
	if _player == null or not is_instance_valid(_player):
		return 0
	if not ("current_health" in _player and "max_health" in _player):
		return 0
	return maxi(0, int(_player.max_health) - int(_player.current_health))


func _get_payment_resource() -> ResourceData.ResourceType:
	var selected_id := payment_option.get_selected_id()
	if selected_id < 0:
		return ResourceData.ResourceType.SCRAP
	return selected_id as ResourceData.ResourceType


func _on_buy_pressed(resource_type: ResourceData.ResourceType) -> void:
	MarketManager.buy_resource(resource_type, _get_payment_resource())
	_refresh()


func _on_sell_pressed(resource_type: ResourceData.ResourceType) -> void:
	MarketManager.sell_resource(resource_type, _get_payment_resource())
	_refresh()


func _on_repair_pressed() -> void:
	var missing := _get_missing_health()
	var cost := _get_repair_scrap_cost()
	if missing > 0 and _player.has_method("heal") and ResourceManager.remove_resource(ResourceData.ResourceType.SCRAP, cost):
		_player.heal(missing)
	_refresh()


func _on_close_pressed() -> void:
	GameManager.exit_base()


func _on_inventory_changed(_value = null) -> void:
	if visible:
		_refresh()


func _on_payment_resource_selected(_index: int) -> void:
	_refresh()
