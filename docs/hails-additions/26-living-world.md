# 26: Living world: NPC skaters, pedestrians and traffic

Branch: `world/living-world` (built on all the audio work, #32, which it publishes sounds into). One upstream PR
for all of it (user, 2026-10-04: "this work shall be one PR"; traffic added the same day: "add this to the living
world work"). Details: [`living-world/`](living-world/) (designs and the data formats of milestone 1).

This doc is split into the files below so each topic can be read on its own. Every section keeps its heading, so
an old link `26-living-world.md#<section>` becomes `<file>#<section>` with the same anchor. New sections go into
the file of their topic (and get a line here).

| File | Topic | Contains |
|---|---|---|
| `living_world` | `npc_draw_distance` (1.0, 0.25..4), `skater_fade {fade_in_seconds 1, fade_seconds 1, despawn_alpha 0.2}`, `ped_fade {distance {45, 55}, fade_in_seconds 1, enabled true}` (a model record's own pair still wins), `skater_clips {[phase or phase.Style] = clip}` (empty = shipped picks), `skater_clips["trick.<scorable name>"] = trick animation base` (empty = Tricks.xml picks), `skater_blend_seconds {[phase or default or trick_takeoff or trick_air] = s}` (empty = 0.2 s; tricks 0.05 / 0.1 s), `skater_stance {[record id hex or record name] = regular or goofy}` (empty = the measured retail table; unknown records goofy; read at spawn), `skater_line_chain {radius 4, max_candidates 16, blend_seconds 0.2, keep_facing false}` (line end chaining; root blend onto the new line after a branch or chain, 0 = cut; keep_facing: fix 16 facing carry-over, mod option, not retail), `ped_obstacles {enabled true, min_half_extent 0.2, moving_speed 0.4, recut_fraction 0.25, detour_margin 0.1, step_height 0}` (props and mod bodies as ped obstacles), `npc_skater_props {enabled true}` (NPC skaters push dynamic props), `ped_vehicle_contact {enabled true, push true}` (traffic cars push peds out of the way; no knock-down in retail) | `LivingWorldSettings`, rebuilt via `reset_mod_overrides()` so the player's menu draw distance returns |
| `living_world` | `npc_draw_distance` (1.0, 0.25..4), `skater_fade {fade_in_seconds 1, fade_seconds 1, despawn_alpha 0.2}`, `ped_fade {distance {45, 55}, fade_in_seconds 1, enabled true}` (a model record's own pair still wins), `skater_clips {[phase or phase.Style] = clip}` (empty = shipped picks), `skater_clips["trick.<scorable name>"] = trick animation base` (empty = Tricks.xml picks), `skater_blend_seconds {[phase or default or trick_takeoff or trick_air] = s}` (empty = 0.2 s; tricks 0.05 / 0.1 s), `skater_line_chain {radius 4, max_candidates 16, blend_seconds 0.2, keep_facing false}` (line end chaining; root blend onto the new line after a branch or chain, 0 = cut; keep_facing: fix 16 facing carry-over, mod option, not retail), `ped_obstacles {enabled true, min_half_extent 0.2, moving_speed 0.4, recut_fraction 0.25, detour_margin 0.1, step_height 0, held_is_obstacle true, moving_solid true}` (props and mod bodies as ped obstacles; a held prop stays one, retail; `moving_solid` is the NOT RETAIL YET stand-in for the NavPower moving avoider), `npc_skater_props {enabled true}` (NPC skaters push dynamic props), `ped_vehicle_contact {enabled true, push true}` (traffic cars push peds out of the way; no knock-down in retail) | `LivingWorldSettings`, rebuilt via `reset_mod_overrides()` so the player's menu draw distance returns |
| `living_world` | `npc_draw_distance` (1.0, 0.25..4), `skater_fade {fade_in_seconds 1, fade_seconds 1, despawn_alpha 0.2}`, `ped_fade {distance {45, 55}, fade_in_seconds 1, enabled true}` (a model record's own pair still wins), `skater_clips {[phase or phase.Style] = clip}` (empty = shipped picks), `skater_clips["trick.<scorable name>"] = trick animation base` (empty = Tricks.xml picks), `skater_blend_seconds {[phase or default or trick_takeoff or trick_air] = s}` (empty = 0.2 s; tricks 0.05 / 0.1 s), `skater_stance {[record id hex or record name] = regular or goofy}` (empty = the measured retail table; unknown records goofy; read at spawn), `skater_line_chain {radius 4, max_candidates 16, blend_seconds 0.2, keep_facing false}` (line end chaining; root blend onto the new line after a branch or chain, 0 = cut; keep_facing: fix 16 facing carry-over, mod option, not retail), `ped_obstacles {enabled true, min_half_extent 0.2, moving_speed 0.4, recut_fraction 0.25, detour_margin 0.1, step_height 0, held_is_obstacle true, moving_solid true}` (props and mod bodies as ped obstacles; a held prop stays one, retail; `moving_solid` is the NOT RETAIL YET stand-in for the NavPower moving avoider), `npc_skater_props {enabled true}` (NPC skaters push dynamic props), `ped_vehicle_contact {enabled true, push true}` (traffic cars push peds out of the way; no knock-down in retail), `npc_tricks {mode profile, gate_window 300, min_air_frames 50}` (NPC ollie / flip slots re-picked from the profile, or `recorded` / `none`), `skater_trick_profiles {[character key or profile name] = {regular, nollie}}` (empty = the disc's tables) | `LivingWorldSettings`, rebuilt via `reset_mod_overrides()` so the player's menu draw distance returns |
| `living_world` | `npc_draw_distance` (1.0, 0.25..4), `skater_fade {fade_in_seconds 1, fade_seconds 1, despawn_alpha 0.2}`, `ped_fade {distance {45, 55}, fade_in_seconds 1, enabled true}` (a model record's own pair still wins), `skater_clips {[phase or phase.Style] = clip}` (empty = shipped picks), `skater_clips["trick.<scorable name>"] = trick animation base` (empty = Tricks.xml picks), `skater_blend_seconds {[phase or default or trick_takeoff or trick_air] = s}` (empty = 0.2 s; tricks 0.05 / 0.1 s), `skater_stance {[record id hex or record name] = regular or goofy}` (empty = the measured retail table; unknown records goofy; read at spawn), `skater_line_chain {radius 4, max_candidates 16, blend_seconds 0.2, keep_facing false}` (line end chaining; root blend onto the new line after a branch or chain, 0 = cut; keep_facing: fix 16 facing carry-over, mod option, not retail), `ped_obstacles {enabled true, min_half_extent 0.2, moving_speed 0.4, recut_fraction 0.25, detour_margin 0.1, step_height 0, held_is_obstacle true, moving_solid true}` (props and mod bodies as ped obstacles; a held prop stays one, retail; `moving_solid` is the NOT RETAIL YET stand-in for the NavPower moving avoider), `npc_skater_props {enabled true}` (NPC skaters push dynamic props), `ped_vehicle_contact {enabled true, push true}` (traffic cars push peds out of the way; no knock-down in retail), `npc_tricks {mode profile, gate_window 300, min_air_frames 50}` (NPC ollie / flip slots re-picked from the profile, or `recorded` / `none`), `skater_trick_profiles {[character key or profile name] = {regular, nollie}}` (empty = the disc's tables), `npc_simulated {enabled false, radius 40, max 3}`, `skaters` / `pedestrians` / `vehicles {enabled true, density 1}` (0..4, scales the census caps), `ambient_skaters 3` (0..8), `free_play {traffic, pedestrians, ai_skaters}` (absent = career free roam; retail Free Play: 0..1, 0 removes them at once) | `LivingWorldSettings`, rebuilt via `reset_mod_overrides()` so the player's menu draw distance returns |
| `props` | `default` / `by_template[<MOBJ template>]`: every `PropTuning` field plus `collision_box {center, half_extents}`; a template entry starts from the patched default | `PropTuningSettings` |
| `carry` | `grab_bit` (28, RB), `placement_bit` (20, B), `grab_range` (2.0 m); Move Object: `push_speed` / `pull_speed` / `side_speed` (3.0 / 2.0 / 2.5), `turn_rate`, `grip_reach`, `linear_clamp` (20), `yaw_clamp` (6), `relatch` (0.1), `slew_per_tick` (4), `linear_controller` / `yaw_controller` ([20, 0, 40, 0.1]), the four curves, `let_go_distance` (1.0); slot 9 application: `commanded_material` ([0.03, 0.02] static / dynamic friction), `upright_cos` (0.65), `apply_at_com`, `yaw_replaces_torque`, `ignore_vertical`, `wake_on_command` (true), `by_template[<MOBJ template>] = {material_held, material_free, material_free_upright, upright_pair, restitution}` | `CarrySettings`, pushed into `PropCarry` and `PropDynamics` each tick (survives map loads) |

Events (`on_event {name = "living_world", event = ...}`, `modding::living_world_events`): `spawn` / `despawn` with the
serialisable record a future host sends (`WireRecord`: kind, stable id, tick, position, heading, seed, choice /
reason), `npc_trick` (id, line, node, recorded, chosen), `npc_line_end` (id) and `vehicle_contact` (the
`VehicleContactEvent`). Tests: `living_world_messages_become_mod_events`,
`living_world_density_counts_and_free_play_set_merge_and_reset` (merge, the values reach the population config,
invalid values rejected, reset), skate-mods validation cases.

Not exposed yet: road district selection for mod maps (the loader picks the district by map name), census range
overrides (`data_config`), spawn tables, models per kind, routes, behaviour overrides. The ped mirrored-animation fix has no values.

## Credits

skate3recomp by @mchughalex (rexglue SDK, Xenia), the reference for how the retail code is used; DumbadsSkate3ModdingTools by Ethanw05 (credits to SunJay,
Dumbad, RenderWareGavin and Tuukkas) for the AIPATH field names, NavPower constants and trigger types, used as a
format reference, no code copied; @andrewnakas' `mx/vehicle` fork as prior work on a (player-driven) vehicle Lua API,
described, not copied.

## Open questions

- Props look (D9, ported 2026-10-08, to playtest): the props' `dynamicobject.default` / `dynamicobject.alphatest`
  materials now render with their own family 15, a port of `dynamicobject_defaultPS` (sun N.L with the dynamic
  shadow, `m_params` ambient, tangent-space specular, detail normal). Needs a setup refresh (environment step) for the
  `m_params` rows; without them the old family 1 fallback and log line remain. Open: retail's static world shadow map
  (`shadowWorld`) has no engine pass yet, so props in building shade stay sunlit. Details: doc 27, "D9".
- Population core (milestone 2): retail reads the census count once per spawn pass (`r23` in `sub_826B9940`), so
  during the initial populate the cap would not bind and only the factory (pool 31) would; the recomp sessions show
  at most 15 peds in 15-cap areas, so we re-read the count per spawn (identical outside the initial populate). Also
  open: the vehicle pool size; the character pool's release rule (`sub_8245B400`; we release the oldest unused
  entry that fits no nearby line, and load at once instead of streaming); the line / profile capability bits
  (profile `+144..+146` unnamed; fit = allowed-skater bit or a matching flag bit); the per-skater stuck despawn
  (`skater+1804` vfunc 76 < 0.2) and the requested-character queue; mode 2 (45 m / 20 m cull, 4-30 m ring); the
  forward offset uses the horizontal velocity direction; spawn points are not snapped to the nav mesh / ground yet.
- Teammate looks at runtime: what writes the binding (recruit menu, save importer or mod).
- AIPATH: branch weight meaning, node flag bit 4, orientation order, `m_ID` bytes 6 to 15; the 38 `ai_skater`
  tunables.
- Roads: decoded in V0 except the meaning of a few raw fields (junction `flag_04`, connector `f32_50`, segment
  `word_56`, quad tags); crosswalks for peds (navigation milestone); NavPower; DMO plugin anchors (benches, ATMs,
  fountains are placed objects, not waypoint streams).
- Ped rig: the converted models carry 39 bones, the animation bank 50; matched by name in the ped-body milestone.
- How retail picks among shared-look entities (`sub_826B8B88`).
- Traffic: lane snapping at spawn, the census +144 reader, which of the 4 signal controllers and which light group
  each junction approach uses (V1), the chassis / secondary tint rule of the `vehicle_chassis` shader (V3), the skid
  flag writer, the skitch grab / attach / release numbers, the vehicle bail thresholds.
  New recomp hooks (skitch, lights, connectors, vehicle bails) and a few short play sessions will measure them.

### Peds floating in the air all over the map (2026-10-06)

User: "There were MANY floating peds during my last play session. Not on geometry that is visible, literally floating int he air." / "IT IS NOT JUST ON PROPS GOD DAMNIT, IT IS ALL OVER THE PLACE".

- **Cause:** the ped render height (fix 17) took the first hit of a line from one NavPower agent height (1.6 m) above the navmesh down to 1.6 m below. Any collision within 1.6 m overhead (awnings, ledges, signs, invisible collision) won, so the ped was drawn standing on it. Video 2026-10-06 10-00-44 at 49 s and 51 s.
- **Change:** the upward search is the NavPower step height (agent block [2], 0.2 m [data]); NavPower keeps its polygons within one step of the walkable floor. Downward stays one agent height. Not retail yet: retail's own ped render placement is not decoded.
- **Evidence:** data test `ped_render_ground_does_not_lift_onto_overhead_geometry` over all 36,443 DownTown polygon centres: drawn more than 0.3 m above the navmesh at 195 polygons before, 0 after.
- **Files:** `crates/skate-game/src/living_world/peds.rs` (`ground(up, down)`), `peds_tests.rs`.
- **Logging (always on):** `PED_FLOATING` (warn, every 2 s per ped, once per ped per 10 s) when a ped is drawn more than 0.3 m above the floor under it or over no floor: ped, model, drawn position, navmesh height, floor height, gap, polygon and area code. The ped readout (count, nearest ped, player position) now runs every 2.5 s without debug mode. User: "im tired of you saying you can't see the floating pedestrains". A data check found 167 walkable DownTown polygons (areas 17 and 161) more than 1.6 m above the collision floor or over none; the log names them when a ped walks there.
- **Peds spawned at the player's height (2026-10-06):** the logs showed nearly every floating ped had no navmesh polygon (32 of 34, then 44 of 44). The census ring point carries the observer's height (`census::ring_point`); where the navmesh has no floor within `locate_height` (4 m) of it, the ped kept that height and hung in the air or under the ground. With a navmesh, such a spawn is now released like an unresolved look and the census tries another point next pass. Not retail yet: retail's spawn validation is not decoded. Session after the fix (about 6.5 minutes): 0 `PED_FLOATING`, the ped count stayed at its cap (14 to 15).
| [26a](26a-living-world-overview.md) | Overview, plan and modding | Start here. The problem, what retail does (census, lines, peds, traffic), the milestone plan inside the one PR, the mod surface (`sdk.world.set_tuning` domains, `living_world` events), verification, credits and the open questions. |
| [26b](26b-living-world-population.md) | Data and the population core | Milestone 1 (the `livingworld` setup group, AIPATH lines, tables, census grids, ped / prop GLBs) and milestone 2 (`skate-core::living_world`, `LivingWorldPlugin`), plus the population fixes: NPCs vanishing in view, the NPC draw distance option, the startup freeze, the census following the board, and the hidden-board frame drop. |
| [26c](26c-living-world-npc-skaters.md) | NPC skaters: replay tier and animation | Milestone 3 (NPC skaters replaying recorded lines) and the fixes to how they look and sound: fading at line ends, animation snapping and popping, jitter, switching sides, and silent landings from the voice cap. |
| [26d](26d-living-world-skater-stance.md) | NPC skaters: stance and riding direction | Riding backwards (fix 23) and its correction, then the retail stance ports: fakie drawing, natural stance, trick-clip stance toggles, and the turn rate / pro stance / off-board steer research. The largest single topic. |
| [26e](26e-living-world-skater-ai.md) | NPC skaters: AI and simulated tier | The M5 ports (AI board path steering, trick choice) and M7 steps 1 to 3: per-skater physics context, the AI record driving the physics, and simulated NPC skaters in the game. |
| [26f](26f-living-world-peds.md) | Pedestrians: body, navigation and look | Peds milestones M2 (the ped body) and M3 (navigation), plus the fixes to how peds stand and render: upside down in left turns, warped bone frames, walking in place, clothes in mask colours, and peds floating in the air (the render height search). |
| [26g](26g-living-world-ped-interactions.md) | Pedestrians: props and skater contact | Peds (and NPC skaters, fix 19) walking through props, peds walking through a held prop, and the skater knocking peds down or making them stumble. |
| [26h](26h-living-world-traffic.md) | Traffic | Milestones V0 to V3 (vehicle data, road graph / lane cursor / signals / junction entry, the vehicle census, cars on screen) and the fixes: cars flying off, car shadows from bridges, and the retail reaction when cars hit peds. |
| [26i](26i-living-world-props.md) | Props | Dynamic props and the held / moved prop: props pulled toward the player, moving a held prop (stick directions, skater inside the prop, grab flicker), the board stuck inside a prop, dragged props sinking, and the Move Object port. The dynamic props themselves (movable DMOs from upstream PR #15) are doc 27. |

## Sections per file

### 26a: Overview, plan and modding

- [Problem](26a-living-world-overview.md#problem)
- [What retail does](26a-living-world-overview.md#what-retail-does)
- [Verification](26a-living-world-overview.md#verification)
- [Plan (milestones inside the one PR)](26a-living-world-overview.md#plan-milestones-inside-the-one-pr)
- [Modding](26a-living-world-overview.md#modding)
- [Credits](26a-living-world-overview.md#credits)
- [Open questions](26a-living-world-overview.md#open-questions)

### 26b: Data and the population core

- [Change (milestone 1: data)](26b-living-world-population.md#change-milestone-1-data)
- [Change (milestone 2: population core)](26b-living-world-population.md#change-milestone-2-population-core)
- [NPCs vanishing in view (leave fade, census centre), 2026-10-05](26b-living-world-population.md#npcs-vanishing-in-view-leave-fade-census-centre-2026-10-05)
- [NPC draw distance (QoL, not retail)](26b-living-world-population.md#npc-draw-distance-qol-not-retail)
- [Startup freeze from the first-play fixes, 2026-10-05](26b-living-world-population.md#startup-freeze-from-the-first-play-fixes-2026-10-05)
- [Population follows the board, not the player, 2026-10-05](26b-living-world-population.md#population-follows-the-board-not-the-player-2026-10-05)
- [Frame drop with the board thrown away (hidden board scanned the whole map), 2026-10-05](26b-living-world-population.md#frame-drop-with-the-board-thrown-away-hidden-board-scanned-the-whole-map-2026-10-05)

### 26c: NPC skaters: replay tier and animation

- [Change (milestone 3: NPC skaters, replay tier)](26c-living-world-npc-skaters.md#change-milestone-3-npc-skaters-replay-tier)
- [NPC skaters fading out near the player (line end), 2026-10-05](26c-living-world-npc-skaters.md#npc-skaters-fading-out-near-the-player-line-end-2026-10-05)
- [NPC skaters snapping between animations, 2026-10-05](26c-living-world-npc-skaters.md#npc-skaters-snapping-between-animations-2026-10-05)
- [NPC skaters jittery while skating, 2026-10-05](26c-living-world-npc-skaters.md#npc-skaters-jittery-while-skating-2026-10-05)
- [NPC skaters switching the side they stand on, 2026-10-05](26c-living-world-npc-skaters.md#npc-skaters-switching-the-side-they-stand-on-2026-10-05)
- [NPC skaters popping between animations, tricks not playing, 2026-10-05](26c-living-world-npc-skaters.md#npc-skaters-popping-between-animations-tricks-not-playing-2026-10-05)
- [Silent landings (NPC skater sounds filled the voice cap), 2026-10-07](26c-living-world-npc-skaters.md#silent-landings-npc-skater-sounds-filled-the-voice-cap-2026-10-07)

### 26d: NPC skaters: stance and riding direction

- [NPC skaters riding backwards (fix 23), 2026-10-08](26d-living-world-skater-stance.md#npc-skaters-riding-backwards-fix-23-2026-10-08)
  - [Fix 23 corrected (2026-10-08)](26d-living-world-skater-stance.md#fix-23-corrected-2026-10-08)
  - [NPC skater fakie drawing (stance port, 2026-10-08)](26d-living-world-skater-stance.md#npc-skater-fakie-drawing-stance-port-2026-10-08)
  - [NPC skater turn rate, pro stance and off-board steer (research, 2026-10-08)](26d-living-world-skater-stance.md#npc-skater-turn-rate-pro-stance-and-off-board-steer-research-2026-10-08)
  - [NPC skater natural stance (port, 2026-10-08)](26d-living-world-skater-stance.md#npc-skater-natural-stance-port-2026-10-08)
  - [NPC skater trick-clip stance toggles (port, 2026-10-08)](26d-living-world-skater-stance.md#npc-skater-trick-clip-stance-toggles-port-2026-10-08)

### 26e: NPC skaters: AI and simulated tier

- [NPC skater steering: the AI board path (M5 port, 2026-10-08)](26e-living-world-skater-ai.md#npc-skater-steering-the-ai-board-path-m5-port-2026-10-08)
- [NPC skater trick choice (M5 port, 2026-10-08)](26e-living-world-skater-ai.md#npc-skater-trick-choice-m5-port-2026-10-08)
- [Simulated NPC skaters: per-skater physics context (M7 step 1, 2026-10-08)](26e-living-world-skater-ai.md#simulated-npc-skaters-per-skater-physics-context-m7-step-1-2026-10-08)
- [Simulated NPC skaters: the AI record drives the physics (M7 step 2, 2026-10-08)](26e-living-world-skater-ai.md#simulated-npc-skaters-the-ai-record-drives-the-physics-m7-step-2-2026-10-08)
- [Simulated NPC skaters in the game (M7 step 3, 2026-10-08)](26e-living-world-skater-ai.md#simulated-npc-skaters-in-the-game-m7-step-3-2026-10-08)
- [NPC skater obstacle avoider (M5 port, 2026-10-09)](26e-living-world-skater-ai.md#npc-skater-obstacle-avoider-m5-port-2026-10-09)
- [NPC skater proxies in retail's collision groups (2026-10-09)](26e-living-world-skater-ai.md#npc-skater-proxies-in-retails-collision-groups-2026-10-09)
- [Simulated NPC skaters bail and respawn (M7, 2026-10-09)](26e-living-world-skater-ai.md#simulated-npc-skaters-bail-and-respawn-m7-2026-10-09)
- [Simulated NPC skaters do their recorded jumps and tricks (M7, 2026-10-09)](26e-living-world-skater-ai.md#simulated-npc-skaters-do-their-recorded-jumps-and-tricks-m7-2026-10-09)

### 26f: Pedestrians: body, navigation and look

- [Change: peds milestone M2, the ped body](26f-living-world-peds.md#change-peds-milestone-m2-the-ped-body)
- [Change: peds milestone M3, navigation](26f-living-world-peds.md#change-peds-milestone-m3-navigation)
- [Peds standing on their heads in the left turn, 2026-10-05](26f-living-world-peds.md#peds-standing-on-their-heads-in-the-left-turn-2026-10-05)
- [Peds rendered warped (bone frames twisted 90 degrees), 2026-10-05](26f-living-world-peds.md#peds-rendered-warped-bone-frames-twisted-90-degrees-2026-10-05)
- [Peds walking in place at fixed spots, one standing on a wall top, 2026-10-05](26f-living-world-peds.md#peds-walking-in-place-at-fixed-spots-one-standing-on-a-wall-top-2026-10-05)
- [Ped clothes drawn in their mask colours (looked like mixed outfits), 2026-10-05](26f-living-world-peds.md#ped-clothes-drawn-in-their-mask-colours-looked-like-mixed-outfits-2026-10-05)
- [Peds floating in the air all over the map (2026-10-06)](26f-living-world-peds.md#peds-floating-in-the-air-all-over-the-map-2026-10-06)

### 26g: Pedestrians: props and skater contact

- [Peds walking through props, 2026-10-05](26g-living-world-ped-interactions.md#peds-walking-through-props-2026-10-05)
  - [NPC skaters riding through props, 2026-10-05 (fix 19)](26g-living-world-ped-interactions.md#npc-skaters-riding-through-props-2026-10-05-fix-19)
- [Peds walking through a held prop, 2026-10-08](26g-living-world-ped-interactions.md#peds-walking-through-a-held-prop-2026-10-08)
- [Skater hits peds: knock-down or stumble (2026-10-08)](26g-living-world-ped-interactions.md#skater-hits-peds-knock-down-or-stumble-2026-10-08)

- [Ped behaviour runtime: the stock ped AI graph on each ped (2026-10-09)](26g-living-world-ped-interactions.md#ped-behaviour-runtime-the-stock-ped-ai-graph-on-each-ped-2026-10-09)
- [Ped mood system: wants from the stock mood tables (2026-10-09)](26g-living-world-ped-interactions.md#ped-mood-system-wants-from-the-stock-mood-tables-2026-10-09)
- [Fleeing peds run away from the threat (2026-10-09)](26g-living-world-ped-interactions.md#fleeing-peds-run-away-from-the-threat-2026-10-09)
- [Peds speak from their AI graph (2026-10-09)](26g-living-world-ped-interactions.md#peds-speak-from-their-ai-graph-2026-10-09)
  - [Graph timers: SetSimpleTimer and SimpleTimerExpired (2026-10-09)](26g-living-world-ped-interactions.md#graph-timers-setsimpletimer-and-simpletimerexpired-2026-10-09)
- [Ped chases: chase record, chase groups and the intercept (2026-10-09)](26g-living-world-ped-interactions.md#ped-chases-chase-record-chase-groups-and-the-intercept-2026-10-09)
- [Ped takedowns and chase exhaustion (2026-10-09)](26g-living-world-ped-interactions.md#ped-takedowns-and-chase-exhaustion-2026-10-09)
- [Ped perception, secondary chasers and tazers (2026-10-09)](26g-living-world-ped-interactions.md#ped-perception-secondary-chasers-and-tazers-2026-10-09)
- [Peds greet each other (2026-10-09)](26g-living-world-ped-interactions.md#peds-greet-each-other-2026-10-09)
- [Ped conversations: the plugin runner and the conversation object (2026-10-09)](26g-living-world-ped-interactions.md#ped-conversations-the-plugin-runner-and-the-conversation-object-2026-10-09)
- [Conversation speech, gather timer and abort (2026-10-09)](26g-living-world-ped-interactions.md#conversation-speech-gather-timer-and-abort-2026-10-09)
### 26h: Traffic

- [Change: milestone V0, vehicle data](26h-living-world-traffic.md#change-milestone-v0-vehicle-data)
- [Change: milestone V1, road graph, lane cursor, traffic signals and junction entry](26h-living-world-traffic.md#change-milestone-v1-road-graph-lane-cursor-traffic-signals-and-junction-entry)
- [Change: milestone V2, the vehicle census](26h-living-world-traffic.md#change-milestone-v2-the-vehicle-census)
- [Change: milestone V3, cars on screen](26h-living-world-traffic.md#change-milestone-v3-cars-on-screen)
- [Cars flying off, population gone, 2026-10-05](26h-living-world-traffic.md#cars-flying-off-population-gone-2026-10-05)
- [Car shadows from a bridge printed on the ground below, 2026-10-08](26h-living-world-traffic.md#car-shadows-from-a-bridge-printed-on-the-ground-below-2026-10-08)
- [Cars hit peds: retail reaction, 2026-10-08](26h-living-world-traffic.md#cars-hit-peds-retail-reaction-2026-10-08)
- [Skitching: research and the tow spring (2026-10-09, groundwork)](26h-living-world-traffic.md#skitching-research-and-the-tow-spring-2026-10-09-groundwork)
- [Cars knock the skater down, and brake when hit (V5 start, 2026-10-09)](26h-living-world-traffic.md#cars-knock-the-skater-down-and-brake-when-hit-v5-start-2026-10-09)
- [Traffic: obstacles ahead (V4 look-ahead, 2026-10-09)](26h-living-world-traffic.md#traffic-obstacles-ahead-v4-look-ahead-2026-10-09)
- [Traffic: the horn, and peds running from it (V4, 2026-10-09)](26h-living-world-traffic.md#traffic-the-horn-and-peds-running-from-it-v4-2026-10-09)
- [Skitching step 1: car grab splines in the vehicle data (2026-10-09)](26h-living-world-traffic.md#skitching-step-1-car-grab-splines-in-the-vehicle-data-2026-10-09)

### 26i: Props

- [Props pulled toward the player, 2026-10-05](26i-living-world-props.md#props-pulled-toward-the-player-2026-10-05)
- [Moving a held prop: every stick direction goes forward, skater inside the prop, grab flicker, 2026-10-05](26i-living-world-props.md#moving-a-held-prop-every-stick-direction-goes-forward-skater-inside-the-prop-grab-flicker-2026-10-05)
- [Board stuck inside a prop, 2026-10-05](26i-living-world-props.md#board-stuck-inside-a-prop-2026-10-05)
- [Dragged props sinking through the floor, 2026-10-07](26i-living-world-props.md#dragged-props-sinking-through-the-floor-2026-10-07)
  - [Move Object port (2026-10-08)](26i-living-world-props.md#move-object-port-2026-10-08)
