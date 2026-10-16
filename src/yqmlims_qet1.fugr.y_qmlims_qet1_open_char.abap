FUNCTION Y_QMLIMS_QET1_OPEN_CHAR.
*"--------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     VALUE(I_ROW_NO) LIKE  SY-CUROW
*"     VALUE(I_COL_NO) LIKE  SY-CUCOL
*"     VALUE(I_AREA) LIKE  SY-TNAME
*"     VALUE(I_OK_CODE) LIKE  T185-FCODE
*"  TABLES
*"      T_SPECS STRUCTURE  QETBCELLS
*"      T_RESULTS STRUCTURE  QETBCELLS
*"--------------------------------------------------------------------

  DATA: L_CELLS     TYPE QETBCELLS.
  DATA: L_SUBRC     LIKE SY-SUBRC.
  DATA: L_LOT       TYPE BAPI2045D_IL0.
  DATA: L_OPERATION TYPE BAPI2045L2.
  DATA: L_REQUIREMENTS TYPE BAPI2045D1.
  DATA: L_LOCKED TYPE QKZ.

* Cursorposition überprüfen
  PERFORM CHECK_CURSOR_ON_RESULTS_FIELD
      TABLES   T_RESULTS
      USING    I_ROW_NO I_COL_NO I_AREA
      CHANGING L_SUBRC.
  CHECK L_SUBRC IS INITIAL.

* Daten der Zelle lesen
  READ TABLE T_RESULTS INTO L_CELLS
           WITH KEY ROW_NO = I_ROW_NO
                    COL_NO = I_COL_NO.

  IF L_CELLS-INPUT_ALLOWED IS INITIAL.
* Eingaben sind nicht erlaubt
* Prüflos lesen
    CALL FUNCTION 'QET4_SYNCHRONIZE_DATA'
         EXPORTING
              I_CELLS    = L_CELLS
         IMPORTING
              E_INSP_LOT = L_LOT.

* Betriebswirtschaflicher Vorgang: Arbeitsvorrat Prüfergebnisse
    CALL FUNCTION 'QAST_PROCESS_ACTIVITY'
         EXPORTING
              I_CHECK_ONLY         = 'X'
              I_DIALOG             = 'X'
              I_OBJNR              = L_LOT-OBJECT_NO
              I_VORGANG            = 'QM25'
         EXCEPTIONS
              NOT_ALLOWED          = 01
              ACTIVITY_NOT_ALLOWED = 02.

    IF NOT SY-SUBRC IS INITIAL.
* Because:  IF L_CELLS-INPUT_ALLOWED IS INITIAL.
* Nur S-Message ausgeben
      MESSAGE ID SY-MSGID TYPE 'S' NUMBER SY-MSGNO.
      EXIT.                            "und raus
    ENDIF.
* Absprung in die Ergebniserfassung -> Ändern
    CALL FUNCTION 'Y_QMLIMS_QET1_JUMP_RESULTREC'
         EXPORTING
              I_ROW_NO    = G_ROW_NO
              I_COL_NO    = G_COL_NO
              I_AREA      = G_AREA
              I_OK_CODE   = 'QETBJPRRC'
         TABLES
              T_SPECS     = T_SPECS
              T_RESULTS   = T_RESULTS
         EXCEPTIONS
              NO_JUMP_RR  = 1
              NO_LOT_OPER = 2
              NO_IP       = 3
              OTHERS      = 4.

    IF SY-SUBRC <> 0.
* Nur S-Message ausgeben
      MESSAGE ID SY-MSGID TYPE 'S' NUMBER SY-MSGNO.
    ENDIF.
    EXIT.                              "und immer raus

  ENDIF."IF L_CELLS-INPUT_ALLOWED IS INITIAL.

* Feld bereits eingabebereit?
  CHECK L_CELLS-INPUT_FLG IS INITIAL.

