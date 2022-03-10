extends GridContainer

func _ready():
	$ip.request("https://api64.ipify.org")
	$int_ip.text = Server.internal_ip()

func _on_ip_request_completed(_result, _response_code, _headers, body):
	$ext_ip.text = body.get_string_from_utf8()


func _on_Copy_xt_ip_pressed() -> void:
	OS.set_clipboard($ext_ip.text)


func _on_Copy_it_ip_pressed() -> void:
	OS.set_clipboard($int_ip.text)
