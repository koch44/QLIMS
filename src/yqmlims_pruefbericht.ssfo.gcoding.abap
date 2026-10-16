
TYPES:
  BEGIN OF lty_toa,
    arc_doc_id TYPE toa01-arc_doc_id,
    ar_date    TYPE toa01-ar_date,
    creatime   TYPE toaat-creatime,
    descr      TYPE toaat-descr,
  END OF lty_toa.

DATA: ls_t247         TYPE t247.
DATA: ls_matn_mk_t    TYPE yqm_matn_mk_t.
*DATA: ls_matn_fo_t    TYPE yqm_matn_fo_t.
DATA: ls_toa          TYPE lty_toa.
DATA: lt_toa          TYPE TABLE OF lty_toa.
DATA: ls_diadr        TYPE diadr.
DATA: ls_smtp         TYPE adsmtp.
DATA: lt_smtp         TYPE TABLE OF adsmtp.

gt_qamv[] = it_qamv[].
gt_qapp[] = it_qapp[].

SORT gt_qapp BY prueflos probenr vorglfnr.
DELETE ADJACENT DUPLICATES FROM gt_qapp COMPARING prueflos probenr.

CLEAR gv_count_qapp.
LOOP AT it_qapp INTO gs_qapp
  WHERE vorglfnr   EQ 1
  AND   vbewertung NE space.
  gv_count_qapp = gv_count_qapp + 1.
ENDLOOP.

* Langtextschlüssel aufbauen
CONCATENATE is_qals-mandant
            is_qals-prueflos
       INTO gv_tdname_qals.

CONCATENATE is_qals-mandant
            is_qals-prueflos
            'L'
       INTO gv_tdname_qave.

SELECT SINGLE * FROM yqm_vnltpv_t INTO gs_vnltpv
  WHERE vnlpv = is_qals-yqm_vnlpv.
IF sy-subrc <> 0.
  CLEAR gs_vnltpv.
ENDIF.

* Steuerung via Cust-Tab
SELECT SINGLE * FROM yqm_vnltcu_t INTO gs_vnltcu
  WHERE swerk = is_qals-werk.
IF sy-subrc <> 0.
  CLEAR gs_vnltcu.
ENDIF.

PERFORM lesen_center USING gs_vnltcu-kokrs
                           gs_vnltcu-prctr
                  CHANGING gs_zusatz-abtei
                           gs_zusatz-stras
                           gs_zusatz-ltext.


SELECT SINGLE * FROM t001w INTO gs_t001w
  WHERE werks = is_qals-werk.
IF sy-subrc <> 0.
  CLEAR gs_t001w.
ENDIF.

IF NOT it_qamv[] IS INITIAL.

  SELECT * FROM t006a INTO TABLE gt_t006a
    FOR ALL ENTRIES IN it_qamv
    WHERE spras = sy-langu
      AND msehi = it_qamv-masseinhsw.
  IF sy-subrc <> 0.
    CLEAR gt_t006a.
  ENDIF.

  SELECT * FROM qmtt INTO TABLE gt_qmtt
    FOR ALL ENTRIES IN it_qamv
      WHERE werks   = it_qamv-qmtb_werks
      AND   pmtnr   = it_qamv-pmethode
      AND   version = it_qamv-pmtversion
      AND   sprache = sy-langu.
  IF sy-subrc <> 0.
    CLEAR gt_qmtt.
  ENDIF.

ENDIF.

CALL FUNCTION 'STATUS_TEXT_EDIT'
  EXPORTING
    flg_user_stat    = 'X'
    objnr            = is_qals-objnr
*   ONLY_ACTIVE      = 'X'
    spras            = sy-langu
  IMPORTING
    line             = gs_status_line
    user_line        = gs_status_user_line
  EXCEPTIONS
    object_not_found = 1
    OTHERS           = 2.
IF sy-subrc <> 0.
* Implement suitable error handling here
  CLEAR gs_status_line.
  CLEAR gs_status_user_line.
ENDIF.

IF gs_status_user_line CP '*GUTE*'.
  gv_status_gute = 'X'.
ELSE.
  CLEAR gv_status_gute.
ENDIF.

