import { FormEvent, useState } from "react";

export const ListNft = () => {
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
    // Handle the form submission here
    console.log({
      name,
      supply,
      description,
      imageUrl,
    });
  };

  return (
    <div className="max-w-md mx-auto mt-10 p-6 bg-gray-700 rounded-lg shadow-md">
      <h1 className="text-2xl font-bold mb-4 ">Create a NFT</h1>
      <h2 className="text-xl mb-6 ">
        Once your item is minted you will not be able to change any of its
        information.
      </h2>
      <form onSubmit={handleSubmit}>
        <div className="mb-4">
          <label className="block ">Name</label>
          <input
            type="text"
            className={`w-full px-3 py-2 border-2 rounded-lg ${name.length < 5 && name.length > 0 ? "border-solid border-red-400" : ""} `}
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="A name (at least 5 characters)"
          />
        </div>
        <div className="mb-4">
          <label className="block ">Supply</label>
          <input
            type="number"
            className={`w-full px-3 py-2 border-2 rounded-lg ${supply && parseInt(supply) < 10 ? "border-solid border-red-400" : ""}`}
            value={supply}
            onChange={(e) => setSupply(e.target.value)}
            placeholder="A supply of minimum 10."
          />
        </div>
        <div className="mb-4">
          <label className="block ">Description</label>
          <textarea
            className="w-full px-3 py-2 border rounded-lg"
            value={description}
            onChange={(e) => setDescription(e.target.value)}
          ></textarea>
        </div>
        <div className="mb-4">
          <label className="block ">Image URL</label>
          <input
            type="text"
            className={`w-full px-3 py-2 border-2 rounded-lg ${imageUrl.length > 1 && !isValidUrl(imageUrl) ? "border-solid border-red-400" : ""}`}
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
      </form>
    </div>
  );
};
