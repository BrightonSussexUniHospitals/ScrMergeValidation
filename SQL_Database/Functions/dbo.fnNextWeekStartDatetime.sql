SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





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
Description:				Calculate the midnight point that represents the end of the week and the start of next week
**************************************************************************************************************************************************/

CREATE FUNCTION [dbo].[fnNextWeekStartDatetime]

				(@CurrentDate DATETIME2
				,@CalcWaitTimesAsNightBefore BIT
				)

RETURNS DATETIME2
AS
BEGIN

		-- Declare an internal variable to represent the end of the week and the start of next week
		DECLARE @fnNextWeekStartDatetime DATETIME2

		/*****************************************************************************************************************************/
		-- Calculate the midnight point that represents the end of the week and the start of next week
		/*****************************************************************************************************************************/
		
		-- Return the end of the week and the start of next week
		SET @fnNextWeekStartDatetime = DATEADD(DAY, DATEDIFF(DAY, 0, @CurrentDate) + dbo.fnDaysToEndOfWeek(@CurrentDate, @CalcWaitTimesAsNightBefore) - @CalcWaitTimesAsNightBefore + 1, 0)

		-- Catch all for records that don't meet the criteria
		RETURN	@fnNextWeekStartDatetime

END

GO
