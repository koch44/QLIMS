FUNCTION y_qmlims_cert_create.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     REFERENCE(IV_PDF) TYPE  QKZ OPTIONAL
*"     REFERENCE(IV_PREVIEW) TYPE  QKZ OPTIONAL
*"     REFERENCE(IV_UDCALL) TYPE  QKZ OPTIONAL
*"     REFERENCE(IV_APPROVAL) TYPE  QKZ OPTIONAL
*"     REFERENCE(IV_NACHDRUCK) TYPE  QKZ OPTIONAL
*"     REFERENCE(IV_KZDAKKS) TYPE  QKZ OPTIONAL
*"     REFERENCE(IV_DIALOG) TYPE  QKZ OPTIONAL
*"     REFERENCE(IV_PRUEFLOS) TYPE  QPLOS OPTIONAL
*"     REFERENCE(IV_FILENAME) TYPE  CHAR255 OPTIONAL
*"     REFERENCE(IS_ITCPO) TYPE  ITCPO OPTIONAL
*"     REFERENCE(IS_ARCHIVE_INDEX) TYPE  TOA_DARA OPTIONAL
*"     REFERENCE(IS_ARCHIVE_PARAMETERS) TYPE  ARC_PARAMS OPTIONAL
*"     REFERENCE(IS_QALS) TYPE  QALS OPTIONAL
*"  EXCEPTIONS
*"      FORM_ERROR
*"      ACTION_CANCELLED
*"----------------------------------------------------------------------

  CONSTANTS:
    lc_form_pb    TYPE tdsfname VALUE 'YQMLIMS_PRUEFBERICHT',
    lc_form_legio TYPE tdsfname VALUE 'YQMLIMS_PRUEFBERICHT_LEGIO'.

  DATA: lv_kunnr TYPE kna1-kunnr,
        lv_parnr TYPE kna1-kunnr,
        lv_adrnr TYPE kna1-adrnr.

  DATA: lv_fm_name         TYPE rs38l_fnam,
*        lv_cont                 TYPE qkz,
        lv_approve         TYPE flag,
        lv_accept          TYPE flag,
*        lv_accept_kmv           TYPE flag,
        lv_reject          TYPE flag,
        lv_set_inact       TYPE flag,
        lv_estat_pbio      TYPE j_status,
*        lv_filesize             TYPE i,
*        lv_binlines             TYPE i,
*        lv_binwidth             TYPE i,
        lv_filename        TYPE string,
        ls_results         TYPE match_result,
        lt_results         TYPE match_result_tab,
*        lv_document_output_info TYPE ssfcrespd,
        ls_options         TYPE ssfcompop,
        ls_control         TYPE ssfctrlop,
        ls_job_output_info TYPE ssfcrescl,
*        ls_job_output_options   TYPE ssfcresop,
        lt_pdf             TYPE TABLE OF tline.

  DATA : lv_objnr    TYPE j_objnr,
         lv_formname TYPE tdsfname VALUE 'YQMLIMS_PRUEFBERICHT_LEGIO'.

  CLEAR ls_control.
  CLEAR ls_options.

  CLEAR gs_iflo.
  CLEAR gs_adrc.
  CLEAR gs_matn_tx.
  CLEAR gs_qals.
  CLEAR gs_qave.
  CLEAR gt_qapo.
  CLEAR gt_qapp.
  CLEAR gt_qasr.
  CLEAR gt_qamv.
  CLEAR gt_qprs.

  IF is_qals IS INITIAL.
    SELECT SINGLE * FROM qals INTO CORRESPONDING FIELDS OF gs_qals
      WHERE prueflos = iv_prueflos.
    IF sy-subrc <> 0.
      CLEAR gs_qals.
    ENDIF.
  ELSE.
    MOVE-CORRESPONDING is_qals TO gs_qals.
  ENDIF.

  SELECT SINGLE * FROM qave INTO CORRESPONDING FIELDS OF gs_qave
        WHERE prueflos = gs_qals-prueflos.
  IF sy-subrc <> 0.
    CLEAR gs_qave.
  ENDIF.

  SELECT * FROM qamv INTO CORRESPONDING FIELDS OF TABLE gt_qamv
        WHERE prueflos = gs_qals-prueflos.
  IF sy-subrc <> 0.
    CLEAR gt_qamv.
  ENDIF.

  SELECT * FROM qasr INTO CORRESPONDING FIELDS OF TABLE gt_qasr
        WHERE prueflos = gs_qals-prueflos.
  IF sy-subrc <> 0.
    CLEAR gt_qasr.
  ENDIF.

  SELECT * FROM qapp INTO CORRESPONDING FIELDS OF TABLE gt_qapp
        WHERE prueflos = gs_qals-prueflos.
  IF sy-subrc <> 0.
    CLEAR gt_qapp.
  ENDIF.


  IF gs_qals-slwbez = '910'.