IF gs_status_user_line CP '*MVID*'.
  gv_status_mvid = 'X'.
ELSE.
  CLEAR gv_status_mvid.
ENDIF.

IF is_qals-yqm_qpbversion NE '00'.
  SELECT toa01~arc_doc_id toa01~ar_date toaat~creatime toaat~descr
         FROM toa01 JOIN toaat
           ON toa01~arc_doc_id = toaat~arc_doc_id
    INTO TABLE lt_toa
    WHERE    toa01~sap_object = 'BUS2045'
    AND      toa01~object_id  = is_qals-prueflos
    AND      toa01~archiv_id  = 'BM'
    ORDER BY ar_date DESCENDING creatime DESCENDING.
  IF sy-subrc = 0.
    DELETE lt_toa WHERE descr(22) NE 'Prüfbericht zu Prüflos'.

    READ TABLE lt_toa INTO ls_toa INDEX 1.
    IF sy-subrc = 0.
      REPLACE ' zu Prüflos ' WITH space INTO ls_toa-descr.
      SPLIT ls_toa-descr AT ' - ' INTO ls_toa-descr gv_version_alt.
*      gv_version_alt       = ls_toa-descr.
      gv_version_alt_datum = ls_toa-ar_date.
    ENDIF.
  ENDIF.
ENDIF.

CLEAR gs_freigeber.

IF iv_udcall = 'X'.
* Verwendungsentscheid wird getroffen
*  IF NOT is_qave-vaename IS INITIAL.
*    gs_freigeber-vname  = is_qave-vaename.
*    gs_freigeber-vdatum = is_qave-vaedatum.
*    gs_freigeber-vzeit  = is_qave-vezeitaen.
*  ELSE.
* Es soll immer der Treffer des VE angedruckt werden
  gs_freigeber-vname  = is_qave-vname.
  gs_freigeber-vdatum = is_qave-vdatum.
  gs_freigeber-vzeit  = is_qave-vezeiterf.
*  ENDIF.
ELSEIF iv_approval  = 'X'.
*  Freigabe erfolgt gerade
  gs_freigeber-vname  = sy-uname.
  gs_freigeber-vdatum = sy-datlo.
  gs_freigeber-vzeit  = sy-timlo.
ELSE.
  IF NOT is_qave-vcode IS INITIAL.
*    IF NOT is_qave-vaename IS INITIAL.
*      gs_freigeber-vname  = is_qave-vaename.
*      gs_freigeber-vdatum = is_qave-vaedatum.
*      gs_freigeber-vzeit  = is_qave-vezeitaen.
*    ELSE.
* Es soll immer der Treffer des VE angedruckt werden
    gs_freigeber-vname  = is_qave-vname.
    gs_freigeber-vdatum = is_qave-vdatum.
    gs_freigeber-vzeit  = is_qave-vezeiterf.
*    ENDIF.
  ENDIF.
ENDIF.

IF NOT gs_freigeber-vname IS INITIAL.
  CALL FUNCTION 'PM_PARTNER_READ'
    EXPORTING
      parvw                  = 'VU'
      parnr                  = gs_freigeber-vname
    IMPORTING
      diadr_wa               = ls_diadr
    EXCEPTIONS
      no_valid_parnr         = 1
      no_valid_parnr_today   = 2
      no_authority           = 3
      parvw_and_nrart_inital = 4
      OTHERS                 = 5.
  IF sy-subrc = 0.
    gs_freigeber-vname_list  = ls_diadr-name_list.

    CALL FUNCTION 'SUSR_USER_ADDRESS_READ'
      EXPORTING
        user_name              = gs_freigeber-vname
      IMPORTING
        user_address           = gs_addr3_val
      EXCEPTIONS
        user_address_not_found = 1
        OTHERS                 = 2.
    IF sy-subrc <> 0.
      CLEAR gv_email .
    ELSE.
      CALL FUNCTION 'ADDR_PERS_COMP_COMM_GET'
        EXPORTING
          address_number    = gs_addr3_val-addrnumber
          language          = sy-langu
          person_number     = gs_addr3_val-persnumber
          table_type        = 'ADSMTP'
        TABLES
          comm_table        = lt_smtp
        EXCEPTIONS
          parameter_error   = 1
          address_not_exist = 2
          person_not_exist  = 3
          internal_error    = 4
          OTHERS            = 5.
      IF sy-subrc = 0.
        LOOP AT lt_smtp INTO ls_smtp
             WHERE flgdefault = 'X'.
          gv_email = ls_smtp-smtp_addr.     "EMail-Anschrift Anspr
        ENDLOOP.
      ENDIF.
    ENDIF.
  ELSE.
