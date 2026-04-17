extends Node

var selected_god: int = 0
var selected_leader: int = 0
var god_name: String = ""
var leader_name: String = ""

# Campaign results — set by campaign_map.gd, read and cleared by game.gd on return
var campaign_result_believers: int = 0
var campaign_result_stars: int     = 0
