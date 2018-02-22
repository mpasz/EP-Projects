CREATE PROCEDURE SBO_SP_PostTransactionNotice
(
	in object_type nvarchar(20), 				-- SBO Object Type
	in transaction_type nchar(1),			-- [A]dd, [U]pdate, [D]elete, [C]ancel, C[L]ose
	in num_of_cols_in_key int,
	in list_of_key_cols_tab_del nvarchar(255),
	in list_of_cols_val_tab_del nvarchar(255)
)
LANGUAGE SQLSCRIPT
AS
-- Return values
error  int;				-- Result (0 for no error)
error_message nvarchar (200); 		-- Error string to be displayed
cnt int;
id int ;
begin

error := 0;
error_message := N'Ok';

--------------------------------------------------------------------------------------------------------------------------------
---To jest zmiana TN
--	ADD	YOUR	CODE	HERE
--call "CT_TEST_POSTTN" ();



--Blokada zapisu dokumentu PZ dla indeksów PP
IF :error = 0 and :cnt = 0
AND :object_type ='20' 
AND (:transaction_type =N'A')
THEN SELECT  Count(*) 
into cnt 
FROM "PDN1" T0 
WHERE "ItemCode" LIKE 'PP%'
and
 T0."DocEntry" = :list_of_cols_val_tab_del ;

if :cnt>0 
then error:=1 
;
error_message:= 'Brak możliwości zapisu dokumentu PZ. Na pozycji znajduje się indeks PP'
;

end 
if 
;

END 
if 
;


-----------------------insert numer PH

IF :error = 0 
AND :object_type = '4' 
AND (:transaction_type =N'A')
THEN 
       INSERT INTO OSCN
      SELECT DISTINCT * FROM (SELECT DISTINCT  T0."ItemCode", T1."CardCode", T0."U_DrawNoFinal",
        'N', 'A', 518, 0, 'N' FROM OITM T0
        LEFT JOIN  OCRD T1 ON SUBSTRING (T0."ItemCode",4,5 )=SUBSTRING (T1."CardCode",2,5 ) WHERE SUBSTRING (T0."ItemCode",1,2 )='WG' AND SUBSTRING (T1."CardCode",1,1 )='O' AND T0."U_DrawNoFinal"<>'' AND T0."CardCode" = :list_of_cols_val_tab_del
        UNION ALL
        SELECT DISTINCT  T0."ItemCode", T1."CardCode", T0."U_DrawNoRaw",
        'N', 'A', 518, 0, 'N' FROM OITM T0
        LEFT JOIN  OCRD T1 ON SUBSTRING (T0."ItemCode",4,5 )=SUBSTRING (T1."CardCode",2,5 ) WHERE SUBSTRING (T0."ItemCode",1,2 )='SU' AND SUBSTRING (T1."CardCode",1,1 )='D'  AND T0."U_DrawNoRaw"<>'' AND T0."CardCode" = :list_of_cols_val_tab_del) A
 ;
END 
IF;



-- inwentaryzacja dodatkowy arkusz

IF :error = 0 
AND :object_type ='1470000065' 
AND ( :transaction_type =N'U')
THEN 
BEGIN
      INSERT INTO "@CT_ARK_INWENT_N"
      (           "DocEntry"
           ,"DocNum"
           ,"Period"
	   ,"Instance"
	   ,"Series"
	   ,"Handwrtten"
           ,"Canceled"
           ,"Object"
           ,"LogInst"
           ,"UserSign"
           ,"Transfered"
           ,"CreateDate"
           ,"CreateTime"
           ,"UpdateDate"
           ,"UpdateTime"
           ,"DataSource"
         
      )
      SELECT 
             (select "AutoKey"  from ONNM where "ObjectCode"='CT_INWENT')
              , "DocEntry"
	      ,34
              ,0
              ,151
              ,'N'
              ,'N'
              ,'CT_INWENT'
              ,null
              ,1
              ,'N'
              ,CURRENT_DATE
              ,600
              ,CURRENT_DATE
              ,600
              ,'I'      
           
      from OINC where  "DocEntry" = :list_of_cols_val_tab_del and "U_STATUS"=2 and "U_INVENT" is null   ;
      
   
      
--insert pozycji dla arkusza
delete from "@CT_ARK_INWENT_P" where "U_DocEntryOINV"=:list_of_cols_val_tab_del ;

    INSERT INTO "@CT_ARK_INWENT_P"
      ( "DocEntry",
       "LineId",
       "Object",
       "U_NazwaDetalu", "U_NrRysSur", "U_NrRysGot", "U_SymbKartoteki", "U_KodKreskowy", "U_Lokalizacja", "U_Reklamacja", "U_Naprawa", "U_Technologia", "U_Proces", "U_Ilosc", "U_IloscSkan", "U_DocEntryOINV", "U_LineIdOINV")  
      SELECT 
              ( SELECT T1."DocEntry" FROM OINC T0 left join "@CT_ARK_INWENT_N" T1 on t0."DocEntry"=t1."DocNum" Where T0."DocEntry"=:list_of_cols_val_tab_del)
              ,ROW_NUMBER() OVER()
              ,'CT_INWENT'
              , t1."ItemDesc",  t6."U_DrawNoRaw" , t6."U_DrawNoFinal" , t1."ItemCode", t4."DistNumber", t2."BinCode", '' "Rekl", '' "Napr", '' "Tech",
 t2."SL1Code",  t3."OnHandQty", t5."Quantity" ,  ( SELECT T0."DocEntry" FROM OINC T0 inner join "@CT_ARK_INWENT_N" T1 on t0."DocEntry"=t1."DocNum" Where T0."DocEntry"=:list_of_cols_val_tab_del), t1."LineNum"
from OINC t0
	left join INC1 t1 on t0."DocEntry"=t1."DocEntry"
	inner join OBIN t2 on t1."BinEntry"=t2."AbsEntry"
	inner join OBBQ t3 on t3."ItemCode"=t1."ItemCode" and t3."BinAbs"=t2."AbsEntry" and t3."OnHandQty"<>0
	inner join OBTN t4 on t4."AbsEntry"=t3."SnBMDAbs"
	left join INC3 t5 on t5."ObjAbs"=t4."AbsEntry" and t5."DocEntry"=t1."DocEntry" and t5."LineNum"=t1."LineNum"
	inner join OITM t6 on t6."ItemCode"=t1."ItemCode"
	 where t0."DocEntry"=:list_of_cols_val_tab_del and "U_STATUS"=2 --and "U_INVENT" is null
	 ;
            
    
-- update id wpisu


      UPDATE ONNM 
                  SET "AutoKey"=(SELECT max("DocEntry")+1 FROM "@CT_ARK_INWENT_N")
      WHERE "ObjectCode"='CT_INWENT'
      AND "AutoKey"<>(SELECT max("DocEntry")+1 "MaxDocEntry" FROM "@CT_ARK_INWENT_N") ;

    
UPDATE OINC T0
      SET "U_INVENT"=T1."DocEntry"
      FROM
      OINC T0
      inner join "@CT_ARK_INWENT_N" T1 on t0."DocEntry"=t1."DocNum"
      Where T0."DocEntry"=:list_of_cols_val_tab_del
      AND ifnull(T0."U_INVENT",0)=0
      and T0."U_STATUS"=2 and T0."U_INVENT" is null;
        END;
        END if;

--INC LOG--INC LOG--INC LOG--INC LOG--INC LOG--INC LOG--INC LOG--INC LOG--INC LOG--INC LOG--INC LOG--INC LOG
--INC LOG--INC LOG--INC LOG--INC LOG--INC LOG--INC LOG--INC LOG--INC LOG--INC LOG--INC LOG--INC LOG--INC LOG


IF :error = 0 
AND :object_type = N'CT_INC_LOG' 
AND (:transaction_type =N'A' or :transaction_type =N'U')
THEN 
begin
delete from "@CT_INC_LOG2" where "U_Nr_czesci" is null and "DocEntry"=:list_of_cols_val_tab_del;

insert into "SBOELECTROPOLI"."@CT_INC_LOG2" 
("DocEntry",
"LineId",
"VisOrder",
"Object",
"LogInst",
"U_Nr_czesci",
"U_Nazwa_czesci",
"U_Data_dostawy",
"U_Nr_dok_WZ")

SELECT t0."DocEntry"
,row_number() over (order by t2."VisOrder")
,row_number() over (order by t2."VisOrder")
,t0."Object"
,null
,ifnull(t5."U_DrawNoRaw",'')
,t2."Dscription"
,t1."DocDueDate"
,t1."NumAtCard"
 FROM 

"@CT_INC_LOG1" T0
INNER JOIN OPDN T1 ON t1."DocEntry"=T0."U_Dok_powiaz"
INNER JOIN PDN1 T2 ON T1."DocEntry"=T2."DocEntry"
inner join oitm t5 on t2."ItemCode"=t5."ItemCode"
LEFT OUTER JOIN "@CT_INC_LOG2" T3 on T0."DocEntry"=T3."DocEntry"

where T0."DocEntry"=:list_of_cols_val_tab_del
and t3."DocEntry" is null
;
end;
END 
IF;


--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--
--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--

--Aktualizacja tabeli z numerami dużych etykiet

IF :error = 0 
AND :object_type = N'15' 
AND :transaction_type =N'A'
THEN 

CALL "CT_NUMERACJA_ETYKIET_DUZYCH" (cast(:list_of_cols_val_tab_del as bigint));

END 
IF;

--Aktualizacja tabeli z numerami dużych etykiet - tworzenie tymczasowej WZ

IF :error = 0 
AND :object_type = N'112' 
AND :transaction_type =N'A'
THEN 

CALL "CT_NUMERACJA_ETYKIET_DUZYCH_TYMCZ" (cast(:list_of_cols_val_tab_del as bigint));

END 
IF;

--Aktualizacja tabeli z numerami dużych etykiet - aktualizacja tymczasowej WZ

IF :error = 0 
AND :object_type = N'112' 
AND :transaction_type =N'U'
THEN 

CALL "CT_NUMERACJA_ETYKIET_DUZYCH_TYMCZ_AKT" (cast(:list_of_cols_val_tab_del as bigint));

END 
IF;

--Aktualizacja tabeli z numerami małych etykiet

IF :error = 0 
AND :object_type = N'15' 
AND :transaction_type =N'A'
THEN 

CALL "CT_NUMERACJA_ETYKIET_MALYCH_LPOJ" (:list_of_cols_val_tab_del);

END 
IF;

--Aktualizacja tabeli z numerami małych etykiet - tworzenie tymczasowej WZ

IF :error = 0 
AND :object_type = N'112' 
AND :transaction_type =N'A'
THEN 

CALL "CT_NUMERACJA_ETYKIET_MALYCH_LPOJ_TYMCZ" (:list_of_cols_val_tab_del);

