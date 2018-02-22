CREATE PROCEDURE SBO_SP_TransactionNotification
(
	in object_type nvarchar(30), 				-- SBO Object Type
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
cnt2 int;
code nvarchar(200);
big bigint;
binabs int;
dostepne decimal;
pobrane decimal;
rbinabs bigint ;
jkonbin bigint;
jkontrola nvarchar(1);

begin

error := 0;
error_message := N'Ok';
cnt := 0;
cnt2 := 0;
code :='';
rbinabs :=0 ;
jkonbin :=0;
jkontrola :='N';
--------------------------------------------------------------------------------------------------------------------------------

--	ADD	YOUR	CODE	HERE
-- Select the return values
 
IF :error = 0 and :cnt = 0
AND :object_type ='20' 
AND (:transaction_type =N'A')
THEN SELECT  Count(*) 
into cnt 
FROM "PDN1" T0 
WHERE "ItemCode" LIKE 'PP%'
and
 T0."DocEntry" =:list_of_cols_val_tab_del ;

if :cnt>0 
then error:=1 
;
error_message:= N'Brak możliwości zapisu dokumentu PZ. Na pozycji znajduje się indeks PP'
;

end 
if 
;

END 
if 
;



--OCRD--OCRD--OCRD--OCRD--OCRD--OCRD--OCRD--OCRD--OCRD--OCRD--OCRD--OCRD--OCRD--OCRD--OCRD--OCRD--OCRD--
--OCRD--OCRD--OCRD--OCRD--OCRD--OCRD--OCRD--OCRD--OCRD--OCRD--OCRD--OCRD--OCRD--OCRD--OCRD--OCRD--OCRD--

--blokada dodania PH o takim samym numerze NIP 

IF :error = 0 
AND :object_type ='2' 
AND (:transaction_type =N'A') --OR :transaction_type =N'U')
THEN SELECT
      Count(*) 
into cnt 
FROM OCRD T0, 
	 OCRD T1
WHERE T0."CardCode" = :list_of_cols_val_tab_del 
AND
T0."CardCode" <> T1."CardCode"
AND
REPLACE(T0."LicTradNum",'-','') = REPLACE(T1."LicTradNum",'-','')
AND
T0."CardType" = T1."CardType"
AND 
LENGTH(T1."LicTradNum") > 2
AND IFNULL(T0."U_Odb_NIP", 'N') <> 'T' 
;

if :cnt>0 
then error:=1 
;
error_message:='Istnieje już kontrahent o takim numerze NIP'
;

end 
if 
;

END 
if 
;


--OITM--OITM--OITM--OITM--OITM--OITM--OITM--OITM--OITM--OITM--OITM--OITM--OITM--OITM--OITM--OITM--OITM--
--OITM--OITM--OITM--OITM--OITM--OITM--OITM--OITM--OITM--OITM--OITM--OITM--OITM--OITM--OITM--OITM--OITM--

--Kontrola poprawności konstrukcji indeksu
/*
IF :error = 0 
AND :object_type ='4' 
AND (:transaction_type =N'A')-- OR :transaction_type =N'U')
THEN SELECT
      Count(*) 
into cnt
FROM
(SELECT T0."ItemCode" 
FROM OITM T0 
WHERE T0."ItemCode" = :list_of_cols_val_tab_del 
AND
(SUBSTRING(T0."ItemCode",4,5) <> T0."U_CustomerCode"
OR
LEFT("ItemCode",2) <> T0."U_ItemCategory"
OR
(SELECT 
	RIGHT('00000' || CAST(MAX(CAST(RIGHT(G0."ItemCode",5) AS NUMERIC(10,0))) + 1 AS NVARCHAR(5)),5) 
FROM OITM G0 WHERE G0."U_ItemCategory" = T0."U_ItemCategory" AND G0."U_CustomerCode" = T0."U_CustomerCode")
<> RIGHT(T0."ItemCode",5)
))
;

if :cnt>0 
then error:=1 
;
error_message:= N'Niepoprawnie skonstruowany indeks. Wprowadź odpowiednie dane w panelu bocznym i kliknij "lupkę" w polu Indeks.'
;

end 
if 
;

END 
if 
;
*/
/*
--Kontrola danych do Intrastat

IF :error = 0 
AND :object_type ='4' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN SELECT
      Count(*) 
into cnt 
FROM OITM T0 
 LEFT OUTER JOIN ITM10 T1 ON T0."ItemCode" = T1."ItemCode"
WHERE T0."ItemCode" = :list_of_cols_val_tab_del 
AND
T0."InvntItem" = 'Y'
AND
(
T1."ISRelevant" = 'N'
OR
IFNULL(T1."ISCommCode",'') = ''
OR
IFNULL(T1."ISSubMasUn",'') = ''
OR
IFNULL(T1."ISNaTraImp",'') = ''
OR
IFNULL(T1."ISNaTraExp",'') = ''
OR
IFNULL(T1."ISOriCntry",'') = ''
)
;

if :cnt>0 
then error:=1 
;
error_message:= N'Proszę oznaczyć indeks jako podlegający Intrastat i wprowadzić niezbędne dane w zakładce dotyczącej Intrastat.'
;

end 
if 
;

END 
if 
;

*/

--Kontrola wybrania poprawnej grupy materiałów
IF :error = 0 
AND :object_type ='4' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN SELECT
      Count(*) 
into cnt 
FROM OITM T0 
WHERE T0."ItemCode" = :list_of_cols_val_tab_del 
AND
T0."ItmsGrpCod" = 171
;

if :cnt>0 
then error:=1 
;
error_message:= N'Wybierz właściwą grupę materiałów.'
;

end 
if 
;

END 
if 
;

--Kontrola wybrania poprawnej metody dekretacji
IF :error = 0 
AND :object_type ='4' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN SELECT
      Count(*) 
into cnt 
FROM OITM T0 
WHERE T0."ItemCode" = :list_of_cols_val_tab_del 
AND
T0."GLMethod" <> 'C' AND T0."InvntItem"='Y'
;

if :cnt>0 
then error:=1 
;
error_message:= N'Metoda dekretacji w zakładce Dane magazynu musi być ustawiona na Grupa materiałów.'
;

end 
if 
;

END 
if 
;

--Kontrola podania stanu minimalnego dla magazynu chemicznego
IF :error = 0 
AND :object_type ='4' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN SELECT
      Count(*) 
into cnt 
FROM OITM T0 
 LEFT OUTER JOIN OITW T1 ON T0."ItemCode" = T1."ItemCode"
WHERE T0."ItemCode" = :list_of_cols_val_tab_del 
AND
T0."InvntItem" = 'Y'
AND
T1."WhsCode" IN ('MW01','MW01-N')
AND IFNULL(T1."MinStock",0) = 0
;

if :cnt>0 
then error:=1 
;
error_message:= N'Prosze podać stan minimalny dla magazynu chemicznego.'
;

end 
if 
;

END 
if 
;

--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--
--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--ODLN--

--Blokada dodania WZ na indeksy nieprzypisane do danego dostawcy
IF :error = 0 
AND :object_type ='15' 
AND (:transaction_type =N'A')
THEN SELECT
      Count(*) 
into cnt 
FROM ODLN T0
 INNER JOIN DLN1 T1 ON T0."DocEntry" = T1."DocEntry"
 INNER JOIN NNM1 T2 ON T0."Series" = T2."Series"
 INNER JOIN OITM T3 ON T1."ItemCode" = T3."ItemCode"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND
T2."SeriesName" NOT LIKE '%WZPDW%'
AND
T3."ItmsGrpCod" NOT IN (157,160)
AND RIGHT(T0."CardCode",5) <> SUBSTRING(T1."ItemCode",4,5)
;

if :cnt>0 
then error:=1 
;

SELECT TOP 1
 G0."VisOrder"+1 into code
FROM
(
SELECT
 T1."VisOrder"
FROM ODLN T0
 INNER JOIN DLN1 T1 ON T0."DocEntry" = T1."DocEntry"
 INNER JOIN NNM1 T2 ON T0."Series" = T2."Series"
 INNER JOIN OITM T3 ON T1."ItemCode" = T3."ItemCode"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND
T2."SeriesName" NOT LIKE '%WZPDW%'
AND
T3."ItmsGrpCod" NOT IN (157,160)
AND RIGHT(T0."CardCode",5) <> SUBSTRING(T1."ItemCode",4,5)
) G0;

error_message:= N'Indeks nie należy do danego klienta - pozycja nr '  || CAST(:code AS NVARCHAR)
;

end 
if 
;

END 
if 
;

--Blokada dodania drugi raz WZ z tego samego dokumentu tymczasowego

IF :error = 0 
AND :object_type ='15' 
AND (:transaction_type =N'A')
THEN SELECT
      Count(*) 
into cnt 
FROM ODLN T0, ODLN T1
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND
T0."DocEntry" <> T1."DocEntry"
AND
T0."draftKey" = T1."draftKey"
;

if :cnt>0 
then error:=1 
;
error_message:= N'Nie można dodać dokumentu WZ na bazie wybranego dokumentu tymczasowego, ponieważ taki dokument WZ został już utworzony.'
;

end 
if 
;

END 
if 
;

--Blokada WZ z lokalizacji POD (gdy towar u podwykonawcy)
IF :error = 0 and :cnt = 0
AND :object_type ='15' 
AND (:transaction_type =N'A')
THEN SELECT
      COUNT(*) 
into cnt 
FROM
(
SELECT
T6."BinCode", T6."Attr1Val"
FROM ODLN T0
 INNER JOIN DLN1 T1 on T0."DocEntry"=T1."DocEntry"
 LEFT OUTER JOIN OITL T3 on T3."DocEntry"=T1."DocEntry" and T3."DocLine"=T1."LineNum" and T3."DocType"=T1."ObjType"
 LEFT OUTER JOIN ITL1 T4 on T4."LogEntry"=T3."LogEntry"
 LEFT OUTER JOIN OBBQ T5 ON T4."MdAbsEntry" = T5."SnBMDAbs"
 LEFT OUTER JOIN OBIN T6 ON T5."BinAbs" = T6."AbsEntry"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del
) G0
WHERE G0."Attr1Val" LIKE '%POD%' AND G0."BinCode" NOT LIKE '%POD%_WYS%'
;

if :cnt>0 
then error:=1 
;
SELECT TOP 1
 G0."VisOrder"+1 into code
FROM
(
SELECT
T6."BinCode", T6."Attr1Val", T1."VisOrder"
FROM ODLN T0
 INNER JOIN DLN1 T1 on T0."DocEntry"=T1."DocEntry"
 LEFT OUTER JOIN OITL T3 on T3."DocEntry"=T1."DocEntry" and T3."DocLine"=T1."LineNum" and T3."DocType"=T1."ObjType"
 LEFT OUTER JOIN ITL1 T4 on T4."LogEntry"=T3."LogEntry"
 LEFT OUTER JOIN OBTL T5 ON T4."LogEntry" = T5."ITLEntry" 
 LEFT OUTER JOIN OBIN T6 ON T5."BinAbs" = T6."AbsEntry"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del
) G0
WHERE G0."Attr1Val" LIKE '%POD%' AND G0."BinCode" NOT LIKE '%POD%_WYS%';

error_message:= N'Nie możesz robić wydania z lokalizacji POD dla pozycji nr ' || CAST(:code AS NVARCHAR)
;

end 
if 
;

END 
if 
;

--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--
--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--ORDR--

--Blokada sprzedaży z ceną szacunkową
IF :error = 0 
AND :object_type ='17' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN SELECT
      Count(*) 
into cnt 
FROM ORDR T0
 INNER JOIN RDR1 T1 ON T0."DocEntry" = T1."DocEntry" 
 INNER JOIN ITM1 T2 ON T1."ItemCode" = T2."ItemCode" AND T2."PriceList" = '2'
 INNER JOIN ITM1 T3 ON T1."ItemCode" = T3."ItemCode" AND T3."PriceList" = '2'
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND
T2."Price" = 0 AND T3."Price" <> 0
;

if :cnt>0 
then error:=1 
;
error_message:= N'Nie można sprzedawać w cenie szacunkowej.'
;

end 
if 
;

END 
if 
;

--Blokada dodania ZS na indeksy nieprzypisane do danego klienta
IF :error = 0 
AND :object_type ='17' 
AND (:transaction_type =N'A')
THEN SELECT
      Count(*) 
into cnt 
FROM ORDR T0
 INNER JOIN RDR1 T1 ON T0."DocEntry" = T1."DocEntry"
 INNER JOIN NNM1 T2 ON T0."Series" = T2."Series"
 INNER JOIN OITM T3 ON T1."ItemCode" = T3."ItemCode"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND
T2."SeriesName" NOT LIKE '%WZPDW%'
AND
T3."ItmsGrpCod" NOT IN (157,160)
AND RIGHT(T0."CardCode",5) <> SUBSTRING(T1."ItemCode",4,5)
;

if :cnt>0 
then error:=1 
;

SELECT TOP 1
 G0."VisOrder"+1 into code
FROM
(
SELECT
 T1."VisOrder"
FROM ORDR T0
 INNER JOIN RDR1 T1 ON T0."DocEntry" = T1."DocEntry"
 INNER JOIN NNM1 T2 ON T0."Series" = T2."Series"
 INNER JOIN OITM T3 ON T1."ItemCode" = T3."ItemCode"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND
T2."SeriesName" NOT LIKE '%WZPDW%'
AND
T3."ItmsGrpCod" NOT IN (157,160)
AND RIGHT(T0."CardCode",5) <> SUBSTRING(T1."ItemCode",4,5)
) G0;

error_message:= N'Indeks nie należy do danego klienta - pozycja nr '  || CAST(:code AS NVARCHAR)
;

end 
if 
;

END 
if 
;

--Blokada dodania ZS na indeksy surowe
IF :error = 0 
AND :object_type ='17' 
AND (:transaction_type =N'A')
THEN SELECT
      Count(*) 
into cnt 
FROM ORDR T0
 INNER JOIN RDR1 T1 ON T0."DocEntry" = T1."DocEntry"
 INNER JOIN NNM1 T2 ON T0."Series" = T2."Series"
 INNER JOIN OITM T3 ON T1."ItemCode" = T3."ItemCode"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND
T2."SeriesName" NOT LIKE '%WZPDW%'
AND
T3."ItmsGrpCod" NOT IN (157,160)
AND LEFT(T1."ItemCode",2) <> 'WG'
;

if :cnt>0 
then error:=1 
;

SELECT TOP 1
 G0."VisOrder"+1 into code
