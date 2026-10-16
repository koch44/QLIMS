REPORT yqmlims_rqeeal10 MESSAGE-ID ih NO STANDARD PAGE HEADING.
*&--------------------------------------------------------------------- *
*& Dieser Report untersucht alle Prüflose die den Selektions-           *
*& bedingungen entsprechen danach ob                                    *
*&  1. alle Merkmale mit i.O. bewertet wurden                           *
*&  2. Keine Beurteilung erforderlich ist                               *
*&                                                                      *
*& Wenn diese Voraussetzungen gegeben sind, erhält das Prueflos den     *
*& Anwenderstatus AVEM (auto. VE moeglich), ansonsten den Status        *
*& KAVE (kein auto. VE moeglich).                                       *
*& Alle Prüflose mit Status AVEM werden in einer ersten ALV Liste       *
*& angezeigt. In dieser ersten Liste kann eine Übersicht der Ergebnisse *
*& auf einem Popup angezeigt werden. Alle Prüflose für die der          *
*& automatische Verwendungsentscheid getroffen werden soll, werden in   *
*& dieser Liste markiert und die Bearbeitung wird mit F8 forgesetzt.    *
*& Alle zu diesem Zeitpunkt nicht markierten Prüflose bekommen den      *
*& Anwenderstatus KAVE und werden in einer zweiten ALV Liste angezeigt  *
*& In der zweiten Liste kann bei Bedarf eine Beurteilung erstellt       *
*& werden (abgelegt im Langtext zum VE) und der VE kann manuell         *
*& getroffen werden.                                                    *
*&--------------------------------------------------------------------- *
*& Änderungen:                                                          *
*& 17.03.2026 FISCH50   Übernahme aus TN1                               *
*&--------------------------------------------------------------------- *


INCLUDE rqalvtop.

*---------------------------------------------------------------------*
* Dictionary Tables
*---------------------------------------------------------------------*
TABLES: qals,
        qavp,
        qapo.

*---------------------------------------------------------------------*
* Types
*---------------------------------------------------------------------*
TYPES: BEGIN OF gty_object_tab.
         INCLUDE  TYPE yqm_rqeeal10.
TYPES:   kz_qave  TYPE flag,
         selected TYPE flag,
         lights   TYPE flag,
         viewed   TYPE pm_selected,
       END OF gty_object_tab.

*---------------------------------------------------------------------*
* Internal Tables
*---------------------------------------------------------------------*
DATA object_tab     TYPE STANDARD TABLE OF gty_object_tab WITH HEADER LINE WITH EMPTY KEY.
DATA object_tab_all TYPE STANDARD TABLE OF gty_object_tab WITH HEADER LINE WITH EMPTY KEY.

*---------------------------------------------------------------------*
* Authorization Buffer
*---------------------------------------------------------------------*
TYPES: BEGIN OF gty_auth,
         art       TYPE qals-art,
         werk      TYPE qals-werk,
         qmatauth  TYPE qals-qmatauth,
         cvp_xblck TYPE qals-cvp_xblck,
         ok        TYPE qm00-qkz,
       END OF gty_auth.

DATA gs_auth TYPE gty_auth.

DATA gv_anz_no_auth TYPE i.

*---------------------------------------------------------------------*
* Flags / Control
*---------------------------------------------------------------------*
DATA gv_qapo_exist       TYPE qkz.
DATA gv_qapo_select      TYPE qkz.
DATA gv_ignore_ud_fields TYPE qkz.

DATA gt_dyn_range TYPE rsds_trange.

DATA gv_stern TYPE c VALUE '*'.

*---------------------------------------------------------------------*
* Transaction / Control
*---------------------------------------------------------------------*
CONSTANTS gc_tcode TYPE sy-tcode VALUE 'QA33'.

DATA gv_tcode     TYPE sy-tcode.
DATA gv_okcode    TYPE sy-ucomm.
DATA gv_view_type TYPE c LENGTH 4 VALUE 'AVEM'.

*---------------------------------------------------------------------*
* Customizing / Helper Structures
*---------------------------------------------------------------------*
*DATA gs_t399a TYPE t399a.
*DATA gs_t370a TYPE t370a.
DATA gs_tq30  TYPE tq30.

DATA gv_dummy TYPE c.

*---------------------------------------------------------------------*
* Status / User
*---------------------------------------------------------------------*
DATA gv_user   TYPE sy-uname.
DATA gv_status TYPE jest-stat.
DATA gv_status_c TYPE c LENGTH 4.

DATA gv_display_log TYPE flag.

*---------------------------------------------------------------------*
* Application Log
*---------------------------------------------------------------------*
DATA gs_msg TYPE bal_s_msg.
DATA gs_log TYPE bal_s_log.

DATA gv_log_handle TYPE balloghndl.
DATA gt_log_handle TYPE bal_t_logh.

DATA gs_display_profile TYPE bal_s_prof.

*---------------------------------------------------------------------*
* Unicode / ALV
*---------------------------------------------------------------------*
DATA gv_message_text TYPE slis_varbz.

*---------------------------------------------------------------------*
* Constants
*---------------------------------------------------------------------*
CONSTANTS gc_pruefart TYPE c LENGTH 8 VALUE 'YQM_TP'.

*---------------------------------------------------------------------*
* User Status Constants
*---------------------------------------------------------------------*
CONSTANTS:
  gc_ergm TYPE c LENGTH 4 VALUE 'ERGM',  " Ergebniserfassung möglich
  gc_avem TYPE c LENGTH 4 VALUE 'AVEM',  " Auto. VE möglich
  gc_kave TYPE c LENGTH 4 VALUE 'KAVE',  " Kein auto. VE möglich
  gc_gute TYPE c LENGTH 4 VALUE 'GUTE'.  " Gutachten erforderlich

*---------------------------------------------------------------------*
* System Status Constants
*---------------------------------------------------------------------*
CONSTANTS:
  gc_stat_ve   TYPE jest-stat VALUE 'I0218', " VE getroffen
  gc_stat_sper TYPE jest-stat VALUE 'I0043', " Los gesperrt
  gc_stat_lsto TYPE jest-stat VALUE 'I0224'. " Los storniert

*---------------------------------------------------------------------*
* User Status (internal)
*---------------------------------------------------------------------*
DATA:
  gv_stat_ergm TYPE jest-stat,  " Ergebniserfassung möglich
  gv_stat_avem TYPE jest-stat,  " Auto VE möglich
  gv_stat_kave TYPE jest-stat,  " Kein Auto VE möglich
  gv_stat_gute TYPE jest-stat,  " Gutachten erforderlich
  gv_stat_begu TYPE jest-stat.  " Gutachten erstellt

*TABLES: qals,

* SELECT-OPTIONS mit Rahmen
SELECTION-SCREEN BEGIN OF BLOCK zusatz WITH FRAME TITLE TEXT-s11.
  SELECT-OPTIONS so_los   FOR qals-prueflos.
  SELECT-OPTIONS so_phynr FOR qals-yqm_qphysprnr.
  SELECT-OPTIONS so_kunzl FOR qals-yqm_kunnrzl.
  SELECT-OPTIONS so_pnahm FOR qals-yqm_probedatum.
SELECTION-SCREEN END OF BLOCK zusatz.

SELECTION-SCREEN BEGIN OF BLOCK code WITH FRAME TITLE TEXT-a00.
  PARAMETERS: p_ausmg TYPE qave-vauswahlmg,
              p_vwerk TYPE qave-vwerks,
              p_cdgrp TYPE qave-vcodegrp,
              p_code  TYPE qave-vcode        OBLIGATORY.
SELECTION-SCREEN END OF BLOCK code.

* PARAMETERS --------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK bottom WITH FRAME TITLE TEXT-p00.
  SELECTION-SCREEN BEGIN OF LINE.
    PARAMETERS: p_alles RADIOBUTTON GROUP ud.
    SELECTION-SCREEN COMMENT 3(70) TEXT-p03 FOR FIELD p_alles.
  SELECTION-SCREEN END OF LINE.

  SELECTION-SCREEN BEGIN OF LINE.
    PARAMETERS: p_no_ud RADIOBUTTON GROUP ud.
    SELECTION-SCREEN COMMENT 3(72) TEXT-p01 FOR FIELD p_no_ud.
  SELECTION-SCREEN END OF LINE.

  SELECTION-SCREEN BEGIN OF LINE.
    PARAMETERS: p_no_uda RADIOBUTTON GROUP ud.
    SELECTION-SCREEN COMMENT 3(70) TEXT-p05 FOR FIELD p_no_uda. "N744242
  SELECTION-SCREEN END OF LINE.

  SELECTION-SCREEN BEGIN OF LINE.
    PARAMETERS: p_ud RADIOBUTTON GROUP ud.
    SELECTION-SCREEN COMMENT 3(70) TEXT-p02 FOR FIELD p_ud.
  SELECTION-SCREEN END OF LINE.

  PARAMETERS: variant TYPE disvariant-variant.
  PARAMETERS: monitor TYPE rqmonitor-qm_monitor
              AS LISTBOX VISIBLE LENGTH 30.
  PARAMETERS: p_log   AS CHECKBOX.
SELECTION-SCREEN END OF BLOCK bottom.
*-- Mit diesen Selektionskriterien wird der optimale Zugriff auf
*   Prüflose ohne Verwendungsentscheid.
SELECT-OPTIONS:
  s_stat35 FOR qals-stat35 NO-DISPLAY.
*--------------------------------------------------------------------*
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_vwerk.
  PERFORM code_auswahl.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_ausmg.
  PERFORM code_auswahl.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_cdgrp.
  PERFORM code_auswahl.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_code.
  PERFORM code_auswahl.

AT SELECTION-SCREEN ON BLOCK code.
  PERFORM code_auswahl.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR variant.
  PERFORM variant_inputhelp_f14 USING variant.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR monitor.
  PERFORM create_monitor_tab_f16.
  PERFORM monitor_inputhelp_f16 USING monitor.
*--------------------------------------------------------------------*
* AT SELECTION SCREEN OUTPUT                                         *
*--------------------------------------------------------------------*
AT SELECTION-SCREEN OUTPUT.
  CHECK g_submit IS INITIAL.
* Fcode FC01 bei Variantenpflege deaktivieren
  PERFORM user_fc_steuern.
  LOOP AT SCREEN.
    IF screen-name CP 'QL_PRPLZ*' OR
       screen-name CP '%_QL_PRPLZ_%_APP_%*'.
*     Hide text of workplace
      screen-input = 0.
      screen-output = 0.
      screen-active = 0.
      MODIFY SCREEN.
    ENDIF.
    IF screen-name CP 'QL_PRPLT*' OR
       screen-name CP '%_QL_PRPLT_%_APP_%*'.
*     Hide text of workplace text
      screen-input = 0.
      screen-output = 0.
      screen-active = 0.
      MODIFY SCREEN.
    ENDIF.
    IF screen-name CP 'QL_PRWRK*' OR
       screen-name CP '%_QL_PRWRK_%_APP_%*'.
*     Hide text of workplace plant
      screen-input = 0.
      screen-output = 0.
      screen-active = 0.
      MODIFY SCREEN.
    ENDIF.
* deactivate Selection Profile in Cloud
    IF ( screen-name = 'QL_SELID' OR
         screen-name = '%_QL_SELID_%_APP_%-TEXT' )  AND
       cl_qall_switch_check=>qm_sfws_ui_qall( ) IS INITIAL.
      screen-active = '0'.
      MODIFY SCREEN.
    ENDIF.

  ENDLOOP.

*--------------------------------------------------------------------*
* AT SELECTION SCREEN                                                *
*--------------------------------------------------------------------*
*------------------------------*
AT SELECTION-SCREEN ON RADIOBUTTON GROUP ud.

  CLEAR s_stat35[].

  IF NOT p_no_ud  IS INITIAL
  OR NOT p_no_uda IS INITIAL.
    " nur Prüflosse mit STAT35 = space
    APPEND VALUE #(
      sign   = 'I'
      option = 'EQ'
      low    = space ) TO s_stat35.

  ELSEIF NOT p_ud IS INITIAL.
    " nur Prüflosse mit STAT35 = 'X'
    APPEND VALUE #(
      sign   = 'I'
      option = 'EQ'
      low    = 'X' ) TO s_stat35.
  ENDIF.
*------------------------------*
AT SELECTION-SCREEN.

  PERFORM variant_existence_f14 USING variant.     "check for Cust. var.

  CHECK g_submit IS INITIAL.
  g_variant-variant = variant.
*== F-Code verarbeiten
  IF sscrfields-ucomm EQ 'FC01'.
*-- User-Variante einstellen
    PERFORM variant_f10.
*   neuer Aufruf um Variante zu uebernehmen
    IF sy-tcode = 'SE38'
    OR sy-tcode = 'SA38'.
      SUBMIT (sy-repid) VIA SELECTION-SCREEN.
    ELSE.
      LEAVE TO TRANSACTION sy-tcode.
    ENDIF.
  ENDIF.

*--------------------------------------------------------------------*
* INITIALIZATION                                                     *
*--------------------------------------------------------------------*
INITIALIZATION.

* Performance: Preread auf die JEST, da Vorgänge geprüft werden
* move g_x to G_STATUS_PREREAD.

  IF p_ausmg IS INITIAL
  OR p_vwerk IS INITIAL
  OR p_cdgrp IS INITIAL
  OR p_code  IS INITIAL.
* Ermittlung Vorschlagswerte aus Werkseinstellungen (Werk 1011)
    SELECT SINGLE ppvemenge,
                  ppvewerk,
                  ppvecodegr,
                  ppvecode
      FROM tqss1
      INTO (@p_ausmg, @p_vwerk, @p_cdgrp, @p_code)
      WHERE werks = '1011'.
    IF sy-subrc <> 0.
      CLEAR: p_ausmg, p_vwerk, p_cdgrp, p_code.
    ENDIF.
  ENDIF.

  PERFORM check_status_settings.

