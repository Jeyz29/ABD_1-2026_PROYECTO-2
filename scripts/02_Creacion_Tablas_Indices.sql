-- ============================================================================
-- DESCRIPCIÓN:
--   1. Creación de las 18 tablas del modelo relacional en el esquema 'comisiones'.
--   2. Todas las tablas se alojan explícitamente en el filegroup FG_COMPU_DATA.
--   3. Todos los índices de claves primarias e índices sobre atributos «nombre»
--      se crean explícitamente en el filegroup FG_COMPU_INDEX siguiendo la
--      nomenclatura requerida: <nombreAtributo>_<nombreTabla>_indx.
--   4. Restricciones de integridad referencial, dominio (CHECK), unicidad (UNIQUE)
--      y obligatoriedad (NOT NULL).
--   5. Asignación de permisos al rol 'registrador' sobre tablas de personas, facturas y participaciones.
-- ============================================================================

USE CompuComisiones;
GO

-- ============================================================================
-- 1. TABLA: comisiones.Persona (Entidad Base)
-- ============================================================================
CREATE TABLE comisiones.Persona
(
    id_persona           INT IDENTITY(1,1) NOT NULL,
    nombre               VARCHAR(100)      NOT NULL,
    apellidos            VARCHAR(100)      NOT NULL,
    correo               VARCHAR(150)      NOT NULL,
    fecha_incorporacion  DATE              NOT NULL,
    tipo_persona         VARCHAR(15)       NOT NULL,
    estatus              VARCHAR(10)       NOT NULL,

    -- Clave Primaria en FG_COMPU_INDEX
    CONSTRAINT id_persona_Persona_indx PRIMARY KEY CLUSTERED (id_persona)
        ON FG_COMPU_INDEX,

    -- Restricciones de dominio y unicidad
    CONSTRAINT UQ_Persona_correo UNIQUE (correo)
        ON FG_COMPU_INDEX,
    CONSTRAINT CK_Persona_tipo CHECK (tipo_persona IN ('VENDEDOR', 'SUPERVISOR', 'FINANZAS')),
    CONSTRAINT CK_Persona_estatus CHECK (estatus IN ('Activo', 'Inactivo')),
    CONSTRAINT CK_Persona_campos_no_vacios CHECK (
        LEN(LTRIM(RTRIM(nombre))) > 0 AND
        LEN(LTRIM(RTRIM(apellidos))) > 0 AND
        LEN(LTRIM(RTRIM(correo))) > 0
    )
) ON FG_COMPU_DATA;
GO

-- Índice sobre el atributo 'nombre' en FG_COMPU_INDEX
CREATE NONCLUSTERED INDEX nombre_Persona_indx
    ON comisiones.Persona (nombre)
    ON FG_COMPU_INDEX;
GO

-- ============================================================================
-- 2. TABLA: comisiones.Vendedor (Especialización de Persona)
-- ============================================================================
CREATE TABLE comisiones.Vendedor
(
    id_vendedor   INT            NOT NULL,
    cuota_ventas  DECIMAL(14,2)  NOT NULL,

    CONSTRAINT id_vendedor_Vendedor_indx PRIMARY KEY CLUSTERED (id_vendedor)
        ON FG_COMPU_INDEX,

    CONSTRAINT FK_Vendedor_Persona FOREIGN KEY (id_vendedor)
        REFERENCES comisiones.Persona (id_persona)
        ON DELETE CASCADE,

    CONSTRAINT CK_Vendedor_cuota CHECK (cuota_ventas >= 0)
) ON FG_COMPU_DATA;
GO

