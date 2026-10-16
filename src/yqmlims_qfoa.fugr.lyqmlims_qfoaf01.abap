*----------------------------------------------------------------------*
***INCLUDE LYQMLIMS_QFOAF01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  fill_text_field
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_TEXT       zu bergebender Text
*      -->P_FIELDNAME  Feldname
*----------------------------------------------------------------------*
FORM fill_text_field USING    iv_text
                              iv_fieldname.

  DATA: lv_ftext(40)  TYPE c.
  DATA: lv_count      TYPE c.

  CALL METHOD OF
      gv_file
      'FormFields' = gv_field
      NO
      FLUSH

    EXPORTING
      #1           = iv_fieldname.

  SET PROPERTY OF gv_field 'Result' = iv_text NO FLUSH.
  FREE OBJECT gv_field.

  DO 3 TIMES.
    lv_count = sy-index.
    CONCATENATE iv_fieldname lv_count INTO lv_ftext.
    CALL METHOD OF
        gv_file
        'FormFields' = gv_field
        NO
        FLUSH

      EXPORTING
        #1           = lv_ftext.

    SET PROPERTY OF gv_field 'Result' = iv_text NO FLUSH.
    FREE OBJECT gv_field.
  ENDDO.

ENDFORM.                    " fill_text_field
*&---------------------------------------------------------------------*
*&      Form  RECEIVE_TEXT_FROM_OCX
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_GT_LTXT  text
*      -->P_0009   text
*----------------------------------------------------------------------*
FORM receive_text_from_ocx  USING iv_save.

  DATA:
    lv_name     TYPE thead-tdname,
    lv_langu    TYPE sy-langu,
    lv_tdobject TYPE thead-tdobject,
    lv_txtid    TYPE ttxid-tdid,
    lv_subrc    TYPE sy-subrc,
    lv_textline LIKE LINE OF gt_selected_text,
    ls_ltxt     TYPE tline.

*--- Bei Anzeigemodus keine Änderungen übernehmen --------------------*
  IF gv_aktyp = 'A'.
    RETURN.
  ENDIF.

  CLEAR:
    gt_selected_text,
    gt_ltxt.

*--- Text zeilenweise aus dem Control lesen --------------------------*
  CALL METHOD gv_edit->get_text_as_r3table
    EXPORTING
      only_when_modified     = cl_gui_textedit=>false
    IMPORTING
      table                  = gt_selected_text
    EXCEPTIONS
      error_dp               = 1
      error_cntl_call_method = 2
      error_dp_create        = 3
      potential_data_loss    = 4
      OTHERS                 = 5.

  lv_subrc = sy-subrc.

*--- Gepufferte Control-Aufrufe an das Frontend senden ---------------*
  CALL METHOD cl_gui_cfw=>flush
    EXCEPTIONS
      cntl_system_error = 1
      cntl_error        = 2
      OTHERS            = 3.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

*--- Potential data loss wird toleriert ------------------------------*
  IF lv_subrc <> 0 AND lv_subrc <> 4.
    RETURN.
  ENDIF.

*---------------------------------------------------------------------*
* Editorzeilen direkt in SAPscript-ITF-Zeilen übertragen.
*
* Jede Zeile des Text-Controls wird als eigener Standardabsatz
* gespeichert. Dadurch bleiben auch Leerzeilen und Zeilenumbrüche
* erhalten.
*---------------------------------------------------------------------*
  CLEAR gt_ltxt.

  LOOP AT gt_selected_text INTO lv_textline.

    CLEAR ls_ltxt.

    ls_ltxt-tdformat = '*'.
    ls_ltxt-tdline   = lv_textline.

*--- Unerwünschte Maskierungszeichen entfernen -----------------------*
    REPLACE ALL OCCURRENCES OF '<(>'
      IN ls_ltxt-tdline
      WITH ''.

    REPLACE ALL OCCURRENCES OF '<)>'
      IN ls_ltxt-tdline
      WITH ''.

    APPEND ls_ltxt TO gt_ltxt.

  ENDLOOP.

*--- Globale Arbeitsstruktur bei Bedarf synchronisieren --------------*
  CLEAR gs_ltxt.

*--- Nur speichern, wenn angefordert ---------------------------------*
  IF iv_save <> 'X'.
    RETURN.
  ENDIF.

  lv_tdobject = 'QPRUEFLOS'.
  lv_txtid    = 'QAVE'.
  lv_langu    = sy-langu.

  CONCATENATE
    sy-mandt
    gs_qals-prueflos
    'L'
    INTO lv_name.

  CLEAR gs_headltx.

  gs_headltx-tdobject = lv_tdobject.
  gs_headltx-tdid     = lv_txtid.
  gs_headltx-tdspras  = lv_langu.
  gs_headltx-tdname   = lv_name.

*--- Text speichern --------------------------------------------------*
  CALL FUNCTION 'SAVE_TEXT'
    EXPORTING
      header          = gs_headltx
      savemode_direct = 'X'
    TABLES
      lines           = gt_ltxt
    EXCEPTIONS
      id              = 1
      language        = 2
      name            = 3
      object          = 4
      OTHERS          = 5.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  COMMIT WORK AND WAIT.

ENDFORM.                    " RECEIVE_TEXT_FROM_OCX

*&---------------------------------------------------------------------*
*&      Form  CREATE_AND_INIT_CONTROLS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
*FORM create_and_init_controls .

FORM create_and_init_controls .

  DATA: lv_text TYPE text100.

  gv_repid = sy-repid.


*---------------------------------------------------------------------*
* Fall 1: Kein Editor
*---------------------------------------------------------------------*
  IF gv_no_editor = 'X'.

*   Hauptcontainer
    CREATE OBJECT gv_docking_container_2
      EXPORTING
        repid     = gv_repid
        dynnr     = '200'
        extension = 400
        side      = cl_gui_docking_container=>dock_at_top.

*   ALV direkt in den Hauptcontainer
    CREATE OBJECT gv_alv
      EXPORTING
        i_parent = gv_docking_container_2.

    CONCATENATE TEXT-104
                gs_qals-prueflos
                ' - '
                gs_qals-ktextmat
           INTO lv_text
           SEPARATED BY space.


*---------------------------------------------------------------------*
* Fall 2: ALV + Editor
*---------------------------------------------------------------------*
  ELSE.

*   Nur noch EIN Docking Container
    CREATE OBJECT gv_docking_container_2
      EXPORTING
        repid     = gv_repid
        dynnr     = '200'
        extension = 800
        side      = cl_gui_docking_container=>dock_at_top.


*   Hauptcontainer in zwei Zeilen teilen
*   Zeile 1 = ALV
*   Zeile 2 = Texteditor
    CREATE OBJECT gv_splitter
      EXPORTING
        parent  = gv_docking_container_2
        rows    = 2
        columns = 1.


*   Container der Splitter-Zellen holen
    gv_container_top =
      gv_splitter->get_container(
        row    = 1
        column = 1 ).

    gv_container_bottom =
      gv_splitter->get_container(
        row    = 2
        column = 1 ).


*   Größenverhältnis setzen
*   Oberer Bereich größer für ALV
    CALL METHOD gv_splitter->set_row_height
      EXPORTING
        id     = 1
        height = 65.

**   Unterer Bereich für Editor
*    CALL METHOD gv_splitter->set_row_height
*      EXPORTING
*        id     = 2
*        height = 35.


*---------------------------------------------------------------------*
*   ALV
*---------------------------------------------------------------------*
    CREATE OBJECT gv_alv
      EXPORTING
        i_parent = gv_container_top.


*---------------------------------------------------------------------*
*   Editor
*---------------------------------------------------------------------*
    CREATE OBJECT gv_edit
      EXPORTING
        parent                     = gv_container_bottom
        wordwrap_mode              = cl_gui_textedit=>wordwrap_off
        wordwrap_to_linebreak_mode = cl_gui_textedit=>false.


    IF gv_aktyp = 'A'.

*     Control only in display mode if activity type is set to "display"
      CALL METHOD gv_edit->set_readonly_mode
        EXPORTING
          readonly_mode = gc_true.

    ENDIF.


*---------------------------------------------------------------------*
*   Text lesen
*---------------------------------------------------------------------*
    PERFORM read_text USING gs_qals.


*---------------------------------------------------------------------*
*   Application Object
*---------------------------------------------------------------------*
    CREATE OBJECT gv_application.


*---------------------------------------------------------------------*
*   Events ALV
*---------------------------------------------------------------------*
    SET HANDLER gv_application->handle_alv_drag
      FOR gv_alv.

    SET HANDLER gv_application->handle_alv_drop_complete
      FOR gv_alv.


*---------------------------------------------------------------------*
*   Events Editor
*---------------------------------------------------------------------*
    SET HANDLER gv_application->handle_edit_drop
      FOR gv_edit.


*---------------------------------------------------------------------*
*   Drag & Drop konfigurieren
*---------------------------------------------------------------------*
    PERFORM build_handles.


*---------------------------------------------------------------------*
*   Titel
*---------------------------------------------------------------------*
    CONCATENATE TEXT-105
                gs_qals-prueflos
                ' - '
                gs_qals-ktextmat
           INTO lv_text
           SEPARATED BY space.

  ENDIF.


*---------------------------------------------------------------------*
* ALV Layout
*---------------------------------------------------------------------*
  gs_layout-grid_title = lv_text.

  gs_variant-report = sy-repid.


*---------------------------------------------------------------------*
* ALV anzeigen
*---------------------------------------------------------------------*
  CALL METHOD gv_alv->set_table_for_first_display
    EXPORTING
      i_structure_name = 'YQM_RESULTS_DISPLAY'
      i_save           = 'X'
      i_default        = 'X'
      is_variant       = gs_variant
      is_layout        = gs_layout
    CHANGING
      it_outtab        = gt_results.


