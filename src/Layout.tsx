import { ConnectButton, useCurrentAccount } from "@mysten/dapp-kit";
import React, { useState } from "react";
import { NavLink, useNavigate } from "react-router-dom";
import { routeNames } from "./routes";
import { ToastContainer } from "react-toastify";
import "react-toastify/dist/ReactToastify.min.css";
import burgerMenuIcon from "./assets/burger-menu.svg";
import closeIcon from "./assets/close-button.svg";
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
      <Footer />
    </>
  );
};

export const NavBar = () => {
  const account = useCurrentAccount();
  const navigate = useNavigate();

  const [isModalOpen, setModalOpen] = useState(false);
  const [isMenuOpen, setMenuOpen] = useState(false);

  const onListClick = () => {
    if (location.pathname.includes(routeNames.placeListing)) {
      return;
    }
    navigate(routeNames.placeListing);
  };

  const toggleMenu = () => {
    setMenuOpen(!isMenuOpen);
  };

  return (
    <div className="flex flex-col md:flex-row px-3 py-4 w-full items-center">
      <div className="flex flex-row px-3 py-4 w-full items-center">
        <NavLink to={routeNames.home} className="grow">
          <div className="flex flex-row items-center gap-x-1">
            <img
              src={
                "https://cdn.prod.website-files.com/664c70a0853437472986d0d1/664c70a0853437472986d1cf_logo-light.svg"
              }
              className="h-6"
            />
            <span className="text-lg font-bold text-gray-500">
              {" "}
              | NFT Marketplace
            </span>
          </div>
        </NavLink>
        <div className="flex md:hidden">
          <button onClick={toggleMenu} className="text-[#182435]">
            {isMenuOpen ? (
              <img src={closeIcon} height={42} width={42} />
            ) : (
              <img src={burgerMenuIcon} height={42} width={42} />
            )}
          </button>
        </div>
      </div>
      <div
        className={`flex-col md:flex-row gap-2 md:flex ${isMenuOpen ? "flex" : "hidden"} mt-4 md:mt-0 w-full md:w-auto`}
      >
        <ConnectButton />
        {account && (
          <button
            onClick={onListClick}
            className="ml-0 md:ml-2 flex justify-center items-center h-[50px] px-6 rounded-xl bg-[#F6F7F9] text-[#182435] font-semibold text-sm"
          >
            List NFTs
          </button>
        )}
        <button
          onClick={() => setModalOpen(true)}
          className="ml-0 md:ml-2 flex justify-center items-center h-[50px] px-6 rounded-xl bg-[#F6F7F9] text-[#182435] font-semibold text-sm"
        >
          Mint NFTs
        </button>
      </div>
      <MintModal isOpen={isModalOpen} onClose={() => setModalOpen(false)} />
    </div>
  );
};

import HeartIcon from "./assets/heart-icon.svg";
export const Footer = () => {
  return (
    <footer className="mx-auto w-full max-w-prose pb-6 pl-6 pr-6 mt-6 text-center text-gray-400">
      <div className="flex flex-col items-center text sm text-gray-400">
        <a
          className="text-gray-400 text-sm hover:cursor-pointer hover:underline"
          href="/disclaimer"
        >
          Disclaimer
        </a>
        <a
          target="_blank"
          className="flex items-center text-sm hover:underline"
          href="https://www.buidly.com/"
        >
          Made with <img src={HeartIcon} className="mx-1 fill-blue-500" /> by
          the Buidly team
        </a>
      </div>
    </footer>
  );
};
