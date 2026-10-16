class YCL_QMLIMS_QPL1_INSPLOT_CHANGE definition
  public
  final
  create public .

public section.

  interfaces IF_BADI_INTERFACE .
  interfaces IF_EX_SMOD_QPL10001 .
protected section.
private section.
ENDCLASS.



CLASS YCL_QMLIMS_QPL1_INSPLOT_CHANGE IMPLEMENTATION.


METHOD if_ex_smod_qpl10001~exit_saplqpl1_002.

  DATA:
    lv_matnr        TYPE matnr,
    lv_cuobj        TYPE pmsdo-cuobj,
    lv_sch_kave     TYPE c LENGTH 1,
    lv_gutachten    TYPE flag,
    lv_beurteilung  TYPE flag,
    lv_kein_auto_ve TYPE flag,
    lv_druck_mvi    TYPE flag,
    lv_labor        TYPE mara-labor,
    lv_name_xihpa   TYPE c LENGTH 32 VALUE '(SAPLIPAR)XIHPA[]',
    lv_status_gute  TYPE jest-stat,
    lv_status_beur  TYPE jest-stat,
    lv_status_kave  TYPE jest-stat,
    lv_status_mvid  TYPE jest-stat.

  DATA:
    ls_caufvd  TYPE caufvd,
    ls_iflot   TYPE iflot,
    ls_ihpa    TYPE ihpavb,
    ls_matn_hd TYPE yqm_matn_hd_t.

  DATA lt_ihpa TYPE STANDARD TABLE OF ihpavb.

  FIELD-SYMBOLS <ls_xihpa> TYPE ANY TABLE.

  " User-Exit nur für Prüfart CHTP durchlaufen
  CHECK i_qals-art = 'YQM_TP'.

  e_qals = i_qals.

  CALL FUNCTION 'CO_IH_GET_HEADER'
    IMPORTING
      caufvd_imp = ls_caufvd.

  IF ls_caufvd IS INITIAL.
    RETURN.
  ENDIF.

  " Fortschreibung aktivieren
  e_active         = abap_true.
  e_qals-yqm_tplnr = ls_caufvd-tplnr.

  " CUOBJ in Serviceauftrag ist nicht immer richtig versorgt,
  " deshalb wird die CUOBJ aus der Kundenauftragsposition gelesen.
* Implement suitable error handling here
  SELECT SINGLE object_id, number_int, int_obj_no, ordered_prod, description, sold_to_party
       FROM crms4_serv_i_search
       INTO @DATA(ls_crms4_serv)
       WHERE  object_type = 'BUS2000116'
         AND  object_id   = @ls_caufvd-service_doc_id
         AND  number_int  = @ls_caufvd-service_doc_item_id
         AND  int_obj_no <> '0'.
  IF sy-subrc = 0.
    lv_cuobj = ls_crms4_serv-int_obj_no.

  ELSE.
