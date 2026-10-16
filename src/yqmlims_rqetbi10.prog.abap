INCLUDE rqalvtop.

TABLES: qapo, qave, qapp, qmkst.

* Internal tables
DATA: BEGIN OF object_tab OCCURS 0.
        INCLUDE STRUCTURE yqm_rqetbi10.
DATA: kz_qave.
DATA: selected.
DATA: lights.
DATA: viewed TYPE pm_selected.
DATA: END OF object_tab.

* Berechtigungspuffer
DATA: BEGIN OF g_auth,
        art       LIKE qals-art,
        werk      LIKE qals-werk,
        qmatauth  LIKE qals-qmatauth,
        cvp_xblck TYPE qals-cvp_xblck,
        ok        LIKE qm00-qkz,
      END OF g_auth,
* Anzahl Lose mit fehlender Berechtigung
      g_anz_no_auth TYPE i.

DATA:
  g_structure      LIKE t370a-tabname VALUE 'OBJECT_TAB',
  g_tcode          LIKE sy-tcode,
  g_char_exist     TYPE c,           " Char. exist
  g_qapp_finished  TYPE c,           " Prüfpunkt abgeschlossen
  g_ok_code_screen LIKE t185-fcode,
  g_antwort        TYPE c.

* Datendeklaration für Unicodeumstellung
DATA: message_text TYPE slis_varbz.

* Optimization 616:
TYPES: tt_qals    TYPE STANDARD TABLE OF qals.
DATA: gv_callback TYPE xfeld.
DATA: gv_ok       TYPE xfeld.
FORM filter_qals_tab DEFINITION CHANGING qals_tab TYPE tt_qals.


* PARAMETERS --------------------------------*
PARAMETERS: p_incllz TYPE q_include_lt_char.

* Skip worklist
*selection-screen begin of block options with frame title text-s10.
PARAMETERS: p_skip_l TYPE qskip_wl DEFAULT ' '.
PARAMETERS: variant LIKE disvariant-variant.
PARAMETERS: monitor LIKE rqmonitor-qm_monitor
            AS LISTBOX VISIBLE LENGTH 30.
*selection-screen end of block options.

SELECT-OPTIONS:
* Mit diesen Selektionskriterien kann auch bei Selektionsbild 902
* der Datenbankindex fuer offene Lose verwendet werden.
  s_stat14 FOR qals-stat14 NO-DISPLAY,
  s_stat35 FOR qals-stat35 NO-DISPLAY.
*--------------------------------------------------------------------*
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

  PERFORM check_variant_maintain.

*--------------------------------------------------------------------*
* AT SELECTION SCREEN ON P_INCLLZ                                    *
*--------------------------------------------------------------------*
AT SELECTION-SCREEN ON p_incllz .

  REFRESH s_stat14.
  REFRESH s_stat35.
* Prüflose mit STAT14 = ' ' und mit STAT35 = ' '
  IF p_incllz IS INITIAL.
    MOVE: ' '  TO s_stat14-low,
          'I'  TO s_stat14-sign,
          'EQ' TO s_stat14-option.
    APPEND s_stat14.
    MOVE s_stat14[] TO s_stat35[].
  ENDIF.

*--------------------------------------------------------------------*
* AT SELECTION SCREEN                                                *
*--------------------------------------------------------------------*
AT SELECTION-SCREEN.
  IF p_skip_l IS INITIAL.
    PERFORM variant_existence_f14 USING variant. "check for Cust. var.
  ENDIF.
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

  MOVE 'YQM_RQETBI10' TO g_tabname.
  IF NOT sy-calld IS INITIAL.
    IMPORT g_submit g_fieldcat_tab FROM MEMORY ID 'SUBMIT'.
  ENDIF.

*-------------------------------------------------------------------*
  message_text = TEXT-tes.
  PERFORM variant_init_f14 USING 'LOTS'
                                 'LOTS'
*UC                              TEXT-TES.
                                 message_text.

  CHECK g_submit IS INITIAL.
  PERFORM get_default_variant_f14 USING variant.
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

  IF g_submit IS INITIAL.
    PERFORM create_fieldcat_l USING g_tabname.
    PERFORM update_fieldcat_variant_f14.
*   Toolbox initialisieren
    CALL FUNCTION 'QET4_INITIALIZE'.

  ENDIF.
  PERFORM select_fields_manip2_f16   USING g_fieldcat_tab.

*Stati are checked in this report. Therefore JEST is preread
  MOVE g_x TO preread.
* optimization 616: Parameter for Callback from PGQ
  p_calpgm = sy-repid.
  p_calfrm = 'FILTER_QALS_TAB'.
  CLEAR: gv_callback.

*-------------------------------------------------------------------*
* GET                                                               *
*-------------------------------------------------------------------*
GET qals FIELDS prueflos
                werk
                qmatauth
                obtyp
                objnr
                aufpl
                art
                offennlzmk
                offen_lzmk
                pastrterm
                paendterm
                lmengezub
                aufnr_co
                plnty
                stat02
                stat07
                stat35
                stat36.           "note2331512

* optimization 616: already done via callback of form FILTER_QALS_TAB from LDB
* ( Thus already in LDB the not-relevant QALS entries can be filtered out and
*   SELECT for all ENTRIES in QALS_TAB for dependant tables performs better )
  IF gv_callback IS INITIAL.
    CLEAR gv_ok.
    PERFORM check_qals USING qals CHANGING gv_ok.
    CHECK gv_ok IS NOT INITIAL.
* optimization 616: logic moved to form CHECK_QALS

** Prüfartenberechtigung prüfen mit Puffer
*  IF    G_AUTH-ART  NE QALS-ART
*    OR G_AUTH-WERK  NE QALS-WERK.
**   Berechtigung hat sich geändert, neu prüfen
*    MOVE-CORRESPONDING QALS TO G_AUTH.
*    CALL FUNCTION 'QAUT_INSPTYPE'
*      EXPORTING
*        I_PRUEFART       = G_AUTH-ART
*        I_WERK           = G_AUTH-WERK
*      EXCEPTIONS
*        NO_AUTHORIZATION = 1.
*
** Berechtigung vorhanden
*    IF SY-SUBRC IS INITIAL.
*      MOVE G_X TO G_AUTH-OK.
*    ELSE.
*      CLEAR G_AUTH-OK.
*    ENDIF.
*
*  ENDIF.
*
** Berechtigung prüfen
*  IF G_AUTH-OK EQ SPACE.
** Keine Berechtigung
*    ADD 1 TO G_ANZ_NO_AUTH.
*    REJECT.
*  ENDIF.
*
** Material
*  IF NOT QALS-QMATAUTH IS INITIAL.
*    CALL FUNCTION 'QAUT_MATERIAL'
*      EXPORTING
*        I_WERKS          = QALS-WERK
*        I_QMATMODUS      = 'D'
*        I_QMATAUTH       = QALS-QMATAUTH
*      EXCEPTIONS
*        NO_AUTHORIZATION = 01.
*
*    CHECK SY-SUBRC EQ 0.
*  ENDIF.
*
** Betriebswirtschaflicher Vorgang: Arbeitsvorrat Prüfergebnisse
*  CALL FUNCTION 'QAST_PROCESS_ACTIVITY'
*    EXPORTING
*      I_CHECK_ONLY         = 'X'
*      I_DIALOG             = ' '
*      I_OBJNR              = QALS-OBJNR
*      I_VORGANG            = 'QM25'
*    EXCEPTIONS
*      NOT_ALLOWED          = 01
*      ACTIVITY_NOT_ALLOWED = 02.
*
*  CHECK SY-SUBRC EQ 0.
  ENDIF. " optimization 616

* Fill internal table
  CLEAR object_tab.
  MOVE-CORRESPONDING qals TO object_tab.
  MOVE qals-stat35 TO object_tab-kz_qave.

  PERFORM set_monitor_f16.

* Generate status and user texts
  CALL FUNCTION 'STATUS_TEXT_EDIT'
    EXPORTING
      flg_user_stat    = 'X'
      objnr            = qals-objnr
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

** optimization 6161: obsolete as no action whatever value is returned
** Check status 'Inspection started'
*  CALL FUNCTION 'QAST_STATUS_CHECK'
*    EXPORTING
*      I_OBJNR          = QALS-OBJNR
*      I_STATUS         = 'I0218'
*    EXCEPTIONS
*      STATUS_NOT_ACTIV = 1.      "01.

GET qave FIELDS prueflos kzart.
* QAVE statt QAVP da QAVE vor QAPO in Datenbankstruktur
  CHECK qave-kzart EQ 'L'.
  MOVE-CORRESPONDING qave TO object_tab.

GET qapo FIELDS vornr
                vorglfnr
                vorktxt
                prplatz
                prplatzwrk
                prplatztxt.

*== authority check inspection results
  TRY.
      cl_qm_authorization_check=>get_instance( )->check_q_insprslt(
        EXPORTING
          iv_pruefart               = qals-art
          iv_werk                   = qals-werk
          iv_arbpl                  = qapo-prplatz
          iv_qmatauth               = qals-qmatauth
          iv_actvt                  = if_qm_authorization_check=>sc_insprslt-display
      ).
    CATCH cx_qm_authorization_check.
      REJECT.
  ENDTRY.

  MOVE qapo-vornr      TO object_tab-vornr.
  MOVE qapo-vorglfnr   TO object_tab-vorglfnr.
  MOVE qapo-vorktxt    TO object_tab-vorktxt.
  MOVE qapo-prplatz    TO object_tab-prplatz.
  MOVE qapo-prplatzwrk TO object_tab-prplatzwrk.
  MOVE qapo-prplatztxt TO object_tab-prplatztxt.
  CLEAR g_char_exist.

GET qapp FIELDS vbewertung
                kzbewert.

  IF p_ppve = 'X'.
    IF NOT qapp-vbewertung IS INITIAL.
      MOVE 'X' TO g_qapp_finished.
      REJECT.
    ELSE.
      CLEAR g_qapp_finished.
    ENDIF.
  ELSE.
    CLEAR g_qapp_finished.
  ENDIF.

GET qamv FIELDS verwmerkm.
  g_char_exist = 'X'.

GET qapo LATE.

  IF NOT g_char_exist     IS INITIAL
  AND    g_qapp_finished  IS INITIAL.
    APPEND object_tab.
  ENDIF.
