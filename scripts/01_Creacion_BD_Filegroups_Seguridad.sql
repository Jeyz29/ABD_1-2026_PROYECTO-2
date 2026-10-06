-- ============================================================================
-- DESCRIPCIÓN:
--   1. Creación dinámica de la Base de Datos con detección de rutas físicas.
--   2. Configuración de Filegroups dedicados:
--      - FG_COMPU_DATA  : Almacenamiento exclusivo de tablas (páginas de datos).
--      - FG_COMPU_INDEX : Almacenamiento exclusivo de índices.
--      * Por política, NO se almacenan objetos de usuario en el FG PRIMARY.
--   3. Configuración de modelo de recuperación FULL para soporte 24/7.
--   4. Creación de usuario sin login como propietario del esquema.
--   5. Creación del esquema 'comisiones'.
--   6. Creación de roles de seguridad: registrador, moderador y administrador.
-- ============================================================================

USE master;
GO

-- 1. Cerrar conexiones previas y eliminar la base de datos si ya existe
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'CompuComisiones')
BEGIN
    ALTER DATABASE CompuComisiones SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE CompuComisiones;
END;
GO

-- 2. Detección de rutas por defecto de datos y logs de la instancia de SQL Server
DECLARE @defaultDataPath NVARCHAR(512) = CAST(SERVERPROPERTY('InstanceDefaultDataPath') AS NVARCHAR(512));
DECLARE @defaultLogPath  NVARCHAR(512) = CAST(SERVERPROPERTY('InstanceDefaultLogPath') AS NVARCHAR(512));

-- En caso de que las propiedades retornen NULL
IF @defaultDataPath IS NULL
    SET @defaultDataPath = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\';
IF @defaultLogPath IS NULL
    SET @defaultLogPath = @defaultDataPath;

-- Asegurar barra inclinada al final
IF RIGHT(@defaultDataPath, 1) <> '\' SET @defaultDataPath = @defaultDataPath + '\';
IF RIGHT(@defaultLogPath, 1) <> '\'  SET @defaultLogPath = @defaultLogPath + '\';

DECLARE @sqlCreateDB NVARCHAR(MAX);
SET @sqlCreateDB = N'
CREATE DATABASE CompuComisiones
ON PRIMARY
(
    NAME = N''CompuComisiones_Primary'',
    FILENAME = ''' + @defaultDataPath + N'CompuComisiones_Primary.mdf'',
    SIZE = 10MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 5MB
),
FILEGROUP FG_COMPU_DATA
(
    NAME = N''CompuComisiones_Data'',
    FILENAME = ''' + @defaultDataPath + N'CompuComisiones_Data.ndf'',
    SIZE = 50MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10MB
),
FILEGROUP FG_COMPU_INDEX
(
    NAME = N''CompuComisiones_Index'',
    FILENAME = ''' + @defaultDataPath + N'CompuComisiones_Index.ndf'',
    SIZE = 30MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10MB
)
LOG ON
(
    NAME = N''CompuComisiones_Log'',
    FILENAME = ''' + @defaultLogPath + N'CompuComisiones_Log.ldf'',
    SIZE = 20MB,
    MAXSIZE = 2GB,
    FILEGROWTH = 10MB
);';

EXEC sp_executesql @sqlCreateDB;
GO

-- 3. Configurar Recovery Model FULL (requisito para operación 24/7 y respaldos continuos)
ALTER DATABASE CompuComisiones SET RECOVERY FULL;
GO

USE CompuComisiones;
GO

-- 4. Establecer FG_COMPU_DATA como filegroup por defecto para evitar objetos en PRIMARY
ALTER DATABASE CompuComisiones MODIFY FILEGROUP FG_COMPU_DATA DEFAULT;
GO

-- 5. Creación de usuario propietario del esquema SIN INICIO DE SESIÓN
-- Política: El usuario propietario no puede conectarse ni iniciar sesión.
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'usr_schema_owner')
BEGIN
    CREATE USER usr_schema_owner WITHOUT LOGIN;
END;
GO

-- 6. Creación del esquema contenedor 'comisiones' con propietario usr_schema_owner
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'comisiones')
BEGIN
    EXEC('CREATE SCHEMA comisiones AUTHORIZATION usr_schema_owner;');
END;
GO

-- 7. Creación de Roles de Base de Datos requeridos
-- - registrador: inserción y modificación sobre personas, facturas y participaciones.
-- - moderador: solo consultas sobre cualquier tabla del modelo.
-- - administrador: cualquier operación DML sobre cualquier tabla del modelo.

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'registrador' AND type = 'R')
    CREATE ROLE registrador;
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'moderador' AND type = 'R')
    CREATE ROLE moderador;
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'administrador' AND type = 'R')
    CREATE ROLE administrador;
GO

-- 8. Asignación inicial de permisos a nivel de esquema
-- Permisos del Moderador: Solo lectura sobre todo el esquema
GRANT SELECT ON SCHEMA::comisiones TO moderador;

-- Permisos del Administrador: DML completo y ejecución sobre todo el esquema
GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::comisiones TO administrador;

PRINT '>> Base de datos CompuComisiones, Filegroups y Esquema de Seguridad configurados exitosamente.';
GO
