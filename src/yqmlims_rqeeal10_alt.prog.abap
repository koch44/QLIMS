REPORT yqm_rqeeal10 MESSAGE-ID ih NO STANDARD PAGE HEADING.
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
*  FISCHEC7 09.03.2026 Übernahme aus TN1
*&--------------------------------------------------------------------- *


INCLUDE rqalvtop.

TABLES: qals,
        qamr,
        qasr,
        qavp,
        tq30,
        tqss1,                         "QM-Defaults: Werksebene
        t399a.              "Gmelch 20.2.15


** INTERNAL TABLES
*DATA: BEGIN OF object_tab OCCURS 0.
*        INCLUDE STRUCTURE yqm_rqeeal10.
*DATA: kz_qave.
*DATA: selected.
*DATA: lights.
*DATA: viewed TYPE pm_selected.
*DATA: END OF object_tab.
*
*DATA: BEGIN OF object_tab_all OCCURS 0.
*        INCLUDE STRUCTURE yqm_rqeeal10.
*DATA: kz_qave.
*DATA: selected.
*DATA: lights.
*DATA: viewed TYPE pm_selected.
*DATA: END OF object_tab_all.

* Type for output object tab
TYPES: BEGIN OF gty_object_tab .
         INCLUDE  TYPE yqm_rqeeal10.
TYPES:   kz_qave TYPE flag.
TYPES:  selected TYPE flag.
TYPES:  lights   TYPE flag.
TYPES:  viewed   TYPE pm_selected.
TYPES: END OF gty_object_tab.

TYPES: BEGIN OF gty_sel_tab.
         INCLUDE  TYPE yqm_rqeeal10.
TYPES:   kz_qave  TYPE abap_bool,
         selected TYPE abap_bool,
         lights   TYPE c LENGTH 1,
         viewed   TYPE pm_selected,
       END OF gty_sel_tab.

DATA: object_tab     TYPE STANDARD TABLE OF gty_object_tab WITH HEADER LINE WITH EMPTY KEY.
DATA: object_tab_all TYPE STANDARD TABLE OF gty_object_tab WITH HEADER LINE WITH EMPTY KEY.

DATA sel_tab     TYPE STANDARD TABLE OF gty_sel_tab WITH EMPTY KEY.
DATA gs_sel_tab  TYPE gty_sel_tab.

*  Berechtigungspuffer
DATA: BEGIN OF g_auth,
        art  TYPE qals-art,
        werk TYPE qals-werk,
        ok   TYPE qm00-qkz,
      END OF g_auth,
*  Anzahl Lose mit fehlender Berechtigung
      g_anz_no_auth TYPE i.

CONSTANTS gc_tcode      TYPE sy-tcode       VALUE 'QA33'.
DATA gv_stern           VALUE '*'.

DATA g_tcode           TYPE sy-tcode.
DATA g_okcode          TYPE sy-ucomm.
DATA g_view_type(4)    TYPE c VALUE 'AVEM'.

DATA: dummy            TYPE c.
DATA: lv_user          TYPE sy-uname.
DATA: lv_status        TYPE jest-stat.
DATA: lv_status_c(4)   TYPE c.
DATA: gv_display_log   TYPE flag.

DATA: ls_msg              TYPE bal_s_msg.
DATA: ls_log              TYPE bal_s_log.
DATA: l_log_handle        TYPE balloghndl.
DATA: t_log_handle        TYPE bal_t_logh.
DATA: l_extnumber         TYPE balnrext.
DATA: l_s_display_profile TYPE bal_s_prof.

DATA: gv_fullfill    TYPE char1.

DATA: gt_jsto_pre      TYPE TABLE OF jsto_pre.

* Authorization buffer
DATA: BEGIN OF gs_auth,
        art  TYPE qals-art,
        werk TYPE qals-werk,
        ok   TYPE qm00-qkz,
      END OF gs_auth.

DATA: gt_where_clauses TYPE rsds_twhere.
DATA: gs_qals          TYPE rsds_where.
DATA: gs_qave          TYPE rsds_where.
DATA: gs_qapo          TYPE rsds_where.
DATA: gs_qapp          TYPE rsds_where.
DATA: gs_qamv          TYPE rsds_where.
DATA: gs_qase          TYPE rsds_where.
DATA: gs_qamr          TYPE rsds_where.
DATA: gs_qasr          TYPE rsds_where.

DATA gr_arbid  TYPE RANGE OF afvc-arbid.
DATA gr_serlot TYPE RANGE OF qals-prueflos.

DATA: gv_progress_act        TYPE i,
      gv_progress_max        TYPE i,
      gv_progress_percentage TYPE i,
      gv_progress_string     TYPE text132.

* Datendeklaration für Unicodeumstellung
DATA: message_text TYPE slis_varbz.

CONSTANTS: c_pruefart(8) VALUE 'YQM_TP'. "Pruefart YQM_TP

* Konstante fuer Anwenderstatus
CONSTANTS: c_ergm(4) VALUE 'ERGM',     "Ergebniserfassung möglich
           c_avem(4) VALUE 'AVEM',     "Auto. VE moeglich
           c_kave(4) VALUE 'KAVE',     "Kein auto. VE moeglich
           c_gute(4) VALUE 'GUTE'.     "Gutachten erforderlich

CONSTANTS: c_stat_frei TYPE jest-stat VALUE 'I0002', "Stat. Frei
           c_stat_erg  TYPE jest-stat VALUE 'I0213', "Stat. Ergebnisse
           c_stat_ve   TYPE jest-stat VALUE 'I0218', "Stat. VE getroffen
           c_stat_sper TYPE jest-stat VALUE 'I0043', "Stat. Los gesperrt
           c_stat_lsto TYPE jest-stat VALUE 'I0224'. "Stat. Los storn.

* Variable für internen Code Anwenderstatus
DATA: stat_ergm TYPE jest-stat,        "Ergebniserfassung möglich
      stat_avem TYPE jest-stat,        "Auto. VE moeglich
      stat_apbe TYPE jest-stat,        "Ausgabe Prüfbericht erfolgt
      stat_kave TYPE jest-stat,        "Kein auto. VE moeglich
      stat_gute TYPE jest-stat,        "Gutachten erforderlich
      stat_begu TYPE jest-stat.        "Gutachten erstellt

* SELECT-OPTIONS mit Rahmen
SELECTION-SCREEN BEGIN OF BLOCK zusatz WITH FRAME TITLE TEXT-s11.
  SELECT-OPTIONS so_los    FOR qals-prueflos.
  SELECT-OPTIONS so_phynr  FOR qals-yqm_qphysprnr.
  SELECT-OPTIONS so_kunzl  FOR qals-yqm_kunnrzl.
  SELECT-OPTIONS so_prdat  FOR qals-yqm_probedatum.
  PARAMETERS     p_gute   NO-DISPLAY DEFAULT ' '.
*PARAMETERS     p_gute   AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN END OF BLOCK zusatz.

SELECTION-SCREEN BEGIN OF BLOCK code WITH FRAME TITLE TEXT-a00.
  PARAMETERS: p_ausmg TYPE qave-vauswahlmg,
              p_vwerk TYPE qave-vwerks,
              p_cdgrp TYPE qave-vcodegrp,
              p_code  TYPE qave-vcode        OBLIGATORY.
SELECTION-SCREEN END OF BLOCK code.

* PARAMETERS --------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK bottom WITH FRAME TITLE TEXT-p00.
*PARAMETERS: p_alles NO-DISPLAY DEFAULT ' '.
*PARAMETERS: p_no_ud NO-DISPLAY DEFAULT 'X'.
*PARAMETERS: p_ud    NO-DISPLAY DEFAULT ' '.

  PARAMETERS: p_nlzmk TYPE qals-offennlzmk NO-DISPLAY DEFAULT 0.  "keine offene Kurzzeitmerkmale
  PARAMETERS: p_lzmk  TYPE qals-offen_lzmk NO-DISPLAY DEFAULT 0.  "keine offene Langzeitmerkmale

  SELECTION-SCREEN BEGIN OF LINE.
    PARAMETERS: p_alles RADIOBUTTON GROUP ud.
    SELECTION-SCREEN COMMENT 3(70) TEXT-p03 FOR FIELD p_alles. "N744242
  SELECTION-SCREEN END OF LINE.

  SELECTION-SCREEN BEGIN OF LINE.
    PARAMETERS: p_no_ud RADIOBUTTON GROUP ud.
    SELECTION-SCREEN COMMENT 3(70) TEXT-p04 FOR FIELD p_no_ud. "N744242
  SELECTION-SCREEN END OF LINE.
  SELECTION-SCREEN BEGIN OF LINE.
    PARAMETERS: p_no_uda RADIOBUTTON GROUP ud.
    SELECTION-SCREEN COMMENT 3(70) TEXT-p05 FOR FIELD p_no_uda. "N744242
  SELECTION-SCREEN END OF LINE.

  SELECTION-SCREEN BEGIN OF LINE.
    PARAMETERS: p_ud RADIOBUTTON GROUP ud.
    SELECTION-SCREEN COMMENT 3(70) TEXT-p02 FOR FIELD p_ud. "N744242
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

  g_view_type = 'AVEM'.

*--------------------------------------------------------------------*
* AT SELECTION SCREEN                                                *
*--------------------------------------------------------------------*
AT SELECTION-SCREEN ON RADIOBUTTON GROUP ud.

  REFRESH s_stat35.
  IF NOT p_no_ud  IS INITIAL
  OR NOT p_no_uda IS INITIAL.
*-- nur Prueflose mit STAT35 = ' '
    s_stat35-low    = ' '.
    s_stat35-sign   = 'I'.
    s_stat35-option = 'EQ'.
    APPEND s_stat35.
  ELSEIF NOT p_ud IS INITIAL.
*-- nur Prueflose mit STAT35 = 'X'
    s_stat35-low    = 'X'.
    s_stat35-sign   = 'I'.
    s_stat35-option = 'EQ'.
    APPEND s_stat35.
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

* Ermittlung Vorschlagswerte aus Werkseinstellungen (Werk 2701)
  SELECT SINGLE * FROM tqss1
*    where werks eq '1102'.               "Gme20141209 * Gmelch 3.1.23 Werk sehr spät korr. "DEL CT20250206
    WHERE werks = '1011'.                                                                   "INS CT20250206
  IF sy-subrc EQ 0.
    p_ausmg = tqss1-ppvemenge.
    p_vwerk = tqss1-ppvewerk.
    p_cdgrp = tqss1-ppvecodegr.
    p_code  = tqss1-ppvecode.
  ENDIF.

  PERFORM check_status_settings.

*--- Aktivitätstyp bestimmen -----------------------------------------
  SELECT SINGLE * FROM t370a WHERE tcode = sy-tcode.
  IF sy-subrc <> 0.
    SELECT SINGLE * FROM t370a WHERE tcode = gc_tcode.
    IF sy-subrc <> 0.
      RAISE tcode_not_in_t370a.
    ENDIF.
  ENDIF.

  MOVE 'YQM_RQEEAL10' TO g_tabname.
  IF NOT sy-calld IS INITIAL.
    IMPORT g_submit g_fieldcat_tab FROM MEMORY ID 'SUBMIT'.
  ENDIF.

*-------------------------------------------------------------------*
  message_text = TEXT-tes.
  PERFORM variant_init_f14 USING 'LOTS'
                                 'LOTS'
*                                text-tes.
                                 message_text.
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

* Zusätzliche Initialisierungen, um 'alte' Selektionsvarianten zu
* übersteuern
  CLEAR p_gute.
  CLEAR p_alles.
  CLEAR p_ud.
  MOVE 'X' TO p_no_ud.

  IF NOT p_no_ud IS INITIAL.
*-- nur Prueflose mit STAT35 = ' '
    s_stat35-low    = ' '.
    s_stat35-sign   = 'I'.
    s_stat35-option = 'EQ'.
    APPEND s_stat35.
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

*--- Aktivitätstyp bestimmen -----------------------------------------
  dy_tcode = sy-tcode.
  SELECT SINGLE * FROM t370a WHERE tcode = dy_tcode.
  IF sy-subrc <> 0.
    SELECT SINGLE * FROM t370a WHERE tcode = gc_tcode.
    IF sy-subrc <> 0.
      RAISE tcode_not_in_t370a.
    ENDIF.
  ENDIF.

  IF g_submit IS INITIAL.
    PERFORM create_fieldcat_l USING g_tabname.
    PERFORM update_fieldcat_variant_f14.
  ENDIF.
*  PERFORM select_fields_manip_l   USING g_fieldcat_tab.

*Stati are checked in this report. Therefore JEST is preread
  MOVE g_x TO preread.

  BREAK fisch50.

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
         qals~yqm_probenahmeart, qals~yqm_anlass, qals~yqm_kunnrzl, qals~yqm_vnlpv,
         qals~yqm_vnlpvkt, qals~yqm_pnzwk, qals~yqm_qphysprnr, qals~yqm_qpbversion,

