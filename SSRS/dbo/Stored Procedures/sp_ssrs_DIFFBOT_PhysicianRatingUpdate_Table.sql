


CREATE procedure [dbo].[sp_ssrs_DIFFBOT_PhysicianRatingUpdate_Table] (@Database nvarchar(200), @Month int)

as

/*
declare
@Database nvarchar(200), @Month int
set @Database = 'Rothman'
set @Month = 4

exec sp_ssrs_DIFFBOT_PhysicianRatingUpdate_Table @Database, @Month
*/

create table #ratings(
	RatingType nvarchar(20),
	RatingSite nvarchar(20),
	Rating decimal(2,1),
	RatingDate datetime
)
insert #ratings exec sp_ssrs_DIFFBOT_BarChart @Database, @Month

create table #volume(
	VolumeType nvarchar(20),
	VolumeSite nvarchar(20),
	Volume int,
	VolumeDate datetime,
	OrderID int
)
insert #volume exec sp_ssrs_DIFFBOT_PieCharts @Database, @Month

create table #table_data(
	HealthGradesAverageRatings decimal(2,1),
	HealthGradesNumberOfRatings int,
	HealthGradesRatingDifference decimal(2,1),
	HealthGradesVolumeDifference int,
	VitalsAverageRatings decimal(2,1),
	VitalsNumberOfRatings int,
	VitalsRatingDifference decimal(2,1),
	VitalsVolumeDifference int,
	UCompareAverageRatings decimal(2,1),
	UCompareNumberOfRatings int,
	UCompareRatingDifference decimal(2,1),
	UCompareVolumeDifference int,
	RateMDsAverageRatings decimal(2,1),
	RateMDsNumberOfRatings int,
	RateMDsRatingDifference decimal(2,1),
	RateMDsVolumeDifference int
)

insert #table_data(HealthGradesAverageRatings) select null

/* UPDATE HEALTHGRADES DATA FOR TABLE */
update		#table_data
set			HealthGradesAverageRatings = r.Rating,
			HealthGradesNumberOfRatings = v.Volume,
			HealthGradesRatingDifference = r.Rating - rb.Rating,
			HealthGradesVolumeDifference = v.Volume - vb.Volume
from		#ratings r
inner join	#volume v
on			v.VolumeSite = r.RatingSite
and			v.VolumeType = r.RatingType
inner join	#ratings rb
on			rb.RatingSite = r.RatingSite
and			rb.RatingType = 'Baseline'
inner join	#volume vb
on			vb.VolumeSite = v.VolumeSite
and			vb.VolumeType = 'Baseline'
where		r.RatingSite = 'HealthGrades'
and			r.RatingType = 'Updated'

--select * from #table_data 

/* UPDATE VITALS DATA FOR TABLE */
update		#table_data
set			VitalsAverageRatings = r.Rating,
			VitalsNumberOfRatings = v.Volume,
			VitalsRatingDifference = r.Rating - rb.Rating,
			VitalsVolumeDifference = v.Volume - vb.Volume
from		#ratings r
inner join	#volume v
on			v.VolumeSite = r.RatingSite
and			v.VolumeType = r.RatingType
inner join	#ratings rb
on			rb.RatingSite = r.RatingSite
and			rb.RatingType = 'Baseline'
inner join	#volume vb
on			vb.VolumeSite = v.VolumeSite
and			vb.VolumeType = 'Baseline'
where		r.RatingSite = 'Vitals'
and			r.RatingType = 'Updated'

/* UPDATE UCOMPARE DATA FOR TABLE */
update		#table_data
set			UCompareAverageRatings = r.Rating,
			UCompareNumberOfRatings = v.Volume,
			UCompareRatingDifference = r.Rating - rb.Rating,
			UCompareVolumeDifference = v.Volume - vb.Volume
from		#ratings r
inner join	#volume v
on			v.VolumeSite = r.RatingSite
and			v.VolumeType = r.RatingType
inner join	#ratings rb
on			rb.RatingSite = r.RatingSite
and			rb.RatingType = 'Baseline'
inner join	#volume vb
on			vb.VolumeSite = v.VolumeSite
and			vb.VolumeType = 'Baseline'
where		r.RatingSite = 'UCompare'
and			r.RatingType = 'Updated'

/* UPDATE RATEMDS DATA FOR TABLE */
update		#table_data
set			RateMDsAverageRatings = r.Rating,
			RateMDsNumberOfRatings = v.Volume,
			RateMDsRatingDifference = r.Rating - rb.Rating,
			RateMDsVolumeDifference = v.Volume - vb.Volume
from		#ratings r
inner join	#volume v
on			v.VolumeSite = r.RatingSite
and			v.VolumeType = r.RatingType
inner join	#ratings rb
on			rb.RatingSite = r.RatingSite
and			rb.RatingType = 'Baseline'
inner join	#volume vb
on			vb.VolumeSite = v.VolumeSite
and			vb.VolumeType = 'Baseline'
where		r.RatingSite = 'RateMDs'
and			r.RatingType = 'Updated'

select		*
from		#table_data

drop table #ratings
drop table #volume
drop table #table_data


