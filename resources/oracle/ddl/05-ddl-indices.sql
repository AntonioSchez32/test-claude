---------------------------------------------------------
-- CREACIÓN DE ÍNDICES EN EL ESQUEMA 'padrononline'
---------------------------------------------------------

-- Para búsquedas por claves foráneas
-- CREATE INDEX IDX_HOGARES_CIV ON HOGARES (CIV);
-- CREATE INDEX IDX_PERSONAS_HOGAR ON PERSONAS (HOGAR);

-- Para búsquedas frecuentes en PERSONAS
-- CREATE INDEX IDX_PERSONAS_NDOCU ON PERSONAS (NDOCU);
-- CREATE INDEX IDX_PERSONAS_APELLIDOS ON PERSONAS (APE1, APE2);

-- Para búsquedas geográficas en VIVIENDAS
-- CREATE INDEX IDX_VIVIENDAS_COORD ON VIVIENDAS (COOR_X, COOR_Y);

-- Para búsquedas territoriales
-- CREATE INDEX IDX_VIVIENDAS_LOCALIZACION ON VIVIENDAS (CPRO_INE, CMUN_INE);
-- CREATE INDEX IDX_HOGARES_LOCALIZACION ON HOGARES (CPRO, CMUN, DIST, SECC);