## Introduction
- the folder ../docs has Chinese HSK exam related official documents.
- I want a IOS Swift/Swift UI app (that can be converted to android app later) that has below features

## Features

- At the top of the screen there should be a drop down with label HSK Level. User should be able to select values in the range of 1-9
- the list of chinese characters should be shown in a grid. Each cell of the grid  is rounded square and font size of 16 px. The characters should be listed in the same order as they are in the CSV file.
- Below it the romanized pinyin should be shown in the same cell below the Chinese character. 
- when the button is clicked it should show the character in large size - almost the size of the screen excluding margins.
- The character should be shown in dark gray color. Then it should start tracing the first stroke in a different color. Let the user use their finger to trace the stroke. The system moves to trace the next stroke and waits for the user to trace it as well.
- The stroke order for each character is in the ../docs/chinese-stroke-order.pdf file. 
- Is it possible to play the audio for the pinyin when the tracing is done ? If so add that feature as well

PS - Setup a git repo in the project folder. Initiate with a .gitignore that is typical of a ios app project. Commit and push the code to https://github.com/meta-forte/Calli.git
