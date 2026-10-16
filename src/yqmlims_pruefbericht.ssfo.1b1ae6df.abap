DATA: ls_address_selection TYPE addr1_sel.

IF NOT is_iflo-adrnr IS INITIAL.
  ls_address_selection-addrnumber = is_iflo-adrnr.

  CALL FUNCTION 'ADDR_GET'
    EXPORTING
      address_selection = ls_address_selection
    IMPORTING
      sadr              = gs_sadr
    EXCEPTIONS
      parameter_error   = 1
      address_not_exist = 2
      version_not_exist = 3
      internal_error    = 4
      address_blocked   = 5
      OTHERS            = 6.
  IF sy-subrc <> 0.
* Implement suitable error handling here
    CLEAR gs_sadr.
  ENDIF.
ELSE.
  CLEAR gs_sadr.
ENDIF.





















