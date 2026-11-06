extends CanvasLayer
signal play_requested
signal exploration_requested
signal park_requested(id: String)
signal search_requested(index: int)
signal story_requested(id: String)
signal race_requested(id: String)
signal dialogue_requested
signal resume_requested
signal restart_requested
signal menu_requested
signal quit_requested
var vehicle: CharacterBody3D
var mission: Node
var speed_label: Label
var mission_label: Label
var guidance_label: Label
var dialogue_label: Label
var overlay: ColorRect
var card: PanelContainer
var content: VBoxContainer
var speed_lines: Control
var splash_overlay: Control
var status_label: Label
var elapsed: float = 0.0
var base: Control
var bold: FontVariation
var card_centered: bool = true
const GOLD = Color("ffd27a")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var theme := build_theme()
	base = Control.new()
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	base.theme = theme
	add_child(base)
	# Vignettatura leggera: incornicia la guida senza coprire l'interfaccia.
	var vignette := ColorRect.new()
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vignette_material := ShaderMaterial.new()
	vignette_material.shader = load("res://assets/shaders/vignette.gdshader")
	vignette.material = vignette_material
	base.add_child(vignette)
	speed_lines = Control.new()
	speed_lines.set_script(load("res://scripts/ui/speed_lines.gd"))
	base.add_child(speed_lines)
	splash_overlay = Control.new()
	splash_overlay.set_script(load("res://scripts/ui/splash_overlay.gd"))
	base.add_child(splash_overlay)
	var top := panel(base, Vector2(48, 38), Vector2(640, 150))
	var title := label(top, "APOLLO  /  VOLPIANO" if mission.route_mode else "APOLLO  /  IL PRIMO GIRO", 22, Color("eccb82"))
	title.tooltip_text = "Esplorazione geografica" if mission.route_mode else "Circuito di prova della Fase 1"
	mission_label = label(top, "", 31)
	mission_label.add_theme_font_override("font", bold)
	guidance_label = label(top, "", 22, Color("c1dcdb"))
	var meter := panel(base, Vector2(1600, 38), Vector2(270, 150))
	speed_label = label(meter, "0 km/h", 50)
	speed_label.add_theme_font_override("font", bold)
	status_label = label(meter, "ANDIAMO CON CALMA", 17, Color("eccb82"))
	var bottom := panel(base, Vector2(48, 878), Vector2(1320, 152))
	dialogue_label = label(bottom, "Nonno: «Allacciamo le cinture e via!»", 28, Color("eccb82"))
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.custom_minimum_size.x = 1250
	label(bottom, "WASD / Frecce  guida    SPAZIO  frena    R  riposiziona    ESC  pausa", 24)
	label(bottom, "L  fari     H  clacson     C  visuale     Pag↑ / Pag↓  distanza telecamera", 21, Color("c1dcdb"))
	var pause := Button.new()
	pause.text = "Pausa  Ⅱ"
	pause.position = Vector2(1670, 948)
	pause.size = Vector2(200, 70)
	base.add_child(pause)
	pause.pressed.connect(func(): get_parent().toggle_pause())
	overlay = ColorRect.new()
	overlay.color = Color(0.035, 0.105, 0.14, 0.80)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Lo sfondo dei menu sfoca la scena; l'alfa del colore regola sfocatura e velatura.
	var backdrop := ShaderMaterial.new()
	backdrop.shader = load("res://assets/shaders/menu_backdrop.gdshader")
	overlay.material = backdrop
	base.add_child(overlay)
	card = PanelContainer.new()
	card.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	card.offset_left = -450
	card.offset_right = 450
	card.offset_top = -350
	card.offset_bottom = 350
	var card_style := style(Color(0.11, 0.24, 0.29, 0.95))
	card_style.border_color = Color(1.0, 0.82, 0.48, 0.55)
	card_style.set_border_width_all(3)
	card_style.set_corner_radius_all(30)
	card_style.shadow_size = 28
	card.add_theme_stylebox_override("panel", card_style)
	overlay.add_child(card)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 20)
	card.add_child(content)
	show_menu()

