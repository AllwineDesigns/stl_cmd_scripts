#!/bin/bash

twobyfour_edge_radius=.125
twobyfour_thickness=1.5
twobyfour_width=3.5
width=96
height=43
depth=36
backboard=true
shelf_height=74.75
shelf_depth=11.875
overhang=0
plywood_thickness=.75
pegboard_thickness=.25

shelf_gap=2
gap=3.5

while getopts 'w:h:d:b:e:p:o:' flag; do
  case "${flag}" in
    w) width="${OPTARG}" ;;
    h) height="${OPTARG}" ;;
    d) depth="${OPTARG}" ;;
    b) backboard="${OPTARG}" ;;
    o) overhang="${OPTARG}" ;;
    e) shelf_height="${OPTARG}" ;;
    p) shelf_depth="${OPTARG}" ;;
    *) error "Unexpected option ${flag}" ;;
  esac
done

if [ `echo "$shelf_depth > 0" | bc` -eq 1 ]; then
  frame_height=`echo "$shelf_height+$twobyfour_thickness+$shelf_gap" | bc -l`
  joist_length=`echo "$frame_height-2*$twobyfour_thickness-$height" | bc -l`
  shelf_support_length=`echo "$shelf_depth+$twobyfour_width" | bc -l`
  pegboard_height=`echo "$shelf_height-$plywood_thickness-$twobyfour_width-$height-$gap" | bc -l`
else
  frame_height=$shelf_height
  joist_length=`echo "$frame_height-2*$twobyfour_thickness-$height" | bc -l`
  shelf_support_length=0
  pegboard_height=`echo "$frame_height-$height-$gap-$shelf_gap-$twobyfour_thickness" | bc -l`
fi

leg_length=`echo "$height-$plywood_thickness" | bc -l`
cross_support_length=`echo "sqrt(2)*.5*($depth-$overhang-4*$twobyfour_thickness)+$twobyfour_width" | bc -l`
support_height=`echo "$height-$plywood_thickness-$cross_support_length*sqrt(2)*.5" | bc -l`
support_length=`echo "$depth-$overhang-4*$twobyfour_thickness" | bc -l`
oversize=.1
yjoist_length=`echo "$depth-$overhang-2*$twobyfour_thickness" | bc -l`
numYJoists=`echo "($width-$twobyfour_thickness)/24+2" | bc`
spaceBetween=`echo "($width-$twobyfour_thickness)/($numYJoists-1)" | bc -l`

function VerticalTwoByFour {
  corner1=$(mktemp /tmp/workbench.corner1.XXXXXX)
  corner2=$(mktemp /tmp/workbench.corner2.XXXXXX)
  corner3=$(mktemp /tmp/workbench.corner3.XXXXXX)
  corner4=$(mktemp /tmp/workbench.corner4.XXXXXX)
  corners=$(mktemp /tmp/workbench.corners.XXXXXX)
  body1=$(mktemp /tmp/workbench.body1.XXXXXX)
  body2=$(mktemp /tmp/workbench.body2.XXXXXX)

  tmpfile=$(mktemp /tmp/workbench.tmpfile.XXXXXX)
  twobyfour=$(mktemp /tmp/workbench.twobyfour.XXXXXX)

  stl_cylinder -r $twobyfour_edge_radius -h $1 -s 4 $tmpfile
  stl_transform -tx $twobyfour_edge_radius -ty $twobyfour_edge_radius -tz `echo "$1/2" | bc -l` $tmpfile $corner1

  stl_cylinder -r $twobyfour_edge_radius -h $1 -s 4 $tmpfile
  stl_transform -tx `echo "$twobyfour_thickness-$twobyfour_edge_radius" | bc -l` -ty $twobyfour_edge_radius -tz `echo "$1/2" | bc -l` $tmpfile $corner2

  stl_cylinder -r $twobyfour_edge_radius -h $1 -s 4 $tmpfile
  stl_transform -tx `echo "$twobyfour_thickness-$twobyfour_edge_radius" | bc -l` -ty `echo "$twobyfour_width-$twobyfour_edge_radius" | bc -l` -tz `echo "$1/2" | bc -l` $tmpfile $corner3

  stl_cylinder -r $twobyfour_edge_radius -h $1 -s 4 $tmpfile
  stl_transform -tx $twobyfour_edge_radius -ty `echo "$twobyfour_width-$twobyfour_edge_radius" | bc -l` -tz `echo "$1/2" | bc -l` $tmpfile $corner4

  stl_cube $tmpfile
  stl_transform -tx .5 -ty .5 -tz .5 -sz $1 -sx `echo "$twobyfour_thickness-2*$twobyfour_edge_radius" | bc -l` -sy $twobyfour_width -tx $twobyfour_edge_radius $tmpfile $body1
  stl_transform -tx .5 -ty .5 -tz .5 -sz $1 -sx $twobyfour_thickness -sy `echo "$twobyfour_width-2*$twobyfour_edge_radius" | bc -l` -ty $twobyfour_edge_radius $tmpfile $body2

  stl_merge -o $corners $corner1 $corner2 $corner3 $corner4

  stl_boolean -a $body1 -b $body2 $tmpfile
  stl_boolean -a $tmpfile -b $corners $twobyfour

  cat $twobyfour

  rm $corner1 $corner2 $corner3 $corner4 $corners $body1 $body2 $tmpfile $twobyfour
}