-- ============================================================================
-- 3. TABLA: comisiones.Supervisor (Especialización de Persona y Jerarquía)
-- ============================================================================
CREATE TABLE comisiones.Supervisor
(
    id_supervisor       INT           NOT NULL,
    zona                VARCHAR(100)  NOT NULL,
    id_supervisor_jefe  INT           NULL,

    CONSTRAINT id_supervisor_Supervisor_indx PRIMARY KEY CLUSTERED (id_supervisor)
        ON FG_COMPU_INDEX,

    CONSTRAINT FK_Supervisor_Persona FOREIGN KEY (id_supervisor)
        REFERENCES comisiones.Persona (id_persona)
        ON DELETE CASCADE,

    CONSTRAINT FK_Supervisor_Jefe FOREIGN KEY (id_supervisor_jefe)
        REFERENCES comisiones.Supervisor (id_supervisor),

    CONSTRAINT CK_Supervisor_zona CHECK (LEN(LTRIM(RTRIM(zona))) > 0)
) ON FG_COMPU_DATA;
GO

-- ============================================================================
-- 4. TABLA: comisiones.PersonalFinanzas (Especialización de Persona)
-- ============================================================================
CREATE TABLE comisiones.PersonalFinanzas
(
    id_personal  INT           NOT NULL,
    cargo        VARCHAR(100)  NOT NULL,

    CONSTRAINT id_personal_PersonalFinanzas_indx PRIMARY KEY CLUSTERED (id_personal)
        ON FG_COMPU_INDEX,

    CONSTRAINT FK_PersonalFinanzas_Persona FOREIGN KEY (id_personal)
        REFERENCES comisiones.Persona (id_persona)
        ON DELETE CASCADE,

    CONSTRAINT CK_PersonalFinanzas_cargo CHECK (LEN(LTRIM(RTRIM(cargo))) > 0)
) ON FG_COMPU_DATA;
GO

-- ============================================================================
-- 5. TABLA: comisiones.SupervisorVendedor (Asignación con Reconocimiento)
-- ============================================================================
CREATE TABLE comisiones.SupervisorVendedor
(
    id_asignacion_sup         INT           IDENTITY(1,1) NOT NULL,
    id_supervisor             INT           NOT NULL,
    id_vendedor               INT           NOT NULL,
    porcentaje_reconocimiento DECIMAL(5,2)  NOT NULL,
    fecha_inicio              DATE          NOT NULL,
    fecha_fin                 DATE          NULL,

    CONSTRAINT id_asignacion_sup_SupervisorVendedor_indx PRIMARY KEY CLUSTERED (id_asignacion_sup)
        ON FG_COMPU_INDEX,

    CONSTRAINT FK_SupVen_Supervisor FOREIGN KEY (id_supervisor)
        REFERENCES comisiones.Supervisor (id_supervisor),

    CONSTRAINT FK_SupVen_Vendedor FOREIGN KEY (id_vendedor)
        REFERENCES comisiones.Vendedor (id_vendedor),

    CONSTRAINT CK_SupVen_porcentaje CHECK (porcentaje_reconocimiento >= 0 AND porcentaje_reconocimiento <= 100),
    CONSTRAINT CK_SupVen_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
) ON FG_COMPU_DATA;
GO

-- ============================================================================
-- 6. TABLA: comisiones.Cliente
-- ============================================================================
CREATE TABLE comisiones.Cliente
(
    id_cliente        INT           IDENTITY(1,1) NOT NULL,
    codigo_cliente    VARCHAR(20)   NOT NULL,
    nombre            VARCHAR(150)  NOT NULL,
    segmento_mercado  VARCHAR(100)  NOT NULL,

    CONSTRAINT id_cliente_Cliente_indx PRIMARY KEY CLUSTERED (id_cliente)
        ON FG_COMPU_INDEX,

    CONSTRAINT UQ_Cliente_codigo UNIQUE (codigo_cliente)
        ON FG_COMPU_INDEX,

    CONSTRAINT CK_Cliente_campos CHECK (
        LEN(LTRIM(RTRIM(codigo_cliente))) > 0 AND
        LEN(LTRIM(RTRIM(nombre))) > 0 AND
        LEN(LTRIM(RTRIM(segmento_mercado))) > 0
    )
) ON FG_COMPU_DATA;
GO

CREATE NONCLUSTERED INDEX nombre_Cliente_indx
    ON comisiones.Cliente (nombre)
    ON FG_COMPU_INDEX;
GO

