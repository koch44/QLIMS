DATA:
  lv_field_order TYPE char32,
  ls_smtp        TYPE adsmtp,
  lt_smtp        TYPE STANDARD TABLE OF adsmtp.

FIELD-SYMBOLS <lv_order> TYPE any.

gv_order = is_tpk-order01.

IF iv_prnda+4(2) <> '01'.
  CONCATENATE 'IS_TPK-ORDER' iv_prnda+4(2) INTO lv_field_order.
  ASSIGN (lv_field_order) TO <lv_order>.
  IF sy-subrc = 0 AND <lv_order> IS NOT INITIAL.
    gv_order = <lv_order>.
  ENDIF.
ENDIF.

IF is_adrc_tplnr-name1 IS NOT INITIAL.
  MOVE-CORRESPONDING is_adrc_tplnr TO gs_adrc.
ELSE.
  MOVE-CORRESPONDING is_adrc_tplma TO gs_adrc.
ENDIF.

CALL FUNCTION 'ADDR_COMM_GET'
  EXPORTING
    address_number    = gs_adrc-addrnumber
    table_type        = 'ADSMTP'
  TABLES
    comm_table        = lt_smtp
  EXCEPTIONS
    parameter_error   = 1
    address_not_exist = 2
    internal_error    = 3
    address_blocked   = 4
    OTHERS            = 5.

IF sy-subrc = 0.
  CLEAR gv_email.

  LOOP AT lt_smtp INTO ls_smtp WHERE flgdefault = abap_true.
    gv_email = ls_smtp-smtp_addr.
    EXIT.
  ENDLOOP.
ELSE.
  CLEAR gv_email.
ENDIF.

IF is_tpk-pn_ma IS NOT INITIAL.
  SELECT SINGLE kname
    FROM yqm_pruefer_t
    INTO CORRESPONDING FIELDS OF @gs_pruefer
    WHERE kname = @is_tpk-pn_ma.

  IF sy-subrc <> 0.
    CLEAR gs_pruefer.
  ENDIF.
ENDIF.
