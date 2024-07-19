pragma solidity >0.4.0 <=0.7.0;
pragma experimental ABIEncoderV2;
import "./SC_P_HA_2.sol";

contract SC_P_DBO
{

		uint public Now;

		uint public databaseStoringFilePrice=5;


		struct ApplicationForStoring
    {
        uint appID; //application ID..
				address patientAddress;
				address dboAddress;
        uint multiSigID; //Multi-signature ID..
				bytes32 key;
				bytes32 merkleRootOfFile;
				bytes32 merkleRootOfEncFile;
        uint timestamp_application;  //timestamp of application..
				uint timestamp_merkleRootVerification;
				uint timestamp_keyReveal;
				uint timestamp_complain;
				uint timestamp_approval;
				uint timestamp_Unlocking_Patient;
				uint timeStamp_Unlocking_DO;
		}

		uint public applicationIDGenerator;
    ApplicationForStoring[] public applicationForStoring;


		uint public timeLimitForMerkleRootVerification_P_DO = 100 seconds;
		uint public timeLimitForKeyReveal_P_DO = 100 seconds;
		uint public timeLimitForGivingComplainOrPuttingInTheDatatbase_P_DO = 100 seconds;

		mapping(uint=>uint) public patientIdToApplicationId;
 		mapping(uint=>bool) public applicationToApproval;


		function increaseTheTimeBy10seconds() public {
			Now=now;
		}


		function getApplicationForStoringStruct(uint id) public view returns(ApplicationForStoring memory)
		{
				return applicationForStoring[id-1];
		}


		function keepData_Patient(address System_Users_Info_address,address P_HA_address,uint _estimatedBillID,bytes32 _merkleRootEncFile, bytes32 _merkleRootFile,address _dboAddress) payable public returns(uint)
    {
        uint _pId;
				uint _multiSigID;
				uint _finalBillID;



				System_Users_Info System_Users_Info_instance = System_Users_Info(System_Users_Info_address);
				SC_P_HA_1 P_HA_1_instance=SC_P_HA_1(P_HA_address);
        (,_pId , , , , )=System_Users_Info_instance.getPatientbyAddress(msg.sender);


				_finalBillID=P_HA_1_instance.estimatedBillIDToFinalBillID(_estimatedBillID);
				_multiSigID=P_HA_1_instance.estimatedCostBillIDToMultiSigOnMedicalDataID(_estimatedBillID);


				SC_P_HA_1.MultiSigOnMedicalData memory multiSigOnMedicalData_Object =P_HA_1_instance.getMultiSigOnMedicalDataStruct(_multiSigID);
				SC_P_HA_1.FinalCheckUpCost memory finalCheckUpCost_Object=P_HA_1_instance.getFinalBillStruct(_finalBillID);

        applicationIDGenerator = applicationIDGenerator+1;

				require(_pId==multiSigOnMedicalData_Object.patientID);
				require(msg.value>=databaseStoringFilePrice);
				require(finalCheckUpCost_Object.timeStampOfFinalConsent!=0);
        require(finalCheckUpCost_Object.timeStampOfComplain==0);
				require(multiSigOnMedicalData_Object.hashOfData==_merkleRootFile);


				ApplicationForStoring memory a=ApplicationForStoring(applicationIDGenerator,msg.sender,_dboAddress,_multiSigID,"",multiSigOnMedicalData_Object.hashOfData,_merkleRootEncFile,now,0,0,0,0,0,0);
        applicationForStoring.push(a);
				patientIdToApplicationId[_pId]=applicationIDGenerator;
        return(applicationIDGenerator);
    }

		function leaveAfterKeepData_Patient(address System_Users_Info_address,address P_HA_address,uint _appID,uint _estimatedBillID) public
		{
				uint _pId;
				uint _multiSigID;

				System_Users_Info System_Users_Info_instance = System_Users_Info(System_Users_Info_address);
				SC_P_HA_1 P_HA_1_instance=SC_P_HA_1(P_HA_address);
				(,_pId , , , , )=System_Users_Info_instance.getPatientbyAddress(msg.sender);

				_multiSigID=P_HA_1_instance.estimatedCostBillIDToMultiSigOnMedicalDataID(_estimatedBillID);

				SC_P_HA_1.MultiSigOnMedicalData memory multiSigOnMedicalData_Object =P_HA_1_instance.getMultiSigOnMedicalDataStruct(_multiSigID);

				require(_pId==multiSigOnMedicalData_Object.patientID);
				require(applicationForStoring[_appID-1].timestamp_application!=0);
				require(applicationForStoring[_appID-1].timestamp_merkleRootVerification==0);
				require(applicationForStoring[_appID-1].timestamp_Unlocking_Patient==0);
				require(now-applicationForStoring[_appID-1].timestamp_application>timeLimitForMerkleRootVerification_P_DO);
				msg.sender.transfer(databaseStoringFilePrice);
				applicationForStoring[_appID-1].timestamp_Unlocking_Patient=now;

		}


		function verifyEncFile_DO(uint _appID) public payable
		{
				require(msg.sender==applicationForStoring[_appID-1].dboAddress);
				require(msg.value>=databaseStoringFilePrice);
				require(applicationForStoring[_appID-1].timestamp_merkleRootVerification==0);
				require(now-applicationForStoring[_appID-1].timestamp_application<=timeLimitForMerkleRootVerification_P_DO);
				applicationForStoring[_appID-1].timestamp_merkleRootVerification=now;
		}



		function leaveAfterVerifyEncFile_DO(uint _appID) public
		{
				require(msg.sender==applicationForStoring[_appID-1].dboAddress);
				require(applicationForStoring[_appID-1].timestamp_merkleRootVerification!=0);
				require(applicationForStoring[_appID-1].timestamp_keyReveal==0);
				require(applicationForStoring[_appID-1].timeStamp_Unlocking_DO==0);
				require(now-applicationForStoring[_appID-1].timestamp_merkleRootVerification>timeLimitForKeyReveal_P_DO);
				msg.sender.transfer(databaseStoringFilePrice);
				applicationForStoring[_appID-1].timeStamp_Unlocking_DO=now;

		}

		function keyReveal_Patient(address System_Users_Info_address,address P_HA_address,uint _appID,bytes32 _key) public returns(uint)
		{
				System_Users_Info System_Users_Info_instance = System_Users_Info(System_Users_Info_address);
				SC_P_HA_1 P_HA_1_instance=SC_P_HA_1(P_HA_address);

				uint _multiSigID=applicationForStoring[_appID-1].multiSigID;
				SC_P_HA_1.MultiSigOnMedicalData memory multiSigOnMedicalData_Object =P_HA_1_instance.getMultiSigOnMedicalDataStruct(_multiSigID);

				address payable _pAddr;
        (_pAddr, , , , , )=System_Users_Info_instance.getPatientbyID(multiSigOnMedicalData_Object.patientID);


				require(msg.sender==_pAddr);
				require(applicationForStoring[_appID-1].timestamp_keyReveal==0);
				require(now-applicationForStoring[_appID-1].timestamp_merkleRootVerification<=timeLimitForKeyReveal_P_DO);
				applicationForStoring[_appID-1].key=_key;
				applicationForStoring[_appID-1].timestamp_keyReveal=now;
		}

		function leaveAfterKeyReveal_patient(address System_Users_Info_address,address P_HA_address,uint _appID,uint _estimatedBillID) public
		{
				uint _pId;
				uint _multiSigID;

				System_Users_Info System_Users_Info_instance = System_Users_Info(System_Users_Info_address);
				SC_P_HA_1 P_HA_1_instance=SC_P_HA_1(P_HA_address);
				(,_pId , , , , )=System_Users_Info_instance.getPatientbyAddress(msg.sender);

				_multiSigID=P_HA_1_instance.estimatedCostBillIDToMultiSigOnMedicalDataID(_estimatedBillID);

				SC_P_HA_1.MultiSigOnMedicalData memory multiSigOnMedicalData_Object =P_HA_1_instance.getMultiSigOnMedicalDataStruct(_multiSigID);

				require(_pId==multiSigOnMedicalData_Object.patientID);
				require(applicationForStoring[_appID-1].timestamp_keyReveal!=0);
				require(applicationForStoring[_appID-1].timestamp_complain==0);
				require(applicationForStoring[_appID-1].timestamp_approval==0);
				require(applicationForStoring[_appID-1].timestamp_Unlocking_Patient==0);
				require(now-applicationForStoring[_appID-1].timestamp_keyReveal>timeLimitForGivingComplainOrPuttingInTheDatatbase_P_DO);
				msg.sender.transfer(databaseStoringFilePrice);
				applicationForStoring[_appID-1].timestamp_Unlocking_Patient=now;

		}


		function approval_DO(uint _appID) public
		{
			require(msg.sender==applicationForStoring[_appID-1].dboAddress);
			require(applicationForStoring[_appID-1].timestamp_complain==0);
			require(applicationForStoring[_appID-1].timestamp_approval==0);
			require(now-applicationForStoring[_appID-1].timestamp_keyReveal<=timeLimitForGivingComplainOrPuttingInTheDatatbase_P_DO);
			applicationToApproval[_appID]=true;
			msg.sender.transfer(2*databaseStoringFilePrice);
			applicationForStoring[_appID-1].timestamp_approval=now;
		}



		function complain(address System_Users_Info_address,address P_HA_address,bytes32[][] memory complaint,bytes[] memory encodedVectors_ThisGate,uint _outputIndex,uint _appID) public returns(bool)
		{


				System_Users_Info System_Users_Info_instance = System_Users_Info(System_Users_Info_address);
				SC_P_HA_1 P_HA_1_instance=SC_P_HA_1(P_HA_address);

				uint _multiSigID=applicationForStoring[_appID].multiSigID;
				SC_P_HA_1.MultiSigOnMedicalData memory multiSigOnMedicalData_Object =P_HA_1_instance.getMultiSigOnMedicalDataStruct(_multiSigID);

				bytes32 _hashOfEncryptedData=multiSigOnMedicalData_Object.hashOfEncryptedData;applicationToApproval;
				SC_P_HA_1.FileProperties memory fileProperties_Object=P_HA_1_instance.getEncFileProperties(_multiSigID);

				uint _depth=fileProperties_Object.depth;


				require( _outputIndex>=(2^_depth-1) && _outputIndex<(2^(_depth)-1) );
				require(msg.sender==applicationForStoring[_appID-1].dboAddress);
				require(applicationForStoring[_appID-1].timestamp_complain==0);
				require(applicationForStoring[_appID-1].timestamp_approval==0);
				require(now-applicationForStoring[_appID].timestamp_keyReveal<=timeLimitForGivingComplainOrPuttingInTheDatatbase_P_DO);


				address payable _pAddr;
				(_pAddr, , , , , )=System_Users_Info_instance.getPatientbyID(multiSigOnMedicalData_Object.patientID);

				bytes32 _key=applicationForStoring[_appID].key;

				applicationForStoring[_appID].timestamp_complain=now;

				if(!verify(complaint,encodedVectors_ThisGate,_outputIndex,_depth,_hashOfEncryptedData,_key))
				{
						/* applicationToApproval[_appID]=true; */
						applicationForStoring[_appID-1].timestamp_approval=now;
						return false;

				}
				else{

						 return true;
				}
		}

		function verify(bytes32[][] memory complaint,bytes[] memory encodedVectors_ThisGate,uint _outputIndex,uint _depth,bytes32 _hashOfEncryptedData,bytes32 _key) private returns(bool){

			bytes[] memory inputVectorsToTheGate;
			bytes32 OperationValue;
			bytes32 Out;
			bytes memory Outy;

			uint inputIndexOne=(2*_outputIndex)-(2^(_depth));
			uint inputIndexTwo=(2*_outputIndex)+1-(2^(_depth));

			if(encodedVectors_ThisGate.length!=3)
			{
				return false;
			}

			if(complaint.length!=3)
			{
				return false;
			}

			for(uint i=0;i<encodedVectors_ThisGate.length;i++)
			{
				if(Hash(encodedVectors_ThisGate[i])!=complaint[i][0])
				{
					return false;
				}
			}

			if(!Mverify(complaint[0],_outputIndex,_depth,_hashOfEncryptedData))
			{
				return false;
			}

			if(!Mverify(complaint[1],inputIndexOne,_depth,_hashOfEncryptedData))
			{
				return false;
			}

			if(!Mverify(complaint[1],inputIndexTwo,_depth,_hashOfEncryptedData))
			{
				return false;
			}


			Outy=new bytes(encodedVectors_ThisGate[0].length);
			Outy=Dec(encodedVectors_ThisGate[0],_key);

			//uptoComplaintLength=true;
			inputVectorsToTheGate = new bytes[] (2);
			inputVectorsToTheGate[0]=new bytes (encodedVectors_ThisGate[1].length);
			inputVectorsToTheGate[0]=Dec(encodedVectors_ThisGate[1],_key);
			inputVectorsToTheGate[1]=new bytes (encodedVectors_ThisGate[2].length);
			inputVectorsToTheGate[1]=Dec(encodedVectors_ThisGate[2],_key);

			OperationValue=Operation(inputVectorsToTheGate);
			Out=bytesToBytes32(Outy);

			if(Out!=OperationValue)
			{
				return true;
			}

			return false;

		}


		function  Mverify(bytes32[] memory complaint,uint _index,uint _depth,bytes32 _hashOfEncryptedData) private view returns(bool)
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
			return (_value==_hashOfEncryptedData);
		}

		function Operation(bytes[] memory inputVectorsToTheGate) private pure returns(bytes32)
		{
				bytes32 Hashed;
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

}
