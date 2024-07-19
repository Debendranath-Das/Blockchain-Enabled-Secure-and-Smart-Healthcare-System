pragma solidity >0.6.0 <=0.7.0;
pragma experimental ABIEncoderV2;
import "./SC_Registration.sol";
import "./SC_P_HA_1.sol";

contract SC_P_HA_2
{


		// Invoking party : hospital
		// Previously invoked function : generateEstimatedCostBill
		// When : After hospital generates the estimated bill and sends the estimated bill id to patient offline. And then patient fails to respond by invoking 'lockEstimatedAmount' fn within timeout.
		// Major changes = estimatedCheckUpCost_Object.timestampOfUnlockingByHospital=now

		function hospital_leave_generateEstimatedCostBill(address System_Users_Info_address,address P_HA_1_address,uint _pID,uint _estimatedBillID) public
		{
				uint _hID;
				System_Users_Info System_Users_Info_instance = System_Users_Info(System_Users_Info_address);
				SC_P_HA_1 P_HA_1_instance=SC_P_HA_1(P_HA_1_address);
				(,_hID,)=System_Users_Info_instance.getHospitalbyAddress(msg.sender);

				SC_P_HA_1.EstimatedCheckUpCost memory estimatedCheckUpCost_Object=P_HA_1_instance.getEstimatedCheckUpCostStruct(_estimatedBillID);

				require(estimatedCheckUpCost_Object.estimatedCostBillID==_estimatedBillID);
				require(estimatedCheckUpCost_Object.hID==_hID);
				require(estimatedCheckUpCost_Object.pID==_pID);
				require(estimatedCheckUpCost_Object.timestampOfLockingByPatient==0);
				require(now-estimatedCheckUpCost_Object.timestampOfLockingByHospital>P_HA_1_instance.timeLimitForPatientLocking());
				require(estimatedCheckUpCost_Object.timestampOfUnlockingByPatient==0);
				require(estimatedCheckUpCost_Object.timestampOfUnlockingByHospital==0);
				estimatedCheckUpCost_Object.timestampOfUnlockingByHospital=now;
				P_HA_1_instance.transferEtherFromThisContract(msg.sender,estimatedCheckUpCost_Object.estimatedCost);
				P_HA_1_instance.setEstimatedCheckUpCostStruct(estimatedCheckUpCost_Object,_estimatedBillID);


		}


		// Invoking party : Patient
		// Previously invoked function : lockEstimatedAmount
		// When : After patient locks the money for estimated bill and the hospital fails to invoke 'startTreatment' fn within timeout.
		// Major changes = estimatedCheckUpCost_Object.timestampOfUnlockingByPatient=now

		function patient_leave_lockEstimatedAmount(address System_Users_Info_address,address payable P_HA_1_address,uint _hID,uint _estimatedBillID) public
		{
				uint _pID;
				System_Users_Info System_Users_Info_instance = System_Users_Info(System_Users_Info_address);
				SC_P_HA_1 P_HA_1_instance=SC_P_HA_1(P_HA_1_address);
				(,_pID , , , , )=System_Users_Info_instance.getPatientbyAddress(msg.sender);

				SC_P_HA_1.EstimatedCheckUpCost memory estimatedCheckUpCost_Object=P_HA_1_instance.getEstimatedCheckUpCostStruct(_estimatedBillID);

				require(estimatedCheckUpCost_Object.estimatedCostBillID==_estimatedBillID);
				require(estimatedCheckUpCost_Object.hID==_hID);
				require(estimatedCheckUpCost_Object.pID==_pID);
				require(estimatedCheckUpCost_Object.timestampOfCheckUpStart==0);
				require(estimatedCheckUpCost_Object.timestampOfUnlockingByPatient==0);
				require(estimatedCheckUpCost_Object.timestampOfUnlockingByHospital==0);
				require(now-estimatedCheckUpCost_Object.timestampOfLockingByPatient>P_HA_1_instance.timeLimitForStartingOperation());
				estimatedCheckUpCost_Object.timestampOfUnlockingByPatient=now;
				P_HA_1_instance.transferEtherFromThisContract(msg.sender,estimatedCheckUpCost_Object.estimatedCost);
				P_HA_1_instance.setEstimatedCheckUpCostStruct(estimatedCheckUpCost_Object,_estimatedBillID);
		}


		// Invoking Party : Hospital
		// Previously invoked function : keepSignedHashToBlockchain
		// When : After hospital keeps the hash details in blockchain and patient fails to invoke the 'verifyAndGiveConsent' fn within the timeout.
		// Major changes :  multiSigOnMedicalData_Object.timeStampOfUnlockingByHospital_multi=now

		function hospital_leave_keepHashToBlockchain(address System_Users_Info_address,address payable P_HA_1_address,uint _pID,uint _estimatedBillID) public
		{
				uint _hID;
				uint _multiSigID;
				System_Users_Info System_Users_Info_instance = System_Users_Info(System_Users_Info_address);
				SC_P_HA_1 P_HA_1_instance=SC_P_HA_1(P_HA_1_address);
				(,_hID,)=System_Users_Info_instance.getHospitalbyAddress(msg.sender);

				SC_P_HA_1.EstimatedCheckUpCost memory estimatedCheckUpCost_Object=P_HA_1_instance.getEstimatedCheckUpCostStruct(_estimatedBillID);
				_multiSigID=P_HA_1_instance.estimatedCostBillIDToMultiSigOnMedicalDataID(_estimatedBillID);

				SC_P_HA_1.MultiSigOnMedicalData memory multiSigOnMedicalData_Object=P_HA_1_instance.getMultiSigOnMedicalDataStruct(_multiSigID);


				require(multiSigOnMedicalData_Object.hospitalID==_hID);
				require(multiSigOnMedicalData_Object.patientID==_pID);
				require(multiSigOnMedicalData_Object.timeStampOfSignByHospital!=0 && multiSigOnMedicalData_Object.timeStampOfSignByHospital<now);
				require(multiSigOnMedicalData_Object.timeStampOfUnlockingByHospital_multi==0);
				require(multiSigOnMedicalData_Object.timeStampOfVerificationByPatient==0);
				require(now - multiSigOnMedicalData_Object.timeStampOfSignByHospital>P_HA_1_instance.timeLimitForVerifyingSignature());
				multiSigOnMedicalData_Object.timeStampOfUnlockingByHospital_multi=now;
				P_HA_1_instance.transferEtherFromThisContract(msg.sender,estimatedCheckUpCost_Object.estimatedCost);
				P_HA_1_instance.setMultiSigOnMedicalData(multiSigOnMedicalData_Object,_multiSigID);

		}


		// Invoking Party : Patient
		// Previously invoked function : keepSignedHashToBlockchain (by hospital)
		// When : After hospital keeps the hash details in blockchain and the hashes of the enc file got offline doesnt match with the ones kept in the blockchain.
		// Major changes :  multiSigOnMedicalData_Object.timeStampOfUnlockingByPatient_multi=now


		function patient_leave_keepHashToBlockchain(address System_Users_Info_address,address payable P_HA_1_address,uint _hID,uint _estimatedBillID) public
		{
				uint _pID;
				uint _multiSigID;

				System_Users_Info System_Users_Info_instance = System_Users_Info(System_Users_Info_address);
				SC_P_HA_1 P_HA_1_instance=SC_P_HA_1(P_HA_1_address);
				(,_pID , , , , )=System_Users_Info_instance.getPatientbyAddress(msg.sender);


				SC_P_HA_1.EstimatedCheckUpCost memory estimatedCheckUpCost_Object=P_HA_1_instance.getEstimatedCheckUpCostStruct(_estimatedBillID);
				_multiSigID=P_HA_1_instance.estimatedCostBillIDToMultiSigOnMedicalDataID(_estimatedBillID);

				SC_P_HA_1.MultiSigOnMedicalData memory multiSigOnMedicalData_Object=P_HA_1_instance.getMultiSigOnMedicalDataStruct(_multiSigID);


				require(multiSigOnMedicalData_Object.hospitalID==_hID);
				require(multiSigOnMedicalData_Object.patientID==_pID);
				require(multiSigOnMedicalData_Object.timeStampOfSignByHospital!=0 && multiSigOnMedicalData_Object.timeStampOfSignByHospital<now);
				require(multiSigOnMedicalData_Object.timeStampOfUnlockingByPatient_multi==0);
				require(multiSigOnMedicalData_Object.timeStampOfVerificationByPatient==0);
				require(now - multiSigOnMedicalData_Object.timeStampOfSignByHospital<P_HA_1_instance.timeLimitForVerifyingSignature());
				multiSigOnMedicalData_Object.timeStampOfUnlockingByPatient_multi=now;
				P_HA_1_instance.transferEtherFromThisContract(msg.sender,estimatedCheckUpCost_Object.estimatedCost);
				P_HA_1_instance.setMultiSigOnMedicalData(multiSigOnMedicalData_Object,_multiSigID);

		}


		// Invoking Party : Patient
		// Previously invoked function : verifyAndGiveConsent
		// When : After patient verifies the hashes and then hospital fails to invoke 'DischargeAndGenerateFinalCostBill' fn within timeout.
		// Major changes :  multiSigOnMedicalData_Object.timeStampOfUnlockingByPatient_multi=now


		function patient_leave_verifyAndGiveConsent(address System_Users_Info_address,address payable P_HA_1_address,uint _hID,uint _estimatedBillID) public
		{
				uint _pID;
				uint _multiSigID;
				uint _finalBillID;
				System_Users_Info System_Users_Info_instance = System_Users_Info(System_Users_Info_address);
				SC_P_HA_1 P_HA_1_instance=SC_P_HA_1(P_HA_1_address);
				(,_pID , , , , )=System_Users_Info_instance.getPatientbyAddress(msg.sender);


				_multiSigID=P_HA_1_instance.estimatedCostBillIDToMultiSigOnMedicalDataID(_estimatedBillID);
				_finalBillID=P_HA_1_instance.estimatedBillIDToFinalBillID(_estimatedBillID);

				SC_P_HA_1.MultiSigOnMedicalData memory multiSigOnMedicalData_Object=P_HA_1_instance.getMultiSigOnMedicalDataStruct(_multiSigID);
				SC_P_HA_1.EstimatedCheckUpCost memory estimatedCheckUpCost_Object=P_HA_1_instance.getEstimatedCheckUpCostStruct(_estimatedBillID);


				require(multiSigOnMedicalData_Object.hospitalID==_hID);
				require(multiSigOnMedicalData_Object.patientID==_pID);
				require(multiSigOnMedicalData_Object.timeStampOfVerificationByPatient!=0 && multiSigOnMedicalData_Object.timeStampOfVerificationByPatient<now);
				require(multiSigOnMedicalData_Object.timeStampOfUnlockingByPatient_multi==0);
				require(_finalBillID==0);



				require(now - multiSigOnMedicalData_Object.timeStampOfVerificationByPatient>P_HA_1_instance.timeLimitForGeneratingFillBill());
				multiSigOnMedicalData_Object.timeStampOfUnlockingByPatient_multi=now;
				P_HA_1_instance.transferEtherFromThisContract(msg.sender,estimatedCheckUpCost_Object.estimatedCost);
				P_HA_1_instance.setMultiSigOnMedicalData(multiSigOnMedicalData_Object,_multiSigID);
		}


		// Invoking Party : Hospital
		// Previously invoked function : DischargeAndGenerateFinalCostBill
		// When : After hospital generates the final bill and then patient fails to invoke 'consentFinalBill_Patient' or 'raiseDispute' fn within timeout.
		// Major changes :  finalCheckUpCost_Object.timeStampOfUnlockingByHospital_final=now


		function hospital_leave_DischargeAndGenerateFinalCostBill(address System_Users_Info_address,address payable  P_HA_1_address,uint _estimatedBillID,uint _pID) public
		{
			 uint _hID;
			 uint _finalBillID;
			 System_Users_Info System_Users_Info_instance = System_Users_Info(System_Users_Info_address);
			 SC_P_HA_1 P_HA_1_instance=SC_P_HA_1(P_HA_1_address);
			 (,_hID,)=System_Users_Info_instance.getHospitalbyAddress(msg.sender);

			 _finalBillID=P_HA_1_instance.estimatedBillIDToFinalBillID(_estimatedBillID);

			 SC_P_HA_1.FinalCheckUpCost memory finalCheckUpCost_Object=P_HA_1_instance.getFinalBillStruct(_finalBillID);


			 require(finalCheckUpCost_Object.hID==_hID);
			 require(finalCheckUpCost_Object.pID==_pID);
			 require(finalCheckUpCost_Object.timeStampOfUnlockingByHospital_final==0);
			 require(finalCheckUpCost_Object.timestampOfFinalBilling!=0 && finalCheckUpCost_Object.timestampOfFinalBilling<now);
			 require(finalCheckUpCost_Object.timeStampOfPatientFinalBillConsent==0);
			 require(now-finalCheckUpCost_Object.timestampOfFinalBilling>P_HA_1_instance.timeLimitForSigningFinalBill());
			 finalCheckUpCost_Object.timeStampOfUnlockingByHospital_final=now;
			 P_HA_1_instance.transferEtherFromThisContract(msg.sender,finalCheckUpCost_Object.finalCost);
			 P_HA_1_instance.setFinalCheckUpCost(finalCheckUpCost_Object,_finalBillID);

		}

		// Invoking Party : Patient
		// Previously invoked function : consentFinalBill_Patient
		// When : After patient gives the consent for final bill  and then hospital fails to invoke 'keyReveal' fn within timeout.
		// Major changes :  finalCheckUpCost_Object.timestampOfUnlockingByPatient_final=now


		function patient_leave_consentFinalBill(address System_Users_Info_address,address payable P_HA_1_address,uint _estimatedBillID,uint _hID) public
		{
				uint _pID;
				uint _finalBillID;
				uint _multiSigID;
				System_Users_Info System_Users_Info_instance = System_Users_Info(System_Users_Info_address);
				SC_P_HA_1 P_HA_1_instance=SC_P_HA_1(P_HA_1_address);
				(,_pID , , , , )=System_Users_Info_instance.getPatientbyAddress(msg.sender);

				_finalBillID=P_HA_1_instance.estimatedBillIDToFinalBillID(_estimatedBillID);
				_multiSigID=P_HA_1_instance.estimatedCostBillIDToMultiSigOnMedicalDataID(_estimatedBillID);

				SC_P_HA_1.FinalCheckUpCost memory finalCheckUpCost_Object=P_HA_1_instance.getFinalBillStruct(_finalBillID);
				SC_P_HA_1.KeyAndExchange memory keyAndExchange_Object=P_HA_1_instance.getKeyAndExchangeStruct(_multiSigID);


				require(finalCheckUpCost_Object.hID==_hID);
				require(finalCheckUpCost_Object.pID==_pID);
				require(finalCheckUpCost_Object.timeStampOfPatientFinalBillConsent!=0 && finalCheckUpCost_Object.timeStampOfPatientFinalBillConsent<now);
				require(finalCheckUpCost_Object.timestampOfUnlockingByPatient_final==0);
				require(keyAndExchange_Object.timeStampOfKeyReveal==0);
				require(now-finalCheckUpCost_Object.timeStampOfPatientFinalBillConsent>P_HA_1_instance.timeLimitForRaisingDispute());
				finalCheckUpCost_Object.timestampOfUnlockingByPatient_final=now;
				P_HA_1_instance.transferEtherFromThisContract(msg.sender,finalCheckUpCost_Object.finalCost);
 			 	P_HA_1_instance.setFinalCheckUpCost(finalCheckUpCost_Object,_finalBillID);

		}


		// Invoking Party : Hospital
		// Previously invoked function : keyReveal
		// When : After hospital reveals the key and then patient fails to invoke 'patient_final_consent' or 'patient_Complain' fn within timeout.
		// Major changes :  finalCheckUpCost_Object.timeStampOfFinalConsent=now



		function hospital_leave_keyReveal(address System_Users_Info_address,address payable P_HA_1_address,uint _estimatedBillID,uint _pId) public
		{
				uint _hID;
				uint _finalBillID;
				uint _multiSigID;
				System_Users_Info System_Users_Info_instance = System_Users_Info(System_Users_Info_address);
				SC_P_HA_1 P_HA_1_instance=SC_P_HA_1(P_HA_1_address);
				(,_hID,)=System_Users_Info_instance.getHospitalbyAddress(msg.sender);

				_finalBillID=P_HA_1_instance.estimatedBillIDToFinalBillID(_estimatedBillID);
				_multiSigID=P_HA_1_instance.estimatedCostBillIDToMultiSigOnMedicalDataID(_estimatedBillID);

				SC_P_HA_1.FinalCheckUpCost memory finalCheckUpCost_Object=P_HA_1_instance.getFinalBillStruct(_finalBillID);
				SC_P_HA_1.KeyAndExchange memory keyAndExchange_Object=P_HA_1_instance.getKeyAndExchangeStruct(_multiSigID);


				require(finalCheckUpCost_Object.hID==_hID);
				require(finalCheckUpCost_Object.pID==	_pId);
				require(finalCheckUpCost_Object.timeStampOfUnlockingByHospital_final==0);
				require(keyAndExchange_Object.timeStampOfKeyReveal!=0 && keyAndExchange_Object.timeStampOfKeyReveal<now);
				require(finalCheckUpCost_Object.timeStampOfFinalConsent==0);
				require(finalCheckUpCost_Object.timeStampOfComplain==0);
				require(now-keyAndExchange_Object.timeStampOfKeyReveal>P_HA_1_instance.timeLimitForAcceptingOrProducingComplain());
				finalCheckUpCost_Object.timeStampOfFinalConsent=now;
				P_HA_1_instance.transferEtherFromThisContract(msg.sender,2*finalCheckUpCost_Object.finalCost);
				P_HA_1_instance.setFinalCheckUpCost(finalCheckUpCost_Object,_finalBillID);

		}




		function solveDisputeAndModifiedFinalBill(address System_Users_Info_address,address payable P_HA_1_address,uint _disputeID,uint _estimatedBillID,uint _finalBillID,uint _pID,uint _modifiedCost) public
    {
        uint _hID;
				uint _excessID;
				System_Users_Info System_Users_Info_instance = System_Users_Info(System_Users_Info_address);
				SC_P_HA_1 P_HA_1_instance=SC_P_HA_1(P_HA_1_address);
				(,_hID,)=System_Users_Info_instance.getHospitalbyAddress(msg.sender);
        address payable _pAddr;
        (_pAddr, , , , , )=System_Users_Info_instance.getPatientbyID(_pID);


				SC_P_HA_1.Dispute memory disputeStruct=P_HA_1_instance.getDisputeStruct(_disputeID);
				SC_P_HA_1.FinalCheckUpCost memory finalCheckUpCost_Object=P_HA_1_instance.getFinalBillStruct(_finalBillID);
				SC_P_HA_1.Excess memory excessStruct;


        /* uint i=_disputeID-1; */


        require(disputeStruct.disputeID==_disputeID);
        require(disputeStruct.hID==_hID);
        require(disputeStruct.pID==_pID);
        require(now-disputeStruct.timestampOfRaisingDispute<=P_HA_1_instance.timeLimitForSolvingDispute());
        require(disputeStruct.finalBillID==_finalBillID);



        require(finalCheckUpCost_Object.finalCostBillID==_finalBillID);
        require(finalCheckUpCost_Object.pID==_pID);
        require(finalCheckUpCost_Object.hID==_hID);
        require(finalCheckUpCost_Object.timestampOfFinalBilling<disputeStruct.timestampOfRaisingDispute);




        require(_modifiedCost<=finalCheckUpCost_Object.finalCost);

        if(_modifiedCost<finalCheckUpCost_Object.finalCost) // final cost is changed..
        {
            SC_P_HA_1.EstimatedCheckUpCost memory estimatedCheckUpCost_Object=P_HA_1_instance.getEstimatedCheckUpCostStruct(_estimatedBillID);
            require(estimatedCheckUpCost_Object.estimatedCostBillID==_estimatedBillID);
            require(estimatedCheckUpCost_Object.pID==_pID);
            require(estimatedCheckUpCost_Object.hID==_hID);


						disputeStruct.finalCostChanged=true;


            if(finalCheckUpCost_Object.excessID!=0) //finalCheckUpcost != estimatedCheckUpcost
            {
								_excessID = finalCheckUpCost_Object.excessID;
								excessStruct = P_HA_1_instance.getExcessStruct(_excessID);


								require(excessStruct.excessID==finalCheckUpCost_Object.excessID);
								require(excessStruct.pID==_pID);
								require(excessStruct.hID==_hID);

								excessStruct.excessAmount=estimatedCheckUpCost_Object.estimatedCost - _modifiedCost;


								P_HA_1_instance.transferEtherFromThisContract(msg.sender,finalCheckUpCost_Object.finalCost - _modifiedCost);
								P_HA_1_instance.transferEtherFromThisContract(_pAddr,finalCheckUpCost_Object.finalCost - _modifiedCost);


								P_HA_1_instance.setExcessObject(excessStruct,_excessID);



						}
						else
						{
								excessStruct.pID=_pID;
								excessStruct.hID=_hID;
								excessStruct.excessAmount=estimatedCheckUpCost_Object.estimatedCost - _modifiedCost;

								P_HA_1_instance.incrementAndSetExcessObject(excessStruct,_finalBillID);


								P_HA_1_instance.transferEtherFromThisContract(msg.sender,finalCheckUpCost_Object.finalCost - _modifiedCost);
								P_HA_1_instance.transferEtherFromThisContract(_pAddr,finalCheckUpCost_Object.finalCost - _modifiedCost);


						}


  			}
        else //finalCost is not changed..same as before..
        {
            disputeStruct.finalCostChanged=false;

        }


        disputeStruct.timestampOfSolvingDispute=now;
				P_HA_1_instance.setDisputeStruct(disputeStruct,_disputeID);


				finalCheckUpCost_Object.finalCost=_modifiedCost;
				finalCheckUpCost_Object.timestampOfFinalBilling=now;
				P_HA_1_instance.setFinalCheckUpCost(finalCheckUpCost_Object,_finalBillID);



    }

		function consentFinalBill_AfterDisputeRaise_Patient(address System_Users_Info_address,address payable P_HA_1_address,uint _finalBillID,uint _hID) public payable
	 	{

  			 uint _pID;
  			 System_Users_Info System_Users_Info_instance = System_Users_Info(System_Users_Info_address);
				 SC_P_HA_1 P_HA_1_instance=SC_P_HA_1(P_HA_1_address);
  			 (,_pID , , , , )=System_Users_Info_instance.getPatientbyAddress(msg.sender);
  			 address payable _hAddr;
  			 (_hAddr, , )=System_Users_Info_instance.getHospitalbyID(_hID);

				 SC_P_HA_1.FinalCheckUpCost memory finalCheckUpCost_Object=P_HA_1_instance.getFinalBillStruct(_finalBillID);



  			 require(finalCheckUpCost_Object.finalCostBillID==_finalBillID);
  			 require(finalCheckUpCost_Object.pID==_pID);
  			 require(finalCheckUpCost_Object.hID==_hID);
  			 require(finalCheckUpCost_Object.timestampOfFinalBilling<now);
  			 require(finalCheckUpCost_Object.timeStampOfPatientFinalBillConsent==0);



  			 uint _disputeID=P_HA_1_instance.finalBillIDToDisputeID(_finalBillID);
  			 require(_disputeID!=0);

				 SC_P_HA_1.Dispute memory disputeStruct=P_HA_1_instance.getDisputeStruct(_disputeID);


  			 require(disputeStruct.timestampOfSolvingDispute>0);
  			 require(now-disputeStruct.timestampOfSolvingDispute<=P_HA_1_instance.timeLimitForSigningFinalBill());


	  	 		P_HA_1_instance.transferEtherFromThisContract(_hAddr,2*finalCheckUpCost_Object.finalCost);
	  			finalCheckUpCost_Object.timeStampOfPatientFinalBillConsent=now;

					P_HA_1_instance.setFinalCheckUpCost(finalCheckUpCost_Object,_finalBillID);

	 	}


}
