TYPES: t_t006a     TYPE TABLE OF t006a.
TYPES: t_qmtt      TYPE TABLE OF qmtt.
TYPES: t_cert_attr TYPE TABLE OF yqm_cert_attr_t.

TYPES: BEGIN OF s_zusatz,
         abtei LIKE cepc-abtei,     "Profitcenter Abteilung
         stras LIKE cepc-stras,     "Profitcenter Strasse
         ltext LIKE cepct-ltext,    "Profitcenter Langtext
       END OF s_zusatz.

TYPES: BEGIN OF s_freigeber,
         vname      LIKE qave-vname,
         vname_list LIKE diadr-name_list,
         vdatum     LIKE qave-vdatum,
         vzeit      LIKE qave-vezeiterf,
       END OF s_freigeber.

TYPES: BEGIN OF s_qamv_qmtt,
         qamv_verwmerkm TYPE qmerknr,
         qamv_kurztext  TYPE qmkkurztxt,
         qamv_pmethode  TYPE qpmethode.
         INCLUDE STRUCTURE qmtt.
TYPES: END OF s_qamv_qmtt.

TYPES: BEGIN OF s_gw,
         eingehalten         TYPE char1,
         nicht_eingehalten   TYPE char1,
         nicht_kontaminiert  TYPE char1,
         gering_kontaminiert TYPE char1,
         mittel_kontaminiert TYPE char1,
         hoch_kontaminiert   TYPE char1,
         extrem_kontaminiert TYPE char1,
       END OF s_gw.


TYPES: t_qamv_qmtt  TYPE TABLE OF s_qamv_qmtt.
TYPES: t_matn_mk_t  TYPE TABLE OF yqm_matn_mk_t.