*--------------------------------------------------------------------*
* END OF SELECTION                                                   *
*--------------------------------------------------------------------*
END-OF-SELECTION.
  IF g_submit = 'X'.
* CALL MODUS FOR REFRESH
    EXPORT object_tab TO MEMORY ID g_repid.
  ELSE.
    IF p_skip_l IS INITIAL.
* TESTLAUF is set in DBPGQSEL. It has nothing to do with this report,
* but shows up in the selection criteria popup if it isn't cleared.
      CLEAR testlauf.
      CLEAR g_form_top_of_page.
      CLEAR dy_tcode.
      PERFORM fill_events_f14.
      PERFORM fill_event_exit_tab_f14.
      PERFORM fill_layout_f16.
      PERFORM get_fieldcat_actual_f16.
      PERFORM fill_fieldgroups_l.
      PERFORM call_listviewer_f14 USING g_fieldcat_tab[] object_tab[].
    ELSE.
* Skip worklist, mark all entries
      PERFORM skip_list.
    ENDIF.
  ENDIF.

*---------------------------------------------------------------------*
*       FORM USER_COMMAND_L             called dynamically            *
*---------------------------------------------------------------------*
*       handle locally defined f-codes                               *
*---------------------------------------------------------------------*
*  -->  P_UCOMM                                                       *
*  -->  P_SELFIELD                                                    *
*---------------------------------------------------------------------*
FORM user_command_l USING p_ucomm LIKE sy-ucomm
                          p_selfield TYPE slis_selfield.
  DATA: object_tab_wa LIKE object_tab.
  DATA l_tabix        TYPE sy-tabix.
  DATA l_tabix2       TYPE sy-tabix.
  DATA l_selected     TYPE qkz.

  CLEAR g_ok_code_screen.
* FOR PLOS, QMEL... if g_aktyp eq v, then change transaction is called.

  g_aktyp = 'V'.

  CASE p_ucomm.

* Ergebniserfassung, prozessoptimiert
    WHEN 'TAMV'.
      p_selfield-refresh = g_s.    "rebuild list to set checkmark
      p_selfield-row_stable = g_x. "stable scrolling
      p_selfield-col_stable = g_x. "stable scrolling
      CALL FUNCTION 'QEEA_INITIALIZE_LOT_BASETABS'.
      CALL FUNCTION 'QET4_INITIALIZE'.
      CALL FUNCTION 'Y_QMLIMS_QET5_RESET_SAVE_FLAG'.
      CALL FUNCTION 'Y_QMLIMS_QET5_QAMV_COLLECT'
        EXPORTING
          i_reset = 'X'.
      CLEAR g_antwort.
      IF p_sin_pr EQ 'X'.
* Der Screenaufruf erfolgt bezogen auf den Vorgang
* z.B. tabellarische Ergebniserfassung zu Prüfpunkten
        DO.
          IF g_ok_code_screen <> 'BACK'.

*           Berechtigungsprüfung Werk und Arbeitsplatz         "2498617
            LOOP AT object_tab WHERE selected = g_x         "2498617
*                              and werk     is not initial     "2507050
                               AND prplatzwrk IS NOT INITIAL "2507050
                                 AND prplatz  IS NOT INITIAL. "2498617
              CALL FUNCTION 'QAUT_CHARACTERISTIC_PROC'         "2498617
                EXPORTING
*                 I_WERK            = object_tab-werk          "2503508
                  i_werk            = object_tab-prplatzwrk    "2503508
                  i_arbpl           = object_tab-prplatz
                  i_no_status_check = 'X'
                EXCEPTIONS
                  no_authorization  = 1
                  auth_destroyed    = 2
                  internal_error    = 3
                  OTHERS            = 4.
              IF sy-subrc <> 0.                             "2498617
                MESSAGE e156(q0)
*                 with object_tab-werk object_tab-prplatz.     "2507050
                  WITH object_tab-prplatzwrk                "2507050
                       object_tab-prplatz.                  "2507050
                RETURN.
              ENDIF.
            ENDLOOP.                                        "2498617

*           Vorwärtsnavigation
            l_tabix = l_tabix + 1.
            LOOP AT object_tab FROM l_tabix
                               WHERE selected = g_x.
*             Es wurde ein Eintrag gefunden
              MOVE 'X' TO l_selected.
              l_tabix = sy-tabix.
              object_tab-viewed = sym_check_mark.
              MODIFY object_tab.
              PERFORM put_samples_to_toolbox.
              PERFORM call_screen.
              EXIT.
            ENDLOOP.
            IF sy-subrc <> 0.
              EXIT.
            ENDIF.
          ELSE.
*           Rückwärtsnavigation
            l_tabix = l_tabix - 1.
            LOOP AT object_tab TO l_tabix
                               WHERE selected = g_x.
              l_tabix2 = sy-tabix.
            ENDLOOP.
            IF sy-subrc IS INITIAL.
*             Es wurde ein Eintrag gefunden
              l_tabix = l_tabix2.
              object_tab-viewed = sym_check_mark.
              MODIFY object_tab INDEX l_tabix.
              PERFORM put_samples_to_toolbox.
              PERFORM call_screen.
            ELSE.
              EXIT.
            ENDIF.
          ENDIF.
          IF   g_ok_code_screen EQ 'END'
            OR g_ok_code_screen EQ 'EXIT'.
            EXIT.
          ENDIF.
        ENDDO.
* Cursor on one item only -> go via index
        IF   l_selected IS INITIAL
         AND NOT p_selfield-tabindex IS INITIAL.
          READ TABLE object_tab INDEX p_selfield-tabindex.
          MOVE object_tab TO object_tab_wa.
          object_tab_wa-viewed = sym_check_mark.
          MODIFY object_tab FROM object_tab_wa INDEX p_selfield-tabindex
                          TRANSPORTING viewed.
          PERFORM put_samples_to_toolbox.
          PERFORM call_screen.
        ENDIF.
      ELSE.
* Der Screenaufruf erfolgt vorgangsübergreifend
        LOOP AT object_tab WHERE selected = g_x.
          object_tab-viewed = sym_check_mark.
          MODIFY object_tab.
          PERFORM put_samples_to_toolbox.
        ENDLOOP.
* Cursor on one item only -> go via index
        IF   NOT sy-subrc IS INITIAL
         AND NOT p_selfield-tabindex IS INITIAL.
          READ TABLE object_tab INDEX p_selfield-tabindex.
          MOVE object_tab TO object_tab_wa.
          object_tab_wa-viewed = sym_check_mark.
          MODIFY object_tab FROM object_tab_wa INDEX p_selfield-tabindex
                           TRANSPORTING viewed.
          PERFORM put_samples_to_toolbox.
          PERFORM call_screen.
        ELSE.
          PERFORM call_screen.
        ENDIF.
      ENDIF.

* Ergebniserfassung, prozessoptimiert, Vorgangsübergreifend
    WHEN 'TAMVV'.
      p_selfield-refresh    = g_s.     "rebuild list to set checkmark
      p_selfield-row_stable = g_x.     "stable scrolling
      p_selfield-col_stable = g_x.     "stable scrolling
      CALL FUNCTION 'QEEA_INITIALIZE_LOT_BASETABS'.
      CALL FUNCTION 'QET4_INITIALIZE'.
      CALL FUNCTION 'Y_QMLIMS_QET5_RESET_SAVE_FLAG'.
      CALL FUNCTION 'Y_QMLIMS_QET5_QAMV_COLLECT'
        EXPORTING
          i_reset = 'X'.

      LOOP AT object_tab WHERE selected = g_x.
        object_tab-viewed = sym_check_mark.
        MODIFY object_tab.
        PERFORM put_samples_to_toolbox.
      ENDLOOP.
      IF sy-subrc <> 0.
        EXIT.
      ELSE.
        PERFORM call_screen.
      ENDIF.

* Probe ändern
    WHEN 'PHYNR'.
      p_selfield-refresh    = g_s.     "rebuild list to set checkmark
      p_selfield-row_stable = g_x.     "stable scrolling
      p_selfield-col_stable = g_x.     "stable scrolling

      LOOP AT object_tab WHERE selected = g_x.
        object_tab-viewed = sym_check_mark.
        MODIFY object_tab.
        PERFORM change_physical_sample.
      ENDLOOP.
      IF sy-subrc <> 0.
        EXIT.
      ENDIF.

    WHEN OTHERS.    " codes that require reading items from the list
