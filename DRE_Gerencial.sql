/*
    PROJETO: 
    Extração de dados do ERP para elaboração de DRE Gerencial e criação de dashboards dentro do ERP
    
    MÉTODO:
    Usando CTE (Common Table Expression) de modo a permitir a reutilização de blocos da consulta por seus ALIAS

    RESULTADO:
    Facilitação do cálculo de indicadores gerenciais 
*/

WITH dre AS 
    (
    SELECT * FROM
    
        (
        SELECT DISTINCT
        
            cab.CODEMP AS EMPRESA, 
            
            SUM(
                CASE WHEN cab.CODTIPOPER IN ('1100', '1111', '1120', '1126', '1128', 
                                             '1130', '1131', '1706', '1708', '1709', 
                                             '1710', '1711', '1714', '1720', '1799', '8') 
                THEN cab.VLRNOTA ELSE 0 END) AS FATURAMENTO,
                    
            SUM(CASE WHEN cab.CODTIPOPER IN ('1100', '1111', '1799') THEN cab.VLRNOTA ELSE 0 END) AS MAQ_INTERNO,
            SUM(CASE WHEN cab.CODTIPOPER IN ('1706', '1708') THEN cab.VLRNOTA ELSE 0 END) AS MAQ_EXPORT,
            SUM(CASE WHEN cab.CODTIPOPER IN ('1126', '1130', '1131', '1709', '8') THEN cab.VLRNOTA ELSE 0 END) AS PECAS,
            SUM(CASE WHEN cab.CODTIPOPER IN ('1710', '1711', '1714') THEN cab.VLRNOTA ELSE 0 END) AS SERVICOS,
            SUM(CASE WHEN cab.CODTIPOPER IN ('1120', '1720') THEN cab.VLRNOTA ELSE 0 END) AS SUCATA_IMOB_OUTROS,
        
            (
            SELECT DISTINCT
            SUM(CASE WHEN cab.TIPMOV = 'V' THEN cab.VLRICMS ELSE 0 END)
            FROM TGFCAB cab
            WHERE cab.CODEMP = 1
            AND (cab.DTFATUR BETWEEN '01/01/2023' AND '31/12/2023')
            AND cab.TIPMOV = 'V'
            AND cab.STATUSNOTA = 'L'
            ) AS ICMS,
            
            (
            SELECT DISTINCT
            SUM(CASE WHEN cab.TIPMOV = 'V' THEN cab.VLRIPI ELSE 0 END)
            FROM TGFCAB cab
            WHERE cab.CODEMP = 1
            AND (cab.DTFATUR BETWEEN '01/01/2023' AND '31/12/2023')
            AND cab.TIPMOV = 'V'
            AND cab.STATUSNOTA = 'L'
            ) AS IPI,
            
            (
            SELECT DISTINCT
            SUM(CASE WHEN cab.CODTIPOPER IN ('1100', '1111', '1120', '1125', '1126', '1128', '1131', '1709', '1710', '1711', '1720') AND cab.TIPMOV = 'V' THEN cab.VLRNOTA * 0.0065 ELSE 0 END)
            FROM TGFCAB cab
            WHERE cab.CODEMP = 1
            AND (cab.DTFATUR BETWEEN '01/01/2023' AND '31/12/2023')
            AND cab.TIPMOV = 'V'
            AND cab.STATUSNOTA = 'L'
            ) AS PIS,
            
            (
            SELECT DISTINCT
            SUM(CASE WHEN cab.CODTIPOPER IN ('1100', '1111', '1120', '1125', '1126', '1128', '1131', '1709', '1710', '1711', '1720') AND cab.TIPMOV = 'V' THEN cab.VLRNOTA * 0.03 ELSE 0 END)
            FROM TGFCAB cab
            WHERE cab.CODEMP = 1
            AND (cab.DTFATUR BETWEEN '01/01/2023' AND '31/12/2023')
            AND cab.TIPMOV = 'V'
            AND cab.STATUSNOTA = 'L'
            ) AS COFINS,
            
            (
            SELECT DISTINCT
            SUM(CASE WHEN cab.CODTIPOPER IN ('1710', '1711', '1714') AND cab.TIPMOV = 'V' THEN cab.VLRNOTA * 0.03 ELSE 0 END)
            FROM TGFCAB cab
            WHERE cab.CODEMP = 1
            AND (cab.DTFATUR BETWEEN '01/01/2023' AND '31/12/2023')
            AND cab.TIPMOV = 'V'
            ) AS ISS,
            
            (
            SELECT DISTINCT
            SUM(CASE WHEN cab.CODTIPOPER <> 203 THEN ite.VLRTOT ELSE ite.VLRTOT - ite.VLRICMS END) AS CPV
            FROM TGFCAB cab
            INNER JOIN TGFITE ite ON cab.NUNOTA = ite.NUNOTA
            WHERE cab.CODEMP = 1
            AND cab.TIPMOV = 'C'
            AND	(ite.AD_CODNAT IN (1020101))
            AND (cab.DTFATUR BETWEEN '01/01/2023' AND '31/12/2023')
            ) AS MP,
    
            (
            SELECT DISTINCT 
            SUM(CASE WHEN ite.AD_CODNAT IN (1020102, 1020103, 1020104, 1020199) THEN ite.VLRTOT - ite.VLRICMS ELSE 0 END) 
            FROM TGFCAB cab
            INNER JOIN TGFITE ite ON cab.NUNOTA = ite.NUNOTA
            WHERE cab.CODEMP = 1
            AND cab.TIPMOV = 'C'
            AND (cab.DTFATUR BETWEEN '01/01/2023' AND '31/12/2023')
            ) AS MAT_CONS_IND_SERV_OUT,
    
            (
            SELECT DISTINCT
            SUM(ite.VLRTOT - ite.VLRICMS)
            FROM TGFCAB cab, TGFITE ite
            WHERE cab.CODEMP = 1
            AND cab.CODNAT IN (1020201, 1020202)
            AND (cab.DTFATUR between '01/01/2023' and '31/12/2023')
            AND ite.NUNOTA = cab.NUNOTA
            ) AS FRETES,
            
            (
            SELECT DISTINCT
            SUM(CASE WHEN fin.CODNAT LIKE ('103%') THEN fin.VLRBAIXA ELSE 0 END)
            FROM TGFFIN fin
            WHERE fin.CODEMP = 1
            AND (fin.DHBAIXA BETWEEN '01/01/2023' AND '31/12/2023')
            AND fin.RECDESP = -1
            AND fin.PROVISAO = 'N'
            AND fin.VLRBAIXA <> 0
            ) AS DESP_COML,
            
            (
            SELECT DISTINCT
            SUM(CASE WHEN fin.CODNAT LIKE ('104%') 
            THEN fin.VLRBAIXA ELSE 0 END)
            FROM TGFFIN fin
            WHERE fin.CODEMP = 1
            AND (fin.DHBAIXA BETWEEN '01/01/2023' AND '31/12/2023')
            AND fin.RECDESP = -1
            AND fin.PROVISAO = 'N'
            AND fin.VLRBAIXA > 0
            AND fin.VLRCHEQUE IS NOT NULL
            ) AS PESSOAS,
            
            (
            SELECT DISTINCT
            SUM(CASE WHEN fin.CODNAT LIKE ('10501%') 
            THEN fin.VLRBAIXA ELSE 0 END)
            FROM TGFFIN fin
            WHERE fin.CODEMP = 1
            AND (fin.DHBAIXA BETWEEN '01/01/2023' AND '31/12/2023')
            AND fin.RECDESP = -1
            AND fin.PROVISAO = 'N'
            AND fin.VLRBAIXA > 0
            AND fin.VLRCHEQUE IS NOT NULL
            ) AS UTILIDADES,
            
            (
            SELECT DISTINCT
            SUM(CASE WHEN fin.CODNAT LIKE ('10502%') 
            THEN fin.VLRBAIXA ELSE 0 END)
            FROM TGFFIN fin
            WHERE fin.CODEMP = 1
            AND (fin.DHBAIXA BETWEEN '01/01/2023' AND '31/12/2023')
            AND fin.RECDESP = -1
            AND fin.PROVISAO = 'N'
            AND fin.VLRBAIXA > 0
            AND fin.VLRCHEQUE IS NOT NULL
            ) AS DESP_IMOVEIS,
            
            (
            SELECT DISTINCT
            SUM(CASE WHEN fin.CODNAT LIKE ('10503%') 
            THEN fin.VLRBAIXA ELSE 0 END)
            FROM TGFFIN fin
            WHERE fin.CODEMP = 1
            AND (fin.DHBAIXA BETWEEN '01/01/2023' AND '31/12/2023')
            AND fin.RECDESP = -1
            AND fin.PROVISAO = 'N'
            AND fin.VLRBAIXA > 0
            AND fin.VLRCHEQUE IS NOT NULL
            ) AS DESP_VEICULOS,
            
            (
            SELECT DISTINCT
            SUM(CASE WHEN fin.CODNAT LIKE ('10504%') 
            THEN fin.VLRBAIXA ELSE 0 END)
            FROM TGFFIN fin
            WHERE fin.CODEMP = 1
            AND (fin.DHBAIXA BETWEEN '01/01/2023' AND '31/12/2023')
            AND fin.RECDESP = -1
            AND fin.PROVISAO = 'N'
            AND fin.VLRBAIXA > 0
            AND fin.VLRCHEQUE IS NOT NULL
            ) AS SERV_TERC,
            
            (
            SELECT DISTINCT
            SUM(CASE WHEN fin.CODNAT LIKE ('106%')
            THEN fin.VLRBAIXA ELSE 0 END)
            FROM TGFFIN fin
            WHERE fin.CODEMP = 1
            AND (fin.DHBAIXA BETWEEN '01/01/2023' AND '31/12/2023')
            AND fin.RECDESP = -1
            AND fin.PROVISAO = 'N'
            AND fin.VLRBAIXA > 0
            AND fin.VLRCHEQUE IS NOT NULL
            ) AS GASTOS_GERAIS,
        
            (
            SELECT DISTINCT
            SUM(CASE WHEN fin.CODNAT IN (1080100, 1080200)
            THEN fin.VLRBAIXA ELSE 0 END)
            FROM TGFFIN fin
            WHERE fin.CODEMP = 1
            AND (fin.DHBAIXA BETWEEN '01/01/2023' AND '31/12/2023')
            AND fin.RECDESP = -1
            AND fin.PROVISAO = 'N'
            AND fin.VLRBAIXA > 0
            AND fin.VLRCHEQUE IS NOT NULL
            ) AS REC_DESP_FIN,
            
            (
            SELECT DISTINCT
            SUM(ite.VLRTOT * 0.03)
            FROM TGFITE ite, TGFCAB cab
            WHERE cab.CODEMP = 1
            AND cab.CODTIPOPER in   ('1100', '1111', '1120', '1125', '1126', 
                                     '1128', '1130', '1131', '1706', '1708', 
                                     '1709', '1710', '1711', '1714', '1720')
            AND (cab.DTFATUR BETWEEN '01/01/2023' AND '31/12/2023')
            AND cab.TIPMOV = 'V'
            AND ite.NUNOTA = cab.NUNOTA
            ) AS IRPJ_CSLL
        
        FROM TGFCAB cab
        
        WHERE cab.CODEMP = 1
        
        AND cab.TIPMOV = 'V'
        AND (cab.DTFATUR BETWEEN '01/01/2023' AND '31/12/2023')
        
        AND cab.CODTIPOPER in ('1100', '1111', '1120', '1125', '1126', '1128', '1130', '1131', '1706', '1708', '1709', '1710', '1711', '1714', '1720', '1799', '8')
        
        GROUP BY cab.CODEMP
        
        ORDER BY EMPRESA
        ) 
    
    ) AS DRE

-- Com o uso da CTE, a partir deste ponto podemos usar as diversas saídas dos blocos de código como VARIÁVEIS 
SELECT (MP / FATURAMENTO * 100) AS CUSTO_MP

-- E de maneira muito simples pode-se calcular outros indicadores, apenas "chamando" os nomes 
    -- SELECT (PESSOAS / FATURAMENTO * 100) AS DESP_PESSOAL
    -- SELECT (MAQ_EXPORT / FATURAMENTO * 100) AS EXPORTACAO


FROM dre