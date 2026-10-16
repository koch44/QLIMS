FUNCTION y_qmlims_qfoa_create_certifica.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     REFERENCE(I_QALS) LIKE  QALS STRUCTURE  QALS
*"     REFERENCE(I_QAVE) LIKE  QAVE STRUCTURE  QAVE
*"     VALUE(I_RESEND) TYPE  FLAG OPTIONAL
*"  EXPORTING
*"     VALUE(E_SUBRC) LIKE  SY-SUBRC
*"  TABLES
*"      E_PROTOCOL STRUCTURE  RQEVP
*"----------------------------------------------------------------------

  TYPES:
    BEGIN OF lty_toa,
      sap_object TYPE toa01-sap_object,
      object_id  TYPE toa01-object_id,
      arc_doc_id TYPE toa01-arc_doc_id,
      ar_date    TYPE toa01-ar_date,
      creatime   TYPE toaat-creatime,
      descr      TYPE toaat-descr,
    END OF lty_toa,

    BEGIN OF lty_object,
      object_id TYPE saeobjid,
    END OF lty_object,

    BEGIN OF lty_qals_sel,
      prueflos TYPE qals-prueflos,
      objnr    TYPE qals-objnr,
      stat35   TYPE qals-stat35,
    END OF lty_qals_sel.

  DATA:
    lv_no_processing   TYPE c,
    lv_cont            TYPE c,
    lv_commit          TYPE c,
    lv_vbpe            TYPE c,
    lv_objnr           TYPE j_objnr,
    lv_kosten          TYPE flag,
    lv_new_version     TYPE flag,
    lv_initial_version TYPE flag,
    lv_subrc           TYPE sy-subrc,
    lv_estat_apbe      TYPE j_status,
    lv_estat_vpbe      TYPE j_status,
    lv_ar_date         TYPE sy-datum,
    lv_ar_time         TYPE sy-uzeit,
    lv_found           TYPE flag,
    lv_text            TYPE text255.

  DATA:
    ls_toa      TYPE lty_toa,
    lt_toa      TYPE STANDARD TABLE OF lty_toa WITH EMPTY KEY,
    lt_last_toa TYPE STANDARD TABLE OF lty_toa WITH EMPTY KEY,
    ls_toa01    TYPE toa01,
    lt_toa01    TYPE STANDARD TABLE OF toa01 WITH EMPTY KEY.

  DATA:
    ls_arpbhd TYPE yqm_arpbhd_t,
    lt_kt     TYPE STANDARD TABLE OF yqm_vnltkt_t WITH EMPTY KEY.

  DATA:
    ls_qals     TYPE qals,
    ls_qals_rel TYPE lty_qals_sel,
    lt_qals_rel TYPE STANDARD TABLE OF lty_qals_sel WITH EMPTY KEY.

  DATA:
    lt_object TYPE STANDARD TABLE OF lty_object WITH EMPTY KEY.

  DATA:
    ls_yqarpblg TYPE yqm_arpblg_t,
    lt_yqarpblg TYPE STANDARD TABLE OF yqm_arpblg_t WITH EMPTY KEY.

  DATA:
    ls_receiver TYPE somlreci1,
    lt_receiver TYPE STANDARD TABLE OF somlreci1 WITH EMPTY KEY.

  e_subrc = 0.

  CLEAR: lv_no_processing,
         lv_new_version,
         lv_initial_version,
         lv_commit,
         lv_vbpe,
         lv_found.

  CLEAR lt_toa01.

  ls_qals = i_qals.

  " Kennzeichen Kostenbericht: wenn kein Logeintrag existiert -> X
