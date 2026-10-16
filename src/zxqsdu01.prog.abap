*&---------------------------------------------------------------------*
*& Include          ZXQSDU01
*&---------------------------------------------------------------------*
e_dummy10  = i_qpmk-dummy10.
e_dummy20  = i_qpmk-dummy20.
e_dummy40  = i_qpmk-dummy40.

gv_dummy10 = i_qpmk-dummy10.
gv_dummy20 = i_qpmk-dummy20.
gv_dummy40 = i_qpmk-dummy40.

gv_werk    = i_qpmk-werks.

CALL SCREEN 0100 STARTING AT 10 10
                 ENDING   AT 82 21.

CASE gv_ok_code.
  WHEN 'ABBR'.
  WHEN 'ENT1'.
    e_dummy10 = gv_dummy10.
    e_dummy20 = gv_dummy20.
    e_dummy40 = gv_dummy40.
ENDCASE.
