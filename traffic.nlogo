globals
[
  grid-x-inc               ;; the amount of patches in between two roads in the x direction
  grid-y-inc               ;; the amount of patches in between two roads in the y direction
  acceleration             ;; the constant that controls how much a car speeds up or slows down by if
                           ;; it is to accelerate or decelerate
  phase                    ;; keeps track of the phase
  num-cars-stopped         ;; the number of cars that are stopped during a single pass thru the go procedure
  current-intersection     ;; the currently selected intersection

  ;; patch agentsets
  intersections ;; agentset containing the patches that are intersections
  roads         ;; agentset containing the patches that are roads
]

turtles-own
[
  speed     ;; the speed of the turtle
  up-car?   ;; true if the turtle moves downwards and false if it moves to the right
  wait-time ;; the amount of time since the last time a turtle has moved
  work      ;; the patch where they work
  house     ;; the patch where they live
  goal      ;; where am I currently headed
]

patches-own
[
  intersection?   ;; true if the patch is at the intersection of two roads
  green-light-up? ;; true if the green light is above the intersection.  otherwise, false.
                  ;; false for a non-intersection patches.
  my-row          ;; the row of the intersection counting from the upper left corner of the
                  ;; world.  -1 for non-intersection patches.
  my-column       ;; the column of the intersection counting from the upper left corner of the
                  ;; world.  -1 for non-intersection patches.
  my-phase        ;; the phase for the intersection.  -1 for non-intersection patches.
  auto?           ;; whether or not this intersection will switch automatically.
                  ;; false for non-intersection patches.
]


;;;;;;;;;;;;;;;;;;;;;;
;; Setup Procedures ;;
;;;;;;;;;;;;;;;;;;;;;;

;; Initialize the display by giving the global and patch variables initial values.
;; Create num-cars of turtles if there are enough road patches for one turtle to
;; be created per road patch.
to setup

  clear-all
  setup-globals
  setup-patches  ;; ask the patches to draw themselves and set up a few variables

  ;; Make an agentset of all patches where there can be a house or road
  ;; those patches with the background color shade of brown and next to a road
  let goal-candidates patches with [
    pcolor = 38 and any? neighbors with [ pcolor = white ]
  ]
  ask one-of intersections [ become-current ]

  set-default-shape turtles "car"

  if (num-cars > count roads) [
    user-message (word
      "There are too many cars for the amount of "
      "road.  Either increase the amount of roads "
      "by increasing the GRID-SIZE-X or "
      "GRID-SIZE-Y sliders, or decrease the "
      "number of cars by lowering the NUM-CAR slider.\n"
      "The setup has stopped.")
    stop
  ]

  ;; Now create the cars and have each created car call the functions setup-cars and set-car-color
  create-turtles num-cars [
    setup-cars
    set-car-color ;; slower turtles are blue, faster ones are colored cyan
    record-data
    ;; choose at random a location for the house
    set house one-of goal-candidates
    ;; choose at random a location for work, make sure work is not located at same location as house
    set work one-of goal-candidates with [ self != [ house ] of myself ]
    set goal work
  ]

  ;; give the turtles an initial speed
  ask turtles [ set-car-speed ]

  reset-ticks
end

;; Initialize the global variables to appropriate values
to setup-globals
  set current-intersection nobody ;; just for now, since there are no intersections yet
  set phase 0
  set num-cars-stopped 0
  set grid-x-inc world-width / grid-size-x
  set grid-y-inc world-height / grid-size-y

  ;; don't make acceleration 0.1 since we could get a rounding error and end up on a patch boundary
  set acceleration 0.099
end

;; Make the patches have appropriate colors, set up the roads and intersections agentsets,
;; and initialize the traffic lights to one setting
to setup-patches
  ;; initialize the patch-owned variables and color the patches to a base-color
  ask patches [
    set intersection? false
    set auto? false
    set green-light-up? true
    set my-row -1
    set my-column -1
    set my-phase -1
    set pcolor brown + 3
  ]

  ;; initialize the global variables that hold patch agentsets
  set roads patches with [
    (floor ((pxcor + max-pxcor - floor (grid-x-inc - 1)) mod grid-x-inc) = 0) or
    (floor ((pycor + max-pycor) mod grid-y-inc) = 0)
  ]
  set intersections roads with [
    (floor ((pxcor + max-pxcor - floor (grid-x-inc - 1)) mod grid-x-inc) = 0) and
    (floor ((pycor + max-pycor) mod grid-y-inc) = 0)
  ]

  ask roads [ set pcolor white ]
  setup-intersections