END 
IF;

--Aktualizacja tabeli z numerami małych etykiet - aktualizacja tymczasowej WZ

IF :error = 0 
AND :object_type = N'112' 
AND :transaction_type =N'U'
THEN 

CALL "CT_NUMERACJA_ETYKIET_MALYCH_LPOJ_TYMCZ_AKT" (:list_of_cols_val_tab_del);

END 
IF;

--Aktualizacja sumy ilośći z pozycji

IF :error = 0 
AND :object_type = N'15' 
AND :transaction_type =N'A'
THEN 
		UPDATE ODLN SET "ODLN"."U_PosQtySum" = 
		(SELECT SUM(T0."InvQty")
		FROM DLN1 T0
		WHERE T0."DocEntry" = "ODLN"."DocEntry")
		WHERE "ODLN"."DocEntry" = :list_of_cols_val_tab_del
		;
END 
IF;

--Aktualizacja numeru zamówienia klienta
/*
IF :error = 0 
AND :object_type = N'15' 
AND :transaction_type =N'A'
THEN 

UPDATE DLN1 SET "DLN1"."U_OrderNo" = 
		(SELECT DISTINCT
 			T3."AbsID"
		FROM ODLN T0
 		INNER JOIN DLN1 T1 ON T0."DocEntry" = T1."DocEntry"
 		LEFT OUTER JOIN OAT1 T2 ON T1."ItemCode" = T2."ItemCode"
 		LEFT OUTER JOIN OOAT T3 ON T2."AgrNo" = T3."AbsID"
		WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T0."DocEntry" = "DLN1"."DocEntry" AND T1."LineNum" = "DLN1"."LineNum"
		AND T0."DocDate" >= IFNULL(T3."U_OrderFrom",'1900-01-01') AND T0."DocDate" <= IFNULL(T3."U_OrderTo",'2999-12-31') AND "DLN1"."ItemCode" = T2."ItemCode")
WHERE "DLN1"."DocEntry" = 
		(SELECT DISTINCT
 			T1."DocEntry"
		FROM ODLN T0
 		INNER JOIN DLN1 T1 ON T0."DocEntry" = T1."DocEntry"
 		LEFT OUTER JOIN OAT1 T2 ON T1."ItemCode" = T2."ItemCode"
 		LEFT OUTER JOIN OOAT T3 ON T2."AgrNo" = T3."AbsID"
		WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T0."DocEntry" = "DLN1"."DocEntry" AND T1."LineNum" = "DLN1"."LineNum"
		AND T0."DocDate" >= IFNULL(T3."U_OrderFrom",'1900-01-01') AND T0."DocDate" <= IFNULL(T3."U_OrderTo",'2999-12-31') AND "DLN1"."ItemCode" = T2."ItemCode")
		
		AND "DLN1"."LineNum" = 
		(SELECT DISTINCT
 			T1."LineNum"
		FROM ODLN T0
 		INNER JOIN DLN1 T1 ON T0."DocEntry" = T1."DocEntry"
 		LEFT OUTER JOIN OAT1 T2 ON T1."ItemCode" = T2."ItemCode"
 		LEFT OUTER JOIN OOAT T3 ON T2."AgrNo" = T3."AbsID"
		WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T0."DocEntry" = "DLN1"."DocEntry" AND T1."LineNum" = "DLN1"."LineNum"
		AND T0."DocDate" >= IFNULL(T3."U_OrderFrom",'1900-01-01') AND T0."DocDate" <= IFNULL(T3."U_OrderTo",'2999-12-31') AND "DLN1"."ItemCode" = T2."ItemCode")
;
END 
IF;

--Aktualizacja zrealizowanej ilości z zamówienia

IF :error = 0 
AND :object_type = N'15' 
AND :transaction_type =N'A'
THEN 
		UPDATE OAT1 SET "OAT1"."U_UsedQty" = 
		(SELECT
 			SUM(IFNULL(T2."U_InQty",0)) + SUM(T1."InvQty")
		FROM ODLN T0
 		INNER JOIN DLN1 T1 ON T0."DocEntry" = T1."DocEntry"
 		LEFT OUTER JOIN OAT1 T2 ON T1."ItemCode" = T2."ItemCode"
 		LEFT OUTER JOIN OOAT T3 ON T2."AgrNo" = T3."AbsID"
		WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T0."DocDate" >= IFNULL(T3."U_OrderFrom",'1900-01-01') AND T0."DocDate" <= IFNULL(T3."U_OrderTo",'2999-12-31')
		AND T1."ItemCode" = T2."ItemCode" AND "OAT1"."AgrNo" = T2."AgrNo" AND "OAT1"."AgrLineNum" = T2."AgrLineNum")
		WHERE "OAT1"."AgrNo" = (SELECT
 			T2."AgrNo"
		FROM ODLN T0
 		INNER JOIN DLN1 T1 ON T0."DocEntry" = T1."DocEntry"
 		INNER JOIN OAT1 T2 ON T1."ItemCode" = T2."ItemCode"
 		INNER JOIN OOAT T3 ON T2."AgrNo" = T3."AbsID"
		WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T0."DocDate" >= IFNULL(T3."U_OrderFrom",'1900-01-01') AND T0."DocDate" <= IFNULL(T3."U_OrderTo",'2999-12-31')
		AND T1."ItemCode" = T2."ItemCode" AND "OAT1"."AgrNo" = T2."AgrNo" AND "OAT1"."AgrLineNum" = T2."AgrLineNum")
		;
END 
IF;
*/
--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--
--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--

--Aktualizacja numeru zamówienia klienta
/*
IF :error = 0 
AND :object_type = N'17' 
AND :transaction_type =N'A'
THEN 
		UPDATE RDR1 SET "RDR1"."U_OrderNo" = T3."AbsID"
		FROM ORDR T0
 		INNER JOIN RDR1 T1 ON T0."DocEntry" = T1."DocEntry"
 		LEFT OUTER JOIN OAT1 T2 ON T1."ItemCode" = T2."ItemCode"
 		LEFT OUTER JOIN OOAT T3 ON T2."AgrNo" = T3."AbsID"
		WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T0."DocEntry" = "RDR1"."DocEntry" AND T1."LineNum" = "RDR1"."LineNum"
		AND T0."DocDate" >= T3."U_OrderFrom" AND T0."DocDate" <= T3."U_OrderTo"
		;
END 
IF;
*/
--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--
--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--

--Aktualizacja tabeli z numerami PZPDW

IF :error = 0 
AND :object_type = N'20' 
AND :transaction_type =N'A'
THEN 

CALL "CT_PZPDW" (:list_of_cols_val_tab_del);

END 
IF;

--Aktualizacja statusu zamówienia na realizację częściową

IF :error = 0 
AND :object_type = N'20' 
AND :transaction_type =N'A'
THEN 
		UPDATE OPOR SET "U_POStatus" = 6 WHERE "DocEntry" IN
		(
			SELECT DISTINCT
			 T2."DocEntry"
			FROM OPDN T0
			 LEFT OUTER JOIN PDN1 T1 ON T0."DocEntry" = T1."DocEntry"
			 LEFT OUTER JOIN POR1 T2 ON T1."BaseEntry" = T2."DocEntry" AND T1."BaseLine" = T2."LineNum" AND T1."BaseType" = T2."ObjType"
			 LEFT OUTER JOIN OPOR T3 ON T2."DocEntry" = T3."DocEntry"
			WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T3."DocStatus" = 'O' AND T3."U_POStatus" <= 6
		);
END 
IF;

--Aktualizacja statusu zamówienia na zrealizowane

IF :error = 0 
AND :object_type = N'20' 
AND :transaction_type =N'A'
THEN 
		UPDATE OPOR SET "U_POStatus" = 7 WHERE "DocEntry" IN
		(
			SELECT DISTINCT
			 T2."DocEntry"
			FROM OPDN T0
			 LEFT OUTER JOIN PDN1 T1 ON T0."DocEntry" = T1."DocEntry"
			 LEFT OUTER JOIN POR1 T2 ON T1."BaseEntry" = T2."DocEntry" AND T1."BaseLine" = T2."LineNum" AND T1."BaseType" = T2."ObjType"
			 LEFT OUTER JOIN OPOR T3 ON T2."DocEntry" = T3."DocEntry"
			WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T3."DocStatus" = 'C' AND T3."U_POStatus" <= 7 
		);
END 
IF;

--Aktualizacja sumy ilośći z pozycji

IF :error = 0 
AND :object_type = N'20' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN 
		UPDATE OPDN SET "OPDN"."U_PosQtySum" = 
		(SELECT SUM(T0."InvQty")
		FROM PDN1 T0
		WHERE T0."DocEntry" = "OPDN"."DocEntry")
		WHERE "OPDN"."DocEntry" = :list_of_cols_val_tab_del
		;
END 
IF;

--Aktualizacja zrealizowanej ilości z zamówienia
/*
IF :error = 0 
AND :object_type = N'20' 
AND :transaction_type =N'A'
THEN 
		UPDATE OAT1 SET "OAT1"."U_InQty" = 
		(SELECT
 			SUM(IFNULL(T2."U_InQty",0)) + SUM(T1."InvQty")
		FROM OPDN T0
 		INNER JOIN PDN1 T1 ON T0."DocEntry" = T1."DocEntry"
 		INNER JOIN OAT1 T2 ON T1."ItemCode" = REPLACE(T2."ItemCode",'WG','SU')
 		INNER JOIN OOAT T3 ON T2."AgrNo" = T3."AbsID"
		WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T0."DocDate" >= IFNULL(T3."U_OrderFrom",'1900-01-01') AND T0."DocDate" <= IFNULL(T3."U_OrderTo",'2999-12-31')
		AND T1."ItemCode" = REPLACE(T2."ItemCode",'WG','SU') AND "OAT1"."AgrNo" = T2."AgrNo" AND "OAT1"."AgrLineNum" = T2."AgrLineNum")
		--GROUP BY IFNULL(T2."U_InQty",0)
		WHERE "OAT1"."AgrNo" = (SELECT
 			T2."AgrNo"
		FROM OPDN T0
 		INNER JOIN PDN1 T1 ON T0."DocEntry" = T1."DocEntry"
 		INNER JOIN OAT1 T2 ON T1."ItemCode" = REPLACE(T2."ItemCode",'WG','SU')
 		INNER JOIN OOAT T3 ON T2."AgrNo" = T3."AbsID"
		WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T0."DocDate" >= IFNULL(T3."U_OrderFrom",'1900-01-01') AND T0."DocDate" <= IFNULL(T3."U_OrderTo",'2999-12-31')
		AND T1."ItemCode" = REPLACE(T2."ItemCode",'WG','SU') AND "OAT1"."AgrNo" = T2."AgrNo" AND "OAT1"."AgrLineNum" = T2."AgrLineNum")
		;
END 
IF;
*/
--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--
--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--

