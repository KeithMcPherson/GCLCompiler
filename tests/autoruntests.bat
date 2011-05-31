@echo off
cd ..\bin
java -cp . gcl.GCLCompiler ..\tests\test0 ..\tests\results\test0list.txt 
..\sam3-pc.exe
..\macc3-pc.exe <..\tests\test0.dat >..\tests\results\test0.result
java -cp . gcl.GCLCompiler ..\tests\test0.fix ..\tests\results\test0fixlist.txt 
..\sam3-pc.exe
..\macc3-pc.exe <..\tests\test0.dat >..\tests\results\test0fix.result
java -cp . gcl.GCLCompiler ..\tests\test1_1 ..\tests\results\test1_1list.txt 
..\sam3-pc.exe
..\macc3-pc.exe <..\tests\test1_1.dat >..\tests\results\test1_1.result
java -cp . gcl.GCLCompiler ..\tests\test1_2 ..\tests\results\test1_2list.txt 
..\sam3-pc.exe
..\macc3-pc.exe <..\tests\test1_1.dat >..\tests\results\test1_2.result
java -cp . gcl.GCLCompiler ..\tests\test2 ..\tests\results\test2list.txt 
..\sam3-pc.exe
..\macc3-pc.exe  >..\tests\results\test2.result
java -cp . gcl.GCLCompiler ..\tests\test3 ..\tests\results\test3list.txt 
..\sam3-pc.exe
..\macc3-pc.exe  >..\tests\results\test3.result
java -cp . gcl.GCLCompiler ..\tests\test4 ..\tests\results\test4list.txt 
..\sam3-pc.exe
..\macc3-pc.exe  >..\tests\results\test4.result
java -cp . gcl.GCLCompiler ..\tests\test4_1 ..\tests\results\test4_1list.txt 
..\sam3-pc.exe
..\macc3-pc.exe  >..\tests\results\test4_1.result
java -cp . gcl.GCLCompiler ..\tests\test5 ..\tests\results\test5list.txt 
..\sam3-pc.exe
..\macc3-pc.exe  >..\tests\results\test5.result
java -cp . gcl.GCLCompiler ..\tests\test5_1 ..\tests\results\test5_1list.txt 
..\sam3-pc.exe
..\macc3-pc.exe  >..\tests\results\test5_1.result
java -cp . gcl.GCLCompiler ..\tests\test6 ..\tests\results\test6list.txt 
..\sam3-pc.exe
java -cp . gcl.GCLCompiler ..\tests\test7 ..\tests\results\test7list.txt 
..\sam3-pc.exe
..\macc3-pc.exe  >..\tests\results\test7.result
java -cp . gcl.GCLCompiler ..\tests\test8 ..\tests\results\test8list.txt 
..\sam3-pc.exe
..\macc3-pc.exe  >..\tests\results\test8.result
java -cp . gcl.GCLCompiler ..\tests\test9 ..\tests\results\test9list.txt 
..\sam3-pc.exe
..\macc3-pc.exe  <..\tests\test9.dat >..\tests\results\test9.result
java -cp . gcl.GCLCompiler ..\tests\test9_1 ..\tests\results\test9_1list.txt 
..\sam3-pc.exe
..\macc3-pc.exe  <..\tests\test9_1.dat >..\tests\results\test9_1.result
java -cp . gcl.GCLCompiler ..\tests\test9_2 ..\tests\results\test9_2list.txt 
..\sam3-pc.exe
..\macc3-pc.exe  >..\tests\results\test9_2.result
java -cp . gcl.GCLCompiler ..\tests\test9_3 ..\tests\results\test9_3list.txt 
..\sam3-pc.exe
java -cp . gcl.GCLCompiler ..\tests\test10 ..\tests\results\test10list.txt 
java -cp . gcl.GCLCompiler ..\tests\test10_1 ..\tests\results\test10_1list.txt 
..\sam3-pc.exe
..\macc3-pc.exe  >..\tests\results\test1-_1.result
java -cp . gcl.GCLCompiler ..\tests\test10_2 ..\tests\results\test10_2list.txt 
..\sam3-pc.exe
java -cp . gcl.GCLCompiler ..\tests\test11 ..\tests\results\test11list.txt 
..\sam3-pc.exe
..\macc3-pc.exe  <..\tests\test11.dat >..\tests\results\test11.result
java -cp . gcl.GCLCompiler ..\tests\test11_1 ..\tests\results\test11_1list.txt 
..\sam3-pc.exe
..\macc3-pc.exe  <..\tests\test11.dat >..\tests\results\test11_1.result
java -cp . gcl.GCLCompiler ..\tests\test11_2 ..\tests\results\test11_2list.txt 
..\sam3-pc.exe
..\macc3-pc.exe  <..\tests\test11.dat >..\tests\results\test11_2.result
java -cp . gcl.GCLCompiler ..\tests\test11_3 ..\tests\results\test11_3list.txt 
..\sam3-pc.exe
..\macc3-pc.exe  <..\tests\test11.dat >..\tests\results\test11_3.result
java -cp . gcl.GCLCompiler ..\tests\test11_3.fix ..\tests\results\test11_3fixlist.txt 
..\sam3-pc.exe
..\macc3-pc.exe  <..\tests\test11.dat >..\tests\results\test11_3fix.result
java -cp . gcl.GCLCompiler ..\tests\test11_4 ..\tests\results\test11_4list.txt 
..\sam3-pc.exe
..\macc3-pc.exe  <..\tests\test11.dat >..\tests\results\test11_4.result
java -cp . gcl.GCLCompiler ..\tests\test11_5 ..\tests\results\test11_5list.txt 
..\sam3-pc.exe
..\macc3-pc.exe  <..\tests\test11.dat >..\tests\results\test11_5.result
java -cp . gcl.GCLCompiler ..\tests\test11_6 ..\tests\results\test11_6list.txt 
..\sam3-pc.exe
..\macc3-pc.exe  <..\tests\test11.dat >..\tests\results\test11_6.result
java -cp . gcl.GCLCompiler ..\tests\Test11_7 ..\tests\results\Test11_7list.txt 
java -cp . gcl.GCLCompiler ..\tests\test11_8 ..\tests\results\test11_8list.txt 
..\sam3-pc.exe
..\macc3-pc.exe   >..\tests\results\test11_8.result
java -cp . gcl.GCLCompiler ..\tests\test11_9 ..\tests\results\test11_9list.txt 
..\sam3-pc.exe
..\macc3-pc.exe  <..\tests\test11.dat >..\tests\results\test11_9.result
java -cp . gcl.GCLCompiler ..\tests\test12 ..\tests\results\test12list.txt 
..\sam3-pc.exe
..\macc3-pc.exe   >..\tests\results\test12.result
java -cp . gcl.GCLCompiler ..\tests\test12_1 ..\tests\results\test12_1list.txt 
..\sam3-pc.exe
java -cp . gcl.GCLCompiler ..\tests\test12_2 ..\tests\results\test12_2list.txt 
java -cp . gcl.GCLCompiler ..\tests\test13 ..\tests\results\test13list.txt 
..\sam3-pc.exe
..\macc3-pc.exe  <..\tests\test13.dat >..\tests\results\test13.result
java -cp . gcl.GCLCompiler ..\tests\test13_1 ..\tests\results\test13_1list.txt 
..\sam3-pc.exe
..\macc3-pc.exe  <..\tests\test13.dat >..\tests\results\test13_1.result
java -cp . gcl.GCLCompiler ..\tests\test14 ..\tests\results\test14list.txt 
..\sam3-pc.exe
..\macc3-pc.exe  >..\tests\results\test14.result
java -cp . gcl.GCLCompiler ..\tests\test14_1 ..\tests\results\test14_1list.txt 
..\sam3-pc.exe
..\macc3-pc.exe  <..\tests\test14_1.dat >..\tests\results\test14_1.result
java -cp . gcl.GCLCompiler ..\tests\test15 ..\tests\results\test15list.txt 
..\sam3-pc.exe
..\macc3-pc.exe  <..\tests\test15.dat >..\tests\results\test15.result

