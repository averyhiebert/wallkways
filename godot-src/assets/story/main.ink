VAR DEBUG = false
-> default

// Utils ==============================================================

=== default ===
~can_repair = true
Debugging hub
+ [antenna 1]
    -> antenna_mast1
+ [antenna 2]
    -> antenna_mast2
+ [antenna 3]
    -> antenna_mast3
+ [computer]
    -> computer
+ [exit]
    -> DONE
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

// Main Menu ======================================================================
VAR BLACK_BACKGROUND = false

=== main_menu
[center]WALLKWAYS[/center] #CLEAR
[center]=========[/center]
+ [Play]
  ~BLACK_BACKGROUND = true
  -> prologue
+ [Controls]
  -> controls
+ [Credits]
  -> credits

= controls
[center]Controls[/center] #CLEAR
[center]========[/center]
W/A/S/D or ARROW KEYS to move
SPACE or SHIFT to jump
LEFT CLICK to inspect/interact
RIGHT CLICK for flashlight
ESC for pause menu / settings
+ [Main Menu]
  -> main_menu

= credits
[center]Credits[/center] #CLEAR
[center]=======[/center]
<br>
A game by Avery Hiebert.
<br>

AUDIO
"Mountain pyrenees early evening bird" by PLukx of freesound.org
CC0
freesound.org/people/PLukx/sounds/430588/
<br>

PBR MATERIALS
Created using multiple materials from ambientcg.com,
licensed under the Creative Commons CC0 1.0 Universal License.
<br>

FONT
Font used is Share Tech Mono

Copyright (c) 2012, Carrois Type Design, Ralph du Carrois (post@carrois.com www.carrois.com), with Reserved Font Name 'Share'

This Font Software is licensed under the SIL Open Font License, Version 1.1.
This license is available with a FAQ at openfontlicense.org

+ [Main Menu]
  -> main_menu


// Prologue =======================================================================

=== prologue ===
~BLACK_BACKGROUND = true
The Gravitational Aberration appeared unexpectedly 15 years ago, severely disrupting the local ecosystem.
-> continue ->
A research facility was quickly established to investigate and, hopefully, eliminate the Aberration.
-> continue ->
However, the facility was shut down and abandoned 12 years ago due to labour issues.
-> continue ->
Allegedly, the facility was on the verge of resolving the Aberration at the time when it was shut down.
-> continue ->
Now, 12 years later, you have been dispatched to finish what was started and resolve the Aberration.  Good luck.
+ [Begin your investigation...]
    ~BLACK_BACKGROUND = false
    # LEVEL1
    Good luck...
    ++ [placeholder]
        -> DONE

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

EXTERNAL player_upright()
=== function player_upright ===
~return true

=== set_checkpoint(n) ===
{player_upright():
    ~spawnpoint = locations(n)
    ~repaired_checkpoint = repaired
    Progress saved.
- else:
    You can only save progress while oriented vertically.
}
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
+ {total_repaired == 3}[> y]
    -> activate
+ {total_repaired < 3}[> y]
    ERROR: unable to initialize activation sequence.
    {LIST_COUNT(repaired)}/3 antennas functional.
    Please ensure all antennas are functional and try again.
    -> exit
+ [> n]
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
 + [> y]
    ~BLACK_BACKGROUND = true
    The screen goes black for a moment... #CLEAR
    -> continue ->
    The buildings around you begin to move with a shudder...
    -> continue ->
    {selected == correct:
        -> win
    - else:
        -> lose
    }
 + [> n]
    SEQUENCE ABORTED
    ~selected = ()
    -> exit

= win
#CLEAR
Suddenly, you feel a strange, disorienting jolt.
-> continue ->
Just as suddenly, you regain awareness.
Everything feels normal.
-> continue ->
The Gravitational Aberration has been resolved.
The local environment will thrive again.
-> continue ->
CONGRATULATIONS!
<br>
Thanks for playing!
If you enjoyed the game, please consider paying for it :)
+ [Main Menu]
    # MAIN_MENU
    -> exit

= lose
#CLEAR
Suddenly, the entire facility collapses to the ground with a sickening crash.
-> continue ->
As your head rushes towards the concrete, you realize that the activation sequence must have been incorrect.
-> continue ->
The facility has been destroyed, the Aberration remains, and the local environment may never recover.
-> continue ->
GAME OVER. #CLEAR
<br>
Thanks for playing!
A better ending is still possible, if you're up for it.
<br>
If you enjoyed the game, please consider paying for it :)
+ [Main Menu]
    # MAIN_MENU
    -> exit
    

= abort
+ [> ABORT]
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
    + [> {curr}]
        ~selected += curr
        ->->
    -> DONE



// Signs ------------------------------------------------------------------------

=== entrance_sign ===
WARNING: GRAVITATIONAL ABERRATION
<br>
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