ENDFORM.                    " CREATE_AND_INIT_CONTROLS
*  DATA: lv_text TYPE text100.
*
*  gv_repid = sy-repid.
*
*  IF gv_no_editor = 'X'.
** create docking container
** create docking container
*    CREATE OBJECT gv_docking_container_2
*      EXPORTING
*        repid     = gv_repid
*        dynnr     = '200'
*        extension = 400
*        side      = cl_gui_docking_container=>dock_at_top.
*
** alv control
*    CREATE OBJECT gv_alv
*      EXPORTING
*        i_parent = gv_docking_container_2.
*
*    CONCATENATE TEXT-104
*                gs_qals-prueflos
*                ' - '
*                gs_qals-ktextmat
*                INTO lv_text
*                SEPARATED BY space.
*
*  ELSE.
** create docking container
*    CREATE OBJECT gv_docking_container_1
*      EXPORTING
*        repid     = gv_repid
*        dynnr     = '200'
*        extension = 200
*        side      = cl_gui_docking_container=>dock_at_bottom.
*
** create docking container
*    CREATE OBJECT gv_docking_container_2
*      EXPORTING
*        repid     = gv_repid
*        dynnr     = '200'
*        extension = 600
*        side      = cl_gui_docking_container=>dock_at_top.
*
** alv control
*    CREATE OBJECT gv_alv
*      EXPORTING
*        i_parent = gv_docking_container_2.
*
** editor
**    CREATE OBJECT gv_edit
**      EXPORTING
***       wordwrap_mode     = '2'
***       wordwrap_position = '72'
**        parent = gv_docking_container_1.
*    CREATE OBJECT gv_edit
*      EXPORTING
*        parent                     = gv_docking_container_1
*        wordwrap_mode              = cl_gui_textedit=>wordwrap_off
*        wordwrap_to_linebreak_mode = cl_gui_textedit=>false.
*
*    IF gv_aktyp = 'A'.
**--- Control only in display mode if activity type is set to "display" *
*      CALL METHOD gv_edit->set_readonly_mode
*        EXPORTING
*          readonly_mode = gc_true.
*    ENDIF.
*
*    PERFORM read_text USING gs_qals.
*
** create the application object
*    CREATE OBJECT gv_application.
*
** Events alv control
*    SET HANDLER gv_application->handle_alv_drag          FOR gv_alv.
*    SET HANDLER gv_application->handle_alv_drop_complete FOR gv_alv.
*
** Events edit control
*    SET HANDLER gv_application->handle_edit_drop         FOR gv_edit.
*
** describe behaviour of drag&drop
*    PERFORM build_handles.
*
*    CONCATENATE TEXT-105
*                gs_qals-prueflos
*                ' - '
*                gs_qals-ktextmat
*                INTO lv_text
*                SEPARATED BY space.
*
**    CONCATENATE TEXT-105
**                TEXT-102
**                gs_qals-prueflos
**                INTO lv_text
**                SEPARATED BY space.
*
*  ENDIF.
*
*  gs_layout-grid_title = lv_text.
*  gs_variant-report    = sy-repid.
**  gs_variant-log       = 'ALV'.
**  gs_variant-handle    = 'ALV'.
*
*  CALL METHOD gv_alv->set_table_for_first_display
*    EXPORTING
*      i_structure_name = 'YQM_RESULTS_DISPLAY'
*      i_save           = 'X'
*      i_default        = 'X'
*      is_variant       = gs_variant
*      is_layout        = gs_layout
*    CHANGING
*      it_outtab        = gt_results.


*ENDFORM.                    " CREATE_AND_INIT_CONTROLS
*&---------------------------------------------------------------------*
*&      Form  BUILD_HANDLES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM build_handles .

  DATA: lv_effect     TYPE i,
        lv_handle_alv TYPE i.


  CREATE OBJECT gv_behaviour_edit.
  lv_effect = cl_dragdrop=>move + cl_dragdrop=>copy.

  CALL METHOD gv_behaviour_edit->add
    EXPORTING
      flavor     = 'Line'                                   "#EC NOTEXT
      dragsrc    = ' '
      droptarget = 'X'
      effect     = lv_effect.

  CALL METHOD gv_behaviour_edit->get_handle.

  CREATE OBJECT gv_behaviour_alv.
  lv_effect = cl_dragdrop=>move + cl_dragdrop=>copy.
  CALL METHOD gv_behaviour_alv->add
    EXPORTING
      flavor     = 'Line'
      dragsrc    = 'X'
      droptarget = ' '
      effect     = lv_effect.

  CALL METHOD gv_behaviour_alv->get_handle
    IMPORTING
      handle = lv_handle_alv.

  CALL METHOD gv_edit->set_dragdrop
    EXPORTING
      dragdrop = gv_behaviour_edit.

  gs_layout-s_dragdrop-row_ddid = lv_handle_alv.

ENDFORM.                    " BUILD_HANDLES
*&---------------------------------------------------------------------*
*&      Form  READ_TEXT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_GS_QALS  text
*----------------------------------------------------------------------*
FORM read_text  USING    is_qals TYPE qals.

  DATA: lv_langu          TYPE sy-langu.
  DATA: lv_name           TYPE thead-tdname.
  DATA: lv_tdobject       TYPE thead-tdobject.
  DATA: lv_txtid          TYPE ttxid-tdid.
  DATA: lt_lines          TYPE TABLE OF tline.
  DATA: ls_textline(72)   TYPE c.
  DATA: lt_texttable      LIKE TABLE OF ls_textline.

  lv_tdobject = 'QPRUEFLOS'.
  lv_txtid    = 'QAVE'.
  lv_langu    = sy-langu.

  CONCATENATE sy-mandt is_qals-prueflos 'L' INTO lv_name.

*--- Read text -------------------------------------------------------*
  CALL FUNCTION 'READ_TEXT'
    EXPORTING
      id                      = lv_txtid
      language                = lv_langu
      name                    = lv_name
      object                  = lv_tdobject
    IMPORTING
      header                  = gs_headltx
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
  IF sy-subrc = 0.
    CALL FUNCTION 'CONVERT_ITF_TO_STREAM_TEXT'
      TABLES
        itf_text    = lt_lines
        text_stream = lt_texttable.

  ELSE.
    CALL FUNCTION 'CONVERT_ITF_TO_STREAM_TEXT'
      TABLES
        itf_text    = gt_lines
        text_stream = lt_texttable.
  ENDIF.

  CLEAR gv_string.

  LOOP AT lt_texttable INTO ls_textline.
    CONCATENATE gv_string ls_textline INTO gv_string.
  ENDLOOP.

* and send text to note editor
  CALL METHOD gv_edit->set_textstream
    EXPORTING
      text = gv_string.

*  CALL METHOD gv_edit->set_text_as_r3table
*    EXPORTING
*      table = lt_texttable.

ENDFORM.                    " READ_TEXT
*&---------------------------------------------------------------------*
*&      Form  FLTP_CHAR_CONVERSION
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_GS_RESULTS  text
*----------------------------------------------------------------------*
FORM fltp_char_conversion  CHANGING cs_results TYPE yqm_results_display.

  DATA: lv_stellen     TYPE qstellen.
  DATA: lv_stellen_tol TYPE qstellen.

  TRY.
      lv_stellen     = cs_results-stellen + cs_results-diff_dec_places.
    CATCH cx_sy_arithmetic_error.
      lv_stellen = 0.
  ENDTRY.

  TRY.
      lv_stellen_tol = cs_results-stellen + cs_results-zztoloben_diff_dec_places.
    CATCH cx_sy_arithmetic_error.
      lv_stellen_tol = 0.
  ENDTRY.


  CALL FUNCTION 'QSS0_FLTP_TO_CHAR_CONVERSION'
    EXPORTING
      i_number_of_digits       = lv_stellen
      i_fltp_value             = cs_results-sollwert
      i_value_not_initial_flag = cs_results-sollwni
      i_screen_fieldlength     = 16
    IMPORTING
      e_char_field             = cs_results-sollwertc.

  CALL FUNCTION 'QSS0_FLTP_TO_CHAR_CONVERSION'
    EXPORTING
      i_number_of_digits       = lv_stellen_tol
      i_fltp_value             = cs_results-toleranzob
      i_value_not_initial_flag = cs_results-tolobni
      i_screen_fieldlength     = 16
    IMPORTING
      e_char_field             = cs_results-toleranzobc.

  CALL FUNCTION 'QSS0_FLTP_TO_CHAR_CONVERSION'
    EXPORTING
      i_number_of_digits       = lv_stellen
      i_fltp_value             = cs_results-toleranzun
      i_value_not_initial_flag = cs_results-tolunni
      i_screen_fieldlength     = 16
    IMPORTING
      e_char_field             = cs_results-toleranzunc.

  CALL FUNCTION 'QSS0_FLTP_TO_CHAR_CONVERSION'
    EXPORTING
      i_number_of_digits       = lv_stellen
      i_fltp_value             = cs_results-grenzeob1
      i_value_not_initial_flag = cs_results-grenzob1ni
      i_screen_fieldlength     = 16
    IMPORTING
      e_char_field             = cs_results-grenzeob1c.

  CALL FUNCTION 'QSS0_FLTP_TO_CHAR_CONVERSION'
    EXPORTING
      i_number_of_digits       = lv_stellen
      i_fltp_value             = cs_results-grenzeun1
      i_value_not_initial_flag = cs_results-grenzun1ni
      i_screen_fieldlength     = 16
    IMPORTING
      e_char_field             = cs_results-grenzeun1c.

  CALL FUNCTION 'QSS0_FLTP_TO_CHAR_CONVERSION'
    EXPORTING
      i_number_of_digits       = lv_stellen
      i_fltp_value             = cs_results-grenzeob2
      i_value_not_initial_flag = cs_results-grenzob2ni
      i_screen_fieldlength     = 16
    IMPORTING
      e_char_field             = cs_results-grenzeob2c.

  CALL FUNCTION 'QSS0_FLTP_TO_CHAR_CONVERSION'
    EXPORTING
      i_number_of_digits       = lv_stellen
      i_fltp_value             = cs_results-grenzeun2
      i_value_not_initial_flag = cs_results-grenzun2ni
      i_screen_fieldlength     = 16
    IMPORTING
      e_char_field             = cs_results-grenzeun2c.

  CALL FUNCTION 'QSS0_FLTP_TO_CHAR_CONVERSION'
    EXPORTING
      i_number_of_digits       = lv_stellen
      i_fltp_value             = cs_results-plausioben
      i_value_not_initial_flag = cs_results-plausiobni
      i_screen_fieldlength     = 16
    IMPORTING
      e_char_field             = cs_results-plausiobenc.

  CALL FUNCTION 'QSS0_FLTP_TO_CHAR_CONVERSION'
    EXPORTING
      i_number_of_digits       = lv_stellen
      i_fltp_value             = cs_results-plausiunte
      i_value_not_initial_flag = cs_results-plausiunni
      i_screen_fieldlength     = 16
    IMPORTING
      e_char_field             = cs_results-plausiuntec.

  CALL FUNCTION 'QSS0_FLTP_TO_CHAR_CONVERSION'
    EXPORTING
      i_number_of_digits       = lv_stellen
      i_fltp_value             = cs_results-mittelwert
      i_value_not_initial_flag = cs_results-mittelwni
      i_screen_fieldlength     = 16
    IMPORTING
      e_char_field             = cs_results-mittelwertc.

ENDFORM.                    " FLTP_CHAR_CONVERSION
*&---------------------------------------------------------------------*
*&      Form  ERMITTLUNG_WAEHRUNG
*&---------------------------------------------------------------------*
*       Waehrung der Kostenstelle ermitteln
*----------------------------------------------------------------------*
FORM ermittlung_waehrung .

  CLEAR gs_cost_header-waers.

  SELECT SINGLE waers
    FROM csks
    WHERE kokrs = @gv_kokrs
      AND kostl = @gv_kostl
      AND datbi >= @sy-datum
    INTO @gs_cost_header-waers.
  IF sy-subrc <> 0.
    CLEAR gs_cost_header-waers.
  ENDIF.

