*&---------------------------------------------------------------------*
*& Include          ZXQEVU09
*&---------------------------------------------------------------------*
* Bei Rücknahme des VE soll der vorgeschlagene Text 'Bitte kommentieren Sie:'
* ersetzt werden durch 'Grund der Korrektur'

  DATA: lv_lines TYPE sy-tfill.

  FIELD-SYMBOLS <ls_ud_ltxt> TYPE any.

  CHECK i_qals-art  EQ 'YQM_TP'.
  CHECK i_tcode     EQ 'QA12'.

  DESCRIBE TABLE t_ud_longtext LINES lv_lines.

  LOOP AT t_ud_longtext ASSIGNING <ls_ud_ltxt>
    WHERE tdline CS TEXT-k05.
* Nur die letzte Zeile soll angepasst werden
    IF sy-tabix = lv_lines.
      e_exit_activ = 'X'.
      REPLACE TEXT-k05 WITH TEXT-k95 INTO <ls_ud_ltxt>.
    ENDIF.
  ENDLOOP.
