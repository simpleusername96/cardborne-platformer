<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.10" tiledversion="1.12.2" name="Flooded Works Authoring" tilewidth="64" tileheight="64" tilecount="16" columns="4" objectalignment="topleft">
 <properties>
  <property name="authoring_only" type="bool" value="true"/>
  <property name="meters_per_tile" type="float" value="1"/>
  <property name="runtime_owner" value="Godot 3D room converter"/>
 </properties>
 <image source="flooded-works-authoring-tiles.png" width="256" height="256"/>
 <tile id="0">
  <properties>
   <property name="asset_id" value="floor_plain_a"/>
   <property name="category" value="ground"/>
   <property name="navigation_cost" type="float" value="1"/>
   <property name="runtime_role" value="surface"/>
   <property name="walkable" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="1">
  <properties>
   <property name="asset_id" value="floor_plain_b"/>
   <property name="category" value="ground"/>
   <property name="navigation_cost" type="float" value="1"/>
   <property name="runtime_role" value="surface"/>
   <property name="walkable" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="2">
  <properties>
   <property name="asset_id" value="floor_wet"/>
   <property name="category" value="ground"/>
   <property name="navigation_cost" type="float" value="1"/>
   <property name="runtime_role" value="surface"/>
   <property name="walkable" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="3">
  <properties>
   <property name="asset_id" value="floor_reinforced"/>
   <property name="category" value="ground"/>
   <property name="navigation_cost" type="float" value="1"/>
   <property name="runtime_role" value="surface"/>
   <property name="walkable" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="4">
  <properties>
   <property name="asset_id" value="shallow_water"/>
   <property name="category" value="ground"/>
   <property name="navigation_cost" type="float" value="1.35"/>
   <property name="runtime_role" value="surface"/>
   <property name="walkable" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="5">
  <properties>
   <property name="asset_id" value="deep_water"/>
   <property name="category" value="ground"/>
   <property name="runtime_role" value="nav_exclusion"/>
   <property name="walkable" type="bool" value="false"/>
  </properties>
 </tile>
 <tile id="6">
  <properties>
   <property name="asset_id" value="void"/>
   <property name="category" value="ground"/>
   <property name="runtime_role" value="nav_exclusion"/>
   <property name="walkable" type="bool" value="false"/>
  </properties>
 </tile>
 <tile id="7">
  <properties>
   <property name="asset_id" value="pressure_hazard"/>
   <property name="category" value="ground"/>
   <property name="navigation_cost" type="float" value="1"/>
   <property name="runtime_role" value="hazard_surface"/>
   <property name="walkable" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="8">
  <properties>
   <property name="asset_id" value="wall_footprint"/>
   <property name="category" value="structure"/>
   <property name="runtime_role" value="wall"/>
   <property name="walkable" type="bool" value="false"/>
  </properties>
 </tile>
 <tile id="9">
  <properties>
   <property name="asset_id" value="low_cover_footprint"/>
   <property name="category" value="structure"/>
   <property name="runtime_role" value="low_cover"/>
   <property name="walkable" type="bool" value="false"/>
  </properties>
 </tile>
 <tile id="10">
  <properties>
   <property name="asset_id" value="door_socket"/>
   <property name="category" value="connection"/>
   <property name="runtime_role" value="door_socket"/>
   <property name="socket_width_m" type="float" value="1"/>
   <property name="walkable" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="11">
  <properties>
   <property name="asset_id" value="wide_gate_socket"/>
   <property name="category" value="connection"/>
   <property name="runtime_role" value="door_socket"/>
   <property name="socket_width_m" type="float" value="3"/>
   <property name="walkable" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="12">
  <properties>
   <property name="asset_id" value="player_spawn"/>
   <property name="category" value="marker"/>
   <property name="runtime_role" value="player_spawn"/>
  </properties>
 </tile>
 <tile id="13">
  <properties>
   <property name="asset_id" value="enemy_spawn"/>
   <property name="category" value="marker"/>
   <property name="runtime_role" value="enemy_spawn"/>
  </properties>
 </tile>
 <tile id="14">
  <properties>
   <property name="asset_id" value="prop_anchor"/>
   <property name="category" value="marker"/>
   <property name="runtime_role" value="prop_anchor"/>
  </properties>
 </tile>
 <tile id="15">
  <properties>
   <property name="asset_id" value="objective_anchor"/>
   <property name="category" value="marker"/>
   <property name="runtime_role" value="objective_anchor"/>
  </properties>
 </tile>
</tileset>
