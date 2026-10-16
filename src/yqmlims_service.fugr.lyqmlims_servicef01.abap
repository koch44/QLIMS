*----------------------------------------------------------------------*
***INCLUDE LYQMLIMS_SERVICEF01.
*----------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&      Form  GET_ACTIVITIES_AND_LIST
*&---------------------------------------------------------------------*
FORM get_activities_and_list USING iv_dummy10_tmp.

  DATA: lv_tablines TYPE i,
        lv_tarif    TYPE cost-tkg001.

* Refresh der internen Tabelle der moeglichen Leistungsarten
  CLEAR gt_csla.
  CLEAR gs_csla.

* Ermittlung aller zulaessigen Leistungsarten
  SELECT lstar, datbi FROM csla
      INTO @DATA(ls_csla)
      WHERE kokrs EQ @gv_kokrs
        AND datbi GE @sy-datum
        AND sprkz NE 'X'.              "nicht gesperrt
    IF ls_csla-lstar CP iv_dummy10_tmp.     "sucht String ohne *
      gs_csla-lsttext+1(6) = ls_csla-lstar.
      WRITE ls_csla-datbi TO gs_csla-lsttext+29(10).
* Existiert eine Zuordnung zur Kostenstelle im aktuellen Geschaeftsjahr
      SELECT SINGLE objnr FROM cssl
        INTO @DATA(lv_cssl_objnr)
        WHERE kokrs EQ @gv_kokrs
          AND kostl EQ @gv_kostl
          AND lstar EQ @ls_csla-lstar
          AND gjahr EQ @sy-datum+0(4).
      IF sy-subrc NE 0.                "keine Zuordnung vorhanden
        CONTINUE.
      ENDIF.
* Ermittlung Text zur Leistungsart
      SELECT ktext FROM cslt
        INTO @DATA(lv_cslt_ktext)
        WHERE spras EQ @sy-langu
          AND kokrs EQ @gv_kokrs
          AND lstar EQ @ls_csla-lstar
          AND datbi EQ @ls_csla-datbi.
        gs_csla-lsttext+8(20) = lv_cslt_ktext.
* kein exit nach ersten Satz, da neuere Eintraege vorhanden sein koennt.
      ENDSELECT.
      IF sy-subrc <> 0.
        CLEAR lv_cslt_ktext.
      ENDIF.
* Ermittlung Tarif der Leistungsart zur Kostenstelle
      SELECT tkg001, tkg002, tkg003, tkg004, tkg005, tkg006,
             tkg007, tkg008, tkg009, tkg010, tkg011, tkg012 FROM cost
          INTO @DATA(ls_cost)
          WHERE objnr EQ @lv_cssl_objnr
            AND gjahr EQ @sy-datum+0(4)
            AND versn EQ '000'.
        CASE sy-datum+4(2).
          WHEN '01'.
            lv_tarif = ls_cost-tkg001.
          WHEN '02'.
            lv_tarif = ls_cost-tkg002.
          WHEN '03'.
            lv_tarif = ls_cost-tkg003.
          WHEN '04'.
            lv_tarif = ls_cost-tkg004.
          WHEN '05'.
            lv_tarif = ls_cost-tkg005.
          WHEN '06'.
            lv_tarif = ls_cost-tkg006.
          WHEN '07'.
            lv_tarif = ls_cost-tkg007.
          WHEN '08'.
            lv_tarif = ls_cost-tkg008.
          WHEN '09'.
            lv_tarif = ls_cost-tkg009.
          WHEN '10'.
            lv_tarif = ls_cost-tkg010.
          WHEN '11'.
            lv_tarif = ls_cost-tkg011.
          WHEN '12'.
            lv_tarif = ls_cost-tkg012.
        ENDCASE.
        WRITE lv_tarif TO gs_csla-lsttext+40(16).  "Anzeige-Konvertierung
        gs_csla-lsttext+57(5) = gv_waers.
        EXIT.
      ENDSELECT.
      IF sy-subrc NE 0.                "kein Tarif gefunden
        gs_csla-lsttext+40(20) = TEXT-011.
      ENDIF.
      APPEND gs_csla TO gt_csla.
    ENDIF.
  ENDSELECT.

  IF  sy-subrc = 0.
