/*
Breathable Under-Desk Mini PC Mount (Front/Back Open) - LIGHTWEIGHT (TUNED)
=========================================================================

Two side brackets (left + right) that grip the PC on the top and support it on the bottom,
leaving front and back faces completely open.

Tuned for:
- Mini PC weight ~1.1 lb (~0.5 kg)
- Wood screws into a wood desk

Includes:
- Wider resting shelf
- Filled-in joints (removed chamfer relief cuts)
- 2 screw slots, moved farther from ends
- Material reduction: ribbed wall + pockets in shelf & lip + no-cut zones under screw lines

NOTE:
OpenSCAD has no `return` or `continue`, so logic is expressed with if-block guards.
*/

//////////////////////
// PC DIMENSIONS
//////////////////////
pc_w = 122.32;
pc_d = 111.59;
pc_h = 36.75;

//////////////////////
// USER TUNING
//////////////////////
part = "assembly"; // "assembly" | "left" | "right" | "both"
show_pc = false;    // only in assembly preview

clearance = 1.2;         // mm gap around PC
wall = 4;                // mm bracket wall thickness

// Resting shelf
shelf_depth = 16;        // mm shelf under PC
shelf_th = 5;            // mm thickness of shelf

// Retention lip
lip_depth = 7;           // mm top lip overlap
lip_th = 4;              // thickness of lip

// Length along depth (Y)
bracket_len = 95;        // mm

// Top flange (screws into desk)
flange_w = 26;           // mm flange extension outwards (+X)
flange_th = 4;           // mm thickness of flange
hole_d = 4.5;            // mm screw clearance diameter
slot_len = 12;           // mm elongated slot length (adjustability)
hole_edge = 16;          // mm from ends (moved farther from edge)

// Vent slots (simple slots)
slot_w = 6;              // mm
slot_gap = 6;            // mm
slot_margin = 10;        // mm

// LIGHTWEIGHTING (tuned)
lighten      = true;

edge_beam    = 5;        // mm no-cut border around wall edges
joint_beam   = 12;       // mm keep solid near shelf/lip junctions (strength)
flange_beam  = 12;       // mm keep solid around screw-slot y-lines (strength)

rib_w        = 4;        // mm rib thickness
rib_gap      = 18;       // mm spacing for wall lightening (bigger = lighter)

shelf_edge        = 4;   // mm solid border on shelf along depth edges
shelf_pocket_gap  = 12;  // mm spacing along depth for pockets
shelf_pocket_w    = 12;  // mm pocket width along depth

lip_edge = 3;            // mm solid border on lip

// Edge rounding (off by default; slower)
inner_corner_r = 1.5;    // mm
use_rounding = false;

//////////////////////
// DERIVED
//////////////////////
inner_h = pc_h + 2*clearance;

//////////////////////
// HELPERS
//////////////////////

module elongated_slot(d, len, th){
  hull(){
    translate([-len/2,0,0]) cylinder(h=th+0.2, d=d, $fn=48);
    translate([ len/2,0,0]) cylinder(h=th+0.2, d=d, $fn=48);
  }
}

module vent_slots(plate_x, plate_y, plate_z){
  for (y = [slot_margin : (slot_w + slot_gap) : (plate_y - slot_margin - slot_w)]){
    translate([-1, y, slot_margin])
      cube([plate_x+2, slot_w, plate_z - 2*slot_margin], center=false);
  }
}

module maybe_round(){
  if(use_rounding){
    minkowski(){
      children();
      sphere(r=inner_corner_r, $fn=24);
    }
  } else children();
}

//////////////////////
// LIGHTENING CUTS
//////////////////////

// Ribbed cutouts in the main vertical wall plate.
// Assumes wall plate is at [0..plate_th] x [0..plate_d] x [0..plate_h]
module lighten_wall(plate_th, plate_d, plate_h, flange_th){
  if(lighten){
    usable_h = plate_h - flange_th - 1;

    // solid zones near bottom shelf and top lip joints
    shelf_z1 = joint_beam + 2*wall + shelf_th;
    lip_z0   = usable_h - (joint_beam + 2*wall);

    // y positions of screw slots
    screw_y1 = hole_edge;
    screw_y2 = plate_d - hole_edge;

    for (y = [edge_beam : rib_gap : (plate_d - edge_beam - rib_gap)]){

      // Only cut if NOT within the no-cut bands around screw y zones
      ok_y =
        (abs(y - screw_y1) >= flange_beam) &&
        (abs(y - screw_y2) >= flange_beam);

      ok_z = (lip_z0 > shelf_z1);

      if(ok_y && ok_z){
        translate([-0.5, y, shelf_z1])
          cube([plate_th+1,
                rib_gap - rib_w,
                lip_z0 - shelf_z1], center=false);
      }
    }
  }
}

