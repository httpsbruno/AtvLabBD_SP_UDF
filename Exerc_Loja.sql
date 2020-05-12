CREATE DATABASE Exerc_Loja
GO
USE Exerc_Loja

CREATE TABLE Cliente(
codigo   INT IDENTITY,
nome     VARCHAR(120),
telefone VARCHAR(11)
PRIMARY KEY (codigo)
)

CREATE TABLE Produto(
codigo INT IDENTITY(1000,1),
nome VARCHAR(100),
valor_uni DECIMAL(7,2)
PRIMARY KEY(codigo)
)

CREATE TABLE Venda(
cod_cli INT NOT NULL,
cod_pro INT NOT NULL,
data_hora DATETIME,
quantidade INT,
valor_uni DECIMAL(7,2),
valor_total DECIMAL(7,2)
PRIMARY KEY (cod_cli,cod_pro,data_hora)
FOREIGN KEY (cod_cli) REFERENCES Cliente(codigo),
FOREIGN KEY (cod_pro) REFERENCES Produto(codigo)
)

CREATE TABLE Bonus(
id INT IDENTITY,
valor INT,
premio VARCHAR(100)
PRIMARY KEY (id)
)

CREATE PROCEDURE sp_inserevenda (@cod_cliente INT, @cod_produto INT, @qtd INT, 
	@saida VARCHAR(100) OUTPUT)
AS
	DECLARE @c_produto INT,
			@c_cliente INT,
			@v_uni DECIMAL(7,2),
			@v_tot DECIMAL(7,2)

	SET @c_produto = (SELECT COUNT(*) FROM Produto 	WHERE codigo = @cod_produto)
	SET @c_cliente = (SELECT COUNT(*) FROM Cliente 	WHERE codigo = @cod_cliente)
	IF (@c_produto > 0 AND @c_cliente >0)
	BEGIN
		SELECT @v_uni = valor_uni FROM Produto WHERE codigo = @cod_produto
		SET @v_tot = @v_uni * @qtd

		INSERT INTO venda VALUES
			(@cod_cliente, @cod_produto,GETDATE(), @qtd, @v_uni, @v_tot)
			SET @saida = 'Venda cadastrada com sucesso !'
	END
	ELSE
	BEGIN
		RAISERROR ('Cliente ou Produto não cadastrado', 16, 1)
	END

	
DECLARE @resp VARCHAR(100)
EXEC sp_inserevenda  1, 1000, 3, @resp OUTPUT
PRINT @resp


----Retorna tabela de clientes e seus respectivos bônus
CREATE FUNCTION fn_tblBonusCliente() RETURNS @tabela TABLE(
cod_cli      INT,
nome_cli    VARCHAR(120),
total_gasto DECIMAL(7,2),
valor_bonus INT,
premio      VARCHAR(100),
sobra_bonus INT
)
AS
BEGIN
	INSERT @tabela(cod_cli,nome_cli,total_gasto)
		SELECT Cliente.codigo, Cliente.nome, SUM(valor_total) AS total_gasto 
		FROM Cliente INNER JOIN Venda ON Venda.cod_cli = Cliente.codigo 
		GROUP BY Cliente.codigo, Cliente.nome
	
	UPDATE @tabela SET valor_bonus = CAST(total_gasto AS INT)
	UPDATE @tabela SET premio = (SELECT premio FROM Bonus WHERE valor = ( select MAX(valor) FROM Bonus WHERE valor <= valor_bonus))
	UPDATE @tabela SET sobra_bonus = (valor_bonus -(select MAX(valor) FROM Bonus WHERE valor <= valor_bonus))
	RETURN 
END

SELECT * FROM fn_tblBonusCliente()
