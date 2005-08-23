# -*- tcl -*-
#
# scrollw.tcl -
#
#	Scrolled widget
#

if 0 {
    # Samples
    package require widget::scrolledwindow
    set sw [widget::scrolledwindow .sw -scrollbar vertical]
    set text [text .sw.text -wrap word]
    $sw setwidget $text
    pack $sw -fill both -expand 1
}

###

package require widget

snit::widget widget::scrolledwindow {
    hulltype frame ; # not themed to allow relief

    component hscroll
    component vscroll

    delegate option * to hull
    delegate method * to hull
    #delegate option -size to {hscroll vscroll} as -width

    option -scrollbar -default "both" \
	-configuremethod C-scrollbar -validatemethod isa
    option -auto      -default "both" \
	-configuremethod C-scrollbar -validatemethod isa
    option -sides     -default "se" \
	-configuremethod C-scrollbar -validatemethod isa
    option -size      -default 0 -configuremethod C-size -validatemethod isa
    option -padding   -default 1 -configuremethod C-padding -validatemethod isa

    typevariable scrollopts {none horizontal vertical both}
    variable hlock 0       ; # locks to prevent redisplay loop
    variable vlock 0
    variable realized 0    ; # set when first Configure'd
    variable hsb -array {packed 0 present 0 auto 0 cell 0}
    variable vsb -array {packed 0 present 0 auto 0 cell 0}
    variable pending {}    ; # pending after id for scrollbar mgmt

    constructor args {
	install hscroll using scrollbar $win.hscroll -orient horizontal \
	    -highlightthickness 0 -takefocus 0
	install vscroll using scrollbar $win.vscroll -orient vertical \
	    -highlightthickness 0 -takefocus 0

	bind $win <Configure> [mymethod _realize $win]

	grid columnconfigure $win 1 -weight 1
	grid rowconfigure    $win 1 -weight 1

	set pending [after idle [mymethod _setdata]]
	$self configurelist $args
    }

    # Do we need this ??
    method getframe {} { return $win }

    method isa {option value} {
	set cmd widget::isa
	switch -exact -- $option {
	    -scrollbar -
	    -auto {
		return [uplevel 1 [list $cmd list $scrollopts $option $value]]
	    }
	    -sides {
		return [uplevel 1 [list $cmd list {ne en nw wn se es sw ws} $option $value]]
	    }
	    -size {
		return [uplevel 1 [list $cmd integer {0 30} $option $value]]
	    }
	    -padding {
		return [uplevel 1 [list $cmd listofint 4 $option $value]]
	    }
	}
    }

    variable setwidget {}
    method setwidget {widget} {
	if {$setwidget eq $widget} { return }
	if {[winfo exists $setwidget]} {
	    grid remove $setwidget
	    $setwidget configure -xscrollcommand "" -yscrollcommand ""
	    set setwidget {}
	}
	if {[winfo exists $widget]} {
	    set setwidget $widget
	    grid $widget -in $win -row 1 -column 1 -sticky news

	    $hscroll configure -command [list $widget xview]
	    $vscroll configure -command [list $widget yview]
	    $widget configure \
		-xscrollcommand [mymethod _set_hscroll] \
		-yscrollcommand [mymethod _set_vscroll]
	}
    }

    method C-size {option value} {
	$vscroll configure -width $value
	$hscroll configure -width $value
	set options($option) $value
    }

    method C-scrollbar {option value} {
	after cancel $pending
	set pending [after idle [mymethod _setdata]]
	set options($option) $value
    }

    method _set_hscroll {vmin vmax} {
	if {$realized && $hsb(present)} {
	    if {$hsb(auto)} {
		if {$hsb(packed) && $vmin == 0 && $vmax == 1} {
		    if {!$hlock} {
			set hsb(packed) 0
			grid remove $hscroll
		    }
		} elseif {!$hsb(packed) && ($vmin != 0 || $vmax != 1)} {
		    set hsb(packed) 1
		    grid $hscroll -column 1 -row $hsb(cell) -sticky ew
		    set hlock 1
		    update idletasks
		    set hlock 0
		}
	    }
	    $hscroll set $vmin $vmax
	}
    }

    method _set_vscroll {vmin vmax} {
	if {$realized && $vsb(present)} {
	    if {$vsb(auto)} {
		if {$vsb(packed) && $vmin == 0 && $vmax == 1} {
		    if {!$vlock} {
			set vsb(packed) 0
			grid remove $win.vscroll
		    }
		} elseif {!$vsb(packed) && ($vmin != 0 || $vmax != 1) } {
		    set vsb(packed) 1
		    grid $win.vscroll -column $vsb(cell) -row 1 -sticky ns
		    set vlock 1
		    update idletasks
		    set vlock 0
		}
	    }
	    $vscroll set $vmin $vmax
	}
    }

    method _setdata {} {
	set sb    [lsearch -exact $scrollopts $options(-scrollbar)]
	set auto  [lsearch -exact $scrollopts $options(-auto)]

	set hsb(present) [expr {($sb & 1) != 0}]
	set hsb(auto)	 [expr {($auto & 1) != 0}]
	set hsb(cell)	 [expr {[string match *n* $options(-sides)] ? 0 : 2}]

	set vsb(present) [expr {($sb & 2) != 0}]
	set vsb(auto)	 [expr {($auto & 2) != 0}]
	set vsb(cell)    [expr {[string match *w* $options(-sides)] ? 0 : 2}]

	foreach {vmin vmax} [$hscroll get] { break }
	set hsb(packed) [expr {$hsb(present) &&
			       (!$hsb(auto) || ($vmin != 0 || $vmax != 1))}]
	foreach {vmin vmax} [$vscroll get] { break }
	set vsb(packed) [expr {$vsb(present) &&
			       (!$vsb(auto) || ($vmin != 0 || $vmax != 1))}]

	if {$hsb(packed)} {
	    grid $hscroll -column 1 -row $hsb(cell) -sticky ew
	}
	if {$vsb(packed)} {
	    grid $vscroll -column $vsb(cell) -row 1 -sticky ns
	}
    }

    method _realize {w} {
	if {$w eq $win} {
	    bind $win <Configure> {}
	    set realized 1
	}
    }
}

package provide widget::scrolledwindow 1.0