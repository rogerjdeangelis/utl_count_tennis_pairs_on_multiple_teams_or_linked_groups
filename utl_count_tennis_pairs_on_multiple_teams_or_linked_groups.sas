Count tennis pairs on multiple teams or linked groups

 Same results in WPS and SAS

 Two Solutions
    1. Base SAS and Base WPS
    2. WPS PROC R or SAS/IML/R

Get number of same individuals for different groups

see
https://goo.gl/4GU7Xf
https://stackoverflow.com/questions/33613655/get-number-of-same-individuals-for-different-groups

Antoniosk  profile
https://stackoverflow.com/users/5193485/antoniosk

INPUT
=====

 WORK.HAVE                       RULES
                                 =====
   GROUP   ID  |
               |     Element1   Element2  Links
     A      1  |        A           B       2    (on two teams team 1 and 5)
     B      1  |        A           C       3
     C      1  |        B           C       3
     B      2  |
     C      2  |    A and B are linked twice because
     A      3  |
     A      4  |     GROUP       ID
     C      4  |      A      ->   1
     A      5  |      B      ->   1   first link
     B      5  |      A      ->   5
     C      5  |      B      ->   5   second link
               |                      sum of links =2


PROCESS
=======

* create the catesian self join mathing on id;
* rearrange the two groups in alphabetical order so links A->B
  is equivalent to B->A
* count the element1 x element2 links;

proc sql;
  create
     table want as
  select
     case when l.group > r.group then r.group
     else l.group
     end as element1
    ,case when l.group <= r.group then l.group
     else l.group
     end as element2
    ,count(*) as cnt
  from
     sd1.have as l full outer join sd1.have as r
  on
     l.id = r.id
  where
     calculated element1 ne calculated element2
  group
     by element1, element2
;quit;

OUTPUT
======

 WORK.WANT total obs=3

  ELEMENT1    ELEMENT2    CNT

     A           B         2
     A           C         3
     B           C         3
*                _               _       _
 _ __ ___   __ _| | _____     __| | __ _| |_ __ _
| '_ ` _ \ / _` | |/ / _ \   / _` |/ _` | __/ _` |
| | | | | | (_| |   <  __/  | (_| | (_| | || (_| |
|_| |_| |_|\__,_|_|\_\___|   \__,_|\__,_|\__\__,_|

;

options validvarname=upcase;
libname sd1 "d:/sd1";
data sd1.have;
 input ID Group$;
cards4;
 1 A
 1 B
 1 C
 2 B
 2 C
 3 A
 4 A
 4 C
 5 A
 5 B
 5 C
;;;;
run;quit;




%utl_submit_wps64('
libname sd1 sas7bdat "d:/sd1";
libname wrk sas7bdat "%sysfunc(pathname(work))";
proc sql;
  create
     table wrk.wantwps as
  select
     case when l.group > r.group then r.group
     else l.group
     end as element1
    ,case when l.group <= r.group then l.group
     else l.group
     end as element2
    ,count(*) as cnt
  from
     sd1.have as l full outer join sd1.have as r
  on
     l.id = r.id
  where
     calculated element1 ne calculated element2
  group
     by element1, element2
;quit;
');

/*
Obs    ELEMENT1    ELEMENT2    CNT

 1        A           B         2
 2        A           C         3
 3        B           C         3
*/

*
__      ___ __  ___   _ __  _ __ ___   ___   _ __
\ \ /\ / / '_ \/ __| | '_ \| '__/ _ \ / __| | '__|
 \ V  V /| |_) \__ \ | |_) | | | (_) | (__  | |
  \_/\_/ | .__/|___/ | .__/|_|  \___/ \___| |_|
         |_|         |_|
;

%utl_submit_wps64('
libname sd1 sas7bdat "d:/sd1";
libname wrk sas7bdat "%sysfunc(pathname(work))";
proc r;
submit;
source("C:/Program Files/R/R-3.3.2/etc/Rprofile.site", echo=T);
library(haven);
library(dplyr);
library(data.table);
have<-data.table(read_sas("d:/sd1/have.sas7bdat"));
have;
cmb <- combn(unique(have$GROUP),2);
want<-data.frame(g1 = cmb[1,],
           g2 = cmb[2,]) %>%
  group_by(g1,g2) %>%
  summarise(l=length(intersect(have[have$GROUP==g1,]$ID,
                               have[have$GROUP==g2,]$ID)));
endsubmit;
import r=want data=wrk.wantwps;
');

proc print data=wantwps;
run;quit;

Obs    G1    G2    L

 1     A     B     2
 2     A     C     3
 3     B     C     3


