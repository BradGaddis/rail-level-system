@tool
extends EditorPlugin

const PLUGINNAME = "rail-level-system"

var DEPENDENT_PLUGINS: Array =\
# The order does matter
[
	SaveAndLoadPlugin, 
	MusicHandlerPlugin
]


func _enable_plugin() -> void:
	for plugin in DEPENDENT_PLUGINS:
		if !Engine.has_singleton(plugin.PLUGINNAME):
			return
		var path = PLUGINNAME + "/" + plugin.PLUGINNAME + "/"
		if !EditorInterface.is_plugin_enabled(path):
			EditorInterface.set_plugin_enabled(path, true)


func _disable_plugin() -> void:
	for plugin in DEPENDENT_PLUGINS:
		if !Engine.has_singleton(plugin.PLUGINNAME):
				return
		var path = PLUGINNAME + "/" + plugin.PLUGINNAME + "/"
		if EditorInterface.is_plugin_enabled(path):
			EditorInterface.set_plugin_enabled(path, false)