-- ============================================================================
-- 7. TABLA: comisiones.Producto
-- ============================================================================
CREATE TABLE comisiones.Producto
(
    id_producto     INT            IDENTITY(1,1) NOT NULL,
    codigo_producto VARCHAR(20)    NOT NULL,
    nombre          VARCHAR(150)   NOT NULL,
    categoria       VARCHAR(100)   NOT NULL,
    precio          DECIMAL(14,2)  NOT NULL DEFAULT 0,
    costo_unitario  DECIMAL(14,2)  NOT NULL DEFAULT 0,

    CONSTRAINT id_producto_Producto_indx PRIMARY KEY CLUSTERED (id_producto)
        ON FG_COMPU_INDEX,

    CONSTRAINT UQ_Producto_codigo UNIQUE (codigo_producto)
        ON FG_COMPU_INDEX,

    CONSTRAINT CK_Producto_precio CHECK (precio >= 0),
    CONSTRAINT CK_Producto_costo CHECK (costo_unitario >= 0),
    CONSTRAINT CK_Producto_campos CHECK (
        LEN(LTRIM(RTRIM(codigo_producto))) > 0 AND
        LEN(LTRIM(RTRIM(nombre))) > 0 AND
        LEN(LTRIM(RTRIM(categoria))) > 0
    )
) ON FG_COMPU_DATA;
GO

CREATE NONCLUSTERED INDEX nombre_Producto_indx
    ON comisiones.Producto (nombre)
    ON FG_COMPU_INDEX;
GO

-- ============================================================================
-- 8. TABLA: comisiones.RolVenta (Catálogo de Roles en Facturas)
-- ============================================================================
CREATE TABLE comisiones.RolVenta
(
    id_rol       INT           IDENTITY(1,1) NOT NULL,
    nombre_rol   VARCHAR(50)   NOT NULL,
    descripcion  VARCHAR(250)  NOT NULL,

    CONSTRAINT id_rol_RolVenta_indx PRIMARY KEY CLUSTERED (id_rol)
        ON FG_COMPU_INDEX,

    CONSTRAINT UQ_RolVenta_nombre UNIQUE (nombre_rol)
        ON FG_COMPU_INDEX,

    CONSTRAINT CK_RolVenta_campos CHECK (
        LEN(LTRIM(RTRIM(nombre_rol))) > 0 AND
        LEN(LTRIM(RTRIM(descripcion))) > 0
    )
) ON FG_COMPU_DATA;
GO

CREATE NONCLUSTERED INDEX nombre_rol_RolVenta_indx
    ON comisiones.RolVenta (nombre_rol)
    ON FG_COMPU_INDEX;
GO

-- ============================================================================
-- 9. TABLA: comisiones.Factura
-- ============================================================================
CREATE TABLE comisiones.Factura
(
    id_factura      INT          IDENTITY(1,1) NOT NULL,
    numero_factura  VARCHAR(30)  NOT NULL,
    id_cliente      INT          NOT NULL,
    fecha_emision   DATE         NOT NULL,
    situacion       VARCHAR(15)  NOT NULL,
    fecha_cobro     DATE         NULL,

    CONSTRAINT id_factura_Factura_indx PRIMARY KEY CLUSTERED (id_factura)
        ON FG_COMPU_INDEX,

    CONSTRAINT UQ_Factura_numero UNIQUE (numero_factura)
        ON FG_COMPU_INDEX,

    CONSTRAINT FK_Factura_Cliente FOREIGN KEY (id_cliente)
        REFERENCES comisiones.Cliente (id_cliente),

    CONSTRAINT CK_Factura_situacion CHECK (situacion IN ('Emitida', 'Cobrada', 'Anulada')),

    CONSTRAINT CK_Factura_cobro CHECK (
        (situacion = 'Emitida' AND fecha_cobro IS NULL) OR
        (situacion = 'Cobrada' AND fecha_cobro IS NOT NULL AND fecha_cobro >= fecha_emision) OR
        (situacion = 'Anulada' AND (fecha_cobro IS NULL OR fecha_cobro >= fecha_emision))
    ),

    CONSTRAINT CK_Factura_numero_valido CHECK (LEN(LTRIM(RTRIM(numero_factura))) > 0)
) ON FG_COMPU_DATA;
GO

