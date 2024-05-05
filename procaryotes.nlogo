;;Extension : "vid" to make movies
extensions [ vid ]

;;Global variables : "colour" to represent chemoattractant, "tumble" to make movement of bacteria, "fuite" to make chemoattractant diffuse, "i_low" lower bound for concentration of chemoattractant, "i_up" upper bound for concentration of chemoattractant, "index" for colours
globals [colour i_low i_up index tumble fuite compteur_run compteur_tumble]

;;Breed : "bacteria" represent all the turtles, "bacterium" is one of the turtles
breed [ bacteria bacterium ]

;;Patches variables : "c" is the concentration of chemoattractant on each patch, "source" is a boolean to put a constant source of chemoattractant
patches-own [c source]

;;Setup Procedure :
to setup
  ;;Reset the world :
  clear-all
  reset-ticks

  ;;Vid extension :
  if vid:recorder-status = "recording"
    [vid:record-view]

  ;;Set the background to brown :
  ask patches
    [set pcolor 34]

  ;;Create walls around the world to prevent bacteria from escaping :
  ask patches with [count neighbors != 8]
    [set pcolor grey]

  ;;Set a list of index :
  set index [0 1 2 3 4 5 6 7 8 9]

  ;;Set a list of color for the chemoattractant :
  set colour [19 18 17 16 15 14 13 12 11 121]

  ;;Set a list for lower bound, to link concentration of chemoattractant to coulour :
  set i_low [0.001 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9]

  ;;Set a list for upper bound, to link concentration of chemoattractant to coulour :
  set i_up [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 100]

  ;;Initialise a variable for tumbling to false :
  set tumble True

  set compteur_tumble 1

  set compteur_run 1
end

;;Go Procedure :
to go
  ;;Bacteria evolution :
  ask bacteria
    [bacteria-movement]

  ;;Patches evolution :
  ask patches
    [evolution-patches]

  ;;Patches of Chemoattractant evolution :
  maj_patches_colour

  ;;Video Extension
  if vid:recorder-status = "recording"
    [vid:record-view]

  ;;We tick :
  tick
end

;CREATION PROCEDURES :

;;Command to create bacteria on the coordinates specified by the mouse
to put-turtle-mouse
  if mouse-down?
    [create-bacteria 1
      [setxy mouse-xcor mouse-ycor
      set shape "bacteria_not_tumbling"
      set color 85
      set size 20]
    ]
end

;;Command to create source of attractant :
to source-mouse
  if mouse-down?
    [ask patch mouse-xcor mouse-ycor
      [;;We place "value_source" of attractant on the case :
      set c (c + value_source)

      ;;If we switch source_cst to "On" we renew the quantity of attractant on the source :
      if source_cst = true
        [set source true
        ask neighbors
          [set source true]
        ]

      ;;We change the color of the patch :
      set pcolor item 4 colour

      ;;Whe also put attractant on the neighbors :
      ask neighbors
        [set c (c + value_source)
        set pcolor item 4 colour]
        display
      ]
    ]
end

;WALL PROCEDURES :

;;Command to draw wall :
to draw-wall
  if mouse-down?
    [ask patch mouse-xcor mouse-ycor
        [set pcolor grey

        ;;We ask also the neighbors to be walls :
        ask neighbors
          [ask neighbors
             [set pcolor grey]
             display
          ]
        ]
    ]
end

;;Command to remove wall :
to remove-wall
  if mouse-down?
    [ask patch mouse-xcor mouse-ycor
      [set pcolor 34
      set c 0

      ;;We also remove wall around :
      ask neighbors
        [set pcolor 34
        set c 0]
        display
      ]
    ]
end

;;Command to draw maze easily :
to draw-walls-height
  if mouse-down?
    [ask patch mouse-xcor mouse-ycor
      [let cord mouse-xcor
      set pcolor grey
      ask neighbors
        [ask neighbors
          [ask neighbors
            [ask neighbors
              [ask neighbors
                [ask neighbors
                  [ask neighbors
                    [if abs(pxcor - cord) < 1
                      [set pcolor grey]]]]]]]]
      display]
    ]
end

;;Command to draw maze easily :
to draw-walls-width
  if mouse-down?
    [ask patch mouse-xcor mouse-ycor
      [let cord mouse-ycor
      set pcolor grey
      ask neighbors
        [ask neighbors
          [ask neighbors
            [ask neighbors
              [ask neighbors
                [ask neighbors
                  [ask neighbors
                    [if abs(pycor - cord) < 1
                      [set pcolor grey]]]]]]]]
      display]
    ]
end

;MOVEMENT PROCEDURES :

