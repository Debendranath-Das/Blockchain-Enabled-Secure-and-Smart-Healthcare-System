pragma solidity >0.6.0 <=0.7.0;
pragma experimental ABIEncoderV2;
import "./SC_Registration.sol";
import "./SC_P_HA_2.sol";


contract SC_P_HA_1
{
		uint public Now;

    address public addr_SC_P_HA_2;

    struct MultiSigOnMedicalData
    {
        uint multiSigID;
        uint patientID; //ID of patient..
        uint hospitalID; //ID of hsopital..
        bytes32 hashOfData;  //hash value..
				bytes32 hashOfEncryptedData;
				bytes32 hashOfPatientIdDateHashEncFile;
        bytes signOnFileHashByHospital;
				bytes signOnHashOf_PatientId_DateOfReport_HashOfEncryptedFile;
        uint timeStampOfSignByHospital; //timeOutstamp when hospital signs..
        uint timeStampOfVerificationByPatient;  //timestamp when patient signs..
				bool verified;
				uint timeStampOfUnlockingByPatient_multi;
				uint timeStampOfUnlockingByHospital_multi;

    }

		struct KeyAndExchange
		{
			bytes32 key;
			bytes32 keyHash;
			uint timeStampOfKeyReveal;

		}

		struct FileProperties{
			uint noOfInputGates; //size of the file..
		 	uint fileChunkSize; //size of each file chunk..
		 	uint depth; //root at depth 0..(Merkle tree: hash computation of file
			uint maxLinesToGate;
		}

    struct EstimatedCheckUpCost
    {
        uint estimatedCostBillID;
        uint pID;
        uint hID;
        uint estimatedCost;
        uint timestampOfEstimate;
				uint timestampOfLockingByHospital;
        uint timestampOfLockingByPatient;
        uint timestampOfCheckUpStart;
        uint timestampOfUnlockingByPatient; //Patient can unlock money if hospital does not start check up with in 5 minutes of locking.
        uint timestampOfUnlockingByHospital; //Hospital can unlock money if patient does not lock the estimated amount within 5 minutes of estimated bill generation.

    }

    struct FinalCheckUpCost
    {
        uint finalCostBillID;
        uint pID;
        uint hID;
        uint finalCost;
        uint timestampOfFinalBilling;
	      uint excessID;
        uint timeStampOfPatientFinalBillConsent;
        uint timeStampOfFinalConsent;
        uint timeStampOfComplain;
				uint timeStampOfUnlockingByHospital_final;
				uint timestampOfUnlockingByPatient_final;
    }

    struct Excess
    {
        uint excessID;
        uint pID;
        uint hID;
        uint excessAmount;
        uint timestampOfRefundingExcessToPatient;
    }

    struct Dispute
    {
        uint disputeID;
        uint pID;
        uint hID;
        uint finalBillID;
        uint timestampOfRaisingDispute;
        uint timestampOfSolvingDispute;
        bool finalCostChanged;
    }



    MultiSigOnMedicalData[] public multiSigOnMedicalData;
    uint public multiSigIDGenerator=0;


    EstimatedCheckUpCost[] public estimatedCheckUpCost;
    uint public estimatedBillIDGenerator=0;


    FinalCheckUpCost[] public finalCheckUpCost;
    uint public finalBillIDGenerator=0;


    Excess[] public excess;
    uint public excessIDGenerator=0;


    Dispute[] public dispute;
    uint public disputeIDGenerator=0;


    mapping(uint=>uint) public estimatedBillIDToFinalBillID;
    mapping(uint=>uint) public estimatedCostBillIDToMultiSigOnMedicalDataID;
    mapping(uint=>FileProperties) public MultiSignIdToEncFileProperties;
		mapping(uint=>KeyAndExchange) public MultiSignIdToKeyAndExchange;
    mapping(uint=>uint) public finalBillIDToDisputeID;


		mapping(uint => mapping(uint => uint)) public patientId_hospitalId_estimateBillId;


    uint constant public timeLimitForPatientLocking = 100 seconds;
    uint constant public timeLimitForStartingOperation = 100 seconds;
		uint constant public timeLimitForVerifyingSignature=100 seconds;
		uint constant public timeLimitForGeneratingFillBill=100 seconds;
    uint constant public timeLimitForRaisingDispute=100 seconds;
    uint constant public timeLimitForSigningFinalBill=timeLimitForRaisingDispute;
    uint constant public timeLimitForSolvingDispute=100 seconds;
		uint constant public timeLimitForKeyRevealing=100 seconds;
		uint constant public timeLimitForAcceptingOrProducingComplain = 100 seconds;


		function increaseTheTimeBy10seconds() public {
			Now=now;
		}


    modifier only_SC_P_HA_2(address _party)
    {
        require(addr_SC_P_HA_2==_party);
        _;
    }



		function getMultiSigOnMedicalDataStruct(uint id) public view returns(MultiSigOnMedicalData memory)
		{
			return multiSigOnMedicalData[id-1];
		}

		function getEstimatedCheckUpCostStruct(uint id) public view returns(EstimatedCheckUpCost memory)
		{
			return estimatedCheckUpCost[id-1];
		}

		function getFinalBillStruct(uint id) public view returns(FinalCheckUpCost memory)
		{
			return finalCheckUpCost[id-1];
		}

		function getKeyAndExchangeStruct(uint id) public view returns(KeyAndExchange memory)
		{
			return(MultiSignIdToKeyAndExchange[id]);
		}

		function getEncFileProperties(uint id) public view returns(FileProperties memory)
		{
			return(MultiSignIdToEncFileProperties[id]);
		}

		function getDisputeStruct(uint id) public view returns(Dispute memory)
		{
			return(dispute[id-1]);
		}

		function getExcessStruct(uint id) public view returns(Excess memory)
		{
			return(excess[id-1]);
		}



    //set structure objects to storage
    function setEstimatedCheckUpCostStruct(EstimatedCheckUpCost memory estimatedCheckUpCost_Object, uint id) only_SC_P_HA_2(msg.sender) public
		{
       estimatedCheckUpCost[id-1]=estimatedCheckUpCost_Object;
		}

    function setMultiSigOnMedicalData(MultiSigOnMedicalData memory multiSigOnMedicalData_Object, uint id) only_SC_P_HA_2(msg.sender) public
		{
       multiSigOnMedicalData[id-1]=multiSigOnMedicalData_Object;
		}

    function setFinalCheckUpCost(FinalCheckUpCost memory finalCheckUpCost_Object,uint id) only_SC_P_HA_2(msg.sender) public
    {
        finalCheckUpCost[id-1]=finalCheckUpCost_Object;
    }

		function setDisputeStruct(Dispute memory dispute_object,uint id) only_SC_P_HA_2(msg.sender) public
		{
				dispute[id-1]=dispute_object;
		}

		function setExcessObject(Excess memory excess_object,uint id) only_SC_P_HA_2(msg.sender) public
		{
				excess[id-1]=excess_object;
		}


		function incrementAndSetExcessObject(Excess memory excess_object,uint _finalId) only_SC_P_HA_2(msg.sender) public
		{
				excessIDGenerator+=1;
        excess_object.excessID=excessIDGenerator;
        finalCheckUpCost[_finalId-1].excessID=excessIDGenerator;
        excess.push(excess_object);
		}





    function transferEtherFromThisContract(address payable _addr,uint _amount) only_SC_P_HA_2(msg.sender) public
    {
        _addr.transfer(_amount);
    }


    constructor(address _addr_SC_P_HA_2) public
    {
        addr_SC_P_HA_2 = _addr_SC_P_HA_2;
    }



    function generateEstimatedCostBill(address System_Users_Info_address,uint _pID, uint _estimatedCost) public payable
    {
        uint _hID;
				System_Users_Info System_Users_Info_instance = System_Users_Info(System_Users_Info_address);
        (,_hID,)=System_Users_Info_instance.getHospitalbyAddress(msg.sender);
        require(_pID>=1 && _pID<=System_Users_Info_instance.patientIDGenerator());
        require(msg.value>=_estimatedCost);
        estimatedBillIDGenerator++;
        EstimatedCheckUpCost memory temp;
        temp.estimatedCostBillID=estimatedBillIDGenerator;
        temp.pID=_pID;
        temp.hID=_hID;
        temp.estimatedCost=_estimatedCost;
        temp.timestampOfEstimate=now;
        temp.timestampOfLockingByPatient=0;
        temp.timestampOfLockingByHospital=now;
        temp.timestampOfCheckUpStart=0;
        temp.timestampOfUnlockingByPatient=0;
        temp.timestampOfUnlockingByHospital=0;
        estimatedCheckUpCost.push(temp);
				patientId_hospitalId_estimateBillId[_pID][_hID]=estimatedBillIDGenerator;
    }

		//(address System_Users_Info_address,uint _hID,

		function lockEstimatedAmount(address System_Users_Info_address,uint _hID,uint _estimatedBillID) public payable
    {
        uint _pID;
				System_Users_Info System_Users_Info_instance = System_Users_Info(System_Users_Info_address);
        (,_pID , , , , )=System_Users_Info_instance.getPatientbyAddress(msg.sender);
        uint i=_estimatedBillID-1;
			  require(estimatedCheckUpCost[i].estimatedCostBillID==_estimatedBillID);
        require(estimatedCheckUpCost[i].pID==_pID);
        require(estimatedCheckUpCost[i].hID==_hID);
        require(estimatedCheckUpCost[i].timestampOfLockingByHospital!=0);
        require((now - estimatedCheckUpCost[i].timestampOfLockingByHospital)<=timeLimitForPatientLocking);
        require(estimatedCheckUpCost[i].timestampOfUnlockingByHospital==0); // this is redundant..still Ok.
        require(estimatedCheckUpCost[i].estimatedCost<=msg.value);
        estimatedCheckUpCost[_estimatedBillID-1].timestampOfLockingByPatient=now;

    }



		function startTreatment(address System_Users_Info_address,uint _pID,uint _estimatedCostBillID) public
    {
        uint _hID;
				System_Users_Info System_Users_Info_instance = System_Users_Info(System_Users_Info_address);
        (,_hID,)=System_Users_Info_instance.getHospitalbyAddress(msg.sender);
        uint i=_estimatedCostBillID-1;
        require(estimatedCheckUpCost[i].estimatedCostBillID==_estimatedCostBillID);
        require(estimatedCheckUpCost[i].hID==_hID);
        require(estimatedCheckUpCost[i].pID==_pID);
        require(now>=estimatedCheckUpCost[i].timestampOfLockingByPatient);
        require((now-estimatedCheckUpCost[i].timestampOfLockingByPatient)<=timeLimitForStartingOperation);
        estimatedCheckUpCost[i].timestampOfCheckUpStart=now;

    }


		function keepSignedHashToBlockchain(address System_Users_Info_address,uint _pID,uint _estimatedCostBillID, bytes32 _hashOfData,bytes32 _hashOfEncryptedData,bytes32 _hashOfPatientIdDateHashEncFile,bytes memory _signOnFileHashByHospital,bytes memory _signOnHashOf_PatientId_DateOfReport_HashOfEncryptedFile,uint _noOfInputGates,uint _fileChunkSize,uint _maxInputLinesToAGate,bytes32 _keyHash) public
    {
        uint _hID;
				System_Users_Info System_Users_Info_instance = System_Users_Info(System_Users_Info_address);
        (,_hID,)=System_Users_Info_instance.getHospitalbyAddress(msg.sender);
        require(_pID>=1 && _pID<=System_Users_Info_instance.patientIDGenerator());
				require(_estimatedCostBillID!=0);
				require(estimatedCostBillIDToMultiSigOnMedicalDataID[_estimatedCostBillID]==0);
       	multiSigIDGenerator = multiSigIDGenerator +1;
       	storeMultiSignData(multiSigIDGenerator,_pID,_hID,_hashOfData,_hashOfEncryptedData,_hashOfPatientIdDateHashEncFile,_signOnFileHashByHospital,_signOnHashOf_PatientId_DateOfReport_HashOfEncryptedFile,now);
			 	storeFileProperties(multiSigIDGenerator,_noOfInputGates,_fileChunkSize,_maxInputLinesToAGate);
			 	storeKeyAndExchange(multiSigIDGenerator,_keyHash);
			 	estimatedCostBillIDToMultiSigOnMedicalDataID[_estimatedCostBillID]=multiSigIDGenerator;
    }


		function storeKeyAndExchange(uint _multiSigID,bytes32 _keyHash) internal
		{
				KeyAndExchange memory x;
				x.keyHash=_keyHash;
				MultiSignIdToKeyAndExchange[_multiSigID]=x;

		}


		function storeMultiSignData(uint multiSigID,uint _pID,uint _hID,bytes32 _hashOfData,bytes32 _hashOfEncryptedData,bytes32 _hashOfPatientIdDateHashEncFile,bytes memory _signOnFileHashByHospital,bytes memory _signOnHashOf_PatientId_DateOfReport_HashOfEncryptedFile,uint time) internal
		{
				MultiSigOnMedicalData memory ms = MultiSigOnMedicalData(multiSigID,_pID,_hID,_hashOfData,_hashOfEncryptedData,_hashOfPatientIdDateHashEncFile,_signOnFileHashByHospital,_signOnHashOf_PatientId_DateOfReport_HashOfEncryptedFile,now,0,false,0,0);
				multiSigOnMedicalData.push(ms);
		}


		function storeFileProperties(uint multiSigID,uint _noOfInputGates,uint _fileChunkSize,uint _maxInputLinesToAGate) internal
		{
				FileProperties memory x;
				x.noOfInputGates=_noOfInputGates;
				x.fileChunkSize=_fileChunkSize;
				x.depth=log2(2*_noOfInputGates)+1;
				x.maxLinesToGate=_maxInputLinesToAGate;
				MultiSignIdToEncFileProperties[multiSigID]=x;
		}


		function verifyAndGiveConsent(address System_Users_Info_address,uint _multiSigID,uint _hID,bytes32 _HashOf_PatientId_DateOfReport_HashOfEncryptedFile,bytes32 _hashOfEncryptedData) public
    {
        uint _pID;
				System_Users_Info System_Users_Info_instance = System_Users_Info(System_Users_Info_address);
				  (,_pID , , , , )=System_Users_Info_instance.getPatientbyAddress(msg.sender);
        address _hAddr;
        (_hAddr, , )=System_Users_Info_instance.getHospitalbyID(_hID);
        uint i=_multiSigID-1;
        require(multiSigOnMedicalData[i].multiSigID == _multiSigID);
        require(multiSigOnMedicalData[i].patientID == _pID);
        require(multiSigOnMedicalData[i].hospitalID == _hID);
        require(multiSigOnMedicalData[i].hashOfEncryptedData==_hashOfEncryptedData);
        require(verifySignature(_hAddr,_HashOf_PatientId_DateOfReport_HashOfEncryptedFile,multiSigOnMedicalData[i].signOnHashOf_PatientId_DateOfReport_HashOfEncryptedFile) == true );
				 require(verifySignature(_hAddr,multiSigOnMedicalData[i].hashOfData,multiSigOnMedicalData[i].signOnFileHashByHospital) == true );
        require(now>=multiSigOnMedicalData[i].timeStampOfSignByHospital);
				require(now-multiSigOnMedicalData[i].timeStampOfSignByHospital<=timeLimitForVerifyingSignature);
        multiSigOnMedicalData[i].timeStampOfVerificationByPatient=now;
				multiSigOnMedicalData[i].verified=true;
  }



	function DischargeAndGenerateFinalCostBill(address System_Users_Info_address,uint _estimatedBillID,uint _pID,uint _finalCost) public payable returns(uint)
    {
        uint _hID;
        uint _multiSigID;
				System_Users_Info System_Users_Info_instance = System_Users_Info(System_Users_Info_address);
        (,_hID,)=System_Users_Info_instance.getHospitalbyAddress(msg.sender);
        address payable _pAddr;
        (_pAddr, , , , , )=System_Users_Info_instance.getPatientbyID(_pID);
        uint i=_estimatedBillID-1;
        _multiSigID=estimatedCostBillIDToMultiSigOnMedicalDataID[_estimatedBillID];
        require(estimatedCheckUpCost[i].estimatedCostBillID==_estimatedBillID);
        require(estimatedCheckUpCost[i].pID==_pID);
        require(estimatedCheckUpCost[i].hID==_hID);
        require(estimatedCheckUpCost[i].timestampOfUnlockingByPatient==0 && estimatedCheckUpCost[i].timestampOfUnlockingByHospital==0);
        require(estimatedCheckUpCost[i].timestampOfCheckUpStart!=0);
        require(_finalCost<=estimatedCheckUpCost[i].estimatedCost);
        require(multiSigOnMedicalData[_multiSigID-1].multiSigID==_multiSigID);
        require(multiSigOnMedicalData[_multiSigID-1].patientID==_pID);
        require(multiSigOnMedicalData[_multiSigID-1].hospitalID==_hID);
        require(multiSigOnMedicalData[_multiSigID-1].timeStampOfVerificationByPatient!=0);
				require(now-multiSigOnMedicalData[_multiSigID-1].timeStampOfVerificationByPatient<=timeLimitForGeneratingFillBill);
				require(multiSigOnMedicalData[_multiSigID-1].verified==true);
        finalBillIDGenerator++;
        FinalCheckUpCost memory temp;
        temp.finalCostBillID=finalBillIDGenerator;
        temp.pID=_pID;
        temp.hID=_hID;
        temp.finalCost=_finalCost;
        temp.timestampOfFinalBilling=now;
        temp.excessID=0;
        //if final cost is not equal to the estimated cost.
				if(_finalCost<estimatedCheckUpCost[i].estimatedCost)
        {
            Excess memory excessObject;
            uint excessAmount;
            if(_finalCost<estimatedCheckUpCost[i].estimatedCost)
            {
                excessAmount = estimatedCheckUpCost[i].estimatedCost - _finalCost;
                excessIDGenerator++;
                excessObject.excessID=excessIDGenerator;
                excessObject.pID=_pID;
                excessObject.hID=_hID;
                excessObject.excessAmount=excessAmount;
                excessObject.timestampOfRefundingExcessToPatient=now;
                msg.sender.transfer(excessAmount);
                _pAddr.transfer(excessAmount);
                excess.push(excessObject);
                temp.excessID=excessIDGenerator;
            }

        }
        temp.timeStampOfPatientFinalBillConsent=0;
        finalCheckUpCost.push(temp);
        estimatedBillIDToFinalBillID[_estimatedBillID]=finalBillIDGenerator;
        return(finalBillIDGenerator);
    }



		 function consentFinalBill_Patient(address System_Users_Info_address,	uint _finalBillID,uint _hID) public payable
     {
        uint i=_finalBillID-1;
        uint _pID;
				System_Users_Info System_Users_Info_instance = System_Users_Info(System_Users_Info_address);
        (,_pID , , , , )=System_Users_Info_instance.getPatientbyAddress(msg.sender);
        address payable _hAddr;
        (_hAddr, , )=System_Users_Info_instance.getHospitalbyID(_hID);
        require(finalCheckUpCost[i].finalCostBillID==_finalBillID);
        require(finalCheckUpCost[i].pID==_pID);
        require(finalCheckUpCost[i].hID==_hID);
        require(finalCheckUpCost[i].timestampOfFinalBilling<=now);
				require(finalCheckUpCost[i].timeStampOfPatientFinalBillConsent==0);
        uint _excessID=finalCheckUpCost[i].excessID;
        if(_excessID!=0)
        {
            require(excess[_excessID-1].excessID==_excessID);
            require(excess[_excessID-1].pID==_pID);
            require(excess[_excessID-1].hID==_hID);

            if(excess[_excessID-1].excessAmount>0)
            {
                require(excess[_excessID-1].timestampOfRefundingExcessToPatient<now);
            }

        }
        require(now-finalCheckUpCost[i].timestampOfFinalBilling<=timeLimitForSigningFinalBill);
        finalCheckUpCost[i].timeStampOfPatientFinalBillConsent=now;
    }

		function raiseDispute(address System_Users_Info_address,uint _finalBillID, uint _hID) public returns(uint)
    {
        uint i=_finalBillID-1;
        uint _pID;
				System_Users_Info System_Users_Info_instance = System_Users_Info(System_Users_Info_address);
        (,_pID , , , , )=System_Users_Info_instance.getPatientbyAddress(msg.sender);
        address _hAddr;
        (_hAddr, , )=System_Users_Info_instance.getHospitalbyID(_hID);
        require(finalCheckUpCost[i].finalCostBillID==_finalBillID);
        require(finalCheckUpCost[i].pID==_pID);
        require(finalCheckUpCost[i].hID==_hID);
        require(finalCheckUpCost[i].timestampOfFinalBilling<now);
        require(now-finalCheckUpCost[i].timestampOfFinalBilling<=timeLimitForRaisingDispute);
        disputeIDGenerator++;
        Dispute memory temp=Dispute(disputeIDGenerator,_pID,_hID,_finalBillID,now,0,false);
        dispute.push(temp);
        finalBillIDToDisputeID[_finalBillID]=disputeIDGenerator;
        return(disputeIDGenerator);
    }




		function revealKey(address System_Users_Info_address,bytes32 _key,uint _estimatedBillID,uint _pId) public
		{
				uint _hID;
				uint _finalBillID;
				uint _multiSigID;
				_finalBillID=estimatedBillIDToFinalBillID[_estimatedBillID];
				_multiSigID=estimatedCostBillIDToMultiSigOnMedicalDataID[_estimatedBillID];

				System_Users_Info System_Users_Info_instance = System_Users_Info(System_Users_Info_address);
				(,_hID,)=System_Users_Info_instance.getHospitalbyAddress(msg.sender);
				require(finalCheckUpCost[_finalBillID-1].hID==_hID);
				require(finalCheckUpCost[_finalBillID-1].pID==_pId);
				require(now-finalCheckUpCost[_finalBillID-1].timeStampOfPatientFinalBillConsent<=timeLimitForKeyRevealing);
				require(MultiSignIdToKeyAndExchange[_multiSigID].timeStampOfKeyReveal==0);


				address payable _pAddr;
				(_pAddr, , , , , )=System_Users_Info_instance.getPatientbyID(_pId);

				bytes32 Hashed;
				bytes memory toBeHashed;
				toBeHashed=new bytes (32);
				for (uint i=0;i<32;i++)
				{
						toBeHashed[i]=_key[i];
				}
				Hashed=keccak256(toBeHashed);

				if(Hashed!=MultiSignIdToKeyAndExchange[_multiSigID].keyHash)
				{
					_pAddr.transfer(finalCheckUpCost[_finalBillID-1].finalCost);
				}
				else
				{
					MultiSignIdToKeyAndExchange[_multiSigID].timeStampOfKeyReveal=now;
					MultiSignIdToKeyAndExchange[_multiSigID].key=_key;
				}

		}


		function satisfyAndCompleteTheProcess(address System_Users_Info_address,uint _estimatedBillID,uint _hID) public
		{
  			uint _pID;
  			uint _finalBillID;
  			uint _multiSigID;
  			_finalBillID=estimatedBillIDToFinalBillID[_estimatedBillID];
  			_multiSigID=estimatedCostBillIDToMultiSigOnMedicalDataID[_estimatedBillID];

  			System_Users_Info System_Users_Info_instance = System_Users_Info(System_Users_Info_address);
  			(,_pID , , , , )=System_Users_Info_instance.getPatientbyAddress(msg.sender);
  			require(finalCheckUpCost[_finalBillID-1].hID==_hID);
  			require(finalCheckUpCost[_finalBillID-1].pID==_pID);
        require(finalCheckUpCost[_finalBillID-1].timeStampOfFinalConsent==0);
        require(finalCheckUpCost[_finalBillID-1].timeStampOfComplain==0);
  			require(now-MultiSignIdToKeyAndExchange[_multiSigID].timeStampOfKeyReveal<=timeLimitForAcceptingOrProducingComplain);
        finalCheckUpCost[_finalBillID-1].timeStampOfFinalConsent=now;

		}


		function patient_Complain(address System_Users_Info_address,bytes32[][] memory complaint,bytes[] memory encodedVectors_ThisGate,uint[] memory _gateIndexes,uint _estimatedBillID,uint _hID) public returns(bool)
		{

					bytes[] memory inputVectorsToTheGate;

					bool check;


					uint _pID;
					address payable _hAddr;
					uint _finalBillID;
					uint _multiSigID;
					_multiSigID=estimatedCostBillIDToMultiSigOnMedicalDataID[_estimatedBillID];
					_finalBillID=estimatedBillIDToFinalBillID[_estimatedBillID];



					System_Users_Info System_Users_Info_instance = System_Users_Info(System_Users_Info_address);
					(_hAddr, , )=System_Users_Info_instance.getHospitalbyID(_hID);
	 			 	(,_pID , , , , )=System_Users_Info_instance.getPatientbyAddress(msg.sender);
					require(multiSigOnMedicalData[_multiSigID-1].hospitalID==_hID);
					require(multiSigOnMedicalData[_multiSigID-1].patientID==_pID);
          require(finalCheckUpCost[_finalBillID-1].timeStampOfFinalConsent==0);
          require(finalCheckUpCost[_finalBillID-1].timeStampOfComplain==0);
					require(now-MultiSignIdToKeyAndExchange[_multiSigID].timeStampOfKeyReveal<=timeLimitForAcceptingOrProducingComplain);
          finalCheckUpCost[_finalBillID-1].timeStampOfComplain=now;


					if(encodedVectors_ThisGate.length!=complaint.length)
					{
						_hAddr.transfer(finalCheckUpCost[_finalBillID-1].finalCost);
						return false;
					}


					for(uint i=0;i<encodedVectors_ThisGate.length;i++)
					{
						if(Hash(encodedVectors_ThisGate[i])!=complaint[i][0])
						{
							_hAddr.transfer(finalCheckUpCost[_finalBillID-1].finalCost);
							return false;
						}
					}

					if(_gateIndexes.length>MultiSignIdToEncFileProperties[_multiSigID].maxLinesToGate+1)
					{
						_hAddr.transfer(finalCheckUpCost[_finalBillID-1].finalCost);
						return false;
					}



					for(uint i=0;i<_gateIndexes.length;i++)
					{
						if(!Mverify(complaint[i],_gateIndexes[i],multiSigOnMedicalData[_multiSigID-1].hashOfEncryptedData,MultiSignIdToEncFileProperties[_multiSigID].depth))
						{
							_hAddr.transfer(finalCheckUpCost[_finalBillID-1].finalCost);
							return false;
						}

					}


					inputVectorsToTheGate = new bytes[] (complaint.length-1);


					for(uint i=0;i<_gateIndexes.length-1;i++)
					{
							inputVectorsToTheGate[i]=new bytes (encodedVectors_ThisGate[i+1].length);
							inputVectorsToTheGate[i]=Dec(encodedVectors_ThisGate[i+1],MultiSignIdToKeyAndExchange[_multiSigID].key);
					}

					check=complain_supplement(inputVectorsToTheGate,encodedVectors_ThisGate[0],multiSigOnMedicalData[_multiSigID-1].hashOfData,MultiSignIdToKeyAndExchange[_multiSigID].key);


					if(check)
					{
						msg.sender.transfer(finalCheckUpCost[_finalBillID-1].finalCost);
						return true;
					}

					_hAddr.transfer(finalCheckUpCost[_finalBillID-1].finalCost);
					return false;



		}

		function complain_supplement(bytes[] memory inputVectorsToTheGate,bytes memory encodedVector,bytes32 _root_HashFile,bytes32 _key) private returns(bool)
		{

					bytes32 OperationValue;
					bytes32 Out;
					bytes memory Outy;

					OperationValue=Operation(inputVectorsToTheGate,_root_HashFile);


					Outy=new bytes(encodedVector.length);
					Outy=Dec(encodedVector,_key);
					Out=bytesToBytes32(Outy);

					if(OperationValue!=Out)
					{
						return true;
					}
					else
					{
						return false;
					}

	 }



		function  Mverify(bytes32[] memory complaint,uint _index,bytes32 _rootHashEncFile,uint _depth)  private pure  returns(bool)
		{

					bytes32 _value;
					_value=complaint[0];
					bytes32 Hashed;
					uint i ;
					bytes memory toBeHashed;
					toBeHashed=new bytes (64);

					for(i=0; i<_depth-1; i++)
					{
						//if condition is used to decide whether to append the _value with the complaint vector or append complaint vector
						//with the _value
						/* if(_index+1==1) */
						if ((_index&(1<<i))>>i == 1)
						{

							for (uint j=0;j<32;j++)
							{
								toBeHashed[j]=complaint[i+1][j];
							}
							for (uint j=0;j<32;j++)
							{
								toBeHashed[j+32]=_value[j];
							}


							Hashed=keccak256(toBeHashed);
							_value=Hashed;
						}
						else
						{
							for (uint j=0;j<32;j++)
							{
								toBeHashed[j]=_value[j];
							}
							for (uint j=0;j<32;j++)
							{
								toBeHashed[j+32]=complaint[i+1][j];
							}

							Hashed=keccak256(toBeHashed);
							_value=Hashed;
						}
					}

					return (_value==_rootHashEncFile);
		}




	 function verifySignature(address _addr,bytes32 _hash, bytes  memory signature) private pure returns (bool)
  {
			bytes32 r;
	    bytes32 s;
	    uint8 v;

	    // Check the signature length
	    if (signature.length != 65) {
	      return (false);
	    }

	    // Divide the signature in r, s and v variables with inline assembly.
	    assembly {
	      r := mload(add(signature, 0x20))
	      s := mload(add(signature, 0x40))
	      v := byte(0, mload(add(signature, 0x60)))
	    }

	    if (v < 27) {
	      v += 27;
	    }


	    if (v != 27 && v != 28) {
	      return (false);
	    } else {
	      return(ecrecover(_hash, v, r, s)==_addr);
	    }
  }

	function Dec(bytes memory encryptedText,bytes32 key) private pure returns(bytes memory)
	{

				bytes memory decoded;
				bytes memory finalKey;
				finalKey=new bytes (encryptedText.length);
				finalKey=generateKey(key,encryptedText.length);
				decoded=new bytes (encryptedText.length);
				for(uint i=0;i<encryptedText.length;i++){
					decoded[i]=finalKey[i]^encryptedText[i];
				}
				return decoded;
	}



	function generateKey(bytes32 key,uint keySize) private pure  returns(bytes memory)
	{


			bytes memory finalKey;
			bytes memory keyHashed;
			bytes32 temp;
			finalKey=new bytes(keySize);
			keyHashed=new bytes(32);

			for(uint i=0;i<keySize/32;i++){

				if(i==0)
				{
					bytes memory keyPlusIndex;
					keyPlusIndex=new bytes (33);
					for(uint j=0;j<32;j++){
						keyPlusIndex[j]=key[j];
					}
					keyPlusIndex[32]=0;
					temp=keccak256(keyPlusIndex);

					for(uint j=0;j<32;j++)
					{
						keyHashed[j]=temp[j];
						finalKey[j]=temp[j];
					}
				}
				else
				{
					delete keyHashed;
					keyHashed=new bytes(32);

					for(uint j=0;j<32;j++)
					{
							keyHashed[j]=temp[j];
					}
					temp=keccak256(keyHashed);

					for(uint j=0;j<32;j++)
					{
						keyHashed[j]=temp[j];
						finalKey[i*32+j]=temp[j];
					}

				}

			}
			return finalKey;
	}


	function Operation(bytes[] memory inputVectorsToTheGate,bytes32 _root_HashFile) private returns(bytes32)
	{
			bytes32 Hashed;
			bytes memory equality_bytes;
			bytes32 equality;
			uint operation=2;

			if(operation==2)
			{
						bytes memory toBeHashed;

						toBeHashed=new bytes (2*inputVectorsToTheGate[0].length);
						for (uint i=0;i<inputVectorsToTheGate[0].length;i++)
						{
							toBeHashed[i]=inputVectorsToTheGate[0][i];
						}
						for (uint i=0;i<inputVectorsToTheGate[1].length;i++)
						{
							toBeHashed[i+inputVectorsToTheGate[0].length]=inputVectorsToTheGate[1][i];
						}
						Hashed=keccak256(toBeHashed);
						return Hashed;
			}


			if(operation==3)
			{
						bytes32 temp;
						temp=bytesToBytes32(inputVectorsToTheGate[0]);
						equality_bytes=new bytes (32);
						uint8 a=1;

						if(temp==_root_HashFile)
						{
							equality_bytes[0]=byte(a);
							equality=bytesToBytes32(equality_bytes);
							return equality;
						}
						else
						{
							for(uint8 i=0;i<32;i++)
							{
								equality_bytes[i]=byte(a);
							}
							equality_bytes[0]=0;
							equality=bytesToBytes32(equality_bytes);
							return equality;
						}
			}

			if(operation==4)
			{
				bytes memory toBeHashed;
				uint8 a=1;
				equality_bytes=new bytes (32);

				toBeHashed=new bytes (inputVectorsToTheGate[0].length);
				for (uint i=0;i<inputVectorsToTheGate[0].length;i++)
				{
					toBeHashed[i]=inputVectorsToTheGate[0][i];
				}
				Hashed=keccak256(toBeHashed);

				if(Hashed==_root_HashFile)
				{
					equality_bytes[0]=byte(a);
					equality=bytesToBytes32(equality_bytes);
					return equality;
				}
				else
				{
					for(uint8 i=0;i<32;i++)
					{
						equality_bytes[i]=byte(a);
					}
					equality_bytes[0]=0;
					equality=bytesToBytes32(equality_bytes);
					return equality;
				}
			}

	}


	function Hash(bytes memory _toBeHashed) private pure returns(bytes32)
	{
			bytes32 Hashed;
			bytes memory toBeHashed;
			toBeHashed=new bytes (_toBeHashed.length);
			for (uint i=0;i<_toBeHashed.length;i++)
			{
				toBeHashed[i]=_toBeHashed[i];
			}
			Hashed=keccak256(toBeHashed);
			return Hashed;
	}

	function bytesToBytes32(bytes memory source) private pure returns (bytes32 result)
	{

		    bytes memory tempEmptyStringTest = bytes(source);
		    if (tempEmptyStringTest.length == 0) {
		        return 0x0;
		    }

		    assembly {
		        result := mload(add(source, 32))
		    }
	}

	function log2(uint x) private pure returns (uint y)
	{

			 assembly
			 {
					 let arg := x
					 x := sub(x,1)
					 x := or(x, div(x, 0x02))
					 x := or(x, div(x, 0x04))
					 x := or(x, div(x, 0x10))
					 x := or(x, div(x, 0x100))
					 x := or(x, div(x, 0x10000))
					 x := or(x, div(x, 0x100000000))
					 x := or(x, div(x, 0x10000000000000000))
					 x := or(x, div(x, 0x100000000000000000000000000000000))
					 x := add(x, 1)
					 let m := mload(0x40)
					 mstore(m,           0xf8f9cbfae6cc78fbefe7cdc3a1793dfcf4f0e8bbd8cec470b6a28a7a5a3e1efd)
					 mstore(add(m,0x20), 0xf5ecf1b3e9debc68e1d9cfabc5997135bfb7a7a3938b7b606b5b4b3f2f1f0ffe)
					 mstore(add(m,0x40), 0xf6e4ed9ff2d6b458eadcdf97bd91692de2d4da8fd2d0ac50c6ae9a8272523616)
					 mstore(add(m,0x60), 0xc8c0b887b0a8a4489c948c7f847c6125746c645c544c444038302820181008ff)
					 mstore(add(m,0x80), 0xf7cae577eec2a03cf3bad76fb589591debb2dd67e0aa9834bea6925f6a4a2e0e)
					 mstore(add(m,0xa0), 0xe39ed557db96902cd38ed14fad815115c786af479b7e83247363534337271707)
					 mstore(add(m,0xc0), 0xc976c13bb96e881cb166a933a55e490d9d56952b8d4e801485467d2362422606)
					 mstore(add(m,0xe0), 0x753a6d1b65325d0c552a4d1345224105391a310b29122104190a110309020100)
					 mstore(0x40, add(m, 0x100))
					 let magic := 0x818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff
					 let shift := 0x100000000000000000000000000000000000000000000000000000000000000
					 let a := div(mul(x, magic), shift)
					 y := div(mload(add(m,sub(255,a))), shift)
					 y := add(y, mul(256, gt(arg, 0x8000000000000000000000000000000000000000000000000000000000000000)))
				}

		}




}