-- ============================================================================
-- 10. TABLA: comisiones.FacturaDetalle (Productos en la Factura)
-- ============================================================================
CREATE TABLE comisiones.FacturaDetalle
(
    id_factura   INT            NOT NULL,
    id_producto  INT            NOT NULL,
    cantidad     DECIMAL(12,2)  NOT NULL,
    monto        DECIMAL(14,2)  NOT NULL,
    motivo       VARCHAR(100)   NOT NULL,

    -- Clave Primaria compuesta que impide repetir un producto en la misma factura
    CONSTRAINT id_factura_id_producto_FacturaDetalle_indx PRIMARY KEY CLUSTERED (id_factura, id_producto)
        ON FG_COMPU_INDEX,

    CONSTRAINT FK_FacturaDetalle_Factura FOREIGN KEY (id_factura)
        REFERENCES comisiones.Factura (id_factura)
        ON DELETE CASCADE,

    CONSTRAINT FK_FacturaDetalle_Producto FOREIGN KEY (id_producto)
        REFERENCES comisiones.Producto (id_producto),

    CONSTRAINT CK_FacturaDetalle_cantidad CHECK (cantidad > 0),
    CONSTRAINT CK_FacturaDetalle_monto CHECK (monto >= 0),
    CONSTRAINT CK_FacturaDetalle_motivo CHECK (LEN(LTRIM(RTRIM(motivo))) > 0)
) ON FG_COMPU_DATA;
GO

-- ============================================================================
-- 11. TABLA: comisiones.FacturaParticipacion (Vendedores y Roles en Factura)
-- ============================================================================
CREATE TABLE comisiones.FacturaParticipacion
(
    id_participacion         INT           IDENTITY(1,1) NOT NULL,
    id_factura               INT           NOT NULL,
    id_vendedor              INT           NOT NULL,
    id_rol                   INT           NOT NULL,
    porcentaje_participacion DECIMAL(5,2)  NOT NULL,

    CONSTRAINT id_participacion_FacturaParticipacion_indx PRIMARY KEY CLUSTERED (id_participacion)
        ON FG_COMPU_INDEX,

    CONSTRAINT FK_FacPart_Factura FOREIGN KEY (id_factura)
        REFERENCES comisiones.Factura (id_factura)
        ON DELETE CASCADE,

    CONSTRAINT FK_FacPart_Vendedor FOREIGN KEY (id_vendedor)
        REFERENCES comisiones.Vendedor (id_vendedor),

    CONSTRAINT FK_FacPart_Rol FOREIGN KEY (id_rol)
        REFERENCES comisiones.RolVenta (id_rol),

    -- Un vendedor no puede aparecer dos veces con el mismo rol en la misma factura
    CONSTRAINT UQ_Factura_Vendedor_Rol UNIQUE (id_factura, id_vendedor, id_rol)
        ON FG_COMPU_INDEX,

    CONSTRAINT CK_FacPart_porcentaje CHECK (porcentaje_participacion > 0 AND porcentaje_participacion <= 100)
) ON FG_COMPU_DATA;
GO

-- ============================================================================
-- 12. TABLA: comisiones.PlanComision (Planes de Incentivos)
-- ============================================================================
CREATE TABLE comisiones.PlanComision
(
    id_plan           INT           IDENTITY(1,1) NOT NULL,
    codigo_plan       VARCHAR(20)   NOT NULL,
    nombre            VARCHAR(100)  NOT NULL,
    tasa_comision     DECIMAL(5,2)  NOT NULL,
    base_aplicacion   VARCHAR(15)   NOT NULL,
    admite_descuento  BIT           NOT NULL DEFAULT 0,

    CONSTRAINT id_plan_PlanComision_indx PRIMARY KEY CLUSTERED (id_plan)
        ON FG_COMPU_INDEX,

    CONSTRAINT UQ_PlanComision_codigo UNIQUE (codigo_plan)
        ON FG_COMPU_INDEX,

    CONSTRAINT CK_PlanComision_tasa CHECK (tasa_comision >= 0 AND tasa_comision <= 100),
    CONSTRAINT CK_PlanComision_base CHECK (base_aplicacion IN ('Ingreso', 'Margen', 'Cantidad')),
    CONSTRAINT CK_PlanComision_nombre CHECK (LEN(LTRIM(RTRIM(nombre))) > 0)
) ON FG_COMPU_DATA;
GO

