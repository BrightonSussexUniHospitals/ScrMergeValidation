SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [Merge_DM_MatchAudit].[uspConfirmMajor]

		(@Success BIT = NULL
		,@ErrorMessage VARCHAR(MAX) = NULL
		,@UserID VARCHAR(255) = NULL

		,@tableName VARCHAR(255) = NULL
		,@SrcSys_Major TINYINT = NULL
		,@Src_UID_Major VARCHAR(255) = NULL
		)

AS 

/******************************************************** © Copyright & Licensing ****************************************************************
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
Description:				A stored procedure to confirm a major entity
**************************************************************************************************************************************************/

/*****************************************************************************************************************************************/
-- Create and populate the #Aud_ConfirmMajor table if it doesn't already exist
/*****************************************************************************************************************************************/
		
		IF OBJECT_ID('tempdb..#Aud_ConfirmMajor') IS NULL 
		BEGIN
				
				-- Throw an error if there are missing parameter values
				IF @Success IS NULL OR @UserID IS NULL OR @tableName IS NULL OR @SrcSys_Major IS NULL OR @Src_UID_Major IS NULL
				THROW 50000, 'A null parameter value has been passed where one is expected', 1
				
				-- Create the #Aud_ConfirmMajor table
				CREATE TABLE #Aud_ConfirmMajor
							(Success BIT
							,ErrorMessage VARCHAR(MAX)
							,UserID VARCHAR(255)
							,tableName VARCHAR(255)
							,SrcSys_Major TINYINT
							,Src_UID_Major VARCHAR(255)
							)

				-- Populate the #Aud_ConfirmMajor table with the provided parameter values
				INSERT INTO	#Aud_ConfirmMajor (Success,ErrorMessage,UserID,tableName,SrcSys_Major,Src_UID_Major)
				VALUES (@Success, @ErrorMessage, @UserID, @tableName, @SrcSys_Major, @Src_UID_Major)
				
		END

/*****************************************************************************************************************************************/
-- Insert an audit record of attempts to update Merge_DM_Match.tblConfirmMajor
/*****************************************************************************************************************************************/
		
INSERT INTO Merge_DM_MatchAudit.tblConfirmMajor
			(Success
			,ErrorMessage
			,UserID
			,tableName
			,SrcSys_Major
			,Src_UID_Major
			)

SELECT		Success
			,ErrorMessage
			,UserID
			,tableName
			,SrcSys_Major
			,Src_UID_Major
FROM		#Aud_ConfirmMajor
GO
