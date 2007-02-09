# plotaxis.tcl --
#    Facilities to draw simple plots in a dedicated canvas
#
# Note:
#    This source file contains the functions for drawing the axes
#    and the legend. It is the companion of "plotchart.tcl"
#

# DrawYaxis --
#    Draw the y-axis
# Arguments:
#    w           Name of the canvas
#    ymin        Minimum y coordinate
#    ymax        Maximum y coordinate
#    ystep       Step size
# Result:
#    None
# Side effects:
#    Axis drawn in canvas
#
proc ::Plotchart::DrawYaxis { w ymin ymax ydelt } {
    variable scaling

    set scaling($w,ydelt) $ydelt

    $w delete yaxis

    $w create line $scaling($w,pxmin) $scaling($w,pymin) \
                   $scaling($w,pxmin) $scaling($w,pymax) \
                   -fill black -tag yaxis

    set format ""
    if { [info exists scaling($w,-format,y)] } {
        set format $scaling($w,-format,y)
    }

    set y $ymin
    set scaling($w,yaxis) {}

    while { $y < $ymax+0.5*$ydelt } {

        foreach {xcrd ycrd} [coordsToPixel $w $scaling($w,xmin) $y] {break}

        lappend scaling($w,yaxis) $ycrd

        set ylabel $y
        if { $format != "" } {
            set ylabel [format $format $y]
        }
        $w create text $xcrd $ycrd -text $ylabel -tag yaxis -anchor e
        set y [expr {$y+$ydelt}]
        if { abs($y) < 0.5*$ydelt } {
            set y 0.0
        }
    }
}

# DrawXaxis --
#    Draw the x-axis
# Arguments:
#    w           Name of the canvas
#    xmin        Minimum x coordinate
#    xmax        Maximum x coordinate
#    xstep       Step size
# Result:
#    None
# Side effects:
#    Axis drawn in canvas
#
proc ::Plotchart::DrawXaxis { w xmin xmax xdelt } {
    variable scaling

    set scaling($w,xdelt) $xdelt

    $w delete xaxis

    $w create line $scaling($w,pxmin) $scaling($w,pymax) \
                   $scaling($w,pxmax) $scaling($w,pymax) \
                   -fill black -tag xaxis

    set format ""
    if { [info exists scaling($w,-format,x)] } {
        set format $scaling($w,-format,x)
    }

    set x $xmin
    set scaling($w,xaxis) {}

    while { $x < $xmax+0.5*$xdelt } {

        foreach {xcrd ycrd} [coordsToPixel $w $x $scaling($w,ymin)] {break}

        lappend scaling($w,xaxis) $xcrd

        set xlabel $x
        if { $format != "" } {
            set xlabel [format $format $x]
        }
        $w create text $xcrd $ycrd -text $xlabel -tag xaxis -anchor n
        set x [expr {$x+$xdelt}]
        if { abs($x) < 0.5*$xdelt } {
            set x 0.0
        }
    }

    set scaling($w,xdelt) $xdelt
}

# DrawXtext --
#    Draw text to the x-axis
# Arguments:
#    w           Name of the canvas
#    text        Text to be drawn
# Result:
#    None
# Side effects:
#    Text drawn in canvas
#
proc ::Plotchart::DrawXtext { w text } {
    variable scaling

    set xt [expr {($scaling($w,pxmin)+$scaling($w,pxmax))/2}]
    set yt [expr {$scaling($w,pymax)+12}]

    $w create text $xt $yt -text $text -fill black -anchor n
}

# DrawYtext --
#    Draw text to the y-axis
# Arguments:
#    w           Name of the canvas
#    text        Text to be drawn
# Result:
#    None
# Side effects:
#    Text drawn in canvas
#
proc ::Plotchart::DrawYtext { w text } {
    variable scaling

    set xt $scaling($w,pxmin)
    set yt [expr {$scaling($w,pymin)-8}]

    $w create text $xt $yt -text $text -fill black -anchor se
}

