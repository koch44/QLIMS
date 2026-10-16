*----------------------------------------------------------------------*
***INCLUDE LYQMLIMS_ARCHF01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form befund_legionellen_ermitteln
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> OBJTXT_LEG
*&      --> I_PRUEFLOS
*&---------------------------------------------------------------------*
FORM befund_legionellen_ermitteln  TABLES   t_objtxt_leg TYPE STANDARD TABLE "solisti1
                                   USING    iv_prueflos.

  DATA: lv_attribut   TYPE qattribut.
  DATA: lv_mittelwert TYPE yqm_wert.
  DATA: ls_ve_lt      TYPE yqm_ve_lt_t.
  DATA: lv_ltext_ve   TYPE flag.
  DATA: ls_matn_mk    TYPE yqm_matn_mk_t.
  DATA: lv_tdname     TYPE tdobname.
  DATA: ls_qals       TYPE qals.
  DATA: ls_qamv       TYPE qamv.
  DATA: lt_qamv       TYPE TABLE OF qamv.
  DATA: ls_qasr_h     TYPE qasr.
  DATA: ls_qasr       TYPE qasr.
  DATA: lt_qasr       TYPE TABLE OF qasr.
  DATA: ls_lines      TYPE tline.
  DATA: lt_lines      TYPE TABLE OF tline.

* Langtext zum Verwendungsentscheid ermitteln
  CONCATENATE sy-mandt
              iv_prueflos
              'L'
         INTO lv_tdname.

  CLEAR lv_ltext_ve.

  CALL FUNCTION 'READ_TEXT'
    EXPORTING
      id                      = 'QAVE'
      language                = sy-langu
      name                    = lv_tdname
      object                  = 'QPRUEFLOS'
    TABLES
      lines                   = lt_lines
    EXCEPTIONS
      id                      = 1
      language                = 2
      name                    = 3
      not_found               = 4
      object                  = 5
      reference_check         = 6
      wrong_access_to_archive = 7
      OTHERS                  = 8.
  IF sy-subrc <> 0.
* Implement suitable error handling here
    CLEAR lt_lines.
  ELSE.
    LOOP AT lt_lines INTO ls_lines
      WHERE tdformat = space
      OR    tdformat = '='
      OR    tdformat = '*'.

      APPEND ls_lines-tdline TO t_objtxt_leg.
      lv_ltext_ve = 'X'.
    ENDLOOP.
    IF sy-subrc <> 0.
      CLEAR lv_ltext_ve.
    ENDIF.
  ENDIF.

  IF lv_ltext_ve IS INITIAL.

    SELECT SINGLE * FROM qals INTO ls_qals
      WHERE prueflos = iv_prueflos.
    IF sy-subrc <> 0.
      EXIT.
    ENDIF.

    SELECT * FROM qamv INTO TABLE lt_qamv
      WHERE prueflos = iv_prueflos.
    IF sy-subrc <> 0.
      EXIT.
    ENDIF.

    SELECT * FROM qasr INTO TABLE lt_qasr
      WHERE prueflos = iv_prueflos.
    IF sy-subrc <> 0.
      EXIT.
    ENDIF.

    SELECT SINGLE * FROM yqm_matn_mk_t
      INTO ls_matn_mk
      WHERE matnr   = ls_qals-matnr
      AND   regel   = '20'.
    IF sy-subrc <> 0.
      EXIT.
    ENDIF.

    LOOP AT lt_qamv INTO ls_qamv
      WHERE verwmerkm = ls_matn_mk-merkmal.
      LOOP AT lt_qasr INTO ls_qasr
        WHERE prueflos = ls_qamv-prueflos
        AND   vorglfnr = ls_qamv-vorglfnr
        AND   merknr   = ls_qamv-merknr.