*    break fisch50.
*  In case user ist not existing read information from YQ0100FORM
*    SELECT SINGLE * FROM yqm_matn_fo_t
*      INTO ls_matn_fo_t
*      WHERE datvon LE sy-datum
*      AND   datbis GE sy-datum.
*    IF sy-subrc = 0.
*      SPLIT ls_matn_fo_t-tel AT '-' INTO
*      gs_addr3_val-tel_number gs_addr3_val-tel_extens.
*      gs_addr3_val-name_text  = ls_matn_fo_t-name_zust.
*      gs_freigeber-vname_list = ls_matn_fo_t-name_zust.
*      gv_email                = ls_matn_fo_t-mail.
*    ELSE.
*      gs_freigeber-vname_list = gs_freigeber-vname.
*    ENDIF.
  ENDIF.

ELSE.
  CALL FUNCTION 'SUSR_USER_ADDRESS_READ'
    EXPORTING
      user_name              = sy-uname
    IMPORTING
      user_address           = gs_addr3_val
    EXCEPTIONS
      user_address_not_found = 1
      OTHERS                 = 2.
  IF sy-subrc <> 0.
    CLEAR gv_email .
  ELSE.
    CALL FUNCTION 'ADDR_PERS_COMP_COMM_GET'
      EXPORTING
        address_number    = gs_addr3_val-addrnumber
        language          = sy-langu
        person_number     = gs_addr3_val-persnumber
        table_type        = 'ADSMTP'
      TABLES
        comm_table        = lt_smtp
      EXCEPTIONS
        parameter_error   = 1
        address_not_exist = 2
        person_not_exist  = 3
        internal_error    = 4
        OTHERS            = 5.
    IF sy-subrc = 0.
      LOOP AT lt_smtp INTO ls_smtp
        WHERE flgdefault = 'X'.
        gv_email = ls_smtp-smtp_addr.     "EMail-Anschrift Anspr
      ENDLOOP.
    ENDIF.
  ENDIF.

ENDIF.


CLEAR gv_ltext_ve.
IF NOT gv_tdname_qave IS INITIAL.
  CALL FUNCTION 'READ_TEXT'
    EXPORTING
*     CLIENT                  = SY-MANDT
      id                      = 'QAVE'
      language                = sy-langu
      name                    = gv_tdname_qave
      object                  = 'QPRUEFLOS'
*     ARCHIVE_HANDLE          = 0
*     LOCAL_CAT               = ' '
* IMPORTING
*     HEADER                  =
*     OLD_LINE_COUNTER        =
    TABLES
      lines                   = gt_tline_qave
    EXCEPTIONS
      id                      = 1
      language                = 2
      name                    = 3
      not_found               = 4
      object                  = 5
      reference_check         = 6
      wrong_access_to_archive = 7
      OTHERS                  = 8.
  IF sy-subrc <> 0.
* Implement suitable error handling here
    CLEAR gt_tline_qave.
  ELSE.
    LOOP AT gt_tline_qave INTO gs_tline_qave
      WHERE tdformat = space
      OR    tdformat = '='
      OR    tdformat = '*'.
      gv_ltext_ve = 'X'.
      EXIT.
    ENDLOOP.
    IF sy-subrc <> 0.
      CLEAR gv_ltext_ve.
    ENDIF.
  ENDIF.
ENDIF.
IF NOT is_qals-yqm_probenehmer03 IS INITIAL.
  SELECT SINGLE * FROM yqm_pruefer_t INTO gs_pruefer
    WHERE kname = is_qals-yqm_probenehmer03.
  IF sy-subrc <> 0.
    CLEAR gs_pruefer.
  ENDIF.
ELSE.
  CLEAR gs_pruefer.
ENDIF.