* Codes are : PLOS QAMV VEAZ QMEL (display or change)
*             PRLS PRZG (print inspection report and certificate)
      PERFORM user_command_f16 USING p_ucomm p_selfield.
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

  DATA h_fieldgroups TYPE slis_sp_group_alv.
  DATA h_fieldcat_wa TYPE slis_fieldcat_alv.

  h_fieldgroups-sp_group = 'B'.        "Bewegungsdaten
  h_fieldgroups-text     = TEXT-gpb .
  APPEND h_fieldgroups TO g_fieldgroups_tab.

  h_fieldgroups-sp_group = 'K'.        "Kontierung
  h_fieldgroups-text     = TEXT-gpk .
  APPEND h_fieldgroups TO g_fieldgroups_tab.

  h_fieldgroups-sp_group = 'M'.        "Mengen
  h_fieldgroups-text     = TEXT-gpm .
  APPEND h_fieldgroups TO g_fieldgroups_tab.

  h_fieldgroups-sp_group = 'O'.        "Vorgang
  h_fieldgroups-text     = TEXT-gpo .
  APPEND h_fieldgroups TO g_fieldgroups_tab.

  h_fieldgroups-sp_group = 'P'.        "Prüflos
  h_fieldgroups-text     = TEXT-gpp .
  APPEND h_fieldgroups TO g_fieldgroups_tab.

  h_fieldgroups-sp_group = 'Q'.        "Prüfplan
  h_fieldgroups-text     = TEXT-gpq.
  APPEND h_fieldgroups TO g_fieldgroups_tab.

  h_fieldgroups-sp_group = 'R'.        "Stammdaten
  h_fieldgroups-text     = TEXT-gpr .
  APPEND h_fieldgroups TO g_fieldgroups_tab.

  h_fieldgroups-sp_group = 'S'.        "Stichprobe
  h_fieldgroups-text     = TEXT-gps .
  APPEND h_fieldgroups TO g_fieldgroups_tab.

  h_fieldgroups-sp_group = 'U'.        "Verwendungsentscheid
  h_fieldgroups-text     = TEXT-gpu .
  APPEND h_fieldgroups TO g_fieldgroups_tab.

  h_fieldgroups-sp_group = 'V'.        "Verwaltung
  h_fieldgroups-text     = TEXT-gpv .
  APPEND h_fieldgroups TO g_fieldgroups_tab.

  h_fieldgroups-sp_group = 'Z'.        "Zaehler
  h_fieldgroups-text     = TEXT-gpz .
  APPEND h_fieldgroups TO g_fieldgroups_tab.

  LOOP AT g_fieldcat_tab INTO h_fieldcat_wa.
    CLEAR h_fieldcat_wa-sp_group.
    CASE h_fieldcat_wa-fieldname.

      WHEN 'AUFNR'.
        h_fieldcat_wa-sp_group = 'B'.
      WHEN 'SA_AUFNR'.
        h_fieldcat_wa-sp_group = 'B'.
      WHEN 'EBELN'.
        h_fieldcat_wa-sp_group = 'B'.
      WHEN 'EBELP'.
        h_fieldcat_wa-sp_group = 'B'.
      WHEN 'BLART'.
        h_fieldcat_wa-sp_group = 'B'.
      WHEN 'MJAHR'.
        h_fieldcat_wa-sp_group = 'B'.
      WHEN 'ZEILE'.
        h_fieldcat_wa-sp_group = 'B'.
      WHEN 'BUDAT'.
        h_fieldcat_wa-sp_group = 'B'.
      WHEN 'BWART'.
        h_fieldcat_wa-sp_group = 'B'.
      WHEN 'LS_KDAUF'.
        h_fieldcat_wa-sp_group = 'B'.
      WHEN 'LS_KDPOS'.
        h_fieldcat_wa-sp_group = 'B'.
      WHEN 'LS_VBELN'.
        h_fieldcat_wa-sp_group = 'B'.
      WHEN 'LS_POSNR'.
        h_fieldcat_wa-sp_group = 'B'.
      WHEN 'LS_ABRVW'.
        h_fieldcat_wa-sp_group = 'B'.
      WHEN 'LS_ROUTE'.
        h_fieldcat_wa-sp_group = 'B'.
      WHEN 'LS_LLAND'.
        h_fieldcat_wa-sp_group = 'B'.
      WHEN 'LS_KUNAG'.
        h_fieldcat_wa-sp_group = 'B'.
      WHEN 'LS_VKORG'.
        h_fieldcat_wa-sp_group = 'B'.
      WHEN 'LS_KDMAT'.
        h_fieldcat_wa-sp_group = 'B'.

      WHEN 'STAT06'.
        h_fieldcat_wa-sp_group = 'K'.
      WHEN 'AUFNR_CO'.
        h_fieldcat_wa-sp_group = 'K'.
      WHEN 'KZVBR'.
        h_fieldcat_wa-sp_group = 'K'.
      WHEN 'KNTTP'.
        h_fieldcat_wa-sp_group = 'K'.
      WHEN 'KOSTL'.
        h_fieldcat_wa-sp_group = 'K'.
      WHEN 'AUFPS'.
        h_fieldcat_wa-sp_group = 'K'.
      WHEN 'ANLN1'.
        h_fieldcat_wa-sp_group = 'K'.
      WHEN 'ANLN2'.
        h_fieldcat_wa-sp_group = 'K'.
      WHEN 'PS_PSP_PNR'.
        h_fieldcat_wa-sp_group = 'K'.
      WHEN 'NPLNR'.
        h_fieldcat_wa-sp_group = 'K'.
      WHEN 'APLZL'.
        h_fieldcat_wa-sp_group = 'K'.
      WHEN 'KDAUF'.
        h_fieldcat_wa-sp_group = 'K'.
      WHEN 'KDPOS'.
        h_fieldcat_wa-sp_group = 'K'.
      WHEN 'PAOBJNR'.
        h_fieldcat_wa-sp_group = 'K'.
      WHEN 'PRCTR'.
        h_fieldcat_wa-sp_group = 'K'.
      WHEN 'GSBER'.
        h_fieldcat_wa-sp_group = 'K'.
      WHEN 'KONTO'.
        h_fieldcat_wa-sp_group = 'K'.
      WHEN 'KOKRS'.
        h_fieldcat_wa-sp_group = 'K'.
      WHEN 'BUKRS'.
        h_fieldcat_wa-sp_group = 'K'.

      WHEN 'SOBKZ'.
        h_fieldcat_wa-sp_group = 'M'.
      WHEN 'WERKVORG'.
        h_fieldcat_wa-sp_group = 'M'.
      WHEN 'LAGORTVORG'.
        h_fieldcat_wa-sp_group = 'M'.
      WHEN 'LGNUM'.
        h_fieldcat_wa-sp_group = 'M'.
      WHEN 'LGTYP'.
        h_fieldcat_wa-sp_group = 'M'.
      WHEN 'LGPLA'.
        h_fieldcat_wa-sp_group = 'M'.
      WHEN 'LMENGE01'.
        h_fieldcat_wa-sp_group = 'M'.
      WHEN 'LMENGE02'.
        h_fieldcat_wa-sp_group = 'M'.
      WHEN 'LMENGE03'.
        h_fieldcat_wa-sp_group = 'M'.
      WHEN 'LMENGE04'.
        h_fieldcat_wa-sp_group = 'M'.
      WHEN 'LMENGE05'.
        h_fieldcat_wa-sp_group = 'M'.
      WHEN 'LMENGE06'.
        h_fieldcat_wa-sp_group = 'M'.
      WHEN 'LMENGE07'.
        h_fieldcat_wa-sp_group = 'M'.
      WHEN 'LMENGE08'.
        h_fieldcat_wa-sp_group = 'M'.
      WHEN 'LMENGE09'.
        h_fieldcat_wa-sp_group = 'M'.
      WHEN 'MATNRNEU'.
        h_fieldcat_wa-sp_group = 'M'.
      WHEN 'CHARGNEU'.
        h_fieldcat_wa-sp_group = 'M'.
      WHEN 'LMENGEZUB'.
        h_fieldcat_wa-sp_group = 'M'.
      WHEN 'LMENGELZ'.
        h_fieldcat_wa-sp_group = 'M'.
      WHEN 'LMENGEPR'.
        h_fieldcat_wa-sp_group = 'M'.
      WHEN 'LMENGEZER'.
        h_fieldcat_wa-sp_group = 'M'.
      WHEN 'LMENGEIST'.
        h_fieldcat_wa-sp_group = 'M'.
      WHEN 'LMENGESCH'.
        h_fieldcat_wa-sp_group = 'M'.

      WHEN 'VORNR'.
        h_fieldcat_wa-sp_group = 'O'.
      WHEN 'VORKTXT'.
        h_fieldcat_wa-sp_group = 'O'.
      WHEN 'PRPLATZ'.
        h_fieldcat_wa-sp_group = 'O'.
      WHEN 'PRPLATZWRK'.
        h_fieldcat_wa-sp_group = 'O'.
      WHEN 'PRPLATZTXT'.
        h_fieldcat_wa-sp_group = 'O'.

      WHEN 'PRUEFLOS'.
        h_fieldcat_wa-sp_group = 'P'.
      WHEN 'WERK'.
        h_fieldcat_wa-sp_group = 'P'.
      WHEN 'ART'.
        h_fieldcat_wa-sp_group = 'P'.
      WHEN 'HERKUNFT'.
        h_fieldcat_wa-sp_group = 'P'.
      WHEN 'OBTYP'.
        h_fieldcat_wa-sp_group = 'P'.
      WHEN 'STSMA'.
        h_fieldcat_wa-sp_group = 'P'.
      WHEN 'QMATAUTH'.
        h_fieldcat_wa-sp_group = 'P'.
      WHEN 'STAT11'.
        h_fieldcat_wa-sp_group = 'P'.
      WHEN 'INSMK'.
        h_fieldcat_wa-sp_group = 'P'.
      WHEN 'STAT09'.
        h_fieldcat_wa-sp_group = 'P'.
      WHEN 'STAT19'.
        h_fieldcat_wa-sp_group = 'P'.
      WHEN 'STAT23'.
        h_fieldcat_wa-sp_group = 'P'.
      WHEN 'STAT24'.
        h_fieldcat_wa-sp_group = 'P'.
      WHEN 'STAT25'.
        h_fieldcat_wa-sp_group = 'P'.
      WHEN 'DYNHEAD'.
        h_fieldcat_wa-sp_group = 'P'.
      WHEN 'STPRVER'.
        h_fieldcat_wa-sp_group = 'P'.
      WHEN 'SPRACHE'.
        h_fieldcat_wa-sp_group = 'P'.
      WHEN 'KTEXTLOS'.
        h_fieldcat_wa-sp_group = 'P'.
      WHEN 'KTEXTMAT'.
        h_fieldcat_wa-sp_group = 'P'.
      WHEN 'LOSMENGE'.
        h_fieldcat_wa-sp_group = 'P'.
      WHEN 'MENGENEINH'.
        h_fieldcat_wa-sp_group = 'P'.
      WHEN 'ANZGEB'.
        h_fieldcat_wa-sp_group = 'P'.
      WHEN 'GEBEH'.
        h_fieldcat_wa-sp_group = 'P'.
      WHEN 'SERNP'.
        h_fieldcat_wa-sp_group = 'P'.
      WHEN 'INSP_DOC_NUMBER'.
        h_fieldcat_wa-sp_group = 'P'.
      WHEN 'PRIO_PUNKTE'.
        h_fieldcat_wa-sp_group = 'P'.
      WHEN 'YQM_TPLNR'.
        h_fieldcat_wa-sp_group = 'P'.
      WHEN 'YQM_PROBEDATUM'.
        h_fieldcat_wa-sp_group = 'P'.
      WHEN 'YQM_PROBEZEIT'.
        h_fieldcat_wa-sp_group = 'P'.
      WHEN 'YQM_PROBENEHMER03'.
        h_fieldcat_wa-sp_group = 'P'.
      WHEN 'YQM_PROBENEHMER40'.
        h_fieldcat_wa-sp_group = 'P'.
      WHEN 'YQM_PROBEEINGANG'.
        h_fieldcat_wa-sp_group = 'P'.
      WHEN 'YQM_BERICHTNR'.
        h_fieldcat_wa-sp_group = 'P'.
      WHEN 'YQM_KZ_COST'.
        h_fieldcat_wa-sp_group = 'P'.
      WHEN 'YQM_CO_BELEG'.
        h_fieldcat_wa-sp_group = 'P'.
      WHEN 'YQM_CO_BELEG_DATUM'.
        h_fieldcat_wa-sp_group = 'P'.
      WHEN 'YQM_UEBERWACHUNG'.
        h_fieldcat_wa-sp_group = 'P'.
      WHEN 'YQM_ANLASS'.
        h_fieldcat_wa-sp_group = 'P'.
      WHEN 'YQM_KUNNRZL'.
        h_fieldcat_wa-sp_group = 'P'.
      WHEN 'YQM_INFO1'.
        h_fieldcat_wa-sp_group = 'P'.
      WHEN 'YQM_INFO2'.
        h_fieldcat_wa-sp_group = 'P'.
      WHEN 'YQM_INFO3'.
        h_fieldcat_wa-sp_group = 'P'.
      WHEN 'YQM_SPEZID'.
        h_fieldcat_wa-sp_group = 'P'.
      WHEN 'YQM_ARKTX'.
        h_fieldcat_wa-sp_group = 'P'.

      WHEN 'PLNTY'.
        h_fieldcat_wa-sp_group = 'Q'.
      WHEN 'PLNNR'.
        h_fieldcat_wa-sp_group = 'Q'.
      WHEN 'PPLVERW'.
        h_fieldcat_wa-sp_group = 'Q'.
      WHEN 'PLNAL'.
        h_fieldcat_wa-sp_group = 'Q'.
      WHEN 'SLWBEZ'.
        h_fieldcat_wa-sp_group = 'Q'.
      WHEN 'STAT13'.
        h_fieldcat_wa-sp_group = 'Q'.
      WHEN 'SELMATNR'.
        h_fieldcat_wa-sp_group = 'Q'.
      WHEN 'SELREVLV'.
        h_fieldcat_wa-sp_group = 'Q'.
      WHEN 'SELWERK'.
        h_fieldcat_wa-sp_group = 'Q'.
      WHEN 'SELLIFNR'.
        h_fieldcat_wa-sp_group = 'Q'.
      WHEN 'SELHERST'.
        h_fieldcat_wa-sp_group = 'Q'.
      WHEN 'SELKUNNR'.
        h_fieldcat_wa-sp_group = 'Q'.
      WHEN 'SELPPLVERW'.
        h_fieldcat_wa-sp_group = 'Q'.
      WHEN 'GUELTIGAB'.
        h_fieldcat_wa-sp_group = 'Q'.

      WHEN 'KUNNR'.
        h_fieldcat_wa-sp_group = 'R'.
      WHEN 'LIFNR'.
        h_fieldcat_wa-sp_group = 'R'.
      WHEN 'HERSTELLER'.
        h_fieldcat_wa-sp_group = 'R'.
      WHEN 'EMATNR'.
        h_fieldcat_wa-sp_group = 'R'.
      WHEN 'MATNR'.
        h_fieldcat_wa-sp_group = 'R'.
      WHEN 'REVLV'.
        h_fieldcat_wa-sp_group = 'R'.
      WHEN 'CHARG'.
        h_fieldcat_wa-sp_group = 'R'.
      WHEN 'LAGORTCHRG'.
        h_fieldcat_wa-sp_group = 'R'.
      WHEN 'EKORG'.
        h_fieldcat_wa-sp_group = 'R'.

      WHEN 'GESSTICHPR'.
        h_fieldcat_wa-sp_group = 'S'.
      WHEN 'EINHPROBE'.
        h_fieldcat_wa-sp_group = 'S'.
      WHEN 'DYNREGEL'.
        h_fieldcat_wa-sp_group = 'S'.
      WHEN 'STAT44'.
        h_fieldcat_wa-sp_group = 'S'.
      WHEN 'PRSTUFE'.
        h_fieldcat_wa-sp_group = 'S'.
      WHEN 'PRSCHAERFE'.
        h_fieldcat_wa-sp_group = 'S'.
      WHEN 'STAT12'.
        h_fieldcat_wa-sp_group = 'S'.
      WHEN 'PRBNAVERF'.
        h_fieldcat_wa-sp_group = 'S'.
      WHEN 'PRBNAVV'.
        h_fieldcat_wa-sp_group = 'S'.

      WHEN 'VBEWERTUNG'.
        h_fieldcat_wa-sp_group = 'U'.
      WHEN 'QKENNZAHL'.
        h_fieldcat_wa-sp_group = 'U'.
      WHEN 'DBEWERTUNG'.
        h_fieldcat_wa-sp_group = 'U'.
      WHEN 'VFOLGEAKTI'.
        h_fieldcat_wa-sp_group = 'U'.
      WHEN 'VNAME'.
        h_fieldcat_wa-sp_group = 'U'.
      WHEN 'VDATUM'.
        h_fieldcat_wa-sp_group = 'U'.
      WHEN 'VEZEITERF'.
        h_fieldcat_wa-sp_group = 'U'.
      WHEN 'VAENAME'.
        h_fieldcat_wa-sp_group = 'U'.
      WHEN 'VAEDATUM'.
        h_fieldcat_wa-sp_group = 'U'.
      WHEN 'VEZEITAEN'.
        h_fieldcat_wa-sp_group = 'U'.
      WHEN 'KZART'.
        h_fieldcat_wa-sp_group = 'U'.
      WHEN 'VKATART'.
        h_fieldcat_wa-sp_group = 'U'.
      WHEN 'VAUSWAHLMG'.
        h_fieldcat_wa-sp_group = 'U'.
      WHEN 'VCODEGRP'.
        h_fieldcat_wa-sp_group = 'U'.
      WHEN 'VCODE'.
        h_fieldcat_wa-sp_group = 'U'.

      WHEN 'ENSTEHDAT'.
        h_fieldcat_wa-sp_group = 'V'.
      WHEN 'ENTSTEZEIT'.
        h_fieldcat_wa-sp_group = 'V'.
      WHEN 'ERSTELLER'.
        h_fieldcat_wa-sp_group = 'V'.
      WHEN 'ERSTELDAT'.
        h_fieldcat_wa-sp_group = 'V'.
      WHEN 'ERSTELZEIT'.
        h_fieldcat_wa-sp_group = 'V'.
      WHEN 'AENDERER'.
        h_fieldcat_wa-sp_group = 'V'.
      WHEN 'AENDERDAT'.
        h_fieldcat_wa-sp_group = 'V'.
      WHEN 'AENDERZEIT'.
        h_fieldcat_wa-sp_group = 'V'.
      WHEN 'PASTRTERM'.
        h_fieldcat_wa-sp_group = 'V'.
      WHEN 'PASTRZEIT'.
        h_fieldcat_wa-sp_group = 'V'.
      WHEN 'PAENDTERM'.
        h_fieldcat_wa-sp_group = 'V'.
      WHEN 'PAENDZEIT'.
        h_fieldcat_wa-sp_group = 'V'.

      WHEN 'ZUSMKZAEHL'.
        h_fieldcat_wa-sp_group = 'Z'.
      WHEN 'OFFENNLZMK'.
        h_fieldcat_wa-sp_group = 'Z'.
      WHEN 'OFFEN_LZMK'.
        h_fieldcat_wa-sp_group = 'Z'.
      WHEN 'ANTEIL'.
        h_fieldcat_wa-sp_group = 'Z'.
      WHEN 'QPMATLOS'.
        h_fieldcat_wa-sp_group = 'Z'.

