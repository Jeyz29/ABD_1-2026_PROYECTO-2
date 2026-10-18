-- ============================================================================
-- PROYECTO II - ADMINISTRACIÓN DE BASES DE DATOS (UCV - 1-2026)
-- EMPRESA: CompuComisiones, C.A.
-- ARCHIVO: 04_Insercion_Datos_Prueba.sql
-- DESCRIPCIÓN:
--   Inserción de datos de prueba contextualizados, realistas y no dummy.
--   Garantiza un mínimo estricto de 10 registros en cada una de las tablas
--   del modelo, con coherencia relacional completa.
-- ============================================================================

USE CompuComisiones;
GO

SET NOCOUNT ON;

PRINT '>> Iniciando carga de datos de prueba...';

-- ============================================================================
-- 1. TABLA: comisiones.Persona (32 Personas: 12 Vendedores, 10 Supervisores, 10 Finanzas)
-- ============================================================================
-- Vendedores (IDs 1 al 12)
INSERT INTO comisiones.Persona (nombre, apellidos, correo, fecha_incorporacion, tipo_persona, estatus) VALUES
('Carlos', 'Mendoza Ramos', 'carlos.mendoza@compucomisiones.com', '2023-01-15', 'VENDEDOR', 'Activo'),
('Elena', 'Vásquez Torres', 'elena.vasquez@compucomisiones.com', '2023-02-01', 'VENDEDOR', 'Activo'),
('Ricardo', 'Pérez Silva', 'ricardo.perez@compucomisiones.com', '2023-03-10', 'VENDEDOR', 'Activo'),
('Mariana', 'Gómez Castillo', 'mariana.gomez@compucomisiones.com', '2023-04-05', 'VENDEDOR', 'Activo'),
('Alejandro', 'Rojas Benítez', 'alejandro.rojas@compucomisiones.com', '2023-05-20', 'VENDEDOR', 'Activo'),
('Valeria', 'Morales Medina', 'valeria.morales@compucomisiones.com', '2023-06-12', 'VENDEDOR', 'Activo'),
('Gabriel', 'Hernández Paz', 'gabriel.hernandez@compucomisiones.com', '2023-07-01', 'VENDEDOR', 'Activo'),
('Sofía', 'Delgado Cruz', 'sofia.delgado@compucomisiones.com', '2023-08-15', 'VENDEDOR', 'Activo'),
('Daniel', 'Navarro Ortiz', 'daniel.navarro@compucomisiones.com', '2023-09-01', 'VENDEDOR', 'Activo'),
('Camila', 'Alvarado Reyes', 'camila.alvarado@compucomisiones.com', '2023-10-10', 'VENDEDOR', 'Activo'),
('Mauricio', 'Contreras Gil', 'mauricio.contreras@compucomisiones.com', '2023-11-05', 'VENDEDOR', 'Activo'),
('Patricia', 'Soto Paredes', 'patricia.soto@compucomisiones.com', '2023-12-01', 'VENDEDOR', 'Inactivo');

-- Supervisores (IDs 13 al 22)
INSERT INTO comisiones.Persona (nombre, apellidos, correo, fecha_incorporacion, tipo_persona, estatus) VALUES
('Eduardo', 'Fernández Peña', 'eduardo.fernandez@compucomisiones.com', '2022-01-10', 'SUPERVISOR', 'Activo'),
('Verónica', 'Suárez Blanco', 'veronica.suarez@compucomisiones.com', '2022-02-15', 'SUPERVISOR', 'Activo'),
('Gustavo', 'López Domínguez', 'gustavo.lopez@compucomisiones.com', '2022-03-20', 'SUPERVISOR', 'Activo'),
('Beatriz', 'Cabrera Romero', 'beatriz.cabrera@compucomisiones.com', '2022-05-01', 'SUPERVISOR', 'Activo'),
('Fernando', 'Torres Rivas', 'fernando.torres@compucomisiones.com', '2022-06-15', 'SUPERVISOR', 'Activo'),
('Adriana', 'Molina Salas', 'adriana.molina@compucomisiones.com', '2022-07-10', 'SUPERVISOR', 'Activo'),
('Javier', 'Acosta Núñez', 'javier.acosta@compucomisiones.com', '2022-08-01', 'SUPERVISOR', 'Activo'),
('Natalia', 'Guerrero Parra', 'natalia.guerrero@compucomisiones.com', '2022-09-15', 'SUPERVISOR', 'Activo'),
('Héctor', 'Vega Cárdenas', 'hector.vega@compucomisiones.com', '2022-10-20', 'SUPERVISOR', 'Activo'),
('Lucía', 'Mejía Cordero', 'lucia.mejia@compucomisiones.com', '2022-11-15', 'SUPERVISOR', 'Activo');

