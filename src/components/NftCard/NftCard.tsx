export const NftCard = () => {
  return (
    <div className="flex flex-col p-3 rounded-lg shadow-md bg-gray-700 bg-opacity-25 hover:bg-opacity-75 transition duration-300 min-w-[250px] min-h-[320px] cursor-pointer">
      <img
        className="rounded-lg h-[257px] w-[257px]"
        src="https://i.seadn.io/s/raw/files/6a45583bd2683834496cddf0c425338a.png?auto=format&dpr=1&w=1000"
      />
      <span className="font-bold text-sm mt-3">COLORPEPE #3278</span>
      <span className="font-bold text-sm">Price: 12 SUI</span>
    </div>
  );
};
