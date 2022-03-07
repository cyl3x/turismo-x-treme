extends Control

var url_encoded

signal switch(to)

func _ready():
	if not ProjectSettings.get_setting("global/build_date") in [ "", "null", "Null" ]:
		url_encoded = "\"Project\" is \"cyl3x/godot-racing-game\" and successful and \"Submit Date\" is since \"" + ProjectSettings.get_setting("global/build_date") + "\"".percent_encode()
		var _discart = $HBox/main.connect("update_request", self, "_update_check_request")
	else:
		$HBox/main/settingsBox.remove_child($HBox/main/settingsBox/updateBtn)

func _on_update_request_completed(_result, response_code, _headers, body):
	if response_code == 200:
		var json = JSON.parse(body.get_string_from_utf8())
		if not json.error:
			var _discard = OS.shell_open("https://git.cyl3x.de/projects/" + str(json.result[0].projectId) + "/builds/" + str(json.result[0].number) + "/artifacts")

func _update_check_request():
	if url_encoded:
		$Update.request("https://git.cyl3x.de/api/builds?count=1&offset=0&query=" + url_encoded)
	else:
		print("ERROR: Update url not set")

func _on_car_pressed():
	emit_signal("switch", "car_selector")

func _on_credits_pressed():
	emit_signal("switch", "credits")
