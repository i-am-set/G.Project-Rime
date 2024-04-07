@tool
extends Container


@export var margin = 5 :
	set(value):
		margin = value
		queue_sort()


func _ready() -> void:
	sort_children.connect(_sort_children)


func _sort_children():
	var children = []

	for child in get_children():
		if child is Control:
			children.append(child)
	
	if children.size() > 0:
		children[0].position = Vector2.ZERO
		
		var current_x : int
		var current_y: int
		var current_rects = []
		current_rects.append(children[0].get_rect())
		
		for i in range(1, children.size(), 1):
			current_x = children[i-1].position.x + children[i-1].size.x + margin
			current_y = 0
			if current_x + children[i].size.x > size.x:
				current_x = 0
				current_y += margin
			var current_rect: Rect2
			while true:
				var breakit = true
				current_rect = Rect2(current_x, current_y, children[i].size.x, children[i].size.y)
				for rect in current_rects:
					if rect.intersects(current_rect):
						current_x = rect.position.x + rect.size.x + margin
						if current_x + children[i].size.x > size.x:
							current_x = 0
							current_y += margin
						breakit = false
						break
				
				if breakit:
					break
					
			children[i].position = Vector2(current_x, current_y)
			current_rects.append(current_rect)
