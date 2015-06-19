      SUBROUTINE OFCOMP (*,FILE,TYPE,ELTYP,IAPP,HEADNG,PNCHED,FORM)     
C        
C     OFP ROUTINE TO HANDLE PRINT AND PUNCH OF LAYERED COMPOSITE        
C     ELEMENT STRESSES AND FORCES.  CURRENTLY, THIS INVOLVES ONLY       
C     THE CQUAD4 AND CTRIA3 ELEMENTS.        
C        
C     FILE     = OUTPUT FILE UNDER PROCESSING        
C     TYPE     = TYPE OF DATA-  REAL   , SORT 1       = 1        
C                               COMPLEX, SORT 1       = 2        
C                               REAL   , SORT 2       = 3        
C                               COMPLEX, SORT 2       = 4        
C     ELTYP    = ELEMENT TYPE-  QUAD4                 = 64        
C                               TRIA3                 = 83        
C     IAPP     = SOLUTION TYPE        
C     HEADNG   = INDICATES PRINT HEADINGS ARE DONE FOR A PAGE        
C     PNCHED   = INDICATES PUNCH HEADINGS ARE DONE        
C     FORM     = DATA TYPE-     STRESSES              = 22        
C                               FORCES                = 23        
C                               STRAIN                = 21        
C        
      EXTERNAL        ANDF        
      LOGICAL         HEAT,PNCHED,CMPXDT,SORT1,SORT2,HEADNG,MAGPHA,     
     1                QUAD4,TRIA3,STRESS,FORCE,STRN        
      INTEGER         IST(86),FILE,FLAG,NOUT,PUNCH,BUF(86),IBUF(3),     
     1                DEVICE,ANDF,HEAD,TYPE,ELTYP,FORM,STATIC,FREQ,     
     2                CEIG,ITITLE(32),ISUBTL(32),LABEL(32),ELEMID,      
     3                FAILTH,HILL(2),HOFFMN(2),TSAIWU(2),STRESF(2),     
     4                STRAIN(2),IFAIL(2),BLNK,ASTR,SUBST(3),        
     5                ID(50),OF(58)        
C     INTEGER         REIG,TRANS,BK1,ELEC        
      REAL            RST(86),RID(50),BUFR(86),RBUF(3)        
C     REAL            HARMON,PANGLE,BUFF(1)        
      CHARACTER*5     T3Q4,T3,Q4        
      COMMON /BLANK / ICARD        
C     COMMON /ZZOFPX/ L1,L2,L3,L4,L5,ID(50),HARMON,PANGLE,BUFF(1)       
CZZ   COMMON /ZZOFPX/ CORE(1)        
      COMMON /ZZZZZZ/ CORE(1)        
      COMMON /OUTPUT/ HEAD(96)        
      COMMON /SYSTEM/ KSYSTM(100)        
      EQUIVALENCE     (IST(1)    ,RST(1) ), (ID(1)     ,RID(1)  ),      
     1                (BUF(1)    ,BUFR(1)), (IBUF(1)   ,RBUF(1) ),      
     2                (IFAIL(1)  ,FAILMX ), (IFAIL(2)  ,MAXFLG  ),      
     3                (KSYSTM(2) ,NOUT   ), (KSYSTM(9) ,MAXLNS  ),      
     4                (KSYSTM(12),LINE   ), (KSYSTM(33),IFLG    ),      
     5                (KSYSTM(56),ITHERM ), (KSYSTM(69),ISUBS   ),      
     6                (KSYSTM(91),PUNCH  ), (HEAD( 1) ,ITITLE(1)),      
     7                (HEAD(65) ,LABEL(1)), (HEAD(33) ,ISUBTL(1)),      
     8                (L1, OF(1) ,CORE(1)), (L2,OF(2)),(L3,OF(3)),      
     9                (ID(1)     ,OF  (6)), (L4,OF(4)),(L5,OF(5))       
C     EQUIVALENCE     (HARMON    ,OF (56)), (PANGLE   ,OF   (57)),      
C    1                (BUFF(1)   ,OF (58))        
C        
      DATA  STATIC,FREQ,CEIG    / 1 , 5 , 9      /        
