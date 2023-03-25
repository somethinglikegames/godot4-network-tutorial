extends Node

var network := ENetMultiplayerPeer.new()
var gateway_server : NetworkConnectionData
var username : String
var password : String
var callback : Callable

func login_to_server(_username: String, _password: String) -> void:
	username = _username
	password = _password

	print("Connecting to %s" % gateway_server.to_string())
	var ret = network.create_client(gateway_server.address, gateway_server.port)
	if ret == OK:
		get_multiplayer().multiplayer_peer = network
		get_multiplayer().connected_to_server.connect(_on_connection_succeeded)
		get_multiplayer().connection_failed.connect(_on_connection_failed.bind(FAILED))
	else:
		_on_connection_failed(ret)


func _on_connection_failed(ret: int) -> void:
	print("Failed to connect to gateway server on %s, errorcode was %d"
			% [gateway_server.to_string(), ret])
	callback.call(ret, "")


func _on_connection_succeeded() -> void:
	print("Succesfully connected to gateway server %s" % [gateway_server.to_string()])
	print("send login request to gateway server")
	rpc_id(MultiplayerPeer.TARGET_PEER_SERVER, "s_login_request", username, password)
	s_login_request.rpc_id(MultiplayerPeer.TARGET_PEER_SERVER, username, password)
	username = ""
	password = ""


@rpc("call_remote", "any_peer", "reliable")
func s_login_request(_username: String, _password: String) -> void:
	pass # on gateway server


@rpc("call_remote", "authority", "reliable")
func c_login_response(result: bool, token: String) -> void:
	print("login response is %s" % str(result))
	print("token is '%s'" % token)
	get_multiplayer().connected_to_server.disconnect(_on_connection_succeeded)
	multiplayer.set_multiplayer_peer(null)
	network = null
	callback.call(OK if result else ERR_INVALID_DATA, token)
