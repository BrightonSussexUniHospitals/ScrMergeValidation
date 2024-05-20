CREATE TABLE [Merge_DM_MatchAudit].[tblProcessAudit]
(
[SessionID] [smallint] NOT NULL,
[UserID] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ProcName] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[Section] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[StartDttm] [datetime2] NULL CONSTRAINT [DF__tblProces__Start__3537AEDF] DEFAULT (getdate()),
[EndDttm] [datetime2] NULL,
[Success] [bit] NULL,
[ErrorMessage] [varchar] (max) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