--Aktualizacja statusu zamówienia na fakturę

IF :error = 0 
AND :object_type = N'18' 
AND :transaction_type =N'A'
THEN 
		UPDATE OPOR SET "U_POStatus" = 8 WHERE "DocEntry" IN
		(
			SELECT DISTINCT
			 T4."DocEntry"
			FROM OPCH T0
			 LEFT OUTER JOIN PCH1 T1 ON T0."DocEntry" = T1."DocEntry"
			 LEFT OUTER JOIN PDN1 T2 ON T1."BaseEntry" = T2."DocEntry" AND T1."BaseLine" = T2."LineNum" AND T1."BaseType" = T2."ObjType"
			 LEFT OUTER JOIN POR1 T3 ON T2."BaseEntry" = T3."DocEntry" AND T2."BaseLine" = T3."LineNum" AND T2."BaseType" = T3."ObjType"
			 LEFT OUTER JOIN OPOR T4 ON T3."DocEntry" = T4."DocEntry"
			WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T4."DocStatus" = 'O' AND T4."U_POStatus" <= 8
		);
END 
IF;

--Aktualizacja statusu zamówienia na archiwalne

IF :error = 0 
AND :object_type = N'18' 
AND :transaction_type =N'A'
THEN 
		UPDATE OPOR SET "U_POStatus" = 9 WHERE "DocEntry" IN
		(
			SELECT DISTINCT
			 T4."DocEntry"
			FROM OPCH T0
			 LEFT OUTER JOIN PCH1 T1 ON T0."DocEntry" = T1."DocEntry"
			 LEFT OUTER JOIN PDN1 T2 ON T1."BaseEntry" = T2."DocEntry" AND T1."BaseLine" = T2."LineNum" AND T1."BaseType" = T2."ObjType"
			 LEFT OUTER JOIN POR1 T3 ON T2."BaseEntry" = T3."DocEntry" AND T2."BaseLine" = T3."LineNum" AND T2."BaseType" = T3."ObjType"
			 LEFT OUTER JOIN OPOR T4 ON T3."DocEntry" = T4."DocEntry"
			WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T4."DocStatus" = 'C' 
		);
END 
IF;

--OIGN--OIGN--OIGN--OIGN--OIGN--OIGN--OIGN--OIGN--OIGN--OIGN--OIGN--OIGN--OIGN--OIGN--OIGN--OIGN--OIGN--
--OIGN--OIGN--OIGN--OIGN--OIGN--OIGN--OIGN--OIGN--OIGN--OIGN--OIGN--OIGN--OIGN--OIGN--OIGN--OIGN--OIGN--

--Aktualizacja sumy ilośći z pozycji

IF :error = 0 
AND :object_type = N'59' 
AND :transaction_type =N'A'
THEN 
		UPDATE OIGN SET "OIGN"."U_PosQtySum" = 
		(SELECT SUM(T0."InvQty")
		FROM IGN1 T0
		WHERE T0."DocEntry" = "OIGN"."DocEntry")
		WHERE "OIGN"."DocEntry" = :list_of_cols_val_tab_del
		
		;
END 
IF;

--OIGE--OIGE--OIGE--OIGE--OIGE--OIGE--OIGE--OIGE--OIGE--OIGE--OIGE--OIGE--OIGE--OIGE--OIGE--OIGE--OIGE--
--OIGE--OIGE--OIGE--OIGE--OIGE--OIGE--OIGE--OIGE--OIGE--OIGE--OIGE--OIGE--OIGE--OIGE--OIGE--OIGE--OIGE--

--Aktualizacja sumy ilośći z pozycji

IF :error = 0 
AND :object_type = N'60' 
AND :transaction_type =N'A'
THEN 
		UPDATE OIGE SET "OIGE"."U_PosQtySum" = 
		(SELECT SUM(T0."InvQty")
		FROM IGE1 T0
		WHERE T0."DocEntry" = "OIGE"."DocEntry")
		WHERE "OIGE"."DocEntry" = :list_of_cols_val_tab_del
		;
END 
IF;

--Aktualizacja nr RW w tabeli CT_PDW dla utworzonych RW do PZ

IF :error = 0 
AND :object_type = N'60' 
AND :transaction_type =N'A'
THEN 
		UPDATE "@CT_PDW" SET "@CT_PDW"."U_DocEntryRW" = 
		(SELECT T0."DocEntry"
		FROM OIGE T0
		WHERE T0."DocEntry" = :list_of_cols_val_tab_del)
		WHERE (SELECT DISTINCT T0."U_PZPDW" FROM IGE1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del) = "@CT_PDW"."U_DocEntryPZ"
		;
END 
IF;

--Aktualizacja tabeli PWRW i PWRWLINIE do przyjęcia na konfekcji

IF :error = 0 
AND :object_type = N'60' 
AND :transaction_type =N'A'
THEN 
 CALL "CT_PW_KONFEKCJA" (:list_of_cols_val_tab_del)
 ;
END 
IF;

--Towrezenie storage unitów po przesuieciu na maszyne 
--Te storage Unity są trugerami do dalszych transakcji magazynowych
-- Tworzą sie tylko jęsli przesuwamy na lokalizaje magazynową powiązaną z zasobrem
-- MM-Ki nietworzone 
IF :error = 0 
AND :object_type = N'67' 
AND :transaction_type =N'A'
THEN 
	call	CreateSSTU_FROM_MM ( :list_of_cols_val_tab_del);
END 
IF;



 
--Wydruki na zamkniętą palete
IF :error = 0 
AND :object_type = N'CT_WMS_OSTU' 
AND (:transaction_type =N'U' or :transaction_type =N'A')
THEN 

--select count(*)  into id from "@CT_WMS_OSTU" where "Code"=:list_of_cols_val_tab_del 
--and "U_StatusSU" in ('1') AND "U_IloscSU" = "U_IloscOrig";

select count(*) into id from "@CT_WMS_OSTU" t00
inner join "@ACT_WMS_OSTU" t0 on t0."Code" = t00."Code"
--inner join "@ACT_WMS_OSTU" t1 on t0."Code" = t1."Code" and t0."LogInst" = t1."LogInst"+1
where t00."Code" = :list_of_cols_val_tab_del 
and t0."LogInst" = (select Max("LogInst")-1 from "@ACT_WMS_OSTU" where "Code" = :list_of_cols_val_tab_del )
and t00. "U_Attribute5" <>'Wor' and  (
(
	t00."U_IloscSU" + t00."U_IloscZlych" = t00."U_IloscOrig" and t00."U_IloscOrig" > 0 and t00."U_StatusSU" = '1' -- Zamykamy cale pudelko 
) or 
(
	t00."U_StatusSU" = '2' and t00."U_IloscSU" > 0 and  ( t0."U_IloscSU" <> t00."U_IloscSU" --or t0."U_IloscZlych" <> t00."U_IloscZlych"
							   )
							   
));
if(:id >0)
then
	call	 "CT_GetBoxClose" ( :list_of_cols_val_tab_del);
end if;
END 
IF;

/*
--test
IF :error = 0 
AND :object_type = N'CT_WMS_OSTU' 
THEN

	call "CT_TEST_POSTTN" (:list_of_cols_val_tab_del);

END 
IF;
*/
 /* 

-- CT_PLANOWANIE -- CT_PLANOWANIE -- CT_PLANOWANIE -- CT_PLANOWANIE -- CT_PLANOWANIE -- CT_PLANOWANIE --
-- CT_PLANOWANIE -- CT_PLANOWANIE -- CT_PLANOWANIE -- CT_PLANOWANIE -- CT_PLANOWANIE -- CT_PLANOWANIE --
--IF :object_type = N'CT_PF_ManufacOrd' 
--AND :transaction_type =N'A' 
--THEN 
--INSERT INTO "@CT_PLANOWANIE"
--		("DocEntry",
--		"DocNum",
--		"Period",
--		"Instance",
--		"Series",
--		"Handwrtten",
--		"Canceled",
--		"Object",
--		"UserSign",
--		"Transfered",
--		"Status",
--		"CreateDate",
--		"CreateTime",
--		"DataSource",
--		"RequestStatus",
--		"Creator",
--		"U_Klucz")
--	SELECT 
--		(SELECT Max("DocEntry")+1 FROM "@CT_PLANOWANIE"),
--		"DocNum",
--		24,
--		0,
--		-1,
--		'N',
--		'N',
--		'CT_PLANOWANIE',
--		1,
--		'N',
--		'O',
		CURRENT_DATE,
		0,
		'I',
		'W',
		"Creator",
		"DocEntry"
	FROM
		"@CT_PF_OMOR"
	WHERE 
		"DocEntry"=:list_of_cols_val_tab_del ;
		END 
if;
		*/
		

--ODRF--ODRF--ODRF--ODRF--ODRF--ODRF--ODRF--ODRF--ODRF--ODRF--ODRF--ODRF--ODRF--ODRF--ODRF--ODRF--ODRF--
--ODRF--ODRF--ODRF--ODRF--ODRF--ODRF--ODRF--ODRF--ODRF--ODRF--ODRF--ODRF--ODRF--ODRF--ODRF--ODRF--ODRF--

--Wpisanie numeru dokumentu tymczasowego na WZ

IF :error = 0 
AND :object_type = N'112' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN 
		UPDATE "ODRF" SET "U_DraftKey" = "DocEntry"
		WHERE "DocEntry" = :list_of_cols_val_tab_del AND "ObjType" = 15
		;
END 
IF;

--Wpisanie numeru dokumentu tymczasowego na PZ

IF :error = 0 
AND :object_type = N'112' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN 
		UPDATE "ODRF" SET "U_DraftKey" = "DocEntry"
		WHERE "DocEntry" = :list_of_cols_val_tab_del AND "ObjType" = 20
		;
END 
IF;

--OPKL--OPKL--OPKL--OPKL--OPKL--OPKL--OPKL--OPKL--OPKL--OPKL--OPKL--OPKL--OPKL--OPKL--OPKL--OPKL--OPKL--
--OPKL--OPKL--OPKL--OPKL--OPKL--OPKL--OPKL--OPKL--OPKL--OPKL--OPKL--OPKL--OPKL--OPKL--OPKL--OPKL--OPKL--

/*
--Aktualizacja numeru listy pobrania na zleceniu wysyłki (UDO)
IF :error = 0 
AND :object_type = N'156' 
AND :transaction_type =N'A'
THEN 
		UPDATE "@CT_ZW_NAG" SET "@CT_ZW_NAG"."U_PickNo" = G0."AbsEntry"
		FROM OPKL G0
		WHERE G0."AbsEntry" = :list_of_cols_val_tab_del AND G0."U_ZW" = "@CT_ZW_NAG"."DocEntry"
		;
END 
IF;
*/

