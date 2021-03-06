extends Control

# TODO: 
# Add more resolutions (look at steam's HW stats)
# Bring up saved settings

const screenOffset = Vector2(100,100)
const onText = "An"
const offText = "Aus"

var base_node
var settingsMenuPanel
var resSlider
var resLabel
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
var joystickButton

# FPS
var fpsButton
var fpsCapSlider
var fpsCapLabel

# Other
var viewDistanceSlider
var viewDistanceLabel

func _ready():
	#var _discard1 = Server.connect("game_ended", self, "on_joystick_toggle", [0])
	base_node = get_node("SettingsMenuPanel/GridContainer")
	masterPlayer = get_node("MasterAudio")
	fxPlayer = get_node("FxAudio")
	
	settingsMenuPanel = get_node("SettingsMenuPanel")
	resSlider = base_node.get_node("ResFactorSliderBox/ResFactorSlider")
	resLabel = base_node.get_node("ResFactorSliderBox/ResFactorLabel")
	fullscreenButton = base_node.get_node("FullscreenButton")
	masterVolumeSlider = base_node.get_node("MasterVolumeButton/MasterVolumeSlider")
	fxVolumeSlider = base_node.get_node("FxVolumeButton/FxVolumeSlider")
	testMasterButton = base_node.get_node("MasterVolumeButton/MasterVolumePlay")
	testFxButton = base_node.get_node("FxVolumeButton/FxVolumePlay")
	fpsButton = base_node.get_node("FPSButton")
	joystickButton = base_node.get_node("JoystickButton")
	fpsCapSlider = base_node.get_node("FPSCapBox/FPSCapSlider")
	fpsCapLabel = base_node.get_node("FPSCapBox/FPSCapLabel")
	viewDistanceSlider = base_node.get_node("ViewDistanceBox/ViewDistanceSlider")
	viewDistanceLabel = base_node.get_node("ViewDistanceBox/ViewDistanceLabel")
	
	
	joystickButton.add_item("Aus", 0)
	joystickButton.add_item("An", 1)
	joystickButton.add_item("Köpfe", 2)
	joystickButton.add_item("Gerätneigung", 3)
	
	if not OS.has_touchscreen_ui_hint():
		joystickButton.disabled = true
		on_joystick_select(0)
	else:
		joystickButton.connect("item_selected", self, "on_joystick_select")
	
	resSlider.connect("value_changed", self, "on_render_factor_changed")
	fullscreenButton.connect("pressed", self, "on_fullscreen_selected")
	masterVolumeSlider.connect("value_changed", self, "on_master_volume_adjust")
	fxVolumeSlider.connect("value_changed", self, "on_fx_volume_adjust")
	testMasterButton.connect("pressed", self, "on_master_pressed")
	testFxButton.connect("pressed", self, "on_fx_pressed")
	fpsButton.connect("toggled", self, "on_fps_toggle")
	fpsCapSlider.connect("value_changed", self, "on_fps_cap_adjust")
	viewDistanceSlider.connect("value_changed", self, "on_view_distance_adjust")
	
	var panel = get_node("SettingsMenuPanel")
	panel.rect_position = Vector2(1024 / 2 - panel.rect_size.x / 2, 600 / 2 - panel.rect_size.y / 2)
	
	_config_init()

func on_fps_cap_adjust(value):
	Config.set_setting("fps_cap", value)
	fpsCapSlider.value = value
	
	if value == 15:
		fpsCapLabel.text = " -"
		Engine.target_fps = 0
	else:
		fpsCapLabel.text = str(value)
		Engine.target_fps = value

func on_view_distance_adjust(value):
	Config.set_setting("view_distance", value)
	Players.view_distance = value
	viewDistanceSlider.value = value
	
	if value == 100:
		viewDistanceLabel.text = " -"
	else:
		viewDistanceLabel.text = "%1.1f" % (value / 100)

#when selecting resolution, switch to resolution
func on_render_factor_changed(factor):
	Config.set_setting("render_factor", factor)
	resSlider.value = factor
	
	Server.set_viewport_factor(factor)
	resLabel.text = "%1.2f" % stepify(factor, 0.01)

#toggle fullscreen
func on_fullscreen_selected():
	var toggle = !OS.is_window_fullscreen()
	var targetRes = OS.get_window_size()
	fullscreen_toggle(toggle, targetRes)
	
func on_fps_toggle(button_pressed):
	Config.set_setting("fps_display", button_pressed)
	fpsButton.pressed = button_pressed
	
	Players.show_fps = button_pressed
	
func on_joystick_select(value):
	if value == 0:
		Players.touch_controls = Players.JoystickMode.OFF
	elif value == 1:
		Players.touch_controls = Players.JoystickMode.ON
	elif value == 2:
		Players.touch_controls = Players.JoystickMode.BUTTONS
	elif value == 3:
		Players.touch_controls = Players.JoystickMode.ACCELEROMETER
	
	Config.set_setting("joystick_mode", Players.touch_controls)
	joystickButton.selected = value

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
	fullscreen_text_toggle()

#toggles fullscreen text on/off
func fullscreen_text_toggle():
	if(OS.is_window_fullscreen()):
		fullscreenButton.set_text(onText)
	else:
		fullscreenButton.set_text(offText)
		
func on_master_volume_adjust(value):
	Config.set_setting("master_volume", value)
	masterVolumeSlider.value = value
	
	if value == masterVolumeSlider.min_value:
		set_master_volume(-50)
	else:
		set_master_volume(masterVolumeSlider.get_value())
	
func on_fx_volume_adjust(value):
	Config.set_setting("fx_volume", value)
	fxVolumeSlider.value = value
	
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
	settingsMenuPanel.popup_centered()
	
func _config_init():
	if Config.has_setting("fps_cap"):
		on_fps_cap_adjust(Config.get_setting("fps_cap"))
	elif Server.IS_MOBILE:
		fullscreenButton.disabled = true
		on_fps_cap_adjust(60)
		
	if Config.has_setting("view_distance"):
		on_view_distance_adjust(Config.get_setting("view_distance"))
		
	if Config.has_setting("fps_display"):
		on_fps_toggle(Config.get_setting("fps_display"))
		
	if Config.has_setting("fx_volume"):
		on_fx_volume_adjust(Config.get_setting("fx_volume"))
		
	if Config.has_setting("master_volume"):
		on_master_volume_adjust(Config.get_setting("master_volume"))
	
	if Config.has_setting("render_factor"):
		on_render_factor_changed(Config.get_setting("render_factor"))
	
	if Config.has_setting("joystick_mode"):
		Players.touch_controls = Config.get_setting("joystick_mode")
	else:
		if !Server.IS_MOBILE: on_joystick_select(0)
		else: on_joystick_select(1)
