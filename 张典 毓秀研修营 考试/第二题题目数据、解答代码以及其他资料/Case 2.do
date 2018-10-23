/*
先观察数据。
首先我们可以看出，这是一份类似于抽查的数据。分别记录了：
抽查年月，州，年纪性别，职业，种族，教育，劳动-收入状态等信息。
其中：
年龄 有分组
种族 有大类分组、拉丁裔分组、白人bool变量
教育 有具体教育状态和是否接受过高等教育
劳动 有是否劳动力、劳动状态、去年工作星期数量和分组、每周一般工作时长等
收入状态有总个体收入、个体工薪收入、工作时薪收入。
*/

clear

/*
核心是回答受教育和没受教育的人 工资和劳动参与率的变化。
看题目，四个小问题。
a）总结工资和劳动力参与的主要趋势。（基本）
B）在25岁以上的男性中，哪些群体的劳动力参与发生了最大的变化？（基本）
C）你认为哪些因素在驱动这些模式？（中级）
D）如果你要进一步研究这些假设，你想收集哪些证据来检验这些假设？（困难）


3. 什么因素导致了这个现象的出现？
4. 你之后进一步分析会需要什么材料？
*/

set more off
use "C:\Users\johnz\Desktop\cps_wages_LFP.dta" 
/*尝试出来，educ这个栏目里，本科学历是111，硕士是123，博士是125. 这真的很累。。。
数据集要附件文档啊！！！！！！！
好吧我知道很多数据真的没有文档我懂......
1992年开始有这三个学历统计。
发现类似于抽样调查，用一阶差分是不可行的。
那只能够看，在juv组内，拥有ba学历的人数比重了。
不断地试错尝试是最花费时间的......
*/

bysort year: egen lfpr = mean(lfp) if lfp != ./*劳动参与率,最高的是2001年*/

bysort year: egen Avewage = mean(wage) if empstatid == 2/*在被雇佣的人里面计算时薪平均数字*/

/*
接下来我们要在不同的人群中来探究劳动参与率差异的问题。
先把整个数据的大样子刻画出来，在考虑细分细节。
我们分：性别、人种、受教育程度来分别考虑这个问题。
*/

bysort year sex: egen lfpr_sex = mean(lfp) if lfp != ./*依据性别来进行分类*/
bysort year age_group: egen lfpr_age = mean(lfp) if lfp != ./*依据年纪来分类*/
bysort year white: egen lfpr_white = mean(lfp) if lfp != ./*依据是否是白人来分类*/
bysort year skilled: egen lfpr_edu = mean(lfp) if lfp != ./*依据教育程度来分类*/

gen men_lfpr = lfpr_sex if sex == 1
gen women_lfpr = lfpr_sex if sex == 2

gen juv_lfpr = lfpr_age if age_group == 0
gen you_lfpr = lfpr_age if age_group == 1
gen mid_lfpr = lfpr_age if age_group == 2
gen old_lfpr = lfpr_age if age_group == 3

gen whi_lfpr = lfpr_white if white == 1
gen nwh_lfpr = lfpr_white if white == 0

gen edu_lfpr = lfpr_edu if skilled == 1
gen ned_lfpr = lfpr_edu if skilled == 0

/*
对wage也做一个
wage的话，很多人是缺失值。我们就先按照没有缺失的来探究。
*/
bysort year sex: egen wage_sex = mean(wage) if wage != ./*依据性别来进行分类*/
bysort year age_group: egen wage_age = mean(wage) if wage != ./*依据年纪来分类*/
bysort year white: egen wage_white = mean(wage) if wage != ./*依据是否是白人来分类*/
bysort year skilled: egen wage_edu = mean(wage) if wage != ./*依据教育程度来分类*/

gen men_wage = wage_sex if sex == 1
gen women_wage = wage_sex if sex == 2


gen juv_wage = wage_age if age_group == 0
gen you_wage = wage_age if age_group == 1
gen mid_wage = wage_age if age_group == 2
gen old_wage = wage_age if age_group == 3

gen whi_wage = wage_white if white == 1
gen nwh_wage = wage_white if white == 0

gen edu_wage = wage_edu if skilled == 1
gen ned_wage = wage_edu if skilled == 0


/*开始关注进一步的归因问题。*/

bysort year: egen aveinct = mean(inctot) if lfp != . /*每年平均总收入*/
bysort year: egen aveincw = mean(incwage) if lfp != . /*每年平均工薪总收入*/
gen wtr = aveincw/aveinct /*工薪收入占平均总收入占比*/