FROM
(
SELECT
 T1."VisOrder"
FROM ORDR T0
 INNER JOIN RDR1 T1 ON T0."DocEntry" = T1."DocEntry"
 INNER JOIN NNM1 T2 ON T0."Series" = T2."Series"
 INNER JOIN OITM T3 ON T1."ItemCode" = T3."ItemCode"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND
T2."SeriesName" NOT LIKE '%WZPDW%'
AND
T3."ItmsGrpCod" NOT IN (157,160)
AND LEFT(T1."ItemCode",2) <> 'WG'
) G0;

error_message:= N'Indeks surowy nie może być użyty na harmonogramie - pozycja nr '  || CAST(:code AS NVARCHAR)
;

end 
if 
;

END 
if 
;

--OPOR--OPOR--OPOR--OPOR--OPOR--OPOR--OPOR--OPOR--OPOR--OPOR--OPOR--OPOR--OPOR--OPOR--OPOR--OPOR--OPOR--
--OPOR--OPOR--OPOR--OPOR--OPOR--OPOR--OPOR--OPOR--OPOR--OPOR--OPOR--OPOR--OPOR--OPOR--OPOR--OPOR--OPOR--
/*
--Blokada zakupu na magazyn chemiczny bez potwierdzenie certyfikatów dla indeksu
IF :error = 0 
AND :object_type ='22' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN SELECT
      Count(*) 
into cnt 
FROM OPOR T0
 INNER JOIN POR1 T1 ON T0."DocEntry" = T1."DocEntry" 
 INNER JOIN OITM T2 ON T1."ItemCode" = T2."ItemCode"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND
T1."WhsCode" IN ('MW01','MW01-N')
AND
IFNULL(T2."U_PaintCertifcate",'N') = 'N'
;

if :cnt>0 
then error:=1 
;
error_message:= N'Nie można zamówić indeksu na magazyn chemiczny bez potwierdzonych certyfikatów.'
;

end 
if 
;

END 
if 
;

--Kontrola podania ceny zakupu dla materiałów, które nie są powierzone
IF :error = 0 
AND :object_type ='22' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN SELECT
      Count(*) 
into cnt 
FROM OPOR T0
 INNER JOIN POR1 T1 ON T0."DocEntry" = T1."DocEntry" 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND
T1."WhsCode" IN ('MSU01','MSU01-N')
AND
T1."LineTotal" = 0
;

if :cnt>0 
then error:=1 
;
error_message:= N'Zamówienia zakupu na materiały własne muszę mieć wpisaną cenę.'
;

end 
if 
;

END 
if 
;
*/
--Blokada aktualizacji zamówień specyficznych przez nieuprawnionych użytkowników
IF :error = 0 
AND :object_type ='22' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN SELECT
      Count(*) 
into cnt 
FROM OPOR T0
 LEFT OUTER JOIN (SELECT G0."DocEntry", G0."ObjType", MAX(G0."LogInstanc") AS "LogInstanc" 
 				  FROM ADOC G0 GROUP BY G0."DocEntry", G0."ObjType") T1 ON T0."DocEntry" = T1."DocEntry" AND T0."ObjType" = T1."ObjType"
 LEFT OUTER JOIN ADOC T4 ON T1."DocEntry" = T4."DocEntry" AND T1."ObjType" = T4."ObjType" AND T1."LogInstanc" = T4."LogInstanc"				  
 INNER JOIN NNM1 T2 ON T0."Series" = T2."Series" 
 INNER JOIN OUSR T5 ON T0."UserSign" = T5."USERID" 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND T4."U_POStatus" > 0 AND T0."U_POStatus" >= 1
AND
IFNULL(T5."U_SpecificPO",'T') = 'T'
AND
T2."SeriesName" LIKE 'ZAM%'
;

if :cnt>0 
then error:=1 
;
error_message:= N'Nie masz uprawnień do aktualizacji zamówień zakupu.'
;

end
if
;

END 
if 
;

 --##MPASZ  blokada dla typu dokumentu  dla potrzeb zakupów wewnętrznych

IF :error = 0 
AND :object_type = '22'
AND (:transaction_type = N'A' OR :transaction_type =N'U')
THEN SELECT 
	Count(*)
	into cnt
	FROM  OPOR T0
		INNER JOIN NNM1 T2 ON T0."Series" = T2."Series" 
	WHERE T2."SeriesName" LIKE 'Seria%'
;

if :cnt>0
then error :=1
;
error_message:= N'Wybierz poprawną serię dokumentu.'
;

--##MPASZ ### END


end 
if 
;

END 
if 
;

--Wymuszenie przekazania zamówienia do dyrektora
IF :error = 0 
AND :object_type ='22' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN SELECT
      Count(*) 
into cnt 
FROM OPOR T0
 LEFT OUTER JOIN (SELECT G0."DocEntry", G0."ObjType", MAX(G0."LogInstanc") AS "LogInstanc" 
 				  FROM ADOC G0 GROUP BY G0."DocEntry", G0."ObjType") T1 ON T0."DocEntry" = T1."DocEntry" AND T0."ObjType" = T1."ObjType"
 LEFT OUTER JOIN ADOC T4 ON T1."DocEntry" = T4."DocEntry" AND T1."ObjType" = T4."ObjType" AND T1."LogInstanc" = T4."LogInstanc"				  
 INNER JOIN NNM1 T2 ON T0."Series" = T2."Series" 
 INNER JOIN OUSR T5 ON T0."UserSign" = T5."USERID"  
WHERE T0."DocEntry" = :list_of_cols_val_tab_del
AND T0."U_Status_Zam" not in ('3','7') AND T4."U_Status_Zam" in ('1', '7')
AND
T2."SeriesName" LIKE 'ZAK%'
;

if :cnt>0 
then error:=1 
;
error_message:= N'Wyslij zamówienie do akceptacji Dyr_zak/log.'
;

end 
if 
;

END 
if 
;
/*
--Wymuszenie przekazania zamówienia do dyrektora finansowego, gdy zamówienie 4-8tys
IF :error = 0 
AND :object_type ='22' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN SELECT
      Count(*) 
into cnt 
FROM OPOR T0
 LEFT OUTER JOIN (SELECT G0."DocEntry", G0."ObjType", MAX(G0."LogInstanc") AS "LogInstanc" 
 				  FROM ADOC G0 GROUP BY G0."DocEntry", G0."ObjType") T1 ON T0."DocEntry" = T1."DocEntry" AND T0."ObjType" = T1."ObjType"
 LEFT OUTER JOIN ADOC T4 ON T1."DocEntry" = T4."DocEntry" AND T1."ObjType" = T4."ObjType" AND T1."LogInstanc" = T4."LogInstanc"				  
 INNER JOIN NNM1 T2 ON T0."Series" = T2."Series" 
 INNER JOIN OUSR T5 ON T0."UserSign" = T5."USERID"  
WHERE T0."DocEntry" = :list_of_cols_val_tab_del
AND T0."U_Status_Zam" not in ('4','7')  AND T4."U_Status_Zam" not in ('3','7')
AND
T2."SeriesName" LIKE 'ZAK%'					
AND (T0."DocTotal"-T0."VatSum") >= 4000 --AND (T0."DocTotal"-T0."VatSum") <= 8000
;

if :cnt>0 
then error:=1 
;
error_message:= N'Wyslij zamówienie do akceptacji dyrektora finansowego.'
;

end 

if 
;

END 
if 
;
*/
--Wymuszenie przekazania zamówienia do dyrektora zakładu, gdy zamówienie >8tys
IF :error = 0 
AND :object_type ='22' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN SELECT
      Count(*) 
into cnt 
FROM OPOR T0
 LEFT OUTER JOIN (SELECT G0."DocEntry", G0."ObjType", MAX(G0."LogInstanc") AS "LogInstanc" 
 				  FROM ADOC G0 GROUP BY G0."DocEntry", G0."ObjType") T1 ON T0."DocEntry" = T1."DocEntry" AND T0."ObjType" = T1."ObjType"
 LEFT OUTER JOIN ADOC T4 ON T1."DocEntry" = T4."DocEntry" AND T1."ObjType" = T4."ObjType" AND T1."LogInstanc" = T4."LogInstanc"				  
 INNER JOIN NNM1 T2 ON T0."Series" = T2."Series" 
 INNER JOIN OUSR T5 ON T0."UserSign" = T5."USERID"  
WHERE T0."DocEntry" = :list_of_cols_val_tab_del
AND T0."U_Status_Zam" not in ('2','7') AND T4."U_Status_Zam"  in ('4','7')
AND
T2."SeriesName" LIKE 'ZAK%'
AND (T0."DocTotal"-T0."VatSum") >= 8000
;

if :cnt>0 
then error:=1 
;
error_message:= N'Wyslij zamówienie do akceptacji dyrektora zakładu.'
;

end 
if 
;

END 
if 
;

--Akceptacja zamówienia przez dyrektora
IF :error = 0 
AND :object_type ='22' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN SELECT
      Count(*) 
into cnt 
FROM OPOR T0
 LEFT OUTER JOIN (SELECT G0."DocEntry", G0."ObjType", MAX(G0."LogInstanc") AS "LogInstanc" 
 				  FROM ADOC G0 GROUP BY G0."DocEntry", G0."ObjType") T1 ON T0."DocEntry" = T1."DocEntry" AND T0."ObjType" = T1."ObjType"
 LEFT OUTER JOIN ADOC T4 ON T1."DocEntry" = T4."DocEntry" AND T1."ObjType" = T4."ObjType" AND T1."LogInstanc" = T4."LogInstanc"				  
 INNER JOIN NNM1 T2 ON T0."Series" = T2."Series"
 INNER JOIN OUSR T5 ON T0."UserSign" = T5."USERID"   
WHERE T0."DocEntry" = :list_of_cols_val_tab_del
AND T0."U_POStatus" = 4 AND T4."U_POStatus" = 1
AND
IFNULL(T5."U_POAccept",'N') <> 'T'
AND
T2."SeriesName" LIKE 'ZAM%'
AND (T0."DocTotal"-T0."VatSum") <= 4000
;

if :cnt>0 
then error:=1 
;
error_message:= N'Nie masz uprawnień do zatwierdzania zamówień.'
;

end 
if 
;

END 
if 
;

--Akceptacja zamówienia przez dyrektora finansowego
IF :error = 0 
AND :object_type ='22' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN SELECT
      Count(*) 
into cnt 
FROM OPOR T0
 LEFT OUTER JOIN (SELECT G0."DocEntry", G0."ObjType", MAX(G0."LogInstanc") AS "LogInstanc" 
 				  FROM ADOC G0 GROUP BY G0."DocEntry", G0."ObjType") T1 ON T0."DocEntry" = T1."DocEntry" AND T0."ObjType" = T1."ObjType"
 LEFT OUTER JOIN ADOC T4 ON T1."DocEntry" = T4."DocEntry" AND T1."ObjType" = T4."ObjType" AND T1."LogInstanc" = T4."LogInstanc"				  
 INNER JOIN NNM1 T2 ON T0."Series" = T2."Series"
 INNER JOIN OUSR T5 ON T0."UserSign" = T5."USERID"   
WHERE T0."DocEntry" = :list_of_cols_val_tab_del
AND T0."U_POStatus" = 4 AND T4."U_POStatus" = 2
AND
IFNULL(T5."U_POAccept",'N') <> 'T'
AND
T2."SeriesName" LIKE 'ZAM%'
AND (T0."DocTotal"-T0."VatSum") > 4000 AND (T0."DocTotal"-T0."VatSum") <= 8000
;

if :cnt>0 
then error:=1 
;
error_message:= N'Nie masz uprawnień do zatwierdzania zamówień.'
;

end 
if 
;

END 
if 
;

--Akceptacja zamówienia przez dyrektora zakładu
IF :error = 0 
AND :object_type ='22' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN SELECT
      Count(*) 
into cnt 
FROM OPOR T0
 LEFT OUTER JOIN (SELECT G0."DocEntry", G0."ObjType", MAX(G0."LogInstanc") AS "LogInstanc" 
 				  FROM ADOC G0 GROUP BY G0."DocEntry", G0."ObjType") T1 ON T0."DocEntry" = T1."DocEntry" AND T0."ObjType" = T1."ObjType"
 LEFT OUTER JOIN ADOC T4 ON T1."DocEntry" = T4."DocEntry" AND T1."ObjType" = T4."ObjType" AND T1."LogInstanc" = T4."LogInstanc"				  
 INNER JOIN NNM1 T2 ON T0."Series" = T2."Series"
 INNER JOIN OUSR T5 ON T0."UserSign" = T5."USERID"   
WHERE T0."DocEntry" = :list_of_cols_val_tab_del
AND T0."U_POStatus" = 4 AND T4."U_POStatus" = 3
AND
IFNULL(T5."U_POAccept",'N') <> 'T'
AND
T2."SeriesName" LIKE 'ZAM%'
AND (T0."DocTotal"-T0."VatSum") > 8000
;

if :cnt>0 
then error:=1 
;
error_message:= N'Nie masz uprawnień do zatwierdzania zamówień.'
;

end 
if 
;

END 
if 
;


--Blokada ominięcia akceptacji dyrektora
IF :error = 0 
AND :object_type ='22' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN SELECT
      Count(*) 
into cnt 
FROM OPOR T0
 LEFT OUTER JOIN (SELECT G0."DocEntry", G0."ObjType", MAX(G0."LogInstanc") AS "LogInstanc" 
 				  FROM ADOC G0 GROUP BY G0."DocEntry", G0."ObjType") T1 ON T0."DocEntry" = T1."DocEntry" AND T0."ObjType" = T1."ObjType"
 LEFT OUTER JOIN ADOC T4 ON T1."DocEntry" = T4."DocEntry" AND T1."ObjType" = T4."ObjType" AND T1."LogInstanc" = T4."LogInstanc"				  
 INNER JOIN NNM1 T2 ON T0."Series" = T2."Series"  
 INNER JOIN OUSR T5 ON T0."UserSign" = T5."USERID" 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del
AND T0."U_POStatus" > 5 AND T4."U_POStatus" = 0
--AND (T0."DocTotal"-T0."VatSum") <= 4000
AND
T2."SeriesName" LIKE 'ZAM%'
;

if :cnt>0 
then error:=1 
;
error_message:= N'Nie możesz pominąć akceptacji dyrektora.'
;

end 
if 
;

END 
if 
;




--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--
--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--OPDN--
/*
--Blokada dodania PZ z ilością większą niż na zamówieniu
IF :error = 0 
AND :object_type ='20' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN SELECT
      Count(*) 
into cnt 
FROM OPDN T0
 LEFT OUTER JOIN PDN1 T1 ON T0."DocEntry" = T1."DocEntry" 
 LEFT OUTER JOIN POR1 T2 ON T1."BaseEntry" = T2."DocEntry" AND T1."BaseType" = T2."ObjType" AND T1."BaseLine" = T2."LineNum"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND
T1."Quantity" > IFNULL(T2."Quantity",0)
;

if :cnt>0 
then error:=1 
;
error_message:= N'Ilość na PZ przekracza ilość z zamówienia. Zapisz jako dokument tymczasowy.'
;

end 
if 
;

END 
if 
;
*/

