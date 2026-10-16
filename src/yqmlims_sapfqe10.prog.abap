PROGRAM YQMLIMS_SAPFQE10.
* The type of program SAPFQE10 is 'M' Module pool. But the program
* is used like a subroutine pool type 'S'.

INCLUDE <ICON>.
INCLUDE RQETBI20.
INCLUDE RQETBI30.

TABLES: QALS,
        QAPO,
        RMQEA.

DATA: GV_INSPLOT     LIKE BAPI2045D5-INSPLOT.
DATA: GV_INSPOPER    LIKE BAPI2045D5-INSPOPER.
DATA: GS_SAMPLES     TYPE QSMPL_LIST.
DATA: GT_SAMPLES     TYPE TABLE OF QSMPL_LIST.

DATA: US_QAMV       LIKE QAMV.
DATA: UT_QAMV       TYPE TABLE OF QAMV.

DATA: GS_QALS       LIKE QALS.
DATA: GT_QALS       TYPE TABLE OF QALS.

DATA: GS_QPRS       LIKE QPRS.
DATA: GT_QPRS       TYPE TABLE OF QPRS.

DATA: H_RESULTS     LIKE QETBCELLS.

DATA: L_CELLS           TYPE QETBCELLS OCCURS 0 WITH HEADER LINE.
DATA: C_MAX_INSP_POINT  LIKE BAPI2045D5-INSPPOINT VALUE '999999'.
DATA: G_PS_FIX_COLUMNS  TYPE I.
DATA: G_NEXT_INSP_POINT LIKE QAPP-PROBENR.

DATA: GV_HEADER_ROWS     TYPE I VALUE 4.
DATA: GV_HEADER_COLS     TYPE I VALUE 6.
DATA: GV_LEN_MAX         LIKE USPARAM-PARVA.
DATA: GV_SLWBEZ          TYPE QALS-SLWBEZ.

DATA: GV_TRANSFORMED    TYPE QKZ.
DATA: GV_VORWERTE       TYPE QKZ.
DATA: GV_VORGABEN       TYPE QKZ.

DATA: UT_QASR           TYPE TABLE OF QASR.

DATA: BEGIN OF T_COLUMNS,
        ZINSPLOT    TYPE BAPI2045D1-INSPLOT,
        ZINSPOPER   TYPE BAPI2045D1-INSPOPER,
        ZINSPCHAR   TYPE BAPI2045D1-INSPCHAR,
        ZCONFIRM_NO TYPE BAPI2045D1-CONFIRM_NO.
        INCLUDE STRUCTURE BAPI2045D1.
DATA  END OF T_COLUMNS.

DATA: G_COLUMNS LIKE T_COLUMNS OCCURS 0 WITH HEADER LINE.

DATA: G_ROWS              TYPE QETBCELLS OCCURS 0 WITH HEADER LINE.
DATA: G_CLEAR_FIELDS(200) TYPE C OCCURS 0 WITH HEADER LINE.
DATA: H_CLEAR_FIELDS(200) TYPE C OCCURS 0 WITH HEADER LINE.

DATA: G_TITLE_L           TYPE QETBCELLS OCCURS 0 WITH HEADER LINE..

*---------------------------------------------------------------------*
*       FORM CREATE_CELLS                                             *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  G_TITLE    currently not used
*  -->  G_TITLE_R  title of results table control
*  -->  G_SPECS    fields for specifications table control
*  -->  G_RESULTS  fields for results table control
*  -->  P_PS_FIX_COLUMNS number of not scrolling columns
*  -->  P_UNLOCK   'X': Merkmale werden entsperrt
*                  ' ': Sperren bleiben wie gehabt
*---------------------------------------------------------------------*
FORM CREATE_CELLS
    TABLES G_TITLE   STRUCTURE QETBCELLS
           G_TITLE_R STRUCTURE QETBCELLS
           G_SPECS   STRUCTURE QETBCELLS
           G_RESULTS STRUCTURE QETBCELLS
*     USING p_unlock TYPE qkz
    CHANGING P_PS_FIX_COLUMNS  TYPE I.

  DATA: L_ROW_NO          LIKE QETBCELLS-ROW_NO.
  DATA: L_COL_NO          TYPE I.
  DATA: L_SAMPLE_NO       TYPE QIBPPROBE.
  DATA: L_INSP_POINT      TYPE BAPI2045L4.
  DATA: L_FOUND           TYPE C.
  DATA: L_IP_REQUIREMENTS TYPE BAPI2045D5.

  REFRESH  G_RESULTS.
  REFRESH: G_COLUMNS.
  REFRESH: G_ROWS.
  REFRESH: G_TITLE_L.

  REFRESH: G_CLEAR_FIELDS.
  REFRESH: L_CELLS.

* Parameter auswerten
  GET PARAMETER ID 'YQMLIMS_TRANSFORM' FIELD GV_TRANSFORMED.
*  GET PARAMETER ID 'YQMLIMS_VORWERTE'  FIELD vorwerte.
  GET PARAMETER ID 'YQMLIMS_VORGABEN'  FIELD GV_VORGABEN.

  G_PS_FIX_COLUMNS = 0.
  GV_HEADER_COLS    = 6.

* Sort Inspection Points
*  CALL FUNCTION 'QET4_SORT_INSP_POINTS'.

* Read Inspection Point Requirements
  CALL FUNCTION 'QET4_GET_IP_REQUIREMENTS'
    IMPORTING
      E_REQUIREMENTS = L_IP_REQUIREMENTS
    EXCEPTIONS
      NOT_FOUND      = 1.

  CHECK SY-SUBRC IS INITIAL.

* Read Inspection Point Requirements
  CALL FUNCTION 'QET4_GET_IP_REQUIREMENTS'
    EXPORTING
      I_INSPLOT      = GV_INSPLOT
      I_INSPOPER     = GV_INSPOPER
    IMPORTING
      E_REQUIREMENTS = L_IP_REQUIREMENTS
    EXCEPTIONS
      NOT_FOUND      = 1.
  CHECK SY-SUBRC IS INITIAL.

  GV_SLWBEZ = L_IP_REQUIREMENTS-IDENT_KEY.

  IF GV_SLWBEZ = '910'.
    ADD 2 TO GV_HEADER_COLS.
  ENDIF.

* Überschriften
  PERFORM NEW_TEXT_FIELD TABLES G_RESULTS USING 1 GV_HEADER_COLS 'Best.Grenze'     1.
  PERFORM NEW_TEXT_FIELD TABLES G_RESULTS USING 2 GV_HEADER_COLS 'Masseinheit'     1.
  PERFORM NEW_TEXT_FIELD TABLES G_RESULTS USING 3 GV_HEADER_COLS 'Prüfmerkmal'     1.
  PERFORM NEW_TEXT_FIELD TABLES G_RESULTS USING 4 GV_HEADER_COLS 'Prüfvorschrift'  0.

* Pruefpunktüberschriften (setzt auch g_ps_fix_columns)
  L_COL_NO = 1.
  L_ROW_NO = GV_HEADER_ROWS.

  PERFORM PRUEFPUNKT_UEBERSCHRIFTEN
      TABLES   G_RESULTS
      USING    L_IP_REQUIREMENTS
      CHANGING L_ROW_NO L_COL_NO.

* Den Zeilen Prüflos/Vorgang/Probe zuordnen
  REFRESH G_ROWS.
  REFRESH G_COLUMNS.
  REFRESH G_CLEAR_FIELDS.