ENDFORM.                    " ERMITTLUNG_WAEHRUNG

*&---------------------------------------------------------------------*
*&      Form  lesen_abr_auftraege
*&---------------------------------------------------------------------*
*       Spezielle Abrechnungsauftraege lesen
*       Wenn im Technischen Platz ein Dauerauftrag vorhanden ist,
*       dann wird dieser anstelle des Serviceauftrages fuer die
*       Abrechnungs herangezogen
*----------------------------------------------------------------------*
FORM lesen_abr_auftraege.

* Hilfsvariable fuer Dauerauftrag
  DATA: lv_dauftrag TYPE iflo-daufn.

*   Dauerauftrag aus Techn. Platz ermitteln
  SELECT SINGLE daufn
    INTO lv_dauftrag
    FROM iflo
    WHERE tplnr EQ gs_qals-yqm_tplnr
      AND spras EQ sy-langu.

*   Wenn Eintrag gefunden --> Uebernahme in I_PRUEFLOS
  IF sy-subrc EQ 0 AND NOT ( lv_dauftrag IS INITIAL ).
    gs_cost_header-dauer_auftr = lv_dauftrag.   "Dauerauftrag
  ENDIF.

ENDFORM.                    " lesen_abr_auftraege
*&---------------------------------------------------------------------*
*&      Form  lesen_kostentabellen
*&---------------------------------------------------------------------*
*       Uebernahme der Kostentabelle ZQMKOSTEN1 und ZQMKOSTEN2 in
*       interne Tabellen
*----------------------------------------------------------------------*
FORM lesen_kostentabellen.

  CLEAR:   gt_kosten4.
  CLEAR: gt_kosten4.

* Tabelle der Kosten auf Ebene Material/Kunde/TP lesen
  SELECT *
    INTO CORRESPONDING FIELDS OF TABLE gt_kosten4
    FROM yqm_kosten4_t
    WHERE aktiv          EQ 'X'
    OR    var_menge_flag EQ 'X'.
  IF sy-subrc = 0.
    SORT gt_kosten4.
  ENDIF.

ENDFORM.                    " lesen_kostentabellen
*&---------------------------------------------------------------------*
*&      Form  ERMITTELN_KOSTENQUELLE
*&---------------------------------------------------------------------*
*       Ermittlung, wie die lv_pruefkosten zu berechnen sind und
*       Fortschreibung in interner Tabelle
*----------------------------------------------------------------------*
FORM ermitteln_kostenquelle .

*   Fall 1: Kosten (LstArt) direkt zum Material/Kunde/Technischer Platz hinterlegt
  READ TABLE gt_kosten4 INTO gs_kosten4
                        WITH KEY matnr = gs_qals-matnr
                                 kunnr = gs_qals-kunnr
                                 tplnr = gs_qals-yqm_tplnr
                                 BINARY SEARCH.
  IF sy-subrc = 0.
    IF gs_kosten4-aktiv = 'X'.
      gs_cost_header-kostenquelle   = 'T'.   "Kosten auf Ebene Material/Kunde/Technischer Platz
    ELSE.
      gs_cost_header-kostenquelle   = 'M'.   "Kosten auf Merkmalsebene
    ENDIF.
    gs_cost_header-lstar          = gs_kosten4-lstar.
    gs_cost_header-menge          = gs_kosten4-menge.
    gs_cost_header-meins          = gs_kosten4-meins.
    gs_cost_header-var_menge_flag = gs_kosten4-var_menge_flag.
    gs_cost_header-alt_lstar      = gs_kosten4-alt_lstar.
    EXIT.
  ENDIF.

*   Fall 2: Kosten (LstArt) direkt zum Material/Kunde hinterlegt
  READ TABLE gt_kosten4 INTO gs_kosten4
                        WITH KEY matnr = gs_qals-matnr
                                 kunnr = gs_qals-kunnr
                                 tplnr = space
                                 BINARY SEARCH.
  IF sy-subrc = 0.
    IF gs_kosten4-aktiv = 'X'.
      gs_cost_header-kostenquelle   = 'K'.   "Kosten auf Ebene Material/Kunde
    ELSE.
      gs_cost_header-kostenquelle   = 'M'.   "Kosten auf Merkmalsebene
    ENDIF.
    gs_cost_header-lstar          = gs_kosten4-lstar.
    gs_cost_header-menge          = gs_kosten4-menge.
    gs_cost_header-meins          = gs_kosten4-meins.
    gs_cost_header-var_menge_flag = gs_kosten4-var_menge_flag.
    gs_cost_header-alt_lstar      = gs_kosten4-alt_lstar.
    EXIT.
  ENDIF.

*   Fall 3: Kosten (LstArt) direkt zum Material hinterlegt
  READ TABLE gt_kosten4 INTO gs_kosten4
                        WITH KEY matnr = gs_qals-matnr
                                 kunnr = space
                                 tplnr = space
                                 BINARY SEARCH.
  IF sy-subrc = 0.
    IF gs_kosten4-aktiv = 'X'.
      gs_cost_header-kostenquelle   = 'L'.   "Kosten auf Ebene Material
    ELSE.
      gs_cost_header-kostenquelle   = 'M'.   "Kosten auf Merkmalsebene
    ENDIF.
    gs_cost_header-lstar          = gs_kosten4-lstar.
    gs_cost_header-menge          = gs_kosten4-menge.
    gs_cost_header-meins          = gs_kosten4-meins.
    gs_cost_header-var_menge_flag = gs_kosten4-var_menge_flag.
    gs_cost_header-alt_lstar      = gs_kosten4-alt_lstar.
    EXIT.
  ENDIF.

*   Fall 4: Kosten (LstArt) zu Pruefmerkmalen hinterlegt
  IF gs_cost_header-kostenquelle IS INITIAL.
    gs_cost_header-kostenquelle = 'M'.   "Kosten auf Merkmalsebene
  ENDIF.

ENDFORM.                    " ERMITTELN_KOSTENQUELLE
*&---------------------------------------------------------------------*
*&      Form  lesen_merkmalsdaten
*&---------------------------------------------------------------------*
*       Lesen der DB-Tabellen QAMV (Merkmalsvorgaben) und QASR
*       (Merkmalsergebnisse) in interne Tabellen zwecks Performance
*----------------------------------------------------------------------*
FORM lesen_merkmalsdaten.

  CLEAR:   gs_qamv, gs_qasr.
  CLEAR: gt_qamv, gt_qasr.

* Tabelle der Merkmalsvorgaben speichern
  SELECT *
    INTO CORRESPONDING FIELDS OF TABLE gt_qamv
    FROM qamv
    WHERE prueflos  EQ gs_qals-prueflos
    AND   verwmerkm IN gr_merkmal.                          "20230420CF
  IF sy-subrc <> 0.
    CLEAR gt_qamv.
  ENDIF.

* Tabelle der Merkmalsergebnisse speichern
  SELECT *
    INTO CORRESPONDING FIELDS OF TABLE gt_qasr
    FROM qasr
    WHERE prueflos EQ gs_qals-prueflos.
  IF sy-subrc <> 0.
    CLEAR gt_qasr.
  ENDIF.

  SELECT prueflos vorglfnr probenr tplnr phynr FROM qapp
    INTO CORRESPONDING FIELDS OF TABLE gt_qapp
    WHERE prueflos   = gs_qals-prueflos
    AND   vbewertung NE space.
  IF sy-subrc <> 0.
    CLEAR gt_qapp.
  ELSE.
    SORT gt_qapp BY prueflos tplnr phynr.
    DELETE ADJACENT DUPLICATES FROM gt_qapp COMPARING prueflos tplnr phynr.
  ENDIF.

ENDFORM.                    " lesen_merkmalsdaten
*&---------------------------------------------------------------------*
*&      Form  lesen_tarif_daten
*&---------------------------------------------------------------------*
*       Daten zu Kostenstellen/Leistungsarten sowie Tarifdaten in
*       interne Tabellen speichern aus Gruenden der Performance
*----------------------------------------------------------------------*
FORM lesen_tarif_daten.

* Hilfsvariable fuer akt. Geschaeftsjahr bzw. Vorgeschaeftsjahr
  DATA: lv_agjahr TYPE cssl-gjahr,
        lv_vgjahr TYPE cssl-gjahr.

* Hilfstabelle fuer Objektnummern (verschluesselt KOKRS + KOSTL + LSTAR)
  DATA: lr_objekte TYPE RANGE OF cssl-objnr.

  CLEAR: gs_cssl, gs_cost, lr_objekte.
  CLEAR: gt_cssl, gt_cost.

  lv_agjahr = sy-datum+0(4).
  lv_vgjahr = lv_agjahr - 1.

* Tabelle der Kostenstellen/Leistungsarten speichern
  SELECT *
  INTO CORRESPONDING FIELDS OF TABLE gt_cssl
  FROM cssl
  WHERE kokrs EQ gv_kokrs                                   "CF20191206
    AND kostl EQ gv_kostl                                   "CF20191206
    AND ( gjahr EQ lv_agjahr OR gjahr EQ lv_vgjahr ).
  IF sy-subrc <> 0.
    CLEAR gt_cssl.
  ENDIF.

  IF gt_cssl[] IS INITIAL.
    MESSAGE a765(yqmlims).   "Fehler in Kostendaten oder fehlende Daten
  ENDIF.

* Objektnummern (KOKRS + KOSTL + LSTAR) ermitteln und in Range-Tabelle
* fuer weitere Selektion schreiben
  LOOP AT gt_cssl INTO gs_cssl.
    APPEND VALUE #(
      sign   = 'I'
      option = 'EQ'
      low    = gs_cssl-objnr
    ) TO lr_objekte.
  ENDLOOP.


* Tabelle der Tarife speichern
  SELECT *
  INTO CORRESPONDING FIELDS OF TABLE gt_cost
  FROM cost
  WHERE objnr IN lr_objekte
    AND ( gjahr EQ lv_agjahr OR gjahr EQ lv_vgjahr )
    AND versn EQ '000'.
  IF sy-subrc <> 0.
    CLEAR gt_cost.
  ENDIF.

  IF gt_cost[] IS INITIAL.
    MESSAGE a765(yqmlims).   "Fehler in Kostendaten oder fehlende Daten
  ENDIF.

ENDFORM.                    " lesen_tarif_daten
*&---------------------------------------------------------------------*
*&      Form  lesen_lst_arten
*&---------------------------------------------------------------------*
*       Zu allen Prueflosen alle prinzipiell relevanten Leistungsarten
*       ermitteln
*----------------------------------------------------------------------*
FORM lesen_lst_arten.

* Hilfsvariable fuer lfd. Zaehler
  DATA: lv_zaehler TYPE i.

* Hilfsvariable fuer Tarif
  DATA: lv_tarif   TYPE cost-tkg001.
  DATA: lv_unit    TYPE cssl-leinh.