* Usage Decision information
         qave~vbewertung, qave~qkennzahl, qave~kzart, qave~vkatart, qave~vauswahlmg,
         qave~vcodegrp, qave~vcode, qave~dbewertung, qave~vfolgeakti, qave~vname, qave~ltextkz AS ltextkzve,
         qave~vdatum, qave~vezeiterf, qave~vaename, qave~vaedatum, qave~vezeitaen,

* Material Master Information
         mara~mhdrz, mara~mhdhb, mara~iprkz, mara~rdmhd, mara~mhdlp, mara~extwg, "mara~yqm_1u_mhdhb,
*
* Material Master Information - Plant level
         marc~maabc, marc~dispo, "marc~prctr AS zprctr1, marc~qmata, marc~yqm_1u_plnt_matcat,
         "marc~yqm_1u_oper_area,
* Auftragsdaten
         aufk~auart
    FROM  qals
     LEFT OUTER JOIN qave  ON  ( qave~prueflos = qals~prueflos
                           AND   qave~kzart    = 'L' )
     LEFT OUTER JOIN qapp  ON  ( qapp~prueflos = qals~prueflos )
*     LEFT OUTER JOIN qprs  ON  ( qprs~phynr    = qapp~phynr )
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
    AND qals~werk           IN @ql_prwrk
    AND qals~herkunft       IN @ql_herkt
    AND qals~matnr          IN @ql_matnr
    AND qals~charg          IN @ql_charg
    AND qals~lifnr          IN @ql_lifnr
    AND qals~hersteller     IN @ql_herst
    AND qals~kunnr          IN @ql_kunnr
*    AND qals~aufnr          IN @so_aufnr
*    AND qals~stat35         IN @so_sta35
    AND qals~yqm_kunnrzl      IN @so_kunzl
    AND qals~yqm_probedatum   IN @so_prdat
    AND (gs_qals-where_tab)
*    AND qapp~equnr          IN @ql_equi
*    AND qapp~tplnr          IN @so_tplnr
    AND qapp~phynr          IN @so_phynr
    AND (gs_qapp-where_tab)
    AND (gs_qave-where_tab)
*    AND qamv~verwmerkm      IN @so_merk
*    AND (gs_qamv-where_tab)
    AND afvc~arbid          IN @gr_arbid
    AND afvc~werks          IN @ql_prwrk
*    AND afvc~vornr          IN @so_vornr
*    AND aufk~auart          IN @so_auart
    AND (gs_qapo-where_tab)
      INTO TABLE @DATA(lt_qals_sel).
*   INTO CORRESPONDING FIELDS OF TABLE @sel_tab.
  IF sy-subrc <> 0.
    CLEAR sel_tab.
    IF sy-calld IS INITIAL.
      MESSAGE i047(ih).
    ENDIF.
    EXIT.
*  ENDIF.
*       INTO TABLE @DATA(lt_qapo_sel).
*    IF sy-subrc <> 0.
*      CLEAR gt_insp_results.
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

  CLEAR object_tab..

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



**-------------------------------------------------------------------*
** GET                                                               *
**-------------------------------------------------------------------*
*
*GET qals FIELDS prueflos
*                obtyp
*                objnr
*                aufpl
*                art                    "for authorization
*                werk                   "for authorization
*                offennlzmk             "for monitor
*                offen_lzmk             "for monitor
*                pastrterm              "for monitor
*                paendterm              "for monitor
*                lmengezub              "for monitor
*                aufnr_co
*                plnty
*                stsma
*                stat02
*                stat07
*                stat35
*                ktextlos
*                matnr.     "Gmelch 20.2.15
*
** Gmelch 20.2.15 Lesen QAPO wg. Selectoptions Prüfvorgänge: Arb.platz inkl. Text und Werk
*  IF ql_prwrk IS NOT INITIAL.
*    CHECK qals-werk IN ql_prwrk.
*  ENDIF.
*  IF ql_prplz IS NOT INITIAL.
*    SELECT SINGLE * FROM t399a WHERE iwerk = qals-werk
*                                 AND svobj_id = '01'
*                                 AND svobj = qals-matnr.
*    IF sy-subrc = 0.
*      CHECK t399a-vaplz IN ql_prplz.
*    ENDIF.
*  ENDIF.
*
** Prüfartenberechtigung prüfen mit Puffer
*  IF    g_auth-art  NE qals-art
*    OR g_auth-werk  NE qals-werk.
**   Berechtigung hat sich geändert, neu prüfen
*    MOVE-CORRESPONDING qals TO g_auth.
*    CALL FUNCTION 'QAUT_INSPTYPE'
*      EXPORTING
*        i_pruefart       = g_auth-art
*        i_werk           = g_auth-werk
*      EXCEPTIONS
*        no_authorization = 1.
*
**     Berechtigung vorhanden
*    IF sy-subrc IS INITIAL.
*      MOVE g_x TO g_auth-ok.
*    ELSE.
*      CLEAR g_auth-ok.
*      REJECT.
*    ENDIF.
*  ENDIF.
** Berechtigung prüfen
*  IF g_auth-ok EQ space.
**   keine Berechtigung
*    ADD 1 TO g_anz_no_auth.
*    REJECT.
*  ENDIF.
*
** FILL INTERNAL TABLE
*  CLEAR object_tab.
*  MOVE-CORRESPONDING qals TO object_tab.
*  MOVE qals-stat35 TO object_tab-kz_qave.
*  PERFORM set_monitor_f16.
*
** GENERATE STATUS AND USER TEXTS
*  CALL FUNCTION 'STATUS_TEXT_EDIT'
*    EXPORTING
*      objnr            = qals-objnr
*      flg_user_stat    = g_x
*      spras            = sy-langu
*    IMPORTING
*      line             = object_tab-sttxt
*      user_line        = object_tab-ustxt
*    EXCEPTIONS
*      object_not_found = 01.
*  IF sy-subrc NE 0.
*    CLEAR object_tab-sttxt.
*    CLEAR object_tab-ustxt.
*  ENDIF.
*
** Ausser den Status LSTO und SPER sollen keine System-/und
** Anwenderstatus explizit geprüft werden. Die Prüfung soll
** mit den Selektionsschema durchgeführt werden
*  CALL FUNCTION 'STATUS_CHECK'
*    EXPORTING
*      objnr             = qals-objnr
*      status            = c_stat_lsto
*    EXCEPTIONS
*      object_not_found  = 1
*      status_not_active = 2
*      OTHERS            = 3.
*  IF sy-subrc = 0.
*    REJECT.
*  ENDIF.
*
*  CALL FUNCTION 'STATUS_CHECK'
*    EXPORTING
*      objnr             = qals-objnr
*      status            = c_stat_sper
*    EXCEPTIONS
*      object_not_found  = 1
*      status_not_active = 2
*      OTHERS            = 3.
*  IF sy-subrc = 0.
*    REJECT.
*  ENDIF.
*
**
**  CALL FUNCTION 'STATUS_CHECK'
**    EXPORTING
**      objnr             = qals-objnr
**      status            = c_stat_erg
**    EXCEPTIONS
**      object_not_found  = 1
**      status_not_active = 2
**      OTHERS            = 3.
**  IF sy-subrc <> 0.
**    REJECT.
**  ENDIF.
**
**  CALL FUNCTION 'STATUS_CHECK'
**    EXPORTING
**      objnr             = qals-objnr
**      status            = c_stat_frei
**    EXCEPTIONS
**      object_not_found  = 1
**      status_not_active = 2
**      OTHERS            = 3.
**  IF sy-subrc = 0.
**    REJECT.
**  ENDIF.
**
**
**-- Pruefen, ob VE erlaubt
**  CALL FUNCTION 'QAST_PROCESS_ACTIVITY'
**    EXPORTING
**      i_check_only         = 'X'
**      i_dialog             = space
**      i_objnr              = qals-objnr
**      i_vorgang            = 'QM20'  "Einstieg VE
**    EXCEPTIONS
**      not_allowed          = 01
**      activity_not_allowed = 02.
**  IF sy-subrc NE 0.                  "VE nicht erlaubt
**    REJECT.
**  ENDIF.
**
**  IF p_gute = 'X'.
*** Begutachtete ausschliessen
**    CALL FUNCTION 'STATUS_TEXT_CONVERSION'
**      EXPORTING
***       CLIENT                   = SY-MANDT
**        language                 = sy-langu
**        mode                     = 'E'
**        objnr                    = qals-objnr
***       STSMA                    = ' '
**        txt04                    = 'BEGU'
**     IMPORTING
**       status_number            = stat_begu
**     EXCEPTIONS
**       insufficient_input       = 1
**       not_found                = 2
**       object_not_found         = 3
**       wrong_mode               = 4
**       OTHERS                   = 5.
**    IF sy-subrc = 0.
**      CALL FUNCTION 'STATUS_CHECK'
**        EXPORTING
**          objnr             = qals-objnr
**          status            = stat_begu
**        EXCEPTIONS
**          object_not_found  = 1
**          status_not_active = 2
**          OTHERS            = 3.
**      IF sy-subrc = 0.
**        REJECT.
**      ENDIF.
**    ENDIF.
**  ENDIF.
**
**
*** Prüflose bei denen 'Ausgabe Prüfbericht erfolgt' ausschliessen
**    CALL FUNCTION 'STATUS_TEXT_CONVERSION'
**      EXPORTING
***       CLIENT                   = SY-MANDT
**        language                 = sy-langu
**        mode                     = 'E'
**        objnr                    = qals-objnr
***       STSMA                    = ' '
**        txt04                    = 'APBE'
**     IMPORTING
**       status_number            = stat_apbe
**     EXCEPTIONS
**       insufficient_input       = 1
**       not_found                = 2
**       object_not_found         = 3
**       wrong_mode               = 4
**       OTHERS                   = 5.
**    IF sy-subrc = 0.
**      CALL FUNCTION 'STATUS_CHECK'
**        EXPORTING
**          objnr             = qals-objnr
**          status            = stat_apbe
**        EXCEPTIONS
**          object_not_found  = 1
**          status_not_active = 2
**          OTHERS            = 3.
**      IF sy-subrc = 0.
**        REJECT.
**      ENDIF.
**    ENDIF.
*
*  IF NOT object_tab-yqm_tplnr IS INITIAL.
*    SELECT SINGLE yqm_info1 yqm_info2 yqm_info3
*      FROM iflot
*      INTO CORRESPONDING FIELDS OF object_tab
*      WHERE tplnr = object_tab-yqm_tplnr.
*      if sy-subrc <> 0.
*
*      endif.
*  ENDIF.
*
**Logic is as follows: If UD data is not required, object_tab is
**appended. If it is required, a flag is set which is then changed at GET
** QAVP to account for the dynamic selections.
*
*  IF    NOT p_no_ud  IS INITIAL.
*    IF qals-offennlzmk EQ 0.
*      REJECT.
*    ENDIF.
*  ELSEIF NOT p_no_uda IS INITIAL.
*    IF qals-offennlzmk GT 0.
*      REJECT.
*    ENDIF.
*  ENDIF.
*
*  IF NOT p_no_ud  IS INITIAL
*  OR NOT p_no_uda IS INITIAL
*  OR NOT p_alles  IS INITIAL AND qals-stat35 EQ space.  " Ignore UD fields
**   kein VE zu lesen
*    APPEND object_tab TO object_tab_all.
*    REJECT.
*  ELSE.
**elseif qals-stat35 eq g_x.
*    MOVE 'Y' TO qals-stat35.
*  ENDIF.
*
*GET qavp FIELDS prueflos.
*  MOVE-CORRESPONDING qavp TO object_tab.
*  MOVE g_x TO qals-stat35.
*
*GET qals LATE FIELDS prueflos obtyp objnr  aufpl
*                     aufnr_co plnty stat02 stat07.
*
*  IF qals-stat35 EQ g_x.
*    APPEND object_tab TO object_tab_all.
*  ENDIF.
*
**--------------------------------------------------------------------*
** END OF SELECTION                                                   *
**--------------------------------------------------------------------*
*END-OF-SELECTION.
*
*  CLEAR gv_display_log.
*
*  REFRESH t_log_handle.
*
*  ls_log-object     = 'YQM'.
*  ls_log-subobject  = 'YQM_QA33'.
*  ls_log-extnumber  = 'Statuswechsel beim Einstieg in YQM_QA33'.
*
*  CALL FUNCTION 'BAL_LOG_CREATE'
*    EXPORTING
*      i_s_log      = ls_log
*    IMPORTING
*      e_log_handle = l_log_handle
*    EXCEPTIONS
*      OTHERS       = 1.
*  IF sy-subrc <> 0.
*    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
*  ELSE.
*    APPEND l_log_handle TO t_log_handle.
*  ENDIF.
*
** Zuerst der Anwenderstatus aller selektierten Prüflose im Status 'ERGM'
** setzen auf
**            'AVEM' - falls automatischer VE möglich
**            'KAVE' - falls kein automatischer VE erlaubt
*  LOOP AT object_tab_all.
*    CLEAR lv_status.
*
**---- Status ERGM (Ergebniserfassung möglich)
*    CALL FUNCTION 'STATUS_CHECK'
*      EXPORTING
*        bypass_buffer     = 'X'
*        objnr             = object_tab_all-objnr
*        status            = stat_ergm
*      EXCEPTIONS
*        object_not_found  = 1
*        status_not_active = 2
*        OTHERS            = 3.
*    IF sy-subrc <> 0.
*      CONTINUE.
*    ENDIF.
*
*    lv_status   = stat_avem.
*    lv_status_c = c_avem.
*
**---- Status 'GUTE' (Gutachten erforderlich)
*    CALL FUNCTION 'STATUS_CHECK'
*      EXPORTING
*        bypass_buffer     = 'X'
*        objnr             = object_tab_all-objnr
*        status            = stat_gute
*      EXCEPTIONS
*        object_not_found  = 1
*        status_not_active = 2
*        OTHERS            = 3.
*    IF sy-subrc = 0.
*      lv_status   = stat_kave.
*      lv_status_c = c_kave.
*    ENDIF.
*
**-- Untersuchen, ob Prueflos mind. ein rueckgewiesenes Merkmal hat
*    SELECT * FROM qamr
*      WHERE prueflos EQ object_tab_all-prueflos
*        AND mbewertg NE 'A'.           "Bewertung nicht i.O.
*      lv_status   = stat_kave.
*      lv_status_c = c_kave.
*      EXIT.                            "mind. ein Merkmal gefunden
*    ENDSELECT.
*
**-- Untersuchen, ob Prueflos mind. ein rueckgewiesenes Merkmal hat
*    SELECT * FROM qasr
*      WHERE   prueflos EQ object_tab_all-prueflos
*        AND ( mbewertg NE 'A'           "Bewertung nicht i.O.
*          OR  attribut EQ 'W'           "Attribut 'Warngrenze überschritten'
*          OR  fehlklas EQ '90' ).       "Plausibilitätsverletzung
*      lv_status   = stat_kave.
*      lv_status_c = c_kave.
*      EXIT.                            "mind. ein Merkmal gefunden
*    ENDSELECT.
*
*    IF NOT lv_status IS INITIAL.
*
**-- Sperre setzen
*      CALL FUNCTION 'ENQUEUE_EQQALS1'
*        EXPORTING
*          prueflos       = object_tab_all-prueflos
*        EXCEPTIONS
*          foreign_lock   = 1
*          system_failure = 2
*          OTHERS         = 3.
*      IF sy-subrc EQ 0.                  "Sperre erfolgreich gesetzt
**---- Status AVEM (auto. VE moeglich)      oder
**---- Status KAVE (Kein auto. VE moeglich) setzen
*        CALL FUNCTION 'STATUS_CHANGE_EXTERN'
*          EXPORTING
*            objnr               = object_tab_all-objnr
*            user_status         = lv_status
*          EXCEPTIONS
*            object_not_found    = 1
*            status_inconsistent = 2
*            status_not_allowed  = 3
*            OTHERS              = 4.
**---- Status gesetzt?
*        IF sy-subrc EQ 0.
*          MESSAGE s301(yqmlims) WITH object_tab_all-prueflos
*                                     lv_status_c INTO dummy.
*          PERFORM add_message.
*          COMMIT WORK AND WAIT.         "Status fortschreiben
*        ELSE.
*          MESSAGE e302(yqmlims) WITH object_tab_all-prueflos
*                                     lv_status_c INTO dummy.
*          PERFORM add_message.
*        ENDIF.
*      ELSE.                              "Fremde Sperre
*        WRITE sy-msgv1 TO lv_user.
*        MESSAGE w303(yqmlims) WITH object_tab_all-prueflos
*                                   lv_status_c
*                                   lv_user INTO dummy.
*        PERFORM add_message.
*      ENDIF.
*    ENDIF.
*
*    CALL FUNCTION 'STATUS_TEXT_EDIT'
*      EXPORTING
*        objnr            = object_tab_all-objnr
*        flg_user_stat    = g_x
*        spras            = sy-langu
*        bypass_buffer    = g_x
*      IMPORTING
*        line             = object_tab_all-sttxt
*        user_line        = object_tab_all-ustxt
*      EXCEPTIONS
*        object_not_found = 01.
*    IF sy-subrc NE 0.
*      CLEAR object_tab_all-sttxt.
*      CLEAR object_tab_all-ustxt.
*    ENDIF.
*    MODIFY object_tab_all.
*  ENDLOOP.
*
*  IF gv_display_log = 'X'.
*    IF p_log = 'X'.
*      PERFORM display_log.
*    ENDIF.
*    PERFORM save_log.
*  ENDIF.
*
**  Der Screen für den automatischen Verwendungsentscheid wird nicht mehr
**  benötigt. Initial wird direkt der zweite Screen angezeigt
**  PERFORM refresh_object_list.
**
**  IF object_tab[] IS INITIAL.
*  g_view_type = 'KAVE'.
*  PERFORM refresh_object_list.
**  ENDIF.
*
*  IF g_anz_no_auth GT 0.
**   Lose ohne Berechtigung vorhanden
*    MESSAGE s046.
*    CLEAR g_anz_no_auth.
*  ENDIF.


  IF g_submit = 'X'.
