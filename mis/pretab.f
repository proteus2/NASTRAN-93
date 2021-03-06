      SUBROUTINE PRETAB (DITF,RZ,INZ,BUF,LCRGVN,LCUSED,TABNOL,LIST)     
C        
C     SUBROUTINE PRETAB READS TABLES INTO OPEN CORE, SETS UP TABLE      
C     DICTIONARIES WHICH ARE LATER USED WHEN THE CALLING ROUTINE        
C     REQUESTS A FUNCTIONAL VALUE FROM A TABLE VIA A CALL TO THE ENTRY  
C     POINT TAB.        
C        
C     REVISED  7/92, BY G.CHAN/UNISYS.        
C     1. NEW REFERENCE TO THE OPEN CORE ARRAY SUCH THAT THE SOURCE CODE 
C        IS UP TO ANSI FORTRAN 77 STANDARD        
C     2. LOGARITHMIC SCALE ENHANCEMENT        
C        
C     ARGUMENT LIST -        
C        
C     DITF     THE GINO NAME OF THE FILE ON WHICH THE TABLES RESIDE.    
C     RZ       THE OPEN CORE ARRAY. RZ IS USED AS REAL BY THIS ROUTINE. 
C     INZ      SAME ADDRESS AS RZ.  USED AS INTEGER IN THIS ROUTINE.    
C     BUF      A BUFFER TO BE USED BY SUBROUTINE PRELOC.        
C     LCRGVN   THE LENGTH OF OPEN CORE GIVEN TO PRETAB.        
C     LCUSED   THE AMOUNT OF CORE USED BY PRETAB.        
C     TABNOL   LIST OF TABLE NUMBERS THAT THE USER WILL BE REFERENCING. 
C              TABNOL(1) = N IS THE NUMBER OF TABLES TO BE REFERENCED.  
C              TABNOL(2),...,TABNOL(N+1) CONTAIN THE TABLE NUMBERS. NOTE
C              THAT 0 IS AN ADMISSIBLE TABLE NUMBER IN THE TABLE NO.    
C              LIST.  TABLE NO. 0 DEFINES A FUNCTION WHICH IS IDENTICAL-
C              LY = 0 FOR ALL VALUES OF THE INDEPENDENT VARIABLE.       
C     LIST     ARRAY OF CONTROL WORDS FOR SUBROUTINE LOCATE AND TABLE   
C              TYPES.        
C              LIST(1) = M IS THE NO. OF TRIPLES WHICH FOLLOW IN LIST.  
C              THE FIRST TWO WORDS OF EACH TRIPLE ARE THE SUBROUTINE    
C              LOCATE CONTROL WORDS AND THE THIRD WORD IS THE TABLE TYPE
C              = 1,2,3,4, OR 5.        
C     LNTH     = 12 WORDS PER TABLE ENTRY        
C        
      LOGICAL         PART1        
      INTEGER         DITF   ,INZ(1) ,TABNOL(1)      ,DIT     ,LIST(1), 
     1                IARY(8),TABNO  ,TABTYP ,TABIDO ,NAME(2) ,        
     2                CLSRW  ,TABID  ,OFFSET ,SCTYP        
      REAL            Y(2)   ,RZ(1)  ,Z(1)   ,BUF(1) ,PX(2,2)        
      COMPLEX         SUM    ,A      ,B      ,TERM        
      CHARACTER       UFM*23        
      COMMON /XMSSG / UFM        
      COMMON /CONDAS/ PI     ,TWOPI  ,RADEG  ,DEGRA  ,S4PISQ        
      COMMON /SYSTEM/ IBUF   ,NOUT        
CZZ   COMMON /XNSTRN/ IZ(1)        
      COMMON /ZZZZZZ/ IZ(1)        
      EQUIVALENCE     (Z(1),IZ(1))        
      DATA     CLSRW, NEOR  ,NAME         ,PX              , LNTH  /    
     1         1    , 0     ,4HPRET,4HAB  ,3.,2.,1.339,1.0 , 12    /    
C        
C     INITIALIZE        
C        
      OFFSET = LOCFX(INZ(1)) - LOCFX(IZ(1))        
      IF (OFFSET .LT. 0) CALL ERRTRC ('PRETAB  ',5)        
      DIT  = DITF        
      IDIC = 0 + OFFSET        
      PART1= .TRUE.        
      LIM  = TABNOL(1)        
      ICRQ = LNTH*LIM - LCRGVN        
      IF (ICRQ .GE. 0) GO TO 1080        
