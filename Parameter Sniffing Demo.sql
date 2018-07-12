
--Creación
IF OBJECT_ID('dbo.ClientesDemo', 'U') IS NOT NULL
  DROP TABLE dbo.ClientesDemo
GO

CREATE TABLE ClientesDemo
  (
   ID INT NOT NULL IDENTITY(1,1) ,
   Nombre VARCHAR(50) NOT NULL ,
   Direccion VARCHAR(50) NOT NULL ,
   Ciudad VARCHAR(20) NOT NULL ,   
   FechaCreacion DATETIME ,
   Categoria char(1) NOT NULL
   PRIMARY KEY CLUSTERED ( ID )
  )

 CREATE INDEX IX_ClientesDemo_Categoria 
ON ClientesDemo(Categoria)

 CREATE INDEX IX_ClientesDemo_Ciudad  
ON ClientesDemo(Ciudad)

--Poblado
DECLARE @row INT ;
DECLARE @string VARCHAR (80), @length INT, @code INT;
SET @row = 0;
WHILE @row < 5001 
BEGIN
   SET @row = @row + 1;

INSERT INTO [dbo].[ClientesDemo] ( 
                Nombre,
                Direccion,
                Ciudad,
			 Categoria,
                FechaCreacion)
SELECT 
    'Cliente Nubox ' +CONVERT (VARCHAR( 20),@row ),
    'Orinoco 90',
    'Santiago',
    'A',
    GETDATE()
END

WHILE @row < 8000 
BEGIN
   SET @row = @row + 1;

INSERT INTO [dbo].[ClientesDemo] ( 
                Nombre,
                Direccion,
                Ciudad,
			 Categoria,
                FechaCreacion)
SELECT 
    'Cliente Nubox Region ' +CONVERT (VARCHAR( 20),@row ),
    'Orinoco 91',
    'Viña del Mar',
    'B',
    GETDATE()
END


SET STATISTICS IO ON

--Non-Sargable Query because of Function Used in Where Clause
SELECT Ciudad
FROM  ClientesDemo
WHERE LEFT( Ciudad,1 ) = 'V';

--Sargable Query
SELECT Ciudad
FROM  ClientesDemo
WHERE Ciudad LIKE 'V%';

SET STATISTICS IO OFF


--Prueba Select Funciona Bien

SELECT C.Nombre,C.Direccion
FROM [dbo].[ClientesDemo] C
WHERE C.Categoria = 'A'

SELECT C.Nombre,C.Direccion
FROM [dbo].[ClientesDemo] C
WHERE C.Categoria = 'B'

-- Creamos SP
IF OBJECT_ID('dbo.Test_Sniffing', 'P') IS NOT NULL
  DROP PROCEDURE dbo.Test_Sniffing
GO
CREATE PROCEDURE Test_Sniffing 
 @CategoriaID   CHAR(1)
AS
--DECLARE @CategoriaAux CHAR(1)
--SELECT @CategoriaAux = @CategoriaID
SELECT C.Nombre,C.Direccion
FROM [dbo].[ClientesDemo] C
WHERE C.Categoria = @CategoriaID
--WHERE C.Categoria = @CategoriaAux
--OPTION (RECOMPILE) 
GO

--PRUEBA
DECLARE @cache_plan_handle varbinary(44)
SELECT @cache_plan_handle = c.plan_handle
FROM 
 sys.dm_exec_cached_plans c
 CROSS APPLY sys.dm_exec_sql_text(c.plan_handle) t
WHERE 
 text like 'CREATE%ClientesDemo%' 
-- Nunca correr DBCC FREEPROCCACHE en producción sin parámetros...
-- select @cache_plan_handle
DBCC FREEPROCCACHE(@cache_plan_handle)
GO

-- llamadas al procedimiento se produce parameter sniffing
DECLARE @CategoriaID CHAR(1)
SET @CategoriaID = 'A'
EXEC dbo.Test_Sniffing @CategoriaID 
GO

DECLARE @CategoriaID CHAR(1)
SET @CategoriaID = 'B'
EXEC dbo.Test_Sniffing @CategoriaID 
GO