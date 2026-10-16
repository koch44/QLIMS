*----------------------------------------------------------------------*
***INCLUDE LYQMLIMS_QFOAO01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  STATUS_0200  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0200 OUTPUT.

  IF gv_no_editor = 'X'.
    SET PF-STATUS '0200'.
    SET TITLEBAR  '0200'.
  ELSE.
    SET PF-STATUS '0200_2'.
    SET TITLEBAR  '0200_2'.
  ENDIF.


ENDMODULE.                 " STATUS_0200  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  CREATE_AND_INIT_CONTROLS  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE create_and_init_controls OUTPUT.

  IF gv_alv IS INITIAL.
    PERFORM create_and_init_controls.
  ENDIF.

ENDMODULE.                 " CREATE_AND_INIT_CONTROLS  OUTPUT.