IF :error = 0 
AND :object_type = N'156' 
AND :transaction_type =N'A'
THEN 
		UPDATE ORDR SET "U_CreateSendOrder" = 'U' WHERE "DocEntry" IN
		(SELECT DISTINCT "OrderEntry" FROM PKL1 WHERE "AbsEntry" = :list_of_cols_val_tab_del);
END 
IF;

-- Kopiowanie przewoźnika 'NumAtCard' z Zlecenia Wysylki do PickListy
IF :error = 0 
AND :object_type = N'156' 
AND :transaction_type =N'A'
THEN 
	UPDATE "OPKL" SET "U_InfoTrans" = (SELECT "NumAtCard" from ORDR 
							WHERE "DocEntry" = (SELECT DISTINCT "OrderEntry" FROM PKL1 WHERE "AbsEntry" = :list_of_cols_val_tab_del))
	WHERE  "AbsEntry" = :list_of_cols_val_tab_del;
END 
IF;

--KALKULACJA OFERT_ZACHOWAĆ KOLEJNOŚĆ PONIŻSZYCH PROCEDUR!!!
--KALKULACJA OFERT_ZACHOWAĆ KOLEJNOŚĆ PONIŻSZYCH PROCEDUR!!!

--- Nadanie numeru ofercie (ZoF)
IF :error = 0 
AND :object_type = N'CT_ZOF' 
AND (:transaction_type =N'A')
THEN 

  	
	UPDATE "@CT_ZOF_N" T1 SET 

T1."U_InqNo"=
	(select 
	 	ifnull((
	select
	case length(cast(max(left("U_InqNo",4))  as int)+1) when 1 then '000' when 2 then '00' when 3 then '0' else '' end
	||
	cast(max(left("U_InqNo",4))+1 as nvarchar(10))
	from "@CT_ZOF_N" 
	where  ifnull("U_InqNo",'') <>''

	and "U_InqNo" like '%'||'/'||'00'||'/'||year(CURRENT_DATE)
	),'0001') 
	|| '/'
	|| '00'
	|| '/'
	|| year(CURRENT_DATE)
	
		from dummy)
	
	WHERE T1."DocEntry" = :list_of_cols_val_tab_del 
	 
	and "U_InqNo" is null
	
	
	 ;
END 
IF;

--- Dodawanie lini w ZOF InzProdukcji

IF :error = 0 
AND :object_type = N'CT_ZOF' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN  

 INSERT INTO "@CT_ZOF_P2" ("DocEntry", "LineId","VisOrder", "Object", "U_Proces", "U_ProdLine", "U_DrawNoRaw")
 (SELECT T0."DocEntry", T0."LineId", T0."VisOrder", T0."Object", T0."U_Proces", T0."U_ProdLine", T0."U_RawDrawNo" 
      FROM "@CT_ZOF_P1" T0
	  LEFT OUTER JOIN "@CT_ZOF_P2" T1 ON T0."DocEntry" = T1."DocEntry" and T0."LineId" = T1."LineId"
      WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T1."LineId" IS NULL) 
 ;
END 
IF;

IF :error = 0 
AND :object_type = N'CT_ZOF' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN 

  UPDATE "@CT_ZOF_P2" T1 SET 
      T1."VisOrder" = T0."VisOrder", 
      T1."Object" = T0."Object", 
      T1."U_DrawNoRaw" = T0."U_RawDrawNo", 
      T1."U_Proces" = T0."U_Proces",
      T1."U_ProdLine" = T0."U_ProdLine"

      FROM "@CT_ZOF_P1" T0
	  LEFT OUTER JOIN "@CT_ZOF_P2" T1 ON T0."DocEntry" = T1."DocEntry" and T0."LineId" = T1."LineId"
 	  WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
 ;
END 
IF;



--- Dodawanie lini w ZOF Czasochłonnosc

IF :error = 0 
AND :object_type = N'CT_ZOF' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN  

 INSERT INTO "@CT_ZOF_P3" ("DocEntry", "LineId","VisOrder", "Object", "U_Proces", "U_DrawNoRaw")
 (SELECT T0."DocEntry", T0."LineId", T0."VisOrder", T0."Object", T0."U_Proces",  T0."U_RawDrawNo" 
      FROM "@CT_ZOF_P1" T0
	  LEFT OUTER JOIN "@CT_ZOF_P3" T1 ON T0."DocEntry" = T1."DocEntry" and T0."LineId" = T1."LineId"
      WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T1."LineId" IS NULL) 
 ;
END 
IF;


IF :error = 0 
AND :object_type = N'CT_ZOF' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN 

  UPDATE "@CT_ZOF_P3" T1 SET 
      T1."VisOrder" = T0."VisOrder", 
      T1."Object" = T0."Object", 
      T1."U_DrawNoRaw" = T0."U_RawDrawNo", 
      T1."U_Proces" = T0."U_Proces"

      FROM "@CT_ZOF_P1" T0
	  LEFT OUTER JOIN "@CT_ZOF_P3" T1 ON T0."DocEntry" = T1."DocEntry" and T0."LineId" = T1."LineId"
 	  WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
 ;
END 
IF;

--Ilość zawieszek na ZOF

IF :error = 0 
AND :object_type = N'CT_ZOF' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN 
	    UPDATE "@CT_ZOF_P2" T1 SET T1."U_HangQty" = G0."IloscZawieszek"
		FROM
		(Select T0."DocEntry",
		T1."LineId" AS "LineId",
		T5."U_Quantity" AS "NowaIlosc" ,
		T6."U_Quantity" AS "StaraIlosc",
		T3."U_QtyOnHang" AS "NowaNaZawieszke",
		T4."U_QtyOnHang" AS "StaraNaZawieszke",
		T3."U_RotQtyDay" AS "NoweObroty",
		T4."U_RotQtyDay" AS "StareObroty",
		CEILING(T1."U_Quantity"/T7."U_YearWorkDay"/T2."U_QtyOnHang"/T2."U_RotQtyDay")AS "IloscZawieszek"
        FROM "@CT_ZOF_N" T0
 		 INNER JOIN "@CT_ZOF_P1" T1 ON T0."DocEntry" = T1."DocEntry"
 		 LEFT OUTER JOIN "@CT_ZOF_P2" T2 ON T1."DocEntry" = T2."DocEntry" AND T2."LineId" = T1."LineId"
 		 LEFT OUTER JOIN "@ACT_ZOF_P2" T3 ON T2."DocEntry" = T3."DocEntry" AND T2."LineId" = T3."LineId"
 		 LEFT OUTER JOIN "@ACT_ZOF_P2" T4 ON T2."DocEntry" = T4."DocEntry" AND T2."LineId" = T4."LineId"
 		 LEFT OUTER JOIN "@ACT_ZOF_P1" T5 ON T1."DocEntry" = T5."DocEntry" AND T1."LineId" = T5."LineId"
 		 LEFT OUTER JOIN "@ACT_ZOF_P1" T6 ON T1."DocEntry" = T6."DocEntry" AND T1."LineId" = T6."LineId"
 		 LEFT OUTER JOIN "@CT_OF_PD" T7 ON 1=1		 
		WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
		AND T3."LogInst" = (SELECT MAX(G0."LogInst") FROM "@ACT_ZOF_P2" G0 WHERE G0."DocEntry" = T3."DocEntry")
		AND T4."LogInst" = (SELECT MAX(G1."LogInst")-1 FROM "@ACT_ZOF_P2" G1 WHERE G1."DocEntry" = T4."DocEntry")
		AND T5."LogInst" = (SELECT MAX(G0."LogInst") FROM "@ACT_ZOF_P1" G0 WHERE G0."DocEntry" = T5."DocEntry")
		AND T6."LogInst" = (SELECT MAX(G1."LogInst")-1 FROM "@ACT_ZOF_P1" G1 WHERE G1."DocEntry" = T6."DocEntry")
		and( T5."U_Quantity" <> T6."U_Quantity" or T3."U_QtyOnHang" <> T4."U_QtyOnHang" or T3."U_RotQtyDay" <> T4."U_RotQtyDay")) G0
		
		WHERE T1."DocEntry" = :list_of_cols_val_tab_del 
		and T1."LineId" = G0."LineId"
		and (G0."NowaIlosc"<>G0."StaraIlosc" or G0."NowaNaZawieszke" <> G0."StaraNaZawieszke" or G0."NoweObroty" <> G0."StareObroty")
		;
END 
IF;

--Wyliczenie kosztów materiałów na kalkulacji

IF :error = 0 
AND :object_type = N'CT_KOF' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN 
		UPDATE "@CT_KOF_P1" T1 SET "U_MatCost" = 
		ROUND(CASE WHEN T2."U_PricingName" = 'Typ_KTL' THEN
 			(((T1."U_Lack"/100)+1)*((T1."U_DirMatZl"*T1."U_Volume")+T1."U_OthMat"*T1."U_Area"))
 		ELSE
 		CASE WHEN T2."U_PricingName" = 'Typ_PRO' THEN
 			(((T1."U_Lack"/100)+1)*((T1."U_F1Price"*T1."U_DirMatKg"*T1."U_Volume")+T1."U_OthMat"*T1."U_Area"))
 		ELSE
 		CASE WHEN T2."U_PricingName" = 'Typ_NAT' THEN
 			(((T1."U_Lack"/100)+1)*T1."U_F1Price")+(T1."U_OthMat"*T1."U_Area")
 		END END END,4)
		FROM "@CT_KOF_N" T0
 		 INNER JOIN "@CT_KOF_P1" T1 ON T0."DocEntry" = T1."DocEntry"
 		 LEFT OUTER JOIN "@CT_OF_LPRW" T2 ON T1."U_Line" = T2."U_Line"
		WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
		;
END 
IF;

--Wyliczenie kosztów robocizny na kalkulacji

IF :error = 0 
AND :object_type = N'CT_KOF' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN 
		UPDATE "@CT_KOF_P1" t1 SET "U_WorkCost" = 
		ROUND(((T1."U_OperTime"*T1."U_EmpPrice"/3600/(T1."U_EmpEffic"/100))*((T1."U_Lack"/100)+1)),4)
		FROM "@CT_KOF_N" T0
 		 INNER JOIN "@CT_KOF_P1" T1 ON T0."DocEntry" = T1."DocEntry"
 		 LEFT OUTER JOIN "@CT_OF_LPRW" T2 ON T1."U_Line" = T2."U_Line"
		WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
		;
END 
IF;

--Wyliczenie kosztów maskowania na kalkulacji

