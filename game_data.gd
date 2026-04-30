extends Node

var selected_god: int = 0
var selected_leader: int = 0
var god_name: String = ""
var leader_name: String = ""

# Campaign results — set by campaign_map.gd, read and cleared by game.gd on return
var campaign_result_believers: int = 0
var campaign_result_stars: int     = 0

# Mid-mission state — preserved when player switches back to base camp
var mission_active: bool              = false
var mission_exit_ticks_msec: int      = 0
var mission_timer_remaining: float    = 0.0
var mission_converted_count: int      = 0
var mission_campaign_ended: bool      = false
var mission_blockade_alive: bool      = true
var mission_villager_resist: Array    = []
var mission_villager_done: Array      = []
var mission_villager_active: Array    = []
var mission_villager_positions: Array = []
