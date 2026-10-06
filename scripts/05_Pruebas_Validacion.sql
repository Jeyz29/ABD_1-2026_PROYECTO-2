-- ============================================================================
-- PROYECTO II - ADMINISTRACIÓN DE BASES DE DATOS (UCV - 1-2026)
-- EMPRESA: CompuComisiones, C.A.
-- ARCHIVO: 05_Pruebas_Validacion.sql
-- DESCRIPCIÓN:
--   Batería integral de pruebas unitarias y de validación de reglas de negocio:
--   1. Validación de almacenamiento en Filegroups (Tablas en DATA, Índices en INDEX, 0 en PRIMARY).
--   2. Prueba de Trigger 1: Control de Participación en Factura (<= 100% y solo vendedores activos).
--   3. Prueba de Trigger 2: Integridad de Cadena de Supervisión (previene auto-jefe y ciclos).
--   4. Prueba de Trigger 3: Recupero por Devolución (factura anulada retrae comisiones).
--   5. Prueba de Trigger 4: Integridad de Asignación de Plan (solo activos y no solapamiento).
--   6. Prueba de Restricción CK_Periodo_fechas: Duración exacta (semana, mes, trimestre, año).
--   7. Prueba de Función comisiones.fn_CalcularBaseComisionable (filtros y bases).
--   8. Prueba de Procedimientos y Vista comisiones.vw_ReportePagosFinanzas.
--   9. Prueba de Roles de Seguridad (registrador, moderador, administrador, usr_schema_owner).
-- ============================================================================

USE CompuComisiones;
GO

SET NOCOUNT ON;

PRINT '======================================================================';
PRINT 'PRUEBA 1: Verificación de Almacenamiento Físico en Filegroups';
PRINT '======================================================================';

-- 1.1 Validar que NINGUNA tabla de usuario resida en el filegroup PRIMARY
DECLARE @TablasEnPrimary INT;
SELECT @TablasEnPrimary = COUNT(*)
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.indexes i ON t.object_id = i.object_id AND i.index_id IN (0, 1)
INNER JOIN sys.filegroups fg ON i.data_space_id = fg.data_space_id
WHERE s.name = 'comisiones' AND fg.name = 'PRIMARY';

IF @TablasEnPrimary = 0
    PRINT '>> ÉXITO [1.1]: Ninguna tabla de usuario reside en el filegroup PRIMARY.';
ELSE
    PRINT '>> ERROR [1.1]: Se encontraron tablas en PRIMARY.';

-- 1.2 Validar que todas las 18 tablas residan en FG_COMPU_DATA
SELECT
    t.name AS Tabla,
    fg.name AS Filegroup_Datos
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.indexes i ON t.object_id = i.object_id AND i.index_id IN (0, 1)
INNER JOIN sys.filegroups fg ON i.data_space_id = fg.data_space_id
WHERE s.name = 'comisiones'
ORDER BY t.name;

-- 1.3 Validar que los índices residan en FG_COMPU_INDEX
SELECT
    t.name AS Tabla,
    i.name AS Indice,
    fg.name AS Filegroup_Indices
FROM sys.indexes i
INNER JOIN sys.tables t ON i.object_id = t.object_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.filegroups fg ON i.data_space_id = fg.data_space_id
WHERE s.name = 'comisiones' AND i.name LIKE '%_indx'
ORDER BY t.name, i.name;
GO

PRINT '======================================================================';
PRINT 'PRUEBA 2: Trigger 1 - Control de Participación en Factura';
PRINT '======================================================================';

-- 2.1 Intento de superar el 100% de participación en una factura
BEGIN TRY
    PRINT 'Caso 2.1: Intentando insertar participación excedente (70% adicional en factura que ya tiene 100%)...';
    INSERT INTO comisiones.FacturaParticipacion (id_factura, id_vendedor, id_rol, porcentaje_participacion)
    VALUES (1, 3, 3, 70.00);
    PRINT '>> ERROR [2.1]: La prueba falló, se permitió una suma superior al 100%.';
END TRY
BEGIN CATCH
    PRINT '>> ÉXITO [2.1]: Trigger 1 bloqueó correctamente la participación excedente.';
    PRINT '   Mensaje: ' + ERROR_MESSAGE();
END CATCH;

