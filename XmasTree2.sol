// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "base64-sol/base64.sol";

contract WinterTrees is ERC721URIStorage, Ownable {
    uint256 public tokenCounter;
    uint256 public maxTrees;

    event CreatedRandomSVG(uint256 indexed tokenId, string tokenURI);
    event CreatedUnfinishedRandomSVG(uint256 indexed tokenId, uint256 randomNumber);
    event requestedRandomSVG(bytes32 indexed requestId, uint256 indexed tokenId); 
    mapping(bytes32 => address) public requestIdToSender;
    mapping(uint256 => uint256) public tokenIdToRandomNumber;
    mapping(bytes32 => uint256) public requestIdToTokenId;
    uint256 public maxNumberOfPaths;
    uint256 public maxNumberOfPathCommands;
    uint256 public maxNumberOfSnow;
    uint256 public size;
    string[] public pathCommands;
    string[] public colors;
    string[] public durvals;


    constructor() 
    ERC721("WinterTree", "rsNFT")
    {
        tokenCounter = 0;
        maxTrees = 100;
        size = 500;
        colors = ["red", "blue", "#1a1", "#1ee", "#000", "#fff"];
        durvals = ["2.5","3","3.25","2.15","2","3.1","1.9"];
        maxNumberOfSnow = 2;
    }

    function withdraw() public payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function create() public {
        require(tokenCounter <= maxTrees, "Already minted max number of trees");
        uint256 tokenId = tokenCounter;
        tokenCounter = tokenCounter + 1;

        uint256 randomNumber = random(string(abi.encodePacked('neonstoic', uint2str(tokenId + 102))));
        string memory svg = generateSVG(randomNumber);
        string memory imageURI = svgToImageURI(svg);
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, formatTokenURI(tokenId, imageURI));    
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function generateSVG(uint256 _randomness) public view returns (string memory finalSvg) {
        finalSvg = string(abi.encodePacked("<svg xmlns='http://www.w3.org/2000/svg' height='370' width='500' viewBox='50 0 100 70'><defs><g id='s' fill='#fff' stroke='#000'><circle r='1'/><circle r='1' cx='40' cy='20'/></g></defs>"));
        string memory snowSVG1 = generateSnow(_randomness);        
        finalSvg = string(abi.encodePacked(finalSvg, snowSVG1));
        finalSvg = string(abi.encodePacked(finalSvg, "<g stroke='#000'><rect x='91' width='9' y='59' height='10' fill='#952'/><rect x='91' width='9' y='59' height='3' stroke-width='0' fill='#521'/>"));
        finalSvg = string(abi.encodePacked(finalSvg, "<path d='M95 1L110 15L100 15L120 30L100 30L125 45L100 45L130 60L60 60L90 45L65 45L90 30L70 30L90 15L80 15L95 1z' fill='#171'/></g>"));
        string memory snowSVG2 = generateSnow(uint256(keccak256(abi.encode(_randomness, size * 2))));
        finalSvg = string(abi.encodePacked(finalSvg, snowSVG2));
        string memory present = addPresent(_randomness);
        finalSvg = string(abi.encodePacked(finalSvg, present));
        finalSvg = string(abi.encodePacked(finalSvg, "</svg>"));
    }

    function generateSnow(uint256 _randomness) public view returns(string memory svgSnow) {        
        for(uint i = 0; i < 2; i++) {                        
            svgSnow = string(abi.encodePacked(svgSnow, generateSnowflake(_randomness, i)));
        }        
    }

    function generateSnowflake(uint256 _randomness, uint256 _index) public view returns(string memory svgSnowflake){
        uint256 r = uint256(keccak256(abi.encode(_randomness, _index * 2)));
        uint256 cx = (r % 60) + 50;
        uint256 cy = (r % 60);
        uint256 _durindex = r % durvals.length;
        string memory _sdur = durvals[_durindex];

        svgSnowflake = string(abi.encodePacked("<use x='", uint2str(cx), "' href='#s'><animate attributeName='y' from='-", uint2str(cy), "' to='70' dur='", _sdur, "' repeatCount='indefinite'/></use>"));
    }

    function addPresent(uint256 _randomness) public view returns(string memory presentSvg) {
        string memory color = colors[_randomness % colors.length];
        string memory ribboncolor = colors[(_randomness+1) % colors.length];
        uint256 xloc = ((_randomness) % 90) + 45;
        presentSvg = string(abi.encodePacked("<g stroke='#000' fill='",color,"' transform='translate(",uint2str(xloc)," 58)'><rect x='1' width='10' y='3' height='8' stroke-width='1'/><rect x='0' width='12' y='0' height='3' stroke-width='1'/><rect x='5' width='2' y='0' height='11' fill='",ribboncolor,"'/></g>"));
    }

    // From: https://stackoverflow.com/a/65707309/11969592
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function svgToImageURI(string memory svg) public pure returns (string memory) {
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(bytes(string(abi.encodePacked(svg))));
        return string(abi.encodePacked(baseURL,svgBase64Encoded));
    }

    function formatTokenURI(uint256 id, string memory imageURI) public pure returns (string memory) {
        string memory desc = string(abi.encodePacked('Winter tree #', uint2str(id)));
        return string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                "Winter Tree", // You can add whatever name here
                                '", "description":"',desc,'", "attributes":"", "image":"',imageURI,'"}'
                            )
                        )
                    )
                )
            );
    }

}