*--- Aktivitätstyp bestimmen -----------------------------------------
  SELECT SINGLE * FROM t370a WHERE tcode = sy-tcode.
  IF sy-subrc <> 0.
    SELECT SINGLE * FROM t370a WHERE tcode = gc_tcode.
    IF sy-subrc <> 0.
      MESSAGE e119(yqmlims) WITH sy-tcode.
    ENDIF.
  ENDIF.

  g_tabname = 'YQM_RQEEAL10'.
  IF NOT sy-calld IS INITIAL.
    IMPORT g_submit = g_submit g_fieldcat_tab = g_fieldcat_tab FROM MEMORY ID 'SUBMIT'.
  ENDIF.

*-------------------------------------------------------------------*
  gv_message_text = TEXT-tes.
  PERFORM variant_init_f14 USING 'LOTS'
                                 'LOTS'
*                                text-tes.
                                 gv_message_text.
  CHECK g_submit IS INITIAL.
*-- Report-Selektionsvariante lesen
  PERFORM variant_start_f10.
*-- ALV-Anzeigevariante vorschlagen
  IF NOT variant IS INITIAL.
    PERFORM get_default_variant_f14 USING variant.
*   Wenn die angegebene ALV-Anzeigevariante nicht existiert, ist der
*   Parameter variant jetzt leer.
  ENDIF.
  IF variant IS INITIAL.
*   Default-Anzeigevariante suchen
    PERFORM get_default_variant_f14 USING variant.
  ENDIF.

  IF  p_alles  IS INITIAL
  AND p_no_ud  IS INITIAL
  AND p_no_uda IS INITIAL
  AND p_ud     IS INITIAL.
    p_no_uda = 'X'.
  ENDIF.

*---------------------------------------------------------------------*
  SELECTION-SCREEN
*-- FUNCTION KEYS
  FUNCTION KEY 1.
*-- DEFINE FUNCTION KEYS ON INITIAL SCREEN
  sscrfields-functxt_01 = 'Meine Vorbelegung   '(f01).

*---------------------------------------------------------------------*
* START OF SELECTION                                                  *
*---------------------------------------------------------------------*
START-OF-SELECTION.

  " Initialize operation selection
  CALL FUNCTION 'RS_REFRESH_FROM_DYNAMICAL_SEL'
    EXPORTING
      curr_report        = 'RQEEAL10'
      mode_write_or_move = 'W'
    IMPORTING
      p_trange           = gt_dyn_range
    EXCEPTIONS
      OTHERS             = 1.

  IF sy-subrc = 0.
    READ TABLE gt_dyn_range
         WITH KEY tablename = 'QAPO'
         TRANSPORTING NO FIELDS.
    IF sy-subrc = 0.
      gv_qapo_select = g_x.
    ENDIF.
  ENDIF.

*--- Aktivitätstyp bestimmen -----------------------------------------
  SELECT SINGLE * FROM t370a WHERE tcode = sy-tcode.
  IF sy-subrc <> 0.
    SELECT SINGLE * FROM t370a WHERE tcode = gc_tcode.
    IF sy-subrc <> 0.
      MESSAGE e119(yqmlims) WITH sy-tcode.
    ENDIF.
  ENDIF.


  IF g_submit IS INITIAL.
    PERFORM create_fieldcat_l USING g_tabname.
    PERFORM update_fieldcat_variant_f14.
  ENDIF.

  PERFORM select_fields_manip_l USING g_fieldcat_tab.

* Stati are checked in this report. Therefore JEST is preread
  preread = g_x.

*-------------------------------------------------------------------*
* GET                                                               *
*-------------------------------------------------------------------*

GET qals FIELDS prueflos
                obtyp
                objnr
                aufpl
                art
                werk
                qmatauth
                offennlzmk
                offen_lzmk
                pastrterm
                paendterm
                lmengezub
                aufnr_co
                plnty
                insmk
                stat11
                lmenge01
                lmenge04
                stat02
                stat07
                stat35
                stat36
                stat43
                /cwm/losmenge
                /cwm/lmengezub.

  IF ql_prwrk IS NOT INITIAL.
    CHECK qals-werk IN ql_prwrk.
  ENDIF.

  IF ql_prplz IS NOT INITIAL.
    SELECT SINGLE vaplz
      FROM t399a
      INTO @DATA(lv_vaplz)
      WHERE iwerk    = @qals-werk
        AND svobj_id = '01'
        AND svobj    = @qals-matnr.

    IF sy-subrc = 0.
      CHECK lv_vaplz IN ql_prplz.
    ENDIF.
  ENDIF.

* Prüfartenberechtigung prüfen mit Puffer
  IF gs_auth-art <> qals-art
     OR gs_auth-werk <> qals-werk.

*   Berechtigung hat sich geändert, neu prüfen
    MOVE-CORRESPONDING qals TO gs_auth.

    CALL FUNCTION 'QAUT_INSPTYPE'
      EXPORTING
        i_pruefart       = gs_auth-art
        i_werk           = gs_auth-werk
      EXCEPTIONS
        auth_destroyed   = 1
        internal_error   = 2
        no_authorization = 3
        OTHERS           = 4.
    IF sy-subrc = 0.
      gs_auth-ok = g_x.
    ELSE.
      CLEAR gs_auth-ok.
      REJECT.
    ENDIF.
  ENDIF.

* Berechtigung prüfen
  IF gs_auth-ok IS INITIAL.
    gv_anz_no_auth = gv_anz_no_auth + 1.
    REJECT.
  ENDIF.

* FILL INTERNAL TABLE
  CLEAR object_tab.
  MOVE-CORRESPONDING qals TO object_tab.
  object_tab-kz_qave = qals-stat35.

  PERFORM set_monitor_f16.

* GENERATE STATUS AND USER TEXTS
  CALL FUNCTION 'STATUS_TEXT_EDIT'
    EXPORTING
      objnr            = qals-objnr
      flg_user_stat    = g_x
      spras            = sy-langu
    IMPORTING
      line             = object_tab-sttxt
      user_line        = object_tab-ustxt
    EXCEPTIONS
      object_not_found = 1
      OTHERS           = 2.

  IF sy-subrc <> 0.
    CLEAR: object_tab-sttxt,
           object_tab-ustxt.
  ENDIF.

* Ausser den Status LSTO und SPER sollen keine System-/und
* Anwenderstatus explizit geprüft werden. Die Prüfung soll
* mit den Selektionsschema durchgeführt werden
  CALL FUNCTION 'STATUS_CHECK'
    EXPORTING
      objnr             = qals-objnr
      status            = gc_stat_lsto
    EXCEPTIONS
      object_not_found  = 1
      status_not_active = 2
      OTHERS            = 3.
  IF sy-subrc = 0.
    REJECT.
  ENDIF.

  CALL FUNCTION 'STATUS_CHECK'
    EXPORTING
      objnr             = qals-objnr
      status            = gc_stat_sper
    EXCEPTIONS
      object_not_found  = 1
      status_not_active = 2
      OTHERS            = 3.
  IF sy-subrc = 0.
    REJECT.
  ENDIF.

  IF object_tab-yqm_tplnr IS NOT INITIAL.
    SELECT SINGLE yqm_info1,
                  yqm_info2,
                  yqm_info3
      FROM iflot
      INTO @DATA(ls_iflot)
      WHERE tplnr = @object_tab-yqm_tplnr.

    IF sy-subrc = 0.
      object_tab-yqm_info1 = ls_iflot-yqm_info1.
      object_tab-yqm_info2 = ls_iflot-yqm_info2.
      object_tab-yqm_info3 = ls_iflot-yqm_info3.
    ENDIF.
  ENDIF.

* Logic is as follows: If UD data is not required, object_tab is
* appended. If it is required, a flag is set which is then changed at GET
* QAVP to account for the dynamic selections.
  IF p_no_ud IS NOT INITIAL.
    IF qals-offennlzmk = 0.
      REJECT.
    ENDIF.

  ELSEIF p_no_uda IS NOT INITIAL.
    IF qals-offennlzmk > 0.
      REJECT.
    ENDIF.
  ENDIF.

  IF p_no_ud IS NOT INITIAL
     OR p_no_uda IS NOT INITIAL
     OR ( p_alles IS NOT INITIAL AND qals-stat35 = space ).

*   kein VE zu lesen
    APPEND object_tab TO object_tab_all.
    REJECT.
  ELSE.
*   elseif qals-stat35 eq g_x.
    qals-stat35 = 'Y'.
  ENDIF.

GET qapo FIELDS vornr.
  gv_qapo_exist = g_x.

GET qavp FIELDS prueflos.
  MOVE-CORRESPONDING qavp TO object_tab.
* get QAVE custom fields descriptions (QAVE custom fields are only filled
* in the worklist if the UD is made)
* PERFORM get_descriptions USING name_ps_qave ls_qave_ps ls_qave_tr qavp.
  qals-stat35 = g_x.

GET qals LATE FIELDS prueflos
                     obtyp
                     objnr
                     aufpl
                     aufnr_co
                     plnty
                     stat02
                     stat07.

  IF ( qals-stat35 = g_x OR gv_ignore_ud_fields = g_x )
     AND ( gv_qapo_select IS INITIAL OR gv_qapo_exist = g_x ).
    APPEND object_tab TO object_tab_all.
  ENDIF.

*--------------------------------------------------------------------*
* END OF SELECTION                                                   *
*--------------------------------------------------------------------*
END-OF-SELECTION.

  CLEAR gv_display_log.

  CLEAR gt_log_handle.

  gs_log-object     = 'YQM'.
  gs_log-subobject  = 'YQM_QA33'.
  gs_log-extnumber  = 'Statuswechsel beim Einstieg in YQM_QA33'.

  CALL FUNCTION 'BAL_LOG_CREATE'
    EXPORTING
      i_s_log      = gs_log
    IMPORTING
      e_log_handle = gv_log_handle
    EXCEPTIONS
      OTHERS       = 1.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    APPEND gv_log_handle TO gt_log_handle.
  ENDIF.

* Zuerst der Anwenderstatus aller selektierten Prüflose im Status 'ERGM'
* setzen auf
*            'AVEM' - falls automatischer VE möglich
*            'KAVE' - falls kein automatischer VE erlaubt

  FIELD-SYMBOLS <gs_object_tab_all> LIKE LINE OF object_tab_all.

  LOOP AT object_tab_all ASSIGNING <gs_object_tab_all>.

    CLEAR: gv_status,
           gv_status_c.

    "---- Status ERGM (Ergebniserfassung möglich)
    CALL FUNCTION 'STATUS_CHECK'
      EXPORTING
        bypass_buffer     = g_x
        objnr             = <gs_object_tab_all>-objnr
        status            = gv_stat_ergm
      EXCEPTIONS
        object_not_found  = 1
        status_not_active = 2
        OTHERS            = 3.
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    gv_status   = gv_stat_avem.
    gv_status_c = gc_avem.

    "---- Status GUTE (Gutachten erforderlich)
    CALL FUNCTION 'STATUS_CHECK'
      EXPORTING
        bypass_buffer     = g_x
        objnr             = <gs_object_tab_all>-objnr
        status            = gv_stat_gute
      EXCEPTIONS
        object_not_found  = 1
        status_not_active = 2
        OTHERS            = 3.
    IF sy-subrc = 0.
      gv_status   = gv_stat_kave.
      gv_status_c = gc_kave.
    ENDIF.

    "-- Prüfen, ob mind. ein nicht i.O.-Merkmal in QAMR existiert
    SELECT SINGLE @abap_true
      FROM qamr
      WHERE prueflos = @<gs_object_tab_all>-prueflos
        AND mbewertg <> 'A'
      INTO @DATA(lv_qamr_exists).

    IF sy-subrc = 0.
      gv_status   = gv_stat_kave.
      gv_status_c = gc_kave.
    ENDIF.

    "-- Prüfen, ob mind. ein kritisches Merkmal in QASR existiert
    SELECT SINGLE @abap_true
      FROM qasr
      WHERE prueflos = @<gs_object_tab_all>-prueflos
        AND ( mbewertg <> 'A'
           OR attribut = 'W'
           OR fehlklas = '90' )
      INTO @DATA(lv_qasr_exists).

    IF sy-subrc = 0.
      gv_status   = gv_stat_kave.
      gv_status_c = gc_kave.
    ENDIF.

    IF gv_status IS NOT INITIAL.

      "-- Sperre setzen
      CALL FUNCTION 'ENQUEUE_EQQALS1'
        EXPORTING
          prueflos       = <gs_object_tab_all>-prueflos
        EXCEPTIONS
          foreign_lock   = 1
          system_failure = 2
          OTHERS         = 3.

      IF sy-subrc = 0.

        "---- Status AVEM oder KAVE setzen
        CALL FUNCTION 'STATUS_CHANGE_EXTERN'
          EXPORTING
            objnr               = <gs_object_tab_all>-objnr
            user_status         = gv_status
          EXCEPTIONS
            object_not_found    = 1
            status_inconsistent = 2
            status_not_allowed  = 3
            OTHERS              = 4.

        IF sy-subrc = 0.
          MESSAGE s301(yqmlims) WITH <gs_object_tab_all>-prueflos
                                     gv_status_c INTO gv_dummy.
          PERFORM add_message.
          COMMIT WORK AND WAIT.
        ELSE.
          MESSAGE e302(yqmlims) WITH <gs_object_tab_all>-prueflos
                                     gv_status_c INTO gv_dummy.
          PERFORM add_message.
        ENDIF.

      ELSE.
        gv_user = sy-msgv1.
        MESSAGE w303(yqmlims) WITH <gs_object_tab_all>-prueflos
                                   gv_status_c
                                   gv_user INTO gv_dummy.
        PERFORM add_message.
      ENDIF.
    ENDIF.

    CALL FUNCTION 'STATUS_TEXT_EDIT'
      EXPORTING
        objnr            = <gs_object_tab_all>-objnr
        flg_user_stat    = g_x
        spras            = sy-langu
        bypass_buffer    = g_x
      IMPORTING
        line             = <gs_object_tab_all>-sttxt
        user_line        = <gs_object_tab_all>-ustxt
      EXCEPTIONS
        object_not_found = 1
        OTHERS           = 2.

    IF sy-subrc <> 0.
      CLEAR: <gs_object_tab_all>-sttxt,
             <gs_object_tab_all>-ustxt.
    ENDIF.

  ENDLOOP.

  IF gv_display_log = 'X'.
    IF p_log = 'X'.
      PERFORM display_log.
    ENDIF.
    PERFORM save_log.
  ENDIF.

  gv_view_type = 'KAVE'.
  PERFORM refresh_object_list.

  IF gv_anz_no_auth GT 0.
