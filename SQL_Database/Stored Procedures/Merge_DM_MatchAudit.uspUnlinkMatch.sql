SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [Merge_DM_MatchAudit].[uspUnlinkMatch]

		(@Success BIT
		,@ErrorMessage VARCHAR(MAX) = NULL
		,@UserID VARCHAR(255)

		,@tableName VARCHAR(255)
		,@SrcSys_Major TINYINT
		,@Src_UID_Major VARCHAR(255)
		,@SrcSys TINYINT
		,@Src_UID VARCHAR(255)
		)

AS 

I/******************************************************** © Copyright & Licensing ****************************************************************
© 2024 Perspicacity Ltd & University Hospitals Sussex

This code / file is part of Perspicacity & University Hospitals Sussex SCR merge validation suite.

This SCR merge validation suite is free software: you can 
redistribute it and/or modify it under the terms of the GNU Affero 
General Public License as published by the Free Software Foundation, 
either version 3 of the License, or (at your option) any later version.

This SCR migration merge suite is distributed in the hope 
that it will be useful, but WITHOUT ANY WARRANTY; without even the 
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
See the GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

A full copy of this code can be found at https://github.com/BrightonSussexUniHospitals/ScrMergeValidation

You may also be interested in the other repositories at https://github.com/perspicacity-ltd or
https://github.com/BrightonSussexUniHospitals

Original Work Created Date:	31/01/2024
Original Work Created By:	Perspicacity Ltd (Matthew Bishop)
Original Work Contact:		07545 878906
Original Work Contact:		matthew.bishop@perspicacityltd.co.uk
Description:				A stored procedure to audit unlinking of incorrect matches between an entity and the major entity
**************************************************************************************************************************************************/

NSERT INTO Merge_DM_MatchAudit.tblUnlinkMatch
		(Success
		,ErrorMessage
		,UserID

		,tableName
		,SrcSys_Major
		,Src_UID_Major
		,SrcSys
		,Src_UID
		)

VALUES	(@Success
		,@ErrorMessage
		,@UserID

		,@tableName
		,@SrcSys_Major
		,@Src_UID_Major
		,@SrcSys
		,@Src_UID
		)
GO