--Kontrola wpisania poprawnej ilości partii dla pozycji

IF :error = 0 and :cnt = 0
AND :object_type ='20' 
AND (:transaction_type =N'A')
THEN SELECT
      COUNT(*) 
into cnt 
FROM
(
SELECT
T1."NumPerMsr", COUNT(T1."LineNum") AS "BatchNo", T0."Series"
 --T1."LineNum", T1."ItemCode", T1."NumPerMsr", COUNT(T1."LineNum")
FROM OPDN T0
 INNER JOIN PDN1 T1 on T0."DocEntry"=T1."DocEntry"
 --INNER JOIN POR1 T2 on T1."BaseEntry"=T2."DocEntry" and T1."BaseType"=T2."ObjType" and T1."BaseLine"=T2."LineNum"
 LEFT OUTER JOIN OITL T3 on T3."DocEntry"=T1."DocEntry" and T3."DocLine"=T1."LineNum" and T3."DocType"=T1."ObjType"
 LEFT OUTER JOIN ITL1 T4 on T4."LogEntry"=T3."LogEntry"
 LEFT OUTER JOIN OITM T5 on T1."ItemCode" = T5."ItemCode"
 --INNER JOIN OBTN T5 on T4."SysNumber"=T5."SysNumber" and T4."ItemCode"=T5."ItemCode" 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T5."ManBtchNum" = 'Y'
GROUP BY T1."LineNum", T1."NumPerMsr", T0."Series"
--HAVING T1."NumPerMsr" = COUNT(T1."LineNum")
) G0
WHERE G0."NumPerMsr" <> G0."BatchNo" AND G0."Series" NOT IN (134)
;

if :cnt>0 
then error:=1 
;
SELECT TOP 1
 G0."VisOrder"+1 into code
FROM
(
SELECT
T1."NumPerMsr", COUNT(T1."LineNum") AS "BatchNo", T1."VisOrder", T0."Series"
 --T1."LineNum", T1."ItemCode", T1."NumPerMsr", COUNT(T1."LineNum")
FROM OPDN T0
 INNER JOIN PDN1 T1 on T0."DocEntry"=T1."DocEntry"
 --INNER JOIN POR1 T2 on T1."BaseEntry"=T2."DocEntry" and T1."BaseType"=T2."ObjType" and T1."BaseLine"=T2."LineNum"
 LEFT OUTER JOIN OITL T3 on T3."DocEntry"=T1."DocEntry" and T3."DocLine"=T1."LineNum" and T3."DocType"=T1."ObjType"
 LEFT OUTER JOIN ITL1 T4 on T4."LogEntry"=T3."LogEntry"
 LEFT OUTER JOIN OITM T5 on T1."ItemCode" = T5."ItemCode"
 --INNER JOIN OBTN T5 on T4."SysNumber"=T5."SysNumber" and T4."ItemCode"=T5."ItemCode" 
WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T5."ManBtchNum" = 'Y'
GROUP BY T1."LineNum", T1."NumPerMsr", T1."VisOrder", T0."Series"
--HAVING T1."NumPerMsr" = COUNT(T1."LineNum")
) G0
WHERE G0."NumPerMsr" <> G0."BatchNo" AND G0."Series" NOT IN (134);

error_message:= N'Liczba partii niezgodna z ilością palet dla pozycji nr ' || CAST(:code AS NVARCHAR)
;

end 
if 
;

END 
if 
;

--Kontrola podania lokalizacji innej niż systemowa

IF :error = 0 and :cnt = 0
AND :object_type ='20' 
AND (:transaction_type =N'A')
THEN SELECT
      COUNT(*) 
into cnt 
FROM
(
SELECT
T6."BinCode"
FROM OPDN T0
 INNER JOIN PDN1 T1 on T0."DocEntry"=T1."DocEntry"
 LEFT OUTER JOIN OITL T3 on T3."DocEntry"=T1."DocEntry" and T3."DocLine"=T1."LineNum" and T3."DocType"=T1."ObjType"
 LEFT OUTER JOIN ITL1 T4 on T4."LogEntry"=T3."LogEntry"
-- LEFT OUTER JOIN OBBQ T5 ON T4."MdAbsEntry" = T5."SnBMDAbs"
 LEFT OUTER JOIN OBTL T5 ON T4."LogEntry" = T5."ITLEntry"
 LEFT OUTER JOIN OBIN T6 ON T5."BinAbs" = T6."AbsEntry"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del
) G0
WHERE G0."BinCode" LIKE '%SYSTEM%'
;

if :cnt>0 
then error:=1 
;
SELECT TOP 1
 G0."VisOrder"+1 into code
FROM
(
SELECT
T6."BinCode", T1."VisOrder"
FROM OPDN T0
 INNER JOIN PDN1 T1 on T0."DocEntry"=T1."DocEntry"
 LEFT OUTER JOIN OITL T3 on T3."DocEntry"=T1."DocEntry" and T3."DocLine"=T1."LineNum" and T3."DocType"=T1."ObjType"
 LEFT OUTER JOIN ITL1 T4 on T4."LogEntry"=T3."LogEntry"
 LEFT OUTER JOIN OBTL T5 ON T4."LogEntry" = T5."ITLEntry" 
-- LEFT OUTER JOIN OBBQ T5 ON T4."MdAbsEntry" = T5."SnBMDAbs"
 LEFT OUTER JOIN OBIN T6 ON T5."BinAbs" = T6."AbsEntry"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del
) G0
WHERE G0."BinCode" LIKE '%SYSTEM%';

error_message:= N'Wskaż poprawną lokalizację dla pozycji nr ' || CAST(:code AS NVARCHAR)
;

end 
if 
;

END 
if 
;


--Blokada dodania PZPDW na indeks niebędący na stanie podwykonawcy
IF :error = 0 and :cnt = 0
AND :object_type ='20' 
AND (:transaction_type =N'A')
THEN SELECT
      Count(*) 
into cnt 
FROM
(SELECT
  T2."SeriesName"
FROM OPDN T0
 INNER JOIN PDN1 T1 ON T0."DocEntry" = T1."DocEntry"
 INNER JOIN NNM1 T2 ON T0."Series" = T2."Series"
 LEFT OUTER JOIN (SELECT
	 					DISTINCT T0."ItemCode"
					  FROM OBBQ T0  
						LEFT OUTER JOIN OBIN T3 ON T0."BinAbs" = T3."AbsEntry" 
					  WHERE T0."OnHandQty" <> 0 AND T3."Attr1Val" LIKE '%POD%') G0 ON RIGHT(T1."ItemCode",LENGTH(T1."ItemCode")-2) = IFNULL(RIGHT(G0."ItemCode",LENGTH(G0."ItemCode")-2),'')
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
--AND
--T2."SeriesName" LIKE '%PZPDW%'
AND
RIGHT(T1."ItemCode",LENGTH(T1."ItemCode")-2) <> IFNULL(RIGHT(G0."ItemCode",LENGTH(G0."ItemCode")-2),'')
) G1
WHERE G1."SeriesName" LIKE '%PZPDW%'
;

if :cnt>0 
then error:=1 
;

SELECT TOP 1
 G0."VisOrder"+1 into code
FROM
(
SELECT
 T1."VisOrder"
FROM OPDN T0
 INNER JOIN PDN1 T1 ON T0."DocEntry" = T1."DocEntry"
 INNER JOIN NNM1 T2 ON T0."Series" = T2."Series"
 LEFT OUTER JOIN (SELECT
	 					DISTINCT T0."ItemCode"
					  FROM OBBQ T0  
						LEFT OUTER JOIN OBIN T3 ON T0."BinAbs" = T3."AbsEntry" 
					  WHERE T0."OnHandQty" <> 0 AND T3."Attr1Val" LIKE '%POD%') G0 ON RIGHT(T1."ItemCode",LENGTH(T1."ItemCode")-2) = IFNULL(RIGHT(G0."ItemCode",LENGTH(G0."ItemCode")-2),'')
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND
T2."SeriesName" LIKE '%PZPDW%'
AND
RIGHT(T1."ItemCode",LENGTH(T1."ItemCode")-2) <> IFNULL(RIGHT(G0."ItemCode",LENGTH(G0."ItemCode")-2),'')
) G0;

error_message:= N'Wybrany indeks nie został wydany do podwykonawcy, więc nie może być przyjęty - pozycja nr '  || CAST(:code AS NVARCHAR)
;

end 
if 
;

END 
if 
;

--Blokada dodania PZPDW na ilość większą niż wydana do podwykonawcy
IF :error = 0 and :cnt = 0
AND :object_type ='20' 
AND (:transaction_type =N'A')
THEN SELECT
      Count(*) 
into cnt 
FROM
(SELECT
  T2."SeriesName"
FROM OPDN T0
 INNER JOIN PDN1 T1 ON T0."DocEntry" = T1."DocEntry"
 INNER JOIN NNM1 T2 ON T0."Series" = T2."Series"
 LEFT OUTER JOIN (SELECT
	  				T0."ItemCode", SUM(IFNULL(T0."OnHandQty",0)) AS "OnHandQty"
				  FROM OBBQ T0 
					LEFT OUTER JOIN OBIN T3 ON T0."BinAbs" = T3."AbsEntry" 
				  WHERE T0."OnHandQty" <> 0 AND T3."Attr1Val" LIKE '%POD%'
				  GROUP BY T0."ItemCode") G0 ON RIGHT(T1."ItemCode",LENGTH(T1."ItemCode")-2) = IFNULL(RIGHT(G0."ItemCode",LENGTH(G0."ItemCode")-2),'')
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
--AND
--T2."SeriesName" LIKE '%PZPDW%'
AND
T1."InvQty" > IFNULL(G0."OnHandQty",0)
) G1
WHERE G1."SeriesName" LIKE '%PZPDW%'
;

if :cnt>0 
then error:=1 
;

SELECT TOP 1
 G0."VisOrder"+1 into code
FROM
(
SELECT
 T1."VisOrder"
FROM OPDN T0
 INNER JOIN PDN1 T1 ON T0."DocEntry" = T1."DocEntry"
 INNER JOIN NNM1 T2 ON T0."Series" = T2."Series"
 LEFT OUTER JOIN (SELECT
	  				T0."ItemCode", SUM(IFNULL(T0."OnHandQty",0)) AS "OnHandQty"
				  FROM OBBQ T0 
					LEFT OUTER JOIN OBIN T3 ON T0."BinAbs" = T3."AbsEntry" 
				  WHERE T0."OnHandQty" <> 0 AND T3."Attr1Val" LIKE '%POD%'
				  GROUP BY T0."ItemCode") G0 ON RIGHT(T1."ItemCode",LENGTH(T1."ItemCode")-2) = IFNULL(RIGHT(G0."ItemCode",LENGTH(G0."ItemCode")-2),'')
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND
T2."SeriesName" LIKE '%PZPDW%'
AND
T1."InvQty" > IFNULL(G0."OnHandQty",0)
) G0;

error_message:= N'Ilość przekracza ilość wydaną do podwykonawcy dla pozycji nr '  || CAST(:code AS NVARCHAR)
;

end 
if 
;

END 
if 
;

--Blokada PZ na lokalizację POD (gdy towar u podwykonawcy)
IF :error = 0 and :cnt = 0
AND :object_type ='20' 
AND (:transaction_type =N'A')
THEN SELECT
      COUNT(*) 
into cnt 
FROM
(
SELECT
T6."BinCode", T6."Attr1Val"
FROM OPDN T0
 INNER JOIN PDN1 T1 on T0."DocEntry"=T1."DocEntry"
 LEFT OUTER JOIN OITL T3 on T3."DocEntry"=T1."DocEntry" and T3."DocLine"=T1."LineNum" and T3."DocType"=T1."ObjType"
 LEFT OUTER JOIN ITL1 T4 on T4."LogEntry"=T3."LogEntry"
 LEFT OUTER JOIN OBBQ T5 ON T4."MdAbsEntry" = T5."SnBMDAbs"
 LEFT OUTER JOIN OBIN T6 ON T5."BinAbs" = T6."AbsEntry"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del
) G0
WHERE G0."Attr1Val" LIKE '%POD%' AND G0."BinCode" NOT LIKE '%POD%_WYS%'
;

if :cnt>0 
then error:=1 
;
SELECT TOP 1
 G0."VisOrder"+1 into code
FROM
(
SELECT
T6."BinCode", T6."Attr1Val", T1."VisOrder"
FROM OPDN T0
 INNER JOIN PDN1 T1 on T0."DocEntry"=T1."DocEntry"
 LEFT OUTER JOIN OITL T3 on T3."DocEntry"=T1."DocEntry" and T3."DocLine"=T1."LineNum" and T3."DocType"=T1."ObjType"
 LEFT OUTER JOIN ITL1 T4 on T4."LogEntry"=T3."LogEntry"
 LEFT OUTER JOIN OBBQ T5 ON T4."MdAbsEntry" = T5."SnBMDAbs"
 LEFT OUTER JOIN OBIN T6 ON T5."BinAbs" = T6."AbsEntry"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del
) G0
WHERE G0."Attr1Val" LIKE '%POD%' AND G0."BinCode" NOT LIKE '%POD%_WYS%';

error_message:= N'Nie możesz robić przyjęcia na lokalizację POD dla pozycji nr ' || CAST(:code AS NVARCHAR)
;

end 
if 
;

END 
if 
;

--Blokada dodania PZ na indeksy nieprzypisane do danego dostawcy
IF :error = 0 
AND :object_type ='20' 
AND (:transaction_type =N'A')
THEN SELECT
      Count(*) 
into cnt 
FROM OPDN T0
 INNER JOIN PDN1 T1 ON T0."DocEntry" = T1."DocEntry"
 INNER JOIN NNM1 T2 ON T0."Series" = T2."Series"
 INNER JOIN OITM T3 ON T1."ItemCode" = T3."ItemCode"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND
T2."SeriesName" NOT LIKE '%PZPDW%'
AND
T3."ItmsGrpCod" NOT IN (157,160)
AND RIGHT(T0."CardCode",5) <> SUBSTRING(T1."ItemCode",4,5)
AND T3."InvntItem" = 'Y'
;

if :cnt>0 
then error:=1 
;

SELECT TOP 1
 G0."VisOrder"+1 into code
FROM
(
SELECT
 T1."VisOrder"
FROM OPDN T0
 INNER JOIN PDN1 T1 ON T0."DocEntry" = T1."DocEntry"
 INNER JOIN NNM1 T2 ON T0."Series" = T2."Series"
 INNER JOIN OITM T3 ON T1."ItemCode" = T3."ItemCode"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND
T2."SeriesName" NOT LIKE '%PZPDW%'
AND
T3."ItmsGrpCod" NOT IN (157,160)
AND RIGHT(T0."CardCode",5) <> SUBSTRING(T1."ItemCode",4,5)
) G0;

