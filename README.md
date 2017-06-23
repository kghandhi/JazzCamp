# JazzCamp

The Class Scheduler schedules a set of jazz camp students into five different classes.
Each student plays an instrument throughout the duration of the camp and is tested to
produce a variety of different metrics about the student. All of these metrics and the
student's instrument are predetermined before the start of the Class Scheduler. 
Additionally we've made a few assumptions about the content and format of the data.

## Assumptions
### Data Format

The script requires a file parameter. This file should be a csv with rows representing
students. Each row should contain
```
last_name, first_name, instrument, instrument_rank, theory_score, musicianship_score, combo_score 
```
Some exceptions to this include 
1. Drummers: 
    - drummers do not need a `musicianship_score` as all drummers are placed into 
      `drum_rudiments` for musicianship
    - do not need a `theory_score`. If they have one, they are placed in the appropriate 
      theory class, but otherwise they're placed into `drum_theory`
2. Vocalists: do not have a musicianship score as they are placed into `vocal_musicianship`


The possible instruments include
1. Bass (electric, acoustic)
2. Cello
3. Clarinet
4. Drums
5. Flute
6. Guitar
7. Piano
8. Saxophone (alto, baritone, soprano, tenor)
9. Trombone
10. Trumpet
11. Vibes
12. Viola
13. Violin
14. Voice

### Data Content

Each week of the camp is restricted in a few ways, so it is assumed that the data reflects 
these restrictions.

Per week the number of drums, pianos, acoustic bass, electric bass, and guitars are capped to
the same number. That number is determined by the number of rooms available for combos. Per week
there will be `drums.length` combos. Additionally the number of rooms and sizes of those rooms
is determined at the point this program is run.

The other instruments are also capped as follows:
https://docs.google.com/a/stanfordjazz.org/spreadsheets/d/1fU0Sg6bJru0MZux0btoP5HybkNlcA4wY9hE_8jKnKSA/edit?usp=sharing


## How are students ranked
### Instrument Rank

Instrument rank is a rank of students in their instrument's family. These families include
- Strings: cello, viola, violin
- Brass: trumpet, trombone
- Woodwinds: clarinet, flute, saxophone
- Vibes: vibes
- Piano: piano
- Guitar: guitar
- Bass: bass
- Drums: drums
this _integer_ is used to schedule `combos` and ranges from `1` (the top instrument in the family) to `num_instruments_in_family`.

### Theory Score

The theory score is an _integer_ between `0` and `47`. This score is used to determine `theory class` placement.

### Musicianship Score

The musicianship score is a _float_ between `0` and `6` and is used to determine `musicianship class` placement.

### Combo Score

The combo score is a _float_ between `0` and `6` and is used to determine `combos` and `split` classes.

## The Classes

There are 5 periods of classes. The first and second period of classes are scheduled for `theory` and `musicianship` 
classes (`EV1` and `EV2`). The third period of classes (called `EV3`) is the `masterclass`. The fouth and fifth periods
are scheduled for `combos` and `splits` (`EV6` and `EV7`). Each student is assigned to one of each type of class. This
means that students who are in early theory are in late musicianship. Students who are in early combos are in late splits.
For each of the periods, there should be an even number of students in `theory`/`musicianship` or `combo`/`split`.

Both `musicianship` and `combo` classes require room considerations. Since some instruments are larger than others
(namely pianoes, guitars, and bass) each room requires a `capacity`, `num_pianos`, and `num_amps`. These attributes
on a room help to determine how to fill the class. Although this script does not specify to which classroom each 
course is assigned, the specifications of the rooms available are taken into consideration. It is up to the jazz
camp itself to decide the assignments of classes to rooms. The rooms are pretty evenly sized, so most of the 
classes will fit in any room. Theory and split classes do not need to take this into consideration. Masterclasses
are per instrument.

Note that vocalists are left out of the last three periods (masterclass, combo, and split).

### Theory Class
Most theory classes are calculated by the _theory score_. Students with theory scores between [43,47] are placed in 
Applied theory. The rest of the students are sorted by their theory scores and evenly divided into the remaining
4 classes per period.

There are a few requirements on how these classes are chosen, though. 
1. Since all drums students are in the same musicianship class (an early class) they must be scheduled for late thoery.
2. Drummers who do not have theory scores (opted not to take the theory test) should be placed in `late_drum_theory`
3. Vocalists are scheduled in early early theory because their musicianship class is late.

### Musicianship Class
Although musicianship classes are limited by room size, they are not restricted in instrumentation. Essentially
the only consideration apart from room size is making sure that students with close enough `musicianship_score`s 
are grouped together in a class.

The requirement is specifically that 
1. The room requirements about capacity are met
2. Students in one musicianship class have very close `musicianship_score`s
3. There should be at most 2 bass, at most 2 guitars, at most 2 pianos, and at most 5 saxophones (of any type) per class 

The way this is achieved is by separating piano-like instruments, amp requiring instruments, and all the rest.
Once they are separated and sorted by `musicianship_score`, students are selected from each of the three lists
to join a musicianship class based on room capacity and deviation from the maximum `musicianship_score` in the
currently selected class. This requires that to be part of a musicianship class, a student's instrument must fit
in the room and that student must have a `musicianship_score` that is at least `1.0` less than the top score in
the group.


### Masterclass

Masterclasses are specific to instrument. There are a different number of masterclasses for each instrument type.
Specifically the instrument to number of masterclasses mapping is:
- Saxophone: 4
- Clarinet: 1
- Strings: 1
- Vocal: 1
- Flute: 1
- Bass: 1
- Drum: 2
- Guitar: 2
- Piano: 2
- Trombone: 2
- Trumpet: 2

The students are sorted by `combo_score` then grouped evenly into the number of masterclasses based on their instrument.
This ensures that the classes are all even in size and students with close `combo_score`s are grouped together.

### Combo

Combos require specific instrumentation. Ideally a combo will have 1 guitarist, 1 pianist, 1 drummer, 1 bassist,
and 4-5 "horn" players. Horn players here are defined as every instrument that isn't a piano, guitar, drum, or bass.

Requirements
1. At most 2 brass players (trumpet or trombone) and at most 3 saxophone players
2. Except for alto and tenor saxophones, all horn components of a combo must be unique


### Split
There are three splits per period (early/late, 6 classes in total). Students are ranked by their `combo_score` and split
evenly into split classes.
