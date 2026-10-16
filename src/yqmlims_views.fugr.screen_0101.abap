PROCESS BEFORE OUTPUT.
  MODULE liste_initialisieren.
  LOOP AT extract WITH CONTROL
   tctrl_yqm_spez_pmk_t CURSOR nextline.
    MODULE liste_show_liste.
    MODULE read_qpmk_text.
    MODULE read_qmtt_text.
  ENDLOOP.
*
PROCESS AFTER INPUT.
  MODULE liste_exit_command AT EXIT-COMMAND.
  MODULE liste_before_loop.
  LOOP AT extract.
    MODULE liste_init_workarea.
    CHAIN.
      FIELD yqm_spez_pmk_t-spezid .
      FIELD yqm_spez_pmk_t-qpmk_zaehl .
      FIELD yqm_spez_pmk_t-verwmerkm .
      FIELD yqm_spez_pmk_t-sollwert .
      FIELD yqm_spez_pmk_t-toleranzun .
      FIELD yqm_spez_pmk_t-toleranzob .
      FIELD yqm_spez_pmk_t-grenzeun1 .
      FIELD yqm_spez_pmk_t-grenzeob1 .
      FIELD yqm_spez_pmk_t-grenzeun2 .
      FIELD yqm_spez_pmk_t-grenzeob2 .
      FIELD yqm_spez_pmk_t-plausiunten .
      FIELD yqm_spez_pmk_t-plausioben .
      FIELD yqm_spez_pmk_t-signifikanztyp .
      FIELD yqm_spez_pmk_t-qmtb_werks .
      FIELD yqm_spez_pmk_t-pmethode .
      FIELD yqm_spez_pmk_t-cert_grenze .
      MODULE set_update_flag ON CHAIN-REQUEST.
    ENDCHAIN.
    FIELD vim_marked MODULE liste_mark_checkbox.
    CHAIN.
      FIELD yqm_spez_pmk_t-spezid .
      FIELD yqm_spez_pmk_t-qpmk_zaehl .
      FIELD yqm_spez_pmk_t-verwmerkm .
      MODULE liste_update_liste.
    ENDCHAIN.
  ENDLOOP.
  MODULE liste_after_loop.

PROCESS ON VALUE-REQUEST.
  FIELD yqm_spez_pmk_t-signifikanztyp MODULE vcl_help_values.
  FIELD yqm_spez_pmk_t-spezid         MODULE vcl_help_values.
  FIELD yqm_spez_pmk_t-qmtb_werks     MODULE f4_pmethode_101.
  FIELD yqm_spez_pmk_t-pmethode       MODULE f4_pmethode_101.
