extends Node

const file_name = "config.cfg"

var config = ConfigFile.new()

func _ready():
	var file = File.new()
	
	if file.file_exists("user://" + file_name):
		if OK != config.load("user://" + file_name):
			print("ERROR: Cannot load config file '" + file_name + "'")
			return
	else:
		save()

func save():
	config.save("user://" + file_name)

func set_setting(name, value):
	if config.has_section_key("Settings", name) or value != get_setting(name):
		config.set_value("Settings", name, value)
		save()
	
func get_setting(name):
	return config.get_value("Settings", name)
	
func has_setting(name):
	return config.has_section("Settings") and config.has_section_key("Settings", name)

func set_player_setting(name, value):
	if config.has_section_key("Player", name) or value != get_player_setting(name):
		config.set_value("Player", name, value)
		save()
	
func get_player_setting(name):
	return config.get_value("Player", name)
	
func has_player_setting(name):
	return config.has_section("Player") and config.has_section_key("Player", name)

func set_server_setting(name, value):
	if config.has_section_key("Server", name) or value != get_player_setting(name):
		config.set_value("Server", name, value)
		save()
	
func get_server_setting(name):
	return config.get_value("Server", name)
	
func has_server_setting(name):
	return config.has_section_key("Server", name)
