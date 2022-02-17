extends Control

const _max_size = 200
const _margin: float = 15.0
var font = Label.new().get_font("")
onready var curve : Curve2D
var factor: float = 1
var player_vec: Vector2 = Vector2()
var player_pos = {}
var background = StyleBoxFlat.new()
var size = Vector2()
var rotate = false

var finish_line_start = Vector2()
var finish_line_end = Vector2()

func _ready():
	if not Server.IS_STANDALONE_SERVER:
		var _discart = Players.connect("list_car_pos_updated", self, "_update_pos")
	background.corner_radius_top_right = 12
	background.bg_color = Color("#96353537")
	self.rect_position = Vector2(0,600)
	
func _process(_delta):
	update()

func _draw():
	draw_style_box(background, Rect2(Vector2(-_margin, -_margin), self.rect_size + Vector2(_margin, 0)))
	if curve != null:
		draw_polyline(curve.get_baked_points(), Color.gray, 5.0, true)
		draw_line(finish_line_start, finish_line_end, Color(0.05,0.05,0.05,1), 2.0, false)
	var player: Vector2
	for key in player_pos:
		if key == Sync.me:
			player = player_pos[key]
		else:
			var color = Color(Players.get_color(key))
			draw_circle(player_pos[key], 6.0, color.darkened(0.6))
			draw_circle(player_pos[key], 5.0, color)
	draw_circle(player, 6.0, Color.blue)
	draw_circle(player, 5.0, Color.cornflower)

func set_curve(curve2d: Curve2D, w: float, h: float):
	curve = Curve2D.new()
	
	if h > w:
		rotate = true
		var temp = h
		h = w
		w = temp
		
	factor = _max_size / w
	size = Vector2(w * factor, h * factor)
	
	var pos = Vector2(10000000, 10000000)
	var points : PoolVector2Array = PoolVector2Array()
	for point_idx in curve2d.get_point_count():
		var vec: Vector2 = curve2d.get_point_position(point_idx) * factor
		if rotate:
			vec = Vector2(-vec.y, vec.x)
		if vec.x < pos.x: pos.x = vec.x
		if vec.y < pos.y: pos.y = vec.y
		points.append(vec)
		
	for point in points:
		var vec = point - pos
		
		# mirror along vertical middle
		vec.x += (size.x / 2 - vec.x) * 2
		
		curve.add_point(vec)

	# Define finish line
	var vec = curve.get_point_position(1) - curve.get_point_position(0)
	vec = Vector2(-vec.y, vec.x).normalized()
	finish_line_start = curve.get_point_position(0) + vec * 8
	finish_line_end = curve.get_point_position(0) + vec * -8

	self.rect_size = size + Vector2(_margin * 2, _margin * 2)
	self.margin_top = -self.rect_size.y + _margin
	self.margin_left = _margin

func _update_pos():
	player_pos.clear()
	for key in Players.keys():
		player_pos[key] = curve.interpolate_baked(Players.get_map_offset(key) * factor, false)
