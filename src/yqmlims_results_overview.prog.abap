*&---------------------------------------------------------------------*
*& Report YQMLIMS_RESULTS_OVERVIEW
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT yqmlims_results_overview MESSAGE-ID qetb.

TABLES: aufk,
        qapo,
        qapp,
        qals,
        qamv,
        qasr.
INCLUDE rqalvtop.
INCLUDE <icon>.

DATA:
  gv_s VALUE 'S',
  gv_x VALUE 'X'.

* Type for output object tab
TYPES: BEGIN OF gty_object_tab .
         INCLUDE  TYPE yqm_worklist.
TYPES:   kz_qave TYPE flag.
TYPES:  selected TYPE flag.
TYPES:  lights   TYPE flag.
TYPES:  viewed   TYPE pm_selected.
TYPES: END OF gty_object_tab.

TYPES: BEGIN OF gty_insp_res_rec,
         prueflos TYPE qplos,
         stat07   TYPE qkzfertprf.
         INCLUDE TYPE yqm_qapo.
         INCLUDE TYPE yqm_qapp.
         INCLUDE TYPE yqm_results.
TYPES: END OF gty_insp_res_rec.

TYPES :

  BEGIN OF gty_qasr,
    prueflos   TYPE qplos,
    vorglfnr   TYPE qlfnkn,
    merknr     TYPE qmerknrp,
    probenr    TYPE qstipronr,
    satzstatus TYPE qbeastatus,
    mbewertg   TYPE qmbewertg,
  END OF gty_qasr,

  BEGIN OF gty_qpgt,
    katalogart TYPE qkatart,
    codegruppe TYPE qcodegrp,
    kurztext   TYPE qktextgr,
  END OF gty_qpgt,

  BEGIN OF gty_qpct,
    katalogart TYPE qkatart,
    codegruppe TYPE qcodegrp,
    code       TYPE qcode,
    version    TYPE qversnr,
    kurztext   TYPE qktextgr,
  END OF gty_qpct.

DATA: gs_field_text       TYPE yqm_rtext_t.
DATA: gt_field_text       TYPE TABLE OF yqm_rtext_t.

DATA: gt_qasr TYPE STANDARD TABLE OF gty_qasr.
DATA: gt_qpgt TYPE STANDARD TABLE OF gty_qpgt,
      gs_qpgt TYPE gty_qpgt.
DATA: gt_qpct TYPE STANDARD TABLE OF gty_qpct,
      gs_qpct TYPE gty_qpct.

DATA: gs_tq73t TYPE tq73t.
DATA: gs_tq76t TYPE tq76t.
DATA: gt_tq73t TYPE TABLE OF tq73t.
DATA: gt_tq76t TYPE TABLE OF tq76t.
DATA: gs_t006a TYPE t006a.
DATA: gt_t006a TYPE TABLE OF t006a.

DATA: object_tab TYPE STANDARD TABLE OF gty_object_tab WITH HEADER LINE WITH EMPTY KEY.

TYPES: BEGIN OF gty_sel_tab.
         INCLUDE  TYPE yqm_worklist.
TYPES:   kz_qave  TYPE abap_bool,
         selected TYPE abap_bool,
         lights   TYPE c LENGTH 1,
         viewed   TYPE pm_selected,
       END OF gty_sel_tab.

DATA sel_tab     TYPE STANDARD TABLE OF gty_sel_tab WITH EMPTY KEY.
DATA gs_sel_tab  TYPE gty_sel_tab.

* Select inspection results
DATA: gs_insp_results TYPE gty_insp_res_rec.
DATA: gt_insp_results TYPE TABLE OF gty_insp_res_rec.


DATA: gv_fullfill    TYPE char1.

* Authorization buffer
DATA: BEGIN OF gs_auth,
        art  TYPE qals-art,
        werk TYPE qals-werk,
        ok   TYPE qm00-qkz,
      END OF gs_auth.

DATA: gv_tcode         TYPE sytcode.
DATA: gs_trange        TYPE rsds_range.
DATA: gt_trange        TYPE rsds_trange.
DATA: gt_trange_h      TYPE rsds_trange.
DATA: gt_where_clauses TYPE rsds_twhere.
DATA: gs_qals          TYPE rsds_where.
DATA: gs_qave          TYPE rsds_where.
DATA: gs_qapo          TYPE rsds_where.
DATA: gs_qapp          TYPE rsds_where.
DATA: gs_qamv          TYPE rsds_where.
DATA: gs_qase          TYPE rsds_where.
DATA: gs_qamr          TYPE rsds_where.
DATA: gs_qasr          TYPE rsds_where.
DATA: gt_jsto_pre      TYPE TABLE OF jsto_pre.
DATA: gv_var           TYPE c.
DATA: gv_message_text  TYPE slis_varbz.
DATA: gv_flag          TYPE c.
DATA: gv_stellen       TYPE qstellen.

DATA gr_arbid  TYPE RANGE OF afvc-arbid.
DATA gr_serlot TYPE RANGE OF qals-prueflos.

DATA: gv_progress_act        TYPE i,
      gv_progress_max        TYPE i,
      gv_progress_percentage TYPE i,
      gv_progress_string     TYPE text132.

SELECTION-SCREEN BEGIN OF BLOCK zusatz WITH FRAME TITLE TEXT-s09.
  SELECT-OPTIONS so_los   FOR qals-prueflos.
  SELECT-OPTIONS so_pnahm FOR qals-yqm_probedatum.

  SELECT-OPTIONS so_kost  FOR qals-yqm_kz_cost NO-DISPLAY.
  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN COMMENT 1(20) TEXT-p20.
    SELECTION-SCREEN POSITION 25.
    PARAMETERS: p_kostna RADIOBUTTON GROUP kost.
    SELECTION-SCREEN COMMENT 30(15) TEXT-p21 FOR FIELD p_kostna.
    SELECTION-SCREEN POSITION 45.
    PARAMETERS: p_kostn  RADIOBUTTON GROUP kost.
    SELECTION-SCREEN COMMENT 50(15) TEXT-p23 FOR FIELD p_kostn.
    SELECTION-SCREEN POSITION 65.
    PARAMETERS: p_kosty  RADIOBUTTON GROUP kost.
    SELECTION-SCREEN COMMENT 70(15) TEXT-p22 FOR FIELD p_kosty.
  SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN END OF BLOCK zusatz.

SELECTION-SCREEN BEGIN OF BLOCK pb WITH FRAME TITLE TEXT-s13.
  SELECT-OPTIONS so_vornr  FOR qapo-vornr.
  SELECT-OPTIONS so_tplnr  FOR qapp-tplnr.
  SELECT-OPTIONS so_phynr  FOR qapp-phynr.
SELECTION-SCREEN END OF BLOCK pb.

SELECTION-SCREEN BEGIN OF BLOCK char WITH FRAME TITLE TEXT-s10.
  SELECT-OPTIONS so_stat FOR qasr-satzstatus MODIF ID md2.
  SELECT-OPTIONS so_merk FOR qamv-verwmerkm  MODIF ID md2.
SELECTION-SCREEN END OF BLOCK char.

SELECTION-SCREEN BEGIN OF BLOCK auftrag WITH FRAME TITLE TEXT-s12.
  SELECT-OPTIONS so_auart FOR aufk-auart.
  SELECT-OPTIONS so_aufnr FOR aufk-aufnr.
SELECTION-SCREEN END OF BLOCK auftrag.

* --------------------PARAMETERS------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK scope WITH FRAME TITLE TEXT-p10.
  SELECTION-SCREEN BEGIN OF LINE.
    PARAMETERS: p_qals RADIOBUTTON GROUP scp USER-COMMAND usr .
    SELECTION-SCREEN COMMENT 3(12) TEXT-p11 FOR FIELD p_qals.
    PARAMETERS: p_qapo RADIOBUTTON GROUP scp.
    SELECTION-SCREEN COMMENT 20(12) TEXT-p12 FOR FIELD p_qapo.
    PARAMETERS: p_qapp RADIOBUTTON GROUP scp.
    SELECTION-SCREEN COMMENT 37(12) TEXT-p13 FOR FIELD p_qapp.
    PARAMETERS: p_ires RADIOBUTTON GROUP scp .
    SELECTION-SCREEN COMMENT 54(12) TEXT-p14 FOR FIELD p_ires.
    PARAMETERS : p_rec AS CHECKBOX MODIF ID md2 USER-COMMAND us2.
    SELECTION-SCREEN COMMENT 71(20) TEXT-p16 FOR FIELD p_rec.
  SELECTION-SCREEN END OF LINE.

  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN POSITION 67.
    PARAMETERS : p_out AS CHECKBOX MODIF ID md2.
    SELECTION-SCREEN COMMENT 71(20) TEXT-p17 FOR FIELD p_out.
  SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN END OF BLOCK scope.

SELECTION-SCREEN BEGIN OF BLOCK bottom WITH FRAME TITLE TEXT-p00.
  SELECTION-SCREEN BEGIN OF LINE.
    PARAMETERS: p_alles RADIOBUTTON GROUP ud.
    SELECTION-SCREEN COMMENT 3(70) TEXT-p03 FOR FIELD p_alles.
  SELECTION-SCREEN END OF LINE.

  SELECTION-SCREEN BEGIN OF LINE.
    PARAMETERS: p_no_ud RADIOBUTTON GROUP ud.
    SELECTION-SCREEN COMMENT 3(70) TEXT-p01 FOR FIELD p_no_ud.
  SELECTION-SCREEN END OF LINE.

  SELECTION-SCREEN BEGIN OF LINE.
    PARAMETERS: p_ud RADIOBUTTON GROUP ud.
    SELECTION-SCREEN COMMENT 3(70) TEXT-p02 FOR FIELD p_ud.
  SELECTION-SCREEN END OF LINE.
*Skip worklist
*selection-screen begin of block options with frame title text-s10.
  PARAMETERS: p_var TYPE disvariant-variant.  " used in standard form in case statement.
  PARAMETERS: monitor TYPE rqmonitor-qm_monitor " used in standard form in case statement.
                                                " So naming convention not followed
              AS LISTBOX VISIBLE LENGTH 30.
*selection-screen end of block options.
SELECTION-SCREEN END OF BLOCK bottom.
SELECT-OPTIONS:
* With these selection criteria may also at selection screen 902
* The database index will be used for open lots.
*  so_sta14 FOR qals-stat14 NO-DISPLAY,
  so_sta35 FOR qals-stat35 NO-DISPLAY.

*--------------------------------------------------------------------*
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_var.
  PERFORM variant_inputhelp_f14 USING p_var.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR monitor.
  PERFORM create_monitor_tab_f16.
  PERFORM monitor_inputhelp_f16 USING monitor.

*--------------------------------------------------------------------*
* AT SELECTION SCREEN OUTPUT                                         *
*--------------------------------------------------------------------*
AT SELECTION-SCREEN OUTPUT.

* Ausblenden der Selektion zur Materialklasse
  LOOP AT SCREEN .
    IF screen-name = 'PMATICON'
    OR screen-name = 'PMATCLAS'
    OR screen-name = '%CCS2052_1000'
    OR screen-name = '%PCS1053_1000'
    OR screen-group3 = 'PBU'.
      screen-input  = 0.
      screen-output = 0.
      screen-active = 0.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

  IF p_ires = ' '.
*    CLEAR: p_rec, p_out.
*    CLEAR : so_ana, so_val, p_rec, p_out.
    LOOP AT SCREEN .
      IF screen-group1 = 'MD2'.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ELSE.
    LOOP AT SCREEN.
      IF screen-group1 = 'MD2'.
        screen-input = 1.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.

  IF sy-tcode = 'YQM_AV'.
    LOOP AT SCREEN.
      IF screen-name CS 'QL_CHARG'
      OR screen-name CS 'QL_LIFNR'
      OR screen-name CS 'QL_HERST'
      OR screen-name CS 'QL_KUNNR'.
        screen-active = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.

  LOOP AT SCREEN.
    IF screen-name  CS 'QL_MAX_R'.
      screen-input  = 0.
      screen-output = 0.
      screen-active = 0.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

  CHECK g_submit IS INITIAL.
* Fcode FC01 bei Variantenpflege deaktivieren
  PERFORM user_fc_steuern.

  PERFORM check_variant_maintain.

*--------------------------------------------------------------------*
* AT SELECTION SCREEN                                                *
*--------------------------------------------------------------------*
AT SELECTION-SCREEN.

  PERFORM variant_existence_f14 USING p_var.  "check for Cust. var.
  CHECK g_submit IS INITIAL.
  g_variant-variant = p_var.
*== F-Code Verification
  IF sscrfields-ucomm EQ 'FC01'.
*-- User-Vset ersion
    PERFORM variant_f10.
*   new call to take over to variant
    IF sy-tcode = 'SE38'
    OR sy-tcode = 'SA38'.
      SUBMIT (sy-repid) VIA SELECTION-SCREEN.
    ELSE.
      LEAVE TO TRANSACTION sy-tcode.
    ENDIF.
  ENDIF.


AT SELECTION-SCREEN ON RADIOBUTTON GROUP ud.

  DATA lt_sta35 TYPE RANGE OF qals-stat35.

  CLEAR so_sta35.

  IF p_no_ud = abap_true.
*-- inspection lots with STAT35 = ' '
    lt_sta35 = VALUE #(
      ( sign = 'I' option = 'EQ' low = space ) ).

  ELSEIF p_ud = abap_true.
*-- inspection lots with STAT35 = 'X'
    lt_sta35 = VALUE #(
      ( sign = 'I' option = 'EQ' low = 'X' ) ).

  ENDIF.

  so_sta35[] = lt_sta35.

AT SELECTION-SCREEN ON RADIOBUTTON GROUP kost.

  DATA lt_kost TYPE RANGE OF qals-yqm_kz_cost.

  CLEAR so_kost.

  IF p_kostn = abap_true.
*-- inspection lots with STAT35 = ' '
    lt_kost = VALUE #(
      ( sign = 'I' option = 'EQ' low = space ) ).

  ELSEIF p_kosty = abap_true.
*-- inspection lots with STAT35 = 'X'
    lt_kost = VALUE #(
      ( sign = 'I' option = 'EQ' low = 'X' ) ).

  ENDIF.

  so_kost[] = lt_kost.

*--------------------------------------------------------------------*
* INITIALIZATION                                                     *
*--------------------------------------------------------------------*
INITIALIZATION.

  g_tabname = 'YQM_WORKLIST'.
  IF NOT sy-calld IS INITIAL.
    IMPORT g_submit g_fieldcat_tab FROM MEMORY ID 'SUBMIT'.
  ENDIF.

*-------------------------------------------------------------------*
  gv_message_text = TEXT-tes.
  PERFORM variant_init_f14 USING 'LOTS'
                                 'LOTS'
                                 gv_message_text.

  CHECK g_submit IS INITIAL.
  PERFORM get_default_variant_f14 USING p_var.
*---------------------------------------------------------------------*
  SELECTION-SCREEN
*-- FUNCTION KEYS
  FUNCTION KEY 1.
  PERFORM variant_start_f10.
*-- DEFINE FUNCTION KEYS ON INITIAL SCREEN
  sscrfields-functxt_01 = 'Meine Vorbelegung   '(f01).

*---------------------------------------------------------------------*
* START OF SELECTION                                                  *
*---------------------------------------------------------------------*
START-OF-SELECTION.

  CLEAR gv_flag.
  IF g_submit IS INITIAL.
    PERFORM create_fieldcat_l USING g_tabname.
    PERFORM update_fieldcat_variant_f14.
*   Toolbox initialisation
    CALL FUNCTION 'QET4_INITIALIZE'.
  ENDIF.

  PERFORM prepare_dynamic_selects.
*  PERFORM preselect_samples.

  IF NOT ql_prplz[] IS INITIAL
  OR NOT ql_prplt[] IS INITIAL.
    PERFORM preselect_workcenter.
    IF gr_arbid[] IS INITIAL.
      EXIT.
    ENDIF.
  ELSE.
    CLEAR gr_arbid.
  ENDIF.

*Stati are checked in this report. Therefore JEST is preread
  preread = g_x.

* Select Inspection lots
  SELECT DISTINCT
