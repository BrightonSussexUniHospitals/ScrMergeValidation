SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
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
Description:				A function that stores information on the different source systems in the merge process
**************************************************************************************************************************************************/

-- Test me
-- SELECT Merge_DM_Match.fnSrcSys('SCR WSHT', 1)

CREATE FUNCTION [Merge_DM_Match].[fnSrcSys]
	(@DataSourceName VARCHAR(255)
	,@ConversionSrcSys INT = NULL
	,@ReturnType TINYINT
	)

RETURNS SQL_VARIANT
AS
BEGIN

		/************************************************************************************************/
		-- Resolution by data source name
		/************************************************************************************************/
		
		-- SCR West
		IF @DataSourceName = 'SCR WSHT'
		RETURN CASE WHEN @ReturnType = 1
					THEN '1'
					END

		-- SCR East
		IF @DataSourceName = 'SCR BSUH'
		RETURN CASE WHEN @ReturnType = 1
					THEN '2'
					END

		-- PAS
		IF @DataSourceName = 'Careflow'
		RETURN CASE WHEN @ReturnType = 1
					THEN '3'
					END

		/************************************************************************************************/
		-- Resolution by conversion
		/************************************************************************************************/
		
		-- Live to Merge
		IF @DataSourceName = 'Convert Live to Merge'
		RETURN CASE WHEN @ReturnType = 1 AND @ConversionSrcSys = 1
					THEN '2'
					WHEN @ReturnType = 1 AND @ConversionSrcSys = 4
					THEN '1'
					END

		-- Merge to Live
		IF @DataSourceName = 'Convert Merge to Live'
		RETURN CASE WHEN @ReturnType = 1 AND @ConversionSrcSys = 1
					THEN '4'
					WHEN @ReturnType = 1 AND @ConversionSrcSys = 2
					THEN '1'
					END
		
		
		/************************************************************************************************/
		-- Catch all
		/************************************************************************************************/
		
		-- Catch all
		RETURN 0

END
GO
