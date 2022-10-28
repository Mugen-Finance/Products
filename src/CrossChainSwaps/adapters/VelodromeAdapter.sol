// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "velodrome/contracts/libraries/Math.sol";
import "velodrome/contracts/interfaces/IERC20.sol";
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

    address public immutable veloFactory;
    IWETH public immutable veloWETH;
    uint256 internal constant MINIMUM_LIQUIDITY = 10**3;
    bytes32 immutable veloPairCodeHash;

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "Router: EXPIRED");
        _;
    }

    constructor(address _veloFactory, address _veloWETH) {
        veloFactory = _veloFactory;
        veloPairCodeHash = IPairFactory(_veloFactory).pairCodeHash();
        veloWETH = IWETH(_veloWETH);
    }

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
    ) public view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            veloFactory,
                            keccak256(abi.encodePacked(token0, token1, stable)),
                            veloPairCodeHash // init code hash
                        )
                    )
                )
            )
        );
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quoteLiquidity(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "Router: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "Router: INSUFFICIENT_LIQUIDITY");
        amountB = (amountA * reserveB) / reserveA;
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address tokenA,
        address tokenB,
        bool stable
    ) public view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IPair(
            pairFor(tokenA, tokenB, stable)
        ).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountOut(
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) external view returns (uint256 amount, bool stable) {
        address pair = pairFor(tokenIn, tokenOut, true);
        uint256 amountStable;
        uint256 amountVolatile;
        if (IPairFactory(veloFactory).isPair(pair)) {
            amountStable = IPair(pair).getAmountOut(amountIn, tokenIn);
        }
        pair = pairFor(tokenIn, tokenOut, false);
        if (IPairFactory(veloFactory).isPair(pair)) {
            amountVolatile = IPair(pair).getAmountOut(amountIn, tokenIn);
        }
        return
            amountStable > amountVolatile
                ? (amountStable, true)
                : (amountVolatile, false);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(uint256 amountIn, route[] memory routes)
        public
        view
        returns (uint256[] memory amounts)
    {
        require(routes.length >= 1, "Router: INVALID_PATH");
        amounts = new uint256[](routes.length + 1);
        amounts[0] = amountIn;
        for (uint256 i = 0; i < routes.length; i++) {
            address pair = pairFor(
                routes[i].from,
                routes[i].to,
                routes[i].stable
            );
            if (IPairFactory(veloFactory).isPair(pair)) {
                amounts[i + 1] = IPair(pair).getAmountOut(
                    amounts[i],
                    routes[i].from
                );
            }
        }
    }

    function isPair(address pair) external view returns (bool) {
        return IPairFactory(veloFactory).isPair(pair);
    }

    function quoteAddLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 amountADesired,
        uint256 amountBDesired
    )
        external
        view
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        // create the pair if it doesn't exist yet
        address _pair = IPairFactory(veloFactory).getPair(
            tokenA,
            tokenB,
            stable
        );
        (uint256 reserveA, uint256 reserveB) = (0, 0);
        uint256 _totalSupply = 0;
        if (_pair != address(0)) {
            _totalSupply = IERC20(_pair).totalSupply();
            (reserveA, reserveB) = getReserves(tokenA, tokenB, stable);
        }
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
            liquidity = Math.sqrt(amountA * amountB) - MINIMUM_LIQUIDITY;
        } else {
            uint256 amountBOptimal = quoteLiquidity(
                amountADesired,
                reserveA,
                reserveB
            );
            if (amountBOptimal <= amountBDesired) {
                (amountA, amountB) = (amountADesired, amountBOptimal);
                liquidity = Math.min(
                    (amountA * _totalSupply) / reserveA,
                    (amountB * _totalSupply) / reserveB
                );
            } else {
                uint256 amountAOptimal = quoteLiquidity(
                    amountBDesired,
                    reserveB,
                    reserveA
                );
                (amountA, amountB) = (amountAOptimal, amountBDesired);
                liquidity = Math.min(
                    (amountA * _totalSupply) / reserveA,
                    (amountB * _totalSupply) / reserveB
                );
            }
        }
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
