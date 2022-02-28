@tool
extends Node3D


signal received_event(scene)


const COMPONENT = preload("res://interfaces/component.gd")
const EVENT = preload("res://interfaces/event.gd")
const PROTO = preload("res://server/engineinterface.gd")
const WAYPOINT = preload("res://ui/waypoint/waypoint.tscn")
const parcel_size = 16

var peer = null
var global_scene
var id

var current_index = -1
var entities = {
	"0": get_node("."),
	"AvatarEntityReference": Server.player
}
var components: Dictionary

var _raycast_queue := []

var json = JSON.new()


func create(msg, p_peer, is_global):
	id = msg.payload.id
	global_scene = is_global
	peer = p_peer

	if msg.payload.contents.size() > 0:
		ContentManager.load_contents(msg.payload)
		transform.origin = Vector3(msg.payload.basePosition.x, 0, msg.payload.basePosition.y) * parcel_size

	# TODO: this should be called after all contents are loaded
	await Server.get_tree().create_timer(2).timeout
	var response = {"eventType":"SceneReady", "payload": {"sceneId": id}}
	Server.send({"type": "ControlEvent", "payload": json.stringify(response)}, peer)


func message(scene_msg):
	#print(scene_msg.to_string())

	if scene_msg.has_createEntity():
		#print("create entity ", scene_msg.get_createEntity().get_id())
		var entity_id = scene_msg.get_createEntity().get_id()
		entities[entity_id] = Node3D.new()
		entities[entity_id].name = entity_id
		add_child(entities[entity_id])

	if scene_msg.has_removeEntity():
		pass#print("remove entity ", scene_msg.get_removeEntity().get_id())

	if scene_msg.has_setEntityParent():
#		print("setEntityParent %s -> %s" % [
#			scene_msg.get_setEntityParent().get_parentId(),
#			scene_msg.get_setEntityParent().get_entityId() ])
		reparent(
			scene_msg.get_setEntityParent().get_entityId(),
			scene_msg.get_setEntityParent().get_parentId()
		)

	if scene_msg.has_componentCreated():
		#print("component created ", scene_msg.get_componentCreated().get_name())
		var classid = scene_msg.get_componentCreated().get_classid()
		var c_id = scene_msg.get_componentCreated().get_id()
		var c_name = scene_msg.get_componentCreated().get_name()
		match classid:
			DCL_BoxShape._classid:
				components[c_id] = DCL_BoxShape.new(c_name, self, c_id)

			DCL_SphereShape._classid:
				components[c_id] = DCL_SphereShape.new(c_name, self, c_id)

			DCL_PlaneShape._classid:
				components[c_id] = DCL_PlaneShape.new(c_name, self, c_id)

			DCL_ConeShape._classid:
				components[c_id] = DCL_ConeShape.new(c_name, self, c_id)

			DCL_CylinderShape._classid:
				components[c_id] = DCL_CylinderShape.new(c_name, self, c_id)

			DCL_Material._classid:
				components[c_id] = DCL_Material.new(c_name, self, c_id)

			DCL_GLTFShape._classid:
				components[c_id] = DCL_GLTFShape.new(c_name, self, c_id)

			DCL_AudioSource._classid:
				components[c_id] = DCL_AudioSource.new(c_name, self, c_id)

			DCL_AudioClip._classid:
				components[c_id] = DCL_AudioClip.new(c_name, self, c_id)

			DCL_VideoClip._classid:
				components[c_id] = DCL_VideoClip.new(c_name, self, c_id)

			DCL_VideoTexture._classid:
				components[c_id] = DCL_VideoTexture.new(c_name, self, c_id)

			DCL_NFTShape._classid:
				components[c_id] = DCL_NFTShape.new(c_name, self, c_id)
			_:
				printt("**** Unimplemented component creation", classid)
				components[c_id] = DCL_Component.new(c_name, self, c_id)

	if scene_msg.has_componentDisposed():
		pass#print("component disposed ", scene_msg.get_componentDisposed().get_id())

	if scene_msg.has_componentRemoved():
		pass#print("component removed ", scene_msg.get_componentRemoved().get_name())

	if scene_msg.has_componentUpdated():
#		print("component updated %s -> %s" % [
#			scene_msg.get_componentUpdated().get_id(),
#			scene_msg.get_componentUpdated().get_json() ])
		components[scene_msg.get_componentUpdated().get_id()].update(
			scene_msg.get_componentUpdated().get_json()
		)

	if scene_msg.has_attachEntityComponent():
		#print("attach component to entity %s -> %s" % [
