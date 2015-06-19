      SUBROUTINE CF1ORT (SUCESS,MAXITS,TEN2MT,NZERO,IORTHO,
     2                   VR,VL,V1,V1L,V2,V2L,ZB)
C*******
C     CF1ORT IS A SINGLE-PRECISION ROUTINE (CREATED FOR USE BY
C     THE COMPLEX FEER METHOD) WHICH PERFORMS THE
C     REORTHOGONALIZATION ALGORITHM
C*******
C     DEFINITION OF INPUT AND OUTPUT PARAMETERS
C*******
C     SUCESS   = LOGICAL INDICATOR FOR SUCCESSFUL REORTHOGONALIZATION
C                (OUTPUT)
C     MAXITS   = MAXIMUM NUMBER OF ALLOWED ITERATIONS (INPUT)
C     TEN2MT   = CONVERGENCE CRITERION
C     NZERO    = NUMBER OF ORTHOGONAL VECTOR PAIRS IN PRIOR
C                NEIGHBORHOODS INCLUDING RESTART
C     IORTHO   = NUMBER OF EXISTING ORTHOGONAL VECTOR PAIRS
C                IN CURRENT NEIGHBORHOOD
C     VR       = RIGHT-HANDED VECTOR TO BE REORTHOGONALIZED
C     VL       = LEFT -HANDED VECTOR TO BE REORTHOGONALIZED
C     V1,V1L,  = WORKING SPACE FOR FOUR VECTORS (V1L MUST
C     V2,V2L     FOLLOW V1 IN CORE)
C     ZB       = WORKING SPACE FOR ONE GINO BUFFER
C*******
      DIMENSION         VR(1)    ,VL(1)    ,V1(1)    ,V1L(1)
     2                 ,V2(1)    ,V2L(1)   ,A(2)     ,OTEST(4)
      LOGICAL           SUCESS   ,QPR      ,SKIP
      INTEGER           ZB(1)
      COMMON  /FEERAA/  DUMAA(42),ISCR7
      COMMON  /FEERXC/  DUMXC(7) ,IDIAG    ,XCDUM(3) ,NORD2
     2                 ,XCDUM2(9),QPR      ,XCDUM3(5),NUMORT
      COMMON  /UNPAKX/  IPRC     ,II       ,NN       ,INCR
      COMMON  /NAMES /  RD       ,RDREW    ,WRT      ,WRTREW
     2                 ,REW      ,NOREW    ,EOFNRW
      COMMON  /SYSTEM/  KSYS     ,NOUT
      MORTHO = NZERO+IORTHO
      IF (MORTHO.LE.0) GO TO 500
      IF (QPR) WRITE (NOUT,700)
      NUMORT = NUMORT + 1
      K = 0
      SUCESS = .FALSE.
      NN = NORD2
      CRITF = 100.*TEN2MT**2
      DO 5  I = 1,NORD2
      V2 (I) = VR(I)
    5 V2L(I) = VL(I)
      CALL GOPEN (ISCR7,ZB(1),RDREW)
    8 DO 9  I = 1,4
    9 OTEST(I) = 0.
      LL = 2
C*******
C     ENTER LOOP
C*******
      DO 40  I = 1,MORTHO
      IF (I.EQ.NZERO+1) LL = 0
      IF (QPR) WRITE (NOUT,701) I
C     VALUES ARE UNPACKED INTO BOTH V1 AND V1L
      CALL UNPACK(*10,ISCR7,V1(1))
      IF (.NOT.QPR) GO TO 20
      WRITE (NOUT,702) (V1 (J),J=1,NORD2)
      WRITE (NOUT,702) (V1L(J),J=1,NORD2)
      GO TO 20
   10 IF (IDIAG.NE.0) WRITE (NOUT,710) I
      GO TO 40
C*******
C     OBTAIN RIGHT-HAND INNER-PRODUCT TERM
C*******
   20 CALL CFNOR1 (VR(1),V1L(1),NORD2,1,A(1))
C*******
C     SUBTRACT OFF RIGHT-HAND INNER-PRODUCT TERM
C*******
      DO 25  J = 1,NORD2,2
      L = J+1
      V2(J) = V2(J) - A(1)*V1(J) + A(2)*V1(L)
   25 V2(L) = V2(L) - A(1)*V1(L) - A(2)*V1(J)
C*******
C     COMPUTE MAXIMUM RIGHT-HAND SQUARED-ERROR
C*******
      A(1) = A(1)**2+A(2)**2
      IF (OTEST(LL+1).LT.A(1)) OTEST(LL+1) = A(1)
C*******
C     OBTAIN LEFT-HAND INNER-PRODUCT TERM
C*******
      CALL CFNOR1 (VL(1),V1(1),NORD2,1,A(1))
C*******
C     SUBTRACT OFF LEFT-HAND INNER-PRODUCT TERM
C*******
      DO 30  J = 1,NORD2,2
      L = J+1
      V2L(J) = V2L(J) - A(1)*V1L(J) + A(2)*V1L(L)
   30 V2L(L) = V2L(L) - A(1)*V1L(L) - A(2)*V1L(J)
C*******
C     COMPUTE MAXIMUM LEFT-HAND SQUARED-ERROR
C*******
      A(1) = A(1)**2+A(2)**2
      IF (OTEST(LL+2).LT.A(1)) OTEST(LL+2) = A(1)
   40 CONTINUE
      DO 50  I = 1,NORD2
      VR(I) = V2 (I)
   50 VL(I) = V2L(I)
      SKIP = .FALSE.
      IF (.NOT.QPR) GO TO 91
      WRITE (NOUT,702) (VR(I),I=1,NORD2)
      WRITE (NOUT,702) (VL(I),I=1,NORD2)
C*******
C     TEST FOR CONVERGENCE
C*******
   91 IF (IDIAG.NE.0) WRITE (NOUT,703) K,CRITF,OTEST
      IF (OTEST(1).LE.CRITF .AND. OTEST(2).LE.CRITF .AND.
     2    OTEST(3).LE.CRITF .AND. OTEST(4).LE.CRITF) GO TO 450
      IF (SKIP) GO TO 92
      IF (K.NE.1.AND.K.NE.3.AND.K.NE.5) GO TO 92
      IF (IDIAG.NE.0) WRITE (NOUT,720)
      CRITF = 100.*CRITF
      SKIP = .TRUE.
      GO TO 91
   92 K = K + 1
      IF (K.GT.MAXITS) GO TO 95
      CALL CLOSE (ISCR7,EOFNRW)
      CALL GOPEN (ISCR7,ZB(1),RDREW)
      GO TO 8
   95 CALL CLOSE (ISCR7,NOREW)
      GO TO 600
  450 CALL CLOSE (ISCR7,NOREW)
  500 SUCESS = .TRUE.
  600 RETURN
  700 FORMAT(1H0,//26H BEGIN REORTHOGONALIZATION,//)                    
  701 FORMAT(1H ,13HUNPACK VECTOR,I4)                                   
  702 FORMAT(3H --,32(4H----),/(1H ,4E25.16))                           
  703 FORMAT(32H   REORTHOGONALIZATION ITERATION,I3,                    
     2 9X,14HTARGET VALUE =,E12.4,4X,8HERRORS =,4E12.4)                 
  710 FORMAT(18H ORTHOGONAL VECTOR,I4,                                  
     2 39H IS NULL IN REORTHOGONALIZATION ROUTINE)                      
  720 FORMAT(52H   REORTHOGONALIZATION TOLERANCE TEMPORARILY RELAXED)   
      END