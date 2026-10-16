FUNCTION Y_QMLIMS_QET5_PAGE_LEFT_RIGHT.
*"--------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     VALUE(I_OK_CODE) LIKE  T185-FCODE
*"--------------------------------------------------------------------
  DATA: L_MAX_COL TYPE I.

  L_MAX_COL = G_MAX_COL_NO - G_PS_FIX_COLS.
  IF L_MAX_COL < 1.
    L_MAX_COL = 1.
  ENDIF.

  CASE I_OK_CODE.

    WHEN 'QETBPS++'.
      G_PS_BEGIN = L_MAX_COL.

    WHEN 'QETBPS+'.
      G_PS_BEGIN = G_PS_BEGIN + 1.

    WHEN 'QETBPS-'.
      G_PS_BEGIN = G_PS_BEGIN - 1.

    WHEN 'QETBPS--'.
      G_PS_BEGIN = 1.

  ENDCASE.

  IF G_PS_BEGIN < 1.
    G_PS_BEGIN = 1.
  ENDIF.

  IF G_PS_BEGIN > L_MAX_COL.
    G_PS_BEGIN = L_MAX_COL.
  ENDIF.

  PERFORM CREATE_SCREEN.


ENDFUNCTION.