-- Personal de Finanzas (IDs 23 al 32)
INSERT INTO comisiones.Persona (nombre, apellidos, correo, fecha_incorporacion, tipo_persona, estatus) VALUES
('Manuel', 'Bermúdez Ochoa', 'manuel.bermudez@compucomisiones.com', '2021-05-01', 'FINANZAS', 'Activo'),
('Raquel', 'Pacheco Serrano', 'raquel.pacheco@compucomisiones.com', '2021-06-15', 'FINANZAS', 'Activo'),
('Andrés', 'Santana Vidal', 'andres.santana@compucomisiones.com', '2021-08-01', 'FINANZAS', 'Activo'),
('Mónica', 'Quintero Leal', 'monica.quintero@compucomisiones.com', '2021-09-10', 'FINANZAS', 'Activo'),
('Jorge', 'Salazar Rangel', 'jorge.salazar@compucomisiones.com', '2022-01-15', 'FINANZAS', 'Activo'),
('Carmen', 'Villegas Prado', 'carmen.villegas@compucomisiones.com', '2022-03-01', 'FINANZAS', 'Activo'),
('Tomás', 'Figueroa Ponce', 'tomas.figueroa@compucomisiones.com', '2022-04-12', 'FINANZAS', 'Activo'),
('Isabel', 'Barrios Campos', 'isabel.barrios@compucomisiones.com', '2022-07-20', 'FINANZAS', 'Activo'),
('Rodrigo', 'Palacios Vera', 'rodrigo.palacios@compucomisiones.com', '2022-09-05', 'FINANZAS', 'Activo'),
('Daniela', 'Zambrano Rosales', 'daniela.zambrano@compucomisiones.com', '2022-11-01', 'FINANZAS', 'Activo');
GO

-- ============================================================================
-- 2. TABLA: comisiones.Vendedor (12 registros)
-- ============================================================================
INSERT INTO comisiones.Vendedor (id_vendedor, cuota_ventas) VALUES
(1, 150000.00),
(2, 120000.00),
(3, 180000.00),
(4, 140000.00),
(5, 200000.00),
(6, 110000.00),
(7, 160000.00),
(8, 130000.00),
(9, 175000.00),
(10, 145000.00),
(11, 190000.00),
(12, 100000.00);
GO

-- ============================================================================
-- 3. TABLA: comisiones.Supervisor (10 registros con jerarquía multinivel)
-- Jerarquía:
--   Eduardo (13 - Director Nacional, sin jefe)
--     -> Verónica (14 - Gerente Región Capital, jefe: 13)
--          -> Gustavo (15 - Sup. Zona Financiera, jefe: 14)
--          -> Beatriz (16 - Sup. Zona Telecom, jefe: 14)
--     -> Fernando (17 - Gerente Región Central, jefe: 13)
--          -> Adriana (18 - Sup. Zona Industrial, jefe: 17)
--          -> Javier (19 - Sup. Zona Comercial, jefe: 17)
--     -> Natalia (20 - Gerente Región Occidente, jefe: 13)
--          -> Héctor (21 - Sup. Zona Petrolera, jefe: 20)
--          -> Lucía (22 - Sup. Zona Agroindustrial, jefe: 20)
-- ============================================================================
INSERT INTO comisiones.Supervisor (id_supervisor, zona, id_supervisor_jefe) VALUES
(13, 'Dirección Nacional de Ventas', NULL),
(14, 'Gerencia Regional Capital', 13),
(15, 'Zona Financiera y Banca Caracas', 14),
(16, 'Zona Telecomunicaciones e Internet', 14),
(17, 'Gerencia Regional Central', 13),
(18, 'Zona Industrial Valencia', 17),
(19, 'Zona Comercial Maracay', 17),
(20, 'Gerencia Regional Occidente', 13),
(21, 'Zona Petrolera y Energía Maracaibo', 20),
(22, 'Zona Agroindustrial Barquisimeto', 20);
GO

