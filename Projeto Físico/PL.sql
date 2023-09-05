-- BAIXAR A STEAM (CADASTRAR USUARIO) --

CREATE OR REPLACE PROCEDURE BAIXAR_STEAM () IS
CNT NUMBER;
BEGIN
	SELECT COUNT(*) + 1 INTO CNT FROM USUARIO;
	INSERT INTO USUARIO VALUES(TO_CHAR(CNT));
	DBMS_OUTPUT.PUT_LINE('STEAM BAIXADA!');
END;

-- CADASTRAR CONTA -- 

CREATE OR REPLACE PROCEDURE CADASTRAR_CONTA (USERNAME VARCHAR2, LOC_PAIS VARCHAR2, LOC_ESTADO VARCHAR2, LOC_CIDADE VARCHAR2) IS

BEGIN
    INSERT INTO CONTA VALUES (USERNAME, 0, LOC_PAIS, LOC_ESTADO, LOC_CIDADE, 0, NULL);
	DBMS_OUTPUT.PUT_LINE('CONTA CADASTRADA COM SUCESSO!');
END;

-- LOGAR CONTA EM USUARIO --

CREATE OR REPLACE PROCEDURE LOGAR (CODIGO VARCHAR2, USERNAME2 VARCHAR2, SENHA2 VARCHAR2) IS
SENHA_CONTA VARCHAR2;
BEGIN
	SELECT SENHA INTO SENHA_CONTA FROM CONTA WHERE USERNAME = USERNAME2;
	IF SENHA2 = SENHA_CONTA THEN
		INSERT INTO TEM_ACESSO VALUES(USERNAME2, CODIGO);
		DBMS_OUTPUT.PUT_LINE('LOGIN EFETUADO COM SUCESSO!');
	ELSE
		DBMS_OUTPUT.PUT_LINE('USERNAME OU SENHA INVÁLIDO');
	END IF;
END;

-- ADICIONAR CRÉDITOS --

CREATE OR REPLACE PROCEDURE COMPRAR_CREDITO (USERNAME2 VARCHAR2, VALOR NUMBER) IS

BEGIN
    UPDATE CONTA SET SALDO = VALOR WHERE USERNAME = USERNAME2; 
	DBMS_OUTPUT.PUT_LINE('CRÉDITOS ADICIONADOS! DINHEIRO NA MÃO, CALCINHA NO CHÃO.');
END;

-- VINCULAR REDE SOCIAL --

CREATE OR REPLACE PROCEDURE VINCULAR_REDE (USERNAME2 VARCHAR2, USERNAME2_REDE VARCHAR2) IS

BEGIN
    UPDATE CONTA SET USERNAME_REDE = USERNAME2_REDE WHERE USERNAME = USERNAME2; 
	DBMS_OUTPUT.PUT_LINE('CONTAS VINCULADAS!');
END;

-- ADICIONAR AMIGOS --

CREATE OR REPLACE PROCEDURE FAZER_AMIZADE (USERNAME1 VARCHAR2, USERNAME2 VARCHAR2) IS
	DATA DATE;
	CNT NUMBER;
BEGIN
	SELECT CURRENT_DATE INTO DATA FROM DUAL;

	SELECT	COUNT(*) INTO CNT FROM AMIGO A WHERE (A.USERNAME1 = USERNAME1 AND A.USERNAME2 = USERNAME2) OR (A.USERNAME1 = USERNAME2 AND A.USERNAME2 = USERNAME1);

    IF CNT = 0 THEN
    	INSERT INTO AMIGO VALUES(USERNAME1, USERNAME2, DATA);
		DBMS_OUTPUT.PUT_LINE('AMIZADE FEITA :D');
	ELSE
		DBMS_OUTPUT.PUT_LINE('VOCES JÁ SÃO AMIGOS!');
	END IF;
END;

-- CADASTRAR EMPRESA -- 

CREATE OR REPLACE PROCEDURE CADASTRAR_EMPRESA (CNPJ VARCHAR2, NOME VARCHAR2) IS

BEGIN
    INSERT INTO EMPRESA VALUES (CNPJ, NOME);
	DBMS_OUTPUT.PUT_LINE('EMPRESA CADASTRADA COM SUCESSO!');
END;

-- PUBLICAR APLICATIVO --

CREATE OR REPLACE TYPE myarray IS VARRAY(10) OF VARCHAR2(20);

CREATE OR REPLACE PROCEDURE publicar_app (NOME VARCHAR2, CNPJ VARCHAR2, CATEGORIAS myarray, PRECO NUMBER, TIPO VARCHAR2) IS
	DATA DATE;
	CNT NUMBER;

BEGIN
	SELECT COUNT(*) INTO CNT FROM EMPRESA E WHERE E.CNPJ = CNPJ;

	IF CNT > 0 THEN
		SELECT CURRENT_DATE INTO DATA FROM DUAL;
		INSERT INTO APLICATIVO VALUES (NOME, PRECO, DATA, CNPJ, TIPO);

		FOR I IN 1 .. CATEGORIAS.COUNT LOOP
			INSERT INTO CATEGORIA VALUES (NOME, CATEGORIAS(I));
		END LOOP;
	ELSE
		DBMS_OUTPUT.PUT_LINE('CNPJ ERRADO, CARAI! AJEITA ISSO AI!');
	END IF;