/*统计样本中年龄人口占比*/
gen old = 1 if age_group == 3
gen mid = 1 if age_group == 2
gen you = 1 if age_group == 1
gen juv = 1 if age_group == 0

bysort year: egen numo = total(old)
bysort year: egen numm = total(mid)
bysort year: egen numy = total(you)
bysort year: egen numj = total(juv)

gen numpopu = numo+numm+numy+numj

gen oldr = numo/numpopu
gen minr = numm/numpopu
gen your = numy/numpopu
gen juvr = numj/numpopu

drop old mid you juv numo numm numy numj numpopu

/*然后，在劳动力中，分别对于种族 进行人口结构探索。
*/
gen wlf = 1 if lfp!= .
bysort year: egen totlf = total(wlf)/*每年适龄人口总数*/
bysort year: egen totwhi = total(white) if lfp != ./*每年适龄白人总数*/
gen whp = totwhi/totlf


/* ················································
现在，删除25岁以下的人口。（juv）我们再来看一看，25岁以上的同志们的整个情况。
*/


clear
set more off
use "C:\Users\johnz\Desktop\cps_wages_LFP.dta" 
drop if age < 26
bysort year: egen lfpr = mean(lfp) if lfp != ./*劳动参与率*/
bysort year: egen Avewage = mean(wage) if empstatid == 2/*在被雇佣的人里面计算时薪平均数字*/

/*劳动参与率*/

bysort year sex: egen lfpr_sex = mean(lfp) if lfp != ./*依据性别来进行分类*/
bysort year white: egen lfpr_white = mean(lfp) if lfp != ./*依据是否是白人来分类*/
bysort year skilled: egen lfpr_edu = mean(lfp) if lfp != ./*依据教育程度来分类*/

gen men_lfpr = lfpr_sex if sex == 1
gen women_lfpr = lfpr_sex if sex == 2

gen whi_lfpr = lfpr_white if white == 1
gen nwh_lfpr = lfpr_white if white == 0

gen edu_lfpr = lfpr_edu if skilled == 1
gen ned_lfpr = lfpr_edu if skilled == 0


/*薪水*/

bysort year sex: egen wage_sex = mean(wage) if wage != ./*依据性别来进行分类*/
bysort year white: egen wage_white = mean(wage) if wage != ./*依据是否是白人来分类*/
bysort year skilled: egen wage_edu = mean(wage) if wage != ./*依据教育程度来分类*/

gen men_wage = wage_sex if sex == 1
gen women_wage = wage_sex if sex == 2

gen whi_wage = wage_white if white == 1
gen nwh_wage = wage_white if white == 0

gen edu_wage = wage_edu if skilled == 1
gen ned_wage = wage_edu if skilled == 0

/*人口结构*/
gen wlf = 1 if lfp!= .
bysort year: egen totlf = total(wlf)/*每年适龄人口总数*/
bysort year: egen totwhi = total(white) if lfp != ./*每年适龄白人总数*/
gen whp = totwhi/totlf


/*接下来可以做的数据整理：
女性受教育人数的变化
各个族裔受教育人数的变化
以及一些族裔人口占比数据
*/

gen Women_Edu = 1 if (sex == 1 & skilled == 1)
bysort year: egen numew = total(Women_Edu)
bysort year: egen numw = total(sex)
gen wer_w = numew/numw

gen Black = 1 if race == 200
gen Latino = 1 if (hispan != . & hispan != 0)

bysort year: egen numBl = total(Black)
bysort year: egen numLa = total(Latino)

gen EduBl = 1 if (Black == 1 & skilled == 1)
gen EduLa = 1 if (Latino == 1 & skilled == 1)

bysort year: egen numEBL = total(EduBl)
bysort year: egen numELA = total(EduLa)

gen ber = numEBL/numBl
gen Laer = numELA/numLa

gen White_Edu = 1 if(white == 1 & skilled == 1)
bysort year: egen numewhi = total(White_Edu)
bysort year: egen numwhi = total(white)
gen whier_w = numewhi/numwhi

bysort year: egen totBla = total(Black) if lfp != ./*每年适龄黑人总数*/
gen Blp = totBla/totlf

bysort year: egen totLat = total(Latino) if lfp != ./*每年适龄拉丁人总数*/
gen Lap = totLat/totlf 