* Prüfbericht für Legionellen
    lv_formname = lc_form_legio.
    LOOP AT gt_qapp INTO gs_qapp.

      IF NOT gs_qapp-phynr IS INITIAL.
        CONCATENATE 'QP' gs_qapp-phynr        INTO lv_objnr.
      ELSE.
        CONCATENATE 'QP' gs_qapp-userc1+6(12) INTO lv_objnr.
      ENDIF.

*    MOVE gs_qapp-userc1+6(12) TO gs_qapp-phynr.
*    CONCATENATE 'QP' gs_qapp-phynr INTO l_objnr.

      CALL FUNCTION 'STATUS_CHECK'
        EXPORTING
          objnr             = lv_objnr
          status            = 'I0076'
        EXCEPTIONS
          object_not_found  = 1
          status_not_active = 2
          OTHERS            = 3.
      IF sy-subrc = 0.
        DELETE TABLE gt_qapp FROM gs_qapp.
        CONTINUE.
      ENDIF.

      CALL FUNCTION 'STATUS_CHECK'
        EXPORTING
          objnr             = lv_objnr
          status            = 'I0043'
        EXCEPTIONS
          object_not_found  = 1
          status_not_active = 2
          OTHERS            = 3.
      IF sy-subrc = 0.
        DELETE TABLE gt_qapp FROM gs_qapp.
        CONTINUE.
      ENDIF.
      MODIFY gt_qapp FROM gs_qapp.
    ENDLOOP.

    CHECK NOT gt_qapp[] IS INITIAL.

    SELECT * FROM qprs INTO CORRESPONDING FIELDS OF TABLE gt_qprs
          FOR ALL ENTRIES IN gt_qapp
          WHERE phynr = gt_qapp-phynr.
    IF sy-subrc <> 0.
      CLEAR gt_qprs.
    ENDIF.
    LOOP AT gt_qprs INTO gs_qprs.
* Probenahmezeitpunkt ggf aus Prüflos füllen
      IF gs_qprs-entdatum IS INITIAL.
        gs_qprs-entdatum = gs_qals-yqm_probedatum.
      ENDIF.
      IF gs_qprs-entzeit = '      '.
        gs_qprs-entzeit = gs_qals-yqm_probezeit.
      ENDIF.
      MODIFY gt_qprs FROM gs_qprs.
    ENDLOOP.

    IF NOT gt_qprs[] IS INITIAL.
      LOOP AT gt_qapp INTO gs_qapp.
        READ TABLE gt_qprs INTO gs_qprs
          WITH KEY phynr = gs_qapp-phynr.
        IF sy-subrc = 0.
          gs_qapp-usern1 = gs_qprs-sortnr.
          MODIFY gt_qapp FROM gs_qapp.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ELSE.
* Allgemeiner Prüfbericht
    lv_formname = lc_form_pb.
  ENDIF.

  CALL FUNCTION 'QPAP_QAPO_READ_FROM_DB'
    EXPORTING
      i_qals       = gs_qals
    TABLES
      qapo_tab     = gt_qapo
    EXCEPTIONS
      no_operation = 1
      no_order     = 2
      OTHERS       = 3.
  IF sy-subrc <> 0.
* Implement suitable error handling here
    CLEAR gt_qapo.
  ENDIF.

  SORT gt_qamv.
  SORT gt_qasr.
  SORT gt_qapp.
  SORT gt_qapo.

  SELECT SINGLE * FROM iflo INTO gs_iflo
    WHERE tplnr = gs_qals-yqm_tplnr
    AND   spras = sy-langu.
  IF sy-subrc <> 0.
    CLEAR gs_iflo.
  ENDIF.

  lv_kunnr = gs_qals-kunnr.

  IF gs_qals-matnr IS INITIAL.
*     lese Partnerverwaltung
    PERFORM lese_ihpa USING gs_qals-aufnr
                   CHANGING lv_parnr sy-subrc.
  ELSE.