;;Procedure for bacteria movement :
to bacteria-movement
  ;;If the patch ahead is nobody (the limit of the world) or grey (the patch color that represents walls in our model) we turn in a random direction, else we move :
  ifelse [pcolor] of patch-ahead 1 = grey
     ;;Turn in a random direction :
     [lt random-float 360]

     ;;Biaised movement relative to concentration :
     [;;"c_devant" is the concentration of the patch ahead the bacterium :
     let c_devant 0
     ask patch-ahead 1
       [set c_devant c]

     ;;"diff" is the difference between the concentration ahead and the concentration where the bacterium is :
     let diff (c_devant - c)

     ;;We can change the sensitivity of the bacteria : Sensitivity has been mesured by the observed fact that bacteria can go up exponential gradient and it
     ;;imply that they can spot differences about 0.0001%
     ifelse diff > 0.000001
       [run-tumble-biaised]
       [run-tumble]
     ]

end

;;Command that represent the run-and-tumble movement of the bacteria (if there is not enough attractant) :
to run-tumble
  ;;If tumble is true we tumble and then we run, we have 3/10 chance to tumble when we are on a run phase :
  ifelse tumble
    ;;Tumbling :
    [set shape "bacteria_tumbling"
    set compteur_tumble compteur_tumble + 1
    set heading random 360
    set tumble False]

    ;;Run :
    [set shape "bacteria_not_tumbling"
    ifelse random 100 <= 20
      [set tumble True]
      [forward 1
      set compteur_run compteur_run + 1]
    ]
end

;;Command that represent the biaised movement of bacteria in response to attractant :
to run-tumble-biaised
  ;;If tumble is true we tumble and then we run, we have 1/10 chance to tumble when we are on a run phase --> the movement is then biaised :
  ifelse tumble
    ;;Tumbling :
    [set shape "bacteria_tumbling"
    set heading random 360
    set compteur_tumble compteur_tumble + 1
    set tumble False]

    ;;Run phase are longer :
    [set shape "bacteria_not_tumbling"
    ifelse random 100 <= 1
      [set tumble True]
      [forward 1
      set compteur_run compteur_run + 1]
    ]
end

;PATCHES PROCEDURE :

