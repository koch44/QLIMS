DATA: ls_address_selection TYPE addr1_sel.

IF NOT is_iflo-adrnr IS INITIAL.
  ls_address_selection-addrnumber = is_iflo-adrnr.

  CALL FUNCTION 'ADDR_GET'
    EXPORTING
      address_selection = ls_address_selection
*     ADDRESS_GROUP     =
*     READ_SADR_ONLY    = ' '
*     READ_TEXTS        = ' '
*     IV_CURRENT_COMM_DATA          = ' '
*     BLK_EXCPT         =
    IMPORTING
*     ADDRESS_VALUE     =
*     ADDRESS_ADDITIONAL_INFO       =
*     RETURNCODE        =
*     ADDRESS_TEXT      =
      sadr              = gs_sadr
* TABLES
*     ADDRESS_GROUPS    =
*     ERROR_TABLE       =
*     VERSIONS          =
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






















