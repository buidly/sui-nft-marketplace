import { ConnectButton, useCurrentAccount } from "@mysten/dapp-kit";
import React from "react";

export const Layout = ({ children }: { children: React.ReactNode }) => {
  return (
    <>
      <div className="bg-light d-flex flex-column flex-fill wrapper">
        <NavBar />
        <div className="w-full h-[1px] bg-slate-100 mb-3" />
        <main className="d-flex flex-column flex-grow-1">{children}</main>
      </div>
    </>
  );
};

export const NavBar = () => {
  const account = useCurrentAccount();

  return (
    <div className="flex flex-row px-3 py-4 w-full items-center">
      <span className="text-lg font-bold grow">NFT Marketplace</span>
      <ConnectButton />
      {account && (
        <button className="ml-2 flex justify-center items-center h-[50px] px-6 rounded-xl bg-[#F6F7F9] text-[#182435] font-semibold text-sm">
          List NFT
        </button>
      )}
    </div>
  );
};