C     DATA  REIG,TRANS,BK1,ELEC / 2 , 6 , 8 , 11 /        
      DATA  HILL  ,       HOFFMN,       TSAIWU,       STRESF       /    
     1      4H   H,4HILL ,4HHOFF,4HMAN ,4HTSAI,4H-WU ,4H STR,4HESS /    
      DATA  STRAIN       /4H STR,4HAIN /        
      DATA  BLNK  ,ASTR  /4H    ,4H  * /        
      DATA  SUBST        /4HSUBS,4HTRUC,4HTURE /        
      DATA  T3Q4, T3, Q4 /' ', 'TRIA3', 'QUAD4'/        
C        
C     INITIALIZE        
C        
      CMPXDT = TYPE.EQ.2 .OR. TYPE.EQ.4        
      SORT1  = TYPE  .LE. 2        
      SORT2  = TYPE  .GT. 2        
      HEAT   = ITHERM.EQ. 1        
      MAGPHA = ID(9).EQ.3 .AND. (IAPP.EQ.FREQ .OR. IAPP.EQ.CEIG)        
      QUAD4  = ELTYP .EQ. 64        
      TRIA3  = ELTYP .EQ. 83        
      STRESS = FORM  .EQ. 22        
      FORCE  = FORM  .EQ. 23        
      STRN   = FORM  .EQ. 21        
      IF (HEAT .OR. SORT2 .OR. CMPXDT) GO TO 1800        
C        
C     GET THE DEVICE CODE IF SORT=2,  1=PRINT  2=POST  4=PUNCH        
C        
      IF (SORT1) GO TO 10        
      IDD = ID(5)/10        
      DEVICE = ID(5) - 10*IDD        
      IDEVCE = DEVICE        
      ID(5)  = IDD        
      ELEMID = IDD        
   10 CONTINUE        
C        
C     GET THE NUMBER OF OUTPUT WORDS PER ELEMENT.        
C        
      NWDS = ID(10)        
      IF (NWDS .EQ. 0) GO TO 1800        
      IF (FORCE) GO TO 40        
C        
C     ********************        
C     ******* READ *******        
C     ********************        
C        
   20 CALL READ (*1910,*1800,FILE,IST(1),3,0,FLAG)        
      IF (SORT1) ELEMID = IST(1)        
      IF (SORT2) TIME = RST(1)        
      NLAYER = IST(2)        
      FAILTH = IST(3)        
      IPLY = 0        
   30 IPLY = IPLY + 1        
      IF (IPLY .GT. NLAYER) GO TO 20        
C        
   40 CALL READ (*1910,*1900,FILE,IST(1),NWDS,0,FLAG)        
      IF (STRESS .AND. IPLY.EQ.NLAYER)        
     1    CALL READ (*1910,*1910,FILE,IFAIL,2,0,FLAG)        
      IF (FORCE) ELEMID = IST(1)        
C        
C     GET THE DEVICE CODE IF SORT=1,   1=PRINT  2=POST  4=PUNCH        
C        
      IF (SORT2) GO TO 100        
      IF (STRESS .AND. IPLY.GT.1) GO TO 100        
      ITEMP  = ELEMID / 10        
      DEVICE = ELEMID - 10*ITEMP        
      IDEVCE = DEVICE        
      ELEMID = ITEMP        
C        
C     *********************        
C     ******* PUNCH *******        
C     *********************        
C        
  100 IF (DEVICE .LT. 4) GO TO 820        
C        
C     TAKE OUT INDEX FAILURE FLAGS FOR STRESSES        
C        
      NUMWDS = NWDS        
      IF (STRESS) NUMWDS = NUMWDS - 2        
      DO 110 II=1,NWDS        
  110 BUF(II) = IST(II)        
      IF (FORCE) GO TO 120        
      BUF(6) = BUF(7)        
      BUF(7) = BUF(8)        
      BUF(8) = BUF(9)        
  120 CONTINUE        
C        
      IF (PNCHED) GO TO 500        
