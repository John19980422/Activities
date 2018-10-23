clear
set more off
/* import dataset*/
import delimited C:\Users\johnz\Desktop\scp-1205.csv, varnames(1) encoding(UTF-8) clear 
/*
  首先我们需要整理数据
  我们先将字符串形式的数据转换成数值型（enrollees and penetration）
  接着我们来处理缺失值问题(缺失值处理为0)
  然后我们来观察一下数据，利用sum命令来获得描述性统计。
*/
destring enrolles , gen (ENROLLES)
destring penetration , gen (PENETRATION)
destring eligibles , gen (ELIGIBLES)
drop enrolles penetration eligibles

replace ENROLLES = 0 if ENROLLES == .
replace PENETRATION = 0 if PENETRATION == .
replace ELIGIBLES = 0 if ELIGIBLES == .

/*
观察数据可知，这个数据集提供了一个“县-合约”级数据集。
文件给出了一个"contract-county pair"，意思就是，一个合约-县 搭对子的 数据集合。
此处可以理解：合约-县，应该是一个双指针。
双指针的具体项目为：countyssa-contract
其内容主要是统计了每一个县，加入不同医疗项目的人数。
变量countyssa 排他地指代了每一个county。每一个县具有两个属性：县名称和所属州。
变量contract 派他地指代了计划合约，每一种合约有两个性质：healty-plan的名称和plan 的类型。

州，列出tab，共有57个代码。其中包含空白（缺失）、99、以及诸如关岛和波多黎各等5个岛屿自由邦、1个特区（DC）和50个州。
题目中说you may exclude territories such at Puerto Rico and Guam，应该需要删除5个岛屿自由邦的内容。
5个岛屿自由邦代码：AS GU MP PR VI (MP不包括其中)
1个特区DC

列为99的，基本都是Unusual SCounty Code的内容，估计是比如写的字太难看了辨认不出来。我们删除这些数据。
列空白的，都是under-11。应该是11岁以下人数的统计，并不是每一个地区都递交了。有些内容的countyssa中显示Guxxx，也就是来自关岛。
但是他们的eligibles都是0，并没有办法按照题目需要的数据汇总。因此全部删除。

为了谨慎和保守起见，我将会递交：1. 55州 2. 53州 3. 50州（主要）概况。
这个只需要if + drop就可以了。


eligibles是全县有医疗保险资格的个人人数 相当于县级人数总体
enrolles是每个县 参加特定卫生计划的个人人数 对于每一个县的这个变量求和 就是全县医保覆盖总数
并且enrolles有一个特征：但凡不是缺失值，最小值为11，大于题目中一个变量要求的10.

题目要求最终递交的是一份县级数据集（也就是一个县一个row，给出一个描述性统计数据集），其中新增
numberofplans1: number of health plans with more than 10 enrollees 
numberofplans2: number of health plans with penetration > 0.5 
这两个变量，应该是统计这一个县里面，有哪一些科目有十个人以上报名；渗透率高于0.5
因此，其计算方式应该是根据县进行分类，然后
n1 标识出科目报名数(enr)大于10 的项目 （bool）
n2 标识出科目渗透率(pen)大于0.5的 的项目 （bool）
然后total 累加求和每一个county 的bool值为1 的项目，也就是项目数量计数。
最后删除辅助变量n1、n2
*/

drop if state == "99"
drop if state == "AS "
drop if state == "GU "
drop if state == "PR "
drop if state == "VI "
drop if state == "MP "
drop if state == "  "


bysort countyssa contract : gen n1 = 1 if (ENROLLES > 10)
bysort countyssa : egen numberofplans1 = total(n1)

bysort countyssa contract : gen n2 = 1 if (PENETRATION > 0.5)
bysort countyssa : egen numberofplans2 = total(n2)

drop n1 n2

/*接下来我们需要处理新增的totalenrollees。totalpenetration根据文件中给出的公式就可以计算得出。
totalenrollees需要我们计算一个县里参加plan的人数，利用egen 配合total 公式进行累加求和。
之后利用 totalpenetration = 100*totalenrollees/eligbles 得出totalpenetration
接下来删除多余的coloums 和rows，我们就可以得到题目所需的东西。
*/

bysort countyssa : egen totalenrollees = total(ENROLLES)
gen totalpenetration = 100*totalenrollees/ELIGIBLES

/*
做到这个时候我们计算完了全部需要计算的科目。现在我们删除多余的column。
*/
keep countyname state numberofplans1 numberofplans2 countyssa ELIGIBLES totalenrollees totalpenetration
/*
现在发现，由于双Key被整理成单Key，因此需要删除重复的数值。
然后排序。
*/

duplicates drop
sort state countyname
/*
保存文件
*/
save "C:\Users\johnz\Desktop\Case1.dta"