function HorizontalTwoByFour {
  vertical=$(mktemp /tmp/workbench.vertical.XXXXXX)
  horizontal=$(mktemp /tmp/workbench.horizontal.XXXXXX)

  VerticalTwoByFour $1 > $vertical

  stl_transform -ry 90 -rx 90 $vertical $horizontal

  cat $horizontal
  rm $vertical $horizontal
}

function FourtyFiveTwoByFour {
  vertical_twobyfour=$(mktemp /tmp/workbench.vertical_twobyfour.XXXXXX)
  rotated=$(mktemp /tmp/workbench.rotated.XXXXXX)
  cube=$(mktemp /tmp/workbench.cube.XXXXXX)
  cut1=$(mktemp /tmp/workbench.cut1.XXXXXX)
  cut2=$(mktemp /tmp/workbench.cut2.XXXXXX)
  tmpcut=$(mktemp /tmp/workbench.tmpcut.XXXXXX)

  len_sqrt2=`echo "$1/sqrt(2)" | bc -l`

  VerticalTwoByFour $1 > $vertical_twobyfour

  stl_transform -rx -45 $vertical_twobyfour $rotated

  stl_cube $cube

  if [ $2 -ge 1 ]; then
    stl_transform -tz .5 -s `echo "4*$twobyfour_width" | bc -l` -tz `echo "-4*$twobyfour_width" | bc -l` $cube $cut1
    stl_boolean -a $rotated -b $cut1 -d $tmpcut
    cp $tmpcut $rotated
  fi

  if [ $2 -eq 2 ]; then
    stl_transform -ty .5 -tz .5 -s `echo "4*$twobyfour_width" | bc -l` -ty $len_sqrt2 -tz `echo "$len_sqrt2-2*$twobyfour_width" | bc -l` $cube $cut2
    stl_boolean -a $rotated -b $cut2 -d $tmpcut
    cp $tmpcut $rotated
  fi

  if [ $3 = "true" ]; then
    stl_transform -ty "-$len_sqrt2" -tz "-$len_sqrt2" $rotated $tmpcut
    cp $tmpcut $rotated
  fi

  if [ $4 != "true" ]; then
    stl_transform -rx 45 $rotated $tmpcut
    cp $tmpcut $rotated
  fi

  cp $rotated /tmp/rotate.stl

  cat $rotated

  rm $vertical_twobyfour $rotated $cube $cut1 $cut2 $tmpcut
}

