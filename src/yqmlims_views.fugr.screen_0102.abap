PROCESS BEFORE OUTPUT.
  MODULE detail_init.
  MODULE read_qpmk_text.
  MODULE read_qmtt_text.

*
PROCESS AFTER INPUT.
  MODULE detail_exit_command AT EXIT-COMMAND.
  MODULE detail_set_pfstatus.
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
    FIELD yqm_spez_pmk_t-stellen .
    FIELD yqm_spez_pmk_t-signifikanztyp .
    FIELD yqm_spez_pmk_t-qmtb_werks .
    FIELD yqm_spez_pmk_t-pmethode .
    FIELD yqm_spez_pmk_t-cert_grenze .
    MODULE set_update_flag ON CHAIN-REQUEST.
  ENDCHAIN.
  CHAIN.
    FIELD yqm_spez_pmk_t-spezid .
    FIELD yqm_spez_pmk_t-qpmk_zaehl .
    FIELD yqm_spez_pmk_t-verwmerkm .
    FIELD yqm_spez_pmk_t-signifikanztyp.
    MODULE detail_pai.
  ENDCHAIN.

PROCESS ON VALUE-REQUEST.
  FIELD  yqm_spez_pmk_t-spezid MODULE vcl_help_values.
  FIELD  yqm_spez_pmk_t-signifikanztyp MODULE vcl_help_values.
  FIELD yqm_spez_pmk_t-qmtb_werks  MODULE f4_pmethode_102.
  FIELD yqm_spez_pmk_t-pmethode    MODULE f4_pmethode_102.
