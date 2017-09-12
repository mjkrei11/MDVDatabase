﻿CREATE procedure sp_ssrs_EngagementQA (@Database nvarchar(200))as/*declare@Database nvarchar(200)set @Database = 'HorizontalShuffleTest'exec sp_ssrs_EngagementQA @Database*/declare@sql nvarchar(max),@parms nvarchar(max),@CR char(1)set @CR = char(13)set @sql = 'select media.NPI, media.FirstName, media.LastName, media.SystemName, ' + @CRset @sql = @sql + 'media.SystemID, media.CollectionName, media.CollectionID, metric.EngagementType, metric.OrderID ' + @CRset @sql = @sql + 'from ' + @Database + '.dbo.PhysMetEngagementMedia media ' + @CRset @sql = @sql + 'inner join ' + @Database + '.dbo.PhysMetEngagement metric ' + @CRset @sql = @sql + 'on metric.ComboKey = media.ComboKey ' + @CRset @sql = @sql + 'where metric.EngagementNumber is null ' + @CRset @sql = @sql + 'and metric.EngagementType <> ''Overall'' ' + @CRset @sql = @sql + 'order by CollectionName, SystemName, LastName, FirstName, metric.OrderID ' + @CRexec(@sql)