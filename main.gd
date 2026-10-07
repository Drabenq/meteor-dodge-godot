extends Node2D
## Meteor Dodge: everything is drawn with _draw(), no external assets.
## Move with arrows or A/D, dash with Shift, restart with Space/Enter.

enum State { TITLE, PLAYING, GAME_OVER }

const SCREEN := Vector2(320, 180)
const GROUND_Y := 164.0
const PLAYER_SIZE := Vector2(10, 8)
const PLAYER_SPEED := 120.0
const DASH_SPEED := 340.0
const DASH_TIME := 0.12
const DASH_COOLDOWN := 0.9
const SAVE_PATH := "user://highscore.save"

const COLOR_BG := Color("#14112b")
const COLOR_GROUND := Color("#3b2f63")
const COLOR_PLAYER := Color("#7ee0c3")
const COLOR_METEOR := Color("#ff8a4c")
const COLOR_TRAIL := Color("#ffd166")
const COLOR_TEXT := Color("#f4f1ff")

var state: State = State.TITLE
var player_x := SCREEN.x / 2.0
var meteors: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var stars: Array[Vector2] = []
var spawn_timer := 0.0
var elapsed := 0.0
var score := 0
var high_score := 0
var dash_timer := 0.0
var dash_cooldown := 0.0
var dash_dir := 0.0
var shake := 0.0
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	high_score = _load_high_score()
	for i in 40:
		stars.append(Vector2(rng.randf_range(0, SCREEN.x), rng.randf_range(0, GROUND_Y)))


func _process(delta: float) -> void:
	match state:
		State.TITLE, State.GAME_OVER:
			if Input.is_action_just_pressed("ui_accept"):
				_start_game()
		State.PLAYING:
			_update_game(delta)
	_update_particles(delta)
	shake = maxf(0.0, shake - delta * 20.0)
	queue_redraw()


# --- Game flow -------------------------------------------------------------

func _start_game() -> void:
	state = State.PLAYING
	meteors.clear()
	player_x = SCREEN.x / 2.0
	elapsed = 0.0
	score = 0
	spawn_timer = 0.5
	dash_timer = 0.0
	dash_cooldown = 0.0


func _game_over() -> void:
	state = State.GAME_OVER
	shake = 6.0
	_burst(Vector2(player_x, GROUND_Y - PLAYER_SIZE.y / 2.0), COLOR_PLAYER, 24)
	if score > high_score:
		high_score = score
		_save_high_score(high_score)


## Difficulty grows with time: meteors spawn faster and fall faster.
func difficulty() -> float:
	return 1.0 + elapsed / 20.0


func _update_game(delta: float) -> void:
	elapsed += delta
	score = int(elapsed * 10.0)

	var direction := Input.get_axis("ui_left", "ui_right")
	if Input.is_key_pressed(KEY_A):
		direction = -1.0
	elif Input.is_key_pressed(KEY_D):
		direction = 1.0

	dash_cooldown = maxf(0.0, dash_cooldown - delta)
	if Input.is_key_pressed(KEY_SHIFT) and dash_cooldown == 0.0 and direction != 0.0:
		dash_timer = DASH_TIME
		dash_cooldown = DASH_COOLDOWN
		dash_dir = direction

	var speed := PLAYER_SPEED * direction
	if dash_timer > 0.0:
		dash_timer -= delta
		speed = DASH_SPEED * dash_dir
	player_x = clampf(player_x + speed * delta, PLAYER_SIZE.x / 2.0, SCREEN.x - PLAYER_SIZE.x / 2.0)

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_meteor()
		spawn_timer = maxf(0.12, 0.7 / difficulty())

	var player_rect := Rect2(Vector2(player_x - PLAYER_SIZE.x / 2.0, GROUND_Y - PLAYER_SIZE.y), PLAYER_SIZE)
	for i in range(meteors.size() - 1, -1, -1):
		var m: Dictionary = meteors[i]
		m.pos += m.vel * delta
		if circle_hits_rect(m.pos, m.radius, player_rect):
			_game_over()
			return
		if m.pos.y + m.radius >= GROUND_Y:
			_burst(Vector2(m.pos.x, GROUND_Y), COLOR_METEOR, 6)
			meteors.remove_at(i)


