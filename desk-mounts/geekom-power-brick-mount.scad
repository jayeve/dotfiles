/*
Open-top U-cradle under-desk mount for a rectangular power brick
- Cradle has only 3 walls: bottom + two sides (TOP IS OPEN)
- Flanges are on top of the side walls and contain screw slots (2 per side)
- Optional device visualization as a rectangular prism you can toggle on/off

Copy/paste into OpenSCAD.
Render: F6
Export STL: File -> Export -> Export as STL

Axes:
- X = width (left/right)
- Y = length (front/back)
- Z = height (up toward desk)
*/

//////////////////////
// TOGGLES
//////////////////////
show_device = true;        // set false to hide device preview
show_mount  = true;        // set false to show only the device
device_alpha = 0.35;       // transparency for device preview (0..1)

$fn = 48;                  // global circle resolution

//////////////////////
// DEVICE DIMENSIONS (mm)
//////////////////////
device_w = 63.66;
device_h = 23.18;
device_l = 100;

//////////////////////
// FIT / STRENGTH (mm)
//////////////////////
clearance_xy = 0.8;        // left/right clearance
clearance_z  = 0.8;        // height clearance (device to cradle)

wall_t = 3.0;              // side wall thickness
base_t = 3.0;              // bottom thickness under device

fillet_r = 2.5;            // rounds outside edges of the profile (approx fillet)
mount_l = device_l + 6;    // overall mount length (extra so it doesn't bind)

//////////////////////
// FLANGES (MOUNTING) (mm)
//////////////////////
flange_w = 14.0;           // outward extension from side wall
flange_t = 5.0;            // vertical thickness of flange (Z thickness)

//////////////////////
// SCREW SLOTS (mm)
//////////////////////
slot_d = 4.8;              // slot width / hole diameter clearance
slot_len = 10.0;           // elongation along Y for adjustability
slot_edge_inset = 8.0;     // distance from each end to slot center (along Y)

//////////////////////
// OPTIONAL: DEVICE VISUAL OFFSET
//////////////////////
// If you want the device centered differently along length, adjust this.
// 0 centers device within mount length.
device_y_offset = 0;

//////////////////////
// DERIVED VALUES
//////////////////////
inner_w = device_w + 2*clearance_xy;
inner_h = device_h + clearance_z;

outer_w = inner_w + 2*wall_t;

// Side wall height = bottom thickness + inner cavity height (top remains open)
side_wall_h = base_t + inner_h;

// Convenience
half_outer = outer_w/2;

// Slot X positions: center of each flange region
slot_x_left  = -(half_outer + flange_w/2);
slot_x_right =  (half_outer + flange_w/2);

// Slot Y positions: front/back
slot_y_front = slot_edge_inset;
slot_y_back  = mount_l - slot_edge_inset;

//////////////////////
// HELPERS
//////////////////////

// 2D capsule used for slots (in XY, then extruded in Z)
module slot2d(slot_length, hole_d) {
  hull() {
    translate([-slot_length/2, 0]) circle(d=hole_d);
    translate([ slot_length/2, 0]) circle(d=hole_d);
  }
}

// 2D profile (X,Z) for an open-top U cradle + flanges
module open_u_profile_2d() {
  // Build from rectangles then round outer edges via offset.
  // offset(+r) then offset(-r) yields rounded exterior corners.
  offset(r=fillet_r, $fn=24)
    offset(delta=-fillet_r, $fn=24)
      union() {
        // Bottom plate
        translate([-half_outer, 0])
          square([outer_w, base_t]);

        // Left side wall
        translate([-half_outer, 0])
          square([wall_t, side_wall_h]);

        // Right side wall
        translate([half_outer - wall_t, 0])
          square([wall_t, side_wall_h]);

        // Left flange: sits atop side wall, extends outward + covers wall thickness
        translate([-half_outer - flange_w, side_wall_h])
          square([flange_w + wall_t, flange_t]);

        // Right flange
        translate([half_outer - wall_t, side_wall_h])
          square([flange_w + wall_t, flange_t]);
      }
}

//////////////////////
// MAIN MOUNT SOLID
//////////////////////
module mount_solid() {
  eps = 0.01; // small value to ensure clean boolean operations
  
  difference() {
    // Extrude the outer shell profile along Y
    linear_extrude(height=mount_l, center=false, convexity=10)
      open_u_profile_2d();

    // Cut inner cavity for device (OPEN TO THE TOP)
    // Removes interior space only up to the top of the side walls.
    translate([-inner_w/2, -eps, base_t])
      cube([inner_w, mount_l + 2*eps, inner_h + eps]);

    // Cut 4 vertical screw slots through flange thickness
    for (sx = [slot_x_left, slot_x_right]) {
      for (sy = [slot_y_front, slot_y_back]) {
        translate([sx, sy, side_wall_h - eps]) // bottom of flange region
          linear_extrude(height=flange_t + 2*eps, center=false, convexity=5)
            slot2d(slot_len, slot_d);
      }
    }
  }
}

//////////////////////
// DEVICE PREVIEW
//////////////////////
module device_preview() {
  // Place device so it rests on the bottom plate (z = base_t)
  // and is centered left/right. Center along Y within mount length.
  dev_y = (mount_l - device_l)/2 + device_y_offset;

  color([0.1, 0.7, 0.2, device_alpha])
    translate([-device_w/2, dev_y, base_t])
      cube([device_w, device_l, device_h], center=false);
}

//////////////////////
// SCENE
//////////////////////
if (show_mount) {
  color([0.2, 0.2, 0.2, 1.0]) mount_solid();
}

if (show_device) {
  device_preview();
}