* Fields that need not be displayed
      WHEN 'OBJNR'.
        h_fieldcat_wa-tech = g_x.
      WHEN 'STAT05'.                   " Field has no name
        h_fieldcat_wa-tech = g_x.
      WHEN 'STAT16'.                   " Field has no name
        h_fieldcat_wa-tech = g_x.
      WHEN 'VORGLFNR'.                 " Laufende Knotenummer
        h_fieldcat_wa-tech = g_x.

    ENDCASE.

    MODIFY g_fieldcat_tab FROM h_fieldcat_wa.
  ENDLOOP.
ENDFORM.                               " FILL_FIELDGROUPS_L
*---------------------------------------------------------------------*
*       FORM CREATE_FIELDCAT_L                                        *
*---------------------------------------------------------------------*
*       create g_fieldcat_tab for DDIC structure                      *
*---------------------------------------------------------------------*
*  -->  TABNAME  (DDIC-Structure for Report-Output)                   *
*---------------------------------------------------------------------*
FORM create_fieldcat_l   USING tabname TYPE slis_tabname.

  DATA h_fieldcat_wa TYPE slis_fieldcat_alv.
  DATA h_index       LIKE sy-tabix.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      i_program_name         = g_repid
      i_internal_tabname     = 'OBJECT_TAB'
      i_structure_name       = tabname
      i_client_never_display = ' '
*     I_INCLNAME             = 'RQETBI10'
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
      IF h_fieldcat_wa-fieldname EQ 'VIEWED'.
        MOVE TEXT-vd1  TO h_fieldcat_wa-seltext_l.
        MOVE TEXT-vd2  TO h_fieldcat_wa-seltext_s.
        h_fieldcat_wa-ddictxt = 'S'.
        MODIFY g_fieldcat_tab FROM h_fieldcat_wa.
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
                                 AND   tcode = g_tcode.
    ELSE.
      tstct-ttext = sy-title.
    ENDIF.

    SET TITLEBAR 'LVS' WITH tstct-ttext.


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
        IF NOT sy-subrc IS INITIAL.  APPEND 'TAMV' TO rt_extab. ENDIF.
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

    SET PF-STATUS 'MAIN' OF PROGRAM 'YQMLIMS_RQETBM10' EXCLUDING rt_extab.
  ENDIF.

ENDFORM.                               " SET_PF_STATUS_L

*&---------------------------------------------------------------------*
*&      Form  CALL_TA
*&---------------------------------------------------------------------*
*   Berechtigungsprüfung und Aufruf Transaktion mit SKIP FIRST SCREEN  *
*----------------------------------------------------------------------*
*  -->  p_tcode   Transaktionscode
*----------------------------------------------------------------------*
FORM call_ta USING p_tcode.

  DATA lo_authorization_error TYPE REF TO cx_sy_authorization_error.

  CALL FUNCTION 'QAUT_CHECK_TCODE'
    EXPORTING
      i_tcode = p_tcode.

  TRY.
      CALL TRANSACTION p_tcode WITH AUTHORITY-CHECK AND SKIP FIRST SCREEN.
    CATCH cx_sy_authorization_error INTO lo_authorization_error.
      MESSAGE lo_authorization_error TYPE 'E'.
  ENDTRY.

