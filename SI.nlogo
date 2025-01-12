extensions [ vid ]

globals [couleur intervalles_bas intervalles_haut index pathogene-death macrophage-death]

breed [ pathogenes pathogene ]

breed [ macrophages macrophage ]

breed [ lymphocyte_Bs lympocyte_B ]

macrophages-own [ compteur ]

patches-own [c1 c2 c3]

to setup
  clear-all

  if vid:recorder-status = "recording"
    [vid:record-view]

  ask patches with [count neighbors != 8]
    [set pcolor grey]

  set index [0 1 2 3 4 5 6 7 8 9]

  set couleur [19 18 17 16 15 14 13 12 11 black]

  set intervalles_bas [0.001 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9]

  set intervalles_haut [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 100]

  ask patches [
    set pcolor 34
    set c1 0
    set c2 0
    set c3 0]

  reset-ticks
end

to go
  procedure_macrophage

  procedure_lymphocytes

  procedure_pathogenes

  diffusion_c1

  diffusion_c2

  diffusion_c3

  maj_couleur_patches

  tick
end

to procedure_macrophage
  ask macrophages [
    let target one-of pathogenes-here
    ifelse target != nobody and compteur < 70
      [move-to target
      ask target [ die ]
      set compteur (compteur + 1)
      set pathogene-death pathogene-death + 1]

      [ifelse (random 10) <= (5 * (c1 + 0.5))
        [mouvement-aleatoire]

        [chemotaxis_macrophage]]

  if compteur > 3
    [set c2 c2 + 5]

  set c1 (c1 - (conso-c1-macro * c1))
  ]
end

to procedure_lymphocytes
  ask lymphocyte_Bs [
    ifelse (random 10) <= (5 * (c1 + 0.5))
      [mouvement-aleatoire]
      [chemotaxis_lymphocyte_B]
    if c2 >= 0.5 [set c3 c3 + 10]
    set c2 (c2 - (conso-c2-lympho * c2))
  ]
end

to procedure_pathogenes
  ask pathogenes [
    set c1 c1 + 1
    if c3 >= 0.5
      [set pathogene-death pathogene-death + 1
      ask pathogenes-here [die]]
    mouvement-aleatoire
  ]
end

to maj_couleur_patches
  ask patches with [pcolor != grey]
    [foreach index [ [ii] ->
      if c1 > item ii intervalles_bas and c1 <= item ii intervalles_haut
      [set pcolor item ii couleur]
     ]
    if c1 < item 0 intervalles_bas
      [set pcolor 34 ]
    ]
end

to diffusion_c1
  ask patches [
    let fuite (taux_diffusion * c1)
    let cc c1
    let o 0
    ask neighbors
      [if pcolor != grey and c1 < cc
        [ set o (o + 1)]]
    if o != 0
      [set c1 (c1 - fuite)
      ask neighbors
        [if pcolor != grey and c1 < cc
          [set c1 (c1 + (fuite / o))]]
      ]
  ]
end

to diffusion_c2
  ask patches [
    let fuite (taux_diffusion * c2)
    let o 0
    ask neighbors
      [if pcolor != grey
        [set o (o + 1)]]
    if o != 0
      [set c2 (c2 - fuite)]
    ask neighbors
      [if pcolor != grey
        [set c2 (c2 + (fuite / o))]]
  ]
end

to diffusion_c3
  ask patches [
    let fuite (taux_diffusion * c3)
    let o 0
    ask neighbors
      [if pcolor != grey
        [set o (o + 1)]]
      if o != 0
        [set c3 (c3 - fuite)]
      ask neighbors [ if pcolor != grey [set c3 (c3 + (fuite / o))]]
  ]
end

to  chemotaxis_macrophage
  ask macrophages [
    let c_temp 0
    ask neighbors
      [set c_temp (c_temp + c1)]
    ifelse c_temp = 0
      [mouvement-aleatoire]
      [let c_max [0]
      let pxmax [0]
      let pymax [0]
      let k 0
      ask neighbors with [not any? macrophages-here]
      [if c1 > item 0 c_max [
         set c_max replace-item 0 c_max c1
         set pxmax replace-item 0 pxmax pxcor
         set pymax replace-item 0 pymax pycor]
      if c1 = item 0 c_max [
        set k (k + 1)
        set c_max insert-item k c_max c1
        set pxmax insert-item k pxmax pxcor
        set pymax insert-item k pymax pycor
        ]
      ]
      let i_temp random ((length c_max))
      foreach c_max [ [iii] ->
        if (iii) != item 0 c_max [set i_temp 0]
      ]

      ifelse (item i_temp c_max - c1) >= 0.01 and c_max != [0]
        [setxy (item i_temp pxmax) (item i_temp pymax)]
        [mouvement-aleatoire] ;;]

    ]
  ]
end

