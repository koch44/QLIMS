*----------------------------------------------------------------------*
***INCLUDE ZXQPAI01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.

  CASE gv_ok_code.
    WHEN 'ABBR'.
      SET SCREEN 0.
    WHEN 'ENT1'.
      SET SCREEN 0.
  ENDCASE.

ENDMODULE.                 " USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*&      Module  CHECK_LEISTUNGSART  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_leistungsart INPUT.

* Leistungsart o.k.       --> in dummy10_exp enthalten
* Leistungsart nicht o.k. --> Systemmeldung
  CALL FUNCTION 'Y_QMLIMS_SERVICE_LEISTUNGSART'
    EXPORTING
      iv_search_gen = 'X' "generische Suche (mit *) erlaubt
      iv_werks      = gv_werk
      iv_dummy10    = gv_dummy10
    IMPORTING
      ev_dummy10    = gv_dummy10.

ENDMODULE.
