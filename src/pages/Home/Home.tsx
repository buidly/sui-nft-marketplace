import { NftCard } from "../../components/NftCard";

export const Home = () => {
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
