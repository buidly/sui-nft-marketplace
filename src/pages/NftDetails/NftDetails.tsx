import { useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { useGetNftDetails } from "../../hooks";
import { useCurrentAccount } from "@mysten/dapp-kit";
import { useBuyNft } from "../../hooks/useBuyNft";
import { routeNames } from "../../routes";
import { MIST_PER_SUI } from "@mysten/sui.js/utils";
import { useCancelListing } from "../../hooks/useCancelListing";
import BigNumber from "bignumber.js";
import { Loader } from "../../components";

interface Bid {
  name: string;
  bidValue: number;
}

const mockupBids: Bid[] = [
  { name: "Bidder1", bidValue: 100 },
  { name: "Bidder2", bidValue: 150 },
];

export const NftDetails = () => {
  const { objectId } = useParams<{ objectId: string }>();
  const account = useCurrentAccount();
  const navigate = useNavigate();
  const { nft, isPending, error } = useGetNftDetails(objectId!);
  const buy = useBuyNft(() => {
    navigate(routeNames.home);
  });
  const cancelListing = useCancelListing(() => {
    navigate(routeNames.home);
  });

  const [bids, setBids] = useState<Bid[]>(mockupBids);
  const [showBidField, setShowBidField] = useState(false);
  const [newBid, setNewBid] = useState("");

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

  if (isPending) {
    return <Loader />;
  }

  if (error || !nft) {
    return (
      <span className="text-lg font-bold mx-3">
        Could not fetch NFT details
      </span>
    );
  }

  const priceDenom = new BigNumber(nft.price ?? 0).dividedBy(
    MIST_PER_SUI.toString(),
  );

  return (
    <div className="flex flex-col-reverse md:flex-row">
      <div className="w-full md:w-1/2 p-6">
        <img src={nft.url} alt="NFT" className="w-full h-4/5 object-cover" />
      </div>
      <div className="w-full md:w-1/2 p-6 flex flex-col">
        <div className="bg-gray-700 rounded-lg shadow-md p-6 mb-4">
          <h2 className="text-xl font-bold">{nft.name}</h2>
          <p className="text-md mt-1">{nft.description}</p>
        </div>
        <div className="bg-gray-700 rounded-lg shadow-md p-6 mb-4">
          <h1 className="text-2xl font-bold mb-4">Trade</h1>
          <p className="text-sm mb-4">
            Current Price: {priceDenom.toFixed()} SUI ($
            {priceDenom.multipliedBy(1.2).toFixed()})
          </p>
          <div className="flex space-x-4 mb-4">
            <button
              className="px-4 py-2 bg-blue-500 text-white rounded-lg"
              onClick={() => objectId && buy(objectId, nft.price)}
            >
              Buy
            </button>
            <button
              className={`px-4 py-2 bg-green-500 text-white rounded-lg ${showBidField ? "bg-green-300" : "bg-green-500"}`}
              onClick={() => setShowBidField(!showBidField)}
            >
              Bid
            </button>
            {nft.owner === account?.address && (
              <button
                className={`px-4 py-2 bg-red-500 text-white rounded-lg`}
                onClick={() => objectId && cancelListing(objectId)}
              >
                Cancel listing
              </button>
            )}
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
        {nft.owner === account?.address && (
          <div className="bg-gray-700 rounded-lg shadow-md p-6 mb-4">
            <button className="px-4 py-2 bg-blue-500 text-white rounded-lg">
              Accept bid
            </button>
          </div>
        )}
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
