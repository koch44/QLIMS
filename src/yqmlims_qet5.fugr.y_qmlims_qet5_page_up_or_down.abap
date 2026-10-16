FUNCTION Y_QMLIMS_QET5_PAGE_UP_OR_DOWN.
*"--------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     VALUE(I_AREA) LIKE  SY-TNAME
*"     VALUE(I_OK_CODE) LIKE  T185-FCODE
*"  EXCEPTIONS
*"      NO_SCROLLING
*"--------------------------------------------------------------------
  DATA:
    L_TFILLN         LIKE QAQEE-TFILLN,
    L_TABIXN         LIKE QAQEE-TABIXN,
    L_LOOP_INKREMENT LIKE LOOP_INKREMENT_RESULTS.

* Table Control: Ergebnisse
  MOVE G_PAGEBEGIN_CHAR   TO L_TABIXN.
  MOVE LOOP_INKREMENT_RESULTS TO L_LOOP_INKREMENT.
  DESCRIBE TABLE RESULTSTAB LINES L_TFILLN.

* Blättern in tabellarischen Strukturen laut SAP Style Guide
  CALL FUNCTION 'SCROLLING_IN_TABLE'
    EXPORTING
* Aktuelle Position in der Verarbeitungstabelle
      ENTRY_ACT      = L_TABIXN
* Umfang der Verarbeitungstabelle (aktueller Inhalt)
      ENTRY_TO       = L_TFILLN
* Letzte Seite voll auffüllen 'X', seitengerecht ' '
      LAST_PAGE_FULL = 'X'
      LOOPS          = L_LOOP_INKREMENT
      OK_CODE        = I_OK_CODE
      OVERLAPPING    = ' '
    IMPORTING
      ENTRY_NEW      = L_TABIXN
    EXCEPTIONS
      NO_ENTRY_TO    = 0.

  MOVE L_TABIXN TO CON_RESULTS-CURRENT_LINE.
  MOVE L_TABIXN TO CON_RESULTS-TOP_LINE.

ENDFUNCTION.
