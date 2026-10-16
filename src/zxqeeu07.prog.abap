*&---------------------------------------------------------------------*
*&  Include           ZXQEEU07
*&---------------------------------------------------------------------*
*FUNCTION EXIT_SAPLQEEM_004.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"       IMPORTING
*"             VALUE(I_QALS) LIKE  QALS STRUCTURE  QALS
*"             VALUE(I_QAPO) LIKE  QAPO STRUCTURE  QAPO
*"             VALUE(I_QAPP) LIKE  QAPP STRUCTURE  QAPP OPTIONAL
*"             VALUE(I_QALT) LIKE  QALT STRUCTURE  QALT OPTIONAL
*"             VALUE(I_QAMKR) LIKE  QAMKR STRUCTURE  QAMKR OPTIONAL
*"             VALUE(I_QASPR) LIKE  QASPR STRUCTURE  QASPR OPTIONAL
*"             VALUE(I_SINGLE_SAMPLE_KZ) LIKE  QM00-QKZ
*"       EXPORTING
*"             VALUE(E_QASPR) LIKE  QASPR STRUCTURE  QASPR
*"       TABLES
*"              T_QASPTAB STRUCTURE  QASPR OPTIONAL
*"----------------------------------------------------------------------

DATA: lv_subrc   TYPE sy-subrc.
DATA: lv_merknr  TYPE qamr-merknr.

DATA: ls_savetab TYPE qaspr.
DATA: lt_probtab TYPE TABLE OF qapsp.
DATA: lt_savetab TYPE TABLE OF qaspr.

MOVE-CORRESPONDING i_qaspr TO e_qaspr.

* User-Exit nur für Prüfart CHTP durchlaufen
CHECK i_qals-art = 'YQM_TP'.

IF NOT i_qamkr-formelsl IS INITIAL.

  IF  NOT i_qaspr-mittelwni  IS INITIAL
  AND NOT i_qamkr-grenzun1ni IS INITIAL.
    PERFORM compare_less(sapmqeea)
              USING    i_qaspr-mittelwert i_qaspr-mittelwni
                       i_qamkr-grenzeun1  i_qamkr-grenzun1ni
                       i_qamkr-stellen '0'
              CHANGING lv_subrc.
    IF lv_subrc = 0.
* berechneter Wert liegt unterhalb der Plausigrenze
      e_qaspr-mittelwert = i_qamkr-grenzeun1.
      e_qaspr-attribut   = '<'.
    ENDIF.

* Bei Multiplikation eines Ergebnisses mit Attribut '<' soll auch das
* Attribut '<' gesetzt werden
    IF e_qaspr-attribut NE '<'.
      IF i_qamkr-formel1 CA '*'.
        lv_merknr = i_qamkr-formel1+2(4).
        CALL FUNCTION 'QETM_FETCH_TABLE_QASPTAB'
          EXPORTING
            i_merknr   = lv_merknr
            i_prueflos = i_qaspr-prueflos
            i_vorglfnr = i_qaspr-vorglfnr
            i_probenr  = i_qaspr-probenr
          TABLES
            t_probtab  = lt_probtab
            t_savetab  = lt_savetab
          EXCEPTIONS
            read_error = 1
            OTHERS     = 2.
        IF sy-subrc = 0.
          READ TABLE lt_savetab INTO ls_savetab INDEX 1.
          IF sy-subrc = 0.
            IF ls_savetab-attribut = '<'.
              e_qaspr-attribut = '<'.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.

ENDIF.