error_message:= N'Indeks nie należy do danego klienta - pozycja nr '  || CAST(:code AS NVARCHAR)
;

end 
if 
;

END 
if 
;

--Blokada dodania drugi raz PZ z tego samego dokumentu tymczasowego

IF :error = 0 
AND :object_type ='20' 
AND (:transaction_type =N'A')
THEN SELECT
      Count(*) 
into cnt 
FROM OPDN T0, OPDN T1
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND
T0."DocEntry" <> T1."DocEntry"
AND
T0."draftKey" = T1."draftKey"
;

if :cnt>0 
then error:=1 
;
error_message:= N'Nie można dodać dokumentu PZ na bazie wybranego dokumentu tymczasowego, ponieważ taki dokument PZ został już utworzony.'
;

end 
if 
;

END 
if 
;

--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--
--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--OPCH--

--Blokada dodania faktury bez numeru referencyjnego
IF :error = 0 
AND :object_type ='18' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN SELECT
      Count(*) 
into cnt 
FROM OPCH T0
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND
IFNULL(T0."NumAtCard",'') = ''
;

if :cnt>0 
then error:=1 
;
error_message:= N'Należy wpisać numer refferencyjny dostawcy.'
;

end 
if 
;

END 
if 
;
/*
--Blokada dodania faktury bez dokumentu bazowego
IF :error = 0 
AND :object_type ='18' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN SELECT
      Count(*) 
into cnt 
FROM OPCH T0
 INNER JOIN PCH1 T1 ON T0."DocEntry" = T1."DocEntry"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND
IFNULL(T1."BaseEntry",0) = 0
;

if :cnt>0 
then error:=1 
;
error_message:= N'Faktura musi bazować na dokumencie zamówienia zakupu lub dokumencie PZ.'
;

end 
if 
;

END 
if 
;

--Blokada dodania faktury przez nieuprawnionego użytkownika
IF :error = 0 
AND :object_type ='18' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN SELECT
      Count(*) 
into cnt 
FROM OPCH T0
WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
AND
T0."UserSign" IN ('45')
;

if :cnt>0 
then error:=1 
;
error_message:= N'Nie możesz zatwierdzać faktur zakupu.'
;

end 
if 
;

END 
if 
;

--Blokada usuwania faktur zakupu z dokumentów tymczasowych przez nieuprawnionych użytkowników

IF :error = 0 
AND :object_type ='112' 
AND (:transaction_type =N'D')
THEN SELECT
      Count(*) 
into cnt 
	FROM
		ODRF T0
	WHERE
		T0."DocEntry" = :list_of_cols_val_tab_del
		AND T0."ObjType" in ('18')
		AND T0."UserSign" IN ('45')

;

if :cnt>0 
then error:=1 
;
error_message:= N'Nie możesz usunąć tymczasowej faktury.'
;

end 
if 
;

END 
if 
;

*/

--Blokada usuwania dokumentów PZ z dokumentów tymczasowych przez nieuprawnionych użytkowników

IF :error = 0 
AND :object_type ='112' 
AND (:transaction_type =N'D')
THEN SELECT
      Count(*) 
into cnt 
	FROM
		ODRF T0
	WHERE
		T0."DocEntry" = :list_of_cols_val_tab_del
		AND T0."ObjType" in ('20')
		AND T0."UserSign" IN ('45')

;

if :cnt>0 
then error:=1 
;
error_message:= N'Nie możesz usunąć tymczasowej PZ.'
;

end 
if 
;

END 
if 
;

-- PW--PW--PW--PW--PW-- PW-- PW--
-- PW--PW--PW--PW--PW-- PW-- PW--

--Blokada PW na lokalizację POD (gdy towar u podwykonawcy)
IF :error = 0 and :cnt = 0
AND :object_type ='59' 
AND (:transaction_type =N'A')
THEN SELECT
      COUNT(*) 
into cnt 
FROM
(
SELECT
T6."BinCode", T6."Attr1Val"
FROM OIGN T0
 INNER JOIN IGN1 T1 on T0."DocEntry"=T1."DocEntry"
 LEFT OUTER JOIN OITL T3 on T3."DocEntry"=T1."DocEntry" and T3."DocLine"=T1."LineNum" and T3."DocType"=T1."ObjType"
 LEFT OUTER JOIN ITL1 T4 on T4."LogEntry"=T3."LogEntry"
 LEFT OUTER JOIN OBBQ T5 ON T4."MdAbsEntry" = T5."SnBMDAbs"
 LEFT OUTER JOIN OBIN T6 ON T5."BinAbs" = T6."AbsEntry"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del
) G0
WHERE G0."Attr1Val" LIKE '%POD%' AND G0."BinCode" NOT LIKE '%POD%_WYS%'
;

if :cnt>0 
then error:=1 
;
SELECT TOP 1
 G0."VisOrder"+1 into code
FROM
(
SELECT
T6."BinCode", T6."Attr1Val", T1."VisOrder"
FROM OIGN T0
 INNER JOIN IGN1 T1 on T0."DocEntry"=T1."DocEntry"
 LEFT OUTER JOIN OITL T3 on T3."DocEntry"=T1."DocEntry" and T3."DocLine"=T1."LineNum" and T3."DocType"=T1."ObjType"
 LEFT OUTER JOIN ITL1 T4 on T4."LogEntry"=T3."LogEntry"
 LEFT OUTER JOIN OBBQ T5 ON T4."MdAbsEntry" = T5."SnBMDAbs"
 LEFT OUTER JOIN OBIN T6 ON T5."BinAbs" = T6."AbsEntry"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del
) G0
WHERE G0."Attr1Val" LIKE '%POD%' AND G0."BinCode" NOT LIKE '%POD%_WYS%';

error_message:= N'Nie możesz robić przyjęcia na lokalizację POD dla pozycji nr ' || CAST(:code AS NVARCHAR)
;

end 
if 
;

END 
if 
;

-- RW--RW--RW--RW--RW-- RW-- RW--
-- RW--RW--RW--RW--RW-- RW-- RW--

--Blokada RW na lokalizację POD (gdy towar u podwykonawcy)
/*
IF :error = 0 and :cnt = 0
AND :object_type ='60' 
AND (:transaction_type =N'A')
THEN SELECT
      COUNT(*) 
into cnt 
FROM
(
SELECT
T6."BinCode", T6."Attr1Val"
FROM OIGE T0
 INNER JOIN IGE1 T1 on T0."DocEntry"=T1."DocEntry"
 LEFT OUTER JOIN OITL T3 on T3."DocEntry"=T1."DocEntry" and T3."DocLine"=T1."LineNum" and T3."DocType"=T1."ObjType"
 LEFT OUTER JOIN ITL1 T4 on T4."LogEntry"=T3."LogEntry"
 LEFT OUTER JOIN OBBQ T5 ON T4."MdAbsEntry" = T5."SnBMDAbs"
 LEFT OUTER JOIN OBIN T6 ON T5."BinAbs" = T6."AbsEntry"
 LEFT OUTER JOIN OUSR T7 ON T0."UserSign" = T7."USERID"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T7."USER_CODE" <> 'rafald' AND T7."USER_CODE" NOT LIKE '%script%' 
) G0
WHERE G0."Attr1Val" LIKE '%POD%' AND G0."BinCode" NOT LIKE '%POD%_WYS%'
;

if :cnt>0 
then error:=1 
;
SELECT TOP 1
 G0."VisOrder"+1 into code
FROM
(
SELECT
T6."BinCode", T6."Attr1Val", T1."VisOrder"
FROM OIGE T0
 INNER JOIN IGE1 T1 on T0."DocEntry"=T1."DocEntry"
 LEFT OUTER JOIN OITL T3 on T3."DocEntry"=T1."DocEntry" and T3."DocLine"=T1."LineNum" and T3."DocType"=T1."ObjType"
 LEFT OUTER JOIN ITL1 T4 on T4."LogEntry"=T3."LogEntry"
 LEFT OUTER JOIN OBBQ T5 ON T4."MdAbsEntry" = T5."SnBMDAbs"
 LEFT OUTER JOIN OBIN T6 ON T5."BinAbs" = T6."AbsEntry"
 LEFT OUTER JOIN OUSR T7 ON T0."UserSign" = T7."USERID"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T7."USER_CODE" <> 'rafald' AND T7."USER_CODE" NOT LIKE '%script%' 
) G0
WHERE G0."Attr1Val" LIKE '%POD%' AND G0."BinCode" NOT LIKE '%POD%_WYS%';

error_message:= N'Nie możesz robić wydania z lokalizacji POD dla pozycji nr ' || CAST(:code AS NVARCHAR)
;

end 
if 
;

END 
if 
;
*/
-- MM--MM--MM--MM--MM-- MM-- MM--
-- MM--MM--MM--MM--MM-- MM-- MM--

--Blokada utworzenia dokumentu MM na linie bez żądania magazynowego

IF :error = 0 
AND :object_type ='67' 
AND (:transaction_type =N'A')
THEN SELECT
      Count(*) 
into cnt 
	FROM
		OWTR T0
		INNER JOIN WTR1 T1 ON T0."DocEntry" = T1."DocEntry"
	WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T1."BaseType" <> '1250000001'
		AND T1."FromWhsCod" LIKE 'MS%' AND T1."WhsCode" LIKE 'MPR01%'

;

if :cnt>0 
then error:=1 
;
error_message:= N'Nie można zrobić przesunięcia niebazującego na zleceniu.'
;

end 
if 
;

END 
if 
;

--Blokada MM z lokalizacji POD (gdy towar u podwykonawcy)
IF :error = 0 and :cnt = 0
AND :object_type ='67' 
AND (:transaction_type =N'A')
THEN SELECT
      COUNT(*) 
into cnt 
FROM
(
SELECT
T6."BinCode", T6."Attr1Val", T1."VisOrder"
FROM OWTR T0
 INNER JOIN WTR1 T1 on T0."DocEntry"=T1."DocEntry"
 LEFT OUTER JOIN OITL T3 on T3."DocEntry"=T1."DocEntry" and T3."DocLine"=T1."LineNum" and T3."DocType"=T1."ObjType"
 LEFT OUTER JOIN ITL1 T4 on T4."LogEntry"=T3."LogEntry"
 LEFT OUTER JOIN OBBQ T5 ON T4."MdAbsEntry" = T5."SnBMDAbs"
 LEFT OUTER JOIN OBIN T6 ON T5."BinAbs" = T6."AbsEntry"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T3."DocQty" < 0 AND T1."FromWhsCod" = T5."WhsCode" AND T6."Attr1Val" LIKE '%POD%' AND T5."OnHandQty" = 0
) G0
WHERE G0."Attr1Val" LIKE '%POD%' AND G0."BinCode" NOT LIKE '%POD%_WYS%'
;

if :cnt>0 
then error:=1 
;
SELECT TOP 1
 G0."VisOrder"+1 into code
FROM
(
SELECT
T6."BinCode", T6."Attr1Val", T1."VisOrder"
FROM OWTR T0
 INNER JOIN WTR1 T1 on T0."DocEntry"=T1."DocEntry"
 LEFT OUTER JOIN OITL T3 on T3."DocEntry"=T1."DocEntry" and T3."DocLine"=T1."LineNum" and T3."DocType"=T1."ObjType"
 LEFT OUTER JOIN ITL1 T4 on T4."LogEntry"=T3."LogEntry"
 LEFT OUTER JOIN OBTL T5 ON T4."LogEntry" = T5."ITLEntry" 
 LEFT OUTER JOIN OBIN T6 ON T5."BinAbs" = T6."AbsEntry"
WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T3."DocQty" < 0 AND T6."Attr1Val" LIKE '%POD%' -- AND T5."OnHandQty" = 0
) G0
WHERE G0."Attr1Val" LIKE '%POD%' AND G0."BinCode" NOT LIKE '%POD%_WYS%';

error_message:= N'Nie możesz robić MM z lokalizacji POD dla pozycji nr ' || CAST(:code AS NVARCHAR)
;

end 
if 
;

END 
if 
;

-- @CT_PF_OMOR--@CT_PF_OMOR--@CT_PF_OMOR--@CT_PF_OMOR--@CT_PF_OMOR-- @CT_PF_OMOR-- @CT_PF_OMOR--
-- @CT_PF_OMOR--@CT_PF_OMOR--@CT_PF_OMOR--@CT_PF_OMOR--@CT_PF_OMOR-- @CT_PF_OMOR-- @CT_PF_OMOR--

--UPADTE PROCES ZAWIESZKI PODZIAŁKI

IF  :object_type ='CT_PF_ManufacOrd' 
AND (:transaction_type =N'A')
THEN
SELECT count(*) into cnt 
FROM "@CT_PF_MOR16" where "DocEntry" = :list_of_cols_val_tab_del ; 

if :cnt>0
THEN 

 update T0
set 
"U_Linia1"=case when  ifnull(t0."U_Linia1",'')='' then t1."U_Linia1" else t0."U_Linia1" end,
"U_Linia2"=case when  ifnull(t0."U_Linia2",'')='' then t1."U_Linia2" else t0."U_Linia2" end,
"U_Linia3"=case when  ifnull(t0."U_Linia3",'')='' then t1."U_Linia3" else t0."U_Linia3" end,
"U_Linia4"=case when  ifnull(t0."U_Linia4",'')='' then t1."U_Linia4" else t0."U_Linia4" end,
"U_Linia5"=case when  ifnull(t0."U_Linia5",'')='' then t1."U_Linia5" else t0."U_Linia5" end,
"U_Linia6"=case when  ifnull(t0."U_Linia6",'')='' then t1."U_Linia6" else t0."U_Linia6" end,
"U_Linia7"=case when  ifnull(t0."U_Linia7",'')='' then t1."U_Linia7" else t0."U_Linia7" end,
"U_Linia8"=case when  ifnull(t0."U_Linia8",'')='' then t1."U_Linia8" else t0."U_Linia8" end,
"U_Linia9"=case when  ifnull(t0."U_Linia9",'')='' then t1."U_Linia9" else t0."U_Linia9" end,
"U_Linia10"=case when  ifnull(t0."U_Linia10",'')='' then t1."U_Linia10" else t0."U_Linia10" end,

