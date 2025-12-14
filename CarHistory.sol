// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CarHistory {
    
    struct Record {
        uint256 timestamp;
        uint256 mileage;
        string description;
        address recorder;
    }

    mapping(string => Record[]) public vehicleRecords;
    event RecordAdded(string vin, uint256 mileage, string description, uint256 timestamp);

    function addRecord(string memory _vin, uint256 _mileage, string memory _description) public {
        if (vehicleRecords[_vin].length > 0) {
            uint256 lastMileage = vehicleRecords[_vin][vehicleRecords[_vin].length - 1].mileage;
            require(_mileage >= lastMileage, "Mileage Error: New mileage cannot be less than previous record!");
        }

        Record memory newRecord = Record({
            timestamp: block.timestamp,
            mileage: _mileage,
            description: _description,
            recorder: msg.sender
        });

        vehicleRecords[_vin].push(newRecord);
        emit RecordAdded(_vin, _mileage, _description, block.timestamp);
    }

    function getHistory(string memory _vin) public view returns (Record[] memory) {
        return vehicleRecords[_vin];
    }
}
