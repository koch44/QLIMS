PROCESS BEFORE OUTPUT.
  MODULE liste_initialisieren.
  LOOP AT extract WITH CONTROL
   tctrl_yqm_plty_limit_t CURSOR nextline.
    MODULE liste_show_liste.
    MODULE fltp_char_conv_400.
    MODULE read_qpmk_text_3.
  ENDLOOP.
*
PROCESS AFTER INPUT.
  MODULE liste_exit_command AT EXIT-COMMAND.
  MODULE liste_before_loop.
  LOOP AT extract.
    MODULE liste_init_workarea.
    CHAIN.
      FIELD yqm_plty_limit_t-tplnr .
      FIELD yqm_plty_limit_t-werks .
      FIELD yqm_plty_limit_t-verwmerkm .
      FIELD yqm_plty_limit_t-stellen .
      FIELD yqm_plty_limits_display-mittelwert .
      FIELD yqm_plty_limits_display-stdaw .
      FIELD yqm_plty_limit_t-plausiunni .
      FIELD yqm_plty_limit_t-plausiobni .
      FIELD yqm_plty_limits_display-messwert01.
      FIELD yqm_plty_limit_t-messwert01ni .
      FIELD yqm_plty_limits_display-messwert02.
      FIELD yqm_plty_limit_t-messwert02ni .
      FIELD yqm_plty_limits_display-messwert03.
      FIELD yqm_plty_limit_t-messwert03ni .
      FIELD yqm_plty_limits_display-messwert04.
      FIELD yqm_plty_limit_t-messwert04ni .
      FIELD yqm_plty_limits_display-messwert05.
      FIELD yqm_plty_limit_t-messwert05ni .
      FIELD yqm_plty_limits_display-messwert06.
      FIELD yqm_plty_limit_t-messwert06ni .
      FIELD yqm_plty_limits_display-messwert07.
      FIELD yqm_plty_limit_t-messwert07ni .
      FIELD yqm_plty_limits_display-messwert08.
      FIELD yqm_plty_limit_t-messwert08ni .
      FIELD yqm_plty_limits_display-messwert09.
      FIELD yqm_plty_limit_t-messwert09ni .
      FIELD yqm_plty_limits_display-messwert10.
      FIELD yqm_plty_limit_t-messwert10ni .
      FIELD yqm_plty_limit_t-aenderer .
      FIELD yqm_plty_limit_t-aenderdat .
      FIELD yqm_plty_limit_t-prueflos .
      MODULE calc_new_limits ON CHAIN-REQUEST.
      MODULE set_update_flag ON CHAIN-REQUEST.
    ENDCHAIN.
    FIELD vim_marked MODULE liste_mark_checkbox.
    CHAIN.
      FIELD yqm_plty_limit_t-tplnr .
      FIELD yqm_plty_limit_t-werks .
      FIELD yqm_plty_limit_t-verwmerkm .
      MODULE liste_update_liste.
    ENDCHAIN.
  ENDLOOP.
  MODULE liste_after_loop.
