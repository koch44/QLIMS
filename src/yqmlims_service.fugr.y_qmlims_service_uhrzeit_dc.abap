FUNCTION y_qmlims_service_uhrzeit_dc.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     REFERENCE(CHARACT_NO) TYPE  CABN-ATINN
*"     REFERENCE(CHARACT) TYPE  CABN-ATNAM
*"     REFERENCE(VALUE) TYPE  CAWN-ATWRT
*"     REFERENCE(LANGUAGE) TYPE  SY-LANGU
*"  EXPORTING
*"     REFERENCE(DESCRIPTION) TYPE  CAWNT-ATWTB
*"  EXCEPTIONS
*"      NOT_FOUND
*"----------------------------------------------------------------------

  description = value.

ENDFUNCTION.