func style(color: Color = Color(0.08, 0.19, 0.24, 0.84)) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = color
	result.set_corner_radius_all(24)
	result.border_color = Color(1.0, 0.95, 0.85, 0.16)
	result.set_border_width_all(2)
	result.shadow_color = Color(0.0, 0.05, 0.08, 0.3)
	result.shadow_size = 14
	result.shadow_offset = Vector2(0, 6)
	result.anti_aliasing = true
	result.content_margin_left = 28
	result.content_margin_right = 28
	result.content_margin_top = 22
	result.content_margin_bottom = 22
	return result

## Pulsante in rilievo: bordo inferiore più scuro che si schiaccia alla pressione.
func button_box(color: Color, depth: int = 6) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = color
	result.set_corner_radius_all(18)
	result.border_color = color.darkened(0.35)
	result.border_width_bottom = depth
	result.anti_aliasing = true
	result.content_margin_left = 18
	result.content_margin_right = 18
	result.content_margin_top = 10 + (6 - depth)
	result.content_margin_bottom = 10
	result.shadow_color = Color(0, 0, 0, 0.22)
	result.shadow_size = 6
	result.shadow_offset = Vector2(0, 4)
	return result

func paint_button(target: Button, color: Color) -> void:
	target.add_theme_stylebox_override("normal", button_box(color))
	target.add_theme_stylebox_override("hover", button_box(color.lightened(0.12)))
	target.add_theme_stylebox_override("pressed", button_box(color.darkened(0.08), 2))
	target.add_theme_stylebox_override("hover_pressed", button_box(color.darkened(0.08), 2))

func build_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 25
	bold = FontVariation.new()
	bold.base_font = ThemeDB.fallback_font
	bold.variation_embolden = 0.7
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.set_corner_radius_all(20)
	focus.border_color = GOLD
	focus.set_border_width_all(4)
	focus.set_expand_margin_all(4)
	focus.anti_aliasing = true
	var teal := Color("2f8c8f")
	theme.set_stylebox("normal", "Button", button_box(teal))
	theme.set_stylebox("hover", "Button", button_box(teal.lightened(0.12)))
	theme.set_stylebox("pressed", "Button", button_box(teal.darkened(0.08), 2))
	theme.set_stylebox("hover_pressed", "Button", button_box(teal.darkened(0.08), 2))
	theme.set_stylebox("disabled", "Button", button_box(Color("5d6f73")))
	theme.set_stylebox("focus", "Button", focus)
	theme.set_font("font", "Button", bold)
	theme.set_font_size("font_size", "Button", 26)
	for key in ["font_color", "font_hover_color", "font_focus_color", "font_hover_pressed_color"]:
		theme.set_color(key, "Button", Color("fffaf0"))
	theme.set_color("font_pressed_color", "Button", Color("ffe7b0"))
	theme.set_constant("outline_size", "Button", 4)
	theme.set_color("font_outline_color", "Button", Color(0.05, 0.15, 0.18, 0.55))
	theme.set_color("font_shadow_color", "Label", Color(0.0, 0.05, 0.08, 0.45))
	theme.set_constant("shadow_offset_x", "Label", 0)
	theme.set_constant("shadow_offset_y", "Label", 2)
	var track := StyleBoxFlat.new()
	track.bg_color = Color(1, 1, 1, 0.16)
	track.set_corner_radius_all(8)
	track.content_margin_top = 6
	track.content_margin_bottom = 6
	var filled := track.duplicate() as StyleBoxFlat
	filled.bg_color = Color("f2a64a")
	theme.set_stylebox("slider", "HSlider", track)
	theme.set_stylebox("grabber_area", "HSlider", filled)
	theme.set_stylebox("grabber_area_highlight", "HSlider", filled)
	theme.set_stylebox("focus", "HSlider", focus)
	theme.set_stylebox("focus", "CheckButton", focus)
	var toggle := StyleBoxFlat.new()
	toggle.bg_color = Color(1, 1, 1, 0.07)
	toggle.set_corner_radius_all(14)
	toggle.content_margin_left = 16
	toggle.content_margin_right = 16
	toggle.content_margin_top = 6
	toggle.content_margin_bottom = 6
	var toggle_hover := toggle.duplicate() as StyleBoxFlat
	toggle_hover.bg_color = Color(1, 1, 1, 0.14)
	for state in ["normal", "pressed"]:
		theme.set_stylebox(state, "CheckButton", toggle)
	for state in ["hover", "hover_pressed"]:
		theme.set_stylebox(state, "CheckButton", toggle_hover)
	theme.set_font("font", "CheckButton", ThemeDB.fallback_font)
	theme.set_font_size("font_size", "CheckButton", 24)
	theme.set_constant("outline_size", "CheckButton", 0)
	theme.set_color("font_color", "CheckButton", Color("fff5df"))
	theme.set_color("font_hover_color", "CheckButton", Color("ffffff"))
	theme.set_color("font_focus_color", "CheckButton", Color("ffffff"))
	theme.set_color("font_pressed_color", "CheckButton", Color("fff5df"))
	theme.set_color("font_hover_pressed_color", "CheckButton", Color("ffffff"))
	return theme