ENDFORM.                               " CALL_TA

*---------------------------------------------------------------------*
*       FORM FCODES_WITH_MARK_L                                       *
*---------------------------------------------------------------------*
*       FCodes, die auch im Loop verarbeitet werden können            *
*---------------------------------------------------------------------*
FORM fcodes_with_mark_l.

  DATA: l_vornr LIKE qapo-vornr.

  CASE sy-ucomm.
*   Prüflos
    WHEN 'QALS'.
      SET PARAMETER ID 'QLS' FIELD object_tab-prueflos.
      PERFORM call_ta USING 'QA02'  .
*   Verwendungsentscheid
    WHEN 'QAVE'.
      SET PARAMETER ID 'QLS' FIELD object_tab-prueflos.
      IF object_tab-kz_qave IS INITIAL.
*         noch kein VE
        PERFORM call_ta USING 'QA11'  .
      ELSE.
        PERFORM call_ta USING 'QA12'  .
      ENDIF.
*   Ergebnisse
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
            vornr            = l_vornr
          EXCEPTIONS
            no_data_found    = 01
            no_data_selected = 02.
        IF sy-subrc NE 0.
          MESSAGE i181(qe) WITH object_tab-prueflos.
        ELSE.
          SET PARAMETER ID 'QLS' FIELD object_tab-prueflos.
          SET PARAMETER ID 'QVO' FIELD l_vornr.
          IF object_tab-stat07 NE space.
*         Prüfpunkte
            PERFORM call_ta USING 'QE11' .
*
          ELSEIF object_tab-stat02 NE space
             AND object_tab-stat36 IS INITIAL.             "note2331512
*         Teillose
            PERFORM call_ta USING 'QE14'  .
*
          ELSE.
*         der Rest
            PERFORM call_ta USING 'QE01'  .
          ENDIF.
        ENDIF.
      ENDIF.

*   Fehlererfassung
    WHEN 'QMEL'.
      SET PARAMETER ID 'QLS' FIELD object_tab-prueflos.
*       Bereits Fehler vorhanden
      CALL FUNCTION 'STATUS_CHECK'
        EXPORTING
          objnr             = object_tab-objnr
          status            = 'I0214'
        EXCEPTIONS
          status_not_active = 01.
      IF sy-subrc IS INITIAL.
*         es gibt Fehler
        PERFORM call_ta USING 'QF02'  .
      ELSE.
*         Berichts ist leider nicht gefüllt
        PERFORM call_ta USING 'QF01'  .
      ENDIF.

*   Prüfbericht drucken
    WHEN 'PRLS'.
      CALL FUNCTION 'QAUT_CHECK_TCODE'
        EXPORTING
          i_tcode = 'QGA3'.
      CALL FUNCTION 'QSS1_PRINT_INSPECTION_RESULTS'
        EXPORTING
          i_lot_number = object_tab-prueflos
          i_insp_type  = object_tab-art.

*   Zeugnis drucken
    WHEN 'PRZG'.
      CALL FUNCTION 'QAUT_CHECK_TCODE'
        EXPORTING
          i_tcode = 'QC21'.
      SUBMIT rqcaap01 VIA SELECTION-SCREEN AND RETURN
             WITH p_lot EQ object_tab-prueflos
             WITH p_dialog EQ 'X'      "Mit Benutzerdialog
             WITH p_submit EQ g_x.     "Submit-Modus

  ENDCASE.

ENDFORM.                               "FCODES_WITH_MARK_L

*&---------------------------------------------------------------------*
*&      Form  EXECUTE_FCODE_L
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM execute_fcode_l USING p_ucomm.
  DATA: l_vornr LIKE qapo-vornr.

  CASE p_ucomm.
*   Ergebnisse
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
            vornr            = l_vornr
          EXCEPTIONS
            no_data_found    = 01
            no_data_selected = 02.
        IF sy-subrc NE 0.
          MESSAGE i181(qe) WITH object_tab-prueflos.
        ELSE.
          SET PARAMETER ID 'QLS' FIELD object_tab-prueflos.
          SET PARAMETER ID 'QVO' FIELD l_vornr.
          IF object_tab-stat07 NE space.
*         Prüfpunkte
            CALL TRANSACTION 'QE11' AND SKIP FIRST SCREEN.

          ELSEIF object_tab-stat02 NE space
             AND object_tab-stat36 IS INITIAL.             "note2331512
*         Teillose
            CALL TRANSACTION 'QE14' AND SKIP FIRST SCREEN.

          ELSE.
*         der Rest
            CALL TRANSACTION 'QE01' AND SKIP FIRST SCREEN.
          ENDIF.
        ENDIF.
      ENDIF.
*   Fehlererfassung
    WHEN 'QMEL'.

      SET PARAMETER ID 'QLS' FIELD object_tab-prueflos.

*       Bereits Fehler vorhanden
      CALL FUNCTION 'STATUS_CHECK'
        EXPORTING
          objnr             = object_tab-objnr
          status            = 'I0214'
        EXCEPTIONS
          status_not_active = 01.
      IF sy-subrc IS INITIAL.
*         es gibt Fehler
        PERFORM call_ta USING 'QF02'  .
      ELSE.
*         Bericht ist leider nicht gefüllt
        PERFORM call_ta USING 'QF01'  .
      ENDIF.
  ENDCASE.
ENDFORM.                               " EXECUTE_FCODE_L

*---------------------------------------------------------------------*
*       FORM XCEL_CALL_L                                              *
*---------------------------------------------------------------------*
*       Excel-Aufruf                                                  *
*---------------------------------------------------------------------*
FORM xcel_call_l.

  DATA h_filtered_entries_tab TYPE kkblo_t_sfinfo.
  DATA h_filtered_entries_wa  TYPE kkblo_sfinfo.
  DATA h_hkey        LIKE gxxlt_h OCCURS 90 WITH HEADER LINE.
  DATA h_vkey        LIKE gxxlt_v OCCURS 90 WITH HEADER LINE.
  DATA h_print_text  LIKE gxxlt_p OCCURS 90 WITH HEADER LINE.
  DATA h_online_text LIKE gxxlt_o OCCURS 90 WITH HEADER LINE.
  DATA h_sema        LIKE gxxlt_s OCCURS 90 WITH HEADER LINE.
  DATA h_fieldtab    LIKE dfies   OCCURS 80 WITH HEADER LINE.
  DATA h_itab        LIKE object_tab OCCURS 50 WITH HEADER LINE.

  DATA h_n_att_cols LIKE sy-tabix.
  DATA h_repid      LIKE gxxlt_f-file.
  DATA h_title      LIKE gxxlt_p-text.
  DATA h_so_title   LIKE gxxlt_f-so_title.
  DATA h_index      LIKE sy-index.
  DATA h_n_vrt_keys TYPE n VALUE '2'.
  DATA h_tabname    LIKE dfies-tabname.
  DATA h_langu      LIKE dfies-langu.

  DATA h_fieldcat_wa TYPE slis_fieldcat_alv.

  h_tabname = g_structure.

  CALL FUNCTION 'GET_FIELDTAB'
    EXPORTING
      langu               = sy-langu
      only                = ' '
      tabname             = h_tabname
      withtext            = ' '
*      IMPORTING
*     HEADER              =
*     RC                  =
    TABLES
      fieldtab            = h_fieldtab
    EXCEPTIONS
      internal_error      = 1
      no_texts_found      = 2
      table_has_no_fields = 3
      table_not_activ     = 4
      OTHERS              = 5.

*--- Semantik ------------------------------------------------------
  SORT h_fieldtab BY fieldname.
*--- aktuelle Feldkatalog aus Liste holen --------------------------
  PERFORM get_fieldcat_actual_info_f14.

  SORT g_fieldcat_tab BY no_out ASCENDING
                         tech ASCENDING
                         col_pos ASCENDING.

  h_index = 1.
  DO.
    READ TABLE g_fieldcat_tab INTO h_fieldcat_wa INDEX h_index.
    IF sy-subrc IS INITIAL AND h_fieldcat_wa-no_out = space
    AND h_fieldcat_wa-tech = space.
      READ TABLE h_fieldtab WITH KEY
                               tabname   = h_tabname
                               fieldname = h_fieldcat_wa-fieldname
                               BINARY SEARCH.
      IF sy-subrc IS INITIAL.
        CLEAR h_sema.
        h_sema-col_no   = h_fieldcat_wa-col_pos.     "Spalte auf Screen
        h_sema-col_src  = h_fieldtab-position.       "Position in itab
        CASE h_fieldtab-inttype.
          WHEN 'Z'.
            h_sema-col_typ  = 'NUM'.
            h_sema-col_ops  = 'AVG'.
          WHEN 'C'.
            h_sema-col_typ  = 'STR'.
            h_sema-col_ops  = 'NOP'.
          WHEN 'X'.
            h_sema-col_typ  = 'STR'.
            h_sema-col_ops  = 'NOP'.
          WHEN 'T'.
            h_sema-col_typ  = 'STR'.
            h_sema-col_ops  = 'NOP'.
          WHEN 'P'.
            h_sema-col_typ  = 'NUM'.
            h_sema-col_ops  = 'ADD'.
          WHEN 'F'.
            h_sema-col_typ  = 'NUM'.
            h_sema-col_ops  = 'ADD'.
          WHEN 'I'.
            h_sema-col_typ  = 'NUM'.
            h_sema-col_ops  = 'ADD'.
          WHEN 'N'.
            h_sema-col_typ  = 'STR'.
            h_sema-col_ops  = 'NOP'.
          WHEN 'D'.
            h_sema-col_typ  = 'DAT'.
            h_sema-col_ops  = 'NOP'.
          WHEN OTHERS.
            h_sema-col_typ  = 'STR'.
            h_sema-col_ops  = 'NOP'.
        ENDCASE.
        APPEND h_sema.
*--- Spaltenüberschriften ------------------------------------------
        h_hkey-col_no   = h_fieldcat_wa-col_pos.
        h_hkey-row_no   = 1.
        h_hkey-col_name = h_fieldcat_wa-seltext_m.
        APPEND h_hkey.
      ENDIF.
      h_index = h_index + 1.
    ELSE.
      EXIT.
    ENDIF.
  ENDDO.

  DESCRIBE TABLE h_sema LINES h_n_att_cols.
  h_repid = sy-repid.
  h_title = sy-title.
  h_so_title = sy-title.

