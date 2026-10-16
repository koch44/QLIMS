REPORT yqmlims_update_qals_cost.

TABLES qals.

SELECT-OPTIONS so_plos FOR qals-prueflos.

PARAMETERS p_set   RADIOBUTTON GROUP cost DEFAULT 'X'.
PARAMETERS p_reset RADIOBUTTON GROUP cost.

CONSTANTS gc_max_lots TYPE i VALUE 20.

DATA lv_upd   TYPE i.
DATA lv_fail  TYPE i.
DATA lv_lines TYPE i.
DATA lv_value TYPE qals-yqm_kz_cost.

IF so_plos[] IS INITIAL.
  MESSAGE i027(yqmlims).
  RETURN.
ENDIF.

lv_value = COND #(
  WHEN p_set = abap_true THEN abap_true
  ELSE space ).

SELECT prueflos,
       yqm_kz_cost
  FROM qals
  WHERE prueflos  IN @so_plos
    AND yqm_kz_cost <> @lv_value
  INTO TABLE @DATA(gt_qals).
IF sy-subrc <> 0.
  CLEAR gt_qals.
ENDIF.

lv_lines = lines( gt_qals ).

WRITE: / 'gelesene Prüflose:', lv_lines.

IF lv_lines > gc_max_lots.
  MESSAGE i027(yqmlims).
  RETURN.
ENDIF.

LOOP AT gt_qals ASSIGNING FIELD-SYMBOL(<gs_qals>).

  UPDATE qals
    SET  yqm_kz_cost = @lv_value
    WHERE prueflos   = @<gs_qals>-prueflos.

  IF sy-subrc = 0.
    WRITE: / 'Prüflos erfolgreich aktualisiert:', <gs_qals>-prueflos.
    lv_upd += 1.
  ELSE.
    WRITE: / 'Fehler beim Ändern des Prüfloses:', <gs_qals>-prueflos.
    lv_fail += 1.
  ENDIF.

ENDLOOP.

WRITE: / 'geänderte Prüflose:', lv_upd.
WRITE: / 'Fehler............:', lv_fail.

IF lv_fail = 0.
  COMMIT WORK.
ELSE.
  ROLLBACK WORK.
ENDIF.
