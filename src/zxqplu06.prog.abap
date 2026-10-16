*&---------------------------------------------------------------------*
*& Include          ZXQPLU06
*&---------------------------------------------------------------------*

* Hier werden nur die Felder der Include-Struktur CI_QALS in die QALS
* uebernommen, alle anderen Kunden-Appendfelder wie z. B. ZPTLNR
* werden erst durch die Prueflosfreigabe in die QALS uebernommen

  DATA  lv_name_qals_ktext(32)  TYPE c VALUE '(SAPLQPL1)QALS-KTEXTMAT'.
  FIELD-SYMBOLS <lv_qals_kt>    TYPE any.

  ASSIGN (lv_name_qals_ktext) TO <lv_qals_kt>.
  IF sy-subrc = 0.
    <lv_qals_kt> = gs_qals-ktextmat.
  ENDIF.

* Daten aus Dynpro in Uebergabestruktur stellen
  MOVE-CORRESPONDING gs_qals TO e_qals_cust.
* Datenuebernahme aktivieren
  e_active = 'X'.
