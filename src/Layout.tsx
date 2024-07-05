import { ConnectButton, useCurrentAccount } from "@mysten/dapp-kit";
import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { routeNames } from "./routes";
import { ListNftModal } from "./components/ListNftModal";
import { ToastContainer } from "react-toastify";
import "react-toastify/dist/ReactToastify.min.css";

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

  const [isModalOpen, setIsModalOpen] = useState(false);

  const openModal = () => {
    setIsModalOpen(true);
  };

  const closeModal = () => {
    setIsModalOpen(false);
  };

  const onClick = () => {
    if (location.pathname.includes(routeNames.nftDetails)) {
      navigate(routeNames.home);
      return;
    }

    if (location.pathname.includes("/details")) {
      navigate(routeNames.home);
      return;
    }

    openModal();
  };

  return (
    <div className="flex flex-col md:flex-row px-3 py-4 w-full items-center">
      <span className="text-lg font-bold grow">NFT Marketplace</span>
      <div className="flex flex-col md:flex-row gap-2">
        <ConnectButton />
        {account && (
          <button
            onClick={onClick}
            className="ml-2 flex justify-center items-center h-[50px] px-6 rounded-xl bg-[#F6F7F9] text-[#182435] font-semibold text-sm"
          >
            {location.pathname.includes(routeNames.nftDetails) ||
            location.pathname.includes("/details")
              ? "Home"
              : "List NFT"}
          </button>
        )}
        <ListNftModal isOpen={isModalOpen} onClose={closeModal} />
      </div>
    </div>
  );
};
