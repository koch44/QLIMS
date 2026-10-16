FUNCTION Y_QMLIMS_QET1_REMARK.
*"--------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     VALUE(I_ROW_NO) LIKE  SY-CUROW
*"     VALUE(I_COL_NO) LIKE  SY-CUCOL
*"     VALUE(I_AREA) LIKE  SY-TNAME
*"  TABLES
*"      T_SPECS STRUCTURE  QETBCELLS
*"      T_RESULTS STRUCTURE  QETBCELLS
*"--------------------------------------------------------------------
  DATA: L_VORGLFNR LIKE QAPO-VORGLFNR.
  DATA: L_SAMPLE_RESULT LIKE BAPI2045D3.
  DATA: L_CHAR_RESULT LIKE BAPI2045D2.
  DATA: L_CHAR_REQUIREMENTS LIKE  BAPI2045D1.
  DATA: L_INSP_LOT_GENERAL  LIKE  BAPI2045D_IL0.
  DATA: L_REMARK_FIELD TYPE QREFFLD.
  DATA: L_EDITOR_TITLE LIKE TTXIT-TDTEXT.
  DATA: LV_LANGTEXT_KZ TYPE CHAR1.
  DATA: LS_THEAD       TYPE THEAD.
  IF I_AREA NE 'CON_RESULTS'.          "#EC NOTEXT
    MESSAGE S013.
* Den Cursor auf ein Ergebnisfeld positionieren
    EXIT.
  ENDIF.

  READ TABLE T_RESULTS WITH KEY
                        ROW_NO = I_ROW_NO
                        COL_NO = I_COL_NO.

  IF NOT SY-SUBRC IS INITIAL.
    MESSAGE S012.
* Es sind keine Daten vorhanden
    EXIT.
  ENDIF.

  IF  T_RESULTS-INSPLOT  IS INITIAL
   OR T_RESULTS-INSPOPER IS INITIAL
   OR T_RESULTS-INSPCHAR IS INITIAL.
    MESSAGE S013.
* Den Cursor auf ein Ergebnisfeld positionieren
    EXIT.
  ENDIF.

* read toolbox data
  CALL FUNCTION 'QET4_SYNCHRONIZE_DATA'
       EXPORTING
            I_CELLS             = T_RESULTS
       IMPORTING
            E_CHAR_RESULT       = L_CHAR_RESULT
            E_SAMPLE_RESULT     = L_SAMPLE_RESULT
            E_CHAR_REQUIREMENTS = L_CHAR_REQUIREMENTS
            E_INSP_LOT          = L_INSP_LOT_GENERAL.

* get internal operation number
  CALL FUNCTION 'QIBP_GET_VORGLFNR'
       EXPORTING
            I_INSP_LOT = T_RESULTS-INSPLOT
            I_OPER_NO  = T_RESULTS-INSPOPER
       IMPORTING
            E_VORGLFNR = L_VORGLFNR.

* remark for characteristic
  IF T_RESULTS-INSPSAMPLE IS INITIAL.
    SCHLUESSEL_MERKMAL-PRUEFLOS = T_RESULTS-INSPLOT.
    SCHLUESSEL_MERKMAL-VORGLFNR = L_VORGLFNR.
    SCHLUESSEL_MERKMAL-MERKNR   = T_RESULTS-INSPCHAR.
    MOVE SCHLUESSEL_MERKMAL  TO LTEXTSCHLUESSEL.

*   display or change
    IF T_RESULTS-INPUT_FLG IS INITIAL.
      VKZ = 'AZ'.                      " anzeigen
    ELSE.
      VKZ = 'UP'.                      " Editor erfassen
    ENDIF.

*   short text
    KURZTEXT = L_CHAR_RESULT-REMARK.
    L_EDITOR_TITLE = L_CHAR_REQUIREMENTS-CHAR_DESCR.

*   Textverarbeitung aufrufen
    CALL FUNCTION 'QSS_TEXT_PROCESSING'
         EXPORTING
              VKZ            = VKZ
              INLINE_ZAEHL   = '1'
              OBJECT         = TEXTMERKMAL
              SCHLUESSEL     = LTEXTSCHLUESSEL
              SPRSL          = L_INSP_LOT_GENERAL-LANGU
              TEXTID         = PRUEFBEM_MERKMAL_ID
              ZEILE_IMP      = KURZTEXT
              I_OLD_EDITOR   = ' '
              I_EDITOR_TITLE = L_EDITOR_TITLE
         IMPORTING
              ACTION         = ACTION
              ZEILE_EXP      = KURZTEXT
              E_LANGTEXT_KZ  = LV_LANGTEXT_KZ.

    L_REMARK_FIELD = 'G_CHAR_RESULTS-REMARK'.

    IF NOT T_RESULTS-INPUT_FLG IS INITIAL.     "erfassen