*--- Texttabellen ---------------------------------------------------
*    Reportüberschrift
*    Username
*    Datum
  h_tabname = 'SYST'.
  h_langu   = sy-langu.

  REFRESH h_fieldtab.
  CLEAR   h_fieldtab.
  CALL FUNCTION 'GET_FIELDTAB'
    EXPORTING
      langu    = sy-langu
      tabname  = h_tabname
      withtext = 'X'
    TABLES
      fieldtab = h_fieldtab
                 EXCEPTIONS
                 no_texts_found.

  h_online_text-line_no    = 1.
  READ TABLE h_fieldtab WITH KEY fieldname = 'TITLE'.
  h_online_text-info_name  = h_fieldtab-scrtext_l.
  h_online_text-info_value = sy-title.
  APPEND h_online_text.
  h_print_text-hf          = 'F'.
  h_print_text-lcr         = 'R'.
  h_print_text-line_no     = 1.
  h_print_text-text        = sy-title.
  APPEND h_print_text.
  h_online_text-line_no    = 2.
  READ TABLE h_fieldtab WITH KEY fieldname = 'UNAME'.
  h_online_text-info_name  = h_fieldtab-scrtext_l.
  h_online_text-info_value = sy-uname.
  APPEND h_online_text.
  h_print_text-hf          = 'F'.
  h_print_text-lcr         = 'R'.
  h_print_text-line_no     = 2.
  h_print_text-text        = sy-uname.
  APPEND h_print_text.
  h_online_text-line_no    = 3.
  READ TABLE h_fieldtab WITH KEY fieldname = 'DATUM'.
  h_online_text-info_name  = h_fieldtab-scrtext_l.
  WRITE sy-datlo TO h_online_text-info_value.
  APPEND h_online_text.
  h_print_text-hf          = 'F'.
  h_print_text-lcr         = 'R'.
  h_print_text-line_no     = 3.
  WRITE sy-datlo TO h_print_text-text.
  APPEND h_print_text.

  CALL FUNCTION 'PM_NUMBER_OF_KEY_COL'
    EXPORTING
      key_col_default = 1
      key_col_max     = h_n_att_cols
    IMPORTING
      key_col         = h_n_vrt_keys
    EXCEPTIONS
      cancel          = 01.

  IF sy-subrc <> 0.
    EXIT.
  ENDIF.

  CLEAR h_index.
*--- Eine Schlüsselspalte mehr --------------------------------------
  DO h_n_vrt_keys TIMES.
    h_index = sy-index.
*--- Semantik korrigieren -------------------------------------------
    READ TABLE h_sema INDEX h_index.
    h_sema-col_ops = 'DFT'.
    MODIFY h_sema INDEX h_index.
*--- Schlüsselspalte von HKEY nach VKEY -----------------------------
    READ TABLE h_hkey INDEX 1.
    h_vkey-col_no = h_index.
    h_vkey-col_name = h_hkey-col_name.
    APPEND h_vkey.
    DELETE h_hkey INDEX 1.
  ENDDO.

  h_n_att_cols = h_n_att_cols - h_n_vrt_keys.
  LOOP AT h_hkey.
    h_hkey-col_no = h_hkey-col_no - h_n_vrt_keys.
    MODIFY h_hkey.
  ENDLOOP.
*--- Falls Objekte markiert nur diese übernehmen sonst alle -------
  LOOP AT object_tab WHERE selected = g_x.
    h_itab = object_tab.
    APPEND h_itab.
  ENDLOOP.
  IF NOT sy-subrc IS INITIAL.
*--- Filter aus Listviewer muß berücksichtigt werden --------------
    IF g_filter_tab[] IS INITIAL.
      h_itab[] = object_tab[].
    ELSE.
*--- Filter lesen und abgleichen mit itab -------------------------
      CALL FUNCTION 'K_KKB_LIST_LAYOUT_INFO_GET'
        IMPORTING
          et_filtered_entries = h_filtered_entries_tab[]
        EXCEPTIONS
          no_infos            = 1
          OTHERS              = 2.
      LOOP AT object_tab.
*--- in filter_entries_tab stehen alle indizes von ausgefilterten
*--- zeilen
        READ TABLE h_filtered_entries_tab INTO h_filtered_entries_wa
                                          WITH KEY index = sy-tabix
                                                   BINARY SEARCH.
        CHECK NOT sy-subrc IS INITIAL.
        h_itab = object_tab.
        APPEND h_itab.
      ENDLOOP.
    ENDIF.
  ENDIF.
*   h_itab[] = object_tab[].
* endif.
*--- Excel starten ------------------------------------------------
  CALL FUNCTION 'XXL_FULL_API'
    EXPORTING
      sema_type         = 'X'
      filename          = h_repid
      header_1          = h_title
      so_title          = h_so_title
      no_dialog         = ' '
      no_start          = ' '
      n_att_cols        = h_n_att_cols
      n_hrz_keys        = 1
      n_vrt_keys        = h_n_vrt_keys
    TABLES
      data              = h_itab
      hkey              = h_hkey
      online_text       = h_online_text
      print_text        = h_print_text
      sema              = h_sema
      vkey              = h_vkey
    EXCEPTIONS
      cancelled_by_user = 01
      data_too_big      = 02
      dim_mismatch_data = 03
      dim_mismatch_sema = 04
      dim_mismatch_vkey = 05
      error_in_hkey     = 06
      error_in_sema     = 07
      file_open_error   = 08
      file_write_error  = 09
      inv_data_range    = 10
      inv_winsys        = 11
      inv_xxl           = 12.

ENDFORM.                    "XCEL_CALL_L


*---------------------------------------------------------------------*
*       FORM GET_COLUMN_MARKED_L                                      *
*---------------------------------------------------------------------*
*       Feld zur markierten Spalte wird ermittelt                     *
*---------------------------------------------------------------------*
*  -->  F_SELFIELD                                                    *
*  -->  F_FIELDCAT_WA                                                 *
*---------------------------------------------------------------------*
FORM get_column_marked_l   USING
                           f_selfield    TYPE slis_selfield
                           f_fieldcat_wa TYPE slis_fieldcat_alv
                           f_field       LIKE dfies-fieldname.

  DATA: BEGIN OF h_fieldline,
          filler(23),
          col(2),                      "markierte Spalte
        END OF h_fieldline.

  DATA: h_string(23) VALUE 'GT_STACK2-S_HEADER-TEXT'.

  IF f_selfield-sel_tab_field CS h_string.
*--- Spalte ausgewählt ? --------------------------------------------
    h_fieldline = f_selfield-sel_tab_field.
    IF NOT h_fieldline-col IS INITIAL.

*sort g_fieldcat_tab by no_out tech col_pos.

*--- Feldcatalog für ausgewählte Spalte wird gelesen ----------------
      READ TABLE g_fieldcat_tab INTO f_fieldcat_wa
                                WITH KEY col_pos = h_fieldline-col
                                         tech = space.

      IF sy-subrc = 0.
        f_field = f_fieldcat_wa-fieldname.
      ELSE.
        CLEAR f_fieldcat_wa.
      ENDIF.
    ENDIF.
  ENDIF.

ENDFORM.                    "GET_COLUMN_MARKED_L

*---------------------------------------------------------------------*
*       FORM GRAPHICS_l                                               *
*---------------------------------------------------------------------*
*       Anzahl/Anteil pro Feld                                        *
*---------------------------------------------------------------------*
FORM graphics_l USING f_selfield TYPE slis_selfield.

  DATA: h_filtered_entries_tab TYPE kkblo_t_sfinfo.
  DATA: h_filtered_entries_wa  TYPE kkblo_sfinfo.

  DATA: BEGIN OF h_statistics OCCURS 0,
          field(40),
          count     TYPE p,
        END OF h_statistics,
        h_count TYPE p,
        h_lines LIKE sy-tabix,

        BEGIN OF h_object_wa,
          filler(11) VALUE 'OBJECT_TAB-',
          field(30),                    "Feld zur markierten Spalte
        END OF h_object_wa,

        h_fieldcat_wa TYPE slis_fieldcat_alv.

  FIELD-SYMBOLS:
    <h_field>.

  PERFORM get_column_marked_l USING
                             f_selfield
                             h_fieldcat_wa
                             h_object_wa-field.

  IF NOT h_object_wa-field IS INITIAL.
    ASSIGN (h_object_wa) TO <h_field>.
    REFRESH h_statistics.
*--- Statistiktabelle wird aufgebaut --------------------------------
    LOOP AT object_tab WHERE selected = g_x.
      MOVE <h_field> TO h_statistics-field.
      h_statistics-count = 1.
      COLLECT h_statistics.
    ENDLOOP.
*--- keine Zeilen markiert -> es wird alles übernommen --------------
    IF NOT sy-subrc IS INITIAL.
*--- Filter aus Listviewer muß berücksichtigt werden --------------
      IF g_filter_tab[] IS INITIAL.
        LOOP AT object_tab.
          MOVE <h_field> TO h_statistics-field.
          h_statistics-count = 1.
          COLLECT h_statistics.
        ENDLOOP.
      ELSE.
*--- Filter lesen und abgleichen mit itab -------------------------
        CALL FUNCTION 'K_KKB_LIST_LAYOUT_INFO_GET'
          IMPORTING
            et_filtered_entries = h_filtered_entries_tab[]
          EXCEPTIONS
            no_infos            = 1
            OTHERS              = 2.
        LOOP AT object_tab.
*--- in filter_entries_tab stehen alle indizes von ausgefilterten
*--- zeilen
          READ TABLE h_filtered_entries_tab INTO h_filtered_entries_wa
                                            WITH KEY index = sy-tabix
                                                     BINARY SEARCH.
          CHECK NOT sy-subrc IS INITIAL.
          MOVE <h_field> TO h_statistics-field.
          h_statistics-count = 1.
          COLLECT h_statistics.
        ENDLOOP.
      ENDIF.
    ENDIF.

    SORT h_statistics BY count DESCENDING.
    DESCRIBE TABLE h_statistics LINES h_lines.
    IF h_lines > 20.
      LOOP AT h_statistics.
        IF sy-tabix > 20.
          h_count = h_statistics-count.
          DELETE h_statistics.
          READ TABLE h_statistics INDEX 20.
          h_statistics-count = h_statistics-count + h_count.
          h_statistics-field = 'Sonstige'(son).
          MODIFY h_statistics INDEX 20.
        ENDIF.
      ENDLOOP.
    ENDIF.
    CALL FUNCTION 'GRAPH_2D'
      EXPORTING
        valt       = 'Anzahl'(anz)
        mail_allow = 'X'
        titl       = h_fieldcat_wa-seltext_m
      TABLES
        data       = h_statistics.
  ELSE.
    MESSAGE i081(ih).
  ENDIF.

