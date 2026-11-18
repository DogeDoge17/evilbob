# Evilbob

A multithreaded 2.5D ray caster 'horror' game made in zig.
<img width="1400" height="1049" alt="image" src="https://github.com/user-attachments/assets/99d6f829-1adf-49d0-9f82-8406e8668b50" />

# How To Play

- View your checklist for the tasks you must complete in your run. They will
  randomize each night.
  - You clean tables in the dining room.
  - You clean the toilets in the restroom. That can be found to the far right of
    the kitchen while facing away from the main entrance
  - You count money at the boat where Squidward stands in.
  - You do the dishes in the kitchen. The kitchen can be found through either
    the middle door in the dining room or the back entrance.
  - You take out the trash by first going into the bathroom. The bathroom is the
    door on the right. After collecting the trash, you must take it to the
    dumpster behind the building. The dumpster can be reached either by walking
    around the building or going through the kitchen back door.
- Run away from Evilbob. If he catches you, then your run is over.
- Control
  - WS: Move forward and backward
  - Left Right AD(untoggled): Look left and right
  - AD(toggled): Strafe left and right
  - Shift: Toggles tank controls for WASD. Allows AD to strafe.
  - E: Do closest task. You must hold it for the task to progress.
  - Space: Quickly peek behind yourself
  - Tab: Hide the task list
  - Escape: Pause
  - Enter: Starts the game when in the menu

# Building

Ensure you have [Zig](https://ziglang.org/download/) 0.17.1 installed\
Clone the repo

```
git clone https://github.com/DogeDoge17/evilbob.git
cd evilbob
```

Run the game

```
zig build run -Doptimize=ReleaseFast
```