*   Lose ohne Berechtigung vorhanden
    MESSAGE s046.
    CLEAR gv_anz_no_auth.
  ENDIF.
  IF g_submit = 'X'.
* CALL MODUS FOR REFRESH
    EXPORT object_tab = object_tab TO MEMORY ID g_repid.
  ELSE.
* TESTLAUF is set in DBPGQSEL. It has nothing to do with this report,
* but shows up in the selection criteria popup if it isn't cleared.
*   CLEAR TESTLAUF.
*   CLEAR G_FORM_TOP_OF_PAGE.
    CLEAR dy_tcode.
    PERFORM fill_events_f14.
    PERFORM fill_event_exit_tab_f14.
    PERFORM fill_layout_f16.
    PERFORM get_fieldcat_actual_f16.
    PERFORM fill_fieldgroups_f16.
    PERFORM call_listviewer_f14 USING g_fieldcat_tab[] object_tab[].
  ENDIF.

*---------------------------------------------------------------------*
*       FORM USER_COMMAND_L             called dynamically            *
*---------------------------------------------------------------------*
*       handle locally defined f-codes                                *
*---------------------------------------------------------------------*
*  -->  P_UCOMM                                                       *
*  -->  is_selfield                                                    *
*---------------------------------------------------------------------*
FORM user_command_l USING iv_ucomm    TYPE sy-ucomm
                          is_selfield TYPE slis_selfield.

  DATA:
    lv_subrc         TYPE sy-subrc,
    lv_objnr         TYPE caufvd-objnr,
    lv_ttext         TYPE tstct-ttext,
    lv_kdauf         TYPE aufk-kdauf,
    lv_process_ud    TYPE abap_bool,
    lv_attachment    TYPE swo_typeid,
    ls_qals          TYPE qals,
    ls_qave          TYPE qave,
    ls_caufv         TYPE caufv,
    ls_caufvd        TYPE caufvd,
    ls_t350          TYPE t350,
    lo_attachment    TYPE REF TO cl_gos_document_service,
    ls_object        TYPE borident,
    lt_selected_lots TYPE SORTED TABLE OF qals-prueflos
                       WITH UNIQUE KEY table_line,
    lt_aufnr         TYPE SORTED TABLE OF aufk-aufnr
                       WITH UNIQUE KEY table_line,
    lt_prueflos      TYPE SORTED TABLE OF qals-prueflos
                       WITH UNIQUE KEY table_line.

  TYPES:
    BEGIN OF lty_stat35,
      prueflos TYPE qals-prueflos,
      stat35   TYPE qals-stat35,
    END OF lty_stat35,
    BEGIN OF lty_aufk_kdauf,
      aufnr TYPE aufk-aufnr,
      kdauf TYPE aufk-kdauf,
    END OF lty_aufk_kdauf,
    BEGIN OF lty_qamr_rejected,
      prueflos TYPE qamr-prueflos,
    END OF lty_qamr_rejected.

  DATA:
    lt_stat35_init   TYPE HASHED TABLE OF lty_stat35
                       WITH UNIQUE KEY prueflos,
    lt_stat35_after  TYPE HASHED TABLE OF lty_stat35
                       WITH UNIQUE KEY prueflos,
    lt_aufk_kdauf    TYPE HASHED TABLE OF lty_aufk_kdauf
                       WITH UNIQUE KEY aufnr,
    lt_qamr_rejected TYPE HASHED TABLE OF lty_qamr_rejected
                      WITH UNIQUE KEY prueflos.

  FIELD-SYMBOLS:
    <ls_object_tab>     LIKE LINE OF object_tab,
    <ls_object_tab_all> LIKE LINE OF object_tab_all,
    <ls_stat35>         TYPE lty_stat35,
    <ls_aufk_kdauf>     TYPE lty_aufk_kdauf,
    <ls_qamr_rejected>  TYPE lty_qamr_rejected.

  CASE iv_ucomm.

    WHEN 'AKTU'.                    " Liste aktualisieren

      is_selfield-refresh = g_s.

      LOOP AT object_tab_all ASSIGNING <ls_object_tab_all>.

        CALL FUNCTION 'STATUS_TEXT_EDIT'
          EXPORTING
            objnr            = <ls_object_tab_all>-objnr
            flg_user_stat    = g_x
            spras            = sy-langu
            bypass_buffer    = g_x
          IMPORTING
            line             = <ls_object_tab_all>-sttxt
            user_line        = <ls_object_tab_all>-ustxt
          EXCEPTIONS
            object_not_found = 1
            OTHERS           = 2.

        IF sy-subrc <> 0.
          CLEAR: <ls_object_tab_all>-sttxt,
                 <ls_object_tab_all>-ustxt.
        ENDIF.

      ENDLOOP.

      PERFORM refresh_object_list.

    WHEN 'V-A '.                       " Display<->Change mode
      is_selfield-refresh = g_s.
      PERFORM change_aktyp_l.

    WHEN 'A-V '.                       " Display<->Change mode
      is_selfield-refresh = g_s.
      PERFORM change_aktyp_l.

* Prüfbericht ausdrucken
    WHEN 'PRLS'.

      LOOP AT object_tab ASSIGNING <ls_object_tab>
           WHERE selected = g_x.

        <ls_object_tab>-viewed = sym_check_mark.

        SET PARAMETER ID 'QLS' FIELD <ls_object_tab>-prueflos.

        SUBMIT yqmlims_create_certificate AND RETURN.

        READ TABLE object_tab_all ASSIGNING <ls_object_tab_all>
             WITH KEY prueflos = <ls_object_tab>-prueflos.
        IF sy-subrc = 0.

          CALL FUNCTION 'STATUS_TEXT_EDIT'
            EXPORTING
              objnr            = <ls_object_tab_all>-objnr
              flg_user_stat    = g_x
              spras            = sy-langu
              bypass_buffer    = g_x
            IMPORTING
              line             = <ls_object_tab_all>-sttxt
              user_line        = <ls_object_tab_all>-ustxt
            EXCEPTIONS
              object_not_found = 1
              OTHERS           = 2.

          IF sy-subrc <> 0.
            CLEAR: <ls_object_tab_all>-sttxt,
                   <ls_object_tab_all>-ustxt.
          ENDIF.

          <ls_object_tab>-sttxt = <ls_object_tab_all>-sttxt.
          <ls_object_tab>-ustxt = <ls_object_tab_all>-ustxt.

        ELSE.
          CLEAR: <ls_object_tab>-sttxt,
                 <ls_object_tab>-ustxt.
        ENDIF.

        is_selfield-refresh = abap_true.

      ENDLOOP.

* Prüfberichtsvorschau ausdrucken
    WHEN 'PRLS_PDF'.

      LOOP AT object_tab ASSIGNING <ls_object_tab>
           WHERE selected = g_x.

        <ls_object_tab>-viewed = sym_check_mark.

        PERFORM preview_pdf USING    <ls_object_tab>-prueflos
*                                     <ls_object_tab>-werk
                                     space
                            CHANGING gv_okcode.

        READ TABLE object_tab_all ASSIGNING <ls_object_tab_all>
             WITH KEY prueflos = <ls_object_tab>-prueflos.
        IF sy-subrc = 0.

          CALL FUNCTION 'STATUS_TEXT_EDIT'
            EXPORTING
              objnr            = <ls_object_tab_all>-objnr
              flg_user_stat    = g_x
              spras            = sy-langu
              bypass_buffer    = g_x
            IMPORTING
              line             = <ls_object_tab_all>-sttxt
              user_line        = <ls_object_tab_all>-ustxt
            EXCEPTIONS
              object_not_found = 1
              OTHERS           = 2.

          IF sy-subrc <> 0.
            CLEAR: <ls_object_tab_all>-sttxt,
                   <ls_object_tab_all>-ustxt.
          ENDIF.

          <ls_object_tab>-sttxt = <ls_object_tab_all>-sttxt.
          <ls_object_tab>-ustxt = <ls_object_tab_all>-ustxt.

        ELSE.
          CLEAR: <ls_object_tab>-sttxt,
                 <ls_object_tab>-ustxt.
        ENDIF.

        is_selfield-refresh = abap_true.

      ENDLOOP.

* Automatischen Verwendungsentscheid treffen
    WHEN 'VE_AUTO'
      OR 'VE'.

      IF iv_ucomm = 'VE_AUTO'.
        gv_view_type = 'AVEM'.
      ELSE.
        gv_view_type = 'KAVE'.
      ENDIF.

      CLEAR gv_display_log.

      "------------------------------------------------------------
      " Vorab benötigte Schlüssel sammeln
      "------------------------------------------------------------
      LOOP AT object_tab ASSIGNING <ls_object_tab>
           WHERE selected = abap_true.

        INSERT <ls_object_tab>-prueflos INTO TABLE lt_prueflos.

        READ TABLE object_tab_all ASSIGNING <ls_object_tab_all>
             WITH KEY prueflos = <ls_object_tab>-prueflos.
        IF sy-subrc = 0 AND <ls_object_tab_all>-aufnr IS NOT INITIAL.
          INSERT <ls_object_tab_all>-aufnr INTO TABLE lt_aufnr.
        ENDIF.
      ENDLOOP.

      "------------------------------------------------------------
      " AUFK einmalig lesen
      "------------------------------------------------------------
      IF lt_aufnr IS NOT INITIAL.

        SELECT aufnr, kdauf
          FROM aufk
          INTO TABLE @DATA(lt_aufk_db)
          FOR ALL ENTRIES IN @lt_aufnr
          WHERE aufnr = @lt_aufnr-table_line.

        IF sy-subrc = 0.
          lt_aufk_kdauf = CORRESPONDING #( lt_aufk_db ).
        ELSE.
          CLEAR lt_aufk_kdauf.
        ENDIF.
      ENDIF.

      "------------------------------------------------------------
      " QAMR nur für AVEM einmalig lesen:
      " Prüflosse mit zurückgewiesenen Merkmalen
      "------------------------------------------------------------
      IF gv_view_type = 'AVEM'
         AND lt_prueflos IS NOT INITIAL.

        CLEAR lt_qamr_rejected.

        SELECT DISTINCT prueflos
          FROM qamr
          INTO TABLE @DATA(lt_qamr_db)
          FOR ALL ENTRIES IN @lt_prueflos
          WHERE prueflos   = @lt_prueflos-table_line
            AND satzstatus = '5'
            AND mbewertg   = 'R'.

        IF sy-subrc = 0.
          lt_qamr_rejected = CORRESPONDING #( lt_qamr_db ).
        ENDIF.
      ENDIF.

      "------------------------------------------------------------
      " Hauptverarbeitung
      "------------------------------------------------------------
      LOOP AT object_tab ASSIGNING <ls_object_tab>
           WHERE selected = abap_true.

        READ TABLE object_tab_all ASSIGNING <ls_object_tab_all>
             WITH KEY prueflos = <ls_object_tab>-prueflos.
        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.

        CLEAR lv_kdauf.
        ASSIGN lt_aufk_kdauf[ aufnr = <ls_object_tab_all>-aufnr ] TO <ls_aufk_kdauf>.
        IF sy-subrc = 0.
          lv_kdauf = <ls_aufk_kdauf>-kdauf.
        ENDIF.

        IF lv_kdauf IS NOT INITIAL.
          CALL FUNCTION 'ENQUEUE_EVVBAKE'
            EXPORTING
              mode_vbak      = 'E'
              vbeln          = lv_kdauf
            EXCEPTIONS
              foreign_lock   = 1
              system_failure = 2
              OTHERS         = 3.
          IF sy-subrc <> 0.
            MESSAGE i022(yqmlims) WITH lv_kdauf.
            CONTINUE.
          ENDIF.

          CALL FUNCTION 'DEQUEUE_EVVBAKE'
            EXPORTING
              vbeln = lv_kdauf.
          IF sy-subrc <> 0.
            MESSAGE i022(yqmlims) WITH lv_kdauf.
            CONTINUE.
          ENDIF.
        ENDIF.

        CALL FUNCTION 'ENQUEUE_EQQALS1'
          EXPORTING
            mode_qals      = 'E'
            prueflos       = <ls_object_tab>-prueflos
          EXCEPTIONS
            foreign_lock   = 1
            system_failure = 2
            OTHERS         = 3.
        IF sy-subrc <> 0.
          MESSAGE i023(yqmlims) WITH <ls_object_tab>-prueflos.
          CONTINUE.
        ENDIF.

        CALL FUNCTION 'DEQUEUE_EQQALS1'
          EXPORTING
            prueflos = <ls_object_tab>-prueflos.
        IF sy-subrc <> 0.
          MESSAGE i023(yqmlims) WITH <ls_object_tab>-prueflos.
          CONTINUE.
        ENDIF.

        CALL FUNCTION 'STATUS_CHECK'
          EXPORTING
            bypass_buffer     = abap_true
            client            = sy-mandt
            objnr             = <ls_object_tab_all>-objnr
            status            = gc_stat_ve
          EXCEPTIONS
            object_not_found  = 1
            status_not_active = 2
            OTHERS            = 3.
        IF sy-subrc = 0.
          " VE wurde bereits getroffen
          MESSAGE i309(yqmlims) WITH <ls_object_tab_all>-prueflos.
          CONTINUE.
        ENDIF.

        IF gv_view_type = 'AVEM'.
          ASSIGN lt_qamr_rejected[ prueflos = <ls_object_tab>-prueflos ] TO <ls_qamr_rejected>.
          IF sy-subrc = 0.
            lv_process_ud = abap_false.
          ELSE.
            lv_process_ud = abap_true.
          ENDIF.
        ELSE.
          lv_process_ud = abap_true.
        ENDIF.

        IF lv_process_ud = abap_true.
          " Automatischen VE treffen
          PERFORM process_ud USING <ls_object_tab_all>.
        ELSE.
          " Status 'KAVE' kein automatischer VE setzen
          gv_status   = gv_stat_kave.
          gv_status_c = gc_kave.

          IF gv_status IS NOT INITIAL.
            CALL FUNCTION 'ENQUEUE_EQQALS1'
              EXPORTING
                prueflos       = <ls_object_tab_all>-prueflos
              EXCEPTIONS
                foreign_lock   = 1
                system_failure = 2
                OTHERS         = 3.
            IF sy-subrc = 0.

              CALL FUNCTION 'STATUS_CHANGE_EXTERN'
                EXPORTING
                  objnr               = <ls_object_tab_all>-objnr
                  user_status         = gv_status
                EXCEPTIONS
                  object_not_found    = 1
                  status_inconsistent = 2
                  status_not_allowed  = 3
                  OTHERS              = 4.

              IF sy-subrc = 0.
                MESSAGE s301(yqmlims) WITH <ls_object_tab_all>-prueflos
                                           gv_status_c INTO gv_dummy.
                PERFORM add_message.
                COMMIT WORK.
              ELSE.
                MESSAGE e302(yqmlims) WITH <ls_object_tab_all>-prueflos
                                           gv_status_c INTO gv_dummy.
                PERFORM add_message.
              ENDIF.

            ELSE.
              WRITE sy-msgv1 TO gv_user.
              MESSAGE w303(yqmlims) WITH <ls_object_tab_all>-prueflos
                                         gv_status_c
                                         gv_user INTO gv_dummy.
              PERFORM add_message.
            ENDIF.
          ENDIF.
        ENDIF.

        CALL FUNCTION 'STATUS_TEXT_EDIT'
          EXPORTING
            objnr            = <ls_object_tab_all>-objnr
            flg_user_stat    = g_x
            spras            = sy-langu
            bypass_buffer    = g_x
          IMPORTING
            line             = <ls_object_tab_all>-sttxt
            user_line        = <ls_object_tab_all>-ustxt
          EXCEPTIONS
            object_not_found = 1
            OTHERS           = 2.

        IF sy-subrc <> 0.
          CLEAR: <ls_object_tab_all>-sttxt,
                 <ls_object_tab_all>-ustxt.
        ENDIF.

      ENDLOOP.

      gv_view_type = 'KAVE'.

      IF gv_display_log = abap_true.
        IF p_log = abap_true.
          PERFORM display_log.
        ENDIF.
        PERFORM save_log.
      ENDIF.

      PERFORM refresh_object_list.
      is_selfield-refresh = abap_true.