ENDFORM.                               "  GRAPHICS_L

*--------------------------------------------------------------------*
* And finally, the INCLUDES....                                      *
*--------------------------------------------------------------------*
INCLUDE rqalvf14.
INCLUDE rqalvf16.
INCLUDE rq00mf10.
*&---------------------------------------------------------------------*
*&      Form  PUT_SAMPLES_TO_TOOLBOX
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM put_samples_to_toolbox.

  CONSTANTS lc_plnty_shopfloorrout TYPE plnty VALUE 'V'.

  DATA: l_samples TYPE qsmpl_list OCCURS 0 WITH HEADER LINE.
  DATA: l_qasvtab TYPE qasv       OCCURS 0 WITH HEADER LINE.
  DATA: l_qapptab TYPE qapp       OCCURS 0 WITH HEADER LINE.
  DATA: l_qamvtab TYPE qamv       OCCURS 0 WITH HEADER LINE.
  DATA: c_max_insp_point LIKE bapi2045d5-insppoint VALUE '999999'.
  DATA: l_trange         TYPE rsds_trange.
  DATA: l_where_clauses  TYPE rsds_twhere.
  DATA: l_qamv           LIKE LINE OF l_where_clauses.
  DATA: l_qapp           LIKE LINE OF l_where_clauses.
  DATA:
    l_lines          TYPE i,
    l_subrc          LIKE sy-subrc,
    l_langzeit_aktiv TYPE c,
    l_anzpp          LIKE qapp-probenr.

* check authorization
  DATA(lo_auth_check) = cl_qm_authorization_check=>get_instance( ).
  TRY.
      lo_auth_check->check_q_insprslt(
        EXPORTING
          iv_pruefart               = object_tab-art
          iv_werk                   = object_tab-werk
          iv_arbpl                  = object_tab-prplatz
          iv_qmatauth               = object_tab-qmatauth
          iv_actvt                  = if_qm_authorization_check=>sc_insprslt-process
      ).
    CATCH cx_qm_authorization_check INTO DATA(lx_auth_exc).
*     in case of no auth. we display a warning so that the user may continue with other inspection lot
*     for which he/she may has sufficient auth. But the samples of this lot are not added to the toolbox
      MESSAGE ID sy-msgid TYPE 'W' NUMBER sy-msgno
        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      EXIT.
  ENDTRY.

* keine Langzeitpruefung gewuenscht
  IF p_incllz IS INITIAL.
    CLEAR l_langzeit_aktiv.
  ENDIF.

* Statuscheck immer durchfuehren
  CALL FUNCTION 'STATUS_DELETE_FROM_BUFFER'
    EXPORTING
      objnr = object_tab-objnr.
  PERFORM los_status_check CHANGING l_subrc.
  CASE l_subrc.
    WHEN '0'.
*     alles o.k.

    WHEN '10'.
*     Langzeitprüfung gewünscht
      IF NOT p_incllz IS INITIAL.
*       Selektion war mit Langzeitmerkmalen
        l_langzeit_aktiv = 'X'.
      ENDIF.

    WHEN OTHERS.
*     Losstatus läßt keine Ergebniserfassung zu
      EXIT.
  ENDCASE.

* Liefert Werte der dynamischen Selektionen (Selektionsbild)
  CALL FUNCTION 'RS_REFRESH_FROM_DYNAMICAL_SEL'
    EXPORTING
      curr_report        = g_repid
      mode_write_or_move = 'M'
    IMPORTING
      p_trange           = l_trange
    EXCEPTIONS
      not_found          = 1
      wrong_type         = 2
      OTHERS             = 3.
  IF sy-subrc = 0.
* Freie Abgrenzungen: Konvertierung Format RSDS_TRANGE ==> RSDS_TWHERE
    CALL FUNCTION 'FREE_SELECTIONS_RANGE_2_WHERE'
      EXPORTING
        field_ranges  = l_trange
      IMPORTING
        where_clauses = l_where_clauses.
    READ TABLE l_where_clauses INTO l_qamv
                      WITH KEY tablename = 'QAMV'.
* Ermittlung des QAMV-Eintrages in L_QAMV-WHERE_TAB
    IF sy-subrc <> 0.
      CLEAR l_qamv.
    ENDIF.
    READ TABLE l_where_clauses INTO l_qapp
                      WITH KEY tablename = 'QAPP'.
* Ermittlung des QAPP-Eintrages in L_QAPP-WHERE_TAB
    IF sy-subrc <> 0.
      CLEAR l_qapp.
    ENDIF.
  ENDIF.

  MOVE object_tab-prueflos TO l_samples-insplot.
  MOVE object_tab-vorglfnr TO l_samples-inspoper_int.
  MOVE object_tab-vornr    TO l_samples-inspoper.

  IF object_tab-stat07 IS INITIAL.
    IF object_tab-plnty EQ lc_plnty_shopfloorrout.
      MESSAGE e107(qt).
    ENDIF.
* Alle Merkmale einlesen
    SELECT * FROM qamv INTO TABLE l_qamvtab
             WHERE prueflos  EQ l_samples-insplot
               AND vorglfnr  EQ l_samples-inspoper_int
               AND verwmerkm IN p_merk
               AND (l_qamv-where_tab)
               ORDER BY PRIMARY KEY.

    IF NOT l_langzeit_aktiv IS INITIAL.
* Langzeitprüfung gewünscht
      PERFORM langzeitpruefung_active TABLES l_qamvtab.
    ENDIF.

    LOOP AT l_qamvtab.
      MOVE l_qamvtab-merknr  TO l_samples-inspchar.
      MOVE '000000'          TO l_samples-inspsample.

* Einzelne Stichprobe in Toolbox übernehmen
      CALL FUNCTION 'QET4_ADD_SINGLE_SAMPLE'
        EXPORTING
          i_sample                 = l_samples
        EXCEPTIONS
          wrong_operation          = 1
          wrong_insplot            = 2
          wrong_configuration_data = 3
          OTHERS                   = 4.

      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
*        continue.
        EXIT.
      ENDIF.
    ENDLOOP.
  ELSE.
* Prüfpunktabwicklung, alle Probensätze
* Alle Prüfpunkte einlesen
    IF object_tab-stat13 = 4.
      MESSAGE e105(qt) WITH object_tab-stat13.
    ENDIF.
    IF p_anzpp IS INITIAL.
      SELECT * FROM qapp INTO TABLE l_qapptab
               WHERE prueflos EQ l_samples-insplot
                 AND vorglfnr EQ l_samples-inspoper_int
                 AND (l_qapp-where_tab)
                 ORDER BY PRIMARY KEY.
    ELSE.
* Nur die letzten 'p_anzpp' Prüfpunkte betrachten
      SELECT COUNT(*) FROM qapp INTO l_anzpp
             WHERE prueflos EQ l_samples-insplot
               AND vorglfnr EQ l_samples-inspoper_int
               AND (l_qapp-where_tab).

* Vermeiden negativer Selektionswerte
      IF l_anzpp GT p_anzpp.
        l_anzpp = l_anzpp - p_anzpp.
      ELSE.
        l_anzpp = 0.
      ENDIF.
      SELECT * FROM qapp INTO TABLE l_qapptab
               WHERE prueflos EQ l_samples-insplot
                 AND vorglfnr EQ l_samples-inspoper_int
                 AND probenr  GT l_anzpp
                 AND (l_qapp-where_tab)
                 ORDER BY PRIMARY KEY.
    ENDIF.

*     Eingabezeile generieren
    l_qapptab-prueflos = l_samples-insplot.
    l_qapptab-vorglfnr = l_samples-inspoper_int.
    l_qapptab-probenr = c_max_insp_point.
    APPEND l_qapptab.

* alle Merkmale einlesen
    SELECT * FROM qamv INTO TABLE l_qamvtab
             WHERE prueflos EQ l_samples-insplot
               AND vorglfnr EQ l_samples-inspoper_int
               AND verwmerkm IN p_merk
               AND (l_qamv-where_tab)
               ORDER BY PRIMARY KEY.

    IF NOT l_langzeit_aktiv IS INITIAL.
* Langzeitprüfung gewünscht
      PERFORM langzeitpruefung_active TABLES l_qamvtab.
    ENDIF.

*   Probensätze erzeugen
    LOOP AT l_qapptab.
      LOOP AT l_qamvtab.

*     Ungeplante Merkmale:
*     AKTPPKT space: bei allen Prüfpunkten (Vergangenheit + Zukunft)
*                 1: nur bei dem in PPKTUNGEMK angegeben Prüfpunkt
*                 2: ab dem in PPKTUNGEMK angegebenen Prüfpunkt
        CASE l_qamvtab-aktppkt.
          WHEN space.
*             do nothing
          WHEN 1.
            CHECK l_qamvtab-ppktungemk = l_qapptab-probenr.
          WHEN 2.
            CHECK l_qamvtab-ppktungemk <= l_qapptab-probenr.
        ENDCASE.

        MOVE l_qamvtab-merknr  TO l_samples-inspchar.
        MOVE l_qapptab-probenr TO l_samples-inspsample.

*       Einzelne Stichprobe in Toolbox übernehmen
        CALL FUNCTION 'QET4_ADD_SINGLE_SAMPLE'
          EXPORTING
            i_sample                 = l_samples
          EXCEPTIONS
            wrong_operation          = 1
            wrong_insplot            = 2
            wrong_configuration_data = 3
            OTHERS                   = 4.

        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
             WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
*          continue.
          EXIT.
        ENDIF.

      ENDLOOP.                         "L_QAMVTAB
    ENDLOOP.                           "L_QAPPTAB

  ENDIF.

