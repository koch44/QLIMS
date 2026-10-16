FUNCTION y_qmlims_service_qpvk_dc.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     REFERENCE(charact_no) TYPE cabn-atinn
*"     REFERENCE(charact)    TYPE cabn-atnam
*"     REFERENCE(value)      TYPE cawn-atwrt
*"     REFERENCE(language)   TYPE sy-langu
*"  EXPORTING
*"     REFERENCE(description) TYPE cawnt-atwtb
*"  EXCEPTIONS
*"      not_found
*"----------------------------------------------------------------------

  CLEAR description.

  SELECT SINGLE kurztext
    FROM qprvkt
    WHERE prziehverf = @value
      AND sprache    = @language
    INTO @description.

  IF sy-subrc <> 0.
    RAISE not_found.
  ENDIF.

ENDFUNCTION.
