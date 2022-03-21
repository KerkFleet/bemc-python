//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//This is marked as an error for me but i don't think it's actually an error. IDK.
import "OpenZeppelin/openzeppelin-contracts@4.4.1/contracts/access/Ownable.sol";


contract DemandReduction is Ownable{
    
    // Stucture of a submitted bid
    struct Bid {
        uint256 power;
        uint256 price;
        address consumer;
    }

    // ----------- Variables ----------- //

    // To keep track of who has registered
    mapping(address => bool) registered;
    address [] registrants;
    
    Bid[] bids; // All consumer bids
    address [] winners; // selected winners
    uint reward_amount; // Chosen based on winning bid
    uint power_reduction; // Specified by consumer

    // -------- Events --------- //

    // Notify consumer when to submit their bids
    event notify_consumer();

    // Notify consumers of the winning bids
    event notify_rewards();


    // ---------- Public Utility Functions -------------- //

    
    // Allows the utility to request an energy reduction specified by the amount
    function request_reduction(uint reduction_amount) public payable onlyOwner{
        require(reduction_amount > 0, "Must request a reduction amount > 0");
        require(msg.value >= 0.01 ether, "Must pay at least 0.01 ether");
        power_reduction = reduction_amount;
        emit notify_consumer();
    }


    // Driver function for selecting the winning bids
    function select_winners() public {
        require(bids.length > 0, "There are no bids!");
        delete winners;
        Bid [] memory sorted_bids;
        sorted_bids = bids;
        quickSort(sorted_bids, 0, bids.length-1);
        uint lastWinningBid = 0;
        lastWinningBid = optimize_bids(sorted_bids, power_reduction);
        disperse_rewards(sorted_bids, lastWinningBid);
        delete bids;
        // delete reward_amount;
        // delete power_reduction;
    }


    // -------------- Public Consumer Functions -------------- //


    // Function to receive consumer bid submissions in the form of power to price
    function submit_bids(uint256[] memory power, uint256[] memory price) public {
        // require(registered[msg.sender] == true, "Need to register");
        require(power.length == price.length, "Each bid must have a reduction amount and an associated price");
        for(uint i = 0; i < power.length; i++){
            bids.push(Bid(power[i], price[i] * 1 wei, msg.sender)); 
        }
    }


    // Function to allow consumers to register to the smart contract
    function register() public {
        require(registered[msg.sender] == false, "Already registered");
        registrants.push(msg.sender);
        registered[msg.sender] = true;
    }


    // ------------- Private Functions ------------ //


    // Optimizes the bids based on most energy for cheapest price
    // Returns index of the last selected bid of the sorted list
    function optimize_bids(Bid [] memory bids, uint reduction)private returns(uint){
        uint last_bid = 0; uint power_amount = 0;
        for(uint i = 0; i < bids.length; i++){
            power_amount += bids[i].power;
            if(power_amount >= power_reduction){
                last_bid = i;
                reward_amount = bids[i].price;
                break;
            }
        }
        return last_bid;
    }


    // Quick sort algorithm for bids array. Must have a wrapper
    function quickSort(Bid[] memory arr, uint left, uint right) private{
        uint i = left;
        uint j = right;
        if(i==j) return;
        uint pivot = arr[uint(left + (right - left) / 2)].price;
        while (i <= j) {
            while (arr[uint(i)].price < pivot) i++;
            while (pivot < arr[uint(j)].price) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSort(arr, left, j);
        if (i < right)
            quickSort(arr, i, right);
    }


    // Function to disperse rewards to each selected winner
    function disperse_rewards(Bid [] memory bids, uint last_bid) private {
        for(uint i = 0; i <= last_bid; i++){
            address payable winner = payable(bids[i].consumer);
            winners.push(bids[i].consumer);
            // winners.push(bids[i]);
            winner.transfer(reward_amount);
        }
        address payable _owner = payable(owner());
        _owner.transfer(address(this).balance);
        emit notify_rewards();
    }


    // ---------- Public View Functions --------- //
    

    // Simply getters for different global variables

    function getRegistered(address consumer) public view returns(bool){
        return registered[consumer];
    }

    function getBids() public view returns (Bid[] memory){
        return(bids);
    }

    function getWinners() public view returns (address [] memory){
        return(winners);
    }
    // function getWinners() public view returns (address [] memory){
    //     return(winners);
    // }

    function getRewardAmount() public view returns (uint) {
        return(reward_amount);
    }

}
