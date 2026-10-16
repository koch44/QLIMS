*&---------------------------------------------------------------------*
*& Include          ZXTOBU01
*&---------------------------------------------------------------------*

CLEAR sy-ucomm.

gv_activity_type = i_activity_type.
iflo-fltyp       = i_data_iflo-fltyp.
equi-eqtyp       = i_data_equi-eqtyp.

CASE i_object_type.
*--------------------------------------Objekttypen der Techn.Objekte....
*--------------------------------------Techn.Pl.  (I_OBJECT_TYPE = '01')
*--------------------------------------Equipment  (I_OBJECT_TYPE = '02')
*--------------------------------------Serialnum. (I_OBJECT_TYPE = '03')
  WHEN '01'. "Technischer Platz
*--------------------------------------Verarbeitung f. Technische Plätze
    CASE i_data_iflo-fltyp.
      WHEN 'C'.
*--------------------------------------Typ Probeentnahmestelle CH.......
        CASE i_active_fcode.
          WHEN 'SON'.
*---------------------------------Subscreen 1001 Reiter Sonstiges..
            e_subscreen_number = '1001'.
          WHEN 'ZUS3'.
*---------------------------------Subscreen 1003 Reiter Zus.Bezeichnung
            e_subscreen_number = '1003'.
          WHEN OTHERS.
            e_subscreen_number = '1000'.
        ENDCASE.

        iflo-yqm_wasserwirtnr   = i_data_iflo-yqm_wasserwirtnr.
        iflo-yqm_bestellnr      = i_data_iflo-yqm_bestellnr.
        iflo-yqm_wasserwirt     = i_data_iflo-yqm_wasserwirt.
        iflo-yqm_medium         = i_data_iflo-yqm_medium.
        iflo-yqm_extension      = i_data_iflo-yqm_extension.
        iflo-yqm_messid         = i_data_iflo-yqm_messid.
        iflo-yqm_betreiber      = i_data_iflo-yqm_betreiber.
        iflo-yqm_bezeichnung    = i_data_iflo-yqm_bezeichnung.
        iflo-yqm_amtsart        = i_data_iflo-yqm_amtsart.
        iflo-yqm_prggstd        = i_data_iflo-yqm_prggstd.
        iflo-yqm_info1          = i_data_iflo-yqm_info1.
        iflo-yqm_info2          = i_data_iflo-yqm_info2.
        iflo-yqm_info3          = i_data_iflo-yqm_info3.
        iflo-yqm_spezid         = i_data_iflo-yqm_spezid.
        iflo-yqm_usi_name       = i_data_iflo-yqm_usi_name.
        iflo-yqm_usi_tel_number = i_data_iflo-yqm_usi_tel_number.
        iflo-yqm_usi_email      = i_data_iflo-yqm_usi_email.
        iflo-yqm_objektart      = i_data_iflo-yqm_objektart.
        iflo-yqm_ap_name        = i_data_iflo-yqm_ap_name.
        iflo-yqm_ap_tel_number  = i_data_iflo-yqm_ap_tel_number.
        iflo-yqm_ap_email       = i_data_iflo-yqm_ap_email.
        iflo-yqm_vaboen         = i_data_iflo-yqm_vaboen.

      WHEN 'M' OR 'S'.
        CASE i_active_fcode.
*--------------------------------------Subscreen 1004 Reiter Organisat..
          WHEN 'IH'.
*--------------------------------------nur bei im SWERK 1100............
            IF i_data_iflo-swerk = '1100'.
              e_subscreen_number = '1004'.
              iflo-swerk = i_data_iflo-swerk.
              iflo-yybukrs = i_data_iflo-yybukrs.
              iflo-yyanln1 = i_data_iflo-yyanln1.
              IF NOT iflo-yybukrs IS INITIAL AND
                NOT iflo-yyanln1 IS INITIAL.
                SELECT SINGLE txt50 FROM anla
                   INTO   @DATA(lv_txt50)
                   WHERE  bukrs  = @iflo-yybukrs
                     AND  anln1  = @iflo-yyanln1
                     AND  anln2  = '0000'.
                IF sy-subrc = 0.
                  gv_1004_txt50 = lv_txt50.
                ENDIF.
              ENDIF.
            ENDIF.
        ENDCASE.
      WHEN OTHERS.

    ENDCASE.

  WHEN '02' OR '03'. "Equipment und Serialnummer

    CASE i_data_equi-eqtyp.                                 "KE01102017

      WHEN 'G' OR 'I'.                                      "KE01102017
