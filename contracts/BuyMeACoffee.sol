//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// Example Contract Address on Goerli: 0x79e094F25989AB734e9a3CfB94eDE1A0101968e6
// Example Contract Address on Rinkeby: 0x611f526FDd5f382FF0177e3bf194fc54f1A96501

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./libraries/SVG.sol";
import "./libraries/Utils.sol";

import "hardhat/console.sol";

contract BuyMeACoffee is ERC721 {
    event NewMemo(
        address indexed from,
        uint256 timestamp,
        string name,
        string message,
        uint256 price
    );

    struct Memo {
        address from;
        uint256 timestamp;
        string name;
        string message;
        uint256 price;
    }

    uint256 public currentId = 1;
    address payable public owner;

    Memo[] memos;
    mapping(uint256 => uint256) tokenIdToMemo;

    constructor() ERC721("CoffeeMemos", "CUP") {
        owner = payable(msg.sender);
    }

    /**
     * @dev fetches all stored memos
     */
    function getMemos() public view returns (Memo[] memory) {
        return memos;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return _formatTokenURI(getImage(tokenId));
    }

    function _formatTokenURI(string memory imageURI)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name": "XOXO", "description": "On chain Tic-Tac-Toe war game.", "image":"',
                                imageURI,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function getImage(uint256 _tokenId) public view returns (string memory) {
        if (!_exists(_tokenId)) revert();
        Memo memory memo = memos[tokenIdToMemo[_tokenId]];

        string
            memory image = '<svg xmlns="http://www.w3.org/2000/svg" width="500" height="500" style="background:#9061F9;border-style:solid;border-color:white;">';
        string memory text = string.concat(utils.uint2str(memo.price), " Wei");

        image = string.concat(
            image,
            svg.text(
                string.concat(
                    svg.prop("x", "40"),
                    svg.prop("y", "200"),
                    svg.prop("font-size", "50"),
                    svg.prop("fill", "white")
                ),
                string.concat(svg.cdata("I bought a coffee"))
            ),
            svg.text(
                string.concat(
                    svg.prop("x", "40"),
                    svg.prop("y", "270"),
                    svg.prop("font-size", "50"),
                    svg.prop("fill", "white")
                ),
                string.concat(svg.cdata("for Tuturu"))
            ),
            svg.text(
                string.concat(
                    svg.prop("x", "130"),
                    svg.prop("y", "450"),
                    svg.prop("font-size", "50"),
                    svg.prop("fill", "black")
                ),
                string.concat(svg.cdata(memo.name))
            ),
            "</svg>"
        );

        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(bytes(image));
        string memory base64Image = string(
            abi.encodePacked(baseURL, svgBase64Encoded)
        );

        return base64Image;
    }

    /**
     * @dev buy a coffee for owner (sends an ETH tip and leaves a memo)
     * @param _name name of the coffee purchaser
     * @param _message a nice message from the purchaser
     */
    function buyCoffee(string memory _name, string memory _message)
        public
        payable
    {
        require(msg.value > 0, "can't buy coffee for free!");

        memos.push(
            Memo(msg.sender, block.timestamp, _name, _message, msg.value)
        );
        tokenIdToMemo[currentId] = memos.length - 1;
        _mint(msg.sender, currentId++);

        emit NewMemo(msg.sender, block.timestamp, _name, _message, msg.value);
    }

    /**
     * @dev send the entire balance stored in this contract to the owner
     */
    function withdrawTips() public {
        require(owner.send(address(this).balance));
    }
}
