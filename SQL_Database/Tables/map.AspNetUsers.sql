CREATE TABLE [map].[AspNetUsers]
(
[SrcSysID] [tinyint] NOT NULL,
[ID] [int] NOT NULL,
[UserName] [nvarchar] (256) COLLATE Latin1_General_CI_AS NOT NULL,
[MergePrimary] [bit] NULL,
[MergeUsername] [nvarchar] (256) COLLATE Latin1_General_CI_AS NULL,
[LogicalDelete] [bit] NULL,
[DateLogged] [datetime2] NOT NULL CONSTRAINT [DF__AspNetUse__DateL__7997C974] DEFAULT (getdate())
) ON [PRIMARY]
GO
