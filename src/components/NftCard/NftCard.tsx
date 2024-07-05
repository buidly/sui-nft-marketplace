import { useNavigate } from "react-router-dom";
import { routeNames } from "../../routes";

const mockupObjectId =
  "0xdbddf0dd0707f1c34221682abd7fd1b3181db8cf27b6e5ff1ffc7348e6b2aa66";

export const NftCard = () => {
  const navigate = useNavigate();
  return (
    <div
      onClick={() =>
        navigate(routeNames.nftDetails.replace(":objectId", mockupObjectId))
      }
      className="flex flex-col p-3 rounded-lg shadow-md bg-gray-700 bg-opacity-25 hover:bg-opacity-75 transition duration-300 min-w-[250px] min-h-[260px] cursor-pointer"
    >
      <img
        className="object-cover rounded-lg h-[200px] w-[257px]"
        src="https://i.seadn.io/s/raw/files/6a45583bd2683834496cddf0c425338a.png?auto=format&dpr=1&w=1000"
      />
      <span className="font-bold text-sm mt-3">COLORPEPE #3278</span>
      <span className="font-bold text-sm">Price: 12 SUI</span>
    </div>
  );
};