* CALL MODUS FOR REFRESH
    EXPORT object_tab TO MEMORY ID g_repid.
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
*  -->  P_SELFIELD                                                    *
*---------------------------------------------------------------------*
FORM user_command_l USING p_ucomm TYPE sy-ucomm
                          p_selfield TYPE slis_selfield.

  DATA: l_subrc       TYPE sy-subrc.
  DATA: l_qals        TYPE qals.
  DATA: l_qave        TYPE qave.
  DATA: l_objnr       TYPE caufvd-objnr.
  DATA: l_ttext       TYPE tstct-ttext .
  DATA: ls_caufv      TYPE caufv.
  DATA: ls_caufvd     TYPE caufvd.
  DATA: ls_t350       TYPE t350.
  DATA: lv_kdauf      TYPE aufk-kdauf.
  DATA: lv_process_ud TYPE flag.
  DATA: lo_attachment TYPE REF TO cl_gos_document_service.
  DATA: ls_object     TYPE borident.
  DATA: lp_attachment TYPE swo_typeid.
  DATA: ls_attachment TYPE sibflporb.
  DATA: ls_params     TYPE rsparams.
  DATA: lt_params     TYPE TABLE OF rsparams.
  DATA: lt_protocol   TYPE TABLE OF rqevp.

  CASE p_ucomm.

    WHEN 'AKTU'.                    " Liste aktualisieren
      p_selfield-refresh = g_s.

      LOOP AT object_tab_all.
        CALL FUNCTION 'STATUS_TEXT_EDIT'
          EXPORTING
            objnr            = object_tab_all-objnr
            flg_user_stat    = g_x
            spras            = sy-langu
            bypass_buffer    = g_x
          IMPORTING
            line             = object_tab_all-sttxt
            user_line        = object_tab_all-ustxt
          EXCEPTIONS
            object_not_found = 01.
        IF sy-subrc NE 0.
          CLEAR object_tab_all-sttxt.
          CLEAR object_tab_all-ustxt.
        ENDIF.
        MODIFY object_tab_all.
      ENDLOOP.
      PERFORM refresh_object_list.

    WHEN 'V-A '.                       " Display<->Change mode
      p_selfield-refresh = g_s.
      PERFORM change_aktyp_l.

    WHEN 'A-V '.                       " Display<->Change mode
      p_selfield-refresh = g_s.
      PERFORM change_aktyp_l.

* Prüfbericht ausdrucken
    WHEN 'PRLS'.
      LOOP AT object_tab WHERE selected = g_x.
        object_tab-viewed = sym_check_mark.
        MODIFY object_tab.

        SET PARAMETER ID 'QLS' FIELD object_tab-prueflos.

        SUBMIT yqmlims_create_certificate AND RETURN.
*        CALL FUNCTION 'ZQM_SERVICE_PB_NEU'
*          EXPORTING
*            i_prueflos = object_tab-prueflos
*          EXCEPTIONS
*            old_pb     = 1
*            OTHERS     = 2.
*        IF sy-subrc = 0.
*          SUBMIT yq0100 AND RETURN.
*        ELSE.
** Transaktion für Material &1 noch nicht freigegeben
*          SUBMIT yq0100_alt AND RETURN.
*        ENDIF.

        LOOP AT object_tab_all
          WHERE prueflos = object_tab-prueflos.
          CALL FUNCTION 'STATUS_TEXT_EDIT'
            EXPORTING
              objnr            = object_tab_all-objnr
              flg_user_stat    = g_x
              spras            = sy-langu
              bypass_buffer    = g_x
            IMPORTING
              line             = object_tab_all-sttxt
              user_line        = object_tab_all-ustxt
            EXCEPTIONS
              object_not_found = 01.
          IF sy-subrc NE 0.
            CLEAR object_tab_all-sttxt.
            CLEAR object_tab_all-ustxt.
          ENDIF.
          MODIFY object_tab_all.
        ENDLOOP.
        object_tab-sttxt = object_tab_all-sttxt.
        object_tab-ustxt = object_tab_all-ustxt.
        MODIFY object_tab.

        p_selfield-refresh = g_x.

      ENDLOOP.

* Prüfberichtsvorschau ausdrucken
    WHEN 'PRLS_PDF'.
      LOOP AT object_tab WHERE selected = g_x.
        object_tab-viewed = sym_check_mark.
        MODIFY object_tab.

        PERFORM preview_pdf USING    object_tab-prueflos
                                     object_tab-werk
                                     space
                            CHANGING g_okcode.

        LOOP AT object_tab_all
          WHERE prueflos = object_tab-prueflos.
          CALL FUNCTION 'STATUS_TEXT_EDIT'
            EXPORTING
              objnr            = object_tab_all-objnr
              flg_user_stat    = g_x
              spras            = sy-langu
              bypass_buffer    = g_x
            IMPORTING
              line             = object_tab_all-sttxt
              user_line        = object_tab_all-ustxt
            EXCEPTIONS
              object_not_found = 01.
          IF sy-subrc NE 0.
            CLEAR object_tab_all-sttxt.
            CLEAR object_tab_all-ustxt.
          ENDIF.
          MODIFY object_tab_all.
        ENDLOOP.
        object_tab-sttxt = object_tab_all-sttxt.
        object_tab-ustxt = object_tab_all-ustxt.
        MODIFY object_tab.

        p_selfield-refresh = g_x.

      ENDLOOP.

* Automatischen Verwendungsentscheid treffen
    WHEN 'VE_AUTO'
      OR 'VE'.

      IF p_ucomm = 'VE_AUTO'.
        g_view_type = 'AVEM'.
      ELSE.
        g_view_type = 'KAVE'.
      ENDIF.

      CLEAR gv_display_log.

      LOOP AT object_tab WHERE selected = 'X'.
        LOOP AT object_tab_all
          WHERE prueflos = object_tab-prueflos.

          SELECT SINGLE kdauf FROM aufk INTO lv_kdauf
             WHERE aufnr = object_tab_all-aufnr.

          IF NOT lv_kdauf IS INITIAL.
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
            ELSE.
*           Sperre kann direkt wieder zurückgenommen werden,
*           da sie beim EInstieg in den VE im Include ZXQEVU07
*           wieder neu gesetzt wird. Beide Schreibsperren zu
*           setzen führt im Gegensatz zur SAP Doku zu einer
*           Fehlermeldung

              CALL FUNCTION 'DEQUEUE_EVVBAKE'
                EXPORTING
                  vbeln = lv_kdauf.
              IF sy-subrc <> 0.
                MESSAGE i022(yqmlims) WITH lv_kdauf.
                CONTINUE.
              ENDIF.

            ENDIF.
          ENDIF.

          CALL FUNCTION 'ENQUEUE_EQQALS1'
            EXPORTING
              mode_qals      = 'E'
*             MANDANT        = SY-MANDT
              prueflos       = object_tab-prueflos
*             X_PRUEFLOS     = ' '
*             _SCOPE         = '2'
*             _WAIT          = ' '
*             _COLLECT       = ' '
            EXCEPTIONS
              foreign_lock   = 1
              system_failure = 2
              OTHERS         = 3.
          IF sy-subrc <> 0.
            MESSAGE i023(yqmlims) WITH object_tab-prueflos.
            CONTINUE.
          ELSE.