* Ergebnisliste anzeigen
    WHEN 'ERG_LISTE'.

      LOOP AT object_tab ASSIGNING <ls_object_tab>
           WHERE selected = g_x.

        <ls_object_tab>-viewed = sym_check_mark.

        MOVE-CORRESPONDING <ls_object_tab> TO ls_qals.
        MOVE-CORRESPONDING <ls_object_tab> TO ls_qave.

        CALL FUNCTION 'Y_QMLIMS_QFOA_CREATE_EVALUATIO'
          EXPORTING
            i_qals            = ls_qals
            i_qave            = ls_qave
            i_no_status_check = abap_true
            i_no_editor       = abap_true
          IMPORTING
            e_subrc           = lv_subrc.

        CASE lv_subrc.
          WHEN 0.
            MESSAGE s205(yqmlims).
          WHEN 2.
            EXIT.
          WHEN OTHERS.
            EXIT.
        ENDCASE.
      ENDLOOP.

* Beurteilung erstellen
    WHEN 'BEUR'.

      is_selfield-refresh = 'X'.

      LOOP AT object_tab ASSIGNING <ls_object_tab>
           WHERE selected = g_x.

        <ls_object_tab>-viewed = sym_check_mark.

        MOVE-CORRESPONDING <ls_object_tab> TO ls_qals.
        MOVE-CORRESPONDING <ls_object_tab> TO ls_qave.

        CALL FUNCTION 'Y_QMLIMS_QFOA_CREATE_EVALUATIO'
          EXPORTING
            i_qals            = ls_qals
            i_qave            = ls_qave
            i_no_status_check = abap_true
          IMPORTING
            e_subrc           = lv_subrc.

        CASE lv_subrc.
          WHEN 0.
            MESSAGE s205(yqmlims).
          WHEN 2.
            EXIT.
          WHEN OTHERS.
            EXIT.
        ENDCASE.

        READ TABLE object_tab_all ASSIGNING <ls_object_tab_all>
             WITH KEY prueflos = <ls_object_tab>-prueflos.
        IF sy-subrc = 0.

          CALL FUNCTION 'STATUS_TEXT_EDIT'
            EXPORTING
              objnr            = <ls_object_tab_all>-objnr
              flg_user_stat    = g_x
              spras            = sy-langu
              bypass_buffer    = g_x
            IMPORTING
              line             = <ls_object_tab_all>-sttxt
              user_line        = <ls_object_tab_all>-ustxt
            EXCEPTIONS
              object_not_found = 1
              OTHERS           = 2.

          IF sy-subrc <> 0.
            CLEAR: <ls_object_tab_all>-sttxt,
                   <ls_object_tab_all>-ustxt.
          ENDIF.

          <ls_object_tab>-sttxt = <ls_object_tab_all>-sttxt.
          <ls_object_tab>-ustxt = <ls_object_tab_all>-ustxt.

        ELSE.
          CLEAR: <ls_object_tab>-sttxt,
                 <ls_object_tab>-ustxt.
        ENDIF.

      ENDLOOP.

* Gutachten erstellen
    WHEN 'GUTE'.

      is_selfield-refresh = 'X'.

      LOOP AT object_tab ASSIGNING <ls_object_tab>
           WHERE selected = g_x.

        <ls_object_tab>-viewed = sym_check_mark.

        MOVE-CORRESPONDING <ls_object_tab> TO ls_qals.
        MOVE-CORRESPONDING <ls_object_tab> TO ls_qave.

        CALL FUNCTION 'Y_QMLIMS_QFOA_PRINT_APPRAISAL'
          EXPORTING
            i_qals            = ls_qals
            i_qave            = ls_qave
            i_no_status_check = abap_true
          IMPORTING
            e_subrc           = lv_subrc.

        CASE lv_subrc.
          WHEN 0.
            MESSAGE s204(yqmlims).
          WHEN 2.
            MESSAGE i200(yqmlims).
            EXIT.
          WHEN 4.
            MESSAGE i201(yqmlims).
            EXIT.
          WHEN 8.
            MESSAGE i202(yqmlims).
            EXIT.
          WHEN OTHERS.
            MESSAGE i202(yqmlims).
            EXIT.
        ENDCASE.

        READ TABLE object_tab_all ASSIGNING <ls_object_tab_all>
             WITH KEY prueflos = <ls_object_tab>-prueflos.
        IF sy-subrc = 0.

          CALL FUNCTION 'STATUS_TEXT_EDIT'
            EXPORTING
              objnr            = <ls_object_tab_all>-objnr
              flg_user_stat    = g_x
              spras            = sy-langu
              bypass_buffer    = g_x
            IMPORTING
              line             = <ls_object_tab_all>-sttxt
              user_line        = <ls_object_tab_all>-ustxt
            EXCEPTIONS
              object_not_found = 1
              OTHERS           = 2.

          IF sy-subrc <> 0.
            CLEAR: <ls_object_tab_all>-sttxt,
                   <ls_object_tab_all>-ustxt.
          ENDIF.

          <ls_object_tab>-sttxt = <ls_object_tab_all>-sttxt.
          <ls_object_tab>-ustxt = <ls_object_tab_all>-ustxt.

        ELSE.
          CLEAR: <ls_object_tab>-sttxt,
                 <ls_object_tab>-ustxt.
        ENDIF.

      ENDLOOP.

    WHEN 'BEGU'.

      is_selfield-refresh = 'X'.

      LOOP AT object_tab ASSIGNING <ls_object_tab>
           WHERE selected = g_x.

        <ls_object_tab>-viewed = sym_check_mark.

        MOVE-CORRESPONDING <ls_object_tab> TO ls_qals.
        MOVE-CORRESPONDING <ls_object_tab> TO ls_qave.

        ls_object-objkey  = ls_qals-prueflos.
        ls_object-objtype = 'BUS2045'.

        CREATE OBJECT lo_attachment.

        lo_attachment->create_attachment(
          EXPORTING
            is_object     = ls_object
          IMPORTING
            ep_attachment = lv_attachment ).

        IF lv_attachment IS INITIAL.
          MESSAGE s042(sgos_msg).
        ELSE.
          MESSAGE s043(sgos_msg).

          CALL FUNCTION 'STATUS_TEXT_CONVERSION'
            EXPORTING
              language           = sy-langu
              mode               = 'E'
              objnr              = ls_qals-objnr
              txt04              = 'BEGU'
            IMPORTING
              status_number      = gv_stat_begu
            EXCEPTIONS
              insufficient_input = 1
              not_found          = 2
              object_not_found   = 3
              wrong_mode         = 4
              OTHERS             = 5.

          IF sy-subrc = 0.

            CALL FUNCTION 'STATUS_CHECK'
              EXPORTING
                objnr             = ls_qals-objnr
                status            = gv_stat_begu
              EXCEPTIONS
                object_not_found  = 1
                status_not_active = 2
                OTHERS            = 3.

            IF sy-subrc <> 0.
              CALL FUNCTION 'STATUS_CHANGE_EXTERN'
                EXPORTING
                  objnr               = ls_qals-objnr
                  user_status         = gv_stat_begu
                EXCEPTIONS
                  object_not_found    = 1
                  status_inconsistent = 2
                  status_not_allowed  = 3
                  OTHERS              = 4.

              IF sy-subrc <> 0.
                MESSAGE s203(yqmlims) WITH ls_qals-prueflos.
              ENDIF.
            ENDIF.

            COMMIT WORK.
          ENDIF.
        ENDIF.

        READ TABLE object_tab_all ASSIGNING <ls_object_tab_all>
             WITH KEY prueflos = <ls_object_tab>-prueflos.
        IF sy-subrc = 0.

          CALL FUNCTION 'STATUS_TEXT_EDIT'
            EXPORTING
              objnr            = <ls_object_tab_all>-objnr
              flg_user_stat    = g_x
              spras            = sy-langu
              bypass_buffer    = g_x
            IMPORTING
              line             = <ls_object_tab_all>-sttxt
              user_line        = <ls_object_tab_all>-ustxt
            EXCEPTIONS
              object_not_found = 1
              OTHERS           = 2.

          IF sy-subrc <> 0.
            CLEAR: <ls_object_tab_all>-sttxt,
                   <ls_object_tab_all>-ustxt.
          ENDIF.

          <ls_object_tab>-sttxt = <ls_object_tab_all>-sttxt.
          <ls_object_tab>-ustxt = <ls_object_tab_all>-ustxt.

        ELSE.
          CLEAR: <ls_object_tab>-sttxt,
                 <ls_object_tab>-ustxt.
        ENDIF.

      ENDLOOP.

    WHEN 'VEER'. " VE erfassen/ändern

      is_selfield-refresh = abap_true.

      "------------------------------------------------------------
      " 1) Selektierte Prüflosse sammeln
      "------------------------------------------------------------
      LOOP AT object_tab ASSIGNING <ls_object_tab>
           WHERE selected = g_x.
        INSERT <ls_object_tab>-prueflos INTO TABLE lt_selected_lots.
      ENDLOOP.

      "------------------------------------------------------------
      " 2) Initiale QALS-Daten nur einmal lesen
      "    (FOR ALL ENTRIES nur mit nicht-initialer Treibertabelle)
      "------------------------------------------------------------
      IF object_tab_all IS NOT INITIAL.

        SELECT prueflos, stat35
          FROM qals
          INTO TABLE @DATA(lt_stat35_db_init)
          FOR ALL ENTRIES IN @object_tab_all
          WHERE prueflos = @object_tab_all-prueflos.

        IF sy-subrc = 0.
          lt_stat35_init = CORRESPONDING #( lt_stat35_db_init ).
        ELSE.
          CLEAR lt_stat35_init.
        ENDIF.

      ENDIF.

      " Vorbelegung von object_tab_all-kz_qave aus dem Initial-Select
      LOOP AT object_tab_all ASSIGNING <ls_object_tab_all>.
        ASSIGN lt_stat35_init[ prueflos = <ls_object_tab_all>-prueflos ] TO <ls_stat35>.
        IF sy-subrc = 0.
          <ls_object_tab_all>-kz_qave = <ls_stat35>-stat35.
        ELSE.
          CLEAR <ls_object_tab_all>-kz_qave.
        ENDIF.
      ENDLOOP.

      "------------------------------------------------------------
      " 3) Verarbeitung ohne SELECT SINGLE in der Schleife
      "------------------------------------------------------------
      LOOP AT object_tab ASSIGNING <ls_object_tab>
           WHERE selected = g_x.

        SET PARAMETER ID 'QLS' FIELD <ls_object_tab>-prueflos.

        IF <ls_object_tab>-kz_qave IS INITIAL.
          MESSAGE i115(yqmlims) WITH <ls_object_tab>-prueflos.
          EXIT.
        ELSE.
          PERFORM call_transaction_f16 USING 'QA12'.
        ENDIF.

        " object_tab_all zur aktuellen Prüflosnummer lesen
        READ TABLE object_tab_all ASSIGNING <ls_object_tab_all>
             WITH KEY prueflos = <ls_object_tab>-prueflos.
        IF sy-subrc = 0.

          CALL FUNCTION 'STATUS_TEXT_EDIT'
            EXPORTING
              objnr            = <ls_object_tab_all>-objnr
              flg_user_stat    = g_x
              spras            = sy-langu
              bypass_buffer    = g_x
            IMPORTING
              line             = <ls_object_tab_all>-sttxt
              user_line        = <ls_object_tab_all>-ustxt
            EXCEPTIONS
              object_not_found = 1
              OTHERS           = 2.

          IF sy-subrc <> 0.
            CLEAR: <ls_object_tab_all>-sttxt,
                   <ls_object_tab_all>-ustxt.
          ENDIF.

          " Werte in die Anzeigetabelle übernehmen
          <ls_object_tab>-sttxt = <ls_object_tab_all>-sttxt.
          <ls_object_tab>-ustxt = <ls_object_tab_all>-ustxt.
        ENDIF.

      ENDLOOP.

      "------------------------------------------------------------
      " 4) QALS nach allen QA12-Aufrufen gesammelt neu lesen
      "    -> kein SELECT SINGLE in LOOP
      "------------------------------------------------------------
      IF lt_selected_lots IS NOT INITIAL.

        SELECT prueflos, stat35
          FROM qals
          INTO TABLE @DATA(lt_stat35_db_after)
          FOR ALL ENTRIES IN @lt_selected_lots
          WHERE prueflos = @lt_selected_lots-table_line.

        IF sy-subrc = 0.
          lt_stat35_after = CORRESPONDING #( lt_stat35_db_after ).
        ELSE.
          CLEAR lt_stat35_after.
        ENDIF.

        LOOP AT object_tab ASSIGNING <ls_object_tab>
             WHERE selected = g_x.

          ASSIGN lt_stat35_after[ prueflos = <ls_object_tab>-prueflos ] TO <ls_stat35>.
          IF sy-subrc = 0.
            <ls_object_tab>-kz_qave = <ls_stat35>-stat35.
          ELSE.
            CLEAR <ls_object_tab>-kz_qave.
          ENDIF.

        ENDLOOP.

        LOOP AT object_tab_all ASSIGNING <ls_object_tab_all>.

          ASSIGN lt_stat35_after[ prueflos = <ls_object_tab_all>-prueflos ] TO <ls_stat35>.
          IF sy-subrc = 0.
            <ls_object_tab_all>-kz_qave = <ls_stat35>-stat35.
          ELSE.
            CLEAR <ls_object_tab_all>-kz_qave.
          ENDIF.

        ENDLOOP.

      ENDIF.

      iv_ucomm = 'VEER'.


