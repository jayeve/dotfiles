/*
Cable Mount - Single piece with connected shelves and reinforced transitions
===============================================================================
to build:

1. Prompt engineer with ChatGPT to create a scad file
2. Create stl file froma docker container running openscad
   ```bash
   j dotfiles
   cd desk-mounts
   docker run \
       -it \
       --rm \
       -v $(pwd):/openscad \
       -u $(id -u ${USER}):$(id -g ${USER}) \
       openscad/openscad:latest \
       openscad -o cable-mount.stl cable-mount.scad
   ```
3. render in OnShape

Here are the dimensions of the different pieces (height, width, depth)
from the perspective of power cable going into the back and the ports
showing right in front of you

- geekom (36.75,112.32,111.59)
- ugreen displaylink hub (25,160,78.39)
- kvm switch (38.03,140.53,67.36)
- geekom power brick (23.18,63.66,98)
- caldigit power brick (25.75,75.45,150)
*/

//////////////////////
// DEVICE DIMENSIONS
//////////////////////

device_height = 23.18; // height of the device (Z axis when looking head on from front)
device_width = 63.66;   // width of the device (X axis when looking head on from front)
device_depth = 98;     // depth of the device (Y axis when looking head on from front)

//////////////////////
// USER TUNING
//////////////////////
show_device = false;

clearance = 0.5;     // clearance around device
wall = 4;            // main wall thickness

// device sits here
shelf_th = 5;

// Retention lip
lip_depth = 7;
lip_th = 4;

// Top flange (screws into desk)
flange_w = 26;
flange_th = 4;

hole_d = 4.5;
slot_len = 12;
hole_edge = 14;      // moved in from ends

// Fillet radius for wall-to-shelf transition (strengthening)
transition_fillet_r = 4;

// Lightweighting (safe/simple)
lighten = true;
window_y_scale = 0.70;
window_z_scale = 0.70;

// Base weight reduction
base_cutout = true;
base_cutout_margin = 12;  // leave this much material at edges

//////////////////////
// DERIVED
//////////////////////
inner_h = device_height + 2*clearance;
inner_span = device_width + 2*clearance;

$fn = 48;

//////////////////////
// HELPERS
//////////////////////
module elongated_slot(d, len, th){
  hull(){
    translate([-len/2,0,0]) cylinder(h=th+0.2, d=d);
    translate([ len/2,0,0]) cylinder(h=th+0.2, d=d);
  }
}

//////////////////////
// SINGLE UNIFIED MOUNT
//////////////////////
module cable_mount(){
  plate_d  = device_depth;                 // RUN length (Y)
  plate_h  = inner_h + flange_th;
  lip_z    = wall + inner_h + wall;
  eps = 0.01;
  
  difference(){
    union(){
      // Left wall
      translate([-inner_span/2 - wall, 0, 0])
        cube([wall, plate_d, plate_h]);

      // Right wall
      translate([inner_span/2, 0, 0])
        cube([wall, plate_d, plate_h]);

      // Connected shelf spanning the entire width
      // (lower than retention lips by device height)
      translate([-inner_span/2 - wall , 0, 0])
        cube([inner_span + 2*wall , plate_d, shelf_th]);
      
      // Reinforcement fillets at wall-to-shelf transitions (inside corners)
      // These add material where the shelf meets the walls for strength
      
      // Left wall inner fillet (where shelf meets wall on the inside)
      translate([-inner_span/2, 0, shelf_th])
        rotate([0, 90, 0])
          linear_extrude(height=eps)
            difference(){
              square([transition_fillet_r, plate_d]);
              translate([transition_fillet_r, -eps])
                square([transition_fillet_r + eps, plate_d + 2*eps]);
              for(y = [0, plate_d]){
                translate([transition_fillet_r, y])
                  circle(r=transition_fillet_r);
              }
            }
      
      // Better approach: use cylinders to create the fillet
      // Left inner fillet
      translate([-inner_span/2, 0, shelf_th])
        rotate([-90, 0, 0])
          linear_extrude(height=plate_d)
            difference(){
              square([transition_fillet_r, transition_fillet_r]);
              translate([transition_fillet_r, transition_fillet_r])
                circle(r=transition_fillet_r);
            }
      
      // Right inner fillet
      translate([inner_span/2, 0, shelf_th])
        rotate([-90, 0, 0])
          linear_extrude(height=plate_d)
            difference(){
              translate([-transition_fillet_r, 0])
                square([transition_fillet_r, transition_fillet_r]);
              translate([-transition_fillet_r, transition_fillet_r])
                circle(r=transition_fillet_r);
            }

      // Left flange
      translate([-inner_span/2 - wall - flange_w, 0, plate_h - flange_th])
        cube([flange_w, plate_d, flange_th]);

      // Right flange
      translate([inner_span/2 + wall, 0, plate_h - flange_th])
        cube([flange_w, plate_d, flange_th]);
    }

    // Left wall screw slots
    for (yy = [hole_edge, plate_d - hole_edge]){
      translate([-inner_span/2 - wall - flange_w/2, yy, plate_h - flange_th - 0.1])
        rotate([0,0,90])
          elongated_slot(hole_d, slot_len, flange_th);
    }

    // Right wall screw slots
    for (yy = [hole_edge, plate_d - hole_edge]){
      translate([inner_span/2 + wall + flange_w/2, yy, plate_h - flange_th - 0.1])
        rotate([0,0,90])
          elongated_slot(hole_d, slot_len, flange_th);
    }

    // Left wall lightening window
    if(lighten){
      translate([-inner_span/2 - wall - 0.5,
                 plate_d*(1-window_y_scale)/2,
                 wall + inner_h*(1-window_z_scale)/2])
        cube([wall+1,
              plate_d*window_y_scale,
              inner_h*window_z_scale]);
    }

    // Right wall lightening window
    if(lighten){
      translate([inner_span/2 - 0.5,
                 plate_d*(1-window_y_scale)/2,
                 wall + inner_h*(1-window_z_scale)/2])
        cube([wall+1,
              plate_d*window_y_scale,
              inner_h*window_z_scale]);
    }
    
    // Base weight reduction cutout
    if(base_cutout){
      // Calculate cutout dimensions (leave margin at edges for strength)
      cutout_width = inner_span + 2*wall - 2*base_cutout_margin;
      cutout_length = plate_d - 2*base_cutout_margin;
      cutout_depth = shelf_th - 1.5;  // leave bottom layer for strength
      
      // Center cutout in the base
      translate([
        -cutout_width/2,
        base_cutout_margin,
        1.5  // start above bottom layer
      ])
        cube([cutout_width, cutout_length, cutout_depth]);
    }
  }
}

//////////////////////
// DEVICE PREVIEW
//////////////////////
module device_mock(){
  color([0.15,0.15,0.15,0.45])
    translate([
      -device_width/2,
      (device_width - device_depth)/2,
      shelf_th
    ])
      cube([device_width, device_depth, device_height]);
}

//////////////////////
// RENDER
//////////////////////
if(show_device) device_mock();
cable_mount();
