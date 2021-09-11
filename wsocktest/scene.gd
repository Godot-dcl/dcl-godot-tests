extends Spatial

var socket

const proto = preload("res://engineinterface.gd")

var current_index = -1
var msgs = [
	{"type": "SystemInfoReport", "payload": JSON.print({"graphicsDeviceName":"Mocked","graphicsDeviceVersion":"Mocked","graphicsMemorySize":512,"processorType":"n/a","processorCount":1,"systemMemorySize":256}) },
	{"type": "ControlEvent", "payload": JSON.print({"eventType":"ActivateRenderingACK"})},
	#{"type":"SystemInfoReport", "payload": JSON.print({"graphicsDeviceName":"AMD Radeon Pro 5500M OpenGL Engine","graphicsDeviceVersion":"OpenGL ES 3.0 (WebGL 2.0 (OpenGL ES 3.0 Chromium))","graphicsMemorySize":512,"processorType":"n/a","processorCount":1,"systemMemorySize":256}) },
	#{"type": "AllScenesEvent", "payload": JSON.print({"eventType":"cameraModeChanged","payload":{"cameraMode":0}})},
	#{"type": "ApplySettings","payload":"{\"voiceChatVolume\":1.0,\"voiceChatAllowCategory\":0}"},
	#{"type": "SetScenesLoadRadius", "payload": JSON.print({"newRadius":4.0}) },
	#{"type": "SetBaseResolution", "payload": JSON.print({"baseResolution":1080}) },
]

func send():
	current_index = (current_index + 1) % msgs.size()
	socket.send(msgs[current_index])

func message(msg):
	#print(msg.type)
	match msg.type:
		"CreateGlobalScene":
			var response = {"eventType":"SceneReady", "payload": {"sceneId": msg.payload.id}}
			socket.send({"type": "ControlEvent", "payload": JSON.print(response)})
		"SendSceneMessage":
			for buf in msg.payload:
				var scene_msg = proto.PB_SendSceneMessage.new()
				var err = scene_msg.from_bytes(buf)
				if err == proto.PB_ERR.NO_ERRORS:
					if scene_msg.has_createEntity():
						print("create entity ", scene_msg.get_createEntity().get_id())
					
					if scene_msg.has_removeEntity():
						print("remove entity ", scene_msg.get_removeEntity().get_id())
					
					if scene_msg.has_setEntityParent():
						print("setEntityParent %s -> %s" % [
							scene_msg.get_setEntityParent().get_parentId(),
							scene_msg.get_setEntityParent().get_entityId() ])
					
					if scene_msg.has_componentCreated():
						print("component created ", scene_msg.get_componentCreated().get_name())
					
					if scene_msg.has_componentDisposed():
						print("component disposed ", scene_msg.get_componentDisposed().get_id())
					
					if scene_msg.has_componentRemoved():
						print("component removed ", scene_msg.get_componentRemoved().get_name())
					
					if scene_msg.has_componentUpdated():
						print("component updated %s -> %s" % [
							scene_msg.get_componentUpdated().get_id(),
							scene_msg.get_componentUpdated().get_json() ])
					
					if scene_msg.has_attachEntityComponent():
						print("attach component to entity %s -> %s" % [
							scene_msg.get_attachEntityComponent().get_entityId(),
							scene_msg.get_attachEntityComponent().get_name() ])
					
					if scene_msg.has_updateEntityComponent():
						print("update component in entity %s -> %s" % [
							scene_msg.get_updateEntityComponent().get_entityId(),
							scene_msg.get_updateEntityComponent().get_data() ])
					
					if scene_msg.has_sceneStarted():
						print("scene started")
					
					if scene_msg.has_openNFTDialog():
						print("open NFT dialog %s %s" % [
							scene_msg.get_openNFTDialog().get_assetContractAddress(),
							scene_msg.get_openNFTDialog().get_tokenId()
						])
					
					if scene_msg.has_query():
						print("query ", scene_msg.get_query().get_payload())
				else:
					printt("error is ", err)
					printt("msg is ", scene_msg.to_string())
		"LoadParcelScenes":
			var response = {"eventType":"SceneReady", "payload": {"sceneId": msg.payload.id}}
			socket.send({"type": "ControlEvent", "payload": JSON.print(response)})
		"LoadProfile":
			print("LoadProfile ", msg.payload.name)

func _ready():
	socket = get_node("socket")
	get_node("button").connect("pressed", self, "send")
