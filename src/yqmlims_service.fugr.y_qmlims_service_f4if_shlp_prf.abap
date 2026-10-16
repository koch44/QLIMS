FUNCTION y_qmlims_service_f4if_shlp_prf .
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  TABLES
*"      SHLP_TAB TYPE  SHLP_DESCT
*"      RECORD_TAB STRUCTURE  SEAHLPRES
*"  CHANGING
*"     VALUE(SHLP) TYPE  SHLP_DESCR
*"     VALUE(CALLCONTROL) LIKE  DDSHF4CTRL STRUCTURE  DDSHF4CTRL
*"----------------------------------------------------------------------

  DATA: lv_field_name TYPE char32.

  FIELD-SYMBOLS <lv_date>    TYPE dats.
  FIELD-SYMBOLS <lv_pn_flag> TYPE any.
  FIELD-SYMBOLS <ls_alv_pruefer>  TYPE yqm_alv_pruefer.
  FIELD-SYMBOLS <ls_alv_schulung> TYPE yqm_alv_prueferschulung.

  DATA: lt_range_tab_kname     TYPE RANGE OF yqm_alv_pruefer-kname.
  DATA: lt_range_tab_pname     TYPE RANGE OF yqm_alv_pruefer-pname.
  DATA: lt_range_tab_lname     TYPE RANGE OF yqm_alv_pruefer-lname.
  DATA: lt_range_tab_yvxfan    TYPE RANGE OF yqm_alv_pruefer-yvxfan.
  DATA: lt_range_tab_list      TYPE RANGE OF yqm_alv_pruefer-in_listung_flag.
  DATA: lt_range_tab_aktiv     TYPE RANGE OF yqm_alv_pruefer-aktiv.
  DATA: lt_range_tab_pn_bueb   TYPE RANGE OF yqm_alv_pruefer-pn_bueb.
  DATA: lt_range_tab_pn_senso  TYPE RANGE OF yqm_alv_pruefer-pn_senso.
  DATA: lt_range_tab_pn_chemie TYPE RANGE OF yqm_alv_pruefer-pn_chemie.
  DATA: lt_range_tab_pn_mikro  TYPE RANGE OF yqm_alv_pruefer-pn_mikro.
  DATA: lt_range_tab_pn_legio  TYPE RANGE OF yqm_alv_pruefer-pn_legio.

  DATA  ls_range_kname     LIKE LINE OF lt_range_tab_kname.
  DATA  ls_range_pname     LIKE LINE OF lt_range_tab_pname.
  DATA  ls_range_lname     LIKE LINE OF lt_range_tab_lname.
  DATA  ls_range_yvxfan    LIKE LINE OF lt_range_tab_yvxfan .
  DATA  ls_range_list      LIKE LINE OF lt_range_tab_list .
  DATA  ls_range_aktiv     LIKE LINE OF lt_range_tab_aktiv .
  DATA  ls_range_pn_bueb   LIKE LINE OF lt_range_tab_pn_bueb.
  DATA  ls_range_pn_senso  LIKE LINE OF lt_range_tab_pn_senso.
  DATA  ls_range_pn_chemie LIKE LINE OF lt_range_tab_pn_chemie.
  DATA  ls_range_pn_mikro  LIKE LINE OF lt_range_tab_pn_mikro.
  DATA  ls_range_pn_legio  LIKE LINE OF lt_range_tab_pn_legio.

  DATA: lt_alv_pruefer  TYPE TABLE OF yqm_alv_pruefer.
  DATA: lt_alv_schulung TYPE TABLE OF yqm_alv_prueferschulung.

  DATA: ls_selopt TYPE ddshselopt.

* EXIT immediately, if you do not want to handle this step
  IF callcontrol-step <> 'SELONE' AND
     callcontrol-step <> 'SELECT' AND
     " AND SO ON
     callcontrol-step <> 'DISP'.
    EXIT.
  ENDIF.

*"----------------------------------------------------------------------
* STEP SELONE  (Select one of the elementary searchhelps)
*"----------------------------------------------------------------------
* This step is only called for collective searchhelps. It may be used
* to reduce the amount of elementary searchhelps given in SHLP_TAB.
* The compound searchhelp is given in SHLP.
* If you do not change CALLCONTROL-STEP, the next step is the
* dialog, to select one of the elementary searchhelps.
* If you want to skip this dialog, you have to return the selected
* elementary searchhelp in SHLP and to change CALLCONTROL-STEP to
* either to 'PRESEL' or to 'SELECT'.
  IF callcontrol-step = 'SELONE'.
