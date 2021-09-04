# dcl-godot-tests

Steps to run:

- install decentraland-ecs@ci and run

$ npm install decentraland-ecs@ci
$ dcl start

A browser will open on this URL:

http://192.168.0.172:8000/?SCENE_DEBUG_PANEL&position=0%2C0&realm=localhost-stub

This is running decentraland with an in-browser renderer, you will see the avatar selection scene, and later a scene with a cube

- Start the godot project in wsocktest/, this will open a websocket server on port 9080 (see server.gd)

- Reload the browser on this URL:

http://192.168.0.172:8000/?SCENE_DEBUG_PANEL&position=0%2C0&realm=localhost-stub&ws=ws://localhost:9080

- Alternative debug parameters:

http://192.168.0.172:8000/?DEBUG_MESSAGES&FORCE_SEND_MESSAGE&DEBUG_REDUX&TRACE_RENDERER=350&SCENE_DEBUG_PANEL&position=0%2C0&realm=localhost-stub&ws=ws://localhost:9080

- Press the button

Each button press will send a message from the list in scene.gd

Other documents of interest
---------------------------

https://github.com/menduz/text-renderer

https://diagrams.menduz.com/#/notebook/2l3t8FEx6Yc4GyDvkdDe4EQKf2L2/-MhVIlsuYfNVGtyiUN13

https://github.com/decentraland/unity-renderer/blob/614a2bb65abef3093049545ad1d83c64050b3e58/unity-renderer/Assets/Scripts/MainScripts/DCL/WebInterface/Interface.cs#L85

https://github.com/decentraland/kernel/blob/main/packages/shared/proto/engineinterface.proto


