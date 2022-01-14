@tool
extends Node


signal server_state_changed(is_listening)

signal peer_connected(id)
signal peer_disconnected(id)

signal scene_created(scene)

const PROTO = preload("res://server/engineinterface.gd")
var SCENE = load("res://scene/scene.tscn")

const PORT = 9080
var _server = WebSocketServer.new()

var global_scenes = {}
var parcel_scenes = {}

var peers = {}

var httprequests = []

var loading_screen : Control

var player : Node3D

var json

func _ready():
	json = JSON.new()
	set_process(false)

	_server.connect("client_connected", Callable(self, "_connected"))
	_server.connect("client_disconnected", Callable(self, "_disconnected"))
	_server.connect("client_close_request", Callable(self, "_close_request"))
	_server.connect("data_received", Callable(self, "_data_received"))

	if not Engine.is_editor_hint():
		start_server()


func _process(_delta):
	if _server.is_listening():
		_server.poll()


func _connected(id, _protocol, resource_name):
	print("Client connected!")

	var peer = _server.get_peer(id)
	peer.set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)
	peers[id] = peer

	emit_signal("peer_connected", id)


func _disconnected(id, _was_clean_close):
#	print("Client disconnected! was_clean_close: ", _was_clean_close)
	if id in peers:
		peers.erase(id)

	emit_signal("peer_disconnected", id)


func _close_request(_id, _code, _reason):
	pass
#	print("client close request - %d %d: %s" % [
#		_id,
#		_code,
#		"No Reason" if reason.empty() else _reason
#	])


func start_server():
	if _server.is_listening():
		push_warning("Server is already running")
		return

	var res = _server.listen(PORT)
	if res != OK:
		printerr("Failed to listen to port ", PORT)
	else:
		set_process(true)
		emit_signal("server_state_changed", true)


func stop_server():
	if not _server.is_listening():
		push_warning("Server is not currently running")
		return

	_server.stop()
	set_process(false)

	# Avoid memory leaks by freeing the nodes before clearing.
	for i in global_scenes.values() + parcel_scenes.values():
		var scene = i[0]
		# Don't free scenes that have been dumped.
		if not Engine.editor_hint or not scene.is_inside_tree():
			scene.queue_free()
			continue

		if Engine.editor_hint:
			scene.peer = null
			scene.update_configuration_warning()

			if scene.is_inside_tree():
				# Disconect connections for events, since the scene is not tied
				# with the server anymore.
				for j in scene.get_signal_connection_list("received_event"):
					scene.disconnect("received_event", j["target"], j["method"])

	global_scenes.clear()
	parcel_scenes.clear()

	# Avoid memory leaks here as well.
	for i in httprequests:
		i.queue_free()
	httprequests.clear()

	peers.clear()

	emit_signal("server_state_changed", false)


func is_listening():
	return _server.is_listening()


func create_scene(msg, peer, p_global):
	var scene = SCENE.instantiate()
	scene.set_name(msg.payload.id)

	if not Engine.is_editor_hint():
		get_tree().root.add_child(scene)
	scene.create(msg, peer, true)

	if p_global:
		global_scenes[msg.payload.id] = [scene, peer]
	else:
		parcel_scenes[msg.payload.id] = [scene, peer]

	emit_signal("scene_created", scene)


func _message(msg, peer):
	#printt("Server message ", JSON.print(msg))

	match msg.type:
		"CreateGlobalScene":
			create_scene(msg, peer, true)

		"SetLoadingScreen":
			if is_instance_valid(loading_screen):
				loading_screen.message(msg.payload)

		"LoadParcelScenes":
			create_scene(msg, peer, false)

		"SendSceneMessage":
			for buf in msg.payload:
				var scene_msg = PROTO.PB_SendSceneMessage.new()
				var err = scene_msg.from_bytes(buf)
				if err == PROTO.PB_ERR.NO_ERRORS:
					var id = scene_msg.get_sceneId()
					var scene
					if id in global_scenes:
						scene = global_scenes[id][0]
					elif id in parcel_scenes:
						scene = parcel_scenes[id][0]
					else:
						push_warning("error: unknown scene id %s for SendSceneMessage %s" % [id, scene_msg.to_string()])
						break
					scene.message(scene_msg)
				else:
	#				printt("****** Protobuf error is ", err)
					push_warning("%s error msg is %s" % [err, scene_msg.to_string()])

		"Reset":
			send({
				"type": "SystemInfoReport",
				"payload": json.stringify({
					"graphicsDeviceName":"Mocked",
					"graphicsDeviceVersion":"Mocked",
					"graphicsMemorySize":512,
					"processorType":"n/a",
					"processorCount":1,
					"systemMemorySize":256
				})
			})

		"LoadProfile":
#			send({"type": "CloseUserAvatar", "payload": JSON.print({
#				"isSignUpFlow": true
#			})})
			pass

		"ActivateRendering", "ForceActivateRendering":
			send({"type": "ControlEvent", "payload": json.stringify({"eventType":"ActivateRenderingACK"})})

		"Teleport":
			if is_instance_valid(player):
				player.position = Vector3(msg.payload.x, 0.0, msg.payload.z)

		"UnloadScene":
			parcel_scenes[msg.payload][0].queue_free()
			parcel_scenes.erase(msg.payload)

		"SetRenderProfile":
			get_tree().root.add_child(
				preload("res://3d/environments/day.tscn").instantiate()
				if msg.payload.id == 0 else
				preload("res://3d/environments/night.tscn").instantiate()
			)

		_:
			pass#printt("Unhandled message", msg.type)


func _data_received(id):
	var data = peers[id].get_packet().get_string_from_utf8() as String
	if data.left(1) in ["[", "{"]:
		var parser = JSON.new()
		var err = parser.parse(data.strip_edges().strip_escapes())
		if err != OK:
			print("error parsing json data: ", data)
			return
		var json = parser.get_data()
		if typeof(json) == TYPE_DICTIONARY \
			and "payload" in json \
			and json.payload is String:
				if json.payload.left(1) in ["[", "{"]:
					err = parser.parse(json.payload.strip_edges().strip_escapes())
					if err != OK:
						print("error parsing json data: ", json.payload)
					var payload = parser.get_data()
					json.payload = payload
					
				else:
					if not json.payload in parcel_scenes:
						var payload = []
						for line in json.payload.split("\n"):
							if !line.is_empty():
								payload.push_back(Marshalls.base64_to_raw(line))

						json.payload = payload

		_message(json, peers[id])
	else:
		print("unsupported data: ", data)


func send(msg, peer = null):
	if peers.size() == 0:
		return

	if peer == null:
		peer = peers[peers.keys()[0]]

	var txt = json.stringify(msg)
	peer.put_packet(txt.to_utf8_buffer())


func deposit_httprequest_node(http):
	add_child(http)
	httprequests.append(http)