;;Procedure to evolve patches :
to evolution-patches
  ;;We set "fuite" as the quantity of attractant that will leave the patch, "diffusion" is a parameter (slider) that ponderate the quantitity of attractant :
  set fuite (diffusion * c)

  ;;"number_case" is the number of cases that aren't grey (not walls), we set at 0 :
  let number_case 0

  ;;Analyse the number of case that aren't grey :
  ask neighbors
    [
    if pcolor != grey
      [set number_case (number_case + 1)]
    ]

  ;;We substract the amount of attractant that leave the patch to the concentration of the patch :
  if number_case != 0
    [set c (c - fuite)]

  ;;If the color is not grey we diffuse the amount of attractant divide by the number of case on wich we can diffuse (those who aren't grey) :
  ask neighbors
    [
    if pcolor != grey
      [set c (c + (fuite / number_case))]
    ]

  ;;If we switch source_cst to "On" we renew the quantity of attractant on the source :
  if source = true
    [set c c + 1]
end


;;Procedure to update the colour of the patches :
to maj_patches_colour
  ask patches with [pcolor != grey]
    [
    foreach index [[i] ->
        if c > item i i_low and c <= item i i_up
          [set pcolor item i colour]
      ]
    if c < item 0 i_low
      [set pcolor 34]
    ]
end

;VIDEO PROCEDURES :

;;Video Extension : Taken from the "Movie Recording Example" model available on NetLogo Library :
to start-recorder
  carefully [ vid:start-recorder ] [ user-message error-message ]
end

;;Video Extension : Taken from the "Movie Recording Example" model available on NetLogo Library :
to reset-recorder
  let message (word
    "If you reset the recorder, the current recording will be lost."
    "Are you sure you want to reset the recorder?")
  if vid:recorder-status = "inactive" or user-yes-or-no? message [
    vid:reset-recorder
  ]
end

;;Video Extension : Taken from the "Movie Recording Example" model available on NetLogo Library :
to save-recording
  if vid:recorder-status = "inactive" [
    user-message "The recorder is inactive. There is nothing to save."
    stop
  ]
  ;;Prompt user for movie location
  user-message (word
    "Choose a name for your movie file (the "
    ".mp4 extension will be automatically added).")
  let path user-new-file
  if not is-string? path [ stop ]  ;;Stop if user canceled
  ;;Export the movie
  carefully [
    vid:save-recording path
    user-message (word "Exported movie to " path ".")
  ] [
    user-message error-message
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
208
10
669
472
-1
-1
3.0
1
10
1
1
1
0
0
0
1
-75
75
-75
75
1
1
1
ticks
30.0

BUTTON
20
103
132
136
agent
put-turtle-mouse\n
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
113
32
196
65
NIL
setup\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
21
32
105
65
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
19
437
191
470
diffusion
diffusion
0
1
0.0
0.05
1
NIL
HORIZONTAL

SLIDER
19
399
191
432
value_source
value_source
0
10
1.0
1
1
NIL
HORIZONTAL

BUTTON
20
140
131
173
attractant
source-mouse\n\n
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
20
215
131
248
remove wall
remove-wall\n
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
20
177
131
210
wall
draw-wall\n
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
19
361
135
394
source_cst
source_cst
0
1
-1000

BUTTON
705
203
792
236
pen down
pen-down\n
NIL
1
T
TURTLE
NIL
NIL
NIL
NIL
1

BUTTON
703
33
790
66
record
start-recorder
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
799
32
891
65
reset record
reset-recorder\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
703
75
791
108
save record
save-recording
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
703
116
792
161
record status
vid:recorder-status
3
1
11

TEXTBOX
691
10
765
28
Recorder :\n
15
0.0
1

TEXTBOX
5
338
92
356
Parameters :
15
0.0
1

TEXTBOX
6
10
62
28
Menu :\n
15
0.0
1

TEXTBOX
692
180
780
198
Commands :\n
15
0.0
1

TEXTBOX
6
79
70
97
Agents :\n
15
0.0
1

TEXTBOX
691
199
706
313
|\n|\n|\n|\n\n
15
0.0
1

TEXTBOX
691
31
706
164
|\n|\n|\n|\n|\n|\n|\n
15
0.0
1

BUTTON
705
241
791
274
pen up
pen-up
NIL
1
T
TURTLE
NIL
NIL
NIL
NIL
1

TEXTBOX
5
98
20
345
|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n\n
15
0.0
1

TEXTBOX
6
28
21
66
|\n|
15
0.0
1

TEXTBOX
4
357
19
490
|\n|\n|\n|\n|\n|\n\n
15
0.0
1

BUTTON
20
253
131
286
wall width
draw-walls-width
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
20
291
131
324
wall height
draw-walls-height
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

This model reproduce the chemotactic behavior of E. coli.

## HOW IT WORKS

A chemoattractant diffuse, an agent breed of bacteria spreads randomly by a run-and-tumble mechanism. In presence of the chemoattractant they biased they walk toward it.

## HOW TO USE IT

You can record videos, place walls, attractant and agents. You can change parameters of the model with the sliders.

## CREDITS AND REFERENCES

SCALABRINO Morgan, Université côte d'Azur, DL3 Maths-SV.
BALDOUS Jules, Université côte d'Azur, DL3 Maths-SV.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

bacteria_not_tumbling
true
0
Circle -11221820 true false 150 120 0
Circle -11221820 true false 129 84 42
Circle -11221820 true false 129 99 42
Circle -11221820 true false 129 114 42
Line -11221820 false 150 150 135 180
Line -11221820 false 150 135 150 180
Line -11221820 false 135 135 165 180
Line -11221820 false 150 150 165 195
Line -11221820 false 150 135 135 195

bacteria_tumbling
true
0
Circle -11221820 false false 129 84 42
Circle -11221820 true false 129 84 42
Circle -11221820 true false 129 99 42
Circle -11221820 true false 129 114 42
Line -11221820 false 120 150 135 135
Line -11221820 false 135 150 120 180
Line -11221820 false 150 150 150 180
Line -11221820 false 165 135 180 180
Line -11221820 false 135 135 210 150
Line -11221820 false 135 135 90 150
Line -11221820 false 105 135 150 120
Line -11221820 false 165 120 210 135

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

priest
true
0
Circle -11221820 true false 8 8 285
Circle -16777216 true false 120 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 180 255 120 239 92 213 77 191 97 179 120 203 139 218 180 225 222 218 240 203 257 181 281 194 266 217 242 240
Polygon -2674135 true false 30 285 30 135 0 135 0 105 30 105 30 75 60 75 60 105 60 105 90 105 90 135 60 135 60 285 30 285
Polygon -1 true false 15 60 285 60 270 30 270 0 30 0 30 30 15 60
Polygon -1 true false 135 60
Polygon -2674135 true false 135 60 135 60 135 30 135 30 120 30 120 15 135 15 135 15 135 0 150 0 150 15 165 15 165 30 165 30 150 30 150 60 135 60

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