func panel(parent: Control, pos: Vector2, dimensions: Vector2) -> VBoxContainer:
	var box := PanelContainer.new()
	box.position = pos
	box.size = dimensions
	box.add_theme_stylebox_override("panel", style())
	parent.add_child(box)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 6)
	box.add_child(stack)
	return stack

func label(parent: Node, text: String, size: int, color: Color = Color("fff5df")) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	parent.add_child(result)
	return result

func button(text: String, callback: Callable, target: Node = null) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size = Vector2(0, 64)
	(content if target == null else target).add_child(result)
	result.pressed.connect(func():
		if is_instance_valid(get_parent().audio):
			get_parent().audio.click()
		callback.call()
	)
	if content.get_child_count() == 4:
		result.grab_focus()
	var lower := text.to_lower()
	if lower.begins_with("menu principale") or lower == "indietro" or lower == "esci":
		paint_button(result, Color("4f6670"))
	elif (target == null and content.get_child_count() == 4) or text in ["Si parte!", "Continua", "Avanti"]:
		paint_button(result, Color("ee8a3c"))
	return result

func clear_card(title: String, subtitle: String) -> void:
	# Altezza adattata al contenuto, sempre centrata sullo schermo.
	card.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	card.grow_vertical = Control.GROW_DIRECTION_BOTH
	card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card.offset_left = -450
	card.offset_right = 450
	card.offset_top = 0
	card.offset_bottom = 0
	card_centered = true
	fit_card.call_deferred()
	overlay.color.a = 0.80
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	overlay.show()
	label(content, "UN PICCOLO VIAGGIO, UNA GRANDE AVVENTURA", 20, Color("ffd27a"))
	var heading := label(content, title, 52, Color("fffaf0"))
	heading.add_theme_font_override("font", bold)
	heading.add_theme_constant_override("outline_size", 10)
	heading.add_theme_color_override("font_outline_color", Color(0.04, 0.12, 0.16, 0.8))
	var description := label(content, subtitle, 26)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size.x = 790

func show_menu() -> void:
	var main: Node = get_parent()
	var resumable: bool = main.resume_ok
	clear_card("APOLLO", "Un viaggio con nonno e nipotina, tre stelle e un semaforo.\nPronta per una nuova avventura?")
	(content.get_child(1) as Label).add_theme_font_size_override("font_size", 56)
	if resumable:
		button("Riprendi", func(): resume_requested.emit())
	button("Ricomincia" if resumable else "Avvia gioco", func():
		if main.selected_story == "school":
			play_requested.emit()
		else:
			story_requested.emit("school")
	)
	button("Sfida con Gino", func(): race_requested.emit("level2_race"))
	button("Impostazioni", func(): show_settings(false))
	button("Esci", func(): quit_requested.emit())
	if resumable:
		(content.get_child(3) as Button).grab_focus()
	var store: RefCounted = main.save_store
	if store != null and (store.recovered or not store.last_error.is_empty()):
		label(content, "Recuperata la copia di sicurezza." if store.last_error.is_empty() else store.last_error, 20, Color("eccb82"))
	label(content, "© OpenStreetMap contributors · ODbL 1.0" if mission.route_mode else "Controller: A accelera · B retro · X frena · Y riposiziona", 20, Color("c1dcdb"))