function LeftFrontLeg {
  leftFrontLegTemp=$(mktemp /tmp/workbench.leftFrontLegTemp.XXXXXX)
  leftFrontLegBoard1=$(mktemp /tmp/workbench.leftFrontLegBoard1.XXXXXX)
  leftFrontLegBoard2=$(mktemp /tmp/workbench.leftFrontLegBoard2.XXXXXX)
  VerticalTwoByFour $leg_length > $leftFrontLegTemp

  stl_transform -tx $twobyfour_thickness -ty `echo "$twobyfour_thickness+$overhang" | bc -l` $leftFrontLegTemp $leftFrontLegBoard1
  stl_transform -rz -90 -tx `echo "2*$twobyfour_thickness" | bc -l` -ty `echo "2*$twobyfour_thickness+$overhang" | bc -l` $leftFrontLegTemp $leftFrontLegBoard2

  stl_merge -o $leftFrontLegTemp $leftFrontLegBoard1 $leftFrontLegBoard2

  cat $leftFrontLegTemp
  rm $leftFrontLegTemp $leftFrontLegBoard1 $leftFrontLegBoard2
}

function LeftBackLeg {
  leftBackLegTemp=$(mktemp /tmp/workbench.leftBackLegTemp.XXXXXX)
  leftBackLegBoard1=$(mktemp /tmp/workbench.leftBackLegBoard1.XXXXXX)
  leftBackLegBoard2=$(mktemp /tmp/workbench.leftBackLegBoard2.XXXXXX)
  VerticalTwoByFour $leg_length > $leftBackLegTemp

  stl_transform -tx $twobyfour_thickness -ty `echo "$depth-$twobyfour_width-$twobyfour_thickness" | bc -l` $leftBackLegTemp $leftBackLegBoard1
  stl_transform -rz -90 -tx `echo "2*$twobyfour_thickness" | bc -l` -ty `echo "$depth-$twobyfour_thickness" | bc -l` $leftBackLegTemp $leftBackLegBoard2

  stl_merge -o $leftBackLegTemp $leftBackLegBoard1 $leftBackLegBoard2

  cat $leftBackLegTemp
  rm $leftBackLegTemp $leftBackLegBoard1 $leftBackLegBoard2
}

function RightFrontLeg {
  rightFrontLegTemp=$(mktemp /tmp/workbench.rightFrontLegTemp.XXXXXX)
  rightFrontLegBoard1=$(mktemp /tmp/workbench.rightFrontLegBoard1.XXXXXX)
  rightFrontLegBoard2=$(mktemp /tmp/workbench.rightFrontLegBoard2.XXXXXX)
  VerticalTwoByFour $leg_length > $rightFrontLegTemp

  stl_transform -tx `echo "$width-2*$twobyfour_thickness" | bc -l` -ty `echo "$twobyfour_thickness+$overhang" | bc -l` $rightFrontLegTemp $rightFrontLegBoard1
  stl_transform -rz -90 -tx `echo "$width-2*$twobyfour_thickness-$twobyfour_width" | bc -l` -ty `echo "2*$twobyfour_thickness+$overhang" | bc -l` $rightFrontLegTemp $rightFrontLegBoard2

  stl_merge -o $rightFrontLegTemp $rightFrontLegBoard1 $rightFrontLegBoard2

  cat $rightFrontLegTemp
  rm $rightFrontLegTemp $rightFrontLegBoard1 $rightFrontLegBoard2
}

function RightBackLeg {
  rightBackLegTemp=$(mktemp /tmp/workbench.rightBackLegTemp.XXXXXX)
  rightBackLegBoard1=$(mktemp /tmp/workbench.rightBackLegBoard1.XXXXXX)
  rightBackLegBoard2=$(mktemp /tmp/workbench.rightBackLegBoard2.XXXXXX)
  VerticalTwoByFour $leg_length > $rightBackLegTemp

  stl_transform -tx `echo "$width-2*$twobyfour_thickness" | bc -l` -ty `echo "$depth-$twobyfour_width-$twobyfour_thickness" | bc -l` $rightBackLegTemp $rightBackLegBoard1
  stl_transform -rz -90 -tx `echo "$width-2*$twobyfour_thickness-$twobyfour_width" | bc -l` -ty `echo "$depth-$twobyfour_thickness" | bc -l` $rightBackLegTemp $rightBackLegBoard2

  stl_merge -o $rightBackLegTemp $rightBackLegBoard1 $rightBackLegBoard2

  cat $rightBackLegTemp
  rm $rightBackLegTemp $rightBackLegBoard1 $rightBackLegBoard2
}