* Inspection lot information
         qals~prueflos, qals~werk, qals~art, qals~herkunft,
         qals~objnr, qals~obtyp, qals~aufpl, qals~ktextmat, qals~stsma,
         qals~qmatauth, qals~stat11, qals~insmk, qals~stat02, qals~stat07,
         qals~stat06, qals~stat09, qals~stat19, qals~stat23, qals~stat24,
         qals~stat25, qals~kzskiplot, qals~hpz, qals~dynhead, qals~stprver,
         qals~enstehdat, qals~entstezeit, qals~ersteller,
         qals~ersteldat, qals~erstelzeit, qals~aenderer, qals~aenderdat,
         qals~aenderzeit, qals~pastrterm, qals~pastrzeit, qals~paendterm,
         qals~paendzeit, qals~plnty, qals~plnnr, qals~pplverw, qals~plnal,
         qals~slwbez, qals~stat13, qals~prbnaverf, qals~prbnavv, qals~stat12,
         qals~selmatnr, qals~selrevlv, qals~selwerk, qals~sellifnr, qals~selherst,
         qals~selkunnr, qals~selpplverw, qals~gueltigab, qals~aufnr, qals~verid,
         qals~sa_aufnr, qals~kunnr, qals~lifnr, qals~hersteller, qals~ematnr,
         qals~matnr, qals~revlv, qals~xchpf, qals~charg, qals~lagortchrg,
         qals~sobkz, qals~ekorg, qals~ebeln, qals~ebelp, qals~etenr, qals~blart,
         qals~mjahr, qals~mblnr, qals~zeile, qals~budat, qals~bwart, qals~werkvorg,
         qals~lagortvorg, qals~lgnum, qals~lgtyp, qals~lgpla, qals~ls_kdauf,
         qals~ls_kdpos, qals~ls_vbeln, qals~ls_posnr, qals~ls_abrvw, qals~ls_route,
         qals~ls_lland, qals~ls_kunag, qals~ls_vkorg, qals~ls_kdmat,
         qals~sprache, qals~ktextlos, qals~zusmkzaehl, qals~offennlzmk, qals~offen_lzmk,
         qals~losmenge, qals~mengeneinh, qals~anzgeb, qals~gebeh, qals~gesstichpr,
         qals~einhprobe, qals~dynregel, qals~stat44, qals~prstufe, qals~prschaerfe,
         qals~lmenge01, qals~lmenge02, qals~lmenge03, qals~lmenge04, qals~lmenge05,
         qals~lmenge06, qals~matnrneu, qals~chargneu, qals~lmenge07, qals~lmenge08,
         qals~lmenge09, qals~lmengezub, qals~lmengelz, qals~lmengepr, qals~lmengezer,
         qals~lmengeist, qals~lmengesch, qals~anteil, qals~stat03, qals~qpmatlos,
         qals~aufnr_co, qals~kzvbr, qals~knttp, qals~stat05, qals~kostl, qals~aufps,
         qals~anln1, qals~anln2, qals~ps_psp_pnr, qals~nplnr, qals~aplzl,
         qals~kdauf, qals~kdpos, qals~paobjnr, qals~gsber, qals~konto, "qals~prctr,
         qals~kokrs, qals~bukrs, qals~sernp, qals~kont_pspnr, qals~kont_kdauf,
         qals~kont_kdpos, qals~stat16, qals~insp_doc_number, qals~prio_punkte,
         qals~lichn, qals~stat36, qals~ltextkz,
         qals~yqm_probedatum, qals~yqm_probezeit, qals~yqm_probenehmer03, qals~yqm_probenehmer40,
         qals~yqm_probeeingang, qals~yqm_berichtnr, qals~yqm_kz_cost, qals~yqm_co_beleg,
         qals~yqm_co_beleg_datum, qals~yqm_ueberwachung, qals~yqm_probengewinnung,
         qals~yqm_probenahmeart, qals~yqm_anlass, qals~yqm_vnlpv,
         qals~yqm_vnlpvkt, qals~yqm_pnzwk, qals~yqm_qphysprnr, qals~yqm_qpbversion,

* Usage Decision information
         qave~vbewertung, qave~qkennzahl, qave~kzart, qave~vkatart, qave~vauswahlmg,
         qave~vcodegrp, qave~vcode, qave~dbewertung, qave~vfolgeakti, qave~vname, qave~ltextkz AS ltextkzve,
         qave~vdatum, qave~vezeiterf, qave~vaename, qave~vaedatum, qave~vezeitaen,

* Material Master Information
         mara~mhdrz, mara~mhdhb, mara~iprkz, mara~rdmhd, mara~mhdlp, mara~extwg,
*
* Material Master Information - Plant level
         marc~maabc, marc~dispo,
* Auftragsdaten
         aufk~auart
    FROM  qals
     LEFT OUTER JOIN qave  ON  ( qave~prueflos = qals~prueflos
                           AND   qave~kzart    = 'L' )
     LEFT OUTER JOIN qapp  ON  ( qapp~prueflos = qals~prueflos )
     LEFT OUTER JOIN qamv  ON  ( qamv~prueflos = qals~prueflos )
     LEFT OUTER JOIN mara  ON  ( mara~matnr    = qals~matnr )
     LEFT OUTER JOIN marc  ON  ( marc~matnr    = qals~matnr
                           AND   marc~werks    = qals~werk )
     LEFT OUTER JOIN afvc  ON  ( afvc~aufpl    = qals~aufpl )
     LEFT OUTER JOIN aufk  ON  ( aufk~aufnr    = qals~aufnr )
  WHERE qals~prueflos       IN @gr_serlot
    AND qals~prueflos       IN @so_los
    AND qals~enstehdat      IN @ql_enstd
    AND qals~pastrterm      IN @ql_pastr
    AND qals~paendterm      IN @ql_paend
    AND qals~werk           IN @ql_werks
    AND qals~herkunft       IN @ql_herkt
    AND qals~matnr          IN @ql_matnr
    AND qals~charg          IN @ql_charg
    AND qals~lifnr          IN @ql_lifnr
    AND qals~hersteller     IN @ql_herst
    AND qals~kunnr          IN @ql_kunnr
    AND qals~aufnr          IN @so_aufnr
    AND qals~stat35         IN @so_sta35
    AND qals~yqm_probedatum IN @so_pnahm
    AND qals~yqm_kz_cost    IN @so_kost
    AND (gs_qals-where_tab)
    AND qapp~equnr          IN @ql_equi
    AND qapp~tplnr          IN @so_tplnr
    AND qapp~phynr          IN @so_phynr
    AND (gs_qapp-where_tab)
    AND (gs_qave-where_tab)
    AND qamv~verwmerkm      IN @so_merk
    AND (gs_qamv-where_tab)
    AND afvc~arbid          IN @gr_arbid
    AND afvc~werks          IN @ql_prwrk
    AND afvc~vornr          IN @so_vornr
    AND aufk~auart          IN @so_auart
    AND (gs_qapo-where_tab)
      INTO TABLE @DATA(lt_qals_sel).
  IF sy-subrc <> 0.
    CLEAR sel_tab.
    IF sy-calld IS INITIAL.
      MESSAGE i047(ih).
    ENDIF.
    EXIT.
  ELSE.
    sel_tab = CORRESPONDING #(
                        BASE ( sel_tab )
                               lt_qals_sel ).
  ENDIF.


* Check authority on inspection type and plant
  object_tab[] = sel_tab[].
  SORT object_tab BY werk art.
  DELETE ADJACENT DUPLICATES FROM object_tab COMPARING werk art.
  gv_progress_max = lines( object_tab ).

  CLEAR gv_progress_act.
  CLEAR gv_progress_string.

  LOOP AT object_tab.

    gv_progress_string = 'Checking Authority'(200).

    gv_progress_act += 1.

    gv_progress_percentage = 100 * gv_progress_act /  gv_progress_max.

    CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
      EXPORTING
        percentage = gv_progress_percentage
        text       = gv_progress_string.

    MOVE-CORRESPONDING object_tab TO gs_auth.
    CALL FUNCTION 'QAUT_INSPTYPE'
      EXPORTING
        i_pruefart       = gs_auth-art
        i_werk           = gs_auth-werk
      EXCEPTIONS
        auth_destroyed   = 1
        internal_error   = 2
        no_authorization = 3
        OTHERS           = 4.
    IF sy-subrc <> 0.
      MESSAGE s170(qa) WITH gs_auth-art.

      DELETE sel_tab WHERE  werk = gs_auth-werk
                     AND    art  = gs_auth-art.
    ENDIF.
  ENDLOOP.

  CHECK NOT sel_tab[] IS INITIAL.

  LOOP AT sel_tab INTO gs_sel_tab.
    APPEND gs_sel_tab-objnr TO gt_jsto_pre.
  ENDLOOP.

  CALL FUNCTION 'STATUS_PRE_READ'
    TABLES
      jsto_pre_tab = gt_jsto_pre.

  CLEAR object_tab[].

  LOOP AT sel_tab INTO gs_sel_tab.
    MOVE-CORRESPONDING gs_sel_tab TO object_tab.

    IF NOT ql_selid IS INITIAL.
      CALL FUNCTION 'STATUS_CHECK_BY_SELSCHEM'
        EXPORTING
          objnr          = gs_sel_tab-objnr
          selid          = ql_selid
        IMPORTING
          fullfill       = gv_fullfill
        EXCEPTIONS
          no_stat_scheme = 01
          no_stat_tab    = 02.
      IF  sy-subrc    = 0
      AND gv_fullfill = 'X'.
        APPEND object_tab.
      ENDIF.
    ELSE.
      APPEND object_tab.
    ENDIF.
  ENDLOOP.

*  CHECK NOT object_tab[] IS INITIAL.

* Preselect all Inspection lot User Status
  CLEAR gt_jsto_pre.
  LOOP AT object_tab.
    APPEND object_tab-objnr TO gt_jsto_pre.
  ENDLOOP.

  gv_progress_string = 'Reading status information'(202).

  CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
    EXPORTING
      text = gv_progress_string.


  gv_progress_max = lines( object_tab ).

  CLEAR gv_progress_act.
  CLEAR gv_progress_string.

  LOOP AT object_tab.

* For correct setting of monitor
    MOVE-CORRESPONDING object_tab TO qals.

    gv_progress_act += 1.

    IF gv_progress_act MOD 100 = 1.

      gv_progress_string = 'Reading additional information'(201).
      gv_progress_percentage = 100 * gv_progress_act /  gv_progress_max.

      CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
        EXPORTING
          percentage = gv_progress_percentage
          text       = gv_progress_string.
*        EXCEPTIONS
*          OTHERS     = 0.
*      IF sy-subrc <> 0.
*        CLEAR sy-subrc.
*      ENDIF.
    ENDIF.

    CALL FUNCTION 'STATUS_TEXT_EDIT'
      EXPORTING
        flg_user_stat    = 'X'
        objnr            = object_tab-objnr
        spras            = sy-langu
      IMPORTING
        line             = object_tab-sttxt
        user_line        = object_tab-ustxt
      EXCEPTIONS
        object_not_found = 01.
    IF sy-subrc NE 0.
      CLEAR object_tab-sttxt.
      CLEAR object_tab-ustxt.
    ENDIF.

    IF NOT object_tab-vcode IS INITIAL.
      object_tab-kz_qave = 'X'.
    ELSE.
      CLEAR object_tab-kz_qave.
    ENDIF.

    PERFORM set_monitor_f16.
    MODIFY object_tab.
  ENDLOOP.


* Select results data based on selection scope
* 1. Selection Scope Inspection Operation
  IF     NOT p_qapo IS INITIAL.
    SELECT
           qals~prueflos,
           afvc~aplzl      AS vorglfnr,
           afvc~vornr,
           afvc~ltxa1      AS vorktxt,
           crhd~arbpl      AS prplatz,
           crhd~werks      AS prplatzwrk,
           crtx~ktext      AS prplatztxt
      FROM  afvc
                  JOIN qals  ON  ( qals~aufpl    = afvc~aufpl )
                  JOIN crhd  ON  ( crhd~objty    = 'A'
                             AND   crhd~objid    = afvc~arbid )
                  JOIN crtx  ON  ( crtx~objty    = crhd~objty
                             AND   crtx~objid    = crhd~objid
                             AND   crtx~spras    = @sy-langu )
       FOR ALL ENTRIES IN @object_tab
    WHERE qals~prueflos    EQ @object_tab-prueflos
      AND afvc~arbid       IN @gr_arbid
      AND afvc~werks       IN @ql_prwrk
      AND afvc~vornr       IN @so_vornr
      AND (gs_qapo-where_tab)
       INTO TABLE @DATA(lt_qapo_sel).
    IF sy-subrc <> 0.
      CLEAR gt_insp_results.
    ELSE.
      gt_insp_results = CORRESPONDING #(
                          BASE ( gt_insp_results )
                                 lt_qapo_sel ).

      SORT gt_insp_results BY prueflos vorglfnr merknr qasr_probenr qase_detailerg.
    ENDIF.

* 2. Selection Scope Inspection Point
  ELSEIF NOT p_qapp IS INITIAL.

    SELECT qapp~prueflos , qapp~vorglfnr ,
           afvc~vornr,
           afvc~ltxa1      AS vorktxt,
           crhd~arbpl      AS prplatz,
           crhd~werks      AS prplatzwrk,
           crtx~ktext      AS prplatztxt,
           qapp~probenr    AS qapp_probenr,
           qapp~equnr      AS qapp_equnr,
           qapp~tplnr      AS qapp_tplnr,
           qapp~phynr      AS qapp_phynr,
           qapp~userc1     AS qapp_userc1,
           qapp~userc2     AS qapp_userc2,
           qapp~usern1     AS qapp_usern1,
           qapp~usern2     AS qapp_usern2,
           qapp~vkatart    AS qapp_vkatart,
           qapp~vwerks     AS qapp_vwerks,
           qapp~vauswahlmg AS qapp_vauswahlmg,
           qapp~vcodegrp   AS qapp_vcodegrp,
           qapp~vcode      AS qapp_vcode,
           qapp~vbewertung AS qapp_vbewertung,
           qapp~pruefer    AS qapp_pruefer,
           qapp~entstehdat AS qapp_entstehdat,
           qapp~entstehzt  AS qapp_entstehzt,
           qapp~ersteller  AS qapp_ersteller,
           qapp~ersteldat  AS qapp_ersteldat,
           qapp~erstelzeit AS qapp_erstelzeit,
           qapp~aenderer   AS qapp_aenderer,
           qapp~aenderdat  AS qapp_aenderdat,
           qapp~aenderzeit AS qapp_aenderzeit,

* Physical Sample Information
         qprs~ktext AS qapp_ktext

      FROM  qapp
                  JOIN qals  ON  ( qals~prueflos = qapp~prueflos )
                  LEFT OUTER JOIN qprs  ON  ( qprs~phynr    = qapp~phynr )
                  JOIN afvc  ON  ( afvc~aufpl    = qals~aufpl
                             AND   afvc~aplzl    = qapp~vorglfnr )
                  JOIN crhd  ON  ( crhd~objty    = 'A'
                             AND   crhd~objid    = afvc~arbid )
                  JOIN crtx  ON  ( crtx~objty    = crhd~objty
                             AND   crtx~objid    = crhd~objid
                             AND   crtx~spras    = @sy-langu )
       FOR ALL ENTRIES IN @object_tab
    WHERE qals~prueflos    EQ @object_tab-prueflos
      AND qapp~tplnr       IN @so_tplnr
      AND qapp~phynr       IN @so_phynr
      AND (gs_qapp-where_tab)
      AND afvc~arbid       IN @gr_arbid
      AND afvc~werks       IN @ql_prwrk
      AND afvc~vornr       IN @so_vornr
      AND (gs_qapo-where_tab)
       INTO TABLE @DATA(lt_qapp_sel).
    IF sy-subrc <> 0.
      CLEAR gt_insp_results.
    ELSE.
      gt_insp_results = CORRESPONDING #(
                          BASE ( gt_insp_results )
                                 lt_qapp_sel ).
      SORT gt_insp_results BY prueflos vorglfnr merknr qasr_probenr qase_detailerg.
    ENDIF.

    IF NOT gt_insp_results[] IS INITIAL.
      SELECT prueflos vorglfnr merknr probenr satzstatus mbewertg
        FROM qasr
        INTO TABLE gt_qasr
        FOR ALL ENTRIES IN gt_insp_results
        WHERE prueflos   = gt_insp_results-prueflos
        AND   satzstatus EQ '5'.
      IF sy-subrc = 0.
        SORT gt_qasr BY prueflos vorglfnr probenr.
      ELSE.
        CLEAR gt_qasr.
      ENDIF.
    ENDIF.