* Vorgang lesen
  CALL FUNCTION 'QET4_SYNCHRONIZE_DATA'
       EXPORTING
            I_CELLS             = L_CELLS
       IMPORTING
            E_OPERATION         = L_OPERATION
            E_CHAR_REQUIREMENTS = L_REQUIREMENTS
            E_LOCKED            = L_LOCKED.

* gesperrte Merkmale nicht bearbeiten
  IF NOT L_LOCKED IS INITIAL.
    MESSAGE S033.
    EXIT.
  ENDIF.

* Berechtigung überprüfen
* Note 3353608
  IF NOT L_OPERATION-WORKCENTER IS INITIAL.
    CALL FUNCTION 'QAUT_CHARACTERISTIC_PROC'
      EXPORTING
            I_WERK              = L_OPERATION-PLNT_WORKC
            I_ARBPL             = L_OPERATION-WORKCENTER
            I_STATNEW           = '2'
            I_NO_STAT_CHECK_OLD = 'X'
       EXCEPTIONS
            NO_AUTHORIZATION    = 01
            AUTH_DESTROYED      = 02
            INTERNAL_ERROR      = 03.
  IF NOT SY-SUBRC IS INITIAL.
    MESSAGE S019.
    EXIT.
    ENDIF.
  ENDIF.

* alle abhängigen Felder invalidieren
  LOOP AT T_RESULTS
         WHERE INSPLOT    = L_CELLS-INSPLOT
           AND INSPOPER   = L_CELLS-INSPOPER
           AND INSPCHAR   = L_CELLS-INSPCHAR
           AND INSPSAMPLE = L_CELLS-INSPSAMPLE.

    T_RESULTS-INVALID_FLG = 'X'.
    MODIFY T_RESULTS.

  ENDLOOP.

* open characteristic in toolbox data
  IF L_REQUIREMENTS-INSP_POINT IS INITIAL.
    CALL FUNCTION 'QET4_SET_CHAR_RESULTS'
         EXPORTING
              I_VALUE           = '!'
              I_CELLS           = L_CELLS
              I_ALTERNATE_FIELD = 'G_CHAR_RESULTS-CLOSED'
         TABLES
              T_CELLS           = T_RESULTS.

    CALL FUNCTION 'QET4_SET_CHAR_RESULTS'
         EXPORTING
              I_VALUE           = '!'
              I_CELLS           = L_CELLS
              I_ALTERNATE_FIELD = 'G_CHAR_RESULTS-EVALUATED'
         TABLES
              T_CELLS           = T_RESULTS.

* Initialize Evaluation; example first 1 non.con.unit, then 0 non.con.u.
    CALL FUNCTION 'QET4_SET_CHAR_RESULTS'
         EXPORTING
              I_VALUE           = '!'
              I_CELLS           = L_CELLS
              I_ALTERNATE_FIELD = 'G_CHAR_RESULTS-EVALUATION'
         TABLES
              T_CELLS           = T_RESULTS.

  ELSE.
* With inspection points
    CALL FUNCTION 'QET4_SET_CHAR_RESULTS'
         EXPORTING
              I_VALUE           = '!'
              I_CELLS           = L_CELLS
              I_ALTERNATE_FIELD = 'G_SAMPLE_RESULTS-CLOSED'
         TABLES
              T_CELLS           = T_RESULTS.

    CALL FUNCTION 'QET4_SET_CHAR_RESULTS'
         EXPORTING
              I_VALUE           = '!'
              I_CELLS           = L_CELLS
              I_ALTERNATE_FIELD = 'G_SAMPLE_RESULTS-EVALUATED'
         TABLES
              T_CELLS           = T_RESULTS.

* Initialize Evaluation; example first 1 non.con.unit, then 0 non.con.u.
    CALL FUNCTION 'QET4_SET_CHAR_RESULTS'
         EXPORTING
              I_VALUE           = '!'
              I_CELLS           = L_CELLS
              I_ALTERNATE_FIELD = 'G_SAMPLE_RESULTS-EVALUATION'
         TABLES
              T_CELLS           = T_RESULTS.

  ENDIF.

ENDFUNCTION.