*     lese Partnerverwaltung
    PERFORM lese_sdauftrag USING gs_qals-kdauf
                        CHANGING lv_parnr sy-subrc
                                 lv_adrnr.

  ENDIF.

  IF sy-subrc = 0.
*     nimm Kundennummer aus Auftrag
    lv_kunnr = lv_parnr.
  ENDIF.

  PERFORM lese_debitor USING lv_kunnr lv_adrnr
                    CHANGING gs_adrc.

  SELECT SINGLE * FROM yqm_matn_tx_t INTO CORRESPONDING FIELDS OF gs_matn_tx
      WHERE matnr = gs_qals-matnr.
  IF sy-subrc <> 0.
    CLEAR gs_matn_tx.
  ENDIF.

  IF NOT is_itcpo IS INITIAL.

    ls_options-tdarmod   = is_itcpo-tdarmod.
    ls_options-tddest    = is_itcpo-tddest.
*---> Druckparameter, sofort ausgeben
*    ls_options-tdimmed   = ' '.
    ls_options-tdimmed   = 'X'.
*---> Druckparameter, eigene Spool ID
    ls_options-tdnewid   = 'X'.
    ls_options-tdsuffix1 = is_itcpo-tdsuffix1.
    ls_options-tdsuffix2 = is_itcpo-tdsuffix2.

    ls_control-langu     = sy-langu.
    ls_control-preview   = iv_preview.
    ls_control-getotf    = is_itcpo-tdgetotf.

    IF iv_dialog = 'X'.
      CLEAR ls_control-no_dialog.
    ELSE.
      ls_control-no_dialog = 'X'.
    ENDIF.

  ELSE.
*---> Spool: Ausgabegerät
    ls_options-tddest    = 'LOCL'.
*---> Druckparameter, sofort ausgeben
*    ls_options-tdimmed   = ' '.
    ls_options-tdimmed   = 'X'.
*---> Druckparameter, eigene Spool ID
    ls_options-tdnewid   = 'X'.

    ls_control-langu     = sy-langu.
    ls_control-preview   = iv_preview.
    ls_control-no_dialog = 'X'.
    ls_control-getotf    = 'X'.
  ENDIF.


  CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
    EXPORTING
      formname = lv_formname
    IMPORTING
      fm_name  = lv_fm_name
    EXCEPTIONS
      OTHERS   = 1.
  IF sy-subrc <> 0.
    RAISE form_error.
  ENDIF.

  CALL FUNCTION lv_fm_name
    EXPORTING
      archive_index      = is_archive_index
      archive_parameters = is_archive_parameters
      control_parameters = ls_control
      output_options     = ls_options
      user_settings      = space
      is_qals            = gs_qals
      is_qave            = gs_qave
      is_iflo            = gs_iflo
      is_adrc            = gs_adrc
      is_yq90101         = gs_matn_tx
      iv_pdf             = iv_pdf
      iv_pdf_prev        = iv_preview
      iv_udcall          = iv_udcall
      iv_approval        = iv_approval
      iv_nachdruck       = iv_nachdruck
      iv_kzdakks         = iv_kzdakks
    IMPORTING
*     document_output_info = lv_document_output_info
      job_output_info    = ls_job_output_info
*     job_output_options = ls_job_output_options
    TABLES
      it_qapp            = gt_qapp
      it_qapo            = gt_qapo
      it_qamv            = gt_qamv
      it_qasr            = gt_qasr
      it_qprs            = gt_qprs
    EXCEPTIONS
      user_canceled      = 1
      OTHERS             = 2.

  IF sy-subrc = 0.

    IF iv_preview = 'X'.
      IF iv_approval = 'X'. "sy-tcode = 'YQM_QA33'.
        lv_approve = gc_on.
      ELSE.
        CLEAR lv_approve.
      ENDIF.

      CALL FUNCTION 'Y_QMLIMS_SERVICE_PDF_PREVIEW'
        EXPORTING
          iv_approve               = lv_approve
          is_qals                  = gs_qals
          it_otf                   = ls_job_output_info-otfdata[]
        IMPORTING
          ev_accept                = lv_accept
          ev_reject                = lv_reject
        EXCEPTIONS
          convert_otf_to_pdf_error = 1
          cntl_error               = 2
          action_cancelled         = 3
          OTHERS                   = 4.
      CASE sy-subrc.
        WHEN 0.
          IF  lv_accept IS INITIAL
          AND lv_reject IS INITIAL.