"U_Ilosc2"=case when  ifnull(t0."U_Ilosc2",0)=0 and (ifnull(t0."U_Linia2",'')<>'' or ifnull(t1."U_Linia2",'')<>'' )then t0."U_Quantity" else t0."U_Ilosc2" end,
"U_Ilosc3"=case when  ifnull(t0."U_Ilosc3",0)=0 and (ifnull(t0."U_Linia3",'')<>'' or ifnull(t1."U_Linia3",'')<>'' )then t0."U_Quantity" else t0."U_Ilosc3" end,
"U_Ilosc4"=case when  ifnull(t0."U_Ilosc4",0)=0 and (ifnull(t0."U_Linia4",'')<>'' or ifnull(t1."U_Linia4",'')<>'' )then t0."U_Quantity" else t0."U_Ilosc4" end,
"U_Ilosc5"=case when  ifnull(t0."U_Ilosc5",0)=0 and (ifnull(t0."U_Linia5",'')<>'' or ifnull(t1."U_Linia5",'')<>'' )then t0."U_Quantity" else t0."U_Ilosc5" end,
"U_Ilosc6"=case when  ifnull(t0."U_Ilosc6",0)=0 and (ifnull(t0."U_Linia6",'')<>'' or ifnull(t1."U_Linia6",'')<>'' )then t0."U_Quantity" else t0."U_Ilosc6" end,
"U_Ilosc7"=case when  ifnull(t0."U_Ilosc7",0)=0 and (ifnull(t0."U_Linia7",'')<>'' or ifnull(t1."U_Linia7",'')<>'' )then t0."U_Quantity" else t0."U_Ilosc7" end,
"U_Ilosc8"=case when  ifnull(t0."U_Ilosc8",0)=0 and (ifnull(t0."U_Linia8",'')<>'' or ifnull(t1."U_Linia8",'')<>'' )then t0."U_Quantity" else t0."U_Ilosc8" end,
"U_Ilosc9"=case when  ifnull(t0."U_Ilosc9",0)=0 and (ifnull(t0."U_Linia9",'')<>'' or ifnull(t1."U_Linia9",'')<>'' )then t0."U_Quantity" else t0."U_Ilosc9" end,
"U_Ilosc10"=case when  ifnull(t0."U_Ilosc10",0)=0 and (ifnull(t0."U_Linia10",'')<>'' or ifnull(t1."U_Linia10",'')<>'' )then t0."U_Quantity" else t0."U_Ilosc10" end,

"U_IlNaPodzialce1"=case when  ifnull(t0."U_IlNaPodzialce1",0)=0 then t1."U_IlNaPodzialce1" else t0."U_IlNaPodzialce1" end,
"U_IlNaPodzialce2"=case when  ifnull(t0."U_IlNaPodzialce2",0)=0 then t1."U_IlNaPodzialce2" else t0."U_IlNaPodzialce2" end,
"U_IlNaPodzialce3"=case when  ifnull(t0."U_IlNaPodzialce3",0)=0 then t1."U_IlNaPodzialce3" else t0."U_IlNaPodzialce3" end,
"U_IlNaPodzialce4"=case when  ifnull(t0."U_IlNaPodzialce4",0)=0 then t1."U_IlNaPodzialce4" else t0."U_IlNaPodzialce4" end,
"U_IlNaPodzialce5"=case when  ifnull(t0."U_IlNaPodzialce5",0)=0 then t1."U_IlNaPodzialce5" else t0."U_IlNaPodzialce5" end,
"U_IlNaPodzialce6"=case when  ifnull(t0."U_IlNaPodzialce6",0)=0 then t1."U_IlNaPodzialce6" else t0."U_IlNaPodzialce6" end,
"U_IlNaPodzialce7"=case when  ifnull(t0."U_IlNaPodzialce7",0)=0 then t1."U_IlNaPodzialce7" else t0."U_IlNaPodzialce7" end,
"U_IlNaPodzialce8"=case when  ifnull(t0."U_IlNaPodzialce8",0)=0 then t1."U_IlNaPodzialce8" else t0."U_IlNaPodzialce8" end,
"U_IlNaPodzialce9"=case when  ifnull(t0."U_IlNaPodzialce9",0)=0 then t1."U_IlNaPodzialce9" else t0."U_IlNaPodzialce9" end,
"U_IlNaPodzialce10"=case when  ifnull(t0."U_IlNaPodzialce10",0)=0 then t1."U_IlNaPodzialce10" else t0."U_IlNaPodzialce10" end,

"U_Zmiana1"=case when  ifnull(t0."U_Zmiana1",0)=0 then 1  else t0."U_Zmiana1" end,
"U_Zmiana2"=case when  ifnull(t0."U_Zmiana2",0)=0 then 1  else t0."U_Zmiana2" end,
"U_Zmiana3"=case when  ifnull(t0."U_Zmiana3",0)=0 then 1  else t0."U_Zmiana3" end,
"U_Zmiana4"=case when  ifnull(t0."U_Zmiana4",0)=0 then 1  else t0."U_Zmiana4" end,
"U_Zmiana5"=case when  ifnull(t0."U_Zmiana5",0)=0 then 1  else t0."U_Zmiana5" end,
"U_Zmiana6"=case when  ifnull(t0."U_Zmiana6",0)=0 then 1  else t0."U_Zmiana6" end,
"U_Zmiana7"=case when  ifnull(t0."U_Zmiana7",0)=0 then 1  else t0."U_Zmiana7" end,
"U_Zmiana8"=case when  ifnull(t0."U_Zmiana8",0)=0 then 1  else t0."U_Zmiana8" end,
"U_Zmiana9"=case when  ifnull(t0."U_Zmiana9",0)=0 then 1  else t0."U_Zmiana9" end,
"U_Zmiana10"=case when  ifnull(t0."U_Zmiana10",0)=0 then 1 else t0."U_Zmiana10" end,



"U_IlNaZawieszce1"=case when  ifnull(t0."U_IlNaZawieszce1",0)=0 then t1."U_IlNaZawieszcze1" else t0."U_IlNaZawieszce1" end,
"U_IlNaZawieszce2"=case when  ifnull(t0."U_IlNaZawieszce2",0)=0 then t1."U_IlNaZawieszcze2" else t0."U_IlNaZawieszce2" end,
"U_IlNaZawieszce3"=case when  ifnull(t0."U_IlNaZawieszce3",0)=0 then t1."U_IlNaZawieszcze3" else t0."U_IlNaZawieszce3" end,
"U_IlNaZawieszce4"=case when  ifnull(t0."U_IlNaZawieszce4",0)=0 then t1."U_IlNaZawieszcze4" else t0."U_IlNaZawieszce4" end,
"U_IlNaZawieszce5"=case when  ifnull(t0."U_IlNaZawieszce5",0)=0 then t1."U_IlNaZawieszcze5" else t0."U_IlNaZawieszce5" end,
"U_IlNaZawieszce6"=case when  ifnull(t0."U_IlNaZawieszce6",0)=0 then t1."U_IlNaZawieszcze6" else t0."U_IlNaZawieszce6" end,
"U_IlNaZawieszce7"=case when  ifnull(t0."U_IlNaZawieszce7",0)=0 then t1."U_IlNaZawieszcze7" else t0."U_IlNaZawieszce7" end,
"U_IlNaZawieszce8"=case when  ifnull(t0."U_IlNaZawieszce8",0)=0 then t1."U_IlNaZawieszcze8" else t0."U_IlNaZawieszce8" end,
"U_IlNaZawieszce9"=case when  ifnull(t0."U_IlNaZawieszce9",0)=0 then t1."U_IlNaZawieszcze9" else t0."U_IlNaZawieszce9" end,
"U_IlNaZawieszce10"=case when  ifnull(t0."U_IlNaZawieszce10",0)=0 then t1."U_IlNaZawieszcze10" else t0."U_IlNaZawieszce10" end,
 
"U_Data2"=case when  ifnull(t0."U_Data2",'2016-01-01')='2016-01-01' then t0."U_Data1" else t0."U_Data2" end,
"U_Data3"=case when  ifnull(t0."U_Data3",'2016-01-01')='2016-01-01' then t0."U_Data1" else t0."U_Data3" end,
"U_Data4"=case when  ifnull(t0."U_Data4",'2016-01-01')='2016-01-01' then t0."U_Data1" else t0."U_Data4" end,
"U_Data5"=case when  ifnull(t0."U_Data5",'2016-01-01')='2016-01-01' then t0."U_Data1" else t0."U_Data5" end,
"U_Data6"=case when  ifnull(t0."U_Data6",'2016-01-01')='2016-01-01' then t0."U_Data1" else t0."U_Data6" end,
"U_Data7"=case when  ifnull(t0."U_Data7",'2016-01-01')='2016-01-01' then t0."U_Data1" else t0."U_Data7" end,
"U_Data8"=case when  ifnull(t0."U_Data8",'2016-01-01')='2016-01-01' then t0."U_Data1" else t0."U_Data8" end,
"U_Data9"=case when  ifnull(t0."U_Data9",'2016-01-01')='2016-01-01' then t0."U_Data1" else t0."U_Data9" end,
"U_Data10"=case when  ifnull(t0."U_Data10",'2016-01-01')='2016-01-01' then t0."U_Data1" else t0."U_Data1" end,

"U_SumaPodzialek1"=case when  ifnull(t0."U_SumaPodzialek1",0)=0 then t1."U_SumaPodzialek1" else t0."U_SumaPodzialek1" end,
"U_SumaPodzialek2"=case when  ifnull(t0."U_SumaPodzialek2",0)=0 then t1."U_SumaPodzialek2" else t0."U_SumaPodzialek2" end,
"U_SumaPodzialek3"=case when  ifnull(t0."U_SumaPodzialek3",0)=0 then t1."U_SumaPodzialek3" else t0."U_SumaPodzialek3" end,
"U_SumaPodzialek4"=case when  ifnull(t0."U_SumaPodzialek4",0)=0 then t1."U_SumaPodzialek4" else t0."U_SumaPodzialek4" end,
"U_SumaPodzialek5"=case when  ifnull(t0."U_SumaPodzialek5",0)=0 then t1."U_SumaPodzialek5" else t0."U_SumaPodzialek5" end,
"U_SumaPodzialek6"=case when  ifnull(t0."U_SumaPodzialek6",0)=0 then t1."U_SumaPodzialek6" else t0."U_SumaPodzialek6" end,
"U_SumaPodzialek7"=case when  ifnull(t0."U_SumaPodzialek7",0)=0 then t1."U_SumaPodzialek7" else t0."U_SumaPodzialek7" end,
"U_SumaPodzialek8"=case when  ifnull(t0."U_SumaPodzialek8",0)=0 then t1."U_SumaPodzialek8" else t0."U_SumaPodzialek8" end,
"U_SumaPodzialek9"=case when  ifnull(t0."U_SumaPodzialek9",0)=0 then t1."U_SumaPodzialek9" else t0."U_SumaPodzialek9" end,
"U_SumaPodzialek10"=case when  ifnull(t0."U_SumaPodzialek10",0)=0 then t1."U_SumaPodzialek10" else t0."U_SumaPodzialek10" end

from  "@CT_PF_OMOR" T0 inner join 
CT_MOR_LinieZTechnologii t1 on t0."DocEntry"=t1."DocEntry"
where t0."DocEntry"=:list_of_cols_val_tab_del;

  call CT_DodajProcesyKontroli(:list_of_cols_val_tab_del);

UPDATE "@CT_PF_OMOR" SET "U_NazwaFarby" = (SELECT TOP 1 "U_NazwaFarby"  FROM "@CT_PF_MOR16" where "DocEntry" = :list_of_cols_val_tab_del)
where "DocEntry" = :list_of_cols_val_tab_del;

UPDATE "@CT_PF_OMOR" SET "U_KodFarby" = (SELECT TOP 1 "U_KodFarby"  FROM "@CT_PF_MOR16" where "DocEntry" = :list_of_cols_val_tab_del)
where "DocEntry" = :list_of_cols_val_tab_del;

end 
if 
;

END 
if 
;



--UPADTE NR RYSUNKU SUROWEGO I GOTOWEGO 
IF  :object_type ='CT_PF_ManufacOrd' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN
SELECT count(*) into cnt 
FROM "@CT_PF_OMOR" t0 
LEFT OUTER JOIN OITM t1 ON t0."U_ItemCode"=t1."ItemCode" where t0."DocEntry" = :list_of_cols_val_tab_del and (t1."U_DrawNoRaw" is not null or t1."U_DrawNoFinal" is not null ) ; 

if :cnt>0
THEN 
UPDATE "@CT_PF_OMOR" SET "U_DrawNoRaw"=(SELECT t1."U_DrawNoRaw" 
										FROM "@CT_PF_OMOR" t0 
										LEFT OUTER JOIN OITM t1 ON t0."U_ItemCode"=t1."ItemCode" where t0."DocEntry" = :list_of_cols_val_tab_del )
where "DocEntry" = :list_of_cols_val_tab_del;
UPDATE "@CT_PF_OMOR" SET "U_DrawNoFinal"=(SELECT t1."U_DrawNoFinal" 
										FROM "@CT_PF_OMOR" t0 
										LEFT OUTER JOIN OITM t1 ON t0."U_ItemCode"=t1."ItemCode" where t0."DocEntry" = :list_of_cols_val_tab_del )
where "DocEntry" = :list_of_cols_val_tab_del;
end 
if 
;

END 
if 
;
-- sprawdzanie etapów
IF  :object_type ='CT_PF_ManufacOrd' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
then
 select Count(*) into cnt from CT_Zlecenia_Linie t0
  left outer join "@CT_PF_ORSC" t1 on t0."U_Linia1"=t1."U_RscCode"
  where t0."DocEntry"=:list_of_cols_val_tab_del
  and t1."U_RscCode" is null and ifnull(t0."U_Linia1",'')<>'';
  
  if( :cnt>0)
  then
  		error:=114
		;
		error_message:= N'Błedna maszyna na jednym z etapów.';
  end if;

end if;

-- walidacja ilosci na su 
IF  
:error = 0 and
:object_type ='CT_WMS_OSTU' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN
	SELECT count(*) into cnt 
	FROM "@CT_WMS_OSTU" t0 
	where "Code"=:list_of_cols_val_tab_del 
	and "U_IloscZA" >"U_IloscOrig";
	if :cnt>0
		THEN 
		
		error:=112
		;
		error_message:= N'Nie można zawiesić ilości większej niż oryginalna.';
		END if ;
END  if ;


IF  
:error = 0 and
:object_type ='CT_WMS_OSTU' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN
	 
	 
 select count(*)  into cnt  from "@CT_WMS_OSTU" where "U_StatusSU"<>'2'and "U_Attribute5"='Wor' and  "Code"=:list_of_cols_val_tab_del ;
	
	if :cnt>0
		THEN 
		
		error:=212
		;
		error_message:= N'nie można zamknąć tego pojemnika jest to pojemnik zbiorczy.';
		END if ;
END  if ;