* Interne Tabelle aller Leistungsarten zun den Prueflosen refreshen
  CLEAR gs_lst_arten.
  CLEAR gt_lst_arten.
  CASE gs_cost_header-kostenquelle.
*     Leistungsart(Kosten) laut Plan oder Planendung
    WHEN 'P' OR 'E' OR 'T' OR 'K' OR 'L'.
*       Hauptkosten (aus Plan oder Planendung)
      CLEAR: gs_lst_arten.
      lv_zaehler                = 1.
      gs_lst_arten-prueflos     = gs_qals-prueflos.
      gs_lst_arten-lfdnr        = lv_zaehler.
      gs_lst_arten-kostenart    = 'H'.
      gs_lst_arten-kostenquelle = gs_cost_header-kostenquelle.
      CASE gs_cost_header-kostenquelle.
        WHEN 'P'.
          gs_lst_arten-kurztext   = TEXT-120.
        WHEN 'E'.
          gs_lst_arten-kurztext   = TEXT-121.
        WHEN 'T'.
          gs_lst_arten-kurztext   = TEXT-126.
        WHEN 'K'.
          gs_lst_arten-kurztext   = TEXT-119.
        WHEN 'L'.
          gs_lst_arten-kurztext   = TEXT-118.
      ENDCASE.
      gs_lst_arten-lstar        = gs_cost_header-lstar.
      TRANSLATE gs_lst_arten-lstar TO UPPER CASE.
      IF NOT gs_cost_header-menge IS INITIAL.            " Menge aus ZQMKOSTEN4
        gs_lst_arten-menge      = gs_cost_header-menge.
      ELSE.
        gs_lst_arten-menge      = 1.
      ENDIF.
      gs_lst_arten-meins        = gs_cost_header-meins.
      PERFORM ermitteln_tarif USING    gs_lst_arten-lstar
                                       gs_cost_header-buchdatum
                              CHANGING lv_tarif
                                       lv_unit.
      gs_lst_arten-tarif = lv_tarif.
      APPEND gs_lst_arten TO gt_lst_arten.

  ENDCASE.                                                  "20230420CF

  CLEAR: gs_lst_arten, lv_zaehler.
  gs_lst_arten-prueflos     = gs_qals-prueflos.
  gs_lst_arten-kostenart    = 'H'.
  gs_lst_arten-kostenquelle = 'M'. "gs_cost_header-kostenquelle.
*       Merkmalsvorgaben lesen
  LOOP AT gt_qamv INTO gs_qamv
    WHERE prueflos EQ gs_qals-prueflos.
    lv_zaehler             = lv_zaehler + 1.
    gs_lst_arten = CORRESPONDING #( gs_qamv ).
    gs_lst_arten-lfdnr      = lv_zaehler.
    gs_lst_arten-lstar      = gs_qamv-dummy10.
    TRANSLATE gs_lst_arten-lstar TO UPPER CASE.
    gs_lst_arten-menge      = 1.
    CLEAR gs_lst_arten-satzstatus. "Nicht aus QAMV, sondern QAMR

    PERFORM ermitteln_tarif USING    gs_lst_arten-lstar
                                     gs_cost_header-buchdatum
                            CHANGING lv_tarif
                                     lv_unit.
    gs_lst_arten-tarif = lv_tarif.

*         Status Merkmal ermitteln
    LOOP AT gt_qasr INTO gs_qasr
      WHERE prueflos EQ gs_qamv-prueflos
        AND vorglfnr EQ gs_qamv-vorglfnr
        AND merknr   EQ gs_qamv-merknr.
*            AND probenr  EQ '000001'.
      gs_lst_arten-satzstatus = gs_qasr-satzstatus.
      IF gs_qasr-kzbewertg CA '+./' OR   "Abschluss erzwungen
         gs_qasr-attribut  EQ '('   OR   "Attr. NG (nicht gemessen)
         gs_qasr-attribut  EQ '['.       "Attr. KA (keine Anford.)
*             Normalerweise wird bei NG oder KA der Abschluss eines
*             Merkmal auch erzwungen, aber zur Sicherheit ist obige
*             Abfrage flexibler
        CASE gs_qasr-attribut.
          WHEN '('.
            gs_lst_arten-erzwungen = 'X NG'.
          WHEN '['.
            gs_lst_arten-erzwungen = 'X KA'.
          WHEN OTHERS.
            gs_lst_arten-erzwungen = 'X'.
        ENDCASE.
      ELSE.
        gs_lst_arten-erzwungen = space.
      ENDIF.

*         Bei der Legionellenprfung ist die Anzahl der geprften Proben entscheidend
      IF gs_qals-slwbez = '910'.
        READ TABLE gt_qapp INTO gs_qapp
          WITH KEY prueflos = gs_qasr-prueflos
                   vorglfnr = gs_qasr-vorglfnr
                   probenr  = gs_qasr-probenr.
        IF sy-subrc = 0.
          gs_lst_arten-phynr = gs_qapp-phynr.
        ENDIF.
        APPEND gs_lst_arten TO gt_lst_arten.
      ELSE.
        IF gs_qasr-probenr EQ '000001'.
          APPEND gs_lst_arten TO gt_lst_arten.
          EXIT.
        ELSE.
          EXIT.
        ENDIF.
      ENDIF.

    ENDLOOP.

  ENDLOOP.

  CLEAR gs_lst_arten.


ENDFORM.                    " lesen_lst_arten
*&---------------------------------------------------------------------*
*&      Form  ermitteln_tarif
*&---------------------------------------------------------------------*
*       Tarif der Leistungsart zum Stichtag (Buchungsdatum) ermitteln
*----------------------------------------------------------------------*
FORM ermitteln_tarif USING    iv_lstar
                              iv_buchdatum
                     CHANGING cv_tarif
                              cv_unit.

* Hilfsvariable fuer Geschaeftsjahr des Buchungsdatum sowie Monat
  DATA: lv_agjahr    TYPE cssl-gjahr,
        lv_amonat(2) TYPE c.

* Datum umspeichern
  lv_agjahr = iv_buchdatum+0(4).
  lv_amonat = iv_buchdatum+4(2).

  CLEAR cv_tarif.

* Existiert eine Zuordnung zur Kostenstelle im aktuellen Geschaeftsjahr
  LOOP AT gt_cssl INTO gs_cssl
    WHERE lstar EQ iv_lstar
      AND gjahr EQ lv_agjahr.

*   Ermittlung Tarif der Leistungsart zur Kostenstelle
    LOOP AT gt_cost INTO gs_cost
      WHERE objnr EQ gs_cssl-objnr
        AND gjahr EQ lv_agjahr.

      CASE lv_amonat.
        WHEN '01'.   cv_tarif = gs_cost-tkg001.
        WHEN '02'.   cv_tarif = gs_cost-tkg002.
        WHEN '03'.   cv_tarif = gs_cost-tkg003.
        WHEN '04'.   cv_tarif = gs_cost-tkg004.
        WHEN '05'.   cv_tarif = gs_cost-tkg005.
        WHEN '06'.   cv_tarif = gs_cost-tkg006.
        WHEN '07'.   cv_tarif = gs_cost-tkg007.
        WHEN '08'.   cv_tarif = gs_cost-tkg008.
        WHEN '09'.   cv_tarif = gs_cost-tkg009.
        WHEN '10'.   cv_tarif = gs_cost-tkg010.
        WHEN '11'.   cv_tarif = gs_cost-tkg011.
        WHEN '12'.   cv_tarif = gs_cost-tkg012.
        WHEN OTHERS. CLEAR cv_tarif.
      ENDCASE.
      cv_unit = gs_cssl-leinh.

    ENDLOOP.

  ENDLOOP.


ENDFORM.                    " ERMITTELN_TARIF
*&---------------------------------------------------------------------*
*&      Form  AUFBEREITEN_LSTARTEN
*&---------------------------------------------------------------------*
*       Die Tabelle der relevanten Leistungsarten wird aufbereitet,
*       indem bei mehrfachen Auftreten einer Leistungsart auf Merkmals-
*       ebene diese Leistungsart gekennzeichnet wird
*       Alle fuer die Kostenuebertragung relevanten LstArten werden
*       in einem zweitem Schritt gekennzeichnet
*----------------------------------------------------------------------*
FORM aufbereiten_lstarten .

* Alle fuer die Kostenuebertragung relevanten Eintraege kennzeichnen
  LOOP AT gt_lst_arten INTO gs_lst_arten.

*   Abhaengig von Kostenart
*   Hauptkosten
    IF  gs_lst_arten-kostenart EQ 'H'.

*     Abhaengig von der Kostenquelle
      CASE  gs_lst_arten-kostenquelle.

*       Kosten aus Plan bzw. Planendung immer relevant
        WHEN 'P' OR 'E' OR 'T' OR 'K' OR 'L'.
          gs_lst_arten-relevant = 'X'.

*       Kosten aus Merkmalsebene
        WHEN 'M'.
*         Wenn Merkmal korrekt abgeschlossen
*         Lstart nicht mehrfach (obsolet)
*         --> (Haupt-)Kosten relevant
          IF     gs_lst_arten-satzstatus EQ 5
            AND  gs_lst_arten-erzwungen  EQ space.
            gs_lst_arten-relevant = 'X'.
*         --> (Haupt-)Kosten nicht relevant
          ELSE.
            gs_lst_arten-relevant = space.
          ENDIF.

      ENDCASE.

*   Nebenkosten immer relevant fuer Kostenuebertragung
    ELSE.
      gs_lst_arten-relevant = 'X'.

    ENDIF.

    MODIFY gt_lst_arten FROM gs_lst_arten.

  ENDLOOP.
ENDFORM.                    " AUFBEREITEN_LSTARTEN
*&---------------------------------------------------------------------*
*&      Form  berechnen_kosten
*&---------------------------------------------------------------------*
*       Kosten pro Prueflos fuer die Anzeige im TableControl aufsumm.
*----------------------------------------------------------------------*
FORM berechnen_kosten.

* Hilfsvariable fuer Aufsummierung der Leistungsarten
  DATA: lv_var_tarif           TYPE cost-tkg001,      "Tarif zur variablem Leistungsart
        lv_summe_var_tarife    LIKE gs_lst_arten-tarif,
        lv_summe_tarife        LIKE gs_lst_arten-tarif,
        lv_pruefkosten(12)     TYPE c,
        lv_var_pruefkosten(12) TYPE c.

  CLEAR: lv_summe_tarife, lv_pruefkosten.

  LOOP AT gt_lst_arten INTO gs_lst_arten
     WHERE prueflos EQ gs_qals-prueflos
       AND relevant EQ 'X'.