*     Langtextkennzeichen zur Prüfbemerkung setzen
      MOVE LTEXTSCHLUESSEL          TO LS_THEAD-TDNAME.
      MOVE TEXTMERKMAL              TO LS_THEAD-TDOBJECT.
      MOVE L_INSP_LOT_GENERAL-LANGU TO LS_THEAD-TDSPRAS.
      MOVE PRUEFBEM_MERKMAL_ID      TO LS_THEAD-TDID.
      CALL FUNCTION 'QEEM_PRLTEXTKZ'
           EXPORTING
                IV_CONFIRM_NO = L_CHAR_REQUIREMENTS-CONFIRM_NO
                IV_INSPSAMPLE = T_RESULTS-INSPSAMPLE
                IV_PRLTEXTKZ  = LV_LANGTEXT_KZ
                IS_THEAD      = LS_THEAD.
    ENDIF.

* remark for sample
  ELSE.
    SCHLUESSEL_PROBE-PRUEFLOS = T_RESULTS-INSPLOT.
    SCHLUESSEL_PROBE-VORGLFNR = L_VORGLFNR.
    SCHLUESSEL_PROBE-MERKNR   = T_RESULTS-INSPCHAR.
    SCHLUESSEL_PROBE-PROBENR  = T_RESULTS-INSPSAMPLE.
    MOVE SCHLUESSEL_PROBE TO LTEXTSCHLUESSEL.

*   display or change
    IF T_RESULTS-INPUT_FLG IS INITIAL.
      VKZ = 'AZ'.                      " anzeigen
    ELSE.
      VKZ = 'UP'.                      " Editor erfassen
    ENDIF.

*   short text
    KURZTEXT = L_SAMPLE_RESULT-REMARK.
    L_EDITOR_TITLE = L_CHAR_REQUIREMENTS-CHAR_DESCR.

*   Textverarbeitung aufrufen
    CALL FUNCTION 'QSS_TEXT_PROCESSING'
         EXPORTING
              VKZ            = VKZ
              INLINE_ZAEHL   = '1'
              OBJECT         = TEXTPROBE
              SCHLUESSEL     = LTEXTSCHLUESSEL
              SPRSL          = L_INSP_LOT_GENERAL-LANGU
              TEXTID         = PRUEFBEM_PROBE_ID
              ZEILE_IMP      = KURZTEXT
              I_OLD_EDITOR   = ' '
              I_EDITOR_TITLE = L_EDITOR_TITLE
         IMPORTING
              ACTION         = ACTION
              ZEILE_EXP      = KURZTEXT
              E_LANGTEXT_KZ  = LV_LANGTEXT_KZ.

    L_REMARK_FIELD = 'G_SAMPLE_RESULTS-REMARK'.

    IF NOT T_RESULTS-INPUT_FLG IS INITIAL.     "erfassen
* Langtextkennzeichen zur Prüfbemerkung setzen
      MOVE LTEXTSCHLUESSEL          TO LS_THEAD-TDNAME.
      MOVE TEXTPROBE                TO LS_THEAD-TDOBJECT.
      MOVE L_INSP_LOT_GENERAL-LANGU TO LS_THEAD-TDSPRAS.
      MOVE PRUEFBEM_PROBE_ID        TO LS_THEAD-TDID.
      CALL FUNCTION 'QEEM_PRLTEXTKZ'
           EXPORTING
                IV_CONFIRM_NO = L_CHAR_REQUIREMENTS-CONFIRM_NO
                IV_INSPSAMPLE = T_RESULTS-INSPSAMPLE
                IV_PRLTEXTKZ  = LV_LANGTEXT_KZ
                IS_THEAD      = LS_THEAD.
    ENDIF.
  ENDIF.

* transport short text to toolbox data
  CALL FUNCTION 'QET4_SET_CHAR_RESULTS'
       EXPORTING
            I_VALUE           = KURZTEXT
            I_CELLS           = T_RESULTS
            I_ALTERNATE_FIELD = L_REMARK_FIELD
       TABLES
            T_CELLS           = T_RESULTS.

ENDFUNCTION.