ENDFORM.                               " PUT_SAMPLES_TO_TOOLBOX
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
    l_submitinfo  LIKE rssubinfo.

  CALL FUNCTION 'RS_SUBMIT_INFO'
    IMPORTING
      p_submit_info = l_submitinfo.

  IF l_submitinfo-mode_vari IS INITIAL.
    LOOP AT SCREEN.
      IF screen-group1 EQ 'PRG'.
* Variantenpflege, dann Feld 'P_SCRMAN' eingabebereit
        screen-active = '0'.
        MODIFY SCREEN.
      ENDIF.
      IF screen-group1 EQ 'SIP'.
* Variantenpflege, dann Feld 'P_SIN_PR' eingabebereit
        screen-active = '0'.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.

ENDFORM.                               " CHECK_VARIANT_MAINTAIN
*&---------------------------------------------------------------------*
*&      Form  CALL_SCREEN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM call_screen.

* Aufruf der Erfassungstabelle
  CALL FUNCTION 'Y_QMLIMS_QET5_CALL_SCREEN'
    EXPORTING
      i_screen_manager = p_scrman
      i_worklist       = sy-cprog
    IMPORTING
      e_ok_code        = g_ok_code_screen.

* Funktionsgruppe auf Initialzustand zurückstellen
  CALL FUNCTION 'QET4_INITIALIZE'.

ENDFORM.                               " CALL_SCREEN
*&---------------------------------------------------------------------*
*&      Form  LOS_STATUS_CHECK
*&---------------------------------------------------------------------*
*       Die Form prüft, ob die Bearbeitung zum Prüflos möglich ist.
*       Die Logik ist folgende:
*       Erst wird der betriebsw. Vorgang für Ergebniserfassung geprüft.
*       Falls der aktuelle Status das nicht zulässt, wird geprüft,
*       ob evtl. eine Bearbeitung der Langzeitmerkmale möglich ist.
*       Erst wenn auch das nicht möglich ist, wird die Statusverwaltung
*       im Dialog aufgerufen.
*----------------------------------------------------------------------*
*  <->  P_SUBRC        SUBRC
*        1             Losstatus läßt keine Ergebniserfassung zu
*       10             Langzeitprüfung gewünscht
*----------------------------------------------------------------------*
FORM los_status_check CHANGING VALUE(p_subrc) LIKE sy-subrc.

  DATA:
    l_antwort    TYPE c.

* Prüfung ob Ergebnisse erfaßt werden können
  CALL FUNCTION 'QAST_PROCESS_ACTIVITY'
    EXPORTING
      i_check_only         = ' '
      i_dialog             = ' '
      i_objnr              = object_tab-objnr
      i_vorgang            = 'QM18'
    EXCEPTIONS
      not_allowed          = 01
      activity_not_allowed = 02.

  IF sy-subrc EQ 02.
    p_subrc = 1.
    MESSAGE w024 WITH object_tab-prueflos.
* Die Erfassung von Merkmalsergebnissen zum Prüflos & ist nicht möglich

  ELSEIF sy-subrc EQ 01.
* Kurzzeitprüfung nicht möglich! Gibt es offene Langzeitmerkmale ?
    CALL FUNCTION 'QAST_PROCESS_ACTIVITY'
      EXPORTING
        i_check_only = ' '
        i_dialog     = ' '
        i_objnr      = object_tab-objnr
        i_vorgang    = 'QM19'
      EXCEPTIONS
        not_allowed  = 01.

    IF sy-subrc = 0.
* Erfassen Langzeitmerkmale möglich, falls gewünscht
      IF g_antwort IS INITIAL.
        CALL FUNCTION 'POPUP_TO_CONFIRM_STEP'
          EXPORTING
            textline1 = TEXT-101
            textline2 = TEXT-102
            titel     = TEXT-100
          IMPORTING
            answer    = l_antwort.
        g_antwort = l_antwort.
      ELSE.
        l_antwort = g_antwort.
      ENDIF.
      CASE l_antwort.
        WHEN 'J'.
* Alles o.k., Langzeitmermale können erfasst werden
          p_subrc = 10.
        WHEN OTHERS.
* Kein Einstieg in die Ergebniserfassung
          p_subrc = 1.
      ENDCASE.
    ELSE.
* Ergebniserfassung nicht möglich; weder Kurzzeit noch Langzeit !
* Vorgangscheck nun im Dialog !
      CALL FUNCTION 'QAST_PROCESS_ACTIVITY'
        EXPORTING
          i_check_only         = 'X'
          i_dialog             = 'X'
          i_objnr              = object_tab-objnr
          i_vorgang            = 'QM18'
        EXCEPTIONS
          not_allowed          = 01
          activity_not_allowed = 02.

      IF sy-subrc <> 0.
        p_subrc = 1.
      ENDIF.
    ENDIF.

  ELSE.
* Überprüfung, ob Warnung gesendet werden muß (z.B. Skip, LSTV)
* Vorgangscheck nun im Dialog !
    CALL FUNCTION 'QAST_PROCESS_ACTIVITY'
      EXPORTING
        i_check_only         = ' '
        i_dialog             = 'X'
        i_objnr              = object_tab-objnr
        i_vorgang            = 'QM18'
      EXCEPTIONS
        not_allowed          = 01
        activity_not_allowed = 02.

    IF sy-subrc <> 0.
      p_subrc = 1.
    ENDIF.
  ENDIF.

ENDFORM.                               " LOS_STATUS_CHECK
*&---------------------------------------------------------------------*
*&      Form  LANGZEITPRUEFUNG_ACTIVE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_QAMVTAB  text
*----------------------------------------------------------------------*
FORM langzeitpruefung_active TABLES   p_qamvtab STRUCTURE qamv.

  DATA:
    l_fill    LIKE sy-tabix.

  LOOP AT p_qamvtab.
    MOVE p_qamvtab-steuerkz TO qmkst.
    IF qmkst-lzeitkz IS INITIAL.
* Kein Langzeitmerkmal, aber Langzeitprüfung ist aktiv und gewünscht
      DELETE p_qamvtab.
    ENDIF.
  ENDLOOP.

  DESCRIBE TABLE p_qamvtab LINES l_fill.
  IF l_fill IS INITIAL.
    MESSAGE i027.
* Bei diesem Vorgang sind keine Merkmale mit Langzeitprüfung vorhanden
  ENDIF.

ENDFORM.                               " LANGZEITPRUEFUNG_ACTIVE
*&---------------------------------------------------------------------*
*&      Form  SKIP_LIST
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM skip_list.

  DATA:
    l_ucom     LIKE sy-ucomm VALUE 'TAMV',
    l_selfield TYPE slis_selfield.

  object_tab-selected = 'X'.
  MODIFY object_tab TRANSPORTING selected WHERE selected EQ ' '.

  PERFORM user_command_l USING l_ucom
                               l_selfield.

ENDFORM.                               " SKIP_LIST
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

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  FILTER_QALS_TAB
*&---------------------------------------------------------------------*
*     This form is called in FORM PUT_QALS_9xx of logical database
*     program SAPDBPGQ at first execution of this form
*     QALS records are selected into a table. This table then is further
*     by calling FILTER_QALS_TAB to reduce the number of records
*     used later for an "SELECT for all ENTRIES in QALS_TAB" of dependant
*     Tables like V_QAPO, QAMV etc.
*     When selection is not done via PUT_QALS_9xx this method is not
*     called, parameter gv_callback is initial and filtering is done
*     in main routine after GET QALS
*----------------------------------------------------------------------*
FORM filter_qals_tab IMPLEMENTATION.
  DATA: lv_ok TYPE xfeld.

  FIELD-SYMBOLS:
    <ls_qals> TYPE qals.

  LOOP AT qals_tab ASSIGNING <ls_qals>.

    CLEAR lv_ok.
    PERFORM check_qals USING <ls_qals> CHANGING lv_ok.
    IF lv_ok IS INITIAL.
      DELETE qals_tab.
    ENDIF.

  ENDLOOP.

  gv_callback = abap_true.
ENDFORM.                    "filter_QALS_TAB
*&---------------------------------------------------------------------*
*&      Form  Check_qals
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_QALS     text
*      -->P_OK       text
*----------------------------------------------------------------------*
FORM check_qals USING p_qals TYPE qals CHANGING p_ok TYPE xfeld.

  CLEAR p_ok.

* Prüfartenberechtigung prüfen mit Puffer
  IF g_auth-art  NE p_qals-art
  OR g_auth-werk NE p_qals-werk
  OR g_auth-qmatauth NE p_qals-qmatauth
  OR g_auth-cvp_xblck NE p_qals-cvp_xblck.
*   Berechtigung hat sich geändert, neu prüfen
    "Logical DB PGQ will only return unblocked inspection lots if the suer
    "is not authorized to show insp. lots with blocked partners
    "Therefore auth. check with cvp_xblck is not necessary here
    MOVE-CORRESPONDING p_qals TO g_auth.
    TRY.
        cl_qm_authorization_check=>get_instance( )->check_q_insplot(
          EXPORTING
            iv_pruefart               = g_auth-art
            iv_werk                   = g_auth-werk
            iv_actvt                  = if_qm_authorization_check=>sc_insplot-display
            iv_qmatauth               = g_auth-qmatauth
            iv_xblck                  = g_auth-cvp_xblck ).
        MOVE g_x TO g_auth-ok.
      CATCH cx_qm_authorization_check.
        CLEAR g_auth-ok.
    ENDTRY.

  ENDIF.

* Berechtigung prüfen
  IF g_auth-ok EQ space.
* Keine Berechtigung
    ADD 1 TO g_anz_no_auth.
    RETURN.
  ENDIF.

* Material
  IF NOT p_qals-qmatauth IS INITIAL.
    CALL FUNCTION 'QAUT_MATERIAL'
      EXPORTING
        i_werks          = p_qals-werk
        i_qmatmodus      = 'D'
        i_qmatauth       = p_qals-qmatauth
      EXCEPTIONS
        no_authorization = 01.
    CHECK sy-subrc EQ 0.
  ENDIF.

* Betriebswirtschaflicher Vorgang: Arbeitsvorrat Prüfergebnisse
  CALL FUNCTION 'QAST_PROCESS_ACTIVITY'
    EXPORTING
      i_check_only         = 'X'
      i_dialog             = ' '
      i_objnr              = p_qals-objnr
      i_vorgang            = 'QM25'
    EXCEPTIONS
      not_allowed          = 01
      activity_not_allowed = 02.
  CHECK sy-subrc EQ 0.

  p_ok = abap_true.
ENDFORM.                    "Check_qals