* Zusätzliche Berichtsempfänger pflegen
    WHEN 'PARTNER'.

      SELECT SINGLE pargr,
                    parvw,
                    parvw_vera,
                    service
        FROM t350
        INTO CORRESPONDING FIELDS OF @ls_t350
        WHERE auart = '5CSL'.

      IF sy-subrc <> 0.
        CLEAR ls_t350.
      ENDIF.

      LOOP AT object_tab ASSIGNING <ls_object_tab>
           WHERE selected = g_x.

        <ls_object_tab>-viewed = sym_check_mark.

        CALL FUNCTION 'CO_DB_HEADER_READ'
          EXPORTING
            aufnr     = <ls_object_tab>-aufnr
          IMPORTING
            caufvwa   = ls_caufv
          EXCEPTIONS
            not_found = 1
            OTHERS    = 2.
        IF sy-subrc <> 0.
          EXIT.
        ENDIF.

        MOVE-CORRESPONDING ls_caufv TO ls_caufvd.

        CALL FUNCTION 'CO_IH_SET_HEADER'
          EXPORTING
            caufvd_imp = ls_caufvd.

        CONCATENATE 'OR' <ls_object_tab>-aufnr INTO lv_objnr.

        CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
          EXPORTING
            input  = <ls_object_tab>-aufnr
          IMPORTING
            output = lv_ttext.

        CONCATENATE 'Auftrag' lv_ttext INTO lv_ttext SEPARATED BY space.

        CALL FUNCTION 'PM_PARTNER_INIT'
          EXPORTING
            tplnr        = <ls_object_tab>-yqm_tplnr
            aktyp        = 'V'
            objnr        = lv_objnr
            obtyp        = 'ORI'
            refresh      = abap_true
            pargr        = ls_t350-pargr
            parvw_kund   = ls_t350-parvw
            parvw_ap     = space
            parvw_lief   = space
            parvw_int    = space
            parvw_vera   = ls_t350-parvw_vera
            parvw_auto   = space
            service_flag = ls_t350-service.

        CALL FUNCTION 'PM_PARTNER_DIALOG'
          EXPORTING
            display_only       = 'V'
            tplnr              = <ls_object_tab>-yqm_tplnr
            objnr              = lv_objnr
            obtyp              = 'ORI'
            pargr              = 'QM'
            save               = abap_true
            trans_text         = lv_ttext
          EXCEPTIONS
            cancel             = 1
            exit               = 2
            save               = 3
            no_valid_subscreen = 4
            OTHERS             = 5.

        IF sy-subrc = 3.
          CALL FUNCTION 'PM_PARTNER_CALL_VB'
            EXPORTING
              objnr = lv_objnr.

          COMMIT WORK AND WAIT.
        ENDIF.

        is_selfield-refresh = abap_true.

      ENDLOOP.

* Ergebniserfassung, prozessoptimiert
*    WHEN 'TAMV'.
*      is_selfield-refresh    = g_s.    "rebuild list to set checkmark
*      is_selfield-row_stable = g_x. "stable scrolling
*      is_selfield-col_stable = g_x. "stable scrolling
*      CALL FUNCTION 'QEEA_INITIALIZE_LOT_BASETABS'.
*      CALL FUNCTION 'QET4_INITIALIZE'.
*      CALL FUNCTION 'Y_QMLIMS_QET5_RESET_SAVE_FLAG'.
*      CALL FUNCTION 'Y_QMLIMS_QET5_QAMV_COLLECT'
*        EXPORTING
*          i_reset = 'X'.
*
*      " Der Screenaufruf erfolgt vorgangsübergreifend
*      LOOP AT object_tab ASSIGNING <ls_object_tab>
*           WHERE selected = g_x.
*        <ls_object_tab>-viewed = sym_check_mark.
*        PERFORM put_samples_to_toolbox.
*      ENDLOOP.
*
*      " Cursor auf genau einem Eintrag -> Zugriff über Index
*      IF sy-subrc <> 0
*         AND is_selfield-tabindex IS NOT INITIAL.
*        READ TABLE object_tab ASSIGNING <ls_object_tab>
*             INDEX is_selfield-tabindex.
*        IF sy-subrc = 0.
**          object_tab_wa = <ls_object_tab>.
*          <ls_object_tab>-viewed = sym_check_mark.
*          PERFORM put_samples_to_toolbox.
*        ENDIF.
*      ENDIF.
*
*      PERFORM call_screen.

*     Prüflos
    WHEN 'PLOS'.

      LOOP AT object_tab ASSIGNING <ls_object_tab>
           WHERE selected = g_x.
        CALL FUNCTION 'STATUS_CHECK'
          EXPORTING
            bypass_buffer     = abap_true
            client            = sy-mandt
            objnr             = <ls_object_tab>-objnr
            status            = gc_stat_ve
          EXCEPTIONS
            object_not_found  = 1
            status_not_active = 2
            OTHERS            = 3.
        IF sy-subrc = 0.
*       Anzeige Prüflos
          SET PARAMETER ID 'QLS' FIELD <ls_object_tab>-prueflos.
          PERFORM call_transaction_f16 USING 'QA03'.
        ELSE.
*       Ändern Prüflos
          SET PARAMETER ID 'QLS' FIELD <ls_object_tab>-prueflos.
          PERFORM call_transaction_f16 USING 'QA02'.
        ENDIF.
      ENDLOOP.

      " Cursor auf genau einem Eintrag -> Zugriff über Index
      IF sy-subrc <> 0
         AND is_selfield-tabindex IS NOT INITIAL.
        READ TABLE object_tab ASSIGNING <ls_object_tab>
             INDEX is_selfield-tabindex.
        IF sy-subrc = 0.
          CALL FUNCTION 'STATUS_CHECK'
            EXPORTING
              bypass_buffer     = abap_true
              client            = sy-mandt
              objnr             = <ls_object_tab>-objnr
              status            = gc_stat_ve
            EXCEPTIONS
              object_not_found  = 1
              status_not_active = 2
              OTHERS            = 3.
          IF sy-subrc = 0.
*       Anzeige Prüflos
            SET PARAMETER ID 'QLS' FIELD <ls_object_tab>-prueflos.
            PERFORM call_transaction_f16 USING 'QA03'.
          ELSE.
*       Ändern Prüflos
            SET PARAMETER ID 'QLS' FIELD <ls_object_tab>-prueflos.
            PERFORM call_transaction_f16 USING 'QA02'.
          ENDIF.
        ENDIF.
      ENDIF.

    WHEN OTHERS.    " codes that require reading items from the list
* Codes are : QAMV VEAZ QMEL (display or change)
*             PRLS PRZG (print inspection report and certificate)
      PERFORM user_command_f16 USING iv_ucomm is_selfield.

  ENDCASE.

ENDFORM.                               "USER_COMMAND_L
*&---------------------------------------------------------------------*
*&      Form  SET_PF_STATUS_L               called dynamically
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM set_pf_stat_l USING et_extab TYPE slis_t_extab.

  IF sy-tcode = 'OQI4'.
    " Customizing abklemmen
    SET PF-STATUS 'CUST' OF PROGRAM 'RQEVAM10' EXCLUDING et_extab.
    RETURN.
  ENDIF.

  " Tcode aus Parameterübergabe sichern
  IF gv_tcode IS INITIAL.
    IF dy_tcode IS INITIAL.
      gv_tcode = sy-tcode.
    ELSE.
      gv_tcode = dy_tcode.
    ENDIF.
  ENDIF.
  dy_tcode = gv_tcode.

  IF sy-tcode <> 'SE38' AND sy-tcode <> 'SA38'.

    SELECT SINGLE ttext
      FROM tstct
      INTO @tstct-ttext
      WHERE sprsl = @sy-langu
        AND tcode = @t370a-tcode.

    IF sy-subrc <> 0.
      CLEAR tstct-ttext.
    ENDIF.

  ELSE.
    tstct-ttext = sy-title.
  ENDIF.

  CASE gv_view_type.
    WHEN 'AVEM'.
      SET TITLEBAR 'MAIN_AVEM'.
      APPEND 'BEUR' TO et_extab.
      APPEND 'VEER' TO et_extab.
      APPEND 'VEAZ' TO et_extab.
      APPEND 'PRLS' TO et_extab.

    WHEN 'KAVE'.
      SET TITLEBAR 'MAIN_KAVE'.
*        APPEND 'VE_AUTO' TO et_extab.
    WHEN OTHERS.
      SET TITLEBAR 'LVS' WITH tstct-ttext.
  ENDCASE.

  g_aktyp = t370a-aktyp.
  IF g_aktyp IS INITIAL.
    g_aktyp = 'V'.
  ENDIF.

  " Zeugnis
  CALL FUNCTION 'QAUT_CHECK_TCODE'
    EXPORTING
      i_tcode          = 'QC21'
    EXCEPTIONS
      auth_destroyed   = 1
      internal_error   = 2
      no_authorization = 3
      OTHERS           = 4.
  IF sy-subrc <> 0.
    APPEND 'PRZG' TO et_extab.
  ENDIF.

  " Prüfbericht
  CALL FUNCTION 'QAUT_CHECK_TCODE'
    EXPORTING
      i_tcode          = 'QGA3'
    EXCEPTIONS
      auth_destroyed   = 1
      internal_error   = 2
      no_authorization = 3
      OTHERS           = 4.
  IF sy-subrc <> 0.
    APPEND 'PRLS' TO et_extab.
  ENDIF.

  IF g_aktyp = 'V'.

    " Prüflos
    CALL FUNCTION 'QAUT_CHECK_TCODE'
      EXPORTING
        i_tcode          = 'QA02'
      EXCEPTIONS
        auth_destroyed   = 1
        internal_error   = 2
        no_authorization = 3
        OTHERS           = 4.
    IF sy-subrc <> 0.
      APPEND 'PLOS' TO et_extab.
    ENDIF.

    " Verwendungsentscheid
    CALL FUNCTION 'QAUT_CHECK_TCODE'
      EXPORTING
        i_tcode          = 'QA11'
      EXCEPTIONS
        auth_destroyed   = 1
        internal_error   = 2
        no_authorization = 3
        OTHERS           = 4.
    IF sy-subrc <> 0.
      CALL FUNCTION 'QAUT_CHECK_TCODE'
        EXPORTING
          i_tcode          = 'QA12'
        EXCEPTIONS
          auth_destroyed   = 1
          internal_error   = 2
          no_authorization = 3
          OTHERS           = 4.
      IF sy-subrc <> 0.
        APPEND 'VEAZ' TO et_extab.
      ENDIF.
    ENDIF.

    " Ergebnisse
    CALL FUNCTION 'QAUT_CHECK_TCODE'
      EXPORTING
        i_tcode          = 'QE01'
      EXCEPTIONS
        auth_destroyed   = 1
        internal_error   = 2
        no_authorization = 3
        OTHERS           = 4.
    IF sy-subrc <> 0.
      CALL FUNCTION 'QAUT_CHECK_TCODE'
        EXPORTING
          i_tcode          = 'QE11'
        EXCEPTIONS
          auth_destroyed   = 1
          internal_error   = 2
          no_authorization = 3
          OTHERS           = 4.
      IF sy-subrc <> 0.
        CALL FUNCTION 'QAUT_CHECK_TCODE'
          EXPORTING
            i_tcode          = 'QE14'
          EXCEPTIONS
            auth_destroyed   = 1
            internal_error   = 2
            no_authorization = 3
            OTHERS           = 4.
        IF sy-subrc <> 0.
          APPEND 'QAMV' TO et_extab.
        ENDIF.
      ENDIF.
    ENDIF.

    " Fehler
    CALL FUNCTION 'QAUT_CHECK_TCODE'
      EXPORTING
        i_tcode          = 'QF01'
      EXCEPTIONS
        auth_destroyed   = 1
        internal_error   = 2
        no_authorization = 3
        OTHERS           = 4.
    IF sy-subrc <> 0.
      CALL FUNCTION 'QAUT_CHECK_TCODE'
        EXPORTING
          i_tcode          = 'QF02'
        EXCEPTIONS
          auth_destroyed   = 1
          internal_error   = 2
          no_authorization = 3
          OTHERS           = 4.
      IF sy-subrc <> 0.
        APPEND 'QMEL' TO et_extab.
      ENDIF.
    ENDIF.

    SET PF-STATUS 'CHANGE' EXCLUDING et_extab.

  ELSE.

    " Prüflos
    CALL FUNCTION 'QAUT_CHECK_TCODE'
      EXPORTING
        i_tcode          = 'QA03'
      EXCEPTIONS
        auth_destroyed   = 1
        internal_error   = 2
        no_authorization = 3
        OTHERS           = 4.
    IF sy-subrc <> 0.
      APPEND 'PLOS' TO et_extab.
    ENDIF.

    " Verwendungsentscheid
    CALL FUNCTION 'QAUT_CHECK_TCODE'
      EXPORTING
        i_tcode          = 'QA13'
      EXCEPTIONS
        auth_destroyed   = 1
        internal_error   = 2
        no_authorization = 3
        OTHERS           = 4.
    IF sy-subrc <> 0.
      APPEND 'VEAZ' TO et_extab.
    ENDIF.

    " Ergebnisse
    CALL FUNCTION 'QAUT_CHECK_TCODE'
      EXPORTING
        i_tcode          = 'QE03'
      EXCEPTIONS
        auth_destroyed   = 1
        internal_error   = 2
        no_authorization = 3
        OTHERS           = 4.
    IF sy-subrc <> 0.
      APPEND 'QAMV' TO et_extab.
    ENDIF.

    " Fehler
    CALL FUNCTION 'QAUT_CHECK_TCODE'
      EXPORTING
        i_tcode          = 'QF03'
      EXCEPTIONS
        auth_destroyed   = 1
        internal_error   = 2
        no_authorization = 3
        OTHERS           = 4.
    IF sy-subrc <> 0.
      APPEND 'QMEL' TO et_extab.
    ENDIF.

    SET PF-STATUS 'MAIN' EXCLUDING et_extab.

  ENDIF.

