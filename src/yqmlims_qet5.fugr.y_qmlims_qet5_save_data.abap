FUNCTION Y_QMLIMS_QET5_SAVE_DATA.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     VALUE(I_ROLLBACK) TYPE  FLAG OPTIONAL
*"----------------------------------------------------------------------

  IF SAVE_FLAG = 'X'.
    IF I_ROLLBACK = 'X'.
      ROLLBACK WORK.
    ELSE.
      COMMIT WORK.
      CLEAR SAVE_FLAG.
    ENDIF.
  ENDIF.

ENDFUNCTION.
