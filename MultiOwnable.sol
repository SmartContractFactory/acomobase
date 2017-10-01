pragma solidity ^0.4.11;

contract MultiOwnable {
    
    address[2] public owners;

    event OwnershipTransferred(address from, address to);
    event OwnershipGranted(address to);

    function MultiOwnable() public {
        owners[0] = 0xFfB91d2Ce784bE3eb997Ff156E2aa8C31Fd9d942;
        owners[1] = 0x775c6De34084D9D59c6Fbd1da34c4F48a4EC409D;
    }

    /**
     * Functions with this modifier will only execute if the the function is called by the 
     * owners of the contract.
     * */ 
    modifier onlyOwners {
        require(msg.sender == owners[0] || msg.sender == owners[1]);
        _;
    }

    /**
     * Trasfers ownership from the owner who executes the function to another given address.
     * 
     * @param _newOwner The address which will be granted ownership.
     * */
    function transferOwnership(address _newOwner) public onlyOwners {
        require(_newOwner != 0x0 && _newOwner != owners[0] && _newOwner != owners[1]);
        if (msg.sender == owners[0]) {
            OwnershipTransferred(owners[0], _newOwner);
            owners[0] = _newOwner;
        } else {
            OwnershipTransferred(owners[1], _newOwner);
            owners[1] = _newOwner;
        }
    }
}