FUNCTION y_qmlims_qfoa_print_appraisal.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     REFERENCE(I_QALS) LIKE  QALS STRUCTURE  QALS
*"     REFERENCE(I_QAVE) LIKE  QAVE STRUCTURE  QAVE
*"     VALUE(I_NO_STATUS_CHECK) TYPE  FLAG OPTIONAL
*"  EXPORTING
*"     VALUE(E_SUBRC) LIKE  SY-SUBRC
*"  TABLES
*"      E_PROTOCOL STRUCTURE  RQEVP OPTIONAL
*"----------------------------------------------------------------------

  DATA: lv_text(1024)     TYPE c,
        lv_datum(10)      TYPE c,
        lv_datum_von(10)  TYPE c,
        lv_datum_bis(10)  TYPE c,
        lv_uzeit(8)       TYPE c,
        lv_window_title   TYPE string,
        ls_kna1           TYPE kna1,
        ls_file           TYPE file_table,
        lt_file           TYPE filetable,
        lv_rc             TYPE i,
        lv_status_gute    TYPE jest-stat,
        lv_status_begu    TYPE jest-stat,
        lv_cleanup_needed TYPE abap_bool VALUE abap_false.

  e_subrc = 0.

  "------------------------------------------------------------
  " 1) Statusprüfungen (optional)
  "------------------------------------------------------------
  IF i_no_status_check IS INITIAL.

    CALL FUNCTION 'STATUS_TEXT_CONVERSION'
      EXPORTING
        language      = sy-langu
        mode          = 'E'
        objnr         = i_qals-objnr
        txt04         = 'GUTE'
      IMPORTING
        status_number = lv_status_gute
      EXCEPTIONS
        OTHERS        = 5.

    IF sy-subrc <> 0.
      e_subrc = 8.
      RETURN.
    ENDIF.

    CALL FUNCTION 'STATUS_CHECK'
      EXPORTING
        objnr  = i_qals-objnr
        status = lv_status_gute
      EXCEPTIONS
        OTHERS = 3.

    IF sy-subrc <> 0.
      " Gutachten nicht erforderlich
      e_subrc = 4.
      RETURN.
    ENDIF.

    CALL FUNCTION 'STATUS_TEXT_CONVERSION'
      EXPORTING
        language      = sy-langu
        mode          = 'E'
        objnr         = i_qals-objnr
        txt04         = 'BEGU'
      IMPORTING
        status_number = lv_status_begu
      EXCEPTIONS
        OTHERS        = 5.

    IF sy-subrc = 0.
      CALL FUNCTION 'STATUS_CHECK'
        EXPORTING
          objnr  = i_qals-objnr
          status = lv_status_begu
        EXCEPTIONS
          OTHERS = 3.

      IF sy-subrc = 0.
        " Gutachten bereits erstellt
        e_subrc = 4.
        RETURN.
      ENDIF.
    ENDIF.

  ENDIF.

  "------------------------------------------------------------
  " 2) Datei wählen
  "------------------------------------------------------------
  lv_window_title = TEXT-003.

  CALL METHOD cl_gui_frontend_services=>file_open_dialog
    EXPORTING
      window_title     = lv_window_title
      default_filename = '*.doc;*.dot'
    CHANGING
      file_table       = lt_file
      rc               = lv_rc
    EXCEPTIONS
      OTHERS           = 4.

  IF sy-subrc <> 0 OR lv_rc <= 0 OR lt_file IS INITIAL.
    e_subrc = 2.
    RETURN.
  ENDIF.

  READ TABLE lt_file INTO ls_file INDEX 1.
  IF sy-subrc <> 0 OR ls_file-filename IS INITIAL.
    e_subrc = 2.
    RETURN.
  ENDIF.

  "------------------------------------------------------------
  " 3) Word starten + Dokument öffnen (OLE2)
  "------------------------------------------------------------
  CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
    EXPORTING
      text = 'Starte Word...'(022).

  CREATE OBJECT gv_word 'Word.Application'.
  IF sy-subrc <> 0.
    e_subrc = 8.
    RETURN.
  ENDIF.

  lv_cleanup_needed = abap_true.

  SET PROPERTY OF gv_word 'Visible' = 1.
  IF sy-subrc <> 0.
    e_subrc = 8.
  ENDIF.

  IF e_subrc = 0.
    CALL METHOD OF gv_word 'Documents' = gv_document.
    IF sy-subrc <> 0.
      e_subrc = 8.
    ENDIF.
  ENDIF.

  IF e_subrc = 0.
    CALL METHOD OF gv_document 'Open' = gv_file
      EXPORTING
        #1 = ls_file-filename.
    IF sy-subrc <> 0.
      MESSAGE s103(yqmlims) WITH ls_file-filename.
      e_subrc = 8.
    ENDIF.
  ENDIF.

  IF e_subrc = 0.
    CALL METHOD OF gv_word 'Options' = gv_options.
    IF sy-subrc <> 0.
      e_subrc = 8.
    ENDIF.
  ENDIF.

  IF e_subrc = 0.
    SET PROPERTY OF gv_options 'UpdateFieldsAtPrint' = 0.
    IF sy-subrc <> 0.
      e_subrc = 8.
    ENDIF.
  ENDIF.

  "------------------------------------------------------------
  " 4) Felder befüllen (nur wenn bisher alles ok)
  "------------------------------------------------------------
  IF e_subrc = 0.

    CALL FUNCTION 'KNA1_READ_SINGLE'
      EXPORTING
        id_kunnr = i_qals-kunnr
      IMPORTING
        es_kna1  = ls_kna1
      EXCEPTIONS
        OTHERS   = 3.

    IF sy-subrc = 0.
      lv_text = ls_kna1-name1.
      PERFORM fill_text_field USING lv_text 'Auftraggeber_Name'.

      lv_text = ls_kna1-name2.
      PERFORM fill_text_field USING lv_text 'Auftraggeber_Name2'.

      lv_text = ls_kna1-stras.
      PERFORM fill_text_field USING lv_text 'Auftraggeber_Strasse'.

      CONCATENATE ls_kna1-pstlz ls_kna1-ort01 INTO lv_text SEPARATED BY space.
      PERFORM fill_text_field USING lv_text 'Auftraggeber_Ort'.
    ENDIF.

    lv_text = i_qals-ktextmat.
    PERFORM fill_text_field USING lv_text 'Probenahmeort_Name'.

    lv_text = i_qals-yqm_info1.
    PERFORM fill_text_field USING lv_text 'Probenahmeort_Info1'.

    lv_text = i_qals-yqm_info2.
    PERFORM fill_text_field USING lv_text 'Probenahmeort_Info2'.

    lv_text = i_qals-yqm_info3.
    PERFORM fill_text_field USING lv_text 'Probenahmeort_Info3'.

    lv_text = i_qals-ktextlos.
    PERFORM fill_text_field USING lv_text 'Prüfloskurztext'.

    SELECT SINGLE yqm_wasserwirtnr
      FROM iflot
      WHERE tplnr = @i_qals-yqm_tplnr
      INTO @DATA(lv_wasserwirtnr).

    IF sy-subrc = 0 AND lv_wasserwirtnr IS NOT INITIAL.
      lv_text = lv_wasserwirtnr.
      PERFORM fill_text_field USING lv_text 'Objektnummer'.
    ENDIF.

    lv_text = i_qals-yqm_probenehmer40.
    PERFORM fill_text_field USING lv_text 'Probeentnehmer'.

    WRITE i_qals-yqm_probedatum TO lv_datum.
    WRITE i_qals-yqm_probezeit  TO lv_uzeit.
    CONCATENATE lv_datum lv_uzeit INTO lv_text SEPARATED BY space.
    PERFORM fill_text_field USING lv_text 'Probeentnahmedatum'.

    WRITE i_qals-yqm_probeeingang TO lv_datum.
    lv_text = lv_datum.
    PERFORM fill_text_field USING lv_text 'Probeneingang'.

    WRITE i_qave-vdatum    TO lv_datum_von.
    WRITE i_qals-pastrterm TO lv_datum_bis.
    CONCATENATE lv_datum_von '-' lv_datum_bis INTO lv_text SEPARATED BY space.
    PERFORM fill_text_field USING lv_text 'Prüfzeitraum'.

    lv_text = i_qals-prueflos.
    PERFORM fill_text_field USING lv_text 'Prüfnummer'.

    CALL FUNCTION 'FLUSH'
      EXCEPTIONS
        OTHERS = 3.

    IF sy-subrc <> 0.
      e_subrc = 8.
    ENDIF.

  ENDIF.

  "------------------------------------------------------------
  " 5) Cleanup (immer, wenn Word gestartet wurde)
  "------------------------------------------------------------
  IF lv_cleanup_needed = abap_true.
    FREE OBJECT: gv_file, gv_document, gv_options, gv_word.
  ENDIF.

  RETURN.

ENDFUNCTION.
