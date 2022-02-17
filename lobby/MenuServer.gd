extends Control

onready var PlayerList = $PlayerList
onready var spinner = $PlayerList/Spinner
onready var spinAni = $PlayerList/Spinner/SpinAni

func spin():
	spinner.visible = true
	spinAni.play("spin")

func stop_spin():
	spinner.visible = false
	spinAni.stop()

func _ready():
	spinner.visible = false
	PlayerList.clear()
	var _discart = Players.connect("list_data_updated", self, "refresh_players")

func refresh_players():
	if PlayerList.is_visible_in_tree():
		PlayerList.add_color_override("font_color", Color(0.631,0.631,0.631,1))
		PlayerList.clear()
		for player_id in Players.keys():
			var name = Players.get_nickname(player_id)
			PlayerList.add_item(str(name), null, false)
			PlayerList.set_item_custom_fg_color(PlayerList.get_item_count() - 1, Color(Players.get_color(player_id)))
		
func set_error_message(text):
	PlayerList.clear()
	PlayerList.add_item(str(text), null, false)
	PlayerList.set_item_custom_fg_color(PlayerList.get_item_count() - 1, Color.red)
	
