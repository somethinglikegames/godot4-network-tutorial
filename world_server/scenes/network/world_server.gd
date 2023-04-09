extends Node

@export_range(1025, 65536) var network_port := 1909
@export_range(2, 4095) var max_clients := 2

const dtls_key := preload("res://crypto/world_server.key")
const dtls_cert := preload("res://crypto/world_server.crt")

var jwt_algorithm: JWTAlgorithm

func _ready() -> void:
	var public_key := CryptoKey.new()
	var load_ret := public_key.load("res://crypto/jwt_rsa.pem", true)
	if load_ret == OK:
		jwt_algorithm = JWTAlgorithm.new()
		jwt_algorithm._public_crypto = public_key
		jwt_algorithm._alg = JWTAlgorithm.Type.RSA256
	else:
		print("Error while reading RSA public key: %d" % load_ret)
		get_tree().quit(load_ret)


func startup() -> void:
	var network := ENetMultiplayerPeer.new()
	var ret := network.create_server(network_port, max_clients)
	if ret == OK:
		network.host.dtls_server_setup(TLSOptions.server(dtls_key, dtls_cert))
		get_multiplayer().set_multiplayer_peer(network)
		print("Server started on port %d, allowing max %d connections"
				% [network_port, max_clients])

		network.peer_connected.connect(
			func(client_id: int) -> void:
				print("Client %d connected" % client_id)
				)
		network.peer_disconnected.connect(
			func(client_id: int) -> void:
				print("Client %d disconnected" % client_id)
				)
	else:
		print("Error while starting server: %d" % ret)
		get_tree().quit(ret)


@rpc("call_remote", "any_peer", "reliable")
func s_login_request(token: String) -> void:
	var now := int(Time.get_unix_time_from_system())
	var user_id := get_multiplayer().get_remote_sender_id()
	var jwt := JWTDecoder.new(token)
	var is_signature_valid := jwt_algorithm.verify(jwt)
	var is_unexpired = now <= jwt.get_expires_at()
	if is_signature_valid and is_unexpired:
		c_login_response.rpc_id(user_id, true)
	else:
		c_login_response.rpc_id(user_id, false)
		disconnect_player(user_id)


@rpc("call_remote", "authority", "reliable")
func c_login_response(_result: bool) -> void:
	pass # on game client


func disconnect_player(user_id: int) -> void:
	get_multiplayer().disconnect_peer(user_id)