to  chemotaxis_lymphocyte_B
  ask lymphocyte_Bs [
    let c_temp 0
    ask neighbors [ set c_temp (c_temp + c2)]
    ifelse c_temp = 0
    [set heading random 360
      if patch-ahead 1 != nobody and [pcolor] of patch-ahead 1 != grey[
          forward 1]]
    [ let c_max [0]
      let pxmax [0]
      let pymax [0]
      let k 0
      ask neighbors with [not any? lymphocyte_Bs-here] [
        if c2 > item 0 c_max [
            set c_max replace-item 0 c_max c2
            set pxmax replace-item 0 pxmax pxcor
            set pymax replace-item 0 pymax pycor
        ]
        if c2 = item 0 c_max [
          set k (k + 1)
          set c_max insert-item k c_max c2
          set pxmax insert-item k pxmax pxcor
          set pymax insert-item k pymax pycor
        ]
      ]
      let i_temp random ((length c_max))
      foreach c_max [ [iii] ->
        if (iii) != item 0 c_max [set i_temp 0]
      ]
      ifelse (item i_temp c_max - c2) >= 0.001
      [
      if c_max != [0] [
        setxy (item i_temp pxmax) (item i_temp pymax)
      ]]
      [mouvement-aleatoire]
      ]
    ]
end

to mouvement-aleatoire
  ifelse patch-ahead 1 != nobody and [pcolor] of patch-ahead 1 != grey and random 10 < 5
     [forward 1]
     [set heading random 360]
end

to draw-wall
  if mouse-down?
    [ask patch mouse-xcor mouse-ycor
      [set pcolor grey
       ask neighbors [set pcolor grey
       ask neighbors[set pcolor grey]]
       display ]
    ]
end

to remove-wall-espece
  if mouse-down?
    [ask patch mouse-xcor mouse-ycor
      [ set pcolor 34
        set c1 0
        set c2 0
        set c3 0
        ask neighbors[
          set pcolor 34
          set c1 0
          set c2 0
          set c3 0
          ask neighbors [set pcolor 34
            set c1 0
            set c2 0
            set c3 0]]
          display ]
    ]
end

to draw-walls-hauteur
  if mouse-down?     [
      ask patch mouse-xcor mouse-ycor
        [ let hjk mouse-xcor
          set pcolor grey
          ask neighbors [ask neighbors[ask neighbors[ask neighbors[ask neighbors[ask neighbors[ask neighbors
            [if abs(pxcor - hjk) < 1 [set pcolor grey]]]]]]]]]
     display
    ]
end

to draw-walls-largeur
  if mouse-down?     [
      ask patch mouse-xcor mouse-ycor
        [ let hjk mouse-ycor
          set pcolor grey
          ask neighbors [ask neighbors[ask neighbors[ask neighbors[ask neighbors[ask neighbors[ask neighbors
            [if abs(pycor - hjk) < 1 [set pcolor grey]]]]]]]]]
     display
    ]
end

to mobile-source
  if mouse-down?
    [ask patch mouse-xcor mouse-ycor
      [ set c1 (c1 + value_mobile_source)
        set pcolor item 7 couleur
        ask neighbors [
            set c1 (c1 + value_mobile_source)
            set pcolor item 7 couleur]
          ]
        display
    ]
end

to put-pathogenes
  if mouse-down? [
  create-pathogenes quantite-turtle-mobile [
    setxy mouse-xcor mouse-ycor
    set shape "pathogen"
    set size 20
    ]
  display]
end

to put-macrophages
  if mouse-down? [
  create-macrophages quantite-turtle-mobile [
    setxy mouse-xcor mouse-ycor
    set shape "macrophage"
    set size 20
    set compteur 0
    ]
  display]
end

to put-lymphocyte_Bs
  if mouse-down? [
  create-lymphocyte_Bs quantite-turtle-mobile [
    setxy mouse-xcor mouse-ycor
    set shape "lymphocyte"
    set size 20
    ]
  display]
end

to start-recorder
  carefully [ vid:start-recorder ] [ user-message error-message ]
end

to reset-recorder
  let message (word
    "If you reset the recorder, the current recording will be lost."
    "Are you sure you want to reset the recorder?")
  if vid:recorder-status = "inactive" or user-yes-or-no? message [
    vid:reset-recorder
  ]
end

to save-recording
  if vid:recorder-status = "inactive" [
    user-message "The recorder is inactive. There is nothing to save."
    stop
  ]
  user-message (word
    "Choose a name for your movie file (the "
    ".mp4 extension will be automatically added).")
  let path user-new-file
  if not is-string? path [ stop ]
  carefully [
    vid:save-recording path
    user-message (word "Exported movie to " path ".")
  ] [
    user-message error-message
  ]
end

@#$#@#$#@
GRAPHICS-WINDOW
207
10
668
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
0
0
1
ticks
30.0

BUTTON
18
33
102
66
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

