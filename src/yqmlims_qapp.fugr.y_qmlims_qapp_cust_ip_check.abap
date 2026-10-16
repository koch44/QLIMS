FUNCTION y_qmlims_qapp_cust_ip_check.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     REFERENCE(I_QALS) LIKE  QALS STRUCTURE  QALS
*"     REFERENCE(I_QAPP) LIKE  QAPP STRUCTURE  QAPP
*"     REFERENCE(I_VORGLFNR) LIKE  QAPO-VORGLFNR
*"  TABLES
*"      T_QAPP STRUCTURE  QAPP
*"      T_QAPO STRUCTURE  QAPO
*"----------------------------------------------------------------------

  DATA: lv_name_qappd TYPE char30 VALUE '(SAPLQAPP)QAPPD'.

  FIELD-SYMBOLS <ls_qappd> TYPE qappd.

  CHECK i_qals-slwbez = '910'.

  ASSIGN (lv_name_qappd) TO <ls_qappd>.
  IF sy-subrc = 0.
    <ls_qappd>-phynr = <ls_qappd>-userc1+6(12).
  ENDIF.


ENDFUNCTION.