*           Sperre kann direkt wieder zurückgenommen werden,
*           da sie beim EInstieg in den VE im Include ZXQEVU07
*           wieder neu gesetzt wird. Beide Schreibsperren zu
*           setzen führt im Gegensatz zur SAP Doku zu einer
*           Fehlermeldung
            CALL FUNCTION 'DEQUEUE_EQQALS1'
              EXPORTING
                prueflos = object_tab-prueflos.
            IF sy-subrc <> 0.
              MESSAGE i023(yqmlims) WITH object_tab-prueflos.
              CONTINUE.
            ENDIF.
          ENDIF.

          CALL FUNCTION 'STATUS_CHECK'
            EXPORTING
              bypass_buffer     = 'X'
              client            = sy-mandt
              objnr             = object_tab_all-objnr
              status            = c_stat_ve
            EXCEPTIONS
              object_not_found  = 1
              status_not_active = 2
              OTHERS            = 3.
          IF sy-subrc = 0.
* VE wurde bereits getroffen
            MESSAGE i309(yqmlims) WITH object_tab_all-prueflos.
            CONTINUE.
          ENDIF.

          IF object_tab-selected = 'X'.
            IF g_view_type = 'AVEM'.
*   Hier noch pro Prüflos sicherstellen, dass keine Merkmale zurückgewiesen sind
              SELECT COUNT( * ) FROM qamr
                WHERE prueflos   = object_tab-prueflos
                AND   satzstatus = '5'
                AND   mbewertg   = 'R'.
              IF sy-subrc <> 0.
                lv_process_ud = 'X'.
              ELSE.
                CLEAR lv_process_ud.
              ENDIF.
            ELSE.
              lv_process_ud = 'X'.
            ENDIF.

            IF lv_process_ud = 'X'.
* Automatischen VE treffen
              PERFORM process_ud USING object_tab_all-prueflos.
            ELSE.
* Status 'KAVE' kein automatischer VE setzen
              lv_status   = stat_kave.
              lv_status_c = c_kave.

              IF NOT lv_status IS INITIAL.
*-- Sperre setzen
                CALL FUNCTION 'ENQUEUE_EQQALS1'
                  EXPORTING
                    prueflos       = object_tab_all-prueflos
                  EXCEPTIONS
                    foreign_lock   = 1
                    system_failure = 2
                    OTHERS         = 3.
                IF sy-subrc EQ 0.                  "Sperre erfolgreich gesetzt
*---- Status KAVE (Kein auto. VE moeglich) setzen
                  CALL FUNCTION 'STATUS_CHANGE_EXTERN'
                    EXPORTING
                      objnr               = object_tab_all-objnr
                      user_status         = lv_status
                    EXCEPTIONS
                      object_not_found    = 1
                      status_inconsistent = 2
                      status_not_allowed  = 3
                      OTHERS              = 4.
*---- Status gesetzt?
                  IF sy-subrc EQ 0.
                    MESSAGE s301(yqmlims) WITH object_tab_all-prueflos
                                               lv_status_c INTO dummy.
                    PERFORM add_message.
                    COMMIT WORK.                     "Status fortschreiben
                  ELSE.
                    MESSAGE e302(yqmlims) WITH object_tab_all-prueflos
                                               lv_status_c INTO dummy.
                    PERFORM add_message.
                  ENDIF.
                ELSE.                              "Fremde Sperre
                  WRITE sy-msgv1 TO lv_user.
                  MESSAGE w303(yqmlims) WITH object_tab_all-prueflos
                                             lv_status_c
                                             lv_user INTO dummy.
                  PERFORM add_message.
                ENDIF.
              ENDIF.
            ENDIF.

            CALL FUNCTION 'STATUS_TEXT_EDIT'
              EXPORTING
                objnr            = object_tab_all-objnr
                flg_user_stat    = g_x
                spras            = sy-langu
                bypass_buffer    = g_x
              IMPORTING
                line             = object_tab_all-sttxt
                user_line        = object_tab_all-ustxt
              EXCEPTIONS
                object_not_found = 01.
            IF sy-subrc NE 0.
              CLEAR object_tab_all-sttxt.
              CLEAR object_tab_all-ustxt.
            ENDIF.
            MODIFY object_tab_all.
          ENDIF.
        ENDLOOP.

      ENDLOOP.

      g_view_type = 'KAVE'.

      IF gv_display_log = 'X'.
        IF p_log = 'X'.
          PERFORM display_log.
        ENDIF.
        PERFORM save_log.
      ENDIF.

      PERFORM refresh_object_list.
      p_selfield-refresh = g_x.

* Ergebnisliste anzeigen
    WHEN 'ERG_LISTE'.

      LOOP AT object_tab WHERE selected = g_x.
        object_tab-viewed = sym_check_mark.
        MODIFY object_tab.

        MOVE-CORRESPONDING object_tab TO l_qals.
        MOVE-CORRESPONDING object_tab TO l_qave.

        CALL FUNCTION 'YQM_QFOA_CREATE_EVALUATION'
          EXPORTING
            i_qals            = l_qals
            i_qave            = l_qave
            i_no_status_check = 'X'
            i_no_editor       = 'X'
          IMPORTING
            e_subrc           = l_subrc.
        CASE l_subrc.
          WHEN 0.
          WHEN OTHERS.
            EXIT.
        ENDCASE.
      ENDLOOP.

* Beurteilung erstellen
    WHEN 'BEUR'.

      p_selfield-refresh = 'X'.

      LOOP AT object_tab WHERE selected = g_x.
        object_tab-viewed = sym_check_mark.
        MODIFY object_tab.

        MOVE-CORRESPONDING object_tab TO l_qals.
        MOVE-CORRESPONDING object_tab TO l_qave.

        CALL FUNCTION 'YQM_QFOA_CREATE_EVALUATION'
          EXPORTING
            i_qals            = l_qals
            i_qave            = l_qave
            i_no_status_check = 'X'
          IMPORTING
            e_subrc           = l_subrc.
        CASE l_subrc.
          WHEN 0.
            MESSAGE s205(yqmlims).
          WHEN 2.
*            MESSAGE i206(yqmlims).
            EXIT.
          WHEN OTHERS.
*            MESSAGE i206(yqmlims).
            EXIT.
        ENDCASE.

        LOOP AT object_tab_all
          WHERE prueflos = object_tab-prueflos.
          CALL FUNCTION 'STATUS_TEXT_EDIT'
            EXPORTING
              objnr            = object_tab_all-objnr
              flg_user_stat    = g_x
              spras            = sy-langu
              bypass_buffer    = g_x
            IMPORTING
              line             = object_tab_all-sttxt
              user_line        = object_tab_all-ustxt
            EXCEPTIONS
              object_not_found = 01.
          IF sy-subrc NE 0.
            CLEAR object_tab_all-sttxt.
            CLEAR object_tab_all-ustxt.
          ENDIF.
          MODIFY object_tab_all.
        ENDLOOP.
        object_tab-sttxt = object_tab_all-sttxt.
        object_tab-ustxt = object_tab_all-ustxt.
        MODIFY object_tab.
      ENDLOOP.

* Gutachten erstellen
    WHEN 'GUTE'.

      p_selfield-refresh = 'X'.

      LOOP AT object_tab WHERE selected = g_x.
        object_tab-viewed = sym_check_mark.
        MODIFY object_tab.
        MOVE-CORRESPONDING object_tab TO l_qals.
        MOVE-CORRESPONDING object_tab TO l_qave.

        CALL FUNCTION 'YQM_QFOA_PRINT_APPRAISAL'
          EXPORTING
            i_qals            = l_qals
            i_qave            = l_qave
            i_no_status_check = 'X'
          IMPORTING
            e_subrc           = l_subrc.
        CASE l_subrc.
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
          WHEN OTHERS  .
            MESSAGE i202(yqmlims).
            EXIT.
        ENDCASE.
        LOOP AT object_tab_all
          WHERE prueflos = object_tab-prueflos.
          CALL FUNCTION 'STATUS_TEXT_EDIT'
            EXPORTING
              objnr            = object_tab_all-objnr
              flg_user_stat    = g_x
              spras            = sy-langu
              bypass_buffer    = g_x
            IMPORTING
              line             = object_tab_all-sttxt
              user_line        = object_tab_all-ustxt
            EXCEPTIONS
              object_not_found = 01.
          IF sy-subrc NE 0.
            CLEAR object_tab_all-sttxt.
            CLEAR object_tab_all-ustxt.
          ENDIF.
          MODIFY object_tab_all.
        ENDLOOP.
        object_tab-sttxt = object_tab_all-sttxt.
        object_tab-ustxt = object_tab_all-ustxt.
        MODIFY object_tab.

      ENDLOOP.

    WHEN 'BEGU'.

      p_selfield-refresh = 'X'.

      LOOP AT object_tab WHERE selected = g_x.
        object_tab-viewed = sym_check_mark.
        MODIFY object_tab.

        MOVE-CORRESPONDING object_tab TO l_qals.
        MOVE-CORRESPONDING object_tab TO l_qave.

        ls_object-objkey  = l_qals-prueflos.
        ls_object-objtype = 'BUS2045'.  "gs_lporb-typeid.

        CREATE OBJECT lo_attachment.
        CALL METHOD lo_attachment->create_attachment
          EXPORTING
            is_object     = ls_object
          IMPORTING
            ep_attachment = lp_attachment.
        IF lp_attachment IS INITIAL.
          MESSAGE s042(sgos_msg).
        ELSE.
          MESSAGE s043(sgos_msg).

          CALL FUNCTION 'STATUS_TEXT_CONVERSION'
            EXPORTING
*             CLIENT             = SY-MANDT
              language           = sy-langu
              mode               = 'E'
              objnr              = l_qals-objnr
*             STSMA              = ' '
              txt04              = 'BEGU'
            IMPORTING
              status_number      = stat_begu
            EXCEPTIONS
              insufficient_input = 1
              not_found          = 2
              object_not_found   = 3
              wrong_mode         = 4
              OTHERS             = 5.
          IF sy-subrc = 0.
            CALL FUNCTION 'STATUS_CHECK'
              EXPORTING
                objnr             = l_qals-objnr
                status            = stat_begu
              EXCEPTIONS
                object_not_found  = 1
                status_not_active = 2
                OTHERS            = 3.
            IF sy-subrc <> 0.
              CALL FUNCTION 'STATUS_CHANGE_EXTERN'
                EXPORTING
                  objnr               = l_qals-objnr
                  user_status         = stat_begu
                EXCEPTIONS
                  object_not_found    = 1
                  status_inconsistent = 2
                  status_not_allowed  = 3
                  OTHERS              = 4.
              IF sy-subrc <> 0.
                MESSAGE s203(yqmlims) WITH l_qals-prueflos.
              ENDIF.
            ENDIF.
            COMMIT WORK.
          ENDIF.
        ENDIF.

        LOOP AT object_tab_all
          WHERE prueflos = object_tab-prueflos.
          CALL FUNCTION 'STATUS_TEXT_EDIT'
            EXPORTING
              objnr            = object_tab_all-objnr
              flg_user_stat    = g_x
              spras            = sy-langu
              bypass_buffer    = g_x
            IMPORTING
              line             = object_tab_all-sttxt
              user_line        = object_tab_all-ustxt
            EXCEPTIONS
              object_not_found = 01.
          IF sy-subrc NE 0.
            CLEAR object_tab_all-sttxt.
            CLEAR object_tab_all-ustxt.
          ENDIF.
          MODIFY object_tab_all.
        ENDLOOP.
        object_tab-sttxt = object_tab_all-sttxt.
        object_tab-ustxt = object_tab_all-ustxt.
        MODIFY object_tab.
      ENDLOOP.

    WHEN 'VEER'. " VE erfassen/ändern

      p_selfield-refresh = 'X'.

      LOOP AT object_tab WHERE selected = g_x.

        SET PARAMETER ID 'QLS' FIELD object_tab-prueflos.
        IF object_tab-kz_qave IS INITIAL.        "kein VE getroffen.