IF :error = 0 
AND :object_type = N'CT_KOF' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN 
		UPDATE "@CT_KOF_P1" t1 SET "U_MaskCost" = 
		ROUND((((IFNULL(T1."U_MaskTime",0))*T1."U_EmpPrice"/3600/(T1."U_EmpEffic"/100))*((T1."U_Lack"/100)+1)),4)
		FROM "@CT_KOF_N" T0
 		 INNER JOIN "@CT_KOF_P1" T1 ON T0."DocEntry" = T1."DocEntry"
 		 LEFT OUTER JOIN "@CT_OF_LPRW" T2 ON T1."U_Line" = T2."U_Line"
		WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
		;
END 
IF;


--Wyliczenie kosztów stałych linii na kalkulacji

IF :error = 0 
AND :object_type = N'CT_KOF' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN 
		UPDATE "@CT_KOF_P1" T1 SET "U_FixLineCost" = 
		ROUND((((T1."U_HookPrice"*T1."U_Wlpk"/T1."U_LineUse")/T1."U_QtyScale"*((T1."U_Lack"/100)+1))*T1."U_PrcMultiple"),4)
		FROM "@CT_KOF_N" T0
 		 INNER JOIN "@CT_KOF_P1" T1 ON T0."DocEntry" = T1."DocEntry"
 		 LEFT OUTER JOIN "@CT_OF_LPRW" T2 ON T1."U_Line" = T2."U_Line"
		WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
		;
END 
IF;

--Wyliczenie kosztów struktury na kalkulacji

IF :error = 0 
AND :object_type = N'CT_KOF' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN 
		UPDATE "@CT_KOF_P1" T1 SET "U_StrCost" = 
		ROUND(CASE WHEN T2."U_PricingName" = 'Typ_KTL' THEN
 			(((T1."U_Lack"/100)+1)*((((T1."U_DirMatZl")*T1."U_Volume"+T1."U_OthMat"*T1."U_Area")+T1."U_OperTime"*T1."U_EmpPrice"/3600/(T1."U_EmpEffic"/100)
 			+T1."U_HookPrice"*(T1."U_Wlpk"/T1."U_LineUse")/T1."U_QtyScale")*T1."U_PrcMultiple")*((T1."U_StrMargin"/100)+(T1."U_LogMargin"/100)+(T1."U_LabMargin"/100)))
 
 		ELSE
 		CASE WHEN T2."U_PricingName" = 'Typ_PRO' THEN
 			(((T1."U_Lack"/100)+1)*((((T1."U_F1Price"*T1."U_DirMatKg")*T1."U_Volume"+T1."U_OthMat"*T1."U_Area")+T1."U_OperTime"*T1."U_EmpPrice"/3600/(T1."U_EmpEffic"/100)
 			+T1."U_HookPrice"*(T1."U_Wlpk"/T1."U_LineUse")/T1."U_QtyScale")*T1."U_PrcMultiple")*((T1."U_StrMargin"/100)+(T1."U_LogMargin"/100)+(T1."U_LabMargin"/100)))
 		ELSE
 		CASE WHEN T2."U_PricingName" = 'Typ_NAT' THEN
 			(((T1."U_Lack"/100)+1)*(((T1."U_F1Price"+T1."U_OthMat"*T1."U_Area")+T1."U_OperTime"*T1."U_EmpPrice"/3600/(T1."U_EmpEffic"/100)
 			+T1."U_HookPrice"*(T1."U_Wlpk"/T1."U_LineUse")/T1."U_QtyScale")*T1."U_PrcMultiple")*((T1."U_StrMargin"/100)+(T1."U_LogMargin"/100)+(T1."U_LabMargin"/100)))
 		END END END,4)
		FROM "@CT_KOF_N" T0
 		 INNER JOIN "@CT_KOF_P1" T1 ON T0."DocEntry" = T1."DocEntry"
 		 LEFT OUTER JOIN "@CT_OF_LPRW" T2 ON T1."U_Line" = T2."U_Line"
		WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
		;
END 
IF;

--Wyliczenie kosztów razem na kalkulacji

IF :error = 0 
AND :object_type = N'CT_KOF' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN 
		UPDATE "@CT_KOF_P1" T1 SET "U_CostSum" = 
		T1."U_MatCost"+T1."U_WorkCost"+T1."U_FixLineCost"+T1."U_StrCost"+T1."U_AddPrcCost"+T1."U_RepairCost"
		FROM "@CT_KOF_N" T0
 		 INNER JOIN "@CT_KOF_P1" T1 ON T0."DocEntry" = T1."DocEntry"
 		 LEFT OUTER JOIN "@CT_OF_LPRW" T2 ON T1."U_Line" = T2."U_Line"
		WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
		;
END 
IF;

--Wyliczenie wartości narzutu na kalkulacji

IF :error = 0 
AND :object_type = N'CT_KOF' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN 
		UPDATE "@CT_KOF_P1" T1 SET "U_MarginValue" = 
		ROUND(T1."U_CostSum"*(T1."U_Margin"/100),4)
		FROM "@CT_KOF_N" T0
 		 INNER JOIN "@CT_KOF_P1" T1 ON T0."DocEntry" = T1."DocEntry"
 		 LEFT OUTER JOIN "@CT_OF_LPRW" T2 ON T1."U_Line" = T2."U_Line"
		WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
		;
END 
IF;

--Wyliczenie ceny na kalkulacji

IF :error = 0 
AND :object_type = N'CT_KOF' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN 
		UPDATE "@CT_KOF_P1" T1 SET "U_Price" = 
		ROUND(T1."U_CostSum"+T1."U_MarginValue",4)
		FROM "@CT_KOF_N" T0
 		 INNER JOIN "@CT_KOF_P1" T1 ON T0."DocEntry" = T1."DocEntry"
 		 LEFT OUTER JOIN "@CT_OF_LPRW" T2 ON T1."U_Line" = T2."U_Line"
		WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
		;
END 
IF;

--Wyliczenie kosztów jednostkowych zabezpieczeń na kalkulacji

IF :error = 0 
AND :object_type = N'CT_KOF' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN 
		UPDATE "@CT_KOF_P2" T1 SET "U_ZabazPrice" = 
		ROUND(T1."U_SafeValue"/T1."U_Vital",2)
		FROM "@CT_KOF_N" T0
 		 INNER JOIN "@CT_KOF_P2" T1 ON T0."DocEntry" = T1."DocEntry"
		WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
		AND T1."U_Vital"<>0
		;
END 
IF;

--Wyliczenie ilości produkcji na dobę na kalkulacji

IF :error = 0 
AND :object_type = N'CT_KOF' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN 
		UPDATE "@CT_KOF_P2" T2 SET "U_DayQty" = 
		CEILING(T1."U_SpinYear"/T2."U_ProdTime")
		FROM "@CT_KOF_N" T0
 		 INNER JOIN "@CT_KOF_P1" T1 ON T0."DocEntry" = T1."DocEntry"
 		 LEFT OUTER JOIN "@CT_KOF_P2" T2 ON T1."DocEntry" = T2."DocEntry" AND T1."U_Process" = T2."U_Process"
 		 LEFT OUTER JOIN "@ACT_KOF_P2" T3 ON T2."DocEntry" = T3."DocEntry" AND T2."LineId" = T3."LineId"
 		 LEFT OUTER JOIN "@ACT_KOF_P2" T4 ON T2."DocEntry" = T4."DocEntry" AND T2."LineId" = T4."LineId"
		WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
		AND T3."LogInst" = (SELECT MAX(G0."LogInst") FROM "@ACT_KOF_P2" G0 WHERE G0."DocEntry" = T3."DocEntry")
		AND T4."LogInst" = (SELECT MAX(G1."LogInst")-1 FROM "@ACT_KOF_P2" G1 WHERE G1."DocEntry" = T4."DocEntry")
		AND T3."U_ProdTime" <> T4."U_ProdTime"
		;
END 
IF;

--Wyliczenie czasu produkcji na kalkulacji

IF :error = 0 
AND :object_type = N'CT_KOF' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN 
		UPDATE "@CT_KOF_P2" T2 SET "U_ProdTime" = 
		CEILING(T1."U_SpinYear"/T2."U_DayQty")
		FROM "@CT_KOF_N" T0
 		 INNER JOIN "@CT_KOF_P1" T1 ON T0."DocEntry" = T1."DocEntry"
 		 LEFT OUTER JOIN "@CT_KOF_P2" T2 ON T1."DocEntry" = T2."DocEntry" AND T1."U_Process" = T2."U_Process"
 		 LEFT OUTER JOIN "@ACT_KOF_P2" T3 ON T2."DocEntry" = T3."DocEntry" AND T2."LineId" = T3."LineId"
 		 LEFT OUTER JOIN "@ACT_KOF_P2" T4 ON T2."DocEntry" = T4."DocEntry" AND T2."LineId" = T4."LineId"
		WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
		AND T3."LogInst" = (SELECT MAX(G0."LogInst") FROM "@ACT_KOF_P2" G0 WHERE G0."DocEntry" = T3."DocEntry")
		AND T4."LogInst" = (SELECT MAX(G1."LogInst")-1 FROM "@ACT_KOF_P2" G1 WHERE G1."DocEntry" = T4."DocEntry")
		AND T3."U_DayQty" <> T4."U_DayQty"
		;
END 
IF;

--Wyliczenie kosztów oprzyrządowania na kalkulacji

IF :error = 0 
AND :object_type = N'CT_KOF' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN 
		UPDATE "@CT_KOF_P2" T2 SET "U_AddInsCost" = 
		ROUND(((T2."U_HangNeed"*T2."U_HangCost")/T1."U_SpinYear"),4)
		FROM "@CT_KOF_N" T0
 		 INNER JOIN "@CT_KOF_P1" T1 ON T0."DocEntry" = T1."DocEntry"
 		 LEFT OUTER JOIN "@CT_KOF_P2" T2 ON T1."DocEntry" = T2."DocEntry" AND T1."U_Process" = T2."U_Process"
		WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
		;
END 
IF;

--Wyliczenie ceny oprzyrządowania na kalkulacji

IF :error = 0 
AND :object_type = N'CT_KOF' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN 
		UPDATE "@CT_KOF_P2" T1 SET "U_AddInsPrice" = 
		ROUND(T1."U_AddInsCost"*(1+(T1."U_AddInsMargin"/100)),4)
		FROM "@CT_KOF_N" T0
 		 INNER JOIN "@CT_KOF_P2" T1 ON T0."DocEntry" = T1."DocEntry"
		WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
		;
END 
IF;

--Przypisanie kalkulacji do oferty

IF :error = 0 
AND :object_type = N'23' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN 
		UPDATE "QUT1" T2 SET T2."U_QutCalc" = T1."DocEntry"
		FROM OQUT T0
		 LEFT OUTER JOIN "@CT_KOF_N" T1 ON T0."U_ZOFno" = T1."U_ZofNo"
		 LEFT OUTER JOIN "QUT1" T2 ON T0."DocEntry" = T2."DocEntry"
		WHERE T2."DocEntry" = :list_of_cols_val_tab_del AND T0."U_ZOFno" = T1."U_ZofNo" AND T2."U_DrawRawNo" = T1."U_RawDrawNo"
		AND T1."DocEntry" NOT IN (SELECT DISTINCT IFNULL("U_QutCalc",0) FROM QUT1)
		;
