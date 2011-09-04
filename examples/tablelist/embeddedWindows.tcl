#!/bin/sh
# the next line restarts using wish \
exec wish "$0" ${1+"$@"}

#==============================================================================
# Demonstrates the use of embedded windows in tablelist widgets.
#
# Copyright (c) 2004-2011  Csaba Nemethi (E-mail: csaba.nemethi@t-online.de)
#==============================================================================

package require tablelist 5.4

wm title . "Tk Library Scripts"

#
# Add some entries to the Tk option database
#
set dir [file dirname [info script]]
source [file join $dir option.tcl]

#
# Create the font TkFixedFont if not yet present
#
catch {font create TkFixedFont -family Courier -size -12}

#
# Create an image to be displayed in buttons embedded in a tablelist widget
#
image create photo openImg -file [file join $dir open.gif]

#
# Create a vertically scrolled tablelist widget with 5
# dynamic-width columns and interactive sort capability
#
set tbl .tbl
set vsb .vsb
tablelist::tablelist $tbl \
    -columns {0 "File Name" left
	      0 "Bar Chart" center
	      0 "File Size" right
	      0 "View"      center
	      0 "Seen"      center} \
    -setgrid no -yscrollcommand [list $vsb set] -width 0
if {[$tbl cget -selectborderwidth] == 0} {
    $tbl configure -spacing 1
}
$tbl columnconfigure 0 -name fileName
$tbl columnconfigure 1 -formatcommand emptyStr -sortmode integer
$tbl columnconfigure 2 -name fileSize -sortmode integer
$tbl columnconfigure 4 -name seen
scrollbar $vsb -orient vertical -command [list $tbl yview]

proc emptyStr val { return "" }

eval font create BoldFont [font actual [$tbl cget -font]] -weight bold

#
# Populate the tablelist widget
#
cd $tk_library
set maxFileSize 0
foreach fileName [lsort [glob *.tcl]] {
    set fileSize [file size $fileName]
    $tbl insert end [list $fileName $fileSize $fileSize "" no]

    if {$fileSize > $maxFileSize} {
	set maxFileSize $fileSize
    }
}

#------------------------------------------------------------------------------
# createFrame
#
# Creates a frame widget w to be embedded into the specified cell of the
# tablelist widget tbl, as well as a child frame representing the size of the
# file whose name is diplayed in the first column of the cell's row.
#------------------------------------------------------------------------------
proc createFrame {tbl row col w} {
    #
    # Create the frame and replace the binding tag "Frame"
    # with "TablelistBody" in the list of its binding tags
    #
    frame $w -width 102 -height 14 -background ivory -borderwidth 1 \
	     -relief solid
    bindtags $w [lreplace [bindtags $w] 1 1 TablelistBody]

    #
    # Create the child frame and replace the binding tag "Frame"
    # with "TablelistBody" in the list of its binding tags
    #
    frame $w.f -height 12 -background red -borderwidth 1 -relief raised
    bindtags $w.f [lreplace [bindtags $w] 1 1 TablelistBody]

    #
    # Manage the child frame
    #
    set fileSize [$tbl cellcget $row,fileSize -text]
    place $w.f -relwidth [expr {double($fileSize) / $::maxFileSize}]
}

#------------------------------------------------------------------------------
# createButton
#
# Creates a button widget w to be embedded into the specified cell of the
# tablelist widget tbl.
#------------------------------------------------------------------------------
proc createButton {tbl row col w} {
    set key [$tbl getkeys $row]
    button $w -image openImg -highlightthickness 0 -takefocus 0 \
	      -command [list viewFile $tbl $key]
}

#------------------------------------------------------------------------------
# viewFile
#
# Displays the contents of the file whose name is contained in the row with the
# given key of the tablelist widget tbl.
#------------------------------------------------------------------------------
proc viewFile {tbl key} {
    set top .top$key
    if {[winfo exists $top]} {
	raise $top
	return ""
    }

    toplevel $top
    set fileName [$tbl cellcget k$key,fileName -text]
    wm title $top "File \"$fileName\""

    #
    # Create a vertically scrolled text widget as a child of the toplevel
    #
    set txt $top.txt
    set vsb $top.vsb
    text $txt -background white -font TkFixedFont -setgrid yes \
	      -yscrollcommand [list $vsb set]
    catch {$txt configure -tabstyle wordprocessor}		;# for Tk 8.5
    scrollbar $vsb -orient vertical -command [list $txt yview]

    #
    # Insert the file's contents into the text widget
    #
    set chan [open $fileName]
    $txt insert end [read $chan]
    close $chan

    set btn [button $top.btn -text "Close" -command [list destroy $top]]

    #
    # Manage the widgets
    #
    grid $txt -row 0 -column 0 -sticky news
    grid $vsb -row 0 -column 1 -sticky ns
    grid $btn -row 1 -column 0 -columnspan 2 -pady 10
    grid rowconfigure    $top 0 -weight 1
    grid columnconfigure $top 0 -weight 1

    #
    # Mark the file as seen
    #
    $tbl rowconfigure k$key -font BoldFont
    $tbl cellconfigure k$key,seen -text yes
}

#------------------------------------------------------------------------------

#
# Create embedded windows in the columns no. 1 and 3
#
set rowCount [$tbl size]
for {set row 0} {$row < $rowCount} {incr row} {
    $tbl cellconfigure $row,1 -window createFrame -stretchwindow yes
    $tbl cellconfigure $row,3 -window createButton
}

set btn [button .btn -text "Close" -command exit]

#
# Manage the widgets
#
grid $tbl -row 0 -column 0 -sticky news
grid $vsb -row 0 -column 1 -sticky ns
grid $btn -row 1 -column 0 -columnspan 2 -pady 10
grid rowconfigure    . 0 -weight 1
grid columnconfigure . 0 -weight 1
