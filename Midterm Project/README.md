# Midterm Project

## 特別感謝
這次主要是參考群組中豪哥提供的架構去實作。

## 硬體架構
![image](https://github.com/Justin5567/2022-Spring-ICLab/blob/main/Midterm%20Project/image/pipeline.jpg)

SRAM的部分主要是在Area與Through put之間做衡量，開越多小的Sram可以一次輸出越多的data，但是卻會造成Area巨量增加。
最終選擇使用4Sram的方法。
![image](https://github.com/Justin5567/2022-Spring-ICLab/blob/main/Midterm%20Project/image/sram_compare.png)



## 心得
透過pipeline可以讓through put從原本window method一次讀一個增加到一次讀四個輸入，可以有效的減少latenct。
由於這次算是第一次實作pipeline沒有處理好邊界條件問題造成第一次demo沒有通過，最後拿了第八名卻被打七折蠻可惜的不然原本可以接近滿分。