**********--------------------------------------PBO, alle Felder versorgen. Diese
**********--------------------------------------werden im PAI wieder übertragen..
*        equi-yybaudt      = i_data_equi-yybaudt.
*        equi-yybgljahr    = i_data_equi-yybgljahr.
*        equi-yybglart     = i_data_equi-yybglart.
*        equi-yyelszu      = i_data_equi-yyelszu.
*        equi-yyelszu_vers = i_data_equi-yyelszu_vers.
*        equi-yyelszu_lhv  = i_data_equi-yyelszu_lhv.
*        equi-yyelsab      = i_data_equi-yyelsab.
*        equi-yyelsab_vers = i_data_equi-yyelsab_vers.
*        equi-yyelsab_lhv  = i_data_equi-yyelsab_lhv.
*        equi-yyvkart      = i_data_equi-yyvkart.
*        equi-yyauftrbu    = i_data_equi-yyauftrbu.
*        equi-yymessdrck   = i_data_equi-yymessdrck.
*        equi-yyparametr   = i_data_equi-yyparametr.
*        equi-yykomgrp     = i_data_equi-yykomgrp.

        equi-zz1_yybaudt_ieq      = i_data_equi-zz1_yybaudt_ieq.
        equi-zz1_yybgljahr_ieq    = i_data_equi-zz1_yybgljahr_ieq.
        equi-zz1_yybglart_ieq     = i_data_equi-zz1_yybglart_ieq.
        equi-zz1_yyelszu_ieq      = i_data_equi-zz1_yyelszu_ieq.
        equi-zz1_yyelszu_vers_ieq = i_data_equi-zz1_yyelszu_vers_ieq.
        equi-zz1_yyelszu_lhv_ieq  = i_data_equi-zz1_yyelszu_lhv_ieq.
        equi-zz1_yyelsab_ieq      = i_data_equi-zz1_yyelsab_ieq.
        equi-zz1_yyelsab_vers_ieq = i_data_equi-zz1_yyelsab_vers_ieq.
        equi-zz1_yyelsab_lhv_ieq  = i_data_equi-zz1_yyelsab_lhv_ieq.
        equi-zz1_yyvkart_ieq      = i_data_equi-zz1_yyvkart_ieq.
        equi-zz1_yyauftrbu_ieq    = i_data_equi-zz1_yyauftrbu_ieq.
        equi-zz1_yymessdrck_ieq   = i_data_equi-zz1_yymessdrck_ieq.
        equi-zz1_yyparametr_ieq   = i_data_equi-zz1_yyparametr_ieq.
        equi-zz1_yykomgrp_ieq     = i_data_equi-zz1_yykomgrp_ieq.



        IF i_data_equi-zz1_yybglart_ieq IS NOT INITIAL.
          SELECT SINGLE bgltxt FROM te359t INTO @te359t-bgltxt
            WHERE  spras   = @sy-langu
            AND    bglart  = @equi-zz1_yybglart_ieq.
          IF sy-subrc <> 0.
            CLEAR te359t-bgltxt.
          ENDIF.
        ENDIF.

        IF i_data_equi-zz1_yyparametr_ieq IS NOT INITIAL.
          SELECT SINGLE bezeichn FROM te927t INTO @te927t-bezeichn
            WHERE  spras    = @sy-langu
            AND    parametr = @equi-zz1_yyparametr_ieq.
          IF sy-subrc <> 0.
            CLEAR te927t-bezeichn.
          ENDIF.
        ENDIF.

        DATA(ls_mblnr) = VALUE mblnr( ).
        PERFORM m_bel_gettxtanfnr USING i_data_equi-sernr i_data_equi-matnr
                                  CHANGING ls_mblnr.

        SELECT SINGLE xblnr FROM mkpf INTO mkpf-xblnr
          WHERE mblnr = ls_mblnr.
        IF sy-subrc <> 0.
          CLEAR mkpf-xblnr .
        ENDIF.

        SELECT SINGLE sgtxt FROM mseg INTO mseg-sgtxt
          WHERE mblnr = ls_mblnr.
        IF sy-subrc <> 0.
          CLEAR mseg-sgtxt .
        ENDIF.

        CASE i_active_fcode.                                "KE01102017
          WHEN 'SD'.                                        "KE01102017
            e_subscreen_number = '1004'.                    "KE01102017
          WHEN OTHERS.                                      "KE01102017
        ENDCASE. "i_active_fcode                            "KE01102017

      WHEN OTHERS. "i_data_equi-eqtyp                       "KE01102017

    ENDCASE.

  WHEN OTHERS.

ENDCASE.