-- ============================================================================
-- 4. TABLA: comisiones.PersonalFinanzas (10 registros)
-- ============================================================================
INSERT INTO comisiones.PersonalFinanzas (id_personal, cargo) VALUES
(23, 'Director de Finanzas y Control de Gestión'),
(24, 'Gerente de Contabilidad y Tesorería'),
(25, 'Especialista Senior de Comisiones e Incentivos'),
(26, 'Analista Senior de Cuentas por Cobrar'),
(27, 'Coordinador de Pagos y Nómina Comercial'),
(28, 'Auditor de Procesos Financieros'),
(29, 'Analista de Operaciones de Facturación'),
(30, 'Especialista de Conciliación Bancaria'),
(31, 'Analista Junior de Compensaciones'),
(32, 'Oficial de Cumplimiento Financiero');
GO

-- ============================================================================
-- 5. TABLA: comisiones.SupervisorVendedor (12 asignaciones históricas/vigentes)
-- ============================================================================
INSERT INTO comisiones.SupervisorVendedor (id_supervisor, id_vendedor, porcentaje_reconocimiento, fecha_inicio, fecha_fin) VALUES
(15, 1, 10.00, '2024-01-01', NULL),
(15, 2, 8.50,  '2024-01-01', NULL),
(16, 3, 12.00, '2024-01-01', NULL),
(16, 4, 10.00, '2024-01-01', NULL),
(18, 5, 9.00,  '2024-01-01', NULL),
(18, 6, 7.50,  '2024-01-01', NULL),
(19, 7, 10.00, '2024-01-01', NULL),
(19, 8, 8.00,  '2024-01-01', NULL),
(21, 9, 11.50, '2024-01-01', NULL),
(21, 10, 9.50, '2024-01-01', NULL),
(22, 11, 10.00, '2024-01-01', NULL),
(22, 12, 5.00,  '2023-01-01', '2023-12-31'); -- Histórico finalizado
GO

-- ============================================================================
-- 6. TABLA: comisiones.Cliente (10 registros de empresas reales)
-- ============================================================================
INSERT INTO comisiones.Cliente (codigo_cliente, nombre, segmento_mercado) VALUES
('CLI-1001', 'Banco Mercantil C.A.', 'Banca y Servicios Financieros'),
('CLI-1002', 'Telefónica Movistar Venezuela', 'Telecomunicaciones'),
('CLI-1003', 'Empresas Polar S.A.', 'Consumo Masivo y Alimentos'),
('CLI-1004', 'Farmatodo de Venezuela', 'Comercio Minorista y Farmacias'),
('CLI-1005', 'Banesco Banco Universal', 'Banca y Servicios Financieros'),
('CLI-1006', 'Digitel Comunicaciones', 'Telecomunicaciones'),
('CLI-1007', 'Cervecería Regional', 'Bebidas y Manufactura'),
('CLI-1008', 'Seguros Caracas Pan American', 'Aseguradoras y Salud'),
('CLI-1009', 'Automercados Plaza''s', 'Supermercados y Retail'),
('CLI-1010', 'Petroregional del Lago', 'Energía e Hidrocarburos');
GO