-- walidacja ilosci na su 
IF  
:error = 0 and
:object_type ='CT_WMS_OSTU' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN
SELECT count(*) into cnt 
FROM "@CT_WMS_OSTU" t0 
where "Code"=:list_of_cols_val_tab_del 
and "U_IloscZA"+ifnull("U_IloscPlusZA",0) <"U_IloscSU"+"U_IloscZlych" +ifnull("U_Ilosc_Plus",0) ;
if :cnt>0
THEN 

error:=112
;
error_message:= N'Nie można zdjąć ilości większej niż zawieszona.';
else
SELECT count(*) into cnt 
FROM "@CT_WMS_OSTU" t0 
where "Code"=:list_of_cols_val_tab_del 
and "U_IloscZA"+ifnull("U_IloscPlusZA",0) >"U_IloscOrig"  ;
if :cnt>0
THEN 

error:=1121
;
error_message:= N'Nie można Zawiesic ilości większej niż dostępna.';
end if;
END 
if ;

END 
if ;
 
 
--blokada na ostatnim procesie
IF  
:error = 0 and
:object_type ='CT_WMS_OSTU' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN


Select count(*) into cnt from 
"@CT_WMS_OSTU" t0    
--inner join "@CT_PF_ORSC" t2 on t0."U_BinAbs"=t2."U_BinAbs" 
--inner join "CT_ZLECENIA_KOLEJNOSC" t1 on t0."U_Attribute1" = cast(t1."DocEntry" as nvarchar(11))  and t2."U_RscCode" = t1."Z"
where t0."U_IloscSU"+  t0."U_Ilosc_Plus" >0 and t0."U_Attribute6"='Koniec' 
and t0."Code"=:list_of_cols_val_tab_del ;--and  t0."U_Attribute5"<>'Wor';

if( :cnt>0)
then
	 error:=134;
	error_message:= N'Na ostatnim procesie przyjmujemy przez liste przyjęć';
end if;

end if;
 
 /*
-- walidacja ilosci na su 
IF  
:error = 0 and
:object_type ='CT_WMS_OSTU' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN
	SELECT count(*) into cnt 
	FROM "@CT_WMS_OSTU" t0 
	where "Code"=:list_of_cols_val_tab_del 
	and ("U_IloscSU" +"U_IloscZlych" >0) and "U_StatusSU" ='1';
	if :cnt>0
		THEN 
		error:=114;
		error_message:= N'Nie można zamknąc pustego pojemnika';
		END if ;
END  if ;
*/
-- walidacja na przesuniecie z izolatora bez kodu wady 
--POST -- Przesuniecie na izolator po zmianie statusu na do przesuniecia
IF  
:error = 0 and
:object_type ='67' 
AND ( :transaction_type =N'A')
THEN
select count(*) into cnt
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
left outer join "@CT_PF_ORSC" fromRsc on t3."BinAbs"=fromRsc."U_BinAbs"
left outer join "@CT_PF_ORSC" ToRsc on t2."BinAbs"=ToRsc."U_BinAbs"
left outer join "OBIN" fromBin on t3."BinAbs"=fromBin."AbsEntry"
left outer join "OBIN" ToBin on t2."BinAbs"=ToBin."AbsEntry"
left outer join "@CT_PF_BOM1" b1 on b1."U_ItemCode"=t0."ItemCode"
left outer join "@CT_PF_OBOM" b2 on b1."Code"=b2."Code"
left  join "@CT_PF_BOM11" t7 on replace(t0."ItemCode",left(b1."U_ItemCode",2),left(b2."U_ItemCode",2))= t7."U_BomCode" and  
								--t7."U_RevCode"=t0."Revision" and and 
								(
														(t7."U_RtgCode"=t0."U_TechNapraw"  and t0."U_TechNapraw"<>'P')  -- tech naprawcza 
									or
									(t0."U_TechNapraw"='P' and  t7."U_IsDefault"='Y' ) -- powrót na linie 
									) --
--								Substring(Replace(substring(t7."U_RtgCode",13,6),'-',''),0,5)=t0."U_TechNapraw"
where t0."DocEntry"=:list_of_cols_val_tab_del  and  FromBin."BinCode"  like '%IZ%' and ( t7."Code" is null ) and
( ToBin."BinCode" <> 'GW-N#BRAK' or
ToBin."BinCode" <> 'GW#BRAK' )
and IFNULL(ToBin."Attr1Val",'') NOT LIKE '%POD%'
;
if :cnt>0 then
	error:=144;
	error_message:= N'prosze wybrać TEchnologie naprawczą gdy przesuwamy z izolatora ' ||cast (:cnt as nvarchar(30));
	END if ;

end if;

--select * from obin where "BinCode"  like '%IZ%'
 --aktualizacja pola w nagłówku SU
IF  
:error = 0 and
:object_type ='CT_WMS_OSTU' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN
update "@CT_WMS_OSTU"  set "U_IloscSU" =ifnull("U_IloscSU",0) +ifnull("U_Ilosc_Plus",0) ,"U_Ilosc_Plus"=0
,"U_IloscZA"=ifnull("U_IloscZA",0) +ifnull("U_IloscPlusZA",0) ,"U_IloscPlusZA"=0

where "Code"= :list_of_cols_val_tab_del;
select case when "U_Attribute5"='Wor' then 1 else 0 end into cnt from "@CT_WMS_OSTU" where "Code"= :list_of_cols_val_tab_del;
if (:cnt=0)
then 

call CT_Su_CreateNewSuWhenOldIsNotFull(:list_of_cols_val_tab_del);
call CT_CheckBigBox();
else

call CT_CheckBigBoxUpdateSmall(:list_of_cols_val_tab_del);

end if;
update "@CT_WMS_OSTU" set "U_SSCC" = ' O:'||cast(cast("U_IloscOrig" as int) as nvarchar(20)) ||' ZA:'||cast(cast("U_IloscZA" as int) as nvarchar(20))||' ZD:'||cast(cast("U_IloscSU" as int)  as nvarchar(20)) 

||' BF:'||cast(cast("U_IloscOrig" -"U_IloscZA" as int)  as nvarchar(20)) 


where "Code"= :list_of_cols_val_tab_del;





END 
if ;

--Zlecenie wysyłki (UDO)--Zlecenie wysyłki (UDO)--Zlecenie wysyłki (UDO)--Zlecenie wysyłki (UDO)--Zlecenie wysyłki (UDO)--Zlecenie wysyłki (UDO)--Zlecenie wysyłki (UDO)--Zlecenie wysyłki (UDO)--Zlecenie wysyłki (UDO)--Zlecenie wysyłki (UDO)--Zlecenie wysyłki (UDO)--Zlecenie wysyłki (UDO)--Zlecenie wysyłki (UDO)--Zlecenie wysyłki (UDO)--Zlecenie wysyłki (UDO)--Zlecenie wysyłki (UDO)--Zlecenie wysyłki (UDO)--
--Zlecenie wysyłki (UDO)--Zlecenie wysyłki (UDO)--Zlecenie wysyłki (UDO)--Zlecenie wysyłki (UDO)--Zlecenie wysyłki (UDO)--Zlecenie wysyłki (UDO)--Zlecenie wysyłki (UDO)--Zlecenie wysyłki (UDO)--Zlecenie wysyłki (UDO)--Zlecenie wysyłki (UDO)--Zlecenie wysyłki (UDO)--Zlecenie wysyłki (UDO)--Zlecenie wysyłki (UDO)--Zlecenie wysyłki (UDO)--Zlecenie wysyłki (UDO)--Zlecenie wysyłki (UDO)--Zlecenie wysyłki (UDO)--

--Wymuszenie wskazania operatora przy zwolnieniu zlecenia wysyłki

IF :error = 0 
AND :object_type ='CT_ZW' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN SELECT
      Count(*) 
into cnt 
	FROM
		"@CT_ZW_NAG" T0
	WHERE
		T0."DocEntry" = :list_of_cols_val_tab_del
		AND IFNULL(T0."U_PickRelease",'N') = 'T'
		AND IFNULL(T0."U_User",'') = ''

;

if :cnt>0 
then error:=1 
;
error_message:= N'Przy zwalnianiu zlecenia wysyłki musisz wskazać operatora.'
;

end 
if 
;

END 
if 
;


--Blokada utworzenia listy pobrania dla pozycji z ilością 0 na magazynie

IF :error = 0 
AND :object_type ='CT_ZW' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN SELECT
      Count(*) 
into cnt 
	FROM
		"@CT_ZW_NAG" T0
	INNER JOIN "@CT_ZW_POZ" T1 ON T0."DocEntry" = T1."DocEntry"
	INNER JOIN RDR1 T2 ON T1."U_DocEntryZS" = T2."DocEntry" AND T1."U_LineNumZS" = T2."LineNum"
	INNER JOIN OITW T3 ON T2."ItemCode" = T3."ItemCode" AND T2."WhsCode" = T3."WhsCode"
	WHERE
		T0."DocEntry" = :list_of_cols_val_tab_del
		AND IFNULL(T0."U_PickRelease",'N') = 'T'
		AND IFNULL(T3."OnHand",0) < IFNULL(T1."U_QtySum",0)
		--AND IFNULL(T3."OnHand",0) <= 0

;

if :cnt>0 
then error:=1 
;
error_message:= N'Brak wystarczającej ilości na magazynie.'
;

end 
if 
;

END 
if 
;

--Blokada edycji zlecenia wysyłki, gdy utworzona jest lista pobrań

IF :error = 0 
AND :object_type ='CT_ZW' 
AND (:transaction_type =N'U')
THEN SELECT
      Count(*) 
into cnt 
	FROM
		"@CT_ZW_NAG" T0
	WHERE
		T0."DocEntry" = :list_of_cols_val_tab_del
		AND IFNULL(T0."U_PickNo",0) <> 0


;

if :cnt>0 
then error:=1 
;
error_message:= N'Nie można edytować zlecenia wysyłki, do którego utworzona jest lista pobrań.'
;

end 
if 
;

END 
if ;

--Wymuszenie wpisania uwag do ryzyka przy wybraniu opcji średniego lub dużego ryzyka

--Wymogi ochrony środowiska
IF :error = 0 
AND :object_type ='CT_ZOF' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN SELECT
      Count(*) 
into cnt
	FROM "@CT_ZOF_P4"
	WHERE "DocEntry" = :list_of_cols_val_tab_del
	AND IFNULL(CAST("U_EnvirRestrRem" AS NVARCHAR(1000)),'') = ''
	AND IFNULL("U_EnvirRestr",'0') <> '0'
;

if :cnt>0 
then error:=1 
;
error_message:= N'Uzupełnij opis wymogów ochrony środowiska.'
;

end 
if 
;

END 
if ;



--Wymogi ochrony REACH
IF :error = 0 
AND :object_type ='CT_ZOF' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN SELECT
      Count(*) 
into cnt
	FROM "@CT_ZOF_P4"
	WHERE "DocEntry" = :list_of_cols_val_tab_del
	AND IFNULL(CAST("U_ReachReqRem" AS NVARCHAR(1000)),'') = ''
	AND IFNULL("U_ReachReq",'0') <> '0'
;

if :cnt>0 
then error:=1 
;
error_message:= N'Uzupełnij opis wymogów REACH.'
;

end 
if 
;

END 
if ;


--Wymagania dodatkowe BHP
IF :error = 0 
AND :object_type ='CT_ZOF' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN SELECT
      Count(*) 
into cnt
	FROM "@CT_ZOF_P4"
	WHERE "DocEntry" = :list_of_cols_val_tab_del
	AND IFNULL(CAST("U_BhpReqRem" AS NVARCHAR(1000)),'') = ''
	AND IFNULL("U_BhpReq",'0') <> '0'
;

if :cnt>0 
then error:=1 
;
error_message:= N'Uzupełnij opis wymagań dodatkowych BHP.'
;

end 
if 
;

END 
if ;

--Specyficzne wymogi klienta
IF :error = 0 
AND :object_type ='CT_ZOF' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN SELECT
      Count(*) 
into cnt
	FROM "@CT_ZOF_P5"
	WHERE "DocEntry" = :list_of_cols_val_tab_del
	AND IFNULL(CAST("U_ClientSpecReqRem" AS NVARCHAR(1000)),'') = ''
	AND IFNULL("U_ClientSpecReq",'0') <> '0'
;

if :cnt>0 
then error:=1 
;
error_message:= N'Uzupełnij opis specjalnych wymagań klienta.'
;

end 
if 
;

END 
if ;


--InżProd
IF :error = 0 
AND :object_type ='CT_ZOF' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN SELECT
      Count(*) 
into cnt
	FROM "@CT_ZOF_P2"
	WHERE "DocEntry" = :list_of_cols_val_tab_del
	AND IFNULL(CAST("U_ProdRiskDesc" AS NVARCHAR(1000)),'') = ''
	AND IFNULL("U_ProdRisk",'0') <> '0'
;

if :cnt>0 
then error:=1 
;
error_message:= N'Uzupełnij opis ryzyka dla pozycji, gdzie oszacowano ryzyki na średniu lub duże.'
;

end 
if 
;

END 
if ;

--Czasochłonność
IF :error = 0 
AND :object_type ='CT_ZOF' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN SELECT
      Count(*) 
into cnt
	FROM "@CT_ZOF_P3"
	WHERE "DocEntry" = :list_of_cols_val_tab_del
	AND IFNULL(CAST("U_RiskTimeDesc" AS NVARCHAR(1000)),'') = ''
	AND IFNULL("U_RiskTime",'0') <> '0'
;

if :cnt>0 
then error:=1 
;
error_message:= N'Uzupełnij opis ryzyka dla pozycji, gdzie oszacowano ryzyki na średniu lub duże.'
;

end 
if 
;

END 
if ;

--BHP i OŚ
IF :error = 0 
AND :object_type ='CT_ZOF' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN SELECT
      Count(*) 
into cnt
	FROM "@CT_ZOF_P4"
	WHERE "DocEntry" = :list_of_cols_val_tab_del
	AND IFNULL(CAST("U_BhpRiskDesc" AS NVARCHAR(1000)),'') = ''
	AND IFNULL("U_BhpRis",'0') <> '0'
;

if :cnt>0 
then error:=1 
;
error_message:= N'Uzupełnij opis ryzyka dla pozycji, gdzie oszacowano ryzyki na średniu lub duże.'
;

end 
if 
;

END 
if ;

--Jakość
IF :error = 0 
AND :object_type ='CT_ZOF' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN SELECT
      Count(*) 
into cnt
	FROM "@CT_ZOF_P5"
	WHERE "DocEntry" = :list_of_cols_val_tab_del
	AND IFNULL(CAST("U_QualityRiskDesc" AS NVARCHAR(1000)),'') = ''
	AND IFNULL("U_QualityRisk",'0') <> '0'
;

if :cnt>0 
then error:=1 
;
error_message:= N'Uzupełnij opis ryzyka dla pozycji, gdzie oszacowano ryzyki na średniu lub duże.'
;