C        
C     SET UP TABLE NUMBERS IN DICTIONARY        
C        
C     FOR EACH TABLE THE DICTIONARY ENTRY IS AS FOLLOWS -        
C        
C       LOC.  1      TABLE NUMBER        
C       LOC.  2      TABLE TYPE(1,2,3, 4, OR 5)        
C       LOC.  3      POINTER TO 1ST  ENTRY IN TABLE.        
C       LOC.  4      POINTER TO LAST ENTRY IN TABLE.        
C       LOC.  5      *        
C       LOC.  6      *        
C       LOC.  7      *        
C       LOC.  8      * LOCATIONS 5 THRU 11 CONTAIN TABLE PARAMETERS.    
C       LOC.  9      *        
C       LOC. 10      *        
C       LOC. 11      *        
C       LOC. 12      SCALE TYPE - LINEAR-LINER(0), LOG-LOG(1), LINEAR-  
C                                 LOG(2), LOG-LINEAR(3)        
C        
      DO 20 I = 1,LIM        
      IZ(IDIC+1) = TABNOL(I+1)        
      JLOW = IDIC + 2        
      JLIM = IDIC + LNTH        
      DO 10 J = JLOW,JLIM        
   10 IZ(J) = 0        
   20 IDIC  = IDIC + LNTH        
      IDICL = 1 + OFFSET        
      IDICH = IDIC        
C        
C     READ THE CARDS REFERENCED VIA THE TABNOL AND LIST ARRAY.        
C        
      ITABLE = IDIC        
      CALL PRELOC (*1010,BUF,DIT)        
      LIMJJ = TABNOL(1)        
      LIM   = LIST(1)        
      JJ    = 1        
   30 JJ3   = 3*JJ - 1        
      CALL LOCATE (*110,BUF,LIST(JJ3),FLAG)        
C        
C     READ 8 WORDS INTO THE ARRAY IARY        
C        
   40 CALL READ (*1020,*110,DIT,IARY,8,NEOR,FLAG)        
      TABNO = IARY(1)        
      SCTYP = IARY(8)        
C        
C     DETERMINE IF THIS TABLE NUMBER IS IN THE USER SUPPLIED LIST OF    
C     TABLE NUMBERS        
C        
      DO 50 J = 1,LIMJJ        
      IF (TABNO .EQ. IABS(TABNOL(J+1))) IF (TABNO-TABNOL(J+1)) 60,70,60 
   50 CONTINUE        