* Check, ob Leistungsarten gefunden, wenn nicht --> Meldung
    ASSERT lines( gt_csla ) = lv_tablines.
    IF lv_tablines EQ 0.                    "Keine Leistungsarten vorhanden
      MESSAGE e733(yqmlims).
    ELSE.
* Ausgabe eine Liste der moeglichen Leistungsarten
      CALL SCREEN '0100'
        STARTING AT 20  1
        ENDING   AT 82 20.
    ENDIF.
  ELSE.
    MESSAGE e733(yqmlims).
  ENDIF.

ENDFORM.                               " GET_ACTIVITIES_AND_LIST

*&---------------------------------------------------------------------*
*&      Form  CHECK_COST_CENTER
*&---------------------------------------------------------------------*
FORM check_cost_center.
  IF gv_ok_code EQ 'ENTR'.                "nur bei Weiter checken
    SELECT SINGLE waers FROM csks
      INTO gv_waers
      WHERE kokrs EQ gv_kokrs
        AND kostl EQ gv_kostl
        AND datbi GE sy-datum.
    IF sy-subrc NE 0.                  "Kostenstelle nicht gefunden
      MESSAGE e719(yqmlims) WITH gv_kostl gv_kokrs.
    ENDIF.
  ENDIF.

ENDFORM.                               " CHECK_COST_CENTER

*&---------------------------------------------------------------------*
*&      Form  LIST_OUTPUT
*&---------------------------------------------------------------------*
FORM list_output.
  DATA: lv_on(1) TYPE c VALUE 'X'.
  NEW-PAGE NO-TITLE.
  FORMAT COLOR COL_NORMAL.
  LOOP AT gt_csla INTO gs_csla.
    IF lv_on EQ 'X'.
      FORMAT INTENSIFIED ON.
      CLEAR lv_on.
    ELSE.
      FORMAT INTENSIFIED OFF.
      lv_on = 'X'.
    ENDIF.
    WRITE: / gs_csla-lsttext.
  ENDLOOP.
ENDFORM.                               " LIST_OUTPUT

* AT LINE_SELECTION
AT LINE-SELECTION.
  GET CURSOR "FIELD gv_cursorfield         "Inhalt des Auswahl ermitteln
             VALUE gv_field_value.
  IF sy-subrc EQ 0.
    gv_sel_lstar = gv_field_value+1(6).
  ENDIF.
  LEAVE LIST-PROCESSING.               "List-Screen verlassen
*&---------------------------------------------------------------------*
*& Module HTML_CONTROL OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE html_control OUTPUT.

  PERFORM pbo_html_control.