-- ============================================================================
-- 7. TABLA: comisiones.Producto (10 productos de tecnología y software)
-- ============================================================================
INSERT INTO comisiones.Producto (codigo_producto, nombre, categoria, precio, costo_unitario) VALUES
('PRD-SW-01', 'Plataforma SaaS CompuComisiones Enterprise', 'Software SaaS', 3500.00, 1200.00),
('PRD-SW-02', 'Módulo de Analítica Predictiva Comercial', 'Software SaaS', 1500.00, 600.00),
('PRD-SW-03', 'Licencia Base de Datos SQL Server Enterprise Core', 'Licencias', 5500.00, 2500.00),
('PRD-HW-01', 'Servidor Rack Dell PowerEdge R750', 'Hardware Servidores', 9000.00, 4500.00),
('PRD-HW-02', 'Almacenamiento SAN HPE Primera 600', 'Hardware Almacenamiento', 28000.00, 9000.00),
('PRD-HW-03', 'Switch Cisco Catalyst 9300 48 Puertos PoE', 'Redes y Telecomunicaciones', 4800.00, 2800.00),
('PRD-SEC-01', 'Firewall Fortinet FortiGate 200F', 'Seguridad Informática', 5500.00, 3200.00),
('PRD-SRV-01', 'Póliza Anual de Soporte Crítico 24/7', 'Servicios Profesionales', 6500.00, 800.00),
('PRD-SRV-02', 'Consultoría de Implementación y Migración Cloud', 'Servicios Profesionales', 8500.00, 1500.00),
('PRD-SRV-03', 'Capacitación Certificada de Administradores', 'Servicios Profesionales', 1500.00, 400.00);
GO

-- ============================================================================
-- 8. TABLA: comisiones.RolVenta (10 roles comerciales)
-- ============================================================================
INSERT INTO comisiones.RolVenta (nombre_rol, descripcion) VALUES
('Originador de Negocio', 'Identifica la oportunidad de negocio y prospecta al cliente'),
('Cerrador Comercial', 'Negocia términos contractuales y logra la firma del acuerdo'),
('Account Executive', 'Atiende la cuenta corporativa de principio a fin'),
('Arquitecto Preventa', 'Diseña la solución técnica y evalúa requerimientos'),
('Consultor de Solución', 'Estructura la propuesta funcional y económica'),
('Hunter Nuevas Cuentas', 'Apertura cuentas en clientes que no tenían relación previa'),
('Farmer de Renovaciones', 'Asegura la renovación de contratos de servicio y licencias'),
('Especialista de Producto', 'Demuestra y valida técnica y comercialmente la suite'),
('Channel Manager', 'Coordina la venta a través de socios y canales integradores'),
('Key Account Manager', 'Gestiona clientes de máxima categoría y volumen estratégico');
GO

-- ============================================================================
-- 9. TABLA: comisiones.Factura (12 facturas con estados y fechas lógicas)
-- ============================================================================
INSERT INTO comisiones.Factura (numero_factura, id_cliente, fecha_emision, situacion, fecha_cobro) VALUES
('FAC-2026-001', 1, '2026-01-05', 'Cobrada', '2026-01-18'),
('FAC-2026-002', 2, '2026-01-10', 'Cobrada', '2026-01-25'),
('FAC-2026-003', 3, '2026-01-15', 'Cobrada', '2026-01-28'),
('FAC-2026-004', 4, '2026-02-02', 'Cobrada', '2026-02-15'),
('FAC-2026-005', 5, '2026-02-08', 'Cobrada', '2026-02-22'),
('FAC-2026-006', 6, '2026-02-12', 'Cobrada', '2026-02-26'),
('FAC-2026-007', 7, '2026-03-01', 'Cobrada', '2026-03-14'),
('FAC-2026-008', 8, '2026-03-05', 'Cobrada', '2026-03-20'),
('FAC-2026-009', 9, '2026-03-10', 'Cobrada', '2026-03-25'),
('FAC-2026-010', 10, '2026-03-15', 'Cobrada', '2026-03-29'),
('FAC-2026-011', 1, '2026-03-20', 'Emitida', NULL),       -- Factura recién emitida pendiente
('FAC-2026-012', 2, '2026-01-20', 'Anulada', NULL);      -- Factura anulada por devolución
GO