C        
C     THIS TABLE IS NOT CALLED FOR.  READ THE TABLE SERIALLY UNTIL AN   
C     END OF TABLE INDICATOR (TWO MINUS ONES FOR TABLE TYPES 1,2,3 AND  
C     ONE MINUS ONE FOR TABLE TYPE 4        
C        
      NWDS = 2        
      IF (LIST(3*JJ+1) .EQ. 4) NWDS = 1        
   55 CALL READ (*1020,*1040,DIT,IARY(2),NWDS,NEOR,IFLAG)        
      IF (IARY(2) .EQ. -1) GO TO 40        
      GO TO 55        
C        
C     THERE ARE TWO DIFFERENT TABLES WITH THE SAME NUMBER -- FATAL ERROR
C        
   60 IARY(1) = TABNO        
      IARY(2) = LIST(3*JJ-1)        
      CALL MESAGE (-30,88,IARY)        
C        
C     THIS IS A NEW TABLE.  SET TABLE NUMBER NEGATIVE AND DEFINE WORDS  
C     2 AND 3 OF THE PROPER DICTIONARY ENTRY.        
C        
   70 TABTYP = LIST(3*JJ+1)        
      TABNOL(J+1) = -TABNOL(J+1)        
      INDEX  = LNTH*(J-1) + OFFSET        
      IZ(INDEX+2) = TABTYP        
      IZ(INDEX+3) = ITABLE + 1        
C        
C     READ THE TABLE INTO CORE.        
C        
      NWDSRD = 2        
      IF (TABTYP .EQ. 4) NWDSRD = 1        
      II = ITABLE + 1        
   80 CALL READ (*1020,*1040,DIT,Z(II),NWDSRD,NEOR,FLAG)        
      IF (IZ(II) .EQ. -1) GO TO 90        
      II   = II + NWDSRD        
      ICRQ = II - LCRGVN - OFFSET        
      IF (ICRQ .GE. 0) GO TO 1080        
      GO TO 80        
C        
C     STORE THE LAST LOCATION OF THE TABLE IN IZ(INDEX+4)        
C        
   90 IZ(INDEX+4) = II - NWDSRD        
C        
C     STORE THE PARAMETERS ON THE TABLE CARD IN WORDS 5 THRU 11 OF THE  
C     PROPER DICTIONARY ENTRY.        
C        
      LX = INDEX + 4        
      DO 100 K = 2,8        
      LX = LX + 1        
  100 IZ(LX) = IARY(K)        
      IZ(LX+1) = SCTYP        
C        
C     STORE THE CORRECT 0TH ADDRESS OF THE NEXT TABLE IN ITABLE        
C        
      ITABLE = IZ(INDEX+4)        
C        
C     IF THE TABLE IS A POLYNOMIAL EVALUATE THE END POINTS.        
C        
      IF (TABTYP .NE. 4) GO TO 108        
      L  = INDEX + 1        
      XX = (Z(L+6) - Z(L+4))/Z(L+5)        
      ASSIGN 470 TO IGOTO        
      GO TO  440        
  102 ASSIGN 480 TO IGOTO        
      XX = (Z(L+7) - Z(L+4))/Z(L+5)        
      GO TO 440        
  108 ITABLE = ITABLE + 1        
      GO TO 40        
C        
C     TEST TO SEE IF ALL OF THE REQUESTED TABLES HAVE BEEN FOUND. IF    
C     ALL TABLES HAVE NOT BEEN FOUND, GO TO NEXT TRIPLE IN LIST ARRAY   
C        
  110 IF (JJ .GE. LIM) GO TO 120        
      DO 115 I = 1,LIMJJ        
      IF (TABNOL(I+1) .GT. 0) GO TO 117        
  115 CONTINUE        
      GO TO 120        
  117 JJ = JJ + 1        
      GO TO 30        
C        
C     SET ALL ENTRIES IN TABNOL BACK TO THEIR ORIGINAL POSITIVE STATUS. 
C     IF AN ENTRY IS STILL POSITIVE, THIS IMPLIES THE TABLE WAS NOT     
C     FOUND IN THE DIT AND A FATAL ERROR CONDITION EXISTS.        
C        
  120 IFLAG = 0        
      DO 140 I = 1,LIMJJ        
      IF (TABNOL(I+1) .LE. 0) GO TO 130        
      CALL MESAGE (30,89,TABNOL(I+1))        
      IFLAG = 1        
      GO TO 140        
  130 TABNOL(I+1) = -TABNOL(I+1)        
  140 CONTINUE        
      IF (IFLAG .NE. 0) CALL MESAGE (-37,0,NAME)        
C        
C     WRAP-UP PRETAB        
C        
      CALL CLOSE (DIT,CLSRW)        
      PART1  = .FALSE.        
      TABIDO = -1        
      XO     = -10.0E+37        
      LCUSED = ITABLE + 1 - OFFSET        
      ICHECK = 123456789        
      RETURN        
C        
C     ENTRY TAB COMPUTES THE FUNCTIONAL VALUE Y AT THE ABSCISSA X FOR   
C     THE FUNCTION DEFINED BY THE TABLE WHOSE NUMBER IS TABID        
C        
C        
      ENTRY TAB (TABID,X,Y)        
C     =====================        
C        
      IF (ICHECK .NE. 123456789) CALL ERRTRC ('PRETAB  ',200)        
      ASSIGN 251 TO IHOP        
C        
      IF (TABID.EQ.TABIDO .AND. X.EQ.XO) GO TO 210        
      TABIDO = TABID        
      XO     = X        
      GO TO 220        
  210 Y(1) = YO        
      RETURN        
  220 IF (TABID .NE. 0) GO TO 230        
      Y(1) = 0.0        
      YO   = 0.0        
      RETURN        
C        
C     SEARCH THE TABLE DICTIONARY TO FIND THE TABLE NUMBER        
C        
  230 DO 240 II = IDICL,IDICH,LNTH        
      IF (TABID .EQ. IZ(II)) GO TO 250        
  240 CONTINUE        
C        
C     TABID COULD NOT BE FOUND IN THE DICTIONARY - FATAL ERROR        
C        
      CALL MESAGE (-30,90,TABID)        
  250 L = II        
      ITYPE = IZ(L+ 1)        
      SCTYP = IZ(L+11) + 1        
      GO TO IHOP, (251,501)        
  251 CONTINUE        
      GO TO (260,270,280,290,295), ITYPE        
C        
C     TABLE TYPE = 1        
C        
C     A  RGUMENT = X        
C        
  260 XX = X        
      GO TO 300        
C        
C     TABLE TYPE = 2        
C        
C     ARGUMENT = (X - X1)        
C        
  270 XX = X - Z(L+4)        
      GO TO 300        
C        
C     TABLE TYPE = 3        
C        
C     ARGUMENT = (X - X1)/X2        
C        
  280 XX = (X - Z(L+4))/Z(L+5)        
      GO TO 300        
C        
C     TABLE TYPE = 4        
C        
C     ARGUMENT = (X - X1)/X2        
C        
  290 XX = (X - Z(L+4))/Z(L+5)        
      GO TO 400        
C        
C     TABLE TYPE = 5        
C        
C     TABRNDG CARD FUNTION ONLY        
C        
  295 CONTINUE        
C        
C     PICK UP TYPE        
C        
      LX = IZ(L+4)        
C        
C     P US ONE OVER TERM IN PX TABLE BASED ONL TYPE        
C        
      P = 1./PX(LX,1)        
C        
C     CONPUTE K SQUARED FROM PX TABLE        
C        
      XKSQ = PX(LX,2)*PX(LX,2)        
C        
C     RETRIEVE LU (L/U) FROM TABLE PARAMS        
C        
      XLU = Z(L+5)        
      XX  = 2.*Z(L+6)**2*XLU        
      XLU = XLU*XLU        
      WSQ = S4PISQ*XO*XO        
      TR  = XKSQ*XLU*WSQ        
      PROP= XX*(1.+2.*(P+1.)*TR)/(1.+TR)**(P+1.5)        
      GO TO 500        
C        
C     ROUTINE TO PERFORM LINEAR INTERPOLATION FOR FUNCTION IN A TABLE.  
C     L POINTS TO THE ENTRY IN THE TABLE DICTIONARY WHICH DEFINES THE   
C     TABLE. THE ARGUMENT IS XX. THE FUNCTIONAL VALUE IS STORED IN PROP.
C     EXTRAPOLATION IS MADE IF XX IS OUTSIDE THE LIMITS OF THE TABLE.   
C     HENCE THERE ARE NO ERROR RETURNS.        
C     HOWEVER, IF FUNCTION OVERFLOWED ON EXTRAPOLATION OUTSIDE TABLE    
C     LIMITS, A FATAL MESSAGE IS ISSUED.        
C        
  300 ITABL = IZ(L+2)        
      NTABL = IZ(L+3)        
      UP    = 1.0        
      IF (Z(ITABL) .GT. Z(ITABL+2)) UP = -1.0        
      KXX1  = ITABL        
      IF ((XX - Z(ITABL))*UP .LE. 0.0) GO TO 350        
      KXX1  = NTABL - 2        
      IF ((XX - Z(NTABL))*UP .GE. 0.0) GO TO 350        
      KLO = 1        
      KHI = (NTABL - ITABL)/2  +  1        
  310 KX  = (KLO + KHI + 1)/2        
      KXX = (KX - 1)*2 + ITABL        
      IF ((XX - Z(KXX))*UP) 320,370,330        
  320 KHI = KX        
      GO TO 340        
  330 KLO = KX        
  340 IF (KHI-KLO .NE. 1) GO TO 310        
      KXX1 = (KLO - 1)*2 + ITABL        
      IF (KXX .EQ.      KXX1) GO TO 350        
      IF (XX  .EQ. Z(KXX1+2)) GO TO 360        
  350 GO TO (355,351,352,353), SCTYP        
  351 CALL LOGLOG (Z(KXX1),Z(KXX1+1),Z(KXX1+2),Z(KXX1+3),XX,PROP)       
      GO TO 500        
  352 CALL SMILOG (Z(KXX1),Z(KXX1+1),Z(KXX1+2),Z(KXX1+3),XX,PROP)       
      GO TO 500        
  353 CALL LOGSMI (Z(KXX1),Z(KXX1+1),Z(KXX1+2),Z(KXX1+3),XX,PROP)       
      GO TO 500        
  355 PROP = (XX - Z(KXX1))*(Z(KXX1+3) - Z(KXX1+1))/(Z(KXX1+2)        
     1     - Z(KXX1)) + Z(KXX1+1)        
      IF (ABS(PROP) .LT. 1.0E-36) PROP = 0.0        
      IF (ABS(PROP) .LT. 1.0E+36) GO TO 500        
      IF (UP.GT.0. .AND. (XX.LT.Z(ITABL) .OR. XX.GT.Z(NTABL)))GO TO 1050
      IF (UP.LT.0. .AND. (XX.GT.Z(ITABL) .OR. XX.LT.Z(NTABL)))GO TO 1050
      GO TO 500        
  360 KXX = KXX1 + 2        
  370 IF (XX .EQ. Z(KXX-2)) GO TO 380        
      IF (XX .EQ. Z(KXX+2)) GO TO 390        
      PROP = Z(KXX+1)        
      GO TO 500        
  380 PROP = (Z(KXX-1) + Z(KXX+1))/2.0        
      GO TO 500        
  390 PROP = (Z(KXX+1) + Z(KXX+3))/2.0        
      GO TO 500        
C        
C     POLYNOMIAL EVALUATION        
C        
  400 IF (XX - (Z(L+6) - Z(L+4))/Z(L+5)) 410,410,420        
  410 PROP = Z(L+8)        
      GO TO 500        
  420 IF (XX - (Z(L+7) - Z(L+4))/Z(L+5)) 440,430,430        
  430 PROP = Z(L+9)        
      GO TO 500        
  440 NN   = IZ(L+3)        
      PROP = Z(NN)        
  450 IF (NN .LE. IZ(L+2)) GO TO 460        
      PROP = PROP*XX + Z(NN-1)        
      NN   = NN - 1        
      GO TO 450        
  460 IF (PART1) GO TO IGOTO, (470,480)        
      GO TO 500        
  470 Z(L+8) = PROP        
      GO TO 102        
  480 Z(L+9) = PROP        
      GO TO 40        
C        
C     TAB WRAP-UP        
C        
  500 Y(1) = PROP        
      YO   = Y(1)        
      RETURN        
C        
C        
      ENTRY TAB1 (TABID,X,Y)        
C     ======================        
C        
C     ENRTY FOR TABLE TRANSFORM        
C        
      ASSIGN 501 TO IHOP        
      GO TO 220        
  501 CONTINUE        
C        
C     L  POINTS  TO TABLE        
C     ITYPE IS THE TABLE TYPE        
C        
      ITABL = IZ(L+2)        
      NTABL = IZ(L+3)        
      OMEGA = TWOPI*X        
      GO TO (510,520,530,540), ITYPE        
C        
C     TABLED1        
C        
  510 CONTINUE        
      X1 = 0.0        
      X2 = 1.0        
      GO TO 550        
C        
C     TABLED2        
C        
  520 CONTINUE        
      X1 = Z(L+4)        
      X2 = 1.0        
      GO TO 550        
C        
C     TABLED3        
C        
  530 CONTINUE        
      X1 = Z(L+4)        
      X2 = Z(L+5)        
      GO TO 550        
C        
C     TABLED4        
C        
  540 CONTINUE        
C        
C     EVALUATE SUM        
C        
  550 CONTINUE        
      SUM = CMPLX(0.0,0.0)        
      K   = ITABL        
  551 CONTINUE        
      YI   = Z(K+1)        
      XI   = Z(K)        
      YIP1 = Z(K+3)        
      XIP1 = Z(K+2)        
      OMEGAX = OMEGA*X2*(XIP1-XI)        
      CALL IFTE2 (OMEGAX,RP,CP)        
      P    =-OMEGA*(X1 + X2*XIP1)        
      A    = CMPLX(0.,P)        
      B    = CMPLX(RP,CP)        
      TERM = CEXP(A)*B*YIP1        
      P    =-OMEGA*(X1 + X2*XI)        
      A    = CMPLX(0.,P)        
      B    = CMPLX(RP,-CP)        
      TERM = TERM + CEXP(A)*B*YI        
      TERM = TERM*(XIP1- XI)*.5        
      SUM  = SUM  + TERM        
      K    = K + 2        
      IF (K .LT. NTABL) GO TO 551        
C        
C     FINISH FUNCTION        
C        
      SUM  = SUM*X2        
      Y(1) = REAL(SUM)        
      Y(2) = AIMAG(SUM)        
      RETURN        
C        
C     FATAL ERROR MESSAGES        
C        
 1010 MN = -1        
      GO TO 1100        
 1020 MN = -2        
      GO TO 1100        
 1040 MN = -3        
      GO TO 1100        
 1050 WRITE  (NOUT,1055) UFM,IZ(L)        
 1055 FORMAT (A23,' 3308, TABLE',I9,' INTERPOLATION ERROR', /5X,        
     1       'FUNCTION OVERFLOWED WHEN EXTRAPOLATION WAS MADE OUTSIDE ',
     2       'TABLE GIVEN RANGE.')        
      MN = -37        
      GO TO 1100        
 1080 MN = -8        
      DIT= ICRQ        
 1100 CALL MESAGE (MN,DIT,NAME)        
      RETURN        
      END        
