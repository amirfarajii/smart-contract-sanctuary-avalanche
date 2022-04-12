/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Broker {
    struct Booking {
        uint256 vmTypeId;
        address miner;
        address client;
        uint256 pricePerSecond;
        bytes32 launchInfoIpfsHash;
        uint256 bookedTill;
    }
    struct VMOffer {
        address miner;
        uint256 pricePerSecond;
        uint256 initiationFee;
        uint256 machinesAvailable;
        uint256 vmTypeId;
    }

    address ownerAddress;

    mapping(uint256 => VMOffer) vmOffers;
    uint256 nextVmOfferId = 0;

    mapping(uint256 => Booking) bookings;
    uint256 nextBookingId = 0;

    function addOffer(
        uint256 pricePerSecond,
        uint256 initiationFee,
        uint256 vmTypeId
    ) public {
        vmOffers[nextVmOfferId] = VMOffer(msg.sender, pricePerSecond, initiationFee, 0, vmTypeId);
        nextVmOfferId++;
    }

    function updateOffer(
        uint256 offerIndex,
        uint256 pricePerSecond,
        uint256 initiationFee,
        uint256 vmTypeId,
        uint256 machinesAvailable
    ) public {
        require(vmOffers[offerIndex].miner == msg.sender, "Only the owner can remove an offer");
        vmOffers[offerIndex].pricePerSecond = pricePerSecond;
        vmOffers[offerIndex].initiationFee = initiationFee;
        vmOffers[offerIndex].machinesAvailable = machinesAvailable;
        vmOffers[offerIndex].vmTypeId = vmTypeId;
    }

    function removeOffer(uint256 offerIndex) public {
        require(vmOffers[offerIndex].miner == msg.sender, "Only the owner can remove an offer");
        delete vmOffers[offerIndex];
    }

    function getOffersLength() public view returns (uint256) {
        return nextVmOfferId;
    }

    function getOffer(uint256 offerIndex)
        public
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        VMOffer memory offer = vmOffers[offerIndex];
        return (offer.miner, offer.pricePerSecond, offer.initiationFee, offer.machinesAvailable, offer.vmTypeId, offer.machinesAvailable);
    }

    function bookVM(uint256 offerIndex, bytes32 launchInfo) public payable returns (uint256) {
        require(vmOffers[offerIndex].machinesAvailable > 0, "No machines available");
        require(msg.value == vmOffers[offerIndex].initiationFee, "Wrong initiation fee");
        Booking memory booking = Booking(
            vmOffers[offerIndex].vmTypeId,
            vmOffers[offerIndex].miner,
            msg.sender,
            vmOffers[offerIndex].pricePerSecond,
            launchInfo,
            block.timestamp + 10 * 60 * 1000
        );
        bookings[nextBookingId] = booking;
        nextBookingId++;
        return nextBookingId - 1;
    }

    function withdraw() public {
        require(ownerAddress == msg.sender, "Only the owner can withdraw");
        payable(ownerAddress).transfer(address(this).balance);
    }

    function extendBooking(uint256 bookingIndex) public payable {
        require(bookings[bookingIndex].bookedTill > block.timestamp, "Booking expired alreaduy");
        bookings[bookingIndex].bookedTill += (msg.value / bookings[bookingIndex].pricePerSecond) * 1000;
    }

    function getBooking(uint256 bookingIndex)
        public
        view
        returns (
            uint256,
            address,
            address,
            uint256,
            bytes32,
            uint256
        )
    {
        Booking memory booking = bookings[bookingIndex];
        return (booking.vmTypeId, booking.miner, booking.client, booking.pricePerSecond, booking.launchInfoIpfsHash, booking.bookedTill);
    }

    // function getMyBookings() public view returns (uint256[] memory) {
    //     uint256[] memory bookingsList = new uint256[];

    //     for (uint256 i = 0; i < nextBookingId; i++) {
    //         if (bookings[i].client == msg.sender) {
    //             bookingsList[i] = i;
    //         }
    //     }
    //     return bookingsList;
    // }

    function findBookingsByClient() public view returns (Booking[] memory filteredBookings) {
        Booking[] memory bookingsTemp = new Booking[](nextBookingId);
        uint256 count;
        for (uint256 i = 0; i < nextBookingId; i++) {
            if (bookings[i].client == msg.sender) {
                bookingsTemp[count] = bookings[i];
                count += 1;
            }
        }

        filteredBookings = new Booking[](count);
        for (uint256 i = 0; i < count; i++) {
            filteredBookings[i] = bookingsTemp[i];
        }
    }

    function getAllBookingsDebug() public view returns (Booking[] memory filteredBookings) {
        Booking[] memory bookingsTemp = new Booking[](nextBookingId);
        uint256 count;
        for (uint256 i = 0; i < nextBookingId; i++) {
            bookingsTemp[count] = bookings[i];
            count += 1;
        }

        filteredBookings = new Booking[](count);
        for (uint256 i = 0; i < count; i++) {
            filteredBookings[i] = bookingsTemp[i];
        }
    }

    function getBookingsLength() public view returns (uint256) {
        return nextBookingId;
    }
}