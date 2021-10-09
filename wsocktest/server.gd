tool
extends Node


signal server_status_updated(is_listening)

const proto = preload("res://engineinterface.gd")

const PORT = 9080
var _server = WebSocketServer.new()

var global_scenes = {}
var parcel_scenes = {}

var peers = {}

var httprequests = []

var profile_loaded = false

var loading_screen : Control

var player : Spatial

func _ready():
	set_process(false)

	_server.connect("client_connected", self, "_connected")
	_server.connect("client_disconnected", self, "_disconnected")
	_server.connect("client_close_request", self, "_close_request")
	_server.connect("data_received", self, "_data_received")

	if not Engine.editor_hint:
		start_server()


func _process(_delta):
	if _server.is_listening():
		_server.poll()


func _connected(id, _protocol):
#	print("Client connected!")

	var peer = _server.get_peer(id)
	peer.set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)
	peers[id] = peer


func _disconnected(id, _was_clean_close):
#	print("Client disconnected! was_clean_close: ", _was_clean_close)
	if id in peers:
		peers.erase(id)


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
		emit_signal("server_status_updated", true)


func stop_server():
	if not _server.is_listening():
		push_warning("Server is not currently running")
		return

	_server.stop()
	set_process(false)

	global_scenes.clear()
	parcel_scenes.clear()
	peers.clear()
	httprequests.clear()

	emit_signal("server_status_updated", false)


func is_listening():
	return _server.is_listening()


func create_scene(msg, peer, p_global):
	var scene = preload("res://scene.tscn").instance()
	scene.set_name(msg.payload.id)

	scene.create(msg, peer, true)
	if not Engine.editor_hint:
		get_tree().root.add_child(scene)

	if p_global:
		global_scenes[msg.payload.id] = [scene, peer]
	else:
		parcel_scenes[msg.payload.id] = [scene, peer]


func _message(msg, peer):
	printt("Server message ", JSON.print(msg))

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
				var scene_msg = proto.PB_SendSceneMessage.new()
				var err = scene_msg.from_bytes(buf)
				if err == proto.PB_ERR.NO_ERRORS:
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
				"payload": JSON.print({
					"graphicsDeviceName":"Mocked",
					"graphicsDeviceVersion":"Mocked",
					"graphicsMemorySize":512,
					"processorType":"n/a",
					"processorCount":1,
					"systemMemorySize":256
				})
			})

		"LoadProfile":
			if !profile_loaded:
				profile_loaded = true
				send({"type": "ControlEvent", "payload": JSON.print({"eventType":"ActivateRenderingACK"})})

		"Teleport":
			if is_instance_valid(player):
				player.translation = Vector3(msg.payload.x, 0.0, msg.payload.z)

		_:
			pass#printt("Unhandled message", msg.type)


func _data_received(id):
	var data = peers[id].get_packet().get_string_from_utf8() as String
	if data.left(1) in ["[", "{"]:
		var json = JSON.parse(data.strip_edges().strip_escapes()) as JSONParseResult
		if typeof(json.result) == TYPE_DICTIONARY \
			and "payload" in json.result \
			and json.result.payload is String:
				if json.result.payload.left(1) in ["[", "{"]:
					var payload = JSON.parse(json.result.payload.strip_edges().strip_escapes()) as JSONParseResult
					json.result.payload = payload.result
				else:
					if !json.result.payload.strip_edges().strip_escapes().empty():
						var payload = []
						for line in json.result.payload.split("\n"):
							if !line.empty():
								payload.push_back(Marshalls.base64_to_raw(line.trim_prefix("b64-")))
						json.result.payload = payload

		_message(json.result, peers[id])
	else:
		print("unsupported data: ", data)


func send(msg, peer = null):
	if peers.size() == 0:
		return

	if peer == null:
		peer = peers[peers.keys()[0]]

	var txt = JSON.print(msg)
	peer.put_packet(txt.to_utf8())


func deposit_httprequest_node(http):
	add_child(http)
	httprequests.append(http)