C        
C     PUNCH HEADINGS - TITLE, SUBTITLE, AND LABEL        
C        
      ICARD = ICARD + 1        
      WRITE  (PUNCH,130) (ITITLE(J),J=1,15),ICARD        
      ICARD = ICARD + 1        
      WRITE  (PUNCH,140) (ISUBTL(J),J=1,15),ICARD        
      ICARD = ICARD + 1        
      WRITE  (PUNCH,150) ( LABEL(J),J=1,15),ICARD        
  130 FORMAT (10H$TITLE   =,15A4,2X,I8)        
  140 FORMAT (10H$SUBTITLE=,15A4,2X,I8)        
  150 FORMAT (10H$LABEL   =,15A4,2X,I8)        
C        
C     IF SUBSTRUCTURE (PHASE2) EXTRACTED ALSO SUBS-NAME AND COMPONENT   
C        
      IF (ISUBS .EQ. 0) GO TO 170        
      IF (ISUBTL(20).NE.SUBST(1) .OR. ISUBTL(21).NE.SUBST(2) .OR.       
     1    ISUBTL(22).NE.SUBST(3)) GO TO 170        
      ICARD = ICARD + 1        
      WRITE (PUNCH,160) (ISUBTL(J),J=20,26),ICARD        
      ICARD = ICARD + 1        
      WRITE  (PUNCH,160) ( LABEL(J),J=20,26),ICARD        
  160 FORMAT (1H$,7A4,43X,I8)        
C        
  170 ICARD = ICARD + 1        
      IF (STRESS) WRITE (PUNCH,190) ICARD        
      IF (FORCE ) WRITE (PUNCH,180) ICARD        
  180 FORMAT (15H$ELEMENT FORCES,57X,I8)        
  190 FORMAT (17H$ELEMENT STRESSES,55X,I8)        
C        
C     REAL, REAL/IMAGINARY, MAGNITUDE/PHASE        
C        
      ICARD = ICARD + 1        
      IF (CMPXDT) GO TO 200        
      WRITE  (PUNCH,220) ICARD        
      GO TO 250        
  200 IF (MAGPHA) GO TO 210        
      WRITE  (PUNCH,230) ICARD        
      GO TO 250        
  210 WRITE  (PUNCH,240) ICARD        
  220 FORMAT (12H$REAL OUTPUT,60X,I8)        
  230 FORMAT (22H$REAL-IMAGINARY OUTPUT,50X,I8)        
  240 FORMAT (23H$MAGNITUDE-PHASE OUTPUT,49X,I8)        
C        
C     SUBCASE OR ELEMENT ID        
C        
  250 ICARD = ICARD + 1        
      IF (SORT2) GO TO 260        
      WRITE  (PUNCH,280) ID(4),ICARD        
      GO TO 270        
  260 WRITE  (PUNCH,290) ELEMID,ICARD        
  270 CONTINUE        
  280 FORMAT (13H$SUBCASE ID =,I12,47X,I8)        
  290 FORMAT (13H$ELEMENT ID =,I10,49X,I8)        
C        
C     PUNCH ELEMENT TYPE NUMBER,        
C     IT IS SWITCHED TO MATCH THOSE OF POST PROCESSOR.        
C        
      ICARD  = ICARD + 1        
      IELTYP = ID(3)        
      T3Q4   = T3        
      IF (IELTYP .EQ. 64) T3Q4 = Q4        
      WRITE  (PUNCH,300) IELTYP,T3Q4,ICARD        
  300 FORMAT (15H$ELEMENT TYPE =,I12,4H   (,A5,1H),37X,I8)        
C        
C     EIGENVALUE, FREQUENCY, OR TIME        
C        
      GO TO (480,400,480,480,440,450,480,400,400,480,480), IAPP        
C        
C     PUNCH EIGENVALUE        
C        
  400 ICARD = ICARD + 1        
      IF (SORT1 .AND. CMPXDT) GO TO 410        
      WRITE  (PUNCH,420) RID(6),ID(5),ICARD        
      GO TO 480        
  410 WRITE  (PUNCH,430) RID(6),RID(7),ID(5),ICARD        
      GO TO 480        
  420 FORMAT (13H$EIGENVALUE =,E15.7,2X,6HMODE =,I6,30X,I8)        
  430 FORMAT (15H$EIGENVALUE = (,E15.7,1H,,E15.7,8H) MODE =,I6,12X,I8)  