func show_stories() -> void:
	clear_card("Le storie di Apollo", "Missione Scuola · versione racconto\nPartenza pubblica su Via Trento; sosta su Via Brandizzo.\nL'ultima parte a piedi è raccontata, non guidata.")
	button("Missione Scuola", func(): story_requested.emit("school"))
	if "school" in get_tree().get_meta("apollo_story_rewards", []):
		button("Il Parcheggio Perfetto", func(): story_requested.emit("parking"))
	else:
		label(content, "Completa il racconto per sbloccare Il Parcheggio Perfetto.", 22, Color("eccb82"))
	button("Indietro", show_menu)
	var records: Dictionary = get_parent().save_store.journey_stars
	label(content, "Record stelle · Scuola: %d / 3 · Parcheggio: %d / 3" % [records.school, records.parking], 22, Color("eccb82"))

func show_collection() -> void:
	var store: RefCounted = get_parent().save_store
	var rewards: Array = get_tree().get_meta("apollo_story_rewards", [])
	clear_card("Il nostro album", "Le stelle e le medaglie restano con Apollo anche dopo la chiusura.")
	label(content, "STELLE DEI VIAGGI", 24, Color("eccb82"))
	label(content, "Scuola: %d / 3 · Parcheggio: %d / 3" % [store.journey_stars.school, store.journey_stars.parking], 28)
	label(content, "PARCHI ESPLORATI: %d / 2" % get_parent().park_rewards().size(), 24, Color("eccb82"))
	for park in [["madonna", "Madonna delle Grazie"], ["san_grato", "San Grato"]]:
		label(content, ("★ " if park[0] in get_parent().park_rewards() else "☆ ") + park[1], 25)
	var medals := "MEDAGLIE · " + str(rewards.size()) + " / 2"
	label(content, medals, 24, Color("eccb82"))
	label(content, ("★ " if "school" in rewards else "☆ ") + "Compagni di viaggio    " + ("★ " if "parking" in rewards else "☆ ") + "Pilota gentile", 23)
	var gained: Array = store.achievements
	label(content, "TRAGUARDI · %d / 4" % gained.size(), 24, Color("eccb82"))
	label(content, ("★ " if "wallet" in gained else "☆ ") + "Portafoglio salvato    " + ("★ " if "all_money" in gained else "☆ ") + "Nemmeno un centesimo perso", 23)
	label(content, ("★ " if "beat_gino" in gained else "☆ ") + "Battuto Gino    " + ("★ " if "clean_race" in gained else "☆ ") + "Gara pulita", 23)
	button("Menu principale", show_menu)

func show_story_dialogue() -> void:
	var storyteller: Node = get_parent().dialogue
	clear_card("Sfida con Gino" if get_parent().selected_race != "" else ("Il Parcheggio Perfetto" if get_parent().selected_story == "parking" else "Missione Scuola"), storyteller.current_text)
	button("Si parte!" if get_parent().story_state == "intro" and storyteller.index == storyteller.sequence.size()-1 else "Avanti", func(): dialogue_requested.emit())
	button("Menu principale", func(): menu_requested.emit())
	label(content, "%d / %d · Leggiamo con calma" % [storyteller.index+1, storyteller.sequence.size()], 22, Color("c1dcdb"))
	park_layout()

func show_story_completed() -> void:
	var challenge: bool = get_parent().selected_story == "parking"
	clear_card("PARCHEGGIO PERFETTO!" if challenge else "MISSIONE COMPIUTA!", "Tre soste morbide, bravo pilota!" if challenge else "Grazie Apollo! Anche oggi siamo arrivati a scuola!")
	label(content, "Stelle del viaggio: %d / 3" % mission.collected_stars, 30, Color("eccb82"))
	if not challenge:
		label(content, "Soldi ritrovati: € %s su %s" % [mission.euro(mission.money_cents), mission.euro(mission.money_total_cents)], 26, Color("ffd27a"))
		label(content, "Casse sfondate: %d" % mission.smashed_crates, 22, Color("c1dcdb"))
		var result: String = mission.money_result()
		label(content, ("★ Portafoglio salvato" if result != "lose" else "☆ Portafoglio da recuperare"), 26, Color("eccb82"))
		label(content, ("★ Nemmeno un centesimo perso" if result == "win" else "☆ Nemmeno un centesimo perso"), 26, Color("eccb82"))
	label(content, "★ Pilota gentile" if challenge else "★ Compagni di viaggio", 28, Color("eccb82"))
	if not challenge:
		button("Sfida: Il Parcheggio Perfetto", func(): story_requested.emit("parking"))
	button("Un altro viaggio", func(): restart_requested.emit())
	button("Le gite nei parchi", show_parks)
	button("Menu principale", func(): menu_requested.emit())
	show_save_warning()

