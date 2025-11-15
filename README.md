# Evilbob

A multithreaded 2.5D raycaster made in zig. 
<img width="1400" height="1049" alt="image" src="https://github.com/user-attachments/assets/99d6f829-1adf-49d0-9f82-8406e8668b50" />

# How to play
* View your check list for the tasks you must complete in your run. They will randomize each night.
  - You clean tables in the dining room.
  - You clean the toilets in the restroom. That can be found to the far right of the kitchen while facing away from the main enterance
  - You count money at the boat where squidward stands in.
  - You do the dishes in the kitchen. The kitchen can be found through either the middle door in the dining room or the back enterance.
  - You take out the trash by first going into the bathroom. The bathroom is the door on the right. After collecting the trash, you must take it to the dumpster behind the building. The dumpster can be reached either by walking around the building or going through the kitchen backdoor.
* Run away from Evilbob. If he catches you, then your run is over.
* Control
  - WS: Move forward and backward
  - AD Left Right: Look left and right
  - SHIFT+AD: Strafe left and right
  - E: Do closest task. You must hold it for the task to progress.
  - Space: Quickly peek behind yourself
  - Tab: Hide the task list
  - Escape: Pause
  
    
# Building
Ensure you have [Zig](https://ziglang.org/download/) 0.15.2 installed
Clone the repo
```
git clone https://github.com/DogeDoge17/evilbob.git
cd evilbob
```
Run the game
```
zig build run
```

