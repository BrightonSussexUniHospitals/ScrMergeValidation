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
Description:				If a string is empty, return null
**************************************************************************************************************************************************/

-- test me
-- SELECT dbo.fnEmptyStringAsNull('')
-- SELECT dbo.fnEmptyStringAsNull(NULL)
-- SELECT dbo.fnEmptyStringAsNull('test')

CREATE FUNCTION [dbo].[fnEmptyStringAsNull]

				(@String VARCHAR(4000)
				)

RETURNS VARCHAR(4000)
AS
BEGIN

		-- Declare an internal variable to represent the string
		DECLARE @fnEmptyStringAsNull VARCHAR(4000)
		
		-- Set the internal variable if it is not empty
		IF @String != ''
		SET @fnEmptyStringAsNull = @String

		-- Return the string
		RETURN	@fnEmptyStringAsNull

END

GO