SELECT * FROM yqm_cert_attr_t INTO TABLE gt_cert_attr.
IF sy-subrc = 0.
  SORT gt_cert_attr BY attribut verwmerkm.
ELSE.
  CLEAR gt_cert_attr.
ENDIF.

IF NOT is_qals-yqm_prggstd IS INITIAL.
  SELECT SINGLE * FROM yqm_prggstd_t INTO gs_prggstd
    WHERE prggstd = is_qals-yqm_prggstd.
  IF sy-subrc <> 0.
    CLEAR gs_prggstd.
  ENDIF.
ELSE.
  CLEAR gs_prggstd.
ENDIF.

DESCRIBE TABLE it_qapo LINES sy-tfill.
IF sy-tfill = 1.
*  lv_qapo_qkz = 'X'.
  gt_qapo[] = it_qapo[].
ELSE.
*  CLEAR lv_qapo_qkz.
  gt_qapo[] = it_qapo[].
ENDIF.

IF NOT is_qals-matnr IS INITIAL.
  SELECT SINGLE * FROM yqm_matn_tx_t
    INTO CORRESPONDING FIELDS OF gs_matn_tx_t
    WHERE matnr = is_qals-matnr.
  IF sy-subrc <> 0.
    CLEAR gs_matn_tx_t.
  ENDIF.

  SELECT * FROM yqm_matn_mk_t
    INTO CORRESPONDING FIELDS OF TABLE gt_matn_mk_t
    WHERE matnr = is_qals-matnr.
  IF sy-subrc = 0.
    SORT gt_matn_mk_t BY matnr zaehler.

    LOOP AT gt_matn_mk_t INTO gs_matn_mk_t
      WHERE kennzeichen IS INITIAL.

      CLEAR gs_qamv.

* existiert ein Merkmal dazu?
      READ TABLE gt_qamv INTO gs_qamv
        WITH KEY prueflos  = is_qals-prueflos
                 verwmerkm = gs_matn_mk_t-merkmal.
      IF sy-subrc <> 0.
        DELETE TABLE gt_matn_mk_t FROM gs_matn_mk_t.
      ENDIF.
    ENDLOOP.
  ENDIF.
ENDIF.

* Ab hier werden neue zusätzliche Einträge in Tabelle gt_yq90100 erzeugt,
* für alle geprüften Merkmale, die in Tabelle YQ0900 nicht vorgeplant waren

DATA: lv_zaehler   TYPE lfd.
DATA: lv_new_page  TYPE qkz.
*DATA: ls_matn_mk_t TYPE yqm_matn_mk_t.

DESCRIBE TABLE gt_matn_mk_t LINES sy-tfill.
READ TABLE gt_matn_mk_t INTO ls_matn_mk_t INDEX sy-tfill.

lv_zaehler = ls_matn_mk_t-zaehler.

LOOP AT gt_qamv INTO gs_qamv.
  READ TABLE gt_matn_mk_t INTO gs_matn_mk_t
  WITH KEY merkmal = gs_qamv-verwmerkm.
  IF sy-subrc = 0.
    CONTINUE.
  ENDIF.

  IF lv_new_page IS INITIAL.
    CLEAR gs_matn_mk_t.
    lv_zaehler = lv_zaehler + 1.
    gs_matn_mk_t-matnr       = ls_matn_mk_t-matnr.
    gs_matn_mk_t-zaehler     = lv_zaehler.
    gs_matn_mk_t-kennzeichen = 'S'.
    APPEND gs_matn_mk_t TO gt_matn_mk_t.
    lv_new_page = 'X'.
  ENDIF.

  CLEAR gs_matn_mk_t.
  lv_zaehler = lv_zaehler + 1.
  gs_matn_mk_t-matnr   = ls_matn_mk_t-matnr.
  gs_matn_mk_t-zaehler = lv_zaehler.
  gs_matn_mk_t-merkmal = gs_qamv-verwmerkm.
  APPEND gs_matn_mk_t TO gt_matn_mk_t.

ENDLOOP.

CALL FUNCTION 'IDWT_READ_MONTH_TEXT'
  EXPORTING
    langu = sy-langu
    month = sy-datlo+4(2)
  IMPORTING
    t247  = ls_t247.