C        
C     FREQUENCY OR TIME        
C        
  440 IF (SORT2) GO TO 480        
      ICARD = ICARD + 1        
      WRITE  (PUNCH,460) RID(5),ICARD        
      GO TO 480        
  450 IF (SORT2) GO TO 480        
      ICARD = ICARD + 1        
      WRITE  (PUNCH,470) RID(5),ICARD        
  460 FORMAT (12H$FREQUENCY =,E16.7,44X,I8)        
  470 FORMAT (7H$TIME =,E16.7,49X,I8)        
C        
  480 PNCHED = .TRUE.        
C        
C     PUNCH HEADINGS COMPLETE        
C        
  500 ICARD = ICARD + 1        
C        
C     ELEMENT STRESSES,  FIRST SUB-RECORD        
C        
      IF (FORCE) GO TO 570        
      IF (IPLY .LE. 1) GO TO 520        
      WRITE  (PUNCH,510) BUF(1),BUFR(2),BUFR(3),ICARD        
  510 FORMAT (6H-CONT-,12X,I10,8X,2(1P,E18.6),I8)        
      GO TO 560        
C        
  520 IF (SORT2 .AND. IAPP.NE.STATIC) GO TO 540        
C        
C     FIRST CARD BEGINS WITH AN INTEGER        
C        
      WRITE  (PUNCH,530) ELEMID,BUF(1),BUFR(2),BUFR(3),ICARD        
  530 FORMAT (I10,8X,I10,8X,2(1P,E18.6),I8)        
      GO TO 560        
C        
C     FIRST CARD BEGINS WITH A REAL        
C        
  540 WRITE  (PUNCH,550) TIME,BUF(1),BUFR(2),BUFR(3),ICARD        
  550 FORMAT (1P,E18.6,I10,8X,2(1P,E18.6),I8)        
  560 NWORD = 3        
      GO TO 620        
C        
C     ELEMENT FORCES,  FIRST SUB-RECORD        
C        
  570 IF (SORT2 .AND. IAPP.NE.STATIC) GO TO 590        
C        
C     FIRST CARD BEGINS WITH AN INTEGER        
C        
      WRITE  (PUNCH,580) BUF(1),BUFR(2),BUFR(3),BUFR(4),ICARD        
  580 FORMAT (I10,8X,3(1P,E18.6),I8)        
      GO TO 610        
C        
C     FIRST CARD BEGINS WITH A REAL        
C        
  590 WRITE  (PUNCH,600) BUFR(1),BUFR(2),BUFR(3),BUFR(4),ICARD        
  600 FORMAT (4(1P,E18.6),I8)        
  610 NWORD = 4        
C        
  620 LENGTH = 8        
C        
C     SUBSEQUENT SUB-RECORDS        
C        
  700 LEFT = NUMWDS - NWORD        
      IF (LEFT .GT. 0) GO TO 710        
      IF (SORT1) GO TO 810        
      GO TO 820        
C        
C     PUNCH THE SUB-RECORDS        
C        
  710 IF (NWORD .GE. LENGTH) GO TO 700        
      ICARD = ICARD + 1        
      NWORD = NWORD + 3        
      JOUT  = 3        
      IF (NWORD .LE. LENGTH) GO TO  720        
      NWORD = NWORD - 1        
      JOUT  = 2        
      IF (NWORD .EQ. LENGTH) GO TO  720        
      NWORD = NWORD - 1        
      JOUT  = 1        
C        
  720 JJ = NWORD - JOUT + 1        
      DO 730 II = 1,JOUT        
      IBUF(II) = BUF(JJ)        
  730 JJ = JJ + 1        
      GO TO (740,760,780), JOUT        
C        
C     1 WORD OUT        
C        
  740 WRITE  (PUNCH,750) RBUF(1),ICARD        
  750 FORMAT (6H-CONT-,12X,1P,E18.6,36X,I8)        
      GO TO 800        
C        
C     2 WORDS OUT        
C        
  760 IF (IPLY .LT. NLAYER) WRITE (PUNCH,770) RBUF(1),RBUF(2),ICARD     
      IF (IPLY .EQ. NLAYER) WRITE (PUNCH,775) RBUF(1),RBUF(2),RBUF(3),  
     1    ICARD        
  770 FORMAT (6H-CONT-,12X,1P,E18.6,0P,F18.4,18X,I8)        
  775 FORMAT (6H-CONT-,12X,1P,E18.6, 2(0P,F18.4),I8)        
      GO TO 800        