CREATE NONCLUSTERED INDEX nombre_PlanComision_indx
    ON comisiones.PlanComision (nombre)
    ON FG_COMPU_INDEX;
GO

-- ============================================================================
-- 13. TABLA: comisiones.AsignacionPlan (Asociación Dupla Vendedor-Rol a Plan)
-- ============================================================================
CREATE TABLE comisiones.AsignacionPlan
(
    id_asignacion_plan  INT   IDENTITY(1,1) NOT NULL,
    id_vendedor         INT   NOT NULL,
    id_rol              INT   NOT NULL,
    id_plan             INT   NOT NULL,
    fecha_inicio_vigor  DATE  NOT NULL,
    fecha_fin_vigor     DATE  NULL,

    CONSTRAINT id_asignacion_plan_AsignacionPlan_indx PRIMARY KEY CLUSTERED (id_asignacion_plan)
        ON FG_COMPU_INDEX,

    CONSTRAINT FK_AsigPlan_Vendedor FOREIGN KEY (id_vendedor)
        REFERENCES comisiones.Vendedor (id_vendedor),

    CONSTRAINT FK_AsigPlan_Rol FOREIGN KEY (id_rol)
        REFERENCES comisiones.RolVenta (id_rol),

    CONSTRAINT FK_AsigPlan_Plan FOREIGN KEY (id_plan)
        REFERENCES comisiones.PlanComision (id_plan),

    CONSTRAINT CK_AsigPlan_fechas CHECK (fecha_fin_vigor IS NULL OR fecha_fin_vigor >= fecha_inicio_vigor)
) ON FG_COMPU_DATA;
GO

-- ============================================================================
-- 14. TABLA: comisiones.PlanFiltro (Entidad Débil - Filtros del Plan)
-- ============================================================================
CREATE TABLE comisiones.PlanFiltro
(
    id_plan       INT           NOT NULL,
    numero_orden  INT           NOT NULL,
    tipo_filtro   VARCHAR(20)   NOT NULL,
    valor_filtro  VARCHAR(100)  NOT NULL,

    -- Clave Primaria Compuesta en FG_COMPU_INDEX
    CONSTRAINT id_plan_numero_orden_PlanFiltro_indx PRIMARY KEY CLUSTERED (id_plan, numero_orden)
        ON FG_COMPU_INDEX,

    CONSTRAINT FK_PlanFiltro_Plan FOREIGN KEY (id_plan)
        REFERENCES comisiones.PlanComision (id_plan)
        ON DELETE CASCADE,

    CONSTRAINT CK_PlanFiltro_orden CHECK (numero_orden >= 1),
    CONSTRAINT CK_PlanFiltro_tipo CHECK (tipo_filtro IN ('PRODUCTO', 'CATEGORIA', 'MOTIVO')),
    CONSTRAINT CK_PlanFiltro_valor CHECK (LEN(LTRIM(RTRIM(valor_filtro))) > 0)
) ON FG_COMPU_DATA;
GO

