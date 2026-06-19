local bootstrap = require("scripts.bootstrap")
local events = require("scripts.events")

bootstrap.register_remote_interface()
events.register()

script.on_init(bootstrap.on_init)
script.on_configuration_changed(bootstrap.on_configuration_changed)
script.on_load(bootstrap.on_load)