*          EXPORT ausmg
*                 vwerk
*                 cdgrp
*                 code
*                 TO MEMORY ID 'YQM_RQEEAL10'.
*          PERFORM call_transaction_f16 USING 'QA11'.
*          FREE MEMORY ID 'YQM_RQEEAL10'.
          MESSAGE i115(yqmlims) WITH object_tab-prueflos.
          EXIT.
        ELSE.
          PERFORM call_transaction_f16 USING 'QA12'.
        ENDIF.

        LOOP AT object_tab_all
          WHERE prueflos = object_tab-prueflos.
          CALL FUNCTION 'STATUS_TEXT_EDIT'
            EXPORTING
              objnr            = object_tab_all-objnr
              flg_user_stat    = g_x
              spras            = sy-langu
              bypass_buffer    = g_x
            IMPORTING
              line             = object_tab_all-sttxt
              user_line        = object_tab_all-ustxt
            EXCEPTIONS
              object_not_found = 01.
          IF sy-subrc NE 0.
            CLEAR object_tab_all-sttxt.
            CLEAR object_tab_all-ustxt.
          ENDIF.

          SELECT SINGLE stat35 FROM qals
            INTO object_tab_all-kz_qave
            WHERE prueflos = object_tab_all-prueflos.
          MODIFY object_tab_all.
        ENDLOOP.
        object_tab-kz_qave = object_tab_all-kz_qave.
        object_tab-sttxt   = object_tab_all-sttxt.
        object_tab-ustxt   = object_tab_all-ustxt.
        MODIFY object_tab.
      ENDLOOP.
      p_ucomm = 'VEER'.

    WHEN 'CERT_MAIL'.

      p_selfield-refresh = 'X'.

      LOOP AT object_tab WHERE selected = g_x.
        object_tab-viewed = sym_check_mark.
        MODIFY object_tab.

        MOVE-CORRESPONDING object_tab TO l_qals.
        MOVE-CORRESPONDING object_tab TO l_qave.

        CALL FUNCTION 'STATUS_CHECK'
          EXPORTING
            bypass_buffer     = 'X'
            client            = sy-mandt
            objnr             = object_tab-objnr
            status            = c_stat_ve
          EXCEPTIONS
            object_not_found  = 1
            status_not_active = 2
            OTHERS            = 3.
        IF sy-subrc <> 0.
* VE wurde bereits getroffen
          MESSAGE i310(yqmlims) WITH object_tab-prueflos.
          CONTINUE.
        ELSE.
          SELECT SINGLE * FROM qals INTO l_qals
             WHERE prueflos = object_tab-prueflos.
          SELECT SINGLE * FROM qave INTO l_qave
             WHERE prueflos = object_tab-prueflos.
        ENDIF.

        CALL FUNCTION 'YQM_QFOA_CREATE_CERTIFICATE'
          EXPORTING
            i_qals     = l_qals
            i_qave     = l_qave
            i_resend   = 'X'
          IMPORTING
            e_subrc    = l_subrc
          TABLES
            e_protocol = lt_protocol.
        IF l_subrc = 0.
* Messagehandling erfolgt bereits im Baustein
        ENDIF.

        LOOP AT object_tab_all
          WHERE prueflos = object_tab-prueflos.
          CALL FUNCTION 'STATUS_TEXT_EDIT'
            EXPORTING
              objnr            = object_tab_all-objnr
              flg_user_stat    = g_x
              spras            = sy-langu
              bypass_buffer    = g_x
            IMPORTING
              line             = object_tab_all-sttxt
              user_line        = object_tab_all-ustxt
            EXCEPTIONS
              object_not_found = 01.
          IF sy-subrc NE 0.
            CLEAR object_tab_all-sttxt.
            CLEAR object_tab_all-ustxt.
          ENDIF.

          SELECT SINGLE stat35 FROM qals
            INTO object_tab_all-kz_qave
            WHERE prueflos = object_tab_all-prueflos.
          MODIFY object_tab_all.
        ENDLOOP.
        object_tab-kz_qave = object_tab_all-kz_qave.
        object_tab-sttxt   = object_tab_all-sttxt.
        object_tab-ustxt   = object_tab_all-ustxt.
        MODIFY object_tab.

      ENDLOOP.

* Zusätzliche Berichtsempfänger pflegen
    WHEN 'PARTNER'.
      SELECT SINGLE * FROM t350 INTO ls_t350 WHERE auart = '5CSL'.
      LOOP AT object_tab WHERE selected = g_x.
        object_tab-viewed = sym_check_mark.
        MODIFY object_tab.

        CALL FUNCTION 'CO_DB_HEADER_READ'
          EXPORTING
            aufnr     = object_tab-aufnr
*           VSNMR     =
          IMPORTING
*           AFPOWA    =
            caufvwa   = ls_caufv
*           VSNMR_EXP =
          EXCEPTIONS
            not_found = 1
            OTHERS    = 2.
        IF sy-subrc <> 0.
* Implement suitable error handling here
          EXIT.
        ENDIF.

        MOVE-CORRESPONDING ls_caufv TO ls_caufvd.
        CALL FUNCTION 'CO_IH_SET_HEADER'
          EXPORTING
            caufvd_imp = ls_caufvd.

        CONCATENATE 'OR' object_tab-aufnr INTO l_objnr.

        CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
          EXPORTING
            input  = object_tab-aufnr
          IMPORTING
            output = l_ttext.

        CONCATENATE 'Auftrag ' l_ttext INTO l_ttext SEPARATED BY space.

        CALL FUNCTION 'PM_PARTNER_INIT'
          EXPORTING
            tplnr        = object_tab-yqm_tplnr
            aktyp        = 'V'
            objnr        = l_objnr
            obtyp        = 'ORI'
            refresh      = 'X'
            pargr        = ls_t350-pargr
            parvw_kund   = ls_t350-parvw
            parvw_ap     = ' '
            parvw_lief   = ' '
            parvw_int    = ' '
            parvw_vera   = ls_t350-parvw_vera
            parvw_auto   = ' '
            service_flag = ls_t350-service.

        CALL FUNCTION 'PM_PARTNER_DIALOG'
          EXPORTING
            display_only       = 'V'
            tplnr              = object_tab-yqm_tplnr
            objnr              = l_objnr
            obtyp              = 'ORI'
            pargr              = 'QM'
            save               = 'X'
            trans_text         = l_ttext
          EXCEPTIONS
            cancel             = 1
            exit               = 2
            save               = 3
            no_valid_subscreen = 4
            OTHERS             = 5.
        CASE sy-subrc.
          WHEN 3.
            CALL FUNCTION 'PM_PARTNER_CALL_VB'
              EXPORTING
                objnr = l_objnr.

            COMMIT WORK AND WAIT.
          WHEN OTHERS.
        ENDCASE.

        p_selfield-refresh = g_x.

      ENDLOOP.

    WHEN OTHERS.    " codes that require reading items from the list
* Codes are : PLOS QAMV VEAZ QMEL (display or change)
*             PRLS PRZG (print inspection report and certificate)
      PERFORM user_command_f16 USING p_ucomm p_selfield.

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

FORM set_pf_stat_l  USING rt_extab TYPE slis_t_extab.

  IF sy-tcode = 'OQI4'.                " Customizing abklemmen.
    SET PF-STATUS 'CUST' OF PROGRAM 'RQEVAM10' EXCLUDING rt_extab.
    EXIT.
  ELSE.
*--- Tcode aus Parameterübergabe sichern -----------------------------*
    IF g_tcode IS INITIAL.
      IF dy_tcode IS INITIAL.
        g_tcode = sy-tcode.
      ELSE.
        g_tcode = dy_tcode.
      ENDIF.
    ENDIF.
    dy_tcode = g_tcode.

    IF sy-tcode <> 'SE38' AND sy-tcode <> 'SA38'.
      SELECT SINGLE * FROM tstct WHERE sprsl = sy-langu
                                 AND   tcode = t370a-tcode.
    ELSE.
      tstct-ttext = sy-title.
    ENDIF.

    g_aktyp = t370a-aktyp.

    IF g_aktyp IS INITIAL.
      g_aktyp = 'V'.
    ENDIF.
*   Zeugnis
    CALL FUNCTION 'QAUT_CHECK_TCODE'
      EXPORTING
        i_tcode          = 'QC21'
      EXCEPTIONS
        no_authorization = 01.
    IF NOT sy-subrc IS INITIAL. APPEND 'PRZG' TO rt_extab.ENDIF.
*   Prüfbericht
    CALL FUNCTION 'QAUT_CHECK_TCODE'
      EXPORTING
        i_tcode          = 'QGA3'
      EXCEPTIONS
        no_authorization = 01.
    IF NOT sy-subrc IS INITIAL. APPEND 'PRLS' TO rt_extab.ENDIF.

    CASE g_view_type.
      WHEN 'AVEM'.
        SET TITLEBAR 'MAIN_AVEM'.
        APPEND 'BEUR' TO rt_extab.
        APPEND 'VEER' TO rt_extab.
        APPEND 'VEAZ' TO rt_extab.
        APPEND 'PRLS' TO rt_extab.

      WHEN 'KAVE'.
        SET TITLEBAR 'MAIN_KAVE'.
*        APPEND 'VE_AUTO' TO rt_extab.
      WHEN OTHERS.
        SET TITLEBAR 'LVS' WITH tstct-ttext.
    ENDCASE.

    IF g_aktyp = 'V'.
*   Prüflos
      CALL FUNCTION 'QAUT_CHECK_TCODE'
        EXPORTING
          i_tcode          = 'QA02'
        EXCEPTIONS
          no_authorization = 01.
      IF NOT sy-subrc IS INITIAL. APPEND 'PLOS' TO rt_extab.ENDIF.
*   Verwendungsentscheid
      CALL FUNCTION 'QAUT_CHECK_TCODE'
        EXPORTING
          i_tcode          = 'QA11'
        EXCEPTIONS
          no_authorization = 01.
      IF NOT sy-subrc IS INITIAL.
        CALL FUNCTION 'QAUT_CHECK_TCODE'
          EXPORTING
            i_tcode          = 'QA12'
          EXCEPTIONS
            no_authorization = 01.
        IF NOT sy-subrc IS INITIAL. APPEND 'VEAZ' TO rt_extab.ENDIF.
      ENDIF.
*   Ergebnisse
      CALL FUNCTION 'QAUT_CHECK_TCODE'
        EXPORTING
          i_tcode          = 'QE01'
        EXCEPTIONS
          no_authorization = 01.
      IF NOT sy-subrc IS INITIAL.
        CALL FUNCTION 'QAUT_CHECK_TCODE'
          EXPORTING
            i_tcode          = 'QE11'
          EXCEPTIONS
            no_authorization = 01.
        IF NOT sy-subrc IS INITIAL.
          CALL FUNCTION 'QAUT_CHECK_TCODE'
            EXPORTING
              i_tcode          = 'QE14'
            EXCEPTIONS
              no_authorization = 01.
          IF NOT sy-subrc IS INITIAL.  APPEND 'QAMV' TO rt_extab. ENDIF.
        ENDIF.
      ENDIF.
*   Fehler
      CALL FUNCTION 'QAUT_CHECK_TCODE'
        EXPORTING
          i_tcode          = 'QF01'
        EXCEPTIONS
          no_authorization = 01.
      IF NOT sy-subrc IS INITIAL.
        CALL FUNCTION 'QAUT_CHECK_TCODE'
          EXPORTING
            i_tcode          = 'QF02'
          EXCEPTIONS
            no_authorization = 01.
        IF NOT sy-subrc IS INITIAL. APPEND 'QMEL' TO rt_extab.ENDIF.
      ENDIF.
      SET PF-STATUS 'CHANGE' EXCLUDING rt_extab.
    ELSE.
*   Prüflos
      CALL FUNCTION 'QAUT_CHECK_TCODE'
        EXPORTING
          i_tcode          = 'QA03'
        EXCEPTIONS
          no_authorization = 01.
      IF NOT sy-subrc IS INITIAL. APPEND 'PLOS' TO rt_extab.ENDIF.
*   Verwendungsentscheid
      CALL FUNCTION 'QAUT_CHECK_TCODE'
        EXPORTING
          i_tcode          = 'QA13'
        EXCEPTIONS
          no_authorization = 01.
      IF NOT sy-subrc IS INITIAL. APPEND 'VEAZ' TO rt_extab.ENDIF.
*   Ergebnisse
      CALL FUNCTION 'QAUT_CHECK_TCODE'
        EXPORTING
          i_tcode          = 'QE03'
        EXCEPTIONS
          no_authorization = 01.
      IF NOT sy-subrc IS INITIAL. APPEND 'QAMV' TO rt_extab. ENDIF.
*   Fehler
      CALL FUNCTION 'QAUT_CHECK_TCODE'
        EXPORTING
          i_tcode          = 'QF03'
        EXCEPTIONS
          no_authorization = 01.
      IF NOT sy-subrc IS INITIAL. APPEND 'QMEL' TO rt_extab.ENDIF.
      SET PF-STATUS 'MAIN' EXCLUDING rt_extab.
    ENDIF.
  ENDIF.

ENDFORM.                               " SET_PF_STATUS_L

*---------------------------------------------------------------------*
*       FORM CHANGE_AKTYP_l                                       *
*---------------------------------------------------------------------*
*       Aktivitätstyp ändern                                          *
*---------------------------------------------------------------------*
FORM change_aktyp_l.

  DATA:   h_tabarg TYPE t370a-tabarg.
  DATA:   h_programm TYPE t370a-programm.
  DATA:   h_retc TYPE sy-subrc.
  DATA:   h_tcode TYPE t370a-tcode.

