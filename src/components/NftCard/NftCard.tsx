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
      className="flex flex-col p-3 rounded-lg shadow-md bg-gray-700 bg-opacity-25 hover:bg-opacity-75 transition duration-300 min-w-[250px] min-h-[260px] cursor-pointer"
    >
      <img
        className="object-cover rounded-lg h-[200px] w-[257px]"
        src={nft.url}
      />
      <span className="font-bold text-sm mt-3">{nft.name}</span>
      <span className="font-bold text-sm">
        Price: {priceDenom.toFixed()} SUI
      </span>
    </div>
  );
};