ENDFORM.

*---------------------------------------------------------------------*
*       FORM CHANGE_AKTYP_l                                       *
*---------------------------------------------------------------------*
*       Aktivitätstyp ändern                                          *
*---------------------------------------------------------------------*
FORM change_aktyp_l.

  DATA:
    lv_tabarg  TYPE t370a-tabarg,
    lv_program TYPE t370a-programm,
    lv_retc    TYPE sy-subrc,
    lv_tcode   TYPE t370a-tcode.

  IF t370a-tcode IS INITIAL.
    RETURN.
  ENDIF.

  lv_tabarg  = t370a-tabarg.
  lv_program = t370a-programm.
  lv_tcode   = t370a-tcode.

  IF g_aktyp = 'A'.
    SELECT SINGLE tcode,
                  programm,
                  tabarg,
                  aktyp
      FROM t370a
      INTO CORRESPONDING FIELDS OF @t370a
      WHERE programm = @lv_program
        AND tabarg   = @lv_tabarg
        AND aktyp   <> @g_aktyp.                        "#EC CI_GENBUFF

    IF sy-subrc <> 0.
      CLEAR t370a.
    ENDIF.
  ELSE.
    SELECT SINGLE tcode,
                  programm,
                  tabarg,
                  aktyp
      FROM t370a
      INTO CORRESPONDING FIELDS OF @t370a
      WHERE tcode   = @sy-tcode
        AND tabarg  = @lv_tabarg
        AND aktyp  <> @g_aktyp.

    IF sy-subrc <> 0.
      SELECT SINGLE tcode,
                    programm,
                    tabarg,
                    aktyp
        FROM t370a
        INTO CORRESPONDING FIELDS OF @t370a
        WHERE programm = @lv_program
          AND tabarg   = @lv_tabarg
          AND aktyp   <> @g_aktyp.                      "#EC CI_GENBUFF

      IF sy-subrc <> 0.
        CLEAR t370a.
      ENDIF.
    ENDIF.
  ENDIF.

  CLEAR lv_retc.

  IF lv_tcode CP 'Q*'.
    AUTHORITY-CHECK OBJECT 'Q_TCODE'
      ID 'TCD' FIELD t370a-tcode.
    lv_retc = sy-subrc.
  ENDIF.

  IF lv_retc = 0.
    IF g_aktyp = 'A'.
      g_aktyp = 'V'.
    ELSE.
      g_aktyp = 'A'.
    ENDIF.
    SELECT SINGLE ttext
      FROM tstct
      INTO @tstct-ttext
      WHERE sprsl = @sy-langu
        AND tcode = @t370a-tcode.

    IF sy-subrc <> 0.
      CLEAR tstct-ttext.
    ENDIF.

    PERFORM set_pf_stat_l USING gt_extab.

  ELSE.
    SELECT SINGLE tcode,
                  programm,
                  tabarg,
                  aktyp
      FROM t370a
      INTO CORRESPONDING FIELDS OF @t370a
      WHERE tcode = @lv_tcode.

    IF sy-subrc <> 0.
      CLEAR t370a.
    ENDIF.
  ENDIF.

ENDFORM.

*---------------------------------------------------------------------*
*       FORM CREATE_FIELDCAT_L                                        *
*---------------------------------------------------------------------*
*       create g_fieldcat_tab for DDIC structure                      *
*---------------------------------------------------------------------*
*  -->  TABNAME  (DDIC-Structure for Report-Output)                   *
*---------------------------------------------------------------------*
FORM create_fieldcat_l
  USING iv_tabname TYPE slis_tabname.

  DATA:
    ls_fieldcat TYPE slis_fieldcat_alv,
    lv_index    TYPE sy-tabix.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      i_program_name         = g_repid
      i_internal_tabname     = 'OBJECT_TAB'
      i_structure_name       = iv_tabname
      i_client_never_display = space
    CHANGING
      ct_fieldcat            = g_fieldcat_tab[]
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.

  IF sy-subrc = 0.

    SORT g_fieldcat_tab BY key DESCENDING.

    lv_index = 1.
    DO.
      " Key-Felder zu normalen Feldern umwandeln
      READ TABLE g_fieldcat_tab INTO ls_fieldcat INDEX lv_index.
      IF sy-subrc = 0 AND ls_fieldcat-key = g_x.
        ls_fieldcat-key = space.
        MODIFY g_fieldcat_tab FROM ls_fieldcat INDEX lv_index.
        lv_index = lv_index + 1.
      ELSE.
        EXIT.
      ENDIF.
    ENDDO.

    " Spalte VIEWED ergänzen
    PERFORM add_viewed_column_f14.

    LOOP AT g_fieldcat_tab ASSIGNING FIELD-SYMBOL(<ls_fieldcat>).

      CASE <ls_fieldcat>-fieldname.

        WHEN 'VIEWED'.
          <ls_fieldcat>-seltext_l = TEXT-vd1.
          <ls_fieldcat>-seltext_s = TEXT-vd2.
          <ls_fieldcat>-ddictxt   = 'S'.

        WHEN 'EMATNR'.
          <ls_fieldcat>-seltext_l = TEXT-fd1.

        WHEN 'MATNRNEU'.
          <ls_fieldcat>-seltext_l = TEXT-fd2.

        WHEN 'SELMATNR'.
          <ls_fieldcat>-seltext_l = TEXT-fd3.

        WHEN 'CHARGNEU'.
          <ls_fieldcat>-seltext_l = TEXT-fd4.

        WHEN 'SELKUNNR'.
          <ls_fieldcat>-seltext_l = TEXT-fd5.

        WHEN 'SELHERST'.
          <ls_fieldcat>-seltext_l = TEXT-fd6.

        WHEN 'SELLIFNR'.
          <ls_fieldcat>-seltext_l = TEXT-fd7.

        WHEN 'SELREVLV'.
          <ls_fieldcat>-seltext_l = TEXT-fd9.

        WHEN 'SELPPLVERW'.
          <ls_fieldcat>-seltext_l = TEXT-fd8.

        WHEN 'SELWERK'.
          <ls_fieldcat>-seltext_l = TEXT-fd0.

        WHEN 'ZEILE'.
          <ls_fieldcat>-seltext_l = TEXT-fe1.

        WHEN 'EBELP'.
          <ls_fieldcat>-seltext_l = TEXT-fe2.

        WHEN 'LS_POSNR'.
          <ls_fieldcat>-seltext_l = TEXT-fe3.

        WHEN 'LS_KDAUF'.
          <ls_fieldcat>-seltext_l = TEXT-fe4.

        WHEN 'LS_KDPOS'.
          <ls_fieldcat>-seltext_l = TEXT-fe5.

        WHEN 'OFFENNLZMK'.
          <ls_fieldcat>-seltext_l = TEXT-002.

        WHEN 'OFFEN_LZMK'.
          <ls_fieldcat>-seltext_l = TEXT-003.

        WHEN 'LOSMENGE'.
          <ls_fieldcat>-seltext_l = TEXT-004.

          " 1S4HC - Feld User-Status nur in Cloud ausblenden
        WHEN 'USTXT'.
          IF cl_qall_switch_check=>qm_sfws_ui_qall( ) IS INITIAL.
            <ls_fieldcat>-tech = abap_true.
          ENDIF.

          " 1S4HC - Feld Statusschema nur in Cloud ausblenden
        WHEN 'STSMA'.
          IF cl_qall_switch_check=>qm_sfws_ui_qall( ) IS INITIAL.
            <ls_fieldcat>-tech = abap_true.
          ENDIF.

      ENDCASE.

    ENDLOOP.
  ENDIF.

  " Der Fieldcat wird hier ins Memory exportiert, weil dieses FORM
  " auch in anderen Reports verwendet wird, um doppelte Textpflege zu vermeiden.
  IF g_repid <> sy-repid.
    EXPORT g_fieldcat_tab = g_fieldcat_tab TO MEMORY ID 'FIELDCATALOG'.
  ENDIF.

ENDFORM.
*--------------------------------------------------------------------*
* And finally, the INCLUDES....                                      *
*--------------------------------------------------------------------*
INCLUDE rqalvf14.        " Central include for ALV functions
INCLUDE rqalvf16.        " Central include for OBJECT_TAB functions
INCLUDE rq00mf10.        " Include for controlling the entry screen
* THAT'S ALL FOLKS !!!!!
*---------------------------------------------------------------------*
*       FORM TOP_OF_PAGE_L                                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM top_of_page_l.

*--- Display header lines above list display -------------------------
  IF NOT g_listheader_tab[] IS INITIAL.
    CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
      EXPORTING
        it_list_commentary = g_listheader_tab.
  ENDIF.

ENDFORM.                    "top_of_page_l
*&---------------------------------------------------------------------*
*&      Form  SELECT_FIELDS_MANIP_L
*&---------------------------------------------------------------------*
*       Fields to be output are determined, and then read
*----------------------------------------------------------------------*
*       Used in QA32 for structure QALS_D02                            *
*----------------------------------------------------------------------*
FORM select_fields_manip_l
  USING it_fieldcat TYPE slis_t_fieldcat_alv.

  DATA:
    ls_fieldcat   TYPE slis_fieldcat_alv,
    ls_table_qals TYPE rsfs_tab_fields,
    lv_tabix_qals TYPE sy-tabix,
    ls_table_qave TYPE rsfs_tab_fields,
    lv_tabix_qave TYPE sy-tabix.

  READ TABLE select_fields INTO ls_table_qals
       WITH KEY tablename = 'QALS'.
  lv_tabix_qals = sy-tabix.

  IF g_repid CS 'RQEEAL10'.
    READ TABLE select_fields INTO ls_table_qave
         WITH KEY tablename = 'QAVP'.
  ELSE.
    READ TABLE select_fields INTO ls_table_qave
         WITH KEY tablename = 'QAVE'.
  ENDIF.

  lv_tabix_qave = sy-tabix.

  " Zu selektierende Felder festlegen
  " nur Felder die angezeigt werden
  LOOP AT it_fieldcat INTO ls_fieldcat
       WHERE no_out = space.

    " Auswerten der Felder
    IF    ls_fieldcat-fieldname = 'LIGHTS'
       OR ls_fieldcat-fieldname = 'VIEWED'
       OR ls_fieldcat-fieldname = 'STTXT'
       OR ls_fieldcat-fieldname = 'USTXT'
       OR ls_fieldcat-fieldname = 'VORNR'
       OR ls_fieldcat-fieldname = 'VORGLFNR'
       OR ls_fieldcat-fieldname = 'VORKTXT'
       OR ls_fieldcat-fieldname = 'PRPLATZ'
       OR ls_fieldcat-fieldname = 'PRPLATZWRK'
       OR ls_fieldcat-fieldname = 'PRPLATZTXT'.

      " nichts zu tun

    ELSEIF ls_fieldcat-fieldname = 'QKENNZAHL'
        OR ls_fieldcat-fieldname = 'VBEWERTUNG'
        OR ls_fieldcat-fieldname = 'KZART'
        OR ls_fieldcat-fieldname = 'VKATART'
        OR ls_fieldcat-fieldname = 'VAUSWAHLMG'
        OR ls_fieldcat-fieldname = 'VCODEGRP'
        OR ls_fieldcat-fieldname = 'VCODE'
        OR ls_fieldcat-fieldname = 'DBEWERTUNG'
        OR ls_fieldcat-fieldname = 'VAENAME'
        OR ls_fieldcat-fieldname = 'VNAME'
        OR ls_fieldcat-fieldname = 'VDATUM'
        OR ls_fieldcat-fieldname = 'VEZEITERF'
        OR ls_fieldcat-fieldname = 'VEZEITAEN'
        OR ls_fieldcat-fieldname = 'VFOLGEAKTI'
        OR ls_fieldcat-fieldname = '/CWM/LOSMENGE'
        OR ls_fieldcat-fieldname = '/CWM/MENGEINH2Q'
        OR ls_fieldcat-fieldname = 'VAEDATUM'.

      " above fields are not contained in QALS - therefore they cannot be read
      " indicator for UD
      g_qave_flag = g_x.

      READ TABLE ls_table_qave-fields
           WITH KEY line = ls_fieldcat-fieldname
           BINARY SEARCH
           TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        " Feld noch nicht in Tabelle
        INSERT ls_fieldcat-fieldname
          INTO ls_table_qave-fields INDEX sy-tabix.
      ENDIF.

    ELSE.

      READ TABLE ls_table_qals-fields
           WITH KEY line = ls_fieldcat-fieldname
           BINARY SEARCH
           TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        " Feld noch nicht in Tabelle
        INSERT ls_fieldcat-fieldname
          INTO ls_table_qals-fields INDEX sy-tabix.
      ENDIF.

    ENDIF.
  ENDLOOP.

  MODIFY select_fields FROM ls_table_qave INDEX lv_tabix_qave.
  MODIFY select_fields FROM ls_table_qals INDEX lv_tabix_qals.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  CODE_AUSWAHL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM code_auswahl .

  DATA ls_qpk1ac TYPE qpk1ac.

  IF p_ausmg IS INITIAL.
    p_ausmg = gv_stern.
  ENDIF.

  IF p_vwerk IS INITIAL.
    p_vwerk = gv_stern.
  ENDIF.

  IF p_cdgrp IS INITIAL.
    p_cdgrp = gv_stern.
  ENDIF.

  IF p_code IS INITIAL.
    p_code = gv_stern.
  ENDIF.

  CALL FUNCTION 'QPK1_UD_CODE_PICKUP_LEAN'
    EXPORTING
      i_werks              = p_vwerk
      i_auswahlmge         = p_ausmg
      i_codegruppe         = p_cdgrp
      i_code               = p_code
      i_no_usageindication = abap_true
    IMPORTING
      e_qpk1ac             = ls_qpk1ac
    EXCEPTIONS
      OTHERS               = 1.

  IF sy-subrc <> 0.
    " Fehlermeldung wurde ausgelöst -> als I-Meldung ausgeben
    MESSAGE ID sy-msgid TYPE 'I' NUMBER sy-msgno
      WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    RETURN.
  ENDIF.

  p_vwerk = ls_qpk1ac-werks.
  p_ausmg = ls_qpk1ac-auswahlmge.
  p_cdgrp = ls_qpk1ac-codegruppe.
  p_code  = ls_qpk1ac-code.

