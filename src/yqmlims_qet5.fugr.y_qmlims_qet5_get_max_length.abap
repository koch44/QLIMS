FUNCTION Y_QMLIMS_QET5_GET_MAX_LENGTH.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  EXPORTING
*"     REFERENCE(E_LEN_MAX) TYPE  I
*"----------------------------------------------------------------------

  DATA: L_LEN_MAX         LIKE USPARAM-PARVA.

  GET PARAMETER ID 'YQMLIMS_MAXLENGTH' FIELD L_LEN_MAX.

  G_LEN_MAX = L_LEN_MAX.

  CALL SCREEN 0200 STARTING AT  1  1
                   ENDING   AT 40  5.

  IF  OK-CODE = 'ENT1'
  AND G_LEN_MAX > 0.
    E_LEN_MAX = G_LEN_MAX.
  ELSE.
    CLEAR E_LEN_MAX.
  ENDIF.

ENDFUNCTION.
