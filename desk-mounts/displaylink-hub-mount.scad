/*
Under-Desk Mount - brackets run along the 80mm side
===================================================

User dimensions:
- height 23mm
- depth  80mm   <-- brackets RUN along this dimension (Y axis)
- length 166mm  <-- this is the spacing BETWEEN brackets (X axis)
weight: 510 g

This mount:
- Two mirrored side brackets (left/right)
- Device rests on a shelf
- Top lip prevents falling
- Open ends along the RUN direction (Y), and the long faces (X direction) remain unobstructed.
*/

//////////////////////
// DEVICE DIMENSIONS
//////////////////////
dev_h = 23;
dev_run = 80;     // brackets run along this side (Y)
dev_span = 166;   // distance between brackets / long dimension (X)

//////////////////////
// USER TUNING
//////////////////////
part = "assembly";   // "assembly" | "left" | "right" | "both"
show_device = false;

clearance = 1.2;     // clearance around device
wall = 4;            // main wall thickness

// Shelf (device rests here)
shelf_depth = 16;
shelf_th = 5;

// Retention lip
lip_depth = 7;
lip_th = 4;

// Bracket length along the 80mm side
bracket_len = 74;    // slightly shorter than 80 so ends are clearly open

// Top flange (screws into desk)
flange_w = 26;
flange_th = 4;

hole_d = 4.5;
slot_len = 12;
hole_edge = 14;      // moved in from ends

// Lightweighting (safe/simple)
lighten = true;
window_y_scale = 0.70;
window_z_scale = 0.70;

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
  plate_d  = bracket_len;                 // RUN length (Y)
  plate_h  = inner_h + wall*2 + flange_th;
  lip_z    = wall + inner_h + wall;

  difference(){
    union(){
      // Main wall
      cube([plate_th, plate_d, plate_h], center=false);

      // Bottom shelf (supports device)
      translate([-shelf_depth, 0, wall])
        cube([shelf_depth, plate_d, shelf_th], center=false);

      // Top retention lip
      translate([-lip_depth, 0, lip_z])
        cube([lip_depth, plate_d, lip_th], center=false);

      // Top flange to screw into desk
      translate([plate_th, 0, plate_h - flange_th])
        cube([flange_w, plate_d, flange_th], center=false);
    }

    // Two screw slots in flange
    for (yy = [hole_edge, plate_d - hole_edge]){
      translate([plate_th + flange_w/2, yy, plate_h - flange_th - 0.1])
        rotate([0,0,90])
          elongated_slot(hole_d, slot_len, flange_th);
    }

    // Lightening window in wall
    if(lighten){
      translate([-0.5,
                 plate_d*(1-window_y_scale)/2,
                 wall + inner_h*(1-window_z_scale)/2])
        cube([plate_th+1,
              plate_d*window_y_scale,
              inner_h*window_z_scale], center=false);
    }
  }
}

module bracket_left(){
  mirror([1,0,0]) bracket_right();
}

//////////////////////
// DEVICE PREVIEW (RESTING ON SHELF)
//////////////////////
module device_mock(){
  // Device is centered between brackets in X, centered along run direction in Y,
  // and rests on top of the shelf at Z = wall + shelf_th.
  color([0.15,0.15,0.15,0.45])
    translate([
      -dev_span/2,              // X span (166)
      -dev_run/2,               // Y run (80)
      wall + shelf_th
    ])
      cube([dev_span, dev_run, dev_h], center=false);
}

//////////////////////
// ASSEMBLY VIEW
//////////////////////
module assembly(){
  if(show_device) device_mock();

  // Brackets centered along the run direction (Y)
  y0 = -bracket_len/2;

  // Inner faces sit dev_span/2 + clearance from center (X)
  x_offset = dev_span/2 + clearance;

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
