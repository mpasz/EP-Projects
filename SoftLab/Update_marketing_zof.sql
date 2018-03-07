
select * from wusr_vv_mg_ZapOfertowe_new_OGF (nolock)



SELECT 
AnRyzBHP,
AnRyzJak,
AnRyzDP,
AnRyzLog,
AnRyzFin,
T1.Data
--,* 
FROM wusr_vv_mg_ZapOfertowe_new_OGF t0 (nolock)
	INNER JOIN mg_nagdow t1 (nolock) ON t0.nagid = t1.nagid
WHERE 
t1.Data < GetDate()
AND 
(AnRyzBHP IS NULL OR AnRyzJak  IS NULL OR AnRyzDP  i IS NULL OR AnRyzLog  IS NULL OR AnRyzFin  IS NULL )


BEGIN TRAN

ROLLBACK TRAN
COMMIT TRAN