// Pockets in the shelf: removes material but keeps outer edges + a solid band near the wall joint
module lighten_shelf(plate_d){
  if(lighten){
    keep_near_wall = joint_beam;

    x_cut_start = -shelf_depth + keep_near_wall;
    x_cut_w     = shelf_depth - keep_near_wall - 0.5;

    // Only pocket if we actually have room
    if(x_cut_w > 0){
      for (y = [shelf_edge : shelf_pocket_gap : (plate_d - shelf_edge - shelf_pocket_w)]){
        translate([x_cut_start, y, wall + 0.6])
          cube([x_cut_w, shelf_pocket_w, shelf_th - 1.2], center=false);
      }
    }
  }
}

// Pockets in the top lip: removes material but keeps border + solid band near wall joint
module lighten_lip(plate_d, lip_z){
  if(lighten){
    keep_near_wall = joint_beam;

    x_cut_start = -lip_depth + keep_near_wall;
    x_cut_w     = lip_depth - keep_near_wall - 0.5;

    if(x_cut_w > 0){
      for (y = [lip_edge : shelf_pocket_gap : (plate_d - lip_edge - shelf_pocket_w)]){
        translate([x_cut_start, y, lip_z + 0.6])
          cube([x_cut_w, shelf_pocket_w, lip_th - 1.2], center=false);
      }
    }
  }
}

//////////////////////
// SINGLE BRACKET (RIGHT)
//////////////////////
module bracket_right(){
  plate_th = wall;
  plate_d  = bracket_len;
  plate_h  = inner_h + wall*2 + flange_th;

  lip_z = wall + inner_h + wall;

  maybe_round()
  difference(){
    union(){
      // Main vertical plate
      cube([plate_th, plate_d, plate_h], center=false);

      // Bottom shelf (supports PC) - extends inward (negative X direction)
      translate([-shelf_depth, 0, wall])
        cube([shelf_depth, plate_d, shelf_th], center=false);

      // Top lip (retains PC) - extends inward (negative X direction)
      translate([-lip_depth, 0, lip_z])
        cube([lip_depth, plate_d, lip_th], center=false);

      // Top flange to screw into desk (extends outward +X)
      translate([plate_th, 0, plate_h - flange_th])
        cube([flange_w, plate_d, flange_th], center=false);
    }

    // Base vent slots in wall plate
    vent_height = plate_h - flange_th - 1;
    vent_slots(plate_th, plate_d, vent_height);

    // Large window cutout for airflow + side cable clearance
    translate([-0.5, plate_d*0.20, wall + inner_h*0.15])
      cube([plate_th+1, plate_d*0.60, inner_h*0.70], center=false);

    // Screw slots in the flange (2 slots, farther from ends)
    for (yy = [hole_edge, plate_d - hole_edge]){
      translate([plate_th + flange_w/2, yy, plate_h - flange_th - 0.1])
        rotate([0,0,90])
          elongated_slot(hole_d, slot_len, flange_th);
    }

    // Lightweighting
    lighten_wall(plate_th, plate_d, plate_h, flange_th);
    lighten_shelf(plate_d);
    lighten_lip(plate_d, lip_z);
  }
}

module bracket_left(){
  mirror([1,0,0]) bracket_right();
}

//////////////////////
// PC (for assembly preview)
//////////////////////
module pc_mock(){
  color([0.2,0.2,0.2,0.45])
    translate([
      -pc_w/2,                 // center in X
      -pc_d/2,                 // center in Y
      wall + shelf_th           // RESTS ON TOP of the shelf
    ])
      cube([pc_w, pc_d, pc_h], center=false);
}

//////////////////////
// ASSEMBLY
//////////////////////
module assembly(){
  // PC sits exactly where it would in real life
  if(show_pc) pc_mock();

  // Brackets centered along PC depth
  y0 = -bracket_len/2;

  // Brackets aligned so inner faces touch PC sides with clearance
  x_offset = pc_w/2 + clearance;

  // Right bracket
  translate([ x_offset + wall, y0, 0 ])
    bracket_right();

  // Left bracket
  translate([-(x_offset + wall), y0, 0 ])
    bracket_left();
}

//////////////////////
// OUTPUT SELECTOR
//////////////////////
if(part == "assembly"){
  assembly();
} else if(part == "right"){
  bracket_right();
} else if(part == "left"){
  bracket_left();
} else if(part == "both"){
  translate([0, -bracket_len-20, 0]) bracket_left();
  translate([0,  0,             0]) bracket_right();
} else {
  assembly();
}