#			scene_msg.get_attachEntityComponent().get_entityId(),
#			scene_msg.get_attachEntityComponent().get_id() ])

		components[scene_msg.get_attachEntityComponent().get_id()].attach_to(
			entities[scene_msg.get_attachEntityComponent().get_entityId()]
		)

	if scene_msg.has_updateEntityComponent():

		var classid = scene_msg.get_updateEntityComponent().get_classId()
		var data = scene_msg.get_updateEntityComponent().get_data()
		var entity_id = scene_msg.get_updateEntityComponent().get_entityId()

#		print("update component in entity %s -> %s" % [
#			entity_id,
#			data ])

		# check this classid in engineinterface.proto (line 24)
		match classid:
			DCL_UUIDCallback._classid:
				DCL_UUIDCallback.update_component_in_entity(data, entities[entity_id], self)
				emit_signal("received_event", self)

			DCL_Transform._classid:
				DCL_Transform.update_component_in_entity(data, entities[entity_id], self)

			DCL_TextShape._classid:
				DCL_TextShape.update_component_in_entity(data, entities[entity_id], self)

			DCL_AnimationState._classid:
				DCL_AnimationState.update_component_in_entity(data, entities[entity_id], self)

			DCL_AudioSource._classid:
				DCL_AudioSource.update_component_in_entity(data, entities[entity_id], self)

			DCL_AudioClip._classid:
				DCL_AudioClip.update_component_in_entity(data, entities[entity_id], self)

			_:
				printt("**** Unimplemented component update", classid)

	if scene_msg.has_sceneStarted():
		pass#print("scene started ", id)

	if scene_msg.has_openNFTDialog():
		pass#print("open NFT dialog %s %s" % [
#			scene_msg.get_openNFTDialog().get_assetContractAddress(),
#			scene_msg.get_openNFTDialog().get_tokenId()
#		])

	if scene_msg.has_query():
		# if another query is added, we chould componentize this
		var query = PROTO.PB_RayQuery.new()
		if query.from_bytes(Marshalls.base64_to_raw(scene_msg.get_query().get_payload())) == PROTO.PB_ERR.NO_ERRORS:
			_raycast_queue.append(query)
		else:
			push_warning("**** queryError %s" % scene_msg.to_string())


func reparent(src, dest):
	var src_node = entities[src]
	var dest_node = entities[dest]
	src_node.get_parent().remove_child(src_node)
	dest_node.add_child(src_node)


func _get_configuration_warnings():
	var warn = PackedStringArray()
	if peer != null:
		warn.append("Scene is currently connected to a peer." +\
				"\nRemoving the DebuggerDump off the tree will completely detach this scene from it.")

	return warn

func _physics_process(delta):
	if not _raycast_queue.is_empty():
		var space_state := get_world_3d().direct_space_state
		var _raycast_parameters := PhysicsRayQueryParameters3D.new()
		_raycast_parameters.collide_with_areas = true
		_raycast_parameters.hit_from_inside = true

		while not _raycast_queue.is_empty():
			var queue = _raycast_queue.pop_front()
			var raycast = queue.get_ray()
			var origin = raycast.get_origin()
			var direction = raycast.get_direction()
			var distance = raycast.get_distance()

			_raycast_parameters.from = rayQueryVector(origin)
			_raycast_parameters.to = _raycast_parameters.from + rayQueryVector(direction) * distance

			var result : Dictionary = space_state.intersect_ray(_raycast_parameters)
			var response = {
				"sceneId": id,
				"eventType":"raycastResponse",
				"payload": {
					"queryId": queue.get_queryId(),
					"queryType": queue.get_queryType(),
					"payload": {
						"didHit": !result.is_empty(),
						"ray": {
							"origin": {
								"x": origin.get_x(),
								"y": origin.get_y(),
								"z": origin.get_z(),
							},
							"direction": {
								"x": direction.get_x(),
								"y": direction.get_y(),
								"z": direction.get_z(),
							},
							"distance": raycast.get_distance()
						},
						"hitPoint": Vector3.ZERO if result.is_empty() else result.position,
						"hitNormal":Vector3.ZERO if result.is_empty() else result.normal,
						"entities": [] if result.is_empty() else [{"entity":{ "entityId": result.collider.get_parent().get_parent().name}}]
					}
				}
			}
			Server.send({"type": "SceneEvent", "payload": json.stringify(response)})

func rayQueryVector(v) -> Vector3:
	return Vector3(v.get_x(), v.get_y(), v.get_z())