end 
if 
;

END 
if ;

--Logistyka
IF :error = 0 
AND :object_type ='CT_ZOF' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN SELECT
      Count(*) 
into cnt
	FROM "@CT_ZOF_P6"
	WHERE "DocEntry" = :list_of_cols_val_tab_del
	AND IFNULL(CAST("U_LogRiskDesc" AS NVARCHAR(1000)),'') = ''
	AND IFNULL("U_LogRisk",'0') <> '0'
;

if :cnt>0 
then error:=1 
;
error_message:= N'Uzupełnij opis ryzyka dla pozycji, gdzie oszacowano ryzyki na średniu lub duże.'
;

end 
if 
;

END 
if ;

--Finanse
IF :error = 0 
AND :object_type ='CT_ZOF' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN SELECT
      Count(*) 
into cnt
	FROM "@CT_ZOF_P9"
	WHERE "DocEntry" = :list_of_cols_val_tab_del
	AND IFNULL(CAST("U_FinRiskDesc" AS NVARCHAR(1000)),'') = ''
	AND IFNULL("U_FinRisk",'0') <> '0'
;

if :cnt>0 
then error:=1 
;
error_message:= N'Uzupełnij opis ryzyka dla pozycji, gdzie oszacowano ryzyki na średniu lub duże.'
;

end 
if 
;

END 
if ;

--Dyrekcja
IF :error = 0 
AND :object_type ='CT_ZOF' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN SELECT
      Count(*) 
into cnt
	FROM "@CT_ZOF_P7"
	WHERE "DocEntry" = :list_of_cols_val_tab_del
	AND IFNULL(CAST("U_DirRiskDesc" AS NVARCHAR(1000)),'') = ''
	AND IFNULL("U_DirRisk",'0') <> '0'
;

if :cnt>0 
then error:=1 
;
error_message:= N'Uzupełnij opis ryzyka dla pozycji, gdzie oszacowano ryzyki na średniu lub duże.'
;

end 
if 
;

END 
if ;

--Czasochlonnosc (UDO)--Czasochlonnosc (UDO)--Czasochlonnosc (UDO)--Czasochlonnosc (UDO)--Czasochlonnosc (UDO)--Czasochlonnosc (UDO)--Czasochlonnosc (UDO)--Czasochlonnosc (UDO)--Czasochlonnosc (UDO)--Czasochlonnosc (UDO)--Czasochlonnosc (UDO)--Czasochlonnosc (UDO)--Czasochlonnosc (UDO)--Czasochlonnosc (UDO)--Czasochlonnosc (UDO)--Czasochlonnosc (UDO)--Czasochlonnosc (UDO)--
--Czasochlonnosc (UDO)--Czasochlonnosc (UDO)--Czasochlonnosc (UDO)--Czasochlonnosc (UDO)--Czasochlonnosc (UDO)--Czasochlonnosc (UDO)--Czasochlonnosc (UDO)--Czasochlonnosc (UDO)--Czasochlonnosc (UDO)--Czasochlonnosc (UDO)--Czasochlonnosc (UDO)--Czasochlonnosc (UDO)--Czasochlonnosc (UDO)--Czasochlonnosc (UDO)--Czasochlonnosc (UDO)--Czasochlonnosc (UDO)--Czasochlonnosc (UDO)--

--Blokada wpisania czynności spoza zdefiniowanej listy

IF :error = 0 
AND :object_type ='CT_CZASCH' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN SELECT
      Count(*) 
into cnt
	FROM "@CT_CZASCH_Z"
	WHERE "Code" = :list_of_cols_val_tab_del
	AND "U_Czynnosc" NOT IN (SELECT CAST("Remark" AS NVARCHAR(100)) FROM "@CT_CZYNNOSCI")
;

if :cnt>0 
then error:=1 
;
error_message:= N'Wpisana czynność jest spoza listy - Zakładka Załadunek.'
;

end 
if 
;

END 
if ;

IF :error = 0 
AND :object_type ='CT_CZASCH' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN SELECT
      Count(*) 
into cnt
	FROM "@CT_CZASCH_R"
	WHERE "Code" = :list_of_cols_val_tab_del
	AND "U_Czynnosc" NOT IN (SELECT CAST("Remark" AS NVARCHAR(100)) FROM "@CT_CZYNNOSCI")
;

if :cnt>0 
then error:=1 
;
error_message:= N'Wpisana czynność jest spoza listy - Zakładka Rozładunek.'
;

end 
if 
;

END 
if ;

IF :error = 0 
AND :object_type ='CT_CZASCH' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN SELECT
      Count(*) 
into cnt
	FROM "@CT_CZASCH_K"
	WHERE "Code" = :list_of_cols_val_tab_del
	AND "U_Czynnosc" NOT IN (SELECT CAST("Remark" AS NVARCHAR(100)) FROM "@CT_CZYNNOSCI")
;

if :cnt>0 
then error:=1 
;
error_message:= N'Wpisana czynność jest spoza listy - Zakładka Pakowanie.'
;

end 
if 
;

END 
if ;

IF :error = 0 
AND :object_type ='CT_CZASCH' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN SELECT
      Count(*) 
into cnt
	FROM "@CT_CZASCH_W"
	WHERE "Code" = :list_of_cols_val_tab_del
	AND "U_Czynnosc" NOT IN (SELECT CAST("Remark" AS NVARCHAR(100)) FROM "@CT_CZYNNOSCI")
;

if :cnt>0 
then error:=1 
;
error_message:= N'Wpisana czynność jest spoza listy - Zakładka Zawieszanie.'
;

end 
if 
;

END 
if ;

IF :error = 0 
AND :object_type ='CT_CZASCH' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN SELECT
      Count(*) 
into cnt
	FROM "@CT_CZASCH_P"
	WHERE "Code" = :list_of_cols_val_tab_del
	AND "U_Czynnosc" NOT IN (SELECT CAST("Remark" AS NVARCHAR(100)) FROM "@CT_CZYNNOSCI")
;

if :cnt>0 
then error:=1 
;
error_message:= N'Wpisana czynność jest spoza listy - Zakładka Praca.'
;

end 
if 
;

END 
if ;

-- Blokada zwolnienia partii na magazynie innym niż wyrobu gotowych 
IF :error = 0 
AND :object_type = N'CT_PF_AdditonalBatch' 
AND (:transaction_type =N'U')
then
select count(*) into cnt 
 
from  
(
select t0."Code"
from
"@CT_PF_AABT" t0 
inner join "@CT_PF_AABT" t1 on t0."Code"=t1."Code" and t0."LogInst"=t1."LogInst"+1 
inner join "@CT_PF_OABT" t00 on t0."Code"=t00."Code" 
inner join "OBTN" t2 on t0."U_DistNumber"=t2."DistNumber" and t0."U_ItemCode" =t2."ItemCode"
inner join OBBQ t3 on t2."AbsEntry"=t3."SnBMDAbs"  and "OnHandQty">0 
inner join OBIN t4 on t3."BinAbs"=t4."AbsEntry"
where t0."Code"=:list_of_cols_val_tab_del
and t1."U_Status" <>'R'
and t0."U_Status" ='R'
and t0."LogInst"=(select Max("LogInst") from "@CT_PF_AABT" where "Code"=:list_of_cols_val_tab_del)
--and t4."WhsCode" like '%GW%'
 and   t2."U_BADQTY" <t3."OnHandQty"
union all 

select t0."Code"
from
"@CT_PF_OABT" t0   
where t0."Code"=:list_of_cols_val_tab_del
and t0."U_Status" <>'R'
);
  
if :cnt=0 
then error:=1 
;
error_message:= N'Nie można zwolnic partii brak odpowiedniej ilosci na magazynie '
;

end 
if 
;
 


END if;



-- Blokada przesuniecia z listy ilosci , zawieszonych 
IF :error = 0 
AND :object_type = '67'
AND (:transaction_type =N'A')
then
	select count(*) into cnt 
	 
	from
		WTR1 t0
		inner join OWTR t000 on t0."DocEntry"=t000."DocEntry"
		inner join OITL t1 on t0."DocEntry"=t1."DocEntry" and t0."LineNum"=t1."DocLine" and t1."DocType"=67 and t1. "DocQty">0 
		inner join OBTL t2 on t1."LogEntry"=t2."ITLEntry" 
		inner join obin tobin  on t2."BinAbs"=tobin."AbsEntry"
		inner join obtn bt  on t2."SnBMDAbs"=bt."AbsEntry"
		inner join 
		(
			select t1."DocLine",t1."DocEntry" ,t3."BinAbs",t3."SnBMDAbs",t3."Quantity",t1."DocQty",t1."LocCode"
			from
			 OITL t1 --on t0."DocEntry"=t1."DocEntry" and t0."LineNum"=t1."DocLine" and t1."DocType"=67
			inner join OBTL t3 on t1."LogEntry"=t3."ITLEntry" 
			where t1. "DocQty"<0 and t1."DocType"=67 and t1."DocEntry"=:list_of_cols_val_tab_del
		) T3 on t3."DocLine"=t1."DocLine" and t3."DocEntry"=t1."DocEntry"  and t1."DocQty"=t3."DocQty"*-1  and t3."SnBMDAbs"=t2."SnBMDAbs"
	
	
		inner join  (SELECT stu."U_Attribute2",stu."U_Attribute3",stu."U_BinAbs" , sum(stu."U_IloscOrig"-stu."U_IloscZlych" - stu."U_IloscSU")	"SUM"
		from 
		"@CT_WMS_OSTU" stu
		where  stu."U_StatusSU"='2'
		group by stu."U_Attribute2",stu."U_Attribute3",stu."U_BinAbs"
		)stu
		  on stu."U_Attribute2"=t0."ItemCode"  and t3."BinAbs"=stu."U_BinAbs" and bt."DistNumber"=stu."U_Attribute3"
	where t0."DocEntry"=:list_of_cols_val_tab_del
			and 
			ifnull(t000."U_Guid",'') <> '1'  and tobin."BinCode" like '%IZ%'
			--and stu."U_StatusSU"='2'
	        and t2. "Quantity">	stu."SUM";

	if :cnt>0 
		then
		 error:=13;
		error_message:= N'Brak wystarczającej nie zawieszonej ilosci do przesunieci' ;
		
		end 
		if 
	;


END 
if ;
-- walidacja przyjecia z produkcji 

--select * from "CT_ZLECENIA_KOLEJNOSC"

IF  

:error = 0 and
:object_type ='CT_PF_PickReceipt' 
  
THEN
 call CT_Receipt_Before(:transaction_type ,:list_of_cols_val_tab_del,  :error,  :error_message);
		
END  if ;

---------J####KONTROLA--------
IF  
:error = 0 and
:object_type ='67' 
AND ( :transaction_type =N'A' or :transaction_type =N'U' )
THEN
 
	select count(*) into cnt from "WTR1" t0
	inner join OITL t1 on t0."DocEntry"=t1."DocEntry" and t0."LineNum"=t1."DocLine" and t1."DocType"=67 and t1. "DocQty">0 
	inner join OBTL t2 on t1."LogEntry"=t2."ITLEntry" 
	inner join obtn bt  on t2."SnBMDAbs"=bt."AbsEntry"
	inner join oitm it  on t0."ItemCode"=it."ItemCode"
	
	where t0."WhsCode" like 'GW%' and it."U_JKontola"='Y' and bt."Status"<>'0'
	and t0."DocEntry"=:list_of_cols_val_tab_del;
	if(:cnt>0)
	then
	
	error:=132;
	error_message:= 'J#Kontrola - nie można przesunąc tej pozycji na magazyn GW';
	end if;
end if;
IF  
:error = 0 and
:object_type ='67' 

--####MM ręcznie na produkcji
AND ( :transaction_type =N'A' or :transaction_type =N'U' )
THEN

select count(*) into cnt from OWTR  where "DocEntry"=:list_of_cols_val_tab_del and ifnull("U_Guid",'')=''; 

if :cnt=1 --- nie automat
then
cnt:=0;
 select count(*) into cnt from "WTR1" t0
		inner join OITL t1i on t0."DocEntry"=t1i."DocEntry" and t0."LineNum"=t1i."DocLine" and t1i."DocType"=67 and t1i. "DocQty">0 
	inner join OITL t1f on t0."DocEntry"=t1f."DocEntry" and t0."LineNum"=t1f."DocLine" and t1f."DocType"=67 and t1f. "DocQty"<0 
	inner join OBTL t2i on t1i."LogEntry"=t2i."ITLEntry" 
	inner join OBTL t2f on t1f."LogEntry"=t2f."ITLEntry" 
	inner join OBIN t3i on t2i."BinAbs"=t3i."AbsEntry"
	inner join OBIN t3f on t2f."BinAbs"=t3f."AbsEntry"
	where (( t0."U_FromBinCode" <> t3f."BinCode" and t0."FromWhsCod" not  like 'MSU%') or ( t0."U_ToBinCode"<>t3i."BinCode" ))
	and (t0."ItemCode" like 'SU*' or t0."ItemCode" like 'PP%')
	and t0."DocEntry"=:list_of_cols_val_tab_del
	and ifnull(t0."BaseEntry",0)<>0;
	if(:cnt>0)
	then
	error:=1323;
	error_message:= 'Błedna lokalizacja początkowa lub koncowa ';
	end if;
end if;

	-- select count(*) into cnt from "WTR1" t0
	-- inner join OITL t1 on t0."DocEntry"=t1."DocEntry" and t0."LineNum"=t1."DocLine" and t1."DocType"=67 and t1. "DocQty">0 
	-- inner join OBTL t2 on t1."LogEntry"=t2."ITLEntry" 
	-- inner join obtn bt  on t2."SnBMDAbs"=bt."AbsEntry"
	-- inner join oitm it  on t0."ItemCode"=it."ItemCode"
	
	-- where t0."WhsCode" like 'GW%' and it."U_JKontola"='Y' and bt."Status"<>'0'
	-- and t0."DocEntry"=:list_of_cols_val_tab_del;
	-- if(:cnt>0)
	-- then
	
	-- error:=132;
	-- error_message:= 'J#Kontrola - nie można przesunąc tej pozycji na magazyn GW';
	-- end if;
