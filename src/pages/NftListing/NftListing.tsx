import { useNavigate } from "react-router-dom";
import { SelectNftCard } from "../../components/SelectNftCard";
import { useGetAccountNfts } from "../../hooks/useGetAccountNfts";
import { usePlaceListing } from "../../hooks/usePlaceListing";
import { routeNames } from "../../routes";
import { Nft } from "../../types";
import { Loader } from "../../components";

export const NftListing = () => {
  const navigate = useNavigate();
  const { nfts, isPending, error } = useGetAccountNfts();
  const placeListing = usePlaceListing((id) => {
    navigate(routeNames.nftDetails.replace(":objectId", id));
  });

  if (isPending) {
    return <Loader />;
  }

  if (error) {
    return (
      <span className="text-lg font-bold mx-3">
        Could not fetch account NFTs
      </span>
    );
  }

  return (
    <div className="px-3">
      <span className="text-lg font-bold">List NFTs</span>
      <div className="flex flex-wrap justify-center gap-2 md:justify-start md:grid-auto-fit mt-3">
        {nfts.map((nft) => (
          <SelectNftCard
            key={nft.id}
            nft={nft}
            onListNft={function (nft: Nft, price: number): void {
              placeListing(nft.id, price, nft.type);
            }}
          />
        ))}
      </div>
    </div>
  );
};
