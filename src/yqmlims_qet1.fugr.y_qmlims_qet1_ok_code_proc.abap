FUNCTION Y_QMLIMS_QET1_OK_CODE_PROC.
*"--------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     VALUE(I_ROW_NO) LIKE  SY-CUROW
*"     VALUE(I_COL_NO) LIKE  SY-CUCOL
*"     VALUE(I_AREA) LIKE  SY-TNAME
*"     VALUE(I_OK_CODE) LIKE  T185-FCODE
*"     VALUE(I_SCREEN_MANAGER) LIKE  SY-CPROG
*"  TABLES
*"      T_SPECS STRUCTURE  QETBCELLS
*"      T_RESULTS STRUCTURE  QETBCELLS
*"--------------------------------------------------------------------

  DATA: L_NOT_PROCESSED TYPE C.

  L_NOT_PROCESSED = 'X'.

* Globale Daten belegen
  MOVE I_ROW_NO         TO G_ROW_NO.
  MOVE I_COL_NO         TO G_COL_NO.
  MOVE I_AREA           TO G_AREA.
  MOVE I_OK_CODE        TO G_OK_CODE.
  MOVE I_SCREEN_MANAGER TO G_SCREEN_MANAGER.

* Redirect certain OK Codes
  IF g_ok_code = 'QETBPICK'.
    READ TABLE t_results WITH KEY row_no = i_row_no
                                  col_no = i_col_no.
    IF sy-subrc = 0.
      CASE t_results-field_type.
        WHEN 'QPRS'.
          g_ok_code = 'QPRS'.
        WHEN 'QPRS_ALL'.
          g_ok_code = 'QPRS_ALL'.
        WHEN OTHERS.
      ENDCASE.
    ENDIF.
  ENDIF.

  CASE G_OK_CODE.
* Zurück, Beenden
    WHEN 'BACK'
      OR 'END'
      OR 'QETBNEXTOP'.
      PERFORM BACK_END.
      CLEAR L_NOT_PROCESSED.
* Sichern
    WHEN 'SAVE'.
      PERFORM SAVE.
      CLEAR L_NOT_PROCESSED.

* Abschliessen und sichern
    WHEN 'QETBCLOSE'.
      PERFORM CLOSE_AND_SAVE TABLES T_SPECS T_RESULTS.
      CLEAR L_NOT_PROCESSED.

* Auswählen
    WHEN 'QETBPICK'.
      PERFORM SELECT TABLES T_SPECS T_RESULTS.
      CLEAR L_NOT_PROCESSED.

* Protokoll anzeigen
    WHEN 'QETBPROT'.
      PERFORM SHOW_PROTOCOL.
      CLEAR L_NOT_PROCESSED.

* Prüfbemerkung
    WHEN 'QETBTEXT'.
      PERFORM REMARK TABLES T_SPECS T_RESULTS.
      CLEAR L_NOT_PROCESSED.

* Ergebniserfassung ändern
    WHEN 'QETBJPRRC'.
      PERFORM JUMP_RESULTRECORDING TABLES T_SPECS T_RESULTS.
      CLEAR L_NOT_PROCESSED.

* Ergebniserfassung anzeigen
    WHEN 'QETBJPRRD'.
      PERFORM JUMP_RESULTRECORDING TABLES T_SPECS T_RESULTS.
      CLEAR L_NOT_PROCESSED.

* Regelkarte
    WHEN 'QETBJQRKD'.
      PERFORM JUMP_CONTROL_CHART TABLES T_SPECS T_RESULTS.
      CLEAR L_NOT_PROCESSED.

* STI-Auswertungen
    WHEN 'QETBJSTI'.
      PERFORM CALL_STI TABLES T_SPECS T_RESULTS.
      CLEAR L_NOT_PROCESSED.

* Ergebnishistorie
    WHEN 'QETBJHIST'.
      PERFORM CALL_HISTORIE TABLES T_SPECS T_RESULTS.
      CLEAR L_NOT_PROCESSED.

* Prüflosstatus
    WHEN 'QETBPSTA'.
      PERFORM LOT_STATUS TABLES T_SPECS T_RESULTS.
      CLEAR L_NOT_PROCESSED.

* Ganz nach rechts blättern
    WHEN 'QETBPS--'.
      PERFORM PAGE_LEFT_OR_RIGHT.
      CLEAR L_NOT_PROCESSED.
* Eine Spalte nach rechts blättern
    WHEN 'QETBPS-'.
      PERFORM PAGE_LEFT_OR_RIGHT.
      CLEAR L_NOT_PROCESSED.
* Eine Spalte nach links blättern
    WHEN 'QETBPS+'.
      PERFORM PAGE_LEFT_OR_RIGHT.
      CLEAR L_NOT_PROCESSED.
* Ganz nach links blättern
    WHEN 'QETBPS++'.
      PERFORM PAGE_LEFT_OR_RIGHT.
      CLEAR L_NOT_PROCESSED.

* Ganz nach oben blättern
    WHEN 'P--'.
      PERFORM PAGE_UP_OR_DOWN.
      CLEAR L_NOT_PROCESSED.
* Eine Seite nach oben blättern
    WHEN 'P-'.
      PERFORM PAGE_UP_OR_DOWN.
      CLEAR L_NOT_PROCESSED.
* Eine Seite nach unten blättern
    WHEN 'P+'.
      PERFORM PAGE_UP_OR_DOWN.
      CLEAR L_NOT_PROCESSED.
* Ganz nach oben blättern
    WHEN 'P++'.
      PERFORM PAGE_UP_OR_DOWN.
      CLEAR L_NOT_PROCESSED.

  ENDCASE.

  IF NOT L_NOT_PROCESSED IS INITIAL.
    PERFORM USER_OK_CODE TABLES T_SPECS T_RESULTS.
  ENDIF.

ENDFUNCTION.
