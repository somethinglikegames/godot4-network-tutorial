extends Control

@onready var gw_server_addr_txt := $Center/Grid/GatewayServer/Server
@onready var gw_server_port_txt := $Center/Grid/GatewayServer/Port
@onready var world_server_addr_txt := $Center/Grid/WorldServer/Server
@onready var world_server_port_txt := $Center/Grid/WorldServer/Port
@onready var username_txt := $Center/Grid/Username
@onready var password_txt := $Center/Grid/Password
@onready var login_btn := $Center/Grid/Login

var login : Callable


func reset() -> void:
    login_btn.disabled = false


func _on_login_pressed() -> void:
    login_btn.disabled = true
    login.call(NetworkConnectionData.new(gw_server_addr_txt.text, gw_server_port_txt.text as int),
            NetworkConnectionData.new(world_server_addr_txt.text, world_server_port_txt.text as int),
            username_txt.text, password_txt.text)