*  SELECT SINGLE *
*    FROM yqm_arpblg_t
*    WHERE prueflos = @ls_qals-prueflos
*    INTO @ls_yqarpblg.
*  IF sy-subrc = 0.
*    CLEAR lv_kosten.
*  ELSE.
*    lv_kosten = 'X'.
*  ENDIF.

  CLEAR lv_kosten.

  " Kennzeichen Kostenbericht: wenn kein Logeintrag existiert -> X
  SELECT SINGLE @abap_true
    FROM yqm_arpblg_t
    WHERE prueflos = @ls_qals-prueflos
    INTO @DATA(lv_log_exists).

  IF sy-subrc <> 0.
    lv_kosten = 'X'.
  ENDIF.

  " Kunde / Dummy-Kunde
  SELECT SINGLE *
    FROM yqm_arpbhd_t
    WHERE kunag   = @ls_qals-kunnr
      AND inaktiv = @space
    INTO @ls_arpbhd.

  IF sy-subrc <> 0.
    SELECT SINGLE *
      FROM yqm_arpbhd_t
      WHERE kunag   = @space
        AND inaktiv = @space
      INTO @ls_arpbhd.
    IF sy-subrc <> 0.
      CLEAR ls_arpbhd.
    ENDIF.
  ENDIF.

  IF ls_arpbhd IS NOT INITIAL.
    CASE ls_arpbhd-modus.
      WHEN '1'. " nur drucken
        CLEAR gv_mailversand.
        IF i_qave-vaename IS INITIAL.
          lv_no_processing = 'X'.
        ENDIF.

      WHEN '2'. " nur mailen
        " ok

      WHEN '9'. " nur archivieren
        lv_no_processing = 'X'.

      WHEN OTHERS.
        MESSAGE i112(yqmlims).
        e_subrc = 8.
        RETURN.
    ENDCASE.
  ELSE.
    lv_no_processing = 'X'.
    MESSAGE a117(yqmlims) WITH 'YQM_ARPBHD_T'.
    e_subrc = 8.
    RETURN.
  ENDIF.

  " Status APBE prüfen
  CALL FUNCTION 'STATUS_TEXT_CONVERSION'
    EXPORTING
      language      = sy-langu
      mode          = 'E'
      objnr         = ls_qals-objnr
      txt04         = 'APBE'
    IMPORTING
      status_number = lv_estat_apbe
    EXCEPTIONS
      OTHERS        = 5.

  IF sy-subrc = 0.
    CALL FUNCTION 'STATUS_CHECK'
      EXPORTING
        bypass_buffer = 'X'
        objnr         = ls_qals-objnr
        status        = lv_estat_apbe
      EXCEPTIONS
        OTHERS        = 3.

    IF sy-subrc = 0.
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar       = 'Neue Version des Prüfberichts?'(014)
          text_question  = TEXT-015
          text_button_1  = 'Ja'(004)
          text_button_2  = 'Nein'(005)
          default_button = '1'
        IMPORTING
          answer         = lv_cont
        EXCEPTIONS
          OTHERS         = 2.
      IF sy-subrc = 0.
        CASE lv_cont.
          WHEN '1'.
            CALL FUNCTION 'STATUS_CHANGE_EXTERN'
              EXPORTING
                objnr       = ls_qals-objnr
                user_status = lv_estat_apbe
                set_inact   = 'X'
                set_chgkz   = 'X'
              EXCEPTIONS
                OTHERS      = 4.
            IF sy-subrc = 0.
              lv_new_version = 'X'.
              lv_commit      = 'X'.
            ENDIF.

          WHEN '2'.
            IF i_resend = 'X'.
              CLEAR lv_new_version.
              lv_commit = 'X'.
            ELSE.
              RETURN.
            ENDIF.

          WHEN OTHERS.
            RETURN.
        ENDCASE.
      ELSE.
        RETURN.
      ENDIF.
    ELSE.
      lv_initial_version = 'X'.
    ENDIF.
  ELSE.
    lv_initial_version = 'X'.
  ENDIF.

  CLEAR lv_vbpe.

  IF ls_arpbhd-modus = '2' OR ls_arpbhd-modus = '3'.
    gv_mailversand = 'X'.

    CALL FUNCTION 'STATUS_TEXT_CONVERSION'
      EXPORTING
        language      = sy-langu
        mode          = 'E'
        objnr         = ls_qals-objnr
        txt04         = 'VPBE'
      IMPORTING
        status_number = lv_estat_vpbe
      EXCEPTIONS
        OTHERS        = 5.

    IF sy-subrc <> 0.
      MESSAGE i113(yqmlims) WITH 'VPBE'.
    ELSE.
      CALL FUNCTION 'STATUS_CHECK'
        EXPORTING
          bypass_buffer = 'X'
          objnr         = ls_qals-objnr
          status        = lv_estat_vpbe
        EXCEPTIONS
          OTHERS        = 3.

      IF sy-subrc = 0.
        lv_vbpe = 'X'.

        CALL FUNCTION 'POPUP_TO_CONFIRM'
          EXPORTING
            titlebar       = 'Versand Prüfbericht?'(012)
            text_question  = TEXT-013
            text_button_1  = 'Ja'(004)
            text_button_2  = 'Nein'(005)
            default_button = '1'
          IMPORTING
            answer         = lv_cont
          EXCEPTIONS
            OTHERS         = 2.
        IF sy-subrc <> 0.
          CLEAR gv_mailversand.
        ELSE.
          IF lv_cont = '1'.
            gv_mailversand = 'X'.
          ELSE.
            CLEAR gv_mailversand.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.

  lv_ar_date = sy-datlo.
  lv_ar_time = sy-timlo.

  CHECK lv_no_processing IS INITIAL.

  IF lv_new_version = 'X' OR lv_initial_version = 'X'.

    IF lv_new_version = 'X'.
      ls_qals-yqm_qpbversion = ls_qals-yqm_qpbversion + 1.

      UPDATE qals
        SET yqm_qpbversion = @ls_qals-yqm_qpbversion
        WHERE prueflos     = @ls_qals-prueflos.

      IF sy-subrc = 0.
        lv_commit = 'X'.
      ENDIF.

      IF lv_commit = 'X'.
        COMMIT WORK AND WAIT.
      ENDIF.
    ENDIF.

    PERFORM create_certificate USING ls_qals-prueflos
                                     ls_qals-werk.

  ELSE.
    " Letzten existierenden Prüfbericht ermitteln
    CLEAR lt_last_toa.

    SELECT toa01~sap_object, toa01~object_id, toa01~arc_doc_id,
           toa01~ar_date,   toaat~creatime,  toaat~descr
      FROM toa01
      INNER JOIN toaat
        ON toa01~arc_doc_id = toaat~arc_doc_id
      WHERE toa01~sap_object = 'BUS2045'
        AND toa01~object_id  = @ls_qals-prueflos
        AND toa01~archiv_id  = 'BM'
      INTO TABLE @lt_last_toa.
    IF sy-subrc <> 0.
      CLEAR lt_last_toa.
    ENDIF.

    IF lt_last_toa IS NOT INITIAL.
      SORT lt_last_toa BY sap_object object_id ar_date DESCENDING creatime DESCENDING.
      READ TABLE lt_last_toa INTO ls_toa INDEX 1.
      IF sy-subrc = 0.
        lv_ar_date = ls_toa-ar_date.
        lv_ar_time = ls_toa-creatime.
      ENDIF.
    ENDIF.

    CLEAR lt_last_toa.
  ENDIF.

  CHECK gv_mailversand = 'X'.

