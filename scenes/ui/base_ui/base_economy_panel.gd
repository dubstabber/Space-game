extends Control

const REPAIR_COST_PER_HP := 2
const RESOURCE_TYPES := [
	ResourceData.ResourceType.IRON,
	ResourceData.ResourceType.GOLD,
	ResourceData.ResourceType.CRYSTAL,
	ResourceData.ResourceType.ICE,
	ResourceData.ResourceType.FUEL,
	ResourceData.ResourceType.SCRAP,
]

var _row_labels: Dictionary = {}
var _sell_buttons: Dictionary = {}
var _player: Node = null

@onready var credits_label: Label = $Panel/Margin/Rows/CreditsLabel
@onready var resource_rows: VBoxContainer = $Panel/Margin/Rows/ResourceRows
@onready var repair_button: Button = $Panel/Margin/Rows/Actions/RepairButton
@onready var sell_all_button: Button = $Panel/Margin/Rows/Actions/SellAllButton
@onready var close_button: Button = $Panel/Margin/Rows/Actions/CloseButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_resource_rows()
	_connect_signals()
	_on_game_state_changed(GameManager.current_state)
	_refresh()


func _create_resource_rows() -> void:
	for resource_type in RESOURCE_TYPES:
		var row := HBoxContainer.new()
		var label := Label.new()
		var button := Button.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text = "Sell"
		button.pressed.connect(_on_sell_pressed.bind(resource_type))
		row.add_child(label)
		row.add_child(button)
		resource_rows.add_child(row)
		_row_labels[resource_type] = label
		_sell_buttons[resource_type] = button


func _connect_signals() -> void:
	GameManager.game_state_changed.connect(_on_game_state_changed)
	ResourceManager.credits_changed.connect(_on_inventory_changed)
	ResourceManager.inventory_changed.connect(_on_inventory_changed)
	repair_button.pressed.connect(_on_repair_pressed)
	sell_all_button.pressed.connect(_on_sell_all_pressed)
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
	credits_label.text = "Credits: %d" % ResourceManager.credits
	var has_resources := false
	for resource_type in RESOURCE_TYPES:
		var amount := ResourceManager.get_resource_amount(resource_type)
		var value := ResourceData.get_base_value(resource_type)
		(_row_labels[resource_type] as Label).text = "%s: %d  (%d cr each)" % [
			ResourceData.get_type_name(resource_type).capitalize(),
			amount,
			value
		]
		(_sell_buttons[resource_type] as Button).disabled = amount <= 0
		has_resources = has_resources or amount > 0
	sell_all_button.disabled = not has_resources
	_update_repair_button()


func _update_repair_button() -> void:
	var missing := _get_missing_health()
	var cost := missing * REPAIR_COST_PER_HP
	repair_button.text = "Repair (%d cr)" % cost
	repair_button.disabled = missing <= 0 or ResourceManager.credits < cost


func _get_missing_health() -> int:
	if _player == null or not is_instance_valid(_player):
		return 0
	if not ("current_health" in _player and "max_health" in _player):
		return 0
	return maxi(0, int(_player.max_health) - int(_player.current_health))


func _on_sell_pressed(resource_type: ResourceData.ResourceType) -> void:
	ResourceManager.sell_resource(resource_type, ResourceManager.get_resource_amount(resource_type))
	_refresh()


func _on_sell_all_pressed() -> void:
	ResourceManager.sell_all_resources()
	_refresh()


func _on_repair_pressed() -> void:
	var missing := _get_missing_health()
	var cost := missing * REPAIR_COST_PER_HP
	if missing > 0 and ResourceManager.spend_credits(cost) and _player.has_method("heal"):
		_player.heal(missing)
	_refresh()


func _on_close_pressed() -> void:
	GameManager.exit_base()


func _on_inventory_changed(_value = null) -> void:
	if visible:
		_refresh()
