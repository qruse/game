extends Node
## 배경음악 (docs/08-music.md 6절). 곡 하나를 반복하고, 바뀔 때 1초 크로스페이드
## 쓰는 법: Music.play("res://audio/bgm_title.ogg") / Music.stop()

const FADE := 1.0
const VOLUME_DB := -6.0

var _cur: AudioStreamPlayer
var _path := ""


func play(path: String) -> void:
	if path == _path:
		return
	_fade_out()
	_path = path
	var s = load(path)
	if s == null:
		return
	if s is AudioStreamOggVorbis:
		s.loop = true
	_cur = AudioStreamPlayer.new()
	_cur.stream = s
	_cur.volume_db = -40.0
	add_child(_cur)
	_cur.play()
	create_tween().tween_property(_cur, "volume_db", VOLUME_DB, FADE)


func stop() -> void:
	_fade_out()
	_path = ""


func _fade_out() -> void:
	if _cur == null:
		return
	var old := _cur
	_cur = null
	var tw := create_tween()
	tw.tween_property(old, "volume_db", -40.0, FADE)
	tw.tween_callback(old.queue_free)
