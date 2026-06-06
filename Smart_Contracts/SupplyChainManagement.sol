// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract SupplyChainManagement {

    enum ProductStatus {
        Created,
        InTransit,
        Delivered
    }

    struct Product {
        uint256 id;
        string name;
        string metadataURI; // IPFS/Arweave metadata
        address manufacturer;
        address currentOwner;
        ProductStatus status;
        uint256 createdAt;
    }

    struct TrackingRecord {
        address actor;
        string location;
        ProductStatus status;
        uint256 timestamp;
    }

    uint256 public productCount;

    // productId => Product
    mapping(uint256 => Product) public products;

    // productId => tracking history
    mapping(uint256 => TrackingRecord[]) public trackingHistory;

    event ProductCreated(
        uint256 indexed productId,
        string name,
        address indexed manufacturer
    );

    event OwnershipTransferred(
        uint256 indexed productId,
        address indexed from,
        address indexed to
    );

    event StatusUpdated(
        uint256 indexed productId,
        ProductStatus status,
        string location
    );

    modifier productExists(uint256 productId) {
        require(productId < productCount, "Product does not exist");
        _;
    }

    modifier onlyProductOwner(uint256 productId) {
        require(
            products[productId].currentOwner == msg.sender,
            "Not current owner"
        );
        _;
    }

    /// Create new product
    function createProduct(
        string calldata name,
        string calldata metadataURI,
        string calldata originLocation
    ) external {

        uint256 productId = productCount;

        products[productId] = Product({
            id: productId,
            name: name,
            metadataURI: metadataURI,
            manufacturer: msg.sender,
            currentOwner: msg.sender,
            status: ProductStatus.Created,
            createdAt: block.timestamp
        });

        trackingHistory[productId].push(
            TrackingRecord({
                actor: msg.sender,
                location: originLocation,
                status: ProductStatus.Created,
                timestamp: block.timestamp
            })
        );

        productCount++;

        emit ProductCreated(
            productId,
            name,
            msg.sender
        );
    }

    /// Transfer product ownership
    function transferOwnership(
        uint256 productId,
        address newOwner,
        string calldata newLocation
    )
        external
        productExists(productId)
        onlyProductOwner(productId)
    {
        require(newOwner != address(0), "Invalid address");

        address previousOwner =
            products[productId].currentOwner;

        products[productId].currentOwner = newOwner;
        products[productId].status =
            ProductStatus.InTransit;

        trackingHistory[productId].push(
            TrackingRecord({
                actor: msg.sender,
                location: newLocation,
                status: ProductStatus.InTransit,
                timestamp: block.timestamp
            })
        );

        emit OwnershipTransferred(
            productId,
            previousOwner,
            newOwner
        );

        emit StatusUpdated(
            productId,
            ProductStatus.InTransit,
            newLocation
        );
    }

    /// Mark product as delivered
    function markDelivered(
        uint256 productId,
        string calldata deliveryLocation
    )
        external
        productExists(productId)
        onlyProductOwner(productId)
    {
        products[productId].status =
            ProductStatus.Delivered;

        trackingHistory[productId].push(
            TrackingRecord({
                actor: msg.sender,
                location: deliveryLocation,
                status: ProductStatus.Delivered,
                timestamp: block.timestamp
            })
        );

        emit StatusUpdated(
            productId,
            ProductStatus.Delivered,
            deliveryLocation
        );
    }

    /// Get tracking history count
    function getTrackingHistoryLength(
        uint256 productId
    )
        external
        view
        returns (uint256)
    {
        return trackingHistory[productId].length;
    }

    /// Get specific tracking record
    function getTrackingRecord(
        uint256 productId,
        uint256 index
    )
        external
        view
        returns (
            address actor,
            string memory location,
            ProductStatus status,
            uint256 timestamp
        )
    {
        TrackingRecord memory record =
            trackingHistory[productId][index];

        return (
            record.actor,
            record.location,
            record.status,
            record.timestamp
        );
    }
}