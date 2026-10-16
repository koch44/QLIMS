*&---------------------------------------------------------------------*
*& Include          ZXQPAU02
*&---------------------------------------------------------------------*
e_dummy10  = i_plmkb-dummy10.
e_dummy20  = i_plmkb-dummy20.
e_dummy40  = i_plmkb-dummy40.

gv_dummy10 = i_plmkb-dummy10.
gv_dummy20 = i_plmkb-dummy20.
gv_dummy40 = i_plmkb-dummy40.

* Check, ob Werk bekannt (nur bei Stammprüfmerkmalen Werksangabe auf
* Merkmalsebene vorhanden)
IF i_plmkb-qpmk_werks IS INITIAL.      "keine Werks-Info
* Werk aus Vorgang ermitteln
  SELECT SINGLE werks FROM plpo
    INTO @DATA(lv_plpo_werks)
    WHERE plnty EQ @i_plmkb-plnty
      AND plnnr EQ @i_plmkb-plnnr
      AND plnkn EQ @i_plmkb-plnkn .
  IF sy-subrc = 0.
    i_plmkb-qpmk_werks = lv_plpo_werks.   "Werk des Vorgangs
  ELSE.
    CLEAR i_plmkb-qpmk_werks.
  ENDIF.

ENDIF.

gv_werk = i_plmkb-qpmk_werks.

CALL SCREEN 0100 STARTING AT 10 10
               ENDING   AT 82 21.

CASE gv_ok_code.
  WHEN 'ABBR'.
  WHEN 'ENT1'.
    e_dummy10 = gv_dummy10.
    e_dummy20 = gv_dummy20.
    e_dummy40 = gv_dummy40.
ENDCASE.