*     Aufsummierung
    lv_summe_tarife = lv_summe_tarife + gs_lst_arten-tarif * gs_lst_arten-menge.

    CHECK NOT gs_lst_arten-tarif IS INITIAL.
    CHECK NOT gs_lst_arten-menge IS INITIAL.

    IF NOT gs_cost_header-var_menge_flag IS INITIAL.
      gs_lst_arten-var_menge_flag = gs_cost_header-var_menge_flag.
      gs_lst_arten-var_meins      = gs_cost_header-var_meins.
      gs_lst_arten-alt_lstar      = gs_cost_header-alt_lstar.

      PERFORM ermitteln_tarif USING    gs_lst_arten-alt_lstar
                                       gs_cost_header-buchdatum
                              CHANGING gs_lst_arten-var_tarif
                                       gs_lst_arten-var_meins.

      gs_lst_arten-var_menge = gs_lst_arten-tarif / gs_lst_arten-var_tarif.

      MODIFY gt_lst_arten FROM gs_lst_arten.
    ENDIF.

  ENDLOOP.

*   KZ, ob keine Kosten vorhanden sind, setzen bzw. loeschen
  IF lv_summe_tarife EQ 0.
    gs_cost_header-keinekosten = 'X'.
  ELSE.
    CLEAR gs_cost_header-keinekosten.
  ENDIF.

  WRITE lv_summe_tarife TO lv_pruefkosten.
  CONCATENATE lv_pruefkosten gs_cost_header-waers INTO gs_cost_header-pruefkosten
    SEPARATED BY space.

* Variable Leistungsmenge ist aktiv, Umrechnung in alternative Leistungsart
  IF NOT gs_cost_header-var_menge_flag IS INITIAL.

    PERFORM ermitteln_tarif USING    gs_cost_header-alt_lstar
                                     gs_cost_header-buchdatum
                            CHANGING lv_var_tarif
                                     gs_cost_header-var_meins.

    lv_summe_var_tarife = lv_summe_tarife / lv_var_tarif.

    WRITE lv_summe_var_tarife TO lv_var_pruefkosten.
    CONCATENATE lv_var_pruefkosten gs_cost_header-waers INTO gs_cost_header-var_pruefkosten
      SEPARATED BY space.

    gs_cost_header-var_menge = lv_summe_var_tarife.
  ENDIF.

ENDFORM.                    " berechnen_kosten
*&---------------------------------------------------------------------*
*&      Form  uebertragen_kosten
*&---------------------------------------------------------------------*
*       Steuert die Kostenuebertragung komplett
*----------------------------------------------------------------------*
FORM uebertragen_kosten.

* Batch-Input zur CO-Leistungsverrechnung anstossen
* (eigentliche Kostenuebertragung)
  PERFORM leistungsverrechnung.

* Erledigte Prueflose in QALS aktualisieren; ausserdem
* IST-Rabatt fortschreiben und ggf. Rabattzaehler reduzieren
  PERFORM aktualisieren_prueflose.

* Sperre fuer Prueflose loeschen, um SM-Auftraege zu aendern
  PERFORM entsperren_qals.

* Technischen Abschluss fuer alle SM-Auftraege durchfuehren,
* die durch die Wartungsplanung erzeugt wurden
  PERFORM schliessen_sm_auftrag.

