interface ModalProps {
  isOpen: boolean;
  onClose: () => void;
}

const MintModal = ({ isOpen, onClose }: ModalProps) => {
  if (!isOpen) return null;

  return (
    <div
      className="fixed inset-0 bg-black bg-opacity-50 z-50 flex justify-center items-center"
      onClick={onClose}
    >
      <div
        className="bg-gray-700 p-5 rounded-md max-w-sm mx-auto min-w-[300px] min-h-[400px] relative"
        onClick={(e) => e.stopPropagation()}
      >
        <button
          onClick={onClose}
          className="absolute top-1 right-3 text-xl font-bold p-2"
        >
          &times;
        </button>
        <div className="mt-5">
          <span className="font-bold text-lg">Mint</span>
          {/* <input
            type="text"
            className={`w-full px-3 py-2 border-2 rounded-lg ${
              price.length <= 0 ? "border-red-400" : ""
            }`}
            value={price}
            onChange={(e) => setPrice(e.target.value)}
            placeholder="Price (SUI)"
          />
          <input
            type="text"
            className={`w-full px-3 py-2 border-2 rounded-lg ${
              price.length <= 0 ? "border-red-400" : ""
            }`}
            value={price}
            onChange={(e) => setPrice(e.target.value)}
            placeholder="Price (SUI)"
          />
          <input
            type="text"
            className={`w-full px-3 py-2 border-2 rounded-lg ${
              price.length <= 0 ? "border-red-400" : ""
            }`}
            value={price}
            onChange={(e) => setPrice(e.target.value)}
            placeholder="Price (SUI)"
          /> */}
        </div>
      </div>
    </div>
  );
};

export default MintModal;