BUTTON
1132
421
1216
454
NIL
setup
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
18
257
140
290
wall
draw-wall
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
18
294
140
327
remove wall
remove-wall-espece
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
18
220
140
253
attractant
mobile-source
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
18
331
140
364
wall height
draw-walls-hauteur
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
18
369
140
402
wall width
draw-walls-largeur
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
18
183
141
216
lymphocyte
put-lymphocyte_Bs
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
18
109
141
142
pathogene
put-pathogenes
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
18
146
141
179
macrophage
put-macrophages
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
707
31
879
64
conso-c1-macro
conso-c1-macro
0
1
0.7
0.05
1
NIL
HORIZONTAL

SLIDER
706
69
879
102
conso-c2-lympho
conso-c2-lympho
0
1
0.3
0.05
1
NIL
HORIZONTAL

SLIDER
707
184
879
217
taux_diffusion
taux_diffusion
0
1
0.8
0.05
1
NIL
HORIZONTAL

SLIDER
707
145
879
178
value_mobile_source
value_mobile_source
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
707
107
879
140
quantite-turtle-mobile
quantite-turtle-mobile
0
100
25.0
1
1
NIL
HORIZONTAL

TEXTBOX
7
10
87
29
Menu :
15
0.0
1

TEXTBOX
6
30
21
68
|\n|\n
15
0.0
1

TEXTBOX
7
83
157
102
Agents :
15
0.0
1

TEXTBOX
6
103
21
407
|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n
15
0.0
1

TEXTBOX
692
10
842
29
Parameters :
15
0.0
1

TEXTBOX
692
27
707
236
|\n|\n|\n|\n|\n|\n|\n|\n|\n|
15
0.0
1

MONITOR
704
300
789
345
record status
vid:recorder-status
3
1
11

TEXTBOX
691
235
841
254
Recorder :
15
0.0
1

BUTTON
705
260
790
293
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
798
260
884
293
reset record
reset-recorder
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
798
304
884
337
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

TEXTBOX
691
253
706
367
|\n|\n|\n|\n|
15
0.0
1

TEXTBOX
689
364
839
383
Commands :
15
0.0
1

TEXTBOX
691
383
706
421
|\n|\n
15
0.0
1

BUTTON
703
386
791
419
pen down
pen-down
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
802
386
884
419
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
549
268
699
286
Lymph Node
11
0.0
1

TEXTBOX
307
98
457
116
Injury site
11
0.0
1

@#$#@#$#@
## WHAT IS IT?

This model reproduce a simple immune system.


## HOW IT WORKS

There is 3 breeds :

- Pathogens : They spread randomly and diffuse a chemoattractant for macropages.

- Macrophages : They spread randomly and they are attracted by pathogen's chemoattractant, they kill pathogens and then spread a chemoattractant for lympohcytes.

- Lymphocytes : They spread randomly and are attracted by the chemoattractant diffused by macrophages, they reach injury site from the node and then they spread a killing species that represents antibodies in it.


## HOW TO USE IT

You can use our wall patches to recreate compartment of the bodies (injury site, lymph node).

## THINGS TO TRY/NOTICE

Try to reproduce a "human body" and let the model run, play with the parameters.

## EXTENDING THE MODEL

You could try to add breed to be more precise.


## CREDITS AND REFERENCES

SCALABRINO Morgan, Université côte d'Azur, DL3 Maths-SV
BALDOUS Jules, Univsersité côte d'Azur, DL3 Maths-SV
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

lymphocyte
true
0
Line -7500403 true 150 120 150 90
Circle -7500403 true true 135 60 30
Line -7500403 true 180 135 210 105
Circle -7500403 true true 195 90 30
Line -7500403 true 90 105 120 135
Circle -7500403 true true 75 90 30
Line -7500403 true 120 150 90 165
Circle -7500403 true true 60 150 30
Line -7500403 true 135 180 120 210
Circle -7500403 true true 105 195 30
Line -7500403 true 165 180 180 225
Circle -7500403 true true 165 210 30
Line -7500403 true 180 165 225 180
Circle -7500403 true true 210 165 30
Circle -13345367 true false 108 108 85

macrophage
true
0
Circle -11221820 true false 123 93 85
Circle -11221820 true false 118 88 32
Circle -11221820 true false 120 165 30
Circle -11221820 true false 195 120 30
Circle -11221820 true false 180 105 30
Circle -11221820 true false 165 90 30
Circle -11221820 true false 150 75 30
Circle -11221820 true false 135 75 30
Circle -11221820 true false 105 150 30
Circle -11221820 true false 180 90 30
Circle -11221820 true false 135 165 30
Circle -11221820 true false 165 165 30
Circle -11221820 true false 180 150 30
Circle -11221820 true false 195 135 30
Circle -11221820 true false 165 150 30
Circle -11221820 true false 120 75 28
Circle -11221820 true false 105 90 28
Circle -11221820 true false 165 75 28
Circle -11221820 true false 195 105 28

pathogen
true
0
Rectangle -1184463 true false 135 90 165 150
Circle -1184463 true false 165 150 0

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
