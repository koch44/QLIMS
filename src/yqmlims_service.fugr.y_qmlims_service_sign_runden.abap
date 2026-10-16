FUNCTION y_qmlims_service_sign_runden.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     VALUE(IV_WERT) TYPE  QAQEE-MESSWERT
*"     VALUE(IV_SIGTYP) TYPE  YQM_SIGNIFIKANZTYP
*"     VALUE(IV_GEPLANTE_STELLEN) TYPE  QSTELLEN
*"  EXPORTING
*"     VALUE(EV_WERT_CHAR) TYPE  QAQEE-MESSWERT
*"     VALUE(EV_WERT_FLTP) TYPE  QSOLLWERTE
*"     VALUE(EV_WERT_FLTP_NI) TYPE  QNINITIAL
*"     VALUE(EV_DIFF_DEC_PLACES) TYPE  QDIFF_DEC_PLACES
*"  EXCEPTIONS
*"      SIG_TYPE_NOT_DEFINED
*"      SIG_ROUND_UNEXPECTED
*"      SIG_NO_CONVERSION
*"----------------------------------------------------------------------

  DATA:
    lt_sigtyp_gw     TYPE SORTED TABLE OF yqm_sigtyp_gw_t WITH UNIQUE KEY sortnr,
    ls_sigtyp_gw     TYPE yqm_sigtyp_gw_t,
    lv_sigstellen    TYPE i,
    lv_maxsigstellen TYPE i,
    lv_vkstellen     TYPE i,
    lv_nkstellen     TYPE i,
    lv_vorzeichen    TYPE i,
    lv_fltp1         TYPE f,
    lv_fltp2         TYPE f,
    lv_fltp3         TYPE f,
    lv_fltp4         TYPE f,
    lv_grmin         TYPE f,
    lv_grmax         TYPE f,
    lv_faktor        TYPE f,
    lv_flog          TYPE f,
    lv_cw1(22)       TYPE c.

  ev_wert_char = ''.
  ev_wert_fltp = 0.
  ev_wert_fltp_ni = ''.
  ev_diff_dec_places = 0.

  IF iv_sigtyp IS INITIAL.
    RAISE sig_type_not_defined.
  ENDIF.

  lv_vorzeichen = sign( iv_wert ).
  lv_fltp1 = abs( iv_wert ).

  SELECT * FROM yqm_sigtyp_gw_t INTO TABLE lt_sigtyp_gw
  WHERE signifikanztyp = iv_sigtyp.

  IF sy-dbcnt <= 0.
    RAISE sig_type_not_defined.
  ENDIF.

  lv_grmin = gc_min. " '1.0e100'.
  lv_grmax = gc_max. "'-1.0e100'.
  lv_sigstellen = -99.
  lv_maxsigstellen = -99.
  LOOP AT lt_sigtyp_gw INTO ls_sigtyp_gw.
    IF ls_sigtyp_gw-grenzeu < lv_grmin.
      lv_grmin = ls_sigtyp_gw-grenzeu.
    ENDIF.

    IF ls_sigtyp_gw-grenzeo > lv_grmax.
      lv_grmax = ls_sigtyp_gw-grenzeo.
      lv_maxsigstellen = ls_sigtyp_gw-stellen.
    ENDIF.

    IF lv_fltp1 >= ls_sigtyp_gw-grenzeu AND lv_fltp1 < ls_sigtyp_gw-grenzeo.
      lv_sigstellen = ls_sigtyp_gw-stellen.
      EXIT.
    ENDIF.
  ENDLOOP.

  IF iv_wert >= lv_grmax.
    lv_sigstellen = lv_maxsigstellen.
  ENDIF.

  IF lv_sigstellen >= 0.

    IF lv_fltp1 > 0.
      lv_flog = log10( lv_fltp1 ).
    ELSEIF lv_fltp1 < 0.
      lv_flog = log10( ( -1 ) * lv_fltp1 ).
    ELSE.
      lv_flog = 0.
    ENDIF.

    lv_vkstellen = floor( lv_flog ) + 1.

    lv_nkstellen = lv_sigstellen - lv_vkstellen.
    IF lv_nkstellen < 0.
      lv_nkstellen = 0.
    ENDIF.

* Anzahl Nachkommastellen darf nicht größer sein als vorgeplante Anzahl
    IF lv_nkstellen > iv_geplante_stellen.
      lv_nkstellen = iv_geplante_stellen.
    ENDIF.

    ev_diff_dec_places =  lv_nkstellen - iv_geplante_stellen.

    lv_faktor = 10 ** ( lv_sigstellen - lv_vkstellen ).

    lv_fltp2 = lv_fltp1 * lv_faktor + gc_half. "'0.5'.
    lv_fltp3 = trunc( lv_fltp2 ).

    lv_fltp4 = lv_vorzeichen * lv_fltp3 / lv_faktor.

    ev_wert_fltp = lv_fltp4.
    ev_wert_fltp_ni = 'X'.

    CALL FUNCTION 'FLTP_CHAR_CONVERSION'
      EXPORTING
        decim = lv_nkstellen
*       EXPON = 0
        input = lv_fltp4
        ivalu = 'X'
*       MASKN = ' '
      IMPORTING
        flstr = lv_cw1.

    IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
      RAISE sig_no_conversion.
    ENDIF.

    SHIFT lv_cw1 LEFT DELETING LEADING space.
    ev_wert_char = lv_cw1.

  ELSEIF lv_fltp1 < lv_grmin.

    ev_wert_fltp = 0.
    ev_wert_fltp_ni = 'X'.
    ev_diff_dec_places = 0 - iv_geplante_stellen.
    ev_wert_char = '0'.

  ELSE.
    RAISE sig_round_unexpected.
  ENDIF.




ENDFUNCTION.
