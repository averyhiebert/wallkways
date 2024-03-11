-> default

=== default ===
This is a TEMP test of ink.
Test.
* Test1
* Test2
-
Done
-> DONE

=== exit ===
+ [Ok.]
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
        {3 - total_repaired}/3 antennas remaining. #CLEAR
        -> exit
    + [No]
        -> DONE
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
    -> DONE

= activate
Activating computer.
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

=== instructions ===
TODO INSERT INCORRECT INSTRUCTIONS
-> exit

=== note_1 ===
Management is going to get us all killed.
They seriously believe that INSERT SETTING should be set to TODO and not TODO.
This is why we need a union!
-> exit

=== note_2 ===
Management really has no clue what they're doing.
They refuse to understand that TODO needs to be TODO or the whole place will collapse.
We can't let them do this. Solidarity forever, the union makes us strong!
-> exit

=== note_3 ===
If TODO is set to anything other than TODO it will end in disaster.
Fortunately, management can't screw up [i]too[/i] badly while all the antennas are broken.
Keep up the good work, folks! ;)
-> exit

// Other possible flavour text


=== flavour_1 ===
˙ʇɹos ǝɯos ɟo uoᴉʇɐloᴉʌ ∀HSO uɐ ǝq oʇ sɐɥ sᴉɥ┴  ˙dn sᴉ ʎɐʍ ɥɔᴉɥʍ ɹǝqɯǝɯǝɹ uǝʌǝ ʇ,uɐɔ I ƃuol os ǝɹǝɥ dn uǝǝq ǝʌ,I
-> exit




