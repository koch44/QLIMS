FUNCTION Y_QMLIMS_QET5_QPRS_UPDATE.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     REFERENCE(IS_QPRS) TYPE  QPRS
*"  EXPORTING
*"     REFERENCE(ES_QPRS) TYPE  QPRS
*"  EXCEPTIONS
*"      ACTION_CANCELLED
*"----------------------------------------------------------------------

  MOVE-CORRESPONDING IS_QPRS TO QPRS.

  CALL SCREEN 300 STARTING AT 1 1.

  MOVE-CORRESPONDING QPRS TO ES_QPRS.

ENDFUNCTION.
