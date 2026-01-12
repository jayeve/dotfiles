/*
Under-Desk KVM Mount (Front/Back Open)
=====================================

Design:
- Two side brackets (left + right)
- KVM rests on a lower shelf
- Top lip prevents drop-out
- Front & back faces fully open for ports/cables
- Tuned for ~1.37 lb device, wood-screw mounting

KVM Dimensions:
- Width: 140.53 mm
- Depth: 67.36 mm
- Height: 38.03 mm
*/

//////////////////////
// KVM DIMENSIONS
//////////////////////
dev_w = 140.53;
dev_d = 67.36;
dev_h = 38.03;

//////////////////////
// USER TUNING
//////////////////////
part = "assembly";   // "assembly" | "left" | "right" | "both"
show_device = false;

clearance = 1.2;     // side/top clearance
wall = 4;            // main wall thickness

// Shelf (device rests here)
shelf_depth = 16;
shelf_th = 5;

// Retention lip
lip_depth = 7;
lip_th = 4;

// Bracket length (along device depth)
bracket_len = 60;    // shorter than device depth → ports stay clear

// Top flange (screws into desk)
flange_w = 26;
flange_th = 4;
hole_d = 4.5;
slot_len = 12;
hole_edge = 14;      // distance from ends

//////////////////////
// DERIVED
//////////////////////
inner_h = dev_h + 2*clearance;

//////////////////////
// HELPERS
//////////////////////

module elongated_slot(d, len, th){
  hull(){
    translate([-len/2,0,0]) cylinder(h=th+0.2, d=d, $fn=48);
    translate([ len/2,0,0]) cylinder(h=th+0.2, d=d, $fn=48);
  }
}

//////////////////////
// SINGLE BRACKET (RIGHT)
//////////////////////
module bracket_right(){
  plate_th = wall;
  plate_d  = bracket_len;
  plate_h  = inner_h + wall*2 + flange_th;
  lip_z    = wall + inner_h + wall;

  difference(){
    union(){
      // Main vertical wall
      cube([plate_th, plate_d, plate_h], center=false);

      // Bottom shelf (supports KVM)
      translate([-shelf_depth, 0, wall])
        cube([shelf_depth, plate_d, shelf_th], center=false);

      // Top retention lip
      translate([-lip_depth, 0, lip_z])
        cube([lip_depth, plate_d, lip_th], center=false);

      // Top flange (screws into desk)
      translate([plate_th, 0, plate_h - flange_th])
        cube([flange_w, plate_d, flange_th], center=false);
    }

    // Screw slots (2 per bracket)
    for (yy = [hole_edge, plate_d - hole_edge]){
      translate([plate_th + flange_w/2, yy, plate_h - flange_th - 0.1])
        rotate([0,0,90])
          elongated_slot(hole_d, slot_len, flange_th);
    }

    // Side airflow / weight reduction window
    translate([-0.5, plate_d*0.15, wall + inner_h*0.15])
      cube([plate_th+1, plate_d*0.7, inner_h*0.7], center=false);
  }
}

//////////////////////
// MIRROR FOR LEFT
//////////////////////
module bracket_left(){
  mirror([1,0,0]) bracket_right();
}

//////////////////////
// DEVICE PREVIEW (CORRECTLY RESTING)
//////////////////////
module device_mock(){
  color([0.15,0.15,0.15,0.45])
    translate([
      -dev_w/2,
      -dev_d/2,
      wall + shelf_th   // rests ON the shelf
    ])
      cube([dev_w, dev_d, dev_h], center=false);
}

//////////////////////
// ASSEMBLY VIEW
//////////////////////
module assembly(){
  if(show_device) device_mock();

  y0 = -bracket_len/2;
  x_offset = dev_w/2 + clearance;

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
