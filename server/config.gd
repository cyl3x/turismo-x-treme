extends Node

const public_config_paths = {
	"windows": "C:/Users/Public/Documents/Racing-Game",
	"X11":  "~/.config/Racing-Game",
	"OSX":  "~/Library/Application Support/Racing-Game",
	"Android":  "/data/data/org.oekel.racinggame/files",
} 
const file_name = "public_config.json"
#onready var real_path = "user://" + public_config_paths[OS.get_name()]

var config = {}

func _ready():
	#var dir = Directory.new()
	
	#dir.make_dir_recursive(real_path)
	#dir.open(real_path)
	
	#var file = File.new()
	
	#file.open(real_path + "/" + file_name, File.READ_WRITE)
	
	#if file.file_exists(real_path + "/" + file_name):
		#config = JSON.parse(file.get_as_text())
	#else:
		pass