func show_pause() -> void:
	show_menu()

func show_parks() -> void:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/map/parks.json"))
	var count: int = get_parent().park_rewards().size()
	clear_card("Le gite di Apollo", "Scegli una gita con viaggio rapido.\nParcheggia e cerca la stella fra i giochi!\nStelle trovate: %d / %d · raccolta salvata" % [count, catalog.parks.size()])
	for park: Dictionary in catalog.parks:
		var id: String = park.id
		var found: bool = id in get_parent().park_rewards()
		button(("★  " if found else "☆  ") + str(park.name), func(): park_requested.emit(id))
	button("Indietro", show_menu)
	if count > 0:
		label(content, "★  Adesivo: Apollo Esploratore", 22, Color("eccb82"))
	label(content, "© OpenStreetMap contributors · ODbL 1.0", 18, Color("c1dcdb"))

func show_park_search(message: String = "La stella si è nascosta! Dove guardiamo? Nessuna fretta.") -> void:
	var hint: String = ["Indizio: cerca vicino alla discesa più divertente!", "Indizio: cerca dove si vola avanti e indietro!", "Indizio: cerca dove il nonno si riposa!"][get_parent().world.playground.hiding_place]
	clear_card("La Stella Perduta", message + "\n" + hint)
	button("Vicino allo scivolo", func(): search_requested.emit(0))
	button("Vicino all'altalena", func(): search_requested.emit(1))
	button("Vicino alla panchina", func(): search_requested.emit(2))
	button("Scegli un'altra gita", show_parks)
	label(content, "Apollo resta fermo fuori dal parco.", 20, Color("c1dcdb"))
	park_layout()

func show_park_reward() -> void:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/map/parks.json"))
	clear_card("UNA STELLA PER APOLLO!", "Che bella scoperta!\nAdesivo sbloccato: Apollo Esploratore\nStelle della raccolta: %d / %d" % [get_parent().park_rewards().size(), catalog.parks.size()])
	var badge := label(content, "★  APOLLO ESPLORATORE", 28, Color("f2d392"))
	var badge_style := style()
	badge_style.bg_color = Color("426c66")
	badge_style.border_color = Color("d5bc88")
	badge_style.set_border_width_all(2)
	badge.add_theme_stylebox_override("normal", badge_style)
	button("Un altro parco!", show_parks)
	button("Rigioca questa gita", func(): restart_requested.emit())
	button("Menu principale", func(): menu_requested.emit())
	park_layout()
	show_save_warning()

func show_save_warning() -> void:
	if not get_parent().save_store.last_error.is_empty():
		var warning := label(content, get_parent().save_store.last_error, 20, Color("eccb82"))
		warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

## Ricalcola l'altezza della scheda dopo il cambio di contenuto.
func fit_card() -> void:
	if not card_centered:
		return
	card.offset_top = 0
	card.offset_bottom = 0
	card.reset_size()
	card.offset_top = -card.size.y / 2.0
	card.offset_bottom = card.size.y / 2.0

## Pannello laterale: larghezza fissa a destra, altezza adattata e centrata.
func fit_side_card() -> void:
	if card_centered:
		return
	card.offset_top = 0
	card.offset_bottom = 0
	card.offset_left = -680
	card.offset_right = -30
	card.reset_size()
	card.offset_left = -30 - card.size.x
	card.offset_top = -card.size.y / 2.0
	card.offset_bottom = card.size.y / 2.0

func park_layout() -> void:
	card_centered = false
	card.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	card.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	card.offset_left = -680
	card.offset_right = -30
	card.offset_top = -340
	card.offset_bottom = 340
	overlay.color.a = 0.15
	for child in content.get_children():
		if child is Label:
			child.custom_minimum_size.x = 540
			child.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	(content.get_child(1) as Label).add_theme_font_size_override("font_size", 38)
	fit_side_card.call_deferred()

