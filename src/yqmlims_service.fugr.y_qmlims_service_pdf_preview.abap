FUNCTION y_qmlims_service_pdf_preview.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     REFERENCE(IV_APPROVE) TYPE  FLAG OPTIONAL
*"     REFERENCE(IS_QALS) TYPE  QALS OPTIONAL
*"     REFERENCE(IT_OTF) TYPE  TSFOTF
*"  EXPORTING
*"     REFERENCE(EV_ACCEPT) TYPE  FLAG
*"     REFERENCE(EV_REJECT) TYPE  FLAG
*"  EXCEPTIONS
*"      CONVERT_OTF_TO_PDF_ERROR
*"      CNTL_ERROR
*"      ACTION_CANCELLED
*"----------------------------------------------------------------------

  DATA:
    lt_dummy      TYPE STANDARD TABLE OF tline,
    lv_estat_mvid TYPE j_status.

  CLEAR: gv_pdf_data,
         gv_pdf_size.

  gv_approve = iv_approve.

  SELECT SINGLE matnr
    FROM mara
    INTO CORRESPONDING FIELDS OF @gs_mara
    WHERE matnr = @is_qals-matnr.

  IF sy-subrc <> 0.
    CLEAR gs_mara.
  ENDIF.

  " Convert OTF to PDF
  CALL FUNCTION 'CONVERT_OTF'
    EXPORTING
      format                = 'PDF'
    IMPORTING
      bin_filesize          = gv_pdf_size
      bin_file              = gv_pdf_data
    TABLES
      otf                   = it_otf[]
      lines                 = lt_dummy
    EXCEPTIONS
      err_max_linewidth     = 1
      err_format            = 2
      err_conv_not_possible = 3
      OTHERS                = 4.

  IF sy-subrc <> 0.
    RAISE convert_otf_to_pdf_error.
  ENDIF.

  CALL SCREEN 0300 STARTING AT 1 1.

  IF iv_approve = 'X'
     AND ( sy-ucomm = gc_fcode_cancel
        OR sy-ucomm = gc_fcode_enter ).
    " Wenn der Aufruf im Genehmigungsmodus erfolgt, dürfen CANCEL und ENTER
    " nicht zur Erzeugung des Prüfberichts führen
    RAISE action_cancelled.
  ENDIF.

  CLEAR: ev_accept,
         ev_reject.

  IF gv_accept = 'X'.

    ev_accept = gv_accept.

  ELSEIF gv_accept_kmv = 'X'.

    ev_accept = gv_accept_kmv.

    IF lv_estat_mvid IS INITIAL.
      CALL FUNCTION 'STATUS_TEXT_CONVERSION'
        EXPORTING
          language           = sy-langu
          mode               = 'E'
          objnr              = is_qals-objnr
          txt04              = 'MVID'
        IMPORTING
          status_number      = lv_estat_mvid
        EXCEPTIONS
          insufficient_input = 1
          not_found          = 2
          object_not_found   = 3
          wrong_mode         = 4
          OTHERS             = 5.

      IF sy-subrc <> 0.
        MESSAGE i203(yqmlims) WITH is_qals-prueflos.
      ENDIF.
    ENDIF.

    CALL FUNCTION 'STATUS_CHANGE_EXTERN'
      EXPORTING
        objnr               = is_qals-objnr
        user_status         = lv_estat_mvid
        set_inact           = 'X'
      EXCEPTIONS
        object_not_found    = 2
        status_inconsistent = 4
        status_not_allowed  = 6.

    CASE sy-subrc.
      WHEN 0.
        " COMMIT WORK AND WAIT.
      WHEN OTHERS.
        MESSAGE i208(yqmlims) WITH is_qals-prueflos.
    ENDCASE.

  ELSEIF gv_reject = 'X'.

    ev_reject = gv_reject.

  ENDIF.

ENDFUNCTION.
