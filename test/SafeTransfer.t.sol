// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {MockERC20} from "@solbase/test/utils/mocks/MockERC20.sol";
import {RevertingToken} from "@solbase/test/utils/weird-tokens/RevertingToken.sol";
import {ReturnsTwoToken} from "@solbase/test/utils/weird-tokens/ReturnsTwoToken.sol";
import {ReturnsFalseToken} from "@solbase/test/utils/weird-tokens/ReturnsFalseToken.sol";
import {MissingReturnToken} from "@solbase/test/utils/weird-tokens/MissingReturnToken.sol";
import {ReturnsTooMuchToken} from "@solbase/test/utils/weird-tokens/ReturnsTooMuchToken.sol";
import {ReturnsGarbageToken} from "@solbase/test/utils/weird-tokens/ReturnsGarbageToken.sol";
import {ReturnsTooLittleToken} from "@solbase/test/utils/weird-tokens/ReturnsTooLittleToken.sol";

import "@solbase/test/utils/TestPlus.sol";

import {ERC20} from "@solbase/src/tokens/ERC20/ERC20.sol";
import {
    ETHTransferFailed,
    safeTransferETH,
    ApproveFailed,
    safeApprove,
    TransferFailed,
    safeTransfer,
    TransferFromFailed,
    safeTransferFrom
} from "../src/utils/SafeTransfer.sol";

