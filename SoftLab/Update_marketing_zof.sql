SELECT T0.NumerZOF,
AnRyzBHP,
AnRyzJak,
AnRyzDP,
AnRyzLog,
AnRyzFin,
AnRyzInz,
AnRyzCzas,
T0.*


FROM wusr_vv_mg_ZapOfertowe_new_OGF t0 (nolock)
INNER JOIN mg_nagdow t1 (nolock) ON t0.nagid = t1.nagid
WHERE t0.NagId = 176595009101 and 
(AnRyzBHP IS NULL OR AnRyzJak IS NULL OR AnRyzDP IS NULL OR AnRyzLog  IS NULL OR AnRyzFin  IS NULL )

begin tran
--update wusr_vv_mg_ZapOfertowe_new_OGF
set AnRyzInz = 0 , AnRyzCzas = 0
where Nagid = 176595009101 

commit tran
rollback tran


