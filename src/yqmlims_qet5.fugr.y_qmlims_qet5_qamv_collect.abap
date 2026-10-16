FUNCTION Y_QMLIMS_QET5_QAMV_COLLECT.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     REFERENCE(IS_QAMV) TYPE  QAMV OPTIONAL
*"     REFERENCE(I_RESET) TYPE  FLAG OPTIONAL
*"  TABLES
*"      UT_QAMV STRUCTURE  QAMV OPTIONAL
*"----------------------------------------------------------------------


  IF I_RESET IS INITIAL.
    READ TABLE UT_QAMV INTO US_QAMV
               WITH KEY PRUEFLOS = IS_QAMV-PRUEFLOS
                        VORGLFNR = IS_QAMV-VORGLFNR
                        MERKNR   = IS_QAMV-MERKNR.
    IF SY-SUBRC = 0.
      MOVE-CORRESPONDING IS_QAMV TO US_QAMV.
      MODIFY UT_QAMV FROM US_QAMV INDEX SY-TABIX.
    ELSE.
      APPEND IS_QAMV TO UT_QAMV.
    ENDIF.
  ELSE.
    REFRESH UT_QAMV.
  ENDIF.

ENDFUNCTION.
