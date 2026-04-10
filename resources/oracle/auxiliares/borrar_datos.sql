-- BORRA LOS DATOS DE LAS TABLAS, EXCEPTO DE MUNICIPIOS
DECLARE
  v_sql VARCHAR2(4000);
BEGIN
  -- Primero borrar tablas hijas según dependencias
  FOR t IN (
    SELECT table_name
    FROM user_tables
    WHERE table_name <> 'MUNICIPIOS'
    ORDER BY (
      SELECT COUNT(*)
      FROM user_constraints c
      WHERE c.table_name = user_tables.table_name
        AND c.constraint_type = 'R'
    ) DESC
  ) LOOP
    v_sql := 'DELETE FROM "' || t.table_name || '"';
    EXECUTE IMMEDIATE v_sql;
  END LOOP;
END;
/
COMMIT;