CONCATENATE sy-datlo+6(2)
            '.'
            INTO gv_datum_lang.

CONCATENATE gv_datum_lang
            ls_t247-ltx
            sy-datlo(4)
            INTO gv_datum_lang
            SEPARATED BY space.

*LOOP AT it_qamv INTO ls_qamv
*  WHERE verwmerkm = ls_yq90100-merkmal.
*  LOOP AT it_qasr INTO ls_qasr
*    WHERE prueflos = ls_qamv-prueflos
*    AND   vorglfnr = ls_qamv-vorglfnr
*    AND   merknr   = ls_qamv-merknr.
*
**   Attribut 'U' bedeutet nicht nachweisbar.
**   Ergebnisse mit diesem Attribut haben den Messwerte 99999
**   und dürfen nicht betrachtet werden
*    IF ls_qasr-attribut = 'U'.
*      CONTINUE.
*    ENDIF.
*
*    IF ls_qasr_h            IS INITIAL.
*      ls_qasr_h = ls_qasr.
*    ELSEIF ls_qasr_h-mittelwert LT ls_qasr-mittelwert.
*      ls_qasr_h = ls_qasr.
*    ELSEIF ls_qasr_h-mittelwert EQ ls_qasr-mittelwert.
*      IF ls_qasr_h-attribut = '<'.
*        ls_qasr_h = ls_qasr.
*      ENDIF.
*    ENDIF.
*  ENDLOOP.
*
*  IF  ls_qasr_h         IS INITIAL
*  AND ls_qasr-attribut = 'U'.
** Falls bis hierhin kein Ergebnis gefunden werden konnte,
** waren offensichtlich alle Messwerte mit Attribut U versehen.
** In diesem Fall wird der Ergebniswert 99999 übernommen und damit der
** korrekte Langtext bzgl der Kontamination ausgegeben
*    ls_qasr_h = ls_qasr.
*  ENDIF.
*
*ENDLOOP.
*
*MOVE ls_qasr_h-mittelwert TO lv_mittelwert.
*MOVE ls_qasr_h-attribut   TO lv_attribut.
*
*CLEAR gs_ve_lt.
*CLEAR gs_gw.
*
*gs_gw-eingehalten           = 'O'.
*gs_gw-nicht_eingehalten     = 'O'.
*gs_gw-nicht_kontaminiert    = 'O'.
*gs_gw-gering_kontaminiert   = 'O'.
*gs_gw-mittel_kontaminiert   = 'O'.
*gs_gw-hoch_kontaminiert     = 'O'.
*gs_gw-extrem_kontaminiert   = 'O'.
*
*IF lv_attribut = '<'.
*  SELECT * FROM zq03_ve_lt INTO gs_ve_lt
*    WHERE asnum     = is_qals-matnr
*    AND   verwmerkm = ls_qamv-verwmerkm
*    AND   abw       = 'X'
*    AND   wertv     LT lv_mittelwert
*    ORDER BY wertv DESCENDING.
**  pv_name = ls_ve_lt-name_text.
*    EXIT.
*  ENDSELECT.
*ELSE.
*  SELECT * FROM zq03_ve_lt INTO gs_ve_lt
*    WHERE asnum     = is_qals-matnr
*    AND   verwmerkm = ls_qamv-verwmerkm
*    AND   abw       = 'X'
*    AND   wertv     LE lv_mittelwert
*    ORDER BY wertv DESCENDING.
**  pv_name = ls_ve_lt-name_text.
*    EXIT.
*  ENDSELECT.
*ENDIF.
*
*CLEAR gv_beauftragung.
*
*CASE gs_ve_lt-lfdnr.
*  WHEN 0.
*    gs_gw-eingehalten          = 'X'.
*    gs_gw-nicht_kontaminiert   = 'X'.
*    CONCATENATE 'Y_QM_MIETERINFO_KONTAMINIERT_'
*                '01' INTO gv_mieterinfo_langtext.
*  WHEN 1.
*    gs_gw-eingehalten          = 'X'.
*    gs_gw-gering_kontaminiert  = 'X'.
*    CONCATENATE 'Y_QM_MIETERINFO_KONTAMINIERT_'
*                '02' INTO gv_mieterinfo_langtext.
*  WHEN 2.
*    gs_gw-eingehalten          = 'X'.
*    gs_gw-gering_kontaminiert  = 'X'.
*    CONCATENATE 'Y_QM_MIETERINFO_KONTAMINIERT_'
*                '02' INTO gv_mieterinfo_langtext.
*  WHEN 3.
*    gs_gw-nicht_eingehalten    = 'X'.
*    gs_gw-mittel_kontaminiert  = 'X'.
*    CONCATENATE 'Y_QM_MIETERINFO_KONTAMINIERT_'
*                '03' INTO gv_mieterinfo_langtext.
*    gv_beauftragung            = 'X'.
*  WHEN 4.
*    gs_gw-nicht_eingehalten    = 'X'.
*    gs_gw-hoch_kontaminiert    = 'X'.
*    CONCATENATE 'Y_QM_MIETERINFO_KONTAMINIERT_'
*                '04' INTO gv_mieterinfo_langtext.
*    gv_beauftragung            = 'X'.
*  WHEN 5.
*    gs_gw-nicht_eingehalten    = 'X'.
*    gs_gw-extrem_kontaminiert  = 'X'.
*    CONCATENATE 'Y_QM_MIETERINFO_KONTAMINIERT_'
*                '05' INTO gv_mieterinfo_langtext.
*    gv_beauftragung            = 'X'.
*  WHEN 6.
*    gs_gw-nicht_eingehalten    = 'X'.
*    gs_gw-extrem_kontaminiert  = 'X'.
*    CONCATENATE 'Y_QM_MIETERINFO_KONTAMINIERT_'
*                '05' INTO gv_mieterinfo_langtext.
*    gv_beauftragung            = 'X'.
*ENDCASE.
*
*IF gv_beauftragung            = 'X'.
*  CASE is_qals-zzprobenahmeart.
*    WHEN 'S'.
*      gv_tdname_beauftragung = 'Y_QM_BEAUFTRAGUNG_S'.
*    WHEN 'W'.
*      gv_tdname_beauftragung = 'Y_QM_BEAUFTRAGUNG_W'.
*    WHEN OTHERS.
*      CLEAR gv_beauftragung.
*      CLEAR gv_tdname_beauftragung.
*  ENDCASE.
*ELSE.
*  CLEAR gv_beauftragung.
*  CLEAR gv_tdname_beauftragung.
*ENDIF.

