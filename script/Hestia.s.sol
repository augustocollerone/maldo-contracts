// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {ERC20} from "@solady/tokens/ERC20.sol";
import {Script, console} from "forge-std/Script.sol";

import {IRegistry} from "../src/interfaces/IRegistry.sol";
import {MaldoToken} from "../src/contracts/tokens/MaldoToken.sol";
import {Registry} from "../src/contracts/Registry.sol";
import {Badges} from "../src/contracts/Badges.sol";

contract MaldoScript is Script {
    function setUp() public {}

    address public constant SEPOLIA_ESCROW_ADDRESS = 0xA01e6B988aeDae1fD4a748D6bfBcB8A438601DeE;

    function _deployer() internal returns (uint256, address) {
        uint256 deployerPK = vm.envUint("DEPLOYER_PRIVATE_KEY");
        return (deployerPK, vm.addr(deployerPK));
    }

    function run() public {
        console.log("Specify a function to run");
        (uint256 deployerPK, address deployer) = _deployer();
        console.log("DEPLOYER:", deployer);
    }

    function fullDeploy(address _token) public {
        uint256 privateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(privateKey);

        // Deploy contracts in order
        Badges badges = deployBadges(deployer);

        Registry registry = deployRegistry(_token, address(badges), SEPOLIA_ESCROW_ADDRESS);
    }

    function deployRegistry(address _token, address _badges, address _escrow) public returns (Registry) {
        uint256 privateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(privateKey);
        Registry registry = new Registry(_token, _badges, _escrow);
        console.log("Registry deployed at:", address(registry));
        vm.stopBroadcast();
        return registry;
    }

    function deployBadges(address admin) public returns (Badges) {
        uint256 privateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(privateKey);
        Badges badges = new Badges(admin);
        console.log("Badges deployed at:", address(badges));
        vm.stopBroadcast();
        return badges;
    }

    function deployTokenMaldo() public {
        uint256 privateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        ERC20 token = new MaldoToken();

        vm.stopBroadcast();
    }

    // function demo() public {
    //     uint256 deployerPK = vm.envUint("PRIVATE_KEY");
    //     vm.startBroadcast(deployerPK);

    //     Registry registry = deployRegistry();

    //     vm.stopBroadcast();
    // }
}