*  " Klammerung prüfen
*  SELECT SINGLE *
*    FROM yqm_vnltkt_t
*    WHERE tplnr = @ls_qals-yqm_tplnr
*    INTO @ls_vnltkt.
*
*  IF sy-subrc = 0.
*    SELECT *
*      FROM yqm_vnltkt_t
*      WHERE vnlkl = @ls_vnltkt-vnlkl
*      INTO TABLE @lt_kt.
*    IF sy-subrc <> 0.
*      CLEAR lt_kt.
*    ENDIF.
*  ENDIF.

  CLEAR: lt_kt.

  SELECT mandt,
         vnlkl,
         tplnr
    FROM yqm_vnltkt_t
    INTO TABLE @DATA(lt_vnltkt_by_tplnr)
    WHERE tplnr = @ls_qals-yqm_tplnr
    ORDER BY vnlkl.
  IF sy-subrc <> 0.
    CLEAR lt_vnltkt_by_tplnr.
  ENDIF.

  IF lt_vnltkt_by_tplnr IS NOT INITIAL.

    SELECT mandt,
           vnlkl,
           tplnr
      FROM yqm_vnltkt_t
      INTO TABLE @lt_kt
      FOR ALL ENTRIES IN @lt_vnltkt_by_tplnr
      WHERE vnlkl = @lt_vnltkt_by_tplnr-vnlkl.
    IF sy-subrc <> 0.
      CLEAR lt_kt.
    ENDIF.

  ENDIF.

  IF lt_kt IS NOT INITIAL.

    SORT lt_kt BY tplnr.
    DELETE ADJACENT DUPLICATES FROM lt_kt COMPARING tplnr.

    " <<< FIX: schlanker Typ + INTO TABLE (passt jetzt garantiert) >>>
    SELECT prueflos, objnr, stat35
      FROM qals
      INTO TABLE @lt_qals_rel
      FOR ALL ENTRIES IN @lt_kt
      WHERE prueflos       <> @ls_qals-prueflos
        AND yqm_probedatum =  @ls_qals-yqm_probedatum
        AND yqm_tplnr      =  @lt_kt-tplnr.

    IF sy-subrc = 0.

      CLEAR lt_object.

      LOOP AT lt_qals_rel INTO ls_qals_rel.

        CALL FUNCTION 'STATUS_CHECK'
          EXPORTING
            objnr  = ls_qals_rel-objnr
            status = 'I0224'
          EXCEPTIONS
            OTHERS = 3.

        IF sy-subrc = 0.
          DELETE TABLE lt_qals_rel FROM ls_qals_rel.
          CONTINUE.
        ENDIF.

        IF ls_qals_rel-stat35 IS INITIAL.
          CLEAR gv_mailversand.
        ELSE.
          APPEND VALUE lty_object( object_id = ls_qals_rel-prueflos ) TO lt_object.
        ENDIF.
      ENDLOOP.

      IF gv_mailversand = 'X' AND lt_object IS NOT INITIAL.

        SORT lt_object BY object_id.
        DELETE ADJACENT DUPLICATES FROM lt_object COMPARING object_id.

        CLEAR lt_toa.

        SELECT toa01~sap_object, toa01~object_id, toa01~arc_doc_id,
               toa01~ar_date,   toaat~creatime,  toaat~descr
          FROM toa01
          INNER JOIN toaat
            ON toa01~arc_doc_id = toaat~arc_doc_id
          INTO TABLE @lt_toa
          FOR ALL ENTRIES IN @lt_object
          WHERE toa01~sap_object = 'BUS2045'
            AND toa01~object_id  = @lt_object-object_id
            AND toa01~archiv_id  = 'BM'.
        IF sy-subrc <> 0.
          CLEAR lt_last_toa.
        ENDIF.

        IF lt_toa IS NOT INITIAL.
          SORT lt_toa BY sap_object object_id ar_date DESCENDING creatime DESCENDING.
          DELETE ADJACENT DUPLICATES FROM lt_toa COMPARING sap_object object_id.

          CLEAR lt_toa01.
          LOOP AT lt_toa INTO ls_toa.
            ls_toa01 = CORRESPONDING #( ls_toa ).
            APPEND ls_toa01 TO lt_toa01.
          ENDLOOP.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.

  IF gv_mailversand IS INITIAL.

    lv_text = 'Prüflos unterliegt Klammerung und wird noch nicht versendet'.

    CLEAR ls_yqarpblg.
    ls_yqarpblg-prueflos = ls_qals-prueflos.
    ls_yqarpblg-erdat    = sy-datum.
    ls_yqarpblg-erzeit   = sy-uzeit.
    ls_yqarpblg-subrc    = lv_text.
    ls_yqarpblg-kosten   = lv_kosten.

    INSERT yqm_arpblg_t FROM @ls_yqarpblg.
    IF sy-subrc = 0.
      COMMIT WORK.
    ENDIF.

    e_subrc = 8.
    RETURN.
  ENDIF.

  CHECK gv_mailversand = 'X'.

  IF lv_vbpe = 'X' AND lt_toa01 IS NOT INITIAL.

    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        titlebar       = TEXT-016
        text_question  = TEXT-017
        text_button_1  = 'Ja'(004)
        text_button_2  = 'Nein'(005)
        default_button = '1'
      IMPORTING
        answer         = lv_cont
      EXCEPTIONS
        OTHERS         = 2.
    IF sy-subrc = 0.
      IF lv_cont <> '1'.
        CLEAR lt_toa01.
      ENDIF.
    ELSE.
      CLEAR lt_toa01.
    ENDIF.
  ENDIF.

  IF ls_arpbhd-modus = '2' OR ls_arpbhd-modus = '3'.

    DATA(lv_tries) = 0.

    WHILE lv_found IS INITIAL.

      lv_tries = lv_tries + 1.
      CLEAR lt_toa.

      SELECT toa01~sap_object, toa01~object_id, toa01~arc_doc_id,
             toa01~ar_date,   toaat~creatime,  toaat~descr
        FROM toa01
        INNER JOIN toaat
          ON toa01~arc_doc_id = toaat~arc_doc_id
        INTO TABLE @lt_toa
        UP TO 1 ROWS
        WHERE toa01~sap_object = 'BUS2045'
          AND toa01~object_id  = @ls_qals-prueflos
          AND toa01~archiv_id  = 'BM'
          AND toa01~ar_date    >= @lv_ar_date
          AND toaat~creatime   >= @lv_ar_time
        ORDER BY ar_date, creatime DESCENDING.

      IF sy-subrc = 0.
        READ TABLE lt_toa INTO ls_toa INDEX 1.
        IF sy-subrc = 0.
          lv_found = 'X'.
        ENDIF.
      ELSE.
        WAIT UP TO 1 SECONDS.
      ENDIF.

      IF lv_tries > 99.
        IF sy-batch IS INITIAL.
          MESSAGE i111(yqmlims) WITH ls_qals-prueflos.
        ENDIF.
        e_subrc = 8.
        RETURN.
      ENDIF.

    ENDWHILE.

    IF lv_found = 'X'.

      CLEAR: ls_yqarpblg, lt_receiver, lt_yqarpblg.

      CALL FUNCTION 'Y_QMLIMS_ARCH_PRUEFBER_MAIL'
        EXPORTING
          iv_prueflos = ls_qals-prueflos
          is_qals     = ls_qals
          iv_kunnr    = ls_qals-kunnr
          iv_id       = ls_toa-arc_doc_id
          iv_vbeln    = ls_qals-kdauf
          iv_pndat    = ls_qals-yqm_probedatum
        IMPORTING
          ev_subrc    = lv_subrc
        TABLES
          t_toa01     = lt_toa01
          t_receiver  = lt_receiver.

      IF lv_subrc = 0.

        lv_text = 'Prüfbericht per eMail gesendet'.

        IF lv_estat_vpbe IS INITIAL.
          CALL FUNCTION 'STATUS_TEXT_CONVERSION'
            EXPORTING
              language      = sy-langu
              mode          = 'E'
              objnr         = ls_qals-objnr
              txt04         = 'VPBE'
            IMPORTING
              status_number = lv_estat_vpbe
            EXCEPTIONS
              OTHERS        = 5.
          IF sy-subrc <> 0.
            MESSAGE i113(yqmlims) WITH 'VPBE'.
          ENDIF.
        ENDIF.

        CALL FUNCTION 'STATUS_CHANGE_EXTERN'
          EXPORTING
            objnr       = ls_qals-objnr
            user_status = lv_estat_vpbe
            set_chgkz   = 'X'
          EXCEPTIONS
            OTHERS      = 4.
        IF sy-subrc <> 0.
          MESSAGE i116(yqmlims) WITH ls_qals-prueflos.
        ENDIF.

        LOOP AT lt_toa01 INTO ls_toa01.
          CONCATENATE 'QL' ls_toa01-object_id INTO lv_objnr.
          CALL FUNCTION 'STATUS_CHANGE_EXTERN'
            EXPORTING
              objnr       = lv_objnr
              user_status = lv_estat_vpbe
              set_chgkz   = 'X'
            EXCEPTIONS
              OTHERS      = 4.
          IF sy-subrc <> 0.
            MESSAGE i116(yqmlims) WITH ls_qals-prueflos.
          ENDIF.
        ENDLOOP.

        COMMIT WORK AND WAIT.

      ELSE.
        MESSAGE i111(yqmlims) WITH ls_qals-prueflos.
        CASE lv_subrc.
          WHEN '90'.
            lv_text = 'Prüfbericht nicht im Archiv BM'.
          WHEN '91'.
            lv_text = 'Fehler beim Senden des Mail'.
          WHEN OTHERS.
            lv_text = 'unbekannter Fehler beim Senden des Mail im Baustein Y_QMLIMS_QFOA_CREATE_CERTIFICA'.
        ENDCASE.
      ENDIF.

      IF lv_text IS NOT INITIAL.
        ls_yqarpblg-prueflos = ls_qals-prueflos.
        ls_yqarpblg-erdat    = sy-datum.
        ls_yqarpblg-erzeit   = sy-uzeit.
        ls_yqarpblg-subrc    = lv_text.
        ls_yqarpblg-kosten   = lv_kosten.

        LOOP AT lt_receiver INTO ls_receiver.
          CONCATENATE ls_yqarpblg-mail ls_receiver-receiver
            INTO ls_yqarpblg-mail
            SEPARATED BY space.
        ENDLOOP.

        APPEND ls_yqarpblg TO lt_yqarpblg.

        LOOP AT lt_toa01 INTO ls_toa01.
          ls_yqarpblg-prueflos = ls_toa01-object_id.
          APPEND ls_yqarpblg TO lt_yqarpblg.
        ENDLOOP.

        INSERT yqm_arpblg_t FROM TABLE @lt_yqarpblg.
        COMMIT WORK.
      ENDIF.

    ENDIF.
  ENDIF.

ENDFUNCTION.