-- ============================================================================
-- 15. TABLA: comisiones.Periodo
-- ============================================================================
CREATE TABLE comisiones.Periodo
(
    id_periodo      INT           IDENTITY(1,1) NOT NULL,
    codigo_periodo  VARCHAR(50)   NOT NULL,
    descripcion     VARCHAR(150)  NOT NULL,
    tipo_periodo    VARCHAR(15)   NOT NULL,
    fecha_inicio    DATE          NOT NULL,
    fecha_fin       DATE          NOT NULL,
    comentarios     VARCHAR(500)  NULL,

    CONSTRAINT id_periodo_Periodo_indx PRIMARY KEY CLUSTERED (id_periodo)
        ON FG_COMPU_INDEX,

    CONSTRAINT UQ_Periodo_codigo UNIQUE (codigo_periodo)
        ON FG_COMPU_INDEX,

    CONSTRAINT CK_Periodo_tipo CHECK (tipo_periodo IN ('Semanal', 'Mensual', 'Trimestral', 'Anual')),
    CONSTRAINT CK_Periodo_fechas CHECK (
        fecha_fin >= fecha_inicio AND
        (
            (tipo_periodo = 'Semanal'    AND DATEADD(day, 1, fecha_fin) = DATEADD(week, 1, fecha_inicio)) OR
            (tipo_periodo = 'Mensual'    AND DATEADD(day, 1, fecha_fin) = DATEADD(month, 1, fecha_inicio)) OR
            (tipo_periodo = 'Trimestral' AND DATEADD(day, 1, fecha_fin) = DATEADD(month, 3, fecha_inicio)) OR
            (tipo_periodo = 'Anual'      AND DATEADD(day, 1, fecha_fin) = DATEADD(year, 1, fecha_inicio))
        )
    )
) ON FG_COMPU_DATA;
GO

-- ============================================================================
-- 16. TABLA: comisiones.CalculoComision (Encabezado de Comisiones por Persona)
-- ============================================================================
CREATE TABLE comisiones.CalculoComision
(
    id_calculo              INT            IDENTITY(1,1) NOT NULL,
    id_periodo              INT            NOT NULL,
    id_persona              INT            NOT NULL,
    monto_propio_ventas     DECIMAL(14,2)  NOT NULL DEFAULT 0,
    monto_supervision       DECIMAL(14,2)  NOT NULL DEFAULT 0,
    monto_total_reconocido  DECIMAL(14,2)  NOT NULL DEFAULT 0,
    estado_reconocimiento   VARCHAR(20)    NOT NULL,
    fecha_calculo           DATETIME       NOT NULL DEFAULT GETDATE(),

    CONSTRAINT id_calculo_CalculoComision_indx PRIMARY KEY CLUSTERED (id_calculo)
        ON FG_COMPU_INDEX,

    CONSTRAINT FK_Calculo_Periodo FOREIGN KEY (id_periodo)
        REFERENCES comisiones.Periodo (id_periodo),

    CONSTRAINT FK_Calculo_Persona FOREIGN KEY (id_persona)
        REFERENCES comisiones.Persona (id_persona),

    CONSTRAINT UQ_Calculo_Periodo_Persona UNIQUE (id_periodo, id_persona)
        ON FG_COMPU_INDEX,

    CONSTRAINT CK_Calculo_montos CHECK (
        monto_propio_ventas >= 0 AND
        monto_supervision >= 0 AND
        monto_total_reconocido >= 0
    ),

    CONSTRAINT CK_Calculo_estado CHECK (
        estado_reconocimiento IN ('Calculado', 'Aprobado', 'Ajustado', 'Liquidado')
    )
) ON FG_COMPU_DATA;
GO

-- ============================================================================
-- 17. TABLA: comisiones.CalculoDetalle (Trazabilidad por Factura)
-- ============================================================================
CREATE TABLE comisiones.CalculoDetalle
(
    id_calculo_detalle      INT            IDENTITY(1,1) NOT NULL,
    id_calculo              INT            NOT NULL,
    id_factura              INT            NOT NULL,
    id_rol                  INT            NULL,
    base_comisionable       DECIMAL(14,2)  NOT NULL,
    tasa_aplicada           DECIMAL(5,2)   NOT NULL,
    participacion_aplicada  DECIMAL(5,2)   NOT NULL,
    comision_generada       DECIMAL(14,2)  NOT NULL,
    tipo_origen             VARCHAR(25)    NOT NULL,

    CONSTRAINT id_calculo_detalle_CalculoDetalle_indx PRIMARY KEY CLUSTERED (id_calculo_detalle)
        ON FG_COMPU_INDEX,

    CONSTRAINT FK_CalcDet_Calculo FOREIGN KEY (id_calculo)
        REFERENCES comisiones.CalculoComision (id_calculo)
        ON DELETE CASCADE,

    CONSTRAINT FK_CalcDet_Factura FOREIGN KEY (id_factura)
        REFERENCES comisiones.Factura (id_factura),

    CONSTRAINT FK_CalcDet_Rol FOREIGN KEY (id_rol)
        REFERENCES comisiones.RolVenta (id_rol),

    CONSTRAINT CK_CalcDet_tipo CHECK (tipo_origen IN ('VENTA_DIRECTA', 'RECONOCIMIENTO_SUP', 'AJUSTE_DEVOLUCION'))
) ON FG_COMPU_DATA;
GO