-- ============================================================================
-- 10. TABLA: comisiones.FacturaDetalle (22 líneas de detalle de factura)
-- ============================================================================
INSERT INTO comisiones.FacturaDetalle (id_factura, id_producto, cantidad, monto, motivo) VALUES
-- FAC 1 (Mercantil)
(1, 1, 10.00, 35000.00, 'Venta directa SaaS Enterprise'),
(1, 8, 1.00,  6500.00,  'Renovación soporte crítico'),
-- FAC 2 (Movistar)
(2, 4, 2.00,  18000.00, 'Renovación infraestructura de cómputo'),
(2, 6, 4.00,  19200.00, 'Expansión de red core'),
-- FAC 3 (Polar)
(3, 1, 5.00,  17500.00, 'Venta directa SaaS Enterprise'),
(3, 9, 1.00,  8500.00,  'Consultoría de implementación'),
-- FAC 4 (Farmatodo)
(4, 7, 3.00,  16500.00, 'Actualización de seguridad perimetral'),
(4, 8, 1.00,  5000.00,  'Renovación soporte crítico'),
-- FAC 5 (Banesco)
(5, 5, 1.00,  28000.00, 'Ampliación de almacenamiento SAN'),
(5, 3, 4.00,  22000.00, 'Licenciamiento de motor SQL Server'),
-- FAC 6 (Digitel)
(6, 4, 3.00,  27000.00, 'Adquisición infraestructura Cloud'),
(6, 6, 2.00,  9600.00,  'Expansión de red core'),
-- FAC 7 (Regional)
(7, 1, 4.00,  14000.00, 'Venta directa SaaS Enterprise'),
(7, 2, 4.00,  6000.00,  'Módulo predictivo comercial'),
-- FAC 8 (Seguros Caracas)
(8, 3, 2.00,  11000.00, 'Licenciamiento de motor SQL Server'),
(8, 7, 2.00,  11000.00, 'Actualización de seguridad perimetral'),
-- FAC 9 (Plaza''s)
(9, 1, 6.00,  21000.00, 'Venta directa SaaS Enterprise'),
(9, 10, 2.00, 3000.00,  'Capacitación de personal'),
-- FAC 10 (Petroregional)
(10, 4, 4.00, 36000.00, 'Renovación infraestructura de cómputo'),
(10, 8, 2.00, 12000.00, 'Renovación soporte crítico'),
-- FAC 11 (Emitida)
(11, 2, 5.00, 7500.00,  'Módulo predictivo comercial'),
-- FAC 12 (Anulada)
(12, 1, 2.00, 7000.00,  'Venta directa SaaS Enterprise');
GO

-- ============================================================================
-- 11. TABLA: comisiones.FacturaParticipacion (Participaciones <= 100% por factura)
-- ============================================================================
INSERT INTO comisiones.FacturaParticipacion (id_factura, id_vendedor, id_rol, porcentaje_participacion) VALUES
-- FAC 1: Carlos (Originador 60%), Elena (Cerrador 40%) -> Total 100%
(1, 1, 1, 60.00),
(1, 2, 2, 40.00),
-- FAC 2: Ricardo (Originador 50%), Mariana (Cerrador 50%) -> Total 100%
(2, 3, 1, 50.00),
(2, 4, 2, 50.00),
-- FAC 3: Carlos (Account Exec 100%) -> Total 100%
(3, 1, 3, 100.00),
-- FAC 4: Alejandro (Originador 70%), Valeria (Cerrador 30%) -> Total 100%
(4, 5, 1, 70.00),
(4, 6, 2, 30.00),
-- FAC 5: Gabriel (Originador 50%), Sofía (Cerrador 50%) -> Total 100%
(5, 7, 1, 50.00),
(5, 8, 2, 50.00),
-- FAC 6: Daniel (Account Exec 100%) -> Total 100%
(6, 9, 3, 100.00),
-- FAC 7: Camila (Originador 60%), Mauricio (Cerrador 40%) -> Total 100%
(7, 10, 1, 60.00),
(7, 11, 2, 40.00),
-- FAC 8: Carlos (Originador 50%), Ricardo (Cerrador 50%) -> Total 100%
(8, 1, 1, 50.00),
(8, 3, 2, 50.00),
-- FAC 9: Alejandro (Account Exec 100%) -> Total 100%
(9, 5, 3, 100.00),
-- FAC 10: Gabriel (Originador 60%), Daniel (Cerrador 40%) -> Total 100%
(10, 7, 1, 60.00),
(10, 9, 2, 40.00),
-- FAC 11: Elena (Hunter 100%)
(11, 2, 6, 100.00),
-- FAC 12: Carlos (Originador 100%)
(12, 1, 1, 100.00);
GO