*   PERFORM SELONE .........
    EXIT.
  ENDIF.

*"----------------------------------------------------------------------
* STEP PRESEL  (Enter selection conditions)
*"----------------------------------------------------------------------
* This step allows you, to influence the selection conditions either
* before they are displayed or in order to skip the dialog completely.
* If you want to skip the dialog, you should change CALLCONTROL-STEP
* to 'SELECT'.
* Normaly only SHLP-SELOPT should be changed in this step.
  IF callcontrol-step = 'PRESEL'.
*   PERFORM PRESEL ..........
    EXIT.
  ENDIF.
*"----------------------------------------------------------------------
* STEP SELECT    (Select values)
*"----------------------------------------------------------------------
* This step may be used to overtake the data selection completely.
* To skip the standard seletion, you should return 'DISP' as following
* step in CALLCONTROL-STEP.
* Normally RECORD_TAB should be filled after this step.
* Standard function module F4UT_RESULTS_MAP may be very helpfull in this
* step.
  IF callcontrol-step = 'SELECT'.

    LOOP AT shlp-selopt INTO ls_selopt.
      IF ls_selopt-shlpfield = 'KNAME'.
        ls_range_kname-sign     = ls_selopt-sign.
        ls_range_kname-option   = ls_selopt-option.
        ls_range_kname-low      = ls_selopt-low.
        ls_range_kname-high     = ls_selopt-high.
        APPEND ls_range_kname TO lt_range_tab_kname.
      ENDIF.
      IF ls_selopt-shlpfield = 'PNAME'.
        ls_range_pname-sign     = ls_selopt-sign.
        ls_range_pname-option   = ls_selopt-option.
        ls_range_pname-low      = ls_selopt-low.
        ls_range_pname-high     = ls_selopt-high.
        APPEND ls_range_pname TO lt_range_tab_pname.
      ENDIF.
      IF ls_selopt-shlpfield = 'LNAME'.
        ls_range_lname-sign     = ls_selopt-sign.
        ls_range_lname-option   = ls_selopt-option.
        ls_range_lname-low      = ls_selopt-low.
        ls_range_lname-high     = ls_selopt-high.
        APPEND ls_range_lname TO lt_range_tab_lname.
      ENDIF.
      IF ls_selopt-shlpfield = 'YVXFAN'.
        ls_range_yvxfan-sign     = ls_selopt-sign.
        ls_range_yvxfan-option   = ls_selopt-option.
        ls_range_yvxfan-low      = ls_selopt-low.
        ls_range_yvxfan-high     = ls_selopt-high.
        APPEND ls_range_yvxfan TO lt_range_tab_yvxfan.
      ENDIF.
      IF ls_selopt-shlpfield = 'IN_LISTUNG_FLAG'.
        ls_range_list-sign     = ls_selopt-sign.
        ls_range_list-option   = ls_selopt-option.
        ls_range_list-low      = ls_selopt-low.
        ls_range_list-high     = ls_selopt-high.
        APPEND ls_range_list TO lt_range_tab_list.
      ENDIF.
      IF ls_selopt-shlpfield = 'AKTIV'.
        ls_range_aktiv-sign     = ls_selopt-sign.
        ls_range_aktiv-option   = ls_selopt-option.
        ls_range_aktiv-low      = ls_selopt-low.
        ls_range_aktiv-high     = ls_selopt-high.
        APPEND ls_range_aktiv TO lt_range_tab_aktiv.
      ENDIF.
      IF ls_selopt-shlpfield = 'PN_BUEB'.
        ls_range_pn_bueb-sign     = ls_selopt-sign.
        ls_range_pn_bueb-option   = ls_selopt-option.
        ls_range_pn_bueb-low      = ls_selopt-low.
        ls_range_pn_bueb-high     = ls_selopt-high.
        APPEND ls_range_pn_bueb TO lt_range_tab_pn_bueb.
      ENDIF.
      IF ls_selopt-shlpfield = 'PN_SENSO'.
        ls_range_pn_senso-sign     = ls_selopt-sign.
        ls_range_pn_senso-option   = ls_selopt-option.
        ls_range_pn_senso-low      = ls_selopt-low.
        ls_range_pn_senso-high     = ls_selopt-high.
        APPEND ls_range_pn_senso TO lt_range_tab_pn_senso.
      ENDIF.
      IF ls_selopt-shlpfield = 'PN_CHEMIE'.
        ls_range_pn_chemie-sign     = ls_selopt-sign.
        ls_range_pn_chemie-option   = ls_selopt-option.
        ls_range_pn_chemie-low      = ls_selopt-low.
        ls_range_pn_chemie-high     = ls_selopt-high.
        APPEND ls_range_pn_chemie TO lt_range_tab_pn_chemie.
      ENDIF.
      IF ls_selopt-shlpfield = 'PN_MIKRO'.
        ls_range_pn_mikro-sign     = ls_selopt-sign.
        ls_range_pn_mikro-option   = ls_selopt-option.
        ls_range_pn_mikro-low      = ls_selopt-low.
        ls_range_pn_mikro-high     = ls_selopt-high.
        APPEND ls_range_pn_mikro TO lt_range_tab_pn_mikro.
      ENDIF.
      IF ls_selopt-shlpfield = 'PN_LEGIO'.
        ls_range_pn_legio-sign     = ls_selopt-sign.
        ls_range_pn_legio-option   = ls_selopt-option.
        ls_range_pn_legio-low      = ls_selopt-low.
        ls_range_pn_legio-high     = ls_selopt-high.
        APPEND ls_range_pn_legio TO lt_range_tab_pn_legio.
      ENDIF.
    ENDLOOP.

    SELECT * FROM yqm_pruefer_t INTO CORRESPONDING FIELDS OF TABLE lt_alv_pruefer
      WHERE pname          IN lt_range_tab_pname
      AND   kname          IN lt_range_tab_kname
      AND   lname          IN lt_range_tab_lname
      AND   yvxfan         IN lt_range_tab_yvxfan
      AND   aktiv          IN lt_range_tab_aktiv.
    IF sy-subrc <> 0.
      CLEAR lt_alv_pruefer.
    ENDIF.

    IF NOT lt_alv_pruefer[] IS INITIAL.
      SELECT * FROM yqm_pruefers_t INTO CORRESPONDING FIELDS OF TABLE lt_alv_schulung
        FOR ALL ENTRIES IN lt_alv_pruefer
        WHERE kname EQ lt_alv_pruefer-kname.
      IF sy-subrc <> 0.
        CLEAR lt_alv_schulung.
      ENDIF.
    ENDIF.

    SORT lt_alv_pruefer  BY kname.
    SORT lt_alv_schulung BY kname lfdnr.

    DELETE lt_alv_schulung WHERE loekz = 'X'.
    DELETE ADJACENT DUPLICATES FROM lt_alv_schulung COMPARING kname schulung.

    LOOP AT lt_alv_pruefer ASSIGNING <ls_alv_pruefer>.
      IF    <ls_alv_pruefer>-in_listung   LE sy-datlo
      AND ( <ls_alv_pruefer>-aus_listung  IS INITIAL
        OR  <ls_alv_pruefer>-aus_listung  GE sy-datlo ).
        <ls_alv_pruefer>-in_listung_flag = 'X'.
      ELSE.
        CLEAR <ls_alv_pruefer>-in_listung_flag.
      ENDIF.

      LOOP AT lt_alv_schulung ASSIGNING <ls_alv_schulung>
        WHERE kname = <ls_alv_pruefer>-kname
        AND   loekz EQ space.

        CASE <ls_alv_schulung>-schulung.
          WHEN 'AUD_EXT'
            OR 'AUD_INT'
            OR 'DVGW_BASIC'
            OR 'DVGW_RE'.
            CONCATENATE '<ls_alv_pruefer>-' <ls_alv_schulung>-schulung INTO lv_field_name.
            ASSIGN (lv_field_name) TO <lv_date>.
            IF sy-subrc = 0.
              <lv_date> = <ls_alv_schulung>-zeitpunkt.
            ENDIF.
