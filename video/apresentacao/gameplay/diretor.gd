extends Node
# Piloto automático para gravar gameplay (só existe na cópia de gravação).
# Lê um roteiro JSON (env DIRETOR_PLANO) e executa passo a passo no _physics_process.

var passos: Array = []
var i := 0
var espera := 0.0
var segurando := {}
var log_t := 0.0
var tempo := 0.0
var soltar_no_proximo: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var caminho := OS.get_environment("DIRETOR_PLANO")
	if caminho == "":
		return
	var txt := FileAccess.get_file_as_string(caminho)
	passos = JSON.parse_string(txt)
	print("[diretor] ", passos.size(), " passos")


func jogador() -> Node2D:
	var cena := get_tree().current_scene
	if cena == null:
		return null
	var j := cena.find_child("Jogador", true, false)
	if j == null:
		var g := get_tree().get_nodes_in_group(&"player")
		if g.size() > 0:
			j = g[0]
	return j


func _evento(acao: String, apertado: bool) -> void:
	# InputEventAction passa por _input/_unhandled_input E atualiza o estado do Input.
	var ev := InputEventAction.new()
	ev.action = acao
	ev.pressed = apertado
	ev.strength = 1.0 if apertado else 0.0
	Input.parse_input_event(ev)


func _aperta(acao: String) -> void:
	_evento(acao, true)
	segurando[acao] = true


func _solta(acao: String) -> void:
	_evento(acao, false)
	segurando.erase(acao)


func _botao(texto: String) -> bool:
	for b in get_tree().root.find_children("*", "BaseButton", true, false):
		if b.is_visible_in_tree() and b is Button and (b as Button).text.strip_edges().to_upper().contains(texto.to_upper()):
			b.pressed.emit()
			return true
	return false


func _physics_process(delta: float) -> void:
	tempo += delta
	for a in soltar_no_proximo:
		_solta(a)
	soltar_no_proximo.clear()

	var j := jogador()
	log_t += delta
	if j and OS.get_environment("DIRETOR_LOG") != "" and log_t >= float(OS.get_environment("DIRETOR_LOG")):
		log_t = 0.0
		var chao: bool = j.is_on_floor() if j is CharacterBody2D else false
		print("[pos] t=%.3f x=%.0f y=%.0f chao=%s passo=%d" % [tempo, j.global_position.x, j.global_position.y, chao, i])

	if espera > 0.0:
		espera -= delta
		return

	while i < passos.size():
		var p: Dictionary = passos[i]
		var t: String = p["t"]
		match t:
			"wait":
				espera = float(p["s"])
				i += 1
				return
			"hold":
				_aperta(p["a"])
			"release":
				_solta(p["a"])
			"tap":
				_aperta(p["a"])
				soltar_no_proximo.append(p["a"])
				i += 1
				return
			"x>=":
				if j == null or j.global_position.x < float(p["v"]):
					return
			"x<=":
				if j == null or j.global_position.x > float(p["v"]):
					return
			"y>=":
				if j == null or j.global_position.y < float(p["v"]):
					return
			"y<=":
				if j == null or j.global_position.y > float(p["v"]):
					return
			"floor":
				if j == null or not (j as CharacterBody2D).is_on_floor():
					return
			"button":
				if not _botao(p["v"]):
					return
			"call":
				var alvo := get_tree().current_scene.get_node_or_null(p.get("path", "."))
				if alvo:
					alvo.callv(p["m"], p.get("args", []))
			"callon":
				var dono := get_tree().current_scene.get_node_or_null(p.get("path", "."))
				if dono:
					var obj = dono.get(p["prop"])
					obj.callv(p["m"], p.get("args", []))
			"set":
				var no := get_tree().current_scene.get_node_or_null(p["path"])
				if no:
					var v = p["v"]
					if v is Array and v.size() == 2:
						v = Vector2(v[0], v[1])
					no.set(p["prop"], v)
			"releaseall":
				for a in segurando.keys():
					_solta(a)
		i += 1
