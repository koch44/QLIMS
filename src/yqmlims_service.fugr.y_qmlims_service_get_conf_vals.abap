FUNCTION y_qmlims_service_get_conf_vals.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     VALUE(I_CUOBJ) TYPE  CUOBJ_VA
*"  EXPORTING
*"     REFERENCE(EV_SPEZID) TYPE  YQM_SPEZID
*"     REFERENCE(EV_PROBENEHMER03) TYPE  YQM_PROBENEHMER03
*"     REFERENCE(EV_PROBENEHMER40) TYPE  YQM_PROBENEHMER40
*"     REFERENCE(EV_PROBENAHMEDATUM) TYPE  YQM_PROBENAHMEDATUM
*"     REFERENCE(EV_PROBENAHMEZEIT) TYPE  YQM_PROBENAHMEZEIT
*"     REFERENCE(EV_PROBENEINGANGSDATUM) TYPE  YQM_PROBEEINGANGSDAT
*"     REFERENCE(EV_PROBENAHMEANWEISUNG) TYPE  QPRZIEHVER
*"     REFERENCE(EV_UEBERWACHUNG) TYPE  YQM_UEBERWACHUNG
*"     REFERENCE(EV_ANLASS) TYPE  YQM_ANLASS
*"     REFERENCE(EV_GUTACHTEN) TYPE  FLAG
*"     REFERENCE(EV_BEURTEILUNG) TYPE  FLAG
*"     REFERENCE(EV_KEIN_AUTO_VE) TYPE  FLAG
*"     REFERENCE(EV_PNV) TYPE  YQM_VNLPV
*"     REFERENCE(EV_PROBENGEWINNUNG) TYPE  YQM_PROBENGEWINNUNG
*"     REFERENCE(EV_PROBENANZAHL) TYPE  QPRANZ1
*"     REFERENCE(EV_PROBENAHMEART) TYPE  YQM_PROBENAHMEART
*"     REFERENCE(EV_TEMPERATUR_PN) TYPE  YQM_TEMPERATUR_PN
*"     REFERENCE(EV_TP_SPEZ_PROBENAHMEORTE) TYPE  FLAG
*"----------------------------------------------------------------------

  TYPE-POOLS ibco2.

  TYPES: BEGIN OF lty_cabn,
           atnam TYPE cabn-atnam,
           atinn TYPE cabn-atinn,
         END OF lty_cabn.

  DATA:
    lv_value_char    TYPE c LENGTH 22,
    lv_date_char     TYPE c LENGTH 8,
    lv_time_char     TYPE c LENGTH 6,
    ls_configuration TYPE ibco2_instance_rec2,
    ls_config_value  TYPE ibco2_value_rec,
    lt_cabn          TYPE HASHED TABLE OF lty_cabn WITH UNIQUE KEY atnam.

  FIELD-SYMBOLS:
    <ls_cabn> TYPE lty_cabn.

  CALL FUNCTION 'CUCB_GET_SINGLE_INSTANCE'
    EXPORTING
      instance                     = i_cuobj
    IMPORTING
      instance_rec                 = ls_configuration
    EXCEPTIONS
      invalid_instance             = 1
      instance_is_a_classification = 2
      OTHERS                       = 3.

  IF sy-subrc <> 0.
    CLEAR:
      ev_spezid,
      ev_probenehmer03,
      ev_probenehmer40,
      ev_probenahmedatum,
      ev_probenahmezeit,
      ev_probeneingangsdatum,
      ev_probenahmeanweisung,
      ev_ueberwachung,
      ev_anlass,
      ev_gutachten,
      ev_beurteilung,
      ev_kein_auto_ve,
      ev_pnv,
      ev_probengewinnung,
      ev_probenanzahl,
      ev_probenahmeart,
      ev_temperatur_pn,
      ev_tp_spez_probenahmeorte.
    RETURN.
  ENDIF.

  SELECT atnam, atinn
    FROM cabn
    INTO TABLE @lt_cabn
    WHERE atnam IN (
      'LAB_SPEZIFIKATION             ',
      'LAB_PROBENAHMEDATUM           ',
      'LAB_PROBENAHMEZEIT            ',
      'LAB_PROBENEINGANGSDATUM       ',
      'LAB_PROBENAHMEANWEISUNG       ',
      'LAB_PROBENEHMER               ',
      'LAB_PROBENAHMEAUFWAND         ',
      'LAB_PROBENAHMEPAUSCHALE       ',
      'LAB_PROBENAHMEKILOMETER       ',
      'LAB_UEBERWACHUNGSART          ',
      'LAB_UNTERSUCHUNGSANLASS       ',
      'LAB_GUTACHTEN                 ',
      'LAB_BEURTEILUNG               ',
      'LAB_KEIN_AUTO_VE              ',
      'LAB_PROBENAHMEVERFAHREN       ',
      'LAB_PROBENGEWINNUNG           ',
      'LAB_TEMPERATUR_PN             ',
      'LAB_PROBENAHMEART_LP          ' ).
  IF sy-subrc <> 0.
    CLEAR lt_cabn.
  ENDIF.

  IF ev_spezid IS REQUESTED.
    CLEAR ev_spezid.
    ASSIGN lt_cabn[ atnam = 'LAB_SPEZIFIKATION             ' ] TO <ls_cabn>.
    IF sy-subrc = 0.
      READ TABLE ls_configuration-values INTO ls_config_value
           WITH KEY atinn = <ls_cabn>-atinn.
      IF sy-subrc = 0.
        ev_spezid = ls_config_value-atwrt.
      ENDIF.
    ENDIF.
  ENDIF.

  IF ev_probenahmedatum IS REQUESTED.
    CLEAR ev_probenahmedatum.
    ASSIGN lt_cabn[ atnam = 'LAB_PROBENAHMEDATUM           ' ] TO <ls_cabn>.
    IF sy-subrc = 0.
      CLEAR ev_probenahmedatum.
      READ TABLE ls_configuration-values INTO ls_config_value
           WITH KEY atinn = <ls_cabn>-atinn.
      IF sy-subrc = 0.
        lv_date_char = |{ ls_config_value-atdecv NUMBER = RAW }|.
        IF strlen( lv_date_char ) = 8.
          ev_probenahmedatum = lv_date_char.
        ENDIF.
      ELSE.
        CLEAR ev_probenahmedatum.
      ENDIF.
    ENDIF.
  ENDIF.

  IF ev_probenahmezeit IS REQUESTED.
    CLEAR ev_probenahmezeit.

    ASSIGN lt_cabn[ atnam = 'LAB_PROBENAHMEZEIT            ' ] TO <ls_cabn>.
    IF sy-subrc = 0.
      READ TABLE ls_configuration-values INTO ls_config_value
           WITH KEY atinn = <ls_cabn>-atinn.
      IF sy-subrc = 0.

        lv_time_char = |{ ls_config_value-atdecv NUMBER = RAW }|.

        CONDENSE lv_time_char NO-GAPS.
        ev_probenahmezeit = |{ lv_time_char WIDTH = 6 ALIGN = RIGHT PAD = '0' }|.
      ENDIF.
    ENDIF.
  ENDIF.

  IF ev_probeneingangsdatum IS REQUESTED.
    CLEAR ev_probeneingangsdatum.
    ASSIGN lt_cabn[ atnam = 'LAB_PROBENEINGANGSDATUM       ' ] TO <ls_cabn>.
    IF sy-subrc = 0.
      CLEAR ev_probeneingangsdatum.
      READ TABLE ls_configuration-values INTO ls_config_value
           WITH KEY atinn = <ls_cabn>-atinn.
      IF sy-subrc = 0.
        lv_date_char = |{ ls_config_value-atdecv NUMBER = RAW }|.
        IF strlen( lv_date_char ) = 8.
          ev_probeneingangsdatum = lv_date_char.
        ENDIF.
      ELSE.
        CLEAR ev_probeneingangsdatum.
      ENDIF.
    ENDIF.
  ENDIF.

  IF ev_probenahmeanweisung IS REQUESTED.
    CLEAR ev_probenahmeanweisung.
    ASSIGN lt_cabn[ atnam = 'LAB_PROBENAHMEANWEISUNG       ' ] TO <ls_cabn>.
    IF sy-subrc = 0.
      READ TABLE ls_configuration-values INTO ls_config_value
           WITH KEY atinn = <ls_cabn>-atinn.
      IF sy-subrc = 0.
        ev_probenahmeanweisung = ls_config_value-atwrt.
      ENDIF.
    ENDIF.
  ENDIF.

  IF ev_probenehmer03 IS REQUESTED OR ev_probenehmer40 IS REQUESTED.
    CLEAR: ev_probenehmer03, ev_probenehmer40.
    ASSIGN lt_cabn[ atnam = 'LAB_PROBENEHMER               ' ] TO <ls_cabn>.
    IF sy-subrc = 0.
      READ TABLE ls_configuration-values INTO ls_config_value
           WITH KEY atinn = <ls_cabn>-atinn.
      IF sy-subrc = 0.
        ev_probenehmer03 = ls_config_value-atwrt.
      ENDIF.
    ENDIF.

    IF ev_probenehmer03 IS NOT INITIAL.
      SELECT SINGLE lname
        FROM yqm_pruefer_t
        INTO @ev_probenehmer40
        WHERE kname = @ev_probenehmer03.
      IF sy-subrc <> 0.
        CLEAR ev_probenehmer40.
      ENDIF.
    ENDIF.
  ENDIF.

  IF ev_ueberwachung IS REQUESTED.
    CLEAR ev_ueberwachung.
    ASSIGN lt_cabn[ atnam = 'LAB_UEBERWACHUNGSART          ' ] TO <ls_cabn>.
    IF sy-subrc = 0.
      READ TABLE ls_configuration-values INTO ls_config_value
           WITH KEY atinn = <ls_cabn>-atinn.
      IF sy-subrc = 0.
        ev_ueberwachung = ls_config_value-atwrt.
      ENDIF.
    ENDIF.
  ENDIF.

  IF ev_anlass IS REQUESTED.
    CLEAR ev_anlass.
    ASSIGN lt_cabn[ atnam = 'LAB_UNTERSUCHUNGSANLASS       ' ] TO <ls_cabn>.
    IF sy-subrc = 0.
      READ TABLE ls_configuration-values INTO ls_config_value
           WITH KEY atinn = <ls_cabn>-atinn.
      IF sy-subrc = 0.
        ev_anlass = ls_config_value-atwrt.
      ENDIF.
    ENDIF.
  ENDIF.

  IF ev_gutachten IS REQUESTED.
    CLEAR ev_gutachten.
    ASSIGN lt_cabn[ atnam = 'LAB_GUTACHTEN                 ' ] TO <ls_cabn>.
    IF sy-subrc = 0.
      READ TABLE ls_configuration-values INTO ls_config_value
           WITH KEY atinn = <ls_cabn>-atinn.
      IF sy-subrc = 0.
        ev_gutachten = ls_config_value-atwrt.
      ENDIF.
    ENDIF.
  ENDIF.

  IF ev_beurteilung IS REQUESTED.
    CLEAR ev_beurteilung.
    ASSIGN lt_cabn[ atnam = 'LAB_BEURTEILUNG               ' ] TO <ls_cabn>.
    IF sy-subrc = 0.
      READ TABLE ls_configuration-values INTO ls_config_value
           WITH KEY atinn = <ls_cabn>-atinn.
      IF sy-subrc = 0.
        ev_beurteilung = ls_config_value-atwrt.
      ENDIF.
    ENDIF.
  ENDIF.

  IF ev_kein_auto_ve IS REQUESTED.
    CLEAR ev_kein_auto_ve.
    ASSIGN lt_cabn[ atnam = 'LAB_KEIN_AUTO_VE              ' ] TO <ls_cabn>.
    IF sy-subrc = 0.
      READ TABLE ls_configuration-values INTO ls_config_value
           WITH KEY atinn = <ls_cabn>-atinn.
      IF sy-subrc = 0.
        ev_kein_auto_ve = ls_config_value-atwrt.
      ENDIF.
    ENDIF.
  ENDIF.

  IF ev_pnv IS REQUESTED.
    CLEAR ev_pnv.
    ASSIGN lt_cabn[ atnam = 'LAB_PROBENAHMEVERFAHREN       ' ] TO <ls_cabn>.
    IF sy-subrc = 0.
      READ TABLE ls_configuration-values INTO ls_config_value
           WITH KEY atinn = <ls_cabn>-atinn.
      IF sy-subrc = 0.
        ev_pnv = ls_config_value-atwrt.
      ENDIF.
    ENDIF.
  ENDIF.

  IF ev_probengewinnung IS REQUESTED.
    CLEAR ev_probengewinnung.
    ASSIGN lt_cabn[ atnam = 'LAB_PROBENGEWINNUNG           ' ] TO <ls_cabn>.
    IF sy-subrc = 0.
      READ TABLE ls_configuration-values INTO ls_config_value
           WITH KEY atinn = <ls_cabn>-atinn.
      IF sy-subrc = 0.
        ev_probengewinnung = ls_config_value-atwrt.
      ENDIF.
    ENDIF.
  ENDIF.

  IF ev_probenahmeart IS REQUESTED.
    CLEAR ev_probenahmeart.
    ASSIGN lt_cabn[ atnam = 'LAB_PROBENAHMEART_LP          ' ] TO <ls_cabn>.
    IF sy-subrc = 0.
      READ TABLE ls_configuration-values INTO ls_config_value
           WITH KEY atinn = <ls_cabn>-atinn.
      IF sy-subrc = 0.
        ev_probenahmeart = ls_config_value-atwrt.
      ENDIF.
    ENDIF.
  ENDIF.