-- ============================================================================
-- 12. TABLA: comisiones.PlanComision (10 planes con variedad de bases y descuentos)
-- ============================================================================
INSERT INTO comisiones.PlanComision (codigo_plan, nombre, tasa_comision, base_aplicacion, admite_descuento) VALUES
('PLAN-SaaS-01', 'Plan Soluciones Cloud y Software SaaS', 6.00, 'Ingreso', 1),
('PLAN-HW-01',   'Plan Hardware e Infraestructura Crítica', 3.50, 'Margen', 0),
('PLAN-REN-01',  'Plan Renovaciones de Soporte y Garantía', 4.00, 'Ingreso', 1),
('PLAN-VOL-01',  'Plan de Volumen por Unidades Entregadas', 2.00, 'Cantidad', 0),
('PLAN-MAR-01',  'Plan Alto Margen de Rentabilidad', 8.00, 'Margen', 1),
('PLAN-CORP-01', 'Plan Cuentas Corporativas Estratégicas', 5.00, 'Ingreso', 1),
('PLAN-SEC-01',  'Plan Especial de Ciberseguridad TI', 5.50, 'Ingreso', 1),
('PLAN-SRV-01',  'Plan Consultoría y Servicios Profesionales', 7.00, 'Margen', 0),
('PLAN-LIC-01',  'Plan Licenciamiento Microsoft SQL', 4.50, 'Ingreso', 1),
('PLAN-EXP-01',  'Plan Expansión Nuevos Mercados', 6.50, 'Ingreso', 0);
GO

-- ============================================================================
-- 13. TABLA: comisiones.AsignacionPlan (14 asignaciones vigentes para duplas)
-- ============================================================================
INSERT INTO comisiones.AsignacionPlan (id_vendedor, id_rol, id_plan, fecha_inicio_vigor, fecha_fin_vigor) VALUES
(1, 1, 1, '2024-01-01', NULL), -- Carlos como Originador -> Plan SaaS
(1, 3, 6, '2024-01-01', NULL), -- Carlos como Account Exec -> Plan Corporativo
(2, 2, 1, '2024-01-01', NULL), -- Elena como Cerrador -> Plan SaaS
(2, 6, 10, '2024-01-01', NULL),-- Elena como Hunter -> Plan Expansión
(3, 1, 2, '2024-01-01', NULL), -- Ricardo como Originador -> Plan Hardware
(3, 2, 9, '2024-01-01', NULL), -- Ricardo como Cerrador -> Plan Licenciamiento
(4, 2, 2, '2024-01-01', NULL), -- Mariana como Cerrador -> Plan Hardware
(5, 1, 7, '2024-01-01', NULL), -- Alejandro como Originador -> Plan Ciberseguridad
(5, 3, 6, '2024-01-01', NULL), -- Alejandro como Account Exec -> Plan Corporativo
(6, 2, 7, '2024-01-01', NULL), -- Valeria como Cerrador -> Plan Ciberseguridad
(7, 1, 2, '2024-01-01', NULL), -- Gabriel como Originador -> Plan Hardware
(8, 2, 2, '2024-01-01', NULL), -- Sofía como Cerrador -> Plan Hardware
(9, 2, 2, '2024-01-01', NULL), -- Daniel como Cerrador -> Plan Hardware
(9, 3, 2, '2024-01-01', NULL), -- Daniel como Account Exec -> Plan Hardware
(10, 1, 1, '2024-01-01', NULL),-- Camila como Originador -> Plan SaaS
(11, 2, 1, '2024-01-01', NULL);-- Mauricio como Cerrador -> Plan SaaS
GO

