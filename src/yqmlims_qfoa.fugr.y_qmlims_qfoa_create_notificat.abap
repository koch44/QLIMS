FUNCTION y_qmlims_qfoa_create_notificat.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     REFERENCE(I_QALS) LIKE  QALS STRUCTURE  QALS
*"     REFERENCE(I_QAVE) LIKE  QAVE STRUCTURE  QAVE
*"  EXPORTING
*"     VALUE(E_SUBRC) LIKE  SY-SUBRC
*"  TABLES
*"      E_PROTOCOL STRUCTURE  RQEVP
*"----------------------------------------------------------------------

  DATA: lv_text   TYPE text132,
        lv_answer TYPE char1,
        lv_create TYPE abap_bool VALUE abap_false,
        lv_mw     TYPE decfloat34.

  DATA: ls_qmel   TYPE qmel,
        ls_riqs5  TYPE riqs5,
        lt_return TYPE STANDARD TABLE OF bapiret2 WITH EMPTY KEY.

  e_subrc = 0.

  " Messwerte selektieren
  SELECT r~prueflos,
         r~vorglfnr,
         r~merknr,
         r~probenr,
         r~satzstatus,
         r~attribut,
         r~mittelwni,
         r~mittelwert
    FROM qasr AS r
    INNER JOIN qamv AS v
      ON  r~prueflos = v~prueflos
      AND r~vorglfnr = v~vorglfnr
      AND r~merknr   = v~merknr
    WHERE r~prueflos   = @i_qals-prueflos
      AND r~satzstatus = '5'
      AND v~verwmerkm  = '50001029'
    INTO TABLE @DATA(lt_qasr).
  IF sy-subrc <> 0.
    CLEAR lt_qasr.
  ENDIF.

  IF lt_qasr IS INITIAL.
    RETURN.
  ENDIF.

  CLEAR ls_riqs5.
  ls_riqs5-qmart    = 'YL'.
  ls_riqs5-prueflos = i_qals-prueflos.
  ls_riqs5-kunum    = i_qals-kunnr.

  " Größten Mittelwert bestimmen
  SORT lt_qasr BY mittelwert DESCENDING.
  READ TABLE lt_qasr INTO DATA(ls_qasr) INDEX 1.
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  " Mittelwert numerisch bewerten (statt Stringvergleich)
  TRY.
      lv_mw = CONV decfloat34( ls_qasr-mittelwert ).
    CATCH cx_sy_conversion_no_number cx_sy_conversion_overflow.
      " Wenn nicht numerisch interpretierbar -> nichts tun
      e_subrc = 8.
      RETURN.
  ENDTRY.

  CLEAR lv_create.

  IF lv_mw <= 100.
    ls_riqs5-priok = '9'.
    ls_riqs5-qmkat = 'D'.
    ls_riqs5-qmgrp = 'YQM-LB'.
    ls_riqs5-qmcod = 'TMW0'.

  ELSEIF lv_mw <= 1000.
    ls_riqs5-priok = '3'.
    ls_riqs5-qmkat = 'D'.
    ls_riqs5-qmgrp = 'YQM-LB'.
    ls_riqs5-qmcod = 'TMW1'.
    lv_create      = abap_true.

  ELSEIF lv_mw <= 10000.
    ls_riqs5-priok = '2'.
    ls_riqs5-qmkat = 'D'.
    ls_riqs5-qmgrp = 'YQM-LB'.
    ls_riqs5-qmcod = 'TMW2'.
    lv_create      = abap_true.

  ELSE.
                                                            " > 10000
    ls_riqs5-priok = '1'.
    ls_riqs5-qmkat = 'D'.
    ls_riqs5-qmgrp = 'YQM-LB'.
    ls_riqs5-qmcod = 'TMW3'.
    lv_create      = abap_true.
  ENDIF.

  IF lv_create = abap_true.

    " Existiert schon eine Meldung zum Prüflos?
    SELECT SINGLE qmnum, prueflos
      FROM qmel
      WHERE prueflos = @i_qals-prueflos
      INTO CORRESPONDING FIELDS OF @ls_qmel.

    IF sy-subrc = 0 AND ls_qmel-qmnum IS NOT INITIAL.

      CONCATENATE TEXT-031 ls_qmel-qmnum TEXT-032 INTO lv_text SEPARATED BY space.

      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = TEXT-030
          text_question         = lv_text
          text_button_1         = 'Ja'(033)
          text_button_2         = 'Nein'(034)
          default_button        = '2'
          display_cancel_button = space
        IMPORTING
          answer                = lv_answer
        EXCEPTIONS
          OTHERS                = 2.

      " wenn Popup nicht ok oder nicht bestätigt -> nicht erstellen
      IF sy-subrc <> 0 OR lv_answer <> '1'.
        lv_create = abap_false.
      ENDIF.

    ENDIF.
  ENDIF.

  IF lv_create = abap_true.

    CLEAR: lt_return.

    CALL FUNCTION 'IQS4_CREATE_NOTIFICATION'
      EXPORTING
        i_riqs5            = ls_riqs5
        i_task_det         = space
        i_commit           = 'X'
        i_wait             = 'X'
        i_refresh_complete = 'X'
        i_check_parnr_comp = space
      TABLES
        return             = lt_return.


*   generation successful?
    CALL FUNCTION 'IQS4_CHECK_ERROR_SEVERE'
      TABLES
        return       = lt_return
      EXCEPTIONS
        severe_error = 1
        OTHERS       = 2.

    IF sy-subrc IS INITIAL.
*      CALL FUNCTION 'IQS4_SAVE_NOTIFICATION'
*        EXPORTING
*          i_qmnum  = ls_viqmel-qmnum
*        IMPORTING
*          e_viqmel = ls_viqmel.
*
*      COMMIT WORK.

    ELSE.
      e_subrc = 8.
      RETURN.
    ENDIF.

  ENDIF.

ENDFUNCTION.
