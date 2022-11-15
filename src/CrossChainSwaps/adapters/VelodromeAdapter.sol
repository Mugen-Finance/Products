// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "velodrome/contracts/libraries/Math.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "velodrome/contracts/interfaces/IPair.sol";
import "velodrome/contracts/interfaces/IPairFactory.sol";
import "velodrome/contracts/interfaces/IRouter.sol";
import "velodrome/contracts/interfaces/IWETH.sol";

abstract contract VelodromeAdapter is IRouter {
    struct VeloParams {
        uint256 amountIn;
        uint256 amountOutMin;
        route[] routes;
        uint256 deadline;
    }

    struct route {
        address from;
        address to;
        bool stable;
    }

    // address public constant veloFactory = 0x25CbdDb98b35ab1FF77413456B31EC81A6B6B746;
    // IWETH public constant veloWETH = IWETH(0x4200000000000000000000000000000000000006);
    // bytes32 constant veloPairCodeHash = 0xc1ac28b1c4ebe53c0cff67bab5878c4eb68759bb1e9f73977cd266b247d149f0;
    uint256 internal constant MINIMUM_LIQUIDITY = 10**3;
    address public constant veloRouter = address(0x9c12939390052919aF3155f41Bf4160Fd3666A6f);

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "Router: EXPIRED");
        _;
    }

    constructor() {}

    function sortTokens(address tokenA, address tokenB)
        public
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "Router: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "Router: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address tokenA,
        address tokenB,
        bool stable
    ) public pure returns (address pair) {
        // (address token0, address token1) = sortTokens(tokenA, tokenB);
        // pair = address(
        //     uint160(
        //         uint256(
        //             keccak256(
        //                 abi.encodePacked(
        //                     hex"ff",
        //                     veloFactory,
        //                     keccak256(abi.encodePacked(token0, token1, stable)),
        //                     veloPairCodeHash // init code hash
        //                 )
        //             )
        //         )
        //     )
        // );
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountOut(
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) external view returns (uint256 amount, bool stable) {
        // address pair = pairFor(tokenIn, tokenOut, true);
        // uint256 amountStable;
        // uint256 amountVolatile;
        // if (IPairFactory(veloFactory).isPair(pair)) {
        //     amountStable = IPair(pair).getAmountOut(amountIn, tokenIn);
        // }
        // pair = pairFor(tokenIn, tokenOut, false);
        // if (IPairFactory(veloFactory).isPair(pair)) {
        //     amountVolatile = IPair(pair).getAmountOut(amountIn, tokenIn);
        // }
        // return
        //     amountStable > amountVolatile
        //         ? (amountStable, true)
        //         : (amountVolatile, false);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(uint256 amountIn, route[] memory routes)
        public
        view
        returns (uint256[] memory amounts)
    {
        // require(routes.length >= 1, "Router: INVALID_PATH");
        // amounts = new uint256[](routes.length + 1);
        // amounts[0] = amountIn;
        // for (uint256 i = 0; i < routes.length; i++) {
        //     address pair = pairFor(
        //         routes[i].from,
        //         routes[i].to,
        //         routes[i].stable
        //     );
        //     if (IPairFactory(veloFactory).isPair(pair)) {
        //         amounts[i + 1] = IPair(pair).getAmountOut(
        //             amounts[i],
        //             routes[i].from
        //         );
        //     }
        // }
    }

    function isPair(address pair) external view returns (bool) {
        //return IPairFactory(veloFactory).isPair(pair);
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(
        uint256[] memory amounts,
        route[] memory routes,
        address _to
    ) internal virtual {
        for (uint256 i = 0; i < routes.length; i++) {
            (address token0, ) = sortTokens(routes[i].from, routes[i].to);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = routes[i].from == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            address to = i < routes.length - 1
                ? pairFor(
                    routes[i + 1].from,
                    routes[i + 1].to,
                    routes[i + 1].stable
                )
                : _to;
            IPair(pairFor(routes[i].from, routes[i].to, routes[i].stable)).swap(
                    amount0Out,
                    amount1Out,
                    to,
                    new bytes(0)
                );
        }
    }

    function veloSwapExactTokensForTokens(VeloParams memory params)
        internal
        ensure(params.deadline)
        returns (uint256[] memory amounts)
    {
        amounts = getAmountsOut(params.amountIn, params.routes);
        require(
            amounts[amounts.length - 1] >= params.amountOutMin,
            "Router: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        _safeTransferFrom(
            params.routes[0].from,
            address(this),
            pairFor(
                params.routes[0].from,
                params.routes[0].to,
                params.routes[0].stable
            ),
            amounts[0]
        );
        _swap(amounts, params.routes, address(this));
    }

    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                from,
                to,
                value
            )
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}