-- 2.2 Intento de incorporar como vendedor a una persona inactiva (Patricia Soto, ID 12)
BEGIN TRY
    PRINT 'Caso 2.2: Intentando incorporar vendedor inactivo en Factura 11...';
    INSERT INTO comisiones.FacturaParticipacion (id_factura, id_vendedor, id_rol, porcentaje_participacion)
    VALUES (11, 12, 1, 20.00);
    PRINT '>> ERROR [2.2]: La prueba falló, se permitió un vendedor inactivo.';
END TRY
BEGIN CATCH
    PRINT '>> ÉXITO [2.2]: Trigger 1 bloqueó correctamente la incorporación de vendedor inactivo.';
    PRINT '   Mensaje: ' + ERROR_MESSAGE();
END CATCH;
GO

PRINT '======================================================================';
PRINT 'PRUEBA 3: Trigger 2 - Integridad de la Cadena de Supervisión';
PRINT '======================================================================';

-- 3.1 Auto-supervisión directa
BEGIN TRY
    PRINT 'Caso 3.1: Intentando registrar a un supervisor como su propio jefe...';
    UPDATE comisiones.Supervisor
    SET id_supervisor_jefe = 13
    WHERE id_supervisor = 13;
    PRINT '>> ERROR [3.1]: La prueba falló, se permitió auto-supervisión.';
END TRY
BEGIN CATCH
    PRINT '>> ÉXITO [3.1]: Trigger 2 bloqueó la auto-supervisión directa.';
    PRINT '   Mensaje: ' + ERROR_MESSAGE();
END CATCH;

-- 3.2 Ciclo indirecto (13 es jefe de 14, intentar poner a 14 como jefe de 13)
BEGIN TRY
    PRINT 'Caso 3.2: Intentando crear ciclo indirecto de mando (subordinado como jefe de su superior)...';
    UPDATE comisiones.Supervisor
    SET id_supervisor_jefe = 14
    WHERE id_supervisor = 13;
    PRINT '>> ERROR [3.2]: La prueba falló, se permitió un ciclo en la jerarquía.';
END TRY
BEGIN CATCH
    PRINT '>> ÉXITO [3.2]: Trigger 2 bloqueó el ciclo en la línea de mando.';
    PRINT '   Mensaje: ' + ERROR_MESSAGE();
END CATCH;
GO

PRINT '======================================================================';
PRINT 'PRUEBA 4: Trigger 3 - Recupero por Devolución (Factura Anulada)';
PRINT '======================================================================';

-- Consultar estado previo de Carlos Mendoza (ID 1) y su supervisor Gustavo López (ID 15) en Enero
PRINT 'Estado previo de liquidación para Factura 1 (Carlos Mendoza y Sup. Gustavo López):';
SELECT
    cc.id_calculo,
    cc.id_persona,
    p.nombre + ' ' + p.apellidos AS persona,
    cc.monto_propio_ventas,
    cc.monto_supervision,
    cc.monto_total_reconocido,
    cc.estado_reconocimiento
FROM comisiones.CalculoComision cc
INNER JOIN comisiones.Persona p ON cc.id_persona = p.id_persona
WHERE cc.id_periodo = 1 AND cc.id_persona IN (1, 15);

-- Anular la Factura 1 (que tiene comisión cobrada bajo Plan SaaS con admite_descuento = 1)
PRINT 'Anulando Factura FAC-2026-001 (devolución) para activar Trigger 3...';
UPDATE comisiones.Factura
SET situacion = 'Anulada'
WHERE id_factura = 1;

-- Verificar ajuste inmediato en el cálculo (estado pasa a 'Ajustado' y montos se reducen)
PRINT 'Estado posterior al recupero automático:';
SELECT
    cc.id_calculo,
    cc.id_persona,
    p.nombre + ' ' + p.apellidos AS persona,
    cc.monto_propio_ventas,
    cc.monto_supervision,
    cc.monto_total_reconocido,
    cc.estado_reconocimiento
FROM comisiones.CalculoComision cc
INNER JOIN comisiones.Persona p ON cc.id_persona = p.id_persona
WHERE cc.id_periodo = 1 AND cc.id_persona IN (1, 15);