END 
IF;

--Przypisanie kalkulacji do oferty

IF :error = 0 
AND :object_type = N'CT_KOF'
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN 
		UPDATE "QUT1" T2 SET T2."U_QutCalc" = T1."DocEntry"
		FROM OQUT T0
		 LEFT OUTER JOIN "@CT_KOF_N" T1 ON T0."U_ZOFno" = T1."U_ZofNo"
		 LEFT OUTER JOIN "QUT1" T2 ON T0."DocEntry" = T2."DocEntry"
		WHERE T1."DocEntry" = :list_of_cols_val_tab_del AND T0."U_ZOFno" = T1."U_ZofNo" AND T2."U_DrawRawNo" = T1."U_RawDrawNo"
		AND T1."DocEntry" NOT IN (SELECT DISTINCT IFNULL("U_QutCalc",0) FROM QUT1)
		;
END 
IF;

--Przypisanie kosztu procesu na ofercie

IF :error = 0 
AND :object_type = N'CT_KOF' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN 
		UPDATE "QUT1" T1 SET T1."U_Q_ProcCost" = G0."CostSum"
		FROM
		(SELECT T0."DocEntry" AS "DocEntryOF", T2."DocEntry" AS "DocEntryKOF", ROUND(SUM(IFNULL(T3."U_CostSum",0)),2) AS "CostSum"
		FROM OQUT T0
 		INNER JOIN QUT1 T1 ON T0."DocEntry" = T1."DocEntry"
 		INNER JOIN "@CT_KOF_N" T2 ON T1."U_QutCalc" = T2."DocEntry"
 		LEFT OUTER JOIN "@CT_KOF_P1" T3 ON T2."DocEntry" = T3."DocEntry"
 		WHERE T3."DocEntry" = :list_of_cols_val_tab_del
 		GROUP BY T0."DocEntry", T2."DocEntry") G0
		WHERE G0."DocEntryKOF" = :list_of_cols_val_tab_del AND T1."DocEntry" = G0."DocEntryOF" AND T1."U_QutCalc" = G0."DocEntryKOF"
		;
END 
IF;

--Przypisanie ceny procesu na ofercie

IF :error = 0 
AND :object_type = N'CT_KOF' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN 
		UPDATE "QUT1" T1 SET T1."U_Q_ProcPrice" = G0."CostSum"
		FROM
		(SELECT T0."DocEntry" AS "DocEntryOF", T2."DocEntry" AS "DocEntryKOF", ROUND(SUM(IFNULL(T3."U_Price",0)),2) AS "CostSum"
		FROM OQUT T0
 		INNER JOIN QUT1 T1 ON T0."DocEntry" = T1."DocEntry"
 		INNER JOIN "@CT_KOF_N" T2 ON T1."U_QutCalc" = T2."DocEntry"
 		LEFT OUTER JOIN "@CT_KOF_P1" T3 ON T2."DocEntry" = T3."DocEntry"
 		WHERE T3."DocEntry" = :list_of_cols_val_tab_del
 		GROUP BY T0."DocEntry", T2."DocEntry") G0
		WHERE G0."DocEntryKOF" = :list_of_cols_val_tab_del AND T1."DocEntry" = G0."DocEntryOF" AND T1."U_QutCalc" = G0."DocEntryKOF"
		;
END 
IF;

--Przypisanie ceny dodatkowego oprzyrządowania na ofercie

IF :error = 0 
AND :object_type = N'CT_KOF'
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN 
		UPDATE "QUT1" T1 SET T1."U_Q_InsPrice" = G0."AddInsPrice"
		FROM
		(SELECT T0."DocEntry" AS "DocEntryOF", T2."DocEntry" AS "DocEntryKOF", ROUND(SUM(IFNULL(T3."U_AddInsPrice",0)),2) AS "AddInsPrice"
		FROM OQUT T0
 		INNER JOIN QUT1 T1 ON T0."DocEntry" = T1."DocEntry"
 		INNER JOIN "@CT_KOF_N" T2 ON T1."U_QutCalc" = T2."DocEntry"
 		LEFT OUTER JOIN "@CT_KOF_P2" T3 ON T2."DocEntry" = T3."DocEntry"
 		WHERE T3."DocEntry" = :list_of_cols_val_tab_del
 		GROUP BY T0."DocEntry", T2."DocEntry") G0
		WHERE G0."DocEntryKOF" = :list_of_cols_val_tab_del AND T1."DocEntry" = G0."DocEntryOF" AND T1."U_QutCalc" = G0."DocEntryKOF"
		;
END 
IF;

--Przypisanie ceny pakowania na ofercie

IF :error = 0 
AND :object_type = N'CT_KOF' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN 
		UPDATE "QUT1" T1 SET T1."U_Q_PackPrice" = G0."PackPrice"
		FROM
		(SELECT T0."DocEntry" AS "DocEntryOF", T2."DocEntry" AS "DocEntryKOF", ROUND(SUM(IFNULL(T3."U_SPackPrice",0)),2) AS "PackPrice"
		FROM OQUT T0
 		INNER JOIN QUT1 T1 ON T0."DocEntry" = T1."DocEntry"
 		INNER JOIN "@CT_KOF_N" T2 ON T1."U_QutCalc" = T2."DocEntry"
 		LEFT OUTER JOIN "@CT_KOF_P3" T3 ON T2."DocEntry" = T3."DocEntry"
 		WHERE T2."DocEntry" = :list_of_cols_val_tab_del
 		GROUP BY T0."DocEntry", T2."DocEntry") G0
		WHERE G0."DocEntryKOF" = :list_of_cols_val_tab_del AND T1."DocEntry" = G0."DocEntryOF" AND T1."U_QutCalc" = G0."DocEntryKOF"
		;
END 
IF;


--Przypisanie ceny transportu na ofercie

IF :error = 0 
AND :object_type = N'CT_KOF' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN 
		UPDATE "QUT1" T1 SET T1."U_Q_TranspPrice" = G0."TranspPrice"
		FROM
		(SELECT T0."DocEntry" AS "DocEntryOF", T2."DocEntry" AS "DocEntryKOF", ROUND(SUM(IFNULL(T3."U_STranspPrice",0)),2) AS "TranspPrice"
		FROM OQUT T0
 		INNER JOIN QUT1 T1 ON T0."DocEntry" = T1."DocEntry"
 		INNER JOIN "@CT_KOF_N" T2 ON T1."U_QutCalc" = T2."DocEntry"
 		LEFT OUTER JOIN "@CT_KOF_P4" T3 ON T2."DocEntry" = T3."DocEntry"
 		WHERE T2."DocEntry" = :list_of_cols_val_tab_del
 		GROUP BY T0."DocEntry", T2."DocEntry") G0
		WHERE G0."DocEntryKOF" = :list_of_cols_val_tab_del AND T1."DocEntry" = G0."DocEntryOF" AND T1."U_QutCalc" = G0."DocEntryKOF"
		;
END 
IF;

--Wyliczenie sumy ceny dodatkowych operacji na ofercie

IF :error = 0 
AND :object_type = N'23' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN 
		UPDATE "QUT1" T1 SET T1."U_Q_AddPriceAll" = 
		T1."U_Q_InsPrice"+T1."U_Q_PackPrice"+T1."U_Q_TranspPrice"
		FROM OQUT T0
 		INNER JOIN QUT1 T1 ON T0."DocEntry" = T1."DocEntry"
 		WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
		;
END 
IF;

IF :error = 0 
AND :object_type = N'CT_PF_PickReceipt' 
 
THEN 

call CT_Receipt_After(:transaction_type ,:list_of_cols_val_tab_del,  :error,  :error_message);
END 
IF;

--Wyliczenie ceny EXW w PLN na ofercie

IF :error = 0 
AND :object_type = N'23' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN 
		UPDATE "QUT1" T1 SET T1."U_Q_ExwPlnPrice" = 
		T1."U_Q_ProcPrice"+T1."U_Q_InsPrice"+T1."U_Q_PackPrice"
		FROM OQUT T0
 		INNER JOIN QUT1 T1 ON T0."DocEntry" = T1."DocEntry"
 		WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
		;
END 
IF;

--Wyliczenie ceny DDU w PLN na ofercie

IF :error = 0 
AND :object_type = N'23' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN 
		UPDATE "QUT1" T1 SET T1."U_Q_DduPlnPrice" = 
		CASE WHEN T1."U_Q_TranspPrice" = 0 THEN 0 ELSE
		T1."U_Q_ProcPrice"+T1."U_Q_InsPrice"+T1."U_Q_PackPrice"+T1."U_Q_TranspPrice" END
		FROM OQUT T0
 		INNER JOIN QUT1 T1 ON T0."DocEntry" = T1."DocEntry"
 		WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
		;
END 
IF;

--Wyliczenie ceny EXW w EUR na ofercie

IF :error = 0 
AND :object_type = N'23' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN 
		UPDATE "QUT1" T1 SET T1."U_Q_ExwEurPrice" = 
		ROUND((T1."U_Q_ProcPrice"+T1."U_Q_InsPrice"+T1."U_Q_PackPrice")/T2."U_EurExchRate",2)
		FROM OQUT T0
 		INNER JOIN QUT1 T1 ON T0."DocEntry" = T1."DocEntry"
 		LEFT OUTER JOIN "@CT_OF_PD" T2 ON 1=1
 		WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
		;
END 
IF;

--Wyliczenie ceny DDU w EUR na ofercie

IF :error = 0 
AND :object_type = N'23' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN 
		UPDATE "QUT1" T1 SET T1."U_Q_DduEurPrice" = 
		CASE WHEN T1."U_Q_TranspPrice" = 0 THEN 0 ELSE
		ROUND((T1."U_Q_ProcPrice"+T1."U_Q_InsPrice"+T1."U_Q_PackPrice"+T1."U_Q_TranspPrice")/T2."U_EurExchRate",2) END
		FROM OQUT T0
 		INNER JOIN QUT1 T1 ON T0."DocEntry" = T1."DocEntry"
 		LEFT OUTER JOIN "@CT_OF_PD" T2 ON 1=1
 		WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
		;
END 
IF;


--Przypisanie kosztu maskowania na ofercie