* 3. Selection Scope Inspection Results
  ELSEIF NOT p_ires IS INITIAL.

    SELECT

* Inspection Operation Information
      afvc~vornr,
      afvc~ltxa1      AS vorktxt,
      crhd~arbpl      AS prplatz,
      crhd~werks      AS prplatzwrk,
      crtx~ktext      AS prplatztxt,

* Inspection Point Information
      qapp~probenr    AS qapp_probenr,
      qapp~equnr      AS qapp_equnr,
      qapp~tplnr      AS qapp_tplnr,
      qapp~phynr      AS qapp_phynr,
      qapp~userc1     AS qapp_userc1,
      qapp~userc2     AS qapp_userc2,
      qapp~usern1     AS qapp_usern1,
      qapp~usern2     AS qapp_usern2,
      qapp~vkatart    AS qapp_vkatart,
      qapp~vwerks     AS qapp_vwerks,
      qapp~vauswahlmg AS qapp_vauswahlmg,
      qapp~vcodegrp   AS qapp_vcodegrp,
      qapp~vcode      AS qapp_vcode,
      qapp~vbewertung AS qapp_vbewertung,
      qapp~pruefer    AS qapp_pruefer,
      qapp~entstehdat AS qapp_entstehdat,
      qapp~entstehzt  AS qapp_entstehzt,
      qapp~ersteller  AS qapp_ersteller,
      qapp~ersteldat  AS qapp_ersteldat,
      qapp~erstelzeit AS qapp_erstelzeit,
      qapp~aenderer   AS qapp_aenderer,
      qapp~aenderdat  AS qapp_aenderdat,
      qapp~aenderzeit AS qapp_aenderzeit,

*     Inspection Lot Information
      qals~stat07,

* Physical Sample Information
      qprs~ktext AS qapp_ktext,

*     Inspection Characteristic Information
      qamv~prueflos,
      qamv~vorglfnr,
      qamv~merknr,

*     Inspection Characteristic Information (QAMV)
      qamv~steuerkz   AS qamv_steuerkz,
      qamv~qmtb_werks AS qamv_qmtb_werks,
      qamv~pmethode   AS qamv_pmethode,
      qamv~pmtversion AS qamv_pmtversion,
      qamv~qpmk_ref   AS qamv_qpmk_ref,
      qamv~qpmk_werks AS qamv_qpmk_werks,
      qamv~verwmerkm  AS qamv_verwmerkm,
      qamv~mkversion  AS qamv_mkversion,
      qamv~kurztext   AS qamv_kurztext,
      qamv~sollstpumf AS qamv_sollstpumf,
      qamv~pruefumf   AS qamv_pruefumf,
      qamv~grenzeob1  AS qamv_grenzeob1,
      qamv~grenzob1ni AS qamv_grenzob1ni,
      qamv~grenzeun1  AS qamv_grenzeun1,
      qamv~grenzun1ni AS qamv_grenzun1ni,
      qamv~plausioben AS qamv_plausioben,
      qamv~plausiobni AS qamv_plausiobni,
      qamv~plausiunte AS qamv_plausiunte,
      qamv~plausiunni AS qamv_plausiunni,
      qamv~toleranzob AS qamv_toleranzob,
      qamv~tolobni    AS qamv_tolobni,
      qamv~toleranzun AS qamv_toleranzun,
      qamv~tolunni    AS qamv_tolunni,
      qamv~mengeneinh AS qamv_mengeneinh,
      qamv~dummy10    AS qamv_dummy10,
      qamv~dummy20    AS qamv_dummy20,
      qamv~dummy40    AS qamv_dummy40,
      qamv~stellen    AS qamv_stellen,
      qamv~masseinhsw AS qamv_msehi,

* Inspection results Information (QAMR)
      qamr~satzstatus      AS qamr_statusr,
      qamr~qergdath        AS qamr_qergdath,
      qamr~mbewertg        AS qamr_mbewertg,
      qamr~pruefer         AS qamr_pruefer,
      qamr~pruefdatuv      AS qamr_pruefdatuv,
      qamr~pruefdatub      AS qamr_pruefdatub,
      qamr~pruefzeitv      AS qamr_pruefzeitv,
      qamr~pruefzeitb      AS qamr_pruefzeitb,
      qamr~pruefbemkt      AS qamr_pruefbemkt,
      qamr~mittelwert      AS qamr_mittelwert,
      qamr~mittelwni       AS qamr_mittelwni,
      qamr~katalgart1      AS qamr_katalgart1,
      qamr~gruppe1         AS qamr_gruppe1,
      qamr~code1           AS qamr_code1,
      qamr~version1        AS qamr_version1,
      qamr~fehlklas        AS qamr_fehlklas,
      qamr~attribut        AS qamr_attribut,
      qamr~maschine        AS qamr_maschine,
      qamr~original_input  AS qamr_original_input,
      qamr~diff_dec_places AS qamr_diff_dec_places,

* Inspection results Information (QASR)
      qasr~probenr         AS qasr_probenr,
      qasr~satzstatus      AS qasr_statusr,
      qasr~qergdath        AS qasr_qergdath,
      qasr~mbewertg        AS qasr_mbewertg,
      qasr~pruefer         AS qasr_pruefer,
      qasr~pruefdatuv      AS qasr_pruefdatuv,
      qasr~pruefdatub      AS qasr_pruefdatub,
      qasr~pruefzeitv      AS qasr_pruefzeitv,
      qasr~pruefzeitb      AS qasr_pruefzeitb,
      qasr~pruefbemkt      AS qasr_pruefbemkt,
      qasr~mittelwert      AS qasr_mittelwert,
      qasr~mittelwni       AS qasr_mittelwni,
      qasr~katalgart1      AS qasr_katalgart1,
      qasr~gruppe1         AS qasr_gruppe1,
      qasr~code1           AS qasr_code1,
      qasr~version1        AS qasr_version1,
      qasr~fehlklas        AS qasr_fehlklas,
      qasr~attribut        AS qasr_attribut,
      qasr~maschine        AS qasr_maschine,
      qasr~original_input  AS qasr_original_input,
      qasr~diff_dec_places AS qasr_diff_dec_places,

* Inspection results Information (QASE)
      qase~detailerg       AS qase_detailerg,
      qase~pruefer         AS qase_pruefer,
      qase~pruefdatuv      AS qase_pruefdatuv,
      qase~pruefdatub      AS qase_pruefdatub,
      qase~pruefzeitv      AS qase_pruefzeitv,
      qase~pruefzeitb      AS qase_pruefzeitb,
      qase~pruefbemkt      AS qase_pruefbemkt,
      qase~messwertni      AS qase_messwertni,
      qase~messwert        AS qase_messwert,
      qase~katalgart1      AS qase_katalgart1,
      qase~gruppe1         AS qase_gruppe1,
      qase~code1           AS qase_code1,
      qase~version1        AS qase_version1,
      qase~fehlklas        AS qase_fehlklas,
      qase~attribut        AS qase_attribut,
      qase~maschine        AS qase_maschine,
      qase~original_input  AS qase_original_input,
      qase~diff_dec_places AS qase_diff_dec_places",

      FROM  qamv
       LEFT OUTER JOIN qapp  ON  ( qapp~prueflos = qamv~prueflos
                             AND   qapp~vorglfnr = qamv~vorglfnr )
       LEFT OUTER JOIN qamr  ON  ( qamr~prueflos = qamv~prueflos
                             AND   qamr~vorglfnr = qamv~vorglfnr
                             AND   qamr~merknr   = qamv~merknr )
       LEFT OUTER JOIN qasr  ON  ( qasr~prueflos = qamv~prueflos
                             AND   qasr~vorglfnr = qamv~vorglfnr
                             AND   qasr~merknr   = qamv~merknr
                             AND   qasr~probenr  = qapp~probenr )
       LEFT OUTER JOIN qase  ON  ( qase~prueflos = qamv~prueflos
                             AND   qase~vorglfnr = qamv~vorglfnr
                             AND   qase~merknr   = qamv~merknr )
       LEFT OUTER JOIN qprs  ON  ( qprs~phynr    = qapp~phynr )
                  JOIN qals  ON  ( qals~prueflos = qamv~prueflos )
                  JOIN afvc  ON  ( afvc~aufpl    = qals~aufpl
                             AND   afvc~aplzl    = qamv~vorglfnr )
                  JOIN crhd  ON  ( crhd~objty    = 'A'
                             AND   crhd~objid    = afvc~arbid )
                  JOIN crtx  ON  ( crtx~objty    = crhd~objty
                             AND   crtx~objid    = crhd~objid
                             AND   crtx~spras    = @sy-langu )
       FOR ALL ENTRIES IN @object_tab
    WHERE qals~prueflos    EQ @object_tab-prueflos
      AND qapp~tplnr       IN @so_tplnr
      AND qapp~phynr       IN @so_phynr
      AND (gs_qapp-where_tab)
      AND qamv~verwmerkm   IN @so_merk
      AND (gs_qamv-where_tab)
      AND qasr~satzstatus  IN @so_stat
      AND afvc~arbid       IN @gr_arbid
      AND afvc~werks       IN @ql_prwrk
      AND afvc~vornr       IN @so_vornr
      AND (gs_qapo-where_tab)
       INTO TABLE @DATA(lt_qamv_sel).
    IF sy-subrc <> 0.
      CLEAR gt_insp_results.
    ELSE.

      gt_insp_results = CORRESPONDING #(
                          BASE ( gt_insp_results )
                                 lt_qamv_sel ).

      SORT gt_insp_results BY prueflos vorglfnr merknr qasr_probenr qase_detailerg.

* Delete Characteristics that do not fulfill all selection criteria (Inspector)
      IF     p_rec EQ 'X'
      AND    p_out IS INITIAL.
*       Only recorded results
        DELETE gt_insp_results
          WHERE ( stat07       IS INITIAL AND  qamr_statusr LT 2 )
          OR    ( stat07       EQ 'X'     AND  qasr_statusr LT 2 ).

      ELSEIF p_rec IS INITIAL
      AND    p_out EQ 'X'.
* Only outstanding results
        DELETE gt_insp_results
           WHERE ( stat07 IS INITIAL AND qamr_statusr GE 2 )
              OR ( stat07 EQ 'X'     AND qamr_statusr GE 2 ) .
      ENDIF.
    ENDIF.
  ENDIF.


  IF p_qals IS INITIAL.

    IF gt_insp_results[] IS INITIAL.
* No results data found
      IF sy-calld IS INITIAL.
        MESSAGE i047(ih).
      ENDIF.
      EXIT.
    ELSE.
      sel_tab[] = object_tab[].
      CLEAR object_tab[].

* Preselect all codegroups/codes
      SELECT katalogart codegruppe kurztext
        FROM qpgt INTO CORRESPONDING FIELDS OF TABLE gt_qpgt
        FOR ALL ENTRIES IN gt_insp_results
        WHERE ( ( katalogart = gt_insp_results-qasr_katalgart1
            OR    codegruppe = gt_insp_results-qasr_gruppe1 )
          OR    ( katalogart = gt_insp_results-qase_katalgart1
            OR    codegruppe = gt_insp_results-qase_gruppe1 ) )
        AND sprache = sy-langu.
      IF sy-subrc = 0.
        SORT gt_qpgt BY katalogart codegruppe kurztext.
      ENDIF.

      SELECT katalogart codegruppe code version kurztext
        FROM qpct INTO CORRESPONDING FIELDS OF TABLE gt_qpct
        FOR ALL ENTRIES IN gt_insp_results
        WHERE ( ( katalogart = gt_insp_results-qasr_katalgart1
            AND   codegruppe = gt_insp_results-qasr_gruppe1
            AND   code       = gt_insp_results-qasr_code1 )
          OR    ( katalogart = gt_insp_results-qase_katalgart1
            AND   codegruppe = gt_insp_results-qase_gruppe1
            AND   code       = gt_insp_results-qase_code1 ) )
        AND sprache = sy-langu.
      IF sy-subrc = 0.
        SORT gt_qpct BY katalogart codegruppe code version kurztext.
      ENDIF.

      SELECT * FROM tq76t INTO TABLE gt_tq76t
        WHERE sprache = sy-langu.
      IF sy-subrc = 0.
        SORT gt_tq76t BY sprache status.
      ENDIF.

      SELECT * FROM tq73t INTO TABLE gt_tq73t
        WHERE sprsl = sy-langu.
      IF sy-subrc = 0.
        SORT gt_tq73t BY sprsl qergdath.
      ENDIF.

      SELECT * FROM t006a INTO TABLE gt_t006a
       FOR ALL ENTRIES    IN gt_insp_results
         WHERE spras      EQ sy-langu
         AND   msehi      EQ gt_insp_results-qamv_msehi.
      IF sy-subrc = 0.
        SORT gt_t006a.
      ENDIF.

      SORT sel_tab BY prueflos.

      gv_progress_max = lines( sel_tab ).

      CLEAR gv_progress_act.
      CLEAR gv_progress_string.

      LOOP AT  gt_insp_results INTO  gs_insp_results.

        gv_progress_act += 1.

        IF gv_progress_act MOD 100 = 1.

          gv_progress_string = 'Reading operation information'(203).
          gv_progress_percentage = 100 * gv_progress_act /  gv_progress_max.

          CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
            EXPORTING
              percentage = gv_progress_percentage
              text       = gv_progress_string.
