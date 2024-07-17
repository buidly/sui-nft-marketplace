import {
  useCurrentAccount,
  useSignAndExecuteTransactionBlock,
  useSuiClient,
} from "@mysten/dapp-kit";
import { TransactionBlock } from "@mysten/sui.js/transactions";
import { useNetworkVariable } from "../networkConfig";
import { toast } from "react-toastify";
import BigNumber from "bignumber.js";
import { MIST_PER_SUI } from "@mysten/sui.js/utils";

export const usePlaceBid = (onPlaceBid: () => void) => {
  const account = useCurrentAccount();
  const client = useSuiClient();
  const marketplacePackageId = useNetworkVariable("marketplacePackageId");
  const marketplaceObjectId = useNetworkVariable("marketplaceObjectId");
  const { mutate: signAndExecute } = useSignAndExecuteTransactionBlock();

  const placeBid = (nftId: string, price: string) => {
    if (!account) {
      return;
    }
    const txb = new TransactionBlock();

    const [coin] = txb.splitCoins(txb.gas, [
      new BigNumber(price).multipliedBy(MIST_PER_SUI.toString()).toFixed(),
    ]);

    txb.moveCall({
      arguments: [txb.object(marketplaceObjectId), txb.pure(nftId), coin],
      target: `${marketplacePackageId}::nft_marketplace::place_bid`,
    });

    txb.setGasBudget(100000000);

    signAndExecute(
      {
        transactionBlock: txb,
        options: {
          showEffects: true,
          showObjectChanges: true,
        },
      },
      {
        onSuccess: (tx) => {
          client
            .waitForTransactionBlock({
              digest: tx.digest,
            })
            .then(() => {
              toast.success("Bid placed with success.", {
                autoClose: 1500,
                position: "bottom-right",
                hideProgressBar: true,
                closeOnClick: true,
                pauseOnHover: false,
                draggable: false,
              });
              onPlaceBid();
            });
        },
      },
    );
  };

  return placeBid;
};