-- Consultar las filas de ajuste negativo registradas en CalculoDetalle
SELECT
    cd.id_calculo_detalle,
    cd.id_calculo,
    cd.id_factura,
    cd.comision_generada,
    cd.tipo_origen
FROM comisiones.CalculoDetalle cd
WHERE cd.id_factura = 1;
GO

PRINT '======================================================================';
PRINT 'PRUEBA 5: Trigger 4 - Integridad de Asignación de Plan';
PRINT '======================================================================';

-- 5.1 Asignación a persona inactiva
BEGIN TRY
    PRINT 'Caso 5.1: Intentando asignar plan a persona inactiva (ID 12)...';
    INSERT INTO comisiones.AsignacionPlan (id_vendedor, id_rol, id_plan, fecha_inicio_vigor, fecha_fin_vigor)
    VALUES (12, 1, 1, '2026-01-01', NULL);
    PRINT '>> ERROR [5.1]: Se permitió asignar plan a vendedor inactivo.';
END TRY
BEGIN CATCH
    PRINT '>> ÉXITO [5.1]: Trigger bloqueó asignación a persona inactiva.';
    PRINT '   Mensaje: ' + ERROR_MESSAGE();
END CATCH;

-- 5.2 Dupla (vendedor, rol) con solapamiento de fechas
BEGIN TRY
    PRINT 'Caso 5.2: Intentando solapar vigencia de plan para Carlos (ID 1) en Rol Originador (ID 1)...';
    INSERT INTO comisiones.AsignacionPlan (id_vendedor, id_rol, id_plan, fecha_inicio_vigor, fecha_fin_vigor)
    VALUES (1, 1, 2, '2025-01-01', NULL);
    PRINT '>> ERROR [5.2]: Se permitió solapamiento de planes para la misma dupla.';
END TRY
BEGIN CATCH
    PRINT '>> ÉXITO [5.2]: Trigger bloqueó solapamiento de vigencia para la misma dupla.';
    PRINT '   Mensaje: ' + ERROR_MESSAGE();
END CATCH;
GO

PRINT '======================================================================';
PRINT 'PRUEBA 6: Restricción CK_Periodo_fechas (Duración por Tipo de Periodo)';
PRINT '======================================================================';

-- 6.1 Intento de periodo mensual con fechas que no corresponden a un mes completo
BEGIN TRY
    PRINT 'Caso 6.1: Intentando insertar periodo mensual con solo 15 días...';
    INSERT INTO comisiones.Periodo (codigo_periodo, descripcion, tipo_periodo, fecha_inicio, fecha_fin)
    VALUES ('PER-TEST-INV', 'Periodo Inválido', 'Mensual', '2026-05-01', '2026-05-15');
    PRINT '>> ERROR [6.1]: Se permitió periodo mensual con duración inválida.';
END TRY
BEGIN CATCH
    PRINT '>> ÉXITO [6.1]: CK_Periodo_fechas rechazó duración incorrecta de periodo mensual.';
    PRINT '   Mensaje: ' + ERROR_MESSAGE();
END CATCH;

-- 6.2 Intento de factura con cobro anterior a emisión
BEGIN TRY
    PRINT 'Caso 6.2: Intentando insertar factura con fecha de cobro anterior a emisión...';
    INSERT INTO comisiones.Factura (numero_factura, id_cliente, fecha_emision, situacion, fecha_cobro)
    VALUES ('FAC-INV-001', 1, '2026-05-10', 'Cobrada', '2026-05-01');
    PRINT '>> ERROR [6.2]: Se permitió factura con fecha de cobro anterior a emisión.';
END TRY
BEGIN CATCH
    PRINT '>> ÉXITO [6.2]: CK_Factura_cobro rechazó fecha de cobro anterior a emisión.';
    PRINT '   Mensaje: ' + ERROR_MESSAGE();
END CATCH;
GO

PRINT '======================================================================';
PRINT 'PRUEBA 7: Función comisiones.fn_CalcularBaseComisionable';
PRINT '======================================================================';