*            EXCEPTIONS
*              OTHERS     = 0.
*          IF sy-subrc <> 0.
*            CLEAR sy-subrc.
*          ENDIF.
        ENDIF.

        CLEAR object_tab.

        READ TABLE sel_tab INTO gs_sel_tab
          WITH KEY prueflos = gs_insp_results-prueflos BINARY SEARCH.
        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.

        MOVE-CORRESPONDING gs_sel_tab      TO object_tab.
        MOVE-CORRESPONDING gs_insp_results TO object_tab.

        IF NOT object_tab-qamv_msehi IS INITIAL.
          READ TABLE gt_t006a INTO gs_t006a
                                WITH KEY mandt = sy-mandt
                                         spras = sy-langu
                                         msehi = object_tab-qamv_msehi
                                         BINARY SEARCH.
          IF sy-subrc = 0.
            object_tab-qamv_mseh6       = gs_t006a-mseh6.
            object_tab-qamv_mseht       = gs_t006a-mseht.
            object_tab-qamv_masseinhsw  = gs_t006a-msehi.
          ENDIF.
        ENDIF.

        CASE object_tab-qapp_vbewertung.
          WHEN 'A'.
            object_tab-qapp_vbewertung_icon = icon_checked.
          WHEN 'R'.
            object_tab-qapp_vbewertung_icon = icon_incomplete.
          WHEN OTHERS.
            READ TABLE gt_qasr WITH KEY prueflos = object_tab-prueflos
                                       vorglfnr = object_tab-vorglfnr
                                       probenr  = object_tab-qapp_probenr
                                       BINARY SEARCH TRANSPORTING NO FIELDS.
            IF sy-subrc = 0.
              object_tab-qapp_vbewertung_icon = icon_led_yellow.
            ELSE.
              CLEAR object_tab-qapp_vbewertung_icon.
            ENDIF.
        ENDCASE.
        IF NOT object_tab-qapp_vbewertung IS INITIAL.
          IF object_tab-qapp_aenderer IS INITIAL.
            object_tab-qapp_valuator = object_tab-qapp_ersteller.
          ELSE.
            object_tab-qapp_valuator = object_tab-qapp_aenderer.
          ENDIF.
        ELSE.
          CLEAR object_tab-qapp_valuator.
        ENDIF.

        gv_stellen = object_tab-qamv_stellen.

        IF  NOT object_tab-qamv_grenzob1ni IS INITIAL.
          CALL FUNCTION 'QSS0_FLTP_TO_CHAR_CONVERSION'
            EXPORTING
              i_number_of_digits       = gv_stellen
              i_fltp_value             = object_tab-qamv_grenzeob1
              i_value_not_initial_flag = object_tab-qamv_grenzob1ni
              i_screen_fieldlength     = 16
            IMPORTING
              e_char_field             = object_tab-qamv_grenzeob1c.
        ENDIF.

        IF  NOT object_tab-qamv_grenzun1ni IS INITIAL.
          CALL FUNCTION 'QSS0_FLTP_TO_CHAR_CONVERSION'
            EXPORTING
              i_number_of_digits       = gv_stellen
              i_fltp_value             = object_tab-qamv_grenzeun1
              i_value_not_initial_flag = object_tab-qamv_grenzun1ni
              i_screen_fieldlength     = 16
            IMPORTING
              e_char_field             = object_tab-qamv_grenzeun1c.
        ENDIF.

        IF  NOT object_tab-qamv_plausiobni IS INITIAL.
          CALL FUNCTION 'QSS0_FLTP_TO_CHAR_CONVERSION'
            EXPORTING
              i_number_of_digits       = gv_stellen
              i_fltp_value             = object_tab-qamv_plausioben
              i_value_not_initial_flag = object_tab-qamv_plausiobni
              i_screen_fieldlength     = 16
            IMPORTING
              e_char_field             = object_tab-qamv_plausiobenc.
        ENDIF.

        IF  NOT object_tab-qamv_plausiunni IS INITIAL.
          CALL FUNCTION 'QSS0_FLTP_TO_CHAR_CONVERSION'
            EXPORTING
              i_number_of_digits       = gv_stellen
              i_fltp_value             = object_tab-qamv_plausiunte
              i_value_not_initial_flag = object_tab-qamv_plausiunni
              i_screen_fieldlength     = 16
            IMPORTING
              e_char_field             = object_tab-qamv_plausiuntec.
        ENDIF.

        IF  NOT object_tab-qamv_tolunni IS INITIAL.
          CALL FUNCTION 'QSS0_FLTP_TO_CHAR_CONVERSION'
            EXPORTING
              i_number_of_digits       = gv_stellen
              i_fltp_value             = object_tab-qamv_toleranzun
              i_value_not_initial_flag = object_tab-qamv_tolunni
              i_screen_fieldlength     = 16
            IMPORTING
              e_char_field             = object_tab-qamv_toluntenc.
        ENDIF.

        IF  NOT object_tab-qamv_tolobni IS INITIAL.
          CALL FUNCTION 'QSS0_FLTP_TO_CHAR_CONVERSION'
            EXPORTING
              i_number_of_digits       = gv_stellen
              i_fltp_value             = object_tab-qamv_toleranzob
              i_value_not_initial_flag = object_tab-qamv_tolobni
              i_screen_fieldlength     = 16
            IMPORTING
              e_char_field             = object_tab-qamv_tolobenc.
        ENDIF.

        gv_stellen = object_tab-qamv_stellen + object_tab-qamr_diff_dec_places.

* Ergebnisse auf QAMR Ebene sind nur relevant, wenn es keine Prüfpunkte gibt.
        IF object_tab-stat07 IS INITIAL.
          IF  NOT object_tab-qamr_mittelwni IS INITIAL.
            CALL FUNCTION 'QSS0_FLTP_TO_CHAR_CONVERSION'
              EXPORTING
                i_number_of_digits       = gv_stellen
                i_fltp_value             = object_tab-qamr_mittelwert
                i_value_not_initial_flag = object_tab-qamr_mittelwni
                i_screen_fieldlength     = 16
              IMPORTING
                e_char_field             = object_tab-qamr_mittelwertc.
            object_tab-result =  object_tab-qamr_mittelwertc.
          ENDIF.

          IF  NOT object_tab-qamr_katalgart1 IS INITIAL
          AND NOT object_tab-qamr_gruppe1    IS INITIAL
          AND NOT object_tab-qamr_code1      IS INITIAL
          AND NOT object_tab-qamr_version1   IS INITIAL.
            READ TABLE gt_qpgt INTO gs_qpgt
              WITH KEY katalogart =  object_tab-qamr_katalgart1
                       codegruppe =  object_tab-qamr_gruppe1
              BINARY SEARCH.
            IF sy-subrc = 0.
              object_tab-qamr_gruppe_text = gs_qpgt-kurztext.
            ENDIF.

            READ TABLE gt_qpct INTO gs_qpct
              WITH KEY katalogart =  object_tab-qamr_katalgart1
                       codegruppe =  object_tab-qamr_gruppe1
                       code       =  object_tab-qamr_code1
                       version    =  object_tab-qamr_version1
              BINARY SEARCH.
            IF sy-subrc = 0.
              object_tab-qamr_code_text = gs_qpct-kurztext.
            ENDIF.
            CONCATENATE object_tab-qamr_gruppe_text
                        object_tab-qamr_code_text
                        INTO object_tab-result
                        SEPARATED BY ' - '.

          ENDIF.
        ENDIF.

        TRY.
            gv_stellen = object_tab-qamv_stellen + object_tab-qasr_diff_dec_places.
          CATCH cx_sy_arithmetic_error.
            gv_stellen = object_tab-qamv_stellen.
        ENDTRY.

        IF  NOT object_tab-qasr_mittelwni IS INITIAL.
          CALL FUNCTION 'QSS0_FLTP_TO_CHAR_CONVERSION'
            EXPORTING
              i_number_of_digits       = gv_stellen
              i_fltp_value             = object_tab-qasr_mittelwert
              i_value_not_initial_flag = object_tab-qasr_mittelwni
              i_screen_fieldlength     = 16
            IMPORTING
              e_char_field             = object_tab-qasr_mittelwertc.
          object_tab-result =  object_tab-qasr_mittelwertc.
        ENDIF.


        IF  NOT object_tab-qasr_katalgart1 IS INITIAL
        AND NOT object_tab-qasr_gruppe1    IS INITIAL
        AND NOT object_tab-qasr_code1      IS INITIAL
        AND NOT object_tab-qasr_version1   IS INITIAL.
          READ TABLE gt_qpgt INTO gs_qpgt
            WITH KEY katalogart =  object_tab-qasr_katalgart1
                     codegruppe =  object_tab-qasr_gruppe1
            BINARY SEARCH.
          IF sy-subrc = 0.
            object_tab-qasr_gruppe_text = gs_qpgt-kurztext.
          ENDIF.

          READ TABLE gt_qpct INTO gs_qpct
            WITH KEY katalogart =  object_tab-qasr_katalgart1
                     codegruppe =  object_tab-qasr_gruppe1
                     code       =  object_tab-qasr_code1
                     version    =  object_tab-qasr_version1
            BINARY SEARCH.
          IF sy-subrc = 0.
            object_tab-qasr_code_text = gs_qpct-kurztext.
          ENDIF.
          CONCATENATE object_tab-qasr_gruppe_text
                      object_tab-qasr_code_text
                      INTO object_tab-result
                      SEPARATED BY ' - '.

        ENDIF.

        gv_stellen = object_tab-qamv_stellen + object_tab-qase_diff_dec_places.

        IF  NOT object_tab-qase_messwertni IS INITIAL.
          CALL FUNCTION 'QSS0_FLTP_TO_CHAR_CONVERSION'
            EXPORTING
              i_number_of_digits       = gv_stellen
              i_fltp_value             = object_tab-qase_messwert
              i_value_not_initial_flag = object_tab-qase_messwertni
              i_screen_fieldlength     = 16
            IMPORTING
              e_char_field             = object_tab-qase_messwertc.
          object_tab-result =  object_tab-qase_messwertc.
        ENDIF.

        IF  NOT object_tab-qase_katalgart1 IS INITIAL
        AND NOT object_tab-qase_gruppe1    IS INITIAL
        AND NOT object_tab-qase_code1      IS INITIAL
        AND NOT object_tab-qase_version1   IS INITIAL.
          READ TABLE gt_qpgt INTO gs_qpgt
            WITH KEY katalogart =  object_tab-qase_katalgart1
                     codegruppe =  object_tab-qase_gruppe1
            BINARY SEARCH.
          IF sy-subrc = 0.
            object_tab-qase_gruppe_text = gs_qpgt-kurztext.
          ENDIF.

          READ TABLE gt_qpct INTO gs_qpct
            WITH KEY katalogart =  object_tab-qase_katalgart1
                     codegruppe =  object_tab-qase_gruppe1
                     code       =  object_tab-qase_code1
                     version    =  object_tab-qase_version1
            BINARY SEARCH.
          IF sy-subrc = 0.
            object_tab-qase_code_text = gs_qpct-kurztext.
          ENDIF.
          CONCATENATE object_tab-qase_gruppe_text
                      object_tab-qase_code_text
                      INTO object_tab-result
                      SEPARATED BY ' - '.
        ENDIF.

        READ TABLE gt_tq76t INTO gs_tq76t
          WITH KEY sprache = sy-langu
                   status  = object_tab-qamr_statusr
          BINARY SEARCH         .
        IF sy-subrc = 0.
          object_tab-qamr_statustext = gs_tq76t-kurztext.
        ELSE.
          CLEAR object_tab-qamr_statustext.
        ENDIF.

        READ TABLE gt_tq76t INTO gs_tq76t
          WITH KEY sprache = sy-langu
                   status  = object_tab-qasr_statusr
          BINARY SEARCH         .
        IF sy-subrc = 0.
          object_tab-qasr_statustext = gs_tq76t-kurztext.
        ELSE.
          CLEAR object_tab-qasr_statustext.
        ENDIF.

        READ TABLE gt_tq73t INTO gs_tq73t
          WITH KEY sprsl = sy-langu
                   qergdath  = object_tab-qamr_qergdath
          BINARY SEARCH         .
        IF sy-subrc = 0.
          object_tab-qamr_erdathetxt = gs_tq73t-qergdath.
        ELSE.
          CLEAR object_tab-qamr_erdathetxt.
        ENDIF.

        READ TABLE gt_tq73t INTO gs_tq73t
          WITH KEY sprsl = sy-langu
                   qergdath  = object_tab-qasr_qergdath
          BINARY SEARCH         .
        IF sy-subrc = 0.
          object_tab-qasr_erdathetxt = gs_tq73t-qergdath.
        ELSE.
          CLEAR object_tab-qasr_erdathetxt.
        ENDIF.

        APPEND object_tab.
      ENDLOOP.
    ENDIF.
  ENDIF.

  IF g_submit = 'X'.
    SORT object_tab.
    DELETE ADJACENT DUPLICATES FROM object_tab COMPARING ALL FIELDS.
*   Export Data into memory to allow usage of data table eg in ZQ1U_CAMA_WORKLIST_INSP_LOTS
    EXPORT object_tab TO MEMORY ID g_repid.
  ELSE.
* TESTLAUF is set in DBPGQSEL. It has nothing to do with this report,
* but shows up in the selection criteria popup if it isn't cleared.
    CLEAR testlauf.     " used from logical DB . so naming conventon not followed
    CLEAR g_form_top_of_page.
    CLEAR dy_tcode.   " used from standard top include .so naming convention not followed
    PERFORM fill_events_f14.
    PERFORM fill_event_exit_tab_f14.
    PERFORM fill_layout_f16.
    PERFORM get_fieldcat_actual_f16.
    PERFORM fill_fieldgroups_l.
    PERFORM call_listviewer_f14 USING g_fieldcat_tab[] object_tab[].
  ENDIF.

*---------------------------------------------------------------------*
*       FORM USER_COMMAND_L             called dynamically            *
*---------------------------------------------------------------------*
*       handle locally defined f-codes                               *
*---------------------------------------------------------------------*
*  -->  iv_ucomm                                                       *
*  -->  is_selfield                                                    *
*---------------------------------------------------------------------*
FORM user_command_l USING iv_ucomm    TYPE sy-ucomm
                          is_selfield TYPE slis_selfield.

  DATA: lv_count         TYPE i.
  DATA: lv_name          TYPE thead-tdname.
  DATA: lv_id            TYPE thead-tdid.
  DATA: lv_object        TYPE thead-tdobject.
  DATA: lt_params           TYPE TABLE OF rsparams.

* need to note column and row position for return to list
  is_selfield-col_stable =  gv_x.
  is_selfield-row_stable =  gv_x.
  is_selfield-refresh    =  gv_x.

  IF iv_ucomm(4) = '&IC1'.      "All QM codes have 4 digits. Grid can have more.
    CHECK is_selfield-tabindex > 0.
* Here, if certain fields are double-clicked, different transactions
* are called, e.g. click on insp.lot, QA03 is called. Tables T354T/S.
    READ TABLE object_tab INDEX is_selfield-tabindex.
    CASE is_selfield-fieldname.
      WHEN 'LTEXTICON'
        OR 'LTEXTVEICON'.

        IF is_selfield-fieldname = 'LTEXTICON'.
          CONCATENATE sy-mandt object_tab-prueflos INTO lv_name.
          lv_id     = 'QALS'.
          lv_object = 'QPRUEFLOS'.
        ELSEIF is_selfield-fieldname = 'LTEXTVEICON'.
          CONCATENATE sy-mandt object_tab-prueflos 'L' INTO lv_name.
          lv_id     = 'QAVE'.
          lv_object = 'QPRUEFLOS'.
        ENDIF.
        IF NOT lv_name IS INITIAL.

          CALL FUNCTION 'QSS_TEXT_PROCESSING'
            EXPORTING
              object     = lv_object
              schluessel = lv_name
              sprsl      = object_tab-sprache
              textid     = lv_id
              vkz        = 'PU'
            EXCEPTIONS
              namenew    = 1
              no_name    = 2
              no_object  = 3
              no_sprache = 4
              no_text    = 5
              no_textid  = 6
              no_texttab = 7
              unknown    = 8
              OTHERS     = 9.
          IF sy-subrc <> 0.
* Implement suitable error handling here
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
          ENDIF.
          CLEAR iv_ucomm.
        ENDIF.

      WHEN OTHERS.
    ENDCASE.
  ENDIF.

  CASE iv_ucomm.

    WHEN 'PRZG'.

      is_selfield-refresh =  gv_s.         "rebuild list to set checkmark

      CALL FUNCTION 'AUTHORITY_CHECK_TCODE'
        EXPORTING
          tcode  = 'YQM_CERT'
        EXCEPTIONS
          ok     = 1
          not_ok = 2
          OTHERS = 3.
      IF sy-subrc <> 1.
        MESSAGE e172(00) WITH 'YQM_CERT'.
        RETURN.
      ELSEIF sy-subrc = 1.

*        CLEAR ls_params.
        LOOP AT object_tab WHERE selected = gv_x.

          APPEND VALUE #( selname = 'P_LOS'
                          kind    = 'P'
                          sign    = 'I'
                          option  = 'EQ'
                          low     = object_tab-prueflos
                          high    = space ) TO lt_params.

          APPEND VALUE #( selname = 'P_PRUEF'
                          kind    = 'P'
                          sign    = 'I'
                          option  = 'EQ'
                          low     = object_tab-qapp_usern1
                          high    = space ) TO lt_params.

          SORT lt_params BY selname.
          DELETE ADJACENT DUPLICATES FROM lt_params.

          SUBMIT yqmlims_create_certificate
                 VIA SELECTION-SCREEN
                 WITH SELECTION-TABLE lt_params
                 AND RETURN.

        ENDLOOP.
*--- user has marked 1 item using cursor
        IF NOT sy-subrc IS INITIAL AND
           NOT is_selfield-tabindex IS INITIAL.
          READ TABLE object_tab
          INTO object_tab
               INDEX is_selfield-tabindex.
          IF sy-subrc EQ 0.
*            CLEAR ls_params.

            APPEND VALUE #( selname = 'P_LOS'
                            kind    = 'P'
                            sign    = 'I'
                            option  = 'EQ'
                            low     = object_tab-prueflos
                            high    = space ) TO lt_params.

            APPEND VALUE #( selname = 'P_PRUEF'
                            kind    = 'P'
                            sign    = 'I'
                            option  = 'EQ'
                            low     = object_tab-qapp_usern1
                            high    = space ) TO lt_params.

          ENDIF.

          SORT lt_params BY selname.
          DELETE ADJACENT DUPLICATES FROM lt_params.

          SUBMIT yqmlims_create_certificate
                 VIA SELECTION-SCREEN
                 WITH SELECTION-TABLE lt_params
                 AND RETURN.
        ENDIF.

      ENDIF.

    WHEN 'STATUS'.

      is_selfield-refresh =  gv_s.         "rebuild list to set checkmark

      lv_count = 0.

      LOOP AT object_tab
           WHERE selected = gv_x.
        lv_count += 1.
      ENDLOOP.