*   Attribut 'U' bedeutet nicht nachweisbar.
*   Ergebnisse mit diesem Attribut haben den Messwerte 99999
*   und dürfen nicht betrachtet werden
        IF ls_qasr-attribut = 'U'.
          CONTINUE.
        ENDIF.

        IF ls_qasr_h            IS INITIAL.
          ls_qasr_h = ls_qasr.
        ELSEIF ls_qasr_h-mittelwert LT ls_qasr-mittelwert.
          ls_qasr_h = ls_qasr.
        ELSEIF ls_qasr_h-mittelwert EQ ls_qasr-mittelwert.
          IF ls_qasr_h-attribut = '<'.
            ls_qasr_h = ls_qasr.
          ENDIF.
        ENDIF.
      ENDLOOP.

      IF  ls_qasr_h         IS INITIAL
      AND ls_qasr-attribut = 'U'.
* Falls bis hierhin kein Ergebnis gefunden werden konnte,
* waren offensichtlich alle Messwerte mit Attribut U versehen.
* In diesem Fall wird der Ergebniswert 99999 übernommen und damit der
* korrekte Langtext bzgl der Kontamination ausgegeben
        ls_qasr_h = ls_qasr.
      ENDIF.

    ENDLOOP.

    lv_mittelwert = ls_qasr_h-mittelwert.
    lv_attribut   = ls_qasr_h-attribut.

    CLEAR ls_ve_lt.

    IF lv_attribut = '<'.
      SELECT * FROM yqm_ve_lt_t INTO ls_ve_lt
        WHERE matnr     = ls_qals-matnr
        AND   verwmerkm = ls_qamv-verwmerkm
        AND   abw       = 'X'
        AND   wertv     LT lv_mittelwert
        ORDER BY wertv DESCENDING.
        EXIT.
      ENDSELECT.
      IF sy-subrc <> 0.
        CLEAR ls_ve_lt.
      ENDIF.
    ELSE.
      SELECT * FROM yqm_ve_lt_t INTO ls_ve_lt
        WHERE matnr     = ls_qals-matnr
        AND   verwmerkm = ls_qamv-verwmerkm
        AND   abw       = 'X'
        AND   wertv     LE lv_mittelwert
        ORDER BY wertv DESCENDING.
        EXIT.
      ENDSELECT.
      IF sy-subrc <> 0.
        CLEAR ls_ve_lt.
      ENDIF.
    ENDIF.

    CASE ls_ve_lt-lfdnr.
      WHEN 0.
        CONCATENATE 'Y_QM_MAILTEXT_KONTAMINIERT_'
                    '01' INTO lv_tdname.
      WHEN 1.
        CONCATENATE 'Y_QM_MAILTEXT_KONTAMINIERT_'
                    '02' INTO lv_tdname.
      WHEN 2.
        CONCATENATE 'Y_QM_MAILTEXT_KONTAMINIERT_'
                    '02' INTO lv_tdname.
      WHEN 3.
        CONCATENATE 'Y_QM_MAILTEXT_KONTAMINIERT_'
                    '03' INTO lv_tdname.
      WHEN 4.
        CONCATENATE 'Y_QM_MAILTEXT_KONTAMINIERT_'
                    '04' INTO lv_tdname.
      WHEN 5.
        CONCATENATE 'Y_QM_MAILTEXT_KONTAMINIERT_'
                    '05' INTO lv_tdname.
      WHEN 6.
        CONCATENATE 'Y_QM_MAILTEXT_KONTAMINIERT_'
                    '05' INTO lv_tdname.
    ENDCASE.

    IF NOT lv_tdname IS INITIAL.
      CALL FUNCTION 'READ_TEXT'
        EXPORTING
          id                      = 'ST'
          language                = sy-langu
          name                    = lv_tdname
          object                  = 'TEXT'
        TABLES
          lines                   = lt_lines
        EXCEPTIONS
          id                      = 1
          language                = 2
          name                    = 3
          not_found               = 4
          object                  = 5
          reference_check         = 6
          wrong_access_to_archive = 7
          OTHERS                  = 8.
      IF sy-subrc <> 0.
* Implement suitable error handling here
        EXIT.
      ENDIF.
      LOOP AT lt_lines INTO ls_lines.
        APPEND ls_lines-tdline TO t_objtxt_leg.
      ENDLOOP.
    ENDIF.
  ENDIF.
ENDFORM.
