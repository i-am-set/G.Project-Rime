var map: Array
var _free_fields: int
var free_fields :
    get:
        return _free_fields
    set(new_free_fields):
        assert(false, "free_fields is read-only!")


func _init(size: Vector2i) -> void:
    resize(size)


func resize(size: Vector2i) -> void:
    map = []
    map.resize(size.x)
    for i in map.size():
        map[i] = []
        map[i].resize(size.y)
    _free_fields = size.x * size.y


func fill_rect(rect: Rect2i, value) -> void:
    assert(value != null, "Can't fill with null!")
    _fill_rect_unsafe(rect, value)


func _fill_rect_unsafe(rect: Rect2i, value) -> void:
    for x in range(rect.size.x):
        for y in range(rect.size.y):
            var map_coords := Vector2i(rect.position.x + x, rect.position.y + y)
            if !contains(map_coords):
                continue
            if map[map_coords.x][map_coords.y] != value:
                if value == null:
                    _free_fields += 1
                else:
                    _free_fields -= 1
                map[map_coords.x][map_coords.y] = value


func clear_rect(rect: Rect2i) -> void:
    _fill_rect_unsafe(rect, null)


func print() -> void:
    if map.is_empty():
        return
    var output: String
    var size = get_size()
    for j in range(size.y):
        for i in range(size.x):
            if map[i][j]:
                output = output + "x"
            else:
                output = output + "."
        output = output + "\n"
    print(output + "\n")


func clear() -> void:
    for column in map:
        column.fill(null)
    var size = get_size()
    _free_fields = size.x * size.y


func contains(position: Vector2i) -> bool:
    if map.is_empty():
        return false

    var size = get_size()
    return (position.x >= 0) && (position.y >= 0) && (position.x < size.x) && (position.y < size.y)


func get_field(position: Vector2i):
    assert(contains(position), "%s out of bounds!" % position)
    return map[position.x][position.y]


func get_size() -> Vector2i:
    if map.is_empty():
        return Vector2i.ZERO
    return Vector2i(map.size(), map[0].size())