end if;
---------J####KONTROLA zamykanie pojemników--------
--  IF  
-- :error = 0 and
-- :object_type ='CT_WMS_OSTU' 
-- AND (  :transaction_type =N'U' )
-- THEN
	
	
-- 	select count(*) into cnt  from 
-- 	"@CT_WMS_OSTU" t0 
-- 	inner join "@CT_PF_OMOR"  t1 on t0."U_Attribute1" =cast(t1."DocEntry" as nvarchar(11)) 
-- 	inner join "@CT_PF_BOM12" t2 on t1."U_BOMCode"=t2."Code" and t1."U_RtgCode"=t2."U_RtgCode"
-- 	inner join "@CT_PF_BOM16"  t3 on t2."Code"=t3."Code" and t2."U_RtgCode"=t3."U_RtgCode" and t2."U_OprCode"=t3."U_OprCode" and t2."U_RtgOprCode"=t3."U_RtgOprCode"
-- 	inner join "@CT_PF_ORSC" t4 on t0."U_BinAbs"=t4."U_BinAbs" and t3."U_RscCode"=t3."U_RscCode"
-- 	inner join "@ACT_WMS_OSTU" t5 on t0."Code"=t5."Code" and t5."LogInst"=(select max("LogInst")-1 from  "@ACT_WMS_OSTU"  where "Code"=:list_of_cols_val_tab_del)
-- 	where t2."U_JKONTROLA"='Y' and t0."U_StatusSU"='1' and t5."U_StatusSU"<>'4'  and t0."Code"=:list_of_cols_val_tab_del;
-- 	 if(:cnt>0)
-- 	then
	
-- 			error:=132;
-- 			error_message:= 'J#Kontrola - nie można zamknąć pojemnika wymagana J#KONTROLA';
-- 	end if;
 

-- end if;

if :error = 0 and
:object_type ='CT_PF_ManufacOrd' 
AND (  :transaction_type =N'U' or :transaction_type =N'A' )
THEN
	
	
	select count(*) into cnt  from "@CT_PF_OMOR" where "DocEntry"=:list_of_cols_val_tab_del and "U_Warehouse" not Like 'MPR%' ;
	 
	 if(:cnt>0)
	then
	
			error:=137;
			error_message:= 'Błedny magazyn na zleceiu produkcyjnym';
	end if;
	
	-- select count(*) into cnt  from "@CT_PF_MOR3" where "DocEntry"=:list_of_cols_val_tab_del and "U_IssueType" <> 'M' ; 
	--  if(:cnt>0)
	-- then
	-- 		error:=137;
	-- 		error_message:= 'Surowiec nie może być ustawiony na pobranie wsteczne';
	-- end if;
end if;

if :error = 0 and
:object_type ='1250000001' 
AND (  :transaction_type =N'A' )
THEN

select ifnull(Count (*) ,0) into cnt
--t0."U_DocEntry",t1."U_FromBinCode",t0."U_ToBinCode", Count (*) 
from "WTQ1" t0 
inner join "WTQ1" t1 on t0."U_DocEntry"=t1."U_DocEntry" and t1."U_FromBinCode"=t0."U_FromBinCode" and t0."U_ToBinCode"=t1."U_ToBinCode"  and t0."DocEntry"<>t1."DocEntry" and t0."LineStatus"=t1."LineStatus"
inner join "OWTQ" t11 on t1."DocEntry"=t11."DocEntry"

	where t0."LineStatus"='O' and t0."DocEntry"=:list_of_cols_val_tab_del and t11."U_Dismiss"<>'1';
 if(:cnt>0)
	then
			error:=537;
			error_message:= 'Istnieje otwarte rządanie dla takiego ruchu magazynowego';
	end if;
end if;
--------------------------------------------------------------------------------------------------------------------------------
if :error = 0 and
:object_type ='CT_PF_ManufacOrd' 
AND (    :transaction_type =N'A' )
THEN
	
	
	select count(*) into cnt  from "@CT_PF_OMOR" t0
	inner join  NNM1  t1 on t0."Series" =t1."Series"
	inner join OWHS t2 on t0."U_Warehouse"=t2."WhsCode"  
	 where "DocEntry"=:list_of_cols_val_tab_del  and t1."BPLId"<>t2."BPLid";
	 
	 if(:cnt>0)
	then
	
			error:=137;
			error_message:= 'Błedna seria dokumentacyjna dla wybranego odziału';
	end if;
	
	 
end if;
----------------------------------------------------- zasoby---------------------------------------------------------------------------
if :error = 0 and
:object_type ='CT_PF_Resource' 
AND (    :transaction_type =N'A' or :transaction_type =N'U' )
THEN
	-----------------------------------------------------  sprawdzanie lokalizacji---------------------------------------------------------------------------
	/* 
	select count(*) into cnt  from "@CT_PF_ORSC" t0
		inner join "@CT_PF_ORSC" t1 on t0."U_RscCode" <>t1."U_RscCode" and t0."U_BinAbs"=t1."U_BinAbs"
	 where t0."Code"=:list_of_cols_val_tab_del and ifnull (t0."U_BinAbs",0)<>0;
	 if(:cnt>1)
	then
	
			error:=139;
			error_message:= 'Lokalizacja wydń musi być unikalny';
	end if;

		select count(*) into cnt  from "@CT_PF_ORSC" t0
			inner join "@CT_PF_ORSC" t1 on t0."U_RscCode" <>t1."U_RscCode" and t0."U_RBinAbs"=t1."U_RBinAbs"
	 	where t0."Code"=:list_of_cols_val_tab_del and ifnull (t0."U_RBinAbs",0)<>0;
	 if(:cnt>1)
	then
	
			error:=140;
			error_message:= 'Lokalizacja  przyjęc musi być unikalny';
	end if;
	 	select count(*) into cnt  from "@CT_PF_ORSC" t0
			inner join "@CT_PF_ORSC" t1 on t0."U_RscCode" <>t1."U_RscCode" and t0."U_JKONBIN"=t1."U_JKONBIN"
	 	where t0."Code"=:list_of_cols_val_tab_del and ifnull (t0."U_JKONBIN",0)<>0;
	 if(:cnt>1)
	then
	
			error:=141;
			error_message:= 'Lokalizacja J#Kontrola musi być unikalna';
	end if;

	-----------------------------------------------------  sprawdzanie Bufora

	select count (*) into cnt from "@CT_PF_ORSC" where  "Code"=:list_of_cols_val_tab_del and  "U_UseBufor"='Y' and ifnull("U_BUFFOR",'')='';

	if(:cnt>0)
		then
				error:=142;
				error_message:= 'przy wykożystaniu bufora Lokalicaja jest wymagana';
		end if;
*/
end if;


-----------------------------------------------------  J#Kontrola sprawdzanie undeksu
IF  
:error = 0 and
:object_type ='4' 
AND ( :transaction_type =N'A' or :transaction_type =N'U' )
THEN
 
	select count(*) into cnt from "@CT_PF_BOM16" t0
	inner join OITM t1 on t0."U_BomCode"=t1."ItemCode"
		inner join "@CT_PF_ORSC" t2 on t0."U_RscCode"=t2."U_RscCode"
	where ifnull(t2."U_JKONBIN",'')=''
	and t1."ItemCode"=:list_of_cols_val_tab_del and t1."U_JKontola"='Y';
	if(:cnt>0)
			then
	
		error:=143;
		error_message:= 'J#Kontrola -brak lokaizacji J-kontroli dla powiazanego zasobu z technologią produkcyjną';
	end if;
end if;

-------Walidacja na duplikowanie kodu Odette Dispatch Control

IF :error = 0 
AND :object_type ='CT_WMS_OVDA' 
AND (:transaction_type =N'A' OR :transaction_type =N'U')
THEN 
	SELECT Count(t0."U_Odette") INTO cnt 
	FROM "@CT_WMS_OVDA" t0
	WHERE t0."U_Odette" = (select t1."U_Odette" from "@CT_WMS_OVDA" t1 where T1."Code" = :list_of_cols_val_tab_del);
 
	if :cnt>1 
		then error:=1;
			error_message:= N'Etykieta Odette została juz przypisana do innej partii'; 
	end if;
END if; 


------- porzypisywanie wolnych pokemników po zwolnieniu zlecenia
IF  :object_type ='CT_PF_ManufacOrd' 
AND (:transaction_type = N'A' OR :transaction_type = 'U')
then


select count(*) into cnt from
"@CT_PF_OMOR" where "DocEntry"=:list_of_cols_val_tab_del and "U_Status"='RL' and :transaction_type='A';

select count (*) into cnt2    from "@CT_PF_OMOR" t0
 inner join "@CT_PF_AMOR" t1 on t1."DocEntry"=t0."DocEntry" and t1."LogInst"+1=(select Max("LogInst") from "@CT_PF_AMOR" where "DocEntry"=t0."DocEntry")
 where t1."U_Status"<>'RL' and t0."U_Status"='RL' and t0."DocEntry"=:list_of_cols_val_tab_del and :transaction_type='U';

if(:Cnt>0 OR :CNT2 >0)
THEN
call CreateSSTU_FROM_MOR_RELEASE  (:list_of_cols_val_tab_del);

update d1 set "U_DocEntry"=cast( t0."DocEntry" as nvarchar(11)),
 "U_DocNum" =cast( mor."DocNum" as nvarchar(11))

  from CT_ZLECENIA_KOLEJNOSC t0 
inner join "@CT_PF_OMOR" mor on t0."DocEntry"=mor."DocEntry"
inner join "@CT_PF_ORSC" frm on t0."Z" =frm."U_RscCode" 
inner join "@CT_PF_ORSC" to on t0."Do"= to."U_RscCode"
inner join OBIN bin on to."U_BinAbs" =bin."AbsEntry"

inner join drF1 d1 on d1."U_FromBinCode" =frm.U_BUFFOR and d1."U_ToBinCode"=bin."BinCode" and substring(d1."ItemCode",3)=substring(mor."U_ItemCode",3)
inner join odrf drf on d1."DocEntry"=drf."DocEntry"
 where drf."DocStatus"='O' and ifnull(d1."U_DocEntry",'')='-1' and t0."DocEntry" =:list_of_cols_val_tab_del;


END IF ;

end if;

--- Zamykanie pojemników i walidacja po recznym RW
IF  :object_type ='60' 
AND :transaction_type = N'A'
then
select count(*) into cnt from
"IGE1" where "DocEntry"=:list_of_cols_val_tab_del and ifnull("U_DocEntry",'')='';
if(:Cnt>0)
then 



with b as( 
select  sum (ifnull(U_BLOK,0)) UBLOK  ,
"U_Attribute2","U_Attribute3" ,"U_BinAbs" ,"U_BinCode" from "@CT_WMS_OSTU"
where "U_Status"='O'  and "U_Attribute5"<>'Wor'
group by "U_Attribute2","U_Attribute3" ,"U_BinAbs" ,"U_BinCode"
)

 select count(*) into cnt2 from 
   	IGE1 t0
		inner join OIGE t000 on t0."DocEntry"=t000."DocEntry"
		inner join OITL t1 on t0."DocEntry"=t1."DocEntry" and t0."LineNum"=t1."DocLine" and t1."DocType"=60 and t1. "DocQty"<0 
		inner join OBTL t2 on t1."LogEntry"=t2."ITLEntry" 
        inner join obtn bt  on t2."SnBMDAbs"=bt."AbsEntry"
        inner join OBBQ bbq on bbq."BinAbs" =t2."BinAbs" and bbq."SnBMDAbs"=t2."SnBMDAbs"
        inner join b stu on bt."DistNumber"=stu."U_Attribute3" and bt."ItemCode"=stu."U_Attribute2" and t2."BinAbs"=stu."U_BinAbs" 
        
    where 
     bbq."OnHandQty"- stu."UBLOK">t2."Quantity" and 
    t0."DocEntry"=:list_of_cols_val_tab_del  and ifnull(t0."U_DocEntry",'')='';
if(:cnt2>0)
then 
error:=1541;
error_message:='Nie można zrobić ręcznego RW partia czeka na przesuniecie';

else 
call     CloseSU_Receipt(:list_of_cols_val_tab_del );
end if;

end if;

end if;
------- Zamykanie pojemników po zamknieciu zlecenia
IF  :object_type ='CT_PF_ManufacOrd' 
AND :transaction_type = N'U'
then


select count(*) into cnt from
"@CT_PF_OMOR" where "DocEntry"=:list_of_cols_val_tab_del and "U_Status"='CL';




if(:Cnt>0)
THEN

-- połacz sie z ostatnim procesem i sprawdz czy można zamknąć zlecenie - czy nie ma tam pojemników oczekujących 
select count(*) into cnt2 from "@CT_WMS_OSTU" to 
where ( "U_IloscZA">0 or "U_IloscSU">0 )and "U_StatusSU"<>'3' and "U_Status"='O'
and "U_Attribute1" =cast (:list_of_cols_val_tab_del as nvarchar(20)) and "U_Attribute6"='Koniec';
if(:cnt2>0)
then 
error:=1111;
error_message:='nie można zamknąc zlecenia pojemniki na ostatnim procesie nie są przujęte';

else 

update t1 set "U_Status" = case when t1."U_IloscZA"=0 then 'C' else 'O' end ,
  "U_IloscOrig"=case when t1."U_IloscZA"=0 then t1."U_IloscOrig" else t1."U_IloscZA" end 
 from "@CT_PF_OMOR" t0
inner join "@CT_WMS_OSTU"  t1 on cast(t0."DocEntry" as nvarchar(11)) =t1."U_Attribute1"
where t0."U_Status"='CL' and  t1."U_Status"='O'     and t1."U_StatusSU"= '2' and t1."U_Attribute6"<>'Koniec'
and t0."DocEntry"=:list_of_cols_val_tab_del ;
--update "@CT_WMS_OSTU" set "U_Status"='C' where "U_Attribute1" =cast(:list_of_cols_val_tab_del as nvarchar(11)) and "U_IloscZA"=0 and "U_StatusSU"= '2';
-- teraz rządania przesuniecia tymczasowe
update t1 set "U_DocEntry" ='-1' , "U_DocNum"='-1'  from odrf t0 
inner join drf1 t1 on t0."DocEntry"=t1."DocEntry" and
ifnull( t1."U_DocEntry",'') =cast(:list_of_cols_val_tab_del as nvarchar(11)) and t0."DocStatus"='O';


call CT_CheckBigBox();
END IF ;

end if;
end if;
 --Blokada przeniesienia nie zaknminetego pojemnika "U_Status_Pojemnika"
 IF  :object_type ='67' 
AND :transaction_type = N'A'
then
select count(*) into cnt from 
  wtr1 t0  
		inner join OITL t1 on t0."DocEntry"=t1."DocEntry" and t0."LineNum"=t1."DocLine" and t1."DocType"=67 and t1. "DocQty"<0 
		inner join OBTL t2 on t1."LogEntry"=t2."ITLEntry" 
		inner join obtn bt  on t2."SnBMDAbs"=bt."AbsEntry"
        where t0."DocEntry"= :list_of_cols_val_tab_del and bt."U_Status_Pojemnika"='O';
if(:cnt>0)
then 
error:=154;
error_message:='Błedny status pojemnika ';
end if ;
end if;

-- Select the return values
select :error, :error_message FROM dummy;


end;