* the following fields of structure BAPI2045D1 (characteristic
* requirements are not relevant for building new lines:
  SPLIT 'INSPLOT INSPOPER STATUS CONFIRM_NO SCOPE CC_NO' AT SPACE
         INTO TABLE G_CLEAR_FIELDS.

  SPLIT 'LW_TOL_LMT UP_TOL_LMT LW_LMT_1 UP_LMT_1 LW_LMT_2 UP_LMT_2'
         AT SPACE
         INTO TABLE H_CLEAR_FIELDS.

  LOOP AT H_CLEAR_FIELDS.
    APPEND H_CLEAR_FIELDS TO G_CLEAR_FIELDS.
  ENDLOOP.

* Die Spalten für die Merkmale festlegen
  PERFORM CREATE_COLUMNS.
  PERFORM CREATE_ROWS USING 4.

**************

* Merkmalsüberschriften
  L_ROW_NO = 3.
  L_COL_NO = G_PS_FIX_COLUMNS + 1.
  PERFORM MERKMALS_UEBERSCHRIFTEN
      TABLES G_RESULTS
    CHANGING L_ROW_NO L_COL_NO.

* Results Area
  L_FOUND = C_SET.
  WHILE NOT L_FOUND IS INITIAL.

*   Nächsten Prüfpunkt lesen
    CALL FUNCTION 'QET4_GET_INSP_POINT'
      EXPORTING
        I_NUMBER          = SY-INDEX
      IMPORTING
        E_INSP_POINT_DATA = L_INSP_POINT
      EXCEPTIONS
        NOT_FOUND         = 1.
    IF NOT SY-SUBRC IS INITIAL.
      CLEAR L_FOUND.
      EXIT.
    ENDIF.

*   Read Inspection Point Requirements
    CALL FUNCTION 'QET4_GET_IP_REQUIREMENTS'
      EXPORTING
        I_INSPLOT      = L_INSP_POINT-INSPLOT
        I_INSPOPER     = L_INSP_POINT-INSPOPER
      IMPORTING
        E_REQUIREMENTS = L_IP_REQUIREMENTS
      EXCEPTIONS
        NOT_FOUND      = 1.
    CHECK SY-SUBRC IS INITIAL.

*   suppress input row
    CHECK L_INSP_POINT-INSPPOINT < C_MAX_INSP_POINT.

*   Zeilennummer für diesen Prüfpunkt bestimmen
    PERFORM GET_ROW_NO USING L_INSP_POINT
                    CHANGING L_ROW_NO.

*   l_col_no wird bei Prüfpunktdaten hochgezählt,
*   bei Merkmalsdaten aus Vorgang/Merknr. ermittelt.
    L_COL_NO = 1.

    READ TABLE GT_QALS INTO GS_QALS
         WITH KEY PRUEFLOS = L_INSP_POINT-INSPLOT.
    IF SY-SUBRC <> 0.
      SELECT SINGLE * FROM QALS INTO GS_QALS
         WHERE PRUEFLOS = L_INSP_POINT-INSPLOT.
      IF SY-SUBRC = 0.
        APPEND GS_QALS TO GT_QALS.
      ENDIF.
    ENDIF.

*   Prüfpunktfelder ausgeben
    PERFORM PRUEFPUNKT_DATEN
         TABLES   G_RESULTS
         USING    L_INSP_POINT  L_IP_REQUIREMENTS
         CHANGING L_ROW_NO L_COL_NO.

*   Merkmale zu diesem Prüfpunkt ausgeben
    PERFORM MERKMALS_DATEN
         TABLES   G_RESULTS
         USING    L_INSP_POINT  L_IP_REQUIREMENTS
         CHANGING L_ROW_NO L_COL_NO.

  ENDWHILE.

  P_PS_FIX_COLUMNS  = G_PS_FIX_COLUMNS.

* Bei mehr als 50 Spalten kann nur Transformiert dargestellt werden
  IF L_COL_NO > 50.
    GV_TRANSFORMED = 'X'.
  ENDIF.

  IF GV_TRANSFORMED = 'X'.
    PERFORM TRANSFORM TABLES G_RESULTS.
    G_TITLE_R[]      = G_TITLE_L[].
    P_PS_FIX_COLUMNS = 4.
  ELSE.
    PERFORM SET_COLUMN_TITLE TABLES G_RESULTS
                             G_TITLE_R.
  ENDIF.

ENDFORM.                    "create_cells

*&---------------------------------------------------------------------*
*&      Form  SET_TITLE
*&---------------------------------------------------------------------*
*       Diese Form wird vom Anzeigeprogramm der Toolbox aufgerufen,
*       um den GUI-Titel zu setzen.
*----------------------------------------------------------------------*
*      -->P_STATUS          GUI-Status
*      -->P_SCREEN_MANAGER  Aufbereitung der Erfassungsmaske
*----------------------------------------------------------------------*
FORM SET_TITLE USING P_TITLE TYPE GUI_STATUS
                     P_SCREEN_MANAGER TYPE GUI_TEXT.

  SET TITLEBAR P_TITLE OF PROGRAM P_SCREEN_MANAGER.

ENDFORM.                               " SET_TITLE

*&---------------------------------------------------------------------*
*&      Form  SET_STATUS
*&---------------------------------------------------------------------*
*       Diese Form wird vom Anzeigeprogramm der Toolbox aufgerufen,
*       um den GUI-Status zu setzen.
*----------------------------------------------------------------------*
*      -->P_STATUS          GUI-Status
*      -->P_SCREEN_MANAGER  Aufbereitung der Erfassungsmaske
*----------------------------------------------------------------------*
FORM SET_STATUS USING P_STATUS TYPE GUI_STATUS
                      P_SCREEN_MANAGER TYPE GUI_TEXT.

  SET PF-STATUS P_STATUS OF PROGRAM P_SCREEN_MANAGER.

ENDFORM.                               " SET_STATUS

*&---------------------------------------------------------------------*
*&      Form  USER_OK_CODE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_SPECS    text
*      -->P_RESULTS  text
*      -->P_ROW_NO   text
*      -->P_COL_NO   text
*      -->P_AREA     text
*      -->P_OK_CODE  text
*----------------------------------------------------------------------*
FORM USER_OK_CODE TABLES   P_SPECS   STRUCTURE QETBCELLS
                      P_RESULTS STRUCTURE QETBCELLS
             USING    P_ROW_NO  LIKE SY-CUROW
                      P_COL_NO  LIKE SY-CUCOL
                      P_AREA    LIKE SY-TNAME
                      P_OK_CODE LIKE T185-FCODE.

  CASE P_OK_CODE.

*   Zeilen und Spalten tauschen
    WHEN 'ZTRANSFORM'.
*      PERFORM TRANSFORM TABLES P_RESULTS.
      IF GV_TRANSFORMED = 'X'.
        CLEAR GV_TRANSFORMED.
      ELSE.
        GV_TRANSFORMED = 'X'.
      ENDIF.
      SET PARAMETER ID 'YQMLIMS_TRANSFORM' FIELD GV_TRANSFORMED.
      PERFORM START_OF_PROGRAM IN PROGRAM SAPLYQMLIMS_QET5.

*   automatische Spaltenbreite
    WHEN 'ZCOLWIDTH'.
      PERFORM COLUMN_WIDTH IN PROGRAM SAPLYQMLIMS_QET5 USING 'X'
                                                             ' '.

*   Maximale Spaltenbreite festlegen
    WHEN 'ZMAXLENGTH'.
      DATA: VALUE  TYPE I.

      CALL FUNCTION 'Y_QMLIMS_QET5_GET_MAX_LENGTH'
        IMPORTING
          E_LEN_MAX = VALUE.

      GV_LEN_MAX = VALUE.
      SET PARAMETER ID 'YQMLIMS_MAXLENGTH' FIELD GV_LEN_MAX.
      PERFORM COLUMN_WIDTH IN PROGRAM SAPLYQMLIMS_QET5 USING ' '
                                                             'X'.

*   Auffüllen mit Bestimmungsgrenzen
    WHEN 'ZBESTGR'.
      PERFORM BESTIMMUNGSGRENZEN TABLES P_RESULTS.

*   Vorgaben ein/aus
    WHEN 'ZVORGABEN'.
      PERFORM VORGABEN TABLES P_RESULTS.

*   Einstellungen sichern
    WHEN 'ZSETTINGS'.
      PERFORM SAVE_SETTINGS.

*   Navigation zum ersten Merkmal der nächsten Spalte
    WHEN 'NEXT_CHAR'.
      PERFORM NEXT_CHAR.

* Prüfmethode ändern
    WHEN 'PM_CHANGE'.
      READ TABLE P_RESULTS WITH KEY ROW_NO = P_ROW_NO
                                    COL_NO = P_COL_NO.

      PERFORM CHANGE_INSPECTION_METHOD TABLES P_RESULTS
                                       USING  P_ROW_NO
                                              P_COL_NO.

      PERFORM START_OF_PROGRAM IN PROGRAM SAPLYQMLIMS_QET5.

* Probenahmezeit ändern
    WHEN 'QPRS'.
      READ TABLE P_RESULTS WITH KEY ROW_NO = P_ROW_NO
                                    COL_NO = P_COL_NO.

      LOOP AT GT_QPRS INTO GS_QPRS WHERE PHYNR = P_RESULTS-REF_FIELD.

        CALL FUNCTION 'Y_QMLIMS_QET5_QPRS_UPDATE'
          EXPORTING
            IS_QPRS          = GS_QPRS
          IMPORTING
            ES_QPRS          = GS_QPRS
          EXCEPTIONS
            ACTION_CANCELLED = 1
            OTHERS           = 2.
        IF SY-SUBRC = 0.
* Implement suitable error handling here

          CALL FUNCTION 'QPRS_MASTER_SAMPLE_UPDATE'
            EXPORTING
              I_PHYNR            = GS_QPRS-PHYNR
              I_QPRS_UPD         = GS_QPRS
            EXCEPTIONS
              LOCKING_ERROR      = 1
              NO_ENTRY_FOUND     = 2
              WRONG_IMPORT_PARAM = 3
              WRONG_MODUS        = 4
              STATUS_ERROR       = 5
              NO_DATA_CHANGED    = 6
              ACTION_CANCELED    = 7
              OTHERS             = 8.
          IF SY-SUBRC = 0.
* Implement suitable error handling here
            MODIFY GT_QPRS FROM GS_QPRS.
            CALL FUNCTION 'Y_QMLIMS_QET5_SET_SAVE_FLAG'.
          ENDIF.

        ENDIF.

      ENDLOOP.

      PERFORM START_OF_PROGRAM IN PROGRAM SAPLYQMLIMS_QET5.

    WHEN 'QPRS_ALL'.

      LOOP AT GT_QPRS INTO GS_QPRS.

        CALL FUNCTION 'Y_QMLIMS_QET5_QPRS_UPDATE'
          EXPORTING
            IS_QPRS          = GS_QPRS
          IMPORTING
            ES_QPRS          = GS_QPRS
          EXCEPTIONS
            ACTION_CANCELLED = 1
            OTHERS           = 2.
        IF SY-SUBRC = 0.
* Implement suitable error handling here
          CALL FUNCTION 'QPRS_MASTER_SAMPLE_UPDATE'
            EXPORTING
              I_PHYNR            = GS_QPRS-PHYNR
              I_QPRS_UPD         = GS_QPRS
            EXCEPTIONS
              LOCKING_ERROR      = 1
              NO_ENTRY_FOUND     = 2
              WRONG_IMPORT_PARAM = 3
              WRONG_MODUS        = 4
              STATUS_ERROR       = 5
              NO_DATA_CHANGED    = 6
              ACTION_CANCELED    = 7
              OTHERS             = 8.
          IF SY-SUBRC = 0.
* Implement suitable error handling here
            MODIFY GT_QPRS FROM GS_QPRS.
            CALL FUNCTION 'Y_QMLIMS_QET5_SET_SAVE_FLAG'.
          ENDIF.

        ELSE.
          EXIT.
        ENDIF.

      ENDLOOP.

      PERFORM START_OF_PROGRAM IN PROGRAM SAPLYQMLIMS_QET5.

  ENDCASE.

ENDFORM.                    "user_ok_code


*&---------------------------------------------------------------------*
*&      Form  INSERT_ROW_KEY_TITLES
*&---------------------------------------------------------------------*
*       Legt die Überschriften für die Spalten mit den Zeilentiteln an.
*       (Überschrift der Prüfpunktfelder)
*----------------------------------------------------------------------*
*      -->P_G_TITLE  text
*      -->P_L_IP_REQUIREMENTS  text
*      -->P_L_COL_NO  text
*      -->P_L_ROW_NO  text
*----------------------------------------------------------------------*
FORM INSERT_TITLE_FOR_KEY_COLUMNS
      TABLES   T_CELLS   STRUCTURE QETBCELLS
      USING    I_ROW_NO  LIKE QETBCELLS-ROW_NO
               I_COL_NO  LIKE QETBCELLS-COL_NO
      CHANGING E_FOUND   TYPE C.

  DATA: L_IP_REQUIREMENTS TYPE BAPI2045D5.
  DATA: L_FIELD_ORDER TYPE QKZUSRAKT.
  DATA: L_REF_FIELD TYPE QREFFLD.

* Read Inspection Point Requirements
  CALL FUNCTION 'QET4_GET_IP_REQUIREMENTS'
    EXPORTING
      I_INSPLOT      = GV_INSPLOT
      I_INSPOPER     = GV_INSPOPER
    IMPORTING
      E_REQUIREMENTS = L_IP_REQUIREMENTS.

* Get one user field
  CALL FUNCTION 'QET4_GET_IP_IDENT_TEXT'
    EXPORTING
      I_NUMBER          = SY-INDEX
      I_REQUIREMENTS    = L_IP_REQUIREMENTS
    IMPORTING
      E_FIELD_NAME_TEXT = L_REF_FIELD
      E_FIELD_ORDER     = L_FIELD_ORDER
    EXCEPTIONS
      NOT_FOUND         = 1.
  IF NOT SY-SUBRC IS INITIAL.
    CLEAR E_FOUND.
    EXIT.
  ENDIF.

  E_FOUND = C_SET.
  CLEAR T_CELLS.
  T_CELLS-COL_NO = I_COL_NO.
  T_CELLS-ROW_NO = I_ROW_NO.
  T_CELLS-COLOR  = '1'.
  T_CELLS-FIELD_TYPE = 'COL_TITLE'.                         "#EC NOTEXT
  CONCATENATE 'G_IP_REQUIREMENTS-' L_REF_FIELD '_TXT'       "#EC NOTEXT
              INTO T_CELLS-REF_FIELD.
  T_CELLS-INSPLOT  = L_IP_REQUIREMENTS-INSPLOT.
  T_CELLS-INSPOPER = L_IP_REQUIREMENTS-INSPOPER.

* Userfield optional
  IF L_FIELD_ORDER EQ C_SET.
    T_CELLS-INPUT_FIELD = C_SET.
  ENDIF.

  APPEND T_CELLS.

ENDFORM.                               " INSERT_ROW_KEYS

*&---------------------------------------------------------------------*
*&      Form  INSERT_TITLE_FOR_IP_COLUMNS
*&---------------------------------------------------------------------*
*       Legt die Überschriften für die Spalten mit den zusätzlichen
*       Prüfpunktfeldern an (Teillos, Charge)
*----------------------------------------------------------------------*
*      -->P_G_TITLE  text
*      -->P_L_IP_REQUIREMENTS  text
*      -->P_L_COL_NO  text
*      -->P_L_ROW_NO  text
*----------------------------------------------------------------------*
FORM PREPARE_TITLE_FOR_IP_COLUMNS
      TABLES   T_CELLS   STRUCTURE QETBCELLS
      USING    I_ROW_NO  LIKE QETBCELLS-ROW_NO
               I_COL_NO  LIKE QETBCELLS-COL_NO
               I_IP_REQUIREMENTS LIKE BAPI2045D5
               I_FIELD_NAME LIKE T_CELLS-FIELD_NAME.

  DATA: L_REF_FIELD TYPE QREFFLD.

  CLEAR T_CELLS.
  T_CELLS-COL_NO = I_COL_NO.
  T_CELLS-ROW_NO = I_ROW_NO.
  T_CELLS-INSPLOT  = I_IP_REQUIREMENTS-INSPLOT.
  T_CELLS-INSPOPER = I_IP_REQUIREMENTS-INSPOPER.
  T_CELLS-COLOR = 1.

ENDFORM.                               " INSERT_TITLE_FOR_IP_COLUMNS

*---------------------------------------------------------------------*
*       FORM Merkmals_ueberschriften                                  *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  T_CELLS                                                       *
*  -->  E_ROW_NO                                                      *
*  -->  E_COL_NO                                                      *
*---------------------------------------------------------------------*
FORM MERKMALS_UEBERSCHRIFTEN
      TABLES   T_CELLS STRUCTURE QETBCELLS
      CHANGING E_ROW_NO
               E_COL_NO.

  DATA: LS_CELLS       TYPE QETBCELLS.
  DATA: L_REQUIREMENTS TYPE BAPI2045D1.

* Merkmalsbezeichung
  DO.

*   Merkmalsvorgaben lesen
    CALL FUNCTION 'QET4_GET_CHAR_REQUIREMENTS'
      EXPORTING
        I_NUMBER       = SY-INDEX
      IMPORTING
        E_REQUIREMENTS = L_REQUIREMENTS
      EXCEPTIONS
        NOT_FOUND      = 1.

    IF NOT SY-SUBRC IS INITIAL.
      EXIT.  " ----------> Ausstieg aus der Schleife
    ENDIF.

* Position in der Matrix bestimmen
    PERFORM SEARCH_COL USING L_REQUIREMENTS
        CHANGING E_COL_NO.

    READ TABLE T_CELLS INTO LS_CELLS WITH KEY ROW_NO = '1'
                                              COL_NO = E_COL_NO.
    IF SY-SUBRC = 0.
* Eintrag existiert schon, weiter mit nächstem Merkmal
      CONTINUE.
    ENDIF.

*   Bestimmungsgrenze
    DATA: L_BG(40) TYPE  C.
    PERFORM GET_BESTIMMUNGSGRENZE USING L_REQUIREMENTS CHANGING L_BG.

    CLEAR T_CELLS.
    T_CELLS-ROW_NO = 1.
    T_CELLS-COL_NO = E_COL_NO.
    T_CELLS-COLOR  = 1.

    T_CELLS-INSPLOT  = L_REQUIREMENTS-INSPLOT.
    T_CELLS-INSPOPER = L_REQUIREMENTS-INSPOPER.
    T_CELLS-INSPCHAR = L_REQUIREMENTS-INSPCHAR.

    T_CELLS-FIELD_TYPE = 'TEXT'.
    T_CELLS-REF_FIELD = L_BG.

    APPEND T_CELLS.

*   Masseinheit
    CLEAR T_CELLS.
    T_CELLS-ROW_NO = 2.
    T_CELLS-COL_NO = E_COL_NO.
    T_CELLS-COLOR  = 1.

    T_CELLS-INSPLOT  = L_REQUIREMENTS-INSPLOT.
    T_CELLS-INSPOPER = L_REQUIREMENTS-INSPOPER.
    T_CELLS-INSPCHAR = L_REQUIREMENTS-INSPCHAR.

    T_CELLS-FIELD_TYPE = 'COL_TITLE'.

    T_CELLS-REF_FIELD = 'G_REQUIREMENTS-MEAS_UNIT'.

    APPEND T_CELLS.

*   Merkmalskurztext
    CLEAR T_CELLS.
    T_CELLS-ROW_NO = 3.
    T_CELLS-COL_NO = E_COL_NO.

    T_CELLS-INSPLOT  = L_REQUIREMENTS-INSPLOT.
    T_CELLS-INSPOPER = L_REQUIREMENTS-INSPOPER.
    T_CELLS-INSPCHAR = L_REQUIREMENTS-INSPCHAR.

    T_CELLS-FIELD_TYPE = 'COL_TITLE'.
    IF L_REQUIREMENTS-OBLIGATORY = 'X'.
      T_CELLS-COLOR = 1.
    ENDIF.

*   Fehlender Merkmalskurztext
    IF L_REQUIREMENTS-CHAR_DESCR IS INITIAL.
      T_CELLS-REF_FIELD = 'G_REQUIREMENTS-INSPCHAR'.
    ELSE.
      T_CELLS-REF_FIELD = 'G_REQUIREMENTS-CHAR_DESCR'.
    ENDIF.

    APPEND T_CELLS.

*   Prüfmethode
    CLEAR T_CELLS.
    T_CELLS-ROW_NO = 4.
    T_CELLS-COL_NO = E_COL_NO.

    T_CELLS-INSPLOT  = L_REQUIREMENTS-INSPLOT.
    T_CELLS-INSPOPER = L_REQUIREMENTS-INSPOPER.
    T_CELLS-INSPCHAR = L_REQUIREMENTS-INSPCHAR.

    T_CELLS-FIELD_TYPE = 'PMETH'.
    T_CELLS-REF_FIELD  = L_REQUIREMENTS-METHOD_TXT.

    APPEND T_CELLS.

*   Vorwert
    IF NOT GV_VORWERTE IS INITIAL.
      E_COL_NO = E_COL_NO + 1.
      CLEAR T_CELLS.
      T_CELLS-ROW_NO = E_ROW_NO.
      T_CELLS-COL_NO = E_COL_NO.

      T_CELLS-INSPLOT  = L_REQUIREMENTS-INSPLOT.
      T_CELLS-INSPOPER = L_REQUIREMENTS-INSPOPER.
      T_CELLS-INSPCHAR = L_REQUIREMENTS-INSPCHAR.

      T_CELLS-FIELD_TYPE = 'TEXT'.

      T_CELLS-REF_FIELD = 'Vorwert'.

      APPEND T_CELLS.
    ENDIF.

*   Vorgaben
    IF NOT GV_VORGABEN IS INITIAL.
      E_COL_NO = E_COL_NO + 1.
      CLEAR T_CELLS.
      T_CELLS-ROW_NO = E_ROW_NO.
      T_CELLS-COL_NO = E_COL_NO.

      T_CELLS-INSPLOT  = L_REQUIREMENTS-INSPLOT.
      T_CELLS-INSPOPER = L_REQUIREMENTS-INSPOPER.
      T_CELLS-INSPCHAR = L_REQUIREMENTS-INSPCHAR.

      T_CELLS-FIELD_TYPE = 'TEXT'.

      T_CELLS-REF_FIELD = 'Vorgaben'.

      APPEND T_CELLS.
    ENDIF.

  ENDDO.

ENDFORM.                    "merkmals_ueberschriften

*---------------------------------------------------------------------*
*       FORM PRUEFPUNKT_UEBERSCHRIFTEN                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  T_CELLS                                                       *
*  -->  I_IP_REQUIREMENTS                                             *
*  -->  E_ROW_NO                                                      *
*  -->  E_COL_NO                                                      *
*---------------------------------------------------------------------*
FORM PRUEFPUNKT_UEBERSCHRIFTEN
      TABLES   T_CELLS STRUCTURE QETBCELLS
      USING    I_IP_REQUIREMENTS STRUCTURE BAPI2045D5
      CHANGING E_ROW_NO
               E_COL_NO.

  DATA: L_FOUND TYPE C.

* Prüflos
  PERFORM NEW_TEXT_FIELD
          TABLES T_CELLS
           USING E_ROW_NO E_COL_NO 'Prüflos' 1.
  E_COL_NO = E_COL_NO + 1.

* Überschriften der Prüfpunktidentifikation einfügen
  L_FOUND = C_SET.
  WHILE NOT L_FOUND IS INITIAL.

    PERFORM INSERT_TITLE_FOR_KEY_COLUMNS
       TABLES   T_CELLS
       USING    E_ROW_NO E_COL_NO
       CHANGING L_FOUND.
    IF NOT L_FOUND IS INITIAL.
      E_COL_NO = E_COL_NO + 1.
    ENDIF.

  ENDWHILE.

* Technische Platz Bezeichnung
  PERFORM NEW_TEXT_FIELD
            TABLES T_CELLS
             USING E_ROW_NO E_COL_NO TEXT-132 1.
  E_COL_NO = E_COL_NO + 1.

  IF GV_SLWBEZ = '910'.
* Entnahmestelle
    CLEAR T_CELLS.
    T_CELLS-COL_NO        = E_COL_NO.
    T_CELLS-ROW_NO        = E_ROW_NO.
    T_CELLS-FIELD_TYPE    = 'QPRS_ALL'.                     "#EC NOTEXT
    T_CELLS-INFO          = TEXT-134.
    T_CELLS-INVALID_FLG   = SPACE.
    T_CELLS-COLOR         = 1.

    APPEND T_CELLS.

*    PERFORM new_text_field
*              TABLES t_cells
*               USING e_row_no e_col_no TEXT-134 1.
    E_COL_NO = E_COL_NO + 1.

* Probenahmedatum
    CLEAR T_CELLS.
    T_CELLS-COL_NO        = E_COL_NO.
    T_CELLS-ROW_NO        = E_ROW_NO.
    T_CELLS-FIELD_TYPE    = 'QPRS_ALL'.                     "#EC NOTEXT
    T_CELLS-INFO          = TEXT-133.
    T_CELLS-INVALID_FLG   = SPACE.
    T_CELLS-COLOR         = 1.

    APPEND T_CELLS.
    E_COL_NO = E_COL_NO + 1.

  ELSE.
    PERFORM NEW_TEXT_FIELD
              TABLES T_CELLS
               USING E_ROW_NO E_COL_NO TEXT-133 1.
    E_COL_NO = E_COL_NO + 1.

  ENDIF.

* Prüfloskurtzext
  PERFORM NEW_TEXT_FIELD
            TABLES T_CELLS
             USING E_ROW_NO E_COL_NO TEXT-131 1.
  E_COL_NO = E_COL_NO + 1.

** Teillos
*  IF NOT i_ip_requirements-partlots IS INITIAL.
*    PERFORM new_text_field
*            TABLES t_cells
*             USING e_row_no e_col_no 'Teillos' 0.
*    e_col_no = e_col_no + 1.
*  ENDIF.
*
** Charge
*  IF NOT i_ip_requirements-batches IS INITIAL.
*    PERFORM new_text_field
*            TABLES t_cells
*             USING e_row_no e_col_no 'Charge' 0.
*    e_col_no = e_col_no + 1.
*  ENDIF.
*
** Mengen
*  IF NOT i_ip_requirements-quantities IS INITIAL.
*
**   Gutmenge
*    PERFORM new_text_field
*        TABLES t_cells
*         USING e_row_no e_col_no 'Gutmenge' 0.
*    e_col_no = e_col_no + 1.
*
**   Ausschuss
*    PERFORM new_text_field
*            TABLES t_cells
*             USING e_row_no e_col_no 'Ausschuss' 0.
*    e_col_no = e_col_no + 1.
*
*  ENDIF.
*
* Anzahl Führungsspalten
  G_PS_FIX_COLUMNS = E_COL_NO.

ENDFORM.                    "pruefpunkt_ueberschriften


*&---------------------------------------------------------------------*
*&      Form  INSERT_RESULTS_ROW
*&---------------------------------------------------------------------*
*       Legt komplette Ergebniszeilen an (Schlüssel + Werte)
*----------------------------------------------------------------------*
*      -->P_G_SPECS  text
*      <--P_L_ROW_NO  text
*      <--P_L_COL_NO  text
*----------------------------------------------------------------------*
FORM PRUEFPUNKT_DATEN
     TABLES   T_CELLS      STRUCTURE QETBCELLS
     USING    I_INSP_POINT LIKE BAPI2045L4
              I_IP_REQUIREMENTS STRUCTURE BAPI2045D5
     CHANGING E_ROW_NO     LIKE QETBCELLS-ROW_NO
              E_COL_NO     LIKE QETBCELLS-COL_NO.

  DATA: L_FOUND     TYPE C.
  DATA: L_TEXT      TYPE QETBCELLS-REF_FIELD.
  DATA: L_TEXT_LONG TYPE TEXT240.
  DATA: L_DATUM     TYPE CHAR10.
  DATA: L_UZEIT     TYPE CHAR8.

* Prüflos
  L_TEXT = I_INSP_POINT-INSPLOT.
  PERFORM NEW_TEXT_FIELD
          TABLES T_CELLS
           USING E_ROW_NO E_COL_NO L_TEXT 0.
  E_COL_NO = E_COL_NO + 1.

* Inspection Point Identifications
  L_FOUND = C_SET.
  WHILE NOT L_FOUND IS INITIAL.

    PERFORM INSERT_RES_FOR_KEY_COLUMNS
       TABLES   T_CELLS
       USING    I_INSP_POINT E_ROW_NO E_COL_NO
       CHANGING L_FOUND.
    IF NOT L_FOUND IS INITIAL.
      E_COL_NO = E_COL_NO + 1.
*    ELSE.
*      e_col_no = g_qet5_qapp_fields-max_col.
    ENDIF.

  ENDWHILE.

* TP Bezeichnung
  L_TEXT = GS_QALS-KTEXTMAT.
  PERFORM NEW_TEXT_FIELD
          TABLES T_CELLS
           USING E_ROW_NO E_COL_NO L_TEXT 0.
  E_COL_NO = E_COL_NO + 1.

  IF GV_SLWBEZ = '910'.
* Entnahmestelle
    READ TABLE GT_QPRS INTO GS_QPRS
         WITH KEY PHYNR = I_INSP_POINT-PHYS_SMPL. "userc1+6(12).
    IF SY-SUBRC <> 0.
      SELECT SINGLE * FROM QPRS INTO GS_QPRS
         WHERE PHYNR = I_INSP_POINT-PHYS_SMPL. "userc1+6(12).
      IF SY-SUBRC = 0.
        APPEND GS_QPRS TO GT_QPRS.
      ELSE.
        CLEAR GS_QPRS.
      ENDIF.
    ENDIF.

*    l_text = gs_qprs-infeort.
    L_TEXT = GS_QPRS-KTEXT.

    CLEAR T_CELLS.
    T_CELLS-INSPLOT       = I_IP_REQUIREMENTS-INSPLOT.
    T_CELLS-INSPOPER      = I_IP_REQUIREMENTS-INSPOPER.
    T_CELLS-INSPSAMPLE    = I_INSP_POINT-INSPPOINT.
    T_CELLS-COL_NO        = E_COL_NO.
    T_CELLS-ROW_NO        = E_ROW_NO.
    T_CELLS-FIELD_TYPE    = 'QPRS'.                         "#EC NOTEXT
    T_CELLS-INFO          = L_TEXT.
    T_CELLS-REF_FIELD     = I_INSP_POINT-PHYS_SMPL.
    T_CELLS-INVALID_FLG   = SPACE.
    T_CELLS-COLOR         = 0.

    APPEND T_CELLS.

*    PERFORM new_text_field
*              TABLES t_cells
*               USING e_row_no e_col_no l_text 0.
    E_COL_NO = E_COL_NO + 1.

* Probenahmedatum
    IF NOT  GS_QPRS-ENTDATUM IS INITIAL.
      WRITE GS_QPRS-ENTDATUM TO L_DATUM.
      WRITE GS_QPRS-ENTZEIT  TO L_UZEIT.

      CONCATENATE L_DATUM L_UZEIT(5) INTO L_TEXT SEPARATED BY SPACE.
    ELSE.
      CLEAR L_TEXT.
    ENDIF.

    CLEAR T_CELLS.
    T_CELLS-INSPLOT       = I_IP_REQUIREMENTS-INSPLOT.
    T_CELLS-INSPOPER      = I_IP_REQUIREMENTS-INSPOPER.
    T_CELLS-INSPSAMPLE    = I_INSP_POINT-INSPPOINT.
    T_CELLS-COL_NO        = E_COL_NO.
    T_CELLS-ROW_NO        = E_ROW_NO.
    T_CELLS-FIELD_TYPE    = 'QPRS'.                         "#EC NOTEXT
    T_CELLS-INFO          = L_TEXT.
    T_CELLS-REF_FIELD     = I_INSP_POINT-PHYS_SMPL.
    T_CELLS-INVALID_FLG   = SPACE.
    T_CELLS-COLOR         = 0.

    APPEND T_CELLS.

    E_COL_NO = E_COL_NO + 1.

  ELSE.

* Probenahmedatum
*  WRITE gs_qals-zzprobedatum TO l_datum.
*  WRITE gs_qals-zzprobezeit  TO l_uzeit.
*
*  CONCATENATE l_datum l_uzeit(5) INTO l_text SEPARATED BY space.
    WRITE GS_QALS-YQM_PROBEDATUM TO L_TEXT.
    PERFORM NEW_TEXT_FIELD
            TABLES T_CELLS
             USING E_ROW_NO E_COL_NO L_TEXT 0.
    E_COL_NO = E_COL_NO + 1.

  ENDIF.

* Prüfloskurztext
  L_TEXT = GS_QALS-KTEXTLOS.
  PERFORM NEW_TEXT_FIELD
          TABLES T_CELLS
           USING E_ROW_NO E_COL_NO L_TEXT 0.
  E_COL_NO = E_COL_NO + 1.

ENDFORM.                    "pruefpunkt_daten

*---------------------------------------------------------------------*
*       FORM merkmals_daten                                           *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  T_CELLS                                                       *
*  -->  I_INSP_POINT                                                  *
*  -->  I_IP_REQUIREMENTS                                             *
*  -->  E_ROW_NO                                                      *
*  -->  E_COL_NO                                                      *
*---------------------------------------------------------------------*
FORM MERKMALS_DATEN
     TABLES   T_CELLS      STRUCTURE QETBCELLS
     USING    I_INSP_POINT LIKE BAPI2045L4
              I_IP_REQUIREMENTS STRUCTURE BAPI2045D5
     CHANGING E_ROW_NO     LIKE QETBCELLS-ROW_NO
              E_COL_NO     LIKE QETBCELLS-COL_NO.

  DATA L_FOUND TYPE C.

* Characteristics
  L_FOUND = C_SET.
*  E_COL_NO = G_PS_FIX_COLUMNS + 1.
  WHILE NOT L_FOUND IS INITIAL.

    PERFORM INSERT_RES_FOR_VAL_COLUMNS
        TABLES T_CELLS
        USING I_INSP_POINT E_ROW_NO E_COL_NO
        CHANGING L_FOUND.

*    IF NOT L_FOUND IS INITIAL.
*      E_COL_NO = E_COL_NO + 1.
*    ENDIF.

  ENDWHILE.

ENDFORM.                    "merkmals_daten

*&---------------------------------------------------------------------*
*&      Form  INSERT_RESULTS_FOR_KEY_COLUMNS
*&---------------------------------------------------------------------*
*       Prüfpunktfelder (Inhalte)
*----------------------------------------------------------------------*
*      -->P_T_CELLS  text
*      -->P_I_INSP_POINT  text
*      -->P_E_ROW_NO  text
*      -->P_E_COL_NO  text
*      <--P_L_FOUND  text
*----------------------------------------------------------------------*
FORM INSERT_RES_FOR_KEY_COLUMNS
       TABLES   T_CELLS        STRUCTURE QETBCELLS
       USING    I_INSP_POINT   LIKE BAPI2045L4
                I_ROW_NO       LIKE QETBCELLS-ROW_NO
                I_COL_NO       LIKE QETBCELLS-COL_NO
       CHANGING E_FOUND        TYPE C.

  DATA: L_IP_REQUIREMENTS TYPE BAPI2045D5.
  DATA: L_FIELD_ORDER     TYPE QKZUSRAKT.
  DATA: L_REF_FIELD       TYPE QREFFLD.
  DATA: L_TEXT            LIKE QETBCELLS-REF_FIELD.
  FIELD-SYMBOLS: <FIELD>.

* Read Inspection Point Requirements
  CALL FUNCTION 'QET4_GET_IP_REQUIREMENTS'
    EXPORTING
      I_INSPLOT      = I_INSP_POINT-INSPLOT
      I_INSPOPER     = I_INSP_POINT-INSPOPER
    IMPORTING
      E_REQUIREMENTS = L_IP_REQUIREMENTS.

* Get one user field
  CALL FUNCTION 'QET4_GET_IP_IDENT_TEXT'
    EXPORTING
      I_NUMBER       = SY-INDEX
      I_REQUIREMENTS = L_IP_REQUIREMENTS
    IMPORTING
      E_FIELD_NAME   = L_REF_FIELD
      E_FIELD_ORDER  = L_FIELD_ORDER
    EXCEPTIONS
      NOT_FOUND      = 1.
  IF NOT SY-SUBRC IS INITIAL.
    CLEAR E_FOUND.
    EXIT.
  ENDIF.

* Spaltenüberschrift
  MOVE I_INSP_POINT-FUNCT_LOC TO L_TEXT.
*  CONCATENATE 'TP' i_insp_point-funct_loc INTO l_text SEPARATED BY space.

  PERFORM NEW_TEXT_FIELD TABLES G_TITLE_L
                         USING I_COL_NO I_ROW_NO L_TEXT 1.

  E_FOUND = C_SET.
  CLEAR T_CELLS.

  T_CELLS-COL_NO = I_COL_NO.
  T_CELLS-ROW_NO = I_ROW_NO.

  CONCATENATE 'G_INSP_POINTS-' L_REF_FIELD                  "#EC NOTEXT
           INTO T_CELLS-REF_FIELD.
  T_CELLS-FIELD_TYPE = 'IP_VALUE'.                          "#EC NOTEXT
  T_CELLS-COLOR      = 1.
  T_CELLS-INSPLOT    = L_IP_REQUIREMENTS-INSPLOT.
  T_CELLS-INSPOPER   = L_IP_REQUIREMENTS-INSPOPER.
  T_CELLS-INSPSAMPLE = I_INSP_POINT-INSPPOINT.

  ASSIGN COMPONENT L_REF_FIELD OF STRUCTURE I_INSP_POINT TO <FIELD>.

  APPEND T_CELLS.

ENDFORM.                               " INSERT_RESULTS_FOR_KEY_COLUMNS

*&---------------------------------------------------------------------*
*&      Form  INSERT_RESULTS_FOR_VAL_COLUMNS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_T_CELLS  text
*      -->P_I_INSP_POINT  text
*      -->P_E_ROW_NO  text
*      -->P_E_COL_NO  text
*      <--P_L_FOUND  text
*----------------------------------------------------------------------*
FORM INSERT_RES_FOR_VAL_COLUMNS
       TABLES   T_CELLS       STRUCTURE QETBCELLS
       USING    I_INSP_POINT  LIKE BAPI2045L4
                I_ROW_NO      LIKE QETBCELLS-ROW_NO
                I_COL_NO      LIKE QETBCELLS-COL_NO
       CHANGING E_FOUND       TYPE C.

  DATA: L_REQUIREMENTS   TYPE BAPI2045D1.
  DATA: L_SAMPLE_RESULTS TYPE BAPI2045D3.
  DATA: L_REF_FIELD      LIKE QETBCELLS-REF_FIELD.
  DATA: L_CHAR_INVALID   TYPE QKZ.
  DATA: L_SHOW_ONLY      TYPE QKZ.
  DATA: L_STELLEN        LIKE QAMV-STELLEN.
  DATA: L_VORGLFNR       LIKE QAPO-VORGLFNR.
  DATA: L_CHAR_FIELD     LIKE CHA_CLASS_VIEW-SOLLWERT.
  DATA: L_QASR           LIKE QASR.
  DATA: L_QAMV           LIKE QAMV.
  DATA: L_DATE           LIKE SY-DATUM.
  DATA: L_COUNTER        LIKE SY-TABIX.
  DATA: LS_EQUI          LIKE EQUI.
  DATA: LS_QAPP          LIKE QAPP.
  DATA: LT_QAPP          TYPE TABLE OF QAPP.
  DATA: HT_QAPP          TYPE TABLE OF QAPP.

* nächstes Merkmal lesen
  CLEAR L_CHAR_INVALID.
  CALL FUNCTION 'QET4_GET_CHAR_REQUIREMENTS'
    EXPORTING
      I_NUMBER       = SY-INDEX
    IMPORTING
      E_REQUIREMENTS = L_REQUIREMENTS
    EXCEPTIONS
      NOT_FOUND      = 1.
  IF NOT SY-SUBRC IS INITIAL.
    CLEAR E_FOUND.
    EXIT.
  ENDIF.

  CHECK L_REQUIREMENTS-INSPLOT  = I_INSP_POINT-INSPLOT.
  CHECK L_REQUIREMENTS-INSPOPER = I_INSP_POINT-INSPOPER.

* Ergebnisse dazu lesen
  CALL FUNCTION 'QET4_GET_SAMPLE_RESULTS'
    EXPORTING
      I_INSPLOT        = L_REQUIREMENTS-INSPLOT
      I_INSPOPER       = L_REQUIREMENTS-INSPOPER
      I_INSPCHAR       = L_REQUIREMENTS-INSPCHAR
      I_INSPSAMPLE     = I_INSP_POINT-INSPPOINT
    IMPORTING
      E_SAMPLE_RESULTS = L_SAMPLE_RESULTS
    EXCEPTIONS
      NOT_FOUND        = 1.

* Probenergebnis gegebenenfalls anlegen
  IF NOT SY-SUBRC IS INITIAL.
    CLEAR L_SAMPLE_RESULTS.

    CALL FUNCTION 'QIBP_GET_VORGLFNR'
      EXPORTING
        I_INSP_LOT = L_REQUIREMENTS-INSPLOT
        I_OPER_NO  = L_REQUIREMENTS-INSPOPER
      IMPORTING
        E_VORGLFNR = L_VORGLFNR.

    SELECT SINGLE * FROM QAMV INTO L_QAMV
     WHERE PRUEFLOS = L_REQUIREMENTS-INSPLOT
       AND VORGLFNR = L_VORGLFNR
       AND MERKNR   = L_REQUIREMENTS-INSPCHAR.

    CHECK SY-SUBRC IS INITIAL.

    CASE L_QAMV-AKTPPKT.
      WHEN SPACE.
      WHEN 1.
        IF L_QAMV-PPKTUNGEMK <> I_INSP_POINT-INSPPOINT.
          L_CHAR_INVALID = 'X'.
        ENDIF.
      WHEN 2.
        IF L_QAMV-PPKTUNGEMK > I_INSP_POINT-INSPPOINT.
          L_CHAR_INVALID = 'X'.
        ENDIF.
    ENDCASE.
  ENDIF.

  CHECK L_CHAR_INVALID IS INITIAL.
  E_FOUND = C_SET.
  CLEAR T_CELLS.

* Position in der Matrix bestimmen
* Zeile wird von aussen vorgegeben,
* Spalte wird ermittelt
  DATA: L_COL_NO LIKE QETBCELLS-COL_NO.
  PERFORM SEARCH_COL USING L_REQUIREMENTS
      CHANGING L_COL_NO.

* Keys
  T_CELLS-ROW_NO     = I_ROW_NO.
  T_CELLS-COL_NO     = L_COL_NO.
  T_CELLS-INSPLOT    = L_REQUIREMENTS-INSPLOT.
  T_CELLS-INSPOPER   = L_REQUIREMENTS-INSPOPER.
  T_CELLS-INSPCHAR   = L_REQUIREMENTS-INSPCHAR.
  T_CELLS-INSPSAMPLE = I_INSP_POINT-INSPPOINT.

  IF NOT GT_SAMPLES[] IS INITIAL.
    READ TABLE GT_SAMPLES INTO GS_SAMPLES WITH KEY
              INSPLOT        = L_REQUIREMENTS-INSPLOT
              INSPOPER       = L_REQUIREMENTS-INSPOPER
              INSPCHAR       = L_REQUIREMENTS-INSPCHAR
              INSPSAMPLE     = I_INSP_POINT-INSPPOINT.
    IF SY-SUBRC <> 0.
      MOVE 'X' TO L_SHOW_ONLY.
    ELSE.
      CLEAR L_SHOW_ONLY.
    ENDIF.
  ELSE.
    CLEAR L_SHOW_ONLY.
  ENDIF.

  IF L_REQUIREMENTS-NO_RECORDING = 'X'.
    T_CELLS-FIELD_TYPE = 'PLAUSI'.
    T_CELLS-REF_FIELD  = L_REQUIREMENTS-CHAR_DESCR.
  ELSEIF L_SHOW_ONLY             = 'X'.
    T_CELLS-FIELD_TYPE = 'VALUE_SHOW'.
    T_CELLS-REF_FIELD  = I_INSP_POINT-INSPPOINT.
    CLEAR T_CELLS-INSPSAMPLE.
  ELSE.

    T_CELLS-FIELD_TYPE = 'VALUE2'.                          "#EC NOTEXT

    IF L_REQUIREMENTS-CHAR_TYPE = '01'.                     "#EC NOTEXT
      T_CELLS-REF_FIELD = 'G_SAMPLE_RESULTS-MEAN_VALUE'.    "#EC NOTEXT
    ELSEIF L_REQUIREMENTS-CHAR_TYPE = '05'.                 "#EC NOTEXT
      T_CELLS-REF_FIELD = 'G_SAMPLE_RESULTS-MEAN_VALUE'.    "#EC NOTEXT
    ELSEIF L_REQUIREMENTS-CHAR_TYPE = '02'.                 "#EC NOTEXT
      IF L_REQUIREMENTS-SINGLE_RES = 'X'.
        T_CELLS-REF_FIELD = 'G_SAMPLE_RESULTS-VALID_VALS'.  "#EC NOTEXT
        T_CELLS-FIELD_TYPE = 'SINGLE_RES'.                  "#EC NOTEXT
      ELSE.
        T_CELLS-REF_FIELD = 'G_SAMPLE_RESULTS-CODE1'.       "#EC NOTEXT
        T_CELLS-FIELD_TYPE = 'CODE'.                        "#EC NOTEXT
      ENDIF.
    ELSEIF L_REQUIREMENTS-CHAR_TYPE = '03'.                 "#EC NOTEXT
      T_CELLS-REF_FIELD = 'G_SAMPLE_RESULTS-NONCONF'.
    ELSE.
      T_CELLS-REF_FIELD = 'G_SAMPLE_RESULTS-DEFECTS'.       "#EC NOTEXT
    ENDIF.
    T_CELLS-INPUT_FIELD = C_SET.
  ENDIF.

  APPEND T_CELLS.

* Vorgaben
  IF NOT GV_VORGABEN IS INITIAL.

    DATA: H_REF_FIELD(80) TYPE C.

    T_CELLS-ROW_NO = I_ROW_NO.
    IF NOT GV_VORWERTE IS INITIAL.
      T_CELLS-COL_NO = L_COL_NO + 2.
    ELSE.
      T_CELLS-COL_NO = L_COL_NO + 1.
    ENDIF.
    T_CELLS-INSPLOT    = L_REQUIREMENTS-INSPLOT.
    T_CELLS-INSPOPER   = L_REQUIREMENTS-INSPOPER.
    T_CELLS-INSPCHAR   = L_REQUIREMENTS-INSPCHAR.
    T_CELLS-INSPSAMPLE = I_INSP_POINT-INSPPOINT.

    T_CELLS-FIELD_TYPE = 'TEXT'.                            "#EC NOTEXT
    IF L_REQUIREMENTS-CAT_TYPE2 = 'X'.
* Wenn Katalogart X zugeordnet ist, wird Text der Auswahlmenge als
* Vorgabe übernommen
      DATA: L_QPAM LIKE QPAM.

      CALL FUNCTION 'QPAM_SELSET_READ'
        EXPORTING
          I_KATALOGART = 'X'
          I_WERKS      = L_REQUIREMENTS-PSEL_SET2
          I_AUSWAHLMGE = L_REQUIREMENTS-SEL_SET2
        IMPORTING
          E_QPAM_WA    = L_QPAM
        EXCEPTIONS
          NO_ENTRY     = 1
          NO_AUTHORITY = 2
          OTHERS       = 3.
      IF SY-SUBRC = 0.
        MOVE L_QPAM-KTX01 TO T_CELLS-REF_FIELD.
      ENDIF.

      CONDENSE T_CELLS-REF_FIELD.
    ELSE.

      CONCATENATE L_REQUIREMENTS-LW_TOL_LMT
                  ' - '
                  L_REQUIREMENTS-UP_TOL_LMT
                  INTO H_REF_FIELD.

      CONDENSE H_REF_FIELD.
      MOVE H_REF_FIELD TO T_CELLS-REF_FIELD.

    ENDIF.
    APPEND T_CELLS.
  ENDIF.

ENDFORM.                               " INSERT_RESULTS_FOR_VAL_COLUMNS



*&---------------------------------------------------------------------*
*&      Form  TRANSFORM
*&---------------------------------------------------------------------*
*       Zeilen und Spalten tauschen
*----------------------------------------------------------------------*
*      -->P_P_RESULTS  text
*----------------------------------------------------------------------*
FORM TRANSFORM TABLES P_RESULTS STRUCTURE QETBCELLS.

  DATA: L_ROW_NO LIKE QETBCELLS-ROW_NO.
  FIELD-SYMBOLS: <TITLE>.
  DATA: TABLE_NAME(40) TYPE C.
  DATA: L_TITLE TYPE QETBCELLS.
  DATA: L_TAB TYPE STANDARD TABLE OF QETBCELLS.

  REFRESH L_TAB.

* Zeilen und Spalten tauschen
  LOOP AT P_RESULTS.
    L_ROW_NO = P_RESULTS-ROW_NO.
    P_RESULTS-ROW_NO = P_RESULTS-COL_NO.
    P_RESULTS-COL_NO = L_ROW_NO.
    P_RESULTS-INVALID_FLG = 'X'.
    APPEND P_RESULTS TO L_TAB.
  ENDLOOP.

  P_RESULTS[] = L_TAB[].


ENDFORM.                    " TRANSFORM

*&---------------------------------------------------------------------*
*& Form  CREATE_ROWS
*&---------------------------------------------------------------------*
*  Legt die Zeilen für die Prüfpunkte fest. Pro Prüfpunkt gibt es eine
*  Zeile. Die physische Probenummer wird in das Feld G_CELLS-INFO ge-
*  schrieben, da das Prüflosfeld vom Typ her nicht passt.
*----------------------------------------------------------------------*
FORM CREATE_ROWS USING P_ROW_NO LIKE QETBCELLS-ROW_NO.

  DATA: L_FOUND      TYPE C.
  DATA: L_ROW_NO     TYPE I.
  DATA: L_SORTKEY    LIKE QAPP-PPSORTKEY.
  DATA: L_INSP_POINT LIKE BAPI2045L4.

  L_ROW_NO = P_ROW_NO + 1.

* Schleife über alle Prüfpunkte
  L_FOUND = C_SET.
  WHILE NOT L_FOUND IS INITIAL.

    CALL FUNCTION 'QET4_GET_INSP_POINT'
      EXPORTING
        I_NUMBER          = SY-INDEX
      IMPORTING
        E_INSP_POINT_DATA = L_INSP_POINT
      EXCEPTIONS
        NOT_FOUND         = 1.

*   Letzter Prüfpunkt erreicht?
    IF NOT SY-SUBRC IS INITIAL.
      CLEAR L_FOUND.
      EXIT.
    ENDIF.

*    l_insp_point-phys_smpl = l_insp_point-userc1+6(12).

    READ TABLE G_ROWS WITH KEY
        INSPLOT    = L_INSP_POINT-INSPLOT
        INSPSAMPLE = L_INSP_POINT-INSPPOINT
        INFO       = L_INSP_POINT-PHYS_SMPL.
    IF NOT SY-SUBRC IS INITIAL.
*     Dem Prüfpunkt eine Zeile zuordnen
      G_ROWS-ROW_NO     = L_ROW_NO.
      L_ROW_NO          = L_ROW_NO + 1.
      G_ROWS-INSPLOT    = L_INSP_POINT-INSPLOT.
      G_ROWS-INFO       = L_INSP_POINT-PHYS_SMPL.
      G_ROWS-INSPSAMPLE = L_INSP_POINT-INSPPOINT.
      APPEND G_ROWS.
    ENDIF.

  ENDWHILE.

ENDFORM.                    "create_rows


*&---------------------------------------------------------------------*
*&      Form  CREATE_COLUMNS
*&---------------------------------------------------------------------*
*       Legt die Spalten für die Merkmale fest.
*----------------------------------------------------------------------*
*----------------------------------------------------------------------*
FORM CREATE_COLUMNS.

  DATA: L_FOUND TYPE C.
  DATA: L_REQUIREMENTS LIKE BAPI2045D1.

* Schleife über alle Merkmale
  L_FOUND = C_SET.
  WHILE NOT L_FOUND IS INITIAL.

    CLEAR L_FOUND.
    CALL FUNCTION 'QET4_GET_CHAR_REQUIREMENTS'
      EXPORTING
        I_NUMBER       = SY-INDEX
      IMPORTING
        E_REQUIREMENTS = L_REQUIREMENTS
      EXCEPTIONS
        NOT_FOUND      = 1.
    CHECK SY-SUBRC IS INITIAL.
    L_FOUND = C_SET.
    MOVE-CORRESPONDING L_REQUIREMENTS TO G_COLUMNS.
    G_COLUMNS-ZINSPLOT    = G_COLUMNS-INSPLOT.
    G_COLUMNS-ZINSPOPER   = G_COLUMNS-INSPOPER.
    G_COLUMNS-ZINSPCHAR   = G_COLUMNS-INSPCHAR.
*   G_COLUMNS-ZCONFIRM_NO = G_COLUMNS-CONFIRM_NO.
    APPEND G_COLUMNS.

  ENDWHILE.

* clear fields that are not relevant for building a new line
  LOOP AT G_COLUMNS.
    PERFORM CLEAR_COLS CHANGING G_COLUMNS.
    MODIFY G_COLUMNS.
  ENDLOOP.

* compress the remaining lines
  SORT G_COLUMNS BY MSTR_CHAR METHOD ZINSPLOT ZINSPOPER ZINSPCHAR.
  DELETE ADJACENT DUPLICATES FROM G_COLUMNS
         COMPARING MSTR_CHAR METHOD.
  SORT G_COLUMNS BY ZINSPLOT ZINSPOPER ZINSPCHAR MSTR_CHAR METHOD.

*  LOOP AT g_columns.
*    CLEAR g_columns-zinsplot.
*    MODIFY g_columns.
*  ENDLOOP.

ENDFORM.                               " CREATE_COLUMNS

*&---------------------------------------------------------------------*
*&      Form  SEARCH_COL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_L_REQUIREMENTS  text
*      <--P_L_ROW_NO  text
*----------------------------------------------------------------------*
FORM SEARCH_COL USING    P_REQUIREMENTS STRUCTURE BAPI2045D1
                CHANGING P_COL_NO TYPE I.

  DATA: L_REQUIREMENTS LIKE T_COLUMNS.
  DATA: L_FAKTOR TYPE I.
  DATA: L_INDEX TYPE I.

  L_FAKTOR = 1.
  IF NOT GV_VORWERTE IS INITIAL.
    L_FAKTOR = L_FAKTOR + 1.
  ENDIF.
  IF NOT GV_VORGABEN IS INITIAL.
    L_FAKTOR = L_FAKTOR + 1.
  ENDIF.

  MOVE-CORRESPONDING P_REQUIREMENTS TO L_REQUIREMENTS.
  L_REQUIREMENTS-ZINSPLOT    = P_REQUIREMENTS-INSPLOT.
  L_REQUIREMENTS-ZINSPOPER   = P_REQUIREMENTS-INSPOPER.
  L_REQUIREMENTS-ZINSPCHAR   = P_REQUIREMENTS-INSPCHAR.
*  L_REQUIREMENTS-ZCONFIRM_NO = P_REQUIREMENTS-CONFIRM_NO.

  PERFORM CLEAR_COLS CHANGING L_REQUIREMENTS.
  READ TABLE G_COLUMNS " FROM l_requirements
       WITH KEY MSTR_CHAR = L_REQUIREMENTS-MSTR_CHAR
                METHOD    = L_REQUIREMENTS-METHOD.
  IF SY-SUBRC <> 0.
    MESSAGE A029(YQMLIMS) WITH 'G_COLUMNS'.
  ENDIF.

  L_INDEX = SY-TABIX - 1.
  P_COL_NO = L_FAKTOR * L_INDEX + G_PS_FIX_COLUMNS + 1.

ENDFORM.                               " SEARCH_ROW

*&---------------------------------------------------------------------*
*&      Form  CLEAR_COLS
*&---------------------------------------------------------------------*
*       Delete the fields in p_row for all fieldnames in table
*       g_clear_fields.
*----------------------------------------------------------------------*
*      <--P_ROW          record with the fields to delete
*      <--G_CLEAR_FIELDS field names for the fields to delete
*----------------------------------------------------------------------*
FORM CLEAR_COLS CHANGING P_COL STRUCTURE T_COLUMNS.

  FIELD-SYMBOLS: <FIELD>, <TABLE>.

  LOOP AT G_CLEAR_FIELDS.
    ASSIGN P_COL TO <TABLE>.
    ASSIGN COMPONENT G_CLEAR_FIELDS OF STRUCTURE <TABLE> TO <FIELD>.
    CLEAR <FIELD>.
  ENDLOOP.

ENDFORM.                               " CLEAR_COLS

*---------------------------------------------------------------------*
*       FORM APPEND_EMPTY_ROW                                         *
*---------------------------------------------------------------------*
*       Hängt eine Leerzeile an. Es wird derzeit nur die Spalte 1
*       mit Spaces gefüllt. Die FuGrp QET5 verlangt mindestens 1
*       Zelle pro Zeile, sonst kommt es zum Kurzdump.
*---------------------------------------------------------------------*
*  -->  T_CELLS   Feldkatalog in den eingefügt wird
*  -->  P_ROW_NO  vorherige Zeilennummer, wird um 1 erhöht
*  -->  P_COL_NO  vorherige Spaltennummer, wird auf 1 gesetzt
*---------------------------------------------------------------------*
FORM APPEND_EMPTY_ROW TABLES T_CELLS STRUCTURE QETBCELLS
                    CHANGING P_ROW_NO LIKE QETBCELLS-ROW_NO
                             P_COL_NO LIKE QETBCELLS-COL_NO.

* Zeilenzähler erhöhen und Spalte auf 1 setzen
  P_ROW_NO = P_ROW_NO + 1.
  P_COL_NO = 1.

* Eine Zelle pro Zeile muß mindestens vorhanden sein
  CLEAR T_CELLS.
  T_CELLS-COL_NO = P_COL_NO.
  T_CELLS-ROW_NO = P_ROW_NO.
  T_CELLS-FIELD_TYPE = 'TEXT'.                              "#EC NOTEXT
  T_CELLS-REF_FIELD = '.'.
  APPEND T_CELLS.

ENDFORM.                    "append_empty_row

*---------------------------------------------------------------------*
*       FORM new_text_field                                           *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  T_CELLS                                                       *
*  -->  P_ROW_NO                                                      *
*  -->  P_COL_NO                                                      *
*  -->  P_TEXT                                                        *
*---------------------------------------------------------------------*
FORM NEW_TEXT_FIELD TABLES T_CELLS STRUCTURE QETBCELLS
                    USING  P_ROW_NO LIKE QETBCELLS-ROW_NO
                           P_COL_NO LIKE QETBCELLS-COL_NO
                           P_TEXT   LIKE QETBCELLS-REF_FIELD
                           P_COLOR  LIKE QETBCELLS-COLOR.
  CONDENSE P_TEXT.
  CLEAR T_CELLS.
  T_CELLS-COL_NO = P_COL_NO.
  T_CELLS-ROW_NO = P_ROW_NO.
  T_CELLS-FIELD_TYPE = 'TEXT'.                              "#EC NOTEXT
  T_CELLS-REF_FIELD = P_TEXT.
  T_CELLS-COLOR = P_COLOR.
  APPEND T_CELLS.

ENDFORM.                    "new_text_field
*---------------------------------------------------------------------*
*       FORM new_text_field_long                                      *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  T_CELLS                                                       *
*  -->  P_ROW_NO                                                      *
*  -->  P_COL_NO                                                      *
*  -->  P_TEXT                                                        *
*---------------------------------------------------------------------*
FORM NEW_TEXT_FIELD_LONG TABLES T_CELLS STRUCTURE QETBCELLS
                         USING  P_ROW_NO LIKE QETBCELLS-ROW_NO
                                P_COL_NO LIKE QETBCELLS-COL_NO
                                P_TEXT   TYPE TEXT240
                                P_COLOR  LIKE QETBCELLS-COLOR.
  CONDENSE P_TEXT.
  CLEAR T_CELLS.
  T_CELLS-COL_NO = P_COL_NO.
  T_CELLS-ROW_NO = P_ROW_NO.
  T_CELLS-FIELD_TYPE = 'TEXT'.                              "#EC NOTEXT
  T_CELLS-REF_FIELD = P_TEXT.
  T_CELLS-COLOR = P_COLOR.
  APPEND T_CELLS.

ENDFORM.                    "new_text_field_long

*&---------------------------------------------------------------------*
*&      Form  BESTIMMUNGSGRENZEN
*&---------------------------------------------------------------------*
*       Auffüllen mit Bestimmungsgrenzen
*----------------------------------------------------------------------*
*      -->P_RESULTS Feldcatalog
*----------------------------------------------------------------------*
FORM BESTIMMUNGSGRENZEN TABLES P_RESULTS STRUCTURE QETBCELLS.

  DATA: L_TEXT            TYPE CHAR1024.
  DATA: L_OUTPUT_FORM(60) TYPE C.

  LOOP AT P_RESULTS WHERE REF_FIELD CS 'MEAN_VALUE'.

*   Nur eingabebereite Felder
    CHECK NOT P_RESULTS-INPUT_ALLOWED IS INITIAL.
    CHECK NOT P_RESULTS-INPUT_FLG     IS INITIAL.

*   zugehörige Aufbereitungsfunktion aufrufen
    CLEAR L_TEXT.
    CONCATENATE 'CLASS_' P_RESULTS-FIELD_TYPE '_OUTPUT'
                INTO L_OUTPUT_FORM.
    PERFORM (L_OUTPUT_FORM) IN PROGRAM (SY-REPID)
       CHANGING P_RESULTS L_TEXT.

*   Ikonen entfernen
    SHIFT L_TEXT UP TO '@'.
    IF SY-SUBRC IS INITIAL.
      SHIFT L_TEXT LEFT BY 1 PLACES.
      SHIFT L_TEXT UP TO '@'.
      SHIFT L_TEXT LEFT BY 1 PLACES.
    ENDIF.

*   Nur weiter, wenn noch kein Wert enthalten ist
    CONDENSE L_TEXT.
    CHECK L_TEXT IS INITIAL OR L_TEXT = '!'.

*   Bestimmungsgrenze ermitteln
    DATA: L_BG(40) TYPE  C.
    DATA: L_REQUIREMENTS TYPE BAPI2045D1.
    DATA: LS_DUMMY40     TYPE YQM_DUMMY40.

    CALL FUNCTION 'QET4_SYNCHRONIZE_DATA'
      EXPORTING
        I_CELLS             = P_RESULTS
      IMPORTING
        E_CHAR_REQUIREMENTS = L_REQUIREMENTS.

    MOVE L_REQUIREMENTS-INFOFIELD3 TO LS_DUMMY40.           "CF20250603

*   Nur mit BG auffüllen, wenn es im Stammprüfmerkmal nicht unterbunden wurde
    CHECK LS_DUMMY40-NBG IS INITIAL.                        "CF20250603

    PERFORM GET_BESTIMMUNGSGRENZE USING L_REQUIREMENTS CHANGING L_BG.
    CHECK NOT L_BG IS INITIAL.

*   Bestimmungsgrenze als Ergebnis wegschreiben
    L_TEXT = L_BG.
    CALL FUNCTION 'QET4_SET_CHAR_RESULTS'
      EXPORTING
        I_VALUE = L_TEXT
        I_CELLS = P_RESULTS
      TABLES
        T_CELLS = P_RESULTS.

  ENDLOOP.

ENDFORM.                    " BESTIMMUNGSGRENZEN
*&---------------------------------------------------------------------*
*&      Form  get_bestimmungsgrenze
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_REQUIREMENTS  Merkmalsvorgaben
*      <--P_BG            Bestimmungsgrenze
*----------------------------------------------------------------------*
FORM GET_BESTIMMUNGSGRENZE USING    P_REQUIREMENTS LIKE BAPI2045D1
                           CHANGING P_BG TYPE C.

  CLEAR P_BG.

* Bestimmungsgrenze ist abgelegt in 1. unterer Grenze
  IF  NOT P_REQUIREMENTS-LW_LMT_1 IS INITIAL.
    IF P_REQUIREMENTS-LW_LMT_1 CN ' 0'.
      CONCATENATE '< ' P_REQUIREMENTS-LW_LMT_1 INTO P_BG.
    ELSE.
      P_BG = P_REQUIREMENTS-LW_LMT_1.
    ENDIF.
  ENDIF.

  CONDENSE P_BG.

ENDFORM.                    " get_bestimmungsgrenze
*&---------------------------------------------------------------------*
*&      Form  vorgaben
*&---------------------------------------------------------------------*
*       Vorgaben ein- bzw. ausschalten
*----------------------------------------------------------------------*
*      -->P_RESULTS  Feldkatalog
*----------------------------------------------------------------------*
FORM VORGABEN TABLES P_RESULTS STRUCTURE QETBCELLS.

  IF GV_VORGABEN = 'X'.
    CLEAR GV_VORGABEN.
  ELSE.
    GV_VORGABEN = 'X'.
  ENDIF.
  SET PARAMETER ID 'YQMLIMS_VORGABEN' FIELD GV_VORGABEN.
  PERFORM START_OF_PROGRAM IN PROGRAM SAPLYQMLIMS_QET5.

ENDFORM.                    " vorgaben

*&---------------------------------------------------------------------*
*&      Form  SAVE_SETTINGS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM SAVE_SETTINGS.

  TYPES: BEGIN OF USTYP_PARAMETERS.
           INCLUDE    STRUCTURE USPARAM.
  TYPES:     END OF USTYP_PARAMETERS.
  TYPES: USTYP_T_PARAMETERS TYPE USTYP_PARAMETERS     OCCURS 30.

  DATA: L_USER_PARAMETERS TYPE USTYP_T_PARAMETERS.
  DATA: L_PARAMETERS      LIKE LINE OF L_USER_PARAMETERS.
  DATA: L_STR_EXT         TYPE XUVALUE.
  DATA: L_SAVE_PARAM      TYPE C.

* Sperren User für Benutzerparameter
  CALL FUNCTION 'ENQUEUE_E_USR04'
    EXPORTING
      BNAME          = SY-UNAME                          "#EC DOM_EQUAL
    EXCEPTIONS
      FOREIGN_LOCK   = 1
      SYSTEM_FAILURE = 2
      OTHERS         = 3.
  IF SY-SUBRC <> 0.
    MESSAGE ID SY-MSGID TYPE 'S' NUMBER SY-MSGNO
            WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

* Lesen Benutzerparameter aus Puffer
  CALL FUNCTION 'SUSR_USER_PARAMETERS_GET'
    EXPORTING
      USER_NAME       = SY-UNAME                         "#EC DOM_EQUAL
    TABLES
      USER_PARAMETERS = L_USER_PARAMETERS.

  CLEAR L_PARAMETERS.

* Parameter-Id Tabelle transformiert
  PERFORM BENUTZERPARAMETER_TABELLE TABLES L_USER_PARAMETERS
                                     USING 'YQMLIMS_TRANSFORM'
                                           GV_TRANSFORMED
                                  CHANGING L_SAVE_PARAM.

* Parameter-Id Vorgabewerte anzeigen
  PERFORM BENUTZERPARAMETER_TABELLE TABLES L_USER_PARAMETERS
                                     USING 'YQMLIMS_VORGABEN'
                                           GV_VORGABEN
                                  CHANGING L_SAVE_PARAM.

* Parameter-Id Tabelle transformiert
  PERFORM BENUTZERPARAMETER_TABELLE TABLES L_USER_PARAMETERS
                                     USING 'YQMLIMS_VORWERTE'
                                           GV_TRANSFORMED
                                  CHANGING L_SAVE_PARAM.

  IF NOT L_SAVE_PARAM IS INITIAL.
*----------------------------------------------------------------------
* Benutzerparameter sichern
*----------------------------------------------------------------------
* Füllen Benutzerparameter in Puffer
    CALL FUNCTION 'SUSR_USER_PARAMETERS_PUT'
      EXPORTING
        USER_NAME       = SY-UNAME                       "#EC DOM_EQUAL
      TABLES
        USER_PARAMETERS = L_USER_PARAMETERS.

*  Puffer auf die DB schreiben
    CALL FUNCTION 'SUSR_USER_BUFFERS_TO_DB'
      EXCEPTIONS
        NO_LOGONDATA_FOR_NEW_USER = 1
        NO_INIT_PASSWORD          = 2
        DB_INSERT_USR02_FAILED    = 3
        DB_UPDATE_USR02_FAILED    = 4
        DB_INSERT_USR01_FAILED    = 5
        DB_UPDATE_USR01_FAILED    = 6
        DB_INSERT_USR05_FAILED    = 7
        DB_UPDATE_USR05_FAILED    = 8
        DB_INSERT_USR21_FAILED    = 9
        DB_UPDATE_USR21_FAILED    = 10
        INTERNAL_ERROR            = 11
        OTHERS                    = 12.

    IF SY-SUBRC <> 0.
      MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
              WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
    ENDIF.

* Ent-Sperren User für Benutzerparameter
    CALL FUNCTION 'DEQUEUE_E_USR04'
      EXPORTING
        BNAME = SY-UNAME.                                "#EC DOM_EQUAL

  ENDIF.

ENDFORM.                    "save_settings

*&---------------------------------------------------------------------*
*&      Form  BENUTZERPARAMETER_TABELLE
*&---------------------------------------------------------------------*
*       Tabelle der Benutzerparameter wird aktualisiert
*----------------------------------------------------------------------*
*      <->PARAMETERTAB   Tabelle mit den Benutzerparametern
*      -->P_PARAMETERID  Parameter-Id
*      -->P_VALUE        Parameterwert
*      <->P_SAVE_PARM    Benutzerparameter sichern
*----------------------------------------------------------------------*
FORM BENUTZERPARAMETER_TABELLE TABLES   PARAMETERTAB STRUCTURE USPARAM
                               USING    VALUE(P_PARAMETERID)
                                        P_VALUE
                            CHANGING    P_SAVE_PARAM TYPE C.

  DATA: L_PARAMETERS      LIKE LINE OF PARAMETERTAB.

  CLEAR L_PARAMETERS.

  L_PARAMETERS-PARID = P_PARAMETERID.
  L_PARAMETERS-PARVA = P_VALUE.

  READ TABLE PARAMETERTAB WITH KEY PARID = L_PARAMETERS-PARID
                                   TRANSPORTING PARVA.
  IF SY-SUBRC = 0.
    IF L_PARAMETERS-PARVA = '*'.       "Parameter löschen, Vorgabe zieht
* Parameter aber noch setzen, da Gedächtnis nicht zurückgesetzt wird.
      SET PARAMETER ID L_PARAMETERS-PARID  FIELD L_PARAMETERS-PARVA.
      DELETE PARAMETERTAB INDEX SY-TABIX.
      P_SAVE_PARAM = 'X'.
* Beim Abmelden ist der Parameter dann weg
    ELSE.
      IF P_VALUE NE PARAMETERTAB-PARVA.
        MODIFY PARAMETERTAB FROM L_PARAMETERS INDEX SY-TABIX.
        P_SAVE_PARAM = 'X'.
      ENDIF.
    ENDIF.
  ELSE.
    IF L_PARAMETERS-PARVA = '*'.       "Parameter löschen, Vorgabe zieht
* Nichts tun
    ELSE.
      APPEND L_PARAMETERS TO PARAMETERTAB.
      P_SAVE_PARAM = 'X'.
    ENDIF.
  ENDIF.

ENDFORM.                               " BENUTZERPARAMETER_TABELLE
*&---------------------------------------------------------------------*
*&      Form  next_char
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM NEXT_CHAR.

  FIELD-SYMBOLS: <FIELD>.
  FIELD-SYMBOLS: <LINE>.
  FIELD-SYMBOLS: <RESULTS>.

  DATA: L_CURSORFIELD(20).
  DATA: L_LINO(2)             TYPE C.
  DATA: L_LINE                LIKE SY-LILLI.
  DATA: L_CURSOR_FIELD LIKE SY-TNAME,
        L_CURSOR_LINE  LIKE SY-STEPL,
        L_CURSOR_AREA  LIKE SY-TNAME,
        TABLE_NAME(40) TYPE C.
  DATA: L_RESULTS             LIKE QETBCELLS OCCURS 0 WITH HEADER LINE.

* Zugriff auf Cursorposition
  TABLE_NAME = '(SAPLYQMLIMS_QET5)CURSOR_FIELD'.
  ASSIGN (TABLE_NAME) TO <FIELD>.
  L_CURSOR_FIELD = <FIELD>.

  TABLE_NAME = '(SAPLYQMLIMS_QET5)CURSOR_LINE'.
  ASSIGN (TABLE_NAME) TO <LINE>.
  L_CURSOR_LINE = <LINE>.

  TABLE_NAME = '(SAPLYQMLIMS_QET5)G_RESULTS[]'.
  ASSIGN (TABLE_NAME) TO <RESULTS>.
  L_RESULTS[] = <RESULTS>.

  L_LINO = L_CURSOR_FIELD+14(2).
  L_LINO = L_LINO + 1.

  IF L_LINO < 10.
    L_CURSOR_FIELD+15(1) = L_LINO.
  ELSE.
    L_CURSOR_FIELD+14(2) = L_LINO.
  ENDIF.

* ..die erste freie Zelle der neuen Spalte wird bestimmt...
  SORT L_RESULTS BY COL_NO ROW_NO.

  LOOP AT L_RESULTS WHERE COL_NO     = L_LINO
                    AND   FIELD_TYPE = 'VALUE'
                    AND   INPUT_FLG  = 'X'.
    L_CURSOR_LINE = L_RESULTS-ROW_NO.
    EXIT.
  ENDLOOP.

* ... und die Corsurposition zurückgeschrieben...
  <FIELD> = L_CURSOR_FIELD.
  <LINE>  = L_CURSOR_LINE.

ENDFORM.                    " next_char

*&---------------------------------------------------------------------*
*&      Form  GET_ROW_NO
*&---------------------------------------------------------------------*
*       Liefert die Zeilennummer für einen Prüfpunkt.
*----------------------------------------------------------------------*
*      -->P_INSP_POINT  Prüfpunktdaten
*      <--P_ROW_NO      Zeilennummer
*----------------------------------------------------------------------*
FORM GET_ROW_NO USING    P_INSP_POINT TYPE BAPI2045L4
                CHANGING P_ROW_NO     TYPE SYLINNO.

  DATA: L_SORTKEY LIKE QAPP-PPSORTKEY.

  READ TABLE G_ROWS WITH KEY
        INSPLOT    = P_INSP_POINT-INSPLOT
        INSPSAMPLE = P_INSP_POINT-INSPPOINT
        INFO       = P_INSP_POINT-PHYS_SMPL.
  P_ROW_NO = G_ROWS-ROW_NO.

ENDFORM.                    " GET_ROW_NO

*&---------------------------------------------------------------------*
*&      Form  set_column_title
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_G_RESULTS  text
*      -->P_G_TITLE_R  text
*----------------------------------------------------------------------*
FORM SET_COLUMN_TITLE TABLES   P_RESULTS STRUCTURE QETBCELLS
                               P_TITLE_R STRUCTURE QETBCELLS .

  REFRESH  P_TITLE_R.

  LOOP AT P_RESULTS WHERE ROW_NO = 3.
    P_TITLE_R = P_RESULTS.
    APPEND P_TITLE_R.
  ENDLOOP.

ENDFORM.                    " set_column_title

*---------------------------------------------------------------------*
*       FORM CLASS_VALUE_SHOW_OUTPUT*
*---------------------------------------------------------------------*
*       Standard class for referenced fields of a sample.
*       Parameter P_CELLS contains the reference to the data. The
*       form writes the data in parameter P_VALUE.

*       This form sets the INPUT_FLG of P_CELLS if input is allowed
*       for a field depending on status of sample.

*       The form uses icons to signalize the evaluation of a sample.
*---------------------------------------------------------------------*
*  -->  P_CELLS  description of field to output
*  -->  P_VALUE  resulting value
*---------------------------------------------------------------------*
FORM CLASS_VALUE_SHOW_OUTPUT CHANGING P_CELLS LIKE QETBCELLS
                                 P_VALUE TYPE ANY.

  DATA: TABLE_NAME(40) TYPE C.
  DATA: FIELD_NAME(40) TYPE C.
  DATA: L_INFO         TYPE ICONQUICK.
  DATA: L_TEXT         TYPE QCODETEXT.
  FIELD-SYMBOLS: <TABLE>, <FIELD>.
  FIELD-SYMBOLS: <ATTRIBUT>.

  DATA: L_STELLEN        LIKE QAMV-STELLEN.
  DATA: L_VORGLFNR       LIKE QAPO-VORGLFNR.
  DATA: L_CHAR_FIELD     LIKE CHA_CLASS_VIEW-SOLLWERT.
  DATA: L_QASR           LIKE QASR.
  DATA: L_QAMV           LIKE QAMV.
  DATA: L_ICON           TYPE ICON_TEXT.

* read toolbox data for cell
  CALL FUNCTION 'QET4_SYNCHRONIZE_DATA'
    EXPORTING
      I_CELLS                   = P_CELLS
    IMPORTING
      E_CHAR_REQUIREMENTS       = G_REQUIREMENTS
      E_SAMPLE_RESULT           = G_SAMPLE_RESULTS
      E_CHAR_RESULT             = G_CHAR_RESULTS
      E_INSP_POINT              = G_INSP_POINTS
      E_INSP_POINT_REQUIREMENTS = G_IP_REQUIREMENTS
      E_INSP_LOT                = G_INSP_LOTS
      E_LOCKED                  = G_LOCKED
      E_DURING_POSTING          = G_DURING_POSTING.

  CALL FUNCTION 'QIBP_GET_VORGLFNR'
    EXPORTING
      I_INSP_LOT = G_REQUIREMENTS-INSPLOT
      I_OPER_NO  = G_REQUIREMENTS-INSPOPER
    IMPORTING
      E_VORGLFNR = L_VORGLFNR.

  MOVE P_CELLS-REF_FIELD TO G_INSP_POINTS-INSPPOINT.

  SELECT SINGLE * FROM QAMV INTO L_QAMV
   WHERE PRUEFLOS = G_REQUIREMENTS-INSPLOT
     AND VORGLFNR = L_VORGLFNR
     AND MERKNR   = G_REQUIREMENTS-INSPCHAR.

  SELECT SINGLE * FROM QASR INTO L_QASR
         WHERE  PRUEFLOS  = G_REQUIREMENTS-INSPLOT
         AND    VORGLFNR  = L_VORGLFNR
         AND    MERKNR    = G_REQUIREMENTS-INSPCHAR
         AND    PROBENR   = G_INSP_POINTS-INSPPOINT.
  IF SY-SUBRC = 0.

* Handelt es sich um eine qauntitatives oder qualitatives Merkmal
    IF L_QAMV-STEUERKZ(1) EQ 'X'.
*    ...quantitativ
      CATCH SYSTEM-EXCEPTIONS CONVT_OVERFLOW = 1.
        L_STELLEN = L_QAMV-STELLEN + L_QASR-DIFF_DEC_PLACES.
      ENDCATCH.

      IF SY-SUBRC = 1.
        L_STELLEN = 0.
      ENDIF.

      CALL FUNCTION 'QSS0_FLTP_TO_CHAR_CONVERSION'
        EXPORTING
          I_NUMBER_OF_DIGITS       = L_STELLEN
          I_FLTP_VALUE             = L_QASR-MITTELWERT
          I_VALUE_NOT_INITIAL_FLAG = L_QASR-MITTELWNI
        IMPORTING
          E_CHAR_FIELD             = L_CHAR_FIELD.

      P_VALUE = L_CHAR_FIELD.

      SHIFT P_VALUE LEFT DELETING LEADING SPACE.
      IF NOT L_QASR-ATTRIBUT IS INITIAL.
        CONCATENATE L_QASR-ATTRIBUT P_VALUE INTO P_VALUE.
      ENDIF.

    ELSE.
*    ...qualitativ
      IF NOT L_QASR-CODE1 IS INITIAL.
        CALL FUNCTION 'QPK1_CODE_TEXT'
          EXPORTING
            I_KATALOGART      = L_QASR-KATALGART1
            I_CODEGRUPPE      = L_QASR-GRUPPE1
            I_CODE            = L_QASR-CODE1
          IMPORTING
            E_TEXT            = L_TEXT
          EXCEPTIONS
            NO_MATCH_IN_RANGE = 1
            OTHERS            = 2.
        IF SY-SUBRC <> 0.
          CLEAR L_TEXT.
        ELSE.
          CONCATENATE L_QASR-CODE1 L_TEXT INTO P_VALUE SEPARATED BY ' '.

        ENDIF.
      ENDIF.
    ENDIF.

    IF     L_QASR-MBEWERTG = 'A'.
      L_ICON = ICON_CHECKED.
*      l_info = text-900.
    ELSEIF L_QASR-MBEWERTG = 'R'.
      L_ICON = ICON_INCOMPLETE.
*      l_info = text-900.
    ELSEIF L_QASR-MBEWERTG = 'F'.
      L_ICON = ICON_FAILURE.
*      l_info = text-900.
    ELSE.
      CLEAR L_ICON.
      CLEAR L_INFO.
    ENDIF.

    IF NOT L_ICON IS INITIAL.
      CALL FUNCTION 'ICON_CREATE'
        EXPORTING
          NAME   = L_ICON
          TEXT   = P_VALUE
          INFO   = L_INFO
*         ADD_STDINF            = 'X'
        IMPORTING
          RESULT = P_VALUE.
    ENDIF.

  ELSE.
    CLEAR P_VALUE.
  ENDIF.


ENDFORM.                    "class_value_show_output
*---------------------------------------------------------------------*
*       FORM CLASS_COL_TITLE_OUTPUT                                   *
*---------------------------------------------------------------------*
*       Like class VALUE2, but no input possible.
*---------------------------------------------------------------------*
FORM CLASS_VALUE2_OUTPUT CHANGING P_CELLS LIKE QETBCELLS
                                  P_VALUE TYPE ANY.

  DATA: TABLE_NAME(40) TYPE C.
  DATA: FIELD_NAME(40) TYPE C.
  DATA: L_INFO         TYPE ICONQUICK.
  FIELD-SYMBOLS: <TABLE>, <FIELD>.
  FIELD-SYMBOLS: <ATTRIBUT>.
  DATA: L_ISSKIP       TYPE XFELD.
  DATA: L_ISDIRTY      TYPE XFELD.
  DATA: L_ISBLOCKED    TYPE XFELD.

* read toolbox data for cell
  CALL FUNCTION 'QET4_SYNCHRONIZE_DATA'
    EXPORTING
      I_CELLS                   = P_CELLS
    IMPORTING
      E_CHAR_REQUIREMENTS       = G_REQUIREMENTS
      E_SAMPLE_RESULT           = G_SAMPLE_RESULTS
      E_CHAR_RESULT             = G_CHAR_RESULTS
      E_INSP_POINT              = G_INSP_POINTS
      E_INSP_POINT_REQUIREMENTS = G_IP_REQUIREMENTS
      E_INSP_LOT                = G_INSP_LOTS
      E_LOCKED                  = G_LOCKED
      E_DURING_POSTING          = G_DURING_POSTING
      E_ISSKIP                  = L_ISSKIP
      E_ISDIRTY                 = L_ISDIRTY
      E_ISBLOCKED               = L_ISBLOCKED.

* connect to referenced field
  CHECK NOT P_CELLS-REF_FIELD IS INITIAL.
  SPLIT P_CELLS-REF_FIELD AT '-' INTO TABLE_NAME FIELD_NAME.
  ASSIGN (TABLE_NAME) TO <TABLE>.
  ASSIGN COMPONENT FIELD_NAME OF STRUCTURE <TABLE> TO <FIELD>.
  IF TABLE_NAME = 'G_CHAR_RESULTS'.
    ASSIGN COMPONENT 'CHAR_ATTR' OF STRUCTURE <TABLE> TO <ATTRIBUT>.
  ENDIF.
  IF TABLE_NAME = 'G_SAMPLE_RESULTS'.
    ASSIGN COMPONENT 'SMPL_ATTR' OF STRUCTURE <TABLE> TO <ATTRIBUT>.
  ENDIF.

* output to P_VALUE
  WRITE: <FIELD> TO P_VALUE.
  SHIFT P_VALUE LEFT DELETING LEADING SPACE.
  IF P_VALUE = '!'.
    CLEAR P_VALUE.
  ENDIF.

  IF FIELD_NAME = 'MEAN_VALUE' OR FIELD_NAME = 'NONCONF'
     OR FIELD_NAME = 'DEFECTS'.
    IF <ATTRIBUT> <> '!'.

      CASE <ATTRIBUT>.
        WHEN '('.
          MOVE 'n.g.'              TO P_VALUE.
        WHEN '['.
          MOVE 'k.A.'              TO P_VALUE.
        WHEN '~'.
          MOVE 'n.n.'              TO P_VALUE.
        WHEN '{'.
          MOVE 's.B.'              TO P_VALUE.
        WHEN 'U'.
          MOVE 'n.a.'              TO P_VALUE.
        WHEN 'V'.
          MOVE 'n.b.'              TO P_VALUE.
        WHEN OTHERS.
          CONCATENATE <ATTRIBUT> P_VALUE INTO P_VALUE.
      ENDCASE.

    ENDIF.
  ENDIF.

* status
  IF NOT L_ISBLOCKED IS INITIAL.
    CLEAR P_CELLS-INPUT_FIELD.
  ENDIF.

* input field?
  PERFORM IS_INPUT_ALLOWED
      USING      G_REQUIREMENTS
                 G_CHAR_RESULTS
                 G_SAMPLE_RESULTS
      CHANGING   P_CELLS.

  P_CELLS-INPUT_FLG = C_SET.
  IF P_CELLS-INPUT_ALLOWED IS INITIAL.
    CLEAR P_CELLS-INPUT_FLG.
  ENDIF.

* Formula char
  IF NOT G_REQUIREMENTS-FORMULA IS INITIAL.
    CLEAR P_CELLS-INPUT_FLG.
  ENDIF.

* clear input property for evaluated or closed samples
  IF     NOT G_REQUIREMENTS-CHAR_RES IS INITIAL
     AND NOT G_CHAR_RESULTS-EVALUATED IS INITIAL.
    CLEAR P_CELLS-INPUT_FLG.
  ENDIF.

* clear input property for evaluated or closed characteristics
  IF   NOT G_REQUIREMENTS-SAMPLE_RES  IS INITIAL
   AND NOT G_SAMPLE_RESULTS-EVALUATED IS INITIAL.
    CLEAR P_CELLS-INPUT_FLG.
  ENDIF.

* Characteristic without recording
  IF NOT G_REQUIREMENTS-NO_RECORDING IS INITIAL.
    CLEAR P_CELLS-INPUT_FLG.
  ENDIF.

* locked entries are always output fields
  IF  NOT G_LOCKED IS INITIAL
   OR NOT G_DURING_POSTING IS INITIAL.
    CLEAR P_CELLS-INPUT_FLG.
  ENDIF.

* skip chars
  IF NOT L_ISSKIP IS INITIAL.

    IF P_VALUE IS INITIAL AND L_ISDIRTY IS INITIAL.
      CLEAR P_CELLS-INPUT_FLG.
      P_VALUE = TEXT-075.
    ENDIF.

  ENDIF.

  PERFORM CREATE_ICON
      USING    P_CELLS
               G_LOCKED
               G_DURING_POSTING
      CHANGING P_VALUE.

  IF  ( P_VALUE IS INITIAL OR P_VALUE CS TEXT-075 )
   AND P_CELLS-INPUT_ALLOWED IS INITIAL
   AND  ( P_CELLS-REF_FIELD   CS 'MEAN_VALUE'
         OR P_CELLS-REF_FIELD CS 'DEFECTS'
         OR P_CELLS-REF_FIELD CS 'NONCONF' ).
    L_INFO = 'Pflege mit Ergebniserfassung'(850).

    CALL FUNCTION 'ICON_CREATE'
      EXPORTING
        NAME   = ICON_DETAIL
        TEXT   = P_VALUE
        INFO   = L_INFO
*       ADD_STDINF            = 'X'
      IMPORTING
        RESULT = P_VALUE.
  ENDIF.

ENDFORM.                    "CLASS_VALUE2_OUTPUT

*---------------------------------------------------------------------*
*       FORM CLASS_VALUE_SHOW_INPUT*
*---------------------------------------------------------------------*
*       Input for for the class VALUE_SHOW
*---------------------------------------------------------------------*
*  -->  T_CELLS
*  -->  I_CELLS
*  -->  I_VALUE
*---------------------------------------------------------------------*
FORM CLASS_VALUE_SHOW_INPUT TABLES T_CELLS STRUCTURE QETBCELLS
                            USING  I_CELLS LIKE QETBCELLS
                                   I_VALUE TYPE ANY.


ENDFORM.                    "class_value_show_input
*---------------------------------------------------------------------*
*       FORM CLASS_VALUE_INPUT                                        *
*---------------------------------------------------------------------*
*       Input for for the class VALUE2
*---------------------------------------------------------------------*
*  -->  T_CELLS
*  -->  I_CELLS
*  -->  I_VALUE
*---------------------------------------------------------------------*
FORM CLASS_VALUE2_INPUT TABLES T_CELLS STRUCTURE QETBCELLS
                        USING  I_CELLS LIKE QETBCELLS
                               I_VALUE TYPE ANY.

  DATA: LV_OBJNR         TYPE J_OBJNR.
  DATA: LV_STATUS        TYPE J_STATUS.
  DATA: L_MESSWERT       LIKE QAQEE-MESSWERT.
  DATA: L_ATTRIBUT       LIKE QASER-ATTRIBUT.
  DATA: LS_QAMV          LIKE QAMV.
  DATA: LS_REQUIREMENTS  LIKE BAPI2045D1.
  DATA: L_BG(40)         TYPE C.
  DATA: L_CHAR_VALUE     LIKE QFLTP-SOLLWERT.
  DATA: L_ORIGINAL_INPUT TYPE QORIGINAL_INPUT.
  DATA: L_FLTP_VALUE     LIKE CHA_CLASS_DATA-SOLLWERT.
  DATA: L_CHAR_PLAUSI    LIKE CHA_CLASS_VIEW-SOLLWERT.
  DATA: L_UNIT           TYPE TEXT32.

  IF     I_VALUE CS 'n.g.'.
    REPLACE 'n.g.'               IN I_VALUE WITH '('.
  ELSEIF I_VALUE CS 'k.A.'.
    REPLACE 'k.A.'               IN I_VALUE WITH '['.
  ELSEIF I_VALUE CS 'n.n.'.
    REPLACE 'n.n.'               IN I_VALUE WITH '~'.
  ELSEIF I_VALUE CS 'ng'.
    REPLACE 'ng'                 IN I_VALUE WITH '('.
  ELSEIF I_VALUE CS 'NG'.
    REPLACE 'NG'                 IN I_VALUE WITH '('.
  ELSEIF I_VALUE CS 'nn'.
    REPLACE 'nn'                 IN I_VALUE WITH '~'.
  ELSEIF I_VALUE CS 'NN'.
    REPLACE 'NN'                 IN I_VALUE WITH '~'.
  ELSEIF I_VALUE CS 'ka'.
    REPLACE 'ka'                 IN I_VALUE WITH '['.
  ELSEIF I_VALUE CS 'kA'.
    REPLACE 'kA'                 IN I_VALUE WITH '['.
  ELSEIF I_VALUE CS 'KA'.
    REPLACE 'KA'                 IN I_VALUE WITH '['.
  ELSEIF I_VALUE CS 'sb'.
    REPLACE 'sb'                 IN I_VALUE WITH '{'.
  ELSEIF I_VALUE CS 'SB'.
    REPLACE 'SB'                 IN I_VALUE WITH '{'.
  ELSEIF I_VALUE CS 'sB'.
    REPLACE 'sB'                 IN I_VALUE WITH '{'.
  ELSEIF I_VALUE CS 's.B.'.
    REPLACE 's.B.'               IN I_VALUE WITH '{'.
  ELSEIF I_VALUE CS 'n.a.'.
    REPLACE 'n.a.'               IN I_VALUE WITH 'U'.
  ELSEIF I_VALUE CS 'na'.
    REPLACE 'na'                 IN I_VALUE WITH 'U'.
  ELSEIF I_VALUE CS 'nA'.
    REPLACE 'nA'                 IN I_VALUE WITH 'U'.
  ELSEIF I_VALUE CS 'NA'.
    REPLACE 'NA'                 IN I_VALUE WITH 'U'.
  ELSEIF I_VALUE CS 'Na'.
    REPLACE 'Na'                 IN I_VALUE WITH 'V'.
  ELSEIF I_VALUE CS 'n.b.'.
    REPLACE 'n.b.'               IN I_VALUE WITH 'V'.
  ELSEIF I_VALUE CS 'nb'.
    REPLACE 'nb'                 IN I_VALUE WITH 'V'.
  ELSEIF I_VALUE CS 'nB'.
    REPLACE 'nB'                 IN I_VALUE WITH 'V'.
  ELSEIF I_VALUE CS 'NB'.
    REPLACE 'NB'                 IN I_VALUE WITH 'V'.
  ELSEIF I_VALUE CS 'Nb'.
    REPLACE 'Nb'                 IN I_VALUE WITH 'V'.
  ENDIF.

  CALL FUNCTION 'QET4_GET_CHAR_REQUIREMENTS'
    EXPORTING
      I_INSPLOT      = T_CELLS-INSPLOT
      I_INSPOPER     = T_CELLS-INSPOPER
      I_INSPCHAR     = T_CELLS-INSPCHAR
    IMPORTING
      E_REQUIREMENTS = LS_REQUIREMENTS
      E_QAMV         = LS_QAMV
    EXCEPTIONS
      NOT_FOUND      = 1
      OTHERS         = 2.
  IF SY-SUBRC = 0.

* Meßwert und Attribut trennen (Eingabe <0.75)
    L_MESSWERT = I_VALUE.

    PERFORM MESSWERT_ATTRIBUT_TRENNEN(SAPLQEEM)
            CHANGING L_MESSWERT
                     L_ATTRIBUT.

    L_CHAR_VALUE = L_MESSWERT.

    CASE L_ATTRIBUT.
      WHEN '<'.
        IF NOT L_CHAR_VALUE IS INITIAL.
          CALL FUNCTION 'QSS0_CHAR_FLTP_CONVERSION'
            EXPORTING
*             I_CHAR_FIELD_NAME  = ' '
              I_CHARACTER_STRING = L_CHAR_VALUE
              I_NUMBER_OF_DIGITS = LS_QAMV-STELLEN
            IMPORTING
*             E_VALUE_NOT_INITIAL_FLAG       =
              E_FLTP_VALUE       = L_FLTP_VALUE.

* Überprüfung Bestimmungsgrenze
          CALL FUNCTION 'QEST_TOLERANCE_INSPECTION'
            EXPORTING
              AKTF            = L_FLTP_VALUE
              KZO             = LS_QAMV-TOLOBNI
              KZU             = LS_QAMV-TOLUNNI
              OGWF            = LS_QAMV-TOLERANZOB
              STELLEN         = LS_QAMV-STELLEN
              UGWF            = LS_QAMV-TOLERANZUN
            EXCEPTIONS
              AKTF_HIGHER_OGW = 02
              AKTF_LOWER_UGW  = 01.
          IF SY-SUBRC <> 0.
            IF SY-SUBRC = 1.
              MESSAGE I406(YQMLIMS).
            ELSEIF SY-SUBRC = 2.
              MESSAGE I407(YQMLIMS).
            ENDIF.
          ENDIF.
          CONCATENATE L_ATTRIBUT L_CHAR_VALUE INTO I_VALUE.
        ELSE.
          SHIFT LS_REQUIREMENTS-LW_LMT_1 LEFT DELETING LEADING SPACE.
          L_CHAR_VALUE = LS_REQUIREMENTS-LW_LMT_1.

          CALL FUNCTION 'QSS0_CHAR_FLTP_CONVERSION'
            EXPORTING
*             I_CHAR_FIELD_NAME  = ' '
              I_CHARACTER_STRING = L_CHAR_VALUE
              I_NUMBER_OF_DIGITS = LS_QAMV-STELLEN
            IMPORTING
*             E_VALUE_NOT_INITIAL_FLAG       =
              E_FLTP_VALUE       = L_FLTP_VALUE.

          CONCATENATE L_ATTRIBUT L_CHAR_VALUE INTO I_VALUE.
        ENDIF.

      WHEN 'U'.
* Gmelch 30.6.15 bei U direkt Wert auf -1000 setzen
        DATA: DF16  TYPE DECFLOAT16,
              C6(6).
* Gme 30.6.17 bei U jetzt auf 99999 setzen
*       df16 = '1000-'.
        DF16 = '99999'.
        I_VALUE(1) = 'U'.
        I_VALUE+1(8) = DF16.  "  2D312E303030202020...

      WHEN '('
        OR '['
        OR '~'
        OR '{'
        OR 'V'.
* Gmelch 30.6.15 bei U direkt Wert auf 0 setzen
*        or 'U'.
* Wenn ein Messwert mitgegeben wurde, erfolgt die Verprobung gegen die Bestimmungsgrenze
        IF NOT L_CHAR_VALUE IS INITIAL.
          CALL FUNCTION 'QSS0_CHAR_FLTP_CONVERSION'
            EXPORTING
*             I_CHAR_FIELD_NAME  = ' '
              I_CHARACTER_STRING = L_CHAR_VALUE
              I_NUMBER_OF_DIGITS = LS_QAMV-STELLEN
            IMPORTING
*             E_VALUE_NOT_INITIAL_FLAG       =
              E_FLTP_VALUE       = L_FLTP_VALUE.

* Überprüfung Bestimmungsgrenze
          CALL FUNCTION 'QEST_TOLERANCE_INSPECTION'
            EXPORTING
              AKTF            = L_FLTP_VALUE
              KZO             = LS_QAMV-TOLOBNI
              KZU             = LS_QAMV-TOLUNNI
              OGWF            = LS_QAMV-TOLERANZOB
              STELLEN         = LS_QAMV-STELLEN
              UGWF            = LS_QAMV-TOLERANZUN
            EXCEPTIONS
              AKTF_HIGHER_OGW = 02
              AKTF_LOWER_UGW  = 01.
          IF SY-SUBRC <> 0.
            IF SY-SUBRC = 1.
              MESSAGE I406(YQMLIMS).
            ELSEIF SY-SUBRC = 2.
              MESSAGE I407(YQMLIMS).
            ENDIF.
          ENDIF.
        ELSE.
* ... ansonsten wird der Messwert auf 0 gesetzt.
          CONCATENATE L_ATTRIBUT '0' INTO I_VALUE.
        ENDIF.

      WHEN OTHERS.
        IF NOT L_CHAR_VALUE IS INITIAL.
          CALL FUNCTION 'QSS0_CHAR_FLTP_CONVERSION'
            EXPORTING
*             I_CHAR_FIELD_NAME  = ' '
              I_CHARACTER_STRING = L_CHAR_VALUE
              I_NUMBER_OF_DIGITS = LS_QAMV-STELLEN
            IMPORTING
*             E_VALUE_NOT_INITIAL_FLAG       =
              E_FLTP_VALUE       = L_FLTP_VALUE.

* Überprüfung Bestimmungsgrenze
          CALL FUNCTION 'QEST_TOLERANCE_INSPECTION'
            EXPORTING
              AKTF            = L_FLTP_VALUE
              KZO             = LS_QAMV-TOLOBNI
              KZU             = LS_QAMV-TOLUNNI
              OGWF            = LS_QAMV-TOLERANZOB
              STELLEN         = LS_QAMV-STELLEN
              UGWF            = LS_QAMV-TOLERANZUN
            EXCEPTIONS
              AKTF_HIGHER_OGW = 02
              AKTF_LOWER_UGW  = 01.
          IF SY-SUBRC <> 0.
            IF SY-SUBRC = 1.
              MESSAGE I406(YQMLIMS).
            ELSEIF SY-SUBRC = 2.
              MESSAGE I407(YQMLIMS).
            ENDIF.
          ENDIF.
        ENDIF.

    ENDCASE.

* Überprüfung Plausibilitätsgrenze
    IF  NOT L_CHAR_VALUE IS INITIAL.
      L_ORIGINAL_INPUT = L_CHAR_VALUE.
      CALL FUNCTION 'QEST_TOLERANCE_INSPECTION'
        EXPORTING
          AKTF            = L_FLTP_VALUE
          KZO             = LS_QAMV-PLAUSIOBNI
          KZU             = LS_QAMV-PLAUSIUNNI
          OGWF            = LS_QAMV-PLAUSIOBEN
          STELLEN         = LS_QAMV-STELLEN
          UGWF            = LS_QAMV-PLAUSIUNTE
        EXCEPTIONS
          AKTF_HIGHER_OGW = 02
          AKTF_LOWER_UGW  = 01.
      IF SY-SUBRC <> 0.

        IF SY-SUBRC = 1.
*          CONCATENATE 'V' l_char_value INTO i_value.
*          MESSAGE i404(yqmlims).

          CALL FUNCTION 'CONVERSION_EXIT_CUNIT_OUTPUT'
            EXPORTING
              INPUT          = LS_QAMV-MASSEINHSW
*             LANGUAGE       = SY-LANGU
            IMPORTING
*             LONG_TEXT      =
*             OUTPUT         =
              SHORT_TEXT     = L_UNIT
            EXCEPTIONS
              UNIT_NOT_FOUND = 1
              OTHERS         = 2.
          IF SY-SUBRC <> 0.
* Implement suitable error handling here
            L_UNIT = LS_QAMV-MASSEINHSW.
          ENDIF.

          CALL FUNCTION 'QSS0_FLTP_TO_CHAR_CONVERSION'
            EXPORTING
              I_NUMBER_OF_DIGITS       = LS_QAMV-STELLEN
              I_FLTP_VALUE             = LS_QAMV-PLAUSIUNTE
              I_VALUE_NOT_INITIAL_FLAG = LS_QAMV-PLAUSIUNNI
            IMPORTING
              E_CHAR_FIELD             = L_CHAR_PLAUSI.

          SHIFT L_CHAR_PLAUSI LEFT DELETING LEADING SPACE.

          MESSAGE I404(YQMLIMS) WITH LS_QAMV-KURZTEXT
                                     L_CHAR_VALUE
                                     L_CHAR_PLAUSI
                                     L_UNIT.

          CALL FUNCTION 'Y_QMLIMS_QET5_QASR_COLLECT'
            EXPORTING
              IV_PRUEFLOS       = LS_QAMV-PRUEFLOS
              IV_VORGLFNR       = LS_QAMV-VORGLFNR
              IV_MERKNR         = LS_QAMV-MERKNR
              IV_PROBENR        = T_CELLS-INSPSAMPLE
              IV_ORIGINAL_INPUT = L_ORIGINAL_INPUT
              IV_SET_FEHLKLAS   = 'X'
            TABLES
              ET_QASR           = UT_QASR.

        ELSEIF SY-SUBRC = 2.
*          CONCATENATE 'V' l_char_value INTO i_value.
*          MESSAGE i405(yqmlims).

          CALL FUNCTION 'CONVERSION_EXIT_CUNIT_OUTPUT'
            EXPORTING
              INPUT          = LS_QAMV-MASSEINHSW
*             LANGUAGE       = SY-LANGU
            IMPORTING
*             LONG_TEXT      =
*             OUTPUT         =
              SHORT_TEXT     = L_UNIT
            EXCEPTIONS
              UNIT_NOT_FOUND = 1
              OTHERS         = 2.
          IF SY-SUBRC <> 0.
* Implement suitable error handling here
            L_UNIT = LS_QAMV-MASSEINHSW.
          ENDIF.

          CALL FUNCTION 'QSS0_FLTP_TO_CHAR_CONVERSION'
            EXPORTING
              I_NUMBER_OF_DIGITS       = LS_QAMV-STELLEN
              I_FLTP_VALUE             = LS_QAMV-PLAUSIOBEN
              I_VALUE_NOT_INITIAL_FLAG = LS_QAMV-PLAUSIOBNI
            IMPORTING
              E_CHAR_FIELD             = L_CHAR_PLAUSI.

          SHIFT L_CHAR_PLAUSI LEFT DELETING LEADING SPACE.

          MESSAGE I405(YQMLIMS) WITH LS_QAMV-KURZTEXT
                                     L_CHAR_VALUE
                                     L_CHAR_PLAUSI
                                     L_UNIT.

          CALL FUNCTION 'Y_QMLIMS_QET5_QASR_COLLECT'
            EXPORTING
              IV_PRUEFLOS       = LS_QAMV-PRUEFLOS
              IV_VORGLFNR       = LS_QAMV-VORGLFNR
              IV_MERKNR         = LS_QAMV-MERKNR
              IV_PROBENR        = T_CELLS-INSPSAMPLE
              IV_ORIGINAL_INPUT = L_ORIGINAL_INPUT
              IV_SET_FEHLKLAS   = 'X'
            TABLES
              ET_QASR           = UT_QASR.

        ENDIF.
      ELSE.
        CALL FUNCTION 'Y_QMLIMS_QET5_QASR_COLLECT'
          EXPORTING
            IV_PRUEFLOS       = LS_QAMV-PRUEFLOS
            IV_VORGLFNR       = LS_QAMV-VORGLFNR
            IV_MERKNR         = LS_QAMV-MERKNR
            IV_ORIGINAL_INPUT = L_ORIGINAL_INPUT
            IV_PROBENR        = T_CELLS-INSPSAMPLE
          TABLES
            ET_QASR           = UT_QASR.
      ENDIF.
    ENDIF.

  ENDIF.

  IF L_ATTRIBUT = '{'.
    CONCATENATE 'QL' LS_QAMV-PRUEFLOS INTO LV_OBJNR.
    CALL FUNCTION 'STATUS_TEXT_CONVERSION'
      EXPORTING
        LANGUAGE           = SY-LANGU
        MODE               = 'E'
        OBJNR              = LV_OBJNR
        TXT04              = 'BEUR'
      IMPORTING
        STATUS_NUMBER      = LV_STATUS
      EXCEPTIONS
        INSUFFICIENT_INPUT = 1
        NOT_FOUND          = 2
        OBJECT_NOT_FOUND   = 3
        WRONG_MODE         = 4
        OTHERS             = 5.
    IF SY-SUBRC = 0.
      CALL FUNCTION 'STATUS_CHANGE_EXTERN'
        EXPORTING
          OBJNR               = LV_OBJNR
          USER_STATUS         = LV_STATUS
        EXCEPTIONS
          OBJECT_NOT_FOUND    = 1
          STATUS_INCONSISTENT = 2
          STATUS_NOT_ALLOWED  = 3
          OTHERS              = 4.
      IF SY-SUBRC <> 0.
        MESSAGE I203(YQMLIMS) WITH LS_QAMV-PRUEFLOS.
      ENDIF.
    ENDIF.

    CALL FUNCTION 'STATUS_TEXT_CONVERSION'
      EXPORTING
        LANGUAGE           = SY-LANGU
        MODE               = 'E'
        OBJNR              = LV_OBJNR
        TXT04              = 'KAVE'
      IMPORTING
        STATUS_NUMBER      = LV_STATUS
      EXCEPTIONS
        INSUFFICIENT_INPUT = 1
        NOT_FOUND          = 2
        OBJECT_NOT_FOUND   = 3
        WRONG_MODE         = 4
        OTHERS             = 5.
    IF SY-SUBRC = 0.
      CALL FUNCTION 'STATUS_CHANGE_EXTERN'
        EXPORTING
          OBJNR               = LV_OBJNR
          USER_STATUS         = LV_STATUS
        EXCEPTIONS
          OBJECT_NOT_FOUND    = 1
          STATUS_INCONSISTENT = 2
          STATUS_NOT_ALLOWED  = 3
          OTHERS              = 4.
      IF SY-SUBRC <> 0.
        MESSAGE I207(YQMLIMS) WITH LS_QAMV-PRUEFLOS.
      ENDIF.
    ENDIF.

  ENDIF.

  CALL FUNCTION 'QET4_SET_CHAR_RESULTS'
    EXPORTING
      I_VALUE = I_VALUE
      I_CELLS = T_CELLS
    TABLES
      T_CELLS = T_CELLS.

ENDFORM.                    "CLASS2_VALUE_INPUT
*---------------------------------------------------------------------*
*       FORM CLASS_SINGLE_RES_INPUT                                   *
*---------------------------------------------------------------------*
*       Input form for class CODE
*       Only the first word will be accepted, the rest will be ignored.
*---------------------------------------------------------------------*
*  -->  T_CELLS                                                       *
*  -->  I_CELLS                                                       *
*  -->  I_VALUE                                                       *
*---------------------------------------------------------------------*
FORM CLASS_SINGLE_RES_INPUT TABLES T_CELLS STRUCTURE QETBCELLS
                      USING  I_CELLS LIKE QETBCELLS
                             I_VALUE TYPE ANY
                             I_VALUE2 TYPE ANY.

  DATA: L_CODE LIKE BAPI2045D3-CODE1.
  DATA: L_CODE_TXT TYPE QKURZTEXT.
  DATA: L_CODE_GROUP LIKE BAPI2045D3-CODE_GRP1.

* separate code from field data
  SPLIT I_VALUE AT SPACE INTO L_CODE L_CODE_TXT.
  SET LOCALE LANGUAGE SPACE.
  TRANSLATE L_CODE TO UPPER CASE.                        "#EC TRANSLANG

* No codegroup available
  IF I_VALUE2 IS INITIAL.

*   read codegroup from internal data
    CALL FUNCTION 'QET4_SYNCHRONIZE_DATA'
      EXPORTING
        I_CELLS         = I_CELLS
      IMPORTING
        E_SAMPLE_RESULT = G_SAMPLE_RESULTS
        E_CHAR_RESULT   = G_CHAR_RESULTS. "note 738435

    IF G_SAMPLE_RESULTS-CODE_GRP1 IS INITIAL.
      L_CODE_GROUP = G_CHAR_RESULTS-CODE_GRP1.
    ELSE.
      L_CODE_GROUP = G_SAMPLE_RESULTS-CODE_GRP1.
    ENDIF.                                               "note 738435
  ELSE.
    L_CODE_GROUP = I_VALUE2.
  ENDIF.


* give it to the toolbox
  CALL FUNCTION 'QET4_SET_CHAR_RESULTS'
    EXPORTING
      I_CELLS      = I_CELLS
      I_VALUE      = L_CODE
      I_CODE_GROUP = L_CODE_GROUP  "note 738435
    TABLES
      T_CELLS      = T_CELLS.

ENDFORM.                    "CLASS_SINGLE_RES_INPUT
*---------------------------------------------------------------------*
*       FORM CLASS_SINGLE_RES_OUTPUT                                  *
*---------------------------------------------------------------------*
*       Output form for codes. P_VALUE will get the information as
*       code, blank, short text of code.
*---------------------------------------------------------------------*
*  -->  P_CELLS                                                       *
*  -->  P_VALUE                                                       *
*---------------------------------------------------------------------*
FORM CLASS_SINGLE_RES_OUTPUT CHANGING P_CELLS LIKE QETBCELLS
                                P_VALUE TYPE ANY.

  DATA: TABLE_NAME(40) TYPE C.
  DATA: FIELD_NAME(40) TYPE C.
  DATA: L_INFO         TYPE ICONQUICK.
  DATA: L_TEXT         TYPE QCODETEXT.
  DATA: L_VORGLFNR     LIKE QAPO-VORGLFNR.

  FIELD-SYMBOLS: <TABLE>, <FIELD>.
  DATA: L_ISSKIP       TYPE XFELD.
  DATA: L_ISDIRTY      TYPE XFELD.
  DATA: L_ISBLOCKED    TYPE XFELD.
  DATA: L_CODE_GROUP LIKE BAPI2045D3-CODE_GRP1. "note 738435
  CLEAR P_VALUE.

  DATA: LS_QASE        LIKE QASE.
  DATA: LT_QASE        TYPE TABLE OF QASE.

* read toolbox data
  CALL FUNCTION 'QET4_SYNCHRONIZE_DATA'
    EXPORTING
      I_CELLS                   = P_CELLS
    IMPORTING
      E_CHAR_REQUIREMENTS       = G_REQUIREMENTS
      E_SAMPLE_RESULT           = G_SAMPLE_RESULTS
      E_CHAR_RESULT             = G_CHAR_RESULTS
      E_INSP_POINT              = G_INSP_POINTS
      E_INSP_POINT_REQUIREMENTS = G_IP_REQUIREMENTS
      E_INSP_LOT                = G_INSP_LOTS
      E_LOCKED                  = G_LOCKED
      E_DURING_POSTING          = G_DURING_POSTING
      E_ISSKIP                  = L_ISSKIP
      E_ISDIRTY                 = L_ISDIRTY
      E_ISBLOCKED               = L_ISBLOCKED.

  CHECK NOT P_CELLS-REF_FIELD IS INITIAL.

* read from referenced field
  SPLIT P_CELLS-REF_FIELD AT '-' INTO TABLE_NAME FIELD_NAME.
  ASSIGN (TABLE_NAME) TO <TABLE>.
  ASSIGN COMPONENT FIELD_NAME OF STRUCTURE <TABLE> TO <FIELD>.

* read code
  IF NOT ( <FIELD> IS INITIAL OR <FIELD> = '!' ).
    CALL FUNCTION 'QIBP_GET_VORGLFNR'
      EXPORTING
        I_INSP_LOT           = G_SAMPLE_RESULTS-INSPLOT
        I_OPER_NO            = G_SAMPLE_RESULTS-INSPOPER
      IMPORTING
        E_VORGLFNR           = L_VORGLFNR
      EXCEPTIONS
        WRONG_INSPECTION_LOT = 1
        WRONG_OPERATION_NO   = 2
        OTHERS               = 3.
    IF SY-SUBRC <> 0.
      EXIT.
    ENDIF.

    SELECT * FROM QASE INTO TABLE LT_QASE
           WHERE PRUEFLOS = G_SAMPLE_RESULTS-INSPLOT
           AND   VORGLFNR = L_VORGLFNR
           AND   MERKNR   = G_SAMPLE_RESULTS-INSPCHAR
           AND   PROBENR  = G_SAMPLE_RESULTS-INSPSAMPLE.
    IF NOT LT_QASE[] IS INITIAL.
      LOOP AT LT_QASE INTO LS_QASE.
        CALL FUNCTION 'QPK1_CODE_TEXT'
          EXPORTING
            I_KATALOGART      = LS_QASE-KATALGART1
            I_CODEGRUPPE      = LS_QASE-GRUPPE1
            I_CODE            = LS_QASE-CODE1
            I_SPRACHE         = SY-LANGU
          IMPORTING
            E_TEXT            = L_TEXT
          EXCEPTIONS
            NO_MATCH_IN_RANGE = 1
            OTHERS            = 2.
        IF SY-SUBRC = 0.
*   Build output text
          IF P_VALUE IS INITIAL.
            MOVE L_TEXT TO P_VALUE.
          ELSE.
            CONCATENATE P_VALUE L_TEXT INTO P_VALUE SEPARATED BY '; '.
          ENDIF.
        ENDIF.

      ENDLOOP.
    ENDIF.
  ENDIF.

* status
  IF NOT L_ISBLOCKED IS INITIAL.
    CLEAR P_CELLS-INPUT_FIELD.
  ENDIF.

* input field?
  PERFORM IS_INPUT_ALLOWED
      USING      G_REQUIREMENTS
                 G_CHAR_RESULTS
                 G_SAMPLE_RESULTS
      CHANGING   P_CELLS.

  CLEAR P_CELLS-INPUT_FLG.
  IF NOT P_CELLS-INPUT_ALLOWED IS INITIAL.
    IF NOT G_REQUIREMENTS-CHAR_RES IS INITIAL.
      IF G_CHAR_RESULTS-EVALUATED IS INITIAL.
        P_CELLS-INPUT_FLG = C_SET.
      ENDIF.
    ELSEIF NOT G_REQUIREMENTS-SAMPLE_RES IS INITIAL.
      IF G_SAMPLE_RESULTS-EVALUATED IS INITIAL.
        P_CELLS-INPUT_FLG = C_SET.
      ENDIF.
    ENDIF.
  ENDIF.

* Characteristic without recording
  IF NOT G_REQUIREMENTS-NO_RECORDING IS INITIAL.
    CLEAR P_CELLS-INPUT_FLG.
  ENDIF.

* locked entries are always output fields
  IF  NOT G_LOCKED IS INITIAL
   OR NOT G_DURING_POSTING IS INITIAL.
    CLEAR P_CELLS-INPUT_FLG.
  ENDIF.

* skip chars
  IF NOT L_ISSKIP IS INITIAL.

    IF P_VALUE IS INITIAL AND L_ISDIRTY IS INITIAL.
      CLEAR P_CELLS-INPUT_FLG.
      P_VALUE = TEXT-075.
    ENDIF.

  ENDIF.

*   Icon and infotext
  PERFORM CREATE_ICON_SINGLE_RES
      USING    P_CELLS G_LOCKED G_DURING_POSTING
      CHANGING P_VALUE.

  IF  ( P_VALUE IS INITIAL OR P_VALUE = TEXT-075 )
   AND P_CELLS-INPUT_ALLOWED IS INITIAL.
    L_INFO = 'Pflege mit Ergebniserfassung'(850).

    CALL FUNCTION 'ICON_CREATE'
      EXPORTING
        NAME   = ICON_DETAIL
        TEXT   = P_VALUE
        INFO   = L_INFO
*       ADD_STDINF            = 'X'
      IMPORTING
        RESULT = P_VALUE.
  ENDIF.

ENDFORM.                    "CLASS_SINGLE_RES_OUTPUT
*---------------------------------------------------------------------*
*       FORM CREATE_ICON_SINGLE_RES                                   *
*---------------------------------------------------------------------*
*       Creates the icons for the various classes
*---------------------------------------------------------------------*
*  -->  P_CELLS                                                       *
*  -->  P_LOCKED                                                      *
*  -->  P_DURING_POSTING                                              *
*  -->  P_FIELD                                                       *
*---------------------------------------------------------------------*
FORM CREATE_ICON_SINGLE_RES
                 USING    P_CELLS LIKE QETBCELLS
                          P_LOCKED TYPE QKZ
                          P_DURING_POSTING TYPE QKZ
                 CHANGING P_FIELD.

  DATA: L_ICON  TYPE ICON_TEXT.
  DATA: L_INFO  TYPE ICONQUICK.

* create icon according to cells-icon
  IF P_DURING_POSTING IS INITIAL
     AND P_LOCKED IS INITIAL.

    CHECK NOT P_FIELD = '!'.
    CHECK P_CELLS-INPUT_FLG IS INITIAL.

*   char results
    IF NOT G_REQUIREMENTS-CHAR_RES IS INITIAL
       OR G_REQUIREMENTS-INSP_POINT IS INITIAL.
      IF G_CHAR_RESULTS-EVALUATION = 'A'.                   "#EC NOTEXT
        L_ICON = ICON_CHECKED.
      ELSEIF G_CHAR_RESULTS-EVALUATION = 'R'.               "#EC NOTEXT
        L_ICON = ICON_INCOMPLETE.
      ELSEIF G_CHAR_RESULTS-EVALUATION = 'F'.               "#EC NOTEXT
        L_ICON = ICON_FAILURE.
      ELSE.
        CLEAR L_ICON.
        CLEAR L_INFO.
      ENDIF.

*   sample results
    ELSE.
      IF G_SAMPLE_RESULTS-EVALUATION = 'A'.                 "#EC NOTEXT
        L_ICON = ICON_CHECKED.
      ELSEIF G_SAMPLE_RESULTS-EVALUATION = 'R'.             "#EC NOTEXT
        L_ICON = ICON_INCOMPLETE.
      ELSEIF G_SAMPLE_RESULTS-EVALUATION = 'F'.             "#EC NOTEXT
        L_ICON = ICON_FAILURE.
      ELSE.
        CLEAR L_ICON.
        CLEAR L_INFO.
      ENDIF.
    ENDIF.

    IF NOT L_ICON IS INITIAL.
      CALL FUNCTION 'ICON_CREATE'
        EXPORTING
          NAME       = L_ICON
          TEXT       = P_FIELD
          INFO       = L_INFO
          ADD_STDINF = ' '
        IMPORTING
          RESULT     = P_FIELD.
    ENDIF.
  ENDIF.

* mark field for posting in progress
  IF NOT P_DURING_POSTING IS INITIAL.
    L_INFO = TEXT-820.
    CALL FUNCTION 'ICON_CREATE'
      EXPORTING
        NAME   = ICON_LOCKED
        TEXT   = L_INFO
        INFO   = L_INFO
      IMPORTING
        RESULT = P_FIELD.
  ENDIF.

* mark field as locked
  IF NOT P_LOCKED IS INITIAL.
    L_INFO = TEXT-830.
    CALL FUNCTION 'ICON_CREATE'
      EXPORTING
        NAME   = ICON_LOCKED
        TEXT   = L_INFO
        INFO   = L_INFO
      IMPORTING
        RESULT = P_FIELD.
  ENDIF.

ENDFORM.                    "CREATE_ICON_SINGLE_RES
*&---------------------------------------------------------------------*
*&      Form  change_Inspection_method
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CHANGE_INSPECTION_METHOD
             TABLES P_RESULTS STRUCTURE QETBCELLS
             USING  P_ROW_NO  LIKE SY-CUROW
                    P_COL_NO  LIKE SY-CUCOL.


  DATA: LS_PM_KTEXT       LIKE QMTT-KURZTEXT.
  DATA: LS_QPMK           LIKE QPMK.
  DATA: LS_QAMV           LIKE QAMV.
  DATA: LS_QPMZ           LIKE QPMZ.
  DATA: ANSWER            TYPE C.
  DATA: TEXT_QUESTION     TYPE TEXT132.
  DATA: NO_OF_METHODS     LIKE SY-TABIX.
  DATA: NAME_G_REQUI(32)  VALUE '(SAPLQET4)G_REQUIREMENTS[]'.
  DATA: LS_REQUIREMENTS   LIKE BAPI2045D1.
  DATA: LT_REQUIREMENTS   TYPE TABLE OF BAPI2045D1.

  FIELD-SYMBOLS <G_REQUI> TYPE ANY.

  CALL FUNCTION 'QIBP_GET_VORGLFNR'
    EXPORTING
      I_INSP_LOT           = P_RESULTS-INSPLOT
      I_OPER_NO            = P_RESULTS-INSPOPER
    IMPORTING
      E_VORGLFNR           = LS_QAMV-VORGLFNR
    EXCEPTIONS
      WRONG_INSPECTION_LOT = 1
      WRONG_OPERATION_NO   = 2
      OTHERS               = 3.
  IF SY-SUBRC <> 0.
    MESSAGE S104(YQMLIMS).
    EXIT.
  ENDIF.

  SELECT SINGLE * FROM QAMV INTO LS_QAMV
         WHERE PRUEFLOS = P_RESULTS-INSPLOT
         AND   VORGLFNR = LS_QAMV-VORGLFNR
         AND   MERKNR   = P_RESULTS-INSPCHAR.
  IF SY-SUBRC = 0.
    CALL FUNCTION 'QPSD_FEATURE_VERSION_READ'
      EXPORTING
        WERK             = LS_QAMV-QPMK_WERKS
        MERKMAL          = LS_QAMV-VERWMERKM
        VERSION          = LS_QAMV-MKVERSION
        KZ_AUFLOESUNG    = 'X'
        KZ_NICHTFREI     = ' '
        SPRACHE          = SY-LANGU
      IMPORTING
        QPMZ_EXP         = LS_QPMZ
        QPMZ_KTEXT_METH  = LS_PM_KTEXT
        E_NO_OF_METHODS  = NO_OF_METHODS
      EXCEPTIONS
        NO_FEATURE       = 1
        NO_FREE_VERSION  = 2
        NO_VERSION       = 3
        NO_AUTHORIZATION = 4
        OTHERS           = 5.
    IF SY-SUBRC <> 0.
      MESSAGE ID SY-MSGID TYPE 'S' NUMBER SY-MSGNO
              WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
      MESSAGE S105(YQMLIMS).
      EXIT.
    ELSE.
      IF NOT UT_QAMV[] IS INITIAL.
        READ TABLE UT_QAMV INTO US_QAMV WITH KEY
             PRUEFLOS = P_RESULTS-INSPLOT
             VORGLFNR = LS_QAMV-VORGLFNR
             MERKNR   = P_RESULTS-INSPCHAR.
        IF SY-SUBRC = 0.
          MOVE-CORRESPONDING US_QAMV TO LS_QAMV.
        ENDIF.
      ENDIF.


      IF LS_QPMZ-WERKPM   NE LS_QAMV-QMTB_WERKS
      OR LS_QPMZ-PMETHODE NE LS_QAMV-PMETHODE
      OR LS_QPMZ-VERSPM   NE LS_QAMV-PMTVERSION.

        CASE NO_OF_METHODS.
          WHEN 0.
            MESSAGE S107(YQMLIMS) WITH LS_QAMV-QPMK_WERKS
                                       LS_QAMV-VERWMERKM
                                       LS_QAMV-MKVERSION.
            EXIT.
          WHEN 1.
            CONCATENATE TEXT-T42
                        LS_QAMV-PMETHODE
                        LS_PM_KTEXT
                        TEXT-T42 INTO TEXT_QUESTION SEPARATED BY SPACE.

            CALL FUNCTION 'POPUP_TO_CONFIRM'
              EXPORTING
                TITLEBAR       = TEXT-T41
                TEXT_QUESTION  = TEXT_QUESTION
                TEXT_BUTTON_1  = 'Ja'(101)
                TEXT_BUTTON_2  = 'Nein'(102)
                DEFAULT_BUTTON = '1'
              IMPORTING
                ANSWER         = ANSWER
              EXCEPTIONS
                TEXT_NOT_FOUND = 1
                OTHERS         = 2.

            IF  SY-SUBRC EQ 0
            AND ANSWER  EQ 1.
* Zum Merkmal existiert nur Methode &1. Soll dies übernommen werden

            ELSE.
              MESSAGE S170(QM).
            ENDIF.
          WHEN OTHERS.

        ENDCASE.

        IF  LS_QPMZ-WERKPM   NE SPACE
        AND LS_QPMZ-PMETHODE NE SPACE
        AND LS_QPMZ-VERSPM   NE SPACE.

          MOVE LS_QPMZ-WERKPM   TO LS_QAMV-QMTB_WERKS.
          MOVE LS_QPMZ-PMETHODE TO LS_QAMV-PMETHODE.
          MOVE LS_QPMZ-VERSPM   TO LS_QAMV-PMTVERSION.

          MOVE SY-UNAME         TO LS_QAMV-AENDERER.
          MOVE SY-DATUM         TO LS_QAMV-AENDERDAT.

          CALL FUNCTION 'Y_QMLIMS_QET5_QAMV_COLLECT'
            EXPORTING
              IS_QAMV = LS_QAMV
            TABLES
              UT_QAMV = UT_QAMV.

          CALL FUNCTION 'Y_QMLIMS_QET5_QAMV_UPDATE' IN UPDATE TASK
            TABLES
              UT_QAMV = UT_QAMV.

* Tabelle G_REQUIREMENTS in SAPLQET4 muss noch aktualisiert werden.
          ASSIGN (NAME_G_REQUI) TO <G_REQUI>.

          LT_REQUIREMENTS[] = <G_REQUI>.
          LOOP AT LT_REQUIREMENTS INTO LS_REQUIREMENTS
               WHERE INSPLOT  = P_RESULTS-INSPLOT
               AND   INSPOPER = P_RESULTS-INSPOPER
               AND   INSPCHAR = P_RESULTS-INSPCHAR.

            LS_REQUIREMENTS-METHOD     = LS_QPMZ-PMETHODE.
            LS_REQUIREMENTS-METHOD_TXT = LS_PM_KTEXT.
            LS_REQUIREMENTS-VMETHOD    = LS_QPMZ-VERSPM.
            LS_REQUIREMENTS-PMETHOD    = LS_QPMZ-WERKPM.
            MODIFY LT_REQUIREMENTS FROM LS_REQUIREMENTS.
          ENDLOOP.
          <G_REQUI> = LT_REQUIREMENTS[].

          CALL FUNCTION 'Y_QMLIMS_QET5_SET_SAVE_FLAG'.
        ENDIF.
      ELSE.
        MESSAGE S105(YQMLIMS).
        EXIT.
      ENDIF.
    ENDIF.
  ENDIF.

ENDFORM.                    " change_Inspection_method
*---------------------------------------------------------------------*
*       FORM CLASS_PMETH_OUTPUT                                        *
*---------------------------------------------------------------------*
*       This class interprets the content of REF_FIELD as text and
*       displays it.
*---------------------------------------------------------------------*
*  -->  P_CELLS                                                       *
*  -->  P_VALUE                                                       *
*---------------------------------------------------------------------*
FORM CLASS_PMETH_OUTPUT CHANGING P_CELLS LIKE QETBCELLS
                                 P_VALUE TYPE ANY.

  P_VALUE = P_CELLS-REF_FIELD.

ENDFORM.                    "class_pmeth_output

*---------------------------------------------------------------------*
*       FORM CLASS_PMETH_INPUT                                         *
*---------------------------------------------------------------------*
*       Input form for class PMETH
*       never called
*---------------------------------------------------------------------*
FORM CLASS_PMETH_INPUT TABLES T_CELLS STRUCTURE QETBCELLS
                       USING  I_CELLS LIKE QETBCELLS
                              I_VALUE TYPE ANY.
ENDFORM.                    "class_pmeth_input
*---------------------------------------------------------------------*
*       FORM CLASS_TEXT_OUTPUT                                        *
*---------------------------------------------------------------------*
*       This class interprets the content of REF_FIELD as text and
*       displays it.
*---------------------------------------------------------------------*
*  -->  P_CELLS                                                       *
*  -->  P_VALUE                                                       *
*---------------------------------------------------------------------*
FORM CLASS_QPRS_OUTPUT CHANGING P_CELLS LIKE QETBCELLS
                                P_VALUE TYPE ANY.
  P_VALUE = P_CELLS-INFO.

ENDFORM.                    "CLASS_TEXT_OUTPUT

*---------------------------------------------------------------------*
*       FORM CLASS_TEXT_INPUT                                         *
*---------------------------------------------------------------------*
*       Input form for class TEXT
*       never called
*---------------------------------------------------------------------*
FORM CLASS_QPRS_INPUT TABLES T_CELLS STRUCTURE QETBCELLS
                       USING  I_CELLS LIKE QETBCELLS
                              I_VALUE TYPE ANY.
ENDFORM.                    "CLASS_TEXT_INPUT
*---------------------------------------------------------------------*
*       FORM CLASS_QPRS_ALL_OUTPUT                                        *
*---------------------------------------------------------------------*
*       This class interprets the content of REF_FIELD as text and
*       displays it.
*---------------------------------------------------------------------*
*  -->  P_CELLS                                                       *
*  -->  P_VALUE                                                       *
*---------------------------------------------------------------------*
FORM CLASS_QPRS_ALL_OUTPUT CHANGING P_CELLS LIKE QETBCELLS
                                P_VALUE TYPE ANY.
  P_VALUE = P_CELLS-INFO.

ENDFORM.                    "CLASS_QPRS_ALL_OUTPUT

*---------------------------------------------------------------------*
*       FORM CLASS_QPRS_ALL_INPUT                                         *
*---------------------------------------------------------------------*
*       Input form for class TEXT
*       never called
*---------------------------------------------------------------------*
FORM CLASS_QPRS_ALL_INPUT TABLES T_CELLS STRUCTURE QETBCELLS
                       USING  I_CELLS LIKE QETBCELLS
                              I_VALUE TYPE ANY.
ENDFORM.                    "CLASS_QPRS_ALL_INPUT
