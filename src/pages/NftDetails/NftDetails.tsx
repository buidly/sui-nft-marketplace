import { useCurrentAccount } from "@mysten/dapp-kit";
import { useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { Loader } from "../../components";
import { useGetNftDetails } from "../../hooks";
import { useBuyNft } from "../../hooks/useBuyNft";
import { useCancelListing } from "../../hooks/useCancelListing";
import { useGetBidsDetails } from "../../hooks/useGetBidsDetails";
import { useGetListings } from "../../hooks/useGetListings";
import { usePlaceBid } from "../../hooks/usePlaceBid";
import { routeNames } from "../../routes";
import { priceDenom } from "../../helpers";
import { useCancelBid } from "../../hooks/useCancelBid";
import { useAcceptBid } from "../../hooks/useAcceptBid";

export const NftDetails = () => {
  const { objectId } = useParams<{ objectId: string }>();
  const account = useCurrentAccount();
  const navigate = useNavigate();
  const { nft, isPending, error } = useGetNftDetails(objectId!);
  const {
    bids,
    isPending: isPendingListings,
    error: isErrorListings,
    refetchBids,
  } = useGetListings();
  const {
    data: bidsNeeded,
    isPending: isPendingBidDetails,
    error: errorGetBidDetails,
  } = useGetBidsDetails(bids, nft?.id);
  const buy = useBuyNft(() => {
    navigate(routeNames.home);
  });
  const cancelBid = useCancelBid(() => {
    refetchBids();
  });
  const acceptBid = useAcceptBid(() => {
    navigate(routeNames.home);
  });
  const cancelListing = useCancelListing(() => {
    navigate(routeNames.home);
  });
  const placeBid = usePlaceBid(() => {
    refetchBids();
  });

  const [showBidField, setShowBidField] = useState(false);
  const [newBid, setNewBid] = useState("");

  const handleBid = () => {
    if (!nft || newBid.length === 0) {
      return;
    }

    placeBid(nft?.id, newBid);
    setShowBidField(false);
    setNewBid("");
  };

  if (isPending || isPendingListings || isPendingBidDetails) {
    return <Loader />;
  }

  if (error || !nft || isErrorListings || errorGetBidDetails) {
    return (
      <span className="text-lg font-bold mx-3">
        Could not fetch NFT details
      </span>
    );
  }

  return (
    <div className="flex flex-col-reverse md:flex-row">
      <div className="w-full md:w-1/2 p-6">
        <img
          src={nft.url}
          alt="NFT"
          className="w-full h-4/5 object-cover max-h-[600px]"
        />
      </div>
      <div className="w-full md:w-1/2 p-6 flex flex-col">
        <div className="bg-gray-700 rounded-lg shadow-md p-6 mb-4">
          <h2 className="text-xl font-bold">{nft.name}</h2>
          <p className="text-md mt-1">{nft.description}</p>
        </div>
        <div className="bg-gray-700 rounded-lg shadow-md p-6 mb-4">
          <h1 className="text-2xl font-bold mb-4">Trade</h1>
          <p className="text-sm mb-4">
            Current Price: {priceDenom(nft.price).toFixed()} SUI ($
            {priceDenom(nft.price).multipliedBy(1.2).toFixed()})
          </p>
          <div className="flex space-x-4 mb-4">
            <button
              className="px-4 py-2 bg-blue-500 text-white rounded-lg"
              onClick={() => buy(nft.id, nft.price, nft.type)}
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
                onClick={() => cancelListing(nft.id, nft.type)}
              >
                Cancel listing
              </button>
            )}
          </div>
          {showBidField && (
            <div className="mb-4">
              <input
                type="number"
                min={0}
                className="w-full px-3 py-2 border rounded-lg"
                placeholder={`Bid amount`}
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
            {bidsNeeded?.length > 0 ? (
              bidsNeeded.map((bid, index) => (
                <div
                  key={index}
                  className="flex justify-between items-left p-4 border rounded-lg flex-col gap-2"
                >
                  <span>{bid.owner}</span>
                  <span className="font-bold">
                    {priceDenom(bid.balance).toFixed()} SUI
                  </span>
                  {nft.owner === account?.address && (
                    <button
                      className="px-4 py-2 bg-blue-500 text-white rounded-lg"
                      onClick={() => acceptBid(bid.bidId, bid.nft_id, nft.type)}
                    >
                      Accept bid
                    </button>
                  )}
                  {bid.owner === account?.address && (
                    <button
                      className="px-4 py-2 bg-blue-500 text-white rounded-lg"
                      onClick={() => cancelBid(bid.bidId, nft.id)}
                    >
                      Cancel bid
                    </button>
                  )}
                </div>
              ))
            ) : (
              <p>No active bids.</p>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};
