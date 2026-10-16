PROCESS BEFORE OUTPUT.
  MODULE liste_initialisieren.
  LOOP AT extract WITH CONTROL
   tctrl_yqm_qprv_tplnr_t CURSOR nextline.
    MODULE liste_show_liste.
  ENDLOOP.
*
PROCESS AFTER INPUT.
  MODULE liste_exit_command AT EXIT-COMMAND.
  MODULE liste_before_loop.
  LOOP AT extract.
    MODULE liste_init_workarea.
    CHAIN.
      FIELD yqm_qprv_tplnr_t-tplnr .
      FIELD yqm_qprv_tplnr_t-lfdnr .
      FIELD yqm_qprv_tplnr_t-ktext_etikett .
      FIELD yqm_qprv_tplnr_t-ktext .
      FIELD yqm_qprv_tplnr_t-infeort .
      FIELD yqm_qprv_tplnr_t-pn_art_1 .
      FIELD yqm_qprv_tplnr_t-pn_art_2 .
      FIELD yqm_qprv_tplnr_t-pn_art_3 .
      FIELD yqm_qprv_tplnr_t-pn_art_s .
      FIELD yqm_qprv_tplnr_t-pn_art_k .
      FIELD yqm_qprv_tplnr_t-pn_art_w .
      FIELD yqm_qprv_tplnr_t-pn_art_z .
      MODULE set_update_flag ON CHAIN-REQUEST.
    ENDCHAIN.
    FIELD vim_marked MODULE liste_mark_checkbox.
    CHAIN.
      FIELD yqm_qprv_tplnr_t-tplnr .
      FIELD yqm_qprv_tplnr_t-lfdnr .
      MODULE liste_update_liste.
    ENDCHAIN.
  ENDLOOP.
  MODULE liste_after_loop.
