SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [LocalConfig].[tblDEFINITIVE_TREATMENT] AS

/******************************************************** © Copyright & Licensing ****************************************************************
© 2019 Perspicacity Ltd & Brighton & Sussex University Hospitals

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

Original Work Created Date:	30/07/2020
Original Work Created By:	Perspicacity Ltd (Matthew Bishop) & BSUH (Lawrence Simpson)
Original Work Contact:		07545 878906
Original Work Contact:		matthew.bishop@perspicacityltd.co.uk / lawrencesimpson@nhs.net
Description:				Create a local config view to point at the place where the SCR
							replicated data is located so that the core procedures don't
							need to be changed when they are copied to different environments 
							(e.g. live vs test or from one trust to another)
**************************************************************************************************************************************************/

	-- Select a replica dataset from a V22.2 table
	SELECT  CAST(1 AS tinyint) AS SrcSysID
			,TREATMENT_ID
			,CARE_ID
			,PATHWAY_ID = PATHWAY_ID COLLATE DATABASE_DEFAULT
			,DECISION_DATE
			,ORG_CODE_DTT = ORG_CODE_DTT COLLATE DATABASE_DEFAULT
			,START_DATE
			,TREATMENT = TREATMENT COLLATE DATABASE_DEFAULT
			,ORG_CODE = ORG_CODE COLLATE DATABASE_DEFAULT
			,TREATMENT_EVENT = TREATMENT_EVENT COLLATE DATABASE_DEFAULT
			,TREATMENT_SETTING = TREATMENT_SETTING COLLATE DATABASE_DEFAULT
			,RT_PRIORITY = RT_PRIORITY COLLATE DATABASE_DEFAULT
			,RT_INTENT = RT_INTENT COLLATE DATABASE_DEFAULT
			,SPECIALIST = SPECIALIST COLLATE DATABASE_DEFAULT
			,TRIAL
			,ADJ_DAYS
			,ADJ_CODE
			,DELAY_CODE
			,TREAT_NO
			,TREAT_ID
			,CHEMO_RT = CHEMO_RT COLLATE DATABASE_DEFAULT
			,VALIDATED
			,DELAY_COMMENTS = DELAY_COMMENTS COLLATE DATABASE_DEFAULT
			,DEPRECATED_21_01_COMMENTS = DEPRECATED_21_01_COMMENTS COLLATE DATABASE_DEFAULT
			,DEPRECATED_21_01_ALL_COMMENTS = DEPRECATED_21_01_ALL_COMMENTS COLLATE DATABASE_DEFAULT
			,ROOT_TCI_COMMENTS = ROOT_TCI_COMMENTS COLLATE DATABASE_DEFAULT
			,ROOT_DTT_DATE_COMMENTS = ROOT_DTT_DATE_COMMENTS COLLATE DATABASE_DEFAULT
			,TREATMENT_ADJ_DATE
	FROM  [CancerRegister_WSHT]..tblDEFINITIVE_TREATMENT

		UNION ALL 

	-- Select a replica dataset from a V22.2 table
	SELECT  CAST(2 AS tinyint) AS SrcSysID
			,TREATMENT_ID
			,CARE_ID
			,PATHWAY_ID = PATHWAY_ID COLLATE DATABASE_DEFAULT
			,DECISION_DATE
			,ORG_CODE_DTT = ORG_CODE_DTT COLLATE DATABASE_DEFAULT
			,START_DATE
			,TREATMENT = TREATMENT COLLATE DATABASE_DEFAULT
			,ORG_CODE = ORG_CODE COLLATE DATABASE_DEFAULT
			,TREATMENT_EVENT = TREATMENT_EVENT COLLATE DATABASE_DEFAULT
			,TREATMENT_SETTING = TREATMENT_SETTING COLLATE DATABASE_DEFAULT
			,RT_PRIORITY = RT_PRIORITY COLLATE DATABASE_DEFAULT
			,RT_INTENT = RT_INTENT COLLATE DATABASE_DEFAULT
			,SPECIALIST = SPECIALIST COLLATE DATABASE_DEFAULT
			,TRIAL
			,ADJ_DAYS
			,ADJ_CODE
			,DELAY_CODE
			,TREAT_NO
			,TREAT_ID
			,CHEMO_RT = CHEMO_RT COLLATE DATABASE_DEFAULT
			,VALIDATED
			,DELAY_COMMENTS = DELAY_COMMENTS COLLATE DATABASE_DEFAULT
			,DEPRECATED_21_01_COMMENTS = DEPRECATED_21_01_COMMENTS COLLATE DATABASE_DEFAULT
			,DEPRECATED_21_01_ALL_COMMENTS = DEPRECATED_21_01_ALL_COMMENTS COLLATE DATABASE_DEFAULT
			,ROOT_TCI_COMMENTS = ROOT_TCI_COMMENTS COLLATE DATABASE_DEFAULT
			,ROOT_DTT_DATE_COMMENTS = ROOT_DTT_DATE_COMMENTS COLLATE DATABASE_DEFAULT
			,TREATMENT_ADJ_DATE
	FROM  [CancerRegister_BSUH]..tblDEFINITIVE_TREATMENT
GO