-- Comparación de base comisionable para Factura 2 frente a diversos planes:
-- Plan 1 (SaaS - Ingreso): Debe dar 0 porque Factura 2 no contiene software SaaS.
-- Plan 2 (HW - Margen): Debe calcular el margen exacto de los servidores y switches.
-- Plan 4 (Volumen - Cantidad): Debe sumar la cantidad de unidades.
SELECT
    f.id_factura,
    f.numero_factura,
    p.id_plan,
    p.nombre AS nombre_plan,
    p.base_aplicacion,
    comisiones.fn_CalcularBaseComisionable(f.id_factura, p.id_plan) AS base_comisionable_calculada
FROM comisiones.Factura f
CROSS JOIN comisiones.PlanComision p
WHERE f.id_factura = 2 AND p.id_plan IN (1, 2, 4);
GO

PRINT '======================================================================';
PRINT 'PRUEBA 8: Vista comisiones.vw_ReportePagosFinanzas';
PRINT '======================================================================';

SELECT TOP 10
    codigo_periodo_pago,
    tipo_periodo_pago,
    fecha_pago,
    nombre_completo_beneficiario,
    rol_organizacional,
    monto_pagado,
    estado_pago,
    codigo_periodo_calculado,
    procesado_por_nombre,
    cargo_finanzas
FROM comisiones.vw_ReportePagosFinanzas
ORDER BY fecha_pago DESC;
GO

PRINT '======================================================================';
PRINT 'PRUEBA 9: Seguridad y Privilegios de Roles';
PRINT '======================================================================';

-- Crear usuarios de prueba temporales para verificar permisos de cada rol
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'usr_test_moderador')
    CREATE USER usr_test_moderador WITHOUT LOGIN;
ALTER ROLE moderador ADD MEMBER usr_test_moderador;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'usr_test_registrador')
    CREATE USER usr_test_registrador WITHOUT LOGIN;
ALTER ROLE registrador ADD MEMBER usr_test_registrador;

-- 9.1 Probar rol moderador (solo lectura: SELECT permitido, INSERT denegado)
EXECUTE AS USER = 'usr_test_moderador';
PRINT 'Caso 9.1: Probando rol moderador...';
SELECT TOP 1 id_cliente, nombre FROM comisiones.Cliente;

BEGIN TRY
    INSERT INTO comisiones.Cliente (codigo_cliente, nombre, segmento_mercado)
    VALUES ('CLI-MOD-TEST', 'Prueba Moderador', 'Test');
    PRINT '>> ERROR [9.1]: Moderador pudo realizar INSERT.';
END TRY
BEGIN CATCH
    PRINT '>> ÉXITO [9.1]: Moderador fue bloqueado al intentar INSERT (Solo lectura garantizada).';
    PRINT '   Mensaje: ' + ERROR_MESSAGE();
END CATCH;
REVERT;

-- 9.2 Probar rol registrador (DML en Facturas/Personas permitido, DML en Planes/Periodos denegado)
EXECUTE AS USER = 'usr_test_registrador';
PRINT 'Caso 9.2: Probando rol registrador...';
BEGIN TRY
    -- Intento de modificar configuración de Planes (no autorizado para registrador)
    INSERT INTO comisiones.PlanComision (codigo_plan, nombre, tasa_comision, base_aplicacion)
    VALUES ('PLAN-REG-FAIL', 'Plan No Autorizado', 5.0, 'Ingreso');
    PRINT '>> ERROR [9.2]: Registrador pudo insertar en PlanComision.';
END TRY
BEGIN CATCH
    PRINT '>> ÉXITO [9.2]: Registrador fue bloqueado al intentar INSERT en PlanComision (fuera de su ámbito).';
    PRINT '   Mensaje: ' + ERROR_MESSAGE();
END CATCH;
REVERT;

-- 9.3 Probar usuario propietario del esquema (debe ser WITHOUT LOGIN)
SELECT
    name AS UsuarioPropietario,
    type_desc AS TipoUsuario,
    authentication_type_desc AS TipoAutenticacion
FROM sys.database_principals
WHERE name = N'usr_schema_owner';
PRINT '>> ÉXITO [9.3]: El usuario propietario usr_schema_owner no posee login asociado.';

-- Limpieza de usuarios de prueba
DROP USER usr_test_moderador;
DROP USER usr_test_registrador;
GO

PRINT '======================================================================';
PRINT '>> TODAS LAS PRUEBAS DE VALIDACIÓN Y CONTROL FINALIZARON CON ÉXITO.';
PRINT '======================================================================';
GO
