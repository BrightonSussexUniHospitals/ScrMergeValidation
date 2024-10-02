CREATE TABLE [Merge_R_Compare].[pre_scr_NextActions]
(
[OrigPathwayUpdateEventID] [int] NOT NULL,
[PathwayUpdateEventID] [int] NULL,
[OrigSrcSysID] [tinyint] NOT NULL,
[SrcSysID] [int] NOT NULL,
[OrigCareID] [int] NULL,
[CareID] [int] NULL,
[NextActionID] [int] NULL,
[NextActionDesc] [varchar] (75) NULL,
[NextActionSpecificID] [int] NULL,
[NextActionSpecificDesc] [varchar] (50) NULL,
[AdditionalDetails] [varchar] (255) NULL,
[OwnerID] [int] NULL,
[OwnerDesc] [varchar] (50) NULL,
[OwnerRole] [varchar] (55) NULL,
[OwnerName] [varchar] (55) NULL,
[TargetDate] [date] NULL,
[Escalate] [int] NULL,
[OrganisationID] [int] NULL,
[OrganisationDesc] [nvarchar] (250) NULL,
[ActionComplete] [bit] NULL,
[Inserted] [datetime] NULL,
[InsertedBy] [varchar] (255) NULL,
[ACTION_ID] [int] NULL,
[LastUpdated] [datetime] NULL,
[LastUpdatedBy] [varchar] (50) NULL,
[CareIdIx] [int] NULL,
[CareIdRevIx] [int] NULL,
[CareIdIncompleteIx] [int] NULL,
[CareIdIncompleteRevIx] [int] NULL,
[ReportDate] [datetime] NULL,
[NextActionColourValue] [varchar] (50) NULL
)
GO
CREATE NONCLUSTERED INDEX [ix_NextActions] ON [Merge_R_Compare].[pre_scr_NextActions] ([PathwayUpdateEventID])
GO