ENDFORM.                    " CODE_AUSWAHL
*&---------------------------------------------------------------------*
*&      Form  CHECK_STATUS_SETTINGS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM check_status_settings .

* Statusschema fuer Prueflosherkunft 14 ermitteln
  SELECT SINGLE * FROM tq30
    INTO gs_tq30
    WHERE art EQ gc_pruefart.
  IF sy-subrc NE 0.                    "kein Eintrag gefunden'
    MESSAGE a005 WITH gc_pruefart.
  ENDIF.
  IF gs_tq30-stsma IS INITIAL.            "kein Statusschema zugeordnet
    MESSAGE a006 WITH gc_pruefart.
  ENDIF.
* Interne Nummern der Anwenderstatus ermitteln
* zuerst fuer Anwenderstatus ERGM
  CALL FUNCTION 'STATUS_TEXT_CONVERSION'
    EXPORTING
      language           = sy-langu
      mode               = 'E'  "Anwenderstatus
      stsma              = gs_tq30-stsma
      txt04              = gc_ergm
    IMPORTING
      status_number      = gv_stat_ergm
    EXCEPTIONS
      insufficient_input = 1
      not_found          = 2
      object_not_found   = 3
      wrong_mode         = 4
      OTHERS             = 5.
  IF sy-subrc NE 0.
    MESSAGE a007 WITH gc_avem gs_tq30-stsma.
  ENDIF.

* dann fuer Anwenderstatus AVEM
  CALL FUNCTION 'STATUS_TEXT_CONVERSION'
    EXPORTING
      language           = sy-langu
      mode               = 'E'  "Anwenderstatus
      stsma              = gs_tq30-stsma
      txt04              = gc_avem
    IMPORTING
      status_number      = gv_stat_avem
    EXCEPTIONS
      insufficient_input = 1
      not_found          = 2
      object_not_found   = 3
      wrong_mode         = 4
      OTHERS             = 5.
  IF sy-subrc NE 0.
    MESSAGE a007 WITH gc_avem gs_tq30-stsma.
  ENDIF.
* dann fuer Anwenderstatus KAVE
  CALL FUNCTION 'STATUS_TEXT_CONVERSION'
    EXPORTING
      language           = sy-langu
      mode               = 'E'  "Anwenderstatus
      stsma              = gs_tq30-stsma
      txt04              = gc_kave
    IMPORTING
      status_number      = gv_stat_kave
    EXCEPTIONS
      insufficient_input = 1
      not_found          = 2
      object_not_found   = 3
      wrong_mode         = 4
      OTHERS             = 5.
  IF sy-subrc NE 0.
    MESSAGE a007 WITH gc_kave gs_tq30-stsma.
  ENDIF.
* und fuer Anwenderstatus GUTE
  CALL FUNCTION 'STATUS_TEXT_CONVERSION'
    EXPORTING
      language           = sy-langu
      mode               = 'E'  "Anwenderstatus
      stsma              = gs_tq30-stsma
      txt04              = gc_gute
    IMPORTING
      status_number      = gv_stat_gute
    EXCEPTIONS
      insufficient_input = 1
      not_found          = 2
      object_not_found   = 3
      wrong_mode         = 4
      OTHERS             = 5.
  IF sy-subrc NE 0.
    MESSAGE a007 WITH gc_gute gs_tq30-stsma.
  ENDIF.

ENDFORM.                    " CHECK_STATUS_SETTINGS
*&---------------------------------------------------------------------*
*&      Form  REFRESH_OBJECT_LIST
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_gv_view_type  text
*----------------------------------------------------------------------*
FORM refresh_object_list.

  FIELD-SYMBOLS <ls_object_tab_all> LIKE LINE OF object_tab_all.

  CLEAR object_tab.
  CLEAR object_tab[].

  LOOP AT object_tab_all ASSIGNING <ls_object_tab_all>.

    CALL FUNCTION 'STATUS_CHECK'
      EXPORTING
        bypass_buffer     = g_x
        client            = sy-mandt
        objnr             = <ls_object_tab_all>-objnr
        status            = gc_stat_ve
      EXCEPTIONS
        object_not_found  = 1
        status_not_active = 2
        OTHERS            = 3.

    IF ( p_no_ud = g_x OR p_no_uda = g_x ) AND sy-subrc = 0.
      CONTINUE.
    ENDIF.

    IF p_ud = g_x AND sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    MOVE-CORRESPONDING <ls_object_tab_all> TO object_tab.
    APPEND object_tab TO object_tab.

  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  ADD_MESSAGE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM add_message .

  gv_display_log = 'X'.

* Nachricht erstellen:
  CLEAR gs_msg.
  gs_msg-msgty     = sy-msgty.
  gs_msg-msgid     = sy-msgid.
  gs_msg-msgno     = sy-msgno.
  gs_msg-msgv1     = sy-msgv1.
  gs_msg-msgv2     = sy-msgv2.
  gs_msg-msgv3     = sy-msgv3.
  gs_msg-msgv4     = sy-msgv4.
*  gs_msg-probclass = i_probclass.

* Diese Nachricht zum LOG hinzufügen:
  CALL FUNCTION 'BAL_LOG_MSG_ADD'
    EXPORTING
      i_log_handle  = gv_log_handle
      i_s_msg       = gs_msg
    EXCEPTIONS
      log_not_found = 0
      OTHERS        = 1.

ENDFORM.                    " ADD_MESSAGE
*&---------------------------------------------------------------------*
*&      Form  DISPLAY_LOG
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM display_log .

* get a prepared profile
  CALL FUNCTION 'BAL_DSP_PROFILE_SINGLE_LOG_GET'
    IMPORTING
      e_s_display_profile = gs_display_profile
    EXCEPTIONS
      OTHERS              = 1.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
             WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

* use grid for display if wanted
  gs_display_profile-use_grid = 'X'.
  gs_display_profile-not_empty = 'X'.

  gs_display_profile-start_col = 1.
  gs_display_profile-start_row = 1.
  gs_display_profile-end_col   = 100.
  gs_display_profile-end_row   = 25.


* set report to allow saving of variants
  gs_display_profile-disvariant-report = sy-repid.

* call display function module
* We do not specify any filter (type I_S_LOG_FILTER, ...,
* I_T_MSG_HANDLE) since we want to display all logs available
  CALL FUNCTION 'BAL_DSP_LOG_DISPLAY'
    EXPORTING
      i_s_display_profile = gs_display_profile
      i_amodal            = 'X'
    EXCEPTIONS
      OTHERS              = 1.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
             WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

ENDFORM.                    " DISPLAY_LOG
*&---------------------------------------------------------------------*
*&      Form  PROCESS_UD
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_OBJECT_TAB_ALL_PRUEFLOS  text
*----------------------------------------------------------------------*
FORM process_ud USING is_object_tab LIKE object_tab_all.

  DATA:
    lv_mode        TYPE bdc_struc-bdcmode VALUE 'N',
    lv_preview_pdf TYPE qkz,
    lv_process_ud  TYPE abap_bool,
    lv_estat_pbio  TYPE j_status.

  CLEAR lv_process_ud.

  " Durch Drücken des Buttons Auto VE in Verbindung mit dem
  " Prüflosstatus AVEM wird die Anzeige des PDF unterdrückt
  CASE gv_view_type.
    WHEN 'AVEM'.
      IF is_object_tab-ustxt CS 'AVEM'.
        CLEAR lv_preview_pdf.
      ELSE.
        lv_preview_pdf = abap_true.
      ENDIF.
    WHEN OTHERS.
      lv_preview_pdf = abap_true.
  ENDCASE.

  IF lv_preview_pdf IS INITIAL.
    lv_process_ud = abap_true.
  ELSE.

    PERFORM preview_pdf USING    is_object_tab-prueflos
*                                 object_tab-werk
                                 abap_true
                        CHANGING gv_okcode.

    IF gv_okcode = 'CANC'.
      RETURN.
    ENDIF.

    IF lv_estat_pbio IS INITIAL.
      CALL FUNCTION 'STATUS_TEXT_CONVERSION'
        EXPORTING
          language           = sy-langu
          mode               = 'E'
          objnr              = is_object_tab-objnr
          txt04              = 'PBIO'
        IMPORTING
          status_number      = lv_estat_pbio
        EXCEPTIONS
          insufficient_input = 1
          not_found          = 2
          object_not_found   = 3
          wrong_mode         = 4
          OTHERS             = 5.
      IF sy-subrc <> 0.
        CLEAR lv_estat_pbio.
      ENDIF.
    ENDIF.

    IF lv_estat_pbio IS NOT INITIAL.
      CALL FUNCTION 'STATUS_CHECK'
        EXPORTING
          bypass_buffer     = abap_true
          objnr             = is_object_tab-objnr
          status            = lv_estat_pbio
        EXCEPTIONS
          object_not_found  = 1
          status_not_active = 2
          OTHERS            = 3.
      IF sy-subrc <> 0.
        " Vor dem Treffen des VE muss der Prüfbericht angenommen werden
        MESSAGE s308(yqmlims) WITH is_object_tab-prueflos
                                   INTO gv_dummy.
      ELSE.
        lv_process_ud = abap_true.
      ENDIF.
    ENDIF.
  ENDIF.

  IF lv_process_ud = abap_true.

    CALL FUNCTION 'QAVE_PROCESS_AUTO_UD'
      EXPORTING
        i_lot                = is_object_tab-prueflos
        i_selected_set       = p_ausmg
        i_plant_selected_set = p_vwerk
        i_ud_code            = p_code
        i_ud_codegroup       = p_cdgrp
        i_text_line          = TEXT-j00
        i_stock_posting      = space
        i_process_mode       = lv_mode
        i_origin_ud          = 'B'
      EXCEPTIONS
        error_occured        = 1
        not_posted           = 1
        foreign_lock         = 2
        lock_error           = 2
        no_authority         = 3
        OTHERS               = 6.

    CASE sy-subrc.
      WHEN 0.
        MESSAGE s304(yqmlims) WITH is_object_tab-prueflos
                                   INTO gv_dummy.
        PERFORM add_message.

      WHEN 1.
        IF sy-msgid = '00'
           AND sy-msgno = '344'.

          " Langtext kann im Batchmodus nicht erfasst werden
          lv_mode = 'E'.

          CALL FUNCTION 'QAVE_PROCESS_AUTO_UD'
            EXPORTING
              i_lot                = is_object_tab-prueflos
              i_selected_set       = p_ausmg
              i_plant_selected_set = p_vwerk
              i_ud_code            = p_code
              i_ud_codegroup       = p_cdgrp
              i_text_line          = TEXT-j00
              i_stock_posting      = space
              i_process_mode       = lv_mode
              i_origin_ud          = 'B'
            EXCEPTIONS
              error_occured        = 1
              not_posted           = 1
              foreign_lock         = 2
              lock_error           = 2
              no_authority         = 3
              OTHERS               = 6.
          CASE sy-subrc.
            WHEN 0.
              MESSAGE s304(yqmlims) WITH is_object_tab-prueflos
                                         INTO gv_dummy.
              PERFORM add_message.
            WHEN OTHERS.
              MESSAGE e305(yqmlims) WITH is_object_tab-prueflos
                                         INTO gv_dummy.
              PERFORM add_message.
          ENDCASE.

        ELSE.

          IF sy-msgid IS NOT INITIAL.
            MESSAGE ID sy-msgid
                    TYPE 'E'
                    NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
                    INTO gv_dummy.
            PERFORM add_message.
          ENDIF.
          MESSAGE e304(yqmlims) WITH is_object_tab-prueflos
                                     INTO gv_dummy.
          PERFORM add_message.
        ENDIF.

      WHEN 2.
        MESSAGE e306(yqmlims) WITH is_object_tab-prueflos
                                   INTO gv_dummy.
        PERFORM add_message.

      WHEN 3.
        MESSAGE e310(yqmlims) WITH is_object_tab-prueflos
                                   INTO gv_dummy.
        PERFORM add_message.

      WHEN OTHERS.
        MESSAGE e305(yqmlims) WITH is_object_tab-prueflos
                                   INTO gv_dummy.
        PERFORM add_message.
    ENDCASE.

  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  SAVE_LOG
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM save_log .

  CALL FUNCTION 'BAL_DB_SAVE'
    EXPORTING
      i_save_all       = 'X'
      i_t_log_handle   = gt_log_handle
    EXCEPTIONS
      log_not_found    = 1
      save_not_allowed = 2
      numbering_error  = 3
      OTHERS           = 4.
  IF sy-subrc = 0.
    MESSAGE w002(yqmlims) INTO gv_dummy.
    PERFORM add_message.
    COMMIT WORK.
  ENDIF.