func _spawn_meteor() -> void:
	var radius := rng.randf_range(3.0, 7.0)
	meteors.append({
		"pos": Vector2(rng.randf_range(radius, SCREEN.x - radius), -radius),
		"vel": Vector2(rng.randf_range(-15.0, 15.0), rng.randf_range(55.0, 85.0) * difficulty()),
		"radius": radius,
	})


## Circle vs axis-aligned rectangle collision.
static func circle_hits_rect(center: Vector2, radius: float, rect: Rect2) -> bool:
	var closest := Vector2(
		clampf(center.x, rect.position.x, rect.end.x),
		clampf(center.y, rect.position.y, rect.end.y)
	)
	return center.distance_squared_to(closest) <= radius * radius


# --- Particles -------------------------------------------------------------

func _burst(origin: Vector2, color: Color, amount: int) -> void:
	for i in amount:
		var angle := rng.randf_range(PI, TAU)
		particles.append({
			"pos": origin,
			"vel": Vector2.from_angle(angle) * rng.randf_range(20.0, 70.0),
			"life": rng.randf_range(0.3, 0.7),
			"color": color,
		})


func _update_particles(delta: float) -> void:
	for i in range(particles.size() - 1, -1, -1):
		var p: Dictionary = particles[i]
		p.life -= delta
		p.vel = p.vel + Vector2(0.0, 140.0 * delta)
		p.pos += p.vel * delta
		if p.life <= 0.0:
			particles.remove_at(i)


# --- Save ------------------------------------------------------------------

func _load_high_score() -> int:
	if not FileAccess.file_exists(SAVE_PATH):
		return 0
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	return file.get_32() if file else 0


func _save_high_score(value: int) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_32(value)


# --- Drawing ---------------------------------------------------------------

func _draw() -> void:
	var offset := Vector2(rng.randf_range(-shake, shake), rng.randf_range(-shake, shake)) if shake > 0.0 else Vector2.ZERO
	draw_set_transform(offset)

	draw_rect(Rect2(Vector2.ZERO, SCREEN), COLOR_BG)
	for s in stars:
		draw_rect(Rect2(s, Vector2.ONE), Color(1, 1, 1, 0.35))
	draw_rect(Rect2(0, GROUND_Y, SCREEN.x, SCREEN.y - GROUND_Y), COLOR_GROUND)

	for m in meteors:
		var trail_end: Vector2 = m.pos - m.vel.normalized() * m.radius * 3.0
		draw_line(m.pos, trail_end, COLOR_TRAIL, maxf(1.0, m.radius * 0.8))
		draw_circle(m.pos, m.radius, COLOR_METEOR)

	if state != State.GAME_OVER:
		var body := Rect2(Vector2(player_x - PLAYER_SIZE.x / 2.0, GROUND_Y - PLAYER_SIZE.y), PLAYER_SIZE)
		draw_rect(body, COLOR_PLAYER.lightened(0.4) if dash_timer > 0.0 else COLOR_PLAYER)
		draw_rect(Rect2(body.position + Vector2(2, 2), Vector2(2, 2)), COLOR_BG)
		draw_rect(Rect2(body.position + Vector2(6, 2), Vector2(2, 2)), COLOR_BG)

	for p in particles:
		draw_rect(Rect2(p.pos, Vector2(2, 2)), p.color)

	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(6, 14), "SCORE %d" % score, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, COLOR_TEXT)
	draw_string(font, Vector2(0, 14), "BEST %d" % high_score, HORIZONTAL_ALIGNMENT_RIGHT, SCREEN.x - 6, 10, COLOR_TEXT)

	match state:
		State.TITLE:
			_centered(font, "METEOR DODGE", 70, 20)
			_centered(font, "Flechas o A/D para moverte - Shift para el dash", 92, 8)
			_centered(font, "Espacio para empezar", 108, 10)
		State.GAME_OVER:
			_centered(font, "GAME OVER", 74, 20)
			_centered(font, "Puntaje: %d" % score, 94, 10)
			_centered(font, "Espacio para reintentar", 110, 10)


func _centered(font: Font, text: String, y: float, size: int) -> void:
	draw_string(font, Vector2(0, y), text, HORIZONTAL_ALIGNMENT_CENTER, SCREEN.x, size, COLOR_TEXT)