end

;; Give the intersections appropriate values for the intersection?, my-row, and my-column
;; patch variables.  Make all the traffic lights start off so that the lights are red
;; horizontally and green vertically.
to setup-intersections
  ask intersections [
    set intersection? true
    set green-light-up? true
    set my-phase 0
    set auto? true
    set my-row floor ((pycor + max-pycor) / grid-y-inc)
    set my-column floor ((pxcor + max-pxcor) / grid-x-inc)
    set-signal-colors
  ]
end

;; Initialize the turtle variables to appropriate values and place the turtle on an empty road patch.
to setup-cars  ;; turtle procedure
  set speed 0
  set wait-time 0
  put-on-empty-road
  ifelse intersection? [
    ifelse random 2 = 0
      [ set up-car? true ]
      [ set up-car? false ]
  ]
  [ ; if the turtle is on a vertical road (rather than a horizontal one)
    ifelse (floor ((pxcor + max-pxcor - floor(grid-x-inc - 1)) mod grid-x-inc) = 0)
      [ set up-car? true ]
      [ set up-car? false ]
  ]
  ifelse up-car?
    [ set heading 180 ]
    [ set heading 90 ]
end

;; Find a road patch without any turtles on it and place the turtle there.
to put-on-empty-road  ;; turtle procedure
  move-to one-of roads with [ not any? turtles-on self ]
end


;;;;;;;;;;;;;;;;;;;;;;;;
;; Runtime Procedures ;;
;;;;;;;;;;;;;;;;;;;;;;;;

;; Run the simulation
to go

  ask current-intersection [ update-variables ]

  ;; have the intersections change their color
  set-signals
  set num-cars-stopped 0

  ;; set the cars’ speed, move them forward their speed, record data for plotting,
  ;; and set the color of the cars to an appropriate color based on their speed
  ask turtles [
    face next-patch ;; car heads towards its goal
    set-car-speed
    fd speed
    record-data     ;; record data for plotting
    set-car-color   ;; set color to indicate speed
  ]
  label-subject ;; if we're watching a car, have it display its goal
  next-phase ;; update the phase and the global clock
  tick

end

