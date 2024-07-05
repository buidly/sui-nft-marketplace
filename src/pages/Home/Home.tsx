import { NftCard } from "../../components/NftCard";
import { useGetListings } from "../../hooks/useGetListings";

export const Home = () => {
  const test = useGetListings();
  return (
    <div className="px-3">
      <span className="text-lg font-bold">Explore NFTs</span>
      <div className="grid-auto-fit mt-3">
        <NftCard />
        <NftCard />
        <NftCard />
        <NftCard />
        <NftCard />
        <NftCard />
      </div>
    </div>
  );
};
