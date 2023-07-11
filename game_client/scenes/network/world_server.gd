extends Node

signal disconnected

var network := ENetMultiplayerPeer.new()
var peer : ENetPacketPeer = null
var world_server : NetworkConnectionData
var token : String
var callback : Callable


func login_to_server(_token: String) -> void:
	token = _token

	print("Connecting to %s" % world_server.to_string())
	var ret = network.create_client(world_server.address, world_server.port)
	if ret == OK:
		network.host.dtls_client_setup("localhost", TLSOptions.client_unsafe())
		get_multiplayer().multiplayer_peer = network
		get_multiplayer().connected_to_server.connect(_on_connection_succeeded)
		get_multiplayer().connection_failed.connect(_on_connection_failed.bind(FAILED))
		get_multiplayer().peer_disconnected.connect(func(): disconnected.emit())
	else:
		_on_connection_failed(ret)


func _on_connection_failed(ret: int) -> void:
	print("Failed to connect to world server on %s, errorcode was %d"
			% [world_server.to_string(), ret])
	callback.call(ret, "")


func _on_connection_succeeded() -> void:
	print("Succesfully connected to world server %s" % [world_server.to_string()])
	print("send login request to world server")
	s_login_request.rpc_id(MultiplayerPeer.TARGET_PEER_SERVER, token)
	token = ""


@rpc("call_remote", "any_peer", "reliable")
func s_login_request(_token: String) -> void:
	pass # on game server


@rpc("call_remote", "authority", "reliable")
func c_login_response(result: bool) -> void:
	print("login request result is %s" % str(result))
	get_multiplayer().connected_to_server.disconnect(_on_connection_succeeded)
	if result:
		peer = network.get_host().get_peers()[0]
	callback.call(OK if result else ERR_INVALID_DATA)


func get_rtt() -> float:
	if peer:
		return peer.get_statistic(ENetPacketPeer.PEER_ROUND_TRIP_TIME)
	else:
		return -1.0
