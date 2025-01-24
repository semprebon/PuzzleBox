
include <joints.scad>

/* [Basic Parameters] */
// Size of box (not including ornimentation)
SIZE = [20,35,30];
// Piece
PIECE = "all"; // [all, selected, maze, face, slider, box, lid, handle]
MAZE_PIECE = true;
FACE_PIECE = true;
SLIDE_PIECE = true;
BOX_PIECE = true;
LID_PIECE = true;
HANDLE_PIECE = true;

/* [Customization] */
/* Orientation */
ORIENTATION = "assembled"; // [assembled, print, inverse, intersection]
/* Maze path */
PIN_PATH = [[-1,-1],[-1,0],[0,0],[0,-1],[1,-1],[1,1]];
/* Step in solution (assembled orientation only) */
STEP = 0; // [0:1:20]
INITIAL_STEP = 2;
/* Width of slide piece relative to the height of the box */
SLIDE_WIDTH_FRACTION = 0.3333; // [0:0.05:1];
/* Offset of the slide piece from the center (mm) */
SLIDE_OFFSET = 0;
// Width of face dovetail as a fraction of box width
FACE_DOVETAIL_FRACTION = 0.55;
BOLT_HEAD_SIZE = 5.4;

ACTUAL_SLIDE_OFFSET = SLIDE_OFFSET + THICKNESS/4; // accounts for added lid stop

function slide_width(size) = (size.y + THICKNESS/2 + THICKNESS/4) * SLIDE_WIDTH_FRACTION;

function show_piece(name, flag) = PIECE=="all" || PIECE==name || (PIECE=="selected" && flag);

module maze(size) {
    _size = size_3d(size) - [THICKNESS,0,0];
    tail_width = FACE_DOVETAIL_FRACTION*size.x;
    difference() {
        union() {
            translate([0,0,THICKNESS]) rotate([0,180,0]) {
                simple_sliding_tail_panel(_size, tail_width=tail_width, tail_start=-MIN_THICKNESS);
            }
            panel([_size.x+THICKNESS/2-TOLERANCE, _size.y, _size.z/2-TOLERANCE]);
        }
        translate([0,-ACTUAL_SLIDE_OFFSET,0]) pin_path(size, PIN_PATH);
    }
    panel([_size.x+THICKNESS/2-TOLERANCE, _size.y, MIN_THICKNESS]);
}

module face(size) {
    _size = size_3d(size);
    tail_size = [slide_width(_size), _size.x, _size.z/2];
    max_ext_y = max([for (i=range_for(PIN_PATH)) pin_position(PIN_PATH[i]).y]) + PIN_HOLE_RADIUS;
    echo(max_ext_y=max_ext_y);
    pin_extent = max_ext_y;
    pin_start = MIN_THICKNESS + TOLERANCE + MAZE_CELL_SIZE;
    difference() {
        // main block of face with a pin
        rotate([0, 180, 0]) {
            simple_sliding_pin_panel(_size, pin_start=pin_start, pin_extent=-pin_extent);
            translate([0,-size.y/2-THICKNESS/4,0]) panel([_size.x,THICKNESS/2,_size.z/2]);
        }

        // path for pin
        ext_x = min_max([for (i=range_for(PIN_PATH)) pin_position(PIN_PATH[i]).x]);
        maze_size = [ext_x[1] - ext_x[0], 1] + 2*PIN_HOLE_RADIUS*[1,1];
        translate([0,-ACTUAL_SLIDE_OFFSET,-_size.z]) cube(concat(maze_size, 2*_size.z), center=true);

        //translate([0,_size.y/2-_size.z/4,0]) panel([_size.x,_size.z/2,_size.z]); ??
        translate([0,-ACTUAL_SLIDE_OFFSET,0]) rotate([0,180,90]) {
            dovetail(tail_size, tolerance = TOLERANCE);
        }
    }
}

module slide(size) {
    _size = size_3d(size);
    pin_extent=0;
    pin_start=0;
    pin_socket(_size, reverse_array(pin_position(PIN_PATH[INITIAL_STEP]))) {
        pin_size = [slide_width(_size), _size.x+pin_extent, _size.z*0.5];
        translate([0,pin_start+pin_extent/2,0]) dovetail(pin_size, is_pin=true);
    }
}

module main_box(box_size) {
    difference() {
        // box, open at +z and also +y for mechanism
        panel(box_size);
        translate([THICKNESS/4, 0, THICKNESS/4]) panel(box_size - [0,THICKNESS,0]);

        // slot to hold mechanism
        translate([box_size.x/2-THICKNESS*3/4,0,0]) {
            panel([THICKNESS/2,box_size.y-THICKNESS/2,box_size.z-THICKNESS/2]);
            // cutaway at bottom for mechanism
            translate([THICKNESS/2,0,0]) panel([THICKNESS/2,box_size.y-THICKNESS,THICKNESS/4]);
        }

        // dovetail slot for lid
        lid_x_extent = -THICKNESS/4;
        translate([0,0,box_size.z]) {
            lid(box_size, tolerance=TOLERANCE);
        }
    }

}

module handle(size) {
    _size = size_3d(size) - [size.x*0.333,THICKNESS,THICKNESS*1/4];
    echo(_size=_size);
    inset = THICKNESS;
    mirror([0,0,1]) pin_socket(_size, reverse_array(pin_position(PIN_PATH[INITIAL_STEP]))) {
        difference() {
            hull() {
                panel([slide_width(_size), _size.y, MIN_THICKNESS]);
                panel([slide_width(_size), _size.y - 2*inset, _size.z]);
            }
            #translate([0,0,size.z/2]) cylinder(r=BOLT_HEAD_SIZE/2, h=_size.z/2, $fn=30);
        }
    }
}