IF :error = 0 
AND :object_type = N'CT_KOF' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN 
		UPDATE "QUT1" T1 SET T1."U_Q_MaskCost" = G0."MaskCost"
		FROM
		(SELECT T0."DocEntry" AS "DocEntryOF", T2."DocEntry" AS "DocEntryKOF", ROUND(SUM(IFNULL(T3."U_MaskCost",0)),2) AS "MaskCost"
		FROM OQUT T0
 		INNER JOIN QUT1 T1 ON T0."DocEntry" = T1."DocEntry"
 		INNER JOIN "@CT_KOF_N" T2 ON T1."U_QutCalc" = T2."DocEntry"
 		LEFT OUTER JOIN "@CT_KOF_P1" T3 ON T2."DocEntry" = T3."DocEntry"
 		WHERE T3."DocEntry" = :list_of_cols_val_tab_del
 		GROUP BY T0."DocEntry", T2."DocEntry") G0
		WHERE G0."DocEntryKOF" = :list_of_cols_val_tab_del AND T1."DocEntry" = G0."DocEntryOF" AND T1."U_QutCalc" = G0."DocEntryKOF"
		;
END 
IF;

--Przypisanie ceny zabezpieczeń na ofercie

IF :error = 0 
AND :object_type = N'CT_KOF' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN 
		UPDATE "QUT1" T1 SET T1."U_Q_ZabezPrice" = G0."ZabezPrice"
		,T1."U_Q_MaskPricePLN" = 
		T1."U_Q_MaskCost"+ G0."ZabezPrice"
		FROM
		(SELECT T0."DocEntry" AS "DocEntryOF", T2."DocEntry" AS "DocEntryKOF", ROUND(SUM(IFNULL(T3."U_ZabazPrice",0)),2) AS "ZabezPrice"
		FROM OQUT T0
 		INNER JOIN QUT1 T1 ON T0."DocEntry" = T1."DocEntry"
 		INNER JOIN "@CT_KOF_N" T2 ON T1."U_QutCalc" = T2."DocEntry"
 		LEFT OUTER JOIN "@CT_KOF_P2" T3 ON T2."DocEntry" = T3."DocEntry"
 		WHERE T3."DocEntry" = :list_of_cols_val_tab_del
 		GROUP BY T0."DocEntry", T2."DocEntry") G0
		WHERE G0."DocEntryKOF" = :list_of_cols_val_tab_del AND T1."DocEntry" = G0."DocEntryOF" AND T1."U_QutCalc" = G0."DocEntryKOF"
		;
END 
IF;


--Wyliczenie ceny maskowania w PLN na ofercie

IF :error = 0 
AND :object_type = N'23' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN 
		UPDATE "QUT1" T1 SET T1."U_Q_MaskPricePLN" = 
		T1."U_Q_MaskCost"+T1."U_Q_ZabezPrice"
		FROM OQUT T0
 		INNER JOIN QUT1 T1 ON T0."DocEntry" = T1."DocEntry"
 		WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
		;
END 
IF;



--Wyliczenie ceny maskowania w EUR na ofercie

IF :error = 0 
AND :object_type = N'23' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN 
		UPDATE "QUT1" T1 SET T1."U_Q_MaskPriceEUR" = 
		ROUND((T1."U_Q_MaskCost"+T1."U_Q_ZabezPrice")/T2."U_EurExchRate",2)
		FROM OQUT T0
 		INNER JOIN QUT1 T1 ON T0."DocEntry" = T1."DocEntry"
 		LEFT OUTER JOIN "@CT_OF_PD" T2 ON 1=1
 		WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
		;
END 
IF;

--Przypisanie ZOF do oferty

IF :error = 0 
AND :object_type = N'23' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN 
		UPDATE "QUT1" T2 SET T2."U_Q_NrZOF" = T1."DocEntry"
		FROM OQUT T0
		 LEFT OUTER JOIN "@CT_ZOF_N" T1 ON T0."U_ZOFno" = T1."DocEntry"
		 LEFT OUTER JOIN "@CT_ZOF_P1" T3 ON T3."DocEntry" = T1."DocEntry"
		 LEFT OUTER JOIN "QUT1" T2 ON T0."DocEntry" = T2."DocEntry"
		WHERE T2."DocEntry" = :list_of_cols_val_tab_del AND T0."U_ZOFno" = T1."DocEntry" AND T2."U_DrawRawNo" = T3."U_RawDrawNo"
		AND T1."DocEntry" NOT IN (SELECT DISTINCT IFNULL("U_Q_NrZOF",0) FROM QUT1)
		;
END 
IF;


--Wyliczenie toolingu PLN

IF :error = 0 
AND :object_type = N'CT_KOF' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN 
		UPDATE "QUT1" T1 SET T1."U_Q_ToolingPLN" = G0."Tooling"
		FROM
		(SELECT T0."DocEntry" AS "DocEntryOF", T2."DocEntry" AS "DocEntryKOF", (ROUND(SUM(IFNULL(T3."U_HangNeed",0)),2)*ROUND(SUM(IFNULL(T3."U_HangCost",0)),2)) AS "Tooling"
		FROM OQUT T0
 		INNER JOIN QUT1 T1 ON T0."DocEntry" = T1."DocEntry"
 		INNER JOIN "@CT_KOF_N" T2 ON T1."U_QutCalc" = T2."DocEntry"
 		LEFT OUTER JOIN "@CT_KOF_P2" T3 ON T2."DocEntry" = T3."DocEntry"
 		WHERE T3."DocEntry" = :list_of_cols_val_tab_del
 		GROUP BY T0."DocEntry", T2."DocEntry") G0
		WHERE G0."DocEntryKOF" = :list_of_cols_val_tab_del AND T1."DocEntry" = G0."DocEntryOF" AND T1."U_QutCalc" = G0."DocEntryKOF"
		;
END 
IF;

--Wyliczenie toolingu EUR

IF :error = 0 
AND :object_type = N'CT_KOF' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN 
		UPDATE "QUT1" T1 SET T1."U_Q_ToolingEUR" = G0."Tooling"
		FROM
		(SELECT T0."DocEntry" AS "DocEntryOF", T2."DocEntry" AS "DocEntryKOF", (ROUND(SUM(IFNULL(T3."U_HangNeed",0)),2)*ROUND(SUM(IFNULL(T3."U_HangCost",0)),2)/T4."U_EurExchRate") AS "Tooling"
		FROM OQUT T0
 		INNER JOIN QUT1 T1 ON T0."DocEntry" = T1."DocEntry"
 		INNER JOIN "@CT_KOF_N" T2 ON T1."U_QutCalc" = T2."DocEntry"
 		LEFT OUTER JOIN "@CT_KOF_P2" T3 ON T2."DocEntry" = T3."DocEntry"
		LEFT OUTER JOIN "@CT_OF_PD" T4 ON 1=1
 		WHERE T3."DocEntry" = :list_of_cols_val_tab_del
 		GROUP BY T0."DocEntry", T2."DocEntry", T4."U_EurExchRate") G0
		WHERE G0."DocEntryKOF" = :list_of_cols_val_tab_del AND T1."DocEntry" = G0."DocEntryOF" AND T1."U_QutCalc" = G0."DocEntryKOF"
		;
END 
IF;




--OWTQ--OWTQ--OWTQ--OWTQ--OWTQ--OWTQ--OWTQ--OWTQ--OWTQ--OWTQ--OWTQ--OWTQ--OWTQ--OWTQ--OWTQ--OWTQ--OWTQ--OWTQ--OWTQ--OWTQ--
--OWTQ--OWTQ--OWTQ--OWTQ--OWTQ--OWTQ--OWTQ--OWTQ--OWTQ--OWTQ--OWTQ--OWTQ--OWTQ--OWTQ--OWTQ--OWTQ--OWTQ--OWTQ--OWTQ--OWTQ--

IF :error = 0 
AND :object_type = N'1250000001' 
AND (:transaction_type =N'A')-- OR :transaction_type =N'U')
THEN 

UPDATE t3 SET "U_ToBinCode"= t2."BinCode"
from
 "@CT_PF_OMOR" t0
inner join "@CT_PF_ORSC" t1 on t0."U_Linia1"=t1."U_RscCode"
inner join "OBIN" t2 on t1."U_BinAbs"=t2."AbsEntry"
inner join WTQ1 t3 on t3."U_DocEntry"=t0."DocEntry"
where t3."DocEntry"=:list_of_cols_val_tab_del AND IFNULL(t3."U_ToBinCode",'')='';

UPDATE t4 SET  "U_Tech" = t0. "U_RtgCode"
from
 "@CT_PF_OMOR" t0
inner join WTQ1 t3 on t3."U_DocEntry"=t0."DocEntry"
inner join OWTQ t4 on t3."DocEntry"=t4."DocEntry"
where t3."DocEntry"=:list_of_cols_val_tab_del;


END 
IF;




--Kontrola Jakosci - Zwalnianie partiii złe ilosci
IF :error = 0 
AND :object_type = N'CT_PF_AdditonalBatch' 
AND (:transaction_type =N'U')
then
Rws=(select Top 1 t0."U_Status" "to",t1."U_Status" "from",t0."U_ItemCode",t0."U_DistNumber",t2."AbsEntry",t0."U_WADA" ,
t00."U_BADQTY" ,t3."WhsCode",t4."AbsEntry" "FromAbs" ,t5."AbsEntry" "ToAbs",t4."BinCode" "FromBin",t5."BinCode" "ToBin" 
 

from  
"@CT_PF_AABT" t0 
inner join "@CT_PF_AABT" t1 on t0."Code"=t1."Code" and t0."LogInst"=t1."LogInst"+1 
inner join "@CT_PF_OABT" t00 on t0."Code"=t00."Code" 
inner join "OBTN" t2 on t0."U_DistNumber"=t2."DistNumber" and t0."U_ItemCode" =t2."ItemCode"
inner join OBBQ t3 on t2."AbsEntry"=t3."SnBMDAbs" and "OnHandQty">0 
inner join OBIN t4 on t3."BinAbs"=t4."AbsEntry"

inner join "@CT_PF_ORSC" t6 on t4."BinCode"=t6."U_JKONBIN" 
inner join OBIN t5 on t5."BinCode"=t6."U_IZOLATOR"
where t0."Code"=:list_of_cols_val_tab_del
and t0."LogInst"=(select Max("LogInst") from "@CT_PF_AABT" where "Code"=:list_of_cols_val_tab_del)
--and t4."BinCode" not like '%IZ%' and t4."WhsCode" like '%GW%'
 and t00."U_BADQTY" >0
and t1."U_Status"  <> 'R' and t0."U_Status" ='R'
);

 
insert into  "@PNIZ" select "@PNIZ_S".NextVal ,'',
 "U_ItemCode","WhsCode","WhsCode","U_DistNumber","FromAbs" ,"ToAbs" ,'C',-1,"U_WADA","U_BADQTY" ,null
  from :Rws;
  
  update "@CT_PF_OABT" set "U_BADQTY" =0 where "Code"=:list_of_cols_val_tab_del;
 


END 

