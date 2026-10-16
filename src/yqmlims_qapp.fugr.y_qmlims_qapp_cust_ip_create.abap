FUNCTION y_qmlims_qapp_cust_ip_create.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     REFERENCE(I_QALS) TYPE  QALS
*"  TABLES
*"      QAPO_TAB STRUCTURE  QAPO
*"      QAMV_TAB STRUCTURE  QAMV
*"      QASV_TAB STRUCTURE  QASV
*"----------------------------------------------------------------------


  DATA:
    ls_qapo     TYPE qapo,
    ls_qasv     TYPE qasv,
    ls_qals     TYPE qals,
    ls_qppsv    TYPE qppsv_ip_chartab,
    ls_tq79     TYPE tq79,
    lt_qppsvtab TYPE STANDARD TABLE OF qppsv_ip_chartab.

  " Step 0   Checks and getting order

  " Inspection point processing active for inspection lot?
  CHECK i_qals-stat07 IS NOT INITIAL.

  ls_qals = i_qals.

  " Get inspection point data
  CALL FUNCTION 'QAFD_TQ79_READ'
    EXPORTING
      i_slwbez  = ls_qals-slwbez
    IMPORTING
      e_tq79    = ls_tq79
    EXCEPTIONS
      not_found = 1
      OTHERS    = 2.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  " The function module is used to create inspection points for inspection lots
  " without physical samples
  CHECK ls_tq79-usern2akt = '1'
    AND ls_tq79-userc1akt IS INITIAL
    AND ls_tq79-userc2akt IS INITIAL
    AND ls_tq79-usern1akt IS INITIAL
    AND ls_tq79-userd1akt IS INITIAL
    AND ls_tq79-usert1akt IS INITIAL.

  " Step 1    Preparation of inspection points
  LOOP AT qapo_tab INTO ls_qapo
       WHERE kzfeat IS NOT INITIAL.

    CLEAR: ls_qppsv,
           ls_qasv.

    " Step 1.1  Get all characteristics for one operation
    LOOP AT qasv_tab INTO ls_qasv
         WHERE mandant  = sy-mandt
           AND prueflos = ls_qals-prueflos
           AND vorglfnr = ls_qapo-vorglfnr.
      APPEND ls_qasv TO ls_qppsv-chartab.
    ENDLOOP.

    " Step 1.2 Determine inspection point identification
    ls_qppsv-ip-mandt     = sy-mandt.
    ls_qppsv-ip-prueflos  = ls_qals-prueflos.
    ls_qppsv-ip-vorglfnr  = ls_qapo-vorglfnr.
    ls_qppsv-ip-kzptlbest = ls_qapo-qkztlsbest.

    IF ls_tq79-usern2akt = '1'.
      ls_qppsv-ip-usern2 = 1.
      APPEND ls_qppsv TO lt_qppsvtab.
    ENDIF.

  ENDLOOP.

  " Step 2  Create table qapp (inspection points) and samples (QASV)
  CHECK lt_qppsvtab IS NOT INITIAL.

  CALL FUNCTION 'QAPP_IP_CREATE_QASVTAB_QAPPTAB'
    EXPORTING
      i_qals                = ls_qals
    TABLES
      qppsv_tab             = lt_qppsvtab
      qasv_tab              = qasv_tab
      qamv_tab              = qamv_tab
      qapo_tab              = qapo_tab
    EXCEPTIONS
      x_lot_is_initial      = 1
      x_tq79_not_maintained = 2
      x_error_message_qrk   = 3
      x_foreign_lock_qash   = 4
      OTHERS                = 5.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.


ENDFUNCTION.
