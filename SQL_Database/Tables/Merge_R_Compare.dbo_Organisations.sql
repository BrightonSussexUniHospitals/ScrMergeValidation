CREATE TABLE [Merge_R_Compare].[dbo_Organisations]
(
[DW_Organisations_ID] [bigint] NOT NULL IDENTITY(1, 1),
[DW_LOAD_ID] [int] NULL,
[DW_CREATION_DATE_TIME] [datetime] NULL,
[DW_MODIFIED_DATE_TIME] [datetime] NULL,
[DW_SOURCE_ID] [nvarchar] (200) COLLATE Latin1_General_CI_AS NULL,
[DW_SOURCE_SYSTEM_ID] [int] NULL,
[DW_SOURCE_PATIENT_ID] [nvarchar] (200) COLLATE Latin1_General_CI_AS NULL,
[DW_SOURCE_SYSTEM_CREATED_DATE_TIME] [datetime] NULL,
[DW_SOURCE_SYSTEM_MODIFIED_DATE_TIME] [datetime] NULL,
[ID] [int] NULL,
[Code] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[Description] [varchar] (250) COLLATE Latin1_General_CI_AS NULL,
[IsDeleted] [bit] NULL,
[UpperCode] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[RDC_AllianceCode] [varchar] (9) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
