*----------------------------------------------------------------------*
***INCLUDE ZXQQMF01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form new_okcode
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM new_okcode .

  FIELD-SYMBOLS: <lv_okcode>.
  DATA: lv_field_name(40) TYPE c.
  DATA: lv_okcode TYPE sy-ucomm.

  lv_okcode = 'ENT1'.
  lv_field_name = '(SAPLIQS0)OK-CODE'.
  ASSIGN (lv_field_name) TO <lv_okcode>.
  IF sy-subrc = 0.
    <lv_okcode> = lv_okcode.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_ok_code
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- L_OKCODE
*&---------------------------------------------------------------------*
FORM get_ok_code  CHANGING cv_okcode.

  FIELD-SYMBOLS: <lv_okcode>.
  DATA: lv_field_name(40) TYPE c.

  lv_field_name = '(SAPLIQS0)OK-CODE'.
  ASSIGN (lv_field_name) TO <lv_okcode>.
  cv_okcode = <lv_okcode>.

ENDFORM.
