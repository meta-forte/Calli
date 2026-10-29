
## Defect 2 

- I manually tried the app on simulator and iphone 12.
- The blue color stroke you show is not aligning with the strokes of the underlying NOTO font characters. How are you computing the stroke trace path? Are you using system font or some other base calligraphic character shapes instead of the NOTO SANS TTF file entries? Should you use NOTO Traditional chinese font instead of the SANS font?
- The blue stroke is quite thicker thank the font size you show in gray color.
- The black color stroke I type is also very thick. I wanted these two to be almost same size as the font size you use for NOTO SANS character. I want the strokes to actually be 2 to 5% thinner than the font size you use.
- I tried the character "Cai" (Vegetable, dish, food". 
- If I quickly draw the black stroke as soon as the blue stroke is finished or about to finish, the next blue stroke appears only 5% of the required length
- Do not run  UI Tests. Run basic code unit tests. Let me do manual testing. The reason is that your test runs are taking too long for me to give feedback.
- Do not ask for permission to run ./venv/bin/python as long as the code you write is about reading and writing files within this project folder




##  Defect 1 - Fix attempted - Ignore this section
- For a given chinese character, the app shows Noto font character and ALL strokes to be traced all at once. I want it to show only the NEXT stroke to be traced.
- The app creates artificial manual inaccurate trace line. Do not do this. Create a trace stroke line the fills the exact dimension of the font's stroke, in the shape of the font's strokes. No need to artificially imitate the hand written style wiggles and inaccuraate angles
- When I trace it, make the stroke be almost as thick as the underlying font. Make minor corrections to my strokes to match them the font face stroke. However, if I write a stroke longer than what is needed keep the inaccuracy and let it be so.
- If I draw each stroke as close as possible to your guideline, count it as a repetition. Make minor corrections, but do not correct too short stroke or too long strokes. Corrections to be made for angular bends that come due to natural human finger vibration. 
- Make the app background  color as #efefef. 
- You have a FONT character, a light gray stroke per each stroke, which looks like some stroke traced by a child. That level of artificial human like strokes is unnecessary
- The light gray strokes that appear over the character are redundant. Just trace the next stroke NEATLY and then make it disappear. Retain what I retrace with some corrections to wiggles
- I updated the bunde prefix in project.yml. Update them in the source code and xcodeproject
