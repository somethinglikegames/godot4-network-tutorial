class_name NetworkConnectionData

var address: String
var port: int

func _init(_address: String, _port: int) -> void:
	address = _address
	port = _port

func _to_string() -> String:
	return "%s:%d" % [address, port]
