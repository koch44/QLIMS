*----------------------------------------------------------------------*
***INCLUDE LYQMLIMS_SERVICEI01.
*----------------------------------------------------------------------*
MODULE user_command_0050 INPUT.
  CASE gv_ok_code.
    WHEN 'ENTR'.
      LEAVE TO SCREEN 0.
    WHEN 'CANC'.
      CLEAR gv_kostl.
      LEAVE TO SCREEN 0.
  ENDCASE.
  CLEAR gv_ok_code.
ENDMODULE.                             " USER_COMMAND_0050  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHECK_COST_CENTER  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_cost_center INPUT.
  PERFORM check_cost_center.
ENDMODULE.                             " CHECK_COST_CENTER  INPUT
*&---------------------------------------------------------------------*
*&      Module  HTML_CONTROL  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE html_control INPUT.
  perform pai_html_control.
ENDMODULE.