*      Druckvorschau abgebrochen
*      --> nichts machen
          ELSE.
* Implement suitable error handling here
            IF lv_estat_pbio IS INITIAL.
              CALL FUNCTION 'STATUS_TEXT_CONVERSION'
                EXPORTING
*                 CLIENT             = SY-MANDT
                  language           = sy-langu
                  mode               = 'E'
                  objnr              = gs_qals-objnr
                  txt04              = 'PBIO'
                IMPORTING
                  status_number      = lv_estat_pbio
                EXCEPTIONS
                  insufficient_input = 1
                  not_found          = 2
                  object_not_found   = 3
                  wrong_mode         = 4
                  OTHERS             = 5.
              IF sy-subrc <> 0.
                MESSAGE a113(yqmlims) WITH 'PBIO'.
              ENDIF.

              IF     lv_accept = gc_on.
                lv_set_inact = gc_off.
              ELSEIF lv_reject = gc_on.
                lv_set_inact = gc_on.
              ENDIF.

              CALL FUNCTION 'STATUS_CHANGE_EXTERN'
                EXPORTING
                  objnr               = gs_qals-objnr
                  user_status         = lv_estat_pbio
                  set_inact           = lv_set_inact
                EXCEPTIONS
                  object_not_found    = 0
                  status_inconsistent = 0
                  status_not_allowed  = 0.
            ENDIF.
          ENDIF.
        WHEN 3.
          RAISE action_cancelled.
        WHEN OTHERS.
          RAISE form_error.
      ENDCASE.
    ENDIF.

* To Save Archive Object as well as status change
    COMMIT WORK AND WAIT.

    IF iv_pdf    = gc_on.
      CALL FUNCTION 'CONVERT_OTF'
        EXPORTING
          format                = 'PDF'
          max_linewidth         = 134
*        IMPORTING
*         bin_filesize          = lv_filesize
        TABLES
          otf                   = ls_job_output_info-otfdata[]
          lines                 = lt_pdf
        EXCEPTIONS
          err_max_linewidth     = 1
          err_format            = 2
          err_conv_not_possible = 3
          OTHERS                = 4.
      IF sy-subrc = 0.
        lv_filename = iv_filename.
        FIND ALL OCCURRENCES OF '\' IN lv_filename
          RESULTS lt_results.
        LOOP AT lt_results INTO ls_results.
        ENDLOOP.
        IF sy-subrc = 0.
          ls_results-offset = ls_results-offset + 1.
          SHIFT lv_filename RIGHT DELETING TRAILING '.pdf'.
          CONDENSE lv_filename.
          IF lv_filename IS NOT INITIAL.
            CONCATENATE lv_filename '.pdf' INTO lv_filename.
          ELSE.
            CONCATENATE gs_qals-prueflos
                        '_'
                        gs_qals-ktextmat
                        '_'
                        gs_qals-yqm_arktx '.pdf'
            INTO lv_filename.
          ENDIF.
        ENDIF.

        CALL FUNCTION 'GUI_DOWNLOAD'
          EXPORTING
*           bin_filesize            = lv_filesize
            filename                = lv_filename
            filetype                = 'BIN'
          TABLES
            data_tab                = lt_pdf
          EXCEPTIONS
            file_write_error        = 1
            no_batch                = 2
            gui_refuse_filetransfer = 3
            invalid_type            = 4
            no_authority            = 5
            unknown_error           = 6
            header_not_allowed      = 7
            separator_not_allowed   = 8
            filesize_not_allowed    = 9
            header_too_long         = 10
            dp_error_create         = 11
            dp_error_send           = 12
            dp_error_write          = 13
            unknown_dp_error        = 14
            access_denied           = 15
            dp_out_of_memory        = 16
            disk_full               = 17
            dp_timeout              = 18
            file_not_found          = 19
            dataprovider_exception  = 20
            control_flush_error     = 21
            OTHERS                  = 22.
        IF sy-subrc = 0.
*          MESSAGE s110 WITH lv_filename.
        ELSE.
          MESSAGE s161(0d) WITH 'Es erfolgt keine PDF-Ausgabe für' lv_filename.
        ENDIF.
      ENDIF.
    ENDIF.
  ELSE.
    MESSAGE s120(qm) WITH lv_formname.
    RAISE form_error.
  ENDIF.




ENDFUNCTION.