* Wenn die Position nicht gesichert war, muss aus dem Memory gelesen werden :-(
    DATA: lv_guid         TYPE crmt_object_guid,
          lv_number_int   TYPE crmt_item_no,
          ls_dataexch_btx TYPE crms4s_dataexch_btx,
          ls_orderadm_i   TYPE crmt_orderadm_i_wrk,
          ls_struct_i     TYPE crmt_struct_i_wrk.

    FIELD-SYMBOLS <lv_guid> TYPE crmt_object_guid.

    ASSIGN ('(SAPLCRM_ORDERADM_H_OW)GS_ORDERADM_H_WRK-GUID') TO <lv_guid>.
    IF <lv_guid> IS ASSIGNED.
      lv_guid = <lv_guid>.
    ENDIF.

    TRY.
        CALL METHOD cl_crms4_dataexch_mgr=>process_forward
          EXPORTING
            iv_guid         = lv_guid
          IMPORTING
            es_dataexch_btx = ls_dataexch_btx.

      CATCH cx_sy_create_object_error cx_sy_dyn_call_illegal_method.

    ENDTRY.

    lv_number_int = ls_caufvd-service_doc_item_id.

    READ TABLE ls_dataexch_btx-orderadm_i INTO ls_orderadm_i
      WITH KEY number_int = lv_number_int.
    IF sy-subrc = 0.
      MOVE-CORRESPONDING ls_orderadm_i TO ls_crms4_serv.
      READ TABLE ls_dataexch_btx-struct_i INTO ls_struct_i
        WITH KEY guid = ls_orderadm_i-guid.
      IF sy-subrc = 0.
        lv_cuobj = ls_struct_i-int_obj_no.
      ENDIF.
    ENDIF.

  ENDIF.

  DATA lv_memid  TYPE c LENGTH 45.
  DATA lv_art_le TYPE char1.

* Memory ID aus Methode CREATE_ITEM_WITH_CONFIG der Klasse YCL_QM03_SERVICE_ORDER abholen
  lv_memid = |YQM03_ART_LE_{ ls_caufvd-service_doc_id }_{ CONV i( ls_caufvd-service_doc_item_id ) }|.

  IMPORT yqm_art_le = lv_art_le FROM MEMORY ID lv_memid.
  FREE MEMORY ID lv_memid.

  IF lv_art_le = 'P'.
    e_qals-yqm_art_le = 'P'.  " aus Probeneingangsregistrierung
  ELSE.
    CLEAR e_qals-yqm_art_le.  " Manuell
  ENDIF.

  IF NOT lv_cuobj IS INITIAL. "sy-subrc = 0.

    e_qals-matnr                   = ls_crms4_serv-ordered_prod. "ls_caufvd-matnr. " ls_vbap-matnr.
    e_qals-yqm_arktx               = ls_crms4_serv-description.  "ls_caufvd-ktext. "vbap-arktx.
    e_qals-kunnr                   = ls_crms4_serv-sold_to_party.
    e_qals-yqm_service_doc_type    = ls_caufvd-service_doc_type.
    e_qals-yqm_service_doc_id      = ls_caufvd-service_doc_id.
    e_qals-yqm_service_doc_item_id = ls_caufvd-service_doc_item_id.
    e_qals-yqm_cuobj               = lv_cuobj.

    CALL FUNCTION 'Y_QMLIMS_SERVICE_GET_CONF_VALS'
      EXPORTING
        i_cuobj                = lv_cuobj
      IMPORTING
        ev_spezid              = e_qals-yqm_spezid
        ev_probenehmer03       = e_qals-yqm_probenehmer03
        ev_probenehmer40       = e_qals-yqm_probenehmer40
        ev_probenahmedatum     = e_qals-yqm_probedatum
        ev_probenahmezeit      = e_qals-yqm_probezeit
        ev_probeneingangsdatum = e_qals-yqm_probeeingang
        ev_ueberwachung        = e_qals-yqm_ueberwachung
        ev_anlass              = e_qals-yqm_anlass
        ev_gutachten           = lv_gutachten
        ev_beurteilung         = lv_beurteilung
        ev_kein_auto_ve        = lv_kein_auto_ve
        ev_pnv                 = e_qals-yqm_vnlpv
        ev_probengewinnung     = e_qals-yqm_probengewinnung
        ev_probenahmeart       = e_qals-yqm_probenahmeart.

    IF lv_gutachten = abap_true.
      CALL FUNCTION 'STATUS_TEXT_CONVERSION'
        EXPORTING
          language           = 'D'
          mode               = 'E'
          objnr              = i_qals-objnr
          txt04              = 'GUTE'
        IMPORTING
          status_number      = lv_status_gute
        EXCEPTIONS
          insufficient_input = 1
          not_found          = 2
          object_not_found   = 3
          wrong_mode         = 4
          OTHERS             = 5.
      IF sy-subrc = 0.
        CALL FUNCTION 'STATUS_CHANGE_EXTERN'
          EXPORTING
            objnr               = i_qals-objnr
            user_status         = lv_status_gute
          EXCEPTIONS
            object_not_found    = 1
            status_inconsistent = 2
            status_not_allowed  = 3
            OTHERS              = 4.
        IF sy-subrc <> 0.
          MESSAGE e214(yqmlims) WITH 'GUTE' i_qals-prueflos.
        ENDIF.
      ENDIF.
    ENDIF.

    " Für Legionellen-Materialien wird die Mieter-Verbraucherinformation
    " per Default mit ausgedruckt
    SELECT SINGLE labor
      FROM mara
      INTO @lv_labor
      WHERE matnr = @e_qals-matnr.

    IF sy-subrc = 0 AND lv_labor = 'LEG'.
      lv_druck_mvi = abap_true.
    ELSE.
      CLEAR lv_druck_mvi.
    ENDIF.

    IF lv_druck_mvi = abap_true.
      CALL FUNCTION 'STATUS_TEXT_CONVERSION'
        EXPORTING
          language           = 'D'
          mode               = 'E'
          objnr              = i_qals-objnr
          txt04              = 'MVID'
        IMPORTING
          status_number      = lv_status_mvid
        EXCEPTIONS
          insufficient_input = 1
          not_found          = 2
          object_not_found   = 3
          wrong_mode         = 4
          OTHERS             = 5.

      IF sy-subrc = 0.
        CALL FUNCTION 'STATUS_CHANGE_EXTERN'
          EXPORTING
            objnr               = i_qals-objnr
            user_status         = lv_status_mvid
          EXCEPTIONS
            object_not_found    = 1
            status_inconsistent = 2
            status_not_allowed  = 3
            OTHERS              = 4.
        IF sy-subrc <> 0.
          MESSAGE e214(yqmlims) WITH 'MVID' i_qals-prueflos.
        ENDIF.
      ENDIF.
    ENDIF.

    IF lv_beurteilung = abap_true.
      CALL FUNCTION 'STATUS_TEXT_CONVERSION'
        EXPORTING
          language           = 'D'
          mode               = 'E'
          objnr              = i_qals-objnr
          txt04              = 'BEUR'
        IMPORTING
          status_number      = lv_status_beur
        EXCEPTIONS
          insufficient_input = 1
          not_found          = 2
          object_not_found   = 3
          wrong_mode         = 4
          OTHERS             = 5.

      IF sy-subrc = 0.
        CALL FUNCTION 'STATUS_CHANGE_EXTERN'
          EXPORTING
            objnr               = i_qals-objnr
            user_status         = lv_status_beur
          EXCEPTIONS
            object_not_found    = 1
            status_inconsistent = 2
            status_not_allowed  = 3
            OTHERS              = 4.
        IF sy-subrc <> 0.
          MESSAGE e214(yqmlims) WITH 'BEUR' i_qals-prueflos.
        ENDIF.
      ENDIF.
    ENDIF.

    " Wenn Matnr in YQM_MATN_HD_T gepflegt, dann keinen Status KAVE setzen
    IF lv_matnr IS INITIAL OR lv_matnr <> ls_caufvd-matnr.
      lv_matnr = ls_caufvd-matnr.
      CLEAR lv_sch_kave.

      SELECT SINGLE matnr,
                    kave
        FROM yqm_matn_hd_t
        INTO CORRESPONDING FIELDS OF @ls_matn_hd
        WHERE matnr = @ls_caufvd-matnr.

      IF sy-subrc = 0 AND ls_matn_hd-kave = abap_true.
        lv_sch_kave = 'E'.
      ENDIF.
    ENDIF.

    IF lv_sch_kave IS INITIAL
       AND ( lv_kein_auto_ve = abap_true
          OR lv_gutachten    = abap_true
          OR lv_beurteilung  = abap_true ).

      CALL FUNCTION 'STATUS_TEXT_CONVERSION'
        EXPORTING
          language           = 'D'
          mode               = 'E'
          objnr              = i_qals-objnr
          txt04              = 'KAVE'
        IMPORTING
          status_number      = lv_status_kave
        EXCEPTIONS
          insufficient_input = 1
          not_found          = 2
          object_not_found   = 3
          wrong_mode         = 4
          OTHERS             = 5.

      IF sy-subrc = 0.
        CALL FUNCTION 'STATUS_CHANGE_EXTERN'
          EXPORTING
            objnr               = i_qals-objnr
            user_status         = lv_status_kave
          EXCEPTIONS
            object_not_found    = 1
            status_inconsistent = 2
            status_not_allowed  = 3
            OTHERS              = 4.
        IF sy-subrc <> 0.
          MESSAGE e214(yqmlims) WITH 'KAVE' i_qals-prueflos.
        ENDIF.
      ENDIF.
    ENDIF.

  ENDIF.

  IF NOT e_qals-yqm_vnlpv IS INITIAL.
    SELECT SINGLE vnlpvkt
      FROM yqm_vnltpv_t
      INTO e_qals-yqm_vnlpvkt
      WHERE vnlpv = e_qals-yqm_vnlpv.
    IF sy-subrc <> 0.
      CLEAR e_qals-yqm_vnlpvkt.
    ENDIF.
  ELSE.
    CLEAR e_qals-yqm_vnlpvkt.
  ENDIF.

  e_qals-kunnr = ls_caufvd-kunum.
  e_qals-kdauf = ls_caufvd-kdauf_aufk.
  e_qals-kdpos = ls_caufvd-kdpos_aufk.


  ASSIGN (lv_name_xihpa) TO <ls_xihpa>.
  IF sy-subrc = 0.
    lt_ihpa = <ls_xihpa>.

    READ TABLE lt_ihpa INTO ls_ihpa
         WITH KEY objnr = ls_caufvd-objnr
                  parvw = 'ZL'.
    IF sy-subrc = 0.
      e_qals-yqm_kunnrzl = ls_ihpa-parnr.
    ELSE.
      READ TABLE lt_ihpa INTO ls_ihpa
           WITH KEY objnr = ls_caufvd-objnr
                    parvw = 'AG'.
      IF sy-subrc = 0.
        e_qals-yqm_kunnrzl = ls_ihpa-parnr.
      ENDIF.
    ENDIF.

    IF e_qals-kunnr IS INITIAL.
      READ TABLE lt_ihpa INTO ls_ihpa
           WITH KEY objnr = ls_caufvd-objnr
                    parvw = 'AG'.
      IF sy-subrc = 0.
        e_qals-kunnr = ls_ihpa-parnr.
      ENDIF.
    ENDIF.

  ENDIF.

  IF e_qals-yqm_tplnr IS NOT INITIAL.
    SELECT SINGLE yqm_info1,
                  yqm_info2,
                  yqm_info3,
                  yqm_spezid,
                  yqm_prggstd
      FROM iflot
      INTO CORRESPONDING FIELDS OF @ls_iflot
      WHERE tplnr = @ls_caufvd-tplnr.

    IF sy-subrc = 0.
      e_qals-yqm_info1 = ls_iflot-yqm_info1.
      e_qals-yqm_info2 = ls_iflot-yqm_info2.
      e_qals-yqm_info3 = ls_iflot-yqm_info3.

      " Wenn über die Konfiguration keine Spezifikation mitgegeben wurde,
      " wird sie aus dem Technischen Platz übernommen
      IF e_qals-yqm_spezid IS INITIAL.
        e_qals-yqm_spezid = ls_iflot-yqm_spezid.
      ENDIF.

      " Das gleiche gilt für den Gegenstand der Prüfung
      IF e_qals-yqm_prggstd IS INITIAL.
        e_qals-yqm_prggstd = ls_iflot-yqm_prggstd.
      ENDIF.
    ENDIF.
  ENDIF.

ENDMETHOD.
ENDCLASS.
