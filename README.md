# Meteor Dodge

Small arcade game made with **Godot 4** and **GDScript** as a hobby project. Dodge the falling meteors for as long as you can; they spawn faster and fall harder as time goes on.

## Controls

| Key | Action |
|-----|--------|
| ← → or A / D | Move |
| Shift | Dash (short cooldown) |
| Space / Enter | Start or restart |

## Features

- Difficulty curve based on survival time
- Dash with cooldown
- Circle vs rectangle collision written by hand
- Particle bursts and screen shake on impact
- Best score saved to disk
- Everything drawn in code with `_draw()`: no image assets

## Run it

1. Install [Godot 4](https://godotengine.org/download) (4.2 or newer).
2. Open Godot, click **Import**, and select `project.godot`.
3. Press **F5**.

## Code

All the logic is in [`main.gd`](main.gd): a small state machine (`TITLE`, `PLAYING`, `GAME_OVER`), the update loop, collisions, particles and drawing.
