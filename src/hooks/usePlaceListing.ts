import {
  useCurrentAccount,
  useSignAndExecuteTransactionBlock,
  useSuiClient,
} from "@mysten/dapp-kit";
import { TransactionBlock } from "@mysten/sui.js/transactions";
import { MIST_PER_SUI } from "@mysten/sui.js/utils";
import { toast } from "react-toastify";
import { useNetworkVariable } from "../networkConfig";

export const usePlaceListing = (onListed: (id: string) => void) => {
  const account = useCurrentAccount();
  const client = useSuiClient();
  const marketplacePackageId = useNetworkVariable("marketplacePackageId");
  const marketplaceObjectId = useNetworkVariable("marketplaceObjectId");
  const { mutate: signAndExecute } = useSignAndExecuteTransactionBlock();

  const placeListing = (objectId: string, price: number, type: string) => {
    if (!account) {
      return;
    }

    const txb = new TransactionBlock();

    txb.moveCall({
      arguments: [
        txb.object(marketplaceObjectId),
        txb.pure(objectId),
        txb.pure.u64(price * Number(MIST_PER_SUI)),
      ],
      target: `${marketplacePackageId}::nft_marketplace::place_listing`,
      typeArguments: [type]
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
              toast.success("NFT listed successfully.", {
                autoClose: 3000,
                position: "bottom-right",
                hideProgressBar: true,
                closeOnClick: true,
                pauseOnHover: false,
                draggable: false,
              });

              const objectId = tx.effects?.created?.[0]?.reference?.objectId;

              if (objectId) {
                onListed(objectId);
              }
            });
        },
        onError: (e) => {
          console.log({ e });
        },
      },
    );
  };

  return placeListing;
};