# DrawPolarAxes --
#    Draw thw two polar axes
# Arguments:
#    w           Name of the canvas
#    rad_max     Maximum radius
#    rad_step    Step in radius
# Result:
#    None
# Side effects:
#    Axes drawn in canvas
#
proc ::Plotchart::DrawPolarAxes { w rad_max rad_step } {

    #
    # Draw the spikes
    #
    set angle 0.0

    foreach {xcentre ycentre} [polarToPixel $w 0.0 0.0] {break}

    while { $angle < 360.0 } {
        foreach {xcrd ycrd} [polarToPixel $w $rad_max $angle] {break}
        foreach {xtxt ytxt} [polarToPixel $w [expr {1.05*$rad_max}] $angle] {break}
        $w create line $xcentre $ycentre $xcrd $ycrd
        if { $xcrd > $xcentre } {
            set dir w
        } else {
            set dir e
        }
        $w create text $xtxt $ytxt -text $angle -anchor $dir

        set angle [expr {$angle+30}]
    }

    #
    # Draw the concentric circles
    #
    set rad $rad_step

    while { $rad < $rad_max+0.5*$rad_step } {
        foreach {xright ytxt}    [polarToPixel $w $rad    0.0] {break}
        foreach {xleft  ycrd}    [polarToPixel $w $rad  180.0] {break}
        foreach {xcrd   ytop}    [polarToPixel $w $rad   90.0] {break}
        foreach {xcrd   ybottom} [polarToPixel $w $rad  270.0] {break}

        $w create oval $xleft $ytop $xright $ybottom

        $w create text $xright [expr {$ytxt+3}] -text $rad -anchor n

        set rad [expr {$rad+$rad_step}]
    }
}

# DrawXlabels --
#    Draw the labels to an x-axis (barchart)
# Arguments:
#    w           Name of the canvas
#    xlabels     List of labels
#    noseries    Number of series or "stacked"
# Result:
#    None
# Side effects:
#    Axis drawn in canvas
#
proc ::Plotchart::DrawXlabels { w xlabels noseries } {
    variable scaling

    $w delete xaxis

    $w create line $scaling($w,pxmin) $scaling($w,pymax) \
                   $scaling($w,pxmax) $scaling($w,pymax) \
                   -fill black -tag xaxis

    set x 0.5
    set scaling($w,ybase) {}
    foreach label $xlabels {
        foreach {xcrd ycrd} [coordsToPixel $w $x $scaling($w,ymin)] {break}
        $w create text $xcrd $ycrd -text $label -tag xaxis -anchor n
        set x [expr {$x+1.0}]

        lappend scaling($w,ybase) 0.0
    }

    set scaling($w,xbase) 0.0

    if { $noseries != "stacked" } {
        set scaling($w,stacked)  0
        set scaling($w,xshift)   [expr {1.0/$noseries}]
        set scaling($w,barwidth) [expr {1.0/$noseries}]
    } else {
        set scaling($w,stacked)  1
        set scaling($w,xshift)   0.0
        set scaling($w,barwidth) 0.8
        set scaling($w,xbase)    0.1
    }
}

# DrawYlabels --
#    Draw the labels to a y-axis (barchart)
# Arguments:
#    w           Name of the canvas
#    ylabels     List of labels
#    noseries    Number of series or "stacked"
# Result:
#    None
# Side effects:
#    Axis drawn in canvas
#
proc ::Plotchart::DrawYlabels { w ylabels noseries } {
    variable scaling

    $w delete yaxis

    $w create line $scaling($w,pxmin) $scaling($w,pymin) \
                   $scaling($w,pxmin) $scaling($w,pymax) \
                   -fill black -tag yaxis

    set y 0.5
    set scaling($w,xbase) {}
    foreach label $ylabels {
        foreach {xcrd ycrd} [coordsToPixel $w $scaling($w,xmin) $y] {break}
        $w create text $xcrd $ycrd -text $label -tag yaxis -anchor e
        set y [expr {$y+1.0}]

        lappend scaling($w,xbase) 0.0
    }

    set scaling($w,ybase) 0.0

    if { $noseries != "stacked" } {
        set scaling($w,stacked)  0
        set scaling($w,yshift)   [expr {1.0/$noseries}]
        set scaling($w,barwidth) [expr {1.0/$noseries}]
    } else {
        set scaling($w,stacked)  1
        set scaling($w,yshift)   0.0
        set scaling($w,barwidth) 0.8
        set scaling($w,ybase)    0.1
    }
}

