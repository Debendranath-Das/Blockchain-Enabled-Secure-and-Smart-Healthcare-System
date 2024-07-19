pragma solidity >0.6.0 <=0.7.0;
pragma experimental ABIEncoderV2;

contract System_Users_Info
{

    address public govtAuthority;


    constructor() public {
      govtAuthority=msg.sender;
    }


    modifier onlyGovtAuthority(address _party)
    {
        require(_party==govtAuthority);
        _;
    }



    /* Patient Registration */

    uint public patientIDGenerator=0;

    struct Patient
    {
        address payable pAddr;
        uint patientID;
        string name;
        uint8 age;
        uint mob;
        string add;
    }

    Patient[] public patient;

    mapping(address=>uint) public mapFromAddToId_P; //Mapping from patient address to patient ID..

    function patientRegistration(string memory _name, uint _age, uint _mob, string memory _add) public
    {
        require(mapFromAddToId_P[msg.sender] == 0); //The user was already registered..
        require(!isEmptyString(_name)); //Checking whether name is empty or not..
        require(_age>0 && _age<=100); //Checking for valid age range..
        require(_mob>0 && numDigits(_mob)==10); //Checking for valid mobile no..
        require(!isEmptyString(_add)); //Checking whether address is empty or not..

        //The user will be registered..
        patientIDGenerator = patientIDGenerator + 1;
        mapFromAddToId_P[msg.sender]=patientIDGenerator;
        Patient memory pt = Patient(msg.sender,patientIDGenerator,_name,uint8(_age),_mob,_add);
        patient.push(pt);

    }


    function getPatientbyID(uint _patientID) view public returns(address payable,uint,string memory,uint8,uint,string memory)
    {
        require(_patientID>=1 && _patientID<=patientIDGenerator);
        uint x = _patientID-1;
        return(patient[x].pAddr,patient[x].patientID,patient[x].name,patient[x].age,patient[x].mob,patient[x].add);
    }

    function getPatientbyAddress(address _pAddr) view public returns(address payable,uint,string memory,uint8,uint,string memory)
    {
        uint _patientID = mapFromAddToId_P[_pAddr];
        require(_patientID>=1 && _patientID<=patientIDGenerator);
        uint x = _patientID-1;
        return(patient[x].pAddr,patient[x].patientID,patient[x].name,patient[x].age,patient[x].mob,patient[x].add);

    }

    /*Hospital Registration*/

    uint public hospitalIDGenerator=0;

    struct Hospital
    {
        address payable hAddr;
        uint hospitalID;
        string name;
    }

    Hospital[] public hospital;

    mapping(address=>uint) mapFromAddToId_H; //Mapping from hospital address to hospital ID..

    function hospitalRegistration(string memory _name) public
    {

        require(mapFromAddToId_H[msg.sender] == 0); //this Hospital was already registered..
        require(!isEmptyString(_name)); //Checking whether name is empty or not..

        //Hospital will be registered..
        hospitalIDGenerator = hospitalIDGenerator + 1;
        mapFromAddToId_H[msg.sender]=hospitalIDGenerator;
        Hospital memory h = Hospital(msg.sender,hospitalIDGenerator,_name);
        hospital.push(h);
    }

    function getHospitalbyID(uint _hospitalID) view public returns(address payable,uint,string memory)
    {
        require(_hospitalID>=1 && _hospitalID<=hospitalIDGenerator);
        uint x = _hospitalID-1;
        return(hospital[x].hAddr,hospital[x].hospitalID,hospital[x].name);
    }

    function getHospitalbyAddress(address _hAddr) view public returns(address payable,uint,string memory)
    {
        uint _hospitalID = mapFromAddToId_H[_hAddr];
        require(_hospitalID>=1 && _hospitalID<=hospitalIDGenerator);
        uint x = _hospitalID-1;
        return(hospital[x].hAddr,hospital[x].hospitalID,hospital[x].name);
    }


    /*DataBase Registration*/

    uint public dboIDGenerator=0;

    struct DataBaseOwner
    {
        address payable dboAddr;
        uint dboID;
        string name;
    }


    DataBaseOwner[] public dataBaseOwner;
    mapping(address=>uint) public mapFromAddrToID_DBO;


    function dboRegistration(address payable _dboAddr,string memory _name) public onlyGovtAuthority(msg.sender)
    {
        require(mapFromAddrToID_DBO[_dboAddr]==0);
        require(!isEmptyString(_name));
        dboIDGenerator+=1;

        DataBaseOwner memory DataBaseOwnerStruct;
        DataBaseOwnerStruct.dboAddr=_dboAddr;
        DataBaseOwnerStruct.dboID=dboIDGenerator;
        DataBaseOwnerStruct.name=_name;
        dataBaseOwner.push(DataBaseOwnerStruct);

        mapFromAddrToID_DBO[_dboAddr]=dboIDGenerator;

    }

    function dboById(uint _dboID) public view returns(address payable,uint,string memory)
    {
        require(_dboID>=1 && _dboID<=dboIDGenerator);
        return (dataBaseOwner[_dboID-1].dboAddr,dataBaseOwner[_dboID-1].dboID,dataBaseOwner[_dboID-1].name);
    }

    function dboByAddress(address _dboAddr) public view returns(address payable,uint,string memory)
    {
        uint _dboID=mapFromAddrToID_DBO[_dboAddr];
        require(_dboID>=1 && _dboID<=dboIDGenerator);
        return (dataBaseOwner[_dboID-1].dboAddr,dataBaseOwner[_dboID-1].dboID,dataBaseOwner[_dboID-1].name);

    }



    //Data Structure for Access Control...
    mapping (address=>mapping(address=>bool)) public read_permission_to_H;
    mapping (address=>mapping(address=>bool)) public write_permission_to_H;
    mapping (address=>mapping(address=>bool)) public read_permission_to_IC;


    function grant_permission(address callingPatientAddress,uint _hID) public
    {
        address payable _hAddr;
        (_hAddr, , )=getHospitalbyID(_hID);
        read_permission_to_H[callingPatientAddress][_hAddr]=true;
        write_permission_to_H[callingPatientAddress][_hAddr]=true;
    }

    function grant_permission_patient_To_IC(address callingPatientAddress,uint _IC) public
    {
        address payable icAddr;
        (icAddr, , )=getInsuranceCompanybyID(_IC);
        read_permission_to_IC[callingPatientAddress][icAddr]=true;
    }


    function deny_permission_patient_To_IC(address callingPatientAddress,uint _IC) public
    {
        address payable icAddr;
        (icAddr, , )=getInsuranceCompanybyID(_IC);
        read_permission_to_IC[callingPatientAddress][icAddr]=false;
    }



    function isEmptyString(string memory s) public pure returns(bool)
    {
            bytes memory b=bytes(s);
            if(b.length==0)
            {
                return true;
            }
            return false;
    }

    function numDigits(uint number) public pure returns (uint8)
    {
        uint8 digits = 0;
        while (number != 0)
        {
            number /= 10;
            digits++;
        }
        return digits;
    }

    function isEqual(string memory a, string memory b) public pure returns(bool)
    {
        bytes memory aa=bytes(a);
        bytes memory bb=bytes(b);
        return(keccak256(aa)==keccak256(bb));
    }


}
