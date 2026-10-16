DATA: lv_stellen    TYPE cha_class_data-stellen.
DATA: lv_fltp_value TYPE cha_class_data-sollwert.
DATA: lv_char_value TYPE cha_class_view-sollwert.

READ TABLE it_qamv INTO gs_qamv
  WITH KEY verwmerkm = gv_merknr_03.
IF sy-subrc <> 0.
  CLEAR gs_qamv.
ENDIF.

IF NOT gs_qamv-masseinhsw IS INITIAL.
  READ TABLE gt_t006a INTO gs_t006a
    WITH KEY spras    = sy-langu
             msehi    = gs_qamv-masseinhsw.
  IF sy-subrc <> 0.
    CLEAR gs_t006a.
  ENDIF.
ELSE.
  CLEAR gs_t006a.
ENDIF.

lv_stellen    = gs_qamv-stellen.
lv_fltp_value = gs_qamv-toleranzob.

IF NOT gs_qamv-tolobni IS INITIAL.

  CALL FUNCTION 'QSS0_FLTP_TO_CHAR_CONVERSION'
    EXPORTING
      i_number_of_digits       = lv_stellen
      i_fltp_value             = lv_fltp_value
      i_value_not_initial_flag = gs_qamv-tolobni
    IMPORTING
      e_char_field             = lv_char_value.

  gv_grenzwert = lv_char_value.
  SHIFT gv_grenzwert LEFT DELETING LEADING space.
ELSE.
  gv_grenzwert = gc_na.
ENDIF.