-- ============================================================================
-- 14. TABLA: comisiones.PlanFiltro (14 filtros ordenados por plan)
-- ============================================================================
INSERT INTO comisiones.PlanFiltro (id_plan, numero_orden, tipo_filtro, valor_filtro) VALUES
-- Plan 1 (SaaS): Filtra categoría Software SaaS y motivo
(1, 1, 'CATEGORIA', 'Software SaaS'),
(1, 2, 'MOTIVO',    'Venta directa SaaS Enterprise'),
-- Plan 2 (HW): Filtra categoría Hardware Servidores y Redes
(2, 1, 'CATEGORIA', 'Hardware Servidores'),
(2, 2, 'CATEGORIA', 'Redes y Telecomunicaciones'),
(2, 3, 'CATEGORIA', 'Hardware Almacenamiento'),
-- Plan 3 (Renovaciones): Filtra por motivo de renovación
(3, 1, 'MOTIVO',    'Renovación soporte crítico'),
-- Plan 5 (Alto Margen): Filtra por productos de alto margen
(5, 1, 'CATEGORIA', 'Software SaaS'),
(5, 2, 'CATEGORIA', 'Servicios Profesionales'),
-- Plan 6 (Corporativo): Filtra por motivo corporativo y categorías
(6, 1, 'CATEGORIA', 'Software SaaS'),
(6, 2, 'CATEGORIA', 'Licencias'),
(6, 3, 'CATEGORIA', 'Hardware Servidores'),
-- Plan 7 (Seguridad): Filtra categoría de seguridad informática
(7, 1, 'CATEGORIA', 'Seguridad Informática'),
-- Plan 9 (Licenciamiento): Filtra licencias
(9, 1, 'CATEGORIA', 'Licencias');
GO

-- ============================================================================
-- 15. TABLA: comisiones.Periodo (10 periodos: semanales, mensuales, trimestrales, anuales)
-- ============================================================================
INSERT INTO comisiones.Periodo (codigo_periodo, descripcion, tipo_periodo, fecha_inicio, fecha_fin, comentarios) VALUES
('PER-2026-M01', 'Periodo Mensual Enero 2026', 'Mensual', '2026-01-01', '2026-01-31', 'Cierre mensual de ventas Q1-M1'),
('PER-2026-M02', 'Periodo Mensual Febrero 2026', 'Mensual', '2026-02-01', '2026-02-28', 'Cierre mensual de ventas Q1-M2'),
('PER-2026-M03', 'Periodo Mensual Marzo 2026', 'Mensual', '2026-03-01', '2026-03-31', 'Cierre mensual de ventas Q1-M3'),
('PER-2026-M04', 'Periodo Mensual Abril 2026', 'Mensual', '2026-04-01', '2026-04-30', 'Cierre mensual de ventas Q2-M1'),
('PER-2026-W01', 'Semana 1 Enero 2026', 'Semanal', '2026-01-01', '2026-01-07', 'Liquidación comisiones ventas semana 1'),
('PER-2026-W02', 'Semana 2 Enero 2026', 'Semanal', '2026-01-08', '2026-01-14', 'Liquidación comisiones ventas semana 2'),
('PER-2026-W03', 'Semana 3 Enero 2026', 'Semanal', '2026-01-15', '2026-01-21', 'Liquidación comisiones ventas semana 3'),
('PER-2026-Q01', 'Primer Trimestre Q1 2026', 'Trimestral', '2026-01-01', '2026-03-31', 'Consolidado primer trimestre comercial'),
('PER-2026-Q02', 'Segundo Trimestre Q2 2026', 'Trimestral', '2026-04-01', '2026-06-30', 'Consolidado segundo trimestre comercial'),
('PER-2026-A01', 'Año Fiscal Consolidado 2026', 'Anual', '2026-01-01', '2026-12-31', 'Periodo anual corporativo de comisiones');
GO

