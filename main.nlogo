__includes["bus.nls" "stop.nls" "people.nls" ]

globals [
    width
    height
    offset
    busX
    busY
    wallColor
    doorColor
    floorColor
    g_bus
]

patches-own [
    occupied?
]

to setup

    clear-all

    set width 50
    set height 50
    set offset 10

    ask patches [
        set occupied? false
    ]

    show "picus"
    setup_bus

    reset-ticks
end

to go


    ask buses [
        bus_tick
    ]

    ask people [
        person_tick
    ]


    tick
end

to-report mapX [x]
    report min-pxcor + offset + x
end

to-report mapY [y]
    report min-pycor + offset + ([ b_w ] of g_bus) - y
end

