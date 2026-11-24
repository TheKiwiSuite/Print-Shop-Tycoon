extends RefCounted
# Drain the audio mixer before deleting player nodes. Waiting only after free()
# can strand active playback references in Godot's Dummy audio driver.
static func stop(game, tree:SceneTree) -> void:
 game.set_process(false)
 game.audio_output=false
 game.audio.stop();game.audio.stream=null
 game.music.stop();game.music.stream=null
 for player in game.sfx_players:
  player.stop();player.stream=null
 await tree.create_timer(.25).timeout
