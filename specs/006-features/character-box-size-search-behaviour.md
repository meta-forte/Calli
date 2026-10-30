
-  The home page that shows HSK level characters has an issue: The Pinyin English/Romanized letters are not fitting in the rounded rectangles. Ex: Chuang & "dou, du". There is atleast 50 px space between columns. Increase the character box size so that the space is ample for the character.
- Introduce a fontsize slider - 3 sizes should be good enough I think. On top right create a Gear icon that opens a pop-up/modal where user can increase the font size. Retain the font-size for future app launches.

### Observations on how search is working
- When I select HSK Level 3, and search for "Fu", the search brings up "dan", "duan" (3 Duan characters each with a different tone), duo, fu, and yu. 
- When I select HSK level 2, and search for "Fu", it returned "le". In level 9, it returned bo, chuo, fa, fang, fen, long, mian etc.,  
- The search behaviour is somewhat misleading to me. Also, the search feature is searching within the set of characters of a particular level. Move the search bar up and place the "HSK level" drop down below it. Let the search work across all levels and also in ../../docs/chinese-stroke-order.pdf. 
- Group search results into HSK levels . If a character matches are not found in HSK levels but found in "chinese-stroke-order.pdf", those matches should be shown in "Others" section. If the search bar is cleared, then show all characters of the selected level (by default Level 1).
- If user selects a Level (say Level 3), the selection should be retained for subsequent App Launches.




