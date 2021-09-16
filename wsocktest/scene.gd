extends Spatial

const proto = preload("res://engineinterface.gd")

var peer = null
var global_scene
var id

var current_index = -1

func create(msg, p_peer, is_global):
	id = msg.payload.id
	global_scene = is_global
	
	peer = p_peer

	var response = {"eventType":"SceneReady", "payload": {"sceneId": msg.payload.id}}
	Server.send({"type": "ControlEvent", "payload": JSON.print(response)}, peer)
	print("scene ready! ", msg.payload.id)

func message(scene_msg):
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
		print("scene started ", id)
	
	if scene_msg.has_openNFTDialog():
		print("open NFT dialog %s %s" % [
			scene_msg.get_openNFTDialog().get_assetContractAddress(),
			scene_msg.get_openNFTDialog().get_tokenId()
		])
	
	if scene_msg.has_query():
		print("query ", scene_msg.get_query().get_payload())

func _ready():
	pass
