globals [
  level
  equalResist
  end-found?
  closed-path
  yourResist
  recent-node
  target-current
  voltageSet
  yourCurrent
  is-sat?
]

breed[resistors resistor]
breed[batteries battery]
breed[joints joint]
undirected-link-breed[wires wire]
directed-link-breed[currents current]

resistors-own[resist]

currents-own[valid?]


to clean-up
  if length closed-path >= 1
  [
    foreach closed-path
    [
      x -> ask x
      [
        set valid? 1
      ]
    ]

  ask turtles
    [

      ask my-currents
      [
        if not (valid? = 1)

        [
          let node other-end
          ask myself
        [
            create-wire-with node
          ]
          die
      ]
      ]
  ]
  ]
end

to undirect
  ask currents [die]
end

to direct
  set end-found? false
  let node one-of batteries

  let stop-node one-of batteries
  let n-list []
  set closed-path []

  ask node
  [
    let neib one-of wire-neighbors
    create-current-to neib
    set n-list lput (current-with neib) n-list
    ask wire-with neib [die]
    set node neib
  ]


  direct_helper node stop-node node n-list
  clean-up

  let joint-list []
  ask joints with [count my-currents > 0]
  [
   set joint-list lput self joint-list
  ]
  ask resistors with [count my-currents > 0]
  [
    set joint-list lput self joint-list
  ]
  foreach joint-list
  [
    x -> ask x
    [
      set closed-path []
      set n-list []
      set end-found? false
      show self
      direct_helper self stop-node self n-list
    ]
    clean-up
  ]
  show closed-path

end



to direct_helper [node stop-node start-node n-list]

  ifelse node = stop-node
  [
    set end-found? true
    set closed-path n-list
  ]
  [


    ask node
      [
        if (count my-currents with [not (valid? = 1)]) <= 1
        [



          ask wire-neighbors
            [
              if not end-found?
              [
                create-current-from node
                set n-list lput (current-with node) n-list
                ask wire-with node [die]
                if not (self = start-node)
                [
                  direct_helper self stop-node start-node n-list
                ]
                if not end-found?
                [
                  set n-list but-last n-list
                ]
              ]
          ]


          ask my-out-currents with [valid? = 1]
          [
            if not end-found?
            [
              set n-list lput self n-list
              if not (other-end = start-node)
              [
                direct_helper other-end stop-node start-node n-list
              ]
              if not end-found?
              [
                set n-list but-last n-list
              ]
            ]

          ]






        ]
    ]



  ]

end

to calculate-resistance
  let node one-of batteries
  set yourResist 0
  ask node
  [
    let neib one-of out-current-neighbors
    set node neib
  ]

  set yourResist res_helper node 0
  show yourResist
end

to calculate-current
  set yourCurrent voltage / yourResist
  show voltage
  show yourCurrent
end

;;for this function to work, joints can have no more than three currents attatched to them, so lets make sure that condition is met as soon as the user is done
to-report res_helper [node equi-res]
  let fork 0
  ask node
  [
    set fork count my-in-currents
  ]

  while [ (not (is-battery? node)) and (not (fork > 1))]
  [
    let temp-res 0
    if is-resistor? node
    [
      set equi-res (equi-res + ([resist] of node))
    ]

    ask node
    [
      ifelse (count out-current-neighbors) = 1
      [
        set node one-of out-current-neighbors

      ]
      [
          ask out-current-neighbors
          [
            set temp-res (temp-res + (1 / (res_helper self 0)))
          ]
          set equi-res (equi-res + (1 / temp-res))

          ask recent-node
          [
            set node one-of out-current-neighbors
          ]

      ]


    ]
    ask node
    [
      set fork count my-in-currents
    ]

  ]
  set recent-node node
  report equi-res


end




to start-game
  user-message ["Hello, please refer to info if you don't know the rules"]
  clear-all
  reset-ticks
  set-default-shape resistors "resistor"
  set-default-shape batteries "battery"
  set-default-shape joints "circle"

  ask patches [ set pcolor white ]      ;; plain white background
  set level 1
  create-batteries 1 [
   set color blue
   set size 5
   setxy 10 10
  ]

  if difficulty = "easy" [ calAmps-easy]
  if difficulty = "medium" [ calAmps-medium]
  if difficulty = "hard"[ calAmps-hard]
