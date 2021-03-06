#
# Mooshak: managing programming contests on the web		April 2001
# 
#			Zé Paulo Leal 		
#			zp@ncc.up.pt
#
#-----------------------------------------------------------------------------
# file: exam-auto-grading.tcl
# 
## Marking and classification policy for exams with automatic evaluation. 
## The number of accepted submissions is given in the Solved column.
## The total points of submissions is not computed since 
## there are no  penalties for wrong submissions.  

package provide exam-auto-grading 1.0

package require utils

namespace eval exam-auto-grading {

    # variables used in ranking teams
    variable probs
    variable attpt   
    variable durat

    # a policy MUST define these procedures
    # view this as a kind of contact or interface
    namespace export subjective	;# is grading subjective?
    namespace export order	;# sort teams by rank
    namespace export rank	;# assign ranks to teams
    namespace export cell	;# show a cell in the classification table
    namespace export solved	;# number of problems solved by team
    namespace export points	;# classification of given team

}

## Is grading subjective (a value given by an human judge)?
proc exam-auto-grading::subjective {} {
    return 0
}

## Sort teams by rank
proc exam-auto-grading::order {teams problems subs} {
    variable probs
    variable attpt   
    variable durat
    variable ::Session::Conf

    upvar ::Submission::Results Results

    set accepted [ lindex $Results 0 ]

    # initialize
    foreach team $teams {
	set probs($team) 0
	set attpt($team) 0
	foreach problem $problems {
	    set durat($team,$problem) ""
	    set attpt($team,$problem) 0
	    set resol($team,$problem) 0
	}
    }

    # compute points
    foreach sub [ lsort $subs ] {

	if { ! [ Submissions::load_submission $sub ] } continue 

	if { [ lsearch $teams $Team ] == -1 } {
	    execute::record_error "Undefined team '$Team'"	
	    continue
	}
	# if already accepted ignore subsequent submissions
	if $resol($Team,$Problem) continue
	if { [ string compare $Classify $accepted ] == 0 } {
	    incr probs($Team) 
	    set file [ file tail $sub ]
	    set link $Conf(controller)?split+sms+submissions+$file+modify+0 
	    set durat($Team,$Problem) \
		[ format "<a href='%s' target='bottom'>OK</a>" $link ]
	    set resol($Team,$Problem) 1
	} else {
	    set durat($Team,$Problem) ------
	    incr attpt($Team)
	    incr attpt($Team,$Problem)
	}
    }

    return [ lsort -command ::exam-auto-grading::cmp_pont $teams ]
}

## Assign ranks to teams
proc exam-auto-grading::rank {contest list} {
    variable probs 

    data::open $contest/groups

    set n 0
    foreach team $list {
	incr n
	
	if { $probs($team) == 0 } {
	    set rank 0
	} else {
	    set rank $n
	}
	
	
	if [ catch { set fx [ glob $contest/groups/*/$team ] } ] {
	    execute::report_error "undefined team" $team
	    continue
	} else {
	    set tm [ data::open $fx ]
	    set ${tm}::Rank $rank
	    data::record $fx
	}
    }    
}

## Show a cell in the classification table
proc exam-auto-grading::cell {team problem} {
    variable durat
    variable attpt 

    if { $durat($team,$problem) == "" } {
	set status "&nbsp;"
    } else {
	set status [ format {%s (%s)}		\
		$durat($team,$problem)	\
		$attpt($team,$problem) ]
	
    }
    return $status
}

## Number of solved problems
proc exam-auto-grading::solved {team} {
    variable probs

    return $probs($team)
}

## Total points for team (unused)
proc exam-auto-grading::points {team} {

    return  ""
}

# Compares team's rank according to
#	1) number of solved problems
#	2) number of attempts
proc exam-auto-grading::cmp_pont {a b} {
    variable probs
    variable attpt 
    
    if { $probs($a) == $probs($b) } {
	if { $probs($a) == 0 } {
	    return [ expr $attpt($a) < $attpt($b) ]
	} else {
	    return [ expr $attpt($a) > $attpt($b) ]
	}
    } else {
	return [ expr $probs($a) < $probs($b) ]
    }
	
}