func show_race_result(player_won: bool, clean: bool = false, seconds: float = 0.0, gained: Array = []) -> void:
	var talk: String = get_parent().dialogue.current_text
	clear_card("HAI BATTUTO GINO!" if player_won else "GINO HA VINTO!", talk if talk != "" else ("Bel sorpasso, pilota!" if player_won else "Per un soffio! La rivincita è subito qui."))
	var results: Dictionary = get_parent().save_store.race_results
	label(content, "Tempo: %.1f s%s" % [seconds, ("  ·  Record: %.1f s" % results.best_time) if results.best_time > 0.0 else ""], 28, Color("eccb82"))
	label(content, "Vittorie: %d su %d gare" % [results.wins, results.races], 22, Color("c1dcdb"))
	if player_won:
		label(content, "★ Battuto Gino" + ("  ·  nuovo traguardo!" if "beat_gino" in gained else ""), 26, Color("eccb82"))
		label(content, ("★ Gara pulita" + ("  ·  nuovo traguardo!" if "clean_race" in gained else "")) if clean else "☆ Gara pulita: nessun urto e nessuna frutta addosso", 24, Color("eccb82"))
	button("Rivincita!", func(): restart_requested.emit())
	button("Menu principale", func(): menu_requested.emit())
	show_save_warning()

func show_completed() -> void:
	clear_card("ESPLORAZIONE COMPLETATA!" if mission.route_mode else "GIRO COMPLETATO!", "Bravo pilota! Apollo è pronto per la prossima avventura.\nHai superato tutte le tappe e parcheggiato con cura.")
	button("Un altro giro!", func(): restart_requested.emit())
	button("Menu principale", func(): menu_requested.emit())

func _process(delta: float) -> void:
	if not is_instance_valid(vehicle):
		return
	speed_label.text = "%d km/h" % roundi(absf(vehicle.speed) * 3.6)
	var boosting: bool = vehicle.effects.is_boosting()
	speed_lines.intensity = 1.0 if boosting else (0.3 if vehicle.effects.draft_time > 0.0 else 0.0)
	if "rival" in mission:
		var held: String = mission.items.player_item
		status_label.text = "TURBO!" if boosting else ("SCIA · RISUCCHIO" if mission.player_drafting else ("E · " + mission.items.NAMES[held] if held != "" else "SFIDA CON GINO"))
		if vehicle.effects.shield_time > 0.0 and not boosting:
			status_label.text = "GUANTI ISOLANTI"
	if "rival" in mission:
		mission_label.text = "SFIDA CON GINO  ·  %d / %d m" % [mini(roundi(mission.player_distance), roundi(mission.total_length())), roundi(mission.total_length())]
	elif mission.story_mode:
		mission_label.text = "TRE SOSTE" if get_parent().selected_story == "parking" else "MISSIONE SCUOLA"
		mission_label.text += "  ·  ★ %d / 3" % mission.collected_stars
		if not mission.challenge:
			mission_label.text += "  ·  € %s / %s" % [mission.euro(mission.money_cents), mission.euro(mission.money_total_cents)]
	elif mission.park_mode:
		mission_label.text = "GITA  ·  " + str(mission.park_name)
	else:
		mission_label.text = "VOLPIANO  ·  %d / %d" % [mission.stage + 1, mission.points.size()] if mission.route_mode else "PROVA DI GUIDA  ·  %d / 4" % mini(mission.stage + 1, 4)
	guidance_label.text = mission.instructions()
	if mission.story_mode:
		dialogue_label.text = get_parent().dialogue.current_text if is_instance_valid(get_parent().dialogue) else ""
	elif "rival" in mission:
		var talker: Node = get_parent().dialogue
		dialogue_label.text = talker.current_text if is_instance_valid(talker) and talker.bark_active() else "W accelera · E usa l'oggetto (cassetta rossa con il fulmine) · strisce azzurre = turbo · stai dietro a Gino per la scia"
	elif not get_tree().paused:
		elapsed += delta
		var lines := ["Nonno: «Allacciamo le cinture e via!»", "Nipotina: «Si parte con Apollo!»", "Nonno: «Piano piano, comandante. Ci godiamo il viaggio!»"]
		dialogue_label.text = lines[mini(int(elapsed / 7), 2)]

