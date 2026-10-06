# Sistema de Gestión y Liquidación de Comisiones — CompuComisiones, C.A.

> **Proyecto II — Administración de Bases de Datos (1-2026)**  
> **Universidad Central de Venezuela (UCV)**  
> **Facultad de Ciencias — Escuela de Computación**

---

## 📌 Descripción General

**CompuComisiones, C.A.** es un sistema empresarial desarrollado sobre **Microsoft SQL Server** para la automatización, cálculo, auditoría y liquidación de comisiones de ventas en estructuras multinivel y directas. 

El diseño implementa estándares avanzados de administración de bases de datos, incluyendo segregación física por **Filegroups**, control granular de seguridad por roles, modelo de recuperación **FULL** para alta disponibilidad, integridad relacional estricta y lógica de negocio encapsulada en disparadores (triggers), funciones definidas por el usuario (UDF) y procedimientos almacenados (Stored Procedures).

---

## 🏗️ Arquitectura y Diseño Físico

### 1. Segregación en Filegroups
* **`PRIMARY`**: Reservado exclusivamente para objetos y metadatos del sistema. Por política estricta, no contiene tablas ni índices de usuario.
* **`FG_COMPU_DATA`**: Contenedor exclusivo de páginas de datos para las 18 tablas del esquema `comisiones`.
* **`FG_COMPU_INDEX`**: Contenedor exclusivo para índices de claves primarias, claves foráneas y búsquedas por atributos de nombre (`<nombreAtributo>_<nombreTabla>_indx`).
* **Modelo de Recuperación**: Configurado en **FULL** para garantizar respaldos completos, diferenciales y de registro de transacciones (*Point-in-Time Recovery*).

### 2. Esquema y Seguridad
* **Esquema:** `comisiones` (propiedad de un usuario dedicado sin login `usr_schema_owner`).
* **Roles de Seguridad:**
  * `registrador`: Inserción y actualización en tablas transaccionales de personas, facturas y participaciones.
  * `moderador`: Permisos de consulta y supervisión de cálculos y estados.
  * `administrador`: Permisos de administración y ejecución de procedimientos de liquidación y mantenimiento.

---

## 📂 Estructura del Repositorio

```text
├── .gitignore
├── README.md
├── ProyectoIIABD-CompuComisiones.pdf        # Enunciado y especificaciones del proyecto
├── Justificaciones_Laboratorio5_Seguridad_Integridad.docx # Documentación de diseño y justificaciones
├── PERSONA Role and Commission-...pdf       # Especificaciones complementarias
│
├── docs/
│   ├── Metodo_De_Respaldo_CompuComisiones.pdf # Estrategia y política de respaldos
│   └── diagramas/
│       ├── diagrama_modelo_relacional.mmd     # Diagrama en formato Mermaid
│       ├── diagrama_modelo_relacional.png     # Renderizado en alta resolución
│       ├── diagrama_modelo_relacional.svg     # Formato vectorial escalable
│       └── visor_diagrama.html                # Visor interactivo web
│
└── scripts/
    ├── 01_Creacion_BD_Filegroups_Seguridad.sql # Creación de BD, Filegroups y Seguridad
    ├── 02_Creacion_Tablas_Indices.sql          # DDL de 18 tablas e índices especializados
    ├── 03_Programabilidad_Objetos.sql          # Triggers, Funciones, SPs y Vistas
    ├── 04_Insercion_Datos_Prueba.sql           # Carga de datos realistas (mínimo 10/tabla)
    ├── 05_Pruebas_Validacion.sql               # Suite de pruebas unitarias y de negocio
    └── generar_diagramas.py                    # Script generador de diagramas relacionales
```

---

## ⚙️ Componentes de Programabilidad

| Objeto | Tipo | Descripción |
| :--- | :--- | :--- |
| `trg_ControlParticipacionFactura` | **Trigger** | Garantiza que la suma de porcentajes de participación por factura no exceda el 100% y que los vendedores estén activos. |
| `trg_IntegridadCadenaSupervision` | **Trigger** | Valida la jerarquía de supervisión previniendo auto-asignación como supervisor directo y dependencias cíclicas. |
| `trg_RecuperoPorDevolucion` | **Trigger** | Maneja la anulación de facturas retractando y ajustando las comisiones calculadas asociadas. |
| `trg_IntegridadAsignacionPlan` | **Trigger** | Asegura que un vendedor solo tenga asignado un plan vigente a la vez, sin solapamientos. |
| `fn_CalcularBaseComisionable` | **UDF** | Aplica los filtros del plan (categoría, línea de producto, montos mínimos) para obtener la base neta comisionable. |
| `sp_CorrerCalculoComisiones` | **Stored Procedure** | Orquesta el cálculo integral de comisiones por periodo, aplicando porcentajes fijos y escalonados. |
| `sp_RegistrarPagosPeriodo` | **Stored Procedure** | Registra el pago y liquidación de comisiones acumuladas, actualizando estados financieros. |
| `vw_ReportePagosFinanzas` | **View** | Vista analítica multi-periodo consolidada para auditoría y reportería de finanzas. |

---

## 🚀 Guía de Despliegue y Ejecución

Ejecutar los scripts en Microsoft SQL Server (SSMS o Azure Data Studio) en orden numérico estricto:

1. **`01_Creacion_BD_Filegroups_Seguridad.sql`**  
   Crea la base de datos `CompuComisiones`, detecta dinámicamente las rutas de almacenamiento, crea los filegroups `FG_COMPU_DATA` y `FG_COMPU_INDEX`, el esquema `comisiones` y los roles.

2. **`02_Creacion_Tablas_Indices.sql`**  
   Construye las 18 tablas en `FG_COMPU_DATA`, sus restricciones (PK, FK, CHECK, UNIQUE) y ubica todos los índices en `FG_COMPU_INDEX`.

3. **`03_Programabilidad_Objetos.sql`**  
   Compila las funciones escalares/tabulares, los disparadores de integridad de negocio y los procedimientos almacenados de cálculo y pago.

4. **`04_Insercion_Datos_Prueba.sql`**  
   Inserta un conjunto de datos contextualizado y realista con más de 10 registros por tabla manteniendo integridad referencial.

5. **`05_Pruebas_Validacion.sql`**  
   Ejecuta la suite completa de pruebas:
   - Verificación de ubicación física en Filegroups (0 objetos en `PRIMARY`).
   - Casos límite y control de excepciones en triggers.
   - Cálculos y liquidaciones mediante Stored Procedures.
   - Comprobación de roles y permisos.