* Abschliessendes commit work bei Abarbeitung im Hintergrund fuer
* Statusfortschreibung im Prueflos (sonst wird commit work schon direkt
* nach Statusfortschreibung aufgerufen
  COMMIT WORK.

ENDFORM.                    " UEBERTRAGEN_KOSTEN
*&---------------------------------------------------------------------*
*&      Form  LEISTUNGSVERRECHNUNG
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*       Vorbereitung und Aufruf der CO-Leistungsverrechnung
*       = Uebertragung der Prüfkosten
*----------------------------------------------------------------------*
FORM leistungsverrechnung .

  DATA: lv_doc_no       TYPE bapidochdrp-doc_no.
  DATA: ls_doc_header   TYPE bapidochdrp.
  DATA: ls_doc_items    TYPE bapiaaitm.
  DATA: lt_doc_items    TYPE TABLE OF bapiaaitm.
  DATA: ls_return       TYPE bapiret2.
  DATA: lt_return       TYPE TABLE OF bapiret2.

* Hilfsvariable fuer Positionstext in der Leistungsverrechnung
  DATA: lv_pos_text(50) TYPE c.
  DATA: lv_locked_flag  TYPE flag.

  CLEAR lv_doc_no.
  CLEAR ls_doc_header.

  ls_doc_header-co_area     = gv_kokrs.                     "CF20191206
  ls_doc_header-docdate     = gs_cost_header-buchdatum.
  ls_doc_header-postgdate   = gs_cost_header-buchdatum.
  ls_doc_header-variant     = 'SAP04'.
  ls_doc_header-username   = sy-uname.
  CLEAR lt_doc_items.
  CLEAR lt_return.
*   Alle relevanten Eintraege zu den markierten Prueflosen
*   Nur weiter, wenn Leistungsart und Menge nicht leer
*   (Achtung: Nicht das Feld Tarif zum Vergleich nehmen, denn das ist
*   abhaengig vom Datum; in I_LSTARTEN bezieht sich der Tarif auf das
*   VE-Datum; hier ist aber das Buchungsdatum relevant)
  LOOP AT gt_lst_arten INTO gs_lst_arten
    WHERE prueflos EQ gs_qals-prueflos
      AND relevant EQ 'X'
      AND lstar    NE space
      AND menge    NE 0.

*     Positionstext aufbereiten
    CLEAR lv_pos_text.
    CONCATENATE TEXT-130 gs_qals-prueflos '/'
                TEXT-138 gs_qals-kunnr
      INTO lv_pos_text
      SEPARATED BY space.

    ls_doc_items-seg_text       = lv_pos_text.
    ls_doc_items-send_cctr      = gv_kostl.      "CF20191206     "Sendende Kostenstelle
    IF  gs_cost_header-var_menge_flag IS INITIAL.
*    AND gs_cost_header-lstar          NE gs_lst_arten-lstar.
      ls_doc_items-acttype        = gs_lst_arten-lstar.           "Leistungsart
      ls_doc_items-actvty_qty     = gs_lst_arten-menge.           "Leistungsverbrauch
      IF NOT gs_lst_arten-meins IS INITIAL.                       " Menge aus ZQMKOSTEN4
        ls_doc_items-activityun   = gs_lst_arten-meins.           "Leistungseinheit
      ENDIF.
    ELSE.
      ls_doc_items-acttype    = gs_lst_arten-alt_lstar.    "alternative Leistungsart
      ls_doc_items-actvty_qty = gs_lst_arten-var_menge.    "Menge in alternativer Leistungsart
      ls_doc_items-activityun = gs_lst_arten-var_meins.    "Einheit der alternativen Leistungsart
    ENDIF.

*--------------------------------------Ermitteln Kostl. zur Lstar.......
    LOOP AT gt_vnltilv INTO gs_vnltilv
         WHERE lstar = ls_doc_items-acttype
         AND   datbi GE ls_doc_header-postgdate.
      ls_doc_items-send_cctr = gs_vnltilv-kostl.
      EXIT.
    ENDLOOP.

    IF gs_cost_header-dauer_auftr IS INITIAL.
      ls_doc_items-rec_order = gs_qals-aufnr.              "Empf.=SM-Auftrag
    ELSE.
      ls_doc_items-rec_order = gs_cost_header-dauer_auftr. "Empf.=spez. Auftrag
    ENDIF.
    APPEND ls_doc_items TO lt_doc_items.

  ENDLOOP.

*   Erste Meldung zwecks Gruppierung des Protokolls
  PERFORM sammeln_meldungen
    USING 'I' 'YQMLIMS' '773' gs_qals-prueflos
          space space space.

*   Kein Eintrag in i_lstarten gefunden --> Prueflos hat keine Kosten
*   BTCI_KOSTEN ist initial
  IF lt_doc_items[] IS INITIAL.
    gs_cost_header-erledigt = 'X'.
*     Meldung: Keine Kosten vorhanden
    PERFORM sammeln_meldungen
      USING 'I' 'YQMLIMS' '732' gs_qals-prueflos
            space space space.

*   Kosten koennen uebertragen werden
  ELSE.
    CALL FUNCTION 'BAPI_ACC_ACTIVITY_ALLOC_POST'
      EXPORTING
        doc_header      = ls_doc_header
        ignore_warnings = 'X'
      IMPORTING
        doc_no          = lv_doc_no
      TABLES
        doc_items       = lt_doc_items
        return          = lt_return.

*     Kostenuebertragung fehlgeschlagen
    IF lv_doc_no IS INITIAL.
*       Meldung ausgeben --> Leistungsverrechnung fehlgeschlagen
      PERFORM sammeln_meldungen
        USING 'E' 'YQMLIMS' '767' gs_qals-prueflos
              space space space.

*     Kostenuebertragung erfolgreich
    ELSE.
*       Prueflos erledigt setzen
      gs_cost_header-erledigt = 'X'.
      gs_qals-yqm_co_beleg       = lv_doc_no.
      gs_qals-yqm_co_beleg_datum = gs_cost_header-buchdatum.

    ENDIF.

    LOOP AT lt_return INTO ls_return.
      PERFORM sammeln_meldungen
        USING ls_return-type
              ls_return-id
              ls_return-number
              ls_return-message_v1
              ls_return-message_v2
              ls_return-message_v3
              ls_return-message_v4.
    ENDLOOP.
  ENDIF.
ENDFORM.                    " LEISTUNGSVERRECHNUNG
*&---------------------------------------------------------------------*
*&      Form  AKTUALISIEREN_PRUEFLOSE
*&---------------------------------------------------------------------*
*       Alle aus Sicht der Kostenuebertragung erledigten Prueflose in
*       der Tabelle QALS aktualisieren und Status KSTU fortschreiben;
*       zusaetzlich Ist-Rabatt ermitteln und ggf. Rabattzaehler
*       fortschreiben
*----------------------------------------------------------------------*
FORM aktualisieren_prueflose .

* Hilfsvariable fuer Berichtsnummer
  DATA: lv_berichtnr TYPE yqm_berichtnr.

* Interne Statusnummer zum Anwenderstatus KSTU ermitteln
  CALL FUNCTION 'STATUS_TEXT_CONVERSION'
    EXPORTING
      language           = sy-langu
      mode               = 'E'  "Anwenderstatus
      stsma              = gs_tq30-stsma
      txt04              = gc_kstu
    IMPORTING
      status_number      = gv_stat_kstu
    EXCEPTIONS
      insufficient_input = 1
      not_found          = 2
      object_not_found   = 3
      wrong_mode         = 4
      OTHERS             = 5.
  IF sy-subrc <> 0.
    MESSAGE a707(yqmlims) WITH gc_kstu gs_tq30-stsma.
  ENDIF.

* Interne Statusnummer zum Anwenderstatus OKST ermitteln
  CALL FUNCTION 'STATUS_TEXT_CONVERSION'
    EXPORTING
      language           = sy-langu
      mode               = 'E'  "Anwenderstatus
      stsma              = gs_tq30-stsma
      txt04              = gc_okst
    IMPORTING
      status_number      = gv_stat_okst
    EXCEPTIONS
      insufficient_input = 1
      not_found          = 2
      object_not_found   = 3
      wrong_mode         = 4
      OTHERS             = 5.
  IF sy-subrc <> 0.
    MESSAGE a707(yqmlims) WITH gc_kstu gs_tq30-stsma.
  ENDIF.


* Aktualisierung der Prueflose und Statusfortschreibung
  IF gs_cost_header-erledigt = 'X'.

*   Neue Pruefberichtsnummer ermitteln und ZQMBERICHT fortschreiben
    PERFORM ermitteln_berichtsnr CHANGING lv_berichtnr.

*   Felder ZZKZ_COST, ZZCO_BELEG, ZZCO_BELAG_DATUM, IST-Rabatt und
*   Berichtsnr aktualisieren

*  --> Istrabatt prfen
    UPDATE qals
      SET yqm_berichtnr      = lv_berichtnr
          yqm_kz_cost        = 'X'
          yqm_co_beleg       = gs_qals-yqm_co_beleg
          yqm_co_beleg_datum = gs_qals-yqm_co_beleg_datum
      WHERE prueflos EQ gs_qals-prueflos.

*   Fehler beim Update
    IF sy-subrc <> 0.

      PERFORM sammeln_meldungen
        USING 'E' 'YQMLIMS' '768' space space space space.

*   Update o.k.
    ELSE.

**     Erfolgsmeldung --> Update erfolgreich
      PERFORM sammeln_meldungen
        USING 'I' 'YQMLIMS' '769' space space space space..
*
**     Meldung bzgl. Berichtsnummer ausgeben
      PERFORM sammeln_meldungen
        USING 'I' 'YQMLIMS' '777' lv_berichtnr space space space.

*     Status-Fortschreibung OKST im Prueflos - bei Losen ohne Kosten
      IF gs_cost_header-keinekosten EQ 'X'.
        CALL FUNCTION 'STATUS_CHANGE_EXTERN'
          EXPORTING
            objnr               = gs_qals-objnr
            user_status         = gv_stat_okst  "PLos ohne Kosten
          EXCEPTIONS
            object_not_found    = 1
            status_inconsistent = 2
            status_not_allowed  = 3
            OTHERS              = 4.
        IF sy-subrc <> 0.
*       Meldungen sammeln, hier Fehler bei Statusfortschreibung
          PERFORM sammeln_meldungen
            USING sy-msgty sy-msgid sy-msgno
                  sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.

        ELSE.
**       Meldungen sammeln, hier Erfolgsmeldung Statusfortschreibung
          PERFORM sammeln_meldungen
            USING 'I' 'YQMLIMS' '731' gs_qals-prueflos
                  space space space.
        ENDIF.
      ENDIF.

*     Status-Fortschreibung KSTU im Prueflos
      CALL FUNCTION 'STATUS_CHANGE_EXTERN'
        EXPORTING
          objnr               = gs_qals-objnr
          user_status         = gv_stat_kstu  "Uebertragung erfolgt
        EXCEPTIONS
          object_not_found    = 1
          status_inconsistent = 2
          status_not_allowed  = 3
          OTHERS              = 4.

      IF sy-subrc <> 0.
*       Meldungen sammeln, hier Fehler bei Statusfortschreibung
        PERFORM sammeln_meldungen
          USING sy-msgty sy-msgid sy-msgno
                sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.

      ELSE.
**       Meldungen sammeln, hier Erfolgsmeldung Statusfortschreibung
        PERFORM sammeln_meldungen
          USING 'I' 'YQMLIMS' '731' gs_qals-prueflos
                space space space.
      ENDIF.
    ENDIF.
  ENDIF.

ENDFORM.                    " AKTUALISIEREN_PRUEFLOSE
*&---------------------------------------------------------------------*
*&      Form  ENTSPERREN_QALS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM entsperren_qals .

  CALL FUNCTION 'DEQUEUE_EQQALS1'
    EXPORTING
      prueflos = gs_qals-prueflos.

  CALL FUNCTION 'DEQUEUE_ESORDER'
    EXPORTING
      aufnr = gs_qals-aufnr.

  CALL FUNCTION 'DEQUEUE_EVVBAKE'
    EXPORTING
      vbeln = gs_qals-kdauf.

  WAIT UP TO 1 SECONDS.

ENDFORM.                    " ENTSPERREN_QALS
*&---------------------------------------------------------------------*
*&      Form  schliessen_sm_auftrag
*&---------------------------------------------------------------------*
*       Fuer alle Prueflose, fuer die eine Kostenuebertragung durch-
*       gefuehrt wurde, werden die ausloesenden SM-Auftraege technisch
*       abgeschlossen
*----------------------------------------------------------------------*
FORM schliessen_sm_auftrag.

*  DATA: lv_locked_flag TYPE flag.

* Fuer alle erledigten Prueflose
  IF gs_cost_header-erledigt = 'X'.

*   Batch-Input-Tabelle refreshen
    CLEAR gt_btci_table.
*   Aufbau Batch-Input-Tabelle
    PERFORM btci_dynpro USING 'SAPLCOIH' '0101'.
    PERFORM btci_field  USING 'CAUFVD-AUFNR' gs_qals-aufnr.
    PERFORM btci_field  USING 'BDC_OKCODE' '/00'.
    PERFORM btci_dynpro USING 'SAPLCOIH' '3000'.
*   PERFORM btci_field  USING 'BDC_OKCODE' '=ARCH'. "Techn. Abschl.
    IF NOT ( gs_cost_header-dauer_auftr IS INITIAL ) OR
             gs_cost_header-keinekosten EQ 'X'.
      PERFORM btci_field  USING 'BDC_OKCODE' '=BABS'. "Kaufm. Abschl.
    ELSE.
      PERFORM btci_field  USING 'BDC_OKCODE' '=ARCH'. "Techn. Abschl.
    ENDIF.
    PERFORM btci_dynpro USING 'SAPLCOI0' '1000'.
    PERFORM btci_field  USING 'BDC_OKCODE' '=WEIT'.  "Weiter Techn. Ab.

*   Aufruf der TA SM-Auftrag aendern --> Technischer Abschluss
    CALL TRANSACTION 'IW32' USING gt_btci_table MODE 'E'.
*     MESSAGES INTO sys_messages.

    IF sy-subrc <> 0.                  "Fehler aufgetreten
*   Meldung, dass Fehler augetreten ist, sammmeln
      PERFORM sammeln_meldungen
        USING 'E' 'YQMLIMS' '730' gs_qals-aufnr
              space space space.
    ENDIF.
  ENDIF.

ENDFORM.                    " schliessen_sm_auftrag
*&---------------------------------------------------------------------*
*&      Form  ERMITTELN_BERICHTSNR
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_BERICHTNR  text
*----------------------------------------------------------------------*
FORM ermitteln_berichtsnr  CHANGING cv_berichtnr.

* Hilfsvariable fuer Berichtsnr und Kundennr
  DATA: lv_bnr TYPE yqm_bericht_t-berichtnr,
        lv_knr TYPE qals-kunnr.

* Hilfsvariable clearen
  CLEAR: lv_bnr, lv_knr.

* Kundennummer setzen (entweder Partner ZL (wenn vorhanden) oder AG)
*  IF NOT ( gs_qals-yqm_kunnrzl IS INITIAL ).
*    lv_knr = gs_qals-yqm_kunnrzl.
*  ELSE.
  lv_knr = gs_qals-kunnr.
*  ENDIF.

* Ermittlung der letzten Berichtsnummer laut Tabelle ZQMBERICHT
  SELECT SINGLE berichtnr
  FROM yqm_bericht_t
  WHERE jahr  = @sy-datum+0(4)
    AND kunnr = @lv_knr
  INTO @lv_bnr.
  IF sy-subrc <> 0.
    CLEAR lv_bnr.
  ENDIF.

* Berichtsnummer um 1 erhoehen
  lv_bnr = lv_bnr + 1.

* Berichtsnummer uebergben
  cv_berichtnr = lv_bnr.

* Tabelle YQM_MBERICHT_T aktualisieren (modify = insert oder update)
  DATA(ls_bericht) = VALUE yqm_bericht_t(
  jahr      = sy-datum+0(4)
  kunnr     = lv_knr
  berichtnr = lv_bnr ).

  MODIFY yqm_bericht_t FROM ls_bericht.

ENDFORM.                    " ERMITTELN_BERICHTSNR
*&---------------------------------------------------------------------*
*&      Form  btci_dynpro
*&---------------------------------------------------------------------*
*       Fuellen einer Batch-Input-Tabelle mit Programm und Dynpro
*----------------------------------------------------------------------*
FORM btci_dynpro USING iv_program iv_dynpro.

* Kopfzeile clearen
  CLEAR gs_btci_table.

* Programm und Dynpro in BTCI-Tabelle schreiben
  gs_btci_table-program  = iv_program.
  gs_btci_table-dynpro   = iv_dynpro.
  gs_btci_table-dynbegin = 'X'.
  APPEND gs_btci_table TO gt_btci_table.

ENDFORM.                    " btci_dynpro
*&---------------------------------------------------------------------*
*&      Form  btci_field
*&---------------------------------------------------------------------*
*       Fuellen einer Batch-Input-Tabelle mit Feld und Feldwert
*----------------------------------------------------------------------*
FORM btci_field USING iv_fnam iv_fval.

* Hilfsvaraibel fuer 'No Data'
  DATA: lv_nodata TYPE c VALUE '/'.

* Fuellen der BTCI-Tabelle (Einzelne Felder plus Wert)
  IF iv_fval NE lv_nodata.

*   Kopfzeile clearen
    CLEAR gs_btci_table.
*   Feld und Feldinhalt eintragen
    gs_btci_table-fnam = iv_fnam.
    gs_btci_table-fval = iv_fval.
    APPEND gs_btci_table TO gt_btci_table.

  ENDIF.

ENDFORM.                    " btci_field
*&---------------------------------------------------------------------*
*&      Form  SAMMELN_MELDUNGEN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_SY_MSGTY  text
*      -->P_SY_MSGID  text
*      -->P_SY_MSGNO  text
*      -->P_SY_MSGV1  text
*      -->P_SY_MSGV2  text
*      -->P_SY_MSGV3  text
*      -->P_SY_MSGV4  text
*      -->P_I_PRUEFLOS_PRUEFLOS  text
*----------------------------------------------------------------------*
FORM sammeln_meldungen  USING iv_msgtyp iv_msgid iv_msgnr
                              iv_msgv1  iv_msgv2 iv_msgv3 iv_msgv4.

  CHECK NOT ( iv_msgnr IS INITIAL ).

  MESSAGE ID iv_msgid TYPE iv_msgtyp NUMBER iv_msgnr
          WITH iv_msgv1 iv_msgv2 iv_msgv3 iv_msgv4
          INTO gv_dummy.

  PERFORM add_message.

ENDFORM.                    " sammeln_meldungen
*&---------------------------------------------------------------------*
*&      Form  ADD_MESSAGE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM add_message .

  IF   sy-msgty = 'E'
    OR sy-msgty = 'A'.
    gv_display_log = 'X'.
  ENDIF.

* Nachricht erstellen:
  CLEAR gs_msg.
  gs_msg-msgty     = sy-msgty.
  gs_msg-msgid     = sy-msgid.
  gs_msg-msgno     = sy-msgno.
  gs_msg-msgv1     = sy-msgv1.
  gs_msg-msgv2     = sy-msgv2.
  gs_msg-msgv3     = sy-msgv3.
  gs_msg-msgv4     = sy-msgv4.
*  gs_msg-probclass = i_probclass.

* Diese Nachricht zum LOG hinzufgen:
  CALL FUNCTION 'BAL_LOG_MSG_ADD'
    EXPORTING
      i_log_handle  = gs_log_handle
      i_s_msg       = gs_msg
    EXCEPTIONS
      log_not_found = 0
      OTHERS        = 0.

ENDFORM.                    " ADD_MESSAGE
*&---------------------------------------------------------------------*
*&      Form  DISPLAY_LOG
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM display_log .

* get a prepared profile
  CALL FUNCTION 'BAL_DSP_PROFILE_SINGLE_LOG_GET'
    IMPORTING
      e_s_display_profile = gs_s_display_profile
    EXCEPTIONS
      OTHERS              = 1.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
             WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

* use grid for display if wanted
  gs_s_display_profile-use_grid = 'X'.
  gs_s_display_profile-not_empty = 'X'.

  gs_s_display_profile-start_col = 1.
  gs_s_display_profile-start_row = 1.
  gs_s_display_profile-end_col   = 100.
  gs_s_display_profile-end_row   = 25.


* set report to allow saving of variants
  gs_s_display_profile-disvariant-report = sy-repid.

* call display function module
* We do not specify any filter (type I_S_LOG_FILTER, ...,
* I_T_MSG_HANDLE) since we want to display all logs available
  CALL FUNCTION 'BAL_DSP_LOG_DISPLAY'
    EXPORTING
      i_s_display_profile = gs_s_display_profile
      i_amodal            = 'X'
    EXCEPTIONS
      OTHERS              = 1.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
             WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

ENDFORM.                    " DISPLAY_LOG
*&---------------------------------------------------------------------*
*&      Form  SAVE_LOG
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM save_log .

  CALL FUNCTION 'BAL_DB_SAVE'
    EXPORTING
      i_save_all       = 'X'
      i_t_log_handle   = gt_log_handle
    EXCEPTIONS
      log_not_found    = 1
      save_not_allowed = 2
      numbering_error  = 3
      OTHERS           = 4.
  IF sy-subrc = 0.
    MESSAGE w002(yqmlims) INTO gv_dummy.
    PERFORM add_message.
    COMMIT WORK.
  ENDIF.

ENDFORM.                    " SAVE_LOG
*&---------------------------------------------------------------------*
*&      Form  BEURTEILUNG_GENERIEREN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM beurteilung_generieren .

  DATA: lv_name         TYPE thead-tdname.
  DATA: lv_reject       TYPE flag.
  DATA: lv_found        TYPE flag.
  DATA: ls_lines        TYPE tline.
  DATA: lt_lines        TYPE TABLE OF tline.
  DATA: ls_matn_mk      TYPE yqm_matn_mk_t.
  DATA: lt_matn_mk      TYPE TABLE OF yqm_matn_mk_t.

  DATA: ls_textline(72) TYPE c.
  DATA: lt_texttable    LIKE TABLE OF ls_textline.
*  CLEAR gt_ltxt. Bestehende Beurteilung soll erhalten bleiben

* Zunchst Regeln ohne Gruppe prozessieren
  LOOP AT gt_matn_mk INTO gs_matn_mk
    WHERE gruppe IS INITIAL
    AND   regel  NE space.
    CLEAR gs_parameter_string.
    CLEAR lv_found.
    CLEAR lv_reject.
    CLEAR lv_name.

    CASE gs_matn_mk-regel.
      WHEN '00'.      "Textausgabe
        IF NOT gs_matn_mk-merkmal IS INITIAL.
          PERFORM beurteilung_regel_00 CHANGING lv_found
                                                lv_reject
                                                lv_name.

          IF lv_found = 'X'.
            IF lv_reject = 'X'.
              lv_name = gs_matn_mk-text_nio.
            ELSE.
              lv_name = gs_matn_mk-text_io.
            ENDIF.
            PERFORM text_generieren  TABLES lt_lines
                                     USING  lv_name.
          ENDIF.
        ELSE.
          ls_lines-tdformat = '*'.
          ls_lines-tdline   = gs_matn_mk-text.
          APPEND ls_lines TO lt_lines.
        ENDIF.


      WHEN '10'.      "qualitativ
        PERFORM beurteilung_regel_10 CHANGING lv_found
                                              lv_reject
                                              lv_name.

        IF lv_found = 'X'.
          IF lv_reject = 'X'.
            lv_name = gs_matn_mk-text_nio.
          ELSE.
            lv_name = gs_matn_mk-text_io.
          ENDIF.
          PERFORM text_generieren  TABLES lt_lines
                                   USING  lv_name.
        ENDIF.
      WHEN '20'.      "informativ
        PERFORM beurteilung_regel_20 CHANGING lv_found
                                              lv_reject
                                              lv_name.
        IF lv_found = 'X'.

          IF lv_name IS INITIAL.
            lv_name = gs_matn_mk-text_io.
          ENDIF.

          PERFORM text_generieren  TABLES lt_lines
                                   USING  lv_name.
        ENDIF.

    ENDCASE.

  ENDLOOP.

  lt_matn_mk[] = gt_matn_mk[].

  SORT lt_matn_mk BY matnr gruppe zaehler.
  DELETE ADJACENT DUPLICATES FROM lt_matn_mk
    COMPARING  matnr gruppe.

* Dann Regeln mit allen Parametern einer Gruppe prozessieren
  LOOP AT lt_matn_mk INTO ls_matn_mk
    WHERE gruppe    NE '000'  "<< Um doppelte Prozessierungen im Legionellenfall zu verhindern
    AND   regel     NE space.
    CLEAR gs_parameter_string.
    CLEAR lv_found.
    CLEAR lv_reject.
    CLEAR lv_name.

    LOOP AT gt_matn_mk INTO gs_matn_mk
      WHERE gruppe EQ ls_matn_mk-gruppe.

      CASE gs_matn_mk-regel.
        WHEN '00'.      "Überschrift
          IF NOT gs_matn_mk-merkmal IS INITIAL.
            PERFORM beurteilung_regel_00 CHANGING lv_found
                                                  lv_reject
                                                  lv_name.
            IF lv_found = 'X'.
              IF lv_reject = 'X'.
                lv_name = gs_matn_mk-text_nio.
              ELSE.
                lv_name = gs_matn_mk-text_io.
              ENDIF.
              PERFORM text_generieren  TABLES lt_lines
                                       USING  lv_name.
            ENDIF.
          ELSE.
            ls_lines-tdformat = '*'.
            ls_lines-tdline   = gs_matn_mk-text.
            APPEND ls_lines TO lt_lines.
          ENDIF.

        WHEN '10'.      "qualitativ
          PERFORM beurteilung_regel_10 CHANGING lv_found
                                                lv_reject
                                                lv_name.

          IF lv_found = 'X'.
            IF lv_reject = 'X'.
              lv_name = gs_matn_mk-text_nio.
            ELSE.
              lv_name = gs_matn_mk-text_io.
            ENDIF.
            PERFORM text_generieren  TABLES lt_lines
                                     USING  lv_name.
          ENDIF.
        WHEN '20'.      "informativ
          PERFORM beurteilung_regel_20 CHANGING lv_found
                                                lv_reject
                                                lv_name.
          IF lv_found = 'X'.

            IF lv_name IS INITIAL.
              lv_name = gs_matn_mk-text_io.
            ENDIF.

            PERFORM text_generieren  TABLES lt_lines
                                     USING  lv_name.
          ENDIF.

      ENDCASE.
    ENDLOOP.

*    CASE gs_matn_mk-regel.
*      WHEN '00'.      "Überschrift
**        IF lv_found = 'X'.
**          IF lv_reject = 'X'.
**            lv_name = gs_matn_mk-text_nio.
**          ELSE.
**            lv_name = gs_matn_mk-text_io.
**          ENDIF.
**          PERFORM text_generieren  TABLES lt_lines
**                                   USING  lv_name.
**        ENDIF.
*
*      WHEN '10'.      "qualitativ
*        IF lv_found = 'X'.
*          IF lv_reject = 'X'.
*            lv_name = gs_matn_mk-text_nio.
*          ELSE.
*            lv_name = gs_matn_mk-text_io.
*          ENDIF.
*          PERFORM text_generieren  TABLES lt_lines
*                                   USING  lv_name.
*        ENDIF.
*
*      WHEN '20'.      "informativ
*        IF lv_found = 'X'.
*          IF lv_name IS INITIAL.
*            lv_name = gs_matn_mk-text_io.
*          ENDIF.
*          PERFORM text_generieren  TABLES lt_lines
*                                   USING  lv_name.
*        ENDIF.
*
*    ENDCASE.
  ENDLOOP.

  APPEND LINES OF lt_lines TO gt_ltxt.

  LOOP AT gt_ltxt INTO ls_lines.
    ls_textline = ls_lines-tdline.
    APPEND ls_textline TO lt_texttable.
  ENDLOOP.

  CALL FUNCTION 'CONVERT_ITF_TO_STREAM_TEXT'
    TABLES
      itf_text    = gt_ltxt
      text_stream = lt_texttable.

  CLEAR gv_string.

  LOOP AT lt_texttable INTO ls_textline.
    CONCATENATE gv_string ls_textline INTO gv_string.
  ENDLOOP.

* and send text to note editor
  CALL METHOD gv_edit->set_textstream
    EXPORTING
      text = gv_string.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  TEXT_GENERIEREN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_LINES  text
*      -->P_LV_NAME  text
*----------------------------------------------------------------------*
FORM text_generieren TABLES t_lines TYPE tlinetab
                     USING  iv_name TYPE thead-tdname.

  CONSTANTS:
    lc_id     TYPE thead-tdid     VALUE 'ST',
    lc_object TYPE thead-tdobject VALUE 'TEXT',
    lc_width  TYPE i              VALUE 72.

  DATA: ls_header     TYPE thead,
        ls_line       TYPE tline,
        lt_out_lines  TYPE STANDARD TABLE OF tline WITH EMPTY KEY,
        lt_include    TYPE STANDARD TABLE OF tline WITH EMPTY KEY,
        ls_inc_header TYPE thead.

  " Start: Original lines puffern (wir bauen lt_out_lines neu auf)
  lt_out_lines = t_lines[].

  " Text lesen
  CALL FUNCTION 'READ_TEXT'
    EXPORTING
      id       = lc_id
      language = sy-langu
      name     = iv_name
      object   = lc_object
    IMPORTING
      header   = ls_header
    TABLES
      lines    = t_lines
    EXCEPTIONS
      OTHERS   = 8.

  IF sy-subrc <> 0.
    " Minimal-invasiv: ursprüngliche Lines wiederherstellen und raus
    t_lines[] = lt_out_lines.
    RETURN.
  ENDIF.

  " Symbole/Includes im Text ersetzen (Standardlogik wie vorher)
  CALL FUNCTION 'TEXT_SYMBOL_REPLACE'
    EXPORTING
      header    = ls_header
      program   = sy-repid
    IMPORTING
      newheader = ls_header
    TABLES
      lines     = t_lines.

  CALL FUNCTION 'TEXT_INCLUDE_REPLACE'
    EXPORTING
      header    = ls_header
      program   = sy-repid
    IMPORTING
      newheader = ls_header
    TABLES
      lines     = t_lines.

  " Neu aufbauen: INCLUDE-Zeilen auflösen (wie vorher), Rest übernehmen
*  CLEAR lt_out_lines.

  LOOP AT t_lines INTO ls_line.

    IF ls_line-tdformat  = '/:'
       AND ls_line-tdline(7) = 'INCLUDE'.

      " Erwartetes Format grob:
      " /: INCLUDE <name> OBJECT <object> ID <id> LANGUAGE <spras>
      DATA(lt_tok) = VALUE string_table( ).
      SPLIT ls_line-tdline AT space INTO TABLE lt_tok.
      DELETE lt_tok WHERE table_line IS INITIAL.

      " defensiv: Tokens prüfen (Index-basiert, weil Original so arbeitet)
      IF lines( lt_tok ) < 8.
        " wenn unvollständig: Zeile wie gehabt übernehmen
        APPEND ls_line TO lt_out_lines.
        CONTINUE.
      ENDIF.

      CLEAR ls_inc_header.
      " Entspricht deiner bisherigen SPLIT-Reihenfolge (Dummy/Value/ Dummy/Value ...)
      " 1=INCLUDE, 2=<name>, 3=OBJECT, 4=<object>, 5=ID, 6=<id>, 7=LANGUAGE, 8=<spras>
      ls_inc_header-tdname   = lt_tok[ 2 ].
      ls_inc_header-tdobject = lt_tok[ 4 ].
      ls_inc_header-tdid     = lt_tok[ 6 ].
      ls_inc_header-tdspras  = lt_tok[ 8 ].

      CLEAR lt_include.

      CALL FUNCTION 'READ_TEXT'
        EXPORTING
          id       = ls_inc_header-tdid
          language = ls_inc_header-tdspras
          name     = ls_inc_header-tdname
          object   = ls_inc_header-tdobject
        TABLES
          lines    = lt_include
        EXCEPTIONS
          OTHERS   = 8.

      IF sy-subrc = 0 AND lt_include IS NOT INITIAL.
        APPEND LINES OF lt_include TO lt_out_lines.
      ELSE.
        " Wenn INCLUDE nicht lesbar: Originalzeile behalten (statt still wegwerfen)
        APPEND ls_line TO lt_out_lines.
      ENDIF.

    ELSE.
      APPEND ls_line TO lt_out_lines.
    ENDIF.

  ENDLOOP.

  t_lines[] = lt_out_lines.

  " Formatierung
  CALL FUNCTION 'FORMAT_TEXTLINES'
    EXPORTING
      formatwidth = lc_width
    TABLES
      lines       = t_lines
    EXCEPTIONS
      bound_error = 0
      OTHERS      = 0.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  BEURTEILUNG_REGEL_00
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM beurteilung_regel_00  CHANGING cv_found  TYPE qkz
                                    cv_reject TYPE qkz
                                    cv_name   TYPE tdobname.

  cv_found  = 'X'.
  cv_reject = space.
  cv_name   = gs_matn_mk-text_io.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  BEURTEILUNG_REGEL_10
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM beurteilung_regel_10  CHANGING cv_found  TYPE qkz
                                    cv_reject TYPE qkz
                                    cv_name   TYPE tdobname.

  DATA: lv_unit         TYPE text30.

  LOOP AT gt_results INTO gs_results
    WHERE verwmerkm = gs_matn_mk-merkmal
    AND   nbeurtrel = space.

    IF gs_results-statusr = '5'.
      cv_found = 'X'.
    ENDIF.

    IF gs_results-mbewertg = 'R'.
      CALL FUNCTION 'CONVERSION_EXIT_LUNIT_OUTPUT'
        EXPORTING
          input          = gs_results-masseinhsw
*         LANGUAGE       = SY-LANGU
        IMPORTING
*         LONG_TEXT      =
*         OUTPUT         =
          short_text     = lv_unit
        EXCEPTIONS
          unit_not_found = 1
          OTHERS         = 2.
      IF sy-subrc <> 0.
* Implement suitable error handling here
        lv_unit = gs_results-masseinhsw.
      ENDIF.

      CONCATENATE gs_parameter_string
                  gs_results-kurztext
                  gs_results-mittelwertc
                  lv_unit
                  INTO gs_parameter_string SEPARATED BY space.
      CONDENSE gs_parameter_string.
      cv_reject = 'X'.
    ELSE.
      CONTINUE.
    ENDIF.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  BEURTEILUNG_REGEL_20
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM beurteilung_regel_20  CHANGING cv_found  TYPE qkz
                                    cv_reject TYPE qkz
                                    cv_name   TYPE tdobname.

  DATA: lv_attribut   TYPE qattribut.
  DATA: lv_mittelwert TYPE yqm_wert.
*  DATA: lv_unit       TYPE text30.
  DATA: ls_results    TYPE yqm_results_display.
  DATA: lv_name_text  TYPE tdobname.

  CLEAR lv_name_text.

  LOOP AT gt_results INTO gs_results
    WHERE verwmerkm = gs_matn_mk-merkmal
    AND   nbeurtrel = space.

    IF gs_results-statusr = '5'.
      cv_found = 'X'.
    ENDIF.

*   Attribut 'U' bedeutet nicht nachweisbar.
*   Ergebnisse mit diesem Attribut haben den Messwerte 99999
*   und drfen nicht betrachtet werden
    IF gs_results-attribut = 'U'.
      CONTINUE.
    ENDIF.

    IF ls_results            IS INITIAL.
      ls_results = gs_results.
    ELSEIF ls_results-mittelwert LT gs_results-mittelwert.
      ls_results = gs_results.
    ELSEIF ls_results-mittelwert EQ gs_results-mittelwert.
      IF ls_results-attribut = '<'.
        ls_results = gs_results.
      ENDIF.
    ENDIF.
  ENDLOOP.

  IF  ls_results         IS INITIAL
  AND gs_results-attribut = 'U'.
* Falls bis hierhin kein Ergebnis gefunden werden konnte,
* waren offensichtlich alle Messwerte mit Attribut U versehen.
* In diesem Fall wird der Ergebniswert 99999 bernommen und damit der
* korrekte Langtext bzgl der Kontamination ausgegeben
    ls_results = gs_results.
  ENDIF.
  lv_mittelwert = ls_results-mittelwert.
  lv_attribut = ls_results-attribut.

  IF lv_attribut = '<'.
    SELECT name_text FROM yqm_ve_lt_t INTO lv_name_text
        WHERE matnr     = gs_matn_mk-matnr
        AND   verwmerkm = gs_matn_mk-merkmal
      AND   abw       = 'X'
      AND   wertv     LT lv_mittelwert
      ORDER BY wertv DESCENDING.
      cv_name = lv_name_text.
      EXIT.
    ENDSELECT.
  ELSE.
    SELECT name_text FROM yqm_ve_lt_t INTO lv_name_text
        WHERE matnr     = gs_matn_mk-matnr
        AND   verwmerkm = gs_matn_mk-merkmal
      AND   abw       = 'X'
      AND   wertv     LE lv_mittelwert
      ORDER BY wertv DESCENDING.
      cv_name = lv_name_text.
      EXIT.
    ENDSELECT.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  CREATE_CERTIFICATE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_QALS_PRUEFLOS  text
*      -->P_I_QALS_WERK  text
*----------------------------------------------------------------------*
FORM create_certificate  USING    iv_prueflos
                                  iv_werk.

  DATA: ls_params     TYPE rsparams.
  DATA: lt_params     TYPE TABLE OF rsparams.

  ls_params-selname = 'QL_PRLOS'.
  ls_params-kind    = 'S'.
  ls_params-sign    = 'I'.
  ls_params-option  = 'EQ'.
  ls_params-low     = iv_prueflos.
  APPEND ls_params TO lt_params.

  ls_params-selname = 'P_WERK'.
  ls_params-kind    = 'P'.
  ls_params-sign    = 'I'.
  ls_params-option  = 'EQ'.
  ls_params-low     = iv_werk.
  APPEND ls_params TO lt_params.

  ls_params-selname = 'P_UDCALL'.
  ls_params-kind    = 'P'.
  ls_params-sign    = 'I'.
  ls_params-option  = 'EQ'.
  ls_params-low     = 'X'.
  APPEND ls_params TO lt_params.

  SUBMIT yqmlims_create_certificate WITH SELECTION-TABLE lt_params
         AND RETURN.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  ERMITTELN_STANDARDUMFANG
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM ermitteln_standardumfang .

  SELECT * FROM yqm_matn_mk_t INTO TABLE gt_matn_mk
    WHERE matnr = gs_kosten4-matnr
    ORDER BY matnr zaehler.
  IF sy-subrc <> 0.
    CLEAR gt_matn_mk.
  ENDIF.

  LOOP AT gt_matn_mk INTO gs_matn_mk
    WHERE stumf IS INITIAL.
    gr_merkmal = VALUE #( ( sign   = 'I'
                            option = 'EQ'
                            low    = gs_matn_mk-merkmal ) ).
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form free_screen_200_controls
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM free_screen_200_controls.

  IF gv_docking_container_1 IS BOUND.
    gv_docking_container_1->free(
      EXCEPTIONS
        cntl_system_error = 1
        cntl_error        = 2 ).
    IF sy-subrc <> 0.
      MESSAGE a700(yqmlims).
    ENDIF.
  ENDIF.

  IF gv_docking_container_2 IS BOUND.
    gv_docking_container_2->free(
      EXCEPTIONS
        cntl_system_error = 1
        cntl_error        = 2 ).
    IF sy-subrc <> 0.
      MESSAGE a700(yqmlims).
    ENDIF.
  ENDIF.

  cl_gui_cfw=>flush(
    EXCEPTIONS
      cntl_system_error = 1
      cntl_error        = 2 ).
  IF sy-subrc <> 0.
    MESSAGE a700(yqmlims).
  ENDIF.

  " Referenzen/Controls zurücksetzen
  CLEAR: gv_docking_container_1,
         gv_edit,
         gv_docking_container_2,
         gv_alv.

ENDFORM.
