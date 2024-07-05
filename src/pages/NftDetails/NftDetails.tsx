import React, { useState } from "react";

interface Bid {
  name: string;
  bidValue: number;
}

const mockupBids: Bid[] = [
  { name: "Bidder1", bidValue: 100 },
  { name: "Bidder2", bidValue: 150 },
];

export const NftDetails = () => {
  const [bids, setBids] = useState<Bid[]>(mockupBids);
  const [showBidField, setShowBidField] = useState(false);
  const [newBid, setNewBid] = useState("");
  const [currentPrice, setCurrentPrice] = useState(200);
  const usdPrice = currentPrice * 1.2; // Example conversion rate

  const highestBid = Math.max(...bids.map((bid) => bid.bidValue), 0);

  const handleBid = () => {
    if (parseFloat(newBid) > highestBid) {
      setBids([...bids, { name: "You", bidValue: parseFloat(newBid) }]);
      setShowBidField(false);
      setNewBid("");
    } else {
      alert("Bid must be higher than the current highest bid.");
    }
  };
  return (
    <div className="flex h-screen">
      <div className="w-1/2">
        <img
          src="https://i.seadn.io/s/raw/files/6a45583bd2683834496cddf0c425338a.png?auto=format&dpr=1&w=1000"
          alt="NFT"
          className="w-full h-4/5 object-cover"
        />
      </div>
      <div className="w-1/2 p-6 flex flex-col">
        <div className="bg-gray-700 rounded-lg shadow-md p-6 mb-4">
          <h2 className="text-xl font-bold">COLORPEPE #3278</h2>
        </div>
        <div className="bg-gray-700 rounded-lg shadow-md p-6 mb-4">
          <h1 className="text-2xl font-bold mb-4">Trade</h1>
          <p className="text-sm mb-4">
            Current Price: {currentPrice} SUI (${usdPrice.toFixed(2)})
          </p>
          <div className="flex space-x-4 mb-4">
            <button className="px-4 py-2 bg-blue-500 text-white rounded-lg">
              Buy
            </button>
            <button
              className={`px-4 py-2 bg-green-500 text-white rounded-lg ${showBidField ? "bg-green-300" : "bg-green-500"}`}
              onClick={() => setShowBidField(!showBidField)}
            >
              Bid
            </button>
          </div>
          {showBidField && (
            <div className="mb-4">
              <input
                type="number"
                min={highestBid + 1}
                className="w-full px-3 py-2 border rounded-lg"
                placeholder={`Minimum bid: ${highestBid + 1} SUI`}
                value={newBid}
                onChange={(e) => setNewBid(e.target.value)}
              />
              <button
                className="px-4 py-2 bg-green-500 text-white rounded-lg mt-2"
                onClick={handleBid}
              >
                Submit Bid
              </button>
            </div>
          )}
        </div>
        <div className="bg-gray-700 rounded-lg shadow-md p-6">
          <h2 className="text-xl font-bold mb-4">Existing Bids</h2>
          <div className="space-y-4">
            {bids.map((bid, index) => (
              <div
                key={index}
                className="flex justify-between items-center p-4 border rounded-lg"
              >
                <span>{bid.name}</span>
                <span className="font-bold">${bid.bidValue}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};
