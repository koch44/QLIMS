FUNCTION Y_QMLIMS_QET1_CANCEL_GRAPHICS.
*"--------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"--------------------------------------------------------------------

 IF NOT G_CLOSE_GRAPHICS IS INITIAL.
   call function 'QRKD_CANCEL_GRAPHICS'.
   clear G_CLOSE_GRAPHICS.
 ENDIF.

ENDFUNCTION.