module lid(box_size, tolerance=0) {
    lid_x_extent = -THICKNESS/4;
    lid_size = [box_size.y-4*DOVETAIL_EXTENT-TOLERANCE, box_size.x+lid_x_extent, THICKNESS/2];
    translate([THICKNESS/4+lid_x_extent/2,0,0]) rotate([0,180,90]) dovetail(lid_size, tolerance=tolerance);
}

module orient_assembly(piece, box_size, step) {
    _size = mechanism_size(box_size);
    puzzle_position = pin_position(PIN_PATH[step] - PIN_PATH[0]);
    echo(puzzle_position=puzzle_position);

    if (show_piece("maze", MAZE_PIECE)) {
        translate([box_size.x/2-THICKNESS,0,box_size.z/2-THICKNESS/4]) rotate([-90,0,-90])
            maze(_size);
    }
    if (show_piece("face", FACE_PIECE)) {
        translate([box_size.x/2-THICKNESS,0,box_size.z/2-THICKNESS/4]) rotate([-90,0,-90])
        translate([0,puzzle_position.y,_size.z*1.5]) face(_size);
    }
    if (show_piece("slide", SLIDE_PIECE)) {
        translate([box_size.x/2-THICKNESS,0,box_size.z/2-THICKNESS/4]) rotate([-90,0,-90])
            translate([puzzle_position.x,puzzle_position.y-ACTUAL_SLIDE_OFFSET,_size.z*1.5])
            rotate([0,180,-90]) slide(_size);
    }
    if (show_piece("box", BOX_PIECE)) decorated_box(SIZE) main_box(box_size);
    if (show_piece("lid", LID_PIECE)) translate([0,0,box_size.z]) lid(box_size);
    if (show_piece("handle", HANDLE_PIECE)) {
        translate([box_size.x/2-THICKNESS,0,box_size.z/2-THICKNESS/4]) rotate([-90,0,-90])
            translate([puzzle_position.x,puzzle_position.y-ACTUAL_SLIDE_OFFSET,_size.z*1.5])
                rotate([0,180,-90]) handle(_size);
    }
}

module print_orientation(box_size) {
    _size = mechanism_size(box_size);
    if (show_piece("maze", MAZE_PIECE)) maze(_size);
    if (show_piece("face", FACE_PIECE)) translate([_size.x+3,0,0]) rotate([0,180,0]) face(_size);
    if (show_piece("slide", SLIDE_PIECE)) translate([-_size.x-3,0,0]) rotate([0,0,90]) slide(_size);
    if (show_piece("box", BOX_PIECE)) translate([0,box_size.y,0]) decorated_box(SIZE) main_box(box_size);
    if (show_piece("lid", LID_PIECE)) translate([0,-box_size.y,0]) lid(box_size);

}

module inverse_check(box_size, step) {
    difference() {
        panel(box_size);
        orient_assembly("all", box_size, step);
    }
}

module fit_orientation(box_size, step) {
    for (piece = ["maze", "face", "slider", "box", "lid"])
    orient_assembly(piece, SIZE, STEP);
}

module intersection_check(box_size, step) {
    intersection() {
        orient_assembly("maze", SIZE, STEP);
        orient_assembly("face", SIZE, STEP);
        orient_assembly("slider", SIZE, STEP);
        orient_assembly("box", SIZE, STEP);
        orient_assembly("lid", SIZE, STEP);
    }
}

/*
    Cuts groove along x axis cutting into +y
 */
module groove_cutter(length=1000) {
    x_offset = TOLERANCE/2;
    y_offset = 2*TOLERANCE;
    rotate([0,90,0]) linear_extrude(length, center=true) {
        polygon([[x_offset,0],[0,y_offset],[-x_offset,0]]);
    }
}

module decorated_box(size) {
    z_offset = size.z*SLIDE_WIDTH_FRACTION/2;
    difference() {
        children();
        #for (z=[size.z/2+z_offset, size.z/2-z_offset]) {
            translate([-size.x/2,0,z]) rotate([0,0,-90]) groove_cutter();
            translate([0,-size.y/2,z]) rotate([0,0,0]) groove_cutter();
            translate([0,size.y/2,z]) rotate([0,0,180]) groove_cutter();
        }
    }
}

/*
    x in [-150:150]
    y in [-300:300]

 */
module dragon() {
   linear_extrude(height=0.2)
       import(file="Dragon-Head.svg", center=true, $fn=7);

//       import(file="Dragon-Fixed.svg", center=true, $fn=20);
}

module apply_inlay() {
    difference() {
        children(0);
        children(1);
    }
}

difference() {
    panel([60,60,2]);
    resize([50,50,0.2]) dragon();
}

if (ORIENTATION == "assembled") fit_orientation(SIZE, STEP);
else if (ORIENTATION == "print") print_orientation(SIZE);
else if (ORIENTATION == "inverse") inverse_check(SIZE, STEP);
else intersection_check(SIZE, STEP);

//dragon_inlay();
//decorated_box(SIZE) panel(SIZE);
//handle(mechanism_size(size_3d(SIZE)));
//simple_sliding_tail_panel([10,20,6]);
//translate([0,0,-30]) fit_orientation([100,40,30]);
//translate([0,0,-30])

//translate([0,0,THICKNESS*1.5]) face([40,40]);
//pin_path([40,40], PIN_PATH);
//simple_sliding_tounge_panel([20,20,THICKNESS], pin_start=10, pin_extent=-5);
//translate([0,25,THICKNESS]) rotate([0,180,0]) simple_sliding_tail_panel([20,20,THICKNESS], tail_start=-5);