*      lv_count = lines( FILTER #( object_tab WHERE selected = gv_x ) ).

      IF lv_count GT 1.
        MESSAGE s213(yqmlims).
        RETURN.
      ENDIF.
*--- user has marked item(s) using checkbox
      LOOP AT object_tab
        WHERE selected =  gv_x.
        object_tab-viewed = sym_check_mark.
        MODIFY object_tab.
        PERFORM execute_fcode_l USING iv_ucomm.
      ENDLOOP.
    WHEN 'DISP'.
      is_selfield-refresh =  gv_s.         "rebuild list
      g_aktyp = 'A'.

*--- call customer function to change ALV settings
      CALL FUNCTION 'IREP1_CHANGE_SETTINGS_ALV'
        EXPORTING
          is_repid            = g_repid
          is_variant          = g_variant
          is_form_top_of_page = 'TOP_OF_PAGE_L'
        CHANGING
          i_grid_inactive     = g_grid
          is_layout           = g_layout
          is_print            = g_print
          it_fieldcat         = g_fieldcat_tab[]
          it_special_groups   = g_fieldgroups_tab[]
          it_list_commentary  = g_listheader_tab[]
          it_event_tab        = g_events_tab[].

      IF g_grid IS INITIAL.

        LOOP AT g_fieldcat_tab INTO DATA(ls_fieldcat_tab)
          WHERE fieldname = 'STTXT'.
          ls_fieldcat_tab-lowercase = gv_x.
          MODIFY g_fieldcat_tab FROM ls_fieldcat_tab.
        ENDLOOP.
        g_layout-colwidth_optimize    = gv_x.
        CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
          EXPORTING
            i_callback_program       = g_repid
            i_callback_pf_status_set = g_form_set_pf_stat
            i_callback_user_command  = g_form_user_command
            is_layout                = g_layout
            it_fieldcat              = g_fieldcat_tab[]
            it_special_groups        = g_fieldgroups_tab[]
            it_sort                  = g_sortfields_tab[]
            i_save                   = g_a
            is_variant               = g_variant
            it_events                = g_events_tab[]
            it_event_exit            = g_event_exit_tab[]
            is_print                 = g_print
            i_screen_start_column    = g_screen_start_column
            i_screen_start_line      = g_screen_start_line
            i_screen_end_column      = g_screen_end_column
            i_screen_end_line        = g_screen_end_line
          TABLES
            t_outtab                 = object_tab
          EXCEPTIONS
            program_error            = 1
            OTHERS                   = 2.
        IF sy-subrc NE 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
      ELSE.
        CALL FUNCTION 'REUSE_ALV_LIST_DISPLAY'
          EXPORTING
            i_callback_program       = g_repid
            i_callback_pf_status_set = g_form_set_pf_stat
            i_callback_user_command  = g_form_user_command
            is_layout                = g_layout
            it_fieldcat              = g_fieldcat_tab[]
            it_special_groups        = g_fieldgroups_tab[]
            it_sort                  = g_sortfields_tab[]
            i_save                   = g_a
            is_variant               = g_variant
            it_events                = g_events_tab[]
            it_event_exit            = g_event_exit_tab[]
            is_print                 = g_print
            i_screen_start_column    = g_screen_start_column
            i_screen_start_line      = g_screen_start_line
            i_screen_end_column      = g_screen_end_column
            i_screen_end_line        = g_screen_end_line
          TABLES
            t_outtab                 = object_tab
          EXCEPTIONS
            program_error            = 1
            OTHERS                   = 2.
        IF sy-subrc NE 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
      ENDIF.
*  End of changes VENKAV11 for CHG0333535.
*      PERFORM call_listviewer_f14 USING g_fieldcat_tab[] object_tab[].
    WHEN 'CHNG'.
      is_selfield-refresh = gv_s.        "rebuild list
      g_aktyp = 'V'.

*--- call customer function to change ALV settings
      CALL FUNCTION 'IREP1_CHANGE_SETTINGS_ALV'
        EXPORTING
          is_repid            = g_repid
          is_variant          = g_variant
          is_form_top_of_page = 'TOP_OF_PAGE_L'
        CHANGING
          i_grid_inactive     = g_grid
          is_layout           = g_layout
          is_print            = g_print
          it_fieldcat         = g_fieldcat_tab[]
          it_special_groups   = g_fieldgroups_tab[]
          it_list_commentary  = g_listheader_tab[]
          it_event_tab        = g_events_tab[].

      IF g_grid IS INITIAL.

        LOOP AT g_fieldcat_tab INTO ls_fieldcat_tab
          WHERE fieldname = 'STTXT'.
          ls_fieldcat_tab-lowercase = 'X'.
          MODIFY g_fieldcat_tab FROM ls_fieldcat_tab.
        ENDLOOP.
        g_layout-colwidth_optimize    = gv_x.
        CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
          EXPORTING
            i_callback_program       = g_repid
            i_callback_pf_status_set = g_form_set_pf_stat
            i_callback_user_command  = g_form_user_command
            is_layout                = g_layout
            it_fieldcat              = g_fieldcat_tab[]
            it_special_groups        = g_fieldgroups_tab[]
            it_sort                  = g_sortfields_tab[]
            i_save                   = g_a
            is_variant               = g_variant
            it_events                = g_events_tab[]
            it_event_exit            = g_event_exit_tab[]
            is_print                 = g_print
            i_screen_start_column    = g_screen_start_column
            i_screen_start_line      = g_screen_start_line
            i_screen_end_column      = g_screen_end_column
            i_screen_end_line        = g_screen_end_line
          TABLES
            t_outtab                 = object_tab
          EXCEPTIONS
            program_error            = 1
            OTHERS                   = 2.
        IF sy-subrc NE 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.

      ELSE.
        CALL FUNCTION 'REUSE_ALV_LIST_DISPLAY'
          EXPORTING
            i_callback_program       = g_repid
            i_callback_pf_status_set = g_form_set_pf_stat
            i_callback_user_command  = g_form_user_command
            is_layout                = g_layout
            it_fieldcat              = g_fieldcat_tab[]
            it_special_groups        = g_fieldgroups_tab[]
            it_sort                  = g_sortfields_tab[]
            i_save                   = g_a
            is_variant               = g_variant
            it_events                = g_events_tab[]
            it_event_exit            = g_event_exit_tab[]
            is_print                 = g_print
            i_screen_start_column    = g_screen_start_column
            i_screen_start_line      = g_screen_start_line
            i_screen_end_column      = g_screen_end_column
            i_screen_end_line        = g_screen_end_line
          TABLES
            t_outtab                 = object_tab
          EXCEPTIONS
            program_error            = 1
            OTHERS                   = 2.
        IF sy-subrc NE 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
      ENDIF.

    WHEN '&OLX'.                       "Select fields in variant
      EXIT.
      CLEAR iv_ucomm.
    WHEN '&OAD'.                       "Select variant
      EXIT.
      CLEAR iv_ucomm.
    WHEN '&OL0'.                       "Create variant
      EXIT.
      CLEAR iv_ucomm.

    WHEN OTHERS.
      IF iv_ucomm = 'ZPLOS'.
        sy-ucomm = iv_ucomm = 'PLOS'.
      ELSEIF iv_ucomm = 'ZVEAZ'.
        sy-ucomm = iv_ucomm = 'VEAZ'.
      ELSEIF iv_ucomm = 'ZQAMV'.
        sy-ucomm = iv_ucomm = 'QAMV'.
      ENDIF.

      PERFORM user_command_f16 USING iv_ucomm is_selfield.
      CLEAR iv_ucomm.
  ENDCASE.

ENDFORM.                               "USER_COMMAND_L
*&---------------------------------------------------------------------*
*&      Form  FILL_FIELDGROUPS_L
*&---------------------------------------------------------------------*
*       define fieldgroups
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM fill_fieldgroups_l.

  DATA: ls_fieldgroups    TYPE slis_sp_group_alv.
  DATA: ls_fieldcat_wa    TYPE slis_fieldcat_alv.
  DATA: lt_dfies_clas     TYPE TABLE OF dfies.
  DATA: lt_dfies_qapo     TYPE TABLE OF dfies.
  DATA: lt_dfies_qapp     TYPE TABLE OF dfies.
  DATA: lt_dfies_results  TYPE TABLE OF dfies.

  CALL FUNCTION 'DDIF_FIELDINFO_GET'
    EXPORTING
      tabname        = 'YQM_CLAS'
    TABLES
      dfies_tab      = lt_dfies_clas
    EXCEPTIONS
      not_found      = 1
      internal_error = 2
      OTHERS         = 3.
  IF sy-subrc = 0.
    SORT lt_dfies_clas BY fieldname.
  ELSE.
    CLEAR lt_dfies_clas.
  ENDIF.

  CALL FUNCTION 'DDIF_FIELDINFO_GET'
    EXPORTING
      tabname        = 'YQM_QAPO'
    TABLES
      dfies_tab      = lt_dfies_qapo
    EXCEPTIONS
      not_found      = 1
      internal_error = 2
      OTHERS         = 3.
  IF sy-subrc = 0.
    SORT lt_dfies_qapo BY fieldname.
  ELSE.
    CLEAR lt_dfies_qapo.
  ENDIF.

  CALL FUNCTION 'DDIF_FIELDINFO_GET'
    EXPORTING
      tabname        = 'YQM_QAPP'
    TABLES
      dfies_tab      = lt_dfies_qapp
    EXCEPTIONS
      not_found      = 1
      internal_error = 2
      OTHERS         = 3.
  IF sy-subrc = 0.
    SORT lt_dfies_qapp BY fieldname.
  ELSE.
    CLEAR lt_dfies_qapp.
  ENDIF.

  CALL FUNCTION 'DDIF_FIELDINFO_GET'
    EXPORTING
      tabname        = 'YQM_RESULTS'
    TABLES
      dfies_tab      = lt_dfies_results
    EXCEPTIONS
      not_found      = 1
      internal_error = 2
      OTHERS         = 3.
  IF sy-subrc = 0.
    SORT lt_dfies_results BY fieldname.
  ELSE.
    CLEAR lt_dfies_results.
  ENDIF.

  ls_fieldgroups-sp_group = 'B'.        "movement data
  ls_fieldgroups-text     = TEXT-gpb .
  APPEND ls_fieldgroups TO g_fieldgroups_tab.

  ls_fieldgroups-sp_group = 'C'.        "Classification  data
  ls_fieldgroups-text     = TEXT-gpc .
  APPEND ls_fieldgroups TO g_fieldgroups_tab.

  ls_fieldgroups-sp_group = 'D'.        "Dates
  ls_fieldgroups-text     = TEXT-gpd .
  APPEND ls_fieldgroups TO g_fieldgroups_tab.

  ls_fieldgroups-sp_group = 'E'.        "Icons
  ls_fieldgroups-text     = TEXT-gpe .
  APPEND ls_fieldgroups TO g_fieldgroups_tab.

  IF  NOT p_qapp  IS INITIAL
  OR  NOT p_ires IS INITIAL.
    ls_fieldgroups-sp_group = 'I'.        "Inspection Point
    ls_fieldgroups-text     = TEXT-gpi .
    APPEND ls_fieldgroups TO g_fieldgroups_tab.
  ENDIF.

  ls_fieldgroups-sp_group = 'K'.        "assignment
  ls_fieldgroups-text     = TEXT-gpk .
  APPEND ls_fieldgroups TO g_fieldgroups_tab.

  ls_fieldgroups-sp_group = 'M'.        "Quantities
  ls_fieldgroups-text     = TEXT-gpm .
  APPEND ls_fieldgroups TO g_fieldgroups_tab.

  IF  NOT p_qapo  IS INITIAL
  OR  NOT p_qapp  IS INITIAL
  OR  NOT p_ires IS INITIAL.
    ls_fieldgroups-sp_group = 'O'.        "Operation
    ls_fieldgroups-text     = TEXT-gpo .
    APPEND ls_fieldgroups TO g_fieldgroups_tab.
  ENDIF.

  ls_fieldgroups-sp_group = 'P'.        "Prüflos
  ls_fieldgroups-text     = TEXT-gpp .
  APPEND ls_fieldgroups TO g_fieldgroups_tab.

  ls_fieldgroups-sp_group = 'Q'.        "Prüfplan
  ls_fieldgroups-text     = TEXT-gpq.
  APPEND ls_fieldgroups TO g_fieldgroups_tab.

  ls_fieldgroups-sp_group = 'R'.        "master Data
  ls_fieldgroups-text     = TEXT-gpr .
  APPEND ls_fieldgroups TO g_fieldgroups_tab.

  ls_fieldgroups-sp_group = 'S'.        "sample
  ls_fieldgroups-text     = TEXT-gps .
  APPEND ls_fieldgroups TO g_fieldgroups_tab.

  ls_fieldgroups-sp_group = 'U'.        "usage Decision
  ls_fieldgroups-text     = TEXT-gpu .
  APPEND ls_fieldgroups TO g_fieldgroups_tab.

  ls_fieldgroups-sp_group = 'V'.        "management
  ls_fieldgroups-text     = TEXT-gpv .
  APPEND ls_fieldgroups TO g_fieldgroups_tab.

  IF NOT p_ires IS INITIAL.
    ls_fieldgroups-sp_group = 'W'.        "Inspection Results
    ls_fieldgroups-text     = TEXT-gpw .
    APPEND ls_fieldgroups TO g_fieldgroups_tab.
  ENDIF.

  ls_fieldgroups-sp_group = 'Z'.        "Counter
  ls_fieldgroups-text     = TEXT-gpz .
  APPEND ls_fieldgroups TO g_fieldgroups_tab.
  LOOP AT g_fieldcat_tab INTO ls_fieldcat_wa.
    CLEAR ls_fieldcat_wa-sp_group.
    CASE ls_fieldcat_wa-fieldname.

* Movement Data
      WHEN 'AUFNR'.
        ls_fieldcat_wa-sp_group = 'B'.
      WHEN 'SA_AUFNR'.
        ls_fieldcat_wa-sp_group = 'B'.
      WHEN 'EBELN'.
        ls_fieldcat_wa-sp_group = 'B'.
      WHEN 'EBELP'.
        ls_fieldcat_wa-sp_group = 'B'.
      WHEN 'BLART'.
        ls_fieldcat_wa-sp_group = 'B'.
      WHEN 'MJAHR'.
        ls_fieldcat_wa-sp_group = 'B'.
      WHEN 'ZEILE'.
        ls_fieldcat_wa-sp_group = 'B'.
      WHEN 'BUDAT'.
        ls_fieldcat_wa-sp_group = 'B'.
      WHEN 'BWART'.
        ls_fieldcat_wa-sp_group = 'B'.
      WHEN 'LS_KDAUF'.
        ls_fieldcat_wa-sp_group = 'B'.
      WHEN 'LS_KDPOS'.
        ls_fieldcat_wa-sp_group = 'B'.
      WHEN 'LS_VBELN'.
        ls_fieldcat_wa-sp_group = 'B'.
      WHEN 'LS_POSNR'.
        ls_fieldcat_wa-sp_group = 'B'.
      WHEN 'LS_ABRVW'.
        ls_fieldcat_wa-sp_group = 'B'.
      WHEN 'LS_ROUTE'.
        ls_fieldcat_wa-sp_group = 'B'.
      WHEN 'LS_LLAND'.
        ls_fieldcat_wa-sp_group = 'B'.
      WHEN 'LS_KUNAG'.
        ls_fieldcat_wa-sp_group = 'B'.
      WHEN 'LS_VKORG'.
        ls_fieldcat_wa-sp_group = 'B'.
      WHEN 'LS_KDMAT'.
        ls_fieldcat_wa-sp_group = 'B'.


* Icons
      WHEN 'LTEXTVEICON'.
        ls_fieldcat_wa-sp_group = 'E'.
      WHEN 'LTEXTICON'.
        ls_fieldcat_wa-sp_group = 'E'.

* Assignment data
      WHEN 'STAT06'.
        ls_fieldcat_wa-sp_group = 'K'.
      WHEN 'AUFNR_CO'.
        ls_fieldcat_wa-sp_group = 'K'.
      WHEN 'KZVBR'.
        ls_fieldcat_wa-sp_group = 'K'.
      WHEN 'KNTTP'.
        ls_fieldcat_wa-sp_group = 'K'.
      WHEN 'KOSTL'.
        ls_fieldcat_wa-sp_group = 'K'.
      WHEN 'AUFPS'.
        ls_fieldcat_wa-sp_group = 'K'.
      WHEN 'ANLN1'.
        ls_fieldcat_wa-sp_group = 'K'.
      WHEN 'ANLN2'.
        ls_fieldcat_wa-sp_group = 'K'.
      WHEN 'PS_PSP_PNR'.
        ls_fieldcat_wa-sp_group = 'K'.
      WHEN 'NPLNR'.
        ls_fieldcat_wa-sp_group = 'K'.
      WHEN 'APLZL'.
        ls_fieldcat_wa-sp_group = 'K'.
      WHEN 'KDAUF'.
        ls_fieldcat_wa-sp_group = 'K'.
      WHEN 'KDPOS'.
        ls_fieldcat_wa-sp_group = 'K'.
      WHEN 'PAOBJNR'.
        ls_fieldcat_wa-sp_group = 'K'.
      WHEN 'PRCTR'.
        ls_fieldcat_wa-sp_group = 'K'.
      WHEN 'GSBER'.
        ls_fieldcat_wa-sp_group = 'K'.
      WHEN 'KONTO'.
        ls_fieldcat_wa-sp_group = 'K'.
      WHEN 'KOKRS'.
        ls_fieldcat_wa-sp_group = 'K'.
      WHEN 'BUKRS'.
        ls_fieldcat_wa-sp_group = 'K'.

* Quantity data
      WHEN 'SOBKZ'.
        ls_fieldcat_wa-sp_group = 'M'.
      WHEN 'WERKVORG'.
        ls_fieldcat_wa-sp_group = 'M'.
      WHEN 'LAGORTVORG'.
        ls_fieldcat_wa-sp_group = 'M'.
      WHEN 'LGNUM'.
        ls_fieldcat_wa-sp_group = 'M'.
      WHEN 'LGTYP'.
        ls_fieldcat_wa-sp_group = 'M'.
      WHEN 'LGPLA'.
        ls_fieldcat_wa-sp_group = 'M'.
      WHEN 'LMENGE01'.
        ls_fieldcat_wa-sp_group = 'M'.
      WHEN 'LMENGE02'.
        ls_fieldcat_wa-sp_group = 'M'.
      WHEN 'LMENGE03'.
        ls_fieldcat_wa-sp_group = 'M'.
      WHEN 'LMENGE04'.
        ls_fieldcat_wa-sp_group = 'M'.
      WHEN 'LMENGE05'.
        ls_fieldcat_wa-sp_group = 'M'.
      WHEN 'LMENGE06'.
        ls_fieldcat_wa-sp_group = 'M'.
      WHEN 'LMENGE07'.
        ls_fieldcat_wa-sp_group = 'M'.
      WHEN 'LMENGE08'.
        ls_fieldcat_wa-sp_group = 'M'.
      WHEN 'LMENGE09'.
        ls_fieldcat_wa-sp_group = 'M'.
      WHEN 'MATNRNEU'.
        ls_fieldcat_wa-sp_group = 'M'.
      WHEN 'CHARGNEU'.
        ls_fieldcat_wa-sp_group = 'M'.
      WHEN 'LMENGEZUB'.
        ls_fieldcat_wa-sp_group = 'M'.
      WHEN 'LMENGELZ'.
        ls_fieldcat_wa-sp_group = 'M'.
      WHEN 'LMENGEPR'.
        ls_fieldcat_wa-sp_group = 'M'.
      WHEN 'LMENGEZER'.
        ls_fieldcat_wa-sp_group = 'M'.
      WHEN 'LMENGEIST'.
        ls_fieldcat_wa-sp_group = 'M'.
      WHEN 'LMENGESCH'.
        ls_fieldcat_wa-sp_group = 'M'.

* Inspection lot
      WHEN 'PRUEFLOS'.
        ls_fieldcat_wa-sp_group = 'P'.
      WHEN 'WERK'.
        ls_fieldcat_wa-sp_group = 'P'.
      WHEN 'ART'.
        ls_fieldcat_wa-sp_group = 'P'.
      WHEN 'HERKUNFT'.
        ls_fieldcat_wa-sp_group = 'P'.
      WHEN 'OBTYP'.
        ls_fieldcat_wa-sp_group = 'P'.
      WHEN 'STSMA'.
        ls_fieldcat_wa-sp_group = 'P'.
      WHEN 'QMATAUTH'.
        ls_fieldcat_wa-sp_group = 'P'.
      WHEN 'STAT11'.
        ls_fieldcat_wa-sp_group = 'P'.
      WHEN 'INSMK'.
        ls_fieldcat_wa-sp_group = 'P'.
      WHEN 'STAT09'.
        ls_fieldcat_wa-sp_group = 'P'.
      WHEN 'STAT19'.
        ls_fieldcat_wa-sp_group = 'P'.
      WHEN 'STAT23'.
        ls_fieldcat_wa-sp_group = 'P'.
      WHEN 'STAT24'.
        ls_fieldcat_wa-sp_group = 'P'.
      WHEN 'STAT25'.
        ls_fieldcat_wa-sp_group = 'P'.
      WHEN 'DYNHEAD'.
        ls_fieldcat_wa-sp_group = 'P'.
      WHEN 'STPRVER'.
        ls_fieldcat_wa-sp_group = 'P'.
      WHEN 'SPRACHE'.
        ls_fieldcat_wa-sp_group = 'P'.
      WHEN 'KTEXTLOS'.
        ls_fieldcat_wa-sp_group = 'P'.
      WHEN 'KTEXTMAT'.
        ls_fieldcat_wa-sp_group = 'P'.
      WHEN 'LOSMENGE'.
        ls_fieldcat_wa-sp_group = 'P'.
      WHEN 'MENGENEINH'.
        ls_fieldcat_wa-sp_group = 'P'.
      WHEN 'ANZGEB'.
        ls_fieldcat_wa-sp_group = 'P'.
      WHEN 'GEBEH'.
        ls_fieldcat_wa-sp_group = 'P'.
      WHEN 'SERNP'.
        ls_fieldcat_wa-sp_group = 'P'.
      WHEN 'YQM_TPLNR'.
        ls_fieldcat_wa-sp_group = 'P'.
      WHEN 'YQM_PROBEDATUM'.
        ls_fieldcat_wa-sp_group = 'P'.
      WHEN 'YQM_PROBEZEIT'.
        ls_fieldcat_wa-sp_group = 'P'.
      WHEN 'YQM_PROBENEHMER03'.
        ls_fieldcat_wa-sp_group = 'P'.
      WHEN 'YQM_PROBENEHMER40'.
        ls_fieldcat_wa-sp_group = 'P'.
      WHEN 'YQM_PROBEEINGANG'.
        ls_fieldcat_wa-sp_group = 'P'.
      WHEN 'YQM_BERICHTNR'.
        ls_fieldcat_wa-sp_group = 'P'.
      WHEN 'YQM_KZ_COST'.
        ls_fieldcat_wa-sp_group = 'P'.
      WHEN 'YQM_CO_BELEG'.
        ls_fieldcat_wa-sp_group = 'P'.
      WHEN 'YQM_CO_BELEG_DATUM'.
        ls_fieldcat_wa-sp_group = 'P'.
      WHEN 'YQM_UEBERWACHUNG'.
        ls_fieldcat_wa-sp_group = 'P'.
      WHEN 'YQM_PROBENGEWINNUNG'.
        ls_fieldcat_wa-sp_group = 'P'.
      WHEN 'YQM_PROBENAHMEART'.
        ls_fieldcat_wa-sp_group = 'P'.
      WHEN 'YQM_ANLASS'.
        ls_fieldcat_wa-sp_group = 'P'.
      WHEN 'YQM_KUNNRZL'.
        ls_fieldcat_wa-sp_group = 'P'.
      WHEN 'YQM_VNLPV'.
        ls_fieldcat_wa-sp_group = 'P'.
      WHEN 'YQM_VNLPVKT'.
        ls_fieldcat_wa-sp_group = 'P'.
      WHEN 'YQM_PNZWK'.
        ls_fieldcat_wa-sp_group = 'P'.
      WHEN 'YQM_QPHYSPRNR'.
        ls_fieldcat_wa-sp_group = 'P'.
      WHEN 'YQM_QPBVERSION'.
        ls_fieldcat_wa-sp_group = 'P'.

* Inspection plan
      WHEN 'PLNTY'.
        ls_fieldcat_wa-sp_group = 'Q'.
      WHEN 'PLNNR'.
        ls_fieldcat_wa-sp_group = 'Q'.
      WHEN 'PPLVERW'.
        ls_fieldcat_wa-sp_group = 'Q'.
      WHEN 'PLNAL'.
        ls_fieldcat_wa-sp_group = 'Q'.
      WHEN 'SLWBEZ'.
        ls_fieldcat_wa-sp_group = 'Q'.
      WHEN 'STAT13'.
        ls_fieldcat_wa-sp_group = 'Q'.
      WHEN 'SELMATNR'.
        ls_fieldcat_wa-sp_group = 'Q'.
      WHEN 'SELREVLV'.
        ls_fieldcat_wa-sp_group = 'Q'.
      WHEN 'SELWERK'.
        ls_fieldcat_wa-sp_group = 'Q'.
      WHEN 'SELLIFNR'.
        ls_fieldcat_wa-sp_group = 'Q'.
      WHEN 'SELHERST'.
        ls_fieldcat_wa-sp_group = 'Q'.
      WHEN 'SELKUNNR'.
        ls_fieldcat_wa-sp_group = 'Q'.
      WHEN 'SELPPLVERW'.
        ls_fieldcat_wa-sp_group = 'Q'.
      WHEN 'GUELTIGAB'.
        ls_fieldcat_wa-sp_group = 'Q'.

* Master Data
      WHEN 'KUNNR'.
        ls_fieldcat_wa-sp_group = 'R'.
      WHEN 'LIFNR'.
        ls_fieldcat_wa-sp_group = 'R'.
      WHEN 'HERSTELLER'.
        ls_fieldcat_wa-sp_group = 'R'.
      WHEN 'EMATNR'.
        ls_fieldcat_wa-sp_group = 'R'.
      WHEN 'MATNR'.
        ls_fieldcat_wa-sp_group = 'R'.
      WHEN 'REVLV'.
        ls_fieldcat_wa-sp_group = 'R'.
      WHEN 'CHARG'.
        ls_fieldcat_wa-sp_group = 'R'.
      WHEN 'LAGORTCHRG'.
        ls_fieldcat_wa-sp_group = 'R'.
      WHEN 'EKORG'.
        ls_fieldcat_wa-sp_group = 'R'.
      WHEN 'MHDRZ'.
        ls_fieldcat_wa-sp_group = 'R'.
      WHEN 'MHDHB'.
        ls_fieldcat_wa-sp_group = 'R'.
      WHEN 'IPRKZ'.
        ls_fieldcat_wa-sp_group = 'R'.
      WHEN 'RDMHD'.
        ls_fieldcat_wa-sp_group = 'R'.
      WHEN 'MHDLP'.
        ls_fieldcat_wa-sp_group = 'R'.
      WHEN 'VFDAT'.
        ls_fieldcat_wa-sp_group = 'R'.
      WHEN 'FVDT1'.
        ls_fieldcat_wa-sp_group = 'R'.
      WHEN 'FVDT4'.
        ls_fieldcat_wa-sp_group = 'R'.
      WHEN 'IDNLF'.
        ls_fieldcat_wa-sp_group = 'R'.
      WHEN 'LICHN'.
        ls_fieldcat_wa-sp_group = 'R'.
      WHEN 'ZPRCTR1'.
        ls_fieldcat_wa-sp_group = 'R'.
      WHEN 'QMATA'.
        ls_fieldcat_wa-sp_group = 'R'.
      WHEN 'QMNUM'.
        ls_fieldcat_wa-sp_group = 'R'.
      WHEN 'MAABC'.
        ls_fieldcat_wa-sp_group = 'R'.
      WHEN 'BSCOD'.
        ls_fieldcat_wa-sp_group = 'R'.
      WHEN 'SERNR'.
        ls_fieldcat_wa-sp_group = 'R'.
      WHEN 'ZUSCH'.
        ls_fieldcat_wa-sp_group = 'R'.

* Sample data
      WHEN 'GESSTICHPR'.
        ls_fieldcat_wa-sp_group = 'S'.
      WHEN 'EINHPROBE'.
        ls_fieldcat_wa-sp_group = 'S'.
      WHEN 'DYNREGEL'.
        ls_fieldcat_wa-sp_group = 'S'.
      WHEN 'STAT44'.
        ls_fieldcat_wa-sp_group = 'S'.
      WHEN 'PRSTUFE'.
        ls_fieldcat_wa-sp_group = 'S'.
      WHEN 'PRSCHAERFE'.
        ls_fieldcat_wa-sp_group = 'S'.
      WHEN 'STAT12'.
        ls_fieldcat_wa-sp_group = 'S'.
      WHEN 'PRBNAVERF'.
        ls_fieldcat_wa-sp_group = 'S'.
      WHEN 'PRBNAVV'.
        ls_fieldcat_wa-sp_group = 'S'.

* Usage Decision
      WHEN 'VBEWERTUNG'.
        ls_fieldcat_wa-sp_group = 'U'.
      WHEN 'QKENNZAHL'.
        ls_fieldcat_wa-sp_group = 'U'.
      WHEN 'DBEWERTUNG'.
        ls_fieldcat_wa-sp_group = 'U'.
      WHEN 'VFOLGEAKTI'.
        ls_fieldcat_wa-sp_group = 'U'.
      WHEN 'VNAME'.
        ls_fieldcat_wa-sp_group = 'U'.
      WHEN 'VDATUM'.
        ls_fieldcat_wa-sp_group = 'U'.
      WHEN 'VEZEITERF'.
        ls_fieldcat_wa-sp_group = 'U'.
      WHEN 'VAENAME'.
        ls_fieldcat_wa-sp_group = 'U'.
      WHEN 'VAEDATUM'.
        ls_fieldcat_wa-sp_group = 'U'.
      WHEN 'VEZEITAEN'.
        ls_fieldcat_wa-sp_group = 'U'.
      WHEN 'KZART'.
        ls_fieldcat_wa-sp_group = 'U'.
      WHEN 'VKATART'.
        ls_fieldcat_wa-sp_group = 'U'.
      WHEN 'VAUSWAHLMG'.
        ls_fieldcat_wa-sp_group = 'U'.
      WHEN 'VCODEGRP'.
        ls_fieldcat_wa-sp_group = 'U'.
      WHEN 'VCODE'.
        ls_fieldcat_wa-sp_group = 'U'.
      WHEN 'VELONGTEXT'.
        ls_fieldcat_wa-sp_group = 'U'.

* Administration
      WHEN 'ENSTEHDAT'.
        ls_fieldcat_wa-sp_group = 'V'.
      WHEN 'ENTSTEZEIT'.
        ls_fieldcat_wa-sp_group = 'V'.
      WHEN 'ERSTELLER'.
        ls_fieldcat_wa-sp_group = 'V'.
      WHEN 'ERSTELDAT'.
        ls_fieldcat_wa-sp_group = 'V'.
      WHEN 'ERSTELZEIT'.
        ls_fieldcat_wa-sp_group = 'V'.
      WHEN 'AENDERER'.
        ls_fieldcat_wa-sp_group = 'V'.
      WHEN 'AENDERDAT'.
        ls_fieldcat_wa-sp_group = 'V'.
      WHEN 'AENDERZEIT'.
        ls_fieldcat_wa-sp_group = 'V'.
      WHEN 'PASTRTERM'.
        ls_fieldcat_wa-sp_group = 'V'.
      WHEN 'PASTRZEIT'.
        ls_fieldcat_wa-sp_group = 'V'.
      WHEN 'PAENDTERM'.
        ls_fieldcat_wa-sp_group = 'V'.
      WHEN 'PAENDZEIT'.
        ls_fieldcat_wa-sp_group = 'V'.

* Counter
      WHEN 'ZUSMKZAEHL'.
        ls_fieldcat_wa-sp_group = 'Z'.
      WHEN 'OFFENNLZMK'.
        ls_fieldcat_wa-sp_group = 'Z'.
      WHEN 'OFFEN_LZMK'.
        ls_fieldcat_wa-sp_group = 'Z'.
      WHEN 'ANTEIL'.
        ls_fieldcat_wa-sp_group = 'Z'.
      WHEN 'QPMATLOS'.
        ls_fieldcat_wa-sp_group = 'Z'.

* Fields that need not be displayed
      WHEN 'OBJNR'.
        ls_fieldcat_wa-tech = gv_x.
      WHEN 'STAT05'.                   " Field has no name
        ls_fieldcat_wa-tech = gv_x.
      WHEN 'STAT16'.                   " Field has no name
        ls_fieldcat_wa-tech = gv_x.
      WHEN 'VORGLFNR'.                 " Ongoing Knotenummer
        ls_fieldcat_wa-tech = gv_x.
      WHEN 'LTEXTKZ'.
        ls_fieldcat_wa-tech = gv_x.
      WHEN 'LTEXTKZVE'.
        ls_fieldcat_wa-tech = gv_x.

      WHEN OTHERS.

        READ TABLE lt_dfies_clas
          TRANSPORTING NO FIELDS
          WITH KEY fieldname = ls_fieldcat_wa-fieldname
          BINARY SEARCH.
        IF sy-subrc = 0.
          ls_fieldcat_wa-sp_group = 'C'.
        ENDIF.

        READ TABLE lt_dfies_qapo
          TRANSPORTING NO FIELDS
          WITH KEY fieldname = ls_fieldcat_wa-fieldname
          BINARY SEARCH.
        IF sy-subrc = 0.
          ls_fieldcat_wa-sp_group = 'O'.
        ENDIF.

        READ TABLE lt_dfies_qapp
          TRANSPORTING NO FIELDS
          WITH KEY fieldname = ls_fieldcat_wa-fieldname
          BINARY SEARCH.
        IF sy-subrc = 0.
          ls_fieldcat_wa-sp_group = 'I'.
        ENDIF.

        READ TABLE lt_dfies_results
          TRANSPORTING NO FIELDS
          WITH KEY fieldname = ls_fieldcat_wa-fieldname
          BINARY SEARCH.
        IF sy-subrc = 0.
          ls_fieldcat_wa-sp_group = 'W'.
        ENDIF.

        CLEAR gv_var.
    ENDCASE.

    MODIFY g_fieldcat_tab FROM ls_fieldcat_wa.
  ENDLOOP.
ENDFORM.                               " FILL_FIELDGROUPS_L
*---------------------------------------------------------------------*
*       FORM CREATE_FIELDCAT_L                                        *
*---------------------------------------------------------------------*
*       create g_fieldcat_tab for DDIC structure                      *
*---------------------------------------------------------------------*
*  -->  TABNAME  (DDIC-Structure for Report-Output)                   *
*---------------------------------------------------------------------*
FORM create_fieldcat_l   USING iv_tabname TYPE slis_tabname.

  DATA: ls_fieldcat_wa TYPE slis_fieldcat_alv.
  DATA: lv_index       TYPE sy-tabix.
  DATA: lt_dfies       TYPE TABLE OF dfies.

  IF gt_field_text[] IS INITIAL.
    SELECT mandt repid tabname fieldname reptext
           scrtext_s scrtext_m scrtext_l no_out
      FROM yqm_rtext_t
      INTO TABLE gt_field_text
      WHERE repid = g_repid.
    IF sy-subrc = 0.
      SORT gt_field_text BY repid tabname fieldname.
    ELSE.
      CLEAR gt_field_text.
    ENDIF.
  ENDIF.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      i_program_name         = g_repid
      i_internal_tabname     = 'object_tab'
      i_structure_name       = iv_tabname
      i_client_never_display = ' '
    CHANGING
      ct_fieldcat            = g_fieldcat_tab[]
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.

  IF sy-subrc IS INITIAL.
    SORT g_fieldcat_tab BY key DESCENDING.
    lv_index = 1.
    DO.
*--- change key fields to 'normal' fields
      READ TABLE g_fieldcat_tab INTO ls_fieldcat_wa INDEX lv_index.
      IF sy-subrc IS INITIAL AND ls_fieldcat_wa-key = gv_x.
        ls_fieldcat_wa-key = space.
        MODIFY g_fieldcat_tab FROM ls_fieldcat_wa INDEX lv_index.
        lv_index = lv_index + 1.
      ELSE.
        EXIT.
*        RETURN.
      ENDIF.
    ENDDO.
    g_layout-colwidth_optimize    = gv_x.

    IF  p_qapo  IS INITIAL
    AND p_qapp  IS INITIAL
    AND p_ires IS INITIAL.

      CALL FUNCTION 'DDIF_FIELDINFO_GET'
        EXPORTING
          tabname        = 'YQM_QAPO'
        TABLES
          dfies_tab      = lt_dfies
        EXCEPTIONS
          not_found      = 1
          internal_error = 2
          OTHERS         = 3.
      IF sy-subrc = 0.
        SORT lt_dfies BY fieldname.
        LOOP AT g_fieldcat_tab INTO ls_fieldcat_wa.
          READ TABLE lt_dfies
            TRANSPORTING NO FIELDS
            WITH KEY fieldname = ls_fieldcat_wa-fieldname
            BINARY SEARCH.
          IF sy-subrc = 0.
            DELETE TABLE g_fieldcat_tab FROM ls_fieldcat_wa.
          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDIF.

    IF  p_qapp  IS INITIAL
    AND p_ires IS INITIAL.
      CALL FUNCTION 'DDIF_FIELDINFO_GET'
        EXPORTING
          tabname        = 'YQM_QAPP'
        TABLES
          dfies_tab      = lt_dfies
        EXCEPTIONS
          not_found      = 1
          internal_error = 2
          OTHERS         = 3.
      IF sy-subrc = 0.
        SORT lt_dfies BY fieldname.
        LOOP AT g_fieldcat_tab INTO ls_fieldcat_wa.
          READ TABLE lt_dfies
            TRANSPORTING NO FIELDS
            WITH KEY fieldname = ls_fieldcat_wa-fieldname
            BINARY SEARCH.
          IF sy-subrc = 0.
            DELETE TABLE g_fieldcat_tab FROM ls_fieldcat_wa.
          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDIF.

    IF p_ires IS INITIAL.
      CALL FUNCTION 'DDIF_FIELDINFO_GET'
        EXPORTING
          tabname        = 'YQM_RESULTS'
        TABLES
          dfies_tab      = lt_dfies
        EXCEPTIONS
          not_found      = 1
          internal_error = 2
          OTHERS         = 3.
      IF sy-subrc = 0.
        SORT lt_dfies BY fieldname.
        LOOP AT g_fieldcat_tab INTO ls_fieldcat_wa.
          READ TABLE lt_dfies
            TRANSPORTING NO FIELDS
            WITH KEY fieldname = ls_fieldcat_wa-fieldname
            BINARY SEARCH.
          IF sy-subrc = 0.
            DELETE TABLE g_fieldcat_tab FROM ls_fieldcat_wa.
          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDIF.

* add column 'viewed' to field catalog.
    PERFORM add_viewed_column_f14.

    LOOP AT g_fieldcat_tab INTO ls_fieldcat_wa.

      IF ls_fieldcat_wa-fieldname = 'VIEWED'.
        ls_fieldcat_wa-seltext_l = TEXT-vd1.
        ls_fieldcat_wa-seltext_s = TEXT-vd2.
        ls_fieldcat_wa-ddictxt   = 'S'.
        MODIFY g_fieldcat_tab FROM ls_fieldcat_wa.

      ELSEIF ls_fieldcat_wa-fieldname(3) = 'SEL'.
        ls_fieldcat_wa-tech = abap_true.   "oder 'X' wenn das Feld CHAR1 ist
        MODIFY g_fieldcat_tab FROM ls_fieldcat_wa.

      ELSEIF ls_fieldcat_wa-fieldname = 'LTEXTICON'.
        ls_fieldcat_wa-icon    = abap_true.  "oder 'X'
        ls_fieldcat_wa-hotspot = abap_true.  "oder 'X'
        MODIFY g_fieldcat_tab FROM ls_fieldcat_wa.

      ELSEIF ls_fieldcat_wa-fieldname = 'LTEXTVEICON'.
        ls_fieldcat_wa-icon    = abap_true.  "oder 'X'
        ls_fieldcat_wa-hotspot = abap_true.  "oder 'X'
        MODIFY g_fieldcat_tab FROM ls_fieldcat_wa.

      ELSE.


* Replace SAP standard label text with report specific text labels
        READ TABLE gt_field_text INTO gs_field_text
          WITH KEY repid     = g_repid
                   tabname   = 'YQM_WORKLIST'
                   fieldname = ls_fieldcat_wa-fieldname
          BINARY SEARCH.
        IF sy-subrc = 0.
          IF NOT gs_field_text-scrtext_l IS INITIAL.
            ls_fieldcat_wa-seltext_l    = gs_field_text-scrtext_l.
          ENDIF.
          IF NOT gs_field_text-scrtext_m IS INITIAL.
            ls_fieldcat_wa-seltext_m    = gs_field_text-scrtext_m.
          ENDIF.
          IF NOT gs_field_text-scrtext_s IS INITIAL.
            ls_fieldcat_wa-seltext_s    = gs_field_text-scrtext_s.
          ENDIF.
          IF NOT gs_field_text-reptext   IS INITIAL.
            ls_fieldcat_wa-reptext_ddic = gs_field_text-reptext.
          ENDIF.
          ls_fieldcat_wa-tech         = gs_field_text-no_out.
          ls_fieldcat_wa-no_out       = gs_field_text-no_out.
          MODIFY g_fieldcat_tab FROM ls_fieldcat_wa.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDIF.

ENDFORM.                               " CREATE_FIELDCAT_L

*&---------------------------------------------------------------------*
*&      Form  SET_PF_STATUS_L
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM set_pf_stat_l  USING et_extab TYPE slis_t_extab.

*--- Secure Tcode from parameter passing -----------------------------*
  IF gv_tcode IS INITIAL.
    IF dy_tcode IS INITIAL.   " Naming convention not followe because
      "it is declared in Standard include RQALVTOP
      gv_tcode = sy-tcode.
    ELSE.
      gv_tcode = dy_tcode.
    ENDIF.
  ENDIF.
  dy_tcode = gv_tcode.

*  SET TITLEBAR 'LVS'.

*   Prüflos
  CALL FUNCTION 'QAUT_CHECK_TCODE'
    EXPORTING
      i_tcode          = 'QA03'
    EXCEPTIONS
      auth_destroyed   = 1
      internal_error   = 2
      no_authorization = 3
      OTHERS           = 4.
  IF NOT sy-subrc IS INITIAL.
    APPEND 'PLOS' TO et_extab.
  ENDIF.
*   usage Decision
  CALL FUNCTION 'QAUT_CHECK_TCODE'
    EXPORTING
      i_tcode          = 'QA13'
    EXCEPTIONS
      auth_destroyed   = 1
      internal_error   = 2
      no_authorization = 3
      OTHERS           = 4.
  IF NOT sy-subrc IS INITIAL.
    CALL FUNCTION 'QAUT_CHECK_TCODE'
      EXPORTING
        i_tcode          = 'QA13'
      EXCEPTIONS
        auth_destroyed   = 1
        internal_error   = 2
        no_authorization = 3
        OTHERS           = 4.
    IF NOT sy-subrc IS INITIAL.
      APPEND 'VEAZ' TO et_extab.
    ENDIF.
  ENDIF.
*   results
  CALL FUNCTION 'QAUT_CHECK_TCODE'
    EXPORTING
      i_tcode          = 'QE01'
    EXCEPTIONS
      auth_destroyed   = 1
      internal_error   = 2
      no_authorization = 3
      OTHERS           = 4.
  IF NOT sy-subrc IS INITIAL.
    CALL FUNCTION 'QAUT_CHECK_TCODE'
      EXPORTING
        i_tcode          = 'QE11'
      EXCEPTIONS
        auth_destroyed   = 1
        internal_error   = 2
        no_authorization = 3
        OTHERS           = 4.
    IF NOT sy-subrc IS INITIAL.
      CALL FUNCTION 'QAUT_CHECK_TCODE'
        EXPORTING
          i_tcode          = 'QE14'
        EXCEPTIONS
          auth_destroyed   = 1
          internal_error   = 2
          no_authorization = 3
          OTHERS           = 4.
      IF NOT sy-subrc IS INITIAL.
        APPEND 'TAMV' TO et_extab.
      ENDIF.
    ENDIF.
  ENDIF.
  IF sy-ucomm = 'DISP'.
    gv_flag = 'D'.
    READ TABLE et_extab INTO DATA(ls_extab) WITH KEY
     fcode = '&NFO'.
    IF sy-subrc = 0.
      DELETE TABLE et_extab FROM ls_extab .
    ENDIF.
    SET PF-STATUS 'MAIN' OF PROGRAM 'YQMLIMS_RESULTS_OVERVIEW'
        EXCLUDING et_extab.
  ELSEIF sy-ucomm = 'CHNG'.
    gv_flag = 'C'.
    READ TABLE et_extab INTO ls_extab WITH KEY
     fcode = '&NFO'.
    IF sy-subrc = 0.
      DELETE TABLE et_extab FROM ls_extab .
    ENDIF.
    SET PF-STATUS 'MAIN' OF PROGRAM 'YQMLIMS_RESULTS_OVERVIEW'
        EXCLUDING et_extab.
  ELSEIF gv_flag = 'D' AND
      ( sy-ucomm = 'PLOS' OR sy-ucomm = 'VEAZ' OR sy-ucomm = 'QAMV' ).
    SET PF-STATUS 'MAIN' OF PROGRAM 'YQMLIMS_RESULTS_OVERVIEW'
        EXCLUDING et_extab.
  ELSEIF gv_flag = 'C'  AND
      ( sy-ucomm = 'PLOS' OR sy-ucomm = 'VEAZ' OR sy-ucomm = 'QAMV' ).
    SET PF-STATUS 'MAIN' OF PROGRAM 'YQMLIMS_RESULTS_OVERVIEW'
        EXCLUDING et_extab.
  ELSEIF gv_flag IS INITIAL.
    READ TABLE et_extab INTO ls_extab WITH KEY
     fcode = '&NFO'.
    IF sy-subrc = 0.
      DELETE TABLE et_extab FROM ls_extab .
    ENDIF.
    SET PF-STATUS 'MAIN' OF PROGRAM 'YQMLIMS_RESULTS_OVERVIEW'
        EXCLUDING et_extab.
  ELSEIF sy-ucomm = '&F03'.
    LEAVE TO SCREEN 0.
  ENDIF.
ENDFORM.                               " SET_PF_STATUS_L

*&---------------------------------------------------------------------*
*&      Form  CALL_TA
*&---------------------------------------------------------------------*
*   Authorization check and call transaction with SKIP FIRST SCREEN  *
*----------------------------------------------------------------------*
*  -->  p_tcode   Transaction code
*----------------------------------------------------------------------*
FORM call_ta USING iv_tcode TYPE sytcode.

  CALL FUNCTION 'QAUT_CHECK_TCODE'
    EXPORTING
      i_tcode          = iv_tcode
    EXCEPTIONS
      auth_destroyed   = 1
      internal_error   = 2
      no_authorization = 3
      OTHERS           = 4.
  IF sy-subrc EQ 0.
    CALL TRANSACTION iv_tcode AND SKIP FIRST SCREEN.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  EXECUTE_FCODE_L
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM execute_fcode_l USING iv_ucomm TYPE syucomm.

  DATA: lv_vornr   TYPE qapo-vornr.

  CASE iv_ucomm.
*   Results
    WHEN 'QAMV'.
      IF object_tab-obtyp NE 'QL1'.
        MESSAGE i181(qe) WITH object_tab-prueflos.
      ELSE.
        CALL FUNCTION 'QELA_INSPECTION_OPERATION_LIST'
          EXPORTING
            aufpl            = object_tab-aufpl
            i_plnty          = object_tab-plnty
            losnummer        = object_tab-prueflos
          IMPORTING
            vornr            = lv_vornr
          EXCEPTIONS
            no_data_found    = 01
            no_data_selected = 02.
        IF sy-subrc NE 0.
          MESSAGE i181(qe) WITH object_tab-prueflos.
        ELSE.
          SET PARAMETER ID 'QLS' FIELD object_tab-prueflos.
          SET PARAMETER ID 'QVO' FIELD lv_vornr.
          IF object_tab-stat07 NE space.
*         Checkpoints
*  Code Profiler Fix Begins
            CALL FUNCTION 'AUTHORITY_CHECK_TCODE'
              EXPORTING
                tcode  = 'QE11'
              EXCEPTIONS
                ok     = 1
                not_ok = 2
                OTHERS = 3.
            IF sy-subrc EQ 1.
              CALL TRANSACTION 'QE11' AND SKIP FIRST SCREEN.
            ENDIF.
* Code Profiler Fix ends
          ELSEIF object_tab-stat02 NE space.
*         Teillose
*  Code Profiler Fix Begins
            CALL FUNCTION 'AUTHORITY_CHECK_TCODE'
              EXPORTING
                tcode  = 'QE14'
              EXCEPTIONS
                ok     = 1
                not_ok = 2
                OTHERS = 3.
            IF sy-subrc EQ 1.
              CALL TRANSACTION 'QE14' AND SKIP FIRST SCREEN.
            ENDIF.
* Code Profiler Fix ends
          ELSE.
* The Rest
* Code Profiler Fix Begins
            CALL FUNCTION 'AUTHORITY_CHECK_TCODE'
              EXPORTING
                tcode  = 'QE01'
              EXCEPTIONS
                ok     = 1
                not_ok = 2
                OTHERS = 3.
            IF sy-subrc EQ 1.
              CALL TRANSACTION 'QE01' AND SKIP FIRST SCREEN.
            ENDIF.
* Code Profiler Fix ends
          ENDIF.
        ENDIF.
      ENDIF.
* error detection
    WHEN 'QMEL'.
      SET PARAMETER ID 'QLS' FIELD object_tab-prueflos.
* Already exists error
      CALL FUNCTION 'STATUS_CHECK'
        EXPORTING
          objnr             = object_tab-objnr
          status            = 'I0214'
        EXCEPTIONS
          object_not_found  = 01
          status_not_active = 02.
      IF sy-subrc IS INITIAL.
*         there are errors
        PERFORM call_ta USING 'QF02'  .
      ELSE.
*         Report is not filled
        PERFORM call_ta USING 'QF01'  .
      ENDIF.


    WHEN OTHERS.
      CLEAR gv_var.
  ENDCASE.
ENDFORM.                                            " EXECUTE_FCODE_L


*--------------------------------------------------------------------*
* And finally, the INCLUDES....                                      *
*--------------------------------------------------------------------*
INCLUDE rqalvf14.
INCLUDE rqalvf16.
INCLUDE rq00mf10.
*&---------------------------------------------------------------------*
*&      Form  CHECK_VARIANT_MAINTAIN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM check_variant_maintain.

  DATA:
    lv_submitinfo  TYPE rssubinfo.

  CALL FUNCTION 'RS_SUBMIT_INFO'
    IMPORTING
      p_submit_info = lv_submitinfo.

  IF lv_submitinfo-mode_vari IS INITIAL.
    LOOP AT SCREEN.
      IF screen-group1 EQ 'PRG'.
* p_var maintenance, then field 'P_SCRMAN' ready for input
        screen-active = '0'.
        MODIFY SCREEN.
      ENDIF.
      IF screen-group1 EQ 'SIP'.
* Variant maintenance, then field 'P_SIN_PR' ready for input
        screen-active = '0'.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.

ENDFORM.                               " CHECK_VARIANT_MAINTAIN

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
*&      Form  PREPARE_DYNAMIC_SELECTS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM prepare_dynamic_selects .

  DATA: ls_range TYPE rsds_frange.

* Returns values of the dynamic selections (selection screen)
  CALL FUNCTION 'RS_REFRESH_FROM_DYNAMICAL_SEL'
    EXPORTING
      curr_report        = g_repid
      mode_write_or_move = 'M'
    IMPORTING
      p_trange           = gt_trange
    EXCEPTIONS
      not_found          = 1
      wrong_type         = 2
      OTHERS             = 3.
  IF sy-subrc = 0.
    gt_trange_h[] = gt_trange[].
    LOOP AT gt_trange_h INTO gs_trange.
      LOOP AT gs_trange-frange_t INTO ls_range.
        IF gs_trange-tablename = 'QAPO'
        OR gs_trange-tablename = 'AFVC'.
          IF     ls_range-fieldname = 'WERKS'.
            ql_prwrk[] = ls_range-selopt_t[].
            DELETE gs_trange-frange_t INDEX sy-tabix." FROM gs_trange.
            CONTINUE.
          ELSEIF ls_range-fieldname = 'ARBID'.
            ql_prplz[] = ls_range-selopt_t[].
            DELETE gs_trange-frange_t INDEX sy-tabix. "FROM gs_trange.
            CONTINUE.
          ELSEIF ls_range-fieldname = 'VORKTXT'.
            ls_range-fieldname      = 'LTXA1'.
          ELSEIF ls_range-fieldname = 'VORSTEUS'.
            ls_range-fieldname      = 'STEUS'.
          ENDIF.
          gs_trange-tablename = 'AFVC'.
        ENDIF.
        CONCATENATE gs_trange-tablename
                    '~'
                    ls_range-fieldname
                    INTO ls_range-fieldname.
        MODIFY gs_trange-frange_t FROM ls_range.
      ENDLOOP.
      MODIFY gt_trange_h FROM gs_trange.
    ENDLOOP.

* Dynamic: conversion format RSDS_TRANGE ==> RSDS_TWHERE
    CALL FUNCTION 'FREE_SELECTIONS_RANGE_2_WHERE'
      EXPORTING
        field_ranges  = gt_trange_h
      IMPORTING
        where_clauses = gt_where_clauses.
    SORT gt_where_clauses BY tablename.
    READ TABLE gt_where_clauses INTO gs_qals
                      WITH KEY tablename = 'QALS'
                      BINARY SEARCH.
* Determination of QALS-entry in L_QAMV-WHERE_TAB
    IF sy-subrc <> 0.
      CLEAR gs_qals.
    ENDIF.
    READ TABLE gt_where_clauses INTO gs_qave
                      WITH KEY tablename = 'QAVE'
                      BINARY SEARCH.
* Determination of QAVE-entry in L_QAMV-WHERE_TAB
    IF sy-subrc <> 0.
      CLEAR gs_qave.
    ENDIF.
    READ TABLE gt_where_clauses INTO gs_qapo
                      WITH KEY tablename = 'AFVC'
*                      WITH KEY tablename = 'QAPO'
                      BINARY SEARCH.
* Determination of QAPO-entry in L_QAMV-WHERE_TAB
    IF sy-subrc IS INITIAL.
*      MOVE gv_x TO gv_qapo_select.
*    ELSE.
      CLEAR gs_qapo.
    ENDIF.
    READ TABLE gt_where_clauses INTO gs_qapp
                      WITH KEY tablename = 'QAPP'
                      BINARY SEARCH.
* Determination of QAPP-entry in gs_qapp-WHERE_TAB
    IF sy-subrc <> 0.
      CLEAR gs_qapp.
    ENDIF.
    READ TABLE gt_where_clauses INTO gs_qamv
                      WITH KEY tablename = 'QAMV'.
* Determination of QAMV-entry in L_QAMV-WHERE_TAB
    IF sy-subrc <> 0.
      CLEAR gs_qamv.
    ENDIF.

    READ TABLE gt_where_clauses INTO gs_qamr
                      WITH KEY tablename = 'QAMR'
                      BINARY SEARCH.
    IF sy-subrc <> 0.
      CLEAR gs_qamr.
    ENDIF.

    READ TABLE gt_where_clauses INTO gs_qasr
                      WITH KEY tablename = 'QASR'
                      BINARY SEARCH.
    IF sy-subrc <> 0.
      CLEAR gs_qasr.
    ENDIF.

    READ TABLE gt_where_clauses INTO gs_qase
                      WITH KEY tablename = 'QASE'.
    IF sy-subrc <> 0.
      CLEAR gs_qase.
    ENDIF.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  PRESELECT_WORKCENTER
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM preselect_workcenter .

* Preselect workcenter
  IF NOT ql_prplz[] IS INITIAL
  OR NOT ql_prplt[] IS INITIAL.
    SELECT crhd~objid
      FROM crhd
        JOIN crtx ON  ( crtx~objty = crhd~objty
                  AND   crtx~objid = crhd~objid )
      INTO TABLE @DATA(lt_crhd)
      WHERE crhd~objty = 'A'
      AND   crhd~arbpl IN @ql_prplz
      AND   crhd~werks IN @ql_prwrk
      AND   crtx~ktext IN @ql_prplt
      AND   crtx~spras EQ @sy-langu.
    IF sy-subrc = 0.
      LOOP AT lt_crhd INTO DATA(ls_crhd).
        APPEND VALUE #( sign   = 'I'
                        option = 'EQ'
                        low    = ls_crhd-objid ) TO gr_arbid.
      ENDLOOP.
    ELSE.
      CLEAR lt_crhd.
    ENDIF.
  ELSE.
    CLEAR gr_arbid.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  CALL_QE51N
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_OBJECT_TAB_PRUEFLOS  text
*----------------------------------------------------------------------*
FORM call_qe51n USING is_object TYPE gty_object_tab.

  DATA: lt_bdcdata    TYPE TABLE OF bdcdata,
        ls_bdcoptions TYPE ctu_params,
        ls_bdcdata    TYPE bdcdata,
        lv_tcode      TYPE sy-tcode.

  lv_tcode = 'QE51N'.

  CALL FUNCTION 'QAST_PROCESS_ACTIVITY'
    EXPORTING
      i_check_only         = 'X'
      i_dialog             = 'X'
      i_objnr              = is_object-objnr
      i_vorgang            = 'QM18'
    EXCEPTIONS
      not_allowed          = 1
      activity_not_allowed = 2
      OTHERS               = 3.
  IF sy-subrc = 0.
