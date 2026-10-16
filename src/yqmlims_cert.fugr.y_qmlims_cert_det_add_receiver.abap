FUNCTION y_qmlims_cert_det_add_receiver.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     REFERENCE(is_qals) TYPE qals
*"  TABLES
*"      t_receiver STRUCTURE somlreci1 OPTIONAL
*"----------------------------------------------------------------------

  DATA:
    lv_objnr        TYPE ihpa-objnr,
    lv_adrnr_sd     TYPE ihpavb-adrnr_kupav,
    lv_adrnp        TYPE ihpavb-adrnp,
    lv_window_title TYPE text40.

  DATA:
    ls_diadr        TYPE diadr,
    ls_adr6         TYPE adr6,
    ls_ihpa         TYPE ihpa,
    ls_receiver     TYPE somlreci1,
    ls_add_receiver TYPE yqm_cert_add_receiver,
    ls_return       TYPE ddshretval.

  DATA:
    lt_adr6         TYPE STANDARD TABLE OF adr6,
    lt_ihpa         TYPE STANDARD TABLE OF ihpa,
    lt_add_receiver TYPE STANDARD TABLE OF yqm_cert_add_receiver,
    lt_return       TYPE STANDARD TABLE OF ddshretval.

  CONCATENATE 'OR' is_qals-aufnr INTO lv_objnr.

  SELECT objnr,
         parvw,
         parnr
    FROM ihpa
    INTO CORRESPONDING FIELDS OF TABLE @lt_ihpa
    WHERE objnr = @lv_objnr
      AND parvw = 'ZQ'.

  IF sy-subrc <> 0.
    CLEAR lt_ihpa.
    RETURN.
  ENDIF.

  LOOP AT lt_ihpa INTO ls_ihpa.

    CALL FUNCTION 'PM_PARTNER_READ'
      EXPORTING
        parvw                  = 'ZQ'
        parnr                  = ls_ihpa-parnr
      IMPORTING
        diadr_wa               = ls_diadr
        adrnr_sd               = lv_adrnr_sd
        adrnp                  = lv_adrnp
      EXCEPTIONS
        no_valid_parnr         = 1
        no_valid_parnr_today   = 2
        no_authority           = 3
        parvw_and_nrart_inital = 4
        OTHERS                 = 5.

    IF sy-subrc = 0.

      SELECT addrnumber,
             persnumber,
             smtp_addr
        FROM adr6
        INTO CORRESPONDING FIELDS OF TABLE @lt_adr6
        WHERE addrnumber = @lv_adrnr_sd
          AND persnumber = @lv_adrnp.

      IF sy-subrc = 0.
        LOOP AT lt_adr6 INTO ls_adr6.
          CLEAR ls_add_receiver.
          MOVE-CORRESPONDING ls_diadr TO ls_add_receiver.
          MOVE-CORRESPONDING ls_adr6  TO ls_add_receiver.
          APPEND ls_add_receiver TO lt_add_receiver.
        ENDLOOP.
      ENDIF.

    ENDIF.
  ENDLOOP.

  IF lt_add_receiver IS NOT INITIAL.

    lv_window_title = TEXT-001.

    CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
      EXPORTING
        ddic_structure  = 'YQM_CERT_ADD_RECEIVER'
        retfield        = 'SMTP_ADDR'
        window_title    = lv_window_title
        value_org       = 'S'
        multiple_choice = 'X'
      TABLES
        value_tab       = lt_add_receiver
        return_tab      = lt_return
      EXCEPTIONS
        parameter_error = 1
        no_values_found = 2
        OTHERS          = 3.

    IF sy-subrc = 0.
      LOOP AT lt_return INTO ls_return.

        READ TABLE lt_add_receiver INTO ls_add_receiver
             WITH KEY smtp_addr = ls_return-fieldval.
        IF sy-subrc = 0.
          CLEAR ls_receiver.
          ls_receiver-receiver = ls_add_receiver-smtp_addr.
          ls_receiver-rec_type = 'U'.
          APPEND ls_receiver TO t_receiver.
        ENDIF.

      ENDLOOP.
    ENDIF.

  ENDIF.

ENDFUNCTION.