java -cp . gcl.GCLCompiler ..\tests\test15_1 ..\tests\results\test15_1list.txt 
..\sam3-pc.exe
..\macc3-pc.exe >..\tests\results\test15_1.result

java -cp . gcl.GCLCompiler ..\tests\test16 ..\tests\results\test16list.txt 
..\sam3-pc.exe
..\macc3-pc.exe  >..\tests\results\test16.result
java -cp . gcl.GCLCompiler ..\tests\test16_1 ..\tests\results\test16_1list.txt 
..\sam3-pc.exe
java -cp . gcl.GCLCompiler ..\tests\test16_2 ..\tests\results\test16_2list.txt 
..\sam3-pc.exe
..\macc3-pc.exe  <..\tests\test16_2.dat >..\tests\results\test16_2.result
java -cp . gcl.GCLCompiler ..\tests\test16_3 ..\tests\results\test16_3list.txt 
..\sam3-pc.exe
..\macc3-pc.exe  >..\tests\results\test16_3.result
java -cp . gcl.GCLCompiler ..\tests\test17 ..\tests\results\test17list.txt 
..\sam3-pc.exe
..\macc3-pc.exe  <..\tests\test17.dat >..\tests\results\test17.result
java -cp . gcl.GCLCompiler ..\tests\test17_1 ..\tests\results\test17_1list.txt 
..\sam3-pc.exe
..\macc3-pc.exe  <..\tests\test17_1.dat >..\tests\results\test17_1.result
java -cp . gcl.GCLCompiler ..\tests\test17_2 ..\tests\results\test17_2list.txt 
..\sam3-pc.exe
..\macc3-pc.exe  >..\tests\results\test17_2.result
java -cp . gcl.GCLCompiler ..\tests\test17_3 ..\tests\results\test17_3list.txt 
..\sam3-pc.exe
..\macc3-pc.exe  <..\tests\test17_3.dat >..\tests\results\test17_3.result
java -cp . gcl.GCLCompiler ..\tests\test17_4 ..\tests\results\test17_4list.txt 
java -cp . gcl.GCLCompiler ..\tests\test18 ..\tests\results\test18list.txt 
..\sam3-pc.exe
..\macc3-pc.exe  >..\tests\results\test18.result
java -cp . gcl.GCLCompiler ..\tests\test18_1 ..\tests\results\test18_1list.txt 
..\sam3-pc.exe
..\macc3-pc.exe  >..\tests\results\test18_1.result
java -cp . gcl.GCLCompiler ..\tests\test18_1fix ..\tests\results\test18_1fixlist.txt 
..\sam3-pc.exe
..\macc3-pc.exe  >..\tests\results\test18_1fix.result
java -cp . gcl.GCLCompiler ..\tests\test18_2 ..\tests\results\test18_2list.txt 
..\sam3-pc.exe
..\macc3-pc.exe  >..\tests\results\test18_2.result
java -cp . gcl.GCLCompiler ..\tests\test18_3 ..\tests\results\test18_3list.txt 
..\sam3-pc.exe
..\macc3-pc.exe  >..\tests\results\test18_3.result
::java -cp . gcl.GCLCompiler ..\tests\test19 ..\tests\results\test19list.txt 
::..\sam3-pc.exe
::..\macc3-pc.exe  >..\tests\results\test19.result
::java -cp . gcl.GCLCompiler ..\tests\test19_1 ..\tests\results\test19_1list.txt 
::..\sam3-pc.exe
::java -cp . gcl.GCLCompiler ..\tests\test19_2 ..\tests\results\test19_2list.txt 
::java -cp . gcl.GCLCompiler ..\tests\test20 ..\tests\results\test20list.txt 
::java -cp . gcl.GCLCompiler ..\tests\test20_1 ..\tests\results\test20_1list.txt 
::..\sam3-pc.exe
::..\macc3-pc.exe  >..\tests\results\test20_1.result
::java -cp . gcl.GCLCompiler ..\tests\test20_2 ..\tests\results\test20_2list.txt 
::..\sam3-pc.exe
pause