ENDFORM.                    " SAVE_LOG
*&---------------------------------------------------------------------*
*&      Form  PREVIEW_PDF
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_OBJECT_TAB  text
*      <--P_LV_SUBRC  text
*----------------------------------------------------------------------*
FORM preview_pdf
  USING    iv_prueflos
*           iv_werk
           iv_approve
  CHANGING cv_okcode TYPE sy-ucomm.

  DATA: ls_params TYPE rsparams,
        lt_params TYPE STANDARD TABLE OF rsparams.

  ls_params-selname = 'SO_LOS'.
  ls_params-kind    = 'S'.
  ls_params-sign    = 'I'.
  ls_params-option  = 'EQ'.
  ls_params-low     = iv_prueflos.
  APPEND ls_params TO lt_params.

*  ls_params-selname = 'P_WERK'.
*  ls_params-kind    = 'P'.
*  ls_params-sign    = 'I'.
*  ls_params-option  = 'EQ'.
*  ls_params-low     = iv_werk.
*  APPEND ls_params TO lt_params.

*  ls_params-selname = 'P_NACHDR'.
*  ls_params-kind    = 'P'.
*  ls_params-sign    = 'I'.
*  ls_params-option  = 'EQ'.
*  ls_params-low     = abap_true.
*  APPEND ls_params TO lt_params.

*  ls_params-selname = 'P_PRUEF'.
*  ls_params-kind    = 'P'.
*  ls_params-sign    = 'I'.
*  ls_params-option  = 'EQ'.
*  ls_params-low     = abap_true.
*  APPEND ls_params TO lt_params.

  ls_params-selname = 'P_PREV'.
  ls_params-kind    = 'P'.
  ls_params-sign    = 'I'.
  ls_params-option  = 'EQ'.
  ls_params-low     = abap_true.
  APPEND ls_params TO lt_params.

  ls_params-selname = 'P_APPR'.
  ls_params-kind    = 'P'.
  ls_params-sign    = 'I'.
  ls_params-option  = 'EQ'.
  ls_params-low     = iv_approve.
  APPEND ls_params TO lt_params.

  SUBMIT yqmlims_create_certificate
    WITH SELECTION-TABLE lt_params
    AND RETURN.

  IMPORT ok_code TO cv_okcode FROM MEMORY ID 'YQMLIMS'.

ENDFORM.

**&---------------------------------------------------------------------*
**&      Form  CALL_SCREEN
**&---------------------------------------------------------------------*
**       text
**----------------------------------------------------------------------*
*FORM call_screen.
*
** Aufruf der Erfassungstabelle
*  CALL FUNCTION 'Y_QMLIMS_QET5_CALL_SCREEN'
*    EXPORTING
*      i_screen_manager = 'YQMLIMS_SAPFQE10'
*      i_worklist       = sy-cprog.
**    IMPORTING
**      e_ok_code        = g_ok_code_screen.
*
** Funktionsgruppe auf Initialzustand zurückstellen
*  CALL FUNCTION 'QET4_INITIALIZE'.
*
*ENDFORM.                               " CALL_SCREEN
**&---------------------------------------------------------------------*
**&      Form  PUT_SAMPLES_TO_TOOLBOX
**&---------------------------------------------------------------------*
**       text
**----------------------------------------------------------------------*
**  -->  p1        text
**  <--  p2        text
**----------------------------------------------------------------------*
*FORM put_samples_to_toolbox.
*
*  CONSTANTS lc_plnty_shopfloorrout TYPE plnty VALUE 'V'.
*
*  DATA: l_samples TYPE qsmpl_list OCCURS 0 WITH HEADER LINE.
*  DATA: l_qasvtab TYPE qasv       OCCURS 0 WITH HEADER LINE.
*  DATA: l_qapptab TYPE qapp       OCCURS 0 WITH HEADER LINE.
*  DATA: l_qamvtab TYPE qamv       OCCURS 0 WITH HEADER LINE.
*  DATA: c_max_insp_point LIKE bapi2045d5-insppoint VALUE '999999'.
*  DATA: l_trange         TYPE rsds_trange.
*  DATA: l_where_clauses  TYPE rsds_twhere.
*  DATA: l_qamv           LIKE LINE OF l_where_clauses.
*  DATA: l_qapp           LIKE LINE OF l_where_clauses.
*  DATA:
*    l_lines          TYPE i,
*    l_subrc          LIKE sy-subrc,
*    l_langzeit_aktiv TYPE c,
*    l_anzpp          LIKE qapp-probenr.
*
*** check authorization
**  DATA(lo_auth_check) = cl_qm_authorization_check=>get_instance( ).
**  TRY.
**      lo_auth_check->check_q_insprslt(
**        EXPORTING
**          iv_pruefart               = object_tab-art
**          iv_werk                   = object_tab-werk
**          iv_arbpl                  = object_tab-prplatz
**          iv_qmatauth               = object_tab-qmatauth
**          iv_actvt                  = if_qm_authorization_check=>sc_insprslt-process
**      ).
**    CATCH cx_qm_authorization_check INTO DATA(lx_auth_exc).
***     in case of no auth. we display a warning so that the user may continue with other inspection lot
***     for which he/she may has sufficient auth. But the samples of this lot are not added to the toolbox
**      MESSAGE ID sy-msgid TYPE 'W' NUMBER sy-msgno
**        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
**      EXIT.
**  ENDTRY.
**
*** keine Langzeitpruefung gewuenscht
**  IF p_incllz IS INITIAL.
**    CLEAR l_langzeit_aktiv.
**  ENDIF.
*
** Statuscheck immer durchfuehren
*  CALL FUNCTION 'STATUS_DELETE_FROM_BUFFER'
*    EXPORTING
*      objnr = object_tab-objnr.
*  PERFORM los_status_check IN PROGRAM yqmlims_rqetbi10 CHANGING l_subrc.
*  CASE l_subrc.
*    WHEN '0'.
**     alles o.k.
*
*    WHEN '10'.
**     Langzeitprüfung gewünscht
**      IF NOT p_incllz IS INITIAL.
***       Selektion war mit Langzeitmerkmalen
**        l_langzeit_aktiv = 'X'.
**      ENDIF.
*
*    WHEN OTHERS.
**     Losstatus läßt keine Ergebniserfassung zu
*      EXIT.
*  ENDCASE.
*
*** Liefert Werte der dynamischen Selektionen (Selektionsbild)
**  CALL FUNCTION 'RS_REFRESH_FROM_DYNAMICAL_SEL'
**    EXPORTING
**      curr_report        = g_repid
**      mode_write_or_move = 'M'
**    IMPORTING
**      p_trange           = l_trange
**    EXCEPTIONS
**      not_found          = 1
**      wrong_type         = 2
**      OTHERS             = 3.
**  IF sy-subrc = 0.
*** Freie Abgrenzungen: Konvertierung Format RSDS_TRANGE ==> RSDS_TWHERE
**    CALL FUNCTION 'FREE_SELECTIONS_RANGE_2_WHERE'
**      EXPORTING
**        field_ranges  = l_trange
**      IMPORTING
**        where_clauses = l_where_clauses.
**    READ TABLE l_where_clauses INTO l_qamv
**                      WITH KEY tablename = 'QAMV'.
*** Ermittlung des QAMV-Eintrages in L_QAMV-WHERE_TAB
**    IF sy-subrc <> 0.
**      CLEAR l_qamv.
**    ENDIF.
**    READ TABLE l_where_clauses INTO l_qapp
**                      WITH KEY tablename = 'QAPP'.
*** Ermittlung des QAPP-Eintrages in L_QAPP-WHERE_TAB
**    IF sy-subrc <> 0.
**      CLEAR l_qapp.
**    ENDIF.
**  ENDIF.
*
*  MOVE object_tab-prueflos TO l_samples-insplot.
*  MOVE object_tab-vorglfnr TO l_samples-inspoper_int.
*  MOVE object_tab-vornr    TO l_samples-inspoper.
*
*  IF object_tab-stat07 IS INITIAL.
*    IF object_tab-plnty EQ lc_plnty_shopfloorrout.
*      MESSAGE e107(qt).
*    ENDIF.
** Alle Merkmale einlesen
*    SELECT * FROM qamv INTO TABLE l_qamvtab
*             WHERE prueflos  EQ l_samples-insplot
*               AND vorglfnr  EQ l_samples-inspoper_int
*               AND verwmerkm IN p_merk
*               AND (l_qamv-where_tab)
*               ORDER BY PRIMARY KEY.
*
*    IF NOT l_langzeit_aktiv IS INITIAL.
** Langzeitprüfung gewünscht
*      PERFORM langzeitpruefung_active TABLES l_qamvtab.
*    ENDIF.
*
*    LOOP AT l_qamvtab.
*      MOVE l_qamvtab-merknr  TO l_samples-inspchar.
*      MOVE '000000'          TO l_samples-inspsample.
*
** Einzelne Stichprobe in Toolbox übernehmen
*      CALL FUNCTION 'QET4_ADD_SINGLE_SAMPLE'
*        EXPORTING
*          i_sample                 = l_samples
*        EXCEPTIONS
*          wrong_operation          = 1
*          wrong_insplot            = 2
*          wrong_configuration_data = 3
*          OTHERS                   = 4.
*
*      IF sy-subrc <> 0.
*        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
**        continue.
*        EXIT.
*      ENDIF.
*    ENDLOOP.
*  ELSE.
** Prüfpunktabwicklung, alle Probensätze
** Alle Prüfpunkte einlesen
*    IF object_tab-stat13 = 4.
*      MESSAGE e105(qt) WITH object_tab-stat13.
*    ENDIF.
*    IF p_anzpp IS INITIAL.
*      SELECT * FROM qapp INTO TABLE l_qapptab
*               WHERE prueflos EQ l_samples-insplot
*                 AND vorglfnr EQ l_samples-inspoper_int
*                 AND (l_qapp-where_tab)
*                 ORDER BY PRIMARY KEY.
*    ELSE.
** Nur die letzten 'p_anzpp' Prüfpunkte betrachten
*      SELECT COUNT(*) FROM qapp INTO l_anzpp
*             WHERE prueflos EQ l_samples-insplot
*               AND vorglfnr EQ l_samples-inspoper_int
*               AND (l_qapp-where_tab).
*
** Vermeiden negativer Selektionswerte
*      IF l_anzpp GT p_anzpp.
*        l_anzpp = l_anzpp - p_anzpp.
*      ELSE.
*        l_anzpp = 0.
*      ENDIF.
*      SELECT * FROM qapp INTO TABLE l_qapptab
*               WHERE prueflos EQ l_samples-insplot
*                 AND vorglfnr EQ l_samples-inspoper_int
*                 AND probenr  GT l_anzpp
*                 AND (l_qapp-where_tab)
*                 ORDER BY PRIMARY KEY.
*    ENDIF.
*
**     Eingabezeile generieren
*    l_qapptab-prueflos = l_samples-insplot.
*    l_qapptab-vorglfnr = l_samples-inspoper_int.
*    l_qapptab-probenr = c_max_insp_point.
*    APPEND l_qapptab.
*
** alle Merkmale einlesen
*    SELECT * FROM qamv INTO TABLE l_qamvtab
*             WHERE prueflos EQ l_samples-insplot
*               AND vorglfnr EQ l_samples-inspoper_int
*               AND verwmerkm IN p_merk
*               AND (l_qamv-where_tab)
*               ORDER BY PRIMARY KEY.
*
*    IF NOT l_langzeit_aktiv IS INITIAL.
** Langzeitprüfung gewünscht
*      PERFORM langzeitpruefung_active TABLES l_qamvtab.
*    ENDIF.
*
**   Probensätze erzeugen
*    LOOP AT l_qapptab.
*      LOOP AT l_qamvtab.
*
**     Ungeplante Merkmale:
**     AKTPPKT space: bei allen Prüfpunkten (Vergangenheit + Zukunft)
**                 1: nur bei dem in PPKTUNGEMK angegeben Prüfpunkt
**                 2: ab dem in PPKTUNGEMK angegebenen Prüfpunkt
*        CASE l_qamvtab-aktppkt.
*          WHEN space.
**             do nothing
*          WHEN 1.
*            CHECK l_qamvtab-ppktungemk = l_qapptab-probenr.
*          WHEN 2.
*            CHECK l_qamvtab-ppktungemk <= l_qapptab-probenr.
*        ENDCASE.
*
*        MOVE l_qamvtab-merknr  TO l_samples-inspchar.
*        MOVE l_qapptab-probenr TO l_samples-inspsample.
*
**       Einzelne Stichprobe in Toolbox übernehmen
*        CALL FUNCTION 'QET4_ADD_SINGLE_SAMPLE'
*          EXPORTING
*            i_sample                 = l_samples
*          EXCEPTIONS
*            wrong_operation          = 1
*            wrong_insplot            = 2
*            wrong_configuration_data = 3
*            OTHERS                   = 4.
*
*        IF sy-subrc <> 0.
*          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*             WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
**          continue.
*          EXIT.
*        ENDIF.
*      ENDLOOP.
*    ENDLOOP.
*  ENDIF.
*
*ENDFORM.                               " PUT_SAMPLES_TO_TOOLBOX