end

to reset
  ask resistors [die]
  ask joints [die]
  reset-ticks
end

to add-resistor
  create-resistors 1 [
   set color red
   set size 3
   set resist resistance
   setxy random-xcor random-ycor
  ]
end

to add-joint
  create-joints 1[
   set color black
   set size .5
   setxy random-xcor random-ycor
  ]
end



to connect
 if any? other turtles-here [
    create-wire-with one-of other turtles-here
 ]
end

to satisfies-rules?

  ask batteries
  [
    ifelse not (count my-wires = 2)
    [
      set is-sat? false
    ]
    [set is-sat? true]
  ]

  ask resistors
    [
      ifelse not (count my-wires = 2)

      [

        set is-sat? false
      ]
      [set is-sat? true]
  ]

  ask joints
  [
    if not ((count my-wires = 2) or (count my-wires = 3))
    [
      set is-sat? false
    ]


  ]
  if not is-sat?
  [
  user-message (word "Sorry, the battery and resistors must have exactly 2 wires, and joints must have exactly 2 or 3 wires.")
  ]
end

to go
  ;if (ticks = 0) and (difficulty = "easy") [ calAmps-easy]
  ;if (ticks = 0) and difficulty = "medium"[ calAmps-medium]
  ;if (ticks = 0) and difficulty = "hard"[ calAmps-hard]

  if mouse-down? [
    let grabbed min-one-of turtles [distancexy mouse-xcor mouse-ycor]
    while [mouse-down?] [
      ask turtles[
        connect
      ]
      ask grabbed [ setxy mouse-xcor mouse-ycor ]
      display
    ]
  ]
  tick
end

to calAmps-easy
  set voltageSet [20 30 40]
  let emf one-of voltageSet
  let chance random 2
  if chance = 0 [two-resistors]
  if chance = 1 [three-resistors]
  ;set target-current emf / equalResist
  set target-current 5 / 3
end

to calAmps-medium
  set voltageSet [20 30 40]
  let emf one-of voltageSet
  let chance random 2
  if chance = 0 [four-resistors]
  if chance = 1 [five-resistors]
  ;set target-current emf / equalResist
  set target-current 40 / (103 / 9)
end

to calAmps-hard
  set voltageSet [20 30 40]
  let emf one-of voltageSet
  let chance random 2
  if chance = 0 [six-resistors]
  if chance = 1 [seven-resistors]
  ;set target-current emf / equalResist
  set target-current 40 / (51 / 4)
end

to two-resistors
  let resistValue [5 7 8]
  let tempResist1 one-of resistValue
  let tempResist2 one-of resistValue
  let chooser random 2
  if chooser = 0 [
    resistance-series tempResist1 tempResist2
  ]
  if chooser = 1 [
    resistance-parallel tempResist1 tempResist2
  ]
end

to three-resistors
  two-resistors
  let resistValue [5 7 8]
  let tempResist3 one-of resistValue
  let chooser random 2
  if chooser = 0 [ resistance-series equalResist tempResist3 ]
  if chooser = 1 [ resistance-parallel equalResist tempResist3]
end

to four-resistors
  three-resistors
  let resistValue [5 7 8]
  let tempResist4 one-of resistValue
  let chooser random 2
  if chooser = 0 [ resistance-series equalResist tempResist4 ]
  if chooser = 1 [ resistance-parallel equalResist tempResist4]
end

to five-resistors
  four-resistors
  let resistValue [5 7 8]
  let tempResist5 one-of resistValue
  let chooser random 2
  if chooser = 0 [ resistance-series equalResist tempResist5 ]
  if chooser = 1 [ resistance-parallel equalResist tempResist5]
end

to six-resistors
  five-resistors
  let resistValue [5 7 8]
  let tempResist6 one-of resistValue
  let chooser random 2
  if chooser = 0 [ resistance-series equalResist tempResist6 ]
  if chooser = 1 [ resistance-parallel equalResist tempResist6]
