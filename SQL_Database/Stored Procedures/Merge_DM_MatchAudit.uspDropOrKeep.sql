SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [Merge_DM_MatchAudit].[uspDropOrKeep]

		(@Success BIT = NULL
		,@ErrorMessage VARCHAR(MAX) = NULL
		,@UserID VARCHAR(255) = NULL

		,@tableName VARCHAR(255) = NULL
		,@SrcSys TINYINT = NULL
		,@RecordID VARCHAR(255) = NULL
		,@RecordVariant VARCHAR(255) = NULL
		,@Migrate BIT = NULL
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
Description:				A stored procedure to mark a treatment or MDT as a duplicate to be dropped
**************************************************************************************************************************************************/

/*****************************************************************************************************************************************/
-- Create and populate the #Aud_DropOrKeep table if it doesn't already exist
/*****************************************************************************************************************************************/
		
		IF OBJECT_ID('tempdb..#Aud_DropOrKeep') IS NULL 
		BEGIN
				
				-- Throw an error if there are missing parameter values
				IF @Success IS NULL OR @UserID IS NULL OR @tableName IS NULL
				THROW 50000, 'A null parameter value has been passed where one is expected', 1
				
				-- Create the #Aud_DropOrKeep table
				CREATE TABLE #Aud_DropOrKeep
							(Success BIT
							,ErrorMessage VARCHAR(MAX)
							,UserID VARCHAR(255)
							,tableName VARCHAR(255)
							,SrcSys TINYINT NULL
							,RecordID VARCHAR(255) NULL
							,RecordVariant VARCHAR(255) NULL
							,Migrate BIT NULL
							)

				-- Populate the #Aud_DropOrKeep table with the provided parameter values
				INSERT INTO	#Aud_DropOrKeep (Success,ErrorMessage,UserID,tableName,SrcSys,RecordID,RecordVariant,Migrate)
				VALUES (@Success, @ErrorMessage, @UserID, @tableName, @SrcSys, @RecordID, @RecordVariant, @Migrate)
				
		END

/*****************************************************************************************************************************************/
-- Insert an audit record of attempts to update Merge_DM_Match.tblDropOrKeep
/*****************************************************************************************************************************************/
		
INSERT INTO Merge_DM_MatchAudit.tblDropOrKeep
			(Success
			,ErrorMessage
			,UserID
			,tableName
			,SrcSys
			,RecordID
			,RecordVariant
			,Migrate
			)

SELECT		Success
			,ErrorMessage
			,UserID
			,tableName
			,SrcSys
			,RecordID
			,RecordVariant
			,Migrate
FROM		#Aud_DropOrKeep
GO
