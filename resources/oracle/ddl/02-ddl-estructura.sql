-- =========================================================================
-- Utilizamos el esquema recien creado PADRONONLINE
-- =========================================================================
ALTER SESSION SET CURRENT_SCHEMA = PADRONONLINE;

---------------------------------------------------------
-- ELIMINAR ÍNDICES SI EXISTEN
---------------------------------------------------------
BEGIN
    FOR r IN (
        SELECT index_name FROM user_indexes
    ) LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP INDEX ' || r.index_name;
        EXCEPTION WHEN OTHERS THEN
            NULL; -- por si índice pertenece a PK/UK con nombre generado
        END;
    END LOOP;
END;
/

---------------------------------------------------------
-- ELIMINAR TABLAS SI EXISTEN
---------------------------------------------------------
-- DROPS DE TABLAS DEL INE
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE PERSONAS CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN
   IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE HOGARES CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN
   IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE VIVIENDAS CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN
   IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE HC CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN
   IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE HD CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN
   IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE HH CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN
   IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE HS CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN
   IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE HV CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN
   IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE PP CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN
   IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE VC CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN
   IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE VV CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN
   IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

-- DROPS DE TABLAS DE AYUNTAMIENTOS
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE A1HS CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN
   IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE A1VA CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN
   IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE A2HD CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN
   IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE A2VA CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN
   IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE A3VC CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN
   IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE A4HV CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN
   IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE A5HA CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN
   IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE A6HM CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN
   IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE A6VM CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN
   IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

---------------------------------------------------------
-- CREACIÓN DE TABLAS EN EL ESQUEMA 'padrononline'
---------------------------------------------------------

-- TABLA: MUNICIPIOS
CREATE TABLE MUNICIPIOS (
    CMUN        NUMBER(3)         NOT NULL,
    NOM_MUN     VARCHAR2(30 CHAR) NOT NULL,
    NHAB        NUMBER            NOT NULL,
    CONSTRAINT PK_MUNICIPIOS PRIMARY KEY (CMUN),
    CONSTRAINT UQ_MUNICIPIOS_NOM UNIQUE (NOM_MUN)
);

COMMENT ON TABLE MUNICIPIOS IS 'Municipios de la provincia';
COMMENT ON COLUMN MUNICIPIOS.CMUN IS 'Código del municipio';
COMMENT ON COLUMN MUNICIPIOS.NOM_MUN IS 'Nombre del municipio';
COMMENT ON COLUMN MUNICIPIOS.NHAB IS 'Habitantes del municipio';

-- TABLA: VIVIENDAS
CREATE TABLE VIVIENDAS (
    CIV          VARCHAR2(24 CHAR) PRIMARY KEY,
    CPRO_INE     NUMBER(2),
    CMUN_INE     NUMBER(3),
    CPRO_MEH     NUMBER(2),
    CMUN_DGC     NUMBER(3),
    NENT         VARCHAR2(50 CHAR),
    CVIA_DGC     NUMBER(5),
    TVIA_DGC     VARCHAR2(2 CHAR),
    NVIA_DGC     VARCHAR2(70 CHAR),
    NUMER        VARCHAR2(5 CHAR),
    LETR         VARCHAR2(1 CHAR),
    NUMERS       VARCHAR2(5 CHAR),
    LETRS        VARCHAR2(1 CHAR),
    KMT          VARCHAR2(5 CHAR),
    BLO          VARCHAR2(3 CHAR),
    ESC          VARCHAR2(2 CHAR),
    PLANTA       VARCHAR2(2 CHAR),
    PUERTA       VARCHAR2(3 CHAR),
    COOR_X NUMBER(16,8), -- hasta 8 dígitos decimales, 8 enteros
    COOR_Y NUMBER(18,9),  -- hasta 9 dígitos decimales, 9 enteros
    HUSO         VARCHAR2(10 CHAR),
    CVIA_INE     NUMBER(5)
);

