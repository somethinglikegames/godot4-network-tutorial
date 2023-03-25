extends Node

@export var authentication_server := "127.0.0.1"
@export_range(1025, 65536) var authentication_server_port := 1911
@export var shared_secret := "JustARandomValueYouCantGuess".to_utf8_buffer() # Extract value to external config file

var _crypto := Crypto.new()
var network := ENetMultiplayerPeer.new()
var shutdown_hook : Callable
var gateway_server : Node

func startup() -> void:
	print("Connecting to %s:%d" % [authentication_server, authentication_server_port])
	var ret = network.create_client(authentication_server, authentication_server_port)
	var _hash := _crypto.hmac_digest(HashingContext.HASH_SHA256, shared_secret, Time.get_date_string_from_system(true).to_utf8_buffer())
	if ret == OK:
		multiplayer.multiplayer_peer = network
		multiplayer.connection_failed.connect(_on_connection_failed.bind(FAILED))
		multiplayer.connected_to_server.connect(func() -> void:
			print("Succesfully connected to authentication server %s:%d"
				% [authentication_server, authentication_server_port]))
		multiplayer.peer_authenticating.connect(
			func(server_id: int) -> void:
				print("server_id %d peer_authenticating" % server_id)
				if server_id == MultiplayerPeer.TARGET_PEER_SERVER:
					multiplayer.send_auth(server_id, _hash)
				)
		multiplayer.peer_authentication_failed.connect(
			func(server_id: int) -> void:
				print("server_id %d peer_authentication_failed" % server_id)
				)
		multiplayer.auth_callback = \
			func(server_id: int, data: PackedByteArray) -> void:
				print("server %d sent %s" % [server_id, data.hex_encode()])
				if _crypto.constant_time_compare(_hash, data):
					multiplayer.complete_auth(server_id)
				else:
					print("Validation was not successful")
	else:
		_on_connection_failed(ret)


func shutdown() -> void:
	if multiplayer.multiplayer_peer != null and multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED:
		multiplayer.multiplayer_peer.close()


func _on_connection_failed(ret: int) -> void:
	print("Failed to connect to authentication server on %s:%d, errorcode was %d"
		% [authentication_server, authentication_server_port, ret])
	print("Shutting down")
	shutdown_hook.call(ret)


func authenticate_player(username: String, password: String, player_id: int) -> void:
	print("sending authentication request for player_id: %d" % player_id)
	s_authenticate_player.rpc_id(MultiplayerPeer.TARGET_PEER_SERVER,
			username, password, player_id)


@rpc("call_remote", "any_peer", "reliable")
func s_authenticate_player(_username: String, _password: String, _player_id: int)  -> void:
	pass # on authentication server


@rpc("call_remote", "authority", "reliable")
func c_authentication_result(result: bool, player_id: int, token: String) -> void:
	print("authentication result for player_id: %d is %s" % [player_id, str(result)])
	gateway_server.return_login_request(result, token, player_id)


