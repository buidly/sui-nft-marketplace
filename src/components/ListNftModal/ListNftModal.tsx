import React, { FormEvent, useState } from "react";

interface ListNftModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const ListNftModal: React.FC<ListNftModalProps> = ({
  isOpen,
  onClose,
}) => {
  const [name, setName] = useState("");
  const [supply, setSupply] = useState("");
  const [description, setDescription] = useState("");
  const [imageUrl, setImageUrl] = useState("");

  const isValidUrl = (url: string) => {
    try {
      new URL(url);
      return true;
    } catch (_) {
      return false;
    }
  };

  const isFormValid = () => {
    return name.length >= 5 && parseInt(supply) > 10 && isValidUrl(imageUrl);
  };

  const handleSubmit = (event: FormEvent) => {
    event.preventDefault();
    console.log({
      name,
      supply,
      description,
      imageUrl,
    });
    onClose();
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-gray-600 bg-opacity-75 flex items-center justify-center z-50">
      <div className="max-w-md mx-auto mt-10 p-6 bg-gray-700 rounded-lg shadow-md">
        <h1 className="text-2xl font-bold mb-4 text-white">Create a NFT</h1>
        <h2 className="text-xl mb-6 text-white">
          Once your item is minted you will not be able to change any of its
          information.
        </h2>
        <form onSubmit={handleSubmit}>
          <div className="mb-4">
            <label className="block text-white">Name</label>
            <input
              type="text"
              className={`w-full px-3 py-2 border-2 rounded-lg ${
                name.length < 5 && name.length > 0 ? "border-red-400" : ""
              }`}
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="A name (at least 5 characters)"
            />
          </div>
          <div className="mb-4">
            <label className="block text-white">Supply</label>
            <input
              type="number"
              className={`w-full px-3 py-2 border-2 rounded-lg ${
                supply && parseInt(supply) < 10 ? "border-red-400" : ""
              }`}
              value={supply}
              onChange={(e) => setSupply(e.target.value)}
              placeholder="A supply of minimum 10."
            />
          </div>
          <div className="mb-4">
            <label className="block text-white">Description</label>
            <textarea
              className="w-full px-3 py-2 border rounded-lg"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
            ></textarea>
          </div>
          <div className="mb-4">
            <label className="block text-white">Image URL</label>
            <input
              type="text"
              className={`w-full px-3 py-2 border-2 rounded-lg ${
                imageUrl.length > 1 && !isValidUrl(imageUrl)
                  ? "border-red-400"
                  : ""
              }`}
              value={imageUrl}
              onChange={(e) => setImageUrl(e.target.value)}
              placeholder="A valid image URL."
            />
          </div>
          <button
            type="submit"
            className={`w-full px-3 py-2 bg-blue-500 text-white rounded-lg ${
              !isFormValid() ? "opacity-50 cursor-not-allowed" : ""
            }`}
            disabled={!isFormValid()}
          >
            Submit
          </button>
          <button
            type="button"
            className="w-full px-3 py-2 mt-2 bg-red-500 text-white rounded-lg"
            onClick={onClose}
          >
            Cancel
          </button>
        </form>
      </div>
    </div>
  );
};