*--- Daten aus Kopfzeile Tabelle merken ----------------------------*
  h_tabarg   = t370a-tabarg.
  h_programm = t370a-programm.
  h_tcode    = t370a-tcode.

  CHECK sy-subrc = 0.

  IF g_aktyp = 'A'.
    SELECT        * FROM  t370a
           WHERE  programm    = h_programm
           AND    tabarg      = h_tabarg
           AND    aktyp      <> g_aktyp.
      EXIT.
    ENDSELECT.
  ELSE.
    SELECT        * FROM  t370a
           WHERE  tcode       = sy-tcode
           AND    tabarg      = h_tabarg
           AND    aktyp      <> g_aktyp.
      EXIT.
    ENDSELECT.
    SELECT        * FROM  t370a
           WHERE  programm    = h_programm
           AND    tabarg      = h_tabarg
           AND    aktyp      <> g_aktyp.
      EXIT.
    ENDSELECT.
  ENDIF.
  IF h_tcode CP 'Q*'.
*--- Berechtigungsobject Q_Tcode  ------------------------------*
    AUTHORITY-CHECK OBJECT 'Q_TCODE'
                        ID 'TCD' FIELD t370a-tcode.
    h_retc = sy-subrc.
  ENDIF.
  IF h_retc IS INITIAL.
    IF g_aktyp = 'A'.
      g_aktyp = 'V'.
    ELSE.
      g_aktyp = 'A'.
    ENDIF.

*--- Berechtigung ok ------------------------------------------------*
    SELECT SINGLE * FROM tstct WHERE sprsl = sy-langu
                               AND   tcode = t370a-tcode.
    PERFORM set_pf_stat_l USING gt_extab.
  ELSE.
*--- keine Berecht. -> Kopfzeile muß urspünglichen Eintrag haben ----*
    SELECT SINGLE * FROM t370a WHERE tcode = h_tcode.
  ENDIF.

ENDFORM.                    "change_aktyp_l

*---------------------------------------------------------------------*
*       FORM CREATE_FIELDCAT_L                                        *
*---------------------------------------------------------------------*
*       create g_fieldcat_tab for DDIC structure                      *
*---------------------------------------------------------------------*
*  -->  TABNAME  (DDIC-Structure for Report-Output)                   *
*---------------------------------------------------------------------*
FORM create_fieldcat_l USING tabname TYPE slis_tabname.

  DATA h_fieldcat_wa TYPE slis_fieldcat_alv.
  DATA h_index       TYPE sy-tabix.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      i_program_name         = g_repid
      i_internal_tabname     = 'OBJECT_TAB'
      i_structure_name       = tabname
      i_client_never_display = ' '
    CHANGING
      ct_fieldcat            = g_fieldcat_tab[]
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.

  IF sy-subrc IS INITIAL.
    SORT g_fieldcat_tab BY key DESCENDING.
    h_index = 1.
    DO.
*--- change key fields to 'normal' fields
      READ TABLE g_fieldcat_tab INTO h_fieldcat_wa INDEX h_index.
      IF sy-subrc IS INITIAL AND h_fieldcat_wa-key = g_x.
        h_fieldcat_wa-key = space.
        MODIFY g_fieldcat_tab FROM h_fieldcat_wa INDEX h_index.
        h_index = h_index + 1.
      ELSE.
        EXIT.
      ENDIF.
    ENDDO.

* add column 'viewed' to field catalog.
    PERFORM add_viewed_column_f14.

    LOOP AT g_fieldcat_tab INTO h_fieldcat_wa.
*--- change field header texts for better understanding
* material fields have same heading, as do the 'SEL*' fields, 'item'
* fields and one or two others.

      IF h_fieldcat_wa-fieldname EQ 'VIEWED'.
        h_fieldcat_wa-seltext_l = TEXT-vd1.
        h_fieldcat_wa-seltext_s = TEXT-vd2.
        h_fieldcat_wa-ddictxt   = 'S'.
        MODIFY g_fieldcat_tab FROM h_fieldcat_wa.

      ELSEIF h_fieldcat_wa-fieldname EQ 'EMATNR'.
        h_fieldcat_wa-seltext_l = TEXT-fd1.
        MODIFY g_fieldcat_tab FROM h_fieldcat_wa.

      ELSEIF h_fieldcat_wa-fieldname EQ 'MATNRNEU'.
        h_fieldcat_wa-seltext_l = TEXT-fd2.
        MODIFY g_fieldcat_tab FROM h_fieldcat_wa.

      ELSEIF h_fieldcat_wa-fieldname EQ 'SELMATNR'.
        h_fieldcat_wa-seltext_l = TEXT-fd3.
        MODIFY g_fieldcat_tab FROM h_fieldcat_wa.

      ELSEIF h_fieldcat_wa-fieldname EQ 'CHARGNEU'.
        h_fieldcat_wa-seltext_l = TEXT-fd4.
        MODIFY g_fieldcat_tab FROM h_fieldcat_wa.

      ELSEIF h_fieldcat_wa-fieldname EQ 'SELKUNNR'.
        h_fieldcat_wa-seltext_l = TEXT-fd5.
        MODIFY g_fieldcat_tab FROM h_fieldcat_wa.

      ELSEIF h_fieldcat_wa-fieldname EQ 'SELHERST'.
        h_fieldcat_wa-seltext_l = TEXT-fd6.
        MODIFY g_fieldcat_tab FROM h_fieldcat_wa.

      ELSEIF h_fieldcat_wa-fieldname EQ 'SELLIFNR'.
        h_fieldcat_wa-seltext_l = TEXT-fd7.
        MODIFY g_fieldcat_tab FROM h_fieldcat_wa.

      ELSEIF h_fieldcat_wa-fieldname EQ 'SELREVLV'.
        h_fieldcat_wa-seltext_l = TEXT-fd9.
        MODIFY g_fieldcat_tab FROM h_fieldcat_wa.

      ELSEIF h_fieldcat_wa-fieldname EQ 'SELPPLVERW'.
        h_fieldcat_wa-seltext_l = TEXT-fd8.
        MODIFY g_fieldcat_tab FROM h_fieldcat_wa.

      ELSEIF h_fieldcat_wa-fieldname EQ 'SELWERK'.
        h_fieldcat_wa-seltext_l = TEXT-fd0.
        MODIFY g_fieldcat_tab FROM h_fieldcat_wa.

      ELSEIF h_fieldcat_wa-fieldname EQ 'ZEILE'.
        h_fieldcat_wa-seltext_l = TEXT-fe1.
        MODIFY g_fieldcat_tab FROM h_fieldcat_wa.

      ELSEIF h_fieldcat_wa-fieldname EQ 'EBELP'.
        h_fieldcat_wa-seltext_l = TEXT-fe2.
        MODIFY g_fieldcat_tab FROM h_fieldcat_wa.
        h_index = h_index + 1.

      ELSEIF h_fieldcat_wa-fieldname EQ 'LS_POSNR'.
        h_fieldcat_wa-seltext_l = TEXT-fe3.
        MODIFY g_fieldcat_tab FROM h_fieldcat_wa.

      ELSEIF h_fieldcat_wa-fieldname EQ 'LS_KDAUF'.
        h_fieldcat_wa-seltext_l = TEXT-fe4.
        MODIFY g_fieldcat_tab FROM h_fieldcat_wa.

      ELSEIF h_fieldcat_wa-fieldname EQ 'LS_KDPOS'.
        h_fieldcat_wa-seltext_l = TEXT-fe5.
        MODIFY g_fieldcat_tab FROM h_fieldcat_wa.

      ENDIF.
    ENDLOOP.
  ENDIF.

* The fieldcat is exported to memory here, because this form is called
* in other reports to avoid duplicate text maintenance.
  IF g_repid NE sy-repid.
    EXPORT g_fieldcat_tab TO MEMORY ID 'FIELDCATALOG'.
  ENDIF.

ENDFORM.                               " CREATE_FIELDCAT_L
*FORM create_fieldcat_l  USING tabname TYPE slis_tabname.
*
*
*  DATA h_fieldcat_wa TYPE slis_fieldcat_alv.
*  DATA h_index       TYPE sy-tabix.
*
*  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
*    EXPORTING
*      i_program_name         = g_repid
*      i_internal_tabname     = 'OBJECT_TAB'
*      i_structure_name       = tabname
*      i_client_never_display = ' '
*    CHANGING
*      ct_fieldcat            = g_fieldcat_tab[]
*    EXCEPTIONS
*      inconsistent_interface = 1
*      program_error          = 2
*      OTHERS                 = 3.
*
*  IF sy-subrc IS INITIAL.
*    SORT g_fieldcat_tab BY key DESCENDING.
*    h_index = 1.
*    DO.
**--- change key fields to 'normal' fields
*      READ TABLE g_fieldcat_tab INTO h_fieldcat_wa INDEX h_index.
*      IF sy-subrc IS INITIAL AND h_fieldcat_wa-key = g_x.
*        h_fieldcat_wa-key = space.
*        MODIFY g_fieldcat_tab FROM h_fieldcat_wa INDEX h_index.
*        h_index = h_index + 1.
*      ELSE.
*        EXIT.
*      ENDIF.
*    ENDDO.
** add column 'viewed' to field catalog.
*    PERFORM add_viewed_column_f14.
*
*    LOOP AT g_fieldcat_tab INTO h_fieldcat_wa.
**--- change field header texts for better understanding
** material fields have same heading, as do the 'SEL*' fields, 'item'
** fields and one or two others.
*
*      IF h_fieldcat_wa-fieldname EQ 'VIEWED'.
*        MOVE TEXT-vd1  TO h_fieldcat_wa-seltext_l.
*        MOVE TEXT-vd2  TO h_fieldcat_wa-seltext_s.
*        h_fieldcat_wa-ddictxt = 'S'.
*        MODIFY g_fieldcat_tab FROM h_fieldcat_wa.
*      ELSEIF h_fieldcat_wa-fieldname EQ 'EMATNR'.
*        MOVE TEXT-fd1  TO h_fieldcat_wa-seltext_l.
*        MODIFY g_fieldcat_tab FROM h_fieldcat_wa.
*      ELSEIF h_fieldcat_wa-fieldname EQ 'MATNRNEU'.
*        MOVE TEXT-fd2  TO h_fieldcat_wa-seltext_l.
*        MODIFY g_fieldcat_tab FROM h_fieldcat_wa.
*      ELSEIF h_fieldcat_wa-fieldname EQ 'SELMATNR'.
*        MOVE TEXT-fd3  TO h_fieldcat_wa-seltext_l.
*        MODIFY g_fieldcat_tab FROM h_fieldcat_wa.
*      ELSEIF h_fieldcat_wa-fieldname EQ 'CHARGNEU'.
*        MOVE TEXT-fd4  TO h_fieldcat_wa-seltext_l.
*        MODIFY g_fieldcat_tab FROM h_fieldcat_wa.
*      ELSEIF h_fieldcat_wa-fieldname EQ 'SELKUNNR'.
*        MOVE TEXT-fd5  TO h_fieldcat_wa-seltext_l.
*        MODIFY g_fieldcat_tab FROM h_fieldcat_wa.
*      ELSEIF h_fieldcat_wa-fieldname EQ 'SELHERST'.
*        MOVE TEXT-fd6  TO h_fieldcat_wa-seltext_l.
*        MODIFY g_fieldcat_tab FROM h_fieldcat_wa.
*      ELSEIF h_fieldcat_wa-fieldname EQ 'SELLIFNR'.
*        MOVE TEXT-fd7  TO h_fieldcat_wa-seltext_l.
*        MODIFY g_fieldcat_tab FROM h_fieldcat_wa.
*      ELSEIF h_fieldcat_wa-fieldname EQ 'SELREVLV'.
*        MOVE TEXT-fd9  TO h_fieldcat_wa-seltext_l.
*        MODIFY g_fieldcat_tab FROM h_fieldcat_wa.
*      ELSEIF h_fieldcat_wa-fieldname EQ 'SELPPLVERW'.
*        MOVE TEXT-fd8  TO h_fieldcat_wa-seltext_l.
*        MODIFY g_fieldcat_tab FROM h_fieldcat_wa.
*      ELSEIF h_fieldcat_wa-fieldname EQ 'SELWERK'.
*        MOVE TEXT-fd0 TO h_fieldcat_wa-seltext_l.
*        MODIFY g_fieldcat_tab FROM h_fieldcat_wa.
*      ELSEIF h_fieldcat_wa-fieldname EQ 'ZEILE'.
*        MOVE TEXT-fe1  TO h_fieldcat_wa-seltext_l.
*        MODIFY g_fieldcat_tab FROM h_fieldcat_wa.
*      ELSEIF h_fieldcat_wa-fieldname EQ 'EBELP'.
*        MOVE TEXT-fe2  TO h_fieldcat_wa-seltext_l.
*        MODIFY g_fieldcat_tab FROM h_fieldcat_wa.
*        h_index = h_index + 1.
*      ELSEIF h_fieldcat_wa-fieldname EQ 'LS_POSNR'.
*        MOVE TEXT-fe3  TO h_fieldcat_wa-seltext_l.
*        MODIFY g_fieldcat_tab FROM h_fieldcat_wa.
*      ELSEIF h_fieldcat_wa-fieldname EQ 'LS_KDAUF'.
*        MOVE TEXT-fe4  TO h_fieldcat_wa-seltext_l.
*        MODIFY g_fieldcat_tab FROM h_fieldcat_wa.
*      ELSEIF h_fieldcat_wa-fieldname EQ 'LS_KDPOS'.
*        MOVE TEXT-fe5  TO h_fieldcat_wa-seltext_l.
*        MODIFY g_fieldcat_tab FROM h_fieldcat_wa.
*
*      ENDIF.
*    ENDLOOP.
*  ENDIF.
*
** The fieldcat is exported to memory here, because this form is called
** in other reports to avoid duplicate text maintenance.
*  IF g_repid NE sy-repid.
*    EXPORT g_fieldcat_tab TO MEMORY ID 'FIELDCATALOG'.
*  ENDIF.
*ENDFORM.                               " CREATE_FIELDCAT_L

