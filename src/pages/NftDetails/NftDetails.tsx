import { useState } from "react";
import { useParams } from "react-router-dom";
import { useGetNftDetails } from "../../hooks";
import { useCurrentAccount } from "@mysten/dapp-kit";
import BigNumber from "bignumber.js";

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
  const { data, isPending, error } = useGetNftDetails(objectId!);

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
  if (isPending || !data || !account) {
    return (
      <div className="flex justify-center items-center w-full">
        <svg
          aria-hidden="true"
          className="w-12 h-12 text-gray-200 animate-spin dark:text-gray-600 fill-white"
          viewBox="0 0 100 101"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <path
            d="M100 50.5908C100 78.2051 77.6142 100.591 50 100.591C22.3858 100.591 0 78.2051 0 50.5908C0 22.9766 22.3858 0.59082 50 0.59082C77.6142 0.59082 100 22.9766 100 50.5908ZM9.08144 50.5908C9.08144 73.1895 27.4013 91.5094 50 91.5094C72.5987 91.5094 90.9186 73.1895 90.9186 50.5908C90.9186 27.9921 72.5987 9.67226 50 9.67226C27.4013 9.67226 9.08144 27.9921 9.08144 50.5908Z"
            fill="currentColor"
          />
          <path
            d="M93.9676 39.0409C96.393 38.4038 97.8624 35.9116 97.0079 33.5539C95.2932 28.8227 92.871 24.3692 89.8167 20.348C85.8452 15.1192 80.8826 10.7238 75.2124 7.41289C69.5422 4.10194 63.2754 1.94025 56.7698 1.05124C51.7666 0.367541 46.6976 0.446843 41.7345 1.27873C39.2613 1.69328 37.813 4.19778 38.4501 6.62326C39.0873 9.04874 41.5694 10.4717 44.0505 10.1071C47.8511 9.54855 51.7191 9.52689 55.5402 10.0491C60.8642 10.7766 65.9928 12.5457 70.6331 15.2552C75.2735 17.9648 79.3347 21.5619 82.5849 25.841C84.9175 28.9121 86.7997 32.2913 88.1811 35.8758C89.083 38.2158 91.5421 39.6781 93.9676 39.0409Z"
            fill="currentFill"
          />
        </svg>
      </div>
    );
  }

  const nftFields =
    data.data?.content?.dataType === "moveObject"
      ? (data.data.content.fields as any)
      : null;
  console.log({ nftFields });

  const priceDenom = new BigNumber(nftFields.price ?? 0).shiftedBy(-9);

  const nftOwner = data.data?.owner as any;

  return (
    <div className="flex flex-col-reverse md:flex-row">
      <div className="w-full md:w-1/2 p-6">
        <img
          src={nftFields.nft.fields.url}
          alt="NFT"
          className="w-full h-4/5 object-cover"
        />
      </div>
      <div className="w-full md:w-1/2 p-6 flex flex-col">
        <div className="bg-gray-700 rounded-lg shadow-md p-6 mb-4">
          <h2 className="text-xl font-bold">{nftFields.nft.fields.name}</h2>
          <p className="text-md mt-1">{nftFields.nft.fields.description}</p>
        </div>
        <div className="bg-gray-700 rounded-lg shadow-md p-6 mb-4">
          <h1 className="text-2xl font-bold mb-4">Trade</h1>
          <p className="text-sm mb-4">
            Current Price: {priceDenom.toFixed()} SUI ($
            {priceDenom.times(1.2).toFixed(2)})
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
        {nftOwner?.AddressOwner === account.address && (
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