# XConfig --
#    Configure the x-axis for an XY plot
# Arguments:
#    w           Name of the canvas
#    args        Option and value pairs
# Result:
#    None
#
proc ::Plotchart::XConfig { w args } {
    AxisConfig xyplot $w x DrawXaxis $args
}

# YConfig --
#    Configure the y-axis for an XY plot
# Arguments:
#    w           Name of the canvas
#    args        Option and value pairs
# Result:
#    None
#
proc ::Plotchart::YConfig { w args } {
    AxisConfig xyplot $w y DrawYaxis $args
}

# AxisConfig --
#    Configure an axis and redraw it if necessary
# Arguments:
#    plottype       Type of plot
#    w              Name of the canvas
#    orient         Orientation of the axis
#    drawmethod     Drawing method
#    option_values  Option/value pairs
# Result:
#    None
#
proc ::Plotchart::AxisConfig { plottype w orient drawmethod option_values } {
    variable scaling
    variable axis_options
    variable axis_option_clear
    variable axis_option_values

    set clear_data 0

    foreach {option value} $option_values {
        set idx [lsearch $axis_options $option]
        if { $idx < 0 } {
            return -code error "Unknown or invalid option: $option (value: $value)"
        } else {
            set clear   [lindex  $axis_option_clear  $idx]
            set values  [lindex  $axis_option_values [incr idx]]
            if { $values != "..." } {
                if { [lsearch $values $value] < 0 } {
                    return -code error "Unknown or invalid value: $value for option $option - $values"
                }
            }
            set scaling($w,$option,$orient) $value
            if { $clear } {
                set clear_data 1
            }
        }
    }

    if { $clear_data }  {
        $w delete data
    }

    if { $orient == "x" } {
        $drawmethod $w $scaling($w,xmin) $scaling($w,xmax) $scaling($w,xdelt)
    }
    if { $orient == "y" } {
        $drawmethod $w $scaling($w,ymin) $scaling($w,ymax) $scaling($w,ydelt)
    }
    if { $orient == "z" } {
        $drawmethod $w $scaling($w,zmin) $scaling($w,zmax) $scaling($w,zdelt)
    }
}

# DrawXTicklines --
#    Draw the ticklines for the x-axis
# Arguments:
#    w           Name of the canvas
#    colour      Colour of the ticklines
# Result:
#    None
#
proc ::Plotchart::DrawXTicklines { w {colour black} } {
    DrawTicklines $w x $colour
}

# DrawYTicklines --
#    Draw the ticklines for the y-axis
# Arguments:
#    w           Name of the canvas
#    colour      Colour of the ticklines
# Result:
#    None
#
proc ::Plotchart::DrawYTicklines { w {colour black} } {
    DrawTicklines $w y $colour
}

# DrawTicklines --
#    Draw the ticklines
# Arguments:
#    w           Name of the canvas
#    axis        Which axis (x or y)
#    colour      Colour of the ticklines
# Result:
#    None
#
proc ::Plotchart::DrawTicklines { w axis {colour black} } {
    variable scaling

    if { $axis == "x" } {
        if { $colour != {} } {
            foreach x $scaling($w,xaxis) {
                $w create line $x $scaling($w,pymin) \
                               $x $scaling($w,pymax) \
                               -fill $colour -tag xtickline
            }
        } else {
            $w delete xtickline
        }
    } else {
        if { $colour != {} } {
            foreach y $scaling($w,yaxis) {
                $w create line $scaling($w,pxmin) $y \
                               $scaling($w,pxmax) $y \
                               -fill $colour -tag ytickline
            }
        } else {
            $w delete ytickline
        }
    }
}

