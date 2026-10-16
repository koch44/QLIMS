*&---------------------------------------------------------------------*
*& Include          YQ_LFW1S01
*&---------------------------------------------------------------------*

  SELECT-OPTIONS:
        so_datum               FOR gs_qals-yqm_probedatum,
        so_los                 FOR gs_qals-prueflos,
        so_anl                 FOR yqm_anlass_t-anlass
                               MATCHCODE OBJECT yqm_anlass,
        so_kunnr               FOR gs_qals-yqm_kunnrzl,
        so_ext                 FOR gs_iflot-yqm_extension " OBLIGATORY
                               DEFAULT 'WVA',
        so_stat                FOR gs_jest-stat,
        so_txt                 FOR gs_ya-mail.
  PARAMETERS: pa_low       DEFAULT 'X',

              p_ausgbf(60) DEFAULT '/interface/TN1/ch-qm/LFW_fail' LOWER CASE,
*  PARAMETER: pa_inter ##NEEDED TYPE c LENGTH 21 DEFAULT '/interface/PN1/ch-qm/' LOWER CASE .
              pa_pfad(128) DEFAULT 'C:\Sebam\Daten\THC\' LOWER CASE,
              pa_down(1)   DEFAULT 'X',
              pa_mal       TYPE i    DEFAULT 3,
              pa_stat(5)   DEFAULT 'I0224',
              pa_adr,
              pa_line(2)   DEFAULT '0A',
              pa_url       TYPE gty_adr6-smtp_addr DEFAULT 'marcus.eibl@n-ergie-service.de' LOWER CASE.