-- ============================================================================
-- 18. TABLA: comisiones.PagoComision (Liquidación Financiera Independiente)
-- ============================================================================
CREATE TABLE comisiones.PagoComision
(
    id_pago               INT            IDENTITY(1,1) NOT NULL,
    id_periodo_pago       INT            NOT NULL,
    id_persona            INT            NOT NULL,
    id_calculo            INT            NULL,
    fecha_pago            DATE           NOT NULL,
    monto                 DECIMAL(14,2)  NOT NULL,
    estado_pago           VARCHAR(20)    NOT NULL,
    id_personal_finanzas  INT            NOT NULL,

    CONSTRAINT id_pago_PagoComision_indx PRIMARY KEY CLUSTERED (id_pago)
        ON FG_COMPU_INDEX,

    CONSTRAINT FK_Pago_Periodo FOREIGN KEY (id_periodo_pago)
        REFERENCES comisiones.Periodo (id_periodo),

    CONSTRAINT FK_Pago_Persona FOREIGN KEY (id_persona)
        REFERENCES comisiones.Persona (id_persona),

    CONSTRAINT FK_Pago_Calculo FOREIGN KEY (id_calculo)
        REFERENCES comisiones.CalculoComision (id_calculo),

    CONSTRAINT FK_Pago_Finanzas FOREIGN KEY (id_personal_finanzas)
        REFERENCES comisiones.PersonalFinanzas (id_personal),

    CONSTRAINT CK_Pago_monto CHECK (monto >= 0),
    CONSTRAINT CK_Pago_estado CHECK (estado_pago IN ('Pendiente', 'Procesado', 'Pagado', 'Rechazado', 'Anulado'))
) ON FG_COMPU_DATA;
GO

-- ============================================================================
-- ASIGNACIÓN DE PERMISOS AL ROL REGISTRADOR
-- "Los registradores pueden realizar operaciones de inserción y modificación
--  sobre las tablas de personas y de facturas, así como sobre las participaciones"
-- ============================================================================
GRANT SELECT, INSERT, UPDATE ON comisiones.Persona TO registrador;
GRANT SELECT, INSERT, UPDATE ON comisiones.Vendedor TO registrador;
GRANT SELECT, INSERT, UPDATE ON comisiones.Supervisor TO registrador;
GRANT SELECT, INSERT, UPDATE ON comisiones.PersonalFinanzas TO registrador;
GRANT SELECT, INSERT, UPDATE ON comisiones.SupervisorVendedor TO registrador;
GRANT SELECT, INSERT, UPDATE ON comisiones.Factura TO registrador;
GRANT SELECT, INSERT, UPDATE ON comisiones.FacturaDetalle TO registrador;
GRANT SELECT, INSERT, UPDATE ON comisiones.FacturaParticipacion TO registrador;
GRANT SELECT ON comisiones.Cliente TO registrador;
GRANT SELECT ON comisiones.Producto TO registrador;
GRANT SELECT ON comisiones.RolVenta TO registrador;
GRANT SELECT ON comisiones.PlanComision TO registrador;
GRANT SELECT ON comisiones.AsignacionPlan TO registrador;
GO

PRINT '>> Tablas, restricciones e índices creados exitosamente en FG_COMPU_DATA y FG_COMPU_INDEX.';
GO
