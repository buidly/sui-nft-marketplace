import { useState } from "react";
import { useMintNft } from "../../hooks";

interface ModalProps {
  isOpen: boolean;
  onClose: () => void;
}

const MintModal = ({ isOpen, onClose }: ModalProps) => {
  if (!isOpen) return null;

  const mint = useMintNft(() => {
    onClose();
  });

  const [name, setName] = useState("");
  const [description, setDescription] = useState("");
  const [url, setUrl] = useState("");

  const inputsValid =
    name.length > 0 && description.length > 0 && url.length > 0;

  const onMintClick = () => {
    mint(name, description, url);
  };

  return (
    <div
      className="fixed inset-0 bg-black bg-opacity-50 z-50 flex justify-center items-center"
      onClick={onClose}
    >
      <div
        className="bg-gray-700 p-5 rounded-md max-w-sm mx-auto min-w-[300px] relative"
        onClick={(e) => e.stopPropagation()}
      >
        <button
          onClick={onClose}
          className="absolute top-1 right-3 text-xl font-bold p-2"
        >
          &times;
        </button>
        <div className="mt-5">
          <span className="font-bold text-lg">Mint NFT</span>
          <input
            type="text"
            className={`w-full mt-2 px-3 py-2 border-2 rounded-lg ${
              name.length <= 0 ? "border-red-400" : ""
            }`}
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Name"
          />
          <input
            type="text"
            className={`w-full mt-2 px-3 py-2 border-2 rounded-lg ${
              description.length <= 0 ? "border-red-400" : ""
            }`}
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder="Description"
          />
          <input
            type="text"
            className={`w-full mt-2 px-3 py-2 border-2 rounded-lg ${
              url.length <= 0 ? "border-red-400" : ""
            }`}
            value={url}
            onChange={(e) => setUrl(e.target.value)}
            placeholder="URL"
          />
          <button
            disabled={!inputsValid}
            className={`mt-3 mb-2 w-full px-4 py-2 bg-blue-500 text-white rounded-lg ${!inputsValid ? "opacity-50" : "opacity-100"}`}
            onClick={onMintClick}
          >
            Mint
          </button>
        </div>
      </div>
    </div>
  );
};

export default MintModal;