-- ============================================================================
-- EJECUCIÓN DEL CÁLCULO DE COMISIONES PARA POBLAR TABLAS 16 Y 17
-- Se ejecuta el procedimiento almacenado oficial para Enero, Febrero y Marzo
-- ============================================================================
PRINT '>> Ejecutando sp_CorrerCalculoComisiones para Enero (Periodo 1)...';
EXEC comisiones.sp_CorrerCalculoComisiones @id_periodo = 1;

PRINT '>> Ejecutando sp_CorrerCalculoComisiones para Febrero (Periodo 2)...';
EXEC comisiones.sp_CorrerCalculoComisiones @id_periodo = 2;

PRINT '>> Ejecutando sp_CorrerCalculoComisiones para Marzo (Periodo 3)...';
EXEC comisiones.sp_CorrerCalculoComisiones @id_periodo = 3;
GO

-- ============================================================================
-- EJECUCIÓN DEL REGISTRO DE PAGOS PARA POBLAR TABLA 18
-- Se registran pagos de comisiones del Periodo de Cálculo 1 en el Periodo de Pago 2
-- procesados por el oficial de finanzas (ID 25 - Especialista Senior de Comisiones)
-- ============================================================================
PRINT '>> Ejecutando sp_RegistrarPagosPeriodo (Pago de Enero ejecutado en Febrero)...';
EXEC comisiones.sp_RegistrarPagosPeriodo
    @id_periodo_pago = 2,
    @id_periodo_calculo = 1,
    @id_personal_finanzas = 25;

PRINT '>> Ejecutando sp_RegistrarPagosPeriodo (Pago de Febrero ejecutado en Marzo)...';
EXEC comisiones.sp_RegistrarPagosPeriodo
    @id_periodo_pago = 3,
    @id_periodo_calculo = 2,
    @id_personal_finanzas = 25;
GO

-- ============================================================================
-- RESUMEN DE REGISTROS INSERTADOS POR TABLA
-- ============================================================================
SELECT 'Persona' AS Tabla, COUNT(*) AS CantidadRegistros FROM comisiones.Persona
UNION ALL
SELECT 'Vendedor', COUNT(*) FROM comisiones.Vendedor
UNION ALL
SELECT 'Supervisor', COUNT(*) FROM comisiones.Supervisor
UNION ALL
SELECT 'PersonalFinanzas', COUNT(*) FROM comisiones.PersonalFinanzas
UNION ALL
SELECT 'SupervisorVendedor', COUNT(*) FROM comisiones.SupervisorVendedor
UNION ALL
SELECT 'Cliente', COUNT(*) FROM comisiones.Cliente
UNION ALL
SELECT 'Producto', COUNT(*) FROM comisiones.Producto
UNION ALL
SELECT 'RolVenta', COUNT(*) FROM comisiones.RolVenta
UNION ALL
SELECT 'Factura', COUNT(*) FROM comisiones.Factura
UNION ALL
SELECT 'FacturaDetalle', COUNT(*) FROM comisiones.FacturaDetalle
UNION ALL
SELECT 'FacturaParticipacion', COUNT(*) FROM comisiones.FacturaParticipacion
UNION ALL
SELECT 'PlanComision', COUNT(*) FROM comisiones.PlanComision
UNION ALL
SELECT 'AsignacionPlan', COUNT(*) FROM comisiones.AsignacionPlan
UNION ALL
SELECT 'PlanFiltro', COUNT(*) FROM comisiones.PlanFiltro
UNION ALL
SELECT 'Periodo', COUNT(*) FROM comisiones.Periodo
UNION ALL
SELECT 'CalculoComision', COUNT(*) FROM comisiones.CalculoComision
UNION ALL
SELECT 'CalculoDetalle', COUNT(*) FROM comisiones.CalculoDetalle
UNION ALL
SELECT 'PagoComision', COUNT(*) FROM comisiones.PagoComision;
GO

PRINT '>> Inserción de datos de prueba finalizada exitosamente.';
GO