func show_settings(from_pause: bool = false) -> void:
	clear_card("Viaggiamo a modo tuo", "Regola audio e guida. I cambiamenti si applicano subito.")
	(content.get_child(1) as Label).add_theme_font_size_override("font_size", 42)
	var settings: Dictionary = get_parent().save_store.settings
	setting_slider("Musica", "music", 0, 1, 0.05)
	setting_slider("Effetti e motore", "effects", 0, 1, 0.05)
	setting_slider("Reattività camera", "camera", 1, 6, 0.5)
	for pair in [["gentle", "Guida tranquilla · massimo 36 km/h"], ["reduced_motion", "Movimenti ridotti · camera e giochi"], ["shadows", "Ombre del sole"], ["hq_graphics", "Grafica avanzata · luci morbide e riflessi"]]:
		var key: String = pair[0]
		var toggle := CheckButton.new()
		toggle.text = pair[1]
		toggle.custom_minimum_size.y = 44
		toggle.button_pressed = settings[key]
		content.add_child(toggle)
		toggle.toggled.connect(func(value: bool):
			settings[key] = value
			get_parent().apply_settings()
		)
	var assist_button := Button.new()
	assist_button.custom_minimum_size.y = 48
	var assist_names := ["Più aiuto", "Normale", "Sfida"]
	var refresh_assist := func():
		assist_button.text = "Aiuto in gara con Gino: " + assist_names[roundi(float(settings.race_assist) * 2.0)] + "  (clicca per cambiare)"
	refresh_assist.call()
	assist_button.pressed.connect(func():
		settings.race_assist = float((roundi(float(settings.race_assist) * 2.0) + 1) % 3) / 2.0
		refresh_assist.call()
		get_parent().apply_settings()
	)
	content.add_child(assist_button)
	button("Salva e torna", func():
		if get_parent().persist():
			if from_pause:
				show_pause()
			else:
				show_menu()
		else:
			(content.get_child(2) as Label).text = get_parent().save_store.last_error
	)
	(content.get_child(3).get_child(1) as HSlider).grab_focus()

func setting_slider(title: String, key: String, minimum: float, maximum: float, increment: float) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	content.add_child(row)
	var caption := label(row, title, 24)
	caption.custom_minimum_size.x = 260
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = increment
	slider.value = get_parent().save_store.settings[key]
	slider.custom_minimum_size = Vector2(320, 44)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.tooltip_text = title + " · usa anche le frecce o il controller"
	row.add_child(slider)
	var readout := label(row, "", 24, Color("eccb82"))
	readout.custom_minimum_size.x = 80
	var display := func(value: float): readout.text = str(snappedf(value, 0.1)) if key == "camera" else "%d%%" % roundi(value * 100)
	display.call(slider.value)
	slider.value_changed.connect(func(value: float):
		get_parent().save_store.settings[key] = value
		get_parent().apply_settings()
		display.call(value)
	)

func show_garage() -> void:
	clear_card("Il nostro Apollo", "FIAT Ducato · 2010 · X250\n2.2 MultiJet · 100 PS / 74 kW\nMotore 4HV · Euro 4\n\nPasso medio · tetto alto · L2H2\nLunghezza 5,41 m · passo 3,45 m")
	button("Vista anteriore", func(): get_parent().show_garage(0))
	button("Fianco e porta scorrevole", func(): get_parent().show_garage(1))
	button("Vista posteriore", func(): get_parent().show_garage(2))
	button("Menu principale", func(): menu_requested.emit())
	park_layout()
	label(content, "Modello 3D con materiali realistici", 20, Color("eccb82"))
	label(content, "Base: 2014 Fiat Ducato / razor24 / CC BY 4.0\nAdattamento APOLLO: X250 L2H2", 15, Color("c0c8d0"))
	button("Autore e licenza del modello", func(): OS.shell_open("https://sketchfab.com/3d-models/8a651ad182414bb0a8b6c6d8d5bd7c01"))
	set_gameplay_visible(false)

func set_gameplay_visible(value: bool) -> void:
	for child in base.get_children():
		if child != overlay and child is CanvasItem:
			child.visible = value
