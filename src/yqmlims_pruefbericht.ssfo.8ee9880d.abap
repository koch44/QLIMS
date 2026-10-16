
CALL FUNCTION 'ADDRESS_INTO_PRINTFORM'
  EXPORTING
    address_type                   = '1'
    address_number                 = is_adrc-addrnumber
    no_upper_case_for_city         = 'X'
  IMPORTING
    address_printform_table        = gt_address
  EXCEPTIONS
    address_blocked                = 1
    person_blocked                 = 2
    contact_person_blocked         = 3
    addr_to_be_formated_is_blocked = 4
    OTHERS                         = 5.
IF sy-subrc = 0.
* Implement suitable error handling here
  DELETE gt_address WHERE line_type NA '1234SO'.
ENDIF.





















