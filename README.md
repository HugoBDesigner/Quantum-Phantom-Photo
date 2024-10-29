# Quantum Phantom Photo
"Spooky action at a distance!" - Albert Einstein, on quantum mechanics

"Quantum Phantom Photo" is a little puzzle game about photographing ghosts with quantum properties! Solve 10 unique puzzles with various mechanics and challenges.  
# [🎮 Play in your browser](https://hugobdesigner.itch.io/quantum-phantom-photo)
[Submission page for the entry on GBJam 12](https://itch.io/jam/gbjam-12/rate/2986227)

<hr>

**🆕 NEW FEATURES!**
- Added Brazilian Portuguese localization! Use the `Options` menu or the `Pause` menu to change language;
- Added controller/gamepad/joystick support! Not all controllers may work correctly;
- Added mobile and touchscreen support! The game may run slower on mobile.

**⚠ Known Issues:**  
- `[Web version]` Keyboard support is faulty on Chrome/Edge. After clicking "Run Game", don't use your mouse. Interact with the keyboard (and use WASD instead of arrows). Play on Firefox or download the game if needed.
- `[Web version]` Saving and loading data (such as last level played, sound settings, and palette preferences) does not work on the Web version. If you refresh the page or close it, you'll lose your progress and preferences. If you wish to save them, please download the desktop version!

Use mouse, keyboard, touch or controller to control the game. Controls:  
| Keys                          | Controller             | Action               |
| ----------------------------- | ---------------------- | -------------------- |
| **WASD / Arrows**             | **DPAD / Right Stick** | Movement / DPAD      |
| **Z / J / Shift / Backspace** | **B / X**              | "B" Button           |
| **X / K / Space**             | **A / Y**              | "A" Button           |
| **C / L**                     | **Select / Back**      | Select               |
| **Enter / Escape**            | **Start**              | Start                |
| **Shift + Tab / [**           | **Left bump**          | Open left side menu  |
| **Tab / ]**                   | **Right bump**         | Open right side menu |

Keyboard-only shortcuts:
| Keys    | Action            |
| ------- | ----------------- |
| **F5**  | Reload the game   |
| **F11** | Toggle fullscreen |


**All puzzle solutions:**  
https://www.youtube.com/watch?v=dsgD0kOBGpA

<hr>

# Build instructions - Desktop

For running the game directly, download [Love2D](https://love2d.org/), specifically version 11.0 (Mysterious Mysteries) of it:  
[https://github.com/love2d/love/releases/tag/11.0](https://github.com/love2d/love/releases/tag/11.0)

You can run the game by dragging and dropping the source code folder (specifically the `DESKTOP` folder on this project) into the Love2D executable (`love.exe`). The `main.lua` file must be at the root of the folder in order for the game to run. For running from an IDE or text editor, refer to this guide: [https://love2d.org/wiki/Getting_Started#Running_Games](https://love2d.org/wiki/Getting_Started#Running_Games).

You can also convert the game into a `.love` file, which runs directly on Love2D. To make a `.love` file, compress the game's code (the contents of the `DESKTOP` folder) into a ZIP file, such that `main.lua` is on the root folder. If `main.lua` is inside a subfolder in the ZIP, the game won't run. Then, double-click to run or drag-and-drop it into the Love2D executable (`love.exe`).

Finally, to create an executable, refer to [this page](https://love2d.org/wiki/Game_Distribution). Creating an executable requires a `.love` file, so follow the instructions above.

<hr>

# Build instructions - Web

Building for web requires the creation of a `.love` file. So refer to the instructions above for that.

To generate updated web files, go to [https://schellingb.github.io/LoveWebBuilder/](https://schellingb.github.io/LoveWebBuilder/). This page converts `.love` projects from 11.0 into browser-playable games. You can test run the game with the `Run Project` header link, or build and download the web files using the `Build Package` header link.

On the `Build Package` page, select the `.love` file of the game in the "File Selection" area. On "Build Settings", select `Two files (HTML+JS) with loading progress bar` (should be the default option). Write a filename for the project (I've chosen `game` for mine). The fields of "Title", "Description" and "Author" are optional and only show up in the Web Builder preset page (which this project modifies). So you can leave them blank. For "Initial Player Resolution", choose `1280` x `720`. Finally, set "Memory Size" to `64` MB, and "Stack Size" can be left at `2` MB. Click "Build Package".

The downloaded package ZIP contains two files: an HTML file and a JavaScript file. In this project, I use a modified HTML page, that removes extraneous elements such as headers and footers, so it is proper for uploading to itch.io. If you wish to do the same, simply ignore the HTML file provided by the built package and use the `index.html` file provided in the `WEB` folder of the project. This will require that your JavaScript file be named `game.js` (as seen in the package building settings). Simply replace the `game.js` file on the `WEB` folder with the one you generated, and ZIP the two together, in order to upload to sites like itch.io.

<hr>

This project is licensed under the [Creative Commons Attribution-ShareAlike 4.0 License](https://creativecommons.org/licenses/by-sa/4.0/).