* Create Batch Input Map:
* Batch Input Mappe aufbauen:
* Dynpro 0500 ansteurn
    ls_bdcdata-program  = 'SAPLQEES'.
    ls_bdcdata-dynpro   = '0500'.
    ls_bdcdata-dynbegin = 'X'.
    APPEND ls_bdcdata TO lt_bdcdata.
    CLEAR ls_bdcdata.
* Clear Plant
* Werk löschen
    ls_bdcdata-fnam     = 'QL_WERKS-LOW'.
    ls_bdcdata-fval     = ' '.
    APPEND ls_bdcdata TO lt_bdcdata.
    CLEAR ls_bdcdata.

    CASE object_tab-stat13.

      WHEN '2'.
* Execute OK Code
* OK Code auslösen
        ls_bdcdata-fnam     = 'BDC_OKCODE'.
        ls_bdcdata-fval     = '=TAB_EQU'.
        APPEND ls_bdcdata TO lt_bdcdata.
        CLEAR ls_bdcdata.
* Call Screen 500
* Dynpro 0500 ansteurn
        ls_bdcdata-program  = 'SAPLQEES'.
        ls_bdcdata-dynpro   = '0500'.
        ls_bdcdata-dynbegin = 'X'.
        APPEND ls_bdcdata TO lt_bdcdata.
        CLEAR ls_bdcdata.

