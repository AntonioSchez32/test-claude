---------------------------------------------------------
-- OTORGAR PERMISOS AL USUARIO 'padrononline'
---------------------------------------------------------
ALTER SESSION SET CURRENT_SCHEMA = PADRONONLINE;

-- Permiso DBA (si deseas otorgar permisos completos de administración)
GRANT DBA TO padrononline;

-- Permisos sobre las tablas (SELECT, INSERT, UPDATE, DELETE)
GRANT SELECT, INSERT, UPDATE, DELETE ON PERSONAS TO padrononline;
GRANT SELECT, INSERT, UPDATE, DELETE ON HOGARES TO padrononline;
GRANT SELECT, INSERT, UPDATE, DELETE ON VIVIENDAS TO padrononline;

-- Permisos sobre los índices (ALTER, DROP)
GRANT CREATE ANY INDEX TO padrononline;
GRANT ALTER ANY INDEX TO padrononline;
GRANT DROP ANY INDEX TO padrononline;