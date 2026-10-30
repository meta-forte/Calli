# Open-Source Acknowledgements and Legal Disclaimers

HanziSlate is developed by Ibhatech as an independent educational study aid. This document details the open-source software, datasets, typography, and standard specifications utilized within the application.

---

## 1. Trademark Notice and Fair Use Disclaimer

**HSK (Hànyǔ Shuǐpíng Kǎoshì)** is a registered trademark of Chinese Testing International (CTI).

This application is an independent educational study tool and is not officially affiliated with, sponsored by, endorsed by, or certified by Chinese Testing International (CTI), Hanban, or the Center for Language Education and Cooperation (CLEC) of the Chinese Ministry of Education.

References to "HSK" (such as "HSK 1" through "HSK 9") are used solely under the doctrine of nominative fair use to describe the factual syllabus alignment and grading levels defined in public educational standards.

---

## 2. MakeMeAHanzi and Arphic PL Fonts

HanziSlate utilizes Chinese character stroke order vectors and graphics derived from the open-source **MakeMeAHanzi** project created by Shapecatcher / skishore:
- Repository: [https://github.com/skishore/makemeahanzi](https://github.com/skishore/makemeahanzi)

The stroke graphics in MakeMeAHanzi are derived from the Arphic PL KaitiM GB and PL UKai fonts, released by Arphic Technology Co., Ltd. under the **Arphic Public License (APL)**.

### Full Text of the Arphic Public License (1999)

```text
ARPHIC PUBLIC LICENSE

Copyright (C) 1999 Arphic Technology Co., Ltd.
11Fl. No.168, Yung Chi Rd., Taipei, 110 Taiwan
All rights reserved except as specified below.

Everyone is permitted to copy and distribute verbatim copies of this license document, but changing it is forbidden.

Preamble

   The licenses for most software are designed to take away your freedom to share and change it. By contrast, the ARPHIC PUBLIC LICENSE specifically permits and encourages you to use this software, provided that you give the recipients all the rights that we gave you and make sure they can get the modifications of this software.

Legal Terms

0. Definitions:
   Throughout this License, "Font" means the TrueType fonts "AR PL Mingti2L Big5", "AR PL KaitiM Big5" (BIG-5 character set) and "AR PL SungtiL GB", "AR PL KaitiM GB" (GB character set) which are originally distributed by Arphic, and the derivatives of those fonts created through any modification including modifying glyph, reordering glyph, converting format, changing font name, or adding/deleting some characters in/from glyph table.

   "PL" means "Public License".

   "Copyright Holder" means whoever is named in the copyright or copyrights for the Font.

   "You" means the licensee, or person copying, redistributing or modifying the Font.

   "Freely Available" means that you have the freedom to copy or modify the Font as well as redistribute copies of the Font under the same conditions you received, not price. If you wish, you can charge for this service.

1. Copying & Distribution
   You may copy and distribute verbatim copies of this Font in any medium, without restriction, provided that you retain this license file (ARPHICPL.TXT) unaltered in all copies.

2. Modification
   You may otherwise modify your copy of this Font in any way, including modifying glyph, reordering glyph, converting format, changing font name, or adding/deleting some characters in/from glyph table, and copy and distribute such modifications under the terms of Section 1 above, provided that the following conditions are met:

   a) You must insert a prominent notice in each modified file stating how and when you changed that file.

   b) You must make such modifications Freely Available as a whole to all third parties under the terms of this License, such as by offering access to copy the modifications from a designated place, or distributing the modifications on a medium customarily used for software interchange.

   c) If the modified fonts normally reads commands interactively when run, you must cause it, when started running for such interactive use in the most ordinary way, to print or display an announcement including an appropriate copyright notice and a notice that there is no warranty (or else, saying that you provide a warranty) and that users may redistribute the Font under these conditions, and telling the user how to view a copy of this License.

   These requirements apply to the modified work as a whole. If identifiable sections of that work are not derived from the Font, and can be reasonably considered independent and separate works in themselves, then this License and its terms, do not apply to those sections when you distribute them as separate works. Therefore, mere aggregation of another work not based on the Font with the Font on a volume of a storage or distribution medium does not bring the other work under the scope of this License.

3. Condition Subsequent
   You may not copy, modify, sublicense, or distribute the Font except as expressly provided under this License. Any attempt otherwise to copy, modify, sublicense or distribute the Font will automatically retroactively void your rights under this License. However, parties who have received copies or rights from you under this License will keep their licenses valid so long as such parties remain in full compliance.

4. Acceptance
   You are not required to accept this License, since you have not signed it. However, nothing else grants you permission to copy, modify, sublicense or distribute the Font. These actions are prohibited by law if you do not accept this License. Therefore, by copying, modifying, sublicensing or distributing the Font, you indicate your acceptance of this License and all its terms and conditions.

5. Automatic Receipt
   Each time you redistribute the Font, the recipient automatically receives a license from the original licensor to copy, distribute or modify the Font subject to these terms and conditions. You may not impose any further restrictions on the recipients' exercise of the rights granted herein. You are not responsible for enforcing compliance by third parties to this License. 

6. Contradiction
   If, as a consequence of a court judgment or allegation of patent infringement or for any other reason (not limited to patent issues), conditions are imposed on you (whether by court order, agreement or otherwise) that contradict the conditions of this License, they do not excuse you from the conditions of this License. If you cannot distribute so as to satisfy simultaneously your obligations under this License and any other pertinent obligations, then as a consequence you may not distribute the Font at all. For example, if a patent license would not permit royalty-free redistribution of the Font by all those who receive copies directly or indirectly through you, then the only way you could satisfy both it and this License would be to refrain entirely from distribution of the Font.

   If any portion of this section is held invalid or unenforceable under any particular circumstance, the balance of the section is intended to apply and the section as a whole is intended to apply in other circumstances. 

7. NO WARRANTY
   BECAUSE THE FONT IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE FONT, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS OR OTHER PARTIES PROVIDE THE FONT "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE FONT IS WITH YOU. SHOULD THE FONT PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

8. DAMAGES WAIVER
   UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING, IN NO EVENT WILL ANY COPYRIGHT HOLDERS, OR OTHER PARTIES WHO MAY COPY, MODIFY OR REDISTRIBUTE THE FONT AS PERMITTED ABOVE, BE LIABLE TO YOU FOR ANY DIRECT, INDIRECT, CONSEQUENTIAL, INCIDENTAL, SPECIAL OR EXEMPLARY DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE FONT (INCLUDING BUT NOT LIMITED TO PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA OR PROFITS; OR BUSINESS INTERRUPTION), EVEN IF SUCH HOLDERS OR OTHER PARTIES HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
```

---

## 3. Unihan Database and CJKlib (Dictionary Metadata)

Dictionary metadata and definitions are derived from:
- The Unicode Consortium's **Unihan Database**: [https://www.unicode.org/charts/unihan.html](https://www.unicode.org/charts/unihan.html)
- **CJKlib**: Released under the GNU Lesser General Public License v3 (LGPL-3.0) or later: [https://www.gnu.org/licenses/lgpl-3.0.html](https://www.gnu.org/licenses/lgpl-3.0.html)

---

## 4. HSK 3.0 Standard Curriculum

Character lists, word classifications, and proficiency levels (Levels 1 through 9) are aligned with the official standard published by the Ministry of Education of the People's Republic of China and the National Language Commission:
- Standard: *Chinese Proficiency Grading Standards for International Chinese Language Education* (《国际中文教育中文水平等级标准》, Standard Code: GFS 001-2021).
- Publisher: Center for Language Education and Cooperation (CLEC) / Ministry of Education, PRC.
