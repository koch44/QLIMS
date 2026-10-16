PROCESS BEFORE OUTPUT.
  MODULE liste_initialisieren.
  LOOP AT extract WITH CONTROL
   tctrl_yqm_sigtyp_gw_t CURSOR nextline.
    MODULE liste_show_liste.
*=(1)= zusätzliche Module ===
    MODULE fltp_char_conv_a.
*=(1)========================
  ENDLOOP.
*
PROCESS AFTER INPUT.
  MODULE liste_exit_command AT EXIT-COMMAND.
  MODULE liste_before_loop.
  LOOP AT extract.
    MODULE liste_init_workarea.
    CHAIN.
*=(2)= zusätzliche Module für Variable vom Typ F =============
      FIELD qfltp-qrkfpar1 MODULE qfltp-qrkfpar1_req ON REQUEST.
      FIELD qfltp-qrkfpar2 MODULE qfltp-qrkfpar2_req ON REQUEST.
*=(2)=========================================================
      FIELD yqm_sigtyp_gw_t-signifikanztyp .
      FIELD yqm_sigtyp_gw_t-sortnr .
      FIELD yqm_sigtyp_gw_t-stellen .
      MODULE set_update_flag ON CHAIN-REQUEST.
    ENDCHAIN.
    FIELD vim_marked MODULE liste_mark_checkbox.
    CHAIN.
      FIELD yqm_sigtyp_gw_t-signifikanztyp .
      FIELD yqm_sigtyp_gw_t-sortnr .
      MODULE liste_update_liste.
    ENDCHAIN.
  ENDLOOP.
  MODULE liste_after_loop.

PROCESS ON VALUE-REQUEST.
  FIELD  yqm_sigtyp_gw_t-signifikanztyp MODULE vcl_help_values.
