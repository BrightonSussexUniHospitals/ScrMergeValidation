CREATE TABLE [Merge_R_Compare].[dbo_tblAUDIT]
(
[DW_tblAUDIT_ID] [bigint] NOT NULL IDENTITY(1, 1),
[DW_LOAD_ID] [int] NULL,
[DW_CREATION_DATE_TIME] [datetime] NULL,
[DW_MODIFIED_DATE_TIME] [datetime] NULL,
[DW_SOURCE_ID] [nvarchar] (200) COLLATE Latin1_General_CI_AS NULL,
[DW_SOURCE_SYSTEM_ID] [int] NULL,
[DW_SOURCE_PATIENT_ID] [nvarchar] (200) COLLATE Latin1_General_CI_AS NULL,
[DW_SOURCE_SYSTEM_CREATED_DATE_TIME] [datetime] NULL,
[DW_SOURCE_SYSTEM_MODIFIED_DATE_TIME] [datetime] NULL,
[ACTION_ID] [int] NULL,
[USER_ID] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[ACTION_DATE] [smalldatetime] NULL,
[ACTION_TYPE] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[TABLE_NAME] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[CARE_ID] [int] NULL,
[RECORD_ID] [bigint] NULL
) ON [PRIMARY]
GO
