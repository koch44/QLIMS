*----------------------------------------------------------------------*
***INCLUDE ZXTOBO01 .
*----------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&      Module  LOOP_AT_SCREEN OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE loop_at_screen OUTPUT.
  LOOP AT SCREEN.
    IF screen-name CS 'IFLO-YQM'.
      IF gv_activity_type = '3'.
        screen-input = '0'.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.
  ENDLOOP.
ENDMODULE.                             " LOOP_AT_SCREEN  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  read_spezid  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE read_spezid OUTPUT.

  IF NOT iflo-yqm_spezid IS INITIAL.
    SELECT SINGLE * FROM yqm_spez_t
           WHERE spezid = iflo-yqm_spezid.
    IF sy-subrc <> 0.
      CLEAR yqm_spez_t.
    ENDIF.
  ELSE.
    CLEAR yqm_spez_t.
  ENDIF.

ENDMODULE.                 " read_spezid  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  READ_PRGGSTD  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE read_prggstd OUTPUT.

  IF NOT iflo-yqm_prggstd IS INITIAL.
    SELECT SINGLE * FROM yqm_prggstd_t
           WHERE prggstd = iflo-yqm_prggstd.
    IF sy-subrc <> 0.
      MESSAGE e620(yqmlims) WITH iflo-yqm_prggstd.
      CLEAR iflo-yqm_prggstd.
      CLEAR yqm_prggstd_t.
    ENDIF.
  ELSE.
    CLEAR yqm_prggstd_t.
  ENDIF.

ENDMODULE.
*&---------------------------------------------------------------------*
*& Module STATUS_1004 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_1004 OUTPUT.
*--------------------------------------Feldauswahlsteuerung.............
* Inhalt gv_activity_type: '1' = Stammsatz wird angelegt
*                          '2' = Stammsatz wird geändert
*                          '3' = Stammsatz wird angezeigt
*--------------------------------------Felder Anzeigen nach Gruppen.....

  LOOP AT SCREEN.
"Felder für Anlagennummer zum TP soll nur bei TP des werks 1100 angezeigt werden
    IF screen-group1 = 'KBW'.
      IF iflo-swerk = '1100'.
        IF gv_activity_type = '3'.
          screen-input = '0'.
          MODIFY SCREEN.
        ENDIF.
      ELSE.
        screen-active = '0'.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.

"Felder für Messtellenbetrieb werden nur für den Equi-Typ G angezeigt
    IF screen-group1 = 'MSB'.                               "KE01102017
      IF equi-eqtyp = 'G'.                                  "KE01102017
        IF gv_activity_type = '3'.                          "KE01102017
          screen-input = '0'.                         "KE01102017
          MODIFY SCREEN.                                    "KE01102017
        ENDIF.                                              "KE01102017
      ELSE.                                                 "KE01102017
        screen-active = '0'.                                "KE01102017
        MODIFY SCREEN.                                      "KE01102017
      ENDIF.                                                "KE01102017
    ENDIF.                                                  "KE01102017

  ENDLOOP.

ENDMODULE.                 " mmint_1004_o01  OUTPUT

