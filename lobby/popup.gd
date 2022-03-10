extends PanelContainer


func font_color_title(color : Color):
	$box/title.add_color_override("font_color", color)
	
func font_color_text(color : Color):
	$box/text.add_color_override("font_color", color)

func set_title(title : String):
	$box/title.text = title

func set_text(text : String):
	$box/text.text = text

func popup():
	self.visible = true


func _on_ok_pressed():
	self.visible = false