END;

-- COMPRAR APLICATIVO --

CREATE OR REPLACE PROCEDURE COMPRAR_APP (NOME_APP VARCHAR2, USERNAME2 VARCHAR2) IS
	PRECO_APP NUMBER;
	VALOR NUMBER;
	DATA DATE;

BEGIN
	SELECT CURRENT_DATE INTO DATA FROM DUAL;
	SELECT PRECO_ATUAL INTO PRECO_APP FROM APLICATIVO A WHERE A.NOME = NOME_APP;
	SELECT C.SALDO INTO VALOR FROM CONTA C WHERE C.USERNAME = USERNAME2 AND ROWNUM = 1;

	IF VALOR >= PRECO_APP THEN
		INSERT INTO COMPRA VALUES (USERNAME2, NOME_APP, PRECO_APP, DATA); --ADICIONA NA BIBLIOTECA
		UPDATE CONTA SET SALDO = (SALDO - PRECO_APP) WHERE USERNAME = USERNAME2; --ATUALIZA O SALDO
		DBMS_OUTPUT.PUT_LINE('APLICATIVO COMPRADO! ABRE LOGO AÍ!');
	ELSE
		DBMS_OUTPUT.PUT_LINE('SALDO INSUFICIENTE! FAZ O PIX!');
	END IF;
END;

-- EXECUTAR APLICATIVO--

CREATE OR REPLACE PROCEDURE EXECUTAR_APP (COD_USER VARCHAR2, USERNAME_LOG VARCHAR2, NOME_APP VARCHAR2) IS 
    DATA_INICIO DATE;
	CNT NUMBER;
	USO NUMBER(1);
BEGIN
	SELECT EM_USO INTO USO FROM CONTA WHERE USERNAME = USERNAME_LOG;

	IF USO = 0 THEN
        SELECT COUNT(*) INTO CNT FROM (SELECT NOME FROM COMPRA WHERE NOME = NOME_APP AND USERNAME IN 
    								  (SELECT USERNAME FROM CONTA WHERE USERNAME IN
    								  (SELECT USERNAME FROM TEM_ACESSO WHERE CODIGO = COD_USER)));
    	IF (CNT > 0) THEN
        	SELECT CURRENT_DATE INTO DATA_INICIO FROM DUAL;
    		INSERT INTO HISTORICO_EXEC VALUES(COD_USER, USERNAME_LOG, NOME_APP, DATA_INICIO, NULL);
    		UPDATE CONTA SET EM_USO = 1 WHERE USERNAME = USERNAME_LOG;
        	DBMS_OUTPUT.PUT_LINE('Aplicativo está executando.');
    	ELSE
        	DBMS_OUTPUT.PUT_LINE('Você não tem acesso à esse aplicativo.');
    	END IF;
	ELSE
    	DBMS_OUTPUT.PUT_LINE('Conta ' || USERNAME_LOG || ' já está em uso.');
	END IF;
END;

-- FECHAR APLICATIVO --

CREATE OR REPLACE PROCEDURE FECHAR_APP (USERNAME2 VARCHAR2) IS 
	DATA DATE; 
BEGIN 
    SELECT CURRENT_DATE INTO DATA FROM DUAL; 
    UPDATE HISTORICO_EXEC SET FIM = DATA WHERE USERNAME2 = USERNAME_LOGADO AND FIM IS NULL;  
    UPDATE CONTA SET EM_USO = 0 WHERE USERNAME = USERNAME2; 
END;

-- HORAS JOGADAS --

CREATE OR REPLACE FUNCTION HORAS_JOGADAS (USERNAME VARCHAR2, NOME VARCHAR2) RETURN NUMBER IS
    SOMA NUMBER := 0;
	DIFF NUMBER;
	CURSOR CUR IS (SELECT 24 * (FIM - INICIO) FROM HISTORICO_EXEC WHERE USERNAME_LOGADO = USERNAME AND NOME_APP = NOME);
BEGIN
    OPEN CUR;
	FETCH CUR INTO DIFF;
    WHILE CUR%FOUND LOOP
		SOMA := SOMA + DIFF;
		FETCH CUR INTO DIFF;
    END LOOP;
	RETURN SOMA;
END;

-- RECEITA GERAL('%') / DE UMA EMPRESA --

CREATE OR REPLACE FUNCTION RECEITA (CNPJ2 VARCHAR2) RETURN NUMBER IS
    SOMA NUMBER := 0;
	VALOR NUMBER;
	CURSOR CUR IS (SELECT PRECO_COMPRA FROM COMPRA WHERE NOME IN (SELECT A.NOME FROM APLICATIVO A WHERE A.CNPJ LIKE CNPJ2));
BEGIN
    OPEN CUR;
	FETCH CUR INTO VALOR;
    WHILE CUR%FOUND LOOP
		DBMS_OUTPUT.PUT_LINE(soma);
		SOMA := SOMA + VALOR;
		FETCH CUR INTO VALOR;
    END LOOP;
	RETURN SOMA;
END;

