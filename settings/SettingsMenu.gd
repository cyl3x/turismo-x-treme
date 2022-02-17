extends Control

# TODO: 
# Add more resolutions (look at steam's HW stats)
# Bring up saved settings

const defaultRes = Vector2(1024,600)
const screenOffset = Vector2(100,100)
const onText = "ON"
const offText = "OFF"
const resolutions = {"2560x1600":Vector2(2560,1600), "2560x1440":Vector2(2560,1440), "1920x1200":Vector2(1920,1200), 
					"1920x1080":Vector2(1920,1080), "1280x800":Vector2(1280,800), "1366x768":Vector2(1366,768), 
					"1280x720":Vector2(1280,720), "1024x600":Vector2(1024,600), "640x360":Vector2(640,360)}

var base_node
var availableResolutions
var settingsGrid
var settingsMenuPanel
var resolutionButton
var fullscreenButton
var currScreen
var currScreenRes

# Audio
var masterPlayer
var fxPlayer
var masterVolumeSlider
var fxVolumeSlider
var testFxButton
var testMasterButton
var display_fps = false

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	base_node = get_node("SettingsMenuPanel/GridContainer/HControls/VControls")
	settingsGrid = get_node("SettingsMenuPanel/GridContainer")
	masterPlayer = get_node("MasterAudio")
	fxPlayer = get_node("FxAudio")
	
	settingsMenuPanel = get_node("SettingsMenuPanel")
	resolutionButton = base_node.get_node("ResolutionButton")
	fullscreenButton = base_node.get_node("FullscreenButton")
	masterVolumeSlider = base_node.get_node("MasterVolume/MasterVolumeSlider")
	fxVolumeSlider = base_node.get_node("FxVolume/FxVolumeSlider")
	testMasterButton = base_node.get_node("MasterVolume/MasterVolumePlay")
	testFxButton = base_node.get_node("FxVolume/FxVolumePlay")
	
	resolutionButton.connect("item_selected", self, "on_resolution_selected")
	fullscreenButton.connect("pressed", self, "on_fullscreen_selected")
	masterVolumeSlider.connect("value_changed", self, "on_master_volume_adjust")
	fxVolumeSlider.connect("value_changed", self, "on_fx_volume_adjust")
	testMasterButton.connect("pressed", self, "on_master_pressed")
	testFxButton.connect("pressed", self, "on_fx_pressed")
	
	setup_display()

func setup_display():
	availableResolutions = []
	currScreen = OS.get_current_screen()
	currScreenRes = OS.get_screen_size(currScreen)
	
	add_items_to_dropdown()
	fullscreen_toggle(false, defaultRes)
	resolutionButton.select(availableResolutions.find(defaultRes))
	resolutionButton.grab_focus()

#adds resolutions to dropdown
func add_items_to_dropdown():
	var highestRes = currScreenRes
	for key in resolutions.keys():
		var val = resolutions[key]
		if(highestRes.y >= val.y):
			resolutionButton.add_item(key)
			availableResolutions.append(val)
			#print("Available Resolutions : " + str(key)+' ' +str(availableResolutions[availableResolutions.size()-1]))
		
#when selecting resolution, switch to resolution
func on_resolution_selected(id):
	var targetRes = availableResolutions[id]
	if(targetRes>= currScreenRes):
		var toggle = OS.is_window_fullscreen()
		fullscreen_toggle(toggle, targetRes)
	else:
		var toggle = false
		fullscreen_toggle(toggle, targetRes)
	resolutionButton.select(id)

#toggle fullscreen
func on_fullscreen_selected():
	var toggle = !OS.is_window_fullscreen()
	var targetRes = OS.get_window_size()
	fullscreen_toggle(toggle, targetRes)

#toggles fullscreen to true/false
func fullscreen_toggle(toggleValue, targetRes):
	if(toggleValue):
		OS.set_window_maximized(toggleValue)
		OS.set_window_fullscreen(toggleValue)
	else:
		OS.set_window_maximized(toggleValue)
		OS.set_window_fullscreen(toggleValue)
		OS.set_window_size(targetRes)
		OS.set_window_position(screenOffset)
	resolutionButton.select(availableResolutions.find(currScreenRes))
	fullscreen_text_toggle()

#toggles fullscreen text on/off
func fullscreen_text_toggle():
	if(OS.is_window_fullscreen()):
		fullscreenButton.set_text(onText)
	else:
		fullscreenButton.set_text(offText)
		
func on_master_volume_adjust(value):
	if value == masterVolumeSlider.min_value:
		set_master_volume(-50)
	else:
		set_master_volume(masterVolumeSlider.get_value())
	
func on_fx_volume_adjust(value):
	if value == fxVolumeSlider.min_value:
		set_fx_volume(-50)
	else:
		set_fx_volume(fxVolumeSlider.get_value())
	
func set_master_volume(value):
	if value <= -50:
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)
	else:
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), value)
	
func set_fx_volume(value):
	if value <= -50:
		AudioServer.set_bus_mute(AudioServer.get_bus_index("fx"), true)
	else:
		AudioServer.set_bus_mute(AudioServer.get_bus_index("fx"), false)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("fx"), value)
	
func on_fx_pressed():
	if fxPlayer.playing:
		fxPlayer.stop()
	else:
		fxPlayer.play()
	
func on_master_pressed():
	if masterPlayer.playing:
		masterPlayer.stop()
	else:
		masterPlayer.play()
	
func show():
	settingsMenuPanel.popup()



func _on_CheckButton_toggled(button_pressed):
	Players.show_fps = button_pressed
