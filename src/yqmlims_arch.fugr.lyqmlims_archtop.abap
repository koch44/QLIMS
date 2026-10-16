FUNCTION-POOL yqmlims_arch.                 "MESSAGE-ID ..

TYPES: BEGIN OF gty_freigeber,
         vname      TYPE qave-vname,
         vname_list TYPE diadr-name_list,
         vdatum     TYPE qave-vdatum,
         vzeit      TYPE qave-vezeiterf,
       END OF gty_freigeber.

TYPES: gty_objektc TYPE STANDARD TABLE OF solisti1 WITH EMPTY KEY.
TYPES: gty_objektx TYPE STANDARD TABLE OF solix    WITH EMPTY KEY.

TYPES: BEGIN OF gty_attachment,
         type    TYPE soodk-objtp,             "Typ: PDF, RAW, ALI ...
         name    TYPE sopcklsti1-obj_name,     "Name
         descr   TYPE sopcklsti1-obj_descr,    "Titel
         objektc TYPE gty_objektc,             "Anhang Char
         objektx TYPE gty_objektx,             "Anhang Hex
       END OF gty_attachment.

DATA: gs_reclist       TYPE somlreci1.
DATA: gt_tbl           TYPE TABLE OF tbl1024.
DATA: gt_doc           TYPE TABLE OF docs.
DATA: gt_reclist       TYPE TABLE OF somlreci1.
DATA: gs_arpbag        TYPE yqm_arpbag_t.
DATA: gs_attachment    TYPE gty_attachment.
DATA: gt_attachment    TYPE TABLE OF gty_attachment.
DATA: gv_name1         TYPE name1_adrs,
      gv_documenttitle TYPE sood-objdes,
      gv_documentname  TYPE sood-objnam.