CLEAR gs_probgew.
SELECT SINGLE * FROM yqm_probgew_t INTO gs_probgew
  WHERE probengewinnung = is_qals-yqm_probengewinnung.
IF sy-subrc <> 0.
  CLEAR gs_probgew.
ENDIF.

CLEAR gs_probart.
SELECT SINGLE * FROM yqm_probart_t INTO gs_probart
  WHERE probenahmeart = is_qals-yqm_probenahmeart.
IF sy-subrc <> 0.
  CLEAR gs_probart.
ENDIF.

*CLEAR gs_cawn.
*CLEAR gs_cawnt.
*CLEAR gs_cawn_ltext.
*
*IF NOT is_qals-zzprobengewinnung IS INITIAL.
*  SELECT SINGLE atinn FROM cabn INTO lv_atinn
*    WHERE atnam = 'LAB_PROBENGEWINNUNG'.
*  IF sy-subrc = 0.
*    SELECT SINGLE * FROM cawn INTO gs_cawn
*      WHERE atinn = lv_atinn
*      AND   atwrt = is_qals-zzprobengewinnung.
*    IF sy-subrc = 0.
*      IF gs_cawn-txtnr IS INITIAL.
*        SELECT SINGLE * FROM cawnt INTO gs_cawnt
*          WHERE atinn = gs_cawn-atinn
*          AND   atzhl = gs_cawn-atzhl
*          AND   spras = sy-langu.
*        IF sy-subrc <> 0.
*          CLEAR gs_cawnt.
*        ENDIF.
*      ELSE.
*        CONCATENATE gs_cawn-atinn gs_cawn-txtnr INTO gs_cawn_ltext.
*      ENDIF.
*    ENDIF.
*  ENDIF.
*ENDIF.