IF;
-- MM z izolatora na podmiane indeksów
IF :error = 0 
AND :object_type = N'67' 
AND (:transaction_type =N'A')
then
call CT_Przes_Z_Izolatora(:list_of_cols_val_tab_del);
end if ;

-- MM z Maszyny na izolator recznie

IF  
:error = 0 and
:object_type ='67' 
AND ( :transaction_type =N'A')
THEN

	 select count(*) into cnt
		from
		WTR1 t0
		inner join OWTR t000 on t0."DocEntry"=t000."DocEntry"
		inner join OITL t1 on t0."DocEntry"=t1."DocEntry" and t0."LineNum"=t1."DocLine" and t1."DocType"=67 and t1. "DocQty">0 
		inner join OBTL t2 on t1."LogEntry"=t2."ITLEntry" 
		inner join obin tobin  on t2."BinAbs"=tobin."AbsEntry"
		
	where t0."DocEntry"=:list_of_cols_val_tab_del
		and 
		ifnull(t000."U_Guid",'') <> '1'  and tobin."BinCode" like '%IZ%';
		
	if( :cnt >0)
		then 
			call  CT_MM_ReczneNaIzolator(:list_of_cols_val_tab_del);
		end if;
		
		
		 select count(*) into cnt 
		 from
		WTR1 t0
		where t0."WhsCode" like 'MSU%' ;
		if(:cnt>0)
		then
		
		-- aktualizacja SU po przesunieciu na magazyn surowy
 update su set 
 "U_StatusSU"=case when su."U_IloscOrig"=t3."Quantity" then '3' else '2' end,
 "U_Status"=case when  su."U_IloscOrig"=t3."Quantity" then 'C' else 'O' end ,
 "U_IloscSU"=case when su."U_IloscSU"<t3."Quantity" then 0 else su."U_IloscSU"- t3."Quantity" end,
"U_IloscZlych"= case when su."U_IloscZlych"<t3."Quantity" then 0 else su."U_IloscZlych"- t3."Quantity" end,
"U_IloscZA"=case when  su."U_IloscOrig" -su."U_IloscZA">=t3."Quantity" then     su."U_IloscZA" else      su."U_IloscOrig"   +(su."U_IloscZA"  -t3."Quantity")     end ,
"U_IloscR"= case when su."U_IloscZA"<t3."Quantity" then 0 else su."U_IloscZA"- t3."Quantity" end - case when su."U_IloscSU"<t3."Quantity" then 0 else su."U_IloscSU"- t3."Quantity" end ,
 "U_IloscOrig"=su."U_IloscOrig"-t3."Quantity",
 "U_SSCC"=left('O:'||cast(cast(
 su."U_IloscOrig"-t3."Quantity"
 as int)as nvarchar(20)) ||'ZA:'||cast(cast(
 case when  su."U_IloscOrig" -su."U_IloscZA">=t3."Quantity" then     su."U_IloscZA" else      su."U_IloscOrig"   +(su."U_IloscZA"  -t3."Quantity")     end
  as int)as nvarchar(20))||' ZD:'||cast(cast(
  case when su."U_IloscSU"<t3."Quantity" then 0 else su."U_IloscSU"- t3."Quantity" end 
  as int)as nvarchar(20)),99)
 
from
WTR1 t0
inner join OITL t1 on t0."DocEntry"=t1."DocEntry" and t0."LineNum"=t1."DocLine" and t1."DocType"=67 and t1. "DocQty">0 
inner join OBTL t2 on t1."LogEntry"=t2."ITLEntry" 
inner join 
(
select t1."DocLine",t1."DocEntry" ,t3."BinAbs",t3."SnBMDAbs",t3."Quantity",t1."DocQty",t1."LocCode"
	from
	 OITL t1 --on t0."DocEntry"=t1."DocEntry" and t0."LineNum"=t1."DocLine" and t1."DocType"=67
	inner join OBTL t3 on t1."LogEntry"=t3."ITLEntry" 
	where t1. "DocQty"<0 and t1."DocType"=67
) T3 on t3."DocLine"=t1."DocLine" and t3."DocEntry"=t1."DocEntry"  and t1."DocQty"=t3."DocQty"*-1  and t3."SnBMDAbs"=t2."SnBMDAbs"
inner join "@CT_PF_ORSC" fromRsc on t3."BinAbs"=fromRsc."U_BinAbs"
inner join  "OBIN" fromBin on t3."BinAbs"=fromBin."AbsEntry"
inner join "OBTN" btn on t3."SnBMDAbs"=btn."AbsEntry"
inner join "@CT_WMS_OSTU" su on t0."ItemCode"=su."U_Attribute2" and btn."DistNumber"=su."U_Attribute3" and su."U_StatusSU"='2' and  su."U_BinAbs"=fromBin."AbsEntry"
where t0."DocEntry"=:list_of_cols_val_tab_del and t0."WhsCode" like 'MSU%';

call CT_CheckBigBox();

end if ;

end if ;



--POST -- ręczne Przesuniecie na izolator po zmianie statusu na do przesuniecia
IF  
:error = 0 and
:object_type ='CT_WMS_OSTU' 
AND ( :transaction_type =N'U')
THEN
update "@CT_WMS_OSTU" set


"U_SSCC"=left('O:'||cast(cast("U_IloscOrig" as int)as nvarchar(20)) ||'ZA:'||cast(cast("U_IloscZA" as int)as nvarchar(20))||' ZD:'||cast(cast("U_IloscSU" as int)as nvarchar(20)),99),
 "U_IloscR"="U_IloscZA"-"U_IloscSU"-"U_IloscZlych"
 where "Code"=:list_of_cols_val_tab_del and "U_Attribute5"<>'Wor';
 
	SELECT count(*) into cnt 
	FROM "@CT_WMS_OSTU" t0 
	where "Code"=:list_of_cols_val_tab_del 
	and "U_IloscZlych">0  and "U_StatusSU" ='1';
	if :cnt>0
		THEN 
	call CT_PrzesNaIzolator_PRod (:list_of_cols_val_tab_del );
		END if ;
END  if ;

--CZASOCHLONNOSC--CZASOCHLONNOSC--CZASOCHLONNOSC--CZASOCHLONNOSC--CZASOCHLONNOSC--CZASOCHLONNOSC--CZASOCHLONNOSC--CZASOCHLONNOSC--CZASOCHLONNOSC--CZASOCHLONNOSC--CZASOCHLONNOSC--CZASOCHLONNOSC--CZASOCHLONNOSC--CZASOCHLONNOSC--CZASOCHLONNOSC--CZASOCHLONNOSC--CZASOCHLONNOSC--CZASOCHLONNOSC--CZASOCHLONNOSC--CZASOCHLONNOSC--
--CZASOCHLONNOSC--CZASOCHLONNOSC--CZASOCHLONNOSC--CZASOCHLONNOSC--CZASOCHLONNOSC--CZASOCHLONNOSC--CZASOCHLONNOSC--CZASOCHLONNOSC--CZASOCHLONNOSC--CZASOCHLONNOSC--CZASOCHLONNOSC--CZASOCHLONNOSC--CZASOCHLONNOSC--CZASOCHLONNOSC--CZASOCHLONNOSC--CZASOCHLONNOSC--CZASOCHLONNOSC--CZASOCHLONNOSC--CZASOCHLONNOSC--CZASOCHLONNOSC--

--Aktualizacja średnich czasów w obiekcie czasochłonności

IF :error = 0 
AND :object_type = N'CT_CZASCH' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN 
 CALL "CT_CZASCH_SREDNI_CZAS" (:list_of_cols_val_tab_del)
 ;
END 
IF;

--Aktualizacja sumy czasów w obiekcie czasochłonności

IF :error = 0 
AND :object_type = N'CT_CZASCH' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN 
 CALL "CT_CZASCH_SUMA_CZAS" (:list_of_cols_val_tab_del)
 ;
END 
IF;

--Aktualizacja nazwy procesu i linii do wielkich liter

IF :error = 0 
AND :object_type = N'CT_CZASCH' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN 
 UPDATE "@CT_CZASCH" SET "U_Proces" =
 (SELECT UPPER("U_Proces") FROM "@CT_CZASCH" WHERE "Code" = :list_of_cols_val_tab_del)
 WHERE "Code" = :list_of_cols_val_tab_del
 ;
END 
IF;

IF :error = 0 
AND :object_type = N'CT_CZASCH' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN 
 UPDATE "@CT_CZASCH" SET "U_Linia" =
 (SELECT UPPER("U_Linia") FROM "@CT_CZASCH" WHERE "Code" = :list_of_cols_val_tab_del)
 WHERE "Code" = :list_of_cols_val_tab_del
 ;
END 
IF;

-------------------------------------------------------------------------------------------------------------------
-------- Uzupełnienie dodatkowych pól na przesunięciu dla ulatwienia identyfikacji  i skanowania  -----------------
-------------------------------------------------------------------------------------------------------------------
IF :error = 0
AND :object_type = N'1250000001'
AND (:transaction_type = N'A')
THEN 

UPDATE OWTQ SET 
"U_ToBinCode" = ( select TOP 1 "U_ToBinCode" from "WTQ1" where "DocEntry" = :list_of_cols_val_tab_del),
"U_DrawNoRaw" = ( select T0."U_DrawNoRaw" 
					from "OITM" T0 where T0."ItemCode" = ( 
									select TOP 1 "ItemCode" from "WTQ1" where "DocEntry" = :list_of_cols_val_tab_del order by "LineNum"))
WHERE "DocEntry"=:list_of_cols_val_tab_del AND IFNULL("U_ToBinCode",'')='' AND IFNULL("U_DrawNoRaw", '')='';

END 
IF;

--------------------------------------------------------------------------------------------------------------------------------
IF :error = 0
AND :object_type=N'20' OR :object_type=N'59'
AND (:transaction_type = N'A')
THEN 
update t3   set   "U_SupNumber"=t0."U_NrPartiiKlienta"
    
    from PDN1 T0
INNER JOIN OITL T1 ON T1."DocEntry"=t0."DocEntry" and t1."DocLine" =t0 ."LineNum" and t1."DocType"=20
            INNER JOIN   OBTL T2 on t1."LogEntry"=t2."ITLEntry"
            inner join "OBTN" t3 on t3."AbsEntry"=t2."SnBMDAbs"
            
            where t0."DocEntry"=:list_of_cols_val_tab_del;
            
            END 
IF;
IF :error = 0
AND :object_type = N'67'
AND (:transaction_type = N'A')
then
call CT_MMFromProcess(:list_of_cols_val_tab_del );
call CT_MMToIzolator(:list_of_cols_val_tab_del );
end if;

---------------------------------------------------------------------------------------------------------------------------------

-- Select the return values
select :error, :error_message FROM dummy;


end;-- This is a HANA Database SQL Script