-- Definición de RC rural y urbana (https://www.catastro.hacienda.gob.es/es-ES/referencia_catastral.html)

ALTER TABLE VIVIENDAS ADD CONSTRAINT chk_viviendas_civ_format CHECK (
    CIV IS NULL
    OR REGEXP_LIKE(CIV, '^[A-Z0-9]{7}[A-Z0-9]{7}[0-9]{4}[A-Z0-9]{2}[0-9]{4}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{2}[0-9]{3}[A-Z][0-9]{3}[0-9]{5}[0-9]{4}[A-Z0-9]{2}[0-9]{4}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}[A-Z][0-9]{3}[0-9]{5}[0-9]{10}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}NRC[0-9]{16}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}NVI[0-9]{16}$')
    OR REGEXP_LIKE(CIV, '^0{20}BAJA$')
);

COMMENT ON TABLE VIVIENDAS IS 'Tabla de viviendas con datos de identificación, localización y coordenadas';
COMMENT ON COLUMN VIVIENDAS.CIV IS 'Código de Identificación de Vivienda';
COMMENT ON COLUMN VIVIENDAS.CPRO_INE IS 'Código de Provincia (INE)';
COMMENT ON COLUMN VIVIENDAS.CMUN_INE IS 'Código de Municipio (INE). Excluido el último dígito de control';
COMMENT ON COLUMN VIVIENDAS.CPRO_MEH IS 'Código de Delegación del MEH';
COMMENT ON COLUMN VIVIENDAS.CMUN_DGC IS 'Código del Municipio (Según DGC)';
COMMENT ON COLUMN VIVIENDAS.NENT IS 'Nombre de la entidad menor, en caso de existir';
COMMENT ON COLUMN VIVIENDAS.CVIA_DGC IS 'Código de vía pública (DGC)';
COMMENT ON COLUMN VIVIENDAS.TVIA_DGC IS 'Tipo de vía o sigla pública';
COMMENT ON COLUMN VIVIENDAS.NVIA_DGC IS 'Nombre de la vía pública';
COMMENT ON COLUMN VIVIENDAS.NUMER IS 'Primer número de policía';
COMMENT ON COLUMN VIVIENDAS.LETR IS 'Primera letra.';
COMMENT ON COLUMN VIVIENDAS.NUMERS IS 'Segundo número de policía';
COMMENT ON COLUMN VIVIENDAS.LETRS IS 'Segunda letra.';
COMMENT ON COLUMN VIVIENDAS.KMT IS 'Kilómetro';
COMMENT ON COLUMN VIVIENDAS.BLO IS 'Bloque FIN14';
COMMENT ON COLUMN VIVIENDAS.ESC IS 'Escalera FIN14';
COMMENT ON COLUMN VIVIENDAS.PLANTA IS 'Planta FIN14';
COMMENT ON COLUMN VIVIENDAS.PUERTA IS 'Puerta FIN14';
COMMENT ON COLUMN VIVIENDAS.COOR_X IS 'Coordenada X FIN11 MÁS DEPURACIONES';
COMMENT ON COLUMN VIVIENDAS.COOR_Y IS 'Coordenada Y FIN11 MÁS DEPURACIONES';
COMMENT ON COLUMN VIVIENDAS.HUSO IS ' ';
COMMENT ON COLUMN VIVIENDAS.CVIA_INE IS 'Código de vía (INE)';

-- TABLA: HOGARES
CREATE TABLE HOGARES (
    CIV            VARCHAR2(24 CHAR),
    COLECTIVO      VARCHAR2(1 CHAR),
    HOGAR          VARCHAR2(9 CHAR) PRIMARY KEY,
    CPRO           NUMBER(2),
    CMUN           NUMBER(3),
    DIST           NUMBER(2),
    SECC           NUMBER(3),
    CUNN           NUMBER(6),
    NENTCO         VARCHAR2(50 CHAR),
    NENTSI         VARCHAR2(50 CHAR),
    NNUCLE         VARCHAR2(50 CHAR),
    CVIA           NUMBER(5),
    TVIA           VARCHAR2(5 CHAR),
    NVIA           VARCHAR2(50 CHAR),
    NUMERN         VARCHAR2(5 CHAR),
    NUMERSN        VARCHAR2(5 CHAR),
    KMTN           NUMBER(3),
    HMTN           NUMBER(1),
    BLOQN          VARCHAR2(2 CHAR),
    PORTN          VARCHAR2(2 CHAR),
    ESCAN          VARCHAR2(2 CHAR),
    PLANN          VARCHAR2(3 CHAR),
    PUERN          VARCHAR2(4 CHAR),
    CVIA_DGC       NUMBER(5),
    APP_CE         NUMBER(10),
    HUECO_CE       NUMBER(10),
    CODIGO_EATIM   NUMBER(8),
    NOMBRE_EATIM   VARCHAR2(50 CHAR),
    CONSTRAINT FK_HOGAR_VIV FOREIGN KEY (CIV)
        REFERENCES VIVIENDAS (CIV)
);

ALTER TABLE HOGARES ADD CONSTRAINT chk_hogares_civ_format CHECK (
    CIV IS NULL
    OR REGEXP_LIKE(CIV, '^[A-Z0-9]{7}[A-Z0-9]{7}[0-9]{4}[A-Z0-9]{2}[0-9]{4}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{2}[0-9]{3}[A-Z][0-9]{3}[0-9]{5}[0-9]{4}[A-Z0-9]{2}[0-9]{4}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}[A-Z][0-9]{3}[0-9]{5}[0-9]{10}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}NRC[0-9]{16}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}NVI[0-9]{16}$')
    OR REGEXP_LIKE(CIV, '^0{20}BAJA$')
);

COMMENT ON TABLE HOGARES IS 'Tabla de hogares asociados a las viviendas';
COMMENT ON COLUMN HOGARES.CIV IS 'Código de Identificación de la Vivienda';
COMMENT ON COLUMN HOGARES.COLECTIVO IS
	'0: No es establecimiento colectivo
1: Sí es establecimiento colectivo convencional
8: Si es vivienda alquilada por habitaciones';
COMMENT ON COLUMN HOGARES.HOGAR IS 'Identificador del hogar (campo vivienda del fichero censal de personas)';
COMMENT ON COLUMN HOGARES.CPRO IS 'Código de provincia';
COMMENT ON COLUMN HOGARES.CMUN IS 'Código de municipio';
COMMENT ON COLUMN HOGARES.DIST IS 'Código de distrito';
COMMENT ON COLUMN HOGARES.SECC IS 'Código de sección';
COMMENT ON COLUMN HOGARES.CUNN IS 'Código de Unidad Poblacional';
COMMENT ON COLUMN HOGARES.NENTCO IS 'Nombre de la Entidad Colectiva';
COMMENT ON COLUMN HOGARES.NENTSI IS 'Nombre de la Entidad Singular';
COMMENT ON COLUMN HOGARES.NNUCLE IS 'Nombre del Núcleo/Diseminado';
COMMENT ON COLUMN HOGARES.CVIA IS 'Código de vía INE';
COMMENT ON COLUMN HOGARES.TVIA IS 'Tipo de vía';
COMMENT ON COLUMN HOGARES.NVIA IS 'Nombre de la Vía';
COMMENT ON COLUMN HOGARES.NUMERN IS 'Número';
COMMENT ON COLUMN HOGARES.NUMERSN IS 'Número Superior';
COMMENT ON COLUMN HOGARES.KMTN IS 'Kilómetro';
COMMENT ON COLUMN HOGARES.HMTN IS 'Hectómetro';
COMMENT ON COLUMN HOGARES.BLOQN IS 'Bloque';
COMMENT ON COLUMN HOGARES.PORTN IS 'Portal';
COMMENT ON COLUMN HOGARES.ESCAN IS 'Escalera';
COMMENT ON COLUMN HOGARES.PLANN IS 'Planta';
COMMENT ON COLUMN HOGARES.PUERN IS 'Puerta';
COMMENT ON COLUMN HOGARES.CVIA_DGC IS 'Código de vía de Catastro';
COMMENT ON COLUMN HOGARES.APP_CE IS 'Identificador de Aproximación Postal de Censo Electoral';
COMMENT ON COLUMN HOGARES.HUECO_CE IS 'Identificador de Hueco de Censo Electoral';
COMMENT ON COLUMN HOGARES.CODIGO_EATIM IS 'Código de Entidad de Ámbito Territorial Menor que el Municipio';
COMMENT ON COLUMN HOGARES.NOMBRE_EATIM IS 'Nombre de la Entidad de Ámbito Territorial Menor que el Municipio';


-- TABLA: PERSONAS
CREATE TABLE PERSONAS (
    NIDEN          NUMBER(10) PRIMARY KEY,
    HOGAR          VARCHAR2(9 CHAR),
    CPRO           NUMBER(2),
    CMUN           NUMBER(3),
    NOMBRE         VARCHAR2(20 CHAR),
    APE1           VARCHAR2(25 CHAR),
    APE2           VARCHAR2(25 CHAR),
    FNAC           NUMBER(8),
    SEXO           VARCHAR2(1 CHAR),
    TIDEN          VARCHAR2(1 CHAR),
    LEXTR          VARCHAR2(1 CHAR),
    IDEN           NUMBER(8),
    LIDEN          VARCHAR2(1 CHAR),
    NDOCU          VARCHAR2(20 CHAR),
    CONSTRAINT FK_PERS_HOGAR FOREIGN KEY (HOGAR)
        REFERENCES HOGARES (HOGAR)
);

COMMENT ON TABLE PERSONAS IS 'Tabla de personas asociadas a los hogares';
COMMENT ON COLUMN PERSONAS.NIDEN IS 'Clave personas Padrón';
COMMENT ON COLUMN PERSONAS.HOGAR IS 'Identificador del hogar (campo vivienda del fichero censal de personas)';
COMMENT ON COLUMN PERSONAS.CPRO IS 'Código de provincia';
COMMENT ON COLUMN PERSONAS.CMUN IS 'Código de municipio';
COMMENT ON COLUMN PERSONAS.NOMBRE IS 'Nombre';
COMMENT ON COLUMN PERSONAS.APE1 IS 'Primer apellido';
COMMENT ON COLUMN PERSONAS.APE2 IS 'Segundo apellido';
COMMENT ON COLUMN PERSONAS.FNAC IS 'Fecha de nacimiento';
COMMENT ON COLUMN PERSONAS.SEXO IS 'Sexo';
COMMENT ON COLUMN PERSONAS.TIDEN IS 'Tipo de identificador';
COMMENT ON COLUMN PERSONAS.LEXTR IS 'Letra de Extranjero';
COMMENT ON COLUMN PERSONAS.IDEN IS 'Identificador';
COMMENT ON COLUMN PERSONAS.LIDEN IS 'Letra del DNI/NIEX';
COMMENT ON COLUMN PERSONAS.NDOCU IS 'Número de documento';


-- TABLA: HC
CREATE TABLE HC (
    CIV            VARCHAR2(24 CHAR),
    COLECTIVO      VARCHAR2(1 CHAR),
    HOGAR          VARCHAR2(9 CHAR) PRIMARY KEY,
    CPRO           NUMBER(2),
    CMUN           NUMBER(3),
    DIST           NUMBER(2),
    SECC           NUMBER(3),
    CUNN           NUMBER(6),
    NENTCO         VARCHAR2(50 CHAR),
    NENTSI         VARCHAR2(50 CHAR),
    NNUCLE         VARCHAR2(50 CHAR),
    CVIA           NUMBER(5),
    TVIA           VARCHAR2(5 CHAR),
    NVIA           VARCHAR2(50 CHAR),
    NUMERN         VARCHAR2(5 CHAR),
    NUMERSN        VARCHAR2(5 CHAR),
    KMTN           NUMBER(3),
    HMTN           NUMBER(1),
    BLOQN          VARCHAR2(2 CHAR),
    PORTN          VARCHAR2(2 CHAR),
    ESCAN          VARCHAR2(2 CHAR),
    PLANN          VARCHAR2(3 CHAR),
    PUERN          VARCHAR2(4 CHAR),
    CVIA_DGC       NUMBER(5),
    APP_CE         NUMBER(10),
    HUECO_CE       NUMBER(10),
    CODIGO_EATIM   NUMBER(8),
    NOMBRE_EATIM   VARCHAR2(50 CHAR)
);

ALTER TABLE HC ADD CONSTRAINT chk_hc_civ_format CHECK (
    CIV IS NULL
    OR REGEXP_LIKE(CIV, '^[A-Z0-9]{7}[A-Z0-9]{7}[0-9]{4}[A-Z0-9]{2}[0-9]{4}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{2}[0-9]{3}[A-Z][0-9]{3}[0-9]{5}[0-9]{4}[A-Z0-9]{2}[0-9]{4}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}[A-Z][0-9]{3}[0-9]{5}[0-9]{10}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}NRC[0-9]{16}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}NVI[0-9]{16}$')
    OR REGEXP_LIKE(CIV, '^0{20}BAJA$')
);

COMMENT ON TABLE HC IS 'Registros afectados del fichero de hogares que sean establecimientos colectivos según la información recogida por el INE.';
COMMENT ON COLUMN HC.CIV IS 'Código de Identificación de la Vivienda';
COMMENT ON COLUMN HC.COLECTIVO IS
	'0: No es establecimiento colectivo
1: Sí es establecimiento colectivo convencional
8: Si es vivienda alquilada por habitaciones';
COMMENT ON COLUMN HC.HOGAR IS 'Identificador del hogar (campo vivienda del fichero censal de personas)';
COMMENT ON COLUMN HC.CPRO IS 'Código de provincia';
COMMENT ON COLUMN HC.CMUN IS 'Código de municipio';
COMMENT ON COLUMN HC.DIST IS 'Código de distrito';
COMMENT ON COLUMN HC.SECC IS 'Código de sección';
COMMENT ON COLUMN HC.CUNN IS 'Código de Unidad Poblacional';
COMMENT ON COLUMN HC.NENTCO IS 'Nombre de la Entidad Colectiva';
COMMENT ON COLUMN HC.NENTSI IS 'Nombre de la Entidad Singular';
COMMENT ON COLUMN HC.NNUCLE IS 'Nombre del Núcleo/Diseminado';
COMMENT ON COLUMN HC.CVIA IS 'Código de vía INE';
COMMENT ON COLUMN HC.TVIA IS 'Tipo de vía';
COMMENT ON COLUMN HC.NVIA IS 'Nombre de la Vía';
COMMENT ON COLUMN HC.NUMERN IS 'Número';
COMMENT ON COLUMN HC.NUMERSN IS 'Número Superior';
COMMENT ON COLUMN HC.KMTN IS 'Kilómetro';
COMMENT ON COLUMN HC.HMTN IS 'Hectómetro';
COMMENT ON COLUMN HC.BLOQN IS 'Bloque';
COMMENT ON COLUMN HC.PORTN IS 'Portal';
COMMENT ON COLUMN HC.ESCAN IS 'Escalera';
COMMENT ON COLUMN HC.PLANN IS 'Planta';
COMMENT ON COLUMN HC.PUERN IS 'Puerta';
COMMENT ON COLUMN HC.CVIA_DGC IS 'Código de vía de Catastro';
COMMENT ON COLUMN HC.APP_CE IS 'Identificador de Aproximación Postal de Censo Electoral';
COMMENT ON COLUMN HC.HUECO_CE IS 'Identificador de Hueco de Censo Electoral';
COMMENT ON COLUMN HC.CODIGO_EATIM IS 'Código de Entidad de Ámbito Territorial Menor que el Municipio';
COMMENT ON COLUMN HC.NOMBRE_EATIM IS 'Nombre de la Entidad de Ámbito Territorial Menor que el Municipio';


-- TABLA: HD
CREATE TABLE HD (
    CIV            VARCHAR2(24 CHAR),
    COLECTIVO      VARCHAR2(1 CHAR),
    HOGAR          VARCHAR2(9 CHAR) PRIMARY KEY,
    CPRO           NUMBER(2),
    CMUN           NUMBER(3),
    DIST           NUMBER(2),
    SECC           NUMBER(3),
    CUNN           NUMBER(6),
    NENTCO         VARCHAR2(50 CHAR),
    NENTSI         VARCHAR2(50 CHAR),
    NNUCLE         VARCHAR2(50 CHAR),
    CVIA           NUMBER(5),
    TVIA           VARCHAR2(5 CHAR),
    NVIA           VARCHAR2(50 CHAR),
    NUMERN         VARCHAR2(5 CHAR),
    NUMERSN        VARCHAR2(5 CHAR),
    KMTN           NUMBER(3),
    HMTN           NUMBER(1),
    BLOQN          VARCHAR2(2 CHAR),
    PORTN          VARCHAR2(2 CHAR),
    ESCAN          VARCHAR2(2 CHAR),
    PLANN          VARCHAR2(3 CHAR),
    PUERN          VARCHAR2(4 CHAR),
    CVIA_DGC       NUMBER(5),
    APP_CE         NUMBER(10),
    HUECO_CE       NUMBER(10),
    CODIGO_EATIM   NUMBER(8),
    NOMBRE_EATIM   VARCHAR2(50 CHAR),
    NUMERS_COHERENTE VARCHAR2(1 CHAR),
    KMT_COHERENTE VARCHAR2(1 CHAR),
    PLANTA_COHERENTE VARCHAR2(1 CHAR),
	PUERTA_COHERENTE VARCHAR2(1 CHAR)
);

ALTER TABLE HD ADD CONSTRAINT chk_hd_civ_format CHECK (
    CIV IS NULL
    OR REGEXP_LIKE(CIV, '^[A-Z0-9]{7}[A-Z0-9]{7}[0-9]{4}[A-Z0-9]{2}[0-9]{4}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{2}[0-9]{3}[A-Z][0-9]{3}[0-9]{5}[0-9]{4}[A-Z0-9]{2}[0-9]{4}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}[A-Z][0-9]{3}[0-9]{5}[0-9]{10}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}NRC[0-9]{16}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}NVI[0-9]{16}$')
    OR REGEXP_LIKE(CIV, '^0{20}BAJA$')
);

COMMENT ON TABLE HD IS 'Registros afectados del fichero de hogares con dirección padronal';
COMMENT ON COLUMN HD.CIV IS 'Código de Identificación de la Vivienda';
COMMENT ON COLUMN HD.COLECTIVO IS
	'0: No es establecimiento colectivo
1: Sí es establecimiento colectivo convencional
8: Si es vivienda alquilada por habitaciones';
COMMENT ON COLUMN HD.HOGAR IS 'Identificador del hogar (campo vivienda del fichero censal de personas)';
COMMENT ON COLUMN HD.CPRO IS 'Código de provincia';
COMMENT ON COLUMN HD.CMUN IS 'Código de municipio';
COMMENT ON COLUMN HD.DIST IS 'Código de distrito';
COMMENT ON COLUMN HD.SECC IS 'Código de sección';
COMMENT ON COLUMN HD.CUNN IS 'Código de Unidad Poblacional';
COMMENT ON COLUMN HD.NENTCO IS 'Nombre de la Entidad Colectiva';
COMMENT ON COLUMN HD.NENTSI IS 'Nombre de la Entidad Singular';
COMMENT ON COLUMN HD.NNUCLE IS 'Nombre del Núcleo/Diseminado';
COMMENT ON COLUMN HD.CVIA IS 'Código de vía INE';
COMMENT ON COLUMN HD.TVIA IS 'Tipo de vía';
COMMENT ON COLUMN HD.NVIA IS 'Nombre de la Vía';
COMMENT ON COLUMN HD.NUMERN IS 'Número';
COMMENT ON COLUMN HD.NUMERSN IS 'Número Superior';
COMMENT ON COLUMN HD.KMTN IS 'Kilómetro';
COMMENT ON COLUMN HD.HMTN IS 'Hectómetro';
COMMENT ON COLUMN HD.BLOQN IS 'Bloque';
COMMENT ON COLUMN HD.PORTN IS 'Portal';
COMMENT ON COLUMN HD.ESCAN IS 'Escalera';
COMMENT ON COLUMN HD.PLANN IS 'Planta';
COMMENT ON COLUMN HD.PUERN IS 'Puerta';
COMMENT ON COLUMN HD.CVIA_DGC IS 'Código de vía de Catastro';
COMMENT ON COLUMN HD.APP_CE IS 'Identificador de Aproximación Postal de Censo Electoral';
COMMENT ON COLUMN HD.HUECO_CE IS 'Identificador de Hueco de Censo Electoral';
COMMENT ON COLUMN HD.CODIGO_EATIM IS 'Código de Entidad de Ámbito Territorial Menor que el Municipio';
COMMENT ON COLUMN HD.NOMBRE_EATIM IS 'Nombre de la Entidad de Ámbito Territorial Menor que el Municipio';
COMMENT ON COLUMN HD.NUMERS_COHERENTE IS 'Número superior coherente';
COMMENT ON COLUMN HD.KMT_COHERENTE IS 'Kilómetro coherente';
COMMENT ON COLUMN HD.PLANTA_COHERENTE IS 'Planta coherente';
COMMENT ON COLUMN HD.PUERTA_COHERENTE IS 'Puerta coherente';

-- TABLA: HH
CREATE TABLE HH (
    CIV            VARCHAR2(24 CHAR),
    COLECTIVO      VARCHAR2(1 CHAR),
    HOGAR          VARCHAR2(9 CHAR) PRIMARY KEY,
    CPRO           NUMBER(2),
    CMUN           NUMBER(3),
    DIST           NUMBER(2),
    SECC           NUMBER(3),
    CUNN           NUMBER(6),
    NENTCO         VARCHAR2(50 CHAR),
    NENTSI         VARCHAR2(50 CHAR),
    NNUCLE         VARCHAR2(50 CHAR),
    CVIA           NUMBER(5),
    TVIA           VARCHAR2(5 CHAR),
    NVIA           VARCHAR2(50 CHAR),
    NUMERN         VARCHAR2(5 CHAR),
    NUMERSN        VARCHAR2(5 CHAR),
    KMTN           NUMBER(3),
    HMTN           NUMBER(1),
    BLOQN          VARCHAR2(2 CHAR),
    PORTN          VARCHAR2(2 CHAR),
    ESCAN          VARCHAR2(2 CHAR),
    PLANN          VARCHAR2(3 CHAR),
    PUERN          VARCHAR2(4 CHAR),
    CVIA_DGC       NUMBER(5),
    APP_CE         NUMBER(10),
    HUECO_CE       NUMBER(10),
    CODIGO_EATIM   NUMBER(8),
    NOMBRE_EATIM   VARCHAR2(50 CHAR)
);

ALTER TABLE HH ADD CONSTRAINT chk_hh_civ_format CHECK (
    CIV IS NULL
    OR REGEXP_LIKE(CIV, '^[A-Z0-9]{7}[A-Z0-9]{7}[0-9]{4}[A-Z0-9]{2}[0-9]{4}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{2}[0-9]{3}[A-Z][0-9]{3}[0-9]{5}[0-9]{4}[A-Z0-9]{2}[0-9]{4}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}[A-Z][0-9]{3}[0-9]{5}[0-9]{10}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}NRC[0-9]{16}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}NVI[0-9]{16}$')
    OR REGEXP_LIKE(CIV, '^0{20}BAJA$')
);

COMMENT ON TABLE HH IS 'Totalidad del fichero de hogares.';
COMMENT ON COLUMN HH.CIV IS 'Código de Identificación de la Vivienda';
COMMENT ON COLUMN HH.COLECTIVO IS
	'0: No es establecimiento colectivo
1: Sí es establecimiento colectivo convencional
8: Si es vivienda alquilada por habitaciones';
COMMENT ON COLUMN HH.HOGAR IS 'Identificador del hogar (campo vivienda del fichero censal de personas)';
COMMENT ON COLUMN HH.CPRO IS 'Código de provincia';
COMMENT ON COLUMN HH.CMUN IS 'Código de municipio';
COMMENT ON COLUMN HH.DIST IS 'Código de distrito';
COMMENT ON COLUMN HH.SECC IS 'Código de sección';
COMMENT ON COLUMN HH.CUNN IS 'Código de Unidad Poblacional';
COMMENT ON COLUMN HH.NENTCO IS 'Nombre de la Entidad Colectiva';
COMMENT ON COLUMN HH.NENTSI IS 'Nombre de la Entidad Singular';
COMMENT ON COLUMN HH.NNUCLE IS 'Nombre del Núcleo/Diseminado';
COMMENT ON COLUMN HH.CVIA IS 'Código de vía INE';
COMMENT ON COLUMN HH.TVIA IS 'Tipo de vía';
COMMENT ON COLUMN HH.NVIA IS 'Nombre de la Vía';
COMMENT ON COLUMN HH.NUMERN IS 'Número';
COMMENT ON COLUMN HH.NUMERSN IS 'Número Superior';
COMMENT ON COLUMN HH.KMTN IS 'Kilómetro';
COMMENT ON COLUMN HH.HMTN IS 'Hectómetro';
COMMENT ON COLUMN HH.BLOQN IS 'Bloque';
COMMENT ON COLUMN HH.PORTN IS 'Portal';
COMMENT ON COLUMN HH.ESCAN IS 'Escalera';
COMMENT ON COLUMN HH.PLANN IS 'Planta';
COMMENT ON COLUMN HH.PUERN IS 'Puerta';
COMMENT ON COLUMN HH.CVIA_DGC IS 'Código de vía de Catastro';
COMMENT ON COLUMN HH.APP_CE IS 'Identificador de Aproximación Postal de Censo Electoral';
COMMENT ON COLUMN HH.HUECO_CE IS 'Identificador de Hueco de Censo Electoral';
COMMENT ON COLUMN HH.CODIGO_EATIM IS 'Código de Entidad de Ámbito Territorial Menor que el Municipio';
COMMENT ON COLUMN HH.NOMBRE_EATIM IS 'Nombre de la Entidad de Ámbito Territorial Menor que el Municipio';


-- TABLA: HS
CREATE TABLE HS (
    CIV            VARCHAR2(24 CHAR),
    COLECTIVO      VARCHAR2(1 CHAR),
    HOGAR          VARCHAR2(9 CHAR) PRIMARY KEY,
    CPRO           NUMBER(2),
    CMUN           NUMBER(3),
    DIST           NUMBER(2),
    SECC           NUMBER(3),
    CUNN           NUMBER(6),
    NENTCO         VARCHAR2(50 CHAR),
    NENTSI         VARCHAR2(50 CHAR),
    NNUCLE         VARCHAR2(50 CHAR),
    CVIA           NUMBER(5),
    TVIA           VARCHAR2(5 CHAR),
    NVIA           VARCHAR2(50 CHAR),
    NUMERN         VARCHAR2(5 CHAR),
    NUMERSN        VARCHAR2(5 CHAR),
    KMTN           NUMBER(3),
    HMTN           NUMBER(1),
    BLOQN          VARCHAR2(2 CHAR),
    PORTN          VARCHAR2(2 CHAR),
    ESCAN          VARCHAR2(2 CHAR),
    PLANN          VARCHAR2(3 CHAR),
    PUERN          VARCHAR2(4 CHAR),
    CVIA_DGC       NUMBER(5),
    APP_CE         NUMBER(10),
    HUECO_CE       NUMBER(10),
    CODIGO_EATIM   NUMBER(8),
    NOMBRE_EATIM   VARCHAR2(50 CHAR)
);

ALTER TABLE HS ADD CONSTRAINT chk_hs_civ_format CHECK (
    CIV IS NULL
    OR REGEXP_LIKE(CIV, '^[A-Z0-9]{7}[A-Z0-9]{7}[0-9]{4}[A-Z0-9]{2}[0-9]{4}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{2}[0-9]{3}[A-Z][0-9]{3}[0-9]{5}[0-9]{4}[A-Z0-9]{2}[0-9]{4}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}[A-Z][0-9]{3}[0-9]{5}[0-9]{10}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}NRC[0-9]{16}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}NVI[0-9]{16}$')
    OR REGEXP_LIKE(CIV, '^0{20}BAJA$')
);

COMMENT ON TABLE HS IS 'Registros del fichero de hogares sin CIV.';
COMMENT ON COLUMN HS.CIV IS 'Código de Identificación de la Vivienda';
COMMENT ON COLUMN HS.COLECTIVO IS
	'0: No es establecimiento colectivo
1: Sí es establecimiento colectivo convencional
8: Si es vivienda alquilada por habitaciones';
COMMENT ON COLUMN HS.HOGAR IS 'Identificador del hogar (campo vivienda del fichero censal de personas)';
COMMENT ON COLUMN HS.CPRO IS 'Código de provincia';
COMMENT ON COLUMN HS.CMUN IS 'Código de municipio';
COMMENT ON COLUMN HS.DIST IS 'Código de distrito';
COMMENT ON COLUMN HS.SECC IS 'Código de sección';
COMMENT ON COLUMN HS.CUNN IS 'Código de Unidad Poblacional';
COMMENT ON COLUMN HS.NENTCO IS 'Nombre de la Entidad Colectiva';
COMMENT ON COLUMN HS.NENTSI IS 'Nombre de la Entidad Singular';
COMMENT ON COLUMN HS.NNUCLE IS 'Nombre del Núcleo/Diseminado';
COMMENT ON COLUMN HS.CVIA IS 'Código de vía INE';
COMMENT ON COLUMN HS.TVIA IS 'Tipo de vía';
COMMENT ON COLUMN HS.NVIA IS 'Nombre de la Vía';
COMMENT ON COLUMN HS.NUMERN IS 'Número';
COMMENT ON COLUMN HS.NUMERSN IS 'Número Superior';
COMMENT ON COLUMN HS.KMTN IS 'Kilómetro';
COMMENT ON COLUMN HS.HMTN IS 'Hectómetro';
COMMENT ON COLUMN HS.BLOQN IS 'Bloque';
COMMENT ON COLUMN HS.PORTN IS 'Portal';
COMMENT ON COLUMN HS.ESCAN IS 'Escalera';
COMMENT ON COLUMN HS.PLANN IS 'Planta';
COMMENT ON COLUMN HS.PUERN IS 'Puerta';
COMMENT ON COLUMN HS.CVIA_DGC IS 'Código de vía de Catastro';
COMMENT ON COLUMN HS.APP_CE IS 'Identificador de Aproximación Postal de Censo Electoral';
COMMENT ON COLUMN HS.HUECO_CE IS 'Identificador de Hueco de Censo Electoral';
COMMENT ON COLUMN HS.CODIGO_EATIM IS 'Código de Entidad de Ámbito Territorial Menor que el Municipio';
COMMENT ON COLUMN HS.NOMBRE_EATIM IS 'Nombre de la Entidad de Ámbito Territorial Menor que el Municipio';


-- TABLA: HV
CREATE TABLE HV (
    CIV            VARCHAR2(24 CHAR),
    COLECTIVO      VARCHAR2(1 CHAR),
    HOGAR          VARCHAR2(9 CHAR) PRIMARY KEY,
    CPRO           NUMBER(2),
    CMUN           NUMBER(3),
    DIST           NUMBER(2),
    SECC           NUMBER(3),
    CUNN           NUMBER(6),
    NENTCO         VARCHAR2(50 CHAR),
    NENTSI         VARCHAR2(50 CHAR),
    NNUCLE         VARCHAR2(50 CHAR),
    CVIA           NUMBER(5),
    TVIA           VARCHAR2(5 CHAR),
    NVIA           VARCHAR2(50 CHAR),
    NUMERN         VARCHAR2(5 CHAR),
    NUMERSN        VARCHAR2(5 CHAR),
    KMTN           NUMBER(3),
    HMTN           NUMBER(1),
    BLOQN          VARCHAR2(2 CHAR),
    PORTN          VARCHAR2(2 CHAR),
    ESCAN          VARCHAR2(2 CHAR),
    PLANN          VARCHAR2(3 CHAR),
    PUERN          VARCHAR2(4 CHAR),
    CVIA_DGC       NUMBER(5),
    APP_CE         NUMBER(10),
    HUECO_CE       NUMBER(10),
    CODIGO_EATIM   NUMBER(8),
    NOMBRE_EATIM   VARCHAR2(50 CHAR)
);

ALTER TABLE HV ADD CONSTRAINT chk_hv_civ_format CHECK (
    CIV IS NULL
    OR REGEXP_LIKE(CIV, '^[A-Z0-9]{7}[A-Z0-9]{7}[0-9]{4}[A-Z0-9]{2}[0-9]{4}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{2}[0-9]{3}[A-Z][0-9]{3}[0-9]{5}[0-9]{4}[A-Z0-9]{2}[0-9]{4}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}[A-Z][0-9]{3}[0-9]{5}[0-9]{10}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}NRC[0-9]{16}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}NVI[0-9]{16}$')
    OR REGEXP_LIKE(CIV, '^0{20}BAJA$')
);

COMMENT ON TABLE HV IS 'Registros afectados del fichero de hogares con código de vía INE y sin código de vía de catastro.';
COMMENT ON COLUMN HV.CIV IS 'Código de Identificación de la Vivienda';
COMMENT ON COLUMN HV.COLECTIVO IS
	'0: No es establecimiento colectivo
1: Sí es establecimiento colectivo convencional
8: Si es vivienda alquilada por habitaciones';
COMMENT ON COLUMN HV.HOGAR IS 'Identificador del hogar (campo vivienda del fichero censal de personas)';
COMMENT ON COLUMN HV.CPRO IS 'Código de provincia';
COMMENT ON COLUMN HV.CMUN IS 'Código de municipio';
COMMENT ON COLUMN HV.DIST IS 'Código de distrito';
COMMENT ON COLUMN HV.SECC IS 'Código de sección';
COMMENT ON COLUMN HV.CUNN IS 'Código de Unidad Poblacional';
COMMENT ON COLUMN HV.NENTCO IS 'Nombre de la Entidad Colectiva';
COMMENT ON COLUMN HV.NENTSI IS 'Nombre de la Entidad Singular';
COMMENT ON COLUMN HV.NNUCLE IS 'Nombre del Núcleo/Diseminado';
COMMENT ON COLUMN HV.CVIA IS 'Código de vía INE';
COMMENT ON COLUMN HV.TVIA IS 'Tipo de vía';
COMMENT ON COLUMN HV.NVIA IS 'Nombre de la Vía';
COMMENT ON COLUMN HV.NUMERN IS 'Número';
COMMENT ON COLUMN HV.NUMERSN IS 'Número Superior';
COMMENT ON COLUMN HV.KMTN IS 'Kilómetro';
COMMENT ON COLUMN HV.HMTN IS 'Hectómetro';
COMMENT ON COLUMN HV.BLOQN IS 'Bloque';
COMMENT ON COLUMN HV.PORTN IS 'Portal';
COMMENT ON COLUMN HV.ESCAN IS 'Escalera';
COMMENT ON COLUMN HV.PLANN IS 'Planta';
COMMENT ON COLUMN HV.PUERN IS 'Puerta';
COMMENT ON COLUMN HV.CVIA_DGC IS 'Código de vía de Catastro';
COMMENT ON COLUMN HV.APP_CE IS 'Identificador de Aproximación Postal de Censo Electoral';
COMMENT ON COLUMN HV.HUECO_CE IS 'Identificador de Hueco de Censo Electoral';
COMMENT ON COLUMN HV.CODIGO_EATIM IS 'Código de Entidad de Ámbito Territorial Menor que el Municipio';
COMMENT ON COLUMN HV.NOMBRE_EATIM IS 'Nombre de la Entidad de Ámbito Territorial Menor que el Municipio';


-- TABLA: PP
CREATE TABLE PP (
    NIDEN          NUMBER(10) PRIMARY KEY,
    HOGAR          VARCHAR2(9 CHAR),
    CPRO           NUMBER(2),
    CMUN           NUMBER(3),
    NOMBRE         VARCHAR2(20 CHAR),
    APE1           VARCHAR2(25 CHAR),
    APE2           VARCHAR2(25 CHAR),
    FNAC           NUMBER(8),
    SEXO           VARCHAR2(1 CHAR),
    TIDEN          VARCHAR2(1 CHAR),
    LEXTR          VARCHAR2(1 CHAR),
    IDEN           NUMBER(8),
    LIDEN          VARCHAR2(1 CHAR),
    NDOCU          VARCHAR2(20 CHAR)
);

COMMENT ON TABLE PP IS 'Fichero de personas asociadas a los hogares';
COMMENT ON COLUMN PP.NIDEN IS 'Clave personas Padrón';
COMMENT ON COLUMN PP.HOGAR IS 'Identificador del hogar (campo vivienda del fichero censal de personas)';
COMMENT ON COLUMN PP.CPRO IS 'Código de provincia';
COMMENT ON COLUMN PP.CMUN IS 'Código de municipio';
COMMENT ON COLUMN PP.NOMBRE IS 'Nombre';
COMMENT ON COLUMN PP.APE1 IS 'Primer apellido';
COMMENT ON COLUMN PP.APE2 IS 'Segundo apellido';
COMMENT ON COLUMN PP.FNAC IS 'Fecha de nacimiento';
COMMENT ON COLUMN PP.SEXO IS 'Sexo';
COMMENT ON COLUMN PP.TIDEN IS 'Tipo de identificador';
COMMENT ON COLUMN PP.LEXTR IS 'Letra de Extranjero';
COMMENT ON COLUMN PP.IDEN IS 'Identificador';
COMMENT ON COLUMN PP.LIDEN IS 'Letra del DNI/NIEX';
COMMENT ON COLUMN PP.NDOCU IS 'Número de documento';


-- TABLA: VC
CREATE TABLE VC (
    CIV          VARCHAR2(24 CHAR) PRIMARY KEY,
    CPRO_INE     NUMBER(2),
    CMUN_INE     NUMBER(3),
    CPRO_MEH     NUMBER(2),
    CMUN_DGC     NUMBER(3),
    NENT         VARCHAR2(50 CHAR),
    CVIA_DGC     NUMBER(5),
    TVIA_DGC     VARCHAR2(2 CHAR),
    NVIA_DGC     VARCHAR2(70 CHAR),
    NUMER        VARCHAR2(5 CHAR),
    LETR         VARCHAR2(1 CHAR),
    NUMERS       VARCHAR2(5 CHAR),
    LETRS        VARCHAR2(1 CHAR),
    KMT          VARCHAR2(5 CHAR),
    BLO          VARCHAR2(3 CHAR),
    ESC          VARCHAR2(2 CHAR),
    PLANTA       VARCHAR2(2 CHAR),
    PUERTA       VARCHAR2(3 CHAR),
    COOR_X NUMBER(16,8), -- hasta 8 dígitos decimales, 8 enteros
    COOR_Y NUMBER(18,9),  -- hasta 9 dígitos decimales, 9 enteros
    HUSO         VARCHAR2(10 CHAR),
    CVIA_INE     NUMBER(5)
);

ALTER TABLE VC ADD CONSTRAINT chk_vc_civ_format CHECK (
    CIV IS NULL
    OR REGEXP_LIKE(CIV, '^[A-Z0-9]{7}[A-Z0-9]{7}[0-9]{4}[A-Z0-9]{2}[0-9]{4}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{2}[0-9]{3}[A-Z][0-9]{3}[0-9]{5}[0-9]{4}[A-Z0-9]{2}[0-9]{4}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}[A-Z][0-9]{3}[0-9]{5}[0-9]{10}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}NRC[0-9]{16}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}NVI[0-9]{16}$')
    OR REGEXP_LIKE(CIV, '^0{20}BAJA$')
);

COMMENT ON TABLE VC IS 'Registros afectados del fichero de viviendas con dirección catastral.';
COMMENT ON COLUMN VC.CIV IS 'Código de Identificación de Vivienda';
COMMENT ON COLUMN VC.CPRO_INE IS 'Código de Provincia (INE)';
COMMENT ON COLUMN VC.CMUN_INE IS 'Código de Municipio (INE). Excluido el último dígito de control';
COMMENT ON COLUMN VC.CPRO_MEH IS 'Código de Delegación del MEH';
COMMENT ON COLUMN VC.CMUN_DGC IS 'Código del Municipio (Según DGC)';
COMMENT ON COLUMN VC.NENT IS 'Nombre de la entidad menor, en caso de existir';
COMMENT ON COLUMN VC.CVIA_DGC IS 'Código de vía pública (DGC)';
COMMENT ON COLUMN VC.TVIA_DGC IS 'Tipo de vía o sigla pública';
COMMENT ON COLUMN VC.NVIA_DGC IS 'Nombre de la vía pública';
COMMENT ON COLUMN VC.NUMER IS 'Primer número de policía';
COMMENT ON COLUMN VC.LETR IS 'Primera letra.';
COMMENT ON COLUMN VC.NUMERS IS 'Segundo número de policía';
COMMENT ON COLUMN VC.LETRS IS 'Segunda letra.';
COMMENT ON COLUMN VC.KMT IS 'Kilómetro';
COMMENT ON COLUMN VC.BLO IS 'Bloque FIN14';
COMMENT ON COLUMN VC.ESC IS 'Escalera FIN14';
COMMENT ON COLUMN VC.PLANTA IS 'Planta FIN14';
COMMENT ON COLUMN VC.PUERTA IS 'Puerta FIN14';
COMMENT ON COLUMN VC.COOR_X IS 'Coordenada X FIN11 MÁS DEPURACIONES';
COMMENT ON COLUMN VC.COOR_Y IS 'Coordenada Y FIN11 MÁS DEPURACIONES';
COMMENT ON COLUMN VC.HUSO IS ' ';
COMMENT ON COLUMN VC.CVIA_INE IS 'Código de vía (INE)';


-- TABLA: VV
CREATE TABLE VV (
    CIV          VARCHAR2(24 CHAR) PRIMARY KEY,
    CPRO_INE     NUMBER(2),
    CMUN_INE     NUMBER(3),
    CPRO_MEH     NUMBER(2),
    CMUN_DGC     NUMBER(3),
    NENT         VARCHAR2(50 CHAR),
    CVIA_DGC     NUMBER(5),
    TVIA_DGC     VARCHAR2(2 CHAR),
    NVIA_DGC     VARCHAR2(70 CHAR),
    NUMER        VARCHAR2(5 CHAR),
    LETR         VARCHAR2(1 CHAR),
    NUMERS       VARCHAR2(5 CHAR),
    LETRS        VARCHAR2(1 CHAR),
    KMT          VARCHAR2(5 CHAR),
    BLO          VARCHAR2(3 CHAR),
    ESC          VARCHAR2(2 CHAR),
    PLANTA       VARCHAR2(2 CHAR),
    PUERTA       VARCHAR2(3 CHAR),
    COOR_X NUMBER(16,8), -- hasta 8 dígitos decimales, 8 enteros
    COOR_Y NUMBER(18,9),  -- hasta 9 dígitos decimales, 9 enteros
    HUSO         VARCHAR2(10 CHAR),
    CVIA_INE     NUMBER(5)
);

ALTER TABLE VV ADD CONSTRAINT chk_vv_civ_format CHECK (
    CIV IS NULL
    OR REGEXP_LIKE(CIV, '^[A-Z0-9]{7}[A-Z0-9]{7}[0-9]{4}[A-Z0-9]{2}[0-9]{4}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{2}[0-9]{3}[A-Z][0-9]{3}[0-9]{5}[0-9]{4}[A-Z0-9]{2}[0-9]{4}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}[A-Z][0-9]{3}[0-9]{5}[0-9]{10}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}NRC[0-9]{16}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}NVI[0-9]{16}$')
    OR REGEXP_LIKE(CIV, '^0{20}BAJA$')
);

COMMENT ON TABLE VV IS 'Tabla de viviendas con datos de identificación, localización y coordenadas';
COMMENT ON COLUMN VV.CIV IS 'Código de Identificación de Vivienda';
COMMENT ON COLUMN VV.CPRO_INE IS 'Código de Provincia (INE)';
COMMENT ON COLUMN VV.CMUN_INE IS 'Código de Municipio (INE). Excluido el último dígito de control';
COMMENT ON COLUMN VV.CPRO_MEH IS 'Código de Delegación del MEH';
COMMENT ON COLUMN VV.CMUN_DGC IS 'Código del Municipio (Según DGC)';
COMMENT ON COLUMN VV.NENT IS 'Nombre de la entidad menor, en caso de existir';
COMMENT ON COLUMN VV.CVIA_DGC IS 'Código de vía pública (DGC)';
COMMENT ON COLUMN VV.TVIA_DGC IS 'Tipo de vía o sigla pública';
COMMENT ON COLUMN VV.NVIA_DGC IS 'Nombre de la vía pública';
COMMENT ON COLUMN VV.NUMER IS 'Primer número de policía';
COMMENT ON COLUMN VV.LETR IS 'Primera letra.';
COMMENT ON COLUMN VV.NUMERS IS 'Segundo número de policía';
COMMENT ON COLUMN VV.LETRS IS 'Segunda letra.';
COMMENT ON COLUMN VV.KMT IS 'Kilómetro';
COMMENT ON COLUMN VV.BLO IS 'Bloque FIN14';
COMMENT ON COLUMN VV.ESC IS 'Escalera FIN14';
COMMENT ON COLUMN VV.PLANTA IS 'Planta FIN14';
COMMENT ON COLUMN VV.PUERTA IS 'Puerta FIN14';
COMMENT ON COLUMN VV.COOR_X IS 'Coordenada X FIN11 MÁS DEPURACIONES';
COMMENT ON COLUMN VV.COOR_Y IS 'Coordenada Y FIN11 MÁS DEPURACIONES';
COMMENT ON COLUMN VV.HUSO IS ' ';
COMMENT ON COLUMN VV.CVIA_INE IS 'Código de vía (INE)';


-- TABLA: A1HS
CREATE TABLE A1HS (
    CIV            VARCHAR2(24 CHAR) NOT NULL,
    COLECTIVO      VARCHAR2(1 CHAR),
    HOGAR          VARCHAR2(9 CHAR) PRIMARY KEY,
    CPRO           NUMBER(2),
    CMUN           NUMBER(3),
    DIST           NUMBER(2),
    SECC           NUMBER(3),
    CUNN           NUMBER(6),
    NENTCO         VARCHAR2(50 CHAR),
    NENTSI         VARCHAR2(50 CHAR),
    NNUCLE         VARCHAR2(50 CHAR),
    CVIA           NUMBER(5),
    TVIA           VARCHAR2(5 CHAR),
    NVIA           VARCHAR2(50 CHAR),
    NUMERN         VARCHAR2(5 CHAR),
    NUMERSN        VARCHAR2(5 CHAR),
    KMTN           NUMBER(3),
    HMTN           NUMBER(1),
    BLOQN          VARCHAR2(2 CHAR),
    PORTN          VARCHAR2(2 CHAR),
    ESCAN          VARCHAR2(2 CHAR),
    PLANN          VARCHAR2(3 CHAR),
    PUERN          VARCHAR2(4 CHAR),
    CVIA_DGC       NUMBER(5),
    APP_CE         NUMBER(10),
    HUECO_CE       NUMBER(10),
    CODIGO_EATIM   NUMBER(8),
    NOMBRE_EATIM   VARCHAR2(50 CHAR)
);

ALTER TABLE A1HS ADD CONSTRAINT chk_a1hs_civ_format CHECK (
       REGEXP_LIKE(CIV, '^[A-Z0-9]{7}[A-Z0-9]{7}[0-9]{4}[A-Z0-9]{2}[0-9]{4}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{2}[0-9]{3}[A-Z][0-9]{3}[0-9]{5}[0-9]{4}[A-Z0-9]{2}[0-9]{4}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}[A-Z][0-9]{3}[0-9]{5}[0-9]{10}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}NRC[0-9]{16}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}NVI[0-9]{16}$')
    OR REGEXP_LIKE(CIV, '^0{20}BAJA$')
);

COMMENT ON TABLE A1HS IS 'Registros del fichero de hogares con CIV cumplimentado o indicación de baja.';
COMMENT ON COLUMN A1HS.CIV IS 'Código de Identificación de la Vivienda';
COMMENT ON COLUMN A1HS.COLECTIVO IS
	'0: No es establecimiento colectivo
1: Sí es establecimiento colectivo convencional
8: Si es vivienda alquilada por habitaciones';
COMMENT ON COLUMN A1HS.HOGAR IS 'Identificador del hogar (campo vivienda del fichero censal de personas)';
COMMENT ON COLUMN A1HS.CPRO IS 'Código de provincia';
COMMENT ON COLUMN A1HS.CMUN IS 'Código de municipio';
COMMENT ON COLUMN A1HS.DIST IS 'Código de distrito';
COMMENT ON COLUMN A1HS.SECC IS 'Código de sección';
COMMENT ON COLUMN A1HS.CUNN IS 'Código de Unidad Poblacional';
COMMENT ON COLUMN A1HS.NENTCO IS 'Nombre de la Entidad Colectiva';
COMMENT ON COLUMN A1HS.NENTSI IS 'Nombre de la Entidad Singular';
COMMENT ON COLUMN A1HS.NNUCLE IS 'Nombre del Núcleo/Diseminado';
COMMENT ON COLUMN A1HS.CVIA IS 'Código de vía INE';
COMMENT ON COLUMN A1HS.TVIA IS 'Tipo de vía';
COMMENT ON COLUMN A1HS.NVIA IS 'Nombre de la Vía';
COMMENT ON COLUMN A1HS.NUMERN IS 'Número';
COMMENT ON COLUMN A1HS.NUMERSN IS 'Número Superior';
COMMENT ON COLUMN A1HS.KMTN IS 'Kilómetro';
COMMENT ON COLUMN A1HS.HMTN IS 'Hectómetro';
COMMENT ON COLUMN A1HS.BLOQN IS 'Bloque';
COMMENT ON COLUMN A1HS.PORTN IS 'Portal';
COMMENT ON COLUMN A1HS.ESCAN IS 'Escalera';
COMMENT ON COLUMN A1HS.PLANN IS 'Planta';
COMMENT ON COLUMN A1HS.PUERN IS 'Puerta';
COMMENT ON COLUMN A1HS.CVIA_DGC IS 'Código de vía de Catastro';
COMMENT ON COLUMN A1HS.APP_CE IS 'Identificador de Aproximación Postal de Censo Electoral';
COMMENT ON COLUMN A1HS.HUECO_CE IS 'Identificador de Hueco de Censo Electoral';
COMMENT ON COLUMN A1HS.CODIGO_EATIM IS 'Código de Entidad de Ámbito Territorial Menor que el Municipio';
COMMENT ON COLUMN A1HS.NOMBRE_EATIM IS 'Nombre de la Entidad de Ámbito Territorial Menor que el Municipio';


-- TABLA: A1VA
CREATE TABLE A1VA (
    CIV          VARCHAR2(24 CHAR) PRIMARY KEY,
    CPRO_INE     NUMBER(2),
    CMUN_INE     NUMBER(3),
    CPRO_MEH     NUMBER(2),
    CMUN_DGC     NUMBER(3),
    NENT         VARCHAR2(50 CHAR),
    CVIA_DGC     NUMBER(5),
    TVIA_DGC     VARCHAR2(2 CHAR),
    NVIA_DGC     VARCHAR2(70 CHAR),
    NUMER        VARCHAR2(5 CHAR),
    LETR         VARCHAR2(1 CHAR),
    NUMERS       VARCHAR2(5 CHAR),
    LETRS        VARCHAR2(1 CHAR),
    KMT          VARCHAR2(5 CHAR),
    BLO          VARCHAR2(3 CHAR),
    ESC          VARCHAR2(2 CHAR),
    PLANTA       VARCHAR2(2 CHAR),
    PUERTA       VARCHAR2(3 CHAR),
    COOR_X NUMBER(16,8), -- hasta 8 dígitos decimales, 8 enteros
    COOR_Y NUMBER(18,9),  -- hasta 9 dígitos decimales, 9 enteros
    HUSO         VARCHAR2(10 CHAR),
    CVIA_INE     NUMBER(5)
);

ALTER TABLE A1VA ADD CONSTRAINT chk_a1va_civ_format CHECK (
       REGEXP_LIKE(CIV, '^[A-Z0-9]{7}[A-Z0-9]{7}[0-9]{4}[A-Z0-9]{2}[0-9]{4}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{2}[0-9]{3}[A-Z][0-9]{3}[0-9]{5}[0-9]{4}[A-Z0-9]{2}[0-9]{4}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}[A-Z][0-9]{3}[0-9]{5}[0-9]{10}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}NRC[0-9]{16}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}NVI[0-9]{16}$')
);

COMMENT ON TABLE A1VA IS 'Registros de alta del fichero de alta de viviendas con CIV nuevo, caso de existir.';
COMMENT ON COLUMN A1VA.CIV IS 'Código de Identificación de Vivienda';
COMMENT ON COLUMN A1VA.CPRO_INE IS 'Código de Provincia (INE)';
COMMENT ON COLUMN A1VA.CMUN_INE IS 'Código de Municipio (INE). Excluido el último dígito de control';
COMMENT ON COLUMN A1VA.CPRO_MEH IS 'Código de Delegación del MEH';
COMMENT ON COLUMN A1VA.CMUN_DGC IS 'Código del Municipio (Según DGC)';
COMMENT ON COLUMN A1VA.NENT IS 'Nombre de la entidad menor, en caso de existir';
COMMENT ON COLUMN A1VA.CVIA_DGC IS 'Código de vía pública (DGC)';
COMMENT ON COLUMN A1VA.TVIA_DGC IS 'Tipo de vía o sigla pública';
COMMENT ON COLUMN A1VA.NVIA_DGC IS 'Nombre de la vía pública';
COMMENT ON COLUMN A1VA.NUMER IS 'Primer número de policía';
COMMENT ON COLUMN A1VA.LETR IS 'Primera letra.';
COMMENT ON COLUMN A1VA.NUMERS IS 'Segundo número de policía';
COMMENT ON COLUMN A1VA.LETRS IS 'Segunda letra.';
COMMENT ON COLUMN A1VA.KMT IS 'Kilómetro';
COMMENT ON COLUMN A1VA.BLO IS 'Bloque FIN14';
COMMENT ON COLUMN A1VA.ESC IS 'Escalera FIN14';
COMMENT ON COLUMN A1VA.PLANTA IS 'Planta FIN14';
COMMENT ON COLUMN A1VA.PUERTA IS 'Puerta FIN14';
COMMENT ON COLUMN A1VA.COOR_X IS 'Coordenada X FIN11 MÁS DEPURACIONES';
COMMENT ON COLUMN A1VA.COOR_Y IS 'Coordenada Y FIN11 MÁS DEPURACIONES';
COMMENT ON COLUMN A1VA.HUSO IS ' ';
COMMENT ON COLUMN A1VA.CVIA_INE IS 'Código de vía (INE)';

-- TABLA: A2HD
CREATE TABLE A2HD (
    CIV            VARCHAR2(24 CHAR),
    COLECTIVO      VARCHAR2(1 CHAR),
    HOGAR          VARCHAR2(9 CHAR) PRIMARY KEY,
    CPRO           NUMBER(2),
    CMUN           NUMBER(3),
    DIST           NUMBER(2),
    SECC           NUMBER(3),
    CUNN           NUMBER(6),
    NENTCO         VARCHAR2(50 CHAR),
    NENTSI         VARCHAR2(50 CHAR),
    NNUCLE         VARCHAR2(50 CHAR),
    CVIA           NUMBER(5),
    TVIA           VARCHAR2(5 CHAR),
    NVIA           VARCHAR2(50 CHAR),
    NUMERN         VARCHAR2(5 CHAR),
    NUMERSN        VARCHAR2(5 CHAR),
    KMTN           NUMBER(3),
    HMTN           NUMBER(1),
    BLOQN          VARCHAR2(2 CHAR),
    PORTN          VARCHAR2(2 CHAR),
    ESCAN          VARCHAR2(2 CHAR),
    PLANN          VARCHAR2(3 CHAR),
    PUERN          VARCHAR2(4 CHAR),
    CVIA_DGC       NUMBER(5),
    APP_CE         NUMBER(10),
    HUECO_CE       NUMBER(10),
    CODIGO_EATIM   NUMBER(8),
    NOMBRE_EATIM   VARCHAR2(50 CHAR),
    NUMERS_COHERENTE VARCHAR2(1 CHAR),
    KMT_COHERENTE    VARCHAR2(1 CHAR),
    PLANTA_COHERENTE VARCHAR2(1 CHAR),
    PUERTA_COHERENTE VARCHAR2(1 CHAR),
    CIV_PRO        VARCHAR2(24 CHAR) NOT NULL
);

ALTER TABLE A2HD ADD CONSTRAINT chk_a2hd_civ_format CHECK (
       REGEXP_LIKE(CIV, '^[A-Z0-9]{7}[A-Z0-9]{7}[0-9]{4}[A-Z0-9]{2}[0-9]{4}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{2}[0-9]{3}[A-Z][0-9]{3}[0-9]{5}[0-9]{4}[A-Z0-9]{2}[0-9]{4}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}[A-Z][0-9]{3}[0-9]{5}[0-9]{10}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}NRC[0-9]{16}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}NVI[0-9]{16}$')
    OR REGEXP_LIKE(CIV, '^0{20}BAJA$')
);

ALTER TABLE A2HD ADD CONSTRAINT chk_a2hd_civ_pro_format CHECK (
       REGEXP_LIKE(CIV_PRO, '^[A-Z0-9]{7}[A-Z0-9]{7}[0-9]{4}[A-Z0-9]{2}[0-9]{4}$')
    OR REGEXP_LIKE(CIV_PRO, '^[0-9]{2}[0-9]{3}[A-Z][0-9]{3}[0-9]{5}[0-9]{4}[A-Z0-9]{2}[0-9]{4}$')
    OR REGEXP_LIKE(CIV_PRO, '^[0-9]{5}[A-Z][0-9]{3}[0-9]{5}[0-9]{10}$')
    OR REGEXP_LIKE(CIV_PRO, '^[0-9]{5}NRC[0-9]{16}$')
    OR REGEXP_LIKE(CIV_PRO, '^[0-9]{5}NVI[0-9]{16}$')
    OR REGEXP_LIKE(CIV_PRO, '^0{20}BAJA$')
);

COMMENT ON TABLE A2HD IS 'Registros afectados del fichero de hogares con dirección padronal con propuesta de modificación de CIV';
COMMENT ON COLUMN A2HD.CIV IS 'Código de Identificación de la Vivienda';
COMMENT ON COLUMN A2HD.COLECTIVO IS
	'0: No es establecimiento colectivo
1: Sí es establecimiento colectivo convencional
8: Si es vivienda alquilada por habitaciones';
COMMENT ON COLUMN A2HD.HOGAR IS 'Identificador del hogar (campo vivienda del fichero censal de personas)';
COMMENT ON COLUMN A2HD.CPRO IS 'Código de provincia';
COMMENT ON COLUMN A2HD.CMUN IS 'Código de municipio';
COMMENT ON COLUMN A2HD.DIST IS 'Código de distrito';
COMMENT ON COLUMN A2HD.SECC IS 'Código de sección';
COMMENT ON COLUMN A2HD.CUNN IS 'Código de Unidad Poblacional';
COMMENT ON COLUMN A2HD.NENTCO IS 'Nombre de la Entidad Colectiva';
COMMENT ON COLUMN A2HD.NENTSI IS 'Nombre de la Entidad Singular';
COMMENT ON COLUMN A2HD.NNUCLE IS 'Nombre del Núcleo/Diseminado';
COMMENT ON COLUMN A2HD.CVIA IS 'Código de vía INE';
COMMENT ON COLUMN A2HD.TVIA IS 'Tipo de vía';
COMMENT ON COLUMN A2HD.NVIA IS 'Nombre de la Vía';
COMMENT ON COLUMN A2HD.NUMERN IS 'Número';
COMMENT ON COLUMN A2HD.NUMERSN IS 'Número Superior';
COMMENT ON COLUMN A2HD.KMTN IS 'Kilómetro';
COMMENT ON COLUMN A2HD.HMTN IS 'Hectómetro';
COMMENT ON COLUMN A2HD.BLOQN IS 'Bloque';
COMMENT ON COLUMN A2HD.PORTN IS 'Portal';
COMMENT ON COLUMN A2HD.ESCAN IS 'Escalera';
COMMENT ON COLUMN A2HD.PLANN IS 'Planta';
COMMENT ON COLUMN A2HD.PUERN IS 'Puerta';
COMMENT ON COLUMN A2HD.CVIA_DGC IS 'Código de vía de Catastro';
COMMENT ON COLUMN A2HD.APP_CE IS 'Identificador de Aproximación Postal de Censo Electoral';
COMMENT ON COLUMN A2HD.HUECO_CE IS 'Identificador de Hueco de Censo Electoral';
COMMENT ON COLUMN A2HD.CODIGO_EATIM IS 'Código de Entidad de Ámbito Territorial Menor que el Municipio';
COMMENT ON COLUMN A2HD.NOMBRE_EATIM IS 'Nombre de la Entidad de Ámbito Territorial Menor que el Municipio';
COMMENT ON COLUMN A2HD.NUMERS_COHERENTE IS 'Número superior coherente';
COMMENT ON COLUMN A2HD.KMT_COHERENTE IS 'Kilómetro coherente';
COMMENT ON COLUMN A2HD.PLANTA_COHERENTE IS 'Planta coherente';
COMMENT ON COLUMN A2HD.PUERTA_COHERENTE IS 'Puerta coherente';
COMMENT ON COLUMN A2HD.CIV_PRO IS 'Propuesta de nuevo Código de Identificación de la Vivienda';

-- TABLA: A2VA
CREATE TABLE A2VA (
    CIV          VARCHAR2(24 CHAR) PRIMARY KEY,
    CPRO_INE     NUMBER(2),
    CMUN_INE     NUMBER(3),
    CPRO_MEH     NUMBER(2),
    CMUN_DGC     NUMBER(3),
    NENT         VARCHAR2(50 CHAR),
    CVIA_DGC     NUMBER(5),
    TVIA_DGC     VARCHAR2(2 CHAR),
    NVIA_DGC     VARCHAR2(70 CHAR),
    NUMER        VARCHAR2(5 CHAR),
    LETR         VARCHAR2(1 CHAR),
    NUMERS       VARCHAR2(5 CHAR),
    LETRS        VARCHAR2(1 CHAR),
    KMT          VARCHAR2(5 CHAR),
    BLO          VARCHAR2(3 CHAR),
    ESC          VARCHAR2(2 CHAR),
    PLANTA       VARCHAR2(2 CHAR),
    PUERTA       VARCHAR2(3 CHAR),
    COOR_X NUMBER(16,8), -- hasta 8 dígitos decimales, 8 enteros
    COOR_Y NUMBER(18,9),  -- hasta 9 dígitos decimales, 9 enteros
    HUSO         VARCHAR2(10 CHAR),
    CVIA_INE     NUMBER(5)
);

ALTER TABLE A2VA ADD CONSTRAINT chk_a2va_civ_format CHECK (
       REGEXP_LIKE(CIV, '^[A-Z0-9]{7}[A-Z0-9]{7}[0-9]{4}[A-Z0-9]{2}[0-9]{4}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{2}[0-9]{3}[A-Z][0-9]{3}[0-9]{5}[0-9]{4}[A-Z0-9]{2}[0-9]{4}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}[A-Z][0-9]{3}[0-9]{5}[0-9]{10}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}NRC[0-9]{16}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}NVI[0-9]{16}$')
);

COMMENT ON TABLE A2VA IS 'Registros de alta del fichero de alta de viviendas con CIV nuevo, caso de existir.';
COMMENT ON COLUMN A2VA.CIV IS 'Código de Identificación de Vivienda';
COMMENT ON COLUMN A2VA.CPRO_INE IS 'Código de Provincia (INE)';
COMMENT ON COLUMN A2VA.CMUN_INE IS 'Código de Municipio (INE). Excluido el último dígito de control';
COMMENT ON COLUMN A2VA.CPRO_MEH IS 'Código de Delegación del MEH';
COMMENT ON COLUMN A2VA.CMUN_DGC IS 'Código del Municipio (Según DGC)';
COMMENT ON COLUMN A2VA.NENT IS 'Nombre de la entidad menor, en caso de existir';
COMMENT ON COLUMN A2VA.CVIA_DGC IS 'Código de vía pública (DGC)';
COMMENT ON COLUMN A2VA.TVIA_DGC IS 'Tipo de vía o sigla pública';
COMMENT ON COLUMN A2VA.NVIA_DGC IS 'Nombre de la vía pública';
COMMENT ON COLUMN A2VA.NUMER IS 'Primer número de policía';
COMMENT ON COLUMN A2VA.LETR IS 'Primera letra.';
COMMENT ON COLUMN A2VA.NUMERS IS 'Segundo número de policía';
COMMENT ON COLUMN A2VA.LETRS IS 'Segunda letra.';
COMMENT ON COLUMN A2VA.KMT IS 'Kilómetro';
COMMENT ON COLUMN A2VA.BLO IS 'Bloque FIN14';
COMMENT ON COLUMN A2VA.ESC IS 'Escalera FIN14';
COMMENT ON COLUMN A2VA.PLANTA IS 'Planta FIN14';
COMMENT ON COLUMN A2VA.PUERTA IS 'Puerta FIN14';
COMMENT ON COLUMN A2VA.COOR_X IS 'Coordenada X FIN11 MÁS DEPURACIONES';
COMMENT ON COLUMN A2VA.COOR_Y IS 'Coordenada Y FIN11 MÁS DEPURACIONES';
COMMENT ON COLUMN A2VA.HUSO IS ' ';
COMMENT ON COLUMN A2VA.CVIA_INE IS 'Código de vía (INE)';

-- TABLA: A3VC
CREATE TABLE A3VC (
    CIV          VARCHAR2(24 CHAR) PRIMARY KEY,
    CPRO_INE     NUMBER(2),
    CMUN_INE     NUMBER(3),
    CPRO_MEH     NUMBER(2),
    CMUN_DGC     NUMBER(3),
    NENT         VARCHAR2(50 CHAR),
    CVIA_DGC     NUMBER(5),
    TVIA_DGC     VARCHAR2(2 CHAR),
    NVIA_DGC     VARCHAR2(70 CHAR),
    NUMER        VARCHAR2(5 CHAR),
    LETR         VARCHAR2(1 CHAR),
    NUMERS       VARCHAR2(5 CHAR),
    LETRS        VARCHAR2(1 CHAR),
    KMT          VARCHAR2(5 CHAR),
    BLO          VARCHAR2(3 CHAR),
    ESC          VARCHAR2(2 CHAR),
    PLANTA       VARCHAR2(2 CHAR),
    PUERTA       VARCHAR2(3 CHAR),
    COOR_X NUMBER(16,8), -- hasta 8 dígitos decimales, 8 enteros
    COOR_Y NUMBER(18,9),  -- hasta 9 dígitos decimales, 9 enteros
    HUSO         VARCHAR2(10 CHAR),
    CVIA_INE     NUMBER(5),
    CUNN         VARCHAR2(6)
);

ALTER TABLE A3VC ADD CONSTRAINT chk_a3vc_civ_format CHECK (
       REGEXP_LIKE(CIV, '^[A-Z0-9]{7}[A-Z0-9]{7}[0-9]{4}[A-Z0-9]{2}[0-9]{4}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{2}[0-9]{3}[A-Z][0-9]{3}[0-9]{5}[0-9]{4}[A-Z0-9]{2}[0-9]{4}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}[A-Z][0-9]{3}[0-9]{5}[0-9]{10}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}NRC[0-9]{16}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}NVI[0-9]{16}$')
);

ALTER TABLE A3VC
ADD CONSTRAINT chk_a3vc_via_o_cunn
CHECK (
    CVIA_INE <> 0
    OR (CUNN IS NOT NULL AND TRIM(CUNN) <> '')
);

COMMENT ON TABLE A3VC IS 'Registros afectados del fichero de viviendas con dirección catastral y código de vía del callejero de censo electoral';
COMMENT ON COLUMN A3VC.CIV IS 'Código de Identificación de Vivienda';
COMMENT ON COLUMN A3VC.CPRO_INE IS 'Código de Provincia (INE)';
COMMENT ON COLUMN A3VC.CMUN_INE IS 'Código de Municipio (INE). Excluido el último dígito de control';
COMMENT ON COLUMN A3VC.CPRO_MEH IS 'Código de Delegación del MEH';
COMMENT ON COLUMN A3VC.CMUN_DGC IS 'Código del Municipio (Según DGC)';
COMMENT ON COLUMN A3VC.NENT IS 'Nombre de la entidad menor, en caso de existir';
COMMENT ON COLUMN A3VC.CVIA_DGC IS 'Código de vía pública (DGC)';
COMMENT ON COLUMN A3VC.TVIA_DGC IS 'Tipo de vía o sigla pública';
COMMENT ON COLUMN A3VC.NVIA_DGC IS 'Nombre de la vía pública';
COMMENT ON COLUMN A3VC.NUMER IS 'Primer número de policía';
COMMENT ON COLUMN A3VC.LETR IS 'Primera letra.';
COMMENT ON COLUMN A3VC.NUMERS IS 'Segundo número de policía';
COMMENT ON COLUMN A3VC.LETRS IS 'Segunda letra.';
COMMENT ON COLUMN A3VC.KMT IS 'Kilómetro';
COMMENT ON COLUMN A3VC.BLO IS 'Bloque FIN14';
COMMENT ON COLUMN A3VC.ESC IS 'Escalera FIN14';
COMMENT ON COLUMN A3VC.PLANTA IS 'Planta FIN14';
COMMENT ON COLUMN A3VC.PUERTA IS 'Puerta FIN14';
COMMENT ON COLUMN A3VC.COOR_X IS 'Coordenada X FIN11 MÁS DEPURACIONES';
COMMENT ON COLUMN A3VC.COOR_Y IS 'Coordenada Y FIN11 MÁS DEPURACIONES';
COMMENT ON COLUMN A3VC.HUSO IS ' ';
COMMENT ON COLUMN A3VC.CVIA_INE IS 'Código de vía (INE)';
COMMENT ON COLUMN A3VC.CUNN IS 'Código de Unidad Poblacional';

-- TABLA: A4HV
CREATE TABLE A4HV (
    CIV            VARCHAR2(24 CHAR),
    COLECTIVO      VARCHAR2(1 CHAR),
    HOGAR          VARCHAR2(9 CHAR) PRIMARY KEY,
    CPRO           NUMBER(2),
    CMUN           NUMBER(3),
    DIST           NUMBER(2),
    SECC           NUMBER(3),
    CUNN           NUMBER(6),
    NENTCO         VARCHAR2(50 CHAR),
    NENTSI         VARCHAR2(50 CHAR),
    NNUCLE         VARCHAR2(50 CHAR),
    CVIA           NUMBER(5),
    TVIA           VARCHAR2(5 CHAR),
    NVIA           VARCHAR2(50 CHAR),
    NUMERN         VARCHAR2(5 CHAR),
    NUMERSN        VARCHAR2(5 CHAR),
    KMTN           NUMBER(3),
    HMTN           NUMBER(1),
    BLOQN          VARCHAR2(2 CHAR),
    PORTN          VARCHAR2(2 CHAR),
    ESCAN          VARCHAR2(2 CHAR),
    PLANN          VARCHAR2(3 CHAR),
    PUERN          VARCHAR2(4 CHAR),
    CVIA_DGC       NUMBER(5),
    APP_CE         NUMBER(10),
    HUECO_CE       NUMBER(10),
    CODIGO_EATIM   NUMBER(8),
    NOMBRE_EATIM   VARCHAR2(50 CHAR)
);

ALTER TABLE A4HV ADD CONSTRAINT chk_a4hv_civ_format CHECK (
        REGEXP_LIKE(CIV, '^[A-Z0-9]{7}[A-Z0-9]{7}[0-9]{4}[A-Z0-9]{2}[0-9]{4}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{2}[0-9]{3}[A-Z][0-9]{3}[0-9]{5}[0-9]{4}[A-Z0-9]{2}[0-9]{4}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}[A-Z][0-9]{3}[0-9]{5}[0-9]{10}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}NRC[0-9]{16}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}NVI[0-9]{16}$')
);

ALTER TABLE A4HV
ADD CONSTRAINT chk_cvia_dgc_informado
CHECK (
    (CVIA IS NOT NULL AND CVIA <> 0)
    AND
    (CVIA_DGC IS NOT NULL AND CVIA_DGC <> 0)
);

COMMENT ON TABLE A4HV IS 'Registros afectados del fichero de hogares con código de vía INE y con código de vía de catastro';
COMMENT ON COLUMN A4HV.CIV IS 'Código de Identificación de la Vivienda';
COMMENT ON COLUMN A4HV.COLECTIVO IS
	'0: No es establecimiento colectivo
1: Sí es establecimiento colectivo convencional
8: Si es vivienda alquilada por habitaciones';
COMMENT ON COLUMN A4HV.HOGAR IS 'Identificador del hogar (campo vivienda del fichero censal de personas)';
COMMENT ON COLUMN A4HV.CPRO IS 'Código de provincia';
COMMENT ON COLUMN A4HV.CMUN IS 'Código de municipio';
COMMENT ON COLUMN A4HV.DIST IS 'Código de distrito';
COMMENT ON COLUMN A4HV.SECC IS 'Código de sección';
COMMENT ON COLUMN A4HV.CUNN IS 'Código de Unidad Poblacional';
COMMENT ON COLUMN A4HV.NENTCO IS 'Nombre de la Entidad Colectiva';
COMMENT ON COLUMN A4HV.NENTSI IS 'Nombre de la Entidad Singular';
COMMENT ON COLUMN A4HV.NNUCLE IS 'Nombre del Núcleo/Diseminado';
COMMENT ON COLUMN A4HV.CVIA IS 'Código de vía INE';
COMMENT ON COLUMN A4HV.TVIA IS 'Tipo de vía';
COMMENT ON COLUMN A4HV.NVIA IS 'Nombre de la Vía';
COMMENT ON COLUMN A4HV.NUMERN IS 'Número';
COMMENT ON COLUMN A4HV.NUMERSN IS 'Número Superior';
COMMENT ON COLUMN A4HV.KMTN IS 'Kilómetro';
COMMENT ON COLUMN A4HV.HMTN IS 'Hectómetro';
COMMENT ON COLUMN A4HV.BLOQN IS 'Bloque';
COMMENT ON COLUMN A4HV.PORTN IS 'Portal';
COMMENT ON COLUMN A4HV.ESCAN IS 'Escalera';
COMMENT ON COLUMN A4HV.PLANN IS 'Planta';
COMMENT ON COLUMN A4HV.PUERN IS 'Puerta';
COMMENT ON COLUMN A4HV.CVIA_DGC IS 'Código de vía de Catastro';
COMMENT ON COLUMN A4HV.APP_CE IS 'Identificador de Aproximación Postal de Censo Electoral';
COMMENT ON COLUMN A4HV.HUECO_CE IS 'Identificador de Hueco de Censo Electoral';
COMMENT ON COLUMN A4HV.CODIGO_EATIM IS 'Código de Entidad de Ámbito Territorial Menor que el Municipio';
COMMENT ON COLUMN A4HV.NOMBRE_EATIM IS 'Nombre de la Entidad de Ámbito Territorial Menor que el Municipio';

CREATE TABLE A5HA (
    CIV            VARCHAR2(24 CHAR),
    COLECTIVO      VARCHAR2(1 CHAR),
    HOGAR          VARCHAR2(9 CHAR),
    CPRO           NUMBER(2),
    CMUN           NUMBER(3),
    DIST           NUMBER(2),
    SECC           NUMBER(3),
    CUNN           NUMBER(6),
    NENTCO         VARCHAR2(50 CHAR),
    NENTSI         VARCHAR2(50 CHAR),
    NNUCLE         VARCHAR2(50 CHAR),
    CVIA           NUMBER(5),
    TVIA           VARCHAR2(5 CHAR),
    NVIA           VARCHAR2(50 CHAR),
    NUMERN         VARCHAR2(5 CHAR),
    NUMERSN        VARCHAR2(5 CHAR),
    KMTN           NUMBER(3),
    HMTN           NUMBER(1),
    BLOQN          VARCHAR2(2 CHAR),
    PORTN          VARCHAR2(2 CHAR),
    ESCAN          VARCHAR2(2 CHAR),
    PLANN          VARCHAR2(3 CHAR),
    PUERN          VARCHAR2(4 CHAR),
    CVIA_DGC       NUMBER(5),
    APP_CE         NUMBER(10),
    HUECO_CE       NUMBER(10),
    CODIGO_EATIM   NUMBER(8),
    NOMBRE_EATIM   VARCHAR2(50 CHAR),
    CIV_PRO        VARCHAR2(24 CHAR) NOT NULL
);

ALTER TABLE A5HA ADD CONSTRAINT chk_a5ha_civ_format CHECK (
       REGEXP_LIKE(CIV, '^[A-Z0-9]{7}[A-Z0-9]{7}[0-9]{4}[A-Z0-9]{2}[0-9]{4}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{2}[0-9]{3}[A-Z][0-9]{3}[0-9]{5}[0-9]{4}[A-Z0-9]{2}[0-9]{4}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}[A-Z][0-9]{3}[0-9]{5}[0-9]{10}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}NRC[0-9]{16}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}NVI[0-9]{16}$')
);

ALTER TABLE A5HA ADD CONSTRAINT chk_a5ha_civ_pro_format CHECK (
       REGEXP_LIKE(CIV_PRO, '^[A-Z0-9]{7}[A-Z0-9]{7}[0-9]{4}[A-Z0-9]{2}[0-9]{4}$')
    OR REGEXP_LIKE(CIV_PRO, '^[0-9]{2}[0-9]{3}[A-Z][0-9]{3}[0-9]{5}[0-9]{4}[A-Z0-9]{2}[0-9]{4}$')
    OR REGEXP_LIKE(CIV_PRO, '^[0-9]{5}[A-Z][0-9]{3}[0-9]{5}[0-9]{10}$')
    OR REGEXP_LIKE(CIV_PRO, '^[0-9]{5}NRC[0-9]{16}$')
    OR REGEXP_LIKE(CIV_PRO, '^[0-9]{5}NVI[0-9]{16}$')
    OR REGEXP_LIKE(CIV_PRO, '^0{20}BAJA$')
);

COMMENT ON TABLE A5HA IS 'Registros de hogares que se separan con los diferentes CIV propuestos que conforman cada uno de ellos';
COMMENT ON COLUMN A5HA.CIV IS 'Código de Identificación de la Vivienda';
COMMENT ON COLUMN A5HA.COLECTIVO IS
	'0: No es establecimiento colectivo
1: Sí es establecimiento colectivo convencional
8: Si es vivienda alquilada por habitaciones';
COMMENT ON COLUMN A5HA.HOGAR IS 'Identificador del hogar (campo vivienda del fichero censal de personas)';
COMMENT ON COLUMN A5HA.CPRO IS 'Código de provincia';
COMMENT ON COLUMN A5HA.CMUN IS 'Código de municipio';
COMMENT ON COLUMN A5HA.DIST IS 'Código de distrito';
COMMENT ON COLUMN A5HA.SECC IS 'Código de sección';
COMMENT ON COLUMN A5HA.CUNN IS 'Código de Unidad Poblacional';
COMMENT ON COLUMN A5HA.NENTCO IS 'Nombre de la Entidad Colectiva';
COMMENT ON COLUMN A5HA.NENTSI IS 'Nombre de la Entidad Singular';
COMMENT ON COLUMN A5HA.NNUCLE IS 'Nombre del Núcleo/Diseminado';
COMMENT ON COLUMN A5HA.CVIA IS 'Código de vía INE';
COMMENT ON COLUMN A5HA.TVIA IS 'Tipo de vía';
COMMENT ON COLUMN A5HA.NVIA IS 'Nombre de la Vía';
COMMENT ON COLUMN A5HA.NUMERN IS 'Número';
COMMENT ON COLUMN A5HA.NUMERSN IS 'Número Superior';
COMMENT ON COLUMN A5HA.KMTN IS 'Kilómetro';
COMMENT ON COLUMN A5HA.HMTN IS 'Hectómetro';
COMMENT ON COLUMN A5HA.BLOQN IS 'Bloque';
COMMENT ON COLUMN A5HA.PORTN IS 'Portal';
COMMENT ON COLUMN A5HA.ESCAN IS 'Escalera';
COMMENT ON COLUMN A5HA.PLANN IS 'Planta';
COMMENT ON COLUMN A5HA.PUERN IS 'Puerta';
COMMENT ON COLUMN A5HA.CVIA_DGC IS 'Código de vía de Catastro';
COMMENT ON COLUMN A5HA.APP_CE IS 'Identificador de Aproximación Postal de Censo Electoral';
COMMENT ON COLUMN A5HA.HUECO_CE IS 'Identificador de Hueco de Censo Electoral';
COMMENT ON COLUMN A5HA.CODIGO_EATIM IS 'Código de Entidad de Ámbito Territorial Menor que el Municipio';
COMMENT ON COLUMN A5HA.NOMBRE_EATIM IS 'Nombre de la Entidad de Ámbito Territorial Menor que el Municipio';
COMMENT ON COLUMN A5HA.CIV_PRO IS 'Propuesta de nuevo Código de Identificación de la Vivienda';

-- TABLA: A6HM
CREATE TABLE A6HM (
    CIV            VARCHAR2(24 CHAR),
    COLECTIVO      VARCHAR2(1 CHAR),
    HOGAR          VARCHAR2(9 CHAR) PRIMARY KEY,
    CPRO           NUMBER(2),
    CMUN           NUMBER(3),
    DIST           NUMBER(2),
    SECC           NUMBER(3),
    CUNN           NUMBER(6),
    NENTCO         VARCHAR2(50 CHAR),
    NENTSI         VARCHAR2(50 CHAR),
    NNUCLE         VARCHAR2(50 CHAR),
    CVIA           NUMBER(5),
    TVIA           VARCHAR2(5 CHAR),
    NVIA           VARCHAR2(50 CHAR),
    NUMERN         VARCHAR2(5 CHAR),
    NUMERSN        VARCHAR2(5 CHAR),
    KMTN           NUMBER(3),
    HMTN           NUMBER(1),
    BLOQN          VARCHAR2(2 CHAR),
    PORTN          VARCHAR2(2 CHAR),
    ESCAN          VARCHAR2(2 CHAR),
    PLANN          VARCHAR2(3 CHAR),
    PUERN          VARCHAR2(4 CHAR),
    CVIA_DGC       NUMBER(5),
    APP_CE         NUMBER(10),
    HUECO_CE       NUMBER(10),
    CODIGO_EATIM   NUMBER(8),
    NOMBRE_EATIM   VARCHAR2(50 CHAR)
);

ALTER TABLE A6HM ADD CONSTRAINT chk_a6hm_civ_format CHECK (
       REGEXP_LIKE(CIV, '^[A-Z0-9]{7}[A-Z0-9]{7}[0-9]{4}[A-Z0-9]{2}[0-9]{4}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{2}[0-9]{3}[A-Z][0-9]{3}[0-9]{5}[0-9]{4}[A-Z0-9]{2}[0-9]{4}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}[A-Z][0-9]{3}[0-9]{5}[0-9]{10}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}NRC[0-9]{16}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}NVI[0-9]{16}$')
    OR REGEXP_LIKE(CIV, '^0{20}BAJA$')
);

COMMENT ON TABLE A6HM IS 'Registros de hogares en donde se han realizado correcciones que sean diferentes a las mencionadas en los apartados A1 a A5';
COMMENT ON COLUMN A6HM.CIV IS 'Código de Identificación de la Vivienda';
COMMENT ON COLUMN A6HM.COLECTIVO IS
	'0: No es establecimiento colectivo
1: Sí es establecimiento colectivo convencional
8: Si es vivienda alquilada por habitaciones';
COMMENT ON COLUMN A6HM.HOGAR IS 'Identificador del hogar (campo vivienda del fichero censal de personas)';
COMMENT ON COLUMN A6HM.CPRO IS 'Código de provincia';
COMMENT ON COLUMN A6HM.CMUN IS 'Código de municipio';
COMMENT ON COLUMN A6HM.DIST IS 'Código de distrito';
COMMENT ON COLUMN A6HM.SECC IS 'Código de sección';
COMMENT ON COLUMN A6HM.CUNN IS 'Código de Unidad Poblacional';
COMMENT ON COLUMN A6HM.NENTCO IS 'Nombre de la Entidad Colectiva';
COMMENT ON COLUMN A6HM.NENTSI IS 'Nombre de la Entidad Singular';
COMMENT ON COLUMN A6HM.NNUCLE IS 'Nombre del Núcleo/Diseminado';
COMMENT ON COLUMN A6HM.CVIA IS 'Código de vía INE';
COMMENT ON COLUMN A6HM.TVIA IS 'Tipo de vía';
COMMENT ON COLUMN A6HM.NVIA IS 'Nombre de la Vía';
COMMENT ON COLUMN A6HM.NUMERN IS 'Número';
COMMENT ON COLUMN A6HM.NUMERSN IS 'Número Superior';
COMMENT ON COLUMN A6HM.KMTN IS 'Kilómetro';
COMMENT ON COLUMN A6HM.HMTN IS 'Hectómetro';
COMMENT ON COLUMN A6HM.BLOQN IS 'Bloque';
COMMENT ON COLUMN A6HM.PORTN IS 'Portal';
COMMENT ON COLUMN A6HM.ESCAN IS 'Escalera';
COMMENT ON COLUMN A6HM.PLANN IS 'Planta';
COMMENT ON COLUMN A6HM.PUERN IS 'Puerta';
COMMENT ON COLUMN A6HM.CVIA_DGC IS 'Código de vía de Catastro';
COMMENT ON COLUMN A6HM.APP_CE IS 'Identificador de Aproximación Postal de Censo Electoral';
COMMENT ON COLUMN A6HM.HUECO_CE IS 'Identificador de Hueco de Censo Electoral';
COMMENT ON COLUMN A6HM.CODIGO_EATIM IS 'Código de Entidad de Ámbito Territorial Menor que el Municipio';
COMMENT ON COLUMN A6HM.NOMBRE_EATIM IS 'Nombre de la Entidad de Ámbito Territorial Menor que el Municipio';

-- TABLA: A6VM
CREATE TABLE A6VM (
    CIV          VARCHAR2(24 CHAR) PRIMARY KEY,
    CPRO_INE     NUMBER(2),
    CMUN_INE     NUMBER(3),
    CPRO_MEH     NUMBER(2),
    CMUN_DGC     NUMBER(3),
    NENT         VARCHAR2(50 CHAR),
    CVIA_DGC     NUMBER(5),
    TVIA_DGC     VARCHAR2(2 CHAR),
    NVIA_DGC     VARCHAR2(70 CHAR),
    NUMER        VARCHAR2(5 CHAR),
    LETR         VARCHAR2(1 CHAR),
    NUMERS       VARCHAR2(5 CHAR),
    LETRS        VARCHAR2(1 CHAR),
    KMT          VARCHAR2(5 CHAR),
    BLO          VARCHAR2(3 CHAR),
    ESC          VARCHAR2(2 CHAR),
    PLANTA       VARCHAR2(2 CHAR),
    PUERTA       VARCHAR2(3 CHAR),
    COOR_X NUMBER(16,8), -- hasta 8 dígitos decimales, 8 enteros
    COOR_Y NUMBER(18,9),  -- hasta 9 dígitos decimales, 9 enteros
    HUSO         VARCHAR2(10 CHAR),
    CVIA_INE     NUMBER(5)
);

ALTER TABLE A6VM ADD CONSTRAINT chk_a6vm_civ_format CHECK (
        REGEXP_LIKE(CIV, '^[A-Z0-9]{7}[A-Z0-9]{7}[0-9]{4}[A-Z0-9]{2}[0-9]{4}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{2}[0-9]{3}[A-Z][0-9]{3}[0-9]{5}[0-9]{4}[A-Z0-9]{2}[0-9]{4}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}[A-Z][0-9]{3}[0-9]{5}[0-9]{10}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}NRC[0-9]{16}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}NVI[0-9]{16}$')
);

COMMENT ON TABLE A6VM IS 'Registros de viviendas en donde se han realizado correcciones que sean diferentes a las mencionadas en los apartados A1 a A5';
COMMENT ON COLUMN A6VM.CIV IS 'Código de Identificación de Vivienda';
COMMENT ON COLUMN A6VM.CPRO_INE IS 'Código de Provincia (INE)';
COMMENT ON COLUMN A6VM.CMUN_INE IS 'Código de Municipio (INE). Excluido el último dígito de control';
COMMENT ON COLUMN A6VM.CPRO_MEH IS 'Código de Delegación del MEH';
COMMENT ON COLUMN A6VM.CMUN_DGC IS 'Código del Municipio (Según DGC)';
COMMENT ON COLUMN A6VM.NENT IS 'Nombre de la entidad menor, en caso de existir';
COMMENT ON COLUMN A6VM.CVIA_DGC IS 'Código de vía pública (DGC)';
COMMENT ON COLUMN A6VM.TVIA_DGC IS 'Tipo de vía o sigla pública';
COMMENT ON COLUMN A6VM.NVIA_DGC IS 'Nombre de la vía pública';
COMMENT ON COLUMN A6VM.NUMER IS 'Primer número de policía';
COMMENT ON COLUMN A6VM.LETR IS 'Primera letra.';
COMMENT ON COLUMN A6VM.NUMERS IS 'Segundo número de policía';
COMMENT ON COLUMN A6VM.LETRS IS 'Segunda letra.';
COMMENT ON COLUMN A6VM.KMT IS 'Kilómetro';
COMMENT ON COLUMN A6VM.BLO IS 'Bloque FIN14';
COMMENT ON COLUMN A6VM.ESC IS 'Escalera FIN14';
COMMENT ON COLUMN A6VM.PLANTA IS 'Planta FIN14';
COMMENT ON COLUMN A6VM.PUERTA IS 'Puerta FIN14';
COMMENT ON COLUMN A6VM.COOR_X IS 'Coordenada X FIN11 MÁS DEPURACIONES';
COMMENT ON COLUMN A6VM.COOR_Y IS 'Coordenada Y FIN11 MÁS DEPURACIONES';
COMMENT ON COLUMN A6VM.HUSO IS ' ';
COMMENT ON COLUMN A6VM.CVIA_INE IS 'Código de vía (INE)';


-- TABLA: BVA
CREATE TABLE BVA (
    CIV          VARCHAR2(24 CHAR) PRIMARY KEY,
    CPRO_INE     NUMBER(2),
    CMUN_INE     NUMBER(3),
    CPRO_MEH     NUMBER(2),
    CMUN_DGC     NUMBER(3),
    NENT         VARCHAR2(50 CHAR),
    CVIA_DGC     NUMBER(5),
    TVIA_DGC     VARCHAR2(2 CHAR),
    NVIA_DGC     VARCHAR2(70 CHAR),
    NUMER        VARCHAR2(5 CHAR),
    LETR         VARCHAR2(1 CHAR),
    NUMERS       VARCHAR2(5 CHAR),
    LETRS        VARCHAR2(1 CHAR),
    KMT          VARCHAR2(5 CHAR),
    BLO          VARCHAR2(3 CHAR),
    ESC          VARCHAR2(2 CHAR),
    PLANTA       VARCHAR2(2 CHAR),
    PUERTA       VARCHAR2(3 CHAR),
    COOR_X NUMBER(16,8), -- hasta 8 dígitos decimales, 8 enteros
    COOR_Y NUMBER(18,9),  -- hasta 9 dígitos decimales, 9 enteros
    HUSO         VARCHAR2(10 CHAR),
    CVIA_INE     NUMBER(5)
);

ALTER TABLE BVA ADD CONSTRAINT chk_bva_civ_format CHECK (
        REGEXP_LIKE(CIV, '^[A-Z0-9]{7}[A-Z0-9]{7}[0-9]{4}[A-Z0-9]{2}[0-9]{4}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{2}[0-9]{3}[A-Z][0-9]{3}[0-9]{5}[0-9]{4}[A-Z0-9]{2}[0-9]{4}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}[A-Z][0-9]{3}[0-9]{5}[0-9]{10}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}NRC[0-9]{16}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}NVI[0-9]{16}$')
);

COMMENT ON TABLE BVA IS 'Registros de alta del fichero de alta de viviendas con CIV nuevo, caso de existir.';
COMMENT ON COLUMN BVA.CIV IS 'Código de Identificación de Vivienda';
COMMENT ON COLUMN BVA.CPRO_INE IS 'Código de Provincia (INE)';
COMMENT ON COLUMN BVA.CMUN_INE IS 'Código de Municipio (INE). Excluido el último dígito de control';
COMMENT ON COLUMN BVA.CPRO_MEH IS 'Código de Delegación del MEH';
COMMENT ON COLUMN BVA.CMUN_DGC IS 'Código del Municipio (Según DGC)';
COMMENT ON COLUMN BVA.NENT IS 'Nombre de la entidad menor, en caso de existir';
COMMENT ON COLUMN BVA.CVIA_DGC IS 'Código de vía pública (DGC)';
COMMENT ON COLUMN BVA.TVIA_DGC IS 'Tipo de vía o sigla pública';
COMMENT ON COLUMN BVA.NVIA_DGC IS 'Nombre de la vía pública';
COMMENT ON COLUMN BVA.NUMER IS 'Primer número de policía';
COMMENT ON COLUMN BVA.LETR IS 'Primera letra.';
COMMENT ON COLUMN BVA.NUMERS IS 'Segundo número de policía';
COMMENT ON COLUMN BVA.LETRS IS 'Segunda letra.';
COMMENT ON COLUMN BVA.KMT IS 'Kilómetro';
COMMENT ON COLUMN BVA.BLO IS 'Bloque FIN14';
COMMENT ON COLUMN BVA.ESC IS 'Escalera FIN14';
COMMENT ON COLUMN BVA.PLANTA IS 'Planta FIN14';
COMMENT ON COLUMN BVA.PUERTA IS 'Puerta FIN14';
COMMENT ON COLUMN BVA.COOR_X IS 'Coordenada X FIN11 MÁS DEPURACIONES';
COMMENT ON COLUMN BVA.COOR_Y IS 'Coordenada Y FIN11 MÁS DEPURACIONES';
COMMENT ON COLUMN BVA.HUSO IS ' ';
COMMENT ON COLUMN BVA.CVIA_INE IS 'Código de vía (INE)';


-- TABLA: CHC
CREATE TABLE CHC (
    CIV            VARCHAR2(24 CHAR),
    COLECTIVO      VARCHAR2(1 CHAR),
    HOGAR          VARCHAR2(9 CHAR) PRIMARY KEY,
    CPRO           NUMBER(2),
    CMUN           NUMBER(3),
    DIST           NUMBER(2),
    SECC           NUMBER(3),
    CUNN           NUMBER(6),
    NENTCO         VARCHAR2(50 CHAR),
    NENTSI         VARCHAR2(50 CHAR),
    NNUCLE         VARCHAR2(50 CHAR),
    CVIA           NUMBER(5),
    TVIA           VARCHAR2(5 CHAR),
    NVIA           VARCHAR2(50 CHAR),
    NUMERN         VARCHAR2(5 CHAR),
    NUMERSN        VARCHAR2(5 CHAR),
    KMTN           NUMBER(3),
    HMTN           NUMBER(1),
    BLOQN          VARCHAR2(2 CHAR),
    PORTN          VARCHAR2(2 CHAR),
    ESCAN          VARCHAR2(2 CHAR),
    PLANN          VARCHAR2(3 CHAR),
    PUERN          VARCHAR2(4 CHAR),
    CVIA_DGC       NUMBER(5),
    APP_CE         NUMBER(10),
    HUECO_CE       NUMBER(10),
    CODIGO_EATIM   NUMBER(8),
    NOMBRE_EATIM   VARCHAR2(50 CHAR)    
);

ALTER TABLE CHC ADD CONSTRAINT chk_chc_civ_format CHECK (
        REGEXP_LIKE(CIV, '^[A-Z0-9]{7}[A-Z0-9]{7}[0-9]{4}[A-Z0-9]{2}[0-9]{4}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{2}[0-9]{3}[A-Z][0-9]{3}[0-9]{5}[0-9]{4}[A-Z0-9]{2}[0-9]{4}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}[A-Z][0-9]{3}[0-9]{5}[0-9]{10}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}NRC[0-9]{16}$')
    OR REGEXP_LIKE(CIV, '^[0-9]{5}NVI[0-9]{16}$')
);

COMMENT ON TABLE CHC IS 'Registros del fichero de hogares con CIV cumplimentado o indicación de baja.';
COMMENT ON COLUMN CHC.CIV IS 'Código de Identificación de la Vivienda';
COMMENT ON COLUMN CHC.COLECTIVO IS 
	'0: No es establecimiento colectivo
1: Sí es establecimiento colectivo convencional
8: Si es vivienda alquilada por habitaciones';
COMMENT ON COLUMN CHC.HOGAR IS 'Identificador del hogar (campo vivienda del fichero censal de personas)';
COMMENT ON COLUMN CHC.CPRO IS 'Código de provincia';
COMMENT ON COLUMN CHC.CMUN IS 'Código de municipio';
COMMENT ON COLUMN CHC.DIST IS 'Código de distrito';
COMMENT ON COLUMN CHC.SECC IS 'Código de sección';
COMMENT ON COLUMN CHC.CUNN IS 'Código de Unidad Poblacional';
COMMENT ON COLUMN CHC.NENTCO IS 'Nombre de la Entidad Colectiva';
COMMENT ON COLUMN CHC.NENTSI IS 'Nombre de la Entidad Singular';
COMMENT ON COLUMN CHC.NNUCLE IS 'Nombre del Núcleo/Diseminado';
COMMENT ON COLUMN CHC.CVIA IS 'Código de vía INE';
COMMENT ON COLUMN CHC.TVIA IS 'Tipo de vía';
COMMENT ON COLUMN CHC.NVIA IS 'Nombre de la Vía';
COMMENT ON COLUMN CHC.NUMERN IS 'Número';
COMMENT ON COLUMN CHC.NUMERSN IS 'Número Superior';
COMMENT ON COLUMN CHC.KMTN IS 'Kilómetro';
COMMENT ON COLUMN CHC.HMTN IS 'Hectómetro';
COMMENT ON COLUMN CHC.BLOQN IS 'Bloque';
COMMENT ON COLUMN CHC.PORTN IS 'Portal';
COMMENT ON COLUMN CHC.ESCAN IS 'Escalera';
COMMENT ON COLUMN CHC.PLANN IS 'Planta';
COMMENT ON COLUMN CHC.PUERN IS 'Puerta';
COMMENT ON COLUMN CHC.CVIA_DGC IS 'Código de vía de Catastro';
COMMENT ON COLUMN CHC.APP_CE IS 'Identificador de Aproximación Postal de Censo Electoral';
COMMENT ON COLUMN CHC.HUECO_CE IS 'Identificador de Hueco de Censo Electoral';
COMMENT ON COLUMN CHC.CODIGO_EATIM IS 'Código de Entidad de Ámbito Territorial Menor que el Municipio';
COMMENT ON COLUMN CHC.NOMBRE_EATIM IS 'Nombre de la Entidad de Ámbito Territorial Menor que el Municipio';

---------------------------------------------------------
-- CREACIÓN DE VISTAS EN EL ESQUEMA 'padrononline'
---------------------------------------------------------
CREATE OR REPLACE VIEW VW_CONTADORES_INE AS
SELECT
  (SELECT COUNT(*) FROM hh) AS HH,
  (SELECT COUNT(*) FROM hc) AS HC,
  (SELECT COUNT(*) FROM hd) AS HD,
  (SELECT COUNT(*) FROM hs) AS HS,
  (SELECT COUNT(*) FROM hv) AS HV,
  (SELECT COUNT(*) FROM pp) AS PP,
  (SELECT COUNT(*) FROM vc) AS VC,
  (SELECT COUNT(*) FROM vv) AS VV
FROM dual;

CREATE OR REPLACE VIEW VW_CONTADORES_INE_POR_CMUN AS
WITH
    hc_c AS (SELECT LPAD(cmun,3,'0') AS cmun, COUNT(*) AS HC FROM hc GROUP BY cmun),
    hd_c AS (SELECT LPAD(cmun,3,'0') AS cmun, COUNT(*) AS HD FROM hd GROUP BY cmun),
    hh_c AS (SELECT LPAD(cmun,3,'0') AS cmun, COUNT(*) AS HH FROM hh GROUP BY cmun),
    hs_c AS (SELECT LPAD(cmun,3,'0') AS cmun, COUNT(*) AS HS FROM hs GROUP BY cmun),
    hv_c AS (SELECT LPAD(cmun,3,'0') AS cmun, COUNT(*) AS HV FROM hv GROUP BY cmun),
    pp_c AS (SELECT LPAD(cmun,3,'0') AS cmun, COUNT(*) AS PP FROM pp GROUP BY cmun),
    vc_c AS (SELECT LPAD(cmun_ine,3,'0') AS cmun, COUNT(*) AS VC FROM vc GROUP BY cmun_ine),
    vv_c AS (SELECT LPAD(cmun_ine,3,'0') AS cmun, COUNT(*) AS VV FROM vv GROUP BY cmun_ine),
    all_cmun AS (
        SELECT LPAD(cmun,3,'0') AS cmun FROM hh_c
        UNION
        SELECT cmun FROM hc_c
        UNION
        SELECT cmun FROM hd_c
        UNION
        SELECT cmun FROM hs_c
        UNION
        SELECT cmun FROM hv_c
        UNION
        SELECT cmun FROM pp_c
        UNION
        SELECT cmun FROM vc_c
        UNION
        SELECT cmun FROM vv_c
    )
SELECT
    a.cmun,
    NVL(hh.HH,0) AS HH,
    NVL(hc.HC,0) AS HC,
    NVL(hd.HD,0) AS HD,
    NVL(hs.HS,0) AS HS,
    NVL(hv.HV,0) AS HV,
    NVL(pp.PP,0) AS PP,
    NVL(vc.VC,0) AS VC,
    NVL(vv.VV,0) AS VV
FROM all_cmun a
LEFT JOIN hh_c hh ON hh.cmun = a.cmun
LEFT JOIN hc_c hc ON hc.cmun = a.cmun
LEFT JOIN hd_c hd ON hd.cmun = a.cmun
LEFT JOIN hs_c hs ON hs.cmun = a.cmun
LEFT JOIN hv_c hv ON hv.cmun = a.cmun
LEFT JOIN pp_c pp ON pp.cmun = a.cmun
LEFT JOIN vc_c vc ON vc.cmun = a.cmun
LEFT JOIN vv_c vv ON vv.cmun = a.cmun
ORDER BY a.cmun;

CREATE OR REPLACE VIEW VW_CONTADORES_MUN AS
SELECT
  (SELECT COUNT(*) FROM a1hs) AS A1HS,
  (SELECT COUNT(*) FROM a1va) AS A1VA,
  (SELECT COUNT(*) FROM a2hd) AS A2HD,
  (SELECT COUNT(*) FROM a2va) AS A2VA,
  (SELECT COUNT(*) FROM a3vc) AS A3VC,
  (SELECT COUNT(*) FROM a4hv) AS A4HV,
  (SELECT COUNT(*) FROM a5ha) AS A5HA,
  (SELECT COUNT(*) FROM a6hm) AS A6HM,
  (SELECT COUNT(*) FROM a6vm) AS A6VM,
  (SELECT COUNT(*) FROM bva)  AS BVA,
  (SELECT COUNT(*) FROM chc)  AS CHC
FROM dual;

CREATE OR REPLACE VIEW VW_CONTADORES_MUN_POR_CMUN AS
WITH
	a1hs_c AS (SELECT LPAD(cmun, 3, '0') AS cmun, COUNT(*) AS A1HS FROM a1hs GROUP BY cmun),
	a1va_c AS (SELECT LPAD(cmun_ine, 3, '0') AS cmun, COUNT(*) AS A1VA FROM a1va GROUP BY cmun_ine),
	a2hd_c AS (SELECT LPAD(cmun, 3, '0') AS cmun, COUNT(*) AS A2HD FROM a2hd GROUP BY cmun),
	a2va_c AS (SELECT LPAD(cmun_ine, 3, '0') AS cmun, COUNT(*) AS A2VA FROM a2va GROUP BY cmun_ine),
	a3vc_c AS (SELECT LPAD(cmun_ine, 3, '0') AS cmun, COUNT(*) AS A3VC FROM a3vc GROUP BY cmun_ine),
	a4hv_c AS (SELECT LPAD(cmun, 3, '0') AS cmun, COUNT(*) AS A4HV FROM a4hv GROUP BY cmun),
	a5ha_c AS (SELECT LPAD(cmun, 3, '0') AS cmun, COUNT(*) AS A5HA FROM a5ha GROUP BY cmun),
	a6hm_c AS (SELECT LPAD(cmun, 3, '0') AS cmun, COUNT(*) AS A6HM FROM a6hm GROUP BY cmun),
	a6vm_c AS (SELECT LPAD(cmun_ine, 3, '0') AS cmun, COUNT(*) AS A6VM FROM a6vm GROUP BY cmun_ine),
	bva_c AS (SELECT LPAD(cmun_ine, 3, '0') AS cmun, COUNT(*) AS BVA FROM bva GROUP BY cmun_ine),
	chc_c AS (SELECT LPAD(cmun, 3, '0') AS cmun, COUNT(*) AS CHC FROM chc GROUP BY cmun),
	all_cmun AS (
		SELECT LPAD(cmun, 3, '0') AS cmun FROM a1hs_c
		UNION SELECT cmun FROM a1va_c
		UNION SELECT cmun FROM a2hd_c
		UNION SELECT cmun FROM a2va_c
		UNION SELECT cmun FROM a3vc_c
		UNION SELECT cmun FROM a4hv_c
		UNION SELECT cmun FROM a5ha_c
		UNION SELECT cmun FROM a6hm_c
		UNION SELECT cmun FROM a6vm_c
		UNION SELECT cmun FROM bva_c
		UNION SELECT cmun FROM chc_c
	)
SELECT
    a.cmun,
    NVL(a1hs.A1HS, 0) AS A1HS,
    NVL(a1va.A1VA, 0) AS A1VA,
    NVL(a2hd.A2HD, 0) AS A2HD,
    NVL(a2va.A2VA, 0) AS A2VA,
    NVL(a3vc.A3VC, 0) AS A3VC,
    NVL(a4hv.A4HV, 0) AS A4HV,
    NVL(a5ha.A5HA, 0) AS A5HA,
    NVL(a6hm.A6HM, 0) AS A6HM,
	NVL(a6vm.A6VM, 0) AS A6VM,
    NVL(bva.BVA,   0) AS BVA,
	NVL(chc.CHC,   0) AS CHC
FROM all_cmun a
LEFT JOIN a1hs_c a1hs ON a1hs.cmun = a.cmun
LEFT JOIN a1va_c a1va ON a1va.cmun = a.cmun
LEFT JOIN a2hd_c a2hd ON a2hd.cmun = a.cmun
LEFT JOIN a2va_c a2va ON a2va.cmun = a.cmun
LEFT JOIN a3vc_c a3vc ON a3vc.cmun = a.cmun
LEFT JOIN a4hv_c a4hv ON a4hv.cmun = a.cmun
LEFT JOIN a5ha_c a5ha ON a5ha.cmun = a.cmun
LEFT JOIN a6hm_c a6hm ON a6hm.cmun = a.cmun
LEFT JOIN a6vm_c a6vm ON a6vm.cmun = a.cmun
LEFT JOIN bva_c  bva  ON bva.cmun  = a.cmun
LEFT JOIN chc_c  chc  ON chc.cmun  = a.cmun
ORDER BY a.cmun;