ENDMODULE.
*&---------------------------------------------------------------------*
*& Form pbo_html_control
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM pbo_html_control .

  DATA lt_excl_fcode TYPE STANDARD TABLE OF sy-ucomm.

  IF gv_approve IS INITIAL.
    APPEND 'REJECT'     TO lt_excl_fcode.
    APPEND 'ACCEPT'     TO lt_excl_fcode.
    APPEND 'ACCEPT_KMV' TO lt_excl_fcode.
  ENDIF.

  IF gs_mara-labor <> 'LEG'.
    APPEND 'ACCEPT_KMV' TO lt_excl_fcode.
  ENDIF.

  SET PF-STATUS '0300' EXCLUDING lt_excl_fcode.
  SET TITLEBAR  '0300'.

  " Container
  IF gv_pdf_my_container IS INITIAL.
    CREATE OBJECT gv_pdf_my_container
      EXPORTING
        container_name = 'HTML'
      EXCEPTIONS
        OTHERS         = 1.
    IF sy-subrc <> 0.
      RAISE cntl_error.
    ENDIF.
  ENDIF.

  " HTML-Control
  IF gv_pdf_html_control IS INITIAL.
    CREATE OBJECT gv_pdf_html_control
      EXPORTING
        parent = gv_pdf_my_container
      EXCEPTIONS
        OTHERS = 1.
    IF sy-subrc <> 0.
      RAISE cntl_error.
    ENDIF.

    gv_pdf_alignment = gv_pdf_html_control->align_at_left  +
                    gv_pdf_html_control->align_at_right +
                    gv_pdf_html_control->align_at_top   +
                    gv_pdf_html_control->align_at_bottom.

    gv_pdf_html_control->set_alignment(
      EXPORTING
        alignment = gv_pdf_alignment
      EXCEPTIONS
        OTHERS    = 1 ).

    IF sy-subrc <> 0.
      RAISE cntl_error.
    ENDIF.

    PERFORM pdf_show.
  ENDIF.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form pdf_show
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM pdf_show.

  TYPES lty_pdf_line(1000) TYPE x.

  DATA:
    lv_url      TYPE c LENGTH 80,
    lt_pdf_data TYPE STANDARD TABLE OF lty_pdf_line,
    lv_pdf_line TYPE lty_pdf_line,
    lv_offset   TYPE i,
    lv_len      TYPE i.

  lv_len = xstrlen( gv_pdf_data ).

  WHILE lv_len >= 1000.
    lv_pdf_line = gv_pdf_data+lv_offset(1000).
    APPEND lv_pdf_line TO lt_pdf_data.
    lv_offset += 1000.
    lv_len    -= 1000.
  ENDWHILE.

  IF lv_len > 0.
    lv_pdf_line = gv_pdf_data+lv_offset(lv_len).
    APPEND lv_pdf_line TO lt_pdf_data.
  ENDIF.

  gv_pdf_html_control->load_data(
    EXPORTING
      url          = 'smart.pdf'
      size         = gv_pdf_size
      type         = 'application'
      subtype      = 'pdf'
    IMPORTING
      assigned_url = lv_url
    CHANGING
      data_table   = lt_pdf_data
    EXCEPTIONS
      OTHERS       = 1 ).

  IF sy-subrc <> 0.
    RAISE cntl_error.
  ENDIF.

  " Daten anzeigen
  gv_pdf_html_control->show_data(
    EXPORTING
      url    = lv_url
    EXCEPTIONS
      OTHERS = 1 ).

  IF sy-subrc <> 0.
    RAISE cntl_error.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form pai_html_control
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM pai_html_control .

  CLEAR: gv_accept,
         gv_accept_kmv,
         gv_reject.

  CASE gv_fcode.
    WHEN gc_fcode_cancel
      OR gc_fcode_enter
      OR gc_fcode_accept
      OR gc_fcode_accept_kmv
      OR gc_fcode_reject.

      IF gv_pdf_html_control IS NOT INITIAL.
        gv_pdf_html_control->free( ).
*        IF sy-subrc <> 0.
*          RAISE cntl_error.
*        ENDIF.
        FREE gv_pdf_html_control.
      ENDIF.

      IF gv_pdf_my_container IS NOT INITIAL.
        gv_pdf_my_container->free( ).
*        IF sy-subrc <> 0.
*          RAISE cntl_error.
*        ENDIF.
        FREE gv_pdf_my_container.
      ENDIF.

      CASE gv_fcode.
        WHEN gc_fcode_accept.
          gv_accept = 'X'.
        WHEN gc_fcode_accept_kmv.
          gv_accept_kmv = 'X'.
        WHEN gc_fcode_reject.
          gv_reject = 'X'.
      ENDCASE.

      LEAVE TO SCREEN 0.

    WHEN OTHERS.
      cl_gui_cfw=>dispatch( ).
*      IF sy-subrc <> 0.
*        RAISE cntl_error.
*      ENDIF.
  ENDCASE.

  CLEAR gv_fcode.

ENDFORM.
