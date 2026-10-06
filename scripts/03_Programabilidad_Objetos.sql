-- ============================================================================
-- DESCRIPCIÓN:
--   Implementación de todos los objetos de lógica de negocio y programabilidad:
--   1. Triggers requeridos:
--      - trg_ControlParticipacionFactura (Suma de participaciones <= 100%)
--      - trg_IntegridadCadenaSupervision (Previene auto-supervisión y ciclos)
--      - trg_RecuperoPorDevolucion (Retrae comisiones ante factura anulada)
--   2. Función de cálculo de base comisionable con filtros de plan:
--      - fn_CalcularBaseComisionable
--   3. Procedimientos Almacenados:
--      - sp_CorrerCalculoComisiones (Ejecuta el cálculo para un periodo dado)
--      - sp_RegistrarPagosPeriodo (Registra pagos independientes y actualiza estados)
--   4. Vista de Reportes:
--      - vw_ReportePagosFinanzas (Reporte multi-periodo para finanzas)
-- ============================================================================

USE CompuComisiones;
GO

-- 1. TRIGGERS

-- ----------------------------------------------------------------------------
-- TRIGGER 1: Control de la participación en la factura
-- "debe garantizar que la suma de los porcentajes de participación de los
--  vendedores de una misma factura nunca supere el 100%, rechazando toda
--  inserción o modificación que rompa esa regla."
-- "Solo las personas activas pueden incorporarse como vendedores en nuevas facturas"
-- ----------------------------------------------------------------------------
CREATE OR ALTER TRIGGER comisiones.trg_ControlParticipacionFactura
ON comisiones.FacturaParticipacion
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Validar que solo personas activas se incorporen como vendedores
    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN comisiones.Persona p ON i.id_vendedor = p.id_persona
        WHERE p.estatus <> 'Activo'
    )
    BEGIN
        RAISERROR('Error de Integridad: Solo las personas activas pueden incorporarse como vendedores en facturas.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    -- 2. Validar que la suma de participaciones no supere el 100.00%
    IF EXISTS (
        SELECT fp.id_factura
        FROM comisiones.FacturaParticipacion fp
        WHERE fp.id_factura IN (SELECT DISTINCT id_factura FROM inserted)
        GROUP BY fp.id_factura
        HAVING SUM(fp.porcentaje_participacion) > 100.00
    )
    BEGIN
        RAISERROR('Error de Integridad: La suma de los porcentajes de participación de los vendedores en una factura no puede superar el 100.00%%.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
GO

-- ----------------------------------------------------------------------------
-- TRIGGER 2: Integridad de la cadena de supervisión
-- "debe impedir que un supervisor quede registrado como su propio jefe y que
--  se formen ciclos en la línea de mando (por ejemplo, que una persona dependa
--  de otra y esta, directa o indirectamente, termine dependiendo de la primera)."
-- ----------------------------------------------------------------------------
CREATE OR ALTER TRIGGER comisiones.trg_IntegridadCadenaSupervision
ON comisiones.Supervisor
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Regla directa: ningún supervisor puede ser su propio jefe
    IF EXISTS (
        SELECT 1
        FROM inserted
        WHERE id_supervisor = id_supervisor_jefe
    )
    BEGIN
        RAISERROR('Error de Jerarquía: Un supervisor no puede ser registrado como su propio jefe.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    -- 2. Regla indirecta (ciclos recursivos): Recorrer la cadena ascendente
    -- Si un supervisor en inserted alcanza a sí mismo en su línea de mando, hay ciclo.
    IF EXISTS (
        SELECT 1 FROM inserted WHERE id_supervisor_jefe IS NOT NULL
    )
    BEGIN
        DECLARE @HayCiclo BIT = 0;

        ;WITH CadenaSupervision AS
        (
            -- Nivel inicial: los supervisores modificados/insertados
            SELECT
                i.id_supervisor AS id_raiz,
                i.id_supervisor_jefe AS id_ancestro,
                1 AS nivel
            FROM inserted i
            WHERE i.id_supervisor_jefe IS NOT NULL

            UNION ALL

            -- Nivel recursivo: subiendo en la jerarquía
            SELECT
                cs.id_raiz,
                s.id_supervisor_jefe AS id_ancestro,
                cs.nivel + 1
            FROM CadenaSupervision cs
            INNER JOIN comisiones.Supervisor s
                ON cs.id_ancestro = s.id_supervisor
            WHERE s.id_supervisor_jefe IS NOT NULL
              AND cs.id_raiz <> cs.id_ancestro -- Detener recursión si se cierra el ciclo
              AND cs.nivel < 50 -- Protección contra desbordamiento de recursión
        )
        SELECT TOP 1 @HayCiclo = 1
        FROM CadenaSupervision
        WHERE id_raiz = id_ancestro;

        IF @HayCiclo = 1
        BEGIN
            RAISERROR('Error de Jerarquía: Se detectó un ciclo en la línea de mando de supervisión. La asignación ha sido rechazada.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END;
    END;
END;
GO

-- ----------------------------------------------------------------------------
-- TRIGGER 3: Recupero por devolución
-- "cuando una factura se anula (devolución) y el plan bajo el cual se reconoció
--  la comisión admite descuentos, debe retraer del cálculo de comisiones la
--  parte que ya se había reconocido a quienes participaron en esa factura."
-- ----------------------------------------------------------------------------
CREATE OR ALTER TRIGGER comisiones.trg_RecuperoPorDevolucion
ON comisiones.Factura
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Identificar facturas que acaban de ser anuladas
    IF UPDATE(situacion)
    BEGIN
        DECLARE @FacturasAnuladas TABLE (id_factura INT);

        INSERT INTO @FacturasAnuladas (id_factura)
        SELECT i.id_factura
        FROM inserted i
        INNER JOIN deleted d ON i.id_factura = d.id_factura
        WHERE i.situacion = 'Anulada' AND d.situacion <> 'Anulada';

        IF EXISTS (SELECT 1 FROM @FacturasAnuladas)
        BEGIN
            -- Tabla de montos a retraer por cálculo y persona
            DECLARE @Retracciones TABLE (
                id_calculo         INT,
                id_factura         INT,
                monto_propio       DECIMAL(14,2),
                monto_supervision  DECIMAL(14,2)
            );

            -- Se evalúan los detalles de cálculo que provienen de planes con admite_descuento = 1
            INSERT INTO @Retracciones (id_calculo, id_factura, monto_propio, monto_supervision)
            SELECT
                cd.id_calculo,
                cd.id_factura,
                SUM(CASE WHEN cd.tipo_origen = 'VENTA_DIRECTA' THEN cd.comision_generada ELSE 0 END) AS monto_propio,
                SUM(CASE WHEN cd.tipo_origen = 'RECONOCIMIENTO_SUP' THEN cd.comision_generada ELSE 0 END) AS monto_supervision
            FROM comisiones.CalculoDetalle cd
            INNER JOIN @FacturasAnuladas fa ON cd.id_factura = fa.id_factura
            INNER JOIN comisiones.Factura f ON cd.id_factura = f.id_factura
            INNER JOIN comisiones.FacturaParticipacion fp
                ON cd.id_factura = fp.id_factura AND (cd.id_rol IS NULL OR cd.id_rol = fp.id_rol)
            INNER JOIN comisiones.AsignacionPlan ap
                ON fp.id_vendedor = ap.id_vendedor
                AND fp.id_rol = ap.id_rol
                AND f.fecha_emision >= ap.fecha_inicio_vigor
                AND (ap.fecha_fin_vigor IS NULL OR f.fecha_emision <= ap.fecha_fin_vigor)
            INNER JOIN comisiones.PlanComision pc
                ON ap.id_plan = pc.id_plan
            WHERE pc.admite_descuento = 1
              AND cd.tipo_origen IN ('VENTA_DIRECTA', 'RECONOCIMIENTO_SUP')
            GROUP BY cd.id_calculo, cd.id_factura;

            -- Registrar fila de ajuste de devolución en CalculoDetalle con signo negativo
            INSERT INTO comisiones.CalculoDetalle
            (
                id_calculo,
                id_factura,
                id_rol,
                base_comisionable,
                tasa_aplicada,
                participacion_aplicada,
                comision_generada,
                tipo_origen
            )
            SELECT
                r.id_calculo,
                r.id_factura,
                NULL,
                0,
                0,
                0,
                -1 * (r.monto_propio + r.monto_supervision),
                'AJUSTE_DEVOLUCION'
            FROM @Retracciones r
            WHERE (r.monto_propio + r.monto_supervision) > 0;

            -- Actualizar los totales del encabezado CalculoComision deduciendo los montos devueltos
            UPDATE cc
            SET
                cc.monto_propio_ventas = CASE
                    WHEN cc.monto_propio_ventas - r.monto_propio < 0 THEN 0
                    ELSE cc.monto_propio_ventas - r.monto_propio
                END,
                cc.monto_supervision = CASE
                    WHEN cc.monto_supervision - r.monto_supervision < 0 THEN 0
                    ELSE cc.monto_supervision - r.monto_supervision
                END,
                cc.monto_total_reconocido = CASE
                    WHEN cc.monto_total_reconocido - (r.monto_propio + r.monto_supervision) < 0 THEN 0
                    ELSE cc.monto_total_reconocido - (r.monto_propio + r.monto_supervision)
                END,
                cc.estado_reconocimiento = 'Ajustado'
            FROM comisiones.CalculoComision cc
            INNER JOIN @Retracciones r ON cc.id_calculo = r.id_calculo;
        END;
    END;
END;
GO

-- ----------------------------------------------------------------------------
-- TRIGGER 4: Integridad de Asignación de Plan
-- "Solo las personas activas pueden recibir nuevas asignaciones de plan."
-- "La dupla (vendedor, rol) puede tener, a lo sumo, un plan vigente en una misma fecha."
-- ----------------------------------------------------------------------------
CREATE OR ALTER TRIGGER comisiones.trg_IntegridadAsignacionPlan
ON comisiones.AsignacionPlan
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Validar que solo personas activas reciban nuevas asignaciones de plan
    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN comisiones.Persona p ON i.id_vendedor = p.id_persona
        WHERE p.estatus <> 'Activo'
    )
    BEGIN
        RAISERROR('Error de Integridad: Solo las personas activas pueden recibir nuevas asignaciones de plan.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    -- 2. Validar que la dupla (vendedor, rol) tenga a lo sumo un plan vigente en la misma fecha (no solapamiento)
    IF EXISTS (
        SELECT 1
        FROM comisiones.AsignacionPlan a1
        INNER JOIN inserted i
            ON a1.id_vendedor = i.id_vendedor
            AND a1.id_rol = i.id_rol
            AND a1.id_asignacion_plan <> i.id_asignacion_plan
        WHERE (a1.fecha_fin_vigor IS NULL OR a1.fecha_fin_vigor >= i.fecha_inicio_vigor)
          AND (i.fecha_fin_vigor IS NULL OR i.fecha_fin_vigor >= a1.fecha_inicio_vigor)
    )
    BEGIN
        RAISERROR('Error de Integridad: La dupla (vendedor, rol) ya posee un plan vigente en el periodo especificado.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
GO

-- ============================================================================
-- 2. FUNCIÓN: comisiones.fn_CalcularBaseComisionable
-- "dada una factura y un plan, devuelva la base comisionable que resulta de
--  aplicar a esa factura los filtros definidos en dicho plan."
-- ============================================================================
CREATE OR ALTER FUNCTION comisiones.fn_CalcularBaseComisionable
(
    @id_factura INT,
    @id_plan    INT
)
RETURNS DECIMAL(14,2)
AS
BEGIN
    DECLARE @base_aplicacion VARCHAR(15);
    DECLARE @tiene_filtros INT;
    DECLARE @base_comisionable DECIMAL(14,2) = 0;

    -- Obtener la base de aplicación del plan
    SELECT @base_aplicacion = base_aplicacion
    FROM comisiones.PlanComision
    WHERE id_plan = @id_plan;

    IF @base_aplicacion IS NULL
        RETURN 0;

    -- Verificar si el plan tiene filtros configurados
    SELECT @tiene_filtros = COUNT(*)
    FROM comisiones.PlanFiltro
    WHERE id_plan = @id_plan;

    -- Cálculo según tipo de base y aplicación de filtros
    IF @tiene_filtros = 0
    BEGIN
        -- Si el plan no posee filtros, aplica la totalidad de los ítems de la factura
        SELECT @base_comisionable = CASE @base_aplicacion
            WHEN 'Ingreso'  THEN ISNULL(SUM(fd.monto), 0)
            WHEN 'Margen'   THEN ISNULL(SUM(fd.monto - (fd.cantidad * p.costo_unitario)), 0)
            WHEN 'Cantidad' THEN ISNULL(SUM(fd.cantidad), 0)
            ELSE 0
        END
        FROM comisiones.FacturaDetalle fd
        INNER JOIN comisiones.Producto p ON fd.id_producto = p.id_producto
        WHERE fd.id_factura = @id_factura;
    END
    ELSE
    BEGIN
        -- Aplican los ítems de la factura que coinciden con las restricciones de los filtros del plan
        SELECT @base_comisionable = CASE @base_aplicacion
            WHEN 'Ingreso'  THEN ISNULL(SUM(fd.monto), 0)
            WHEN 'Margen'   THEN ISNULL(SUM(fd.monto - (fd.cantidad * p.costo_unitario)), 0)
            WHEN 'Cantidad' THEN ISNULL(SUM(fd.cantidad), 0)
            ELSE 0
        END
        FROM comisiones.FacturaDetalle fd
        INNER JOIN comisiones.Producto p ON fd.id_producto = p.id_producto
        WHERE fd.id_factura = @id_factura
          AND (
              NOT EXISTS (SELECT 1 FROM comisiones.PlanFiltro WHERE id_plan = @id_plan AND tipo_filtro = 'CATEGORIA')
              OR p.categoria IN (SELECT valor_filtro FROM comisiones.PlanFiltro WHERE id_plan = @id_plan AND tipo_filtro = 'CATEGORIA')
          )
          AND (
              NOT EXISTS (SELECT 1 FROM comisiones.PlanFiltro WHERE id_plan = @id_plan AND tipo_filtro = 'PRODUCTO')
              OR p.codigo_producto IN (SELECT valor_filtro FROM comisiones.PlanFiltro WHERE id_plan = @id_plan AND tipo_filtro = 'PRODUCTO')
              OR p.nombre IN (SELECT valor_filtro FROM comisiones.PlanFiltro WHERE id_plan = @id_plan AND tipo_filtro = 'PRODUCTO')
          )
          AND (
              NOT EXISTS (SELECT 1 FROM comisiones.PlanFiltro WHERE id_plan = @id_plan AND tipo_filtro = 'MOTIVO')
              OR fd.motivo IN (SELECT valor_filtro FROM comisiones.PlanFiltro WHERE id_plan = @id_plan AND tipo_filtro = 'MOTIVO')
          );
    END;

    RETURN ISNULL(@base_comisionable, 0);
END;
GO

-- ============================================================================
-- 3. PROCEDIMIENTO ALMACENADO: comisiones.sp_CorrerCalculoComisiones
-- "procedimiento almacenado que «corra el cálculo de comisiones» para un periodo dado.
--  A partir de las facturas cobradas dentro de ese periodo y de las participaciones
--  registradas en ellas, deberá aplicar los filtros del plan vigente para cada
--  dupla (vendedor, rol)... obtener la comisión de cada vendedor y el reconocimiento
--  que perciben los supervisores sobre lo generado por sus vendedores..."
-- ============================================================================
CREATE OR ALTER PROCEDURE comisiones.sp_CorrerCalculoComisiones
    @id_periodo INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar existencia del periodo
    DECLARE @fecha_inicio DATE, @fecha_fin DATE;
    SELECT @fecha_inicio = fecha_inicio, @fecha_fin = fecha_fin
    FROM comisiones.Periodo
    WHERE id_periodo = @id_periodo;

    IF @fecha_inicio IS NULL
    BEGIN
        RAISERROR('El periodo especificado no existe.', 16, 1);
        RETURN;
    END;

    BEGIN TRANSACTION;

    BEGIN TRY
        -- 1. Limpiar cálculos previos no pagados de este periodo para permitir re-ejecución limpia
        DELETE FROM comisiones.CalculoDetalle
        WHERE id_calculo IN (
            SELECT id_calculo FROM comisiones.CalculoComision
            WHERE id_periodo = @id_periodo AND estado_reconocimiento IN ('Calculado', 'Ajustado')
        );

        DELETE FROM comisiones.CalculoComision
        WHERE id_periodo = @id_periodo AND estado_reconocimiento IN ('Calculado', 'Ajustado');

        -- 2. Tabla temporal para consolidar liquidaciones directas de vendedores
        CREATE TABLE #LiquidacionDirecta (
            id_factura               INT,
            id_vendedor              INT,
            id_rol                   INT,
            id_plan                  INT,
            tasa_comision            DECIMAL(5,2),
            porcentaje_participacion DECIMAL(5,2),
            base_comisionable        DECIMAL(14,2),
            comision_generada        DECIMAL(14,2)
        );

        -- Obtener facturas cobradas en el rango del periodo, con vendedores activos y planes vigentes
        INSERT INTO #LiquidacionDirecta
        (
            id_factura,
            id_vendedor,
            id_rol,
            id_plan,
            tasa_comision,
            porcentaje_participacion,
            base_comisionable,
            comision_generada
        )
        SELECT
            f.id_factura,
            fp.id_vendedor,
            fp.id_rol,
            ap.id_plan,
            pc.tasa_comision,
            fp.porcentaje_participacion,
            comisiones.fn_CalcularBaseComisionable(f.id_factura, ap.id_plan) AS base_comisionable,
            ROUND(
                comisiones.fn_CalcularBaseComisionable(f.id_factura, ap.id_plan)
                * (fp.porcentaje_participacion / 100.0)
                * (pc.tasa_comision / 100.0),
                2
            ) AS comision_generada
        FROM comisiones.Factura f
        INNER JOIN comisiones.FacturaParticipacion fp ON f.id_factura = fp.id_factura
        INNER JOIN comisiones.Persona per ON fp.id_vendedor = per.id_persona
        INNER JOIN comisiones.AsignacionPlan ap
            ON fp.id_vendedor = ap.id_vendedor
            AND fp.id_rol = ap.id_rol
            AND f.fecha_emision >= ap.fecha_inicio_vigor
            AND (ap.fecha_fin_vigor IS NULL OR f.fecha_emision <= ap.fecha_fin_vigor)
        INNER JOIN comisiones.PlanComision pc ON ap.id_plan = pc.id_plan
        WHERE f.situacion = 'Cobrada'
          AND f.fecha_cobro BETWEEN @fecha_inicio AND @fecha_fin
          AND per.estatus = 'Activo';

        -- 3. Tabla temporal para consolidar comisiones de supervisores
        CREATE TABLE #LiquidacionSupervision (
            id_factura               INT,
            id_supervisor            INT,
            id_vendedor              INT,
            id_rol                   INT,
            porcentaje_reconocimiento DECIMAL(5,2),
            comision_vendedor        DECIMAL(14,2),
            comision_supervisor      DECIMAL(14,2)
        );

        INSERT INTO #LiquidacionSupervision
        (
            id_factura,
            id_supervisor,
            id_vendedor,
            id_rol,
            porcentaje_reconocimiento,
            comision_vendedor,
            comision_supervisor
        )
        SELECT
            ld.id_factura,
            sv.id_supervisor,
            ld.id_vendedor,
            ld.id_rol,
            sv.porcentaje_reconocimiento,
            ld.comision_generada,
            ROUND(ld.comision_generada * (sv.porcentaje_reconocimiento / 100.0), 2) AS comision_supervisor
        FROM #LiquidacionDirecta ld
        INNER JOIN comisiones.Factura f ON ld.id_factura = f.id_factura
        INNER JOIN comisiones.SupervisorVendedor sv
            ON ld.id_vendedor = sv.id_vendedor
            AND f.fecha_cobro >= sv.fecha_inicio
            AND (sv.fecha_fin IS NULL OR f.fecha_cobro <= sv.fecha_fin)
        INNER JOIN comisiones.Persona perSup ON sv.id_supervisor = perSup.id_persona
        WHERE perSup.estatus = 'Activo';

        -- 4. Registrar encabezados en comisiones.CalculoComision para todas las personas impactadas
        DECLARE @PersonasImpactadas TABLE (id_persona INT PRIMARY KEY);

        INSERT INTO @PersonasImpactadas (id_persona)
        SELECT id_vendedor FROM #LiquidacionDirecta
        UNION
        SELECT id_supervisor FROM #LiquidacionSupervision;

        INSERT INTO comisiones.CalculoComision
        (
            id_periodo,
            id_persona,
            monto_propio_ventas,
            monto_supervision,
            monto_total_reconocido,
            estado_reconocimiento,
            fecha_calculo
        )
        SELECT
            @id_periodo,
            p.id_persona,
            ISNULL(vd.total_ventas, 0) AS monto_propio_ventas,
            ISNULL(vs.total_supervision, 0) AS monto_supervision,
            ISNULL(vd.total_ventas, 0) + ISNULL(vs.total_supervision, 0) AS monto_total_reconocido,
            'Calculado' AS estado_reconocimiento,
            GETDATE() AS fecha_calculo
        FROM @PersonasImpactadas p
        LEFT JOIN (
            SELECT id_vendedor, SUM(comision_generada) AS total_ventas
            FROM #LiquidacionDirecta
            GROUP BY id_vendedor
        ) vd ON p.id_persona = vd.id_vendedor
        LEFT JOIN (
            SELECT id_supervisor, SUM(comision_supervisor) AS total_supervision
            FROM #LiquidacionSupervision
            GROUP BY id_supervisor
        ) vs ON p.id_persona = vs.id_supervisor;

        -- 5. Registrar detalle en comisiones.CalculoDetalle para trazabilidad
        -- 5.1 Detalle por Venta Directa
        INSERT INTO comisiones.CalculoDetalle
        (
            id_calculo,
            id_factura,
            id_rol,
            base_comisionable,
            tasa_aplicada,
            participacion_aplicada,
            comision_generada,
            tipo_origen
        )
        SELECT
            cc.id_calculo,
            ld.id_factura,
            ld.id_rol,
            ld.base_comisionable,
            ld.tasa_comision,
            ld.porcentaje_participacion,
            ld.comision_generada,
            'VENTA_DIRECTA'
        FROM #LiquidacionDirecta ld
        INNER JOIN comisiones.CalculoComision cc
            ON cc.id_periodo = @id_periodo AND cc.id_persona = ld.id_vendedor;

        -- 5.2 Detalle por Reconocimiento a Supervisión
        INSERT INTO comisiones.CalculoDetalle
        (
            id_calculo,
            id_factura,
            id_rol,
            base_comisionable,
            tasa_aplicada,
            participacion_aplicada,
            comision_generada,
            tipo_origen
        )
        SELECT
            cc.id_calculo,
            ls.id_factura,
            ls.id_rol,
            ls.comision_vendedor,
            ls.porcentaje_reconocimiento,
            100.00,
            ls.comision_supervisor,
            'RECONOCIMIENTO_SUP'
        FROM #LiquidacionSupervision ls
        INNER JOIN comisiones.CalculoComision cc
            ON cc.id_periodo = @id_periodo AND cc.id_persona = ls.id_supervisor;

        DROP TABLE #LiquidacionDirecta;
        DROP TABLE #LiquidacionSupervision;

        COMMIT TRANSACTION;
        PRINT '>> Cálculo de comisiones completado con éxito para el periodo: ' + CAST(@id_periodo AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH;
END;
GO

-- ============================================================================
-- 4. PROCEDIMIENTO ALMACENADO: comisiones.sp_RegistrarPagosPeriodo
-- "procedimiento almacenado que registre los pagos correspondientes a un
--  periodo —que puede ser distinto de aquel sobre el cual se calcularon—
--  y deje debidamente actualizado el estado de cada pago."
-- ============================================================================
CREATE OR ALTER PROCEDURE comisiones.sp_RegistrarPagosPeriodo
    @id_periodo_pago      INT,
    @id_periodo_calculo   INT,
    @id_personal_finanzas INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar existencia de periodos y rol de finanzas
    IF NOT EXISTS (SELECT 1 FROM comisiones.Periodo WHERE id_periodo = @id_periodo_pago)
    BEGIN
        RAISERROR('El periodo de pago especificado no existe.', 16, 1);
        RETURN;
    END;

    IF NOT EXISTS (SELECT 1 FROM comisiones.Periodo WHERE id_periodo = @id_periodo_calculo)
    BEGIN
        RAISERROR('El periodo de cálculo especificado no existe.', 16, 1);
        RETURN;
    END;

    IF NOT EXISTS (
        SELECT 1 FROM comisiones.PersonalFinanzas pf
        INNER JOIN comisiones.Persona p ON pf.id_personal = p.id_persona
        WHERE pf.id_personal = @id_personal_finanzas AND p.estatus = 'Activo'
    )
    BEGIN
        RAISERROR('El personal de finanzas responsable no existe o no se encuentra activo.', 16, 1);
        RETURN;
    END;

    BEGIN TRANSACTION;

    BEGIN TRY
        -- Insertar los pagos correspondientes a los cálculos aprobados o calculados del periodo origen
        INSERT INTO comisiones.PagoComision
        (
            id_periodo_pago,
            id_persona,
            id_calculo,
            fecha_pago,
            monto,
            estado_pago,
            id_personal_finanzas
        )
        SELECT
            @id_periodo_pago,
            cc.id_persona,
            cc.id_calculo,
            CAST(GETDATE() AS DATE),
            cc.monto_total_reconocido,
            'Pagado',
            @id_personal_finanzas
        FROM comisiones.CalculoComision cc
        WHERE cc.id_periodo = @id_periodo_calculo
          AND cc.estado_reconocimiento IN ('Calculado', 'Aprobado', 'Ajustado')
          AND cc.monto_total_reconocido > 0;

        -- Actualizar el estado de los cálculos a 'Liquidado'
        UPDATE comisiones.CalculoComision
        SET estado_reconocimiento = 'Liquidado'
        WHERE id_periodo = @id_periodo_calculo
          AND estado_reconocimiento IN ('Calculado', 'Aprobado', 'Ajustado')
          AND monto_total_reconocido > 0;

        COMMIT TRANSACTION;
        PRINT '>> Pagos registrados exitosamente en el periodo de pago: ' + CAST(@id_periodo_pago AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrMsg, 16, 1);
    END CATCH;
END;
GO

-- ============================================================================
-- 5. VISTA: comisiones.vw_ReportePagosFinanzas
-- "vista que sirva de base al reporte de pagos que revisa finanzas y que pueda
--  presentarse para periodos semanales, mensuales, trimestrales o anuales."
-- ============================================================================
CREATE OR ALTER VIEW comisiones.vw_ReportePagosFinanzas
AS
SELECT
    -- Datos del Periodo de Pago
    perPago.id_periodo                 AS id_periodo_pago,
    perPago.codigo_periodo             AS codigo_periodo_pago,
    perPago.descripcion                AS descripcion_periodo_pago,
    perPago.tipo_periodo               AS tipo_periodo_pago,
    perPago.fecha_inicio               AS fecha_inicio_periodo_pago,
    perPago.fecha_fin                  AS fecha_fin_periodo_pago,

    -- Datos del Pago
    pg.id_pago,
    pg.fecha_pago,
    pg.monto                           AS monto_pagado,
    pg.estado_pago,

    -- Datos del Beneficiario
    perBen.id_persona                  AS id_beneficiario,
    perBen.nombre + ' ' + perBen.apellidos AS nombre_completo_beneficiario,
    perBen.correo                      AS correo_beneficiario,
    perBen.tipo_persona                AS rol_organizacional,
    perBen.estatus                     AS estatus_beneficiario,

    -- Desglose del Cálculo Origen
    cc.id_calculo                      AS id_calculo_origen,
    perCalc.codigo_periodo             AS codigo_periodo_calculado,
    perCalc.tipo_periodo               AS tipo_periodo_calculado,
    ISNULL(cc.monto_propio_ventas, 0)  AS comision_ventas_propias,
    ISNULL(cc.monto_supervision, 0)    AS comision_supervision,
    ISNULL(cc.monto_total_reconocido,0) AS total_comision_liquidada,

    -- Datos del Responsable de Finanzas
    perFin.nombre + ' ' + perFin.apellidos AS procesado_por_nombre,
    pf.cargo                           AS cargo_finanzas
FROM comisiones.PagoComision pg
INNER JOIN comisiones.Periodo perPago
    ON pg.id_periodo_pago = perPago.id_periodo
INNER JOIN comisiones.Persona perBen
    ON pg.id_persona = perBen.id_persona
LEFT JOIN comisiones.CalculoComision cc
    ON pg.id_calculo = cc.id_calculo
LEFT JOIN comisiones.Periodo perCalc
    ON cc.id_periodo = perCalc.id_periodo
INNER JOIN comisiones.PersonalFinanzas pf
    ON pg.id_personal_finanzas = pf.id_personal
INNER JOIN comisiones.Persona perFin
    ON pf.id_personal = perFin.id_persona;
GO

PRINT '>> Objetos programables (Triggers, Función, Procedimientos Almacenados y Vista) creados exitosamente.';
GO
