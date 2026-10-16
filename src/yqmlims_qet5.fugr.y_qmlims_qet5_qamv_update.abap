FUNCTION Y_QMLIMS_QET5_QAMV_UPDATE.
*"----------------------------------------------------------------------
*"*"Verbuchungsfunktionsbaustein:
*"
*"*"Lokale Schnittstelle:
*"  TABLES
*"      UT_QAMV STRUCTURE  QAMV OPTIONAL
*"----------------------------------------------------------------------

  IF NOT UT_QAMV[] IS INITIAL.
    UPDATE QAMV FROM TABLE UT_QAMV.
    IF SY-SUBRC <> 0.
      MESSAGE A029(YQMLIMS) WITH 'QAMV'.
    ENDIF.
    REFRESH UT_QAMV.
  ENDIF.
  CLEAR SAVE_FLAG.

ENDFUNCTION.
