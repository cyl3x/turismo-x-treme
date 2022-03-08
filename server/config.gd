extends Node

var public_config_paths = {
	"windows": ("%APPDATA%/" + ProjectSettings.get_setting("global/config_name") + "/"),
	"X11":  ("~/.config/" + ProjectSettings.get_setting("global/config_name") + "/"),
	"OSX":  ("~/Library/Application Support/" + ProjectSettings.get_setting("global/config_name") + "/"),
	"Android":  "/data/data/org.oekel.racinggame/files/",
} 
const file_name = "config.cfg"
onready var path = "user://"

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
	return config.has_section("Server") and config.has_section_key("Server", name)
