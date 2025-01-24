// 3d joint tests
//
// See Notebook 2, Page 21 for diagrams

TOLERANCE = 0.25;
DEFAULT_DOVETAIL_ANGLE = 45;
LAYER_HEIGHT = 0.16;
THICKNESS = 6;
MIN_THICKNESS = 1;
DOVETAIL_EXTENT = THICKNESS/2 - 2*MIN_THICKNESS;
FN=30;
PIN_DIAMETER = 2.7; // [0:0.2:6]
MAZE_CELL_SIZE = 3;

PIN_HOLE_RADIUS = PIN_DIAMETER/2+2*TOLERANCE;

function size_3d(size) = (len(size) == 3) ? size : [size.x, size.y, THICKNESS];

function reverse_array(a) = [ for (i=[len(a)-1:-1:0]) a[i] ];

// mirror an array of points to create a polygon symetric around the y axis
function y_mirror(points) = concat(points, [ for (i=[len(points)-1.:-1:0]) [-points[i].x, points[i].y] ]);

function range_for(a) = [0:(len(a)-1)];

function pin_position(p) = mult(p, [PIN_HOLE_RADIUS, PIN_HOLE_RADIUS] * MAZE_CELL_SIZE);

// multiply two vectors by elements
function mult(a, b) = [ for (i=range_for(a)) a[i]*b[i]];

/* return (min,max) from a list of numeric values */
function min_max(a) = [min(a), max(a)];

function mechanism_size(box_size) = size_3d([box_size.y,box_size.z-THICKNESS/2]);

/*
    Create a panel; like cube, but centered on the x/y axis with a default thickness of THICKNESS
 */
module panel(size) {
    _size = size_3d(size);
    translate([0,0,_size.z/2]) cube(_size, center=true);
}

/*
    2D Dovetail dovetail_profile
    
    size - size of dovetal 
    tolerance - tolerance to add; + makes it bigger
    is_pin - Set to true for pins, false for tails. Pins have a layer shaved off 
        the end to reduce friction
 */
module dovetail_profile(size, tolerance=0, is_pin=false) {
    dovetail_y = DOVETAIL_EXTENT;
    xgap = cos(45) * tolerance;
    x1 = size.x/2 + xgap;
    x0 = size.x/2 - (dovetail_y / tan(45)) + xgap;
    y = size.y - (is_pin ? LAYER_HEIGHT : 0);
    polygon(y_mirror([[x0,0], [x0, MIN_THICKNESS], [x1,size.y-MIN_THICKNESS],[x1,size.y]]));
}

/*
    Create a dovetail resting on the xy plane with length along the y axis and centered
    at the origin.

    size - size of dovetal 
    tolerance - tolerance to add; + makes it bigger
    pin - Set to true for pins, false for tails. Pins have a layer shaved off 
        the end to reduce friction
 */
module dovetail(size, tolerance=0, is_pin=false) {
    rotate([90,0,0]) linear_extrude(height=size.y, center=true) {
        dovetail_profile([size.x, size.z], tolerance=tolerance, is_pin=is_pin);
    }
}

/*
    Create a panel with a dovetail pin along its top surface parallel to the y_axis.

    size - size of panel (including pin)
    pin_offset - offsets the pin along the x axis. 0 puts the pin centered on y axis.
    pin_extent - adds to the length of the pin, extening beyond the far end of the panel
    pin_start - the starting point of the pin on the y axis; i..e, y_offset
 */
module simple_sliding_pin_panel(size, pin_start=0, pin_extent=0, pin_offset=0, pin_width=undef) {
    _pin_width = is_undef(pin_width) ? FACE_DOVETAIL_FRACTION*size.x : pin_width;
    pin_size = [_pin_width, size.y+pin_extent, size.z*0.5];
    panel([size.x,size.y,size.z/2]);
    translate([pin_offset,pin_start+pin_extent/2,size.z/2]) dovetail(pin_size, is_pin=true);
}

/*
    Create a panel with a dovetail tail along its bottom surface parallel to the y_axis.

    size - size of panel (including pin)
    tail_offset - offsets the pin along the x axis. 0 puts the pin centered on y axis.
    tail_extent - adds to the length of the pin, extening beyond the far end of the panel
    tail_start - the starting point of the pin on the y axis; i..e, y_offset
 */
module simple_sliding_tail_panel(size, tail_start=0, tail_extent=0, tail_offset=0, tail_width=undef) {
    _tail_width = is_undef(tail_width) ? SLIDE_PANEL_DOVETAIL_FRACTION*size.x : tail_width;
    tail_size = [tail_width, size.y+tail_extent, size.z/2];
    echo(tail_offset=tail_offset);
    difference() {
        panel(size);
        #translate([tail_offset,tail_start+tail_extent/2,0]) dovetail(tail_size, tolerance=TOLERANCE);
    }
}

module pin(h=THICKNESS, r=PIN_DIAMETER/2) {
    bevel = r/3;
    s1 = 2*r;
    s2 = s1 - 2*bevel;
    translate([0,0,h/2]) hull() {
        cube([s1,s2,h], center=true);
        cube([s2,s1,h], center=true);
    }
    rotate([0,0,360/16]) cylinder(r=PIN_DIAMETER/2+TOLERANCE, h=h, $fn=FN);
}

module pin_socket(size, position=[0,0]) {
    difference() {
        children();
        translate(position) pin(h=THICKNESS*100, r=PIN_DIAMETER/2);
    }
}

module pin_path(size, path) {
    for (i=[1:(len(path)-1)]) {
        hull() {
            translate(pin_position(path[i-1])) pin(r=PIN_HOLE_RADIUS);
            translate(pin_position(path[i])) pin(r=PIN_HOLE_RADIUS);
        }
    }
}