* Execute OK Code
* OK Code auslösen
        ls_bdcdata-fnam     = 'BDC_OKCODE'.
        ls_bdcdata-fval     = '=TAB_LOS'.
        APPEND ls_bdcdata TO lt_bdcdata.
        CLEAR ls_bdcdata.
* Call Screen 500
* Dynpro 0500 ansteurn
        ls_bdcdata-program  = 'SAPLQEES'.
        ls_bdcdata-dynpro   = '0500'.
        ls_bdcdata-dynbegin = 'X'.
        APPEND ls_bdcdata TO lt_bdcdata.
        CLEAR ls_bdcdata.
* Set functional location number number
* Technischen Platz übergeben
        ls_bdcdata-fnam     = 'QL_PRLOS-LOW'.
        ls_bdcdata-fval     = is_object-prueflos.
        APPEND ls_bdcdata TO lt_bdcdata.
        CLEAR ls_bdcdata.

      WHEN '3'.
* Execute OK Code
* OK Code auslösen
        ls_bdcdata-fnam     = 'BDC_OKCODE'.
        ls_bdcdata-fval     = '=TAB_SMP'.
        APPEND ls_bdcdata TO lt_bdcdata.
        CLEAR ls_bdcdata.
* Call Screen 500
* Dynpro 0500 ansteurn
        ls_bdcdata-program  = 'SAPLQEES'.
        ls_bdcdata-dynpro   = '0500'.
        ls_bdcdata-dynbegin = 'X'.
        APPEND ls_bdcdata TO lt_bdcdata.
        CLEAR ls_bdcdata.

