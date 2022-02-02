extends AudioStreamPlayer



func _ready():
	connect("Finished", self, "queue_free")