C        
C     3 WORDS OUT        
C        
  780 WRITE  (PUNCH,790) RBUF(1),RBUF(2),RBUF(3),ICARD        
  790 FORMAT (6H-CONT-,12X,1P,E18.6,0P,F18.4,1P,E18.6,I8)        
  800 IF (JOUT .LT. 3) GO TO 700        
      GO TO 710        
C        
C     END OF PUNCH, SEE IF PRINT IS REQUESTED        
C        
  810 IDEVCE = DEVICE - 4        
  820 IF (ANDF(IDEVCE,1) .NE. 0) GO TO 900        
      IF (STRESS) GO TO 30        
      GO TO 40        
C        
C     *********************        
C     ******* PRINT *******        
C     *********************        
C        
C     WRITE TITLES IF HAVE NOT DONE SO YET        
C        
  900 ICHECK = 0        
      IF (LINE.LE.MAXLNS-2 .AND. HEADNG) GO TO 910        
      IFLG = 1        
      CALL PAGE1        
      HEADNG = .TRUE.        
      ICHECK = 1        
C        
C     *** PRINT OF ELEMENT STRESSES ***        
C        
  910 IF (FORCE) GO TO 1500        
C        
C     BRANCH ON TYPE OF OUTPUT        
C        
      GO TO (920,1400,1410,1420), TYPE        
C        
C     *** REAL, SORT 1 ***        
C        
  920 IF (ICHECK .EQ. 0) GO TO 1200        
      GO TO (960,930,960,960,960,940,960,950,960,960,960), IAPP        
C        
  930 WRITE  (NOUT,970) ID(5),RID(8),RID(6)        
      GO TO 1010        
  940 WRITE  (NOUT,980) RID(5)        
      GO TO 1010        
  950 WRITE  (NOUT,990) RID(6)        
      GO TO 1010        
  960 WRITE  (NOUT,1000)        
  970 FORMAT (6X,'MODE NUMBER = ',I4,26X,'FREQUENCY = ',1P,E13.6,26X,   
     1       'EIGENVALUE = ',1P,E13.6)        
  980 FORMAT (6X,6HTIME =,1P,E14.6)        
  990 FORMAT (6X,12HEIGENVALUE =,1P,E14.6)        
 1000 FORMAT (1H )        
C        
 1010 CONTINUE        
      IF (QUAD4) GO TO 1020        
      IF (TRIA3) GO TO 1030        
C     IF (TRIA6) GO TO 1040        
C     WRITE  (NOUT,1060)        
      GO TO 1050        
 1020 WRITE  (NOUT,1070)        
      GO TO 1050        
 1030 WRITE  (NOUT,1080)        
      GO TO 1050        
C1040 WRITE  (NOUT,1090)        
C     GO TO 1050        
 1050 WRITE  (NOUT,1100)        
      WRITE  (NOUT,1110)        
C1060 FORMAT (20X,'S T R E S S E S   I N   L A Y E R E D   ',        
C    1        'C O M P O S I T E   E L E M E N T S   ( Q U A D 8 )')    
 1070 FORMAT (20X,'S T R E S S E S   I N   L A Y E R E D   ',        
     1        'C O M P O S I T E   E L E M E N T S   ( Q U A D 4 )')    
 1080 FORMAT (20X,'S T R E S S E S   I N   L A Y E R E D   ',        
     1        'C O M P O S I T E   E L E M E N T S   ( T R I A 3 )')    
C1090 FORMAT (20X,'S T R E S S E S   I N   L A Y E R E D   ',        
C    1        'C O M P O S I T E   E L E M E N T S   ( T R I A 6 )')    
 1100 FORMAT ('0 ELEMENT',3X,'PLY *STRESSES IN FIBER AND MATRIX',       
     1        ' DIRECTIONS*  *DIRECT FIBER *  *INTER-LAMINAR STRESS',   
     2        'ES*  * SHEAR BOND  *   *MAXIMUM*')        
 1110 FORMAT (4X, 'ID', 6X, 'ID  *  NORMAL-1', 6X, 'NORMAL-2', 6X,      
     1        'SHEAR-12 *  *FAILURE INDEX*  *SHEAR-1Z',6X,'SHEAR-2Z*',  
     2        '  *FAILURE INDEX*   * INDEX *',/)        
