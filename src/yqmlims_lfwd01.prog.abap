*&---------------------------------------------------------------------*
*& Include          YQ_LFW1D01
*&---------------------------------------------------------------------*
CLASS lcl_lfw DEFINITION.

  PUBLIC SECTION.

    TYPES: lty_m_rng_datum TYPE RANGE OF yqm_probenahmedatum,
           lty_m_rng_los   TYPE RANGE OF qplos,
           lty_m_rng_anl   TYPE RANGE OF yqm_anlass,
           lty_m_rng_kunnr TYPE RANGE OF kunnr,
           lty_m_rng_ext   TYPE RANGE OF yqm_extension,
           lty_m_rng_stat  TYPE RANGE OF j_status,
           lty_m_rng_txt   TYPE RANGE OF ad_smtpadr,
           lty_m_rng_probe TYPE RANGE OF qphysprnr,
           BEGIN OF lty_m_qapp,
             prueflos TYPE qapp-prueflos,
             vorglfnr TYPE qapp-vorglfnr,
             probenr  TYPE qapp-probenr,
             tplnr    TYPE qapp-tplnr,
             phynr    TYPE qapp-phynr,
             userc1   TYPE qapp-userc1,
           END OF lty_m_qapp,
           BEGIN OF lty_m_t1,
             mandant          TYPE sy-mandt,
             yqm_extension    TYPE iflot-yqm_extension,
             kunnr            TYPE kna1-kunnr,
             yqm_wasserwirt   TYPE iflot-yqm_wasserwirt,
             yqm_anlass       TYPE qals-yqm_anlass,
             strno            TYPE iflos-strno,
             merknr(8),
             yqm_wasserwirtnr TYPE iflot-yqm_wasserwirtnr,
             yqm_bestellnr    TYPE iflot-yqm_bestellnr,
             yqm_medium       TYPE iflot-yqm_medium,
             kurztext         TYPE qpmt-kurztext,
             pltxt            TYPE iflo-pltxt,
             name1            TYPE kna1-name1,
             prueflos         TYPE qals-prueflos,
             ktextlos         TYPE qals-ktextlos,
             slwbez           TYPE qals-slwbez,
             phynr            TYPE qapp-phynr,
             ktextphynr       TYPE qprs-ktext,
             datum            TYPE qals-yqm_probedatum,
             tplnr            TYPE iflos-tplnr,
             mittelwert(10),
             attribut         TYPE qasr-attribut,
             steuerkz         TYPE qamv-steuerkz,
             eqfnr            TYPE iloa-eqfnr,
             iloan            TYPE iloa-iloan,
             yqm_ueberwachung TYPE qals-yqm_ueberwachung,
             dummy20          TYPE qpmk-dummy20,
             betreiber        TYPE iflot-yqm_betreiber,
             bez              TYPE iflot-yqm_bezeichnung,
             probezeit        TYPE qals-yqm_probezeit,
             objnr            TYPE qals-objnr,
             probgew          TYPE qals-yqm_probengewinnung,
             exkuwwanpl(70),
           END OF lty_m_t1,
           ltty_m_t1   TYPE STANDARD TABLE OF lty_m_t1,
           ltty_m_qapp TYPE STANDARD TABLE OF lty_m_qapp WITH EMPTY KEY,
           BEGIN OF lty_m_t3_fail,
             text1     TYPE char7,
             name1     TYPE kna1-name1,
             sep1      TYPE char1,
             text2     TYPE char14,
             strno     TYPE iflos-strno,
             sep2      TYPE char1,
             text3     TYPE char18,
             merknr(8),
             sep3      TYPE char1,
             text4(8),
             kurztext  TYPE qpmt-kurztext,
           END OF lty_m_t3_fail,
           ltty_m_t3_fail TYPE STANDARD TABLE OF lty_m_t3_fail WITH EMPTY KEY,
           BEGIN OF lty_pfad,
             kunnr    TYPE yqm_pfad_t-kunnr,
             kzsebam  TYPE yqm_pfad_t-kzsebam,
             txtsebam TYPE yqm_pfad_t-txtsebam,
           END OF lty_pfad,
           BEGIN OF lty_qprs,
             ktext    TYPE qtext_prs,
             phynr    TYPE qphysprnr,
             entdatum TYPE qprsentdatum,
             entzeit  TYPE qprsentzeit,
           END OF lty_qprs.

    METHODS: constructor IMPORTING iv_uname_i   TYPE sy-uname
                                   it_rng_datum TYPE lty_m_rng_datum
                                   it_rng_los   TYPE lty_m_rng_los
                                   it_rng_anl   TYPE lty_m_rng_anl
                                   it_rng_kunnr TYPE lty_m_rng_kunnr
                                   it_rng_ext   TYPE lty_m_rng_ext
                                   it_rng_stat  TYPE lty_m_rng_stat
                                   it_rng_txt   TYPE lty_m_rng_txt
                                   iv_down      TYPE flag
                                   iv_ausgabef  TYPE char60
                                   iv_adr       TYPE char1
                                   iv_low       TYPE char1
                                   iv_url       TYPE adr6-smtp_addr
                                   iv_pfad      TYPE char128
                                   it_rng_probe TYPE lty_m_rng_probe,
      run      RETURNING VALUE(rv_ok) TYPE abap_bool,
      set_qals IMPORTING is_qals TYPE qals,
      set_qave IMPORTING is_qave TYPE qave,
      set_qamv IMPORTING is_qamv TYPE qamv,
      set_qasr IMPORTING is_qasr TYPE qasr,
      check_qals RETURNING VALUE(rv_subrc) TYPE sy-subrc,
      set_t1 IMPORTING iv_tabname TYPE char4
             CHANGING  cs_t1      TYPE lty_m_t1
                       cv_subrc   TYPE sy-subrc,
      append_t1 IMPORTING is_t1      TYPE lty_m_t1,
      error2file,
      write_prot.


  PRIVATE SECTION.

    TYPES: BEGIN OF lty_m_usr02,
             bname TYPE usr02-bname,
             ustyp TYPE usr02-ustyp,
           END OF lty_m_usr02,
           BEGIN OF lty_m_qpcd,
             katalogart TYPE qpcd-katalogart,
             codegruppe TYPE qpcd-codegruppe,
             code       TYPE qpcd-code,
             version    TYPE qpcd-version,
           END OF lty_m_qpcd,
           BEGIN OF lty_m_adr6,
             addrnumber TYPE adr6-addrnumber,
             persnumber TYPE adr6-persnumber,
             smtp_addr  TYPE adr6-smtp_addr,
           END OF lty_m_adr6,
           ltty_m_adr6 TYPE STANDARD TABLE OF lty_m_adr6 WITH EMPTY KEY.


    DATA:
      gs_m_yq0100form   TYPE yqm_0100form_t,
      gv_m_uname_i      TYPE sy-uname,
      gv_m_uname        TYPE sy-uname,
      gt_m_zqmanlass    TYPE STANDARD TABLE OF yqm_anlass_t WITH EMPTY KEY,
      gt_m_yqamtsbez    TYPE STANDARD TABLE OF yqm_amtsbez_t WITH EMPTY KEY,
      gt_m_zqpfad       TYPE STANDARD TABLE OF lty_pfad WITH EMPTY KEY,
      gs_m_usr02        TYPE lty_m_usr02,
      gt_m_rng_datum    TYPE lty_m_rng_datum,
      gt_m_rng_los      TYPE lty_m_rng_los,
      gt_m_rng_anl      TYPE lty_m_rng_anl,
      gt_m_rng_kunnr    TYPE lty_m_rng_kunnr,
      gt_m_rng_ext      TYPE lty_m_rng_ext,
      gt_m_rng_stat     TYPE lty_m_rng_stat,
      gt_m_rng_txt      TYPE lty_m_rng_txt,
      gv_m_down         TYPE flag,
      gv_m_pfad         TYPE char128,
      gv_m_adr          TYPE char1,
      gv_m_low          TYPE char1,
      gv_m_url          TYPE adr6-smtp_addr,
      gv_m_ausgabef     TYPE char60,
      gt_m_yqsebam      TYPE STANDARD TABLE OF yqm_sebam_t WITH EMPTY KEY,
      gs_m_qals         TYPE qals,
      gt_m_t2           TYPE STANDARD TABLE OF dats,
      gv_m_werk         TYPE qals-werk,
      gs_m_qave         TYPE qave,
      gt_m_qapp         TYPE ltty_m_qapp,
      gs_m_qapp         TYPE lty_m_qapp,
      gt_m_qprs         TYPE STANDARD TABLE OF lty_qprs WITH EMPTY KEY,
      gt_m_t3_fail      TYPE ltty_m_t3_fail,
      gs_m_qamv         TYPE qamv,
      gs_m_qasr         TYPE qasr,
      gv_m_fbmittelw    TYPE char22,
      gv_m_cnt_fail     TYPE i,
      gs_m_qpcd         TYPE lty_m_qpcd,
      gt_m_t1           TYPE ltty_m_t1,
      gt_m_body         TYPE STANDARD TABLE OF solisti1,
      gt_m_empfaenger   TYPE STANDARD TABLE OF solisti1,
      gv_m_datzl        TYPE i,
      gv_m_attach1(50),
      gv_m_betreff      TYPE text50,
      gv_m_zzwasserwirt TYPE iflot-yqm_wasserwirt,
      gv_m_t2_datum     TYPE dats,
      gt_m_ta1          TYPE STANDARD TABLE OF solisti1,
      gt_m_prueflos     TYPE STANDARD TABLE OF qals-prueflos WITH EMPTY KEY,
      gt_m_bemerkung    TYPE tlinet,
      BEGIN OF gs_m_pe,
        lit1(1)  VALUE 'B',
        tab0(2)  TYPE x   VALUE '0009',
        ktextlos TYPE qals-ktextlos,
        tabe(2)  TYPE x   VALUE '000A',
      END OF gs_m_pe,
      gv_m_subrc     TYPE sy-subrc,
      gt_m_rng_probe TYPE lty_m_rng_probe.

    METHODS: select_y_data,
      chcek_status IMPORTING iv_objnr        TYPE j_objnr
                             iv_stat         TYPE j_status
                   RETURNING VALUE(rv_subrc) TYPE sy-subrc,
      set_qapp CHANGING cs_t1 TYPE lty_m_t1,
      get_messwert RETURNING VALUE(rv_fbmittelw) TYPE char22,
      get_stellen RETURNING VALUE(rv_stellen) TYPE i,
      qualitaet RETURNING VALUE(rv_fbmittelw) TYPE char22,
      neu IMPORTING is_t1         TYPE lty_m_t1
          CHANGING  cv_exkuwwanpl TYPE char70
                    cv_start      TYPE char1,
      mailadresse IMPORTING iv_kunnr       TYPE kna1-kunnr
                  RETURNING VALUE(rt_adr6) TYPE ltty_m_adr6,
      dateiopen IMPORTING is_t1 TYPE lty_m_t1,
      kopf IMPORTING is_t1 TYPE lty_m_t1,
      datum IMPORTING iv_dats         TYPE dats
            RETURNING VALUE(rv_datum) TYPE char10,
      starttxt IMPORTING is_t1         TYPE lty_m_t1
               CHANGING  cv_start      TYPE char1
                         cv_exkuwwanpl TYPE char70,
      poskopf IMPORTING is_t1         TYPE lty_m_t1
              CHANGING  cv_start      TYPE char1
                        cv_exkuwwanpl TYPE char70,
      bemerkung IMPORTING is_t1               TYPE lty_m_t1
                RETURNING VALUE(rt_bemerkung) TYPE tlinet,
      anmerkung,
      leer IMPORTING iv_times TYPE i,
      ausgabe IMPORTING is_t1 TYPE lty_m_t1,
      endtext,
      posende,
      ende,
      pfad,
      signature,
      callmail IMPORTING is_t1 TYPE lty_m_t1.



ENDCLASS.