*            MODIFY lt_alv_pruefer.
          WHEN 'PN_BUEB'
            OR 'PN_SENSO'
            OR 'PN_CHEMIE'
            OR 'PN_MIKRO'
            OR 'PN_LEGIO'.
            IF NOT <ls_alv_schulung>-valid_to IS INITIAL
            AND    <ls_alv_schulung>-valid_to GE sy-datlo.
              CONCATENATE '<ls_alv_pruefer>-' <ls_alv_schulung>-schulung '_DATUM' INTO lv_field_name.
              ASSIGN (lv_field_name)  TO <lv_date>.
              IF sy-subrc = 0.
                <lv_date> = <ls_alv_schulung>-zeitpunkt.
              ENDIF.
              CONCATENATE '<ls_alv_pruefer>-' <ls_alv_schulung>-schulung INTO lv_field_name.
              ASSIGN (lv_field_name) TO <lv_pn_flag>.
              IF sy-subrc = 0.
                <lv_pn_flag> = 'X'.
              ENDIF.
            ENDIF.
          WHEN OTHERS.
        ENDCASE.
      ENDLOOP.
*      MODIFY lt_alv_pruefer.
    ENDLOOP.

    LOOP AT lt_alv_pruefer ASSIGNING <ls_alv_pruefer>.
      IF NOT <ls_alv_pruefer>-in_listung_flag IN lt_range_tab_list
      OR NOT <ls_alv_pruefer>-pn_bueb         IN lt_range_tab_pn_bueb
      OR NOT <ls_alv_pruefer>-pn_senso        IN lt_range_tab_pn_senso
      OR NOT <ls_alv_pruefer>-pn_chemie       IN lt_range_tab_pn_chemie
      OR NOT <ls_alv_pruefer>-pn_mikro        IN lt_range_tab_pn_mikro
      OR NOT <ls_alv_pruefer>-pn_legio        IN lt_range_tab_pn_legio.
        DELETE lt_alv_pruefer.
      ENDIF.
    ENDLOOP.

