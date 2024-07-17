import {
  useCurrentAccount,
  useSignAndExecuteTransactionBlock,
  useSuiClient,
} from "@mysten/dapp-kit";
import { TransactionBlock } from "@mysten/sui.js/transactions";
import { toast } from "react-toastify";
import { useNetworkVariable } from "../networkConfig";

export const useMintNft = (onSuccess: () => void) => {
  const account = useCurrentAccount();
  const client = useSuiClient();
  const marketplacePackageId = useNetworkVariable("marketplacePackageId");
  const { mutate: signAndExecute } = useSignAndExecuteTransactionBlock();

  const mint = (name: string, description: string, url: string) => {
    if (!account) {
      return;
    }

    const txb = new TransactionBlock();

    const nft = txb.moveCall({
      arguments: [
        txb.pure(name),
        txb.pure(description),
        txb.pure(url),
      ],
      target: `${marketplacePackageId}::nft_marketplace::mint_to_sender`,
    });

    txb.transferObjects([nft], txb.pure.address(account.address));

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
              toast.success("NFT minted successfully.", {
                autoClose: 3000,
                position: "bottom-right",
                hideProgressBar: true,
                closeOnClick: true,
                pauseOnHover: false,
                draggable: false,
              });
              onSuccess();
            });
        },
        onError: (err) => {
          console.log({ err });
        }
      },
    );
  };

  return mint;
};