function Supports {
  supports1=$(mktemp /tmp/workbench.supports1.XXXXXX)
  supports2=$(mktemp /tmp/workbench.supports2.XXXXXX)
  supports3=$(mktemp /tmp/workbench.supports3.XXXXXX)
  supports4=$(mktemp /tmp/workbench.supports4.XXXXXX)
  supports5=$(mktemp /tmp/workbench.supports5.XXXXXX)
  supports6=$(mktemp /tmp/workbench.supports6.XXXXXX)

  supportstmp1=$(mktemp /tmp/workbench.supportstmp1.XXXXXX)
  supportstmp2=$(mktemp /tmp/workbench.supportstmp2.XXXXXX)

  HorizontalTwoByFour $support_length > $supportstmp1
  stl_transform -rz 90 -ry 90 -tx `echo "2*$twobyfour_thickness" | bc -l` -ty `echo "2*$twobyfour_thickness+$overhang" | bc -l` -tz `echo "$support_height-$twobyfour_thickness" | bc -l` $supportstmp1 $supports1

  HorizontalTwoByFour $support_length > $supportstmp1
  stl_transform -rz 90 -ry 90 -tx `echo "$width-$twobyfour_width-2*$twobyfour_thickness" | bc -l ` -ty `echo "2*$twobyfour_thickness+$overhang" | bc -l` -tz `echo "$support_height-$twobyfour_thickness" | bc -l` $supportstmp1 $supports2

  FourtyFiveTwoByFour $cross_support_length 2 true true > $supportstmp1
  stl_transform -tx `echo "2*$twobyfour_thickness" | bc -l` -ty `echo "$depth-2*$twobyfour_thickness" | bc -l` -tz `echo "$height-$plywood_thickness" | bc -l` $supportstmp1 $supports3

  FourtyFiveTwoByFour $cross_support_length 2 true true > $supportstmp1
  stl_transform -rz 180 -tx `echo "4*$twobyfour_thickness" | bc -l` -ty `echo "2*$twobyfour_thickness+$overhang" | bc -l` -tz `echo "$height-$plywood_thickness" | bc -l` $supportstmp1 $supports4

  FourtyFiveTwoByFour $cross_support_length 2 true true > $supportstmp1
  stl_transform -tx `echo "$width-3*$twobyfour_thickness" | bc -l` -ty `echo "$depth-2*$twobyfour_thickness" | bc -l` -tz `echo "$height-$plywood_thickness" | bc -l` $supportstmp1 $supports5

  FourtyFiveTwoByFour $cross_support_length 2 true true > $supportstmp1
  stl_transform -rz 180 -tx `echo "$width-3*$twobyfour_thickness" | bc -l` -ty `echo "2*$twobyfour_thickness+$overhang" | bc -l` -tz `echo "$height-$plywood_thickness" | bc -l` $supportstmp1 $supports6

  stl_merge -o $supportstmp1 $supports1 $supports2 $supports3 $supports4 $supports5 $supports6

  cat $supportstmp1

  rm $supportstmp1 $supportstmp2 $supports1 $supports2 $supports3 $supports4 $supports5 $supports6
}

