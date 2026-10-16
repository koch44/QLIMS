FUNCTION Y_QMLIMS_QET5_INITIALIZE.
*"--------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"--------------------------------------------------------------------

  REFRESH: RESULTSTAB.

  REFRESH: G_TITLE_R.
  REFRESH: G_RESULTS.
  REFRESH: G_ROWS.

  REFRESH UT_QAMV.

  DATA: NAME_UT_QAMV(32)  VALUE '(YQMLIMS_SAPFQE10)UT_QAMV[]'.
  FIELD-SYMBOLS <UT_QAMV> TYPE ANY.
  ASSIGN (NAME_UT_QAMV) TO <UT_QAMV>.
  IF SY-SUBRC = 0.
    CLEAR <UT_QAMV>.
  ENDIF.


ENDFUNCTION.
