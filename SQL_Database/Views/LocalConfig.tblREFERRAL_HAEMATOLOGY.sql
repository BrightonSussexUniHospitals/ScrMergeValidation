SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [LocalConfig].[tblREFERRAL_HAEMATOLOGY] AS

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
			,CARE_ID
			,N_H110_ANN
			,N_H111_NODAL
			,N_H112_BONE
			,N_H112_BM
			,N_H112_UGI
			,N_H112_CNS
			,N_H112_GU
			,N_H112_LIVER
			,N_H112_LGI
			,N_H112_ORBIT
			,N_H112_SKIN
			,N_H112_STOMACH
			,N_H112_TESTIS
			,N_H112_THYMUS
			,N_H112_THYROID
			,N_H112_OTHER
			,N_H114_AGE
			,N_H114_LDH
			,N_H114_WHO
			,N_H114_STAGE
			,N_H114_SITE
			,N_H115_SCORE
			,N_H116_ALBUMIN
			,N_H116_HB
			,N_H116_MALE
			,N_H116_AGE
			,N_H116_STAGE
			,N_H116_WBC
			,N_H116_LYMPHOCYTE
			,N_H117_SCORE
			,N_H120_SOKAL
			,N_H121_HB
			,N_H121_WBC_L
			,N_H121_WBC_H
			,N_H122_SCORE
			,N_H124_HB
			,N_H124_SYMPTOMS
			,N_H124_BLASTS
			,N_H125_SCORE
			,L_RAI_STAGE
			,ANN_ARBOR_BULK_ID
			,MURPHY_CODE
			,ANN_ARBOR_EXTRANODALITY_ID
			,BINET_ID
			,DURIE_SALMON = DURIE_SALMON COLLATE DATABASE_DEFAULT
			,HASFORD_ID
			,ALK_1_ID
			,SOKAL_INDEX
			,EXTRANODAL_SITE_ID
			,WHITE_BLOOD_CELL_COUNT
			,CYTOGENETIC_RISK_SUBSIDIARY_COMMENT = CYTOGENETIC_RISK_SUBSIDIARY_COMMENT COLLATE DATABASE_DEFAULT
			,BM_KARYOTYPE_ID
			,LDH_LEVEL_ID
			,IPSS
			,HEPATOMEGALY_IND = HEPATOMEGALY_IND COLLATE DATABASE_DEFAULT
			,SPLENOMEGALY_IND = SPLENOMEGALY_IND COLLATE DATABASE_DEFAULT
			,FLIPI_INDEX
			,RIPI_INDEX
			,NO_OF_ABNORMAL_NODAL_AREAS
			,ANN_ARBOR_SPLENIC_INV
			,EXTRAMED_DIS_TESTES
			,EXTRAMED_DIS_CNS
			,EXTRAMED_DIS_OTHER
			,EXTRAMED_DIS_CNS_1
			,EXTRAMED_DIS_CNS_2
			,EXTRAMED_DIS_CNS_3
			,NICEFever
			,NICENightSweats
			,NICESoB
			,NICEPruritus
			,NICEWeightLoss
			,NICEAlcohol
			,AMLRiskFactorsID
			,ALLRiskGroupAllocationID
			,FABClassificationID
			,PaedRiskGroupID
			,EGILScoreID
			,MixedPhenoSplenomegaly
			,MixedPhenoLymphadenopathy
			,MixedPhenoMediastinalMass
			,MixedPhenoHepatomegaly
			,UnderlyingIBFMS
			,UnderlyingPreviousMalignancy
			,UnderlyingRadiation
			,UnderlyingToxicInsult
			,UnderlyingMitochondrialDisorder
			,UnderlyingOtherSystematicDisorder
			,UnderlyingCongenitalAnomalies
			,UnderlyingNoDisease
			,MyelodysplasiaConsanguinity
			,MyelodysplasiaOrganomegaly
			,MyelodysplasiaLymphadenopathy
			,MyelodysplasiaSevereInfections
			,MyelodysplasiaImmunodeficiency
			,CongenitalAnomalies = CongenitalAnomalies COLLATE DATABASE_DEFAULT
			,PaedMyelodysplasiaDeNovoMDS
			,PaedMyelodysplasiaCytopenia
			,PaedMyelodysplasiaCytopeniaSideroblasts
			,PaedMyelodysplasiaCytopeniaBlasts
			,PaedMyelodysplasiaRAEBInTransformation
			,Cellularity
			,DEBTestID
			,DysplasticHaemopoiesisID
			,BoneMarrowBlasts
			,PeripheralBloodBlasts
			,PostInductionMRD
			,ELNGeneticRisk
			,RISSStage
			,StageLymphomaReportDate
			,StageLymphomaOrgID
			,StageLeukaemiaReportDate
			,StageLeukaemiaOrgID
			,LabResponseReportDate
			,LabResponseOrgID
			,LabLeukaemiaReportDate
			,LabLeukaemiaOrgID
			,LabMyelodysplasiaReportDate
			,LabMyelodysplasiaOrgID
			,RISSDate
			,RISSOrg
	FROM  [CancerRegister_WSHT]..tblREFERRAL_HAEMATOLOGY

		UNION ALL 

	-- Select a replica dataset from a V22.2 table
	SELECT  CAST(2 AS tinyint) AS SrcSysID
			,CARE_ID
			,N_H110_ANN
			,N_H111_NODAL
			,N_H112_BONE
			,N_H112_BM
			,N_H112_UGI
			,N_H112_CNS
			,N_H112_GU
			,N_H112_LIVER
			,N_H112_LGI
			,N_H112_ORBIT
			,N_H112_SKIN
			,N_H112_STOMACH
			,N_H112_TESTIS
			,N_H112_THYMUS
			,N_H112_THYROID
			,N_H112_OTHER
			,N_H114_AGE
			,N_H114_LDH
			,N_H114_WHO
			,N_H114_STAGE
			,N_H114_SITE
			,N_H115_SCORE
			,N_H116_ALBUMIN
			,N_H116_HB
			,N_H116_MALE
			,N_H116_AGE
			,N_H116_STAGE
			,N_H116_WBC
			,N_H116_LYMPHOCYTE
			,N_H117_SCORE
			,N_H120_SOKAL
			,N_H121_HB
			,N_H121_WBC_L
			,N_H121_WBC_H
			,N_H122_SCORE
			,N_H124_HB
			,N_H124_SYMPTOMS
			,N_H124_BLASTS
			,N_H125_SCORE
			,L_RAI_STAGE
			,ANN_ARBOR_BULK_ID
			,MURPHY_CODE
			,ANN_ARBOR_EXTRANODALITY_ID
			,BINET_ID
			,DURIE_SALMON = DURIE_SALMON COLLATE DATABASE_DEFAULT
			,HASFORD_ID
			,ALK_1_ID
			,SOKAL_INDEX
			,EXTRANODAL_SITE_ID
			,WHITE_BLOOD_CELL_COUNT
			,CYTOGENETIC_RISK_SUBSIDIARY_COMMENT = CYTOGENETIC_RISK_SUBSIDIARY_COMMENT COLLATE DATABASE_DEFAULT
			,BM_KARYOTYPE_ID
			,LDH_LEVEL_ID
			,IPSS
			,HEPATOMEGALY_IND = HEPATOMEGALY_IND COLLATE DATABASE_DEFAULT
			,SPLENOMEGALY_IND = SPLENOMEGALY_IND COLLATE DATABASE_DEFAULT
			,FLIPI_INDEX
			,RIPI_INDEX
			,NO_OF_ABNORMAL_NODAL_AREAS
			,ANN_ARBOR_SPLENIC_INV
			,EXTRAMED_DIS_TESTES
			,EXTRAMED_DIS_CNS
			,EXTRAMED_DIS_OTHER
			,EXTRAMED_DIS_CNS_1
			,EXTRAMED_DIS_CNS_2
			,EXTRAMED_DIS_CNS_3
			,NICEFever
			,NICENightSweats
			,NICESoB
			,NICEPruritus
			,NICEWeightLoss
			,NICEAlcohol
			,AMLRiskFactorsID
			,ALLRiskGroupAllocationID
			,FABClassificationID
			,PaedRiskGroupID
			,EGILScoreID
			,MixedPhenoSplenomegaly
			,MixedPhenoLymphadenopathy
			,MixedPhenoMediastinalMass
			,MixedPhenoHepatomegaly
			,UnderlyingIBFMS
			,UnderlyingPreviousMalignancy
			,UnderlyingRadiation
			,UnderlyingToxicInsult
			,UnderlyingMitochondrialDisorder
			,UnderlyingOtherSystematicDisorder
			,UnderlyingCongenitalAnomalies
			,UnderlyingNoDisease
			,MyelodysplasiaConsanguinity
			,MyelodysplasiaOrganomegaly
			,MyelodysplasiaLymphadenopathy
			,MyelodysplasiaSevereInfections
			,MyelodysplasiaImmunodeficiency
			,CongenitalAnomalies = CongenitalAnomalies COLLATE DATABASE_DEFAULT
			,PaedMyelodysplasiaDeNovoMDS
			,PaedMyelodysplasiaCytopenia
			,PaedMyelodysplasiaCytopeniaSideroblasts
			,PaedMyelodysplasiaCytopeniaBlasts
			,PaedMyelodysplasiaRAEBInTransformation
			,Cellularity
			,DEBTestID
			,DysplasticHaemopoiesisID
			,BoneMarrowBlasts
			,PeripheralBloodBlasts
			,PostInductionMRD
			,ELNGeneticRisk
			,RISSStage
			,StageLymphomaReportDate
			,StageLymphomaOrgID
			,StageLeukaemiaReportDate
			,StageLeukaemiaOrgID
			,LabResponseReportDate
			,LabResponseOrgID
			,LabLeukaemiaReportDate
			,LabLeukaemiaOrgID
			,LabMyelodysplasiaReportDate
			,LabMyelodysplasiaOrgID
			,RISSDate
			,RISSOrg
	FROM  [CancerRegister_BSUH]..tblREFERRAL_HAEMATOLOGY
GO
