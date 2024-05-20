SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



--test  
--SELECT dbo.fnDaysToEndOfWeek(GETDATE(),0) DaysTillWeekEnd


/******************************************************** © Copyright & Licensing ****************************************************************
© 2020 Perspicacity Ltd & Brighton & Sussex University Hospitals

This code / file is part of Perspicacity & BSUH's Cancer Data Warehouse & Reporting suite.

This Cancer Data Warehouse & Reporting suite is free software: you can 
redistribute it and/or modify it under the terms of the GNU Affero 
General Public License as published by the Free Software Foundation, 
either version 3 of the License, or (at your option) any later version.

This Cancer Data Warehouse & Reporting suite is distributed in the hope 
that it will be useful, but WITHOUT ANY WARRANTY; without even the 
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
See the GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

A full copy of this code can be found at https://github.com/BrightonSussexUniHospitals/CancerReportingSuite

You may also be interested in the other repositories at https://github.com/perspicacity-ltd or
https://github.com/BrightonSussexUniHospitals

Original Work Created Date:	05/07/2023
Original Work Created By:	Perspicacity Ltd (Matthew Bishop)
Original Work Contact:		07545 878906
Original Work Contact:		matthew.bishop@perspicacityltd.co.uk
Description:				Calculate the days to the end of the week
**************************************************************************************************************************************************/

CREATE FUNCTION [dbo].[fnDaysToEndOfWeek]

				(@CurrentDate DATETIME2
				,@CalcWaitTimesAsNightBefore BIT
				)

RETURNS TINYINT
AS
BEGIN

		-- Declare an internal variable to represent the days to the end of the week
		DECLARE @fnDaysToEndOfWeek TINYINT

		-- Declare & Set the @NightBeforeAdjustment based on the @ReturnType
		DECLARE @NightBeforeAdjustment INT
		SELECT @NightBeforeAdjustment = CASE WHEN @CalcWaitTimesAsNightBefore = 1 THEN -1 ELSE 0 END

		/*****************************************************************************************************************************/
		-- Return the days until the end of the week (compensating for DATEFIRST so Monday is always a 1)
		/*****************************************************************************************************************************/
		
		-- Return the days until the end of the week (compensating for DATEFIRST so Monday is always a 1)
		SET @fnDaysToEndOfWeek = (15 - DATEPART(WEEKDAY, DATEADD(DAY, @NightBeforeAdjustment,@CurrentDate)) - @@DATEFIRST) % 7

		-- Catch all for records that don't meet the criteria
		RETURN	@fnDaysToEndOfWeek

END

GO
GRANT EXECUTE ON  [dbo].[fnDaysToEndOfWeek] TO [cancer-ptl-integration]
GO