C        
C     WRITE THE DATA        
C     BUT FIRST, MODIFY THE FAILURE INDEX FLAGS FROM INTEGER TO BCD     
C        
 1200 IF (IST( 6) .EQ. 0) IST( 6) = BLNK        
      IF (IST( 6) .EQ. 1) IST( 6) = ASTR        
      IF (IST(10) .EQ. 0) IST(10) = BLNK        
      IF (IST(10) .EQ. 1) IST(10) = ASTR        
C        
      IF (IPLY .GT. 1) GO TO 1220        
      WRITE  (NOUT,1210) ELEMID,IST(1),(RST(K),K=2,5),IST(6),        
     1                                 (RST(K),K=7,9),IST(10)        
 1210 FORMAT (1H0,I8,2X,I4,3(1P,E14.5),2X,0P,F10.3,A4,2(1P,E14.5),      
     1        0P,F10.3,A4)        
      NLINES = 3        
      GO TO 1730        
C        
 1220 WRITE  (NOUT,1230) IST(1),(RST(K),K=2,5),IST(6),        
     1                          (RST(K),K=7,9),IST(10)        
 1230 FORMAT (11X,I4,3(1P,E14.5),2X,0P,F10.3,A4,2(1P,E14.5),0P,F10.3,A4)
      NLINES = 1        
      IF (IPLY .LT. NLAYER) GO TO 1730        
C        
C     IF THE LAST LAYER, CHECK THE MAXIMUM FAILURE INDEX        
C        
      NLINES = 2        
      IF (MAXFLG .EQ. 0) MAXFLG = BLNK        
      IF (MAXFLG .EQ. 1) MAXFLG = ASTR        
      IF (FAILTH .NE. 0) GO TO (1250,1260,1270,1280,1290), FAILTH       
      FAILMX = 0.0        
      WRITE  (NOUT,1240) FAILMX        
 1240 FORMAT (1H ,116X,0P,F10.3)        
      GO TO 1730        
 1250 WRITE  (NOUT,1300) HILL(1),HILL(2),FAILMX,MAXFLG        
      GO TO 1730        
 1260 WRITE  (NOUT,1300) HOFFMN(1),HOFFMN(2),FAILMX,MAXFLG        
      GO TO 1730        
 1270 WRITE  (NOUT,1300) TSAIWU(1),TSAIWU(2),FAILMX,MAXFLG        
      GO TO 1730        
 1280 WRITE  (NOUT,1300) STRESF(1),STRESF(2),FAILMX,MAXFLG        
      GO TO 1730        
 1290 WRITE  (NOUT,1300) STRAIN(1),STRAIN(2),FAILMX,MAXFLG        
 1300 FORMAT (1H ,41X,2A4,'FAILURE THEORY WAS USED FOR THIS ELEMENT.',  
     1       26X,0P,F10.3,A4)        
      GO TO 1730        
C        
C     *** COMPLEX, SORT 1 ***        
C        
 1400 GO TO 1800        
C        
C     *** REAL, SORT 2 ***        
C        
 1410 GO TO 1800        
C        
C     *** COMPLEX, SORT 2 ***        
C        
 1420 GO TO 1800        
C        
C     *** PRINT OF ELEMENT FORCES ***        
C        
 1500 CONTINUE        
C        
C     BRANCH ON TYPE OF OUTPUT        
C        
      GO TO (1510,1700,1710,1720), TYPE        
C        
C     *** REAL, SORT 1 ***        
C        
 1510 IF (ICHECK .EQ. 0) GO TO 1670        
      GO TO (1550,1520,1550,1550,1550,1530,1550,1540,1550,1550,1550),   
     1       IAPP        
C        
 1520 WRITE (NOUT,970) ID(5),RID(8),RID(6)        
      GO TO 1560        
 1530 WRITE (NOUT,980) RID(5)        
      GO TO 1560        
 1540 WRITE (NOUT,990) RID(6)        
      GO TO 1560        
 1550 WRITE (NOUT,1000)        
C        
 1560 IF (QUAD4) GO TO 1570        
      IF (TRIA3) GO TO 1580        