* Execute OK Code
* OK Code auslösen
        ls_bdcdata-fnam     = 'BDC_OKCODE'.
        ls_bdcdata-fval     = '=TAB_LOS'.
        APPEND ls_bdcdata TO lt_bdcdata.
        CLEAR ls_bdcdata.
* Call Screen 500
* Dynpro 0500 ansteurn
        ls_bdcdata-program  = 'SAPLQEES'.
        ls_bdcdata-dynpro   = '0500'.
        ls_bdcdata-dynbegin = 'X'.
        APPEND ls_bdcdata TO lt_bdcdata.
        CLEAR ls_bdcdata.
* Set functional location number number
* Technischen Platz übergeben
        ls_bdcdata-fnam     = 'QL_PRLOS-LOW'.
        ls_bdcdata-fval     = is_object-prueflos.
        APPEND ls_bdcdata TO lt_bdcdata.
        CLEAR ls_bdcdata.

      WHEN OTHERS.

* Execute OK Code
* OK Code auslösen
        ls_bdcdata-fnam     = 'BDC_OKCODE'.
        ls_bdcdata-fval     = '=TAB_LOS'.
        APPEND ls_bdcdata TO lt_bdcdata.
        CLEAR ls_bdcdata.
* Call Screen 500
* Dynpro 0500 ansteurn
        ls_bdcdata-program  = 'SAPLQEES'.
        ls_bdcdata-dynpro   = '0500'.
        ls_bdcdata-dynbegin = 'X'.
        APPEND ls_bdcdata TO lt_bdcdata.
        CLEAR ls_bdcdata.
* Set functional location number number
* Technischen Platz übergeben
        ls_bdcdata-fnam     = 'QL_PRLOS-LOW'.
        ls_bdcdata-fval     = is_object-prueflos.
        APPEND ls_bdcdata TO lt_bdcdata.
        CLEAR ls_bdcdata.

    ENDCASE.

* Execute OK Code
* OK Code auslösen
    ls_bdcdata-fnam     = 'BDC_OKCODE'.
    ls_bdcdata-fval     = '=CRET'.
    APPEND ls_bdcdata TO lt_bdcdata.

* Set calling options
* Aufrufoptionen versorgen:
    ls_bdcoptions-dismode  = 'E'.
    ls_bdcoptions-updmode  = 'A'.
    ls_bdcoptions-cattmode = ' '.
    ls_bdcoptions-defsize  = ' '.
*      ls_bdcoptions-racommit = ' '.
*      ls_bdcoptions-nobinpt  = ' '.
*     No automatic return after saving QE51n
    ls_bdcoptions-racommit = 'X'.
    ls_bdcoptions-nobinpt  = 'X'.
    ls_bdcoptions-nobiend  = 'X'.

    CALL FUNCTION 'AUTHORITY_CHECK_TCODE'
      EXPORTING
        tcode  = 'QE51N'
      EXCEPTIONS
        ok     = 1
        not_ok = 2
        OTHERS = 3.
    IF sy-subrc EQ 1.
      CALL TRANSACTION 'QE51N'  USING    lt_bdcdata
                                OPTIONS  FROM ls_bdcoptions.
    ENDIF.

  ENDIF.

ENDFORM.