*&---------------------------------------------------------------------*
*&      Form  CALL_MIGO_DIALOG
*&---------------------------------------------------------------------*
*       MIGO has to be called via function module
*----------------------------------------------------------------------*
*FORM call_migo_dialog.
*
*  DATA l_mblnr TYPE qals-mblnr.
*  DATA l_mjahr TYPE qals-mjahr.
*  DATA l_zeile TYPE qals-zeile.
*
*  GET PARAMETER ID 'MBN' FIELD object_tab-mblnr.
*  GET PARAMETER ID 'MJA' FIELD object_tab-mjahr.
*  GET PARAMETER ID 'POS' FIELD object_tab-zeile.
*
*  MOVE object_tab-mblnr TO l_mblnr.
*  MOVE object_tab-mjahr TO l_mjahr.
*  MOVE object_tab-zeile TO l_zeile.
*
*  CALL FUNCTION 'MIGO_DIALOG'
*    EXPORTING
*      i_action            = 'A04'
*      i_refdoc            = 'R02'
*      i_notree            = 'X'
**     I_NO_AUTH_CHECK     =
**     I_SKIP_FIRST_SCREEN = 'X'
*      i_deadend           = 'X'
**     I_OKCODE            = 'OK_GO'
**     I_LEAVE_AFTER_POST  =
**     I_NEW_ROLLAREA      = 'X'
**     I_SYTCODE           =
**     I_EBELN             =
**     I_EBELP             =
*      i_mblnr             = l_mblnr
*      i_mjahr             = l_mjahr
*      i_zeile             = l_zeile
*    EXCEPTIONS
*      illegal_combination = 1
*      OTHERS              = 2.
*  IF sy-subrc <> 0.
** MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
**         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
*  ENDIF.
*
*ENDFORM.                               " CALL_MIGO_DIALOG
*&---------------------------------------------------------------------*
*&      Form  DELIVERY_DISPLAY
*&---------------------------------------------------------------------*
*       Delivery has to be called via function module (VL03N or VL33N)
*----------------------------------------------------------------------*
*FORM delivery_display.
*
** Local declarations
*  DATA l_vbeln TYPE likp-vbeln.
*
*  GET PARAMETER ID 'VL' FIELD object_tab-ls_vbeln.
*  MOVE object_tab-ls_vbeln TO l_vbeln.
*
** Display delivery
*  CALL FUNCTION 'RV_CALL_DISPLAY_TRANSACTION'
*    EXPORTING
*      vbeln = l_vbeln.
*
*ENDFORM.                               " DELIVERY_DISPLAY
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
FORM select_fields_manip_l  USING
                            p_fieldcat_tab TYPE slis_t_fieldcat_alv .
  DATA: l_fieldcat   TYPE slis_fieldcat_alv,
        l_table_qals TYPE rsfs_tab_fields,
        l_tabix_qals TYPE sy-tabix,
        l_table_qave TYPE rsfs_tab_fields,
        l_tabix_qave TYPE sy-tabix.

  BREAK fisch50.

  READ TABLE select_fields WITH KEY tablename = 'QALS'
                                        INTO l_table_qals.
  MOVE sy-tabix TO l_tabix_qals.

  IF g_repid CS 'RQEEAL10'.
    READ TABLE select_fields WITH KEY tablename = 'QAVP'
                                          INTO l_table_qave.
  ELSE.
    READ TABLE select_fields WITH KEY tablename = 'QAVE'
                                          INTO l_table_qave.
  ENDIF.

  MOVE sy-tabix TO l_tabix_qave.

* Zu selektierende Felder festlegen
*   nur Felder die angezeigt werden
  LOOP AT p_fieldcat_tab INTO l_fieldcat
       WHERE no_out EQ space.
*   Auswerten der Felder
    IF    l_fieldcat-fieldname EQ 'LIGHTS'
       OR l_fieldcat-fieldname EQ 'VIEWED'
       OR l_fieldcat-fieldname EQ 'STTXT'
       OR l_fieldcat-fieldname EQ 'USTXT'
       OR l_fieldcat-fieldname EQ 'VORNR'
       OR l_fieldcat-fieldname EQ 'VORGLFNR'
       OR l_fieldcat-fieldname EQ 'VORKTXT'
       OR l_fieldcat-fieldname EQ 'PRPLATZ'
       OR l_fieldcat-fieldname EQ 'PRPLATZWRK'
       OR l_fieldcat-fieldname EQ 'PRPLATZTXT'.

* nichts zu tun.

* Felder der QAVP
    ELSEIF l_fieldcat-fieldname EQ 'QKENNZAHL'
        OR l_fieldcat-fieldname EQ 'VBEWERTUNG'
        OR l_fieldcat-fieldname EQ 'KZART'
        OR l_fieldcat-fieldname EQ 'VKATART'
        OR l_fieldcat-fieldname EQ 'VAUSWAHLMG'
        OR l_fieldcat-fieldname EQ 'VCODEGRP'
        OR l_fieldcat-fieldname EQ 'VCODE'
        OR l_fieldcat-fieldname EQ 'DBEWERTUNG'
        OR l_fieldcat-fieldname EQ 'VAENAME'
        OR l_fieldcat-fieldname EQ 'VNAME'
        OR l_fieldcat-fieldname EQ 'VDATUM'
        OR l_fieldcat-fieldname EQ 'VEZEITERF'
        OR l_fieldcat-fieldname EQ 'VEZEITAEN'
        OR l_fieldcat-fieldname EQ 'VFOLGEAKTI'
* add additional fields for CWM
       OR l_fieldcat-fieldname EQ '/CWM/LOSMENGE'
       OR l_fieldcat-fieldname EQ '/CWM/MENGEINH2Q'
        OR l_fieldcat-fieldname EQ 'VAEDATUM'.
* above fields are not contained in QALS- therefore they cannot be read.
*     indicator for UD
      MOVE g_x TO g_qave_flag.
*     Positioniert auf Tabellenzeile
      READ TABLE l_table_qave-fields
                 WITH KEY line = l_fieldcat-fieldname
                 BINARY SEARCH TRANSPORTING NO FIELDS.
      IF NOT sy-subrc IS INITIAL.
*       Feld noch nicht in Tabelle
        INSERT l_fieldcat-fieldname
               INTO l_table_qave-fields INDEX sy-tabix.
      ENDIF.
*
    ELSE.
*     Positioniert auf Tabellenzeile
      READ TABLE l_table_qals-fields
                 WITH KEY line = l_fieldcat-fieldname
                 BINARY SEARCH TRANSPORTING NO FIELDS.
      IF NOT sy-subrc IS INITIAL.
*       Feld noch nicht in Tabelle
        INSERT l_fieldcat-fieldname
              INTO l_table_qals-fields INDEX sy-tabix.
      ENDIF.
    ENDIF.
  ENDLOOP.
*
  MODIFY select_fields FROM l_table_qave INDEX l_tabix_qave.
  MODIFY select_fields FROM l_table_qals INDEX l_tabix_qals.
ENDFORM.                               " SELECT_FIELDS_MANIP_L
*&---------------------------------------------------------------------*
*&      Form  CODE_AUSWAHL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM code_auswahl .

  DATA:  ls_qpk1ac          TYPE qpk1ac.
*
  IF p_ausmg IS INITIAL. MOVE gv_stern TO p_ausmg. ENDIF.
  IF p_vwerk IS INITIAL. MOVE gv_stern TO p_vwerk. ENDIF.
  IF p_cdgrp IS INITIAL. MOVE gv_stern TO p_cdgrp. ENDIF.
  IF p_code  IS INITIAL. MOVE gv_stern TO p_code. ENDIF.
*
  CALL FUNCTION 'QPK1_UD_CODE_PICKUP_LEAN'
    EXPORTING
      i_werks              = p_vwerk
      i_auswahlmge         = p_ausmg
      i_codegruppe         = p_cdgrp
      i_code               = p_code
      i_no_usageindication = 'X'
    IMPORTING
      e_qpk1ac             = ls_qpk1ac
    EXCEPTIONS
      OTHERS               = 1.
  IF NOT sy-subrc IS INITIAL.
*-- Fehlermeldung wurde ausgelöst! -> Als I-Meldung ausgeben !
    MESSAGE ID sy-msgid TYPE 'I' NUMBER sy-msgno
          WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    EXIT.
  ENDIF.

  MOVE ls_qpk1ac-werks        TO p_vwerk.
  MOVE ls_qpk1ac-auswahlmge   TO p_ausmg.
  MOVE ls_qpk1ac-codegruppe   TO p_cdgrp.
  MOVE ls_qpk1ac-code         TO p_code.

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
    WHERE art EQ c_pruefart.
  IF sy-subrc NE 0.                    "kein Eintrag gefunden'
    MESSAGE a005 WITH c_pruefart.
  ENDIF.
  IF tq30-stsma IS INITIAL.            "kein Statusschema zugeordnet
    MESSAGE a006 WITH c_pruefart.
  ENDIF.
* Interne Nummern der Anwenderstatus ermitteln
* zuerst fuer Anwenderstatus ERGM
  CALL FUNCTION 'STATUS_TEXT_CONVERSION'
    EXPORTING
      language           = sy-langu
      mode               = 'E'  "Anwenderstatus
      stsma              = tq30-stsma
      txt04              = c_ergm
    IMPORTING
      status_number      = stat_ergm
    EXCEPTIONS
      insufficient_input = 1
      not_found          = 2
      object_not_found   = 3
      wrong_mode         = 4
      OTHERS             = 5.
  IF sy-subrc NE 0.
    MESSAGE a007 WITH c_avem tq30-stsma.
  ENDIF.

* dann fuer Anwenderstatus AVEM
  CALL FUNCTION 'STATUS_TEXT_CONVERSION'
    EXPORTING
      language           = sy-langu
      mode               = 'E'  "Anwenderstatus
      stsma              = tq30-stsma
      txt04              = c_avem
    IMPORTING
      status_number      = stat_avem
    EXCEPTIONS
      insufficient_input = 1
      not_found          = 2
      object_not_found   = 3
      wrong_mode         = 4
      OTHERS             = 5.
  IF sy-subrc NE 0.
    MESSAGE a007 WITH c_avem tq30-stsma.
  ENDIF.
* dann fuer Anwenderstatus KAVE
  CALL FUNCTION 'STATUS_TEXT_CONVERSION'
    EXPORTING
      language           = sy-langu
      mode               = 'E'  "Anwenderstatus
      stsma              = tq30-stsma
      txt04              = c_kave
    IMPORTING
      status_number      = stat_kave
    EXCEPTIONS
      insufficient_input = 1
      not_found          = 2
      object_not_found   = 3
      wrong_mode         = 4
      OTHERS             = 5.
  IF sy-subrc NE 0.
    MESSAGE a007 WITH c_kave tq30-stsma.
  ENDIF.
* und fuer Anwenderstatus GUTE
  CALL FUNCTION 'STATUS_TEXT_CONVERSION'
    EXPORTING
      language           = sy-langu
      mode               = 'E'  "Anwenderstatus
      stsma              = tq30-stsma
      txt04              = c_gute
    IMPORTING
      status_number      = stat_gute
    EXCEPTIONS
      insufficient_input = 1
      not_found          = 2
      object_not_found   = 3
      wrong_mode         = 4
      OTHERS             = 5.
  IF sy-subrc NE 0.
    MESSAGE a007 WITH c_gute tq30-stsma.
  ENDIF.

