PROCESS BEFORE OUTPUT.
  MODULE liste_initialisieren.
  LOOP AT extract WITH CONTROL
   tctrl_yqm_rtext_t CURSOR nextline.
    MODULE liste_show_liste.
  ENDLOOP.
*
PROCESS AFTER INPUT.
  MODULE liste_exit_command AT EXIT-COMMAND.
  MODULE liste_before_loop.
  LOOP AT extract.
    MODULE liste_init_workarea.
    CHAIN.
      FIELD yqm_rtext_t-repid .
      FIELD yqm_rtext_t-tabname .
      FIELD yqm_rtext_t-fieldname .
      FIELD yqm_rtext_t-reptext .
      FIELD yqm_rtext_t-scrtext_s .
      FIELD yqm_rtext_t-scrtext_m .
      FIELD yqm_rtext_t-scrtext_l .
      FIELD yqm_rtext_t-no_out .
      MODULE set_update_flag ON CHAIN-REQUEST.
    ENDCHAIN.
    FIELD vim_marked MODULE liste_mark_checkbox.
    CHAIN.
      FIELD yqm_rtext_t-repid .
      FIELD yqm_rtext_t-tabname .
      FIELD yqm_rtext_t-fieldname .
      MODULE liste_update_liste.
    ENDCHAIN.
  ENDLOOP.
  MODULE liste_after_loop.
