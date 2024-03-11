VAR DEBUG = false
-> default

=== default ===
~can_repair = true
Debugging hub
+ antenna 1
    -> antenna_mast1
+ antenna 2
    -> antenna_mast2
+ antenna 3
    -> antenna_mast3
+ computer
    -> computer
-
-> DONE

=== continue ===
+ [Ok.]
    ->->

=== exit ===
+ [Ok.]
    -> end

=== end
    {DEBUG:
        -> default
    - else:
        -> DONE
    }

// Antennas ========================================================================

LIST antennas = a1=1, a2=2, a3=3

VAR repaired = ()
VAR repaired_checkpoint = ()
VAR total_repaired = 0
VAR can_repair = false // update from within engine when close enough to an antenna.

//n should be in range 1...n
=== antenna_mast(n) ===
{
- repaired? antennas(n): 
    This antenna has already been repaired.
    -> exit
- can_repair:
    Repair the antenna?
    + [Yes]
        ~repaired += antennas(n)
        ~total_repaired = LIST_COUNT(repaired)
        {total_repaired}/3 antennas now active. #CLEAR
        -> exit
    + [No]
        -> end
- else:
    The antenna appears to be broken. You could fix it if you were closer to the top of the mast.
    -> exit
}

// Necessary shortcuts for Godot
=== antenna_mast1 ===
-> antenna_mast(1)

=== antenna_mast2 ===
-> antenna_mast(2)

=== antenna_mast3 ===
-> antenna_mast(3)

// Checkpoints ==================================================================

LIST locations = entrance=0, shed=1, walls=2
VAR spawnpoint = (entrance)

=== set_checkpoint(n) ===
~spawnpoint = locations(n)
~repaired_checkpoint = repaired
Progress saved.
-> exit

// Shortcuts for Godot
=== checkpoint0 ===
-> set_checkpoint(0)

=== checkpoint1 ===
-> set_checkpoint(1)

=== checkpoint2 ===
-> set_checkpoint(2)

=== function respawn() ===
~repaired = repaired_checkpoint
~total_repaired = LIST_COUNT(repaired)
~return LIST_VALUE(spawnpoint)

// Computer ====================================================================

LIST orientation_options = standard, inverse, reversed, flipped
LIST axis_options = X, Y, Z, W, t
LIST frequency_options = 2MHz, 15MHz, 75MHz, 220MHz, 350MHz
VAR selected = ()
VAR correct = (reversed, Z, 15MHz)

=== instructions ===
ACTIVATION INSTRUCTIONS
<br>
Orientation: standard
Primary axis: Y
Frequency: 220 MHz
-> exit

=== computer ===
Initialize activation sequence (y/n)?
+ {total_repaired == 3}[y]
    -> activate
+ {total_repaired < 3}[y]
    ERROR: unable to initialize activation sequence.
    {LIST_COUNT(repaired)}/3 antennas functional.
    Please ensure all antennas are functional and try again.
    -> exit
+ [n]
    -> end 

= activate
Beginning activation sequence.
Select ORIENTATION:
-> choose_from(LIST_ALL(orientation_options)) ->
Select PRIMARY AXIS:
-> choose_from(LIST_ALL(axis_options)) ->
Select FREQUENCY:
-> choose_from(LIST_ALL(frequency_options)) ->
Finalize activation sequence (y/n)?
 + [y]
    The screen goes black for a moment... #CLEAR
    -> continue ->
    The buildings around you begin to move with a shudder.
    -> continue ->
    {selected == correct:
        -> win
    - else:
        -> lose
    }
 + [n]
    SEQUENCE ABORTED
    ~selected = ()
    -> exit

= win
#CLEAR
Suddenly, you feel a strange, disorienting jolt.
-> continue ->
Just as suddenly, you regain awareness.
The facility has returned to normalcy.
The gravitational aberration has been brought under control.
CONGRATULATIONS!
(TODO Write better ending?)
~selected = ()
-> exit

= lose
#CLEAR
Suddenly, the entire facility collapses to the ground with a sickening crash.
As your head rushes towards the concrete, you realize that the activation sequence must have been incorrect.
Not much you can do about it now, though.
-> continue ->
GAME OVER. #CLEAR
(TODO Write ending better).
~selected = ()
-> exit
    

= abort
+ [ABORT]
    SEQUENCE ABORTED
    ~selected = ()
    -> exit

= choose_from(candidates)
<- choice_for_each(candidates)
<- abort
-> DONE

= choice_for_each(candidates)
    {LIST_COUNT(candidates) == 0:
        -> DONE
    }
    ~temp curr = LIST_MAX(candidates)
    <- choice_for_each(candidates - curr)
    + > {curr}
        ~selected += curr
        ->->
    -> DONE



// Signs ------------------------------------------------------------------------

=== entrance_sign ===
WARNING: GRAVITATIONAL ABERRATION
Unsafe for human habitation.
Enter at own risk.
-> exit

=== fenced_sign ===
NOTICE TO STAFF
Employees must fall DOWN at all times.
Walking on walls is strictly forbidden.
Violators will be disciplined.
-> exit

=== anti_union_sign ===
We would like to remind all staff of the collegial relationship between management and labour in this facility.
It is in no one's best interest to let a third party disrupt that relationship while taking a cut of your hard-earned paycheck.
We trust that you will vote accordingly on Friday.
-> exit



=== note_1 ===
Management is going to get us all killed.
They seriously believe that "orientation" should be set to "standard," when it obviously needs to be "reversed."
This is why we need a union!
-> exit

=== note_2 ===
Management really has no clue what they're doing.
They refuse to understand that the frequency [i]needs[/i] to be [b]15 MHz[/b] or the whole place will collapse.
We can't let them do this. Solidarity forever, the union makes us strong!
-> exit

=== note_3 ===
If [b]PRIMARY AXIS[/b] is set to anything other than [b]Z[/b] it will end in disaster!
Fortunately, management can't screw up [i]too[/i] badly while all the antennas are broken.
Keep up the good work, folks! ;)
-> exit

// Other possible flavour text


=== flavour_1 ===
˙ʇɹos ǝɯos ɟo uoᴉʇɐloᴉʌ ∀HSO uɐ ǝq oʇ sɐɥ sᴉɥ┴  ˙dn sᴉ ʎɐʍ ɥɔᴉɥʍ ɹǝqɯǝɯǝɹ uǝʌǝ ʇ,uɐɔ I ƃuol os ǝɹǝɥ dn uǝǝq ǝʌ,I
-> exit