ENDFORM.                    " CHECK_STATUS_SETTINGS
*&---------------------------------------------------------------------*
*&      Form  REFRESH_OBJECT_LIST
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_G_VIEW_TYPE  text
*----------------------------------------------------------------------*
FORM refresh_object_list.

  REFRESH object_tab.

  LOOP AT object_tab_all.
*    CASE g_view_type.
*      WHEN 'AVEM'.
**---- Status AVEM (Auto. VE moeglich)
*        CALL FUNCTION 'STATUS_CHECK'
*          EXPORTING
*            bypass_buffer     = 'X'
*            client            = sy-mandt
*            objnr             = object_tab_all-objnr
*            status            = stat_avem
*          EXCEPTIONS
*            object_not_found  = 1
*            status_not_active = 2
*            OTHERS            = 3.
*        IF sy-subrc <> 0.
*          CONTINUE.
*        ENDIF.
*
**-- Pruefen, ob VE erlaubt
*        CALL FUNCTION 'QAST_PROCESS_ACTIVITY'
*          EXPORTING
*            i_check_only         = 'X'
*            i_dialog             = space
*            i_objnr              = object_tab_all-objnr
*            i_vorgang            = 'QM20'  "Einstieg VE
*          EXCEPTIONS
*            not_allowed          = 01
*            activity_not_allowed = 02.
*        IF sy-subrc NE 0.                  "VE nicht erlaubt
*          CONTINUE.
*        ENDIF.
*
*
*      WHEN 'KAVE'.
**---- Status KAVE (Kein Auto. VE moeglich)
*        CALL FUNCTION 'STATUS_CHECK'
*          EXPORTING
*            bypass_buffer     = 'X'
*            client            = sy-mandt
*            objnr             = object_tab_all-objnr
*            status            = stat_kave
*          EXCEPTIONS
*            object_not_found  = 1
*            status_not_active = 2
*            OTHERS            = 3.
*        IF sy-subrc <> 0.
**         Kein Auto VE möglich
**         Wurde VE bereits getroffen?
*          IF p_no_ud  = 'X'
*          OR p_no_uda = 'X'.
*            CALL FUNCTION 'STATUS_CHECK'
*              EXPORTING
*                bypass_buffer     = 'X'
*                client            = sy-mandt
*                objnr             = object_tab_all-objnr
*                status            = c_stat_ve
*              EXCEPTIONS
*                object_not_found  = 1
*                status_not_active = 2
*                OTHERS            = 3.
*            IF sy-subrc = 0.
*              CONTINUE.
*            ENDIF.
*          ELSEIF p_ud = 'X'.
*            CALL FUNCTION 'STATUS_CHECK'
*              EXPORTING
*                bypass_buffer     = 'X'
*                client            = sy-mandt
*                objnr             = object_tab_all-objnr
*                status            = c_stat_ve
*              EXCEPTIONS
*                object_not_found  = 1
*                status_not_active = 2
*                OTHERS            = 3.
*            IF sy-subrc <> 0.
*              CONTINUE.
*            ENDIF.
*          ENDIF.
*        ENDIF.
*
*    ENDCASE.

    IF p_no_ud  = 'X'
    OR p_no_uda = 'X'.
      CALL FUNCTION 'STATUS_CHECK'
        EXPORTING
          bypass_buffer     = 'X'
          client            = sy-mandt
          objnr             = object_tab_all-objnr
          status            = c_stat_ve
        EXCEPTIONS
          object_not_found  = 1
          status_not_active = 2
          OTHERS            = 3.
      IF sy-subrc = 0.
        CONTINUE.
      ENDIF.
    ELSEIF p_ud = 'X'.
      CALL FUNCTION 'STATUS_CHECK'
        EXPORTING
          bypass_buffer     = 'X'
          client            = sy-mandt
          objnr             = object_tab_all-objnr
          status            = c_stat_ve
        EXCEPTIONS
          object_not_found  = 1
          status_not_active = 2
          OTHERS            = 3.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
    ENDIF.

    MOVE-CORRESPONDING object_tab_all TO object_tab.
    APPEND object_tab.
  ENDLOOP.

ENDFORM.                    " REFRESH_OBJECT_LIST
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
  CLEAR ls_msg.
  ls_msg-msgty     = sy-msgty.
  ls_msg-msgid     = sy-msgid.
  ls_msg-msgno     = sy-msgno.
  ls_msg-msgv1     = sy-msgv1.
  ls_msg-msgv2     = sy-msgv2.
  ls_msg-msgv3     = sy-msgv3.
  ls_msg-msgv4     = sy-msgv4.
*  ls_msg-probclass = i_probclass.

* Diese Nachricht zum LOG hinzufügen:
  CALL FUNCTION 'BAL_LOG_MSG_ADD'
    EXPORTING
      i_log_handle  = l_log_handle
      i_s_msg       = ls_msg
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
      e_s_display_profile = l_s_display_profile
    EXCEPTIONS
      OTHERS              = 1.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
             WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

* use grid for display if wanted
  l_s_display_profile-use_grid = 'X'.
  l_s_display_profile-not_empty = 'X'.

  l_s_display_profile-start_col = 1.
  l_s_display_profile-start_row = 1.
  l_s_display_profile-end_col   = 100.
  l_s_display_profile-end_row   = 25.


* set report to allow saving of variants
  l_s_display_profile-disvariant-report = sy-repid.

* call display function module
* We do not specify any filter (type I_S_LOG_FILTER, ...,
* I_T_MSG_HANDLE) since we want to display all logs available
  CALL FUNCTION 'BAL_DSP_LOG_DISPLAY'
    EXPORTING
      i_s_display_profile = l_s_display_profile
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
FORM process_ud  USING p_prueflos.

  DATA: l_mode           TYPE bdc_struc-bdcmode VALUE 'N' .
  DATA: l_preview_pdf    TYPE qkz.
  DATA: l_process_ud     TYPE qkz.
  DATA: l_estat_pbio     TYPE j_status.

  CLEAR l_process_ud.

* Durch drücken des Buttons Auto VE in Verbindung mit dem
* Prüflosstatus AVEM wird die Anzeige des pdf unterdrückt
  CASE g_view_type.
    WHEN 'AVEM'.
      IF object_tab-ustxt CS 'AVEM'.
        CLEAR l_preview_pdf.
      ELSE.
        l_preview_pdf = 'X'.
      ENDIF.
    WHEN 'KAVE'.
      l_preview_pdf = 'X'.
    WHEN OTHERS.
      l_preview_pdf = 'X'.
  ENDCASE.

  IF l_preview_pdf IS INITIAL.
    l_process_ud = 'X'.
  ELSE.

    PERFORM preview_pdf USING object_tab-prueflos
                              object_tab-werk
                              'X'
                        CHANGING g_okcode.

    IF g_okcode = 'CANC'.
      EXIT.
    ENDIF.

    IF l_estat_pbio IS INITIAL.
      CALL FUNCTION 'STATUS_TEXT_CONVERSION'
        EXPORTING
          language           = sy-langu
          mode               = 'E'
          objnr              = object_tab-objnr
          txt04              = 'PBIO'
        IMPORTING
          status_number      = l_estat_pbio
        EXCEPTIONS
          insufficient_input = 1
          not_found          = 2
          object_not_found   = 3
          wrong_mode         = 4
          OTHERS             = 5.
      IF sy-subrc <> 0.
* Implement suitable error handling here
      ENDIF.
    ENDIF.

    CALL FUNCTION 'STATUS_CHECK'
      EXPORTING
        bypass_buffer     = 'X'
*       CLIENT            = SY-MANDT
        objnr             = object_tab-objnr
        status            = l_estat_pbio
      EXCEPTIONS
        object_not_found  = 1
        status_not_active = 2
        OTHERS            = 3.
    IF sy-subrc <> 0.
* Vor dem Treffen des VE muss der Prüfbericht angenommen werden
* Implement suitable error handling here
      MESSAGE s308(yqmlims) WITH object_tab_all-prueflos
                                 INTO dummy.
    ELSE.
      l_process_ud = 'X'.
    ENDIF.
  ENDIF.

  IF     l_process_ud = 'X'.
    CALL FUNCTION 'QAVE_PROCESS_AUTO_UD'
      EXPORTING
        i_lot                = p_prueflos
        i_selected_set       = p_ausmg
        i_plant_selected_set = p_vwerk
        i_ud_code            = p_code
        i_ud_codegroup       = p_cdgrp
        i_text_line          = TEXT-j00
        i_stock_posting      = space
        i_process_mode       = l_mode
        i_origin_ud          = 'B'
      EXCEPTIONS
        error_occured        = 1
        not_posted           = 1
        foreign_lock         = 2
        lock_error           = 2.
    CASE sy-subrc.
      WHEN 0.
        MESSAGE s304(yqmlims) WITH object_tab_all-prueflos
                                   INTO dummy.
        PERFORM add_message.
      WHEN 1.
        IF  sy-msgid = '00'
        AND sy-msgno = '344'.
* Langtext kann im Batchmodus nicht erfasst werden
          l_mode = 'E'.
          CALL FUNCTION 'QAVE_PROCESS_AUTO_UD'
            EXPORTING
              i_lot                = p_prueflos
              i_selected_set       = p_ausmg
              i_plant_selected_set = p_vwerk
              i_ud_code            = p_code
              i_ud_codegroup       = p_cdgrp
              i_text_line          = TEXT-j00
              i_stock_posting      = space
              i_process_mode       = l_mode
              i_origin_ud          = 'B'
            EXCEPTIONS
              error_occured        = 1
              not_posted           = 1
              foreign_lock         = 2
              lock_error           = 2.
          CASE sy-subrc.
            WHEN 0.
              MESSAGE s304(yqmlims) WITH object_tab_all-prueflos
                                         INTO dummy.
              PERFORM add_message.
            WHEN OTHERS.
              MESSAGE e305(yqmlims) WITH object_tab_all-prueflos
                                         INTO dummy.
              PERFORM add_message.
          ENDCASE.

        ELSE.
          MESSAGE e305(yqmlims) WITH object_tab_all-prueflos
                                     INTO dummy.
          PERFORM add_message.
        ENDIF.
      WHEN 2.
        MESSAGE e306(yqmlims) WITH object_tab_all-prueflos
                                   INTO dummy.
        PERFORM add_message.
      WHEN OTHERS.
        MESSAGE e305(yqmlims) WITH object_tab_all-prueflos
                                   INTO dummy.
        PERFORM add_message.
    ENDCASE.
  ENDIF.

ENDFORM.                    " PROCESS_UD
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
      i_t_log_handle   = t_log_handle
    EXCEPTIONS
      log_not_found    = 1
      save_not_allowed = 2
      numbering_error  = 3
      OTHERS           = 4.
  IF sy-subrc = 0.
    MESSAGE w002(yqmlims) INTO dummy.
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
FORM preview_pdf  USING    pv_prueflos
                           pv_werk
                           pv_approve
                  CHANGING pv_okcode TYPE sy-ucomm.

*  DATA: lv_ok_code    TYPE sy-ucomm.
  DATA: ls_params     TYPE rsparams.
  DATA: lt_params     TYPE TABLE OF rsparams.

  ls_params-selname = 'QL_PRLOS'.
  ls_params-kind    = 'S'.
  ls_params-sign    = 'I'.
  ls_params-option  = 'EQ'.
  ls_params-low     = pv_prueflos.
  APPEND ls_params TO lt_params.

  ls_params-selname = 'P_WERK'.
  ls_params-kind    = 'P'.
  ls_params-sign    = 'I'.
  ls_params-option  = 'EQ'.
  ls_params-low     = pv_werk.
  APPEND ls_params TO lt_params.

  ls_params-selname = 'P_NACHDR'.
  ls_params-kind    = 'P'.
  ls_params-sign    = 'I'.
  ls_params-option  = 'EQ'.
  ls_params-low     = 'X'.
  APPEND ls_params TO lt_params.

  ls_params-selname = 'P_PRUEF'.
  ls_params-kind    = 'P'.
  ls_params-sign    = 'I'.
  ls_params-option  = 'EQ'.
  ls_params-low     = 'X'.
  APPEND ls_params TO lt_params.

  ls_params-selname = 'P_PREV'.
  ls_params-kind    = 'P'.
  ls_params-sign    = 'I'.
  ls_params-option  = 'EQ'.
  ls_params-low     = 'X'.
  APPEND ls_params TO lt_params.

  ls_params-selname = 'P_APPR'.
  ls_params-kind    = 'P'.
  ls_params-sign    = 'I'.
  ls_params-option  = 'EQ'.
  ls_params-low     = pv_approve.
  APPEND ls_params TO lt_params.

  SUBMIT yqmlims_create_certificate WITH SELECTION-TABLE lt_params
         AND RETURN.

  IMPORT ok_code TO pv_okcode FROM MEMORY ID 'YQ0100'.


ENDFORM.
