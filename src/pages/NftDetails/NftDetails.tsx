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
import { priceDenom, truncateText } from "../../helpers";
import { useCancelBid } from "../../hooks/useCancelBid";
import { useAcceptBid } from "../../hooks/useAcceptBid";
import cartIcon from "../../assets/buy-cart-icon.svg";
import tagIcon from "../../assets/tag-icon.svg";
import trashIcon from "../../assets/trash-icon.svg";

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
    <div className="flex flex-col md:flex-row">
      <div className="w-full md:w-1/2 p-6 pb-0 md:pb-6">
        <img
          src={nft.url}
          alt="NFT"
          className="w-full h-4/5 object-cover rounded-lg"
        />
      </div>
      <div className="w-full md:w-1/2 p-6 flex flex-col">
        <div className="bg-zinc-900 rounded-lg shadow-md p-6 mb-4">
          <h2 className="text-xl font-bold">{nft.name}</h2>
          <p className="text-md mt-1">{nft.description}</p>
        </div>
        <div className="bg-zinc-900 rounded-lg shadow-md p-6 mb-4">
          <p className="text-sm">Current Price:</p>
          <h1 className="text-2xl font-bold mb-4">
            {priceDenom(nft.price).toFixed()} SUI ($
            {priceDenom(nft.price).multipliedBy(0.7).toFixed()})
          </h1>

          <div className="flex flex-col md:flex-row gap-x-2 gap-y-2 mb-4">
            <button
              className="px-4 py-2 bg-blue-500 text-white rounded-lg grow md:w-2/6 flex flex-row items-center justify-center gap-x-2"
              onClick={() => buy(nft.id, nft.price, nft.type)}
            >
              <img src={cartIcon} className="h-5" />
              Buy Now
            </button>
            <button
              className={`grow md:w-2/6 px-4 py-2 bg-zinc-800 text-white rounded-lg flex flex-row items-center justify-center gap-x-2`}
              onClick={() => setShowBidField(!showBidField)}
            >
              <img src={tagIcon} className="h-5" />
              Make offer
            </button>
            {nft.owner === account?.address && (
              <button
                className={`grow md:w-2/6 px-4 py-2 bg-zinc-800 border border-red-500 text-white rounded-lg flex flex-row items-center justify-center gap-x-2`}
                onClick={() => cancelListing(nft.id, nft.type)}
              >
                <img src={trashIcon} className="h-5" />
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
                className="px-4 py-2 bg-zinc-800 border border-green-500 text-white rounded-lg mt-2 w-full"
                onClick={handleBid}
              >
                Submit Offer
              </button>
            </div>
          )}
        </div>
        <div className="bg-zinc-900 rounded-lg shadow-md p-6">
          <h2 className="text-xl font-bold mb-4">Existing Offers</h2>
          <div className="space-y-4">
            {bidsNeeded?.length > 0 ? (
              bidsNeeded.map((bid, index) => (
                <div
                  key={index}
                  className="flex justify-between items-left p-4 border rounded-lg flex-col gap-2"
                >
                  <div className="flex flex-row justify-between items-center">
                    <span>{truncateText(bid.owner, 3, 5)}</span>
                    <span className="font-bold">
                      {priceDenom(bid.balance).toFixed()} SUI
                    </span>
                  </div>
                  {nft.owner === account?.address && (
                    <button
                      className="px-4 py-2 bg-zinc-800 border border-blue-500  text-white rounded-lg"
                      onClick={() => acceptBid(bid.bidId, bid.nft_id, nft.type)}
                    >
                      Accept offer
                    </button>
                  )}
                  {bid.owner === account?.address && (
                    <button
                      className="px-4 py-2 bg-zinc-800 border border-red-500 text-white rounded-lg flex flex-row items-center justify-center gap-x-2"
                      onClick={() => cancelBid(bid.bidId, nft.id)}
                    >
                      <img src={trashIcon} className="h-5" />
                      Cancel Offer
                    </button>
                  )}
                </div>
              ))
            ) : (
              <p>No active offers.</p>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};
