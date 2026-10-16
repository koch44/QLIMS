FUNCTION Y_QMLIMS_SERVICE_QPVK.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     REFERENCE(CHARACT_NO) TYPE  CABN-ATINN
*"     REFERENCE(CHARACT) TYPE  CABN-ATNAM
*"     REFERENCE(VALUE) TYPE  CAWN-ATWRT
*"  EXPORTING
*"     REFERENCE(VALUE_EX) TYPE  CAWN-ATWRT
*"  EXCEPTIONS
*"      NOT_FOUND
*"----------------------------------------------------------------------

  value_ex = value.

ENDFUNCTION.