C     IF (TRIA6) GO TO 1590        
C     WRITE  (NOUT,1610)        
      GO TO 1600        
 1570 WRITE  (NOUT,1620)        
      GO TO 1600        
 1580 WRITE  (NOUT,1630)        
      GO TO 1600        
C1590 WRITE  (NOUT,1640)        
C     GO TO 1600        
 1600 WRITE  (NOUT,1650)        
      WRITE  (NOUT,1660)        
C1610 FORMAT (22X,'F O R C E S   I N   L A Y E R E D   C O M P O S ',   
C    1        'I T E   E L E M E N T S   ( Q U A D 8 )'/)        
 1620 FORMAT (22X,'F O R C E S   I N   L A Y E R E D   C O M P O S ',   
     1        'I T E   E L E M E N T S   ( Q U A D 4 )'/)        
 1630 FORMAT (22X,'F O R C E S   I N   L A Y E R E D   C O M P O S ',   
     1        'I T E   E L E M E N T S   ( T R I A 3 )'/)        
C1640 FORMAT (22X,'F O R C E S   I N   L A Y E R E D   C O M P O S ',   
C    1        'I T E   E L E M E N T S   ( T R I A 6 )'/)        
 1650 FORMAT (6X,'ELEMENT',18X,'- MEMBRANE  FORCES -',22X,'- BENDING',  
     1        '   MOMENTS -',11X,'- TRANSVERSE SHEAR FORCES -')        
 1660 FORMAT (8X,'ID',16X,2HFX,12X,2HFY,12X,3HFXY,11X,        
     1        2HMX,12X,2HMY,12X,3HMXY,11X,2HVX,12X,2HVY)        
C        
C     WRITE THE DATA        
C        
 1670 WRITE  (NOUT,1680) ELEMID,(RST(K),K=2,9)        
 1680 FORMAT (1H0,4X,I8,6X,8(1X,1P,E13.5))        
      NLINES = 2        
      GO TO 1730        
C        
C     *** COMPLEX, SORT 1 ***        
C        
 1700 GO TO 1800        
C        
C     *** REAL, SORT 2 ***        
C        
 1710 GO TO 1800        
C        
C     *** COMPLEX, SORT 2 ***        
C        
 1720 GO TO 1800        
C        
C     DONE WITH ONE ENTRY, GO BACK AND READ ANOTHER ONE.        
C        
 1730 LINE = LINE + NLINES        
      IF (STRESS) GO TO 30        
      GO TO 40        
C        
 1800 CONTINUE        
      RETURN        
C        
 1900 IF (FORCE) RETURN        
 1910 CONTINUE        
      RETURN 1        
C        
C2000 FORMAT (6X,11HFREQUENCY =,1P,E14.6)        
C2010 FORMAT (6X,'ELEMENT-ID =',I8)        
C2020 FORMAT (6X,20HCOMPLEX EIGENVALUE =,1P,E14.6,1H,,1P,E14.6)        
C2030 FORMAT (60X,16H(REAL/IMAGINARY))        
C2040 FORMAT (59X,17H(MAGNITUDE/PHASE))        
C        
C2050 FORMAT (6X,'SUBCASE',18X,'- MEMBRANE  FORCES -',22X,'- BENDING',  
C    1        '   MOMENTS -',11X,'- TRANSVERSE SHEAR FORCES -')        
C2060 FORMAT (26X,2HFX,12X,2HFY,12X,3HFXY,11X,        
C    1        2HMX,12X,2HMY,12X,3HMXY,11X,2HVX,12X,2HVY)        
C2070 FORMAT (31X,20H- MEMBRANE  FORCES -,22X,9H- BENDING,        
C    1        12H   MOMENTS -,11X,27H- TRANSVERSE SHEAR FORCES -)       
C2080 FORMAT (6X,'TIME',16X,2HFX,12X,2HFY,12X,3HFXY,11X,        
C    1        2HMX,12X,2HMY,12X,3HMXY,11X,2HVX,12X,2HVY)        
C2090 FORMAT (6X,'FREQUENCY',11X,2HFX,12X,2HFY,12X,3HFXY,        
C    1        11X,2HMX,12X,2HMY,12X,3HMXY,11X,2HVX,12X,2HVY)        
C        
      END        