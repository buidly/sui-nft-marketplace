import { useNavigate } from "react-router-dom";
import { routeNames } from "../../routes";
import { useGetNftDetails } from "../../hooks";
import BigNumber from "bignumber.js";
import { MIST_PER_SUI } from "@mysten/sui.js/utils";

interface NftCard {
  objectId: string;
}

export const NftCard = ({ objectId }: NftCard) => {
  const navigate = useNavigate();

  const { nft } = useGetNftDetails(objectId);

  if (!nft) {
    return null;
  }

  const priceDenom = new BigNumber(nft.price ?? 0).dividedBy(
    MIST_PER_SUI.toString(),
  );

  return (
    <div
      onClick={() =>
        navigate(routeNames.nftDetails.replace(":objectId", objectId))
      }
      className="flex flex-col items-center rounded-lg shadow-md bg-gray-700 bg-opacity-25 hover:bg-opacity-75 transition duration-300 w-[45%] md:min-w-[250px] md:min-h-[260px] cursor-pointer"
    >
      <img className="object-cover rounded-t-lg h-auto w-auto" src={nft.url} />
      <div className="flex flex-col justify-start w-full p-3 gap-y-1">
        <span className="font-bold text-sm text-left w-full">{nft.name}</span>
        <span className="font-bold text-sm text-left w-full">
          {priceDenom.toFixed()} SUI
        </span>
      </div>
    </div>
  );
};
