import { useState } from "react";
import { Nft } from "../../types";

interface SelectNftCardProps {
  nft: Nft;
  onListNft: (nft: Nft, price: number) => void;
}

export const SelectNftCard = ({ nft, onListNft }: SelectNftCardProps) => {
  const [price, setPrice] = useState("");
  return (
    <div className="flex flex-col rounded-lg shadow-md bg-gray-700 bg-opacity-25 transition duration-300 w-[45%] md:min-w-[250px] md:min-h-[260px] cursor-pointer">
      <img
        className="object-cover rounded-t-lg h-auto w-auto min-h-[189px] md:min-h-[250px]"
        src={nft.url}
      />

      <div className="p-3">
        <span className="font-bold text-sm mt-3">{nft.name}</span>
        <div className="flex gap-2 my-3">
          <input
            type="number"
            className={`w-full px-3 py-2 border-2 rounded-lg ${
              price.length <= 0 ? "border-red-400" : ""
            }`}
            value={price}
            onChange={(e) => setPrice(e.target.value)}
            placeholder="Price"
          />
          <button
            className="px-4 py-2 bg-blue-500 text-white rounded-lg"
            onClick={() => onListNft(nft, Number(price))}
          >
            List
          </button>
        </div>
      </div>
    </div>
  );
};
