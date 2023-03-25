extends Node

@export_range(1025, 65536) var network_port := 1911
@export_range(2, 4095) var max_clients := 2

@export var shared_secret := "JustARandomValueYouCantGuess".to_utf8_buffer() # Extract value to external config file
var _crypto = Crypto.new()
var peers = []

var jwt_algorithm: JWTAlgorithm


func _ready() -> void:
	var private_key := CryptoKey.new()
	var load_ret := private_key.load("res://crypto/jwt_rsa.key")
	if load_ret == OK:
		jwt_algorithm = JWTAlgorithm.new()
		jwt_algorithm._private_crypto = private_key
		jwt_algorithm._alg = JWTAlgorithm.Type.RSA256
	else:
		print("Error while reading RSA private key: %d" % load_ret)
		get_tree().quit(load_ret)


func startup() -> void:
	var network := ENetMultiplayerPeer.new()
	var ret := network.create_server(network_port, max_clients)
	if ret == OK:
		multiplayer.server_relay = false
		multiplayer.set_multiplayer_peer(network)
		print("Server started on port %d, allowing max %d connections"
				% [network_port, max_clients])

		multiplayer.peer_connected.connect(
			func(client_id: int) -> void:
				print("Client %d connected" % client_id)
				)
		multiplayer.peer_disconnected.connect(
			func(client_id: int) -> void:
				print("Client %d disconnected" % client_id)
				peers.erase(client_id)
				)
		multiplayer.peer_authenticating.connect(
			func(client_id: int) -> void:
				print("Client %d peer_authenticating" % client_id)
				var _hash := _crypto.hmac_digest(HashingContext.HASH_SHA256,
					shared_secret,
					Time.get_date_string_from_system(true).to_utf8_buffer())
				multiplayer.send_auth(client_id, _hash)
				)
		multiplayer.peer_authentication_failed.connect(
			func(client_id: int) -> void:
				print("Client %d peer_authentication_failed" % client_id)
				)
		multiplayer.auth_callback = \
			func(client_id: int, data: PackedByteArray) -> void:
				print("Client %d sent: %s" % [client_id, data.hex_encode()])
				var _hash := _crypto.hmac_digest(HashingContext.HASH_SHA256, shared_secret, Time.get_date_string_from_system(true).to_utf8_buffer())
				if _crypto.constant_time_compare(_hash, data):
					multiplayer.complete_auth(client_id)
					peers.append(client_id)
				else:
					print("Validation was not successful")
	else:
		print("Error while starting server: %d" % ret)
		get_tree().quit(ret)


@rpc("call_remote", "any_peer", "reliable")
func s_authenticate_player(username: String, password: String, player_id: int) -> void:
	print("authentication requested for player_id: %d" % player_id)
	var gateway_id := multiplayer.get_remote_sender_id()
	var result = username == password # add real user accounts and real check
	print("return authentication result (%s) for player_id: %d to gateway_id: %d"
			% [str(result), player_id, gateway_id])
	var token := ""
	if result:
		var now := int(Time.get_unix_time_from_system())
		token = JWT.create(jwt_algorithm) \
					.with_issued_at(now) \
					.with_expires_at(now + 30) \
					.with_claim("acc", username) \
					.sign(jwt_algorithm)
	c_authentication_result.rpc_id(gateway_id, result, player_id, token)


@rpc("call_remote", "authority", "reliable")
func c_authentication_result(_result: bool, _player_id: int, _token: String) -> void:
	pass # on gateway server