function TableTop {
  tabletop1=$(mktemp /tmp/workbench.tabletop1.XXXXXX)
  tabletop2=$(mktemp /tmp/workbench.tabletop2.XXXXXX)
  tabletop3=$(mktemp /tmp/workbench.tabletop3.XXXXXX)
  tabletop4=$(mktemp /tmp/workbench.tabletop4.XXXXXX)
  tabletop5=$(mktemp /tmp/workbench.tabletop5.XXXXXX)
  joisttmp=$(mktemp /tmp/workbench.joisttmp.XXXXXX)
  joist=$(mktemp /tmp/workbench.joist.XXXXXX)

  tabletoptmp=$(mktemp /tmp/workbench.tabletoptmp.XXXXXX)
  tabletoptmp2=$(mktemp /tmp/workbench.tabletoptmp2.XXXXXX)

  HorizontalTwoByFour $width > $tabletoptmp
  stl_transform -ty $overhang -tz `echo "$leg_length-$twobyfour_width" | bc -l` $tabletoptmp $tabletop1
  stl_transform -ty `echo "$depth-$twobyfour_thickness" | bc -l` -tz `echo "$leg_length-$twobyfour_width" | bc -l` $tabletoptmp $tabletop2

  HorizontalTwoByFour $yjoist_length > $tabletoptmp
  stl_transform -rz 90 -tx $twobyfour_thickness -ty `echo "$twobyfour_thickness+$overhang" | bc -l` -tz `echo "$leg_length-$twobyfour_width" | bc -l` $tabletoptmp $tabletop3

  HorizontalTwoByFour $yjoist_length > $tabletoptmp
  stl_transform -rz 90 -tx $width -ty `echo "$twobyfour_thickness+$overhang" | bc -l` -tz `echo "$leg_length-$twobyfour_width" | bc -l` $tabletoptmp $tabletop4

  stl_cube $tabletoptmp
  stl_transform -tx .5 -ty .5 -tz .5 -sx $width -sy $depth -sz $plywood_thickness -tz $leg_length $tabletoptmp $tabletop5

  stl_merge -o $tabletoptmp $tabletop1 $tabletop2 $tabletop3 $tabletop4 $tabletop5

  for i in `seq 1 $((numYJoists-2))`;
  do
    HorizontalTwoByFour $yjoist_length > $joisttmp
    stl_transform -rz 90 -tx `echo "$twobyfour_thickness+$i*($width-$twobyfour_thickness)/($numYJoists-1)" | bc -l` -ty `echo "$twobyfour_thickness+$overhang" | bc -l` -tz `echo "$leg_length-$twobyfour_width" | bc -l` $joisttmp $joist

    stl_merge -o $tabletoptmp2 $tabletoptmp $joist
    cp $tabletoptmp2 $tabletoptmp
  done

  cat $tabletoptmp

  rm $tabletoptmp $tabletop1 $tabletop2 $tabletop3 $tabletop4 $tabletop5 $joisttmp $joist $tabletoptmp2
}

