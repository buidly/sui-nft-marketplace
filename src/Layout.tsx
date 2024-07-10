import { ConnectButton, useCurrentAccount } from "@mysten/dapp-kit";
import React, { useState } from "react";
import { NavLink, useNavigate } from "react-router-dom";
import { routeNames } from "./routes";
import { ToastContainer } from "react-toastify";
import "react-toastify/dist/ReactToastify.min.css";
import MintModal from "./components/Mint/MintModal";

export const Layout = ({ children }: { children: React.ReactNode }) => {
  return (
    <>
      <div className="bg-light d-flex flex-column flex-fill wrapper">
        <NavBar />
        <div className="w-full h-[1px] bg-slate-100 mb-3" />
        <main className="d-flex flex-column flex-grow-1">{children}</main>
      </div>
      <ToastContainer />
    </>
  );
};

export const NavBar = () => {
  const account = useCurrentAccount();
  const navigate = useNavigate();

  const [isModalOpen, setModalOpen] = useState(false);

  const onListClick = () => {
    if (location.pathname.includes(routeNames.placeListing)) {
      return;
    }
    navigate(routeNames.placeListing);
  };

  return (
    <div className="flex flex-col md:flex-row px-3 py-4 w-full items-center">
      <NavLink to={routeNames.home} className="grow">
        <span className="text-lg font-bold">NFT Marketplace</span>
      </NavLink>
      <div className="flex flex-col md:flex-row gap-2">
        <ConnectButton />
        {account && (
          <button
            onClick={onListClick}
            className="ml-2 flex justify-center items-center h-[50px] px-6 rounded-xl bg-[#F6F7F9] text-[#182435] font-semibold text-sm"
          >
            List NFTs
          </button>
        )}
        <button
          onClick={() => setModalOpen(true)}
          className="ml-2 flex justify-center items-center h-[50px] px-6 rounded-xl bg-[#F6F7F9] text-[#182435] font-semibold text-sm"
        >
          Mint NFTs
        </button>
      </div>

      <MintModal isOpen={isModalOpen} onClose={() => setModalOpen(false)} />
    </div>
  );
};