FORM m_bel_gettxtanfnr USING iv_sernr TYPE gernr
                             iv_matnr TYPE matnr
                       CHANGING cv_mblnr TYPE mblnr.

  CONSTANTS: lc_s TYPE c VALUE 'S',            "Verwendung OL - Serialnr
             lc_k TYPE c VALUE 'K'.            "Verwendung OL - Wartungsvertrag

  DATA: lv_equi_nr TYPE riserx1-equnr.

  CLEAR: cv_mblnr.

  CALL FUNCTION 'SERIAL_NOT_UNIQUE'
    EXPORTING
      material  = iv_matnr
      serial    = iv_sernr
    IMPORTING
      equipment = lv_equi_nr
    EXCEPTIONS
      not_found = 01.

  IF sy-subrc <> 0 OR lv_equi_nr IS INITIAL.
    RETURN.
  ENDIF.

  "Es werden alle Objektlisten zur Serialnummer selektiert.
  SELECT obknr, obzae, objvw, taser FROM objk INTO TABLE @DATA(lt_intobjk)
           WHERE equnr = @lv_equi_nr.
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  LOOP AT lt_intobjk ASSIGNING FIELD-SYMBOL(<ls_intobjk>).

    DATA(lv_flag) = abap_false.
    DATA(ls_rserxx) = VALUE rserxx( ).

    IF <ls_intobjk>-objvw = lc_s OR <ls_intobjk>-objvw = lc_k.

      CASE <ls_intobjk>-taser.

        WHEN 'SER01'. "Lieferungen zur Serialnummer
          SELECT SINGLE * FROM ser01 INTO @DATA(ls_ser01)
            WHERE obknr = @<ls_intobjk>-obknr.
          IF sy-subrc IS INITIAL.
            lv_flag = abap_true.
            MOVE-CORRESPONDING ls_ser01 TO ls_rserxx.
          ENDIF.

        WHEN 'SER02'. "SD-Aufträge zu Serialnummern
          SELECT SINGLE * FROM ser02 INTO @DATA(ls_ser02)
            WHERE obknr = @<ls_intobjk>-obknr.
          IF sy-subrc IS INITIAL.
            lv_flag = abap_true.
            MOVE-CORRESPONDING ls_ser02 TO ls_rserxx.
          ENDIF.

        WHEN 'SER03'. "Materialbelege zu Serialnummern
          SELECT SINGLE * FROM ser03 INTO @DATA(ls_ser03)
            WHERE obknr = @<ls_intobjk>-obknr.
          IF sy-subrc IS INITIAL.
            lv_flag = abap_true.
            MOVE-CORRESPONDING ls_ser03 TO ls_rserxx.
          ENDIF.

        WHEN 'SER04'. "Prüflose zu Serialnummern
          SELECT SINGLE  * FROM ser04 INTO @DATA(ls_ser04)
                    WHERE obknr = @<ls_intobjk>-obknr.
          IF sy-subrc IS INITIAL.
            lv_flag = abap_true.
            MOVE-CORRESPONDING ls_ser04 TO ls_rserxx.
          ENDIF.

        WHEN 'SER07'. "Inventurbelege
          SELECT SINGLE * FROM ser07 INTO @DATA(ls_ser07)
                     WHERE obknr = @<ls_intobjk>-obknr.
          IF sy-subrc IS INITIAL.
            lv_flag = abap_true.
            MOVE-CORRESPONDING ls_ser07 TO ls_rserxx.
          ENDIF.

        WHEN OTHERS.

      ENDCASE.

    ENDIF.

    CASE <ls_intobjk>-objvw.

      WHEN 'A'.

        SELECT SINGLE * FROM viaufkst INTO @DATA(ls_viaufkst)
          WHERE obknr = @<ls_intobjk>-obknr.

        IF sy-subrc = 0.
          lv_flag = abap_true.
          ls_rserxx-pmaufnr = ls_viaufkst-aufnr.
          ls_rserxx-datum   = ls_viaufkst-erdat.
          ls_rserxx-uzeit   = ls_viaufkst-erfzeit.
        ENDIF.

      WHEN 'W'.

        SELECT SINGLE * FROM mpos INTO @DATA(ls_mpos)
          WHERE obknr = @<ls_intobjk>-obknr.
        IF sy-subrc = 0.
          lv_flag = abap_true.
          ls_rserxx-wapos = ls_mpos-wapos.
          ls_rserxx-datum = ls_mpos-ersdt.
        ENDIF.

      WHEN OTHERS.

    ENDCASE.

    "Eintrag gefunden -> ja -> Append da_sertab
    IF lv_flag = abap_true.
      cv_mblnr = ls_rserxx-mblnr.
    ENDIF.

  ENDLOOP.

ENDFORM.
