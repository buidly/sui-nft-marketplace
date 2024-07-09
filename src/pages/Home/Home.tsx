import { Loader } from "../../components";
import { NftCard } from "../../components/NftCard";
import { useGetListings } from "../../hooks/useGetListings";

export const Home = () => {
  const { data, isPending, error } = useGetListings();

  if (isPending) {
    return <Loader />;
  }

  if (error) {
    return (
      <span className="text-lg font-bold mx-3">
        Could not fetch listed NFTs
      </span>
    );
  }

  if (data.length === 0) {
    return (
      <span className="text-lg font-bold mx-3">
        There are no NFTs listed yet
      </span>
    );
  }

  return (
    <div className="px-3">
      <span className="text-lg font-bold">Explore NFTs</span>
      <div className="grid-auto-fit mt-3">
        {data?.map((objectId: string) => (
          <NftCard key={objectId} objectId={objectId} />
        ))}
      </div>
    </div>
  );
};