to choose-current
  if mouse-down? [
    let x-mouse mouse-xcor
    let y-mouse mouse-ycor
    ask current-intersection [
      update-variables
      ask patch-at -1 1 [ set plabel "" ] ;; unlabel the current intersection (because we've chosen a new one)
    ]
    ask min-one-of intersections [ distancexy x-mouse y-mouse ] [
      become-current
    ]
    display
    stop
  ]
end

;; Set up the current intersection and the interface to change it.
to become-current ;; patch procedure
  set current-intersection self
  set current-phase my-phase
  set current-auto? auto?
  ask patch-at -1 1 [
    set plabel-color black
    set plabel "current"
  ]
end

;; update the variables for the current intersection
to update-variables ;; patch procedure
  set my-phase current-phase
  set auto? current-auto?
end

;; have the traffic lights change color if phase equals each intersections' my-phase
to set-signals
  ask intersections with [ auto? and phase = floor ((my-phase * ticks-per-cycle) / 100) ] [
    set green-light-up? (not green-light-up?)
    set-signal-colors
  ]
end

;; This procedure checks the variable green-light-up? at each intersection and sets the
;; traffic lights to have the green light up or the green light to the left.
to set-signal-colors  ;; intersection (patch) procedure
  ifelse power? [
    ifelse green-light-up? [
      ask patch-at -1 0 [ set pcolor red ]
      ask patch-at 0 1 [ set pcolor green ]
    ]
    [
      ask patch-at -1 0 [ set pcolor green ]
      ask patch-at 0 1 [ set pcolor red ]
    ]
  ]
  [
    ask patch-at -1 0 [ set pcolor white ]
    ask patch-at 0 1 [ set pcolor white ]
  ]
end

;; set the turtles' speed based on whether they are at a red traffic light or the speed of the
;; turtle (if any) on the patch in front of them
to set-car-speed  ;; turtle procedure
  ifelse pcolor = red [
    set speed 0
  ]
  [
    ifelse up-car?
      [ set-speed 0 -1 ]
      [ set-speed 1 0 ]
  ]
end

;; set the speed variable of the turtle to an appropriate value (not exceeding the
;; speed limit) based on whether there are turtles on the patch in front of the turtle
to set-speed [ delta-x delta-y ]  ;; turtle procedure
  ;; get the turtles on the patch in front of the turtle
  let turtles-ahead turtles-at delta-x delta-y

  ;; if there are turtles in front of the turtle, slow down
  ;; otherwise, speed up
  ifelse any? turtles-ahead [
    ifelse any? (turtles-ahead with [ up-car? != [ up-car? ] of myself ]) [
      set speed 0
    ]
    [
      set speed [speed] of one-of turtles-ahead
      slow-down
    ]
  ]
  [ speed-up ]
end

;; decrease the speed of the car
to slow-down  ;; turtle procedure
  ifelse speed <= 0
    [ set speed 0 ]
    [ set speed speed - acceleration ]
end

;; increase the speed of the car
to speed-up  ;; turtle procedure
  ifelse speed > speed-limit
    [ set speed speed-limit ]
    [ set speed speed + acceleration ]
end

;; set the color of the car to a different color based on how fast the car is moving
to set-car-color  ;; turtle procedure
  ifelse speed < (speed-limit / 2)
    [ set color blue ]
    [ set color cyan - 2 ]
end

;; keep track of the number of stopped cars and the amount of time a car has been stopped
;; if its speed is 0
to record-data  ;; turtle procedure
  ifelse speed = 0 [
    set num-cars-stopped num-cars-stopped + 1
    set wait-time wait-time + 1
  ]
  [ set wait-time 0 ]
end

to change-light-at-current-intersection
  ask current-intersection [
    set green-light-up? (not green-light-up?)
    set-signal-colors
  ]
end

;; cycles phase to the next appropriate value
to next-phase
  ;; The phase cycles from 0 to ticks-per-cycle, then starts over.
  set phase phase + 1
  if phase mod ticks-per-cycle = 0 [ set phase 0 ]
end

;; establish goal of driver (house or work) and move to next patch along the way
to-report next-patch
  ;; if I am going home and I am next to the patch that is my home
  ;; my goal gets set to the patch that is my work
  if goal = house and (member? patch-here [ neighbors4 ] of house) [
    set goal work
  ]
  ;; if I am going to work and I am next to the patch that is my work
  ;; my goal gets set to the patch that is my home
  if goal = work and (member? patch-here [ neighbors4 ] of work) [
    set goal house
  ]
  ;; CHOICES is an agentset of the candidate patches that the car can
  ;; move to (white patches are roads, green and red patches are lights)
  let choices neighbors with [ pcolor = white or pcolor = red or pcolor = green ]
  ;; choose the patch closest to the goal, this is the patch the car will move to
  let choice min-one-of choices [ distance [ goal ] of myself ]
  ;; report the chosen patch
  report choice
end

to watch-a-car
  stop-watching ;; in case we were previously watching another car
  watch one-of turtles
  ask subject [

    inspect self
    set size 2 ;; make the watched car bigger to be able to see it

    ask house [
      set pcolor yellow          ;; color the house patch yellow
      set plabel-color yellow    ;; label the house in yellow font
      set plabel "house"
      inspect self
    ]
    ask work [
      set pcolor orange          ;; color the work patch orange
      set plabel-color orange    ;; label the work in orange font
      set plabel "work"
      inspect self
    ]
    set label [ plabel ] of goal ;; car displays its goal
  ]
end

to stop-watching
  ;; reset the house and work patches from previously watched car(s) to the background color
  ask patches with [ pcolor = yellow or pcolor = orange ] [
    stop-inspecting self
    set pcolor 38
    set plabel ""
  ]
  ;; make sure we close all turtle inspectors that may have been opened
  ask turtles [
    set label ""
    stop-inspecting self
  ]
  reset-perspective
end

to label-subject
  if subject != nobody [
    ask subject [
      if goal = house [ set label "house" ]
      if goal = work [ set label "work" ]
    ]
  ]
end


; Copyright 2008 Uri Wilensky.
; See Info tab for full copyright and license.