# DefaultLegend --
#    Set all legend options to default
# Arguments:
#    w              Name of the canvas
# Result:
#    None
#
proc ::Plotchart::DefaultLegend { w } {
    variable legend

    set legend($w,background) "white"
    set legend($w,border)     "black"
    set legend($w,canvas)     $w
    set legend($w,position)   "top-right"
    set legend($w,series)     ""
    set legend($w,text)       ""
}

# LegendConfigure --
#    Configure the legend
# Arguments:
#    w              Name of the canvas
#    args           Key-value pairs
# Result:
#    None
#
proc ::Plotchart::LegendConfigure { w args } {
    variable legend

    foreach {option value} $args {
        switch -- $option {
            "-background" {
                 set legend($w,background) $value
            }
            "-border" {
                 set legend($w,border) $value
            }
            "-canvas" {
                 set legend($w,canvas) $value
            }
            "-position" {
                 if { [lsearch {top-left top-right bottom-left bottom-right} $value] >= 0 } {
                     set legend($w,position) $value
                 } else {
                     return -code error "Unknown or invalid position: $value"
                 }
            }
            default {
                return -code error "Unknown or invalid option: $option (value: $value)"
            }
        }
    }
}

# DrawLegend --
#    Draw or extend the legend
# Arguments:
#    w              Name of the canvas
#    series         For which series?
#    text           Text to be shown
# Result:
#    None
#
proc ::Plotchart::DrawLegend { w series text } {
    variable legend
    variable scaling
    variable data_series


    lappend legend($w,series) $series
    lappend legend($w,text)   $text
    set legendw               $legend($w,canvas)

    $legendw delete legend
    $legendw delete legendbg

    set y 0
    foreach series $legend($w,series) text $legend($w,text) {

        set colour "black"
        if { [info exists data_series($w,$series,-colour)] } {
            set colour $data_series($w,$series,-colour)]
        }
        set type "line"
        if { [info exists data_series($w,$series,-type)] } {
            set type $data_series($w,$series,-type)]
        }

        # TODO: line or rectangle!

        $legendw create line 0 $y 15 $y -fill $colour -tag legend

        if { $type == "symbol" || $type == "both" } {
            set symbol "dot"
            if { [info exists data_series($w,$series,-symbol)] } {
                set symbol $data_series($w,$series,-symbol)
            }
            DrawSymbolPixel $legendw $series 7 $y $symbol $colour $tag
        }

        $legendw create text 25 $y -text $text -anchor w -tag legend

        incr y 10   ;# TODO: size of font!
    }

    #
    # Now the frame and the background
    #
    foreach {xl yt xr yb} [$w bbox legend] {break}

    set xl [expr {$xl-2}]
    set xr [expr {$xr+2}]
    set yt [expr {$yt-2}]
    set yb [expr {$yb+2}]

    $legendw create rectangle $xl $yt $xr $yb -fill $legend($w,background) \
        -outline $legend($w,border) -tag legendbg

    $legendw raise legend

    if { $w == $legendw } {
        switch -- $legend($w,position) {
            "top-left" {
                 set dx [expr { 10+$scaling($w,pxmin)-$xl}]
                 set dy [expr { 10+$scaling($w,pymin)-$yt}]
            }
            "top-right" {
                 set dx [expr {-10+$scaling($w,pxmax)-$xr}]
                 set dy [expr { 10+$scaling($w,pymin)-$yt}]
            }
            "bottom-left" {
                 set dx [expr { 10+$scaling($w,pxmin)-$xl}]
                 set dy [expr {-10+$scaling($w,pymax)-$yb}]
            }
            "bottom-right" {
                 set dx [expr {-10+$scaling($w,pxmax)-$xr}]
                 set dy [expr {-10+$scaling($w,pymax)-$yb}]
            }
        }
    } else {
        set dx 10
        set dy 10
    }

    $legendw move legend   $dx $dy
    $legendw move legendbg $dx $dy
}