contract SafeTransferTest is TestPlus {
    RevertingToken reverting;
    ReturnsTwoToken returnsTwo;
    ReturnsFalseToken returnsFalse;
    MissingReturnToken missingReturn;
    ReturnsTooMuchToken returnsTooMuch;
    ReturnsGarbageToken returnsGarbage;
    ReturnsTooLittleToken returnsTooLittle;

    MockERC20 erc20;

    function setUp() public {
        reverting = new RevertingToken();
        returnsTwo = new ReturnsTwoToken();
        returnsFalse = new ReturnsFalseToken();
        missingReturn = new MissingReturnToken();
        returnsTooMuch = new ReturnsTooMuchToken();
        returnsGarbage = new ReturnsGarbageToken();
        returnsTooLittle = new ReturnsTooLittleToken();

        erc20 = new MockERC20("StandardToken", "ST", 18);
        erc20.mint(address(this), type(uint256).max);
    }

    function testTransferWithMissingReturn() public {
        verifySafeTransfer(address(missingReturn), address(0xBEEF), 1e18);
    }

    function testTransferWithStandardERC20() public {
        verifySafeTransfer(address(erc20), address(0xBEEF), 1e18);
    }

    function testTransferWithReturnsTooMuch() public {
        verifySafeTransfer(address(returnsTooMuch), address(0xBEEF), 1e18);
    }

    function testTransferWithNonContract() public {
        safeTransfer(address(0xBADBEEF), address(0xBEEF), 1e18);
    }

    function testTransferFromWithMissingReturn() public {
        verifySafeTransferFrom(address(missingReturn), address(0xFEED), address(0xBEEF), 1e18);
    }

    function testTransferFromWithStandardERC20() public {
        verifySafeTransferFrom(address(erc20), address(0xFEED), address(0xBEEF), 1e18);
    }

    function testTransferFromWithReturnsTooMuch() public {
        verifySafeTransferFrom(address(returnsTooMuch), address(0xFEED), address(0xBEEF), 1e18);
    }

    function testTransferFromWithNonContract() public {
        safeTransferFrom(address(0xBADBEEF), address(0xFEED), address(0xBEEF), 1e18);
    }

    function testApproveWithMissingReturn() public {
        verifySafeApprove(address(missingReturn), address(0xBEEF), 1e18);
    }

    function testApproveWithStandardERC20() public {
        verifySafeApprove(address(erc20), address(0xBEEF), 1e18);
    }

    function testApproveWithReturnsTooMuch() public {
        verifySafeApprove(address(returnsTooMuch), address(0xBEEF), 1e18);
    }

    function testApproveWithNonContract() public {
        safeApprove(address(0xBADBEEF), address(0xBEEF), 1e18);
    }

    function testTransferETH() public {
        safeTransferETH(address(0xBEEF), 1e18);
    }

    function testTransferRevertSelector() public {
        vm.expectRevert(TransferFailed.selector);
        this.testFailTransferWithReturnsFalse();
    }

    function testTransferFromRevertSelector() public {
        vm.expectRevert(TransferFromFailed.selector);
        this.testFailTransferFromWithReturnsFalse();
    }

    function testApproveRevertSelector() public {
        vm.expectRevert(ApproveFailed.selector);
        this.testFailApproveWithReturnsFalse();
    }

    function testTransferETHRevertSelector() public {
        vm.expectRevert(ETHTransferFailed.selector);
        this.testFailTransferETHToContractWithoutFallback();
    }

    function testFailTransferWithReturnsFalse() public {
        verifySafeTransfer(address(returnsFalse), address(0xBEEF), 1e18);
    }

    function testFailTransferWithReverting() public {
        verifySafeTransfer(address(reverting), address(0xBEEF), 1e18);
    }

    function testFailTransferWithReturnsTooLittle() public {
        verifySafeTransfer(address(returnsTooLittle), address(0xBEEF), 1e18);
    }

    function testFailTransferFromWithReturnsFalse() public {
        verifySafeTransferFrom(address(returnsFalse), address(0xFEED), address(0xBEEF), 1e18);
    }

    function testFailTransferFromWithReverting() public {
        verifySafeTransferFrom(address(reverting), address(0xFEED), address(0xBEEF), 1e18);
    }

    function testFailTransferFromWithReturnsTooLittle() public {
        verifySafeTransferFrom(address(returnsTooLittle), address(0xFEED), address(0xBEEF), 1e18);
    }

    function testFailApproveWithReturnsFalse() public {
        verifySafeApprove(address(returnsFalse), address(0xBEEF), 1e18);
    }

    function testFailApproveWithReverting() public {
        verifySafeApprove(address(reverting), address(0xBEEF), 1e18);
    }

    function testFailApproveWithReturnsTooLittle() public {
        verifySafeApprove(address(returnsTooLittle), address(0xBEEF), 1e18);
    }

    function testFuzzTransferWithMissingReturn(address to, uint256 amount) public brutalizeMemory {
        verifySafeTransfer(address(missingReturn), to, amount);
    }

    function testFuzzTransferWithStandardERC20(address to, uint256 amount) public brutalizeMemory {
        verifySafeTransfer(address(erc20), to, amount);
    }

    function testFuzzTransferWithReturnsTooMuch(address to, uint256 amount)
        public
        brutalizeMemory
    {
        verifySafeTransfer(address(returnsTooMuch), to, amount);
    }

    function testFuzzTransferWithGarbage(address to, uint256 amount, bytes memory garbage)
        public
        brutalizeMemory
    {
        if (garbageIsGarbage(garbage)) {
            return;
        }

        returnsGarbage.setGarbage(garbage);

        verifySafeTransfer(address(returnsGarbage), to, amount);
    }

    function testFuzzTransferWithNonContract(address nonContract, address to, uint256 amount)
        public
        brutalizeMemory
    {
        if (uint256(uint160(nonContract)) <= 18 || nonContract.code.length > 0) {
            return;
        }

        safeTransfer(nonContract, to, amount);
    }

    function testFailTransferETHToContractWithoutFallback() public {
        safeTransferETH(address(this), 1e18);
    }

    function testFuzzTransferFromWithMissingReturn(address from, address to, uint256 amount)
        public
        brutalizeMemory
    {
        verifySafeTransferFrom(address(missingReturn), from, to, amount);
    }

    function testFuzzTransferFromWithStandardERC20(address from, address to, uint256 amount)
        public
        brutalizeMemory
    {
        verifySafeTransferFrom(address(erc20), from, to, amount);
    }

    function testFuzzTransferFromWithReturnsTooMuch(address from, address to, uint256 amount)
        public
        brutalizeMemory
    {
        verifySafeTransferFrom(address(returnsTooMuch), from, to, amount);
    }

    function testFuzzTransferFromWithGarbage(
        address from,
        address to,
        uint256 amount,
        bytes memory garbage
    )
        public
        brutalizeMemory
    {
        if (garbageIsGarbage(garbage)) {
            return;
        }

        returnsGarbage.setGarbage(garbage);

        verifySafeTransferFrom(address(returnsGarbage), from, to, amount);
    }

    function testFuzzTransferFromWithNonContract(
        address nonContract,
        address from,
        address to,
        uint256 amount
    )
        public
        brutalizeMemory
    {
        if (uint256(uint160(nonContract)) <= 18 || nonContract.code.length > 0) {
            return;
        }

        safeTransferFrom(nonContract, from, to, amount);
    }

    function testFuzzApproveWithMissingReturn(address to, uint256 amount) public brutalizeMemory {
        verifySafeApprove(address(missingReturn), to, amount);
    }

    function testFuzzApproveWithStandardERC20(address to, uint256 amount) public brutalizeMemory {
        verifySafeApprove(address(erc20), to, amount);
    }

    function testFuzzApproveWithReturnsTooMuch(address to, uint256 amount) public brutalizeMemory {
        verifySafeApprove(address(returnsTooMuch), to, amount);
    }

    function testFuzzApproveWithGarbage(address to, uint256 amount, bytes memory garbage)
        public
        brutalizeMemory
    {
        if (garbageIsGarbage(garbage)) {
            return;
        }

        returnsGarbage.setGarbage(garbage);

        verifySafeApprove(address(returnsGarbage), to, amount);
    }

    function testFuzzApproveWithNonContract(address nonContract, address to, uint256 amount)
        public
        brutalizeMemory
    {
        if (uint256(uint160(nonContract)) <= 18 || nonContract.code.length > 0) {
            return;
        }

        safeApprove(nonContract, to, amount);
    }

    function testFuzzTransferETH(address recipient, uint256 amount) public brutalizeMemory {
        // Transferring to msg.sender can fail because it's possible to overflow their ETH balance as it begins non-zero.
        if (
            recipient.code.length > 0 || uint256(uint160(recipient)) <= 18
                || recipient == msg.sender
        ) {
            return;
        }

        amount = bound(amount, 0, address(this).balance);

        safeTransferETH(recipient, amount);
    }

    function testFailFuzzTransferWithReturnsFalse(address to, uint256 amount)
        public
        brutalizeMemory
    {
        verifySafeTransfer(address(returnsFalse), to, amount);
    }

    function testFailFuzzTransferWithReverting(address to, uint256 amount) public brutalizeMemory {
        verifySafeTransfer(address(reverting), to, amount);
    }

    function testFailFuzzTransferWithReturnsTooLittle(address to, uint256 amount)
        public
        brutalizeMemory
    {
        verifySafeTransfer(address(returnsTooLittle), to, amount);
    }

    function testFailFuzzTransferWithReturnsTwo(address to, uint256 amount)
        public
        brutalizeMemory
    {
        verifySafeTransfer(address(returnsTwo), to, amount);
    }

    function testFailFuzzTransferWithGarbage(address to, uint256 amount, bytes memory garbage)
        public
        brutalizeMemory
    {
        require(garbageIsGarbage(garbage));

        returnsGarbage.setGarbage(garbage);

        verifySafeTransfer(address(returnsGarbage), to, amount);
    }

    function testFailFuzzTransferFromWithReturnsFalse(address from, address to, uint256 amount)
        public
        brutalizeMemory
    {
        verifySafeTransferFrom(address(returnsFalse), from, to, amount);
    }

    function testFailFuzzTransferFromWithReverting(address from, address to, uint256 amount)
        public
        brutalizeMemory
    {
        verifySafeTransferFrom(address(reverting), from, to, amount);
    }

    function testFailFuzzTransferFromWithReturnsTooLittle(address from, address to, uint256 amount)
        public
        brutalizeMemory
    {
        verifySafeTransferFrom(address(returnsTooLittle), from, to, amount);
    }

    function testFailFuzzTransferFromWithReturnsTwo(address from, address to, uint256 amount)
        public
        brutalizeMemory
    {
        verifySafeTransferFrom(address(returnsTwo), from, to, amount);
    }

    function testFailFuzzTransferFromWithGarbage(
        address from,
        address to,
        uint256 amount,
        bytes memory garbage
    )
        public
        brutalizeMemory
    {
        require(garbageIsGarbage(garbage));

        returnsGarbage.setGarbage(garbage);

        verifySafeTransferFrom(address(returnsGarbage), from, to, amount);
    }

    function testFailFuzzApproveWithReturnsFalse(address to, uint256 amount)
        public
        brutalizeMemory
    {
        verifySafeApprove(address(returnsFalse), to, amount);
    }

    function testFailFuzzApproveWithReverting(address to, uint256 amount) public brutalizeMemory {
        verifySafeApprove(address(reverting), to, amount);
    }

    function testFailFuzzApproveWithReturnsTooLittle(address to, uint256 amount)
        public
        brutalizeMemory
    {
        verifySafeApprove(address(returnsTooLittle), to, amount);
    }

    function testFailFuzzApproveWithReturnsTwo(address to, uint256 amount) public brutalizeMemory {
        verifySafeApprove(address(returnsTwo), to, amount);
    }

    function testFailFuzzApproveWithGarbage(address to, uint256 amount, bytes memory garbage)
        public
        brutalizeMemory
    {
        require(garbageIsGarbage(garbage));

        returnsGarbage.setGarbage(garbage);

        verifySafeApprove(address(returnsGarbage), to, amount);
    }

    function testFailFuzzTransferETHToContractWithoutFallback(uint256 amount)
        public
        brutalizeMemory
    {
        safeTransferETH(address(this), amount);
    }

    function verifySafeTransfer(address token, address to, uint256 amount) public {
        uint256 preBal = ERC20(token).balanceOf(to);
        safeTransfer(address(token), to, amount);
        uint256 postBal = ERC20(token).balanceOf(to);

        if (to == address(this)) {
            assertEq(preBal, postBal);
        } else {
            assertEq(postBal - preBal, amount);
        }
    }

    function verifySafeTransferFrom(address token, address from, address to, uint256 amount)
        public
    {
        forceApprove(token, from, address(this), amount);

        // We cast to MissingReturnToken here because it won't check
        // that there was return data, which accommodates all tokens.
        MissingReturnToken(token).transfer(from, amount);

        uint256 preBal = ERC20(token).balanceOf(to);
        safeTransferFrom(token, from, to, amount);
        uint256 postBal = ERC20(token).balanceOf(to);

        if (from == to) {
            assertEq(preBal, postBal);
        } else {
            assertEq(postBal - preBal, amount);
        }
    }

    function verifySafeApprove(address token, address to, uint256 amount) public {
        safeApprove(address(token), to, amount);

        assertEq(ERC20(token).allowance(address(this), to), amount);
    }

    function forceApprove(address token, address from, address to, uint256 amount) public {
        uint256 slot = token == address(erc20) ? 4 : 2; // Standard ERC20 name and symbol aren't constant.

        vm.store(
            token,
            keccak256(abi.encode(to, keccak256(abi.encode(from, uint256(slot))))),
            bytes32(uint256(amount))
        );

        assertEq(ERC20(token).allowance(from, to), amount, "wrong allowance");
    }

    function garbageIsGarbage(bytes memory garbage) public pure returns (bool result) {
        assembly {
            result :=
                and(
                    or(lt(mload(garbage), 32), iszero(eq(mload(add(garbage, 0x20)), 1))),
                    gt(mload(garbage), 0)
                )
        }
    }
}