*   sort lt_selected_tab by kunnr.

* load the selected data into the shlp output list
    CALL FUNCTION 'F4UT_RESULTS_MAP'
      EXPORTING
        source_structure  = 'YQM_ALV_PRUEFER'
*       APPLY_RESTRICTIONS       = 'X'
      TABLES
        shlp_tab          = shlp_tab
        record_tab        = record_tab
        source_tab        = lt_alv_pruefer
      CHANGING
        shlp              = shlp
        callcontrol       = callcontrol
      EXCEPTIONS
        illegal_structure = 1
        OTHERS            = 2.
    IF sy-subrc <> 0.
      EXIT.
    ENDIF.

    callcontrol-step = 'DISP'.


*   PERFORM STEP_SELECT TABLES RECORD_TAB SHLP_TAB
*                       CHANGING SHLP CALLCONTROL RC.
*   IF RC = 0.
*     CALLCONTROL-STEP = 'DISP'.
*   ELSE.
*     CALLCONTROL-STEP = 'EXIT'.
*   ENDIF.
*    EXIT. "Don't process STEP DISP additionally in this call.
  ENDIF.
*"----------------------------------------------------------------------
* STEP DISP     (Display values)
*"----------------------------------------------------------------------
* This step is called, before the selected data is displayed.
* You can e.g. modify or reduce the data in RECORD_TAB
* according to the users authority.
* If you want to get the standard display dialog afterwards, you
* should not change CALLCONTROL-STEP.
* If you want to overtake the dialog on you own, you must return
* the following values in CALLCONTROL-STEP:
* - "RETURN" if one line was selected. The selected line must be
*   the only record left in RECORD_TAB. The corresponding fields of
*   this line are entered into the screen.
* - "EXIT" if the values request should be aborted
* - "PRESEL" if you want to return to the selection dialog
* Standard function modules F4UT_PARAMETER_VALUE_GET and
* F4UT_PARAMETER_RESULTS_PUT may be very helpfull in this step.
  IF callcontrol-step = 'DISP'.
*   PERFORM AUTHORITY_CHECK TABLES RECORD_TAB SHLP_TAB
*                           CHANGING SHLP CALLCONTROL.
    EXIT.
  ENDIF.
ENDFUNCTION.