end

to seven-resistors
  six-resistors
  let resistValue [5 7 8]
  let tempResist7 one-of resistValue
  let chooser random 2
  if chooser = 0 [ resistance-series equalResist tempResist7 ]
  if chooser = 1 [ resistance-parallel equalResist tempResist7]
end

to resistance-parallel [equalResist1 equalResist2]
  set equalResist 1 / (1 / equalResist1 + 1 / equalResist2)
end

to resistance-series [equalResist1 equalResist2]
  set equalResist equalResist1 + equalResist2
end

to check
  ifelse abs ( yourCurrent - target-current) <= .1 [
  user-message (word "Congrats buddy you rock")
  ]
  [user-message (word "That doesn't work, your wires will be deleted. Click go again to continue.")]
end
@#$#@#$#@
GRAPHICS-WINDOW
211
83
573
446
-1
-1
10.73
1
10
1
1
1
0
0
0
1
-16
16
-16
16
0
0
1
ticks
30.0

CHOOSER
600
159
738
204
voltage
voltage
20 30 40
2

BUTTON
17
26
130
70
NIL
start-game
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
16
135
114
168
NIL
add-resistor
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
19
78
82
111
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

CHOOSER
599
104
737
149
resistance
resistance
5 7 8
2

BUTTON
16
178
97
211
NIL
add-joint
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
599
46
737
91
difficulty
difficulty
"easy" "medium" "hard"
2

BUTTON
16
229
86
262
Check
satisfies-rules?\nif(is-sat?)\n[\ndirect\ncalculate-resistance\ncalculate-current\ncheck\nundirect\n]\nset is-sat? true
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
142
25
247
70
Target Current
target-current
2
1
11

BUTTON
95
79
158
112
NIL
reset\n
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
272
25
367
70
Your Current
yourCurrent
17
1
11

@#$#@#$#@
## WHAT IS IT?

This is a drag-and-drop circuit puzzle, where the user has to select resistors to build a circuit that satisfies the given current. 

## HOW IT WORKS

There are three levels of difficulty to this game: easy, medium, and hard. The users will be able to choose the level they prefer before starting a game. For each level, varying numbers of resistors with different resistance will have to be incorporated into a circuit by the user to achieve a certain, specified current. With each new level, a random target current is calculated based on the difficulty specification of the user.  The user can select resistors with different resistance and different battery voltages to meet the specified current. 

## HOW TO USE IT

Difficulty chooser: allows the user to choose which level they want to play.

Resistance chooser: allows the user to choose the resistance of the resistor that will be added.

Voltage chooser: allows the user to choose the voltage of the battery in the circuit.

Start-game: sets up the game and displays the target current.

Go: allows the user to connect different elements of the circuits. A link will be formed between two elements by dragging one element to touch the other element.

Reset: clear all added elements of the circuit (resistors and joints).

Add-resistor: allows the user to add a resistor to the circuit, from which exactly two connections can be formed.

Add-joint: allows the user to add a joint to the circuit, from which two or three connections can be formed.

Check: checks to see if the circuit built by the user satisfies the rules of this game, and calculates the current in the circuit, displaying a winning message if it is within 0.1 of the target current.

## THINGS TO NOTICE

The user will never have to have more than two resistors directly in parallel with each other.

The project is just as much a current calculator as it is anything else; even if it is not used as a game (because the game is too hard) it can be used for that purpose.
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

battery
true
0
Circle -16777216 true false -4 -4 309
Line -7500403 true 0 150 120 150
Line -7500403 true 135 105 135 195
Line -7500403 true 165 60 165 240
Line -7500403 true 180 150 300 150
Line -7500403 true 120 150 135 150
Line -7500403 true 180 150 165 150

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

resistor
true
0
Circle -16777216 true false -4 -4 309
Polygon -7500403 false true 300 150 240 150 225 105 210 195 195 105 180 195 165 105 150 195 135 105 120 195 105 105 90 195 75 150 0 150

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
NetLogo 6.1.0
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