*  IF ev_tp_spez_probenahmeorte IS REQUESTED.
*    CLEAR ev_tp_spez_probenahmeorte.
*    ASSIGN lt_cabn[ atnam = 'TP_SPEZIFISCHE_PROBENAHMEORTE ' ] TO <ls_cabn>.
*    IF sy-subrc = 0.
*      READ TABLE ls_configuration-values INTO ls_config_value
*           WITH KEY atinn = <ls_cabn>-atinn.
*      IF sy-subrc = 0.
*        ev_tp_spez_probenahmeorte = ls_config_value-atwrt.
*      ENDIF.
*    ENDIF.
*  ENDIF.

  IF ev_probenanzahl IS REQUESTED.
    CLEAR ev_probenanzahl.
    CLEAR lv_value_char.
    ASSIGN lt_cabn[ atnam = 'LAB_PROBENANZAHL              ' ] TO <ls_cabn>.
    IF sy-subrc = 0.
      READ TABLE ls_configuration-values INTO ls_config_value
           WITH KEY atinn = <ls_cabn>-atinn.
      IF sy-subrc = 0.
        IF ls_config_value-atwrt IS INITIAL.
          CALL FUNCTION 'FLTP_CHAR_CONVERSION'
            EXPORTING
              decim = '15'
              input = ls_config_value-atflv
              ivalu = 'X'
            IMPORTING
              flstr = lv_value_char.
          ls_config_value-atwrt = lv_value_char.
        ENDIF.
        SHIFT ls_config_value-atwrt LEFT DELETING LEADING space.
        REPLACE ',' IN ls_config_value-atwrt WITH '.'.
        ev_probenanzahl = ls_config_value-atwrt(8).
      ENDIF.
    ENDIF.
  ENDIF.

  IF ev_temperatur_pn IS REQUESTED.
    CLEAR ev_temperatur_pn.
    CLEAR lv_value_char.
    ASSIGN lt_cabn[ atnam = 'LAB_TEMPERATUR_PN             ' ] TO <ls_cabn>.
    IF sy-subrc = 0.
      READ TABLE ls_configuration-values INTO ls_config_value
           WITH KEY atinn = <ls_cabn>-atinn.
      IF sy-subrc = 0.
        IF ls_config_value-atwrt IS INITIAL.
          CALL FUNCTION 'FLTP_CHAR_CONVERSION'
            EXPORTING
              decim = '15'
              input = ls_config_value-atflv
              ivalu = 'X'
            IMPORTING
              flstr = lv_value_char.
          ls_config_value-atwrt = lv_value_char.
        ENDIF.
        SHIFT ls_config_value-atwrt LEFT DELETING LEADING space.
        REPLACE ',' IN ls_config_value-atwrt WITH '.'.
        ev_temperatur_pn = ls_config_value-atwrt(8).
      ENDIF.
    ENDIF.
  ENDIF.

ENDFUNCTION.
