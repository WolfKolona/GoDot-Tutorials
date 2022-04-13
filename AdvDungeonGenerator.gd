extends Node



var room = preload("res://Room.tscn")
onready var map = $TileMap

var tileSize = 32
var numRooms = 50
var minSize = 4
var maxSize = 10

var hSpread = 400

var cull = 0.5

var path

func _ready() -> void:
	randomize()
	makeRooms()

func makeRooms():
	for i in range(numRooms):
		var pos = Vector2(rand_range(-hSpread, hSpread), 0)
		var r = room.instance()
		var w = minSize + randi() % (maxSize - minSize)
		var h = minSize + randi() % (maxSize - minSize)
		r.makeRoom(pos, Vector2(w,h) * tileSize)
		$Rooms.add_child(r)
	yield(get_tree().create_timer(1.1),'timeout')
	var roomPositions = []
	for room in $Rooms.get_children():
		if randf() < cull:
			room.queue_free()
		else:
			room.mode = RigidBody2D.MODE_STATIC
			roomPositions.append(Vector2(room.position.x, room.position.y))
	yield(get_tree(), 'idle_frame')
	path = find_mst(roomPositions)

func _draw():
	for room in $Rooms.get_children():
		draw_rect(Rect2(room.position - room.size, room.size * 2), Color(240,100,0), false)
	
	if path:
		for p in path.get_points():
			for c in path.get_point_connections(p):
				var pp = path.get_point_position(p)
				var cp = path.get_point_position(c)
				draw_line(Vector2(pp.x, pp.y), Vector2(cp.x, cp.y), Color(1,1,0), 15, true)

func _process(delta: float) -> void:
	update()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_select"):
		for n in $Rooms.get_children():
			n.queue_free()
		makeRooms()
	if event.is_action_pressed("ui_focus_next"):
		makeMap()

func find_mst(nodes):
	path = AStar2D.new()
	path.add_point(path.get_available_point_id(), nodes.pop_front())
	
	while nodes:
		var minDist = INF #Minimum distance so far
		var minPos = null #Position of that node
		var p = null #Current position
		for p1 in path.get_points():
			p1 = path.get_point_position(p1)
			
			for p2 in nodes:
				if p1.distance_to(p2) < minDist:
					minDist = p1.distance_to(p2)
					minPos = p2
					p = p1
		var n = path.get_available_point_id()
		path.add_point(n,minPos)
		path.connect_points(path.get_closest_point(p), n)
		nodes.erase(minPos)
	return path

func makeMap():
	map.clear()
	
	var fullRect = Rect2()
	for room in $Rooms.get_children():
		var r = Rect2(room.position - room.size, room.get_node("CollisionShape2D").shape.extents*2)
		fullRect = fullRect.merge(r)
	var topLeft = map.world_to_map(fullRect.position)
	var bottomRight = map.world_to_map(fullRect.end)
	for x in range(topLeft.x, bottomRight.x):
		for y in range(topLeft.y, bottomRight.y):
			map.set_cell(x, y, 0)
	
	
	var corridors = []
	for room in $Rooms.get_children():
		var s = (room.size / tileSize).floor()
		var pos = map.world_to_map(room.position)
		var ul = (room.position / tileSize).floor() - s
		for x in range(2, s.x * 2 - 1):
			for y in range(2, s.y * 2 - 1):
				map.set_cell(ul.x + x, ul.y + y, 1)
		var p = path.get_closest_point(Vector2(room.position.x, room.position.y))
		
		for corri in path.get_point_connections(p):
			if not corri in corridors:
				var start = map.world_to_map(Vector2(path.get_point_position(p).x, path.get_point_position(p).y))
				var end = map.world_to_map(Vector2(path.get_point_position(corri).x, path.get_point_position(corri).y))
				carvePath(start, end)
		corridors.append(p)
	

func carvePath(pos1, pos2):
	var xDiff = sign(pos2.x - pos1.x)
	var yDiff = sign(pos2.y - pos1.y)
	if xDiff == 0 : xDiff = pow(-1.0, randi() % 2)
	if yDiff == 0 : yDiff = pow(-1.0, randi() % 2)
	var xy = pos1
	var yx = pos2
	if (randi() % 2) > 0:
		xy = pos2
		yx = pos1
	for x in range(pos1.x, pos2.x, xDiff):
		map.set_cell(x, xy.y, 1)
		map.set_cell(x, xy.y + yDiff, 1)
	for y in range(pos1.y, pos2.y, yDiff):
		map.set_cell(yx.x, y, 1)
		map.set_cell(yx.x + xDiff, y, 1)
	
	
	
