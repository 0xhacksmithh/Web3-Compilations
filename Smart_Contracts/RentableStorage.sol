// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RentableStorage is Ownable {

    IERC20 public paymentToken;

    // Price per GB per second
    uint256 public pricePerGBPerSecond;

    struct Rental {
        uint256 storageAmount; // in GB
        uint256 startTime;
        uint256 endTime;
        bool active;
    }

    mapping(address => Rental) public rentals;

    event StorageRented(
        address indexed user,
        uint256 storageAmount,
        uint256 duration,
        uint256 cost
    );

    event RentalExtended(
        address indexed user,
        uint256 newEndTime
    );

    event RentalCancelled(
        address indexed user
    );

    constructor(
        address _paymentToken,
        uint256 _pricePerGBPerSecond
    ) Ownable(msg.sender) {
        paymentToken = IERC20(_paymentToken);
        pricePerGBPerSecond = _pricePerGBPerSecond;
    }

    // Rent storage space
    function rentStorage(
        uint256 storageAmount,
        uint256 duration
    ) external {

        require(storageAmount > 0, "Invalid storage amount");
        require(duration > 0, "Invalid duration");

        Rental storage rental = rentals[msg.sender];

        require(!rental.active, "Rental already active");

        uint256 cost =
            storageAmount *
            duration *
            pricePerGBPerSecond;

        // User must approve tokens first
        paymentToken.transferFrom(
            msg.sender,
            address(this),
            cost
        );

        rentals[msg.sender] = Rental({
            storageAmount: storageAmount,
            startTime: block.timestamp,
            endTime: block.timestamp + duration,
            active: true
        });

        emit StorageRented(
            msg.sender,
            storageAmount,
            duration,
            cost
        );
    }

    // Extend rental duration
    function extendRental(
        uint256 additionalDuration
    ) external {

        Rental storage rental = rentals[msg.sender];

        require(rental.active, "No active rental");
        require(
            block.timestamp < rental.endTime,
            "Rental expired"
        );

        uint256 cost =
            rental.storageAmount *
            additionalDuration *
            pricePerGBPerSecond;

        paymentToken.transferFrom(
            msg.sender,
            address(this),
            cost
        );

        rental.endTime += additionalDuration;

        emit RentalExtended(
            msg.sender,
            rental.endTime
        );
    }

    // Cancel expired rental
    function cancelRental() external {

        Rental storage rental = rentals[msg.sender];

        require(rental.active, "No active rental");
        require(
            block.timestamp >= rental.endTime,
            "Rental still active"
        );

        rental.active = false;

        emit RentalCancelled(msg.sender);
    }

    // Check remaining rental time
    function remainingTime(
        address user
    )
        external
        view
        returns (uint256)
    {
        Rental memory rental = rentals[user];

        if (
            !rental.active ||
            block.timestamp >= rental.endTime
        ) {
            return 0;
        }

        return rental.endTime - block.timestamp;
    }

    // Owner withdraws collected tokens
    function withdrawTokens(
        uint256 amount
    ) external onlyOwner {

        paymentToken.transfer(
            owner(),
            amount
        );
    }
}