function Backboard {
  backboard1=$(mktemp /tmp/workbench.backboard1.XXXXXX)
  backboard2=$(mktemp /tmp/workbench.backboard2.XXXXXX)
  backboard3=$(mktemp /tmp/workbench.backboard3.XXXXXX)
  backboardtmp=$(mktemp /tmp/workbench.backboardtmp.XXXXXX)
  backboardtmp2=$(mktemp /tmp/workbench.backboardtmp2.XXXXXX)
  backJoist=$(mktemp /tmp/workbench.backJoist.XXXXXX)
  backJoistTmp=$(mktemp /tmp/workbench.backJoistTmp.XXXXXX)
  shelfJoist=$(mktemp /tmp/workbench.shelfJoist.XXXXXX)
  shelfJoistTmp=$(mktemp /tmp/workbench.shelfJoistTmp.XXXXXX)

  HorizontalTwoByFour $width > $backboardtmp
  stl_transform -rx 90 -ty $depth -tz $height $backboardtmp $backboard1
  stl_transform -rx 90 -ty $depth -tz `echo "$frame_height-$twobyfour_thickness" | bc -l` $backboardtmp $backboard2

  stl_merge -o $backboardtmp $backboard1 $backboard2

  if [ `echo "$shelf_depth > 0" | bc` -eq 1 ]; then
    stl_cube $backboardtmp2
    stl_transform -tx .5 -ty .5 -tz .5 -sx $width -sy $shelf_depth -sz $plywood_thickness -ty `echo "$depth-$shelf_support_length" | bc -l` -tz `echo "$shelf_height-$plywood_thickness" | bc -l` $backboardtmp2 $backboard3
    cp $backboard3 /tmp/shelf.stl
    stl_merge -o $backboardtmp2 $backboardtmp $backboard3
    cp $backboardtmp2 $backboardtmp
  fi

  if [ `echo "$pegboard_height > 0" | bc` -eq 1 ]; then
    stl_cube $backboardtmp2
    stl_transform -tx .5 -ty .5 -tz .5 -sx $width -sy $pegboard_thickness -sz $pegboard_height -ty `echo "$depth-$pegboard_thickness-$twobyfour_width" | bc -l` -tz `echo "$height+$gap" | bc -l` $backboardtmp2 $backboard3
    cp $backboard3 /tmp/pegboard.stl
    stl_merge -o $backboardtmp2 $backboardtmp $backboard3
    cp $backboardtmp2 $backboardtmp
  fi

  for i in `seq 0 $((numYJoists-1))`;
  do
    x=`echo "$i*($width-$twobyfour_thickness)/($numYJoists-1)" | bc -l`
    VerticalTwoByFour $joist_length > $backJoistTmp
    stl_transform -tx $x -ty `echo "$depth-$twobyfour_width" | bc -l` -tz `echo "$height+$twobyfour_thickness" | bc -l` $backJoistTmp $backJoist
    stl_merge -o $backboardtmp2 $backboardtmp $backJoist
    cp $backboardtmp2 $backboardtmp

    if [ `echo "$shelf_support_length > 0" | bc -l` -eq 1 ]; then
      if [ $i -eq $(($numYJoists-1)) ]; then
        FourtyFiveTwoByFour $shelf_support_length 1 false false > $shelfJoistTmp
        stl_transform -rx -90 -tx `echo "$x-$twobyfour_thickness" | bc -l` -ty `echo "$depth-$shelf_support_length" | bc -l` -tz `echo "$shelf_height-$plywood_thickness" | bc -l` $shelfJoistTmp $shelfJoist
        stl_merge -o $backboardtmp2 $backboardtmp $shelfJoist
        cp $backboardtmp2 $backboardtmp
      else
        FourtyFiveTwoByFour $shelf_support_length 1 false false > $shelfJoistTmp
        stl_transform -rx -90 -tx `echo "$x+$twobyfour_thickness" | bc -l` -ty `echo "$depth-$shelf_support_length" | bc -l` -tz `echo "$shelf_height-$plywood_thickness" | bc -l` $shelfJoistTmp $shelfJoist
        stl_merge -o $backboardtmp2 $backboardtmp $shelfJoist
        cp $backboardtmp2 $backboardtmp
      fi
    fi
  done

  cat $backboardtmp

  rm $backboardtmp $backboardtmp2 $backboard1 $backboard2 $backboard3
}

workbenchFile=$(mktemp /tmp/workbench.workbenchFile.XXXXXX)
leftFrontLegFile=$(mktemp /tmp/workbench.leftFrontLegFile.XXXXXX)
leftBackLegFile=$(mktemp /tmp/workbench.leftBackLegFile.XXXXXX)
rightFrontLegFile=$(mktemp /tmp/workbench.rightFrontLegFile.XXXXXX)
rightBackLegFile=$(mktemp /tmp/workbench.rightBackLegFile.XXXXXX)
supportsFile=$(mktemp /tmp/workbench.supportsFile.XXXXXX)
tableTopFile=$(mktemp /tmp/workbench.tableTopFile.XXXXXX)
backboardFile=$(mktemp /tmp/workbench.backboardFile.XXXXXX)

workbenchTemp=$(mktemp /tmp/workbench.workbenchTemp.XXXXXX)

LeftFrontLeg > $leftFrontLegFile
LeftBackLeg > $leftBackLegFile
RightFrontLeg > $rightFrontLegFile
RightBackLeg > $rightBackLegFile
Supports > $supportsFile
TableTop > $tableTopFile

stl_merge -o $workbenchFile $leftFrontLegFile $leftBackLegFile $rightFrontLegFile $rightBackLegFile $supportsFile $tableTopFile

if [ $backboard = "true" ]; then
  Backboard > $backboardFile
  stl_merge -o $workbenchTemp $workbenchFile $backboardFile
  cp $workbenchTemp $workbenchFile
fi

cat $workbenchFile
rm $workbenchFile $leftFrontLegFile $leftBackLegFile $rightFrontLegFile $rightBackLegFile $tableTopFile
